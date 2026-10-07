classdef SurfaceData
    %SURFACEDATA Validated 3-by-N coordinates and triangular mesh connectivity.

    properties (SetAccess = private)
        Coordinates double
        Faces double
        Source
        Metadata (1,1) struct = struct()
    end

    properties (Dependent)
        VertexCount
        FaceCount
    end

    methods
        function obj = SurfaceData(coordinates, faces, source, options)
            arguments
                coordinates double
                faces double
                source (1, 1) brainnet.core.InputReference
                options.Metadata (1,1) struct = struct()
            end
            if size(coordinates, 1) ~= 3 || isempty(coordinates)
                error('BNV:IO:InvalidSurfaceCoordinates', 'Surface coordinates must be a non-empty 3-by-N array.');
            end
            if size(faces, 2) ~= 3 || isempty(faces)
                error('BNV:IO:InvalidSurfaceFaces', 'Surface faces must be a non-empty F-by-3 array.');
            end
            if any(~isfinite(coordinates), 'all') || any(~isfinite(faces), 'all')
                error('BNV:IO:NonFiniteValue', 'Surface coordinates and faces must be finite.');
            end
            if any(faces ~= fix(faces), 'all')
                error('BNV:IO:InvalidFaceIndex', 'Surface face indices must be integers.');
            end
            if min(faces, [], 'all') < 1 || max(faces, [], 'all') > size(coordinates, 2)
                error('BNV:IO:InvalidFaceIndex', 'Surface face indices are outside the vertex range.');
            end
            obj.Coordinates = coordinates;
            obj.Faces = faces;
            obj.Source = source;
            obj.Metadata = options.Metadata;
        end

        function value = get.VertexCount(obj)
            value = size(obj.Coordinates, 2);
        end

        function value = get.FaceCount(obj)
            value = size(obj.Faces, 1);
        end
    end
end
