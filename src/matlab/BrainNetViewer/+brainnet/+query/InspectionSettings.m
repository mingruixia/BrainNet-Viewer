classdef InspectionSettings
    %INSPECTIONSETTINGS Explicit, input-bound atlas-query registration.
    methods (Static)
        function s=defaults()
            s=struct('version','1.0','atlas','none','source_space','unknown', ...
                'atlas_space','unknown','scene_to_atlas',eye(4),'transform_note','', ...
                'confirmed',false,'input_signature','', ...
                'labels',struct('id',{},'name',{}));
        end
        function s=directMni(scene,atlas)
            arguments
                scene (1,1) brainnet.core.Scene
                atlas (1,1) string {mustBeMember(atlas,["aal","brodmann"])}="aal"
            end
            s=brainnet.query.InspectionSettings.defaults();
            s.atlas=char(atlas);
            s.source_space='MNI (assumed for Inspect)';
            s.atlas_space='MNI (legacy AAL/Brodmann)';
            s.scene_to_atlas=eye(4);
            s.transform_note='Direct MNI lookup; no registration or coordinate transform was performed.';
            s.confirmed=true;
            s.input_signature=char(brainnet.query.InspectionSettings.inputSignature(scene));
            s=brainnet.query.InspectionSettings.validate(s);
        end
        function s=validate(s)
            template=brainnet.query.InspectionSettings.defaults();
            try
                assert(isstruct(s) && isscalar(s) && isequal(sort(fieldnames(s)),sort(fieldnames(template))));
                assert(isequal(s.version,'1.0'));
                for field=["atlas","source_space","atlas_space","transform_note","input_signature"]
                    assert((ischar(s.(field)) && (isrow(s.(field)) || isempty(s.(field)))) || ...
                        (isstring(s.(field)) && isscalar(s.(field)) && ~ismissing(s.(field))));
                    s.(field)=char(string(s.(field)));
                end
                assert(ismember(string(s.atlas),["none","aal","brodmann","volume"]));
                m=s.scene_to_atlas;
                assert(isnumeric(m) && isreal(m) && isequal(size(m),[4 4]) && all(isfinite(m),'all'));
                assert(isequal(m(4,:),[0 0 0 1]) && rcond(m(1:3,1:3))>1e-12);
                assert(islogical(s.confirmed) && isscalar(s.confirmed));
                assert(isempty(s.input_signature) || ~isempty(regexp(s.input_signature,'^[a-f0-9]{64}$','once')));
                if isempty(s.labels), s.labels=template.labels; end
                assert(isstruct(s.labels) && numel(s.labels)<=100000 && ...
                    isequal(sort(fieldnames(s.labels)),sort({'id';'name'})));
                for i=1:numel(s.labels)
                    id=s.labels(i).id; name=string(s.labels(i).name);
                    assert(isnumeric(id) && isscalar(id) && isfinite(id) && id==fix(id) && id>0);
                    assert(isscalar(name) && ~ismissing(name) && strlength(strtrim(name))>0);
                    s.labels(i).name=char(name);
                end
                assert(numel(unique([s.labels.id]))==numel(s.labels));
                s.labels=reshape(s.labels,[],1);
                if s.confirmed && ~strcmp(s.atlas,'none')
                    for field=["source_space","atlas_space","transform_note"]
                        assert(strlength(strtrim(string(s.(field))))>0);
                    end
                    assert(isempty(regexpi([s.source_space ' ' s.atlas_space],'unknown|unverified','once')));
                    if ismember(string(s.atlas),["aal","brodmann"])
                        assert(strcmp(s.atlas_space,'MNI (legacy AAL/Brodmann)'));
                    end
                end
            catch
                error('BNV:Query:InvalidSettings','Invalid inspection settings. Declare spaces, an invertible affine and its provenance before confirming registration.');
            end
        end
        function key=inputSignature(scene)
            value=scene.toStruct();
            key=brainnet.core.SessionState.signatureForDocument(struct('inputs',value.inputs,'options',struct()));
        end
        function s=fromScene(scene)
            s=brainnet.query.InspectionSettings.defaults();
            if isfield(scene.Metadata,'inspection')
                s=brainnet.query.InspectionSettings.validate(scene.Metadata.inspection);
            end
        end
    end
end
