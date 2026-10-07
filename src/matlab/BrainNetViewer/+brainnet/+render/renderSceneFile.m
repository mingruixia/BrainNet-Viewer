function record = renderSceneFile(scenePath, outputPath, options)
%RENDERSCENEFILE Render Scene JSON and export without opening the desktop App.
% DataRoot defaults to the installed BrainNetViewer folder. Scene references
% are relative to DataRoot, independent of the JSON file location.
arguments
    scenePath (1, 1) string
    outputPath (1, 1) string
    options.DataRoot (1, 1) string = string(fileparts(fileparts(fileparts(mfilename('fullpath')))))
    options.ComputeBackend (1, 1) string {mustBeMember(options.ComputeBackend,["auto","cpu","gpu"])} = "auto"
    options.PerformanceMode (1, 1) string {mustBeMember(options.PerformanceMode,["auto","quality","interactive"])} = "quality"
    options.LegacyConfig (1, 1) string = ""
    options.Width double = []
    options.Height double = []
    options.Resolution double = []
    options.Units (1, 1) string = ""
    options.BackgroundColor (1, 1) string = ""
    options.ContentType (1, 1) string = ""
    options.Overwrite (1, 1) logical = false
    options.Planner (1, 1) brainnet.render.RenderPlanner = brainnet.render.RenderPlanner()
end
scene = brainnet.io.readScene(scenePath);
if strlength(options.LegacyConfig) > 0
    scene = brainnet.io.importLegacyConfig(options.LegacyConfig, ...
        options.DataRoot, Scene=scene);
end
brainnet.core.VolumeThresholdPolicy.requireSupported(scene.Options.section('volume'));
state = brainnet.core.SessionState.fromScene(scene);
session = brainnet.app.SceneSession(options.DataRoot);
data = session.loadScene(scene);
% Seal previously unhashed input references before constructing cache keys.
value = scene.toStruct();
for index = 1:numel(scene.Inputs)
    input = scene.Inputs{index};
    if strlength(input.Sha256) == 0
        value.inputs.(input.Role).sha256 = char( ...
            brainnet.io.internal.sha256File(input.resolve(options.DataRoot)));
    end
end
scene = brainnet.core.Scene.fromStruct(value);
[prepared, preparation] = options.Planner.prepare(scene, data, ...
    ComputeBackend=options.ComputeBackend);
renderer = brainnet.render.MatlabBatchRenderer;
cleanup = onCleanup(@() delete(renderer));
[figure, metrics] = renderer.render(prepared, scene.Options, Visible=false, ...
    PerformanceMode=options.PerformanceMode, ComputeBackend=options.ComputeBackend);
metrics.preparation = preparation;
metrics.camera_restore = 'not-saved';
if ~isempty(state) && strcmp(state.scene_signature, brainnet.core.SessionState.signature(scene))
    metrics.camera_restore = renderer.restoreCamera(state.camera, AllowLayout2Fallback=true);
elseif ~isempty(state) && ~isempty(state.camera)
    metrics.camera_restore = 'ignored-incompatible-scene';
end
metrics.camera_state = renderer.captureCamera();
imageSettings = scene.Options.section("image");
preference = struct('width',imageSettings.width,'height',imageSettings.height, ...
    'resolution_dpi',imageSettings.dpi,'units','pixels', ...
    'background_color','current','content_type','auto','format','');
if ~isempty(state), preference = state.export; end
if isempty(options.Width) && isempty(options.Height)
    options.Width = preference.width;
    options.Height = preference.height;
    if options.Units == "", options.Units = string(preference.units); end
end
if options.Units == "", options.Units = "pixels"; end
if isempty(options.Resolution), options.Resolution = preference.resolution_dpi; end
if options.BackgroundColor == "", options.BackgroundColor = string(preference.background_color); end
[folder, name, extension] = fileparts(outputPath);
if options.ContentType == ""
    options.ContentType = "auto";
    if strcmpi(extension, "." + string(preference.format))
        options.ContentType = string(preference.content_type);
    end
end
if folder == "", folder = string(pwd); end
exporter = brainnet.export.FigureExporter(folder);
record = exporter.exportFigure(figure, name + extension, scene, prepared, metrics, ...
    Width=options.Width, Height=options.Height, Resolution=options.Resolution, ...
    Units=options.Units, BackgroundColor=options.BackgroundColor, ...
    ContentType=options.ContentType, Overwrite=options.Overwrite);
end
