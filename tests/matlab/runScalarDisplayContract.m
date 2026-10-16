function runScalarDisplayContract(sourceRoot, evidencePath)
% SPDX-License-Identifier: GPL-3.0-or-later
% Small numerical contract; not GUI or manual acceptance.
addpath(fullfile(sourceRoot, 'src', 'matlab', 'BrainNetViewer'));
values = [-.0078; 0; .005; .0078; NaN; Inf];
map = parula(256); base = [.9 .9 .9];
[rgb, legend] = brainnet.render.internal.surfaceMapColors(values, map, [-1 1], base);
assert(isequal(legend, map));
assert(isequal(rgb([2 5 6],:), repmat(base,3,1)));
indices = min(256,max(1,floor(256*(values([1 3 4])+1)/2)+1));
assert(isequal(rgb([1 3 4],:), map(indices,:)));
result = struct('release',version('-release'),'passed',true, ...
    'evidence','MATLAB numerical color contract; no GUI');
fid=fopen(evidencePath,'w','n','UTF-8'); assert(fid>0);
fprintf(fid,'%s',jsonencode(result)); fclose(fid);
disp('Scalar display contract passed.');
end
