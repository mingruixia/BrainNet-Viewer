classdef VolumePValueThreshold
    %VOLUMEPVALUETHRESHOLD Convert uncorrected P to a statistic cutoff.
    methods (Static)
        function result = fromHeader(header, p)
            if ~isscalar(p) || ~isnumeric(p) || ~isreal(p) || ...
                    ~isfinite(p) || p <= 0 || p >= 1
                error('BNV:Volume:InvalidPValue', ...
                    'P Value must be a finite number strictly between 0 and 1.');
            end
            [kind, degrees, source] = brainnet.core.VolumePValueThreshold.parse(header);
            switch kind
                case {"T", "R"}
                    x = betaincinv(p, degrees(1)/2, 0.5);
                    cutoff = sqrt(degrees(1) * (1-x) / x);
                    if kind == "R"
                        cutoff = sqrt(cutoff^2 / (degrees(1) + cutoff^2));
                    end
                    tail = "two-sided";
                case "F"
                    x = betaincinv(p, degrees(2)/2, degrees(1)/2);
                    cutoff = degrees(2) * (1-x) / (degrees(1) * x);
                    tail = "upper";
                case "Z"
                    cutoff = sqrt(2) * erfcinv(p);
                    tail = "two-sided";
            end
            if ~isfinite(cutoff) || cutoff <= 0
                error('BNV:Volume:InvalidPValue', ...
                    'P Value and degrees of freedom did not produce a finite positive cutoff.');
            end
            result = struct('statistic', char(kind), 'degrees_of_freedom', degrees, ...
                'cutoff', cutoff, 'tail', char(tail), 'source', char(source), ...
                'p_value', double(p));
        end

        function [kind, degrees, source] = parse(header)
            description = "";
            if isfield(header, 'Description')
                description = string(header.Description);
            end
            tokens = regexp(char(description), '\{([TtFfRrZz])_\[([^\]]*)\]\}', 'tokens');
            if numel(tokens) > 1
                error('BNV:Volume:AmbiguousStatistic', ...
                    'NIfTI description contains multiple statistic declarations.');
            end
            if numel(tokens) == 1 && ~isempty(regexpi(char(description), 'SPM|REST|DPABI', 'once'))
                kind = upper(string(tokens{1}{1}));
                degrees = brainnet.core.VolumePValueThreshold.parseDegrees(kind, string(tokens{1}{2}));
                if isfield(header, 'IntentCode') && ismember(header.IntentCode, [2 3 4 5])
                    intentKinds = ["R" "T" "F" "Z"];
                    intentKind = intentKinds(find([2 3 4 5] == header.IntentCode, 1));
                    if intentKind ~= kind
                        error('BNV:Volume:AmbiguousStatistic', ...
                            'NIfTI description and statistical intent declare different statistic types.');
                    end
                    if kind ~= "Z" && isfield(header, 'IntentParameters')
                        intentDegrees = double(header.IntentParameters);
                        intentDegrees = intentDegrees(1:min(numel(intentDegrees),numel(degrees)));
                        if numel(intentDegrees)==numel(degrees) && all(isfinite(intentDegrees)) && ...
                                all(intentDegrees > 0) && any(abs(intentDegrees-degrees) > ...
                                1e-4 * max(1,degrees))
                            error('BNV:Volume:AmbiguousStatistic', ...
                                'NIfTI description and statistical intent declare different degrees of freedom.');
                        end
                    end
                end
                source = "NIfTI description";
                return;
            end
            if isfield(header, 'IntentCode') && isfield(header, 'IntentParameters')
                codes = [2 3 4 5];
                kinds = ["R" "T" "F" "Z"];
                index = find(codes == header.IntentCode, 1);
                if ~isempty(index)
                    kind = kinds(index);
                    raw = double(header.IntentParameters);
                    if numel(raw) < 3
                        error('BNV:Volume:InvalidStatisticMetadata', ...
                            'NIfTI statistical intent is missing its parameter fields.');
                    end
                    if kind == "F"
                        degrees = raw(1:2);
                    elseif kind == "Z"
                        degrees = [];
                    else
                        degrees = raw(1);
                    end
                    brainnet.core.VolumePValueThreshold.validateDegrees(kind, degrees);
                    source = "NIfTI intent";
                    return;
                end
            end
            error('BNV:Volume:MissingStatisticMetadata', ...
                ['P Value needs an SPM/REST/DPABI NIfTI description such as ' ...
                'SPM{T_[20]} or a supported NIfTI statistical intent with degrees of freedom.']);
        end
    end
    methods (Static, Access=private)
        function degrees = parseDegrees(kind, raw)
            if kind == "Z"
                degrees = [];
                return;
            end
            numbers = regexp(strtrim(char(raw)), ...
                '^[+]?\d*\.?\d+(?:[eE][+-]?\d+)?(?:[,;\s]+[+]?\d*\.?\d+(?:[eE][+-]?\d+)?)*$', 'once');
            if isempty(numbers)
                error('BNV:Volume:InvalidStatisticMetadata', ...
                    'NIfTI description contains invalid degrees of freedom.');
            end
            parts = regexp(strtrim(char(raw)), '[,;\s]+', 'split');
            degrees = str2double(parts);
            brainnet.core.VolumePValueThreshold.validateDegrees(kind, degrees);
        end
        function validateDegrees(kind, degrees)
            expected = 1;
            if kind == "F", expected = 2; end
            if kind == "Z", expected = 0; end
            if numel(degrees) ~= expected || any(~isfinite(degrees)) || any(degrees <= 0)
                error('BNV:Volume:InvalidStatisticMetadata', ...
                    'Statistic %s requires %d positive finite degree(s) of freedom.', kind, expected);
            end
        end
    end
end
