classdef OrientationLabels
    %ORIENTATIONLABELS Conservative, input-bound declarations; never registration.
    methods (Static)
        function requireLegacyCompatible(scene)
            globalSettings=scene.Options.section('global');
            if ~globalSettings.show_orientation_labels || scene.Options.Layout==1, return; end
            policy=brainnet.core.OrientationLabels.resolve(scene);
            if ~strcmp(policy.mode,'anatomical') || ~strcmp(policy.positive_label,'R')
                error('BNV:Orientation:LegacyRendererMismatch', ...
                    ['Legacy Renderer cannot represent this orientation-label policy. ' ...
                     'Use Modern Batch Renderer or disable Show Orientation Labels.']);
            end
        end
        function scene=confirm(scene,xPositive,options)
            arguments
                scene (1,1) brainnet.core.Scene
                xPositive (1,1) string {mustBeMember(xPositive,["left","right"])}
                options.MidlineIsXZero (1,1) logical = false
            end
            if ~options.MidlineIsXZero
                error('BNV:Orientation:MidlineConfirmationRequired', ...
                    'Confirm that X=0 is the anatomical midline for all displayed inputs.');
            end
            if ~brainnet.core.OrientationLabels.hasHashes(scene)
                error('BNV:Orientation:InputHashesRequired', ...
                    'Seal input SHA-256 hashes before confirming anatomical labels.');
            end
            value=scene.toStruct();
            value.metadata.orientation_labels=struct('version','1.0', ...
                'x_positive',char(xPositive),'midline_is_x_zero',true, ...
                'input_signature',char(brainnet.core.OrientationLabels.signature(scene)));
            scene=brainnet.core.Scene.fromStruct(value);
        end
        function policy=resolve(scene)
            policy=struct('mode','coordinate','negative_label','X<=0','positive_label','X>0', ...
                'reason','Anatomical orientation has not been confirmed for these inputs.');
            if ~isfield(scene.Metadata,'orientation_labels'), return; end
            declaration=scene.Metadata.orientation_labels;
            fields={'version';'x_positive';'midline_is_x_zero';'input_signature'};
            if ~isstruct(declaration)||~isscalar(declaration)||~all(isfield(declaration,fields)) || ...
                    ~ischar(declaration.version)||~strcmp(declaration.version,'1.0') || ...
                    ~ischar(declaration.x_positive)||~isrow(declaration.x_positive)|| ...
                    ~ismember(string(declaration.x_positive),["left","right"]) || ...
                    ~isequal(declaration.midline_is_x_zero,true) || ...
                    ~ischar(declaration.input_signature)||~isrow(declaration.input_signature)
                policy.reason='Invalid orientation declaration; coordinate labels are used.';
                return;
            end
            if ~brainnet.core.OrientationLabels.hasHashes(scene) || ...
                    ~strcmp(declaration.input_signature,brainnet.core.OrientationLabels.signature(scene))
                policy.reason='Inputs or coordinate-space declaration changed; reconfirm anatomical orientation.';
                return;
            end
            policy.mode='anatomical';
            if strcmp(declaration.x_positive,'right')
                policy.negative_label='L'; policy.positive_label='R';
            else
                policy.negative_label='R'; policy.positive_label='L';
            end
            policy.reason='User-declared X direction and X=0 midline; not independently verified registration.';
        end
    end
    methods (Static, Access=private)
        function value=hasHashes(scene)
            value=~isempty(scene.Inputs)&&all(cellfun(@(v) strlength(v.Sha256)==64,scene.Inputs));
        end
        function value=signature(scene)
            doc=scene.toStruct();
            value=brainnet.render.internal.sha256Text(string(jsonencode( ...
                struct('inputs',doc.inputs,'coordinate_space',doc.coordinate_space))));
        end
    end
end
