classdef MatlabBatchRenderer < handle
    %MATLABBATCHRENDERER Render surfaces, nodes, and edges in bounded batches.

    properties (SetAccess = private)
        ActiveFigure = []
        ActiveTarget = []
        ActiveAxes = []
        LastMetrics struct = struct()
        DefaultCamera = []
        CameraLayout = 1
        GeometryCacheHitCount (1, 1) double = 0
        GeometryCacheMissCount (1, 1) double = 0
        InspectEnabled logical = false
    end

    properties (Access = private)
        GeometryCache
        CameraListeners cell = {}
        CameraSyncSuspended logical = false
        InspectCallback = []
        InspectInteractions cell = {}
        TitleAxes = []
    end

    methods
        function obj = MatlabBatchRenderer
            obj.GeometryCache = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end

        function [figureHandle, metrics] = render(obj, prepared, renderOptions, options)
            arguments
                obj (1, 1) brainnet.render.MatlabBatchRenderer
                prepared (1, 1) brainnet.render.PreparedScene
                renderOptions (1, 1) brainnet.core.RenderOptions
                options.Visible (1, 1) logical = true
                options.Parent = []
                options.Position double = []
                options.WindowMode (1, 1) string = "auto"
                options.PerformanceMode (1, 1) string = "auto"
                options.ComputeBackend (1, 1) string = "auto"
                options.NodeDetail double = []
                options.EdgeSides double = []
                options.SurfaceFaceFraction double = []
                options.DetailLevel (1, 1) string = ""
            end
            brainnet.core.VolumeThresholdPolicy.requireSupported(renderOptions.section('volume'));
            doubleBrain=brainnet.core.DoubleBrain.transform(prepared,renderOptions);
            brainnet.core.VertexColors.requireBound(renderOptions.section('surface'),prepared.SurfaceCoordinates,prepared.SurfaceFaces);
            if ~ismember(renderOptions.Layout, 1:5)
                error('BNV:Render:UnsupportedLayout', ...
                    'The batch renderer supports layouts 1 through 5.');
            end
            totalTimer = tic;
            boundary=[];
            surfaceBoundarySettings=renderOptions.section("surface");
            if prepared.VertexCount>0 && any(string(surfaceBoundarySettings.boundary_mode)==["automatic","legacy-automatic","threshold","custom"])
                boundarySettings=surfaceBoundarySettings;
                if string(boundarySettings.boundary_mode)=="automatic"
                    % Preserve the established BrainNet vertex-boundary appearance.
                    boundarySettings.boundary_mode='legacy-automatic';
                end
                boundary=brainnet.render.internal.configuredBoundary(prepared,boundarySettings);
            end
            obj.closeActiveFigure();

            globalSettings = renderOptions.section("global");
            detailLevel=string(globalSettings.render_detail);
            if strlength(options.DetailLevel)>0, detailLevel=options.DetailLevel; end
            policy = brainnet.render.internal.renderPerformancePolicy(prepared, ...
                Mode=options.PerformanceMode, NodeDetail=options.NodeDetail, ...
                EdgeSides=options.EdgeSides, ...
                SurfaceFaceFraction=options.SurfaceFaceFraction, ...
                ComputeBackend=options.ComputeBackend,DetailLevel=detailLevel);

            if string(surfaceBoundarySettings.boundary_mode)=="custom" || string(surfaceBoundarySettings.color_mode)=="vertex-rgb"
                % Reducing unvalued geometry would discard original mask indices.
                policy.surface_face_fraction=1;
                policy.rationale='Original-order custom boundary or vertex RGB requires full surface geometry.';
            end

            geometryTimer = tic;
            [geometry, geometryCacheHit, geometryCacheKey] = ...
                obj.geometryFor(prepared, policy, renderOptions);
            geometrySeconds = toc(geometryTimer);

            graphicsTimer = tic;
            backgroundColor = globalSettings.background_color;
            embedded = ~isempty(options.Parent);
            if embedded
                if ~isgraphics(options.Parent)
                    error('BNV:Render:InvalidParent', ...
                        'Parent must be a valid MATLAB graphics container.');
                end
                target = options.Parent;
                % Normalized axes already follow their container. MATLAB's
                % automatic child resizing would apply a second layout policy.
                if isprop(target,'AutoResizeChildren')
                    target.AutoResizeChildren = 'off';
                end
                figureHandle = ancestor(target, 'figure');
                position = target.Position;
                windowMode = "embedded";
                delete(allchild(target));
                if isprop(target, 'BackgroundColor')
                    target.BackgroundColor = backgroundColor;
                end
                obj.ActiveTarget = target;
            else
                visibility = char(matlab.lang.OnOffSwitchState(options.Visible));
                [position, windowMode] = obj.resolveWindowPlacement( ...
                    options.Visible, options.Position, options.WindowMode);
                figureHandle = figure('Visible', visibility, 'Color', backgroundColor, ...
                    'Position', position, ...
                    'Name', 'BrainNet Viewer 2.0', 'NumberTitle', 'off');
                target = figureHandle;
                obj.ActiveFigure = figureHandle;
                obj.ActiveTarget = figureHandle;
            end
            [positions, views, scopes, layoutPolicy, cameraUps] = obj.layout(prepared, renderOptions);
            viewCount = size(positions, 1);
            axesHandles = gobjects(viewCount, 1);
            patchCounts = zeros(viewCount, 1);
            nodePatchCount = 0;
            edgePatchCount = 0;
            roiPatchCount = 0;
            legacyObjectEstimate = 0;
            for viewIndex = 1:viewCount
                if embedded
                    axesHandles(viewIndex) = uiaxes('Parent', target, ...
                        'Units', 'normalized', 'Position', positions(viewIndex, :), ...
                        'Visible', 'off', 'Color', backgroundColor, ...
                        'Toolbar', []);
                    % The app toolbar owns camera gestures. Default UIAxes
                    % interactions can change axes limits independently.
                    axesHandles(viewIndex).Interactions = [];
                else
                    axesHandles(viewIndex) = axes('Parent', target, ...
                        'Position', positions(viewIndex, :), 'Visible', 'off', ...
                        'Color', backgroundColor);
                end
                hold(axesHandles(viewIndex), 'on');
                scope = geometry.(scopes(viewIndex));
                patchCounts(viewIndex) = obj.drawScope(axesHandles(viewIndex), ...
                    prepared, renderOptions, scope);
                nodePatchCount = nodePatchCount + double(scope.node_count > 0);
                edgePatchCount = edgePatchCount + double(scope.edge_count > 0);
                roiPatchCount = roiPatchCount + double(~isempty(scope.roi_faces));
                legacyObjectEstimate = legacyObjectEstimate + ...
                    double(prepared.VertexCount > 0) + scope.node_count + ...
                    scope.edge_count + scope.roi_count;
                axis(axesHandles(viewIndex), 'equal');
                axis(axesHandles(viewIndex), 'tight');
                axis(axesHandles(viewIndex), 'padded');
                axis(axesHandles(viewIndex), 'off');
                view(axesHandles(viewIndex), views(viewIndex, 1), views(viewIndex, 2));
                if all(isfinite(cameraUps(viewIndex,:)))
                    axesHandles(viewIndex).CameraUpVector=cameraUps(viewIndex,:);
                end
                if renderOptions.Layout > 1
                    axesHandles(viewIndex).Projection = 'orthographic';
                end
                obj.applyAppearance(axesHandles(viewIndex), globalSettings);
            end
            surfaceSettings = renderOptions.section("surface");
            surfaceIsMapped = ~isempty(prepared.SurfaceValues) && ...
                string(surfaceSettings.color_mode) == "scalar";
            if surfaceIsMapped
                volumeSettings = renderOptions.section("volume");
                if volumeSettings.display && ...
                        string(volumeSettings.type) == "surface-map"
                    volumeSettings.null_color = surfaceSettings.color;
                    [map, limits] = obj.volumeColormap( ...
                        prepared.SurfaceValues, volumeSettings);
                else
                    map = obj.namedColormap(surfaceSettings.colormap, 256);
                    limits = obj.sectionColorLimits(prepared.SurfaceValues, ...
                        surfaceSettings.color_limits, renderOptions);
                    [rgb,map]=brainnet.render.internal.surfaceMapColors( ...
                        prepared.SurfaceValues,map,limits,surfaceSettings.color);
                    for a=reshape(axesHandles,1,[])
                        for item=reshape(findall(a,'Tag','brainnet-surface-mapped'),1,[])
                            item.FaceVertexCData=rgb(item.UserData.surface_indices,:);
                        end
                    end
                end
                for axesHandle = reshape(axesHandles, 1, [])
                    colormap(axesHandle, map);
                end
                set(axesHandles, 'CLim', limits);
                if surfaceSettings.show_colorbar
                    if renderOptions.Layout == 2
                        colorAxes = axesHandles(5);
                        colorPosition = [0.35 0.075 0.30 0.018];
                    else
                        colorAxes = axesHandles(end);
                        if renderOptions.Layout == 1
                            colorPosition = [0.35 0.055 0.30 0.018];
                        elseif renderOptions.Layout == 3
                            colorPosition = [0.35 0.060 0.30 0.018];
                        elseif renderOptions.Layout == 4
                            colorPosition = [0.35 0.035 0.30 0.018];
                        else
                            colorPosition = [0.35 0.055 0.30 0.018];
                        end
                    end
                    colorHandle = colorbar(colorAxes, 'southoutside');
                    colorHandle.Position = colorPosition;
                    colorHandle.FontName = 'Arial';
                    colorHandle.FontSize = 8;
                    colorHandle.Color = obj.contrastColor(backgroundColor);
                end
            end
            if ~isempty(boundary)
                for ax=reshape(axesHandles,1,[])
                    for item=reshape(findall(ax,'Type','patch'),1,[])
                        if ~isstruct(item.UserData)||~isfield(item.UserData,'surface_indices'), continue; end
                        selected=boundary.mask(item.UserData.surface_indices);
                        if size(item.FaceVertexCData,2)==3
                            rgb=item.FaceVertexCData;
                        elseif surfaceIsMapped
                            data=item.FaceVertexCData; map=colormap(ax); limits=ax.CLim;
                            indices=1+floor(size(map,1)*(data-limits(1))/(limits(2)-limits(1)));
                            indices(~isfinite(indices))=1; indices=max(1,min(size(map,1),indices));
                            rgb=map(indices,:);
                        elseif string(surfaceSettings.color_mode)=="vertex-rgb"
                            rgb=item.FaceVertexCData;
                        else
                            rgb=repmat(surfaceSettings.color,numel(selected),1);
                        end
                        rgb(selected,:)=repmat(surfaceSettings.boundary_color,nnz(selected),1);
                        item.FaceVertexCData=rgb;
                        if string(surfaceSettings.boundary_mode)=="automatic" || string(globalSettings.shading)=="interp"
                            % Keep the legacy vertex mask but use interpolation for a lighter boundary.
                            item.FaceColor='interp';
                        else
                            item.FaceColor='flat';
                        end
                        item.UserData.boundary_mask=selected;
                    end
                end
            end
            if doubleBrain.enabled
                for a=reshape(axesHandles,1,[])
                    originals=findall(a,'Type','patch','-regexp','Tag','^brainnet-surface-');
                    for original=reshape(originals,1,[])
                        duplicate=copyobj(original,a);
                        duplicate.Vertices=brainnet.core.DoubleBrain.forward(original.Vertices,doubleBrain);
                        duplicate.UserData.double_brain=doubleBrain;
                        if string(surfaceSettings.color_mode)=="vertex-rgb"
                            ids=duplicate.UserData.surface_indices;
                            rgb=surfaceSettings.vertex_colors(prepared.VertexCount+ids,:);
                            if isfield(duplicate.UserData,'boundary_mask')
                                mask=duplicate.UserData.boundary_mask;
                                rgb(mask,:)=repmat(surfaceSettings.boundary_color,nnz(mask),1);
                            end
                            duplicate.FaceVertexCData=rgb;
                        end
                        patchCounts(1)=patchCounts(1)+1;
                    end
                    for original=reshape(findall(a,'Tag','brainnet-surface-boundary'),1,[])
                        duplicate=copyobj(original,a);
                        xyz=brainnet.core.DoubleBrain.forward([original.XData(:),original.YData(:),original.ZData(:)],doubleBrain);
                        set(duplicate,'XData',xyz(:,1),'YData',xyz(:,2),'ZData',xyz(:,3));
                    end
                end
            end
            if renderOptions.Layout > 1 && globalSettings.show_orientation_labels && ...
                    any(scopes == "left") && any(scopes == "right")
                if ismember(renderOptions.Layout, [2 5])
                    rightAxes = axesHandles(3);
                else
                    rightAxes = axesHandles(2);
                end
                labelColor = obj.contrastColor(backgroundColor);
                labelPolicy = prepared.OrientationLabels;
                text(axesHandles(1), 0.04, 0.92, labelPolicy.negative_label, 'Units', 'normalized', ...
                    'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 13, ...
                    'Color', labelColor, 'BackgroundColor', 1-labelColor, ...
                    'Margin', 2, 'Interpreter', 'none', ...
                    'Tag', 'brainnet-orientation-label');
                text(rightAxes, 0.92, 0.92, labelPolicy.positive_label, 'Units', 'normalized', ...
                    'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 13, ...
                    'Color', labelColor, 'BackgroundColor', 1-labelColor, ...
                    'Margin', 2, 'Interpreter', 'none', 'HorizontalAlignment', 'right', ...
                    'Tag', 'brainnet-orientation-label');
            end
            graphicsSeconds = toc(graphicsTimer);
            obj.ActiveAxes = axesHandles;

            drawTimer = tic;
            drawnow;
            packingLayout=renderOptions.Layout;
            if strcmp(layoutPolicy.mode,'six-full')
                % A split preset on an indivisible mesh uses the same six
                % full-brain composition as Overview, not its old split grid.
                packingLayout=2;
            end
            brainnet.render.internal.packLegacyMontage(axesHandles,packingLayout);
            obj.drawTitle(target,axesHandles,renderOptions.section("image"),backgroundColor,embedded);
            drawnow;
            % Equal pixels per data unit, including panes of different heights.
            brainnet.render.CameraState.fit(axesHandles);
            % Freeze initial limits; resize must not reset a user's camera.
            brainnet.render.CameraState.apply(axesHandles, ...
                brainnet.render.CameraState.capture(axesHandles,renderOptions.Layout));
            roiSettings=renderOptions.section("roi");
            if roiSettings.show_legend && ~isempty(prepared.RoiMeshes)
                entries=prepared.RoiMeshes;
                count=min(16,numel(entries));
                keys=gobjects(1,count);
                labels=cell(1,count);
                for roiIndex=1:count
                    keys(roiIndex)=patch(axesHandles(1),'XData',NaN,'YData',NaN, ...
                        'FaceColor',entries(roiIndex).color,'EdgeColor','none', ...
                        'Tag','brainnet-roi-legend-key', ...
                        'HitTest','off','PickableParts','none');
                    labels{roiIndex}=sprintf('ROI %g',entries(roiIndex).label);
                end
                if numel(entries)>count
                    labels{end}=sprintf('%s (+%d more)',labels{end},numel(entries)-count);
                end
                legendHandle=legend(axesHandles(1),keys,labels, ...
                    'Location','northeast','Interpreter','none','FontSize',8);
                legendHandle.Tag='brainnet-roi-legend';
                legendHandle.AutoUpdate='off';
            end
            drawSeconds = toc(drawTimer);
            metrics = struct( ...
                'renderer_version', 'matlab-batch-0.2', ...
                'scene_id', char(prepared.SceneId), ...
                'view_count', viewCount, ...
                'layout_policy', layoutPolicy, ...
                'surface_patch_count', viewCount * double(prepared.VertexCount > 0)*(1+double(doubleBrain.enabled)), ...
                'double_brain', doubleBrain, ...
                'node_patch_count', nodePatchCount, ...
                'edge_patch_count', edgePatchCount, ...
                'roi_patch_count', roiPatchCount, ...
                'patch_count', sum(patchCounts), ...
                'legacy_object_estimate', legacyObjectEstimate, ...
                'geometry_seconds', geometrySeconds, ...
                'graphics_seconds', graphicsSeconds, ...
                'draw_seconds', drawSeconds, ...
                'total_seconds', toc(totalTimer), ...
                'performance_policy', policy, ...
                'geometry_cache_hit', geometryCacheHit, ...
                'geometry_cache_key', char(geometryCacheKey), ...
                'window_mode', char(windowMode), ...
                'initial_position', position, ...
                'window_state', char(string(figureHandle.WindowState)), ...
                'embedded', embedded, ...
                'global_settings', globalSettings, ...
                'orientation_labels', prepared.OrientationLabels, ...
                'surface_settings', surfaceSettings, ...
                'node_settings', renderOptions.section("node"), ...
                'edge_settings', renderOptions.section("edge"), ...
                'volume_settings', renderOptions.section("volume"), ...
                'roi_settings', renderOptions.section("roi"), ...
                'node_detail', policy.node_detail, ...
                'edge_sides', policy.edge_sides, ...
                'geometry', obj.geometrySummary(geometry));
            obj.LastMetrics = metrics;
            obj.CameraLayout = renderOptions.Layout;
            obj.DefaultCamera = obj.captureCamera();
            viewportContainers={target,figureHandle};
            if isequal(target,figureHandle), viewportContainers=viewportContainers(1); end
            for container=viewportContainers
                obj.CameraListeners{end+1}=addlistener(container{1},'SizeChanged', ...
                    @(~,~) obj.refreshViewportScale());
            end
            for a = reshape(obj.ActiveAxes, 1, [])
                a.Clipping = 'on';
                a.ClippingStyle = 'rectangle';
            end
            % Observe modern UIAxes and normal axes without switching to
            % legacy exploration modes or replacing native toolbar callbacks.
            for a = reshape(obj.ActiveAxes, 1, [])
                brainnet.render.internal.updateNodeLabels(a);
                for property=["CameraPosition","CameraTarget","CameraUpVector","CameraViewAngle","Projection","Position"]
                    obj.CameraListeners{end+1}=addlistener(a,char(property),'PostSet', ...
                        @(~,~) brainnet.render.internal.updateNodeLabels(a));
                end
                containers={a.Parent,ancestor(a,'figure')};
                if isequal(containers{1},containers{2}), containers=containers(1); end
                for container=containers
                    obj.CameraListeners{end+1}=addlistener(container{1},'SizeChanged', ...
                        @(~,~) brainnet.render.internal.boundNodeLabels(a));
                end
                for property = ["CameraPosition","CameraTarget","CameraViewAngle"]
                    obj.CameraListeners{end+1} = addlistener(a, char(property), 'PostSet', ...
                        @(~,~) obj.synchronizeInteraction(a));
                end
                for property = ["CameraPosition","CameraTarget","CameraUpVector"]
                    obj.CameraListeners{end+1} = addlistener(a, char(property), 'PostSet', ...
                        @(~,~) obj.synchronizeCameraLighting(a));
                end
            end
        end

        function state = captureCamera(obj)
            state = [];
            if ~isempty(obj.ActiveAxes) && all(isgraphics(obj.ActiveAxes))
                obj.refreshViewportScale();
                state = brainnet.render.CameraState.capture(obj.ActiveAxes, obj.CameraLayout);
            end
        end

        function enableInspection(obj,callback,enabled)
            wasEnabled=obj.InspectEnabled;
            obj.InspectEnabled=logical(enabled); obj.InspectCallback=callback;
            axisIndex=0;
            for a=reshape(obj.ActiveAxes,1,[])
                axisIndex=axisIndex+1;
                if ~isgraphics(a), continue; end
                if isprop(a,'Interactions')
                    if enabled
                        if ~wasEnabled, obj.InspectInteractions{axisIndex}=a.Interactions; end
                        a.Interactions=[];
                    elseif wasEnabled && axisIndex<=numel(obj.InspectInteractions)
                        a.Interactions=obj.InspectInteractions{axisIndex};
                    end
                end
                for p=reshape(findall(a,'Type','patch'),1,[])
                    if startsWith(string(p.Tag),'brainnet-surface-') || strcmp(p.Tag,'brainnet-nodes')
                        if enabled
                            p.PickableParts='visible'; p.HitTest='on';
                            p.ButtonDownFcn=@(source,event) obj.onInspect(source,event);
                        else
                            p.ButtonDownFcn=[];
                        end
                    end
                end
                % Decorative overlays (boundaries, edges, arrows and ROI meshes)
                % must never mask a surface click while Inspect is active.
                if enabled
                    overlays=[findall(a,'Tag','brainnet-surface-boundary'); ...
                        findall(a,'Tag','brainnet-edges'); ...
                        findall(a,'Tag','brainnet-edge-arrows'); ...
                        findall(a,'Tag','brainnet-volume-roi')];
                    for overlay=reshape(overlays,1,[])
                        if isprop(overlay,'PickableParts'), overlay.PickableParts='none'; end
                        if isprop(overlay,'HitTest'), overlay.HitTest='off'; end
                    end
                end
            end
        end

        function status = restoreCamera(obj, state, options)
            arguments
                obj
                state
                options.AllowLayout2Fallback (1,1) logical = false
            end
            status = 'none';
            if isempty(state), return; end
            % Validate public API inputs before changing any axes.
            preference = struct('format','png','width',1,'height',1, ...
                'resolution_dpi',72,'units','pixels','content_type','auto','background_color','white');
            brainnet.core.SessionState.validate(struct('version','1.0', ...
                'scene_signature',repmat('0',1,64),'camera',state,'export',preference));
            assert(state.layout == obj.CameraLayout, 'BNV:Render:CameraLayoutMismatch', ...
                'Saved camera layout does not match the current layout.');
            if options.AllowLayout2Fallback && state.layout == 2 && ...
                    numel(state.views) ~= numel(obj.ActiveAxes)
                obj.resetCamera();
                status = 'reset-layout2-view-count';
                warning('BNV:Render:Layout2CameraReset', ...
                    'Layout 2 view count changed; the saved camera was replaced with a fitted camera.');
                return;
            end
            cleanup = obj.pauseCameraSync(); %#ok<NASGU> Retain synchronization guard until return.
            brainnet.render.CameraState.apply(obj.ActiveAxes, state);
            status = 'restored';
        end

        function resetCamera(obj)
            obj.restoreCamera(obj.DefaultCamera);
        end

        function fitCamera(obj)
            cleanup = obj.pauseCameraSync(); %#ok<NASGU> Retain synchronization guard until return.
            brainnet.render.CameraState.fit(obj.ActiveAxes);
        end

        function applyCameraGesture(obj, action, delta, selectedAxis)
            if isempty(obj.ActiveAxes) || ~all(isgraphics(obj.ActiveAxes))
                return;
            end
            assert(isscalar(selectedAxis) && isgraphics(selectedAxis) && ...
                any(obj.ActiveAxes==selectedAxis), 'BNV:Render:InvalidCameraAxis', ...
                'The selected view must belong to the active layout.');
            cleanup = obj.pauseCameraSync(); %#ok<NASGU> Keep other views unchanged.
            brainnet.render.CameraGesture.apply(selectedAxis,action,delta);
            obj.synchronizeCameraLighting(selectedAxis);
        end

        function setStandardView(obj, direction)
            cleanup = obj.pauseCameraSync(); %#ok<NASGU> Retain synchronization guard until return.
            assert(isscalar(obj.ActiveAxes), 'BNV:Render:MontageViewLocked', ...
                'Multi-view layouts retain their own view directions.');
            angles = struct('left',[-90 0],'right',[90 0],'anterior',[180 0], ...
                'posterior',[0 0],'superior',[0 90],'inferior',[0 -90]);
            if ~isfield(angles, char(direction))
                error('BNV:Render:UnknownView', 'Unknown standard view.');
            end
            view(obj.ActiveAxes(1), angles.(char(direction)));
            obj.fitCamera();
        end

        function synchronizeInteraction(obj, source)
            if obj.CameraSyncSuspended || isempty(source) || ~isgraphics(source) || ...
                    ~all(isgraphics(obj.ActiveAxes)) || ~any(obj.ActiveAxes == source), return; end
            cleanup = obj.pauseCameraSync(); %#ok<NASGU> Retain synchronization guard until return.
            brainnet.render.CameraState.synchronize(obj.ActiveAxes, source);
        end

        function refreshViewportScale(obj)
            if obj.CameraSyncSuspended || isempty(obj.ActiveAxes) || ...
                    ~all(isgraphics(obj.ActiveAxes)), return; end
            cleanup=obj.pauseCameraSync(); %#ok<NASGU>
            brainnet.render.CameraState.refreshViewport(obj.ActiveAxes);
        end

        function synchronizeCameraLighting(~, axesHandle)
            if isempty(axesHandle) || ~isgraphics(axesHandle, 'axes')
                return;
            end
            lights = findall(axesHandle, 'Type', 'light', ...
                'Tag', 'brainnet-camera-light');
            for lightHandle = reshape(lights, 1, [])
                direction = "headlight";
                if isstruct(lightHandle.UserData) && ...
                        isfield(lightHandle.UserData, 'brainnet_light_direction')
                    direction = string(lightHandle.UserData.brainnet_light_direction);
                end
                try
                    % Updates an existing light in camera coordinates; it does
                    % not create a new light during interactive rotation.
                    camlight(lightHandle, char(direction));
                catch
                end
            end
        end

        function clearGeometryCache(obj)
            remove(obj.GeometryCache, keys(obj.GeometryCache));
            obj.GeometryCacheHitCount = 0;
            obj.GeometryCacheMissCount = 0;
        end

        function value = geometryCacheStatistics(obj)
            value = struct( ...
                'entries', obj.GeometryCache.Count, ...
                'hits', obj.GeometryCacheHitCount, ...
                'misses', obj.GeometryCacheMissCount);
        end

        function closeActiveFigure(obj)
            obj.InspectEnabled=false; obj.InspectCallback=[]; obj.InspectInteractions={};
            for listener = obj.CameraListeners
                delete(listener{1});
            end
            obj.CameraListeners = {};
            if isgraphics(obj.TitleAxes), delete(obj.TitleAxes); end
            obj.TitleAxes = [];
            if ~isempty(obj.ActiveFigure) && isgraphics(obj.ActiveFigure)
                close(obj.ActiveFigure);
            end
            if isempty(obj.ActiveFigure) && ~isempty(obj.ActiveAxes)
                validAxes = obj.ActiveAxes(isgraphics(obj.ActiveAxes));
                if ~isempty(validAxes)
                    delete(validAxes);
                end
            end
            obj.ActiveFigure = [];
            obj.ActiveTarget = [];
            obj.ActiveAxes = [];
        end

        function delete(obj)
            obj.closeActiveFigure();
        end
    end

    methods (Access = private)
        function drawTitle(obj,target,axesHandles,settings,background,embedded)
            if strlength(string(settings.title))==0, return; end
            % Reserve one shared title strip, independent of scientific axes.
            % Empty titles preserve the established montage positions exactly.
            for ax=reshape(axesHandles,1,[])
                position=ax.Position; position([2 4])=position([2 4])*.925;
                ax.Position=position;
            end
            for bar=reshape(findall(target,'Type','ColorBar'),1,[])
                position=bar.Position; position([2 4])=position([2 4])*.925;
                bar.Position=position;
            end
            if embedded
                titleAxes=uiaxes('Parent',target,'Toolbar',[]);
                titleAxes.Interactions=[];
            else
                titleAxes=axes('Parent',target);
            end
            set(titleAxes,'Units','normalized','Position',[.015 .932 .97 .06], ...
                'Visible','off','Color','none','XLim',[0 1],'YLim',[0 1], ...
                'HitTest','off','PickableParts','none','Tag','brainnet-title-axes');
            text(titleAxes,.5,.5,settings.title,'Units','normalized', ...
                'HorizontalAlignment','center','VerticalAlignment','middle', ...
                'FontName','Arial','FontSize',12,'FontWeight','bold', ...
                'Color',obj.contrastColor(background),'Interpreter','none', ...
                'HitTest','off','PickableParts','none','Tag','brainnet-image-title');
            obj.TitleAxes=titleAxes;
        end

        function onInspect(obj,source,event)
            if obj.InspectEnabled && ~isempty(obj.InspectCallback)
                obj.InspectCallback(source,reshape(event.IntersectionPoint,1,3));
            end
        end
        function cleanup = pauseCameraSync(obj)
            previous = obj.CameraSyncSuspended;
            obj.CameraSyncSuspended = true;
            cleanup = onCleanup(@() obj.resumeCameraSync(previous));
        end

        function resumeCameraSync(obj, previous)
            obj.CameraSyncSuspended = previous;
        end

        function [geometry, cacheHit, key] = geometryFor(obj, prepared, policy, renderOptions)
            surface=renderOptions.section('surface');
            direction=0; if surface.double_brain, direction=renderOptions.ViewDirection; end
            styleManifest = struct('double_brain',surface.double_brain,'view_direction',direction, ...
                'node', renderOptions.section("node"), ...
                'edge', renderOptions.section("edge"));
            styleKey = brainnet.render.internal.sha256Text(string(jsonencode(styleManifest)));
            key = prepared.CacheKey + "|n" + string(policy.node_detail) + ...
                "|e" + string(policy.edge_sides) + "|s" + ...
                compose('%.6f', policy.surface_face_fraction) + ...
                "|c" + string(policy.compute_backend) + "|v" + styleKey;
            if isKey(obj.GeometryCache, char(key))
                geometry = obj.GeometryCache(char(key));
                cacheHit = true;
                obj.GeometryCacheHitCount = obj.GeometryCacheHitCount + 1;
                return;
            end
            geometry = obj.buildGeometry(prepared, policy, renderOptions);
            obj.GeometryCache(char(key)) = geometry;
            cacheHit = false;
            obj.GeometryCacheMissCount = obj.GeometryCacheMissCount + 1;
        end

        function [position, windowMode] = resolveWindowPlacement(~, visible, requested, mode)
            allowedModes = ["auto", "centered", "maximized", "manual"];
            if ~any(mode == allowedModes)
                error('BNV:Render:UnsupportedWindowMode', ...
                    'WindowMode must be auto, centered, maximized, or manual.');
            end
            if ~isempty(requested)
                if ~isequal(size(requested), [1 4]) || any(~isfinite(requested)) || ...
                        any(requested(3:4) <= 0)
                    error('BNV:Render:InvalidPosition', ...
                        'Position must be empty or a finite 1-by-4 vector with positive size.');
                end
                position = requested;
                if mode == "auto"
                    windowMode = "manual";
                else
                    windowMode = mode;
                end
                return;
            end
            if visible
                position = brainnet.render.internal.screenAwarePosition( ...
                    [1600 1200], AdaptiveScale=true, ...
                    MonitorFraction=[0.86 0.86], MaximumScale=1.25, ...
                    MinimumSize=[800 600]);
                if mode == "auto"
                    windowMode = "centered-adaptive";
                else
                    windowMode = mode;
                end
            else
                position = [100 100 1600 1200];
                if mode == "auto"
                    windowMode = "hidden-fixed";
                else
                    windowMode = mode;
                end
            end
        end

        function geometry = buildGeometry(obj, prepared, policy, renderOptions)
            coordinates = prepared.NodeCoordinates;
            doubleBrain=brainnet.core.DoubleBrain.transform(prepared,renderOptions);
            if doubleBrain.enabled && ~isempty(coordinates)
                moved=doubleBrain.first_moved_node:size(coordinates,1);
                coordinates(moved,:)=brainnet.core.DoubleBrain.forward(coordinates(moved,:),doubleBrain);
            end
            nodeSettings = renderOptions.section("node");
            edgeSettings = renderOptions.section("edge");
            nodeBasis = obj.nodeBasis(prepared, nodeSettings.size_basis);
            nodeRadii = brainnet.render.internal.nodeRadii(nodeBasis,nodeSettings);
            edgeRadii = brainnet.render.internal.edgeRadii(prepared.EdgeValues,edgeSettings);
            nodeVisible = obj.nodeVisibility(prepared, nodeSettings);
            nodeVisible = nodeVisible & nodeRadii>0;
            nodeColors = obj.nodeColors(prepared, nodeSettings);
            edgeColors = obj.edgeColors(prepared, edgeSettings, nodeSettings);
            edgeAlpha = brainnet.render.internal.edgeOpacity(prepared.EdgeValues, edgeSettings);
            if isempty(coordinates)
                nodeMasks = struct('full', false(0, 1), 'left', false(0, 1), 'right', false(0, 1));
                hemisphereLeft = false(0, 1);
                hemisphereRight = false(0, 1);
            else
                hemisphereLeft = coordinates(:, 1) <= 0;
                hemisphereRight = coordinates(:, 1) > 0;
                nodeMasks = struct('full', nodeVisible, ...
                    'left', nodeVisible & hemisphereLeft, ...
                    'right', nodeVisible & hemisphereRight);
            end
            if isempty(prepared.EdgePairs)
                edgeMasks = struct('full', false(0, 1), 'left', false(0, 1), 'right', false(0, 1));
            else
                pairs = prepared.EdgePairs;
                edgeMasks = struct('full', edgeRadii>0, ...
                    'left', edgeRadii>0 & hemisphereLeft(pairs(:, 1)) & hemisphereLeft(pairs(:, 2)), ...
                    'right', edgeRadii>0 & hemisphereRight(pairs(:, 1)) & hemisphereRight(pairs(:, 2)));
            end

            surfaceVertices = prepared.SurfaceCoordinates.';
            surfaceFaces = prepared.SurfaceFaces;
            if ~isempty(surfaceFaces) && policy.surface_face_fraction < 1 && ...
                    isempty(prepared.SurfaceValues)
                [surfaceFaces, surfaceVertices] = reducepatch( ...
                    surfaceFaces, surfaceVertices, ...
                    policy.surface_face_fraction, 'fast');
            end
            if isempty(surfaceFaces)
                faceMasks = struct('full', false(0, 1), 'left', false(0, 1), 'right', false(0, 1));
            else
                payload = struct('SurfaceCoordinates',surfaceVertices.', ...
                    'SurfaceFaces',surfaceFaces);
                [~, leftFaces] = brainnet.render.internal.layout2Policy(payload);
                faceMasks = struct('full', true(size(surfaceFaces, 1), 1), ...
                    'left', leftFaces, 'right', ~leftFaces);
            end

            scopeNames = ["full", "left", "right"];
            for scopeName = scopeNames
                name = char(scopeName);
                scope = struct;
                scope.node_centers=coordinates;
                scope.double_brain=doubleBrain;
                [scope.surface_vertices, scope.surface_faces, ...
                    scope.surface_vertex_indices] = obj.compactSurface( ...
                    surfaceVertices, surfaceFaces(faceMasks.(name), :));
                [scope.node_vertices, scope.node_faces, scope.node_acceleration] = ...
                    brainnet.render.internal.buildNodeMesh(coordinates, nodeRadii, ...
                    find(nodeMasks.(name)), policy.node_detail, ...
                    Backend=policy.compute_backend);
                arrowLengthScale=0;
                if edgeSettings.directed
                    arrowLengthScale=1;
                    if isfield(edgeSettings,'arrow_length_scale')
                        arrowLengthScale=edgeSettings.arrow_length_scale;
                    end
                end
                [scope.edge_vertices, scope.edge_faces, scope.edge_acceleration] = ...
                    brainnet.render.internal.buildEdgeMesh(coordinates, prepared.EdgePairs, ...
                    edgeRadii, nodeRadii, find(edgeMasks.(name)), policy.edge_sides, ...
                        Backend=policy.compute_backend,ArrowLengthScale=arrowLengthScale);
                scope.node_indices = find(nodeMasks.(name));
                scope.edge_indices = find(edgeMasks.(name));
                scope.node_colors = obj.expandColors(nodeColors, scope.node_indices, ...
                    size(scope.node_vertices, 1));
                scope.edge_colors = obj.expandColors(edgeColors, scope.edge_indices, ...
                    size(scope.edge_vertices, 1));
                scope.edge_alpha = obj.expandValues(edgeAlpha, scope.edge_indices, ...
                    size(scope.edge_vertices, 1));
                [scope.roi_vertices, scope.roi_faces, scope.roi_colors, ...
                    scope.roi_count] = obj.roiGeometryForScope( ...
                    prepared.RoiMeshes, scopeName);
                if edgeSettings.directed
                    [scope.arrow_vertices, scope.arrow_faces] = obj.buildArrowheads( ...
                        coordinates, prepared.EdgePairs, edgeRadii, nodeRadii, ...
                        scope.edge_indices, edgeSettings);
                    scope.arrow_colors = obj.expandColors(edgeColors, scope.edge_indices, ...
                        size(scope.arrow_vertices, 1));
                    scope.arrow_alpha = obj.expandValues(edgeAlpha, scope.edge_indices, ...
                        size(scope.arrow_vertices, 1));
                else
                    scope.arrow_vertices = zeros(0, 3);
                    scope.arrow_faces = zeros(0, 3);
                    scope.arrow_colors = zeros(0, 3);
                    scope.arrow_alpha = zeros(0, 1);
                end
                scope.node_count = nnz(nodeMasks.(name));
                scope.edge_count = nnz(edgeMasks.(name));
                geometry.(name) = scope;
            end
        end

        function patchCount = drawScope(obj, axesHandle, prepared, renderOptions, scope)
            patchCount = 0;
            surfaceSettings = renderOptions.section("surface");
            if prepared.VertexCount > 0
                mapped = ~isempty(prepared.SurfaceValues) && ...
                    string(surfaceSettings.color_mode) == "scalar";
                if string(surfaceSettings.color_mode)=="vertex-rgb"
                    patch(axesHandle,'Faces',scope.surface_faces,'Vertices',scope.surface_vertices, ...
                        'FaceVertexCData',surfaceSettings.vertex_colors(scope.surface_vertex_indices,:), ...
                        'FaceColor','interp','FaceAlpha',surfaceSettings.opacity,'EdgeColor','none', ...
                        'AmbientStrength',0.45,'DiffuseStrength',0.65,'SpecularStrength',0.05, ...
                        'Tag','brainnet-surface-rgb','UserData',struct('surface_indices',scope.surface_vertex_indices));
                elseif ~mapped
                    patch(axesHandle, 'Faces', scope.surface_faces, ...
                        'Vertices', scope.surface_vertices, ...
                        'FaceColor', surfaceSettings.color, ...
                        'FaceAlpha', surfaceSettings.opacity, ...
                        'EdgeColor', 'none', 'AmbientStrength', 0.45, ...
                        'DiffuseStrength', 0.65, 'SpecularStrength', 0.05, ...
                        'Tag', 'brainnet-surface-uniform','UserData',struct('surface_indices',scope.surface_vertex_indices));
                else
                    surfaceValues = prepared.SurfaceValues(:);
                    patch(axesHandle, 'Faces', scope.surface_faces, ...
                        'Vertices', scope.surface_vertices, ...
                        'FaceVertexCData', surfaceValues(scope.surface_vertex_indices), ...
                        'FaceColor', 'interp', 'FaceAlpha', surfaceSettings.opacity, ...
                        'EdgeColor', 'none', 'AmbientStrength', 0.55, ...
                        'DiffuseStrength', 0.55, 'SpecularStrength', 0.03, ...
                        'Tag', 'brainnet-surface-mapped','UserData',struct('surface_indices',scope.surface_vertex_indices));
                end
                patchCount = patchCount + 1;
            end
            if ~isempty(scope.roi_faces)
                patch(axesHandle, 'Faces', scope.roi_faces, ...
                    'Vertices', scope.roi_vertices, ...
                    'FaceVertexCData', scope.roi_colors, ...
                    'FaceColor', 'flat', 'FaceAlpha', 0.88, ...
                    'EdgeColor', 'none', 'AmbientStrength', 0.42, ...
                    'DiffuseStrength', 0.68, 'SpecularStrength', 0.08, ...
                    'Tag', 'brainnet-volume-roi');
                patchCount = patchCount + 1;
            end
            if ~isempty(scope.edge_faces)
                patch(axesHandle, 'Faces', scope.edge_faces, 'Vertices', scope.edge_vertices, ...
                    'FaceVertexCData', scope.edge_colors, 'FaceColor', 'interp', ...
                    'FaceVertexAlphaData', scope.edge_alpha, 'FaceAlpha', 'interp', ...
                    'EdgeColor', 'none', 'AmbientStrength', 0.50, ...
                    'DiffuseStrength', 0.60, 'SpecularStrength', 0.05, ...
                    'Tag', 'brainnet-edges');
                patchCount = patchCount + 1;
            end
            if ~isempty(scope.arrow_faces)
                patch(axesHandle, 'Faces', scope.arrow_faces, ...
                    'Vertices', scope.arrow_vertices, ...
                    'FaceVertexCData', scope.arrow_colors, 'FaceColor', 'interp', ...
                    'FaceVertexAlphaData', scope.arrow_alpha, 'FaceAlpha', 'interp', ...
                    'EdgeColor', 'none', 'AmbientStrength', 0.50, ...
                    'DiffuseStrength', 0.60, 'SpecularStrength', 0.05, ...
                    'Tag', 'brainnet-edge-arrows');
                patchCount = patchCount + 1;
            end
            if ~isempty(scope.node_faces)
                nodePatch=patch(axesHandle, 'Faces', scope.node_faces, 'Vertices', scope.node_vertices, ...
                    'FaceVertexCData', scope.node_colors, 'FaceColor', 'interp', ...
                    'FaceAlpha', 1, ...
                    'EdgeColor', 'none', 'AmbientStrength', 0.40, ...
                    'DiffuseStrength', 0.70, 'SpecularStrength', 0.10, ...
                    'Tag', 'brainnet-nodes');
                nodePatch.UserData=struct('brainnet_node_indices',scope.node_indices);
                if scope.double_brain.enabled, nodePatch.UserData.double_brain=scope.double_brain; end
                patchCount = patchCount + 1;
            end
            obj.drawNodeLabels(axesHandle, prepared, scope, renderOptions.section("node"));
        end

        function visible = nodeVisibility(obj, prepared, settings)
            count = prepared.NodeCount;
            visible = true(count, 1);
            switch string(settings.selection_mode)
                case "threshold"
                    values = obj.nodeBasis(prepared, settings.selection_basis);
                    visible = values > settings.threshold;
                case "connected"
                    visible = false(count, 1);
                    if ~isempty(prepared.EdgePairs)
                        visible(unique(prepared.EdgePairs(:))) = true;
                    end
            end
        end

        function values = nodeBasis(~, prepared, basis)
            if string(basis) == "module"
                values = prepared.NodeModules(:);
            else
                values = prepared.NodeSizes(:);
            end
        end

        function colors = nodeColors(obj, prepared, settings)
            count = prepared.NodeCount;
            colors = repmat(settings.color, count, 1);
            switch string(settings.color_mode)
                case "mapped"
                    colors = obj.mapColors(prepared.NodeModules, settings.colormap, ...
                        settings.color_limits);
                case "modular"
                    colors = obj.categoricalColors(prepared.NodeModules, settings.colormap);
                case "threshold"
                    high = prepared.NodeModules > settings.color_threshold;
                    colors = repmat(settings.color_low,count,1);
                    colors(high, :) = repmat(settings.color_high,nnz(high),1);
                case "custom"
                    colors = obj.categoricalColors(prepared.NodeModules, settings.colormap);
            end
        end

        function colors = edgeColors(~, prepared, settings, nodeSettings)
            count = prepared.EdgeCount;
            colors = repmat(settings.color, count, 1);
            if count == 0 && string(settings.color_mode)~="custom"
                return;
            end
            values = prepared.EdgeValues(:);
            switch string(settings.color_mode)
                case "mapped"
                    colors = brainnet.render.internal.mappedEdgeColors(values, settings);
                case "threshold"
                    if string(settings.threshold_value_mode)=="absolute", values=abs(values); end
                    high = values > settings.color_threshold;
                    colors = repmat(settings.color_low,count,1);
                    colors(high,:) = repmat(settings.color_high,nnz(high),1);
                case "length"
                    pairs = prepared.EdgePairs;
                    delta = prepared.NodeCoordinates(pairs(:, 1), :) - ...
                        prepared.NodeCoordinates(pairs(:, 2), :);
                    lengths = sqrt(sum(delta .^ 2, 2));
                    high = lengths >= settings.length_threshold;
                    colors = repmat(settings.color_low,count,1);
                    colors(high,:) = repmat(settings.color_high,nnz(high),1);
                case "node-module"
                    colors = brainnet.render.internal.moduleEdgeColors(prepared.NodeModules,prepared.EdgePairs,settings,nodeSettings.colormap);
                case "custom"
                    colors = brainnet.core.CustomEdgeColors.resolve(settings.custom_color,settings.colormap,prepared.NodeCoordinates,prepared.EdgePairs);
            end
        end

        function colors = mapColors(obj, values, mapName, limits)
            values = double(values(:));
            if isempty(values)
                colors = zeros(0, 3);
                return;
            end
            map = obj.namedColormap(mapName, 256);
            if isempty(limits)
                finiteValues = values(isfinite(values));
                if isempty(finiteValues)
                    limits = [0 1];
                else
                    limits = [min(finiteValues) max(finiteValues)];
                end
            end
            if limits(2) <= limits(1)
                indices = ones(size(values));
            else
                indices = 1 + round((size(map, 1) - 1) * ...
                    (values - limits(1)) / (limits(2) - limits(1)));
            end
            indices = min(max(indices, 1), size(map, 1));
            colors = map(indices, :);
        end

        function colors = categoricalColors(obj, values, mapName)
            values = double(values(:));
            if isempty(values)
                colors = zeros(0, 3);
                return;
            end
            [~, ~, indices] = unique(values, 'sorted');
            if isnumeric(mapName)
                map = brainnet.core.Colormap.validate(mapName);
                indices = 1 + mod(indices - 1, size(map,1));
            else
                map = obj.namedColormap(mapName, max(2, max(indices)));
            end
            colors = map(indices, :);
        end

        function map = namedColormap(~, name, count)
            map = brainnet.core.Colormap.sample(name,count);
        end

        function [map, limits] = volumeColormap(~, values, settings)
            [map, limits] = brainnet.render.internal.volumeColormap(values, settings);
        end

        function expanded = expandColors(~, colors, indices, vertexCount)
            if isempty(indices) || vertexCount == 0
                expanded = zeros(0, 3);
                return;
            end
            repeatCount = vertexCount / numel(indices);
            expanded = repelem(colors(indices, :), repeatCount, 1);
        end

        function expanded = expandValues(~, values, indices, vertexCount)
            if isempty(indices) || vertexCount == 0
                expanded = zeros(0, 1);
                return;
            end
            repeatCount = vertexCount / numel(indices);
            expanded = repelem(values(indices), repeatCount, 1);
        end

        function [vertices, faces] = buildArrowheads(~, coordinates, pairs, ...
                edgeRadii, nodeRadii, indices, settings)
            if isempty(indices)
                vertices = zeros(0, 3);
                faces = zeros(0, 3, 'uint32');
                return;
            end
            selected = pairs(indices, :);
            pointA = coordinates(selected(:, 1), :);
            pointB = coordinates(selected(:, 2), :);
            direction = pointB - pointA;
            lengths = sqrt(sum(direction .^ 2, 2));
            unit = direction ./ max(lengths,eps);
            reference = repmat([0 0 1], numel(indices), 1);
            nearParallel = abs(unit(:, 3)) >= 0.9;
            reference(nearParallel, :) = repmat([0 1 0], nnz(nearParallel), 1);
            axisU = cross(unit, reference, 2);
            axisU = axisU ./ sqrt(sum(axisU .^ 2, 2));
            axisV = cross(unit, axisU, 2);
            lengthScale=1; widthScale=1;
            if isfield(settings,'arrow_length_scale'), lengthScale=settings.arrow_length_scale; end
            if isfield(settings,'arrow_width_scale'), widthScale=settings.arrow_width_scale; end
            [~,trimB,arrowLength]=brainnet.render.internal.edgeArrowTrims( ...
                lengths,nodeRadii(selected(:,1)),nodeRadii(selected(:,2)), ...
                edgeRadii(indices),lengthScale);
            tip = pointB - trimB .* unit;
            arrowWidth = widthScale * max(0.5, 2.5 * edgeRadii(indices));
            base = tip - arrowLength .* unit;
            angles=2*pi*(0:7)/8;
            ring=reshape(base,[],1,3) + ...
                reshape(arrowWidth,[],1,1) .* ( ...
                reshape(cos(angles),1,[],1).*reshape(axisU,[],1,3) + ...
                reshape(sin(angles),1,[],1).*reshape(axisV,[],1,3));
            verticesByArrow = cat(2, reshape(tip, [], 1, 3), ring);
            vertices = reshape(permute(verticesByArrow, [2 1 3]), [], 3);
            baseFaces = uint32([ones(8,1) (2:9)' [3:9 2]'; ...
                repmat(2,6,1) (4:9)' (3:8)']);
            offsets = repelem(uint32((0:(numel(indices) - 1)).') * 9, ...
                size(baseFaces, 1), 1);
            faces = repmat(baseFaces, numel(indices), 1) + offsets;
        end

        function drawNodeLabels(obj, axesHandle, prepared, scope, settings)
            if isempty(scope.node_indices) || string(settings.label_mode) == "none"
                return;
            end
            indices = scope.node_indices;
            if string(settings.label_mode) == "threshold"
                values = obj.nodeBasis(prepared, settings.label_basis);
                indices = indices(values(indices) > settings.label_threshold);
            end
            indices = indices(prepared.NodeLabels(indices) ~= "-");
            coordinates = scope.node_centers(indices, :);
            radii=brainnet.render.internal.nodeRadii(obj.nodeBasis(prepared,settings.size_basis),settings);
            handles=gobjects(numel(indices),1);
            for index = 1:numel(indices)
                handles(index)=text(axesHandle, coordinates(index,1),coordinates(index,2),coordinates(index,3), ...
                    char(prepared.NodeLabels(indices(index))), ...
                    'FontName',char(settings.label_font_name),'FontUnits',char(settings.label_font_units), ...
                    'FontSize',settings.label_font_size,'FontWeight',char(settings.label_font_weight), ...
                    'FontAngle',char(settings.label_font_angle),'Color',settings.label_color, ...
                    'Clipping','on','Interpreter','none','HorizontalAlignment','center', ...
                    'VerticalAlignment','bottom','Tag','brainnet-node-label','HitTest','off','PickableParts','none');
                handles(index).UserData=struct('brainnet_node_index',indices(index));
            end
            low=[inf inf inf]; high=-low;
            for field=["surface_vertices","node_vertices","edge_vertices","arrow_vertices","roi_vertices"]
                if isfield(scope,field) && ~isempty(scope.(field))
                    low=min(low,min(scope.(field),[],1)); high=max(high,max(scope.(field),[],1));
                end
            end
            if isempty(indices), return; end
            setappdata(axesHandle,'brainnet_label_layout',struct('handles',handles,'coordinates',coordinates, ...
                'radii',radii(indices),'low',low,'high',high,'front',settings.label_in_front));
        end

        function drawSurfaceBoundary(~, axesHandle, prepared, scope, settings)
            if string(settings.boundary_mode) ~= "automatic" || ...
                    isempty(prepared.SurfaceValues) || isempty(scope.surface_faces) || ...
                    isempty(scope.surface_vertex_indices) || ...
                    max(scope.surface_vertex_indices) > numel(prepared.SurfaceValues)
                return;
            end
            boundary=brainnet.render.internal.surfaceBoundary(prepared.SurfaceValues, ...
                scope.surface_faces,string(settings.boundary_mode),VertexIndices=scope.surface_vertex_indices);
            edges=boundary.edges;
            if isempty(edges)
                return;
            end
            vertices = scope.surface_vertices;
            x = [vertices(edges(:, 1), 1), vertices(edges(:, 2), 1), nan(size(edges, 1), 1)].';
            y = [vertices(edges(:, 1), 2), vertices(edges(:, 2), 2), nan(size(edges, 1), 1)].';
            z = [vertices(edges(:, 1), 3), vertices(edges(:, 2), 3), nan(size(edges, 1), 1)].';
            line(axesHandle, x(:), y(:), z(:), 'Color', settings.boundary_color, ...
                'LineWidth', 1.0, 'Tag', 'brainnet-surface-boundary');
        end

        function [vertices, faces, vertexIndices] = compactSurface(~, allVertices, selectedFaces)
            if isempty(selectedFaces)
                vertices = zeros(0, 3);
                faces = zeros(0, 3);
                vertexIndices = zeros(0, 1);
                return;
            end
            vertexIndices = unique(selectedFaces(:), 'sorted');
            remap = zeros(size(allVertices, 1), 1);
            remap(vertexIndices) = 1:numel(vertexIndices);
            vertices = allVertices(vertexIndices, :);
            faces = reshape(remap(selectedFaces), size(selectedFaces));
        end

        function [vertices, faces, colors, roiCount] = ...
                roiGeometryForScope(obj, source, scopeName)
            vertexParts = cell(1, numel(source));
            faceParts = cell(1, numel(source));
            colorParts = cell(1, numel(source));
            roiCount = 0;
            vertexOffset = 0;
            for index = 1:numel(source)
                item = source(index);
                selectedFaces = item.faces;
                if scopeName ~= "full" && ~isempty(selectedFaces)
                    faceX = mean(reshape(item.vertices(selectedFaces, 1), ...
                        size(selectedFaces)), 2);
                    if scopeName == "left"
                        selectedFaces = selectedFaces(faceX <= 0, :);
                    else
                        selectedFaces = selectedFaces(faceX > 0, :);
                    end
                end
                [compactVertices, compactFaces] = obj.compactSurface( ...
                    item.vertices, selectedFaces);
                if isempty(compactFaces)
                    continue;
                end
                roiCount = roiCount + 1;
                vertexParts{roiCount} = compactVertices;
                faceParts{roiCount} = compactFaces + vertexOffset;
                colorParts{roiCount} = repmat(item.color, ...
                    size(compactVertices, 1), 1);
                vertexOffset = vertexOffset + size(compactVertices, 1);
            end
            if roiCount == 0
                vertices = zeros(0, 3);
                faces = zeros(0, 3);
                colors = zeros(0, 3);
            else
                vertices = vertcat(vertexParts{1:roiCount});
                faces = vertcat(faceParts{1:roiCount});
                colors = vertcat(colorParts{1:roiCount});
            end
        end

        function applyAppearance(obj, axesHandle, settings)
            candidates = findall(axesHandle, 'Type', 'patch');
            surface = candidates(startsWith(string(get(candidates, 'Tag')), ...
                "brainnet-surface"));
            if ~isempty(surface)
                switch string(settings.shading)
                    case "faceted"
                        for item = reshape(surface, 1, [])
                            if ismember(string(item.Tag),["brainnet-surface-mapped","brainnet-surface-rgb"])
                                item.FaceColor = 'flat';
                            end
                            % Opaque black mesh edges avoid costly per-edge
                            % alpha compositing on dense triangulated meshes.
                            item.EdgeColor = [0 0 0];
                            item.EdgeAlpha = 1;
                        end
                    case "flat"
                        for item = reshape(surface, 1, [])
                            if ismember(string(item.Tag),["brainnet-surface-mapped","brainnet-surface-rgb"])
                                item.FaceColor = 'flat';
                            end
                            item.EdgeColor = 'none';
                        end
                    otherwise
                        for item = reshape(surface, 1, [])
                            if ismember(string(item.Tag),["brainnet-surface-mapped","brainnet-surface-rgb"])
                                item.FaceColor = 'interp';
                            end
                            item.EdgeColor = 'none';
                        end
                end
            end
            try
                if string(settings.material_profile)=="custom"
                    material(axesHandle,settings.material_coefficients);
                else
                    material(axesHandle,char(settings.material_profile));
                end
                lightingMode = char(settings.lighting);
                lighting(axesHandle, lightingMode);
                if ~strcmp(lightingMode, 'none')
                    lightHandle = camlight(axesHandle, char(settings.light_direction));
                    lightHandle.Tag = 'brainnet-camera-light';
                    lightHandle.UserData = struct('brainnet_light_direction', ...
                        char(settings.light_direction));
                end
            catch
                try
                    lighting(axesHandle, 'gouraud');
                    lightHandle = camlight(axesHandle, char(settings.light_direction));
                    lightHandle.Tag = 'brainnet-camera-light';
                    lightHandle.UserData = struct('brainnet_light_direction', ...
                        char(settings.light_direction));
                catch
                end
            end
        end

        function [positions, views, scopes, policy, cameraUps] = layout(~, prepared, renderOptions)
            policy = struct('mode','fixed','reason','selected-layout');
            if renderOptions.Layout == 1
                positions = [0.03 0.03 0.94 0.94];
                layoutSettings = renderOptions.section("layout");
                viewTable = [-90 0; 0 90; 180 0; -45 25; ...
                    90 0; 0 -90; 0 0; -45 25];
                direction = min(max(renderOptions.ViewDirection, 1), ...
                    size(viewTable, 1));
                if direction == 4 && ~isempty(layoutSettings.custom_azimuth)
                    views = [layoutSettings.custom_azimuth, ...
                        layoutSettings.custom_elevation];
                else
                    views = viewTable(direction, :);
                end
                scopes = "full";
                cameraUps = nan(1,3);
                return;
            end
            if ismember(renderOptions.Layout,[3 4 5])
                splitPolicy=brainnet.render.internal.layout2Policy(prepared);
                if strcmp(splitPolicy.mode,'six-full')
                    % A continuous or one-sided mesh is not two hemispheres.
                    % Persisted split presets fall back safely to the full-surface
                    % overview instead of clipping it at X=0.
                    policy=splitPolicy;
                    policy.reason='hemisphere-split-layout-unavailable';
                    positions=[0.005 0.520 0.325 0.470; ...
                        0.3375 0.520 0.325 0.470; 0.670 0.520 0.325 0.470; ...
                        0.005 0.010 0.325 0.470; 0.3375 0.010 0.325 0.470; ...
                        0.670 0.010 0.325 0.470];
                    views=[-90 0; 0 90; 180 0; 90 0; 0 -90; 0 0];
                    scopes=repmat("full",6,1);
                    cameraUps=nan(6,3);
                    return;
                end
            end
            switch renderOptions.Layout
                case 2
                    policy = brainnet.render.internal.layout2Policy(prepared);
                    if strcmp(policy.mode,'six-full')
                        positions = [0.005 0.520 0.325 0.470; ...
                            0.3375 0.520 0.325 0.470; 0.670 0.520 0.325 0.470; ...
                            0.005 0.010 0.325 0.470; 0.3375 0.010 0.325 0.470; ...
                            0.670 0.010 0.325 0.470];
                        views = [-90 0; 0 90; 180 0; 90 0; 0 -90; 0 0];
                        scopes = repmat("full",6,1);
                        cameraUps=nan(6,3);
                        return;
                    end
                    positions = [ ...
                        0.005 0.665 0.325 0.325; ...
                        0.3375 0.665 0.325 0.325; ...
                        0.670 0.665 0.325 0.325; ...
                        0.005 0.340 0.325 0.315; ...
                        0.3375 0.015 0.325 0.580; ...
                        0.670 0.340 0.325 0.315; ...
                        0.005 0.015 0.325 0.315; ...
                        0.670 0.015 0.325 0.315];
                    views = [-90 0; 0 90; 90 0; 90 0; 0 -90; -90 0; 180 0; 0 0];
                    scopes = ["left"; "full"; "right"; "left"; ...
                        "full"; "right"; "full"; "full"];
                case 3
                    positions = [ ...
                        0.035 0.520 0.450 0.440; ...
                        0.515 0.520 0.450 0.440; ...
                        0.035 0.040 0.450 0.440; ...
                        0.515 0.040 0.450 0.440];
                    views = [-90 0; 90 0; 90 0; -90 0];
                    scopes = ["left"; "right"; "left"; "right"];
                case 4
                    positions = [ ...
                        0.015 0.675 0.470 0.310; ...
                        0.515 0.675 0.470 0.310; ...
                        0.015 0.345 0.470 0.310; ...
                        0.515 0.345 0.470 0.310; ...
                        0.015 0.015 0.470 0.310; ...
                        0.515 0.015 0.470 0.310];
                    views = [-90 0; 90 0; 90 0; -90 0; -90 -90; 90 -90];
                    scopes = ["left"; "right"; "left"; "right"; "left"; "right"];
                case 5
                    positions = [ ...
                        0.005 0.540 0.285 0.450; ...
                        0.295 0.270 0.410 0.460; ...
                        0.710 0.540 0.285 0.450; ...
                        0.005 0.010 0.285 0.450; ...
                        0.710 0.010 0.285 0.450];
                    views = [-90 0; 0 90; 90 0; 90 0; -90 0];
                    scopes = ["left"; "full"; "right"; "left"; "right"];
            end
            cameraUps=nan(size(views,1),3);
            if renderOptions.Layout==4
                % Rotate ventral panes outwards so each occupies its wide pane.
                cameraUps(5,:)=[-1 0 0];
                cameraUps(6,:)=[1 0 0];
            end
        end

        function limits = colorLimits(~, values, renderOptions)
            finiteValues = values(isfinite(values));
            if isempty(finiteValues)
                limits = [0 1];
                return;
            end
            lower = min(finiteValues);
            upper = max(finiteValues);
            if ~isempty(renderOptions.NegativeMinimum)
                lower = renderOptions.NegativeMinimum;
            end
            if ~isempty(renderOptions.PositiveMaximum)
                upper = renderOptions.PositiveMaximum;
            end
            if upper <= lower
                upper = lower + 1;
            end
            limits = [lower upper];
        end

        function limits = sectionColorLimits(obj, values, requested, renderOptions)
            if isempty(requested)
                limits = obj.colorLimits(values, renderOptions);
            else
                limits = requested;
                if limits(2) <= limits(1)
                    limits(2) = limits(1) + 1;
                end
            end
        end

        function color = contrastColor(~, background)
            if dot(background, [0.2126 0.7152 0.0722]) < 0.48
                color = [1 1 1];
            else
                color = [0 0 0];
            end
        end

        function summary = geometrySummary(~, geometry)
            summary = struct;
            for name = ["full", "left", "right"]
                scope = geometry.(name);
                summary.(name) = struct( ...
                    'surface_vertex_count', size(scope.surface_vertices, 1), ...
                    'surface_face_count', size(scope.surface_faces, 1), ...
                    'node_count', scope.node_count, ...
                    'node_vertex_count', size(scope.node_vertices, 1), ...
                    'node_face_count', size(scope.node_faces, 1), ...
                    'edge_count', scope.edge_count, ...
                    'edge_vertex_count', size(scope.edge_vertices, 1), ...
                    'edge_face_count', size(scope.edge_faces, 1), ...
                    'roi_mesh_count', scope.roi_count, ...
                    'roi_vertex_count', size(scope.roi_vertices, 1), ...
                    'roi_face_count', size(scope.roi_faces, 1), ...
                    'arrow_vertex_count', size(scope.arrow_vertices, 1), ...
                    'arrow_face_count', size(scope.arrow_faces, 1), ...
                    'node_acceleration', scope.node_acceleration, ...
                    'edge_acceleration', scope.edge_acceleration);
            end
        end
    end
end
