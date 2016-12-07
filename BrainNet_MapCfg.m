function H_BrainNet = BrainNet_MapCfg(varargin)
% BrainNet Viewer, a graph-based brain network mapping tool, by Mingrui Xia
% Function to draw graph from commandline
%-----------------------------------------------------------
%	Copyright(c) 2013
%	State Key Laboratory of Cognitive Neuroscience and Learning, Beijing Normal University
%	Written by Mingrui Xia
%	Mail to Author:  <a href="mingruixia@gmail.com">Mingrui Xia</a>
%   Version 1.52;
%   Date 20121031;
%   Last edited 20150414
%-----------------------------------------------------------
%
% Usage:
% H_BrainNet = BrainNet_MapCfg(Filenames); Filenames can be any kinds of
% files supported by BrainNet Viewer.
%
% Example:
%
% Surface file only:
% BrainNet_MapCfg('BrainMesh_ICBM152.nv');
%
% Surface and node files:
% BrainNet_MapCfg('BrainMesh_ICBM152.nv','Node_AAL90.node');
%
% Surface, node and edge files:
% BrainNet_MapCfg('BrainMesh_ICBM152.nv','Node_AAL90.node','Edge_AAL90_Binary.edge');
%
% Surface, node, edge and pre-saved option files:
% BrainNet_MapCfg('BrainMesh_ICBM152.nv','Node_AAL90.node','Edge_AAL90_Binary.edge','Cfg.mat');
%
% Surface, volume and pre-saved option files:
% BrainNet_MapCfg('BrainMesh_ICBM152_smoothed.nv','OneSample_T.nii','Cfg.mat');
%
% Surface file only and save to image file (jpe, tif, bmp, png, and eps are supported)
% BrainNet_MapCfg('BrainMesh_ICBM152.nv','Surf.jpg');
%
% If the pre-saved option file is not input, BNV draw graphs in default
% settings.



% Initialize input file names
SurfFileName = '';
NodeFileName = '';
EdgeFileName = '';
VolFileName = '';
CfgFileName = '';
PicFileName = '';

for i = 1:nargin
    [path, fname, ext] = fileparts(varargin{i});
    switch ext
        case '.nv'
            SurfFileName = varargin{i};
        case '.node'
            NodeFileName = varargin{i};
        case '.edge'
            EdgeFileName = varargin{i};
        case {'.nii','.img','.txt','.gz'}
            VolFileName = varargin{i};
        case '.mat'
            CfgFileName = varargin{i};
        case {'.jpg','.tif','.bmp','.png','.eps'}
            PicFileName = varargin{i};
    end
end




% Start BrainNet
[H_BrainNet] = BrainNet;
global FLAG
FLAG.Loadfile = 0;
FLAG.IsCalledByCMD = 1;
global EC
global surf

% Load Surf file
if ~isempty(SurfFileName)
    if ~exist('SurfFileName','var')
        [BrainNetViewerPath, fileN, extn] = fileparts(which('BrainNet.m'));
        SurfFileName=[BrainNetViewerPath,filesep,'Data',filesep,...
            'SurfTemplate',filesep,'BrainMesh_ICBM152.nv'];
    end
    fid=fopen(SurfFileName);
    % Modified by Mingrui, 20150206, support comments in commandline
    %     surf.vertex_number=fscanf(fid,'%f',1);
    %     surf.coord=fscanf(fid,'%f',[3,surf.vertex_number]);
    %     surf.ntri=fscanf(fid,'%f',1);
    %     surf.tri=fscanf(fid,'%d',[3,surf.ntri])';
    
    data = textscan(fid,'%f','CommentStyle','#');
    surf.vertex_number = data{1}(1);
    surf.coord  = reshape(data{1}(2:1+3*surf.vertex_number),[3,surf.vertex_number]);
    surf.ntri = data{1}(3*surf.vertex_number+2);
    surf.tri = reshape(data{1}(3*surf.vertex_number+3:end),[3,surf.ntri])';
    fclose(fid);
    FLAG.Loadfile = FLAG.Loadfile + 1;
end

% Load Node file
if ~isempty(NodeFileName)
    fid=fopen(NodeFileName);
    
    % Modified by Mingrui, 20150206, support comments in commandline
    %     i=0;
    %     while ~feof(fid)
    %         curr=fscanf(fid,'%f',5);
    %         if ~isempty(curr)
    %             i=i+1;
    %             textscan(fid,'%s',1);
    %         end
    %     end
    %     surf.nsph=i;
    %     fclose(fid);
    %     surf.sphere=zeros(surf.nsph,5);
    %     surf.label=cell(surf.nsph,1);
    %     fid=fopen(NodeFileName);
    %     i=0;
    %     while ~feof(fid)
    %         curr=fscanf(fid,'%f',5);
    %         if ~isempty(curr)
    %             i=i+1;
    %             surf.sphere(i,1:5)=curr;
    %             surf.label{i}=textscan(fid,'%s',1);
    %         end
    %     end
    
    data = textscan(fid,'%f %f %f %f %f %s','CommentStyle','#');
    fclose(fid);
    surf.sphere = [cell2mat(data(1)) cell2mat(data(2)) cell2mat(data(3)) cell2mat(data(4)) cell2mat(data(5))];
    surf.label = data{6};
    surf.nsph = size(surf.sphere,1);
    FLAG.Loadfile = FLAG.Loadfile + 2;
end

% Load Edge file
if ~isempty(EdgeFileName)
    
    % Modified by Mingrui, 20150206, support comments in commandline
    %     surf.net=load(EdgeFileName);
    
    fid = fopen(EdgeFileName);
    data = textscan(fid,'%f','CommentStyle','#');
    surf.net = reshape(data{1},[sqrt(length(data{1})),sqrt(length(data{1}))])';
    fclose(fid);
    FLAG.Loadfile = FLAG.Loadfile + 4;
end

% Load Volume file
if ~isempty(VolFileName)
    [path, fname, ext] = fileparts(VolFileName);
    switch ext
        case {'.nii','.img'}
            [BrainNetPath] = fileparts(which('BrainNet.m'));
            BrainNet_SPMPath = fullfile(BrainNetPath, 'BrainNet_spm8_files');
            if exist('spm.m','file')
                surf.hdr=spm_vol(VolFileName);
                surf.vol=spm_read_vols(surf.hdr);
            else
                addpath(BrainNet_SPMPath);
                surf.hdr=BrainNet_spm_vol(VolFileName);
                surf.vol=BrainNet_spm_read_vols(surf.hdr);
                rmpath(BrainNet_SPMPath);
            end
            FLAG.MAP = 2;
            FLAG.Loadfile = FLAG.Loadfile + 8;
            EC.vol.px = max(surf.vol(:));
            EC.vol.nx = min(surf.vol(:));
            EC.msh.alpha = 1;
        case '.txt' %% Add by Mingrui, support text file
            surf.T=load(VolFileName);
            FLAG.MAP = 1;
            FLAG.Loadfile = FLAG.Loadfile + 8;
            EC.vol.px = max(surf.T(:));
            EC.vol.nx = min(surf.T(:));
        case {'.gz'}
            tmp_folder = tempdir;
            gunzip(VolFileName,tmp_folder);
            VolFileName = [tmp_folder,fname];
            [BrainNetPath] = fileparts(which('BrainNet.m'));
            BrainNet_SPMPath = fullfile(BrainNetPath, 'BrainNet_spm8_files');
            if exist('spm.m','file')
                surf.hdr=spm_vol(VolFileName);
                surf.vol=spm_read_vols(surf.hdr);
            else
                addpath(BrainNet_SPMPath);
                surf.hdr=BrainNet_spm_vol(VolFileName);
                surf.vol=BrainNet_spm_read_vols(surf.hdr);
                rmpath(BrainNet_SPMPath);
            end
            FLAG.MAP = 2;
            FLAG.Loadfile = FLAG.Loadfile + 8;
            EC.vol.px = max(surf.vol(:));
            EC.vol.nx = min(surf.vol(:));
            EC.msh.alpha = 1;
            delete(VolFileName);
    end
    EC.vol.display = 1;
    EC.vol.pn = 0;
    EC.vol.nn = 0;
end

% Load Configure file
if ~isempty(CfgFileName)
    load(CfgFileName);
end
if ~isfield(EC.bak,'color')
    EC.bak.color = [1 1 1];
end
if ~isfield(EC.msh,'color')
    EC.msh.color = [0.95,0.95,0.95];
end
if ~isfield(EC.msh,'alpha')
    EC.msh.alpha = 0.4;
end
if ~isfield(EC.msh,'doublebrain')
    EC.msh.doublebrain = 0;
end
if ~isfield(EC.nod,'draw')
    EC.nod.draw = 1;
end
if ~isfield(EC.nod,'draw_threshold_type')
    EC.nod.draw_threshold_type = 1;
end
if ~isfield(EC.nod,'draw_threshold')
    EC.nod.draw_threshold = 0;
end
if ~isfield(EC.nod,'size')
    EC.nod.size = 2;
end
if ~isfield(EC.nod,'size_size')
    EC.nod.size_size = 3;
end
if ~isfield(EC.nod,'size_value')
    EC.nod.size_value =1;
end
if ~isfield(EC.nod,'size_threshold')
    EC.nod.size_threshold = 0;
end
if ~isfield(EC.nod,'size_ratio')
    EC.nod.size_ratio = 1;
end
if ~isfield(EC.nod,'color')
    EC.nod.color = 1;
end
if ~isfield(EC.nod,'CM')
    EC.nod.CM = zeros(64,3);
end
if ~isfield(EC.nod,'color_map')
    EC.nod.color_map = 1;
end
if ~isfield(EC.nod,'color_threshold')
    EC.nod.color_threshold = 0;
end
if ~isfield(EC.nod,'CMm')
    EC.nod.CMm = [0.956862745098039,1,0.545098039215686,0,0.247058823529412,0.913725490196078,1,0.803921568627451,0,0.129411764705882,0.611764705882353,1,1,0.298039215686275,0.0117647058823529,0.403921568627451,0.474509803921569,0.376470588235294,0.619607843137255,0,1;
0.262745098039216,0.756862745098039,0.764705882352941,0.737254901960784,0.317647058823529,0.117647058823529,0.596078431372549,0.862745098039216,0.588235294117647,0.588235294117647,0.152941176470588,0.341176470588235,0.921568627450980,0.686274509803922,0.662745098039216,0.227450980392157,0.333333333333333,0.490196078431373,0.619607843137255,0,1;
0.211764705882353,0.0274509803921569,0.290196078431373,0.831372549019608,0.709803921568628,0.388235294117647,0,0.223529411764706,0.533333333333333,0.952941176470588,0.690196078431373,0.133333333333333,0.231372549019608,0.313725490196078,0.956862745098039,0.717647058823529,0.282352941176471,0.545098039215686,0.619607843137255,0,1]';
end

if ~isfield(EC.nod,'ModularNumber')
    EC.nod.ModularNumberm = [];
end

if ~isfield(EC,'lbl')
    EC.lbl = 2;
end
if ~isfield(EC,'lbl_threshold')
    EC.lbl_threshold = 0;
end
if ~isfield(EC,'lbl_threshold_type')
    EC.lbl_threshold_type = 1;
end
if ~isfield(EC.edg,'draw')
    EC.edg.draw = 1;
end
if ~isfield(EC.edg,'draw_threshold')
    EC.edg.draw_threshold = 0;
end
if ~isfield(EC.edg,'draw_abs')
    EC.edg.draw_abs = 1;
end
if ~isfield(EC.edg,'size')
    EC.edg.size = 2;
end
if ~isfield(EC.edg,'size_size')
    EC.edg.size_size = 1;
end
if ~isfield(EC.edg,'size_value')
    EC.edg.size_value = 1;
end
if ~isfield(EC.edg,'size_threshold')
    EC.edg.size_threshold = 0;
end
if ~isfield(EC.edg,'size_ratio')
    EC.edg.size_ratio = 1;
end
if ~isfield(EC.edg,'size_abs')
    EC.edg.size_abs = 1;
end
if ~isfield(EC.edg,'color')
    EC.edg.color = 1;
end
if ~isfield(EC.edg,'CM')
    EC.edg.CM = nes(64,3)*0.38;
end
if ~isfield(EC.edg,'color_map')
    EC.edg.color_map = 1;
end
if ~isfield(EC.edg,'color_threshold')
    EC.edg.color_threshold = 0;
end
if ~isfield(EC.edg,'color_distance')
    EC.edg.color_distance = 0;
end
if ~isfield(EC.edg,'color_abs')
    EC.edg.color_abs = 1;
end
if ~isfield(EC.edg,'interhemiedges')
    EC.edg.interhemiedges = 0;
end
if ~isfield(EC.edg,'directed')
    EC.edg.directed = 0;
end
if ~isfield(EC.img,'width')
    EC.img.width = 2000;
end
if ~isfield(EC.img,'height')
    EC.img.height = 1500;
end
if ~isfield(EC.img,'dpi')
    EC.img.dpi = 300;
end
if ~isfield(EC.lbl_font,'FontName')
    EC.lbl_font.FontName = 'Arial';
end
if ~isfield(EC.lbl_font,'FontWeight')
    EC.lbl_font.FontWeight = 'bold';
end
if ~isfield(EC.lbl_font,'FontAngle')
    EC.lbl_font.FontAngle = 'normal';
end
if ~isfield(EC.lbl_font,'FontSize')
    EC.lbl_font.FontSize = 11;
end
if ~isfield(EC.lbl_font,'FontUnits')
    EC.lbl_font.FontUnits = 'points';
end
if ~isfield(EC.lot,'view')
    EC.lot.view = 1;
end
if ~isfield(EC.lot,'view_direction')
    EC.lot.view_direction = 1;
end
if ~isfield(EC.lot,'view_az')
    EC.lot.view_az = -90;
end
if ~isfield(EC.lot,'view_el')
    EC.lot.view_el = 0;
end
if ~isfield(EC.vol,'display')
    EC.vol.display = [];
end
if ~isfield(EC.vol,'pn')
    EC.vol.pn = [];
end
if ~isfield(EC.vol,'px')
    EC.vol.px = [];
end
if ~isfield(EC.vol,'nn')
    EC.vol.nn = [];
end
if ~isfield(EC.vol,'nx')
    EC.vol.nx = [];
end
if ~isfield(EC.vol,'null')
    EC.vol.null = [0.95,0.95,0.95];
end
if ~isfield(EC.vol,'CM')
    EC.vol.CM = nes(1000,3)*0.75;
end
if ~isfield(EC.vol,'color_map')
    EC.vol.color_map = 13;
end
if ~isfield(EC.vol,'cmstring')
    EC.vol.cmstring = 'jet(1000);';
end
if ~isfield(EC.vol,'adjustCM')
    EC.vol.adjustCM = 1;
end
if ~isfield(EC.vol,'mapalgorithm')
    EC.vol.mapalgorithm = 5;
end
if ~isfield(EC.glb,'material')
    EC.glb.material = 'dull';
end
if ~isfield(EC.glb,'material_ka')
    EC.glb.material_ka = '0.5';
end
if ~isfield(EC.glb,'material_kd')
    EC.glb.material_kd = '0.5';
end
if ~isfield(EC.glb,'material__ks')
    EC.glb.material_ks = '0.5';
end
if ~isfield(EC.glb,'shading')
    EC.glb.shading = 'interp';
end
if ~isfield(EC.glb,'lighting')
    EC.glb.lighting = 'phong';
end
if ~isfield(EC.glb,'lightdirection')
    EC.glb.lightdirection = 'right';
end
if ~isfield(EC.glb,'render')
    EC.glb.render = 'OpenGL';
end
if ~isfield(EC.glb,'detail')
    EC.glb.detail = 3;
end
if ~isfield(EC.vol,'type')
    EC.vol.type = 1;
end
if ~isfield(EC.vol.roi,'drawall')
    EC.vol.roi.drawall = 1;
end
if ~isfield(EC.vol.roi,'draw')
    EC.vol.roi.draw = [];
end
if ~isfield(EC.vol.roi,'color')
    EC.vol.roi.color = hsv(100);
    EC.vol.roi.color = [EC.vol.roi.color(1:10:91,:)',EC.vol.roi.color(2:10:92,:)',EC.vol.roi.color(3:10:93,:)',EC.vol.roi.color(4:10:94,:)',EC.vol.roi.color(5:10:95,:)',EC.vol.roi.color(6:10:96,:)',EC.vol.roi.color(7:10:97,:)',EC.vol.roi.color(8:10:98,:)',EC.vol.roi.color(9:10:99,:)',EC.vol.roi.color(10:10:100,:)']';
EC.vol.roi.color = repmat(EC.vol.roi.color,11,1);
end
if ~isfield(EC.vol.roi,'colort')
    EC.vol.roi.colort = EC.vol.roi.color;
    
end
if ~isfield(EC.vol.roi,'smooth')
    EC.vol.roi.smooth = 1;
end
if ~isfield(EC.vol.roi,'drawcus')
    EC.vol.roi.drawcus = '';
end
if ~isfield(EC.vol.roi,'drawt')
    EC.vol.roi.drawt = [];
end

% Added by Mingrui Xia, 20140916, add statistic for volume mapping
if ~isfield(EC.vol,'threshold')
    EC.vol.threshold = 0;
end
if ~isfield(EC.vol,'p')
    EC.vol.p = 0.05;
end
if ~isfield(EC.vol.roi,'clustersize')
    EC.vol.clustersize = 0;
end
if ~isfield(EC.vol.roi,'rmm')
    EC.vol.rmm = 18;
end

% Add by Mingrui, 20140925, dispaly edge by opacity
if ~isfield(EC.edg,'opacity')
    EC.edg.opacity = 1;
end
if ~isfield(EC.edg,'opacity_same')
    EC.edg.opacity_same = 0.7;
end
if ~isfield(EC.edg,'opacity_max')
    EC.edg.opacity_max = 0.9;
end
if ~isfield(EC.edg,'opacity_min')
    EC.edg.opacity_min = 0.1;
end
if ~isfield(EC.edg,'opacity_abs')
    EC.edg.opacity_abs = 1;
end

% Add by Mingrui, 20150120, using custom matrix to define edge color.
if ~isfield(EC.edg,'color_custom_matrix')
    EC.edg.color_custom_matrix = [];
end
if ~isfield(EC.edg,'color_custom_index')
    EC.edg.color_custom_index = [];
end
if ~isfield(EC.edg,'CM_custom')
    EC.edg.CM_custom = [0.956862745098039,1,0.545098039215686,0,0.247058823529412,0.913725490196078,1,0.803921568627451,0,0.129411764705882,0.611764705882353,1,1,0.298039215686275,0.0117647058823529,0.403921568627451,0.474509803921569,0.376470588235294,0.619607843137255,0,1;
0.262745098039216,0.756862745098039,0.764705882352941,0.737254901960784,0.317647058823529,0.117647058823529,0.596078431372549,0.862745098039216,0.588235294117647,0.588235294117647,0.152941176470588,0.341176470588235,0.921568627450980,0.686274509803922,0.662745098039216,0.227450980392157,0.333333333333333,0.490196078431373,0.619607843137255,0,1;
0.211764705882353,0.0274509803921569,0.290196078431373,0.831372549019608,0.709803921568628,0.388235294117647,0,0.223529411764706,0.533333333333333,0.952941176470588,0.690196078431373,0.133333333333333,0.231372549019608,0.313725490196078,0.956862745098039,0.717647058823529,0.282352941176471,0.545098039215686,0.619607843137255,0,1]';
end

if FLAG.Loadfile ==1 || FLAG.Loadfile == 9 % Add by Mingrui, 20121123, set mesh opacity to 1
    EC.msh.alpha = 1;
end

if FLAG.Loadfile==2||FLAG.Loadfile==3||FLAG.Loadfile==7||FLAG.Loadfile==6||FLAG.Loadfile==11||FLAG.Loadfile==15 %% Add by Mingrui, 20140412, a fix a bug when module number more than option file.
    EC.nod.ModularNumber = unique(surf.sphere(:,4));
end

% Draw
set(H_BrainNet,'handlevisib','on');
BrainNet('NV_m_nm_Callback',H_BrainNet);

% Save to image
if ~isempty(PicFileName)
    [pathstr, name, ext] = fileparts(PicFileName);
    set(H_BrainNet, 'PaperPositionMode', 'manual');
    set(H_BrainNet, 'PaperUnits', 'inch');
    set(H_BrainNet,'Paperposition',[1 1 EC.img.width/EC.img.dpi EC.img.height/EC.img.dpi]);
    switch ext
        case '.tif'
            print(H_BrainNet,PicFileName,'-dtiff',['-r',num2str(EC.img.dpi)]);
        case '.jpg'
            print(H_BrainNet,PicFileName,'-djpeg',['-r',num2str(EC.img.dpi)]);
        case '.bmp'
            print(H_BrainNet,PicFileName,'-dbmp',['-r',num2str(EC.img.dpi)]);
        case '.png'
            print(H_BrainNet,PicFileName,'-dpng',['-r',num2str(EC.img.dpi)]);
        case '.eps'
            print(H_BrainNet,PicFileName,'-depsc',['-r',num2str(EC.img.dpi)]);
            
            
    end
end