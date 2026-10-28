function scene = readScene(path)
%READSCENE Read a UTF-8 Scene JSON without changing the working directory.
arguments
    path (1, 1) string
end
if endsWith(lower(path),".zip")
    scene=brainnet.io.readPortableScene(path);return;
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
if isfield(scene.Metadata,'input_base')
    if ~strcmp(scene.Metadata.input_base,'scene-directory')
        error('BNV:IO:SceneInputBase','Unsupported Scene input base.');
    end
    state=brainnet.core.SessionState.fromScene(scene);
    restore=~isempty(state)&&strcmp(state.scene_signature,brainnet.core.SessionState.signature(scene));
    value=scene.toStruct();folder=string(char(java.io.File(char(fileparts(path))).getCanonicalPath()));
    roles=fieldnames(value.inputs);
    for k=1:numel(roles)
        item=value.inputs.(roles{k});
        if isfield(item,'local_path')&&strlength(string(item.local_path))>0
            error('BNV:IO:PortableLocalPath','A portable Scene cannot contain local paths.');
        end
        item.local_path=char(brainnet.io.internal.sceneRelativeFile(folder,string(item.relative_path)));
        ref=brainnet.core.InputReference.fromStruct(item);
        brainnet.io.internal.resolveAndVerify(ref,folder,ref.Role);
        value.inputs.(roles{k})=item;
    end
    if isfield(value.metadata,'packaged_files')
        for item=reshape(value.metadata.packaged_files,1,[])
            filePath=brainnet.io.internal.sceneRelativeFile(folder,string(item.relative_path));
            ref=brainnet.core.InputReference('surface',string(item.relative_path), ...
                LocalPath=filePath,Sha256=string(item.sha256));
            brainnet.io.internal.resolveAndVerify(ref,folder,'surface');
        end
    end
    value.metadata=rmfield(value.metadata,'input_base');
    scene=brainnet.core.Scene.fromStruct(value);
    if restore,scene=brainnet.core.SessionState.attach(scene,state.camera,state.export);end
end
end
