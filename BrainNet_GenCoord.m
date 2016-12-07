function BrainNet_GenCoord(filename,outputfilename, regions)
% BrainNet Viewer, a graph-based brain network mapping tool, by Mingrui Xia
% Function to generate node file from voxel-based template
%-----------------------------------------------------------
%	Copyright(c) 2015
%	State Key Laboratory of Cognitive Neuroscience and Learning, Beijing Normal University
%	Written by Mingrui Xia
%	Mail to Author:  <a href="mingruixia@gmail.com">Mingrui Xia</a>
%   Version 1.52;
%   Date 20150306;
%   Last edited 20150306
%-----------------------------------------------------------
%
% Usage:
% BrainNet_GenCoord(filename,outputfilename);
% filenames is the name of the voxel-based template file.
% outputfilename is the name of the output node file.
% regions is the wanted index in the template.
%
% Example:
%
% Generate node file from AAL.nii template:
% BrainNet_GenCoord('aal.nii','aal.node');
%
% Generate node file from AAL.nii template only with regions 1~10
% BrainNet_GenCoord('aal.nii','aal1-10.node',[1:10]);

[BrainNetPath] = fileparts(which('BrainNet.m'));
BrainNet_SPMPath = fullfile(BrainNetPath, 'BrainNet_spm8_files');
if exist('spm.m','file')
    hdr=spm_vol(filename);
    vol=spm_read_vols(hdr);
else
    addpath(BrainNet_SPMPath);
    hdr=BrainNet_spm_vol(filename);
    vol=BrainNet_spm_read_vols(hdr);
    rmpath(BrainNet_SPMPath);
end

if nargin < 3
    index = unique(vol);
    index(index == 0) = [];
else    
    index = regions;    
end

coord = zeros(length(index),6);
for i = 1:length(index)
    ind = find(vol == index(i));
    [x y z] = ind2sub(hdr.dim,ind);
    coord_matrix = [mean(x),mean(y),mean(z)];
    coord_real = hdr.mat*[coord_matrix,1]';
    coord(i,1:3) = coord_real(1:3);
    coord(i,6) = index(i);
end


fid = fopen(outputfilename,'wt');
for i=1:length(index)
    fprintf(fid,'%f %f %f %f %f %d\n',coord(i,:));
end
fclose(fid);
