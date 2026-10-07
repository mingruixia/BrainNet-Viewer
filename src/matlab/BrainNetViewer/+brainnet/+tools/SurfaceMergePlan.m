classdef SurfaceMergePlan
    %SURFACEMERGEPLAN Reviewed geometry merge or single-file conversion.
    properties (SetAccess=private)
        Coordinates double
        Faces double
        Report struct
    end
    methods
        function obj=SurfaceMergePlan(paths,options)
            arguments
                paths string
                options.Operation (1,1) string {mustBeMember(options.Operation,["merge","convert"])}="merge"
                options.MaxVertices (1,1) double {mustBeInteger,mustBePositive}=5000000
                options.MaxFaces (1,1) double {mustBeInteger,mustBePositive}=10000000
            end
            paths=paths(:);
            converting=options.Operation=="convert";
            if converting && numel(paths)~=1
                error('BNV:Merge:InputCount','Select exactly one surface to convert.');
            elseif ~converting && (numel(paths)<2 || numel(paths)>64)
                error('BNV:Merge:InputCount','Select 2 to 64 surface files.');
            end
            for k=1:numel(paths)
                paths(k)=string(char(java.io.File(char(paths(k))).getCanonicalPath()));
                if ~isfile(paths(k)), error('BNV:Merge:MissingInput','Surface file not found: %s',paths(k)); end
            end
            identity=paths; if ispc, identity=lower(identity); end
            if numel(unique(identity))~=numel(paths)
                error('BNV:Merge:DuplicateInput','The same file cannot be included twice.');
            end
            coordinates=cell(numel(paths),1); faces=coordinates; components=coordinates;
            vertexOffset=0; faceOffset=0;
            for k=1:numel(paths)
                [folder,name,extension]=fileparts(paths(k));
                hash=brainnet.io.internal.sha256File(paths(k));
                reference=brainnet.core.InputReference('surface',name+extension,Sha256=hash);
                surface=brainnet.tools.SurfaceMergePlan.read(reference,folder);
                c=surface.Coordinates; f=surface.Faces;
                dependencies=struct('path',{},'sha256',{}); nativeMetadata=struct();
                if isa(surface,'brainnet.io.GiftiData')
                    c=c.'; nativeMetadata.coordinate_systems=surface.CoordinateSystems;
                    for a=1:numel(surface.DataArrays)
                        array=surface.DataArrays{a};
                        if strlength(array.ExternalFileName)>0
                            dep=string(char(java.io.File(char(fullfile(folder,array.ExternalFileName))).getCanonicalPath()));
                            dependencies(end+1)=struct('path',char(dep),'sha256',char(array.ExternalFileSha256)); %#ok<AGROW>
                        end
                    end
                elseif isprop(surface,'Metadata')
                    nativeMetadata=surface.Metadata;
                end
                nv=size(c,2); nf=size(f,1);
                if vertexOffset+nv>options.MaxVertices || faceOffset+nf>options.MaxFaces
                    error('BNV:Merge:ResourceLimit','Combined mesh exceeds the configured vertex or face limit.');
                end
                if ~isreal(c) || ~isreal(f)
                    error('BNV:Merge:InvalidGeometry','Geometry must be real-valued.');
                end
                coordinates{k}=c; faces{k}=f+vertexOffset;
                components{k}=struct('path',char(paths(k)),'sha256',char(hash), ...
                    'vertices',nv,'faces',nf,'vertex_range',[vertexOffset+1 vertexOffset+nv], ...
                    'face_range',[faceOffset+1 faceOffset+nf],'bounds',[min(c,[],2) max(c,[],2)].', ...
                    'dependencies',dependencies,'native_metadata',nativeMetadata);
                vertexOffset=vertexOffset+nv; faceOffset=faceOffset+nf;
            end
            obj.Coordinates=cat(2,coordinates{:}); obj.Faces=cat(1,faces{:});
            obj.Report=struct('kind','brainnet-surface-merge','schema_version','1.0', ...
                'operation','concatenate; no transforms, welding, repair or attribute transfer', ...
                'coordinate_space','unknown','units','unknown','confirmation_note','', ...
                'vertices',vertexOffset,'faces',faceOffset,'components',{components});
            if converting
                obj.Report.kind='brainnet-surface-conversion';
                obj.Report.operation='geometry-only conversion; raw coordinates and triangle order retained; no transforms or attribute transfer';
            end
            obj.verifyInputs();
        end
        function report=write(obj,destination,options)
            arguments
                obj (1,1) brainnet.tools.SurfaceMergePlan
                destination (1,1) string
                options.CoordinateSpace (1,1) string=""
                options.Units (1,1) string=""
                options.Note (1,1) string=""
                options.Confirmed (1,1) logical=false
            end
            converting=strcmp(obj.Report.kind,'brainnet-surface-conversion');
            if converting && ~options.Confirmed
                error('BNV:Merge:ConfirmationRequired','Review and confirm geometry-only conversion; colors, maps and active transforms are not transferred to NV.');
            end
            destination=string(char(java.io.File(char(destination)).getCanonicalPath()));
            [folder,~,extension]=fileparts(destination);
            if ~strcmpi(extension,'.nv'), error('BNV:Merge:OutputFormat','Save the surface as a new .nv file.'); end
            if ~isfolder(folder), error('BNV:Merge:OutputFolder','The output folder must already exist.'); end
            if isfile(destination) || isfolder(destination)
                error('BNV:Merge:OutputExists','The destination already exists. Choose a new filename; overwriting is disabled.');
            end
            obj.verifyInputs();
            report=obj.Report; report.coordinate_space=char(strtrim(options.CoordinateSpace));
            report.units=char(strtrim(options.Units)); report.confirmation_note=char(strtrim(options.Note));
            if isempty(report.coordinate_space), report.coordinate_space='unknown'; end
            if isempty(report.units), report.units='unknown'; end
            report.created_utc=char(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss'Z'"));
            temporary=string(tempname(folder))+".nv";
            cleanup=onCleanup(@() brainnet.tools.SurfaceMergePlan.removeTemporary(temporary));
            file=fopen(temporary,'w','n','UTF-8');
            if file<0, error('BNV:Merge:WriteFailed','Cannot create a temporary output file.'); end
            try
                fprintf(file,'# BrainNet Viewer %s; provenance JSON follows.\n',report.kind);
                fprintf(file,'# %s\n',jsonencode(report));
                fprintf(file,'%d\n',size(obj.Coordinates,2));
                fprintf(file,'%.17g %.17g %.17g\n',obj.Coordinates);
                fprintf(file,'%d\n',size(obj.Faces,1));
                fprintf(file,'%d %d %d\n',obj.Faces.');
                [message,number]=ferror(file); status=fclose(file); file=-1;
                if number~=0 || status~=0, error('BNV:Merge:WriteFailed','Cannot finish writing mesh: %s',message); end
            catch failure
                if file>=0, fclose(file); end
                rethrow(failure);
            end
            [~,name,ext]=fileparts(temporary);
            restored=brainnet.io.readSurface(brainnet.core.InputReference('surface',name+ext),folder);
            if ~isequal(restored.Coordinates,obj.Coordinates) || ~isequal(restored.Faces,obj.Faces)
                error('BNV:Merge:RoundtripFailed','Output geometry did not survive exact read-back validation.');
            end
            obj.verifyInputs();
            % NIO move without REPLACE_EXISTING refuses concurrent destinations.
            try
                java.nio.file.Files.move(java.io.File(char(temporary)).toPath(), ...
                    java.io.File(char(destination)).toPath(),javaArray('java.nio.file.CopyOption',0));
            catch failure
                error('BNV:Merge:PublishFailed','Cannot publish the new output without overwriting: %s',failure.message);
            end
            report.output_path=char(destination);
            report.output_sha256=char(brainnet.io.internal.sha256File(destination));
        end
        function verifyInputs(obj)
            for k=1:numel(obj.Report.components)
                c=obj.Report.components{k};
                sources=[struct('path',c.path,'sha256',c.sha256),c.dependencies];
                for j=1:numel(sources)
                    if ~isfile(sources(j).path) || brainnet.io.internal.sha256File(sources(j).path)~=string(sources(j).sha256)
                        error('BNV:Merge:InputChanged','An input or external array changed. Review all inputs again: %s',sources(j).path);
                    end
                end
            end
        end
    end
    methods (Static,Access=private)
        function value=read(reference,folder)
            path=lower(reference.RelativePath);
            if endsWith(path,'.nv'), value=brainnet.io.readSurface(reference,folder);
            elseif endsWith(path,'.pial'), value=brainnet.io.readFreeSurferSurface(reference,folder);
            elseif endsWith(path,'.mesh'), value=brainnet.io.readBrainVisaMesh(reference,folder);
            elseif endsWith(path,'.g'), value=brainnet.io.readByuSurface(reference,folder);
            elseif endsWith(path,'.obj'), value=brainnet.io.readMniObjSurface(reference,folder);
            elseif any(endsWith(path,[".mz3",".mz3.gz"])), value=brainnet.io.readMz3Surface(reference,folder);
            elseif any(endsWith(path,[".gii",".gii.gz"])), value=brainnet.io.readGifti(reference,folder);
            else, error('BNV:Merge:InputFormat','Unsupported surface format: %s',path);
            end
        end
        function removeTemporary(path)
            if isfile(path), delete(path); end
        end
    end
end
