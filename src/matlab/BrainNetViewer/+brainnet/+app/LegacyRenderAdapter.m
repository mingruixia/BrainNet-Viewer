classdef LegacyRenderAdapter < handle
    %LEGACYRENDERADAPTER Isolate explicit scenes from the legacy renderer.

    properties (SetAccess = private)
        RootPath (1, 1) string
        LastConsole (1, 1) string = ""
        LastWarning struct = struct('identifier', '', 'message', '')
        ActiveFigure = []
    end

    methods
        function obj = LegacyRenderAdapter(rootPath)
            arguments
                rootPath (1, 1) string
            end
            if ~isfolder(rootPath)
                error('BNV:App:InvalidRoot', 'BrainNet root does not exist: %s', rootPath);
            end
            obj.RootPath = string(char(java.io.File(char(rootPath)).getCanonicalPath()));
        end

        function argumentsOut = argumentsFor(obj, scene)
            arguments
                obj (1, 1) brainnet.app.LegacyRenderAdapter
                scene (1, 1) brainnet.core.Scene
            end
            scene.validate();
            brainnet.core.VolumeThresholdPolicy.requireSupported(scene.Options.section('volume'));
            if string(scene.Options.section('volume').threshold_mode)=="p-value"
                error('BNV:Volume:LegacyRendererMismatch', ...
                    'P Value thresholding requires Modern Batch Renderer.');
            end
            brainnet.core.DoubleBrain.requireScene(scene.Options,scene);
            if string(scene.Options.section('surface').color_mode)=="vertex-rgb"
                error('BNV:VertexColors:LegacyRendererMismatch','Geometry-bound vertex RGB requires Modern Batch Renderer. EC color tables can still be exported.');
            end
            if string(scene.Options.section('roi').color_mode)=="custom"
                error('BNV:ROI:LegacyRendererMismatch','ID-bound ROI colors require Modern Batch Renderer.');
            end
            if any(string(scene.Options.section('edge').selection_mode)==["sparsity","legacy-sparsity"])
                error('BNV:EdgeSelection:LegacyRendererMismatch','Sparsity modes require Modern Batch Renderer. For EC export, resolve Legacy Threshold using the exact edge matrix.');
            end
            if string(scene.Options.section('edge').color_mode)=="custom"
                error('BNV:EdgeCustom:LegacyRendererMismatch','Bound custom edge colors require Modern Batch Renderer.');
            end
            if string(scene.Options.section('edge').color_mode)=="node-module"
                error('BNV:EdgeModule:LegacyRendererMismatch','Module-edge colors require Modern Batch Renderer to avoid legacy module-21 sentinel collisions.');
            end
            edge=scene.Options.section('edge');
            changedLength=isfield(edge,'arrow_length_scale') && edge.arrow_length_scale~=1;
            changedWidth=isfield(edge,'arrow_width_scale') && edge.arrow_width_scale~=1;
            if edge.directed && (changedLength || changedWidth)
                error('BNV:EdgeArrow:LegacyRendererMismatch', ...
                    'Adjustable arrowhead proportions require Modern Batch Renderer.');
            end
            boundary=scene.Options.section("surface");
            if any(string(boundary.boundary_mode)==["automatic","custom"])
                error('BNV:Boundary:LegacyRendererMismatch', ...
                    'Modern Automatic and geometry-bound custom masks require Modern Batch Renderer.');
            end
            if brainnet.core.Colormap.hasCustom(scene.Options.Settings)
                error('BNV:Color:LegacyUnsupported','Embedded custom RGB maps require Modern Batch Renderer.');
            end
            roleOrder = ["surface", "node", "edge", "surface_map", "volume"];
            argumentsOut = {};
            for role = roleOrder
                matches = cellfun(@(item) item.Role == role, scene.Inputs);
                if nnz(matches) == 0
                    continue;
                end
                input = scene.Inputs{find(matches, 1)};
                obj.validateLegacyExtension(input);
                pathValue = brainnet.io.internal.resolveAndVerify(input, obj.RootPath, role);
                argumentsOut{end + 1} = char(pathValue); %#ok<AGROW>
            end
        end

        function figureHandle = render(obj, scene, options)
            arguments
                obj (1, 1) brainnet.app.LegacyRenderAdapter
                scene (1, 1) brainnet.core.Scene
                options.Visible (1, 1) logical = true
            end
            % A modern-only release must not silently use a different legacy
            % installation found elsewhere on the MATLAB search path.
            if ~isfile(fullfile(obj.RootPath, 'BrainNet.m')) || ...
                    ~isfile(fullfile(obj.RootPath, 'BrainNet_MapCfg.m'))
                error('BNV:App:LegacyRendererNotPackaged', ...
                    ['This package does not include the legacy renderer. ' ...
                     'Use Modern Batch Renderer.']);
            end
            resolvedMain = string(which('BrainNet'));
            resolvedMapCfg = string(which('BrainNet_MapCfg'));
            if strlength(resolvedMain)==0 || strlength(resolvedMapCfg)==0 || ...
                    ~strcmpi(string(char(java.io.File(char(resolvedMain)).getCanonicalPath())), ...
                        fullfile(obj.RootPath, 'BrainNet.m')) || ...
                    ~strcmpi(string(char(java.io.File(char(resolvedMapCfg)).getCanonicalPath())), ...
                        fullfile(obj.RootPath, 'BrainNet_MapCfg.m'))
                error('BNV:App:LegacyRendererWrongRoot', ...
                    'Legacy renderer functions must resolve from the configured application root.');
            end
            brainnet.core.OrientationLabels.requireLegacyCompatible(scene);
            if exist('BrainNet_MapCfg', 'file') ~= 2 || exist('BrainNet', 'file') ~= 2
                error('BNV:App:LegacyRendererNotFound', ...
                    'BrainNet and BrainNet_MapCfg must resolve from the configured root.');
            end
            obj.closeActiveFigure();
            clearLegacyState();
            inputArguments = obj.argumentsFor(scene);
            temporaryFolder = string(tempname);
            mkdir(temporaryFolder);
            folderCleanup = onCleanup(@() removeTemporaryFolder(temporaryFolder));
            configurationPath = fullfile(temporaryFolder, 'scene-config.mat');

            oldVisibility = get(groot, 'DefaultFigureVisible');
            set(groot, 'DefaultFigureVisible', 'off');
            visibilityCleanup = onCleanup(@() set(groot, 'DefaultFigureVisible', oldVisibility));
            obj.writeLegacyConfiguration(configurationPath, scene);
            inputArguments{end + 1} = char(configurationPath); %#ok<NASGU>

            lastwarn('');
            figureHandle = [];
            obj.LastConsole = string(evalc('figureHandle = BrainNet_MapCfg(inputArguments{:});'));
            [warningMessage, warningIdentifier] = lastwarn;
            obj.LastWarning = struct('identifier', warningIdentifier, 'message', warningMessage);
            if ~isgraphics(figureHandle, 'figure')
                error('BNV:App:LegacyRenderFailed', 'Legacy renderer did not return a figure.');
            end
            if options.Visible
                set(figureHandle, 'Position', ...
                    brainnet.render.internal.screenAwarePosition( ...
                        [1600 1200], AdaptiveScale=true, ...
                        MonitorFraction=[0.86 0.86], MaximumScale=1.25, ...
                        MinimumSize=[800 600]));
                set(figureHandle, 'Visible', 'on');
                drawnow;
            else
                set(figureHandle, 'Visible', 'off');
            end
            obj.ActiveFigure = figureHandle;
        end

        function closeActiveFigure(obj)
            if ~isempty(obj.ActiveFigure) && isgraphics(obj.ActiveFigure)
                close(obj.ActiveFigure);
            end
            obj.ActiveFigure = [];
        end

        function delete(obj)
            obj.closeActiveFigure();
        end
    end

    methods (Access = private)
        function validateLegacyExtension(~, input)
            path = lower(input.RelativePath);
            switch input.Role
                case "surface"
                    valid = endsWith(path, ".nv");
                case "node"
                    valid = endsWith(path, ".node");
                case "edge"
                    valid = endsWith(path, ".edge");
                case "surface_map"
                    valid = endsWith(path, ".txt");
                case "volume"
                    valid = endsWith(path, ".nii") || endsWith(path, ".img") || ...
                        endsWith(path, ".nii.gz") || endsWith(path, ".img.gz");
                otherwise
                    valid = false;
            end
            if ~valid
                error('BNV:App:LegacyFormatUnsupported', ...
                    'The legacy renderer cannot consume %s input %s. Loading remains available in the new I/O layer.', ...
                    input.Role, input.RelativePath);
            end
        end

        function writeLegacyConfiguration(~, pathValue, scene)
            global EC %#ok<GVMIS>
            configurationHandle = BrainNet;
            configurationCleanup = onCleanup(@() closeIfGraphics(configurationHandle));
            options = scene.Options;
            [mappedConfiguration, ~] = options.Settings.toLegacy();
            EC = mergeLegacyConfiguration(EC, mappedConfiguration);
            if EC.vol.display == 0 && scene.MapMode > 0, EC.vol.display = 1; end
            if scene.MapMode > 0
                EC.vol.pn = 0;
                EC.vol.nn = 0;
            end
            if ~isempty(options.PositiveMaximum)
                EC.vol.px = options.PositiveMaximum;
            end
            if ~isempty(options.NegativeMinimum)
                EC.vol.nx = options.NegativeMinimum;
            end
            save(pathValue, 'EC');
        end
    end
end


function target = mergeLegacyConfiguration(target, source)
fields = fieldnames(source);
for index = 1:numel(fields)
    name = fields{index};
    if isfield(target, name) && isstruct(target.(name)) && isstruct(source.(name))
        target.(name) = mergeLegacyConfiguration(target.(name), source.(name));
    else
        target.(name) = source.(name);
    end
end
end


function closeIfGraphics(value)
if isgraphics(value)
    close(value);
end
end


function removeTemporaryFolder(folder)
if strlength(folder) > 0 && isfolder(folder)
    rmdir(folder, 's');
end
end


function clearLegacyState
clear global FLAG surf EC a File
end
