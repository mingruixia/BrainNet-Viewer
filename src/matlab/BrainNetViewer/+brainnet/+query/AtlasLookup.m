classdef AtlasLookup
    %ATLASLOOKUP Bounded nearest-voxel lookup in an explicitly declared frame.
    methods (Static)
        function atlas=builtin(name)
            persistent cachedName cachedAtlas
            name=string(name);
            if isequal(name,cachedName), atlas=cachedAtlas; return; end
            root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
            switch name
                case "aal"
                    path=fullfile(root,'BrainNet_AAL_Label.mat');
                    expected="1fe217ef443cff395884e3c5f672891085cb10858a028048b454d02591316ec9";
                    assertHash(path,expected);
                    % Select numeric/cell variables only: never load SPM objects.
                    d=load(path,'AAL_vol','AAL_label'); data=d.AAL_vol;
                    labels=struct('id',num2cell((1:numel(d.AAL_label)).'),'name',d.AAL_label(:));
                case "brodmann"
                    path=fullfile(root,'BrainNet_Brodmann_Label.mat');
                    expected="ed057cd513391e3aefae46e4ade5dea5b23b72da5b7cdb0064b7ebb44f347f8e";
                    assertHash(path,expected);
                    d=load(path,'Brodmann_vol'); data=d.Brodmann_vol;
                    ids=unique(double(data(:))); ids=ids(ids>0);
                    labels=struct('id',num2cell(ids),'name',cellstr("Brodmann Area "+string(ids)));
                otherwise
                    error('BNV:Query:UnknownAtlas','Choose AAL or Brodmann.');
            end
            % One-based voxel affine verified against both frozen MAT headers.
            atlas=struct('data',data,'affine',[1 0 0 -91;0 1 0 -126;0 0 1 -72;0 0 0 1], ...
                'labels',labels,'name',char(name),'source',path,'sha256',char(expected));
            cachedName=name; cachedAtlas=atlas;
        end
        function result=sample(atlas,point,transform)
            arguments
                atlas (1,1) struct
                point (1,3) double {mustBeFinite,mustBeReal}
                transform (4,4) double {mustBeFinite,mustBeReal}
            end
            if ~isequal(transform(4,:),[0 0 0 1]) || rcond(transform(1:3,1:3))<1e-12
                error('BNV:Query:InvalidTransform','Scene-to-atlas affine must be invertible and non-projective.');
            end
            if ~isnumeric(atlas.data) || ~isreal(atlas.data) || isempty(atlas.data)
                error('BNV:Query:InvalidAtlas','Atlas must contain a real, nonempty numeric label array.');
            end
            result=struct('status','outside','value',[],'label_id',[],'label','', ...
                'atlas_coordinate',[],'voxel_1based',[],'name',atlas.name, ...
                'source',atlas.source,'sha256',atlas.sha256,'method','nearest voxel; no interpolation');
            affine=atlas.affine;
            if ~isequal(size(affine),[4 4]) || any(~isfinite(affine),'all') || ...
                    ~isequal(affine(4,:),[0 0 0 1]) || rcond(affine(1:3,1:3))<1e-12
                error('BNV:Query:InvalidAffine','Atlas voxel-to-world affine is singular or invalid.');
            end
            if ndims(atlas.data)>3
                error('BNV:Query:MultiFrameAtlas','Atlas queries require one 3-D label volume, not multiple frames.');
            end
            world=transform*[point(:);1]; voxel=affine\world;
            result.atlas_coordinate=world(1:3).';
            index=round(voxel(1:3).'); result.voxel_1based=index;
            dimensions=[size(atlas.data,1) size(atlas.data,2) size(atlas.data,3)];
            if any(~isfinite(index)) || any(index<1 | index>dimensions), return; end
            value=double(atlas.data(index(1),index(2),index(3))); result.value=value;
            if ~isfinite(value), result.status='missing'; return; end
            if value==0, result.status='background'; return; end
            if value<0 || value~=fix(value), result.status='not-a-label'; return; end
            result.label_id=value; result.status='label-id-only';
            row=find([atlas.labels.id]==value,1);
            if ~isempty(row), result.label=atlas.labels(row).name; result.status='label'; end
        end
    end
end

function assertHash(path,expected)
if ~isfile(path) || brainnet.io.internal.sha256File(path)~=expected
    error('BNV:Query:AtlasIntegrity','Bundled atlas differs from the verified resource; lookup was stopped.');
end
end
