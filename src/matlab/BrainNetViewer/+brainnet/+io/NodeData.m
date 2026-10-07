classdef NodeData
    %NODEDATA Validated numeric values and labels from a BrainNet .node file.

    properties (SetAccess = private)
        Values double
        Labels (:, 1) string
        Source
    end

    properties (Dependent)
        Count
        Coordinates
        Module
        Size
    end

    methods
        function obj = NodeData(values, labels, source)
            arguments
                values double
                labels (:, 1) string
                source (1, 1) brainnet.core.InputReference
            end
            if size(values, 2) ~= 5 || isempty(values)
                error('BNV:IO:InvalidNodeColumns', 'Node values must be a non-empty N-by-5 array.');
            end
            if size(values, 1) ~= numel(labels)
                error('BNV:IO:NodeLabelCountMismatch', 'Every node must have exactly one label.');
            end
            if any(~isfinite(values), 'all')
                error('BNV:IO:NonFiniteValue', 'Node numeric values must be finite.');
            end
            if any(strlength(strip(labels)) == 0)
                error('BNV:IO:MissingNodeLabel', 'Every node must have a non-empty label.');
            end
            obj.Values = values;
            obj.Labels = labels;
            obj.Source = source;
        end

        function value = get.Count(obj)
            value = size(obj.Values, 1);
        end

        function value = get.Coordinates(obj)
            value = obj.Values(:, 1:3);
        end

        function value = get.Module(obj)
            value = obj.Values(:, 4);
        end

        function value = get.Size(obj)
            value = obj.Values(:, 5);
        end
    end
end
