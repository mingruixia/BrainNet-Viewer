classdef PreparedScene
    %PREPAREDSCENE Immutable renderer-independent numeric render payload.

    properties (SetAccess = private)
        AlgorithmVersion (1, 1) string
        CacheKey (1, 1) string
        SceneId (1, 1) string
        OrientationLabels struct
        SurfaceCoordinates double = zeros(3, 0)
        SurfaceFaces double = zeros(0, 3)
        NodeCoordinates double = zeros(0, 3)
        NodeModules double = zeros(0, 1)
        NodeSizes double = zeros(0, 1)
        NodeLabels (:, 1) string = strings(0, 1)
        EdgePairs double = zeros(0, 2)
        EdgeValues double = zeros(0, 1)
        SurfaceValues double = zeros(1, 0)
        RoiMeshes struct = struct('label', {}, 'vertices', {}, 'faces', {}, 'color', {})
        Acceleration struct = struct()
        Timings struct
    end

    properties (Dependent)
        VertexCount
        FaceCount
        NodeCount
        EdgeCount
        RoiCount
    end

    methods
        function obj = PreparedScene(scene, cacheKey, payload, timings, algorithmVersion)
            arguments
                scene (1, 1) brainnet.core.Scene
                cacheKey (1, 1) string
                payload (1, 1) struct
                timings (1, 1) struct
                algorithmVersion (1, 1) string
            end
            obj.AlgorithmVersion = algorithmVersion;
            obj.CacheKey = cacheKey;
            obj.SceneId = scene.Id;
            obj.OrientationLabels = brainnet.core.OrientationLabels.resolve(scene);
            obj.Timings = timings;
            fields = ["SurfaceCoordinates", "SurfaceFaces", "NodeCoordinates", ...
                "NodeModules", "NodeSizes", "NodeLabels", "EdgePairs", ...
                "EdgeValues", "SurfaceValues", "RoiMeshes"];
            fields(end + 1) = "Acceleration";
            for field = fields
                if isfield(payload, field)
                    obj.(field) = payload.(field);
                end
            end
            obj.validate();
        end

        function value = get.VertexCount(obj)
            value = size(obj.SurfaceCoordinates, 2);
        end

        function value = get.FaceCount(obj)
            value = size(obj.SurfaceFaces, 1);
        end

        function value = get.NodeCount(obj)
            value = size(obj.NodeCoordinates, 1);
        end

        function value = get.EdgeCount(obj)
            value = size(obj.EdgePairs, 1);
        end

        function value = get.RoiCount(obj)
            value = numel(obj.RoiMeshes);
        end

        function value = summary(obj)
            value = struct;
            value.scene_id = char(obj.SceneId);
            value.algorithm_version = char(obj.AlgorithmVersion);
            value.cache_key = char(obj.CacheKey);
            value.vertex_count = obj.VertexCount;
            value.face_count = obj.FaceCount;
            value.node_count = obj.NodeCount;
            value.edge_count = obj.EdgeCount;
            value.roi_count = obj.RoiCount;
            value.surface_value_count = numel(obj.SurfaceValues);
            value.fingerprints = struct( ...
                'surface_coordinates', char(brainnet.io.internal.numericSha256(obj.SurfaceCoordinates)), ...
                'surface_faces', char(brainnet.io.internal.numericSha256(obj.SurfaceFaces)), ...
                'node_coordinates', char(brainnet.io.internal.numericSha256(obj.NodeCoordinates)), ...
                'edge_pairs', char(brainnet.io.internal.numericSha256(obj.EdgePairs)), ...
                'edge_values', char(brainnet.io.internal.numericSha256(obj.EdgeValues)), ...
                'surface_values', char(brainnet.io.internal.numericSha256(obj.SurfaceValues)));
            value.timings_seconds = obj.Timings;
            value.acceleration = obj.Acceleration;
        end
    end

    methods (Access = private)
        function validate(obj)
            if size(obj.SurfaceCoordinates, 1) ~= 3 && ~isempty(obj.SurfaceCoordinates)
                error('BNV:Render:InvalidSurfaceCoordinates', ...
                    'Prepared surface coordinates must be a 3-by-N array.');
            end
            if size(obj.SurfaceFaces, 2) ~= 3 && ~isempty(obj.SurfaceFaces)
                error('BNV:Render:InvalidSurfaceFaces', ...
                    'Prepared surface faces must be an F-by-3 array.');
            end
            if size(obj.NodeCoordinates, 2) ~= 3 && ~isempty(obj.NodeCoordinates)
                error('BNV:Render:InvalidNodeCoordinates', ...
                    'Prepared node coordinates must be an N-by-3 array.');
            end
            if size(obj.EdgePairs, 2) ~= 2 && ~isempty(obj.EdgePairs)
                error('BNV:Render:InvalidEdgePairs', ...
                    'Prepared edge pairs must be an E-by-2 array.');
            end
            if size(obj.EdgePairs, 1) ~= numel(obj.EdgeValues)
                error('BNV:Render:EdgeValueCountMismatch', ...
                    'Every prepared edge must have one numeric value.');
            end
            if ~isempty(obj.SurfaceValues) && numel(obj.SurfaceValues) ~= obj.VertexCount
                error('BNV:Render:SurfaceValueCountMismatch', ...
                    'Prepared surface values must match the surface vertex count.');
            end
            for index = 1:numel(obj.RoiMeshes)
                mesh = obj.RoiMeshes(index);
                if size(mesh.vertices, 2) ~= 3 || size(mesh.faces, 2) ~= 3 || ...
                        ~isscalar(mesh.label) || ~isequal(size(mesh.color), [1 3])
                    error('BNV:Render:InvalidRoiMesh', ...
                        'Every prepared ROI mesh must contain a label, V-by-3 vertices, F-by-3 faces, and one RGB color.');
                end
            end
        end
    end
end
