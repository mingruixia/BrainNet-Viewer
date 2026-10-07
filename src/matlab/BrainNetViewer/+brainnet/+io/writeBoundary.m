function report=writeBoundary(scene,prepared,destination,dataRoot)
%WRITEBOUNDARY Save the configured full-resolution boundary as a new binary map.
arguments
    scene (1,1) brainnet.core.Scene
    prepared (1,1) brainnet.render.PreparedScene
    destination (1,1) string
    dataRoot (1,1) string
end
settings=scene.Options.section('surface');
if string(settings.boundary_mode)=="none"
    error('BNV:Boundary:Mode','Enable a surface boundary mode before saving.');
end
if (isempty(prepared.SurfaceValues) && ~strcmp(settings.boundary_mode,'custom')) || prepared.VertexCount==0
    error('BNV:Boundary:MissingMap','A surface with prepared per-vertex values is required.');
end
planner=brainnet.render.RenderPlanner(AlgorithmVersion=prepared.AlgorithmVersion);
keys=strings(1,3); backends=["auto","cpu","gpu"];
for k=1:3, keys(k)=planner.keyFor(scene,ComputeBackend=backends(k)); end
if ~any(keys==prepared.CacheKey)
    error('BNV:Boundary:StalePrepared','Prepared data do not match the Scene. Render again before saving.');
end
destination=string(char(java.io.File(char(destination)).getCanonicalPath()));
[folder,~,ext]=fileparts(destination);
if ~strcmpi(ext,'.txt'), error('BNV:Boundary:OutputFormat','Save boundary masks as a new .txt file.'); end
if ~isfolder(folder), error('BNV:Boundary:OutputFolder','The output folder must already exist.'); end
if isfile(destination) || isfolder(destination)
    error('BNV:Boundary:OutputExists','Output exists. Choose a new filename; overwriting is disabled.');
end
% Re-read to verify main files and bind external arrays to the prepared geometry.
data=struct();
dependencies=struct('path',{},'sha256',{});
for k=1:numel(scene.Inputs)
    input=scene.Inputs{k}; data.(char(input.Role))=brainnet.io.readInput(input,dataRoot);
    value=data.(char(input.Role));
    if isa(value,'brainnet.io.GiftiData')
        for j=1:numel(value.DataArrays)
            a=value.DataArrays{j};
            if strlength(a.ExternalFileName)>0
                dependencies(end+1)=struct('path',char(fullfile(fileparts(input.resolve(dataRoot)),a.ExternalFileName)), ...
                    'sha256',char(a.ExternalFileSha256)); %#ok<AGROW>
            end
        end
    elseif isa(value,'brainnet.io.VolumeData') && value.Header.IsPair
        dependencies(end+1)=struct('path',char(fullfile(dataRoot,value.Header.HeaderRelativePath)), ...
            'sha256',char(value.Header.HeaderSha256)); %#ok<AGROW>
        dependencies(end+1)=struct('path',char(fullfile(dataRoot,value.Header.DataRelativePath)), ...
            'sha256',char(value.Header.DataSha256)); %#ok<AGROW>
    end
end
coordinates=data.surface.Coordinates;
if isa(data.surface,'brainnet.io.GiftiData'), coordinates=coordinates.'; end
if ~isequal(coordinates,prepared.SurfaceCoordinates) || ~isequal(data.surface.Faces,prepared.SurfaceFaces)
    error('BNV:Boundary:ChangedGeometry','Surface geometry changed since preparation. Reload and render again.');
end
fresh=planner.prepare(scene,data,ComputeBackend=backends(find(keys==prepared.CacheKey,1)));
if ~isequaln(fresh.SurfaceValues,prepared.SurfaceValues)
    error('BNV:Boundary:ChangedValues','Prepared map values changed. Reload and render again.');
end
result=brainnet.render.internal.configuredBoundary(prepared,settings);
if strcmp(settings.boundary_mode,'automatic')
    semantics='finite class-transition endpoints including zero-valued vertices';
elseif strcmp(settings.boundary_mode,'custom')
    semantics='explicit binary mask bound to the original ordered geometry';
else
    semantics='legacy mixed-triangle vertex mask with original zero-valued vertices removed';
end
report=struct('kind','brainnet-surface-boundary','schema_version','1.0', ...
    'algorithm',result.algorithm,'classification',result.classification, ...
    'semantics',semantics,'mode',settings.boundary_mode,'threshold',settings.boundary_threshold, ...
    'vertex_order','original input surface; before hemisphere splitting and display LOD', ...
    'vertices',prepared.VertexCount,'boundary_vertices',nnz(result.mask), ...
    'transition_edges',size(result.edges,1),'transition_edges_computed',strcmp(settings.boundary_mode,'automatic'), ...
    'missing_vertices',result.missing_vertices, ...
    'coordinates_sha256',char(brainnet.io.internal.numericSha256(prepared.SurfaceCoordinates)), ...
    'faces_sha256',char(brainnet.io.internal.numericSha256(prepared.SurfaceFaces)), ...
    'values_sha256',char(brainnet.io.internal.numericSha256(prepared.SurfaceValues)), ...
    'prepared_cache_key',char(prepared.CacheKey),'scene',scene.toStruct(),'dependencies',dependencies);
temporary=string(tempname(folder))+".txt";
cleanup=onCleanup(@() removeTemporary(temporary));
file=fopen(temporary,'w','n','UTF-8');
if file<0, error('BNV:Boundary:WriteFailed','Cannot create a temporary boundary file.'); end
try
    fprintf(file,'# BrainNet Viewer full-resolution surface boundary\n# %s\n',jsonencode(report));
    fprintf(file,'%d\n',result.mask);
    [message,number]=ferror(file); status=fclose(file); file=-1;
    if number~=0 || status~=0, error('BNV:Boundary:WriteFailed','Cannot finish writing boundary: %s',message); end
catch failure
    if file>=0, fclose(file); end
    rethrow(failure);
end
[~,name,extension]=fileparts(temporary);
restored=brainnet.io.readSurfaceMap(brainnet.core.InputReference('surface_map',name+extension),folder);
if ~isequal(restored,double(result.mask)), error('BNV:Boundary:Roundtrip','Boundary read-back failed.'); end
for k=1:numel(scene.Inputs)
    input=scene.Inputs{k}; brainnet.io.internal.resolveAndVerify(input,dataRoot,input.Role);
end
for k=1:numel(dependencies)
    d=dependencies(k);
    if ~isfile(d.path) || brainnet.io.internal.sha256File(d.path)~=string(d.sha256)
        error('BNV:Boundary:ChangedDependency','An external input changed during export. Reload and render again.');
    end
end
try
    java.nio.file.Files.move(java.io.File(char(temporary)).toPath(), ...
        java.io.File(char(destination)).toPath(),javaArray('java.nio.file.CopyOption',0));
catch failure
    error('BNV:Boundary:PublishFailed','Cannot publish without overwriting: %s',failure.message);
end
report.output_path=char(destination); report.output_sha256=char(brainnet.io.internal.sha256File(destination));
end
function removeTemporary(path)
if isfile(path), delete(path); end
end
