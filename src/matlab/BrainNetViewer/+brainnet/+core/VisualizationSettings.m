classdef VisualizationSettings
    %VISUALIZATIONSETTINGS Versioned full visualization-settings contract.

    properties (Constant)
        SchemaVersion = "1.22.0"
    end

    properties (SetAccess = private)
        Data (1, 1) struct
    end

    methods
        function obj = VisualizationSettings(options)
            arguments
                options.Data (1, 1) struct = struct()
            end
            if isempty(fieldnames(options.Data))
                value = brainnet.core.VisualizationSettings.defaults();
            else
                value = options.Data;
            end
            obj.Data = brainnet.core.VisualizationSettings.normalize(value);
        end

        function value = toStruct(obj)
            value = obj.Data;
        end

        function text = toJson(obj)
            text = jsonencode(obj.Data, 'PrettyPrint', true);
        end

        function value = section(obj, name)
            arguments
                obj (1, 1) brainnet.core.VisualizationSettings
                name (1, 1) string
            end
            key = char(lower(name));
            if ~isfield(obj.Data, key) || ~isstruct(obj.Data.(key))
                error('BNV:Core:UnknownSettingsSection', ...
                    'Unknown visualization settings section: %s.', name);
            end
            value = obj.Data.(key);
        end

        function obj = withPatch(obj, patch)
            arguments
                obj (1, 1) brainnet.core.VisualizationSettings
                patch (1, 1) struct
            end
            value = brainnet.core.VisualizationSettings.merge(obj.Data, patch);
            obj = brainnet.core.VisualizationSettings(Data=value);
        end

        function [legacy, report] = toLegacy(obj, edgeMatrix)
            if nargin<2, edgeMatrix=[]; end
            d = obj.Data;
            edgeThreshold=d.edge.threshold;
            if string(d.edge.selection_mode)=="sparsity"
                error('BNV:EdgeSelection:LegacyTopCount','Top-count sparsity cannot be represented by an EC threshold. Save a Scene/preset or use an explicit threshold.');
            elseif string(d.edge.selection_mode)=="legacy-sparsity"
                edgeThreshold=brainnet.core.legacySparsityThreshold(edgeMatrix,d.edge.sparsity,string(d.edge.value_mode));
            end
            legacy = struct;
            legacy.lot = struct('view', d.layout.preset, ...
                'view_direction', d.layout.view_direction, ...
                'view_az', brainnet.core.VisualizationSettings.orDefault( ...
                    d.layout.custom_azimuth, -90), ...
                'view_el', brainnet.core.VisualizationSettings.orDefault( ...
                    d.layout.custom_elevation, 0));
            legacy.glb = struct('shading', d.global.shading, ...
                'lighting', d.global.lighting, ...
                'lightdirection', d.global.light_direction, ...
                'lr', double(d.global.show_orientation_labels), ...
                'render', 'OpenGL');
            legacy.glb.detail=brainnet.core.VisualizationSettings.legacyDetailCode(d.global.render_detail);
            legacy.glb.material=brainnet.core.VisualizationSettings.legacyMaterial( ...
                d.global.material_profile,d.global.material_coefficients);
            legacy.glb.material_ka=num2str(d.global.material_coefficients(1),'%.15g');
            legacy.glb.material_kd=num2str(d.global.material_coefficients(2),'%.15g');
            legacy.glb.material_ks=num2str(d.global.material_coefficients(3),'%.15g');
            boundaryMode=string(d.surface.boundary_mode);
            if boundaryMode=="legacy-automatic", boundaryMode="automatic"; end
            legacy.msh = struct('doublebrain',double(d.surface.double_brain),'alpha', d.surface.opacity, ...
                'color_type', 1 + double(d.surface.color_mode ~= "uniform"), ...
                'color', d.surface.color, ...
                'boundary', brainnet.core.VisualizationSettings.codeFor( ...
                    boundaryMode, ["none","automatic","threshold","custom"]), ...
                'boundary_color', d.surface.boundary_color);
            if string(d.surface.color_mode)=="vertex-rgb"
                legacy.msh.color_table=d.surface.vertex_colors;
                legacy.msh.color_table_tmp=d.surface.vertex_colors;
            end
            if boundaryMode=="threshold", legacy.msh.boundary_value=d.surface.boundary_threshold;
            elseif boundaryMode=="custom", legacy.msh.boundary_value=d.surface.boundary_mask(:);
            end
            legacy.lbl = brainnet.core.VisualizationSettings.codeFor( ...
                d.node.label_mode, ["all","none","threshold"]);
            legacy.lbl_threshold = d.node.label_threshold;
            legacy.lbl_threshold_type = brainnet.core.VisualizationSettings.codeFor( ...
                d.node.label_basis, ["value","module"]);
            legacy.lbl_front = double(d.node.label_in_front);
            legacy.lbl_font=struct('FontName',d.node.label_font_name,'FontSize',d.node.label_font_size, ...
                'FontWeight',d.node.label_font_weight,'FontAngle',d.node.label_font_angle,'FontUnits',d.node.label_font_units);
            if string(d.node.size_basis)=="module" && string(d.node.size_mode)~="uniform"
                error('BNV:NodeSize:LegacyBasis','Module-based node sizes have no legacy EC equivalent. Use the modern renderer.');
            end
            nodeSizeMode=string(d.node.size_mode);
            if nodeSizeMode=="raw", nodeSizeMode="mapped"; end
            legacy.nod = struct( ...
                'draw', brainnet.core.VisualizationSettings.codeFor( ...
                    d.node.selection_mode, ["all","threshold","connected"]), ...
                'draw_threshold_type', brainnet.core.VisualizationSettings.codeFor( ...
                    d.node.selection_basis, ["value","module"]), ...
                'draw_threshold', d.node.threshold, ...
                'size', brainnet.core.VisualizationSettings.codeFor( ...
                    nodeSizeMode, ["uniform","mapped","threshold"]), ...
                'size_value', 1 + double(string(d.node.size_mode)=="raw" || ...
                    (string(d.node.size_mode)=="threshold" && string(d.node.size_threshold_basis)=="raw")), ...
                'size_size', d.node.size, 'size_ratio', d.node.size_scale, ...
                'size_threshold', d.node.size_threshold, ...
                'color', brainnet.core.VisualizationSettings.nodeColorCode(d.node.color_mode), ...
                'color_threshold', d.node.color_threshold, ...
                'color_map_low', brainnet.core.VisualizationSettings.limitAt(d.node.color_limits, 1, 0), ...
                'color_map_high', brainnet.core.VisualizationSettings.limitAt(d.node.color_limits, 2, 1));
            legacy.nod.color_map_type = 1 + double(~isempty(d.node.color_limits));
            legacy.nod.CM = brainnet.core.Colormap.sample(d.node.colormap,64);
            if string(d.node.color_mode)=="uniform"
                legacy.nod.CM(1,:)=d.node.color;
            elseif string(d.node.color_mode)=="threshold"
                legacy.nod.CM(1,:)=d.node.color_high;
                legacy.nod.CM(64,:)=d.node.color_low;
            end
            edgeSizeMode=string(d.edge.size_mode);
            if edgeSizeMode=="raw", edgeSizeMode="mapped"; end
            legacy.edg = struct( ...
                'draw', 1 + double(d.edge.selection_mode ~= "all"), ...
                'draw_threshold', edgeThreshold, ...
                'draw_abs', double(d.edge.value_mode == "absolute"), ...
                'directed', double(d.edge.directed), ...
                'interhemiedges', double(d.edge.inter_hemisphere_only), ...
                'size', brainnet.core.VisualizationSettings.codeFor( ...
                    edgeSizeMode, ["uniform","mapped","threshold"]), ...
                'size_value', 1 + double(string(d.edge.size_mode)=="raw" || ...
                    (string(d.edge.size_mode)=="threshold" && string(d.edge.size_threshold_basis)=="raw")), ...
                'size_abs', double(string(d.edge.size_value_mode)=="absolute"), ...
                'size_size', d.edge.size, 'size_ratio', d.edge.size_scale, ...
                'size_threshold', d.edge.size_threshold, ...
                'color', brainnet.core.VisualizationSettings.codeFor( ...
                    d.edge.color_mode, ["uniform","mapped","threshold","length","node-module","custom"]), ...
                'color_threshold', d.edge.color_threshold, ...
                'color_distance', d.edge.length_threshold, ...
                'opacity', brainnet.core.VisualizationSettings.codeFor( ...
                    d.edge.opacity_mode, ["uniform","mapped"]), ...
                'opacity_same', d.edge.opacity, ...
                'opacity_abs', double(string(d.edge.opacity_value_mode)=="absolute"), ...
                'opacity_min', d.edge.opacity_range(1), ...
                'opacity_max', d.edge.opacity_range(2));
            if any(string(d.edge.color_mode)==["threshold","length"])
                legacy.edg.CM=repmat(d.edge.color_low,64,1);
                legacy.edg.CM(1,:)=d.edge.color_high;
                if string(d.edge.color_mode)=="threshold"
                    legacy.edg.color_abs=double(string(d.edge.threshold_value_mode)=="absolute");
                end
            end
            if string(d.edge.color_mode)=="mapped"
                legacy.edg.CM=brainnet.core.Colormap.sample(d.edge.colormap,64);
                legacy.edg.color_abs=double(string(d.edge.mapped_value_mode)=="absolute");
                legacy.edg.color_map_type=1+double(~isempty(d.edge.color_limits));
                legacy.edg.color_map_low=brainnet.core.VisualizationSettings.limitAt(d.edge.color_limits,1,0);
                legacy.edg.color_map_high=brainnet.core.VisualizationSettings.limitAt(d.edge.color_limits,2,1);
            end
            if string(d.edge.color_mode)=="node-module"
                legacy.edg.CM=[brainnet.core.Colormap.sample(d.edge.colormap,20);d.edge.inter_module_color];
            end
            if string(d.edge.color_mode)=="custom"
                custom=d.edge.custom_color;
                if isempty(custom.matrix), error('BNV:EdgeCustom:MissingMatrix','Load a custom color matrix before EC export.'); end
                legacy.edg.color_custom_matrix=custom.matrix; legacy.edg.color_custom_index=custom.indices;
                legacy.edg.CM=brainnet.core.CustomEdgeColors.palette(d.edge.colormap,numel(custom.indices));
                legacy.edg.CM_custom=legacy.edg.CM;
            end
            legacy.vol = struct('display', double(d.volume.display) * ...
                find(string(d.volume.display_mode) == ["both","positive","negative"]), ...
                'adjustCM', double(d.volume.adjust_null), ...
                'type', 1 + double(d.volume.type == "roi"), ...
                'mapalgorithm', d.volume.map_algorithm, ...
                'threshold', d.volume.statistical_threshold, ...
                'p', d.volume.p_value, 'clustersize', d.volume.cluster_size, ...
                'rmm', d.volume.voxel_connectivity, ...
                'pn', d.volume.positive_minimum, ...
                'px', d.volume.positive_maximum, ...
                'nx', d.volume.negative_minimum, ...
                'nn', d.volume.negative_maximum, ...
                'null', d.volume.null_color);
            legacy.vol.roi = struct('drawall', double(d.roi.draw_all), ...
                'drawt', d.roi.selection, ...
                'smooth', double(d.roi.smoothing ~= "none"), ...
                'smooth_kernal', 1 + double(d.roi.smoothing == "gaussian"));
            if string(d.roi.color_mode)=="custom"
                if d.roi.draw_all || isempty(d.roi.selection)
                    error('BNV:ROI:LegacySelectionRequired','EC export of custom ROI colors requires an explicit nonempty ROI Selection and Draw All off.');
                end
                legacy.vol.roi.draw=d.roi.selection;
                legacy.vol.roi.color=brainnet.core.RoiColors.lookup(d.roi.custom_colors,d.roi.selection);
                legacy.vol.roi.colort=legacy.vol.roi.color;
            end
            legacy.img = struct('width', d.image.width, ...
                'height', d.image.height, 'dpi', d.image.dpi);
            report = struct('schema_version', '1.0.0', ...
                'status', 'mapped-with-modern-substitutions', ...
                'retired_renderer', 'Legacy zbuffer is replaced by the supported OpenGL path.', ...
                'unmapped_sections', {{'fiber'}}, ...
                'note', 'Named/custom colormaps, Modern Automatic boundaries and fiber settings have no lossless legacy EC equivalent. Geometry-bound custom masks require modern rendering.');
            if string(d.edge.color_mode)=="node-module"
                report.note=[report.note ' Module-edge EC equivalence requires at most 20 module labels and no label 21; the legacy sentinel collides with label 21. Use Modern Batch Renderer.'];
            end
            if d.edge.arrow_length_scale~=1 || d.edge.arrow_width_scale~=1
                report.note=[report.note ' Adjustable modern arrowhead proportions have no legacy EC equivalent.'];
            end
            if string(d.edge.selection_mode)=="legacy-sparsity"
                report.note=[report.note ' Sparsity was resolved to a fixed threshold using the supplied matrix; EC does not retain the fraction or adapt it to another dataset.'];
            end
        end
    end

    methods (Static)
        function value = defaults()
            value = struct;
            value.schema_version = '1.22.0';
            value.layout = struct('preset', 1, 'view_direction', 1, ...
                'custom_azimuth', [], 'custom_elevation', []);
            value.global = struct('background_color', [1 1 1], ...
                'shading', 'interp', 'lighting', 'phong', ...
                'light_direction', 'right', 'show_orientation_labels', false, ...
                'render_detail', 'adaptive', 'material_profile', 'dull', ...
                'material_coefficients', [0.5 0.5 0.5]);
            value.surface = struct('double_brain',false,'color_mode', 'uniform', ...
                'color', [0.95 0.95 0.95], 'opacity', 0.3, ...
                'colormap', 'parula', 'color_limits', [], ...
                'show_colorbar', true, 'boundary_mode', 'none', ...
                'boundary_color', [0 0 0], 'boundary_threshold',0, ...
                'boundary_mask',[], 'boundary_mesh_sha256','', 'boundary_mask_source','', ...
                'vertex_colors',zeros(0,3),'vertex_colors_mesh_sha256','','vertex_colors_source','');
            value.node = struct('selection_mode', 'all', ...
                'selection_basis', 'value', 'threshold', 0, ...
                'label_mode', 'none', 'label_basis', 'value', ...
                'label_threshold', 0, 'label_font_name', 'Arial', ...
                'label_font_size', 10, 'label_font_weight', 'normal', ...
                'label_font_angle', 'normal', 'label_font_units', 'points', 'label_color', [0 0 0], ...
                'label_in_front', false, 'size_mode', 'mapped', ...
                'size_basis', 'value', 'size', 3, 'size_scale', 1, ...
                'size_threshold', 0, 'color_mode', 'uniform', ...
                'color', [37 89 152] / 255, 'colormap', 'jet', ...
                'color_limits', [], 'color_threshold', 0, ...
                'color_low', [37 89 152]/255, 'color_high', [1 0 0], ...
                'size_threshold_basis', 'mapped');
            value.edge = struct('selection_mode', 'all', ...
                'threshold', 0, 'sparsity', 0.1, 'value_mode', 'absolute', ...
                'inter_hemisphere_only', false, 'directed', false, ...
                'arrow_length_scale', 1, 'arrow_width_scale', 0.7, ...
                'size_mode', 'mapped', 'size', 1, ...
                'size_scale', 0.7, 'size_threshold', 0, ...
                'size_threshold_basis', 'mapped', 'size_value_mode', 'absolute', ...
                'color_mode', 'uniform', 'color', [1 0.9 0.73], ...
                'colormap', 'jet', 'color_limits', [], ...
                'color_threshold', 0, 'length_threshold', 75, ...
                'color_low', [.38 .38 .38], 'color_high', [1 .9 .73], ...
                'threshold_value_mode', 'absolute', ...
                'mapped_value_mode', 'absolute', ...
                'inter_module_color', [.5 .5 .5], ...
                'custom_color', brainnet.core.CustomEdgeColors.empty(), ...
                'opacity_mode', 'uniform', 'opacity', 0.7, ...
                'opacity_value_mode', 'absolute', ...
                'opacity_range', [0.1 0.9]);
            value.volume = struct('display', false, 'type', 'surface-map', ...
                'map_algorithm', 2, 'threshold_mode', 'none', ...
                'statistical_threshold', 0, 'p_value', 0.05, ...
                'cluster_size', 0, 'voxel_connectivity', 18, ...
                'positive_minimum', [], 'positive_maximum', [], ...
                'negative_minimum', [], 'negative_maximum', [], ...
                'display_mode', 'both', 'adjust_null', true, ...
                'null_color', [0.95 0.95 0.95], 'colormap', 'bwr');
            value.roi = struct('draw_all', true, 'selection', [], ...
                'color_mode', 'index', 'color', [0.8 0.2 0.2], 'custom_colors', zeros(0,4), ...
                'palette', 'hsv', 'show_legend', false, ...
                'smoothing', 'gaussian', 'smoothing_kernel', 3);
            value.image = struct('width', 2000, 'height', 1500, ...
                'dpi', 300, 'show_colorbar', false, ...
                'colorbar_location', 'eastoutside', ...
                'colorbar_label', '', 'title', '');
            value.fiber = struct('visible', false, ...
                'color_mode', 'direction', 'color', [0.7 0.7 0.7], ...
                'colormap', 'turbo', 'opacity', 0.8, 'radius', 0.25, ...
                'sampling_stride', 1, 'tube_sides', 6);
        end

        function obj = fromStruct(value)
            arguments
                value (1, 1) struct
            end
            obj = brainnet.core.VisualizationSettings(Data=value);
        end

        function obj = fromJson(text)
            arguments
                text (1, 1) string
            end
            obj = brainnet.core.VisualizationSettings.fromStruct(jsondecode(text));
        end

        function [obj, report] = fromLegacy(configuration, mapMode)
            arguments
                configuration (1, 1) struct
                mapMode (1, 1) double
            end
            value = brainnet.core.VisualizationSettings.defaults();
            % Legacy EC defaults used separate cool-negative/hot-positive
            % palettes. Preserve that look when importing an old config.
            value.volume.colormap=[flipud(cool(128));hot(128)];
            mapped = strings(0, 1);
            direct = { ...
                {'lot','view'}, {'layout','preset'}; ...
                {'lot','view_direction'}, {'layout','view_direction'}; ...
                {'lot','view_az'}, {'layout','custom_azimuth'}; ...
                {'lot','view_el'}, {'layout','custom_elevation'}; ...
                {'glb','shading'}, {'global','shading'}; ...
                {'glb','lighting'}, {'global','lighting'}; ...
                {'glb','lightdirection'}, {'global','light_direction'}; ...
                {'msh','alpha'}, {'surface','opacity'}; ...
                {'msh','color'}, {'surface','color'}; ...
                {'msh','boundary_color'}, {'surface','boundary_color'}; ...
                {'lbl_threshold'}, {'node','label_threshold'}; ...
                {'lbl_font','FontName'}, {'node','label_font_name'}; ...
                {'lbl_font','FontSize'}, {'node','label_font_size'}; ...
                {'lbl_font','FontWeight'}, {'node','label_font_weight'}; ...
                {'lbl_font','FontAngle'}, {'node','label_font_angle'}; ...
                {'lbl_font','FontUnits'}, {'node','label_font_units'}; ...
                {'nod','draw_threshold'}, {'node','threshold'}; ...
                {'nod','size_size'}, {'node','size'}; ...
                {'nod','size_ratio'}, {'node','size_scale'}; ...
                {'nod','size_threshold'}, {'node','size_threshold'}; ...
                {'nod','color_threshold'}, {'node','color_threshold'}; ...
                {'edg','draw_threshold'}, {'edge','threshold'}; ...
                {'edg','size_size'}, {'edge','size'}; ...
                {'edg','size_ratio'}, {'edge','size_scale'}; ...
                {'edg','size_threshold'}, {'edge','size_threshold'}; ...
                {'edg','color_threshold'}, {'edge','color_threshold'}; ...
                {'edg','color_distance'}, {'edge','length_threshold'}; ...
                {'edg','opacity_same'}, {'edge','opacity'}; ...
                {'vol','mapalgorithm'}, {'volume','map_algorithm'}; ...
                {'vol','threshold'}, {'volume','statistical_threshold'}; ...
                {'vol','p'}, {'volume','p_value'}; ...
                {'vol','clustersize'}, {'volume','cluster_size'}; ...
                {'vol','rmm'}, {'volume','voxel_connectivity'}; ...
                {'vol','pn'}, {'volume','positive_minimum'}; ...
                {'vol','px'}, {'volume','positive_maximum'}; ...
                {'vol','nx'}, {'volume','negative_minimum'}; ...
                {'vol','nn'}, {'volume','negative_maximum'}; ...
                {'vol','null'}, {'volume','null_color'}; ...
                {'vol','roi','drawt'}, {'roi','selection'}; ...
                {'img','width'}, {'image','width'}; ...
                {'img','height'}, {'image','height'}; ...
                {'img','dpi'}, {'image','dpi'} };
            for index = 1:size(direct, 1)
                [item, found] = brainnet.core.VisualizationSettings.nested(configuration, direct{index, 1});
                if found && ~isempty(item)
                    value = brainnet.core.VisualizationSettings.setNested(value, direct{index, 2}, item);
                    mapped(end + 1, 1) = "EC." + ...
                        strjoin(string(direct{index, 1}), "."); %#ok<AGROW>
                end
            end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'glb','lr'});
            if found, value.global.show_orientation_labels = logical(item); mapped(end + 1) = "EC.glb.lr"; end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'glb','detail'});
            if found
                value.global.render_detail=char(brainnet.core.VisualizationSettings.nameFor(item,["low","moderate","high"]));
                mapped(end+1)="EC.glb.detail";
            end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'glb','material'});
            if found
                [profile,coefficients]=brainnet.core.VisualizationSettings.fromLegacyMaterial(item,configuration);
                value.global.material_profile=char(profile);
                value.global.material_coefficients=coefficients;
                mapped(end+1)="EC.glb.material";
            end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'msh','doublebrain'});
            if found
                if ~isscalar(item) || ~ismember(item,[0 1]), error('BNV:DoubleBrain:LegacyFlag','EC.msh.doublebrain must be 0 or 1.'); end
                value.surface.double_brain=logical(item); mapped(end+1)="EC.msh.doublebrain";
            end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'msh','color_type'});
            if found
                value.surface.color_mode = char(brainnet.core.VisualizationSettings.nameFor(item, ["uniform","scalar"]));
                mapped(end + 1) = "EC.msh.color_type";
            elseif mapMode > 0
                value.surface.color_mode = 'scalar';
                mapped(end + 1) = "Flag.MAP>0";
            end
            [table, hasTable]=brainnet.core.VisualizationSettings.nested(configuration,{'msh','color_table'});
            if hasTable && ~isempty(table)
                value.surface.vertex_colors=brainnet.core.VertexColors.validate(table);
                value.surface.vertex_colors_source='Legacy EC; vertex-order confirmation and binding required';
                mapped(end+1)="EC.msh.color_table";
                if strcmp(value.surface.color_mode,'scalar') && mapMode==0, value.surface.color_mode='vertex-rgb'; end
            end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'msh','boundary'});
            if found
                value.surface.boundary_mode = char(brainnet.core.VisualizationSettings.nameFor(item, ["none","legacy-automatic","threshold","custom"]));
                mapped(end + 1) = "EC.msh.boundary";
                [boundaryValue,hasValue]=brainnet.core.VisualizationSettings.nested(configuration,{'msh','boundary_value'});
                if any(item==[3 4]) && (~hasValue || isempty(boundaryValue))
                    error('BNV:Boundary:MigrationReview','Legacy threshold/custom boundary settings require EC.msh.boundary_value.');
                end
                if hasValue && item==3
                    value.surface.boundary_threshold=boundaryValue; mapped(end+1)="EC.msh.boundary_value";
                elseif hasValue && item==4
                    value.surface.boundary_mask=boundaryValue;
                    value.surface.boundary_mask_source='Legacy EC import; surface binding required';
                    mapped(end+1)="EC.msh.boundary_value";
                end
            end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'lbl'});
            if found, value.node.label_mode = char(brainnet.core.VisualizationSettings.nameFor(item, ["all","none","threshold"])); mapped(end + 1) = "EC.lbl"; end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'lbl_threshold_type'});
            if found, value.node.label_basis = char(brainnet.core.VisualizationSettings.nameFor(item, ["value","module"])); mapped(end + 1) = "EC.lbl_threshold_type"; end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'lbl_front'});
            if found, value.node.label_in_front = logical(item); mapped(end + 1) = "EC.lbl_front"; end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'nod','draw'});
            if found, value.node.selection_mode = char(brainnet.core.VisualizationSettings.nameFor(item, ["all","threshold","connected"])); mapped(end + 1) = "EC.nod.draw"; end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'nod','draw_threshold_type'});
            if found, value.node.selection_basis = char(brainnet.core.VisualizationSettings.nameFor(item, ["value","module"])); mapped(end + 1) = "EC.nod.draw_threshold_type"; end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'nod','size'});
            if found, value.node.size_mode = char(brainnet.core.VisualizationSettings.nameFor(item, ["uniform","mapped","threshold"])); mapped(end + 1) = "EC.nod.size"; end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'nod','size_value'});
            if found
                sizeTransform=brainnet.core.VisualizationSettings.nameFor(item,["mapped","raw"]);
                value.node.size_threshold_basis=char(sizeTransform);
                if string(value.node.size_mode)=="mapped" && sizeTransform=="raw", value.node.size_mode='raw'; end
                mapped(end + 1) = "EC.nod.size_value";
            end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'nod','color'});
            if found, value.node.color_mode = char(brainnet.core.VisualizationSettings.nameFor(item, ["uniform","mapped","modular","threshold"])); mapped(end + 1) = "EC.nod.color"; end
            nodeLow = brainnet.core.VisualizationSettings.nestedOr(configuration, {'nod','color_map_low'}, []);
            nodeHigh = brainnet.core.VisualizationSettings.nestedOr(configuration, {'nod','color_map_high'}, []);
            if ~isempty(nodeLow) && ~isempty(nodeHigh), value.node.color_limits = [nodeLow nodeHigh]; end
            [rangeType,hasRangeType]=brainnet.core.VisualizationSettings.nested(configuration,{'nod','color_map_type'});
            if hasRangeType
                if rangeType==1, value.node.color_limits=[];
                elseif rangeType~=2 || isempty(nodeLow) || isempty(nodeHigh)
                    error('BNV:NodeColor:LegacyRange','Fixed node color limits require both bounds and color_map_type=2.');
                end
                mapped(end+1)="EC.nod.color_map_type";
            end
            [cm,hasCM]=brainnet.core.VisualizationSettings.nested(configuration,{'nod','CM'});
            if hasCM
                if ~isnumeric(cm)||~isreal(cm)||size(cm,2)~=3||isempty(cm)||any(~isfinite(cm),'all')||any(cm<0|cm>1,'all')
                    error('BNV:NodeColor:LegacyRGB','EC.nod.CM must be a finite RGB matrix in [0,1].');
                end
                if string(value.node.color_mode)=="mapped"
                    value.node.colormap=brainnet.core.Colormap.validate(cm);
                elseif string(value.node.color_mode)=="uniform"
                    value.node.color=cm(1,:);
                end
            end
            if string(value.node.color_mode)=="threshold"
                if ~hasCM || size(cm,1)<64
                    error('BNV:NodeColor:LegacyThresholdColors','Legacy threshold coloring requires EC.nod.CM rows 1 and 64.');
                end
                value.node.color_high=cm(1,:); value.node.color_low=cm(64,:);
            end
            if hasCM && any(string(value.node.color_mode)==["uniform","mapped","threshold"]), mapped(end+1)="EC.nod.CM"; end
            if ~isempty(nodeLow)&&~isempty(nodeHigh)
                mapped(end+1)="EC.nod.color_map_low"; mapped(end+1)="EC.nod.color_map_high";
            end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'edg','draw'});
            if found, value.edge.selection_mode = char(brainnet.core.VisualizationSettings.nameFor(item, ["all","threshold"])); mapped(end + 1) = "EC.edg.draw"; end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'edg','draw_abs'});
            if found, value.edge.value_mode = char(brainnet.core.VisualizationSettings.nameFor(item + 1, ["signed","absolute"])); mapped(end + 1) = "EC.edg.draw_abs"; end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'edg','interhemiedges'});
            if found
                if ~(isnumeric(item)||islogical(item)) || ~isreal(item) || ~isscalar(item) || ~any(item==[0 1])
                    error('BNV:EdgeSelection:LegacyHemisphere','EC.edg.interhemiedges must be 0 or 1.');
                end
                value.edge.inter_hemisphere_only=logical(item); mapped(end+1)="EC.edg.interhemiedges";
            end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'edg','directed'});
            if found, value.edge.directed = logical(item); mapped(end + 1) = "EC.edg.directed"; end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'edg','size'});
            if found, value.edge.size_mode = char(brainnet.core.VisualizationSettings.nameFor(item, ["uniform","mapped","threshold"])); mapped(end + 1) = "EC.edg.size"; end
            [item,found]=brainnet.core.VisualizationSettings.nested(configuration,{'edg','size_value'});
            if found
                if ~isnumeric(item) || ~isreal(item) || ~isscalar(item) || ~any(item==[1 2])
                    error('BNV:EdgeSize:LegacyValue','EC.edg.size_value must be 1 (Mapped) or 2 (Raw).');
                end
                transform=brainnet.core.VisualizationSettings.nameFor(item,["mapped","raw"]);
                value.edge.size_threshold_basis=char(transform);
                if string(value.edge.size_mode)=="mapped" && transform=="raw", value.edge.size_mode='raw'; end
                mapped(end+1)="EC.edg.size_value";
            end
            [item,found]=brainnet.core.VisualizationSettings.nested(configuration,{'edg','size_abs'});
            if found
                if ~(isnumeric(item)||islogical(item)) || ~isreal(item) || ~isscalar(item) || ~any(item==[0 1])
                    error('BNV:EdgeSize:LegacySign','EC.edg.size_abs must be 0 (Signed) or 1 (Absolute).');
                end
                value.edge.size_value_mode=char(brainnet.core.VisualizationSettings.nameFor(double(item)+1,["signed","absolute"]));
                mapped(end+1)="EC.edg.size_abs";
            end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'edg','color'});
            if found, value.edge.color_mode = char(brainnet.core.VisualizationSettings.nameFor(item, ["uniform","mapped","threshold","length","node-module","custom"])); mapped(end + 1) = "EC.edg.color"; end
            if any(string(value.edge.color_mode)==["threshold","length"])
                [cm,hasCM]=brainnet.core.VisualizationSettings.nested(configuration,{'edg','CM'});
                if ~hasCM || ~isnumeric(cm) || ~isreal(cm) || size(cm,2)~=3 || size(cm,1)<64 || ...
                        any(~isfinite(cm),'all') || any(cm<0|cm>1,'all')
                    error('BNV:EdgeColor:LegacyRGB','Legacy Threshold/Length coloring requires finite RGB EC.edg.CM rows 1 and 64 in [0,1].');
                end
                value.edge.color_high=cm(1,:); value.edge.color_low=cm(64,:);
                mapped(end+1)="EC.edg.CM";
                if string(value.edge.color_mode)=="threshold"
                    [absolute,found]=brainnet.core.VisualizationSettings.nested(configuration,{'edg','color_abs'});
                    if found
                        if ~(isnumeric(absolute)||islogical(absolute)) || ~isscalar(absolute) || ~isreal(absolute) || ~any(absolute==[0 1])
                            error('BNV:EdgeColor:LegacyValueMode','EC.edg.color_abs must be 0 or 1.');
                        end
                        value.edge.threshold_value_mode=char(brainnet.core.VisualizationSettings.nameFor(absolute+1,["signed","absolute"]));
                        mapped(end+1)="EC.edg.color_abs";
                    end
                end
            end
            if string(value.edge.color_mode)=="mapped"
                [cm,hasCM]=brainnet.core.VisualizationSettings.nested(configuration,{'edg','CM'});
                if ~hasCM || ~isnumeric(cm) || ~isreal(cm) || ~ismatrix(cm) || size(cm,2)~=3 || size(cm,1)<64 || ...
                        any(~isfinite(cm),'all') || any(cm<0|cm>1,'all')
                    error('BNV:EdgeColor:LegacyRGB','Legacy Mapped coloring requires at least 64 finite RGB rows in EC.edg.CM.');
                end
                value.edge.colormap=cm(1:64,:);
                absolute=brainnet.core.VisualizationSettings.nestedOr(configuration,{'edg','color_abs'},1);
                if ~(isnumeric(absolute)||islogical(absolute)) || ~isscalar(absolute) || ~isreal(absolute) || ~any(absolute==[0 1])
                    error('BNV:EdgeColor:LegacyValueMode','EC.edg.color_abs must be 0 or 1.');
                end
                value.edge.mapped_value_mode=char(brainnet.core.VisualizationSettings.nameFor(double(absolute)+1,["signed","absolute"]));
                rangeType=brainnet.core.VisualizationSettings.nestedOr(configuration,{'edg','color_map_type'},1);
                if ~isnumeric(rangeType) || ~isscalar(rangeType) || ~isreal(rangeType) || ~any(rangeType==[1 2])
                    error('BNV:EdgeColor:LegacyRange','EC.edg.color_map_type must be 1 (Auto) or 2 (Fixed).');
                end
                if rangeType==2
                    low=brainnet.core.VisualizationSettings.nestedOr(configuration,{'edg','color_map_low'},[]);
                    high=brainnet.core.VisualizationSettings.nestedOr(configuration,{'edg','color_map_high'},[]);
                    if ~isnumeric(low) || ~isnumeric(high) || ~isscalar(low) || ~isscalar(high) || ...
                            ~isreal(low) || ~isreal(high) || ~isfinite(low) || ~isfinite(high) || low>high
                        error('BNV:EdgeColor:LegacyRange','Fixed edge color mapping requires finite ordered lower and upper limits.');
                    end
                    value.edge.color_limits=[low high];
                    mapped(end+1:end+2,1)=["EC.edg.color_map_low";"EC.edg.color_map_high"];
                else
                    value.edge.color_limits=[];
                end
                mapped(end+1)="EC.edg.CM";
                if isfield(configuration.edg,'color_abs'), mapped(end+1)="EC.edg.color_abs"; end
                if isfield(configuration.edg,'color_map_type'), mapped(end+1)="EC.edg.color_map_type"; end
            end
            if string(value.edge.color_mode)=="node-module"
                [cm,found]=brainnet.core.VisualizationSettings.nested(configuration,{'edg','CM'});
                if ~found || ~isnumeric(cm) || ~isreal(cm) || ~ismatrix(cm) || size(cm,2)~=3 || size(cm,1)<21 || ...
                        any(~isfinite(cm),'all') || any(cm<0|cm>1,'all')
                    error('BNV:EdgeModule:LegacyRGB','Legacy module-edge coloring requires at least 21 finite RGB rows in EC.edg.CM.');
                end
                value.edge.colormap=double(cm(1:20,:)); value.edge.inter_module_color=double(cm(21,:));
                mapped(end+1)="EC.edg.CM";
            end
            if string(value.edge.color_mode)=="custom"
                custom=brainnet.core.CustomEdgeColors.empty(); custom.source='legacy EC';
                [custom.matrix,hasMatrix]=brainnet.core.VisualizationSettings.nested(configuration,{'edg','color_custom_matrix'});
                [custom.indices,hasIndices]=brainnet.core.VisualizationSettings.nested(configuration,{'edg','color_custom_index'});
                [cm,hasCM]=brainnet.core.VisualizationSettings.nested(configuration,{'edg','CM'});
                if ~hasMatrix||~hasIndices||~hasCM||isempty(custom.matrix)
                    error('BNV:EdgeCustom:LegacyData','Custom EC requires color_custom_matrix, color_custom_index and actual CM.');
                end
                value.edge.custom_color=brainnet.core.CustomEdgeColors.validate(custom);
                if ~isnumeric(cm)||~isreal(cm)||~ismatrix(cm)||size(cm,2)~=3||size(cm,1)<numel(custom.indices)
                    error('BNV:EdgeCustom:LegacyData','Actual CM must contain an RGB row for each custom category.');
                end
                if isnumeric(cm)&&isequal(size(cm),[1 3]), cm=[cm;cm]; end
                value.edge.colormap=brainnet.core.Colormap.validate(cm);
                brainnet.core.CustomEdgeColors.palette(value.edge.colormap,numel(custom.indices));
                mapped(end+1:end+3,1)=["EC.edg.color_custom_matrix";"EC.edg.color_custom_index";"EC.edg.CM"];
            end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'edg','opacity'});
            if found
                if ~isnumeric(item) || ~isreal(item) || ~isscalar(item) || ~any(item==[1 2])
                    error('BNV:EdgeOpacity:LegacyMode','EC.edg.opacity must be 1 (Uniform) or 2 (Mapped).');
                end
                value.edge.opacity_mode = char(brainnet.core.VisualizationSettings.nameFor(item, ["uniform","mapped"]));
                mapped(end+1)="EC.edg.opacity";
            end
            [absolute,found]=brainnet.core.VisualizationSettings.nested(configuration,{'edg','opacity_abs'});
            if found
                if ~(isnumeric(absolute)||islogical(absolute)) || ~isreal(absolute) || ~isscalar(absolute) || ~any(absolute==[0 1])
                    error('BNV:EdgeOpacity:LegacySign','EC.edg.opacity_abs must be 0 or 1.');
                end
                value.edge.opacity_value_mode=char(brainnet.core.VisualizationSettings.nameFor(double(absolute)+1,["signed","absolute"]));
                mapped(end+1)="EC.edg.opacity_abs";
            end
            [opacityLow,foundLow]=brainnet.core.VisualizationSettings.nested(configuration, {'edg','opacity_min'});
            [opacityHigh,foundHigh]=brainnet.core.VisualizationSettings.nested(configuration, {'edg','opacity_max'});
            if ~foundLow, opacityLow=value.edge.opacity_range(1); end
            if ~foundHigh, opacityHigh=value.edge.opacity_range(2); end
            if ~isnumeric(opacityLow) || ~isnumeric(opacityHigh) || ~isreal(opacityLow) || ~isreal(opacityHigh) || ...
                    ~isscalar(opacityLow) || ~isscalar(opacityHigh) || ~isfinite(opacityLow) || ~isfinite(opacityHigh) || ...
                    opacityLow<0 || opacityHigh>1 || opacityLow>opacityHigh
                error('BNV:EdgeOpacity:LegacyRange','Opacity limits must be finite scalars with 0 <= lower <= upper <= 1.');
            end
            value.edge.opacity_range = [opacityLow opacityHigh];
            if isfield(configuration,'edg')
                if isfield(configuration.edg,'opacity_min'), mapped(end+1)="EC.edg.opacity_min"; end
                if isfield(configuration.edg,'opacity_max'), mapped(end+1)="EC.edg.opacity_max"; end
            end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'vol','display'});
            value.volume.display = mapMode > 0;
            if found && ~isempty(item)
                if islogical(item), item=double(item); end
                brainnet.core.VisualizationSettings.integer(item, 'EC.vol.display', 0, 3);
                value.volume.display = item > 0 || mapMode > 0;
                if item > 0
                    modes = ["both","positive","negative"];
                    value.volume.display_mode = char(modes(item));
                end
                mapped(end+1) = "EC.vol.display";
            end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'vol','adjustCM'});
            if found
                if islogical(item), item=double(item); end
                brainnet.core.VisualizationSettings.integer(item, 'EC.vol.adjustCM', 0, 1);
                value.volume.adjust_null = logical(item);
                mapped(end+1) = "EC.vol.adjustCM";
            end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'vol','type'});
            if found, value.volume.type = char(brainnet.core.VisualizationSettings.nameFor(item, ["surface-map","roi"])); mapped(end + 1) = "EC.vol.type"; end
            if value.volume.statistical_threshold ~= 0, value.volume.threshold_mode = 'value'; end
            [item, found] = brainnet.core.VisualizationSettings.nested(configuration, {'vol','roi','drawall'});
            if found, value.roi.draw_all = logical(item); mapped(end + 1) = "EC.vol.roi.drawall"; end
            if value.volume.display && string(value.volume.type)=="roi"
                [rgb, hasColors]=brainnet.core.VisualizationSettings.nested(configuration,{'vol','roi','color'});
                if hasColors && ~isempty(rgb)
                    ids=brainnet.core.VisualizationSettings.nestedOr(configuration,{'vol','roi','draw'},[]);
                    if isempty(ids), ids=value.roi.selection; end
                    if isempty(ids)
                        error('BNV:ROI:LegacyColorMappingRequired','EC ROI colors are positional. Supply the matching draw/drawt IDs before import.');
                    end
                    if ~isnumeric(rgb) || ~ismatrix(rgb) || size(rgb,2)~=3 || size(rgb,1)<numel(ids)
                        error('BNV:ROI:InvalidColors','EC ROI colors require an RGB row for every selected ROI.');
                    end
                    value.roi.custom_colors=brainnet.core.RoiColors.validate([ids(:),rgb(1:numel(ids),:)]);
                    value.roi.selection=reshape(ids,1,[]);
                    value.roi.color_mode='custom';
                    mapped(end+1)="EC.vol.roi.color";
                end
            end
            smooth = brainnet.core.VisualizationSettings.nestedOr(configuration, {'vol','roi','smooth'}, 0);
            kernel = brainnet.core.VisualizationSettings.nestedOr(configuration, {'vol','roi','smooth_kernal'}, 1);
            if ~logical(smooth), value.roi.smoothing = 'none'; elseif kernel == 2, value.roi.smoothing = 'gaussian'; else, value.roi.smoothing = 'box'; end
            % Legacy smooth_kernal selects Box (1) versus Gaussian (2);
            % it is not the modern numeric kernel width.
            % Keep the modern default kernel width already in value.
            legacyMap = brainnet.core.VisualizationSettings.nestedOr(configuration, {'vol','cmstring'}, '');
            mapName = brainnet.core.VisualizationSettings.colormapName(legacyMap);
            if any(lower(mapName) == brainnet.core.Colormap.names()), value.volume.colormap = char(mapName); end
            obj = brainnet.core.VisualizationSettings(Data=value);
            uniqueMapped = unique(mapped, 'stable');
            report = struct('schema_version', '1.0.0', ...
                'mapped_fields', {cellstr(uniqueMapped)}, ...
                'mapped_field_count', numel(uniqueMapped), ...
                'defaults_used_for_unmapped_fields', true, ...
                'retired_fields', {{'EC.glb.render=zbuffer'}}, ...
                'warnings', {{'Custom MATLAB colormap expressions are reduced to a recognized function name when possible.'}});
        end
    end

    methods (Static, Access = private)
        function code=legacyDetailCode(value)
            value=string(value);
            if value=="adaptive"
                % Legacy EC has no adaptive mode; retain its historical default.
                code=3;
            else
                code=brainnet.core.VisualizationSettings.codeFor(value,["low","moderate","high"]);
            end
        end

        function value=legacyMaterial(profile,coefficients)
            profile=string(profile);
            if profile~="custom"
                value=char(profile);
                return;
            end
            value=sprintf('([%.15g %.15g %.15g])',coefficients(1),coefficients(2),coefficients(3));
        end

        function [profile,coefficients]=fromLegacyMaterial(material,configuration)
            profile=lower(strtrim(string(material)));
            coefficients=[0.5 0.5 0.5];
            if any(profile==["dull","shiny","metal"])
                return;
            end
            if ~(startsWith(profile,"([") && endsWith(profile,"])"))
                error('BNV:Material:LegacyValue','EC.glb.material must be dull, shiny, metal, or a three-coefficient custom vector.');
            end
            text=erase(profile,["(",")","[","]",","]);
            values=sscanf(char(text),'%f');
            if numel(values)~=3 || any(~isfinite(values)) || any(values<0 | values>1)
                error('BNV:Material:LegacyCoefficients','Custom EC.glb.material coefficients must be three finite values in [0,1].');
            end
            profile="custom";
            coefficients=reshape(values,1,[]);
            for field=["material_ka","material_kd","material_ks"]
                [item,found]=brainnet.core.VisualizationSettings.nested(configuration,{"glb",char(field)});
                if found && ~isempty(item)
                    numeric=str2double(string(item));
                    if ~isscalar(numeric) || ~isfinite(numeric) || numeric<0 || numeric>1
                        error('BNV:Material:LegacyCoefficients','EC.glb material coefficient fields must be finite values in [0,1].');
                    end
                end
            end
        end

        function value = normalize(value)
            template = brainnet.core.VisualizationSettings.defaults();
            if isfield(value,'edge') && isfield(value.edge,'selection_mode') && ...
                    strcmp(value.edge.selection_mode,'legacy-sparsity')
                value.edge.selection_mode='sparsity';
            end
            if isfield(value,'roi')
                if ~isfield(value.roi,'palette'), value.roi.palette=template.roi.palette; end
                if ~isfield(value.roi,'show_legend'), value.roi.show_legend=template.roi.show_legend; end
            end
            if isfield(value,'global') && ~isfield(value.global,'render_detail')
                value.global.render_detail=template.global.render_detail;
            end
            if isfield(value,'global') && ~isfield(value.global,'material_profile')
                value.global.material_profile=template.global.material_profile;
            end
            if isfield(value,'global') && ~isfield(value.global,'material_coefficients')
                value.global.material_coefficients=template.global.material_coefficients;
            end
            if isfield(value,'schema_version') && ~strcmp(value.schema_version,'1.18.0') && isfield(value,'surface')
                for field=["vertex_colors","vertex_colors_mesh_sha256","vertex_colors_source"]
                    if ~isfield(value.surface,field), value.surface.(field)=template.surface.(field); end
                end
            end
            if isfield(value,'schema_version') && ~any(strcmp(value.schema_version,{'1.17.0','1.18.0'})) && isfield(value,'surface')
                if ~isfield(value.surface,'double_brain'), value.surface.double_brain=false; end
            end
            if isfield(value,'schema_version') && any(string(value.schema_version)== ...
                    ["1.0.0","1.1.0","1.2.0","1.3.0","1.4.0","1.5.0","1.6.0","1.7.0","1.8.0","1.9.0","1.10.0","1.11.0","1.12.0","1.13.0","1.14.0","1.15.0"]) && isfield(value,'roi')
                if ~isfield(value.roi,'custom_colors'), value.roi.custom_colors=zeros(0,4); end
            end
            if isfield(value,'schema_version') && any(string(value.schema_version)== ...
                    ["1.0.0","1.1.0","1.2.0","1.3.0","1.4.0","1.5.0","1.6.0","1.7.0","1.8.0","1.9.0","1.10.0","1.11.0","1.12.0","1.13.0","1.14.0"]) && isfield(value,'volume')
                for field=["display_mode","adjust_null"]
                    if ~isfield(value.volume,field), value.volume.(field)=template.volume.(field); end
                end
            end
            if isfield(value,'schema_version') && any(string(value.schema_version)==["1.0.0","1.1.0","1.2.0","1.3.0","1.4.0","1.5.0","1.6.0","1.7.0","1.8.0","1.9.0","1.10.0","1.11.0","1.12.0","1.13.0"]) && isfield(value,'node')
                for field=["label_font_weight","label_font_angle","label_font_units"]
                    if ~isfield(value.node,field), value.node.(field)=template.node.(field); end
                end
            end
            if isfield(value,'schema_version') && any(string(value.schema_version)==["1.0.0","1.1.0","1.2.0","1.3.0","1.4.0","1.5.0","1.6.0","1.7.0","1.8.0","1.9.0","1.10.0","1.11.0"]) && isfield(value,'edge')
                if ~isfield(value.edge,'inter_hemisphere_only'), value.edge.inter_hemisphere_only=false; end
            end
            if isfield(value,'schema_version') && any(string(value.schema_version)==["1.0.0","1.1.0","1.2.0","1.3.0","1.4.0","1.5.0","1.6.0","1.7.0","1.8.0","1.9.0","1.10.0"]) && isfield(value,'edge')
                if ~isfield(value.edge,'custom_color'), value.edge.custom_color=brainnet.core.CustomEdgeColors.empty(); end
            end
            if isfield(value,'schema_version') && string(value.schema_version)~="1.21.0" && isfield(value,'edge')
                if ~isfield(value.edge,'arrow_length_scale'), value.edge.arrow_length_scale=1; end
                if ~isfield(value.edge,'arrow_width_scale'), value.edge.arrow_width_scale=1; end
            end
            if isfield(value,'schema_version') && any(string(value.schema_version)==["1.0.0","1.1.0","1.2.0","1.3.0","1.4.0","1.5.0","1.6.0","1.7.0","1.8.0","1.9.0"]) && isfield(value,'edge')
                if ~isfield(value.edge,'inter_module_color'), value.edge.inter_module_color=[.5 .5 .5]; end
            end
            if isfield(value,'schema_version') && any(string(value.schema_version)==["1.0.0","1.1.0","1.2.0","1.3.0","1.4.0","1.5.0","1.6.0","1.7.0","1.8.0"]) && isfield(value,'edge')
                if ~isfield(value.edge,'opacity_value_mode'), value.edge.opacity_value_mode='absolute'; end
            end
            if isfield(value,'schema_version') && any(string(value.schema_version)==["1.0.0","1.1.0","1.2.0","1.3.0","1.4.0","1.5.0","1.6.0","1.7.0"]) && isfield(value,'edge')
                if ~isfield(value.edge,'mapped_value_mode'), value.edge.mapped_value_mode='signed'; end
            end
            if isfield(value,'schema_version') && any(string(value.schema_version)==["1.0.0","1.1.0","1.2.0","1.3.0","1.4.0","1.5.0","1.6.0"]) && isfield(value,'edge')
                if ~isfield(value.edge,'size_threshold_basis'), value.edge.size_threshold_basis='mapped'; end
                if ~isfield(value.edge,'size_value_mode'), value.edge.size_value_mode='absolute'; end
            end
            if isfield(value,'schema_version') && any(string(value.schema_version)==["1.0.0","1.1.0","1.2.0","1.3.0","1.4.0","1.5.0"]) && isfield(value,'edge')
                if ~isfield(value.edge,'color_low'), value.edge.color_low=value.edge.color; end
                if ~isfield(value.edge,'color_high')
                    oldMap=brainnet.core.Colormap.sample(value.edge.colormap,2);
                    value.edge.color_high=oldMap(end,:);
                end
                if ~isfield(value.edge,'threshold_value_mode'), value.edge.threshold_value_mode='absolute'; end
            end
            if isfield(value,'schema_version') && any(string(value.schema_version)==["1.0.0","1.1.0","1.2.0","1.3.0"]) && isfield(value,'node')
                if ~isfield(value.node,'size_threshold_basis'), value.node.size_threshold_basis='mapped'; end
            end
            if isfield(value,'schema_version') && any(string(value.schema_version)==["1.0.0","1.1.0","1.2.0"]) && isfield(value,'node')
                if ~isfield(value.node,'color_low'), value.node.color_low=value.node.color; end
                if ~isfield(value.node,'color_high')
                    oldMap=brainnet.core.Colormap.sample(value.node.colormap,2);
                    value.node.color_high=oldMap(end,:);
                end
            end
            if isfield(value,'schema_version') && any(string(value.schema_version)==["1.0.0","1.1.0"]) && isfield(value,'surface')
                if any(string(value.surface.boundary_mode)==["threshold","custom"]) && ~isfield(value.surface,'boundary_threshold')
                    error('BNV:Boundary:MigrationReview','This older Scene has an unimplemented threshold/custom boundary mode. Review its boundary settings explicitly before upgrading.');
                end
                for field=["boundary_threshold","boundary_mask","boundary_mesh_sha256","boundary_mask_source"]
                    if ~isfield(value.surface,field), value.surface.(field)=template.surface.(field); end
                end
            end
            if isfield(value,'volume') && isfield(value,'schema_version') && ...
                    string(value.schema_version)~="1.22.0"
                volume=value.volume;
                if isfield(volume,'positive_colormap') && isfield(volume,'negative_colormap')
                    volume.colormap=[flipud(brainnet.core.Colormap.sample(volume.negative_colormap,128)); ...
                        brainnet.core.Colormap.sample(volume.positive_colormap,128)];
                    volume=rmfield(volume,{'positive_colormap','negative_colormap'});
                end
                value.volume=volume;
            end
            brainnet.core.VisualizationSettings.exactFields(value, template, 'settings');
            sections = setdiff(fieldnames(template), {'schema_version'}, 'stable');
            for index = 1:numel(sections)
                name = sections{index};
                brainnet.core.VisualizationSettings.exactFields(value.(name), template.(name), "settings." + name);
            end
            if ~any(string(value.schema_version) == ["1.0.0","1.1.0","1.2.0","1.3.0","1.4.0","1.5.0","1.6.0","1.7.0","1.8.0","1.9.0","1.10.0","1.11.0","1.12.0","1.13.0","1.14.0","1.15.0","1.16.0","1.17.0","1.18.0","1.19.0","1.20.0","1.21.0","1.22.0"])
                error('BNV:Core:UnsupportedSettingsVersion', ...
                    'Visualization settings schema_version must be %s.', ...
                    brainnet.core.VisualizationSettings.SchemaVersion);
            end
            value.schema_version = '1.22.0';
            value = brainnet.core.VisualizationSettings.canonicalText(value);
            brainnet.core.VisualizationSettings.validate(value);
        end

        function validate(v)
            brainnet.core.VisualizationSettings.integer(v.layout.preset, 'layout.preset', 1, 5);
            brainnet.core.VisualizationSettings.integer(v.layout.view_direction, 'layout.view_direction', 1, 8);
            brainnet.core.VisualizationSettings.optionalRange(v.layout.custom_azimuth, 'layout.custom_azimuth', -360, 360);
            brainnet.core.VisualizationSettings.optionalRange(v.layout.custom_elevation, 'layout.custom_elevation', -90, 90);
            if xor(isempty(v.layout.custom_azimuth), isempty(v.layout.custom_elevation)), error('BNV:Core:InvalidSettingsCombination', 'Custom azimuth and elevation must both be empty or both be set.'); end
            brainnet.core.VisualizationSettings.color(v.global.background_color, 'global.background_color');
            brainnet.core.VisualizationSettings.enumeration(v.global.shading, 'global.shading', ["flat","faceted","interp"]);
            brainnet.core.VisualizationSettings.enumeration(v.global.lighting, 'global.lighting', ["none","flat","gouraud","phong"]);
            brainnet.core.VisualizationSettings.enumeration(v.global.light_direction, 'global.light_direction', ["headlight","right","left"]);
            brainnet.core.VisualizationSettings.boolean(v.global.show_orientation_labels, 'global.show_orientation_labels');
            brainnet.core.VisualizationSettings.enumeration(v.global.render_detail, 'global.render_detail', ["adaptive","low","moderate","high"]);
            brainnet.core.VisualizationSettings.enumeration(v.global.material_profile, 'global.material_profile', ["dull","shiny","metal","custom"]);
            brainnet.core.VisualizationSettings.materialCoefficients(v.global.material_coefficients);
            brainnet.core.VisualizationSettings.enumeration(v.surface.color_mode, 'surface.color_mode', ["uniform","scalar","vertex-rgb"]);
            brainnet.core.VisualizationSettings.color(v.surface.color, 'surface.color');
            brainnet.core.VisualizationSettings.scalar(v.surface.opacity, 'surface.opacity', 0, 1);
            brainnet.core.Colormap.validate(v.surface.colormap);
            brainnet.core.VisualizationSettings.limits(v.surface.color_limits, 'surface.color_limits', -inf, inf);
            brainnet.core.VisualizationSettings.boolean(v.surface.show_colorbar, 'surface.show_colorbar');
            brainnet.core.VisualizationSettings.boolean(v.surface.double_brain, 'surface.double_brain');
            brainnet.core.VertexColors.validate(v.surface.vertex_colors);
            if ~isempty(v.surface.vertex_colors_mesh_sha256) && isempty(regexp(v.surface.vertex_colors_mesh_sha256,'^[0-9a-f]{64}$','once'))
                error('BNV:VertexColors:InvalidHash','Vertex RGB binding must be a SHA-256 fingerprint.');
            end
            brainnet.core.VisualizationSettings.enumeration(v.surface.boundary_mode, 'surface.boundary_mode', ["none","automatic","legacy-automatic","threshold","custom"]);
            brainnet.core.VisualizationSettings.color(v.surface.boundary_color, 'surface.boundary_color');
            brainnet.core.VisualizationSettings.scalar(v.surface.boundary_threshold,'surface.boundary_threshold',-inf,inf);
            brainnet.core.BoundaryMask.validate(v.surface.boundary_mask);
            if ~isempty(v.surface.boundary_mesh_sha256) && isempty(regexp(v.surface.boundary_mesh_sha256,'^[0-9a-f]{64}$','once'))
                error('BNV:Boundary:InvalidBinding','Boundary geometry signature must be empty or a lowercase SHA-256.');
            end
            brainnet.core.VisualizationSettings.enumeration(v.node.selection_mode, 'node.selection_mode', ["all","threshold","connected"]);
            brainnet.core.VisualizationSettings.enumeration(v.node.selection_basis, 'node.selection_basis', ["value","module"]);
            brainnet.core.VisualizationSettings.scalar(v.node.threshold, 'node.threshold', -inf, inf);
            brainnet.core.VisualizationSettings.enumeration(v.node.label_mode, 'node.label_mode', ["all","none","threshold"]);
            brainnet.core.VisualizationSettings.enumeration(v.node.label_basis, 'node.label_basis', ["value","module"]);
            brainnet.core.VisualizationSettings.scalar(v.node.label_threshold, 'node.label_threshold', -inf, inf);
            brainnet.core.VisualizationSettings.text(v.node.label_font_name, 'node.label_font_name', false);
            brainnet.core.VisualizationSettings.scalar(v.node.label_font_size, 'node.label_font_size', eps, 100);
            brainnet.core.VisualizationSettings.enumeration(v.node.label_font_weight,'node.label_font_weight',["normal","bold"]);
            brainnet.core.VisualizationSettings.enumeration(v.node.label_font_angle,'node.label_font_angle',["normal","italic"]);
            brainnet.core.VisualizationSettings.enumeration(v.node.label_font_units,'node.label_font_units',["points","pixels","normalized","inches","centimeters"]);
            brainnet.core.VisualizationSettings.color(v.node.label_color, 'node.label_color');
            brainnet.core.VisualizationSettings.boolean(v.node.label_in_front, 'node.label_in_front');
            brainnet.core.VisualizationSettings.enumeration(v.node.size_mode, 'node.size_mode', ["uniform","mapped","raw","threshold"]);
            brainnet.core.VisualizationSettings.enumeration(v.node.size_threshold_basis, 'node.size_threshold_basis', ["mapped","raw"]);
            brainnet.core.VisualizationSettings.enumeration(v.node.size_basis, 'node.size_basis', ["value","module"]);
            brainnet.core.VisualizationSettings.scalar(v.node.size, 'node.size', eps, inf);
            brainnet.core.VisualizationSettings.scalar(v.node.size_scale, 'node.size_scale', eps, inf);
            brainnet.core.VisualizationSettings.scalar(v.node.size_threshold, 'node.size_threshold', -inf, inf);
            brainnet.core.VisualizationSettings.enumeration(v.node.color_mode, 'node.color_mode', ["uniform","mapped","modular","threshold","custom"]);
            brainnet.core.VisualizationSettings.color(v.node.color, 'node.color');
            brainnet.core.VisualizationSettings.color(v.node.color_low, 'node.color_low');
            brainnet.core.VisualizationSettings.color(v.node.color_high, 'node.color_high');
            brainnet.core.Colormap.validate(v.node.colormap);
            brainnet.core.VisualizationSettings.limits(v.node.color_limits, 'node.color_limits', -inf, inf);
            brainnet.core.VisualizationSettings.scalar(v.node.color_threshold, 'node.color_threshold', -inf, inf);
            brainnet.core.VisualizationSettings.enumeration(v.edge.selection_mode, 'edge.selection_mode', ["all","threshold","sparsity","legacy-sparsity"]);
            brainnet.core.VisualizationSettings.scalar(v.edge.threshold, 'edge.threshold', -inf, inf);
            brainnet.core.VisualizationSettings.scalar(v.edge.sparsity, 'edge.sparsity', 0, 1);
            brainnet.core.VisualizationSettings.enumeration(v.edge.value_mode, 'edge.value_mode', ["signed","absolute"]);
            brainnet.core.VisualizationSettings.boolean(v.edge.directed, 'edge.directed');
            brainnet.core.VisualizationSettings.boolean(v.edge.inter_hemisphere_only, 'edge.inter_hemisphere_only');
            brainnet.core.VisualizationSettings.enumeration(v.edge.size_mode, 'edge.size_mode', ["uniform","mapped","raw","threshold"]);
            brainnet.core.VisualizationSettings.enumeration(v.edge.size_threshold_basis, 'edge.size_threshold_basis', ["mapped","raw"]);
            brainnet.core.VisualizationSettings.enumeration(v.edge.size_value_mode, 'edge.size_value_mode', ["signed","absolute"]);
            brainnet.core.VisualizationSettings.scalar(v.edge.size, 'edge.size', eps, inf);
            brainnet.core.VisualizationSettings.scalar(v.edge.size_scale, 'edge.size_scale', eps, inf);
            brainnet.core.VisualizationSettings.scalar(v.edge.size_threshold, 'edge.size_threshold', -inf, inf);
            brainnet.core.VisualizationSettings.enumeration(v.edge.color_mode, 'edge.color_mode', ["uniform","mapped","threshold","length","node-module","custom"]);
            brainnet.core.VisualizationSettings.scalar(v.edge.arrow_length_scale, 'edge.arrow_length_scale', 0.25, 3);
            brainnet.core.VisualizationSettings.scalar(v.edge.arrow_width_scale, 'edge.arrow_width_scale', 0.25, 3);
            brainnet.core.VisualizationSettings.color(v.edge.color, 'edge.color');
            brainnet.core.Colormap.validate(v.edge.colormap);
            brainnet.core.VisualizationSettings.limits(v.edge.color_limits, 'edge.color_limits', -inf, inf);
            brainnet.core.VisualizationSettings.scalar(v.edge.color_threshold, 'edge.color_threshold', -inf, inf);
            brainnet.core.VisualizationSettings.scalar(v.edge.length_threshold, 'edge.length_threshold', 0, inf);
            brainnet.core.VisualizationSettings.color(v.edge.color_low, 'edge.color_low');
            brainnet.core.VisualizationSettings.color(v.edge.color_high, 'edge.color_high');
            brainnet.core.VisualizationSettings.color(v.edge.inter_module_color, 'edge.inter_module_color');
            brainnet.core.CustomEdgeColors.validate(v.edge.custom_color);
            brainnet.core.CustomEdgeColors.palette(v.edge.colormap,numel(v.edge.custom_color.indices));
            brainnet.core.VisualizationSettings.enumeration(v.edge.threshold_value_mode, 'edge.threshold_value_mode', ["signed","absolute"]);
            brainnet.core.VisualizationSettings.enumeration(v.edge.mapped_value_mode, 'edge.mapped_value_mode', ["signed","absolute"]);
            brainnet.core.VisualizationSettings.enumeration(v.edge.opacity_mode, 'edge.opacity_mode', ["uniform","mapped"]);
            brainnet.core.VisualizationSettings.enumeration(v.edge.opacity_value_mode, 'edge.opacity_value_mode', ["signed","absolute"]);
            brainnet.core.VisualizationSettings.scalar(v.edge.opacity, 'edge.opacity', 0, 1);
            brainnet.core.VisualizationSettings.limits(v.edge.opacity_range, 'edge.opacity_range', 0, 1);
            if ~isreal(v.edge.opacity_range) || numel(v.edge.opacity_range)~=2
                error('BNV:Core:InvalidRenderOption','edge.opacity_range requires two real bounds in [0,1].');
            end
            brainnet.core.VisualizationSettings.boolean(v.volume.display, 'volume.display');
            brainnet.core.VisualizationSettings.enumeration(v.volume.type, 'volume.type', ["surface-map","roi"]);
            brainnet.core.VisualizationSettings.integer(v.volume.map_algorithm, 'volume.map_algorithm', 1, 8);
            brainnet.core.VisualizationSettings.enumeration(v.volume.threshold_mode, 'volume.threshold_mode', ["none","value","p-value","cluster"]);
            brainnet.core.VisualizationSettings.scalar(v.volume.statistical_threshold, 'volume.statistical_threshold', -inf, inf);
            brainnet.core.VisualizationSettings.scalar(v.volume.p_value, 'volume.p_value', 0, 1);
            brainnet.core.VisualizationSettings.integer(v.volume.cluster_size, 'volume.cluster_size', 0, inf);
            if ~any(v.volume.voxel_connectivity == [6 18 26]), error('BNV:Core:InvalidRenderOption', 'volume.voxel_connectivity must be 6, 18, or 26.'); end
            names = {'positive_minimum','positive_maximum','negative_minimum','negative_maximum'};
            for index = 1:numel(names), brainnet.core.VisualizationSettings.optionalScalar(v.volume.(names{index}), "volume." + names{index}); end
            brainnet.core.VisualizationSettings.ordered(v.volume.positive_minimum, v.volume.positive_maximum, 'positive volume range');
            brainnet.core.VisualizationSettings.ordered(v.volume.negative_minimum, v.volume.negative_maximum, 'negative volume range');
            brainnet.core.VisualizationSettings.enumeration(v.volume.display_mode,'volume.display_mode',["both","positive","negative"]);
            brainnet.core.VisualizationSettings.boolean(v.volume.adjust_null,'volume.adjust_null');
            brainnet.core.VisualizationSettings.color(v.volume.null_color, 'volume.null_color');
            brainnet.core.Colormap.validate(v.volume.colormap);
            brainnet.core.VisualizationSettings.boolean(v.roi.draw_all, 'roi.draw_all');
            if ~isempty(v.roi.selection) && (~isnumeric(v.roi.selection) || any(~isfinite(v.roi.selection(:))) || any(v.roi.selection(:) < 1) || any(v.roi.selection(:) ~= fix(v.roi.selection(:)))), error('BNV:Core:InvalidRenderOption', 'roi.selection must contain positive integer labels.'); end
            brainnet.core.VisualizationSettings.enumeration(v.roi.color_mode, 'roi.color_mode', ["uniform","index","custom"]);
            brainnet.core.VisualizationSettings.enumeration(v.roi.palette,'roi.palette', ...
                brainnet.core.Colormap.names());
            brainnet.core.VisualizationSettings.boolean(v.roi.show_legend,'roi.show_legend');
            brainnet.core.VisualizationSettings.color(v.roi.color, 'roi.color');
            brainnet.core.RoiColors.validate(v.roi.custom_colors);
            brainnet.core.VisualizationSettings.enumeration(v.roi.smoothing, 'roi.smoothing', ["none","box","gaussian"]);
            brainnet.core.VisualizationSettings.integer(v.roi.smoothing_kernel, 'roi.smoothing_kernel', 1, inf);
            brainnet.core.VisualizationSettings.integer(v.image.width, 'image.width', 1, inf);
            brainnet.core.VisualizationSettings.integer(v.image.height, 'image.height', 1, inf);
            brainnet.core.VisualizationSettings.scalar(v.image.dpi, 'image.dpi', eps, inf);
            brainnet.core.VisualizationSettings.boolean(v.image.show_colorbar, 'image.show_colorbar');
            brainnet.core.VisualizationSettings.enumeration(v.image.colorbar_location, 'image.colorbar_location', ["northoutside","southoutside","eastoutside","westoutside"]);
            brainnet.core.VisualizationSettings.text(v.image.colorbar_label, 'image.colorbar_label', true);
            brainnet.core.VisualizationSettings.text(v.image.title, 'image.title', true);
            brainnet.core.VisualizationSettings.boolean(v.fiber.visible, 'fiber.visible');
            brainnet.core.VisualizationSettings.enumeration(v.fiber.color_mode, 'fiber.color_mode', ["direction","uniform","scalar","bundle"]);
            brainnet.core.VisualizationSettings.color(v.fiber.color, 'fiber.color');
            brainnet.core.Colormap.validate(v.fiber.colormap);
            brainnet.core.VisualizationSettings.scalar(v.fiber.opacity, 'fiber.opacity', 0, 1);
            brainnet.core.VisualizationSettings.scalar(v.fiber.radius, 'fiber.radius', eps, inf);
            brainnet.core.VisualizationSettings.integer(v.fiber.sampling_stride, 'fiber.sampling_stride', 1, inf);
            brainnet.core.VisualizationSettings.integer(v.fiber.tube_sides, 'fiber.tube_sides', 3, 64);
        end

        function value = canonicalText(value)
            paths = { ...
                {'schema_version'}; {'global','shading'}; {'global','lighting'}; {'global','light_direction'}; {'global','render_detail'}; {'global','material_profile'}; ...
                {'surface','color_mode'}; {'surface','colormap'}; {'surface','boundary_mode'}; ...
                {'surface','boundary_mesh_sha256'}; {'surface','boundary_mask_source'}; ...
                {'surface','vertex_colors_mesh_sha256'}; {'surface','vertex_colors_source'}; ...
                {'node','selection_mode'}; {'node','selection_basis'}; {'node','label_mode'}; {'node','label_basis'}; ...
                {'node','label_font_name'}; {'node','label_font_weight'}; {'node','label_font_angle'}; {'node','label_font_units'}; {'node','size_mode'}; {'node','size_basis'}; {'node','size_threshold_basis'}; {'node','color_mode'}; {'node','colormap'}; ...
                {'edge','selection_mode'}; {'edge','value_mode'}; {'edge','size_mode'}; {'edge','size_threshold_basis'}; {'edge','size_value_mode'}; {'edge','color_mode'}; {'edge','threshold_value_mode'}; {'edge','mapped_value_mode'}; {'edge','colormap'}; {'edge','opacity_mode'}; {'edge','opacity_value_mode'}; ...
                {'volume','type'}; {'volume','display_mode'}; {'volume','threshold_mode'}; {'volume','colormap'}; ...
                {'roi','color_mode'}; {'roi','palette'}; {'roi','smoothing'}; {'image','colorbar_location'}; {'image','colorbar_label'}; {'image','title'}; ...
                {'fiber','color_mode'}; {'fiber','colormap'} };
            for index = 1:numel(paths)
                [item, ~] = brainnet.core.VisualizationSettings.nested(value, paths{index});
                if contains(string(paths{index}{end}), 'colormap')
                    item = brainnet.core.Colormap.validate(item);
                else
                    item = char(string(item));
                end
                value = brainnet.core.VisualizationSettings.setNested(value, paths{index}, item);
            end
            vectorPaths = { ...
                {'global','background_color'}; {'global','material_coefficients'}; {'surface','color'}; ...
                {'surface','color_limits'}; {'surface','boundary_color'}; ...
                {'node','label_color'}; {'node','color'}; {'node','color_limits'}; ...
                {'node','color_low'}; {'node','color_high'}; ...
                {'edge','color'}; {'edge','color_low'}; {'edge','color_high'}; {'edge','inter_module_color'}; {'edge','color_limits'}; {'edge','opacity_range'}; ...
                {'volume','null_color'}; {'roi','color'}; {'fiber','color'} };
            for index = 1:numel(vectorPaths)
                [item, ~] = brainnet.core.VisualizationSettings.nested(value, vectorPaths{index});
                value = brainnet.core.VisualizationSettings.setNested( ...
                    value, vectorPaths{index}, reshape(item, 1, []));
            end
            value.roi.selection = reshape(value.roi.selection, 1, []);
            value.roi.custom_colors = brainnet.core.RoiColors.validate(value.roi.custom_colors);
            value.surface.boundary_mask=brainnet.core.BoundaryMask.validate(value.surface.boundary_mask);
            value.surface.vertex_colors=brainnet.core.VertexColors.validate(value.surface.vertex_colors);
            value.edge.custom_color=brainnet.core.CustomEdgeColors.validate(value.edge.custom_color);
        end

        function exactFields(value, template, path)
            if ~isstruct(value) || ~isscalar(value), error('BNV:Core:InvalidSettingsStructure', '%s must be an object.', path); end
            actual = fieldnames(value); expected = fieldnames(template);
            missing = setdiff(expected, actual); extra = setdiff(actual, expected);
            if ~isempty(missing), error('BNV:Core:MissingSettingsField', '%s is missing: %s.', path, strjoin(missing, ', ')); end
            if ~isempty(extra), error('BNV:Core:UnknownSettingsField', '%s contains unknown fields: %s.', path, strjoin(extra, ', ')); end
        end

        function result = merge(base, patch)
            result = base; names = fieldnames(patch);
            for index = 1:numel(names)
                name = names{index};
                if ~isfield(base, name), error('BNV:Core:UnknownSettingsField', 'Unknown settings field: %s.', name); end
                if isstruct(base.(name)) && isstruct(patch.(name)), result.(name) = brainnet.core.VisualizationSettings.merge(base.(name), patch.(name)); else, result.(name) = patch.(name); end
            end
        end

        function [value, found] = nested(source, path)
            value = source; found = true;
            for index = 1:numel(path)
                if ~isstruct(value) || ~isfield(value, path{index}), value = []; found = false; return; end
                value = value.(path{index});
            end
        end

        function value = nestedOr(source, path, fallback)
            [value, found] = brainnet.core.VisualizationSettings.nested(source, path);
            if ~found || isempty(value), value = fallback; end
        end

        function source = setNested(source, path, value)
            if isscalar(path), source.(path{1}) = value; else, source.(path{1}) = brainnet.core.VisualizationSettings.setNested(source.(path{1}), path(2:end), value); end
        end

        function value = nameFor(code, names)
            value = names(min(max(round(code), 1), numel(names)));
        end

        function value = codeFor(name, names)
            value = find(string(name) == names, 1);
        end

        function value = nodeColorCode(name)
            value = brainnet.core.VisualizationSettings.codeFor(name, ["uniform","mapped","modular","threshold","custom"]);
            if value == 5, value = 3; end
        end

        function name = colormapName(expression)
            match = regexp(char(string(expression)), '^\s*([A-Za-z]\w*)\s*\(', 'tokens', 'once');
            if isempty(match), name = ""; else, name = string(match{1}); end
        end

        function value = orDefault(value, fallback)
            if isempty(value), value = fallback; end
        end

        function value = limitAt(limits, index, fallback)
            if isempty(limits), value = fallback; else, value = limits(index); end
        end

        function enumeration(value, name, choices)
            if ~any(string(value) == choices), error('BNV:Core:InvalidRenderOption', '%s has an unsupported value.', name); end
        end

        function materialCoefficients(value)
            if ~isnumeric(value) || ~isreal(value) || ~isequal(size(value),[1 3]) || ...
                    any(~isfinite(value)) || any(value<0 | value>1)
                error('BNV:Material:Coefficients','global.material_coefficients must be three finite values in [0,1].');
            end
        end

        function color(value, name)
            if ~isnumeric(value) || numel(value) ~= 3 || any(~isfinite(value)) || any(value < 0) || any(value > 1), error('BNV:Core:InvalidRenderOption', '%s must be a three-element RGB value in [0, 1].', name); end
        end

        function scalar(value, name, low, high)
            if ~isscalar(value) || ~isnumeric(value) || ~isfinite(value) || value < low || value > high, error('BNV:Core:InvalidRenderOption', '%s must be a finite scalar in [%g, %g].', name, low, high); end
        end

        function integer(value, name, low, high)
            brainnet.core.VisualizationSettings.scalar(value, name, low, high);
            if value ~= fix(value), error('BNV:Core:InvalidRenderOption', '%s must be an integer.', name); end
        end

        function optionalScalar(value, name)
            if ~isempty(value), brainnet.core.VisualizationSettings.scalar(value, name, -inf, inf); end
        end

        function optionalRange(value, name, low, high)
            if ~isempty(value), brainnet.core.VisualizationSettings.scalar(value, name, low, high); end
        end

        function limits(value, name, low, high)
            if isempty(value), return; end
            if ~isnumeric(value) || numel(value) ~= 2 || any(~isfinite(value)) || value(1) > value(2) || any(value < low) || any(value > high), error('BNV:Core:InvalidRenderOption', '%s must be empty or an ordered two-element range.', name); end
        end

        function boolean(value, name)
            if ~islogical(value) || ~isscalar(value), error('BNV:Core:InvalidRenderOption', '%s must be logical.', name); end
        end

        function text(value, name, allowEmpty)
            if ~isscalar(string(value)) || (~allowEmpty && strlength(string(value)) == 0), error('BNV:Core:InvalidRenderOption', '%s must be scalar text.', name); end
        end

        function ordered(low, high, name)
            if ~isempty(low) && ~isempty(high) && low > high, error('BNV:Core:InvalidSettingsCombination', '%s minimum cannot exceed maximum.', name); end
        end
    end
end
