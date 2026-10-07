function varargout = BrainNetViewer(varargin)
%BRAINNETVIEWER Launch the BrainNet Viewer MATLAB desktop app.

projectRoot = string(fileparts(mfilename('fullpath')));
sourceRoot = fullfile(projectRoot, "src", "matlab", "BrainNetViewer");
addpath(sourceRoot);
app = brainnet.app.launch(sourceRoot, varargin{:});
if nargout > 0
    varargout{1} = app;
end
end
