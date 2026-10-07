function [surface, info, attributes] = readMz3Surface(reference, rootPath, options)
%READMZ3SURFACE Independent bounded raw/GZip MZ3 triangle geometry reader.
% Optional arrays are returned separately, never silently applied as settings.
arguments
    reference (1,1) brainnet.core.InputReference
    rootPath (1,1) string
    options.MaxVertices (1,1) double {mustBeInteger,mustBePositive,mustBeFinite} = 10000000
    options.MaxFaces (1,1) double {mustBeInteger,mustBePositive,mustBeFinite} = 20000000
    options.MaxBytes (1,1) double {mustBeInteger,mustBePositive,mustBeFinite} = 1073741824
    options.MaxSkipBytes (1,1) double {mustBeInteger,mustBeNonnegative,mustBeFinite} = 16777216
    options.MaxScalarLayers (1,1) double {mustBeInteger,mustBePositive,mustBeFinite} = 256
end
path=brainnet.io.internal.resolveAndVerify(reference,rootPath,"surface");
file=-1; temporary=""; output=-1; input=[]; stream=[]; channel=[];
try
file=fopen(path,'rb','ieee-le');
if file<0, error('BNV:IO:InputOpenFailed','Cannot open MZ3 file.'); end
fseek(file,0,'eof'); total=ftell(file); fseek(file,0,'bof');
if total>options.MaxBytes, error('BNV:IO:Mz3ResourceLimit','MZ3 input exceeds MaxBytes.'); end
magic=fread(file,1,'uint16'); encoding='raw';
if isequal(magic,35615)
    if total<18, error('BNV:IO:Mz3Gzip','Incomplete GZip MZ3 container.'); end
    fseek(file,-8,'eof'); trailer=fread(file,2,'uint32');
    fclose(file); file=-1;
    temporary=string(tempname)+".mz3";
    try
        input=java.io.FileInputStream(char(path));
        stream=java.util.zip.GZIPInputStream(input);
        channel=java.nio.channels.Channels.newChannel(stream);
        buffer=java.nio.ByteBuffer.allocate(65536);
        crc=java.util.zip.CRC32;
        output=fopen(temporary,'wb');
        if output<0, error('BNV:IO:InputOpenFailed','Cannot create temporary MZ3 file.'); end
        decoded=0;
        while true
            buffer.clear(); count=channel.read(buffer);
            if count<0, break; end
            decoded=decoded+double(count);
            if decoded>options.MaxBytes
                error('BNV:IO:Mz3ResourceLimit','Decoded MZ3 exceeds MaxBytes.');
            end
            bytes=buffer.array(); bytes=bytes(1:count);
            crc.update(bytes);
            if fwrite(output,typecast(bytes,'uint8'),'uint8')~=count
                error('BNV:IO:InputOpenFailed','Unable to write temporary MZ3 data.');
            end
        end
        if double(crc.getValue())~=trailer(1) || mod(decoded,2^32)~=trailer(2)
            error('BNV:IO:Mz3Gzip','MZ3 GZip checksum/size mismatch or unsupported multiple-member container.');
        end
        fclose(output); output=-1; channel.close(); channel=[];
        stream.close(); stream=[]; input.close(); input=[];
    catch failure
        if startsWith(string(failure.identifier),"BNV:IO:"), rethrow(failure); end
        error('BNV:IO:Mz3Gzip','Cannot decode MZ3 GZip data: %s',failure.message);
    end
    file=fopen(temporary,'rb','ieee-le');
    if file<0, error('BNV:IO:InputOpenFailed','Cannot open decoded MZ3.'); end
    total=decoded; encoding='gzip'; magic=fread(file,1,'uint16');
end
catch failure
    release(file,output,input,stream,channel,temporary);
    rethrow(failure);
end
cleanup=onCleanup(@() release(file,-1,[],[],[],temporary));
if ~isequal(magic,23117), error('BNV:IO:Mz3Signature','Expected little-endian MZ3 signature.'); end
attr=numbers(1,'uint16'); counts=numbers(3,'uint32');
nf=counts(1); nv=counts(2); skip=counts(3);
if attr<1 || attr>31 || (bitand(attr,8)>0 && bitand(attr,16)>0)
    error('BNV:IO:Mz3Attributes','Unsupported MZ3 flags: AO/lookup/future flags and mixed scalar precision are not supported.');
end
if bitand(attr,3)~=3
    error('BNV:IO:Mz3Geometry','Surface input requires both faces and vertices; overlay-only MZ3 is not supported here.');
end
if nv<3 || nv>options.MaxVertices || nf<1 || nf>options.MaxFaces
    error('BNV:IO:Mz3Counts','Invalid or excessive MZ3 vertex/face count.');
end
if skip>options.MaxSkipBytes, error('BNV:IO:Mz3ResourceLimit','MZ3 private header exceeds MaxSkipBytes.'); end
hasColor=bitand(attr,4)>0; hasScalar=bitand(attr,24)>0;
width=4; precision='single';
if bitand(attr,16)>0, width=8; precision='double'; end
base=16+skip+12*nf+12*nv+4*nv*hasColor;
if base>total, error('BNV:IO:Mz3Truncated','Declared MZ3 arrays exceed file length.'); end
layers=0;
if hasScalar
    layers=(total-base)/(nv*width);
    if layers<1 || layers~=fix(layers)
        error('BNV:IO:Mz3Scalars','MZ3 scalar data must contain complete nonempty vertex layers.');
    end
    if layers>options.MaxScalarLayers, error('BNV:IO:Mz3ResourceLimit','MZ3 exceeds MaxScalarLayers.'); end
elseif total~=base
    error('BNV:IO:Mz3TrailingData','Unexpected bytes after MZ3 geometry/color arrays.');
end
fseek(file,16+skip,'bof');
faces=reshape(numbers(3*nf,'uint32'),3,[]).';
if any(faces>=nv,'all'), error('BNV:IO:InvalidFaceIndex','MZ3 indices must lie in the zero-based vertex range.'); end
coordinates=reshape(numbers(3*nv,'single'),3,[]);
if any(~isfinite(coordinates),'all'), error('BNV:IO:NonFiniteValue','MZ3 coordinates must be finite.'); end
attributes=struct('RGBA',zeros(0,4,'uint8'),'Scalars',zeros(nv,0));
if hasColor, attributes.RGBA=uint8(reshape(numbers(4*nv,'uint8'),4,[]).'); end
if hasScalar
    attributes.Scalars=reshape(numbers(nv*layers,precision),nv,layers);
    if any(isinf(attributes.Scalars),'all')
        error('BNV:IO:Mz3Scalars','MZ3 scalars may be finite or NaN, but not infinite.');
    end
end
info=struct('format','mz3','encoding',encoding,'byte_order','little','attribute_flags',attr, ...
    'vertex_count',nv,'face_count',nf,'skip_bytes',skip,'decoded_bytes',total, ...
    'has_vertex_rgba',hasColor,'scalar_layer_count',layers,'scalar_precision',precision, ...
    'scalar_nan_count',nnz(isnan(attributes.Scalars)),'index_base_on_disk',0,'index_base_in_memory',1, ...
    'appearance_policy','RGBA and scalar arrays validated, not applied; optional third output contains arrays', ...
    'coordinate_policy','As stored; no registration, unit conversion, reflection or winding change', ...
    'private_header_policy','Skipped as opaque bytes; not executed or interpreted');
if ~hasScalar, info.scalar_precision='none'; end
surface=brainnet.io.SurfaceData(coordinates,faces+1,reference,Metadata=info);

    function value=numbers(count,precision)
        [value,actual]=fread(file,count,precision);
        if actual~=count, error('BNV:IO:Mz3Truncated','Incomplete MZ3 numeric array.'); end
    end
end

function release(file,output,input,stream,channel,temporary)
if file>=0, fclose(file); end
if output>=0, fclose(output); end
for item={channel,stream,input}
    if ~isempty(item{1})
        try
            item{1}.close();
        catch
            % Cleanup must retain the original decoding failure.
        end
    end
end
if strlength(temporary)>0 && isfile(temporary), delete(temporary); end
end
