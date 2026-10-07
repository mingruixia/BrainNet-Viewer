classdef SessionState
    %SESSIONSTATE Validated, optional Scene metadata for desktop/CLI replay.
    methods (Static)
        function state = fromScene(scene)
            state = [];
            if isfield(scene.Metadata, 'session_state')
                state = brainnet.core.SessionState.validate(scene.Metadata.session_state);
            end
        end
        function scene = normalizeScene(scene)
            state = brainnet.core.SessionState.fromScene(scene);
            if isempty(state), return; end
            value = scene.toStruct();
            value.metadata.session_state = state;
            scene = brainnet.core.Scene.fromStruct(value);
        end
        function key = signature(scene)
            value = scene.toStruct();
            key = brainnet.core.SessionState.signatureForDocument(value);
        end
        function key = signatureForDocument(value)
            % Hash the canonical document at its declared settings version.
            text = jsonencode(struct('inputs', value.inputs, 'options', value.options));
            digest = java.security.MessageDigest.getInstance('SHA-256');
            digest.update(typecast(uint8(unicode2native(text, 'UTF-8')), 'int8'));
            bytes = typecast(digest.digest(), 'uint8');
            key = string(lower(reshape(dec2hex(bytes,2).',1,[])));
        end
        function scene = attach(scene, camera, preferences)
            value = scene.toStruct();
            state = struct('version', '1.0', 'scene_signature', ...
                char(brainnet.core.SessionState.signature(scene)), ...
                'camera', camera, 'export', preferences);
            value.metadata.session_state = brainnet.core.SessionState.validate(state);
            scene = brainnet.core.Scene.fromStruct(value);
        end
        function state = validate(state)
            try
                assert(isstruct(state) && isscalar(state));
                assert(strcmp(state.version, '1.0'));
                assert(~isempty(regexp(state.scene_signature, '^[a-f0-9]{64}$', 'once')));
                e = state.export;
                assert(isstruct(e) && isscalar(e));
                for field = ["format","units","content_type","background_color"]
                    assert(isscalar(string(e.(field))));
                end
                assert(ismember(string(e.format), ["png","jpg","tif","bmp","pdf","svg"]));
                assert(ismember(string(e.units), ["pixels","millimeters","centimeters","inches","points"]));
                assert(ismember(string(e.content_type), ["auto","image","vector"]));
                assert(ismember(string(e.background_color), ["current","white","black","none"]));
                for field = ["width","height","resolution_dpi"]
                    x = e.(field);
                    assert(isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);
                end
                assert(e.resolution_dpi == fix(e.resolution_dpi));
                assert(~(ismember(string(e.format), ["png","jpg","tif","bmp"]) && strcmp(e.content_type, 'vector')));
                assert(~(ismember(string(e.format), ["jpg","bmp"]) && strcmp(e.background_color, 'none')));
                if ~isempty(state.camera)
                    c = state.camera;
                    assert(isstruct(c) && isscalar(c) && isnumeric(c.layout) && ...
                        isscalar(c.layout) && ismember(c.layout, 1:5));
                    % Split presets 3 and 5 fall back to six full-brain
                    % panes when a surface cannot be divided into hemispheres.
                    counts = {1,[6 8],[4 6],6,[5 6]};
                    assert(isstruct(c.views) && ismember(numel(c.views),counts{c.layout}));
                    for v = reshape(c.views, 1, [])
                        for field = ["position","target","up"]
                            x = v.(field);
                            assert(isnumeric(x) && numel(x) == 3 && all(isfinite(x(:))));
                        end
                        direction = v.position(:) - v.target(:);
                        assert(norm(direction) > 0 && norm(cross(direction, v.up(:))) > 1e-10);
                        assert(isnumeric(v.view_angle) && isscalar(v.view_angle) && ...
                            isfinite(v.view_angle) && v.view_angle > 0 && v.view_angle < 180);
                        assert(isscalar(string(v.projection)) && ...
                            ismember(string(v.projection), ["orthographic","perspective"]));
                        for field = ["xlim","ylim","zlim"]
                            x = v.(field);
                            assert(isnumeric(x) && numel(x) == 2 && all(isfinite(x(:))) && x(2) > x(1));
                        end
                        if c.layout > 1, assert(strcmp(v.projection, 'orthographic')); end
                    end
                    if c.layout > 1
                        distances = arrayfun(@(v) norm(v.position(:)-v.target(:)), c.views);
                        angles = [c.views.view_angle];
                        assert(max(distances)-min(distances) < 1e-7 * max(distances));
                        if isfield(c,'viewport_heights')
                            heights = c.viewport_heights;
                            assert(isnumeric(heights) && numel(heights)==numel(c.views) && ...
                                all(isfinite(heights(:))) && all(heights(:)>0) && all(heights(:)<=1));
                            scales = tand(angles(:)/2)./heights(:);
                            assert(max(scales)-min(scales) < 1e-7*max(scales));
                            c.viewport_heights = reshape(heights,[],1);
                        else
                            % Existing scenes used one common angle.
                            assert(max(angles)-min(angles) < 1e-7 * max(angles));
                        end
                    end
                    c.views = reshape(c.views,[],1);
                    for index = 1:numel(c.views)
                        for field = ["position","target","up","xlim","ylim","zlim"]
                            c.views(index).(field) = reshape(c.views(index).(field),1,[]);
                        end
                        c.views(index).projection = char(string(c.views(index).projection));
                    end
                    state.camera = c;
                end
            catch
                error('BNV:Core:InvalidSessionState', ...
                    'Invalid or unsupported Scene session state. Check camera and export preferences.');
            end
        end
    end
end
