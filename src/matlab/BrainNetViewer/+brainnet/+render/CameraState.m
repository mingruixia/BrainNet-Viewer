classdef CameraState
    %CAMERASTATE Camera-only operations; never changes data or axes positions.
    methods (Static)
        function state = capture(axesHandles, layout)
            views = repmat(struct('position', [], 'target', [], 'up', [], ...
                'view_angle', [], 'projection', '', 'xlim', [], 'ylim', [], 'zlim', []), ...
                numel(axesHandles), 1);
            for index = 1:numel(axesHandles)
                a = axesHandles(index);
                angle = a.CameraViewAngle;
                if layout > 1
                    % Store vertical-equivalent angles so resize/replay is
                    % independent of MATLAB's shortest-viewport-side rule.
                    angle = 2*atand(tand(angle/2)*a.Position(4)/ ...
                        brainnet.render.CameraState.viewportFactor(a));
                end
                views(index) = struct('position', a.CameraPosition, 'target', a.CameraTarget, ...
                    'up', a.CameraUpVector, 'view_angle', angle, ...
                    'projection', a.Projection, 'xlim', a.XLim, 'ylim', a.YLim, 'zlim', a.ZLim);
            end
            state = struct('layout', layout, 'views', views);
            if layout > 1
                state.viewport_heights = arrayfun(@(a) a.Position(4),axesHandles);
            end
        end
        function apply(axesHandles, state)
            assert(numel(axesHandles) == numel(state.views), ...
                'BNV:Render:CameraViewCount', 'Camera state does not match the active layout.');
            for index = 1:numel(axesHandles)
                a = axesHandles(index);
                v = state.views(index);
                angle = v.view_angle;
                if numel(axesHandles)>1
                    if isfield(state,'viewport_heights')
                        height = state.viewport_heights(index);
                    else
                        height = max(arrayfun(@(ax) ax.Position(4),axesHandles));
                    end
                    angle = 2*atand(tand(angle/2)* ...
                        brainnet.render.CameraState.viewportFactor(a)/height);
                end
                setappdata(a,'brainnet_viewport_factor',brainnet.render.CameraState.viewportFactor(a));
                set(a, 'XLim', reshape(v.xlim,1,2), 'YLim', reshape(v.ylim,1,2), ...
                    'ZLim', reshape(v.zlim,1,2), 'DataAspectRatio', [1 1 1], ...
                    'Projection', v.projection, 'CameraTarget', reshape(v.target,1,3), ...
                    'CameraPosition', reshape(v.position,1,3), ...
                    'CameraUpVector', reshape(v.up,1,3), 'CameraViewAngle', angle);
            end
        end
        function synchronize(axesHandles, source)
            if numel(axesHandles) < 2, return; end
            distance = norm(source.CameraPosition - source.CameraTarget);
            angle = source.CameraViewAngle;
            height = brainnet.render.CameraState.viewportFactor(source);
            for a = reshape(axesHandles, 1, [])
                direction = a.CameraPosition - a.CameraTarget;
                a.CameraPosition = a.CameraTarget + direction / norm(direction) * distance;
                factor = brainnet.render.CameraState.viewportFactor(a);
                a.CameraViewAngle = 2*atand(tand(angle/2)*factor/height);
                setappdata(a,'brainnet_viewport_factor',factor);
                a.DataAspectRatio = [1 1 1];
                a.Projection = 'orthographic';
            end
        end
        function fit(axesHandles)
            % Project scientific patch vertices; labels/colorbars are excluded.
            extents = zeros(numel(axesHandles), 1);
            distances = zeros(numel(axesHandles), 1);
            for index = 1:numel(axesHandles)
                a = axesHandles(index);
                patches = findall(a, 'Type', 'patch');
                vertices = zeros(0,3);
                for p = reshape(patches,1,[])
                    vertices = [vertices; double(p.Vertices)]; %#ok<AGROW>
                end
                if isempty(vertices), continue; end
                low = min(vertices,[],1); high = max(vertices,[],1);
                target = (low + high)/2;
                direction = a.CameraPosition - a.CameraTarget;
                direction = direction/norm(direction);
                right = cross(a.CameraUpVector, direction); right = right/norm(right);
                up = cross(direction, right);
                % Centre the projected silhouette, not only the 3-D box.
                projected = vertices*[right.' up.'];
                centre = (min(projected,[],1)+max(projected,[],1))/2;
                target = target+(centre(1)-target*right.')*right+ ...
                    (centre(2)-target*up.')*up;
                offsets = vertices-target;
                pixel = getpixelposition(a);
                aspect = max(pixel(3),1)/max(pixel(4),1);
                extents(index) = 1.08 * max([max(abs(offsets*up.')), ...
                    max(abs(offsets*right.'))/aspect, eps])/a.Position(4);
                distances(index) = max(vecnorm(offsets,2,2))*5 + 1;
                a.CameraTarget = target;
                a.CameraPosition = target + direction;
                a.DataAspectRatio = [1 1 1];
                a.Projection = 'orthographic';
                padding = max((high-low)*0.05, 1);
                a.XLim = [low(1)-padding(1) high(1)+padding(1)];
                a.YLim = [low(2)-padding(2) high(2)+padding(2)];
                a.ZLim = [low(3)-padding(3) high(3)+padding(3)];
            end
            distance = max([distances;1]);
            extent = max([extents;eps]);
            for a = reshape(axesHandles,1,[])
                direction = a.CameraPosition-a.CameraTarget;
                a.CameraPosition = a.CameraTarget+direction/norm(direction)*distance;
                factor = brainnet.render.CameraState.viewportFactor(a);
                a.CameraViewAngle = 2*atand(extent*factor/distance);
                setappdata(a,'brainnet_viewport_factor',factor);
            end
        end
        function factor = viewportFactor(a)
            % MATLAB's manual camera angle spans the shorter viewport side.
            pixels = getpixelposition(a);
            factor = a.Position(4)*min(1,max(pixels(3),1)/max(pixels(4),1));
        end
        function refreshViewport(axesHandles)
            if numel(axesHandles)<2, return; end
            for a=reshape(axesHandles,1,[])
                factor=brainnet.render.CameraState.viewportFactor(a);
                old=getappdata(a,'brainnet_viewport_factor');
                if ~isempty(old) && abs(factor-old)>1e-12
                    a.CameraViewAngle=2*atand(tand(a.CameraViewAngle/2)*factor/old);
                end
                setappdata(a,'brainnet_viewport_factor',factor);
            end
        end
    end
end
