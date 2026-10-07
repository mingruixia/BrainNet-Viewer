classdef GiftiData
    %GIFTIDATA Validated point-set and triangle arrays from a GIfTI file.

    properties (SetAccess = private)
        Coordinates double
        Faces double
        DataArrays cell
        CoordinateSystems cell
        Source
    end

    properties (Dependent)
        VertexCount
        FaceCount
    end

    methods
        function obj = GiftiData(coordinates, faces, dataArrays, coordinateSystems, source)
            arguments
                coordinates double
                faces double
                dataArrays cell
                coordinateSystems cell
                source (1, 1) brainnet.core.InputReference
            end
            if isempty(coordinates) || size(coordinates, 2) ~= 3 || any(~isfinite(coordinates), 'all')
                error('BNV:IO:InvalidGiftiPointSet', 'GIfTI point-set data must be a finite N-by-3 array.');
            end
            if isempty(faces) || size(faces, 2) ~= 3 || any(~isfinite(faces), 'all') || ...
                    any(faces ~= fix(faces), 'all')
                error('BNV:IO:InvalidGiftiTriangles', 'GIfTI triangle data must be an integer F-by-3 array.');
            end
            if min(faces, [], 'all') < 1 || max(faces, [], 'all') > size(coordinates, 1)
                error('BNV:IO:InvalidFaceIndex', 'GIfTI triangle indices are outside the vertex range.');
            end
            obj.Coordinates = coordinates;
            obj.Faces = faces;
            obj.DataArrays = dataArrays;
            obj.CoordinateSystems = coordinateSystems;
            obj.Source = source;
        end

        function value = get.VertexCount(obj)
            value = size(obj.Coordinates, 1);
        end

        function value = get.FaceCount(obj)
            value = size(obj.Faces, 1);
        end
    end
end
