function [surface, info] = readFreeSurferSurface(reference, rootPath, options)
%READFREESURFERSURFACE Independent big-endian triangle/quad geometry reader.
% Coordinates remain as stored, normally FreeSurfer surface RAS in mm.
% Volume geometry and other trailing tags are not interpreted or applied.
% Format references and splitting decision: docs/architecture/T1.8D1_*.md.
arguments
    reference (1,1) brainnet.core.InputReference
    rootPath (1,1) string
    options.MaxVertices (1,1) double {mustBeInteger,mustBePositive,mustBeFinite} = 10000000
    options.MaxFaces (1,1) double {mustBeInteger,mustBePositive,mustBeFinite} = 20000000
end
path = brainnet.io.internal.resolveAndVerify(reference, rootPath, "surface");
file = fopen(path, 'rb', 'ieee-be');
if file < 0, error('BNV:IO:InputOpenFailed', 'Cannot open FreeSurfer surface.'); end
cleanup = onCleanup(@() fclose(file));
fseek(file,0,'eof'); fileBytes = ftell(file); fseek(file,0,'bof');
magic = readUint24(file,1);
stamp = ''; removed = 0;
switch magic
    case 16777214
        format = 'triangle';
        stamp = readHeaderLine(file);
        readHeaderLine(file);
        counts = readExact(file,2,'int32');
        vertices = counts(1); polygons = counts(2);
        vertexBytes = 12; faceBytes = 12; outputFaces = polygons;
    case {16777215,16777213}
        counts = readUint24(file,2);
        vertices = counts(1); polygons = counts(2);
        vertexBytes = 12; faceBytes = 12; outputFaces = 2*polygons;
        format = 'quad-float32';
        if magic == 16777215
            vertexBytes = 6; format = 'quad-int16';
        end
    otherwise
        error('BNV:IO:FreeSurferMagic', ...
            'Unrecognized FreeSurfer geometry signature. ASCII, patch and compressed files are not supported.');
end
if vertices < 1 || polygons < 1 || vertices > options.MaxVertices || outputFaces > options.MaxFaces
    error('BNV:IO:FreeSurferCounts', 'Invalid or excessive FreeSurfer vertex/face counts.');
end
geometryBytes = vertices*vertexBytes + polygons*faceBytes;
if geometryBytes > fileBytes-ftell(file)
    error('BNV:IO:FreeSurferTruncated', 'FreeSurfer geometry is shorter than its declared counts.');
end
if magic == 16777215
    coordinates = reshape(readExact(file,3*vertices,'int16'),3,vertices)/100;
else
    coordinates = reshape(readExact(file,3*vertices,'single'),3,vertices);
end
if magic == 16777214
    faces = reshape(readExact(file,3*polygons,'int32'),3,polygons).';
else
    quads = reshape(readUint24(file,4*polygons),4,polygons).';
    if any(quads < 0 | quads >= vertices,'all')
        error('BNV:IO:InvalidFaceIndex', 'FreeSurfer quad index is outside the vertex range.');
    end
    % FreeSurfer mrisurf_aaa.h WHICH_FACE_SPLIT + mrisurf_io.cpp.
    % Unlike NiBabel's historical first-index parity, this uses both IDs.
    evenSplit = mod(floor(sqrt(1.9*quads(:,1)) + sqrt(3.5*quads(:,2)) + 0.5),2) == 0;
    first = quads(:,[1 2 3]); second = quads(:,[1 3 4]);
    first(evenSplit,:) = quads(evenSplit,[1 2 4]);
    second(evenSplit,:) = quads(evenSplit,[3 4 2]);
    faces = zeros(outputFaces,3);
    faces(1:2:end,:) = first; faces(2:2:end,:) = second;
    % Official writers can encode a triangle as a degenerate quad.
    degenerate = faces(:,1)==faces(:,2) | faces(:,1)==faces(:,3) | faces(:,2)==faces(:,3);
    removed = nnz(degenerate); faces(degenerate,:) = [];
end
info = struct('format','freesurfer-surface','encoding',format,'magic',magic, ...
    'vertex_count',vertices,'input_polygon_count',polygons,'face_count',size(faces,1), ...
    'index_base_on_disk',0,'index_base_in_memory',1,'creation_stamp',stamp, ...
    'coordinate_policy','as-stored; no registration or axis change', ...
    'coordinate_note','Normally surface RAS (mm), not MNI; verify registration before combining data.', ...
    'trailing_bytes',fileBytes-ftell(file), ...
    'trailing_policy','Volume geometry and trailing tags are not interpreted or applied.', ...
    'quad_split','FreeSurfer WHICH_FACE_SPLIT using both zero-based vertex IDs', ...
    'degenerate_quad_triangles_removed',removed);
surface = brainnet.io.SurfaceData(coordinates,faces+1,reference,Metadata=info);
end

function value = readExact(file,count,type)
[value,actual] = fread(file,count,type);
if actual ~= count
    error('BNV:IO:FreeSurferTruncated', 'FreeSurfer file ends inside a required field.');
end
end

function value = readUint24(file,count)
bytes = reshape(readExact(file,3*count,'uint8'),3,count);
value = ([65536 256 1]*bytes).';
end

function line = readHeaderLine(file)
% Bounded scan: never search an arbitrary-size corrupt binary file for LF.
bytes = fread(file,4096,'*uint8');
ending = find(bytes==10,1);
if isempty(ending)
    error('BNV:IO:FreeSurferHeader', 'FreeSurfer header line is missing or exceeds 4096 bytes.');
end
fseek(file,ending-numel(bytes),'cof');
line = native2unicode(bytes(1:ending-1).','UTF-8');
end
