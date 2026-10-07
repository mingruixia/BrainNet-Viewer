classdef AtlasNodePlan
    %ATLASNODEPLAN Review a label atlas, then publish a NEW node file safely.
    properties (SetAccess=private)
        Values double
        Labels string
        Report struct
    end
    methods
        function obj=AtlasNodePlan(path,options)
            arguments
                path (1,1) string
                options.Regions double=[]
                options.Module (1,1) double=0
                options.Size (1,1) double=0
            end
            path=string(char(java.io.File(char(path)).getCanonicalPath()));
            [folder,name,ext]=fileparts(path);
            if ~isfile(path), error('BNV:AtlasNodes:MissingInput','Choose an existing NIfTI label atlas.'); end
            reference=brainnet.core.InputReference('volume',name+ext,Sha256=brainnet.io.internal.sha256File(path));
            volume=brainnet.io.readNifti(reference,folder);
            [obj.Values,obj.Labels,obj.Report]=brainnet.tools.atlasNodes(volume, ...
                Regions=options.Regions,Module=options.Module,Size=options.Size);
            h=volume.Header;
            paths=unique([fullfile(folder,string(h.HeaderRelativePath)),fullfile(folder,string(h.DataRelativePath))],'stable');
            sources=repmat(struct('path','','sha256',''),1,numel(paths));
            for k=1:numel(paths)
                file=string(char(java.io.File(char(paths(k))).getCanonicalPath()));
                hash=h.HeaderSha256; if file~=string(char(java.io.File(char(fullfile(folder,string(h.HeaderRelativePath)))).getCanonicalPath())), hash=h.DataSha256; end
                sources(k)=struct('path',char(file),'sha256',char(hash));
            end
            obj.Report.sources=sources; obj.verifyInputs();
        end
        function report=write(obj,destination,options)
            arguments
                obj (1,1) brainnet.tools.AtlasNodePlan
                destination (1,1) string
                options.CoordinateSpace (1,1) string=""
                options.Units (1,1) string=""
                options.Confirmed (1,1) logical=false
            end
            declaration=strtrim([options.CoordinateSpace options.Units]);
            if ~options.Confirmed || any(strlength(declaration)==0) || any(ismember(lower(declaration),["unknown","unverified"]))
                error('BNV:AtlasNodes:ConfirmationRequired','Review the atlas, declare the affine coordinate space and units, then confirm before saving. No conversion to MNI or mm is inferred.');
            end
            destination=string(char(java.io.File(char(destination)).getCanonicalPath()));
            [folder,~,ext]=fileparts(destination);
            if ~strcmpi(ext,'.node'), error('BNV:AtlasNodes:OutputFormat','Choose a new .node filename.'); end
            if ~isfolder(folder), error('BNV:AtlasNodes:OutputFolder','The output folder must already exist.'); end
            if isfile(destination) || isfolder(destination), error('BNV:AtlasNodes:OutputExists','Output exists. Choose a new filename; overwrite is disabled.'); end
            obj.verifyInputs(); report=obj.Report;
            report.coordinate_space=char(declaration(1)); report.units=char(declaration(2));
            report.created_utc=char(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss'Z'"));
            temporary=string(tempname(folder))+".node";
            cleanup=onCleanup(@() removeTemporary(temporary));
            fid=fopen(temporary,'w','n','UTF-8');
            if fid<0, error('BNV:AtlasNodes:WriteFailed','Cannot create temporary node output.'); end
            try
                fprintf(fid,'# BrainNet Viewer atlas nodes; provenance JSON follows.\n');
                fprintf(fid,'# %s\n',jsonencode(report));
                for k=1:numel(obj.Labels)
                    fprintf(fid,'%.17g %.17g %.17g %.17g %.17g %s\n',obj.Values(k,:),char(obj.Labels(k)));
                end
                [message,number]=ferror(fid); status=fclose(fid); fid=-1;
                if number~=0 || status~=0, error('BNV:AtlasNodes:WriteFailed','Cannot finish node output: %s',message); end
            catch failure
                if fid>=0, fclose(fid); end
                rethrow(failure);
            end
            [~,name,extension]=fileparts(temporary);
            restored=brainnet.io.readNodes(brainnet.core.InputReference('node',name+extension),folder);
            if ~isequal(restored.Values,obj.Values) || ~isequal(restored.Labels,obj.Labels)
                error('BNV:AtlasNodes:RoundtripFailed','Node output failed exact read-back validation.');
            end
            obj.verifyInputs();
            try
                java.nio.file.Files.move(java.io.File(char(temporary)).toPath(), ...
                    java.io.File(char(destination)).toPath(),javaArray('java.nio.file.CopyOption',0));
            catch failure
                error('BNV:AtlasNodes:PublishFailed','Cannot publish a NEW node file: %s',failure.message);
            end
            report.output_path=char(destination); report.output_sha256=char(brainnet.io.internal.sha256File(destination));
        end
        function verifyInputs(obj)
            for source=obj.Report.sources
                if ~isfile(source.path) || brainnet.io.internal.sha256File(source.path)~=string(source.sha256)
                    error('BNV:AtlasNodes:InputChanged','Atlas/header/image changed after review. Review the input again.');
                end
            end
        end
    end
end

function removeTemporary(path)
if isfile(path), delete(path); end
end
