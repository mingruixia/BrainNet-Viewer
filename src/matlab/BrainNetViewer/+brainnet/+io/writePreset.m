function writePreset(preset, path, options)
%WRITEPRESET Write a versioned, settings-only JSON with overwrite protection.
arguments
    preset (1,1) brainnet.core.VisualizationPreset
    path (1,1) string
    options.Overwrite (1,1) logical = false
end
brainnet.io.internal.writeJsonFile(path, preset.toStruct(), Overwrite=options.Overwrite);
end
