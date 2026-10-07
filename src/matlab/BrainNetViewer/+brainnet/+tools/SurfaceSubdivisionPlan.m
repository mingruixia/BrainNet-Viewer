classdef SurfaceSubdivisionPlan
    %SURFACESUBDIVISIONPLAN Linear triangle refinement with reviewed provenance.
    properties (SetAccess=private)
        Coordinates double
        Faces double
        Report struct
        SourcePlan
    end
    methods
        function obj=SurfaceSubdivisionPlan(path,options)
            arguments
                path (1,1) string
                options.Levels (1,1) double {mustBeInteger,mustBePositive,mustBeLessThanOrEqual(options.Levels,3)}=1
                options.MaxVertices (1,1) double {mustBeInteger,mustBePositive}=5000000
                options.MaxFaces (1,1) double {mustBeInteger,mustBePositive}=10000000
            end
            obj.SourcePlan=brainnet.tools.SurfaceMergePlan(path,Operation="convert",MaxVertices=options.MaxVertices,MaxFaces=options.MaxFaces);
            coordinates=obj.SourcePlan.Coordinates; faces=obj.SourcePlan.Faces;
            initialVertices=size(coordinates,2); initialFaces=size(faces,1);
            counts=zeros(options.Levels,2);
            for level=1:options.Levels
                [coordinates,faces]=refineOnce(coordinates,faces,options.MaxVertices,options.MaxFaces);
                counts(level,:)=[size(coordinates,2),size(faces,1)];
            end
            obj.Coordinates=coordinates; obj.Faces=faces;
            obj.Report=obj.SourcePlan.Report;
            obj.Report.kind='brainnet-surface-subdivision'; obj.Report.schema_version='1.0';
            obj.Report.operation='linear midpoint triangle subdivision; each triangle becomes four; no smoothing, registration, resampling or attribute transfer';
            obj.Report.initial_vertices=initialVertices; obj.Report.initial_faces=initialFaces;
            obj.Report.levels=options.Levels; obj.Report.level_counts=counts;
            obj.Report.vertices=size(coordinates,2); obj.Report.faces=size(faces,1);
        end
        function report=write(obj,destination,options)
            arguments
                obj (1,1) brainnet.tools.SurfaceSubdivisionPlan
                destination (1,1) string
                options.CoordinateSpace (1,1) string=""
                options.Units (1,1) string=""
                options.Note (1,1) string=""
                options.Confirmed (1,1) logical=false
            end
            if ~options.Confirmed
                error('BNV:Subdivision:ConfirmationRequired','Review and confirm linear subdivision. It changes geometry and does not transfer colors, maps or active transforms.');
            end
            destination=string(char(java.io.File(char(destination)).getCanonicalPath()));
            [folder,~,extension]=fileparts(destination);
            if ~strcmpi(extension,'.nv'), error('BNV:Subdivision:OutputFormat','Save the subdivided surface as a new .nv file.'); end
            if ~isfolder(folder), error('BNV:Subdivision:OutputFolder','The output folder must already exist.'); end
            if isfile(destination) || isfolder(destination), error('BNV:Subdivision:OutputExists','Output exists. Choose a new filename; overwrite is disabled.'); end
            obj.SourcePlan.verifyInputs(); report=obj.Report;
            report.coordinate_space=char(strtrim(options.CoordinateSpace)); report.units=char(strtrim(options.Units));
            report.confirmation_note=char(strtrim(options.Note)); report.created_utc=char(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss'Z'"));
            temporary=string(tempname(folder))+".nv"; cleanup=onCleanup(@() removeTemporary(temporary));
            file=fopen(temporary,'w','n','UTF-8');
            if file<0, error('BNV:Subdivision:WriteFailed','Cannot create temporary output.'); end
            try
                fprintf(file,'# BrainNet Viewer surface subdivision; provenance JSON follows.\n'); fprintf(file,'# %s\n',jsonencode(report));
                fprintf(file,'%d\n',size(obj.Coordinates,2)); fprintf(file,'%.17g %.17g %.17g\n',obj.Coordinates);
                fprintf(file,'%d\n',size(obj.Faces,1)); fprintf(file,'%d %d %d\n',obj.Faces.');
                [message,number]=ferror(file); status=fclose(file); file=-1;
                if number~=0 || status~=0, error('BNV:Subdivision:WriteFailed','Cannot finish output: %s',message); end
            catch failure
                if file>=0, fclose(file); end
                rethrow(failure);
            end
            [~,name,ext]=fileparts(temporary); restored=brainnet.io.readSurface(brainnet.core.InputReference('surface',name+ext),folder);
            if ~isequal(restored.Coordinates,obj.Coordinates) || ~isequal(restored.Faces,obj.Faces)
                error('BNV:Subdivision:RoundtripFailed','Subdivided geometry failed exact read-back validation.');
            end
            obj.SourcePlan.verifyInputs();
            try
                java.nio.file.Files.move(java.io.File(char(temporary)).toPath(),java.io.File(char(destination)).toPath(),javaArray('java.nio.file.CopyOption',0));
            catch failure
                error('BNV:Subdivision:PublishFailed','Cannot publish a new output: %s',failure.message);
            end
            report.output_path=char(destination); report.output_sha256=char(brainnet.io.internal.sha256File(destination));
        end
    end
end

function [coordinates,faces]=refineOnce(coordinates,faces,maxVertices,maxFaces)
if 4*size(faces,1)>maxFaces, error('BNV:Subdivision:ResourceLimit','Subdivision exceeds the face limit.'); end
edges=sort([faces(:,[1 2]);faces(:,[2 3]);faces(:,[3 1])],2);
[uniqueEdges,~,map]=unique(edges,'rows','stable');
if size(coordinates,2)+size(uniqueEdges,1)>maxVertices, error('BNV:Subdivision:ResourceLimit','Subdivision exceeds the vertex limit.'); end
midpoints=(coordinates(:,uniqueEdges(:,1))+coordinates(:,uniqueEdges(:,2)))/2;
first=map(1:size(faces,1)); second=map(size(faces,1)+(1:size(faces,1))); third=map(2*size(faces,1)+(1:size(faces,1)));
offset=size(coordinates,2); ab=first+offset; bc=second+offset; ca=third+offset;
faces=[faces(:,1) ab ca;ab faces(:,2) bc;ca bc faces(:,3);ab bc ca];
coordinates=[coordinates midpoints];
end

function removeTemporary(path)
if isfile(path), delete(path); end
end
