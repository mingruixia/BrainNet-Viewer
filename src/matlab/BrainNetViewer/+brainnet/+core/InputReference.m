classdef InputReference
    %INPUTREFERENCE Portable, provenance-aware reference to one scene input.

    properties (SetAccess = private)
        Role (1, 1) string = "surface"
        RelativePath (1, 1) string = ""
        Sha256 (1, 1) string = ""
        CoordinateSpace (1, 1) string = "unknown"
        SourceUri (1, 1) string = ""
        RedistributionStatus (1, 1) string = "not-cleared"
        Metadata struct = struct()
    end

    methods
        function obj = InputReference(role, relativePath, options)
            arguments
                role (1, 1) string
                relativePath (1, 1) string
                options.Sha256 (1, 1) string = ""
                options.CoordinateSpace (1, 1) string = "unknown"
                options.SourceUri (1, 1) string = ""
                options.RedistributionStatus (1, 1) string = "not-cleared"
                options.Metadata struct = struct()
            end

            allowed = ["surface", "node", "edge", "surface_map", "volume"];
            if ~any(role == allowed)
                error('BNV:Core:InvalidInputRole', 'Unsupported scene input role: %s', role);
            end
            normalizedPath = replace(relativePath, "\", "/");
            if strlength(normalizedPath) == 0
                error('BNV:Core:EmptyRelativePath', 'An input relative path is required.');
            end
            if brainnet.core.InputReference.isAbsolute(normalizedPath)
                error('BNV:Core:AbsolutePath', 'Input identity must use a project-relative path.');
            end
            segments = split(normalizedPath, "/");
            if any(segments == "..")
                error('BNV:Core:ParentTraversal', 'Input relative path cannot contain parent traversal.');
            end
            if strlength(options.Sha256) > 0 && isempty(regexp(options.Sha256, '^[0-9a-fA-F]{64}$', 'once'))
                error('BNV:Core:InvalidSha256', 'SHA-256 must contain exactly 64 hexadecimal characters.');
            end

            obj.Role = role;
            obj.RelativePath = normalizedPath;
            obj.Sha256 = lower(options.Sha256);
            obj.CoordinateSpace = options.CoordinateSpace;
            obj.SourceUri = options.SourceUri;
            obj.RedistributionStatus = options.RedistributionStatus;
            obj.Metadata = options.Metadata;
        end

        function absolutePath = resolve(obj, rootPath)
            arguments
                obj (1, 1) brainnet.core.InputReference
                rootPath (1, 1) string
            end
            absolutePath = string(fullfile(rootPath, replace(obj.RelativePath, "/", filesep)));
        end

        function value = toStruct(obj)
            value = struct;
            value.role = char(obj.Role);
            value.relative_path = char(obj.RelativePath);
            value.sha256 = char(obj.Sha256);
            value.coordinate_space = char(obj.CoordinateSpace);
            value.source_uri = char(obj.SourceUri);
            value.redistribution_status = char(obj.RedistributionStatus);
            value.metadata = obj.Metadata;
        end
    end

    methods (Static)
        function obj = fromStruct(value)
            arguments
                value (1, 1) struct
            end
            obj = brainnet.core.InputReference( ...
                string(value.role), ...
                string(value.relative_path), ...
                Sha256=string(brainnet.core.InputReference.fieldOr(value, 'sha256', '')), ...
                CoordinateSpace=string(brainnet.core.InputReference.fieldOr(value, 'coordinate_space', 'unknown')), ...
                SourceUri=string(brainnet.core.InputReference.fieldOr(value, 'source_uri', '')), ...
                RedistributionStatus=string(brainnet.core.InputReference.fieldOr(value, 'redistribution_status', 'not-cleared')), ...
                Metadata=brainnet.core.InputReference.fieldOr(value, 'metadata', struct()));
        end
    end

    methods (Static, Access = private)
        function tf = isAbsolute(pathValue)
            text = char(pathValue);
            tf = startsWith(text, '/') || startsWith(text, '\\') || ...
                ~isempty(regexp(text, '^[A-Za-z]:[/\\]', 'once'));
        end

        function value = fieldOr(source, fieldName, fallback)
            if isfield(source, fieldName)
                value = source.(fieldName);
            else
                value = fallback;
            end
        end
    end
end
