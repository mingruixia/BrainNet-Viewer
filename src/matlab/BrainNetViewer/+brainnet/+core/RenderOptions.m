classdef RenderOptions
    %RENDEROPTIONS Explicit subset of legacy EC required by scene contracts.

    properties (SetAccess = private)
        Layout (1, 1) double = 1
        ViewDirection (1, 1) double = 1
        MeshAlpha (1, 1) double = 0.3
        NodeLabels (1, 1) double = 2
        EdgeDrawMode (1, 1) double = 1
        EdgeThreshold (1, 1) double = 0
        VolumeDisplay (1, 1) logical = false
        VolumeType (1, 1) double = 1
        MapAlgorithm (1, 1) double = 2
        RoiDrawAll (1, 1) logical = true
        PositiveMaximum double = []
        NegativeMinimum double = []
        Settings (1, 1) brainnet.core.VisualizationSettings = brainnet.core.VisualizationSettings()
    end

    methods
        function obj = RenderOptions(options)
            arguments
                options.Layout (1, 1) double = 1
                options.ViewDirection (1, 1) double = 1
                options.MeshAlpha (1, 1) double = 0.3
                options.NodeLabels (1, 1) double = 2
                options.EdgeDrawMode (1, 1) double = 1
                options.EdgeThreshold (1, 1) double = 0
                options.VolumeDisplay (1, 1) logical = false
                options.VolumeType (1, 1) double = 1
                options.MapAlgorithm (1, 1) double = 2
                options.RoiDrawAll (1, 1) logical = true
                options.PositiveMaximum double = []
                options.NegativeMinimum double = []
                options.Settings (1, 1) brainnet.core.VisualizationSettings = brainnet.core.VisualizationSettings()
                options.UseSettingsAsSource (1, 1) logical = false
            end
            brainnet.core.RenderOptions.requireInteger(options.Layout, 'Layout', 1);
            brainnet.core.RenderOptions.requireInteger(options.ViewDirection, 'ViewDirection', 1);
            brainnet.core.RenderOptions.requireRange(options.MeshAlpha, 'MeshAlpha', 0, 1);
            brainnet.core.RenderOptions.requireInteger(options.NodeLabels, 'NodeLabels', 0);
            brainnet.core.RenderOptions.requireInteger(options.EdgeDrawMode, 'EdgeDrawMode', 0);
            brainnet.core.RenderOptions.requireOptionalScalar(options.EdgeThreshold, 'EdgeThreshold');
            brainnet.core.RenderOptions.requireInteger(options.VolumeType, 'VolumeType', 1);
            brainnet.core.RenderOptions.requireInteger(options.MapAlgorithm, 'MapAlgorithm', 1);
            brainnet.core.RenderOptions.requireOptionalScalar(options.PositiveMaximum, 'PositiveMaximum');
            brainnet.core.RenderOptions.requireOptionalScalar(options.NegativeMinimum, 'NegativeMinimum');

            obj.Layout = options.Layout;
            obj.ViewDirection = options.ViewDirection;
            obj.MeshAlpha = options.MeshAlpha;
            obj.NodeLabels = options.NodeLabels;
            obj.EdgeDrawMode = options.EdgeDrawMode;
            obj.EdgeThreshold = options.EdgeThreshold;
            obj.VolumeDisplay = options.VolumeDisplay;
            obj.VolumeType = options.VolumeType;
            obj.MapAlgorithm = options.MapAlgorithm;
            obj.RoiDrawAll = options.RoiDrawAll;
            obj.PositiveMaximum = options.PositiveMaximum;
            obj.NegativeMinimum = options.NegativeMinimum;
            patch = struct( ...
                'layout', struct('preset', options.Layout, ...
                    'view_direction', options.ViewDirection), ...
                'surface', struct('opacity', options.MeshAlpha), ...
                'node', struct('label_mode', char( ...
                    brainnet.core.RenderOptions.labelModeName(options.NodeLabels))), ...
                'edge', struct('selection_mode', char( ...
                    brainnet.core.RenderOptions.edgeSelectionName(options.EdgeDrawMode)), ...
                    'threshold', options.EdgeThreshold), ...
                'volume', struct('display', options.VolumeDisplay, ...
                    'type', char(brainnet.core.RenderOptions.volumeTypeName(options.VolumeType)), ...
                    'map_algorithm', options.MapAlgorithm, ...
                    'positive_maximum', options.PositiveMaximum, ...
                    'negative_minimum', options.NegativeMinimum), ...
                'roi', struct('draw_all', options.RoiDrawAll));
            if options.UseSettingsAsSource
                obj.Settings = options.Settings;
            else
                obj.Settings = options.Settings.withPatch(patch);
            end
        end

        function value = toStruct(obj)
            value = struct;
            value.layout = obj.Layout;
            value.view_direction = obj.ViewDirection;
            value.mesh_alpha = obj.MeshAlpha;
            value.node_labels = obj.NodeLabels;
            value.edge_draw_mode = obj.EdgeDrawMode;
            value.edge_threshold = obj.EdgeThreshold;
            value.volume_display = obj.VolumeDisplay;
            value.volume_type = obj.VolumeType;
            value.map_algorithm = obj.MapAlgorithm;
            value.roi_draw_all = obj.RoiDrawAll;
            value.positive_maximum = obj.PositiveMaximum;
            value.negative_minimum = obj.NegativeMinimum;
            value.visualization_settings = obj.Settings.toStruct();
        end

        function value = toVisualizationStruct(obj)
            value = obj.Settings.toStruct();
        end

        function text = toVisualizationJson(obj)
            text = obj.Settings.toJson();
        end

        function value = section(obj, name)
            value = obj.Settings.section(name);
        end

        function obj = withPatch(obj, patch)
            settings = obj.Settings.withPatch(patch);
            obj = brainnet.core.RenderOptions.fromVisualizationStruct(settings.toStruct());
        end
    end

    methods (Static)
        function obj = fromStruct(value)
            arguments
                value (1, 1) struct
            end
            if isfield(value, 'visualization_settings')
                obj = brainnet.core.RenderOptions.fromVisualizationStruct( ...
                    value.visualization_settings);
                return;
            end
            get = @(field, fallback) brainnet.core.RenderOptions.fieldOr(value, field, fallback);
            obj = brainnet.core.RenderOptions( ...
                Layout=get('layout', 1), ...
                ViewDirection=get('view_direction', 1), ...
                MeshAlpha=get('mesh_alpha', 0.3), ...
                NodeLabels=get('node_labels', 2), ...
                EdgeDrawMode=get('edge_draw_mode', 1), ...
                EdgeThreshold=get('edge_threshold', 0), ...
                VolumeDisplay=logical(get('volume_display', false)), ...
                VolumeType=get('volume_type', 1), ...
                MapAlgorithm=get('map_algorithm', 5), ...
                RoiDrawAll=logical(get('roi_draw_all', true)), ...
                PositiveMaximum=get('positive_maximum', []), ...
                NegativeMinimum=get('negative_minimum', []));
            if logical(get('volume_display', false))
                obj = obj.withPatch(struct('surface', struct('color_mode', 'scalar')));
            end
        end

        function obj = fromVisualizationStruct(value)
            arguments
                value (1, 1) struct
            end
            settings = brainnet.core.VisualizationSettings.fromStruct(value);
            layout = settings.section("layout");
            surface = settings.section("surface");
            node = settings.section("node");
            edge = settings.section("edge");
            volume = settings.section("volume");
            roi = settings.section("roi");
            obj = brainnet.core.RenderOptions( ...
                Layout=layout.preset, ...
                ViewDirection=layout.view_direction, ...
                MeshAlpha=surface.opacity, ...
                NodeLabels=brainnet.core.RenderOptions.labelModeCode(node.label_mode), ...
                EdgeDrawMode=brainnet.core.RenderOptions.edgeSelectionCode(edge.selection_mode), ...
                EdgeThreshold=edge.threshold, ...
                VolumeDisplay=volume.display, ...
                VolumeType=brainnet.core.RenderOptions.volumeTypeCode(volume.type), ...
                MapAlgorithm=volume.map_algorithm, ...
                RoiDrawAll=roi.draw_all, ...
                PositiveMaximum=volume.positive_maximum, ...
                NegativeMinimum=volume.negative_minimum, ...
                Settings=settings, UseSettingsAsSource=true);
        end

        function obj = fromVisualizationJson(text)
            arguments
                text (1, 1) string
            end
            obj = brainnet.core.RenderOptions.fromVisualizationStruct(jsondecode(text));
        end

        function obj = fromGoldenScene(scene)
            arguments
                scene (1, 1) struct
            end
            settings = scene.settings;
            mapMode = scene.map_mode;
            positiveMaximum = [];
            negativeMinimum = [];
            if mapMode == 1 && isfield(scene.inputs, 'surface_map')
                positiveMaximum = scene.inputs.surface_map.maximum;
                negativeMinimum = scene.inputs.surface_map.minimum;
            elseif mapMode == 2 && isfield(scene.inputs, 'volume')
                positiveMaximum = scene.inputs.volume.finite_maximum;
                negativeMinimum = scene.inputs.volume.finite_minimum;
            end
            hasEdgeThreshold = isfield(settings, 'edge_threshold');
            edgeThreshold = brainnet.core.RenderOptions.fieldOr(settings, 'edge_threshold', 0);
            edgeDrawMode = 1 + hasEdgeThreshold;
            obj = brainnet.core.RenderOptions( ...
                Layout=brainnet.core.RenderOptions.fieldOr(settings, 'layout', 1), ...
                ViewDirection=brainnet.core.RenderOptions.fieldOr(settings, 'view_direction', 1), ...
                MeshAlpha=brainnet.core.RenderOptions.fieldOr(settings, 'mesh_alpha', 0.3), ...
                NodeLabels=brainnet.core.RenderOptions.fieldOr(settings, 'node_labels', 2), ...
                EdgeDrawMode=edgeDrawMode, ...
                EdgeThreshold=edgeThreshold, ...
                VolumeDisplay=mapMode > 0, ...
                VolumeType=brainnet.core.RenderOptions.fieldOr(settings, 'volume_type', 1), ...
                MapAlgorithm=brainnet.core.RenderOptions.fieldOr(settings, 'map_algorithm', 5), ...
                RoiDrawAll=logical(brainnet.core.RenderOptions.fieldOr(settings, 'roi_draw_all', 1)), ...
                PositiveMaximum=positiveMaximum, ...
                NegativeMinimum=negativeMinimum);
            if mapMode > 0
                obj = obj.withPatch(struct('surface', struct('color_mode', 'scalar')));
            end
        end

        function [obj, report] = fromLegacy(configuration, mapMode)
            arguments
                configuration (1, 1) struct
                mapMode (1, 1) double
            end
            [settings, report] = brainnet.core.VisualizationSettings.fromLegacy( ...
                configuration, mapMode);
            obj = brainnet.core.RenderOptions.fromVisualizationStruct(settings.toStruct());
        end
    end

    methods (Static, Access = private)
        function value = fieldOr(source, fieldName, fallback)
            if isfield(source, fieldName)
                value = source.(fieldName);
            else
                value = fallback;
            end
        end

        function value = nestedOr(source, path, fallback)
            value = source;
            for index = 1:numel(path)
                if ~isstruct(value) || ~isfield(value, path{index})
                    value = fallback;
                    return;
                end
                value = value.(path{index});
            end
            if isempty(value)
                value = fallback;
            end
        end

        function requireInteger(value, name, minimum)
            if ~isfinite(value) || value ~= fix(value) || value < minimum
                error('BNV:Core:InvalidRenderOption', '%s must be an integer >= %g.', name, minimum);
            end
        end

        function requireRange(value, name, minimum, maximum)
            if ~isfinite(value) || value < minimum || value > maximum
                error('BNV:Core:InvalidRenderOption', '%s must be in [%g, %g].', name, minimum, maximum);
            end
        end

        function requireOptionalScalar(value, name)
            if ~isempty(value) && (~isscalar(value) || ~isfinite(value))
                error('BNV:Core:InvalidRenderOption', '%s must be empty or a finite scalar.', name);
            end
        end

        function value = labelModeName(code)
            names = ["all", "none", "threshold"];
            value = names(code);
        end

        function value = labelModeCode(name)
            value = find(["all", "none", "threshold"] == string(name), 1);
        end

        function value = edgeSelectionName(code)
            if code == 1
                value = "all";
            else
                value = "threshold";
            end
        end

        function value = edgeSelectionCode(name)
            if string(name) == "all"
                value = 1;
            else
                value = 2;
            end
        end

        function value = volumeTypeName(code)
            if code == 2
                value = "roi";
            else
                value = "surface-map";
            end
        end

        function value = volumeTypeCode(name)
            value = 1 + double(string(name) == "roi");
        end
    end
end
