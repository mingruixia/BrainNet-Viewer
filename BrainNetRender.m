function record = BrainNetRender(scenePath, outputPath, varargin)
%BRAINNETRENDER Render Scene JSON and export an image without opening the App.
% Example: BrainNetRender("scene.json", "figure.png", ComputeBackend="cpu")
projectRoot = string(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'src', 'matlab', 'BrainNetViewer'));
record = brainnet.render.renderSceneFile(scenePath, outputPath, varargin{:});
end
