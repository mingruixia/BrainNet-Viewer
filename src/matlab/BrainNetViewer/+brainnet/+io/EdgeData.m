classdef EdgeData
    %EDGEDATA Validated square numeric matrix from a BrainNet .edge file.

    properties (SetAccess = private)
        Matrix double
        IsSymmetric (1, 1) logical
        Source
    end

    properties (Dependent)
        Dimension
    end

    methods
        function obj = EdgeData(matrix, source, options)
            arguments
                matrix double
                source (1, 1) brainnet.core.InputReference
                options.RequireSymmetric (1, 1) logical = false
                options.SymmetryTolerance (1, 1) double = 0
            end
            if isempty(matrix) || size(matrix, 1) ~= size(matrix, 2)
                error('BNV:IO:NonSquareEdgeMatrix', 'Edge data must be a non-empty square matrix.');
            end
            if any(~isfinite(matrix), 'all')
                error('BNV:IO:NonFiniteValue', 'Edge values must be finite.');
            end
            if options.SymmetryTolerance < 0 || ~isfinite(options.SymmetryTolerance)
                error('BNV:IO:InvalidSymmetryTolerance', 'Symmetry tolerance must be finite and nonnegative.');
            end
            symmetric = max(abs(matrix - matrix.'), [], 'all') <= options.SymmetryTolerance;
            if options.RequireSymmetric && ~symmetric
                error('BNV:IO:AsymmetricEdgeMatrix', 'Edge matrix does not satisfy the symmetry requirement.');
            end
            obj.Matrix = matrix;
            obj.IsSymmetric = symmetric;
            obj.Source = source;
        end

        function value = get.Dimension(obj)
            value = size(obj.Matrix, 1);
        end
    end
end
