function BrainNet_Gen_NodeMap(node_value,atlas_file,map_file)
% BrainNet Viewer, a graph-based brain network mapping tool, by Mingrui Xia
% Function to map node values to voxel-based template
%-----------------------------------------------------------
%	Copyright(c) 2025
%	State Key Laboratory of Cognitive Neuroscience and Learning, Beijing Normal University
%	Written by Mingrui Xia
%	Mail to Author:  <a href="mingruixia@gmail.com">Mingrui Xia</a>
%   Version 1.52;
%   Date 20250223;
%   Last edited 20250223
%-----------------------------------------------------------
%
% Usage:
% BrainNet_Gen_NodeMap(node_value,atlas_file,map_file);
% node_value is the vector of node values.
% atlas_file is the filename of the atlas nifti file.
% map_file is the nifti filename wanted to be saved.
%
% Example:
%
% Assign node values to AAL.nii template:
% BrainNet_Gen_NodeMap(node_value,'aal.nii','node_value_aal.nii');


[BrainNetPath] = fileparts(which('BrainNet.m'));
BrainNet_SPMPath = fullfile(BrainNetPath, 'BrainNet_spm8_files');
if exist('spm.m','file')
    hdr=spm_vol(atlas_file);
    vol=spm_read_vols(hdr);
else
    addpath(BrainNet_SPMPath);
    hdr=BrainNet_spm_vol(atlas_file);
    vol=BrainNet_spm_read_vols(hdr);
    rmpath(BrainNet_SPMPath);
end

index = unique(vol);
index(index == 0) = [];

if length(node_value)~=length(index)
    disp('length of node values does not match the atlas');
else
    vol_new=zeros(size(vol));
    for i = 1:length(node_value)
        vol_new(vol==index(i))=node_value(i);
    end
end

hdr_new = hdr;
hdr_new.fname = map_file;
hdr_new.dt(1) = 64;
spm_write_vol(hdr_new,vol_new);

