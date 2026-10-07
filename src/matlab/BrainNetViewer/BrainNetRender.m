function record = BrainNetRender(scenePath, outputPath, varargin)
%BRAINNETRENDER Render Scene JSON and export an image without opening the App.
record = brainnet.render.renderSceneFile(scenePath, outputPath, varargin{:});
end
