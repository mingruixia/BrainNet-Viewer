function threshold = legacySparsityThreshold(matrix, fraction, valueMode)
%LEGACYSPARSITYTHRESHOLD Reproduce the old sparsity-to-threshold UI conversion.
arguments
    matrix double
    fraction (1,1) double
    valueMode (1,1) string
end
if isempty(matrix) || ~ismatrix(matrix) || size(matrix,1)~=size(matrix,2) || ~isreal(matrix) || any(~isfinite(matrix(:)))
    error('BNV:EdgeSelection:SparsityMatrix','Legacy sparsity requires a finite real nonempty square edge matrix.');
end
if ~isreal(fraction) || ~isfinite(fraction) || fraction<0 || fraction>1 || ~any(valueMode==["signed","absolute"])
    error('BNV:EdgeSelection:SparsitySettings','Sparsity requires a fraction in [0,1] and Signed or Absolute values.');
end
measure=matrix(:); if valueMode=="absolute", measure=abs(measure); end
ordered=sort(measure,'descend');
% MATLAB int32 rounds, it does not truncate. Legacy includes zeros and diagonal.
index=max(1,min(numel(ordered),double(int32(fraction*numel(ordered)))));
% The old edit box persisted six decimal places before GetValue read it.
threshold=str2double(sprintf('%.6f',ordered(index)));
end
