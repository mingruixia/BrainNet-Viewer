classdef SceneSession < handle
    %SCENESESSION Testable, GUI-free scene loading and validation state.

    properties (SetAccess = private)
        RootPath (1, 1) string
        Scene = []
        Data struct = struct()
        Status (1, 1) string = "idle"
        Message (1, 1) string = "No scene selected."
        LastError struct = struct('identifier', '', 'message', '')
    end

    methods
        function obj = SceneSession(rootPath)
            arguments
                rootPath (1, 1) string
            end
            if ~isfolder(rootPath)
                error('BNV:App:InvalidRoot', 'BrainNet data root does not exist: %s', rootPath);
            end
            obj.RootPath = string(char(java.io.File(char(rootPath)).getCanonicalPath()));
        end

        function setScene(obj, scene)
            arguments
                obj (1, 1) brainnet.app.SceneSession
                scene (1, 1) brainnet.core.Scene
            end
            scene.validate();
            obj.Scene = scene;
            obj.Data = struct();
            obj.Status = "ready";
            obj.Message = "Scene ready: " + scene.Name;
            obj.LastError = struct('identifier', '', 'message', '');
        end

        function clearScene(obj)
            obj.Scene = [];
            obj.Data = struct();
            obj.Status = "idle";
            obj.Message = "No scene selected.";
            obj.LastError = struct('identifier', '', 'message', '');
        end

        function clearRenderedState(obj,state)
            % Retain data and applied options; only release the rendered status.
            if isempty(obj.Scene), return; end
            state=brainnet.core.SessionState.validate(state);
            obj.Scene=brainnet.core.SessionState.attach(obj.Scene,state.camera,state.export);
            if obj.Status=="rendered"
                obj.Status="loaded";
                obj.Message="Figure cleared. Inputs and settings retained; select Render Scene to restore.";
            end
        end

        function setInspection(obj,settings)
            if isempty(obj.Scene), error('BNV:Query:SceneRequired','Select a Scene before configuring inspection.'); end
            settings=brainnet.query.InspectionSettings.validate(settings);
            value=obj.Scene.toStruct(); value.metadata.inspection=settings;
            obj.Scene=brainnet.core.Scene.fromStruct(value);
        end

        function loaded = loadScene(obj, scene)
            arguments
                obj (1, 1) brainnet.app.SceneSession
                scene brainnet.core.Scene = brainnet.core.Scene.empty
            end
            if ~isempty(scene)
                obj.setScene(scene);
            end
            obj.beginLoading();
            candidate = struct();
            try
                for index = 1:numel(obj.Scene.Inputs)
                    input = obj.Scene.Inputs{index};
                    candidate.(char(input.Role)) = obj.readInput(input);
                end
                obj.validateRelationships(candidate);
                obj.Data = candidate;
                obj.Status = "loaded";
                obj.Message = sprintf('Loaded %d input(s): %s', ...
                    numel(obj.Scene.Inputs), char(obj.Scene.Name));
                loaded = candidate;
            catch exception
                obj.recordError(exception);
                rethrow(exception);
            end
        end

        function value = dataByRole(obj, role)
            arguments
                obj (1, 1) brainnet.app.SceneSession
                role (1, 1) string
            end
            if ~isfield(obj.Data, role)
                error('BNV:App:DataRoleNotLoaded', 'No loaded data exists for role %s.', role);
            end
            value = obj.Data.(role);
        end

        function beginLoading(obj)
            if isempty(obj.Scene)
                error('BNV:App:NoScene', 'Select or create a scene before loading.');
            end
            obj.Status = "loading";
            obj.Message = "Validating and loading scene inputs...";
            obj.LastError = struct('identifier', '', 'message', '');
        end

        function markRendered(obj, backend)
            arguments
                obj (1, 1) brainnet.app.SceneSession
                backend (1, 1) string = "batch"
            end
            if obj.Status ~= "loaded" && obj.Status ~= "rendered"
                error('BNV:App:SceneNotLoaded', 'Load the current scene before rendering.');
            end
            obj.Status = "rendered";
            if backend == "legacy"
                label = "legacy compatibility renderer";
            else
                label = "modern batch renderer";
            end
            obj.Message = "Rendered with " + label + ": " + obj.Scene.Name;
        end

        function recordError(obj, exception)
            arguments
                obj (1, 1) brainnet.app.SceneSession
                exception (1, 1) MException
            end
            obj.Status = "error";
            obj.Message = string(exception.message);
            obj.LastError = struct('identifier', exception.identifier, 'message', exception.message);
        end

        function value = summary(obj)
            value = struct;
            value.status = char(obj.Status);
            value.message = char(obj.Message);
            value.scene_id = '';
            value.scene_name = '';
            value.input_count = 0;
            value.loaded_roles = fieldnames(obj.Data).';
            value.last_error = obj.LastError;
            if ~isempty(obj.Scene)
                value.scene_id = char(obj.Scene.Id);
                value.scene_name = char(obj.Scene.Name);
                value.input_count = numel(obj.Scene.Inputs);
            end
        end
    end

    methods (Access = private)
        function value = readInput(obj, input)
            switch input.Role
                case "surface"
                    path = lower(input.RelativePath);
                    if endsWith(path, ".gii") || endsWith(path, ".gii.gz")
                        value = brainnet.io.readGifti(input, obj.RootPath);
                    elseif endsWith(path, ".nv")
                        value = brainnet.io.readSurface(input, obj.RootPath);
                    elseif endsWith(path, ".pial")
                        value = brainnet.io.readFreeSurferSurface(input, obj.RootPath);
                    elseif endsWith(path, ".mesh")
                        value = brainnet.io.readBrainVisaMesh(input, obj.RootPath);
                    elseif endsWith(path, ".g")
                        value = brainnet.io.readByuSurface(input, obj.RootPath);
                    elseif endsWith(path, ".obj")
                        value = brainnet.io.readMniObjSurface(input, obj.RootPath);
                    elseif any(endsWith(path, [".mz3", ".mz3.gz"]))
                        value = brainnet.io.readMz3Surface(input, obj.RootPath);
                    else
                        error('BNV:App:UnsupportedSurfaceFormat', ...
                            'Surface files must use .nv, .pial, .mesh, .g, .obj (MNI/BIC), .mz3, .mz3.gz, .gii, or .gii.gz.');
                    end
                case "node"
                    value = brainnet.io.readNodes(input, obj.RootPath);
                case "edge"
                    value = brainnet.io.readEdges(input, obj.RootPath);
                case "surface_map"
                    value = brainnet.io.readSurfaceMap(input, obj.RootPath);
                case "volume"
                    value = brainnet.io.readNifti(input, obj.RootPath);
                otherwise
                    error('BNV:App:UnsupportedInputRole', 'Unsupported scene input role: %s', input.Role);
            end
        end

        function validateRelationships(~, candidate)
            if isfield(candidate, 'node') && isfield(candidate, 'edge') && ...
                    candidate.node.Count ~= candidate.edge.Dimension
                error('BNV:App:NodeEdgeDimensionMismatch', ...
                    'Node count %d does not match edge dimension %d.', ...
                    candidate.node.Count, candidate.edge.Dimension);
            end
            if isfield(candidate, 'surface') && isfield(candidate, 'surface_map') && ...
                    candidate.surface.VertexCount ~= numel(candidate.surface_map)
                error('BNV:App:SurfaceMapDimensionMismatch', ...
                    'Surface vertex count %d does not match map length %d.', ...
                    candidate.surface.VertexCount, numel(candidate.surface_map));
            end
        end
    end
end
