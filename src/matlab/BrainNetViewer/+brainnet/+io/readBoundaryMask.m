function mask=readBoundaryMask(path)
%READBOUNDARYMASK Strict 0/1 whitespace text with # comments; never evaluate.
arguments
    path (1,1) string
end
info=dir(path);
if isempty(info)||info.isdir||info.bytes>64000000
    error('BNV:Boundary:MaskFile','Select an existing mask text file no larger than 64 MB.');
end
text=regexprep(fileread(path),'#[^\r\n]*','');
tokens=regexp(strtrim(text),'\s+','split');
if isempty(strtrim(text)) || any(~ismember(tokens,{'0','1'}))
    error('BNV:Boundary:InvalidMaskText','Mask text must contain only 0/1 values, whitespace and # comments.');
end
mask=brainnet.core.BoundaryMask.validate(str2double(tokens));
end
