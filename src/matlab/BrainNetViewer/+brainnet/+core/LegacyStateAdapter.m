classdef LegacyStateAdapter
    %LEGACYSTATEADAPTER Read-only conversion from File/FLAG/EC to Scene.

    methods (Static)
        function scene = fromLegacy(id, name, fileState, flagState, configuration, brainNetRoot, options)
            arguments
                id (1, 1) string
                name (1, 1) string
                fileState (1, 1) struct
                flagState (1, 1) struct
                configuration (1, 1) struct
                brainNetRoot (1, 1) string
                options.ReferenceCatalog struct = struct()
                options.CoordinateSpace (1, 1) string = "legacy-assumed-MNI; requires explicit verification"
                options.RedistributionStatus (1, 1) string = "internal-baseline-only until resource license review"
            end
            if ~isfield(flagState, 'Loadfile') || ~isfield(flagState, 'MAP')
                error('BNV:Core:IncompleteLegacyFlags', 'Legacy FLAG must contain Loadfile and MAP.');
            end
            inputs = {};
            inputs = brainnet.core.LegacyStateAdapter.appendInput( ...
                inputs, 'surface', fileState, 'MF', brainNetRoot, options);
            inputs = brainnet.core.LegacyStateAdapter.appendInput( ...
                inputs, 'node', fileState, 'NI', brainNetRoot, options);
            inputs = brainnet.core.LegacyStateAdapter.appendInput( ...
                inputs, 'edge', fileState, 'NT', brainNetRoot, options);
            if isfield(fileState, 'VF') && ~isempty(fileState.VF)
                if flagState.MAP == 1
                    role = 'surface_map';
                elseif flagState.MAP == 2
                    role = 'volume';
                else
                    error('BNV:Core:MapModeMismatch', 'Legacy VF requires MAP 1 or 2.');
                end
                inputs = brainnet.core.LegacyStateAdapter.appendPath( ...
                    inputs, role, string(fileState.VF), brainNetRoot, options);
            end
            metadata = struct('adapter', 'legacy-read-only', 'legacy_fields', {{'File', 'FLAG', 'EC'}});
            scene = brainnet.core.Scene( ...
                id, name, flagState.Loadfile, flagState.MAP, inputs, ...
                Options=brainnet.core.RenderOptions.fromLegacy(configuration, flagState.MAP), ...
                CoordinateSpace=options.CoordinateSpace, ...
                RedistributionStatus=options.RedistributionStatus, ...
                Metadata=metadata);
        end
    end

    methods (Static, Access = private)
        function inputs = appendInput(inputs, role, fileState, fieldName, brainNetRoot, options)
            if isfield(fileState, fieldName) && ~isempty(fileState.(fieldName))
                inputs = brainnet.core.LegacyStateAdapter.appendPath( ...
                    inputs, role, string(fileState.(fieldName)), brainNetRoot, options);
            end
        end

        function inputs = appendPath(inputs, role, absolutePath, brainNetRoot, options)
            relativePath = brainnet.core.LegacyStateAdapter.makeRelative(absolutePath, brainNetRoot);
            if isfield(options.ReferenceCatalog, role)
                catalog = options.ReferenceCatalog.(role);
                if ~strcmp(replace(string(catalog.relative_path), "\", "/"), relativePath)
                    error('BNV:Core:CatalogPathMismatch', 'Reference catalog path does not match legacy %s.', role);
                end
                metadata = catalog;
                removable = intersect(fieldnames(metadata), {'role', 'relative_path', 'sha256'});
                if ~isempty(removable)
                    metadata = rmfield(metadata, removable);
                end
                sha = string(catalog.sha256);
            else
                metadata = struct();
                sha = brainnet.core.LegacyStateAdapter.sha256(absolutePath);
            end
            reference = brainnet.core.InputReference( ...
                string(role), relativePath, ...
                Sha256=sha, ...
                CoordinateSpace=options.CoordinateSpace, ...
                RedistributionStatus=options.RedistributionStatus, ...
                Metadata=metadata);
            inputs{end + 1} = reference;
        end

        function relativePath = makeRelative(pathValue, rootValue)
            absolutePath = string(char(java.io.File(char(pathValue)).getCanonicalPath()));
            rootPath = string(char(java.io.File(char(rootValue)).getCanonicalPath()));
            rootPrefix = rootPath + string(filesep);
            if ispc
                inside = startsWith(lower(absolutePath), lower(rootPrefix));
            else
                inside = startsWith(absolutePath, rootPrefix);
            end
            if ~inside
                error('BNV:Core:ExternalPathRequiresReference', ...
                    'Legacy input is outside BrainNetRoot and needs an explicit portable reference.');
            end
            relativePath = extractAfter(absolutePath, strlength(rootPrefix));
            relativePath = replace(relativePath, "\", "/");
        end

        function hex = sha256(pathValue)
            fid = fopen(char(pathValue), 'rb');
            if fid < 0
                error('BNV:Core:InputOpenFailed', 'Cannot open legacy input: %s', pathValue);
            end
            cleanup = onCleanup(@() fclose(fid));
            digest = java.security.MessageDigest.getInstance('SHA-256');
            while true
                bytes = fread(fid, 1024 * 1024, '*uint8');
                if isempty(bytes)
                    break;
                end
                digest.update(typecast(bytes, 'int8'));
            end
            raw = typecast(int8(digest.digest()), 'uint8');
            hex = string(lower(reshape(dec2hex(raw, 2).', 1, [])));
        end
    end
end
