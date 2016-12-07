function BrainNet_GenSurface(filename,outputfilename,threshold)
% BrainNet Viewer, a graph-based brain network mapping tool, by Mingrui Xia
% Function to generate surface file from Nifti mask
%-----------------------------------------------------------
%	Copyright(c) 2015
%	State Key Laboratory of Cognitive Neuroscience and Learning, Beijing Normal University
%	Written by Mingrui Xia
%	Mail to Author:  <a href="mingruixia@gmail.com">Mingrui Xia</a>
%   Version 1.53;
%   Date 20151028;
%   Last edited 20151028
%-----------------------------------------------------------
%
% Usage:
% BrainNet_GenSurface(filename,outputfilename);
% filenames is the name of the Nifti mask file.
% outputfilename is the name of the output surface file, which should be ended with '.nv'.
% threshold is used to binarize the image. If the input image is a binary image, this parameter can be ignored.
%
% Example:
%
% Threshold the spm gray template with 0.2 and generate the surface
% BrainNet_GenSurface('grey.nii','grey.nv',0.2);
%


[BrainNetPath] = fileparts(which('BrainNet.m')); 
BrainNet_SPMPath = fullfile(BrainNetPath, 'BrainNet_spm8_files');
if exist('spm.m','file') 
    surf_hdr = spm_vol(filename); 
    surf_vol = spm_read_vols(surf_hdr);
else
    addpath(BrainNet_SPMPath);
    surf_hdr = BrainNet_spm_vol(filename); 
    surf_vol = BrainNet_spm_read_vols(surf_hdr);
    rmpath(BrainNet_SPMPath);
end

if nargin > 2
    surf_vol(surf_vol<threshold) = 0;
    surf_vol(surf_vol>=threshold) = 1;
end
vol = smooth3(surf_vol);
fv = isosurface(vol);
coord = fv.vertices(:,1);
fv.vertices(:,1) = fv.vertices(:,2);
fv.vertices(:,2) = coord;
fv.vertices = fv.vertices';
fv.vertices(4,:) = 1;
fv.vertices = surf_hdr.mat * fv.vertices;
fv.vertices(4,:) = [];

vertex_num = size(fv.vertices,2);
ntri = size(fv.faces,1);

fid = fopen(outputfilename,'wt');
fprintf(fid,'%d\n',vertex_num);
for i=1:vertex_num
    fprintf(fid,'%f %f %f\n',fv.vertices(1:3,i));
end
fprintf(fid, '%d\n', ntri);
for i=1:ntri
    fprintf(fid,'%d %d %d\n',fv.faces(i,1:3));
end
fclose(fid);

