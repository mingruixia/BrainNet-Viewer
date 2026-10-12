function runReviewNodeComments(sourceRoot, evidencePath)
% SPDX-License-Identifier: GPL-3.0-or-later
% Focused actual MATLAB reader check, not GUI acceptance.
addpath(fullfile(sourceRoot, 'src', 'matlab', 'BrainNetViewer'));
folder = string(tempname); mkdir(folder);
cleanup = onCleanup(@() rmdir(folder, 's'));
path = fullfile(folder, 'comments.node');
fid = fopen(path, 'w', 'n', 'UTF-8');
assert(fid > 0);
fprintf(fid, '# full comment\n0 0 0 1 2 Network#1_PFC # comment\n1 2 3 2 1 Middle region\n');
fclose(fid);
reference = brainnet.core.InputReference("node", "comments.node");
nodes = brainnet.io.readNodes(reference, folder);
assert(isequal(nodes.Labels, ["Network#1_PFC"; "Middle region"]));
assert(isequal(nodes.Coordinates, [0 0 0; 1 2 3]));
result = struct('release', version('-release'), 'labels', nodes.Labels, ...
    'coordinates_unchanged', true, 'evidence', 'Actual MATLAB reader, synthetic input; no GUI');
fid = fopen(evidencePath, 'w', 'n', 'UTF-8'); assert(fid > 0);
fprintf(fid, '%s', jsonencode(result)); fclose(fid);
disp('MATLAB node comment associated check passed.');
end
