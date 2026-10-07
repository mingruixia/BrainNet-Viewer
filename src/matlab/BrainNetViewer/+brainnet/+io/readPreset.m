function preset = readPreset(path)
%READPRESET Read and validate a UTF-8 visualization preset, never a Scene.
arguments
    path (1,1) string
end
file = fopen(path, 'r', 'n', 'UTF-8');
if file < 0
    error('BNV:IO:PresetOpenFailed', 'Cannot open visualization preset: %s', path);
end
cleanup = onCleanup(@() fclose(file));
value = jsondecode(fscanf(file, '%c'));
preset = brainnet.core.VisualizationPreset.fromStruct(value);
end
