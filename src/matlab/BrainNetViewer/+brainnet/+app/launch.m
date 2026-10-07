function app = launch(rootPath, options)
%LAUNCH Start the BrainNet Viewer 2.0 MATLAB desktop shell.

arguments
    rootPath (1, 1) string = string(fileparts(fileparts(fileparts(mfilename('fullpath')))))
    options.Visible (1, 1) logical = true
    options.Scene brainnet.core.Scene = brainnet.core.Scene.empty
end

app = brainnet.app.BrainNetApp(rootPath, Visible=options.Visible);
if ~isempty(options.Scene)
    app.setScene(options.Scene);
end
end
