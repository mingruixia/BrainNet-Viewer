function runDisplayProvenance(sourceRoot, outputRoot)
% SPDX-License-Identifier: GPL-3.0-or-later
% Actual PNG and metadata contract, without GUI or scientific-image acceptance.
addpath(fullfile(sourceRoot, 'src', 'matlab', 'BrainNetViewer'));
scene = brainnet.core.Scene("metadata-test", "Metadata test", 0, 0, {});
prepared = brainnet.render.PreparedScene(scene, "fixture", struct(), struct(), "metadata-test");
window = figure('Visible','off', 'Position',[10 10 320 240]);
cleanup = onCleanup(@() delete(window)); %#ok<NASGU>
plot(axes(window), [0 1], [0 1]);
exporter = brainnet.export.FigureExporter(outputRoot);
record = exporter.exportFigure(window, "metadata.png", scene, prepared, struct(), ...
    Width=320, Height=240, Resolution=100);
saved = jsondecode(fileread(fullfile(outputRoot, 'metadata.png.provenance.json')));
assert(strcmp(record.display_rules.surface_scalar_null_color_rule, 'exact-zero-or-nonfinite'));
assert(isequal(saved.display_rules, record.display_rules));
assert(strcmp(saved.display_rules.surface_scalar_legend, 'continuous-colormap'));
assert(strcmp(saved.schema_version, '1.0'));
result = struct('passed',true, 'release',version('-release'), ...
    'evidence','Actual hidden figure PNG and metadata readback; no GUI/Mac acceptance');
fid = fopen(fullfile(outputRoot,'result.json'),'w','n','UTF-8'); assert(fid>0);
fprintf(fid,'%s',jsonencode(result)); fclose(fid);
disp('Display provenance contract passed.');
end
