classdef VolumeData
    %VOLUMEDATA Validated NIfTI array, spatial transforms, and provenance.

    properties (SetAccess = private)
        Data
        Header struct
        Affine (4, 4) double
        AffineZeroBased (4, 4) double
        Source
    end

    properties (Dependent)
        Dimensions
        VoxelSizes
    end

    methods
        function obj = VolumeData(data, header, affine, affineZeroBased, source)
            arguments
                data {mustBeNumeric}
                header (1, 1) struct
                affine (4, 4) double
                affineZeroBased (4, 4) double
                source (1, 1) brainnet.core.InputReference
            end
            if isempty(data)
                error('BNV:IO:EmptyVolume', 'Volume data must not be empty.');
            end
            if any(~isfinite(affine), 'all') || any(~isfinite(affineZeroBased), 'all')
                error('BNV:IO:InvalidAffine', 'Volume affine matrices must be finite.');
            end
            obj.Data = data;
            obj.Header = header;
            obj.Affine = affine;
            obj.AffineZeroBased = affineZeroBased;
            obj.Source = source;
        end

        function value = get.Dimensions(obj)
            value = obj.Header.Dimensions;
        end

        function value = get.VoxelSizes(obj)
            value = obj.Header.PixelDimensions(1:min(3, numel(obj.Header.PixelDimensions)));
        end
    end
end
