function scene = readScene(path)
%READSCENE Read a UTF-8 Scene JSON without changing the working directory.
arguments
    path (1, 1) string
end
file = fopen(path, 'r', 'n', 'UTF-8');
if file < 0
    error('BNV:IO:SceneOpenFailed', 'Cannot open Scene JSON: %s', path);
end
cleanup = onCleanup(@() fclose(file));
text = fscanf(file, '%c');
try
    document = jsondecode(text);
catch exception
    throwAsCaller(MException('BNV:IO:InvalidSceneJson', ...
        'The selected file is not valid JSON: %s', exception.message));
end
if ~isstruct(document) || ~isscalar(document)
    error('BNV:IO:InvalidSceneDocument', ...
        'Scene JSON must contain one Scene object.');
end
required = {'id','name','loadfile','map_mode','inputs','options'};
missing = required(~isfield(document, required));
if ~isempty(missing)
    if isfield(document, 'scenes')
        error('BNV:IO:SceneCatalogNotSupported', ...
            ['This JSON is a Scene catalog, not one Scene. Open an individual ' ...
             'Scene JSON file (it must contain inputs and options).']);
    end
    error('BNV:IO:InvalidSceneDocument', ...
        'This JSON is not a BrainNet Scene. Missing field(s): %s.', ...
        strjoin(missing, ', '));
end
scene = brainnet.core.Scene.fromStruct(document);
scene = brainnet.core.SessionState.normalizeScene(scene);
end
