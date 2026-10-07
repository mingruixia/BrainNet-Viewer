function [surface, info] = readBrainVisaMesh(reference, rootPath, options)
%READBRAINVISAMESH Independent AIMS ASCII/binary triangle geometry reader.
% Single time step, VOID texture; coordinates retained, MINF not applied.
arguments
    reference (1,1) brainnet.core.InputReference
    rootPath (1,1) string
    options.MaxVertices (1,1) double {mustBeInteger,mustBePositive,mustBeFinite} = 10000000
    options.MaxFaces (1,1) double {mustBeInteger,mustBePositive,mustBeFinite} = 20000000
end
path = brainnet.io.internal.resolveAndVerify(reference,rootPath,"surface");
file = fopen(path,'rb');
if file<0, error('BNV:IO:InputOpenFailed','Cannot open BrainVISA mesh.'); end
cleanup = onCleanup(@() fclose(file));
fseek(file,0,'eof'); total = ftell(file); fseek(file,0,'bof');
mode = char(exact(file,5,'*char').'); endian = 'native';
switch mode
    case 'binar'
        order = char(exact(file,4,'*char').');
        switch order
            case 'ABCD', endian = 'ieee-be';
            case 'DCBA', endian = 'ieee-le';
            otherwise, error('BNV:IO:BrainVisaHeader','Invalid BrainVISA byte order marker.');
        end
        length = number();
        if length~=4, error('BNV:IO:BrainVisaTexture','Only VOID mesh textures are supported.'); end
        texture = char(exact(file,4,'*char').');
    case 'ascii'
        texture = asciiTexture(file);
    otherwise
        error('BNV:IO:BrainVisaHeader','Not an ASCII/binary BrainVISA mesh; Medit .mesh is not supported.');
end
if ~strcmp(texture,'VOID')
    error('BNV:IO:BrainVisaTexture','Only VOID mesh textures are supported.');
end
dimension = number(); steps = number();
if dimension~=3
    error('BNV:IO:BrainVisaPolygons','Only triangular BrainVISA meshes are supported.');
end
if steps~=1
    error('BNV:IO:BrainVisaTimeSteps','Exactly one time step is required; no frame is selected silently.');
end
instant = number(); vertices = number();
if vertices<1 || vertices>options.MaxVertices
    error('BNV:IO:BrainVisaCounts','Invalid or excessive BrainVISA vertex count.');
end
coordinates = tuples(vertices,false);
normalCount = number();
if normalCount~=0 && normalCount~=vertices
    error('BNV:IO:BrainVisaNormals','Normal count must be zero or equal to the vertex count.');
end
normals = tuples(normalCount,false);
if any(~isfinite(normals),'all')
    error('BNV:IO:NonFiniteValue','BrainVISA normals must be finite.');
end
if number()~=0
    error('BNV:IO:BrainVisaTexture','Embedded mesh texture vectors are not supported.');
end
faceCount = number();
if faceCount<1 || faceCount>options.MaxFaces
    error('BNV:IO:BrainVisaCounts','Invalid or excessive BrainVISA face count.');
end
faces = tuples(faceCount,true).';
if any(faces<0 | faces>4294967295 | faces~=fix(faces),'all')
    error('BNV:IO:InvalidFaceIndex','BrainVISA face indices must be unsigned integers.');
end
if strcmp(mode,'ascii')
    % Only whitespace may follow the one declared frame. Check in chunks.
    while ~feof(file)
        tail = fread(file,4096,'*char');
        if any(~isspace(tail))
            error('BNV:IO:BrainVisaTrailingData','Unexpected trailing mesh data.');
        end
    end
elseif ftell(file)~=total
    error('BNV:IO:BrainVisaTrailingData','Unexpected trailing binary mesh data.');
end
info = struct('format','brainvisa-mesh','encoding',mode,'byte_order',endian, ...
    'vertex_count',vertices,'face_count',faceCount,'normal_count',normalCount, ...
    'time_step_count',steps,'time_instant',instant,'polygon_dimension',dimension, ...
    'index_base_on_disk',0,'index_base_in_memory',1, ...
    'coordinate_policy','As stored; no registration, reflection or MINF transform', ...
    'normal_policy','Validated but renderer recomputes display normals', ...
    'minf_present',isfile(path+".minf"), ...
    'minf_policy','Sidecar is not interpreted, executed or applied');
surface = brainnet.io.SurfaceData(coordinates,faces+1,reference,Metadata=info);

    function value = number()
        if strcmp(mode,'ascii')
            [value,count] = fscanf(file,' %f',1);
        else
            [value,count] = fread(file,1,'uint32',0,endian);
        end
        if count~=1
            error('BNV:IO:BrainVisaTruncated','Missing or malformed BrainVISA count.');
        end
        if ~isfinite(value) || value<0 || value>4294967295 || value~=fix(value)
            error('BNV:IO:BrainVisaCounts','BrainVISA counts must be unsigned 32-bit integers.');
        end
    end

    function value = tuples(count,isIndex)
        bytesPerTuple = 12;
        if strcmp(mode,'ascii'), bytesPerTuple = 7; end
        if count*bytesPerTuple>total-ftell(file)
            error('BNV:IO:BrainVisaTruncated','Declared mesh array exceeds the remaining file length.');
        end
        if count==0, value = zeros(3,0); return; end
        start = ftell(file);
        if strcmp(mode,'ascii')
            [value,actual] = fscanf(file,' (%f ,%f ,%f) ',[3,count]);
        else
            type = 'single';
            if isIndex, type = 'uint32'; end
            [value,actual] = fread(file,[3,count],type,0,endian);
        end
        if actual~=3*count
            error('BNV:IO:BrainVisaTruncated','Incomplete or malformed BrainVISA mesh array.');
        end
        if strcmp(mode,'ascii'), requireClosingParenthesis(file,start); end
        % AIMS FLOAT coordinates/normals use float32 in both encodings.
        if ~isIndex, value = double(single(value)); end
    end
end

function value = exact(file,count,type)
[value,actual] = fread(file,count,type);
if actual~=count
    error('BNV:IO:BrainVisaTruncated','BrainVISA header is truncated.');
end
end

function value = asciiTexture(file)
% Bounded token scan avoids fscanf string-size repetition semantics.
for offset = 1:4096
    first = exact(file,1,'*char');
    if ~isspace(first)
        value = [first,reshape(exact(file,3,'*char'),1,[])];
        separator = exact(file,1,'*char');
        if ~isspace(separator)
            error('BNV:IO:BrainVisaTexture','Invalid or unsupported ASCII texture token.');
        end
        return;
    end
end
error('BNV:IO:BrainVisaHeader','ASCII texture header exceeds 4096 whitespace bytes.');
end

function requireClosingParenthesis(file,start)
% fscanf may complete its numeric count even if the final literal is absent.
finish = ftell(file); cursor = finish; closed = false;
while cursor>start
    count = min(4096,cursor-start);
    fseek(file,cursor-count,'bof'); tail = fread(file,count,'*char');
    last = find(~isspace(tail),1,'last');
    if ~isempty(last), closed = tail(last)==')'; break; end
    cursor = cursor-count;
end
fseek(file,finish,'bof');
if ~closed
    error('BNV:IO:BrainVisaSyntax','Mesh tuple is missing its closing parenthesis.');
end
end
