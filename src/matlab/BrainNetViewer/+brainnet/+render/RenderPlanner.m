classdef RenderPlanner < handle
    %RENDERPLANNER Build and cache graphics-free numeric render payloads.

    properties (SetAccess = private)
        AlgorithmVersion (1, 1) string
        CacheEnabled (1, 1) logical
        HitCount (1, 1) double = 0
        MissCount (1, 1) double = 0
    end

    properties (Access = private)
        Cache
    end

    methods
        function obj = RenderPlanner(options)
            arguments
                options.AlgorithmVersion (1, 1) string = "render-plan-0.1"
                options.CacheEnabled (1, 1) logical = true
            end
            if strlength(options.AlgorithmVersion) == 0
                error('BNV:Render:InvalidAlgorithmVersion', ...
                    'AlgorithmVersion cannot be empty.');
            end
            obj.AlgorithmVersion = options.AlgorithmVersion;
            obj.CacheEnabled = options.CacheEnabled;
            obj.Cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end

        function [prepared, information] = prepare(obj, scene, data, options)
            arguments
                obj (1, 1) brainnet.render.RenderPlanner
                scene (1, 1) brainnet.core.Scene
                data (1, 1) struct
                options.ComputeBackend (1, 1) string = "auto"
            end
            scene.validate();
            roles=string(cellfun(@(x) char(x.Role),scene.Inputs,'UniformOutput',false));
            brainnet.core.DoubleBrain.requireSupported(scene.Options,any(roles=="surface"), ...
                any(ismember(roles,["volume","surface_map"])));
            brainnet.core.VolumeThresholdPolicy.requireSupported(scene.Options.section('volume'));
            obj.validateDataRoles(scene, data);
            totalTimer = tic;
            cacheKey = obj.keyFor(scene, ComputeBackend=options.ComputeBackend);
            if obj.CacheEnabled && isKey(obj.Cache, char(cacheKey))
                prepared = obj.Cache(char(cacheKey));
                obj.HitCount = obj.HitCount + 1;
                information = obj.information(cacheKey, true, toc(totalTimer), prepared.Timings);
                return;
            end

            [payload, timings] = obj.prepareUncached( ...
                scene, data, options.ComputeBackend);
            prepared = brainnet.render.PreparedScene( ...
                scene, cacheKey, payload, timings, obj.AlgorithmVersion);
            obj.MissCount = obj.MissCount + 1;
            if obj.CacheEnabled
                obj.Cache(char(cacheKey)) = prepared;
            end
            information = obj.information(cacheKey, false, toc(totalTimer), timings);
        end

        function key = keyFor(obj, scene, options)
            arguments
                obj (1, 1) brainnet.render.RenderPlanner
                scene (1, 1) brainnet.core.Scene
                options.ComputeBackend (1, 1) string = "auto"
            end
            if ~any(options.ComputeBackend == ["auto", "cpu", "gpu"])
                error('BNV:Render:UnsupportedComputeBackend', ...
                    'Compute backend must be auto, cpu, or gpu.');
            end
            manifest = struct;
            manifest.algorithm_version = char(obj.AlgorithmVersion);
            manifest.scene_schema_version = char(scene.SchemaVersion);
            manifest.map_mode = scene.MapMode;
            manifest.inputs = struct;
            roleOrder = ["surface", "node", "edge", "surface_map", "volume"];
            for role = roleOrder
                matches = cellfun(@(item) item.Role == role, scene.Inputs);
                if ~any(matches)
                    continue;
                end
                input = scene.Inputs{find(matches, 1)};
                if strlength(input.Sha256) == 0
                    error('BNV:Render:MissingInputHash', ...
                        'A deterministic render cache key requires SHA-256 for role %s.', role);
                end
                manifest.inputs.(char(role)) = lower(char(input.Sha256));
            end
            manifest.geometry_options = struct( ...
                'edge', scene.Options.section("edge"), ...
                'volume', scene.Options.section("volume"), ...
                'roi', scene.Options.section("roi"));
            manifest.compute_backend = char(options.ComputeBackend);
            manifest.orientation_labels = brainnet.core.OrientationLabels.resolve(scene);
            key = brainnet.render.internal.sha256Text(string(jsonencode(manifest)));
        end

        function clearCache(obj)
            remove(obj.Cache, keys(obj.Cache));
            obj.HitCount = 0;
            obj.MissCount = 0;
        end

        function value = statistics(obj)
            value = struct( ...
                'enabled', obj.CacheEnabled, ...
                'entries', obj.Cache.Count, ...
                'hits', obj.HitCount, ...
                'misses', obj.MissCount);
        end
    end

    methods (Access = private)
        function [payload, timings] = prepareUncached(~, scene, data, computeBackend)
            payload = struct;
            payload.Acceleration = struct( ...
                'volume_mapping', struct('requested', char(computeBackend), ...
                'used', 'not-applicable', 'reason', 'scene-has-no-volume'), ...
                'volume_threshold', struct('mode', 'none', ...
                'reason', 'scene-has-no-volume'), ...
                'roi_geometry', struct('generated_mesh_count', 0, ...
                'reason', 'scene-has-no-roi-volume'));

            timer = tic;
            if isfield(data, 'surface')
                surface = data.surface;
                if isa(surface, 'brainnet.io.GiftiData')
                    payload.SurfaceCoordinates = surface.Coordinates.';
                else
                    payload.SurfaceCoordinates = surface.Coordinates;
                end
                payload.SurfaceFaces = surface.Faces;
            end
            timings.surface_geometry = toc(timer);

            timer = tic;
            if isfield(data, 'node')
                payload.NodeCoordinates = data.node.Coordinates;
                payload.NodeModules = data.node.Module;
                payload.NodeSizes = data.node.Size;
                payload.NodeLabels = data.node.Labels;
            end
            timings.node_geometry = toc(timer);

            timer = tic;
            if isfield(data, 'edge')
                edgeSettings = scene.Options.section("edge");
                nodeCoordinates=zeros(0,3);
                if isfield(payload,'NodeCoordinates'), nodeCoordinates=payload.NodeCoordinates; end
                [payload.EdgePairs, payload.EdgeValues] = ...
                    brainnet.render.internal.selectEdgesForSettings( ...
                    data.edge.Matrix, edgeSettings, nodeCoordinates);
            end
            timings.edge_geometry = toc(timer);

            timer = tic;
            if isfield(data, 'surface_map')
                payload.SurfaceValues = reshape(data.surface_map, 1, []);
            elseif isfield(data, 'volume')
                volumeSettings = scene.Options.section("volume");
                if volumeSettings.display && string(volumeSettings.type) == "surface-map"
                    [mappingVolume, payload.Acceleration.volume_threshold] = ...
                        brainnet.render.internal.thresholdVolume( ...
                        data.volume, volumeSettings);
                    [payload.SurfaceValues, payload.Acceleration.volume_mapping] = ...
                        brainnet.render.internal.mapVolumeToSurface(mappingVolume, ...
                        payload.SurfaceCoordinates, volumeSettings.map_algorithm, ...
                        ComputeBackend=computeBackend, ...
                        SurfaceFaces=payload.SurfaceFaces);
                elseif volumeSettings.display
                    [roiVolume, payload.Acceleration.volume_threshold] = ...
                        brainnet.render.internal.prepareRoiVolume(data.volume, volumeSettings);
                    [payload.RoiMeshes, payload.Acceleration.roi_geometry] = ...
                        brainnet.render.internal.buildRoiMeshes( ...
                        roiVolume, scene.Options.section("roi"));
                    payload.Acceleration.volume_mapping = struct( ...
                        'requested', char(computeBackend), 'used', 'not-applicable', ...
                        'reason', 'atlas-roi-geometry');
                    if string(volumeSettings.threshold_mode) ~= "none"
                        payload.Acceleration.volume_mapping.reason = 'statistical-roi-geometry';
                    end
                else
                    payload.Acceleration.volume_mapping.reason = 'volume-display-disabled';
                end
            end
            timings.volume_mapping = toc(timer);
            timings.roi_geometry = 0;
            if isfield(payload, 'RoiMeshes') && ...
                    isfield(payload.Acceleration.roi_geometry, 'seconds')
                timings.roi_geometry = payload.Acceleration.roi_geometry.seconds;
            end
            timings.total = timings.surface_geometry + timings.node_geometry + ...
                timings.edge_geometry + timings.volume_mapping;
        end

        function validateDataRoles(~, scene, data)
            for index = 1:numel(scene.Inputs)
                role = char(scene.Inputs{index}.Role);
                if ~isfield(data, role)
                    error('BNV:Render:MissingLoadedRole', ...
                        'Loaded render data is missing role %s.', role);
                end
            end
            volumeSettings = scene.Options.section("volume");
            if isfield(data, 'volume') && ~isfield(data, 'surface') && ...
                    string(volumeSettings.type) == "surface-map"
                error('BNV:Render:VolumeRequiresSurface', ...
                    'Volume mapping requires loaded surface geometry.');
            end
        end

        function value = information(~, key, cacheHit, totalSeconds, stageTimings)
            value = struct( ...
                'cache_key', char(key), ...
                'cache_hit', cacheHit, ...
                'request_seconds', totalSeconds, ...
                'stage_timings_seconds', stageTimings);
        end
    end
end
