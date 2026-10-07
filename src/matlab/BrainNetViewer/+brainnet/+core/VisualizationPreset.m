classdef VisualizationPreset
    %VISUALIZATIONPRESET Portable settings only: no inputs or session state.
    properties (SetAccess = private)
        Name (1,1) string
        Settings (1,1) brainnet.core.VisualizationSettings
    end
    methods
        function obj = VisualizationPreset(settings, name)
            arguments
                settings (1,1) brainnet.core.VisualizationSettings
                name (1,1) string = "Custom"
            end
            if ismissing(name) || strlength(strtrim(name)) == 0
                error('BNV:Preset:InvalidName', 'Preset name must not be empty.');
            end
            obj.Name = name;
            obj.Settings = settings;
        end
        function value = toStruct(obj)
            value = struct('kind', 'brainnet-visualization-preset', ...
                'schema_version', '1.0', 'name', char(obj.Name), ...
                'settings', obj.Settings.toStruct());
        end
        function report = checkCompatibility(obj, scene)
            % Role/capability preflight, not a substitute for data validation.
            arguments
                obj (1,1) brainnet.core.VisualizationPreset
                scene = []
            end
            d = obj.Settings.toStruct();
            warnings = strings(0,1); blockers = strings(0,1);
            if d.fiber.visible
                blockers(end+1) = "Fiber rendering is not implemented in this build.";
            end
            thresholdBlocker=brainnet.core.VolumeThresholdPolicy.blocker(d.volume);
            if strlength(thresholdBlocker)>0
                blockers(end+1) = thresholdBlocker;
            elseif string(d.volume.threshold_mode)=="p-value"
                warnings(end+1) = "P Value requires supported NIfTI statistic metadata and degrees of freedom; checked at render time. Statistical ROI mode also applies Cluster Size. No multiple-comparison correction is applied.";
            end
            roles = strings(0,1);
            if d.surface.double_brain
                try
                    hasSurface=true; hasMapping=false;
                    if ~isempty(scene)
                        presetRoles=string(cellfun(@(x) char(x.Role),scene.Inputs,'UniformOutput',false));
                        hasSurface=any(presetRoles=="surface"); hasMapping=any(ismember(presetRoles,["volume","surface_map"]));
                    end
                    brainnet.core.DoubleBrain.requireSupported( ...
                        brainnet.core.RenderOptions.fromVisualizationStruct(d),hasSurface,hasMapping);
                catch failure
                    blockers(end+1)=string(failure.message);
                end
            end
            if ~isempty(scene)
                assert(isa(scene, 'brainnet.core.Scene'), 'BNV:Preset:InvalidScene', ...
                    'Compatibility requires a BrainNet Scene.');
                roles = string(cellfun(@(v) char(v.Role), scene.Inputs, 'UniformOutput', false));
                absent = setdiff(["surface"; "node"; "edge"; "volume"], roles, 'stable');
                warnings = [warnings; "No " + absent + ...
                    " input: its settings remain stored but inactive."];
                if d.volume.display && ~any(roles == "volume")
                    warnings(end+1) = "Volume display is enabled, but no volume is selected.";
                end
                if string(d.surface.color_mode) ~= "uniform" && ...
                        ~any(ismember(roles, ["surface_map", "volume"]))
                    warnings(end+1) = "Mapped surface colors require compatible mapped data; uniform fallback may be used.";
                end
            end
            if string(d.roi.color_mode) == "custom"
                if isempty(d.roi.custom_colors)
                    warnings(end+1) = "The custom ROI color table is empty. Supply ROI_ID R G B rows or select Label Index; rendering fails if any selected ROI lacks a color.";
                else
                    warnings(end+1) = "Custom ROI colors are supported by Modern Batch Renderer. Selected ROI ID coverage is checked at render time; review IDs after data or statistical-threshold changes.";
                end
            end
            status = 'ready';
            if string(d.surface.color_mode)=="vertex-rgb"
                if isempty(d.surface.vertex_colors) || isempty(d.surface.vertex_colors_mesh_sha256)
                    blockers(end+1)="Vertex RGB must be loaded and explicitly bound to the surface.";
                else
                    warnings(end+1)="Vertex RGB requires matching ordered surface geometry and N/2N rows; checked at rendering.";
                end
            end
            if ~isempty(d.surface.boundary_mask)
                warnings(end+1)="Custom mask is tied to ordered geometry; rendering requires the matching surface.";
            end
            if string(d.surface.boundary_mode)=="custom" && ...
                    (isempty(d.surface.boundary_mask)||isempty(d.surface.boundary_mesh_sha256))
                blockers(end+1)="Custom mask must be loaded and explicitly bound to its surface.";
            end
            if isempty(scene), status = 'deferred-until-data'; end
            if ~isempty(warnings), status = 'review-required'; end
            if ~isempty(blockers), status = 'blocked'; end
            report = struct('status', status, 'warnings', {cellstr(warnings)}, ...
                'blockers', {cellstr(blockers)}, 'input_roles', {cellstr(roles)}, ...
                'inputs_replaced', false, 'camera_imported', false, ...
                'note', 'Role-level preflight only. Review thresholds, units and color limits for each dataset.');
        end
    end
    methods (Static)
        function obj = fromStruct(value)
            required = {'kind'; 'schema_version'; 'name'; 'settings'};
            if ~isstruct(value) || ~isscalar(value) || ...
                    ~isequal(sort(fieldnames(value)), sort(required))
                error('BNV:Preset:InvalidDocument', ...
                    'Expected a settings-only preset with kind, schema_version, name and settings.');
            end
            if ~ischar(value.kind) || ~strcmp(value.kind, 'brainnet-visualization-preset') || ...
                    ~ischar(value.schema_version) || ~strcmp(value.schema_version, '1.0')
                error('BNV:Preset:UnsupportedVersion', 'Unknown preset type or schema version.');
            end
            if ~ischar(value.name) || ~isrow(value.name)
                error('BNV:Preset:InvalidName', 'Preset name must be a nonempty text string.');
            end
            if ~isstruct(value.settings) || ~isscalar(value.settings) || ...
                    isempty(fieldnames(value.settings))
                error('BNV:Preset:InvalidSettings', 'Preset settings must be a complete settings object.');
            end
            obj = brainnet.core.VisualizationPreset( ...
                brainnet.core.VisualizationSettings.fromStruct(value.settings), string(value.name));
        end
    end
end
