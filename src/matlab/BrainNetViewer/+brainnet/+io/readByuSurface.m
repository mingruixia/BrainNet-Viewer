function [surface, info] = readByuSurface(reference, rootPath, options)
%READBYUSURFACE Independent MOVIE.BYU ASCII triangle geometry reader.
% All parts are retained in file order. No companion files or transforms.
arguments
    reference (1,1) brainnet.core.InputReference
    rootPath (1,1) string
    options.MaxVertices (1,1) double {mustBeInteger,mustBePositive,mustBeFinite} = 10000000
    options.MaxFaces (1,1) double {mustBeInteger,mustBePositive,mustBeFinite} = 20000000
    options.MaxParts (1,1) double {mustBeInteger,mustBePositive,mustBeFinite} = 100000
end
path = brainnet.io.internal.resolveAndVerify(reference,rootPath,"surface");
file = fopen(path,'rb');
if file<0, error('BNV:IO:InputOpenFailed','Cannot open BYU geometry file.'); end
cleanup = onCleanup(@() fclose(file));
fseek(file,0,'eof'); total = ftell(file); fseek(file,0,'bof');
header = numbers(4);
if any(~isfinite(header) | header<1 | header~=fix(header) | header>2147483647)
    error('BNV:IO:ByuCounts','BYU counts must be positive signed 32-bit integers.');
end
parts = header(1); vertices = header(2); polygons = header(3); entries = header(4);
if parts>options.MaxParts || vertices>options.MaxVertices || polygons>options.MaxFaces || parts>polygons
    error('BNV:IO:ByuCounts','Invalid or excessive BYU part, vertex or polygon count.');
end
if entries~=3*polygons
    error('BNV:IO:ByuPolygons','Only triangle BYU geometry is supported; connectivity count must equal three times polygon count.');
end
% Even one-byte ASCII numbers cannot fit when this bound fails.
if 2*parts+3*vertices+entries>total-ftell(file)
    error('BNV:IO:ByuTruncated','Declared BYU arrays exceed the remaining file length.');
end
ranges = reshape(numbers(2*parts),2,[]).';
if any(~isfinite(ranges) | ranges~=fix(ranges) | ranges<1 | ranges>polygons,'all') || ...
        any(ranges(:,1)>ranges(:,2)) || ranges(1,1)~=1 || ranges(end,2)~=polygons || ...
        any(ranges(2:end,1)~=ranges(1:end-1,2)+1)
    error('BNV:IO:ByuParts','BYU parts must be ordered, nonempty, disjoint polygon ranges covering the complete mesh.');
end
coordinates = reshape(numbers(3*vertices),3,[]);
if any(~isfinite(coordinates),'all')
    error('BNV:IO:NonFiniteValue','BYU coordinates must be finite.');
end
faces = reshape(numbers(entries),3,[]).';
if any(~isfinite(faces) | faces~=fix(faces) | faces==0 | abs(faces)>vertices,'all')
    error('BNV:IO:InvalidFaceIndex','BYU indices must be nonzero integers within the vertex range.');
end
if any(faces(:,1:2)<0,'all') || any(faces(:,3)>0)
    error('BNV:IO:ByuPolygons','Every triangle must end with a negative third index; other polygon sizes are not supported.');
end
faces(:,3) = -faces(:,3);
while ~feof(file)
    tail = fread(file,4096,'*char');
    if any(~isspace(tail))
        error('BNV:IO:ByuTrailingData','Unexpected data after the declared BYU geometry.');
    end
end
info = struct('format','movie-byu','encoding','ascii','part_count',parts, ...
    'part_polygon_ranges',ranges,'vertex_count',vertices,'face_count',polygons, ...
    'connectivity_entry_count',entries,'polygon_dimension',3, ...
    'index_base_on_disk',1,'index_base_in_memory',1, ...
    'part_policy','All parts retained in file order; no part selection or per-part styling', ...
    'coordinate_policy','As stored; no registration, reflection, scaling or displacement', ...
    'companion_policy','Scalar, displacement and texture files are not loaded');
surface = brainnet.io.SurfaceData(coordinates,faces,reference,Metadata=info);

    function value = numbers(count)
        [value,actual] = fscanf(file,' %f',count);
        if actual~=count
            error('BNV:IO:ByuTruncated','Incomplete or malformed BYU numeric array.');
        end
    end
end
