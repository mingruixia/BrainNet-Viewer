function varargout = BrainNetViewer(varargin)
%BRAINNETVIEWER Launch the BrainNet Viewer MATLAB desktop app.

sourceRoot = string(fileparts(mfilename('fullpath')));
app = brainnet.app.launch(sourceRoot, varargin{:});
if nargout > 0
    varargout{1} = app;
end
end
