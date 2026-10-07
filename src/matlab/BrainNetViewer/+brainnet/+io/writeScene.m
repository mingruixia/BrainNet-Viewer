function saved = writeScene(scene, destination, dataRoot, options)
%WRITESCENE Save UTF-8 Scene JSON, verifying and sealing input hashes.
% Input paths remain relative to dataRoot, not to the JSON file location.
arguments
    scene (1, 1) brainnet.core.Scene
    destination (1, 1) string
    dataRoot (1, 1) string
    options.Overwrite (1, 1) logical = false
end
scene = brainnet.core.SessionState.normalizeScene(scene);
value = scene.toStruct();
for index = 1:numel(scene.Inputs)
    reference = scene.Inputs{index};
    path = brainnet.io.internal.resolveAndVerify(reference, dataRoot, reference.Role);
    value.inputs.(reference.Role).sha256 = char(brainnet.io.internal.sha256File(path));
end
saved = brainnet.core.Scene.fromStruct(value);
brainnet.io.internal.writeJsonFile(destination, saved.toStruct(), ...
    Overwrite=options.Overwrite);
end
