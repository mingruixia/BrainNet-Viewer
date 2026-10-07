classdef Scene
    %SCENE Versioned, portable contract for a BrainNet visualization scene.

    properties (SetAccess = private)
        SchemaVersion (1, 1) string = "0.1"
        Id (1, 1) string = ""
        Name (1, 1) string = ""
        LoadFile (1, 1) double = 0
        MapMode (1, 1) double = 0
        Inputs (1, :) cell = {}
        Options (1, 1) brainnet.core.RenderOptions = brainnet.core.RenderOptions()
        CoordinateSpace (1, 1) string = "unknown"
        RedistributionStatus (1, 1) string = "not-cleared"
        Metadata struct = struct()
    end

    methods
        function obj = Scene(id, name, loadFile, mapMode, inputs, options)
            arguments
                id (1, 1) string
                name (1, 1) string
                loadFile (1, 1) double
                mapMode (1, 1) double
                inputs (1, :) cell
                options.Options (1, 1) brainnet.core.RenderOptions = brainnet.core.RenderOptions()
                options.SchemaVersion (1, 1) string = "0.1"
                options.CoordinateSpace (1, 1) string = "unknown"
                options.RedistributionStatus (1, 1) string = "not-cleared"
                options.Metadata struct = struct()
            end
            if strlength(id) == 0 || isempty(regexp(id, '^[A-Za-z][A-Za-z0-9_.-]*$', 'once'))
                error('BNV:Core:InvalidSceneId', 'Scene ID must be a non-empty portable identifier.');
            end
            if strlength(name) == 0
                error('BNV:Core:InvalidSceneName', 'Scene name cannot be empty.');
            end
            if ~isfinite(loadFile) || loadFile ~= fix(loadFile) || loadFile < 0 || loadFile > 15
                error('BNV:Core:InvalidLoadFile', 'LoadFile must be an integer from 0 through 15.');
            end
            if ~any(mapMode == [0, 1, 2])
                error('BNV:Core:InvalidMapMode', 'MapMode must be 0, 1, or 2.');
            end
            if ~all(cellfun(@(item) isa(item, 'brainnet.core.InputReference'), inputs))
                error('BNV:Core:InvalidInputs', 'Every scene input must be an InputReference.');
            end

            obj.SchemaVersion = options.SchemaVersion;
            obj.Id = id;
            obj.Name = name;
            obj.LoadFile = loadFile;
            obj.MapMode = mapMode;
            obj.Inputs = inputs;
            obj.Options = options.Options;
            obj.CoordinateSpace = options.CoordinateSpace;
            obj.RedistributionStatus = options.RedistributionStatus;
            obj.Metadata = options.Metadata;
            obj.validate();
        end

        function validate(obj)
            roles = string(cellfun(@(item) char(item.Role), obj.Inputs, 'UniformOutput', false));
            if numel(unique(roles)) ~= numel(roles)
                error('BNV:Core:DuplicateInputRole', 'A scene cannot contain duplicate input roles.');
            end
            roleBits = struct('surface', 1, 'node', 2, 'edge', 4, 'surface_map', 8, 'volume', 8);
            expectedLoadFile = 0;
            for index = 1:numel(roles)
                expectedLoadFile = expectedLoadFile + roleBits.(char(roles(index)));
            end
            if expectedLoadFile ~= obj.LoadFile
                error('BNV:Core:LoadFileMismatch', ...
                    'LoadFile %d does not match the input-role mask %d.', obj.LoadFile, expectedLoadFile);
            end
            hasSurfaceMap = any(roles == "surface_map");
            hasVolume = any(roles == "volume");
            if obj.MapMode == 0 && (hasSurfaceMap || hasVolume)
                error('BNV:Core:MapModeMismatch', 'MapMode 0 cannot include mapped data.');
            elseif obj.MapMode == 1 && (~hasSurfaceMap || hasVolume)
                error('BNV:Core:MapModeMismatch', 'MapMode 1 requires surface_map and no volume.');
            elseif obj.MapMode == 2 && (~hasVolume || hasSurfaceMap)
                error('BNV:Core:MapModeMismatch', 'MapMode 2 requires volume and no surface_map.');
            end
        end

        function input = inputByRole(obj, role)
            arguments
                obj (1, 1) brainnet.core.Scene
                role (1, 1) string
            end
            matches = cellfun(@(item) item.Role == role, obj.Inputs);
            if nnz(matches) ~= 1
                error('BNV:Core:InputRoleNotFound', 'Scene does not contain exactly one %s input.', role);
            end
            input = obj.Inputs{find(matches, 1)};
        end

        function value = toStruct(obj)
            value = struct;
            value.schema_version = char(obj.SchemaVersion);
            value.id = char(obj.Id);
            value.name = char(obj.Name);
            value.loadfile = obj.LoadFile;
            value.map_mode = obj.MapMode;
            value.coordinate_space = char(obj.CoordinateSpace);
            value.redistribution_status = char(obj.RedistributionStatus);
            value.inputs = struct;
            for index = 1:numel(obj.Inputs)
                input = obj.Inputs{index};
                value.inputs.(char(input.Role)) = input.toStruct();
            end
            value.options = obj.Options.toStruct();
            value.metadata = obj.Metadata;
        end

        function text = toJson(obj)
            text = jsonencode(obj.toStruct(), 'PrettyPrint', true);
        end
    end

    methods (Static)
        function obj = fromStruct(value)
            arguments
                value (1, 1) struct
            end
            inputFields = fieldnames(value.inputs);
            inputs = cell(1, numel(inputFields));
            for index = 1:numel(inputFields)
                inputs{index} = brainnet.core.InputReference.fromStruct(value.inputs.(inputFields{index}));
            end
            obj = brainnet.core.Scene( ...
                string(value.id), string(value.name), value.loadfile, value.map_mode, inputs, ...
                Options=brainnet.core.RenderOptions.fromStruct(value.options), ...
                SchemaVersion=string(brainnet.core.Scene.fieldOr(value, 'schema_version', '0.1')), ...
                CoordinateSpace=string(brainnet.core.Scene.fieldOr(value, 'coordinate_space', 'unknown')), ...
                RedistributionStatus=string(brainnet.core.Scene.fieldOr(value, 'redistribution_status', 'not-cleared')), ...
                Metadata=brainnet.core.Scene.fieldOr(value, 'metadata', struct()));
            if isfield(value.options,'visualization_settings') && ...
                    any(strcmp(value.options.visualization_settings.schema_version,{'1.0.0','1.1.0','1.2.0','1.3.0','1.4.0','1.5.0','1.6.0','1.7.0','1.8.0','1.9.0','1.10.0','1.11.0'}))
                obj.Metadata.edge_hemisphere_upgrade=struct('from',value.options.visualization_settings.schema_version, ...
                    'to','1.12.0','review_required',true, ...
                    'note','Inter-hemisphere-only defaults to off. Earlier EC imports ignored interhemiedges; reimport the original EC to recover that intent. Uses node x=0 as midline, including midline endpoints.');
            end
            if isfield(value.options,'visualization_settings') && ...
                    any(string(value.options.visualization_settings.schema_version)== ...
                    "1."+string(0:13)+".0")
                obj.Metadata.node_label_upgrade=struct('to','1.14.0','review_required',true, ...
                    'note','Label placement now follows each camera with a radius-aware upward offset; foreground uses a camera-facing plane. Old font defaults remain normal/normal/points; reimport original EC to recover missing typography.');
            end
            if isfield(value.options,'visualization_settings') && ...
                    any(string(value.options.visualization_settings.schema_version)== ...
                    "1."+string(0:14)+".0")
                obj.Metadata.volume_display_upgrade=struct('to','1.15.0','review_required',true, ...
                    'note','Defaults preserve Both and Adjust for Null on. Earlier EC imports lost display/adjustCM intent; reimport the original EC.');
            end
            if isfield(value.options,'visualization_settings') && ...
                    any(string(value.options.visualization_settings.schema_version)== ...
                    "1."+string(0:15)+".0")
                obj.Metadata.roi_color_upgrade=struct('to','1.16.0','review_required',true, ...
                    'note','Old Custom ROI mode used index fallback. Supply explicit ROI ID/RGB rows or choose Index; Custom no longer falls back.');
            end
            % Settings upgrades change the signature. Rebind only after checking the old canonical hash;
            % stale data/settings must never acquire a valid camera binding.
            if isfield(value.options,'visualization_settings') && ...
                    any(strcmp(value.options.visualization_settings.schema_version,{'1.0.0','1.1.0','1.2.0','1.3.0','1.4.0','1.5.0','1.6.0','1.7.0','1.8.0','1.9.0','1.10.0','1.11.0','1.12.0','1.13.0','1.14.0','1.15.0','1.16.0','1.17.0'})) && ...
                    isfield(obj.Metadata,'session_state')
                state=brainnet.core.SessionState.fromScene(obj);
                previous=obj.toStruct();
                previous.options.visualization_settings.schema_version=value.options.visualization_settings.schema_version;
                for field=["color_low","color_high","threshold_value_mode","size_threshold_basis","size_value_mode","mapped_value_mode","opacity_value_mode","inter_module_color","custom_color","inter_hemisphere_only"]
                    if ~isfield(value.options.visualization_settings.edge,field)
                        previous.options.visualization_settings.edge=rmfield(previous.options.visualization_settings.edge,field);
                    end
                end
                for field=["color_low","color_high","size_threshold_basis","label_font_weight","label_font_angle","label_font_units"]
                    if ~isfield(value.options.visualization_settings.node,field)
                        previous.options.visualization_settings.node=rmfield(previous.options.visualization_settings.node,field);
                    end
                end
                for field=["custom_colors","palette","show_legend"]
                    if ~isfield(value.options.visualization_settings.roi,field)
                        previous.options.visualization_settings.roi=rmfield(previous.options.visualization_settings.roi,field);
                    end
                end
                for field=["display_mode","adjust_null"]
                    if ~isfield(value.options.visualization_settings.volume,field)
                        previous.options.visualization_settings.volume=rmfield(previous.options.visualization_settings.volume,field);
                    end
                end
                for field=["vertex_colors","vertex_colors_mesh_sha256","vertex_colors_source","double_brain","boundary_threshold","boundary_mask","boundary_mesh_sha256","boundary_mask_source"]
                    if ~isfield(value.options.visualization_settings.surface,field)
                        previous.options.visualization_settings.surface=rmfield(previous.options.visualization_settings.surface,field);
                    end
                end
                if strcmp(state.scene_signature,brainnet.core.SessionState.signatureForDocument(value)) || ...
                        strcmp(state.scene_signature,brainnet.core.SessionState.signatureForDocument(previous))
                    obj.Metadata.session_state.scene_signature=char(brainnet.core.SessionState.signature(obj));
                end
            end
            if isfield(value.options,'visualization_settings') && ...
                    any(strcmp(value.options.visualization_settings.schema_version,{'1.0.0','1.1.0','1.2.0','1.3.0','1.4.0','1.5.0','1.6.0'}))
                obj.Metadata.edge_size_upgrade=struct('from',value.options.visualization_settings.schema_version, ...
                    'to','1.7.0','review_required',true, ...
                    'note','Uniform edge radii now include scale. Threshold selects original weights before mapping the retained subset. Size signs default to Absolute and threshold basis to Mapped; original EC Raw intent cannot be recovered. Review or reimport the original EC.');
            end
            if isfield(value.options,'visualization_settings') && ...
                    any(strcmp(value.options.visualization_settings.schema_version,{'1.0.0','1.1.0','1.2.0','1.3.0','1.4.0','1.5.0','1.6.0','1.7.0','1.8.0','1.9.0','1.10.0'}))
                obj.Metadata.edge_custom_upgrade=struct('from',value.options.visualization_settings.schema_version, ...
                    'to','1.11.0','review_required',true, ...
                    'note','Old Custom edge mode had no matrix implementation. Load or reimport the actual matrix and confirm the current node order before rendering.');
            end
            if isfield(value.options,'visualization_settings') && ...
                    any(strcmp(value.options.visualization_settings.schema_version,{'1.0.0','1.1.0','1.2.0','1.3.0','1.4.0','1.5.0','1.6.0','1.7.0','1.8.0','1.9.0'}))
                obj.Metadata.edge_module_upgrade=struct('from',value.options.visualization_settings.schema_version, ...
                    'to','1.10.0','review_required',true, ...
                    'note','Module-edge colors now compare both endpoints and rank all node modules using 20 colors. Inter-module color defaults to gray; review colors or reimport the original EC. Label 21 is no longer a sentinel.');
            end
            if isfield(value.options,'visualization_settings') && ...
                    any(strcmp(value.options.visualization_settings.schema_version,{'1.0.0','1.1.0','1.2.0','1.3.0','1.4.0','1.5.0','1.6.0','1.7.0','1.8.0'}))
                obj.Metadata.edge_opacity_upgrade=struct('from',value.options.visualization_settings.schema_version, ...
                    'to','1.9.0','review_required',true, ...
                    'note','Opacity signs default to Absolute. Constant weights use the upper opacity; tiny nonzero ranges now map linearly. Original EC Signed intent cannot be recovered; review or reimport the original EC.');
            end
            if isfield(value.options,'visualization_settings') && ...
                    any(strcmp(value.options.visualization_settings.schema_version,{'1.0.0','1.1.0','1.2.0','1.3.0','1.4.0','1.5.0','1.6.0','1.7.0'}))
                obj.Metadata.edge_mapped_color_upgrade=struct('from',value.options.visualization_settings.schema_version, ...
                    'to','1.8.0','review_required',true, ...
                    'note','Mapped edge colors now use 64 bins and the last color for constant ranges. Old development settings default to Signed; original EC signs, palette and fixed range cannot be recovered. Review or reimport the original EC.');
            end
            if isfield(value.options,'visualization_settings') && ...
                    any(strcmp(value.options.visualization_settings.schema_version,{'1.0.0','1.1.0','1.2.0','1.3.0','1.4.0','1.5.0'}))
                obj.Metadata.edge_color_upgrade=struct('from',value.options.visualization_settings.schema_version, ...
                    'to','1.6.0','review_required',true, ...
                    'note','Edge Threshold now uses strict > and independent signed/absolute values; Length uses >=. Both use fixed colors. Migrated colors use the previous base color and colormap endpoint, not the original EC. Review or reimport the original EC.');
            end
            if isfield(value.options,'visualization_settings') && ...
                    any(strcmp(value.options.visualization_settings.schema_version,{'1.0.0','1.1.0','1.2.0'}))
                obj.Metadata.node_color_upgrade=struct('from',value.options.visualization_settings.schema_version, ...
                    'to','1.3.0','review_required',true, ...
                    'note','Node mapped/threshold colors now use column 4. Threshold uses fixed colors and strict >. Review old development scenes; rendered colors may change.');
            end
            if isfield(value.options,'visualization_settings') && ...
                    any(strcmp(value.options.visualization_settings.schema_version,{'1.0.0','1.1.0','1.2.0','1.3.0'}))
                obj.Metadata.node_size_upgrade=struct('from',value.options.visualization_settings.schema_version, ...
                    'to','1.4.0','review_required',true, ...
                    'note','Uniform radii now include scale; Threshold uses mapped/raw radii, floors values below threshold to 1, then scales. Old module-based settings remain module-based; reimport the original EC to recover Raw intent. Review node sizes.');
            end
            if isfield(value.options,'visualization_settings') && ...
                    any(strcmp(value.options.visualization_settings.schema_version,{'1.0.0','1.1.0','1.2.0','1.3.0','1.4.0'}))
                obj.Metadata.node_selection_upgrade=struct('from',value.options.visualization_settings.schema_version, ...
                    'to','1.5.0','review_required',true, ...
                    'note','Node selection and label thresholds now use strict > on original column 5 or 4. A single dash suppresses a label. Connected still uses selected edge endpoints. Review equality cases and labels.');
            end
        end

        function obj = fromJson(text)
            arguments
                text (1, 1) string
            end
            obj = brainnet.core.Scene.fromStruct(jsondecode(text));
        end

        function obj = fromGoldenScene(scene)
            arguments
                scene (1, 1) struct
            end
            coordinateSpace = string(brainnet.core.Scene.fieldOr(scene, 'coordinate_space', 'unknown'));
            redistribution = string(brainnet.core.Scene.fieldOr(scene, 'redistribution_status', 'not-cleared'));
            inputFields = fieldnames(scene.inputs);
            inputs = cell(1, numel(inputFields));
            for index = 1:numel(inputFields)
                role = inputFields{index};
                source = scene.inputs.(role);
                metadata = source;
                removable = intersect(fieldnames(metadata), {'role', 'relative_path', 'sha256'});
                if ~isempty(removable)
                    metadata = rmfield(metadata, removable);
                end
                inputs{index} = brainnet.core.InputReference( ...
                    string(role), string(source.relative_path), ...
                    Sha256=string(source.sha256), ...
                    CoordinateSpace=coordinateSpace, ...
                    RedistributionStatus=redistribution, ...
                    Metadata=metadata);
            end
            metadata = scene;
            removable = intersect(fieldnames(metadata), ...
                {'id', 'name', 'loadfile', 'map_mode', 'inputs', 'settings', ...
                'coordinate_space', 'redistribution_status'});
            metadata = rmfield(metadata, removable);
            obj = brainnet.core.Scene( ...
                string(scene.id), string(scene.name), scene.loadfile, scene.map_mode, inputs, ...
                Options=brainnet.core.RenderOptions.fromGoldenScene(scene), ...
                CoordinateSpace=coordinateSpace, ...
                RedistributionStatus=redistribution, ...
                Metadata=metadata);
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
    end
end
