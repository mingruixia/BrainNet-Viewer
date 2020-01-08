function varargout = BrainNet_Option(varargin)
%BrainNet Viewer, a graph-based brain network mapping tool, by Mingrui Xia
%Function for control panel
%-----------------------------------------------------------
%	Copyright(c) 2019
%	State Key Laboratory of Cognitive Neuroscience and Learning, Beijing Normal University
%	Written by Mingrui Xia
%	Mail to Author:  <a href="mingruixia@gmail.com">Mingrui Xia</a>
%   Version 1.63;
%   Create Date 20110531;
%   Last edited 20190329
%-----------------------------------------------------------
%
% BrainNet_Option MATLAB code for BrainNet_Option.fig
%      BrainNet_Option, by itself, creates a new BrainNet_Option or raises the existing
%      singleton*.
%
%      H = BrainNet_Option returns the handle to a new BrainNet_Option or the handle to
%      the existing singleton*.
%
%      BrainNet_Option('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BrainNet_Option.M with the given input arguments.
%
%      BrainNet_Option('Property','Value',...) creates a new BrainNet_Option or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BrainNet_Option_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BrainNet_Option_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BrainNet_Option

% Last Modified by GUIDE v2.5 21-May-2019 10:51:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @BrainNet_Option_OpeningFcn, ...
    'gui_OutputFcn',  @BrainNet_Option_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before BrainNet_Option is made visible.
function BrainNet_Option_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to BrainNet_Option (see VARARGIN)

% Choose default command line output for BrainNet_Option
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% h_NV=findobj('Tag','NV_fig');
% h_NV=guihandles(h_NV);
% setappdata(handles.EP_fig,'h_NV',h_NV);

movegui(handles.EP_fig,'center');
set(handles.Apply_button,'Enable','off');
Initialization(handles);


function Initialization(handles)
global EC
global surf
global FLAG

% Edited  by Mingrui Xia, 20120806, add custom view for single brain.
set(handles.LotSCusAz_edit,'String',num2str(EC.lot.view_az,'%d'));
set(handles.LotSingleCustomEl_edit,'String',num2str(EC.lot.view_el,'%d'));
switch EC.lot.view
    case 1
        set(handles.LotS_radiobutton,'Value',1);
        set(handles.LotSS_radiobutton,'Enable','on');
        set(handles.LotSA_radiobutton,'Enable','on');
        set(handles.LotSC_radiobutton,'Enable','on');
        set(handles.LotSCus_radiobutton,'Enable','on');
        if EC.msh.doublebrain == 1 % Added by Mingrui Xia, 20120717, show two brains in one figure
            set(handles.LotF_radiobutton,'Enable','off');
            set(handles.LotLM_radiobutton,'Enable','off');
            set(handles.LotLMV_radiobutton,'Enable','off'); % Added by Mingrui Xia, 20130221, add view for medium with ventral
            set(handles.LotLMD_radiobutton,'Enable','off');
        end
    case 2
        set(handles.LotF_radiobutton,'Value',1);
        set(handles.LotSS_radiobutton,'Enable','off');
        set(handles.LotSA_radiobutton,'Enable','off');
        set(handles.LotSC_radiobutton,'Enable','off');
        set(handles.LotSCus_radiobutton,'Enable','off');
        set(handles.LotSCusAz_text,'Enable','off');
        set(handles.LotSCusAz_edit,'Enable','off');
        set(handles.LotSCusEl_text,'Enable','off');
        set(handles.LotSingleCustomEl_edit,'Enable','off');
    case 3 %%% Added by Mingrui Xia, 20111027, add for medium views(4 views).
        set(handles.LotLM_radiobutton, 'Value', 1);
        set(handles.LotSS_radiobutton,'Enable','off');
        set(handles.LotSA_radiobutton,'Enable','off');
        set(handles.LotSC_radiobutton,'Enable','off');
        set(handles.LotSCus_radiobutton,'Enable','off');
        set(handles.LotSCusAz_text,'Enable','off');
        set(handles.LotSCusAz_edit,'Enable','off');
        set(handles.LotSCusEl_text,'Enable','off');
        set(handles.LotSingleCustomEl_edit,'Enable','off');
    case 4 % Added by Mingrui Xia, 20130221, add view for medium with ventral
        set(handles.LotLMV_radiobutton,'Value',1);
        set(handles.LotSS_radiobutton,'Enable','off');
        set(handles.LotSA_radiobutton,'Enable','off');
        set(handles.LotSC_radiobutton,'Enable','off');
        set(handles.LotSCus_radiobutton,'Enable','off');
        set(handles.LotSCusAz_text,'Enable','off');
        set(handles.LotSCusAz_edit,'Enable','off');
        set(handles.LotSCusEl_text,'Enable','off');
        set(handles.LotSingleCustomEl_edit,'Enable','off');
        
        % Added by Mingrui, 20170309, add layout for lateral, medial and dorsal view
    case 5
        set(handles.LotLMD_radiobutton,'Value',1);
        set(handles.LotSS_radiobutton,'Enable','off');
        set(handles.LotSA_radiobutton,'Enable','off');
        set(handles.LotSC_radiobutton,'Enable','off');
        set(handles.LotSCus_radiobutton,'Enable','off');
        set(handles.LotSCusAz_text,'Enable','off');
        set(handles.LotSCusAz_edit,'Enable','off');
        set(handles.LotSCusEl_text,'Enable','off');
        set(handles.LotSingleCustomEl_edit,'Enable','off');
end

switch FLAG.Loadfile
    %     case {1,3,7,9} %%% Edited by Mingrui, add 11 for volume and node mode
    case {1,3,7,9,11,15} %%% Edited by Mingrui Xia, 20120210, add 15 for volume, node and edge mode.
        [t,tl,tr,vl,vr,h1,w1,cut,cuv]=BrainNet('CutMesh', surf);
        if t<=cut
            set(handles.LotLM_radiobutton, 'Enable', 'off');
            set(handles.LotLMV_radiobutton, 'Enable', 'off');
            set(handles.LotLMD_radiobutton, 'Enable', 'off');
            if EC.lot.view==3 && EC.lot.view == 4 % Edited by Mingrui Xia, 20130221, 4 for view of medium with ventral
                EC.lot.view = 2;
                set(handles.LotF_radiobutton,'Value',1);
                set(handles.LotSS_radiobutton,'Enable','off');
                set(handles.LotSA_radiobutton,'Enable','off');
                set(handles.LotSC_radiobutton,'Enable','off');
                set(handles.LotSCus_radiobutton,'Enable','off');
                set(handles.LotSCusAz_text,'Enable','off');
                set(handles.LotSCusAz_edit,'Enable','off');
                set(handles.LotSCusEl_text,'Enable','off');
                set(handles.LotSingleCustomEl_edit,'Enable','off');
            end
        end
    case {2,6}
        set(handles.LotLM_radiobutton, 'Enable', 'off');
        set(handles.LotLMV_radiobutton, 'Enable', 'off');
        set(handles.LotLMD_radiobutton, 'Enable', 'off');
        if EC.lot.view==3 && EC.lot.view == 4
            EC.lot.view = 2;
            set(handles.LotF_radiobutton,'Value',1);
            set(handles.LotSS_radiobutton,'Enable','off');
            set(handles.LotSA_radiobutton,'Enable','off');
            set(handles.LotSC_radiobutton,'Enable','off');
            set(handles.LotSCus_radiobutton,'Enable','off');
            set(handles.LotSCusAz_text,'Enable','off');
            set(handles.LotSCusAz_edit,'Enable','off');
            set(handles.LotSCusEl_text,'Enable','off');
            set(handles.LotSingleCustomEl_edit,'Enable','off');
        end
end
%%% Added END, 20111027
switch EC.lot.view_direction
    case 1
        set(handles.LotSS_radiobutton,'Value',1);
        set(handles.LotSCusAz_text,'Enable','off');
        set(handles.LotSCusAz_edit,'Enable','off');
        set(handles.LotSCusEl_text,'Enable','off');
        set(handles.LotSingleCustomEl_edit,'Enable','off');
    case 2
        set(handles.LotSA_radiobutton,'Value',1);
        set(handles.LotSCusAz_text,'Enable','off');
        set(handles.LotSCusAz_edit,'Enable','off');
        set(handles.LotSCusEl_text,'Enable','off');
        set(handles.LotSingleCustomEl_edit,'Enable','off');
    case 3
        set(handles.LotSC_radiobutton,'Value',1);
        set(handles.LotSCusAz_text,'Enable','off');
        set(handles.LotSCusAz_edit,'Enable','off');
        set(handles.LotSCusEl_text,'Enable','off');
        set(handles.LotSingleCustomEl_edit,'Enable','off');
    case 4
        set(handles.LotSCus_radiobutton,'Value',1);
        set(handles.LotSCusAz_text,'Enable','on');
        set(handles.LotSCusAz_edit,'Enable','on');
        set(handles.LotSCusEl_text,'Enable','on');
        set(handles.LotSingleCustomEl_edit,'Enable','on');
        
end
set(handles.BakC_pushbutton,'BackgroundColor',EC.bak.color);

switch EC.glb.material % Add by Mingrui Xia, 20120316, modify object material, shading, light.
    case 'shiny'
        set(handles.GlbM_popupmenu,'Value',1);
        set(handles.GlbMa_text,'Enable','off');
        set(handles.GlbMa_edit,'Enable','off');
        set(handles.GlbMd_text,'Enable','off');
        set(handles.GlbMd_edit,'Enable','off');
        set(handles.GlbMs_text,'Enable','off');
        set(handles.GlbMs_edit,'Enable','off');
    case 'dull'
        set(handles.GlbM_popupmenu,'Value',2);
        set(handles.GlbMa_text,'Enable','off');
        set(handles.GlbMa_edit,'Enable','off');
        set(handles.GlbMd_text,'Enable','off');
        set(handles.GlbMd_edit,'Enable','off');
        set(handles.GlbMs_text,'Enable','off');
        set(handles.GlbMs_edit,'Enable','off');
    case 'metal'
        set(handles.GlbM_popupmenu,'Value',3);
        set(handles.GlbMa_text,'Enable','off');
        set(handles.GlbMa_edit,'Enable','off');
        set(handles.GlbMd_text,'Enable','off');
        set(handles.GlbMd_edit,'Enable','off');
        set(handles.GlbMs_text,'Enable','off');
        set(handles.GlbMs_edit,'Enable','off');
    otherwise
        set(handles.GlbM_popupmenu,'Value',4);
        set(handles.GlbMa_text,'Enable','on');
        set(handles.GlbMa_edit,'Enable','on');
        set(handles.GlbMd_text,'Enable','on');
        set(handles.GlbMd_edit,'Enable','on');
        set(handles.GlbMs_text,'Enable','on');
        set(handles.GlbMs_edit,'Enable','on');
end

set(handles.GlbMa_edit,'String',EC.glb.material_ka);
set(handles.GlbMd_edit,'String',EC.glb.material_kd);
set(handles.GlbMs_edit,'String',EC.glb.material_ks);

switch EC.glb.shading
    case 'flat'
        set(handles.GlbS_popupmenu,'Value',1);
    case 'faceted'
        set(handles.GlbS_popupmenu,'Value',2);
    case 'interp'
        set(handles.GlbS_popupmenu,'Value',3);
end

switch EC.glb.lighting
    case 'flat'
        set(handles.GlbLA_popupmenu,'Value',1);
    case 'gouraud'
        set(handles.GlbLA_popupmenu,'Value',2);
    case 'phong'
        set(handles.GlbLA_popupmenu,'Value',3);
    case 'none'
        set(handles.GlbLA_popupmenu,'Value',4);
end

switch EC.glb.lightdirection
    case 'headlight'
        set(handles.GlbLD_popupmenu,'Value',1);
    case 'right'
        set(handles.GlbLD_popupmenu,'Value',2);
    case 'left'
        set(handles.GlbLD_popupmenu,'Value',3);
end

switch EC.glb.render % Added by Mingrui Xia, 20120413, selection for rendering methods
    case 'OpenGL'
        set(handles.GlbRd_popupmenu,'Value',1);
    case 'zbuffer'
        set(handles.GlbRd_popupmenu,'Value',2);
end

set(handles.GlbGD_popupmenu,'Value',EC.glb.detail); % Add by Mingrui Xia, 20120413, adjust graph detail

% Add by Mingrui, 20170309, display LR
set(handles.GlbLR_checkbox,'Value',EC.glb.lr);

% if FLAG.Loadfile==1||FLAG.Loadfile==3||FLAG.Loadfile==7 %%% Edited by
% Mingrui Xia, add 11 for volume & node mode.
% if FLAG.Loadfile==2||FLAG.Loadfile==3||FLAG.Loadfile==7||FLAG.Loadfile==6||FLAG.Loadfile==1||FLAG.Loadfile==9||FLAG.Loadfile==11||FLAG.Loadfile==15
if FLAG.Loadfile==3||FLAG.Loadfile==7||FLAG.Loadfile==1||FLAG.Loadfile==9||FLAG.Loadfile==11||FLAG.Loadfile==15
    set(handles.Mesh_color_popupmenu,'Value',EC.msh.color_type);
    if EC.msh.color_type == 1
        set(handles.MshC_pushbutton,'Enable','on');
    else
        set(handles.MshC_pushbutton,'Enable','off');
    end        
    set(handles.MshC_pushbutton,'BackgroundColor',EC.msh.color);
    set(handles.MshA_slider, 'Value',EC.msh.alpha);
    set(handles.MshA_edit, 'String',num2str(EC.msh.alpha,'%f'));
    set(handles.Mesh_boundary_popupmenu,'Value',EC.msh.boundary);
    if length(EC.msh.boundary_value) == 1
        set(handles.Mesh_boundary_edit,'String',num2str(EC.msh.boundary_value));
    else
        set(handles.Mesh_boundary_edit,'String','0');
    end
    set(handles.Mesh_boundary_pushbutton,'BackgroundColor',EC.msh.boundary_color);
    switch EC.msh.boundary
        case 1
            set(handles.Mesh_boundary_edit,'Enable','off');
            set(handles.Mesh_boundary_pushbutton,'Enable','off');
        case {2,4}
            set(handles.Mesh_boundary_edit,'Enable','off');
    end
    EC.msh.boundary_value_tmp = EC.msh.boundary_value;
    
    if FLAG.Loadfile < 9 % Added by Mingrui Xia, 20120717, show two brains in one figure
        set(handles.MshDoubleBrain_checkbox,'Value',EC.msh.doublebrain);
    else
        set(handles.MshDoubleBrain_checkbox,'Enable','off');
    end
    % elseif %% Edited by Mingrui Xia, 20120210, add 15 for volume, node and edge mode.
    %     set(handles.MshC_pushbutton,'Enable','off');
    %     set(handles.MshA_slider, 'Value',EC.msh.alpha);
    %     set(handles.MshA_edit, 'String',num2str(EC.msh.alpha,'%f'));
else
    set(handles.MshC_pushbutton,'Enable','off');
    set(handles.MshC_text1,'Enable','off');
    set(handles.MshA_slider,'Enable','off');
    set(handles.MshA_edit,'Enable','off');
    set(handles.MshA_text,'Enable','off');
    
    set(handles.MshDoubleBrain_checkbox,'Enable','off');%%% Added by Mingrui Xia, 20120717, show two brains in one figure
    
    set(handles.Mesh_boundary_text,'Enable','off');
    set(handles.Mesh_boundary_popupmenu,'Enable','off');
    set(handles.Mesh_boundary_edit,'Enable','off');
    set(handles.Mesh_boundary_pushbutton,'Enable','off');
end

% if FLAG.Loadfile==2||FLAG.Loadfile==3||FLAG.Loadfile==7||FLAG.Loadfile==6
% %%% Edited by Mingrui Xia 20111116, add 11 for volume & node mode
if FLAG.Loadfile==2||FLAG.Loadfile==3||FLAG.Loadfile==7||FLAG.Loadfile==6||FLAG.Loadfile==11||FLAG.Loadfile==15 %% Edited by Mingrui Xia, 20120210, add 15 for volume, node and edge mode.
    EC.nod.ModularNumber = sort(unique(surf.sphere(:,4)));
    if length(EC.nod.ModularNumber) > size(EC.nod.CMm,1)
        EC.nod.CMm(22:length(EC.nod.ModularNumber) ,:) = rand(length(EC.nod.ModularNumber) -21,3);
    end
    switch EC.lbl
        case 1
            set(handles.LblA_radiobutton,'Value',1);
            set(handles.LblT_slider,'Enable','off');
            set(handles.LblT_edit,'Enable','off');
            set(handles.LblT_popupmenu,'Enable','off');
        case 2
            set(handles.LblN_radiobutton,'Value',1);
            set(handles.LblT_slider,'Enable','off');
            set(handles.LblT_edit,'Enable','off');
            set(handles.LblT_popupmenu,'Enable','off');
        case 3
            set(handles.LblT_radiobutton,'Value',1);
            set(handles.LblT_slider,'Enable','on');
            set(handles.LblT_edit,'Enable','on');
            set(handles.LblT_popupmenu,'Enable','on');
    end
    
    set(handles.Lbl_front_checkbox,'Value',EC.lbl_front);
    
    switch EC.lbl_threshold_type
        case 1
            if EC.lbl_threshold>max(surf.sphere(:,5))||EC.lbl_threshold<min(surf.sphere(:,5))
                EC.lbl_threshold=min(surf.sphere(:,5));
            end
            set(handles.LblT_popupmenu,'Value',1);
            set(handles.LblT_slider,'Max',max(surf.sphere(:,5)));
            set(handles.LblT_slider,'Min',min(surf.sphere(:,5))-0.001);
            set(handles.LblT_slider,'Value',EC.lbl_threshold);
            set(handles.LblT_edit,'String',num2str(EC.lbl_threshold,'%f'));
        case 2
            if EC.lbl_threshold>max(surf.sphere(:,4))||EC.lbl_threshold<min(surf.sphere(:,4))
                EC.lbl_threshold=min(surf.sphere(:,4));
            end
            set(handles.LblT_popupmenu,'Value',2);
            set(handles.LblT_slider,'Max',max(surf.sphere(:,4)));
            set(handles.LblT_slider,'Min',min(surf.sphere(:,4))-0.001);
            set(handles.LblT_slider,'Value',EC.lbl_threshold);
            set(handles.LblT_edit,'String',num2str(EC.lbl_threshold,'%f'));
    end
    switch EC.nod.draw
        case 1
            set(handles.NodDA_radiobutton,'Value',1);
            set(handles.NodDT_slider,'Enable','off');
            set(handles.NodDT_edit,'Enable','off');
            set(handles.NodDT_popupmenu,'Enable','off');
        case 2
            set(handles.NodDT_radiobutton,'Value',1);
            set(handles.NodDT_slider,'Enable','on');
            set(handles.NodDT_edit,'Enable','on');
            set(handles.NodDT_popupmenu,'Enable','on');
            
            % Added by Mingrui, 20150120, only draw nodes with connections
        case 3
            set(handles.NodDrawConnection_radiobutton,'Value',1);
            set(handles.NodDT_slider,'Enable','off');
            set(handles.NodDT_edit,'Enable','off');
            set(handles.NodDT_popupmenu,'Enable','off');
    end
    switch EC.nod.draw_threshold_type
        case 1
            if EC.nod.draw_threshold>max(surf.sphere(:,5))||EC.nod.draw_threshold<min(surf.sphere(:,5))
                EC.nod.draw_threshold=min(surf.sphere(:,5));
            end
            set(handles.NodDT_popupmenu,'Value',1);
            set(handles.NodDT_slider,'Max',max(surf.sphere(:,5)));
            set(handles.NodDT_slider,'Min',min(surf.sphere(:,5))-0.001);
            set(handles.NodDT_slider,'Value',EC.nod.draw_threshold);
            set(handles.NodDT_edit,'String',num2str(EC.nod.draw_threshold,'%f'));
        case 2
            if EC.nod.draw_threshold>max(surf.sphere(:,4))||EC.nod.draw_threshold<min(surf.sphere(:,4))
                EC.nod.draw_threshold=min(surf.sphere(:,4));
            end
            set(handles.NodDT_popupmenu,'Value',2);
            set(handles.NodDT_slider,'Max',max(surf.sphere(:,4)));
            set(handles.NodDT_slider,'Min',min(surf.sphere(:,4))-0.001);
            set(handles.NodDT_slider,'Value',EC.nod.draw_threshold);
            set(handles.NodDT_edit,'String',num2str(EC.nod.draw_threshold,'%f'));
    end
    switch EC.nod.size
        case 1
            set(handles.NodSS_radiobutton,'Value',1);
            set(handles.NodSS_edit,'Enable','on');
            set(handles.NodSV_popupmenu,'Enable','off');
            set(handles.NodST_slider,'Enable','off');
            set(handles.NodST_edit,'Enable','off');
            set(handles.NodST_checkbox,'Enable','off');
        case 2
            set(handles.NodSV_radiobutton,'Value',1);
            set(handles.NodSS_edit,'Enable','off');
            set(handles.NodSV_popupmenu,'Enable','on');
            set(handles.NodST_slider,'Enable','off');
            set(handles.NodST_edit,'Enable','off');
            set(handles.NodST_checkbox,'Enable','on');
            set(handles.NodST_checkbox,'Value',0);
        case 3
            set(handles.NodSV_radiobutton,'Value',1);
            set(handles.NodST_checkbox,'Value',1);
            set(handles.NodSS_edit,'Enable','off');
            set(handles.NodSV_popupmenu,'Enable','on');
            set(handles.NodST_slider,'Enable','on');
            set(handles.NodST_edit,'Enable','on');
            set(handles.NodST_checkbox,'Enable','on');
    end
    set(handles.NodSS_edit,'String',num2str(EC.nod.size_size,'%f'));
    set(handles.NodSV_popupmenu,'Value',EC.nod.size_value);
    if EC.nod.size_threshold>max(surf.sphere(:,5))||EC.nod.size_threshold<min(surf.sphere(:,5))
        EC.nod.size_threshold=min(surf.sphere(:,5));
    end
    set(handles.NodST_slider,'Max',max(surf.sphere(:,5)));
    set(handles.NodST_slider,'Min',min(surf.sphere(:,5))-0.001);
    set(handles.NodST_slider,'Value',EC.nod.size_threshold);
    set(handles.NodST_edit,'String',num2str(EC.nod.size_threshold,'%f'));
    set(handles.NodSVR_slider,'Value',EC.nod.size_ratio);
    set(handles.NodSVR_edit,'String',num2str(EC.nod.size_ratio,'%f'));
    
    switch EC.nod.color % Modified by Mingrui, 20170303, fixed range of color mapping
        case 1
            set(handles.NodCS_radiobutton,'Value',1);
            set(handles.NodCC_popupmenu,'Enable','off');
            set(handles.NodCM_pushbutton,'Enable','off');
            set(handles.NodCT_slider,'Enable','off');
            set(handles.NodCT_edit,'Enable','off');
            set(handles.NodCS_pushbutton,'BackgroundColor',EC.nod.CM(1,:));
            set(handles.NodCC_Range_popupmenu,'Enable','off');
            set(handles.NodCC_low_edit,'Enable','off');
            set(handles.NodCC_high_edit,'Enable','off');
        case 2
            set(handles.NodCC_radiobutton,'Value',1);
            set(handles.NodCC_popupmenu,'Enable','on');
            set(handles.NodCM_pushbutton,'Enable','off');
            set(handles.NodCT_slider,'Enable','off');
            set(handles.NodCT_edit,'Enable','off');
            set(handles.NodCC_Range_popupmenu,'Enable','on');
            if EC.nod.color_map_type == 1
                set(handles.NodCC_low_edit,'Enable','off');
                set(handles.NodCC_high_edit,'Enable','off');
            else
                set(handles.NodCC_low_edit,'Enable','on');
                set(handles.NodCC_high_edit,'Enable','on');
            end
        case 3
            set(handles.NodCM_radiobutton,'Value',1);
            set(handles.NodCC_popupmenu,'Enable','off');
            set(handles.NodCM_pushbutton,'Enable','on');
            set(handles.NodCT_slider,'Enable','off');
            set(handles.NodCT_edit,'Enable','off');
            set(handles.NodCC_Range_popupmenu,'Enable','off');
            set(handles.NodCC_low_edit,'Enable','off');
            set(handles.NodCC_high_edit,'Enable','off');
        case 4
            set(handles.NodCT_radiobutton,'Value',1);
            set(handles.NodCC_popupmenu,'Enable','off');
            set(handles.NodCM_pushbutton,'Enable','off');
            set(handles.NodCT_slider,'Enable','on');
            set(handles.NodCT_edit,'Enable','on');
            set(handles.NodCTH_pushbutton,'BackgroundColor',EC.nod.CM(1,:));
            set(handles.NodCTL_pushbutton,'BackgroundColor',EC.nod.CM(64,:));
            set(handles.NodCC_Range_popupmenu,'Enable','off');
            set(handles.NodCC_low_edit,'Enable','off');
            set(handles.NodCC_high_edit,'Enable','off');
    end
    set(handles.NodCC_popupmenu,'Value',EC.nod.color_map);
    if EC.nod.color_threshold>max(surf.sphere(:,4))||EC.nod.color_threshold<min(surf.sphere(:,4))
        EC.nod.color_threshold=min(surf.sphere(:,4));
    end
    set(handles.NodCT_slider,'Max',max(surf.sphere(:,4)));
    set(handles.NodCT_slider,'Min',min(surf.sphere(:,4))-0.001);
    set(handles.NodCT_slider,'Value',EC.nod.color_threshold);
    set(handles.NodCT_edit,'String',num2str(EC.nod.color_threshold,'%f'));
    set(handles.NodCC_Range_popupmenu,'Value',EC.nod.color_map_type);
    set(handles.NodCC_low_edit,'String',num2str(EC.nod.color_map_low,'%f'));
    set(handles.NodCC_high_edit,'String',num2str(EC.nod.color_map_high,'%f'));
else
    set(handles.NodDA_radiobutton,'Enable','off');
    set(handles.NodDT_radiobutton,'Enable','off');
    set(handles.NodDT_slider,'Enable','off');
    set(handles.NodDT_edit,'Enable','off');
    set(handles.NodDT_popupmenu,'Enable','off');
    set(handles.NodDrawConnection_radiobutton,'Enable','off');
    set(handles.NodSS_radiobutton,'Enable','off');
    set(handles.NodSS_edit,'Enable','off');
    set(handles.NodSV_radiobutton,'Enable','off');
    set(handles.NodSV_popupmenu,'Enable','off');
    set(handles.NodST_checkbox,'Enable','off');
    set(handles.NodST_slider,'Enable','off');
    set(handles.NodST_edit,'Enable','off');
    set(handles.NodSVR_slider,'Enable','off');
    set(handles.NodSVR_edit,'Enable','off');
    set(handles.NodCS_radiobutton,'Enable','off');
    set(handles.NodCC_radiobutton,'Enable','off');
    set(handles.NodCC_popupmenu,'Enable','off');
    set(handles.NodCM_radiobutton,'Enable','off');
    set(handles.NodCM_pushbutton,'Enable','off');
    set(handles.NodCT_radiobutton,'Enable','off');
    set(handles.NodCT_slider,'Enable','off');
    set(handles.NodCT_edit,'Enable','off');
    set(handles.LblA_radiobutton,'Enable','off');
    set(handles.LblN_radiobutton,'Enable','off');
    set(handles.LblT_radiobutton,'Enable','off');
    set(handles.LblT_slider,'Enable','off');
    set(handles.LblT_edit,'Enable','off');
    set(handles.LblT_popupmenu,'Enable','off');
    set(handles.LblF_button,'Enable','off');
    set(handles.NodCC_Range_popupmenu,'Enable','off');
    set(handles.NodCC_low_edit,'Enable','off');
    set(handles.NodCC_high_edit,'Enable','off');
end


if FLAG.Loadfile==7||FLAG.Loadfile==6||FLAG.Loadfile==15 %% Edited by Mingrui Xia, 20120210, add 15 for volume, node and edge mode.
    switch EC.edg.draw
        case 1
            set(handles.EdgDA_radiobutton,'Value',1);
            set(handles.EdgDT_slider,'Enable','off');
            set(handles.EdgDT_edit,'Enable','off');
            set(handles.EdgDS_slider,'Enable','off');
            set(handles.EdgDS_edit,'Enable','off');
            %             set(handles.EdgDT_checkbox,'Enable','off');
        case 2
            set(handles.EdgDT_radiobutton,'Value',1);
            set(handles.EdgDT_slider,'Enable','on');
            set(handles.EdgDT_edit,'Enable','on');
            set(handles.EdgDS_slider,'Enable','on');
            set(handles.EdgDS_edit,'Enable','on');
            set(handles.EdgDT_checkbox,'Enable','on');
            set(handles.EdgDT_checkbox,'Value',EC.edg.draw_abs);
    end
    switch get(handles.EdgDT_checkbox,'Value')
        case 0
            if EC.edg.draw_threshold>max(surf.net(:))||EC.edg.draw_threshold<min(surf.net(:))
                EC.edg.draw_threshold=min(surf.net(:));
            end
            set(handles.EdgDT_slider,'Max',max(surf.net(:)));
            set(handles.EdgDT_slider,'Min',min(surf.net(:))-0.001);
            set(handles.EdgDT_slider,'Value',EC.edg.draw_threshold);
            set(handles.EdgDT_edit,'String',num2str(EC.edg.draw_threshold,'%f'));
            set(handles.EdgDS_slider,'Value',length(find(surf.net>EC.edg.draw_threshold))/(size(surf.net,1)*size(surf.net,2)));
            set(handles.EdgDS_edit,'String',num2str(length(find(surf.net>EC.edg.draw_threshold))/(size(surf.net,1)*size(surf.net,2)),'%f'));
        case 1
            if EC.edg.draw_threshold>max(abs(surf.net(:)))||EC.edg.draw_threshold<min(abs(surf.net(:)))
                EC.edg.draw_threshold=min(abs(surf.net(:)));
            end
            set(handles.EdgDT_slider,'Max',max(abs(surf.net(:))));
            set(handles.EdgDT_slider,'Min',min(abs(surf.net(:)))-0.001);
            set(handles.EdgDT_slider,'Value',EC.edg.draw_threshold);
            set(handles.EdgDT_edit,'String',num2str(EC.edg.draw_threshold,'%f'));
            set(handles.EdgDS_slider,'Value',length(find(abs(surf.net)>EC.edg.draw_threshold))/(size(surf.net,1)*size(surf.net,2)));
            set(handles.EdgDS_edit,'String',num2str(length(find(abs(surf.net)>EC.edg.draw_threshold))/(size(surf.net,1)*size(surf.net,2)),'%f'));
    end
    set(handles.EdgDInter_checkbox,'Value',EC.edg.interhemiedges);  % Add by Mingrui Xia, 20120109, draw inter hemisphere edges.
    set(handles.EdgDDirected_checkbox,'Value',EC.edg.directed); % Add by Mingrui Xia, 20120621, draw directed network.
    switch EC.edg.size
        case 1
            set(handles.EdgSS_radiobutton,'Value',1);
            set(handles.EdgSS_edit,'Enable','on');
            set(handles.EdgSV_popupmenu,'Enable','off');
            set(handles.EdgST_slider,'Enable','off');
            set(handles.EdgST_edit,'Enable','off');
            set(handles.EdgST_checkbox,'Enable','off');
        case 2
            set(handles.EdgSV_radiobutton,'Value',1);
            set(handles.EdgSS_edit,'Enable','off');
            set(handles.EdgSV_popupmenu,'Enable','on');
            set(handles.EdgST_checkbox,'Enable','on');
            set(handles.EdgST_slider,'Enable','off');
            set(handles.EdgST_edit,'Enable','off');
        case 3
            set(handles.EdgST_checkbox,'Value',1);
            set(handles.EdgSS_edit,'Enable','off');
            set(handles.EdgSV_popupmenu,'Enable','on');
            set(handles.EdgST_slider,'Enable','on');
            set(handles.EdgST_edit,'Enable','on');
            set(handles.EdgSV_radiobutton,'Value',1);
    end
    set(handles.EdgSS_edit,'String',num2str(EC.edg.size_size,'%f'));
    set(handles.EdgSV_popupmenu,'Value',EC.edg.size_value);
    set(handles.EdgS_checkbox,'Value',EC.edg.size_abs);
    switch EC.edg.size_abs
        case 0
            if EC.edg.size_threshold>max(surf.net(:))||EC.edg.size_threshold<min(surf.net(:))
                EC.edg.size_threshold=min(surf.net(:));
            end
            set(handles.EdgST_slider,'Max',max(surf.net(:)));
            set(handles.EdgST_slider,'Min',min(surf.net(:))-0.001);
            set(handles.EdgST_slider,'Value',EC.edg.size_threshold);
            set(handles.EdgST_edit,'String',num2str(EC.edg.size_threshold,'%f'));
        case 1
            if EC.edg.size_threshold>max(abs(surf.net(:)))||EC.edg.size_threshold<min(abs(surf.net(:)))
                EC.edg.size_threshold=min(abs(surf.net(:)));
            end
            set(handles.EdgST_slider,'Max',max(abs(surf.net(:))));
            set(handles.EdgST_slider,'Min',min(abs(surf.net(:)))-0.001);
            set(handles.EdgST_slider,'Value',EC.edg.size_threshold);
            set(handles.EdgST_edit,'String',num2str(EC.edg.size_threshold,'%f'));
    end
    set(handles.EdgSRR_slider,'Value',EC.edg.size_ratio);
    set(handles.EdgSRR_edit,'String',num2str(EC.edg.size_ratio,'%f'));
    switch EC.edg.color % Modified by Mingrui, 20170303, fixed range of color mapping
        case 1
            set(handles.EdgCS_radiobutton,'Value',1);
            set(handles.EdgCS_pushbutton,'BackgroundColor',EC.edg.CM(1,:));
            set(handles.EdgCC_popupmenu,'Enable','off');
            set(handles.EdgCT_slider,'Enable','off');
            set(handles.EdgCT_edit,'Enable','off');
            set(handles.EdgCD_slider,'Enable','off');
            set(handles.EdgCD_edit,'Enable','off');
            set(handles.EdgColorCostum_pushbutton,'Enable','off');
            set(handles.EdgCC_Range_popupmenu,'Enable','off');
            set(handles.EdgCC_low_edit,'Enable','off');
            set(handles.EdgCC_high_edit,'Enable','off');
        case 2
            set(handles.EdgCC_radiobutton,'Value',1);
            set(handles.EdgCC_popupmenu,'Enable','on');
            set(handles.EdgCT_slider,'Enable','off');
            set(handles.EdgCT_edit,'Enable','off');
            set(handles.EdgCD_slider,'Enable','off');
            set(handles.EdgCD_edit,'Enable','off');
            set(handles.EdgColorCostum_pushbutton,'Enable','off');
            set(handles.EdgCC_Range_popupmenu,'Enable','on');
            if EC.edg.color_map_type == 1
                set(handles.EdgCC_low_edit,'Enable','off');
                set(handles.EdgCC_high_edit,'Enable','off');
            else
                set(handles.NodCC_low_edit,'Enable','on');
                set(handles.NodCC_high_edit,'Enable','on');
            end
        case 3
            set(handles.EdgCT_radiobutton,'Value',1);
            set(handles.EdgCC_popupmenu,'Enable','off');
            set(handles.EdgCT_slider,'Enable','on');
            set(handles.EdgCT_edit,'Enable','on');
            set(handles.EdgCT_slider,'Value',EC.edg.color_threshold);
            set(handles.EdgCT_edit,'String',num2str(EC.edg.color_threshold,'%f'));
            set(handles.EdgCTH_pushbutton,'BackgroundColor',EC.edg.CM(1,:));
            set(handles.EdgCTL_pushbutton,'BackgroundColor',EC.edg.CM(64,:));
            set(handles.EdgCD_slider,'Enable','off');
            set(handles.EdgCD_edit,'Enable','off');
            set(handles.EdgColorCostum_pushbutton,'Enable','off');
            set(handles.EdgCC_Range_popupmenu,'Enable','off');
            set(handles.EdgCC_low_edit,'Enable','off');
            set(handles.EdgCC_high_edit,'Enable','off');
        case 4
            set(handles.EdgCD_radiobutton,'Value',1);
            set(handles.EdgCC_popupmenu,'Enable','off');
            set(handles.EdgCT_slider,'Enable','off');
            set(handles.EdgCT_edit,'Enable','off');
            set(handles.EdgCD_slider,'Enable','on');
            set(handles.EdgCD_edit,'Enable','on');
            set(handles.EdgCDH_pushbutton,'BackgroundColor',EC.edg.CM(1,:));
            set(handles.EdgCDL_pushbutton,'BackgroundColor',EC.edg.CM(64,:));
            set(handles.EdgCD_slider,'Value',EC.edg.color_distance);
            set(handles.EdgCD_edit,'String',num2str(EC.edg.color_distance,'%f'));
            set(handles.EdgColorCostum_pushbutton,'Enable','off');
            set(handles.EdgCC_Range_popupmenu,'Enable','off');
            set(handles.EdgCC_low_edit,'Enable','off');
            set(handles.EdgCC_high_edit,'Enable','off');
        case 5 % Added by Mingrui Xia, 20120809 add edge color according to nodal module
            set(handles.EdgColorModule_radiobutton,'Value',1);
            set(handles.EdgCC_popupmenu,'Enable','off');
            set(handles.EdgCT_slider,'Enable','off');
            set(handles.EdgCT_edit,'Enable','off');
            set(handles.EdgCD_slider,'Enable','off');
            set(handles.EdgCD_edit,'Enable','off');
            set(handles.EdgColorCostum_pushbutton,'Enable','off');
            set(handles.EdgCC_Range_popupmenu,'Enable','off');
            set(handles.EdgCC_low_edit,'Enable','off');
            set(handles.EdgCC_high_edit,'Enable','off');
            
            % Addde by Mingrui, 20150120, using custom matrix to define edge color.
        case 6
            set(handles.EdgColorCostum_radiobutton,'Value',1);
            set(handles.EdgCC_popupmenu,'Enable','off');
            set(handles.EdgCT_slider,'Enable','off');
            set(handles.EdgCT_edit,'Enable','off');
            set(handles.EdgCD_slider,'Enable','off');
            set(handles.EdgCD_edit,'Enable','off');
            set(handles.EdgColorCostum_pushbutton,'Enable','on');
            set(handles.EdgCC_Range_popupmenu,'Enable','off');
            set(handles.EdgCC_low_edit,'Enable','off');
            set(handles.EdgCC_high_edit,'Enable','off');
            
    end
    set(handles.EdgCC_popupmenu,'Value',EC.edg.color_map);
    set(handles.EdgC_checkbox,'Value',EC.edg.color_abs);
    set(handles.EdgCC_Range_popupmenu,'Value',EC.edg.color_map_type);
    set(handles.EdgCC_low_edit,'String',num2str(EC.edg.color_map_low,'%f'));
    set(handles.EdgCC_high_edit,'String',num2str(EC.edg.color_map_high,'%f'));
    
    switch EC.edg.color_abs
        case 0
            if EC.edg.color_threshold>max(surf.net(:))||EC.edg.color_threshold<min(surf.net(:))
                EC.edg.color_threshold=min(surf.net(:));
            end
            set(handles.EdgCT_slider,'Max',max(surf.net(:)));
            set(handles.EdgCT_slider,'Min',min(surf.net(:))-0.001);
            set(handles.EdgCT_slider,'Value',EC.edg.color_threshold);
            set(handles.EdgCT_edit,'String',num2str(EC.edg.color_threshold,'%f'));
        case 1
            if EC.edg.color_threshold>max(abs(surf.net(:)))||EC.edg.color_threshold<min(abs(surf.net(:)))
                EC.edg.color_threshold=min(abs(surf.net(:)));
            end
            set(handles.EdgCT_slider,'Max',max(abs(surf.net(:))));
            set(handles.EdgCT_slider,'Min',min(abs(surf.net(:)))-0.001);
            set(handles.EdgCT_slider,'Value',EC.edg.color_threshold);
            set(handles.EdgCT_edit,'String',num2str(EC.edg.color_threshold,'%f'));
    end
    
    % Added by Mingrui 20150112 support for edge opacity
    switch EC.edg.opacity
        case 1
            set(handles.EdgOpaSam_radiobutton,'Value',1);
            set(handles.EdgOpaSam_edit,'Enable','on');
            set(handles.EdgOpaValMin_edit,'Enable','off');
            set(handles.EdgOpaValMax_edit,'Enable','off');
            set(handles.EdgOpaAbs_checkbox,'Enable','off');
        case 2
            set(handles.EdgOpaVal_radiobutton,'Value',1);
            set(handles.EdgOpaSam_edit,'Enable','off');
            set(handles.EdgOpaValMin_edit,'Enable','on');
            set(handles.EdgOpaValMax_edit,'Enable','on');
            set(handles.EdgOpaAbs_checkbox,'Enable','on');
    end
    set(handles.EdgOpaSam_edit,'String',num2str(EC.edg.opacity_same,'%1.1f'));
    set(handles.EdgOpaValMin_edit,'String',num2str(EC.edg.opacity_min,'%1.1f'));
    set(handles.EdgOpaValMax_edit,'String',num2str(EC.edg.opacity_max,'%1.1f'));
    set(handles.EdgOpaAbs_checkbox,'Value',EC.edg.opacity_abs );
    
else
    set(handles.EdgDA_radiobutton,'Enable','off');
    set(handles.EdgDT_radiobutton,'Enable','off');
    set(handles.EdgDT_slider,'Enable','off');
    set(handles.EdgDT_edit,'Enable','off');
    set(handles.EdgSS_radiobutton,'Enable','off');
    set(handles.EdgSS_edit,'Enable','off');
    set(handles.EdgSV_radiobutton,'Enable','off');
    set(handles.EdgSV_popupmenu,'Enable','off');
    set(handles.EdgST_checkbox,'Enable','off');
    set(handles.EdgST_slider,'Enable','off');
    set(handles.EdgST_edit,'Enable','off');
    set(handles.EdgSRR_slider,'Enable','off');
    set(handles.EdgSRR_edit,'Enable','off');
    set(handles.EdgCS_radiobutton,'Enable','off');
    set(handles.EdgCC_radiobutton,'Enable','off');
    set(handles.EdgCC_popupmenu,'Enable','off');
    set(handles.EdgCT_radiobutton,'Enable','off');
    set(handles.EdgCT_slider,'Enable','off');
    set(handles.EdgCT_edit,'Enable','off');
    set(handles.EdgCD_slider,'Enable','off');
    set(handles.EdgCD_edit,'Enable','off');
    set(handles.EdgDS_slider,'Enable','off');
    set(handles.EdgDS_edit,'Enable','off');
    set(handles.EdgDT_checkbox,'Enable','off');
    set(handles.EdgS_checkbox,'Enable','off');
    set(handles.EdgDDirected_checkbox,'Enable','off'); % Add by Mingrui Xia, 20120621, draw directed network.
    set(handles.EdgDInter_checkbox,'Enable','off');
    set(handles.EdgCD_radiobutton,'Enable','off');
    set(handles.EdgC_checkbox,'Enable','off');
    set(handles.EdgColorModule_radiobutton,'Enable','off');
    set(handles.EdgDS_text,'Enable','off');
    set(handles.EdgSRR_text,'Enable','off');
    set(handles.EdgSizeScaleDiscreption_text,'Enable','off');
    
    set(handles.EdgOpaSam_radiobutton,'Enable','off');
    set(handles.EdgOpaVal_radiobutton,'Enable','off');
    set(handles.EdgOpaSam_edit,'Enable','off');
    set(handles.EdgOpaValMin_edit,'Enable','off');
    set(handles.EdgOpaValMax_edit,'Enable','off');
    set(handles.EdgOpaAbs_checkbox,'Enable','off');
    
    set(handles.EdgColorCostum_radiobutton,'Enable','off');
    set(handles.EdgColorCostum_pushbutton,'Enable','off');
    
    set(handles.NodDrawConnection_radiobutton,'Enable','off');
    set(handles.EdgCC_Range_popupmenu,'Enable','off');
    set(handles.EdgCC_low_edit,'Enable','off');
    set(handles.EdgCC_high_edit,'Enable','off');
end
% if FLAG.Loadfile==9 %%% Edited by Mingrui Xia 20111116, add 11 for volume
% and node mode

% Edited by Mingrui, 20120528, add initial state for ROI draw
if FLAG.Loadfile==9||FLAG.Loadfile==11||FLAG.Loadfile==15 %% Edited by Mingrui Xia, 20120210, add 15 for volume, node and edge mode.
    if FLAG.MAP==2 % if load a nifti
        % Added by Mingrui 20140925, draw cluster in statistical files
        if ~strcmp(surf.test,'No')
            vol_tmp = surf.vol;
            vol_tmp(vol_tmp < EC.vol.threshold & vol_tmp > -EC.vol.threshold) = 0;
            [L, num] = bwlabeln(vol_tmp,EC.vol.rmm);
            vol_tmp2 = zeros(size(vol_tmp));
            n = 0;
            for x = 1:num
                theCurrentCluster = L == x;
                if length(find(theCurrentCluster)) >= EC.vol.clustersize
                    n = n + 1;
                    vol_tmp2(logical(theCurrentCluster)) = n;
                end
            end
            vol_tmp2(vol_tmp2>0) = surf.vol(vol_tmp2>0);
        else
            vol_tmp2 = surf.vol;
        end
        DataLow = min(vol_tmp2(:));
        DataHigh = max(vol_tmp2(:));
        if DataLow == 0
            DataLow = min(vol_tmp2(vol_tmp2 ~= 0));
        end
        set(handles.VolROIRange_text,'String',['ROI Index Range:  ',num2str(DataLow,'%6d'),'   ',num2str(DataHigh,'%6d')]);
        if EC.vol.roi.drawall == 1
            %         EC.vol.roi.draw = unique(surf.vol);
            %         EC.vol.roi.draw(EC.vol.roi.draw == 0) = [];
            set(handles.VolROIDrawAll_checkbox,'Value',1);
            set(handles.VolROICus_text,'Enable','off');
            set(handles.VolROICus_edit,'Enable','off');
            %             if EC.vol.type == 2 %% Edit By Mingrui 20140509, Stop identifying ROIs when initializing option panel
            EC.vol.roi.drawt = unique(vol_tmp2);
            EC.vol.roi.drawt(EC.vol.roi.drawt == 0) = [];
            %             end
            %     else
            %         set(handles.VolROICus_edit,'String',['[',num2str(EC.vol.roi.draw),']']);
        end
        
        % modified by Mingrui 20170609
        if length(EC.vol.roi.drawt) < 2000
            textcell = cell(length(EC.vol.roi.drawt),1);
            
            for i = 1:length(textcell)
                textcell{i} = ['ROI ',num2str(EC.vol.roi.drawt(i))];
            end
        else
            textcell{1} = ['ROI ',num2str(EC.vol.roi.drawt(1))];
        end
        
        set(handles.VolROIColor_popupmenu,'String',textcell);
        set(handles.VolROICus_edit,'String',EC.vol.roi.drawcus);
        
        %     set(handles.VolROIColor_text,'Enable','on');
        %     set(handles.VolROIColor_popupmenu,'Enable','on');
        %     set(handles.VolROIColorSQ_pushbutton,'Enable','on');
        %     set(handles.VolROISmooth_checkbox,'Enable','on');
        set(handles.VolROIColor_popupmenu,'Value',1);
        set(handles.VolROIColorSQ_pushbutton,'BackgroundColor',EC.vol.roi.colort(1,:));
        
        if EC.vol.roi.smooth == 1
            set(handles.VolROISmooth_checkbox,'Value',1);
        end
        set(handles.VolROISmooth_popupmenu,'Value',EC.vol.roi.smooth_kernal);
        
    else % load a text
        DataLow = min(surf.T);
        DataHigh = max(surf.T);
        set(handles.VolVS_radiobutton,'Enable','off');
        set(handles.VolRD_radiobutton,'Enable','off');
        set(handles.VolMapAlgorithm_popupmenu,'Enable','off');
        set(handles.VolMapAlgorithm_text,'Enable','off');
        set(handles.VolROIRange_text,'Enable','off');
        set(handles.VolROIDrawAll_checkbox,'Enable','off');
        set(handles.VolROICus_text,'Enable','off');
        set(handles.VolROICus_edit,'Enable','off');
        set(handles.VolROIColor_text,'Enable','off');
        set(handles.VolROIColor_popupmenu,'Enable','off');
        set(handles.VolROIColorSQ_pushbutton,'Enable','off');
        set(handles.VolROISmooth_checkbox,'Enable','off');
        set(handles.VolROISmooth_popupmenu,'Enable','off');
        
        % Added by Mingrui, 20140923, statistic for SPM or REST nifti files
        set(handles.VolStaThr_edit,'Enable','off');
        set(handles.VolStaThr_text,'Enable','off');
        set(handles.VolStaP_edit,'Enable','off');
        set(handles.VolStaP_text,'Enable','off');
        set(handles.VolStaClu_edit,'Enable','off');
        set(handles.VolStaClu_text,'Enable','off');
        set(handles.VolStaCon_popupmenu,'Enable','off');
        set(handles.VolStaCon_text,'Enable','off');
    end
    
    if strcmp(surf.test,'No')
        set(handles.VolStaP_edit,'Enable','off');
        set(handles.VolStaP_text,'Enable','off');
    end
    
    switch EC.vol.type
        case 1
            set(handles.VolVS_radiobutton,'Value',1);
            set(handles.VolROIRange_text,'Enable','off');
            set(handles.VolROIDrawAll_checkbox,'Enable','off');
            set(handles.VolROICus_text,'Enable','off');
            set(handles.VolROICus_edit,'Enable','off');
            set(handles.VolROIColor_text,'Enable','off');
            set(handles.VolROIColor_popupmenu,'Enable','off');
            set(handles.VolROIColorSQ_pushbutton,'Enable','off');
            set(handles.VolROISmooth_checkbox,'Enable','off');
            set(handles.VolROISmooth_popupmenu,'Enable','off');
        case 2
            set(handles.VolRD_radiobutton,'Value',1);
            set(handles.VolDR_text,'Enable','off');
            set(handles.VolD_text,'Enable','off');
            set(handles.VolD_popupmenu,'Enable','off');
            set(handles.VolNR_text,'Enable','off');
            set(handles.VolNRn_edit,'Enable','off');
            set(handles.VolNRx_edit,'Enable','off');
            set(handles.VolPR_text,'Enable','off');
            set(handles.VolPRn_edit,'Enable','off');
            set(handles.VolPRx_edit,'Enable','off');
            set(handles.VolNC_text,'Enable','off');
            set(handles.VolC_text,'Enable','off');
            set(handles.VolC_popupmenu,'Enable','off');
            set(handles.Vol_AdjustCM_checkbox,'Enable','off');
            set(handles.VolMapAlgorithm_popupmenu,'Enable','off');
            set(handles.VolMapAlgorithm_text,'Enable','off');
            
    end
    set(handles.VolDR_text,'String',['Volume Data Range:  ',num2str(DataLow,'%f'),'   ',num2str(DataHigh,'%f')]);
    if ~isempty(EC.vol.display) % Edited by Mingrui Xia, 20120325, add auto juge volume range.
        switch EC.vol.display
            case 1
                set(handles.VolD_popupmenu,'Value',1);
            case 2
                set(handles.VolD_popupmenu,'Value',2);
                set(handles.VolNR_text,'Enable','off');
                set(handles.VolNRn_edit,'Enable','off');
                set(handles.VolNRx_edit,'Enable','off');
            case 3
                set(handles.VolD_popupmenu,'Value',3);
                set(handles.VolPR_text,'Enable','off');
                set(handles.VolPRn_edit,'Enable','off');
                set(handles.VolPRx_edit,'Enable','off');
        end
        set(handles.VolPRn_edit,'String',num2str(EC.vol.pn,'%f'));
        set(handles.VolPRx_edit,'String',num2str(EC.vol.px,'%f'));
        set(handles.VolNRn_edit,'String',num2str(EC.vol.nn,'%f'));
        set(handles.VolNRx_edit,'String',num2str(EC.vol.nx,'%f'));
    else
        if DataLow * DataHigh < 0
            set(handles.VolD_popupmenu,'Value',1);
            set(handles.VolPRn_edit,'String',num2str(0.01,'%f'));
            set(handles.VolPRx_edit,'String',num2str(DataHigh,'%f'));
            set(handles.VolNRn_edit,'String',num2str(-0.01,'%f'));
            set(handles.VolNRx_edit,'String',num2str(DataLow,'%f'));
        elseif DataLow + DataHigh >= 0
            set(handles.VolD_popupmenu,'Value',2);
            set(handles.VolNR_text,'Enable','off');
            set(handles.VolNRn_edit,'Enable','off');
            set(handles.VolNRx_edit,'Enable','off');
            set(handles.VolPRn_edit,'String',num2str(DataLow,'%f'));
            set(handles.VolPRx_edit,'String',num2str(DataHigh,'%f'));
            set(handles.VolNRn_edit,'String',num2str(-0.01,'%f'));
            set(handles.VolNRx_edit,'String',num2str(-10,'%f'));
        else
            set(handles.VolD_popupmenu,'Value',3);
            set(handles.VolPR_text,'Enable','off');
            set(handles.VolPRn_edit,'Enable','off');
            set(handles.VolPRx_edit,'Enable','off');
            set(handles.VolPRn_edit,'String',num2str(0.01,'%f'));
            set(handles.VolPRx_edit,'String',num2str(10,'%f'));
            set(handles.VolNRn_edit,'String',num2str(DataHigh,'%f'));
            set(handles.VolNRx_edit,'String',num2str(DataLow,'%f'));
        end
    end
    set(handles.VolNCS_pushbutton,'BackgroundColor',EC.vol.null);
    set(handles.VolC_popupmenu,'Value',EC.vol.color_map);
    set(handles.Vol_AdjustCM_checkbox,'Value',EC.vol.adjustCM);
    set(handles.VolMapAlgorithm_popupmenu,'Value',EC.vol.mapalgorithm);
    
    % Added by Mingrui, 20140923, statistic for SPM or REST nifti files
    set(handles.VolStaThr_edit,'String',num2str(EC.vol.threshold));
    set(handles.VolStaP_edit,'String',num2str(EC.vol.p));
    set(handles.VolStaClu_edit,'String',num2str(EC.vol.clustersize));
    switch EC.vol.rmm
        case 6
            set(handles.VolStaCon_popupmenu,'Value',1);
        case 18
            set(handles.VolStaCon_popupmenu,'Value',2);
        case 26
            set(handles.VolStaCon_popupmenu,'Value',3);
    end
else
    set(handles.VolVS_radiobutton,'Enable','off');
    set(handles.VolRD_radiobutton,'Enable','off');
    set(handles.VolDR_text,'Enable','off');
    set(handles.VolD_text,'Enable','off');
    set(handles.VolD_popupmenu,'Enable','off');
    set(handles.VolNR_text,'Enable','off');
    set(handles.VolNRn_edit,'Enable','off');
    set(handles.VolNRx_edit,'Enable','off');
    set(handles.VolPR_text,'Enable','off');
    set(handles.VolPRn_edit,'Enable','off');
    set(handles.VolPRx_edit,'Enable','off');
    set(handles.VolNC_text,'Enable','off');
    set(handles.VolC_text,'Enable','off');
    set(handles.VolC_popupmenu,'Enable','off');
    set(handles.VolROIRange_text,'Enable','off');
    set(handles.VolROIDrawAll_checkbox,'Enable','off');
    set(handles.VolROICus_text,'Enable','off');
    set(handles.VolROICus_edit,'Enable','off');
    set(handles.VolROIColor_text,'Enable','off');
    set(handles.VolROIColor_popupmenu,'Enable','off');
    set(handles.VolROIColorSQ_pushbutton,'Enable','off');
    set(handles.VolROISmooth_checkbox,'Enable','off');
    set(handles.VolROISmooth_popupmenu,'Enable','off');
    set(handles.Vol_AdjustCM_checkbox,'Enable','off');
    set(handles.VolMapAlgorithm_popupmenu,'Enable','off');
    set(handles.VolMapAlgorithm_text,'Enable','off');
    
    % Added by Mingrui, 20140923, statistic for SPM or REST nifti files
    set(handles.VolStaThr_edit,'Enable','off');
    set(handles.VolStaThr_text,'Enable','off');
    set(handles.VolStaP_edit,'Enable','off');
    set(handles.VolStaP_text,'Enable','off');
    set(handles.VolStaClu_edit,'Enable','off');
    set(handles.VolStaClu_text,'Enable','off');
    set(handles.VolStaCon_popupmenu,'Enable','off');
    set(handles.VolStaCon_text,'Enable','off');
end

set(handles.ImgPW_edit,'String',num2str(EC.img.width));
set(handles.ImgPH_edit,'String',num2str(EC.img.height));
set(handles.ImgD_edit,'String',num2str(EC.img.dpi));
set(handles.ImgDW_edit,'String',num2str(EC.img.width/EC.img.dpi*2.54,'%f'));
set(handles.ImgDH_edit,'String',num2str(EC.img.height/EC.img.dpi*2.54,'%f'));
set(handles.ImgDW_popupmenu,'Value',1);
set(handles.ImgDH_popupmenu,'Value',1);
set(handles.ImgC_checkbox,'Value',1);
if FLAG.LF==1
    set(handles.Apply_button,'Enable','on');
end

% UIWAIT makes BrainNet_Option wait for user response (see UIRESUME)
% uiwait(handles.EP_fig);


% --- Outputs from this function are returned to the command line.
function varargout = BrainNet_Option_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in EC_list.
function EC_list_Callback(hObject, eventdata, handles)
% hObject    handle to EC_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns EC_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from EC_list
str = get(hObject, 'string');
n = get(hObject, 'value');
switch str{n}
    case 'Global'
        set(handles.Msh_panel, 'visible','off');
        set(handles.Bak_panel, 'visible','on');
        set(handles.Nod_panel, 'visible','off');
        set(handles.Edg_panel, 'visible','off');
        set(handles.Img_panel, 'visible','off');
        set(handles.Lot_panel,'visible','off');
        set(handles.Vol_panel,'Visible','off');
    case 'Surface'
        set(handles.Bak_panel, 'visible','off');
        set(handles.Msh_panel, 'visible','on');
        set(handles.Nod_panel, 'visible','off');
        set(handles.Edg_panel, 'visible','off');
        set(handles.Img_panel, 'visible','off');
        set(handles.Lot_panel,'visible','off');
        set(handles.Vol_panel,'Visible','off');
    case 'Node'
        set(handles.Nod_panel,'visible','on');
        set(handles.Msh_panel, 'visible','off');
        set(handles.Bak_panel, 'visible','off');
        set(handles.Edg_panel, 'visible','off');
        set(handles.Img_panel, 'visible','off');
        set(handles.Lot_panel,'visible','off');
        set(handles.Vol_panel,'Visible','off');
    case 'Edge'
        set(handles.Nod_panel,'visible','off');
        set(handles.Msh_panel, 'visible','off');
        set(handles.Bak_panel, 'visible','off');
        set(handles.Edg_panel, 'visible','on');
        set(handles.Img_panel, 'visible','off');
        set(handles.Lot_panel,'visible','off');
        set(handles.Vol_panel,'Visible','off');
    case 'Image'
        set(handles.Nod_panel,'visible','off');
        set(handles.Msh_panel, 'visible','off');
        set(handles.Bak_panel, 'visible','off');
        set(handles.Edg_panel, 'visible','off');
        set(handles.Img_panel, 'visible','on');
        set(handles.Lot_panel,'visible','off');
        set(handles.Vol_panel,'Visible','off');
    case 'Layout'
        set(handles.Nod_panel,'visible','off');
        set(handles.Msh_panel, 'visible','off');
        set(handles.Bak_panel, 'visible','off');
        set(handles.Edg_panel, 'visible','off');
        set(handles.Img_panel, 'visible','off');
        set(handles.Lot_panel,'visible','on');
        set(handles.Vol_panel,'Visible','off');
    case 'Volume'
        set(handles.Nod_panel,'visible','off');
        set(handles.Msh_panel, 'visible','off');
        set(handles.Bak_panel, 'visible','off');
        set(handles.Edg_panel, 'visible','off');
        set(handles.Img_panel, 'visible','off');
        set(handles.Lot_panel,'visible','off');
        set(handles.Vol_panel,'Visible','on');
end

% --- Executes during object creation, after setting all properties.
function EC_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EC_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Reset_button.
function Reset_button_Callback(hObject, eventdata, handles)
% hObject    handle to Reset_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Initialization(handles);


% --- Executes on button press in OK_button.
function OK_button_Callback(hObject, eventdata, handles)
% hObject    handle to OK_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global FLAG
GetValue(handles);
if FLAG.LF==1||FLAG.EC_change==1
    FLAG.EC=1;
end
close(findobj('Tag','EP_fig'));


function GetValue(handles)
global EC
global FLAG
FLAG.IsCalledByREST = 0;


if get(handles.LotS_radiobutton,'Value')==1
    EC.lot.view = 1;
elseif get(handles.LotF_radiobutton, 'Value')==1
    EC.lot.view = 2;
elseif get(handles.LotLM_radiobutton,'Value') == 1 %%% Added by Mingrui Xia, 20111026, add for medium views (4 views).
    EC.lot.view = 3;
elseif get(handles.LotLMV_radiobutton,'Value') == 1 % Added by Mingrui Xia, 20130221, add for medium views with ventral.
    EC.lot.view = 4;
    
    % Added by Mingrui, 20170309, add layout for lateral, medial and dorsal view
else
    EC.lot.view = 5;
end

% Edited by Mingrui Xia, 20120806, add custom view for single brain.
if get(handles.LotSS_radiobutton,'Value')==1
    EC.lot.view_direction=1;
    FLAG.sagittal=1;
elseif get(handles.LotSA_radiobutton,'Value')==1
    EC.lot.view_direction=2;
    FLAG.axis=1;
elseif get(handles.LotSC_radiobutton,'Value') == 1
    EC.lot.view_direction=3;
    FLAG.coronal=1;
else
    EC.lot.view_direction = 4;
end
EC.lot.view_az = str2double(get(handles.LotSCusAz_edit,'String'));
EC.lot.view_el = str2double(get(handles.LotSingleCustomEl_edit,'String'));

EC.bak.color=get(handles.BakC_pushbutton,'BackgroundColor');
switch get(handles.GlbM_popupmenu,'Value') % Add by Mingrui Xia, 20120316, modify object material.
    case 1
        EC.glb.material = 'shiny';
    case 2
        EC.glb.material = 'dull';
    case 3
        EC.glb.material = 'metal';
    case 4
        EC.glb.material_ka = get(handles.GlbMa_edit,'String');
        EC.glb.material_kd = get(handles.GlbMd_edit,'String');
        EC.glb.material_ks = get(handles.GlbMs_edit,'String');
        EC.glb.material = ['([',EC.glb.material_ka,' ',EC.glb.material_kd,' ',EC.glb.material_ks,'])'];
end

switch get(handles.GlbS_popupmenu,'Value')
    case 1
        EC.glb.shading = 'flat';
    case 2
        EC.glb.shading = 'faceted';
    case 3
        EC.glb.shading = 'interp';
end

switch get(handles.GlbLA_popupmenu,'Value')
    case 1
        EC.glb.lighting = 'flat';
    case 2
        EC.glb.lighting = 'gouraud';
    case 3
        EC.glb.lighting = 'phong';
    case 4
        EC.glb.lighting = 'none';
end

switch get(handles.GlbLD_popupmenu,'Value')
    case 1
        EC.glb.lightdirection = 'headlight';
    case 2
        EC.glb.lightdirection = 'right';
    case 3
        EC.glb.lightdirection = 'left';
end

switch get(handles.GlbRd_popupmenu,'Value'); % Added by Mingrui Xia, 20120413, selection for rendering methods
    case 1
        EC.glb.render = 'OpenGL';
    case 2
        EC.glb.render = 'zbuffer';
end

EC.glb.detail = get(handles.GlbGD_popupmenu,'Value'); % Add by Mingrui Xia, 20120413, adjust graph detail

% Add by Mingrui, 20170309, display LR
EC.glb.lr = get(handles.GlbLR_checkbox,'Value');

EC.msh.color_type = get(handles.Mesh_color_popupmenu,'Value');
EC.msh.color_table = EC.msh.color_table_tmp;
EC.msh.color=get(handles.MshC_pushbutton,'BackgroundColor');
EC.msh.alpha=str2double(get(handles.MshA_edit,'String'));
EC.msh.doublebrain = get(handles.MshDoubleBrain_checkbox,'Value'); % Added by Mingrui Xia, 20120717, show two brains in one figure

EC.msh.boundary = get(handles.Mesh_boundary_popupmenu,'Value');
switch EC.msh.boundary
    case 3
        EC.msh.boundary_value = str2double(get(handles.Mesh_boundary_edit,'String'));
    case 4
        EC.msh.boundary_value = EC.msh.boundary_value_tmp;
end
EC.msh.boundary_color = get(handles.Mesh_boundary_pushbutton,'BackgroundColor');

if get(handles.NodDA_radiobutton,'Value')==1
    EC.nod.draw=1;
elseif get(handles.NodDT_radiobutton,'Value') == 1
    EC.nod.draw=2;
    EC.nod.draw_threshold_type=get(handles.NodDT_popupmenu,'Value');
    EC.nod.draw_threshold=str2double(get(handles.NodDT_edit,'String'));
else
    EC.nod.draw = 3;
end

if get(handles.NodSS_radiobutton,'Value')==1
    EC.nod.size=1;
    EC.nod.size_size=str2double(get(handles.NodSS_edit,'String'));
elseif get(handles.NodSV_radiobutton,'Value')==1
    if get(handles.NodST_checkbox,'Value')==1
        EC.nod.size=3;
        EC.nod.size_threshold=str2double(get(handles.NodST_edit,'String'));
    else
        EC.nod.size=2;
        EC.nod.size_value=get(handles.NodSV_popupmenu,'Value');
    end
end

EC.nod.size_ratio=str2double(get(handles.NodSVR_edit,'String'));

if get(handles.NodCS_radiobutton,'Value')==1
    EC.nod.color=1;
    EC.nod.CM(1,:)=get(handles.NodCS_pushbutton,'BackgroundColor');
elseif get(handles.NodCC_radiobutton,'Value')==1
    EC.nod.color=2;
    EC.nod.color_map=get(handles.NodCC_popupmenu,'Value');
    switch EC.nod.color_map
        case 1
            EC.nod.CM=jet;
        case 2
            EC.nod.CM=hsv;
        case 3
            EC.nod.CM=hot;
        case 4
            EC.nod.CM=cool;
        case 5
            EC.nod.CM=spring;
        case 6
            EC.nod.CM=summer;
        case 7
            EC.nod.CM=autumn;
        case 8
            EC.nod.CM=winter;
        case 9
            EC.nod.CM=gray;
        case 10
            EC.nod.CM=bone;
        case 11
            EC.nod.CM=copper;
        case 12
            EC.nod.CM=pink;
        case 13
            EC.nod.CM=lines;
        case 14
            EC.nod.CM = EC.nod.CMt;
    end
    EC.nod.color_map_type = get(handles.NodCC_Range_popupmenu,'Value'); % Added by Mingrui, 20170303, fixed range of color mapping
    EC.nod.color_map_low = str2double(get(handles.NodCC_low_edit,'String'));
    EC.nod.color_map_high = str2double(get(handles.NodCC_high_edit,'String'));
elseif get(handles.NodCM_radiobutton,'Value')==1
    EC.nod.color=3;
    %     EC.nod.CM(1:21,:)=EC.nod.CMm;
    %     EC.nod.CM(22,:)=[0.5,0.5,0.5];
    EC.nod.CM = EC.nod.CMm;
else
    EC.nod.color=4;
    EC.nod.color_threshold=str2double(get(handles.NodCT_edit,'String'));
    EC.nod.CM(1,:)=get(handles.NodCTH_pushbutton,'BackgroundColor');
    EC.nod.CM(64,:)=get(handles.NodCTL_pushbutton,'BackgroundColor');
end
if get(handles.LblA_radiobutton,'Value')==1
    EC.lbl=1;
elseif get(handles.LblN_radiobutton,'Value')==1
    EC.lbl=2;
else
    EC.lbl=3;
    EC.lbl_threshold=str2double(get(handles.LblT_edit,'String'));
    EC.lbl_threshold_type=get(handles.LblT_popupmenu,'Value');
end

EC.lbl_front = get(handles.Lbl_front_checkbox,'Value');

if get(handles.EdgDA_radiobutton,'Value')==1
    EC.edg.draw=1;
else
    EC.edg.draw=2;
    EC.edg.draw_threshold=str2double(get(handles.EdgDT_edit,'String'));
    EC.edg.draw_abs=get(handles.EdgDT_checkbox,'Value');
end
EC.edg.interhemiedges = get(handles.EdgDInter_checkbox,'Value'); % Add by Mingrui Xia, 20120109, draw inter hemisphere edges.
EC.edg.directed = get(handles.EdgDDirected_checkbox,'Value'); % Added by Mingrui Xia, 20120621, draw directed network.
if get(handles.EdgSS_radiobutton,'Value')==1
    EC.edg.size=1;
    EC.edg.size_size=str2double(get(handles.EdgSS_edit,'String'));
elseif get(handles.EdgSV_radiobutton,'Value')==1
    if get(handles.EdgST_checkbox,'Value')==1
        EC.edg.size=3;
        EC.edg.size_threshold=str2double(get(handles.EdgST_edit,'String'));
        EC.edg.size_value=get(handles.EdgSV_popupmenu,'Value');
    else
        EC.edg.size=2;
        EC.edg.size_value=get(handles.EdgSV_popupmenu,'Value');
    end
end
EC.edg.size_ratio=str2double(get(handles.EdgSRR_edit,'String'));
EC.edg.size_abs=get(handles.EdgS_checkbox,'Value');
EC.edg.color_abs=get(handles.EdgC_checkbox,'Value');
if get(handles.EdgCS_radiobutton,'Value')==1
    EC.edg.color=1;
    EC.edg.CM(1,:)=get(handles.EdgCS_pushbutton,'BackgroundColor');
elseif get(handles.EdgCC_radiobutton,'Value')==1
    EC.edg.color=2;
    EC.edg.color_map=get(handles.EdgCC_popupmenu,'Value');
    switch EC.edg.color_map
        case 1
            EC.edg.CM=jet;
            % EC.edg.CM = [repmat([51,181,229],21,1);repmat([255,187,51],21,1);repmat([255,68,68],22,1)]/255;
            %                         EC.edg.CM = [linspace(255,255,64);...
            %                             linspace(255,0,64);linspace(255,0,64)]'/255;
        case 2
            EC.edg.CM=hsv;
        case 3
            EC.edg.CM=hot;
        case 4
            EC.edg.CM=cool;
        case 5
            EC.edg.CM=spring;
        case 6
            EC.edg.CM=summer;
        case 7
            EC.edg.CM=autumn;
        case 8
            EC.edg.CM=winter;
        case 9
            EC.edg.CM=gray;
        case 10
            EC.edg.CM=bone;
        case 11
            EC.edg.CM=copper;
        case 12
            EC.edg.CM=pink;
        case 13
            EC.edg.CM=lines;
        case 14
            EC.edg.CM = EC.edg.CMt;
    end
    EC.edg.color_map_type = get(handles.EdgCC_Range_popupmenu,'Value'); % Added by Mingrui, 20170303, fixed range of color mapping
    EC.edg.color_map_low = str2double(get(handles.EdgCC_low_edit,'String'));
    EC.edg.color_map_high = str2double(get(handles.EdgCC_high_edit,'String'));
elseif get(handles.EdgCT_radiobutton,'Value')==1
    EC.edg.color=3;
    EC.edg.color_threshold=str2double(get(handles.EdgCT_edit,'String'));
    EC.edg.CM(1,:)=get(handles.EdgCTH_pushbutton,'BackgroundColor');
    EC.edg.CM(64,:)=get(handles.EdgCTL_pushbutton,'BackgroundColor');
elseif get(handles.EdgCD_radiobutton,'Value') == 1
    EC.edg.color=4;
    EC.edg.color_distance=str2double(get(handles.EdgCD_edit,'String'));
    EC.edg.CM(1,:)=get(handles.EdgCDH_pushbutton,'BackgroundColor');
    EC.edg.CM(64,:)=get(handles.EdgCDL_pushbutton,'BackgroundColor');
elseif get(handles.EdgColorModule_radiobutton,'Value') == 1 % Added by Mingrui Xia, 20120809 add edge color according to nodal module
    EC.edg.color = 5;
    EC.edg.CM = EC.nod.CM;
    EC.edg.CM(end,:) = 0.5;
else
    EC.edg.color = 6;
    EC.edg.CM = EC.edg.CM_custom;
    %             EC.edg.CM = jet;
end

% Added by Mingrui, 20150114, support edge opacity
if get(handles.EdgOpaSam_radiobutton,'Value')==1
    EC.edg.opacity = 1;
else
    EC.edg.opacity = 2;
end
EC.edg.opacity_same = str2double(get(handles.EdgOpaSam_edit,'String'));
EC.edg.opacity_max = str2double(get(handles.EdgOpaValMax_edit,'String'));
EC.edg.opacity_min = str2double(get(handles.EdgOpaValMin_edit,'String'));
EC.edg.opacity_abs = get(handles.EdgOpaAbs_checkbox,'Value');

EC.vol.display=get(handles.VolD_popupmenu,'Value');
EC.vol.pn=str2double(get(handles.VolPRn_edit,'String'));
EC.vol.px=str2double(get(handles.VolPRx_edit,'String'));
EC.vol.nn=str2double(get(handles.VolNRn_edit,'String'));
EC.vol.nx=str2double(get(handles.VolNRx_edit,'String'));
EC.vol.null=get(handles.VolNCS_pushbutton,'BackgroundColor');
EC.vol.color_map=get(handles.VolC_popupmenu,'Value');
EC.vol.adjustCM = get(handles.Vol_AdjustCM_checkbox,'Value');

% Added by Mingrui Xia, 20120726, selection for different mapping algorithm.
EC.vol.mapalgorithm = get(handles.VolMapAlgorithm_popupmenu,'Value');

% Added by Mingrui, 20120529, ROI draw
if get(handles.VolVS_radiobutton,'Value') == 1
    EC.vol.type = 1;
else
    EC.vol.type = 2;
end
EC.vol.roi.drawall = get(handles.VolROIDrawAll_checkbox,'Value');
EC.vol.roi.draw = EC.vol.roi.drawt;
EC.vol.roi.color = EC.vol.roi.colort;
EC.vol.roi.smooth = get(handles.VolROISmooth_checkbox,'Value');
EC.vol.roi.smooth_kernal = get(handles.VolROISmooth_popupmenu,'Value');

% Added by Mingrui, 20140923, statistic for SPM or REST nifti files
EC.vol.threshold = str2double(get(handles.VolStaThr_edit,'String'));
EC.vol.p = str2double(get(handles.VolStaP_edit,'String'));
EC.vol.clustersize = str2double(get(handles.VolStaClu_edit,'String'));
switch get(handles.VolStaCon_popupmenu,'Value')
    case 1
        EC.vol.rmm = 6;
    case 2
        EC.vol.rmm = 18;
    case 3
        EC.vol.rmm = 26;
end

EC.img.width=str2double(get(handles.ImgPW_edit,'String'));
EC.img.height=str2double(get(handles.ImgPH_edit,'String'));
EC.img.dpi=str2double(get(handles.ImgD_edit,'String'));
% --- Executes on button press in Cancel_button.
function Cancel_button_Callback(hObject, eventdata, handles)
% hObject    handle to Cancel_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global FLAG
FLAG.EC=0;
close(findobj('Tag','EP_fig'));

% --- Executes on slider movement.
function MshA_slider_Callback(hObject, eventdata, handles)
% hObject    handle to MshA_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = get(handles.MshA_slider, 'value');
set(handles.MshA_edit, 'string', num2str(val,'%f'));
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function MshA_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MshA_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function MshA_edit_Callback(hObject, eventdata, handles)
% hObject    handle to MshA_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MshA_edit as text
%        str2double(get(hObject,'String')) returns contents of MshA_edit as a double
val=str2double(get(handles.MshA_edit,'String'));
set(handles.MshA_slider,'Value',val);
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function MshA_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MshA_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in NodCC_popupmenu.
function NodCC_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to NodCC_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns NodCC_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from NodCC_popupmenu
ChangeFlag(handles);
global EC
if get(hObject, 'Value') == 14
    prompt = {'Node mapping colorbar: Please input a n*3 matrix.'};
    def = {EC.nod.cmstring};
    answer = inputdlg(prompt,'Custome colorbar defination',1,def);
    if ~isempty(answer)
        EC.nod.cmstring = answer{1};
    end
    tmp = eval([EC.nod.cmstring,';']);
    if size(tmp,2)~=3
        msgbox({'The colorbar inputed has wrong dimension.'},'Error','error');
        tmp = EC.nod.CMt;
    elseif max(tmp(:))>1 || min(tmp(:))<0
        msgbox({['The colorbar inputed exceed range (0-1).','The colorbar is auto arranged']},'Error','error');
        tmp = tmp/255;
        tmp(tmp<0) = 0;
    end
    EC.nod.CMt = tmp;
end


% --- Executes during object creation, after setting all properties.
function NodCC_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NodCC_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in NodCM_pushbutton.
function NodCM_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to NodCM_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
H=BrainNet_ModuleColor;
ChangeFlag(handles);



% --- Executes on slider movement.
function NodCT_slider_Callback(hObject, eventdata, handles)
% hObject    handle to NodCT_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = get(handles.NodCT_slider, 'value');
set(handles.NodCT_edit, 'string', num2str(val,'%f'));
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function NodCT_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NodCT_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function NodCT_edit_Callback(hObject, eventdata, handles)
% hObject    handle to NodCT_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NodCT_edit as text
%        str2double(get(hObject,'String')) returns contents of NodCT_edit as a double
val=str2double(get(handles.NodCT_edit,'String'));
set(handles.NodCT_slider,'Value',val);
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function NodCT_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NodCT_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function NodST_slider_Callback(hObject, eventdata, handles)
% hObject    handle to NodST_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = get(handles.NodST_slider, 'value');
set(handles.NodST_edit, 'string', num2str(val,'%f'));
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function NodST_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NodST_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function NodST_edit_Callback(hObject, eventdata, handles)
% hObject    handle to NodST_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NodST_edit as text
%        str2double(get(hObject,'String')) returns contents of NodST_edit as a double
val=str2double(get(handles.NodST_edit,'String'));
set(handles.NodST_slider,'Value',val);
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function NodST_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NodST_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function NodSVR_slider_Callback(hObject, eventdata, handles)
% hObject    handle to NodSVR_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = get(handles.NodSVR_slider, 'value');
set(handles.NodSVR_edit, 'string', num2str(val,'%f'));
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function NodSVR_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NodSVR_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function NodSVR_edit_Callback(hObject, eventdata, handles)
% hObject    handle to NodSVR_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NodSVR_edit as text
%        str2double(get(hObject,'String')) returns contents of NodSVR_edit as a double
val=str2double(get(handles.NodSVR_edit,'String'));
set(handles.NodSVR_slider,'Value',val);
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function NodSVR_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NodSVR_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function NodSS_edit_Callback(hObject, eventdata, handles)
% hObject    handle to NodSS_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NodSS_edit as text
%        str2double(get(hObject,'String')) returns contents of NodSS_edit as a double
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function NodSS_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NodSS_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in NodSV_popupmenu.
function NodSV_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to NodSV_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns NodSV_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from NodSV_popupmenu
% global surf
% if get(handles.NodSV_popupmenu,'Value')==2
%     if min(surf.sphere(:,5))<1||max(surf.sphere(:,5))>10
%         msgbox('The size inputed may exceed the proper range, and will be adjusted!','Warning','warn');
%     end
% end
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function NodSV_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NodSV_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function NodDT_slider_Callback(hObject, eventdata, handles)
% hObject    handle to NodDT_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = get(handles.NodDT_slider, 'value');
set(handles.NodDT_edit, 'string', num2str(val,'%f'));
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function NodDT_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NodDT_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function NodDT_edit_Callback(hObject, eventdata, handles)
% hObject    handle to NodDT_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NodDT_edit as text
%        str2double(get(hObject,'String')) returns contents of NodDT_edit as a double
val=str2double(get(handles.NodDT_edit,'String'));
set(handles.NodDT_slider,'Value',val);
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function NodDT_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NodDT_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in NodDT_popupmenu.
function NodDT_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to NodDT_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns NodDT_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from NodDT_popupmenu
global EC
global surf
str = get(hObject, 'string');
n = get(hObject, 'value');
switch str{n}
    case 'Size'
        if EC.nod.draw_threshold>max(surf.sphere(:,5))||EC.nod.draw_threshold<min(surf.sphere(:,5))
            EC.nod.draw_threshold=min(surf.sphere(:,5));
        end
        set(handles.NodDT_slider,'Max',max(surf.sphere(:,5)));
        set(handles.NodDT_slider,'Min',min(surf.sphere(:,5)));
        set(handles.NodDT_slider,'Value',EC.nod.draw_threshold);
        set(handles.NodDT_edit,'String',num2str(EC.nod.draw_threshold,'%f'));
    case 'Color'
        if EC.nod.draw_threshold>max(surf.sphere(:,4))||EC.nod.draw_threshold<min(surf.sphere(:,4))
            EC.nod.draw_threshold=min(surf.sphere(:,4));
        end
        set(handles.NodDT_slider,'Max',max(surf.sphere(:,4)));
        set(handles.NodDT_slider,'Min',min(surf.sphere(:,4)));
        set(handles.NodDT_slider,'Value',EC.nod.draw_threshold);
        set(handles.NodDT_edit,'String',num2str(EC.nod.draw_threshold,'%f'));
end
ChangeFlag(handles);



% --- Executes during object creation, after setting all properties.
function NodDT_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NodDT_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when Lbl_panel is resized.
function Lbl_panel_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to Lbl_panel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in LblA_radiobutton.
function LblA_radiobutton_Callback(hObject, eventdata, handles)
% hObject    handle to LblA_radiobutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of LblA_radiobutton


% --- Executes on button press in LblN_radiobutton.
function LblN_radiobutton_Callback(hObject, eventdata, handles)
% hObject    handle to LblN_radiobutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of LblN_radiobutton


% --- Executes on button press in LblT_radiobutton.
function LblT_radiobutton_Callback(hObject, eventdata, handles)
% hObject    handle to LblT_radiobutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of LblT_radiobutton


% --- Executes on slider movement.
function LblT_slider_Callback(hObject, eventdata, handles)
% hObject    handle to LblT_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = get(handles.LblT_slider, 'value');
set(handles.LblT_edit, 'string', num2str(val,'%f'));
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function LblT_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LblT_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function LblT_edit_Callback(hObject, eventdata, handles)
% hObject    handle to LblT_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LblT_edit as text
%        str2double(get(hObject,'String')) returns contents of LblT_edit as a double
val=str2double(get(handles.LblT_edit,'String'));
set(handles.LblT_slider,'Value',val);
ChangeFlag(handles);



% --- Executes during object creation, after setting all properties.
function LblT_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LblT_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in LblT_popupmenu.
function LblT_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to LblT_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns LblT_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from LblT_popupmenu
global EC
global surf
str = get(hObject, 'string');
n = get(hObject, 'value');
switch str{n}
    case 'Size'
        if EC.lbl_threshold>max(surf.sphere(:,5))||EC.lbl_threshold<min(surf.sphere(:,5))
            EC.lbl_threshold=min(surf.sphere(:,5));
        end
        set(handles.LblT_slider,'Max',max(surf.sphere(:,5)));
        set(handles.LblT_slider,'Min',min(surf.sphere(:,5)));
        set(handles.LblT_slider,'Value',EC.lbl_threshold);
        set(handles.LblT_edit,'String',num2str(EC.lbl_threshold,'%f'));
    case 'Color'
        if EC.lbl_threshold>max(surf.sphere(:,4))||EC.lbl_threshold<min(surf.sphere(:,4))
            EC.lbl_threshold=min(surf.sphere(:,4));
        end
        set(handles.LblT_slider,'Max',max(surf.sphere(:,4)));
        set(handles.LblT_slider,'Min',min(surf.sphere(:,4)));
        set(handles.LblT_slider,'Value',EC.lbl_threshold);
        set(handles.LblT_edit,'String',num2str(EC.lbl_threshold,'%f'));
end
ChangeFlag(handles);



% --- Executes during object creation, after setting all properties.
function LblT_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LblT_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in EdgCC_popupmenu.
function EdgCC_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to EdgCC_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns EdgCC_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from EdgCC_popupmenu
ChangeFlag(handles);
global EC
if get(hObject, 'Value') == 14
    prompt = {'Edge mapping colorbar: Please input a n*3 matrix.'};
    def = {EC.edg.cmstring};
    answer = inputdlg(prompt,'Custome colorbar defination',1,def);
    if ~isempty(answer)
        EC.edg.cmstring = answer{1};
    end
    tmp = eval([EC.edg.cmstring,';']);
    if size(tmp,2)~=3
        msgbox({'The colorbar inputed has wrong dimension.'},'Error','error');
        tmp = EC.edg.CMt;
    elseif max(tmp(:))>1 || min(tmp(:))<0
        msgbox({['The colorbar inputed exceed range (0-1).','The colorbar is auto arranged']},'Error','error');
        tmp = tmp/255;
        tmp(tmp<0) = 0;
    end
    EC.edg.CMt = tmp;
end


% --- Executes during object creation, after setting all properties.
function EdgCC_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgCC_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function EdgCT_slider_Callback(hObject, eventdata, handles)
% hObject    handle to EdgCT_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = get(handles.EdgCT_slider, 'value');
set(handles.EdgCT_edit, 'string', num2str(val,'%f'));
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function EdgCT_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgCT_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function EdgCT_edit_Callback(hObject, eventdata, handles)
% hObject    handle to EdgCT_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EdgCT_edit as text
%        str2double(get(hObject,'String')) returns contents of EdgCT_edit as a double
val=str2double(get(handles.EdgCT_edit,'String'));
set(handles.EdgCT_slider,'Value',val);
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function EdgCT_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgCT_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function EdgST_slider_Callback(hObject, eventdata, handles)
% hObject    handle to EdgST_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = get(handles.EdgST_slider, 'value');
set(handles.EdgST_edit, 'string', num2str(val,'%f'));
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function EdgST_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgST_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function EdgST_edit_Callback(hObject, eventdata, handles)
% hObject    handle to EdgST_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EdgST_edit as text
%        str2double(get(hObject,'String')) returns contents of EdgST_edit as a double
val=str2double(get(handles.EdgST_edit,'String'));
set(handles.EdgST_slider,'Value',val);
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function EdgST_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgST_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EdgSRR_edit_Callback(hObject, eventdata, handles)
% hObject    handle to EdgSRR_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EdgSRR_edit as text
%        str2double(get(hObject,'String')) returns contents of EdgSRR_edit as a double
val=str2double(get(handles.EdgSRR_edit,'String'));
set(handles.EdgSRR_slider,'Value',val);
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function EdgSRR_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgSRR_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EdgSS_edit_Callback(hObject, eventdata, handles)
% hObject    handle to EdgSS_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EdgSS_edit as text
%        str2double(get(hObject,'String')) returns contents of EdgSS_edit as a double
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function EdgSS_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgSS_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in EdgSV_popupmenu.
function EdgSV_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to EdgSV_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns EdgSV_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from EdgSV_popupmenu
% global surf
% if get(handles.EdgSV_popupmenu,'Value')==2
%     if min(surf.net(:))<0.2||max(surf.net(:))>3
%         msgbox('The size inputed may exceed the proper range, and will be adjusted!','Warning','warn');
%     end
% end
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function EdgSV_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgSV_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function EdgSRR_slider_Callback(hObject, eventdata, handles)
% hObject    handle to EdgSRR_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = get(handles.EdgSRR_slider, 'value');
set(handles.EdgSRR_edit, 'string', num2str(val,'%f'));
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function EdgSRR_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgSRR_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function EdgDT_slider_Callback(hObject, eventdata, handles)
% hObject    handle to EdgDT_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global surf
val = get(handles.EdgDT_slider, 'value');
set(handles.EdgDT_edit, 'string', num2str(val,'%f'));
switch get(handles.EdgDT_checkbox,'Value')
    case 0
        set(handles.EdgDS_slider,'Value',length(find(surf.net>val))/(size(surf.net,1)*size(surf.net,2)));
        set(handles.EdgDS_edit,'String',num2str(length(find(surf.net>val))/(size(surf.net,1)*size(surf.net,2)),'%f'));
    case 1
        set(handles.EdgDS_slider,'Value',length(find(abs(surf.net)>val))/(size(surf.net,1)*size(surf.net,2)));
        set(handles.EdgDS_edit,'String',num2str(length(find(abs(surf.net)>val))/(size(surf.net,1)*size(surf.net,2)),'%f'));
end
ChangeFlag(handles);



% --- Executes during object creation, after setting all properties.
function EdgDT_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgDT_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function EdgDT_edit_Callback(hObject, eventdata, handles)
% hObject    handle to EdgDT_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EdgDT_edit as text
%        str2double(get(hObject,'String')) returns contents of EdgDT_edit as a double
global surf
global EC %%% Added by Mingrui Xia, 20111130, fix a bug that an error occurs when enter in the edge thershold edit box
val=str2double(get(handles.EdgDT_edit,'String'));
set(handles.EdgDT_slider,'Value',val);
switch get(handles.EdgDT_checkbox,'Value')
    case 0
        set(handles.EdgDS_slider,'Value',length(find(surf.net>EC.edg.draw_threshold))/(size(surf.net,1)*size(surf.net,2)));
        set(handles.EdgDS_edit,'String',num2str(length(find(surf.net>EC.edg.draw_threshold))/(size(surf.net,1)*size(surf.net,2)),'%f'));
    case 1
        set(handles.EdgDS_slider,'Value',length(find(abs(surf.net)>val))/(size(surf.net,1)*size(surf.net,2)));
        set(handles.EdgDS_edit,'String',num2str(length(find(abs(surf.net)>val))/(size(surf.net,1)*size(surf.net,2)),'%f'));
end
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function EdgDT_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgDT_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in EdgDT_popupmenu.
function EdgDT_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to EdgDT_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns EdgDT_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from EdgDT_popupmenu


% --- Executes during object creation, after setting all properties.
function EdgDT_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgDT_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ImgPW_edit_Callback(hObject, eventdata, handles)
% hObject    handle to ImgPW_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ImgPW_edit as text
%        str2double(get(hObject,'String')) returns contents of ImgPW_edit as a double
global EC
switch get(handles.ImgDW_popupmenu,'Value')
    case 1
        set(handles.ImgDW_edit,'String',num2str(str2double(get(handles.ImgPW_edit,'String'))/str2double(get(handles.ImgD_edit,'String'))*2.54,'%f'));
    case 2
        set(handles.ImgDW_edit,'String',num2str(str2double(get(handles.ImgPW_edit,'String'))/str2double(get(handles.ImgD_edit,'String')),'%f'));
end
if get(handles.ImgC_checkbox,'Value')==1
    set(handles.ImgPH_edit,'String',num2str(str2double(get(handles.ImgPW_edit,'String'))*EC.img.height/EC.img.width,'%5d'));
    set(handles.ImgDH_edit,'String',num2str(str2double(get(handles.ImgDW_edit,'String'))*EC.img.height/EC.img.width,'%f'));
end


% --- Executes during object creation, after setting all properties.
function ImgPW_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ImgPW_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ImgPH_edit_Callback(hObject, eventdata, handles)
% hObject    handle to ImgPH_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ImgPH_edit as text
%        str2double(get(hObject,'String')) returns contents of ImgPH_edit as a double
global EC
switch get(handles.ImgDW_popupmenu,'Value')
    case 1
        set(handles.ImgDH_edit,'String',num2str(str2double(get(handles.ImgPH_edit,'String'))/str2double(get(handles.ImgD_edit,'String'))*2.54,'%f'));
    case 2
        set(handles.ImgDH_edit,'String',num2str(str2double(get(handles.ImgPH_edit,'String'))/str2double(get(handles.ImgD_edit,'String')),'%f'));
end
if get(handles.ImgC_checkbox,'Value')==1
    set(handles.ImgPW_edit,'String',num2str(str2double(get(handles.ImgPH_edit,'String'))*EC.img.width/EC.img.height,'%5d'));
    set(handles.ImgDW_edit,'String',num2str(str2double(get(handles.ImgDH_edit,'String'))*EC.img.width/EC.img.height,'%f'));
end


% --- Executes during object creation, after setting all properties.
function ImgPH_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ImgPH_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ImgD_edit_Callback(hObject, eventdata, handles)
% hObject    handle to ImgD_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ImgD_edit as text
%        str2double(get(hObject,'String')) returns contents of ImgD_edit as a double
switch get(handles.ImgDW_popupmenu,'Value')
    case 1
        set(handles.ImgPW_edit,'String',num2str(str2double(get(handles.ImgDW_edit,'String'))*str2double(get(handles.ImgD_edit,'String'))/2.54,'%5.0f'));
        set(handles.ImgPH_edit,'String',num2str(str2double(get(handles.ImgDH_edit,'String'))*str2double(get(handles.ImgD_edit,'String'))/2.54,'%5.0f'));
    case 2
        set(handles.ImgPW_edit,'String',num2str(str2double(get(handles.ImgDW_edit,'String'))*str2double(get(handles.ImgD_edit,'String')),'%5.0f'));
        set(handles.ImgPH_edit,'String',num2str(str2double(get(handles.ImgDH_edit,'String'))*str2double(get(handles.ImgD_edit,'String')),'%5.0f'));
end




% --- Executes during object creation, after setting all properties.
function ImgD_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ImgD_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over BakC_pushbutton.
function BakC_pushbutton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to BakC_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.BakC_pushbutton,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over MshC_pushbutton.
function MshC_pushbutton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to MshC_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.MshC_pushbutton,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- Executes when selected object is changed in NodD_panel.
function NodD_panel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in NodD_panel
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
if get(handles.NodDT_radiobutton,'Value')==1
    set(handles.NodDT_slider,'Enable','on');
    set(handles.NodDT_edit,'Enable','on');
    set(handles.NodDT_popupmenu,'Enable','on');
else
    set(handles.NodDT_slider,'Enable','off');
    set(handles.NodDT_edit,'Enable','off');
    set(handles.NodDT_popupmenu,'Enable','off');
end
ChangeFlag(handles);


% --- Executes when selected object is changed in NodS_panel.
function NodS_panel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in NodS_panel
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
if get(handles.NodSS_radiobutton,'Value')==1
    set(handles.NodSS_edit,'Enable','on');
    set(handles.NodSV_popupmenu,'Enable','off');
    set(handles.NodST_slider,'Enable','off');
    set(handles.NodST_edit,'Enable','off');
    set(handles.NodST_checkbox,'Enable','off');
elseif get(handles.NodSV_radiobutton,'Value')==1
    set(handles.NodSS_edit,'Enable','off');
    set(handles.NodSV_popupmenu,'Enable','on');
    set(handles.NodST_checkbox,'Enable','on');
    if get(handles.NodST_checkbox,'Value')==1
        set(handles.NodST_slider,'Enable','on');
        set(handles.NodST_edit,'Enable','on');
    else
        set(handles.NodST_slider,'Enable','off');
        set(handles.NodST_edit,'Enable','off');
    end
end
ChangeFlag(handles);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over NodCS_pushbutton.
function NodCS_pushbutton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to NodCS_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.NodCS_pushbutton,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- Executes when selected object is changed in NodC_panel.
function NodC_panel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in NodC_panel
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
if get(handles.NodCS_radiobutton,'Value')==1
    set(handles.NodCC_popupmenu,'Enable','off');
    set(handles.NodCM_pushbutton,'Enable','off');
    set(handles.NodCT_slider,'Enable','off');
    set(handles.NodCT_edit,'Enable','off');
    set(handles.NodCC_Range_popupmenu,'Enable','off');
    set(handles.NodCC_low_edit,'Enable','off');
    set(handles.NodCC_high_edit,'Enable','off');
elseif get(handles.NodCC_radiobutton,'Value')==1
    set(handles.NodCC_popupmenu,'Enable','on');
    set(handles.NodCM_pushbutton,'Enable','off');
    set(handles.NodCT_slider,'Enable','off');
    set(handles.NodCT_edit,'Enable','off');
    set(handles.NodCC_Range_popupmenu,'Enable','on');
    if get(handles.NodCC_Range_popupmenu,'Value')==1
        set(handles.NodCC_low_edit,'Enable','off');
        set(handles.NodCC_high_edit,'Enable','off');
    else
        set(handles.NodCC_low_edit,'Enable','on');
        set(handles.NodCC_high_edit,'Enable','on');
    end
    
    
elseif get(handles.NodCM_radiobutton,'Value')==1
    set(handles.NodCC_popupmenu,'Enable','off');
    set(handles.NodCM_pushbutton,'Enable','on');
    set(handles.NodCT_slider,'Enable','off');
    set(handles.NodCT_edit,'Enable','off');
    set(handles.NodCC_Range_popupmenu,'Enable','off');
    set(handles.NodCC_low_edit,'Enable','off');
    set(handles.NodCC_high_edit,'Enable','off');
else
    set(handles.NodCC_popupmenu,'Enable','off');
    set(handles.NodCM_pushbutton,'Enable','off');
    set(handles.NodCT_slider,'Enable','on');
    set(handles.NodCT_edit,'Enable','on');
    set(handles.NodCC_Range_popupmenu,'Enable','off');
    set(handles.NodCC_low_edit,'Enable','off');
    set(handles.NodCC_high_edit,'Enable','off');
end
ChangeFlag(handles);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over NodCTH_pushbutton.
function NodCTH_pushbutton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to NodCTH_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.NodCTH_pushbutton,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over NodCTL_pushbutton.
function NodCTL_pushbutton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to NodCTL_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.NodCTL_pushbutton,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- Executes when selected object is changed in Lbl_panel.
function Lbl_panel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in Lbl_panel
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
if get(handles.LblA_radiobutton,'Value')==1||get(handles.LblN_radiobutton,'Value')==1
    set(handles.LblT_slider,'Enable','off');
    set(handles.LblT_edit,'Enable','off');
    set(handles.LblT_popupmenu,'Enable','off');
else
    set(handles.LblT_slider,'Enable','on');
    set(handles.LblT_edit,'Enable','on');
    set(handles.LblT_popupmenu,'Enable','on');
end
ChangeFlag(handles);



% --- Executes when selected object is changed in EdgD_panel.
function EdgD_panel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in EdgD_panel
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
if get(handles.EdgDA_radiobutton,'Value')==1
    set(handles.EdgDT_slider,'Enable','off');
    set(handles.EdgDT_edit,'Enable','off');
    set(handles.EdgDS_slider,'Enable','off');
    set(handles.EdgDS_edit,'Enable','off');
    %     set(handles.EdgDT_checkbox,'Enable','off');
else
    set(handles.EdgDT_slider,'Enable','on');
    set(handles.EdgDT_edit,'Enable','on');
    set(handles.EdgDS_slider,'Enable','on');
    set(handles.EdgDS_edit,'Enable','on');
    %     set(handles.EdgDT_checkbox,'Enable','on');
end
ChangeFlag(handles);



% --- Executes when selected object is changed in EdgS_uipanel.
function EdgS_uipanel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in EdgS_uipanel
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
if get(handles.EdgSS_radiobutton,'Value')==1
    set(handles.EdgSS_edit,'Enable','on');
    set(handles.EdgSV_popupmenu,'Enable','off');
    set(handles.EdgST_slider,'Enable','off');
    set(handles.EdgST_edit,'Enable','off');
    set(handles.EdgST_checkbox,'Enable','off');
elseif get(handles.EdgSV_radiobutton,'Value')==1
    set(handles.EdgSS_edit,'Enable','off');
    set(handles.EdgSV_popupmenu,'Enable','on');
    set(handles.EdgST_checkbox,'Enable','on');
    if get(handles.EdgST_checkbox,'Value')==1
        set(handles.EdgST_slider,'Enable','on');
        set(handles.EdgST_edit,'Enable','on');
    else
        set(handles.EdgST_slider,'Enable','off');
        set(handles.EdgST_edit,'Enable','off');
    end
end
ChangeFlag(handles);


% --- Executes when selected object is changed in EdgC_panel.
function EdgC_panel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in EdgC_panel
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% Edited by Mingrui Xia, 20120809 add edge color according to nodal module
if get(handles.EdgCS_radiobutton,'Value')==1
    set(handles.EdgCC_popupmenu,'Enable','off');
    set(handles.EdgCT_slider,'Enable','off');
    set(handles.EdgCT_edit,'Enable','off');
    set(handles.EdgCD_slider,'Enable','off');
    set(handles.EdgCD_edit,'Enable','off');
    set(handles.EdgColorCostum_pushbutton,'Enable','off');
    set(handles.EdgCC_Range_popupmenu,'Enable','off');
    set(handles.EdgCC_low_edit,'Enable','off');
    set(handles.EdgCC_high_edit,'Enable','off');
elseif get(handles.EdgCC_radiobutton,'Value')==1
    set(handles.EdgCC_popupmenu,'Enable','on');
    set(handles.EdgCT_slider,'Enable','off');
    set(handles.EdgCT_edit,'Enable','off');
    set(handles.EdgCD_slider,'Enable','off');
    set(handles.EdgCD_edit,'Enable','off');
    set(handles.EdgColorCostum_pushbutton,'Enable','off');
    set(handles.EdgCC_Range_popupmenu,'Enable','on');
    if get(handles.EdgCC_Range_popupmenu,'Value')==1
        set(handles.EdgCC_low_edit,'Enable','off');
        set(handles.EdgCC_high_edit,'Enable','off');
    else
        set(handles.EdgCC_low_edit,'Enable','on');
        set(handles.EdgCC_high_edit,'Enable','on');
    end
elseif get(handles.EdgCT_radiobutton,'Value')==1
    set(handles.EdgCC_popupmenu,'Enable','off');
    set(handles.EdgCT_slider,'Enable','on');
    set(handles.EdgCT_edit,'Enable','on');
    set(handles.EdgCD_slider,'Enable','off');
    set(handles.EdgCD_edit,'Enable','off');
    set(handles.EdgColorCostum_pushbutton,'Enable','off');
    set(handles.EdgCC_Range_popupmenu,'Enable','off');
    set(handles.EdgCC_low_edit,'Enable','off');
    set(handles.EdgCC_high_edit,'Enable','off');
elseif get(handles.EdgCD_radiobutton,'Value') == 1
    set(handles.EdgCC_popupmenu,'Enable','off');
    set(handles.EdgCT_slider,'Enable','off');
    set(handles.EdgCT_edit,'Enable','off');
    set(handles.EdgCD_slider,'Enable','on');
    set(handles.EdgCD_edit,'Enable','on');
    set(handles.EdgColorCostum_pushbutton,'Enable','off');
    set(handles.EdgCC_Range_popupmenu,'Enable','off');
    set(handles.EdgCC_low_edit,'Enable','off');
    set(handles.EdgCC_high_edit,'Enable','off');
elseif get(handles.EdgColorModule_radiobutton,'Value') == 1
    set(handles.EdgCC_popupmenu,'Enable','off');
    set(handles.EdgCT_slider,'Enable','off');
    set(handles.EdgCT_edit,'Enable','off');
    set(handles.EdgCD_slider,'Enable','off');
    set(handles.EdgCD_edit,'Enable','off');
    set(handles.EdgColorCostum_pushbutton,'Enable','off');
    set(handles.EdgCC_Range_popupmenu,'Enable','off');
    set(handles.EdgCC_low_edit,'Enable','off');
    set(handles.EdgCC_high_edit,'Enable','off');
else
    set(handles.EdgCC_popupmenu,'Enable','off');
    set(handles.EdgCT_slider,'Enable','off');
    set(handles.EdgCT_edit,'Enable','off');
    set(handles.EdgCD_slider,'Enable','off');
    set(handles.EdgCD_edit,'Enable','off');
    set(handles.EdgColorCostum_pushbutton,'Enable','on');
    set(handles.EdgCC_Range_popupmenu,'Enable','off');
    set(handles.EdgCC_low_edit,'Enable','off');
    set(handles.EdgCC_high_edit,'Enable','off');
end
ChangeFlag(handles);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over EdgCS_pushbutton.
function EdgCS_pushbutton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to EdgCS_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.EdgCS_pushbutton,'BackgroundColor',c);
end
ChangeFlag(handles);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over EdgCTH_pushbutton.
function EdgCTH_pushbutton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to EdgCTH_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.EdgCTH_pushbutton,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over EdgCTL_pushbutton.
function EdgCTL_pushbutton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to EdgCTL_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.EdgCTL_pushbutton,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- Executes on button press in Load_button.
function Load_button_Callback(hObject, eventdata, handles)
% hObject    handle to Load_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename,pathname]=uigetfile({'*.mat','MAT-files (*.mat)'},'Load Configuration');
if isequal(filename,0)||isequal(pathname,0)
    return;
else
    fpath=fullfile(pathname,filename);
    tmp = load(fpath);
    CheckEC(tmp);
    Initialization(handles);
    msgbox('Option Loaded!','Success','help');
end


function CheckEC(tmp)
% Added by Mingrui Xia, 20120810, adapt New version to older configuration
% file
global EC
if isfield(tmp.EC.bak,'color')
    EC.bak.color = tmp.EC.bak.color;
end
if isfield(tmp.EC.msh,'color_type')
    EC.msh.color_type = tmp.EC.msh.color_type;
end
if isfield(tmp.EC.msh,'color_table')
    EC.msh.color_table = tmp.EC.msh.color_table;
end
if isfield(tmp.EC.msh,'color_table_tmp')
    EC.msh.color_table_tmp = tmp.EC.msh.color_table_tmp;
end

if isfield(tmp.EC.msh,'color')
    EC.msh.color = tmp.EC.msh.color;
end
if isfield(tmp.EC.msh,'alpha')
    EC.msh.alpha = tmp.EC.msh.alpha;
end
if isfield(tmp.EC.msh,'doublebrain')
    EC.msh.doublebrain = tmp.EC.msh.doublebrain;
end
if isfield(tmp.EC.msh,'boundary')
    EC.msh.boundary = tmp.EC.msh.boundary;
end
if isfield(tmp.EC.msh,'boundary_value')
    EC.msh.boundary_value = tmp.EC.msh.boundary_value;
end
if isfield(tmp.EC.msh,'boundary_color')
    EC.msh.boundary_color = tmp.EC.msh.boundary_color;
end
if isfield(tmp.EC.nod,'draw')
    EC.nod.draw = tmp.EC.nod.draw;
end
if isfield(tmp.EC.nod,'draw_threshold_type')
    EC.nod.draw_threshold_type = tmp.EC.nod.draw_threshold_type;
end
if isfield(tmp.EC.nod,'draw_threshold')
    EC.nod.draw_threshold = tmp.EC.nod.draw_threshold;
end
if isfield(tmp.EC.nod,'size')
    EC.nod.size = tmp.EC.nod.size;
end
if isfield(tmp.EC.nod,'size_size')
    EC.nod.size_size = tmp.EC.nod.size_size;
end
if isfield(tmp.EC.nod,'size_value')
    EC.nod.size_value = tmp.EC.nod.size_value;
end
if isfield(tmp.EC.nod,'size_threshold')
    EC.nod.size_threshold = tmp.EC.nod.size_threshold;
end
if isfield(tmp.EC.nod,'size_ratio')
    EC.nod.size_ratio = tmp.EC.nod.size_ratio;
end
if isfield(tmp.EC.nod,'color')
    EC.nod.color = tmp.EC.nod.color;
end
if isfield(tmp.EC.nod,'CM')
    EC.nod.CM = tmp.EC.nod.CM;
end

if isfield(tmp.EC.nod,'CMt')
    EC.nod.CMt = tmp.EC.nod.CMt;
end
if isfield(tmp.EC.nod,'cmstring')
    EC.nod.cmstring = tmp.EC.nod.cmstring;
end

if isfield(tmp.EC.nod,'color_map')
    EC.nod.color_map = tmp.EC.nod.color_map;
end
if isfield(tmp.EC.nod,'color_threshold')
    EC.nod.color_threshold = tmp.EC.nod.color_threshold;
end
if isfield(tmp.EC.nod,'CMm')
    EC.nod.CMm = tmp.EC.nod.CMm;
end
if isfield(tmp.EC.nod,'ModularNumber')
    EC.nod.ModularNumberm = tmp.EC.nod.ModularNumber;
end

% Added by Mingrui, 20170303, fixed range of color mapping
if isfield(tmp.EC.nod,'color_map_type')
    EC.nod.color_map_type = tmp.EC.nod.color_map_type;
end
if isfield(tmp.EC.nod,'color_map_low')
    EC.nod.color_map_low = tmp.EC.nod.color_map_low;
end
if isfield(tmp.EC.nod,'color_map_high')
    EC.nod.color_map_high = tmp.EC.nod.color_map_high;
end


if isfield(tmp.EC,'lbl')
    EC.lbl = tmp.EC.lbl;
end
if isfield(tmp.EC,'lbl_threshold')
    EC.lbl_threshold = tmp.EC.lbl_threshold;
end
if isfield(tmp.EC,'lbl_threshold_type')
    EC.lbl_threshold_type = tmp.EC.lbl_threshold_type;
end
if isfield(tmp.EC.edg,'draw')
    EC.edg.draw = tmp.EC.edg.draw;
end
if isfield(tmp.EC.edg,'draw_threshold')
    EC.edg.draw_threshold = tmp.EC.edg.draw_threshold;
end
if isfield(tmp.EC.edg,'draw_abs')
    EC.edg.draw_abs = tmp.EC.edg.draw_abs;
end
if isfield(tmp.EC.edg,'size')
    EC.edg.size = tmp.EC.edg.size;
end
if isfield(tmp.EC.edg,'size_size')
    EC.edg.size_size = tmp.EC.edg.size_size;
end
if isfield(tmp.EC.edg,'size_value')
    EC.edg.size_value = tmp.EC.edg.size_value;
end
if isfield(tmp.EC.edg,'size_threshold')
    EC.edg.size_threshold = tmp.EC.edg.size_threshold;
end
if isfield(tmp.EC.edg,'size_ratio')
    EC.edg.size_ratio = tmp.EC.edg.size_ratio;
end
if isfield(tmp.EC.edg,'size_abs')
    EC.edg.size_abs = tmp.EC.edg.size_abs;
end
if isfield(tmp.EC.edg,'color')
    EC.edg.color = tmp.EC.edg.color;
end
if isfield(tmp.EC.edg,'CM')
    EC.edg.CM = tmp.EC.edg.CM;
end

if isfield(tmp.EC.edg,'CMt')
    EC.edg.CMt = tmp.EC.edg.CMt;
end
if isfield(tmp.EC.edg,'cmstring')
    EC.edg.cmstring = tmp.EC.edg.cmstring;
end

if isfield(tmp.EC.edg,'color_map')
    EC.edg.color_map = tmp.EC.edg.color_map;
end
if isfield(tmp.EC.edg,'color_threshold')
    EC.edg.color_threshold = tmp.EC.edg.color_threshold;
end
if isfield(tmp.EC.edg,'color_distance')
    EC.edg.color_distance = tmp.EC.edg.color_distance;
end
if isfield(tmp.EC.edg,'color_abs')
    EC.edg.color_abs = tmp.EC.edg.color_abs;
end
if isfield(tmp.EC.edg,'interhemiedges')
    EC.edg.interhemiedges = tmp.EC.edg.interhemiedges;
end
if isfield(tmp.EC.edg,'directed')
    EC.edg.directed = tmp.EC.edg.directed;
end

% Added by Mingrui, 20170303, fixed range of color mapping
if isfield(tmp.EC.edg,'color_map_type')
    EC.edg.color_map_type = tmp.EC.edg.color_map_type;
end
if isfield(tmp.EC.edg,'color_map_low')
    EC.edg.color_map_low = tmp.EC.edg.color_map_low;
end
if isfield(tmp.EC.edg,'color_map_high')
    EC.edg.color_map_high = tmp.EC.edg.color_map_high;
end

if isfield(tmp.EC.img,'width')
    EC.img.width = tmp.EC.img.width;
end
if isfield(tmp.EC.img,'height')
    EC.img.height = tmp.EC.img.height;
end
if isfield(tmp.EC.img,'dpi')
    EC.img.dpi = tmp.EC.img.dpi;
end
if isfield(tmp.EC.lbl_font,'FontName')
    EC.lbl_font.FontName = tmp.EC.lbl_font.FontName;
end
if isfield(tmp.EC.lbl_font,'FontWeight')
    EC.lbl_font.FontWeight = tmp.EC.lbl_font.FontWeight;
end
if isfield(tmp.EC.lbl_font,'FontAngle')
    EC.lbl_font.FontAngle = tmp.EC.lbl_font.FontAngle;
end
if isfield(tmp.EC.lbl_font,'FontSize')
    EC.lbl_font.FontSize = tmp.EC.lbl_font.FontSize;
end
if isfield(tmp.EC.lbl_font,'FontUnits')
    EC.lbl_font.FontUnits = tmp.EC.lbl_font.FontUnits;
end
if isfield(tmp.EC.lot,'view')
    EC.lot.view = tmp.EC.lot.view;
end
if isfield(tmp.EC.lot,'view_direction')
    EC.lot.view_direction = tmp.EC.lot.view_direction;
end
if isfield(tmp.EC.lot,'view_az')
    EC.lot.view_az = tmp.EC.lot.view_az;
end
if isfield(tmp.EC.lot,'view_el')
    EC.lot.view_el = tmp.EC.lot.view_el;
end
if isfield(tmp.EC.vol,'display')
    EC.vol.display = tmp.EC.vol.display;
end
if isfield(tmp.EC.vol,'pn')
    EC.vol.pn = tmp.EC.vol.pn;
end
if isfield(tmp.EC.vol,'px')
    EC.vol.px = tmp.EC.vol.px;
end
if isfield(tmp.EC.vol,'nn')
    EC.vol.nn = tmp.EC.vol.nn;
end
if isfield(tmp.EC.vol,'nx')
    EC.vol.nx = tmp.EC.vol.nx;
end
if isfield(tmp.EC.vol,'null')
    EC.vol.null = tmp.EC.vol.null;
end
if isfield(tmp.EC.vol,'CM')
    EC.vol.CM = tmp.EC.vol.CM;
end
if isfield(tmp.EC.vol,'CMt')
    EC.vol.CMt = tmp.EC.vol.CMt;
end
if isfield(tmp.EC.vol,'color_map')
    EC.vol.color_map = tmp.EC.vol.color_map;
end
if isfield(tmp.EC.vol,'cmstring')
    EC.vol.cmstring = tmp.EC.vol.cmstring;
end
if isfield(tmp.EC.vol,'adjustCM')
    EC.vol.adjustCM = tmp.EC.vol.adjustCM;
end
if isfield(tmp.EC.vol,'mapalgorithm')
    EC.vol.mapalgorithm = tmp.EC.vol.mapalgorithm;
end
if isfield(tmp.EC.glb,'material')
    EC.glb.material = tmp.EC.glb.material;
end
if isfield(tmp.EC.glb,'material_ka')
    EC.glb.material_ka = tmp.EC.glb.material_ka;
end
if isfield(tmp.EC.glb,'material_kd')
    EC.glb.material_kd = tmp.EC.glb.material_kd;
end
if isfield(tmp.EC.glb,'material__ks')
    EC.glb.material_ks = tmp.EC.glb.material_ks;
end
if isfield(tmp.EC.glb,'shading')
    EC.glb.shading = tmp.EC.glb.shading;
end
if isfield(tmp.EC.glb,'lighting')
    EC.glb.lighting = tmp.EC.glb.lighting;
end
if isfield(tmp.EC.glb,'lightdirection')
    EC.glb.lightdirection = tmp.EC.glb.lightdirection;
end
if isfield(tmp.EC.glb,'render')
    EC.glb.render = tmp.EC.glb.render;
end
if isfield(tmp.EC.glb,'detail')
    EC.glb.detail = tmp.EC.glb.detail;
end

% Add by Mingrui, 20170309, display LR
if isfield(tmp.EC.glb,'lr')
    EC.glb.lr = tmp.EC.glb.lr;
end

if isfield(tmp.EC.vol,'type')
    EC.vol.type = tmp.EC.vol.type;
end
if isfield(tmp.EC.vol.roi,'drawall')
    EC.vol.roi.drawall = tmp.EC.vol.roi.drawall;
end
if isfield(tmp.EC.vol.roi,'draw')
    EC.vol.roi.draw = tmp.EC.vol.roi.draw;
end
if isfield(tmp.EC.vol.roi,'color')
    EC.vol.roi.color = tmp.EC.vol.roi.color;
end
if isfield(tmp.EC.vol.roi,'colort')
    EC.vol.roi.colort = tmp.EC.vol.roi.colort;
end
if isfield(tmp.EC.vol.roi,'smooth')
    EC.vol.roi.smooth = tmp.EC.vol.roi.smooth;
end

if isfield(tmp.EC.vol.roi,'smooth_kernal')
    EC.vol.roi.smooth_kernal = tmp.EC.vol.roi.smooth_kernal;
end

if isfield(tmp.EC.vol.roi,'drawcus')
    EC.vol.roi.drawcus = tmp.EC.vol.roi.drawcus;
end
if isfield(tmp.EC.vol.roi,'drawt')
    EC.vol.roi.drawt = tmp.EC.vol.roi.drawt;
end

% Added by Mingrui Xia, 20140916, add statistic for volume mapping
if isfield(tmp.EC.vol,'threshold')
    EC.vol.threshold = tmp.EC.vol.threshold;
end
if isfield(tmp.EC.vol,'p')
    EC.vol.p = tmp.EC.vol.p;
end
if isfield(tmp.EC.vol.roi,'clustersize')
    EC.vol.clustersize = tmp.EC.vol.clustersize;
end
if isfield(tmp.EC.vol.roi,'rmm')
    EC.vol.rmm = tmp.EC.vol.rmm;
end

% Add by Mingrui, 20140925, dispaly edge by opacity
if isfield(tmp.EC.edg,'opacity')
    EC.edg.opacity = tmp.EC.edg.opacity;
end
if isfield(tmp.EC.edg,'opacity_same')
    EC.edg.opacity_same = tmp.EC.edg.opacity_same;
end
if isfield(tmp.EC.edg,'opacity_max')
    EC.edg.opacity_max = tmp.EC.edg.opacity_max;
end
if isfield(tmp.EC.edg,'opacity_min')
    EC.edg.opacity_min = tmp.EC.edg.opacity_min;
end
if isfield(tmp.EC.edg,'opacity_abs')
    EC.edg.opacity_abs = tmp.EC.edg.opacity_abs;
end

% Add by Mingrui, 20150120, using custom matrix to define edge color.
if isfield(tmp.EC.edg,'CM_custom')
    EC.edg.CM_custom = tmp.EC.edg.CM_custom;
end
if isfield(tmp.EC.edg,'color_custom_matrix')
    EC.edg.color_custom_matrix = tmp.EC.edg.color_custom_matrix;
end
if isfield(tmp.EC.edg,'color_custom_index')
    EC.edg.color_custom_index = tmp.EC.edg.color_custom_index;
end

if isfield(tmp.EC.vol,'CM_annot')
    EC.vol.CM_annot = tmp.EC.vol.CM_annot;
end

if isfield(tmp.EC,'front')
    EC.lbl_front = tmp.EC.lbl_front;
end

% --- Executes on button press in Save_button.
function Save_button_Callback(hObject, eventdata, handles)
% hObject    handle to Save_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global EC
[filename,pathname]=uiputfile({'*.mat','MAT-files (*.mat)'},'Save Option');
if isequal(filename,0)||isequal(pathname,0)
    return;
else
    fpath=fullfile(pathname,filename);
    GetValue(handles);
    save(fpath,'EC');
    msgbox('Option Saved!','Success','help');
end


% --- Executes on button press in LblF_button.
function LblF_button_Callback(hObject, eventdata, handles)
% hObject    handle to LblF_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global EC
if isempty(EC.lbl_font)
    s=uisetfont;
else
    s=uisetfont(EC.lbl_font);
end
if isstruct(s)
    EC.lbl_font=s;
    ChangeFlag(handles);
end


% --- Executes on slider movement.
function EdgCD_slider_Callback(hObject, eventdata, handles)
% hObject    handle to EdgCD_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = get(handles.EdgCD_slider, 'value');
set(handles.EdgCD_edit, 'string', num2str(val,'%f'));
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function EdgCD_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgCD_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function EdgCD_edit_Callback(hObject, eventdata, handles)
% hObject    handle to EdgCD_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EdgCD_edit as text
%        str2double(get(hObject,'String')) returns contents of EdgCD_edit as a double
val=str2double(get(handles.EdgCD_edit,'String'));
set(handles.EdgCD_slider,'Value',val);
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function EdgCD_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgCD_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over EdgCDH_pushbutton.
function EdgCDH_pushbutton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to EdgCDH_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.EdgCDH_pushbutton,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over EdgCDL_pushbutton.
function EdgCDL_pushbutton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to EdgCDL_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.EdgCDL_pushbutton,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- Executes on slider movement.
function EdgDS_slider_Callback(hObject, eventdata, handles)
% hObject    handle to EdgDS_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global surf
val = get(handles.EdgDS_slider, 'value');
set(handles.EdgDS_edit, 'string', num2str(val,'%f'));
sq=surf.nsph^2;
switch get(handles.EdgDT_checkbox,'Value')
    case 0
        temp=sort(reshape(surf.net,sq,1),'descend');
    case 1
        temp=sort(reshape(abs(surf.net),sq,1),'descend');
end
index=int32(val*sq);
if index<1
    index=1;
elseif index>sq
    index=sq;
end
set(handles.EdgDT_slider,'Value',temp(index));
set(handles.EdgDT_edit,'String',num2str(temp(index),'%f'));
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function EdgDS_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgDS_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function EdgDS_edit_Callback(hObject, eventdata, handles)
% hObject    handle to EdgDS_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EdgDS_edit as text
%        str2double(get(hObject,'String')) returns contents of EdgDS_edit as a double
global surf
val = str2double(get(handles.EdgDS_edit, 'String'));
set(handles.EdgDS_slider, 'Value', val);
sq=surf.nsph^2;
switch get(handles.EdgDT_checkbox,'Value')
    case 0
        temp=sort(reshape(surf.net,sq,1),'descend');
    case 1
        temp=sort(reshape(abs(surf.net),sq,1),'descend');
end
index=int32(val*sq);
if index<1
    index=1;
elseif index>sq
    index=sq;
end
set(handles.EdgDT_slider,'Value',temp(index));
set(handles.EdgDT_edit,'String',num2str(temp(index),'%f'));
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function EdgDS_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgDS_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on EdgDS_edit and none of its controls.
function EdgDS_edit_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to EdgDS_edit (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in EdgS_checkbox.
function EdgS_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to EdgS_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of EdgS_checkbox
global EC
global surf
switch get(handles.EdgS_checkbox,'Value')
    case 0
        if EC.edg.size_threshold>max(surf.net(:))||EC.edg.size_threshold<min(surf.net(:))
            EC.edg.size_threshold=min(surf.net(:));
        end
        set(handles.EdgST_slider,'Max',max(surf.net(:)));
        set(handles.EdgST_slider,'Min',min(surf.net(:))-0.001);
        set(handles.EdgST_slider,'Value',EC.edg.size_threshold);
        set(handles.EdgST_edit,'String',num2str(EC.edg.size_threshold,'%f'));
    case 1
        if EC.edg.size_threshold>max(abs(surf.net(:)))||EC.edg.size_threshold<min(abs(surf.net(:)))
            EC.edg.size_threshold=min(abs(surf.net(:)));
        end
        set(handles.EdgST_slider,'Max',max(abs(surf.net(:))));
        set(handles.EdgST_slider,'Min',min(abs(surf.net(:)))-0.001);
        set(handles.EdgST_slider,'Value',EC.edg.size_threshold);
        set(handles.EdgST_edit,'String',num2str(EC.edg.size_threshold,'%f'));
end
ChangeFlag(handles);


% --- Executes on button press in EdgDT_checkbox.
function EdgDT_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to EdgDT_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of EdgDT_checkbox
global EC
global surf
switch get(handles.EdgDT_checkbox,'Value')
    case 0
        if EC.edg.draw_threshold>max(surf.net(:))||EC.edg.draw_threshold<min(surf.net(:))
            EC.edg.draw_threshold=min(surf.net(:));
        end
        set(handles.EdgDT_slider,'Max',max(surf.net(:)));
        set(handles.EdgDT_slider,'Min',min(surf.net(:))-0.001);
        set(handles.EdgDT_slider,'Value',EC.edg.draw_threshold);
        set(handles.EdgDT_edit,'String',num2str(EC.edg.draw_threshold,'%f'));
        set(handles.EdgDS_slider,'Value',length(find(surf.net>EC.edg.draw_threshold))/(size(surf.net,1)*size(surf.net,2)));
        set(handles.EdgDS_edit,'String',num2str(length(find(surf.net>EC.edg.draw_threshold))/(size(surf.net,1)*size(surf.net,2)),'%f'));
    case 1
        if EC.edg.draw_threshold>max(abs(surf.net(:)))||EC.edg.draw_threshold<min(abs(surf.net(:)))
            EC.edg.draw_threshold=min(abs(surf.net(:)));
        end
        set(handles.EdgDT_slider,'Max',max(abs(surf.net(:))));
        set(handles.EdgDT_slider,'Min',min(abs(surf.net(:)))-0.001);
        set(handles.EdgDT_slider,'Value',EC.edg.draw_threshold);
        set(handles.EdgDT_edit,'String',num2str(EC.edg.draw_threshold,'%f'));
        set(handles.EdgDS_slider,'Value',length(find(abs(surf.net)>EC.edg.draw_threshold))/(size(surf.net,1)*size(surf.net,2)));
        set(handles.EdgDS_edit,'String',num2str(length(find(abs(surf.net)>EC.edg.draw_threshold))/(size(surf.net,1)*size(surf.net,2)),'%f'));
end
ChangeFlag(handles);


% --- Executes on button press in EdgC_checkbox.
function EdgC_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to EdgC_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of EdgC_checkbox
global EC
global surf
switch get(handles.EdgC_checkbox,'Value')
    case 0
        if EC.edg.color_threshold>max(surf.net(:))||EC.edg.color_threshold<min(surf.net(:))
            EC.edg.color_threshold=min(surf.net(:));
        end
        set(handles.EdgCT_slider,'Max',max(surf.net(:)));
        set(handles.EdgCT_slider,'Min',min(surf.net(:))-0.001);
        set(handles.EdgCT_slider,'Value',EC.edg.color_threshold);
        set(handles.EdgCT_edit,'String',num2str(EC.edg.color_threshold,'%f'));
    case 1
        if EC.edg.color_threshold>max(abs(surf.net(:)))||EC.edg.color_threshold<min(abs(surf.net(:)))
            EC.edg.color_threshold=min(abs(surf.net(:)));
        end
        set(handles.EdgCT_slider,'Max',max(abs(surf.net(:))));
        set(handles.EdgCT_slider,'Min',min(abs(surf.net(:)))-0.001);
        set(handles.EdgCT_slider,'Value',EC.edg.color_threshold);
        set(handles.EdgCT_edit,'String',num2str(EC.edg.color_threshold,'%f'));
end
ChangeFlag(handles);


% --- Executes when selected object is changed in Lot_panel.
function Lot_panel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in Lot_panel
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
if get(handles.LotS_radiobutton,'Value')==1
    set(handles.LotSS_radiobutton,'Enable','on');
    set(handles.LotSA_radiobutton,'Enable','on');
    set(handles.LotSC_radiobutton,'Enable','on');
    set(handles.LotSCus_radiobutton,'Enable','on');
    if get(handles.LotSCus_radiobutton,'Value') == 1
        set(handles.LotSCusAz_text,'Enable','on');
        set(handles.LotSCusAz_edit,'Enable','on');
        set(handles.LotSCusEl_text,'Enable','on');
        set(handles.LotSingleCustomEl_edit,'Enable','on');
    end
else
    set(handles.LotSS_radiobutton,'Enable','off');
    set(handles.LotSA_radiobutton,'Enable','off');
    set(handles.LotSC_radiobutton,'Enable','off');
    set(handles.LotSCus_radiobutton,'Enable','off');
    set(handles.LotSCusAz_text,'Enable','off');
    set(handles.LotSCusAz_edit,'Enable','off');
    set(handles.LotSCusEl_text,'Enable','off');
    set(handles.LotSingleCustomEl_edit,'Enable','off');
end
ChangeFlag(handles);

function ChangeFlag(handles)
global FLAG
FLAG.EC_change=1;
set(handles.Apply_button,'Enable','on');


% --- Executes on button press in Apply_button.
function Apply_button_Callback(hObject, eventdata, handles)
% hObject    handle to Apply_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global FLAG
FLAG.EC_change=0;
set(handles.Apply_button,'Enable','off');
GetValue(handles);
FLAG.EC=2;
uiresume(gcbf);




% --- Executes when selected object is changed in LotP_panel.
function LotP_panel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in LotP_panel
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
ChangeFlag(handles);
% Added by Mingrui Xia, 20120806, add custom view for single brain.
if get(handles.LotSCus_radiobutton,'Value') == 1
    set(handles.LotSCusAz_text,'Enable','on');
    set(handles.LotSCusAz_edit,'Enable','on');
    set(handles.LotSCusEl_text,'Enable','on');
    set(handles.LotSingleCustomEl_edit,'Enable','on');
else
    set(handles.LotSCusAz_text,'Enable','off');
    set(handles.LotSCusAz_edit,'Enable','off');
    set(handles.LotSCusEl_text,'Enable','off');
    set(handles.LotSingleCustomEl_edit,'Enable','off');
end

% --- Executes on button press in ImgC_checkbox.
function ImgC_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to ImgC_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ImgC_checkbox



function ImgDH_edit_Callback(hObject, eventdata, handles)
% hObject    handle to ImgDH_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ImgDH_edit as text
%        str2double(get(hObject,'String')) returns contents of ImgDH_edit as a double
global EC
switch get(handles.ImgDH_popupmenu,'Value')
    case 1
        set(handles.ImgPH_edit,'String',num2str(str2double(get(handles.ImgDH_edit,'String'))*str2double(get(handles.ImgD_edit,'String'))/2.54,'%5.0f'));
    case 2
        set(handles.ImgPH_edit,'String',num2str(str2double(get(handles.ImgDH_edit,'String'))*str2double(get(handles.ImgD_edit,'String')),'%5.0f'));
end
if get(handles.ImgC_checkbox,'Value')==1
    set(handles.ImgDW_edit,'String',num2str(str2double(get(handles.ImgDH_edit,'String'))*EC.img.width/EC.img.height,'%f'));
    set(handles.ImgPW_edit,'String',num2str(str2double(get(handles.ImgPH_edit,'String'))*EC.img.width/EC.img.height,'%5.0f'));
end



% --- Executes during object creation, after setting all properties.
function ImgDH_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ImgDH_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ImgDW_edit_Callback(hObject, eventdata, handles)
% hObject    handle to ImgDW_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ImgDW_edit as text
%        str2double(get(hObject,'String')) returns contents of ImgDW_edit as a double
global EC
switch get(handles.ImgDW_popupmenu,'Value')
    case 1
        set(handles.ImgPW_edit,'String',num2str(str2double(get(handles.ImgDW_edit,'String'))*str2double(get(handles.ImgD_edit,'String'))/2.54,'%5.0f'));
    case 2
        set(handles.ImgPW_edit,'String',num2str(str2double(get(handles.ImgDW_edit,'String'))*str2double(get(handles.ImgD_edit,'String')),'%5.0f'));
end
if get(handles.ImgC_checkbox,'Value')==1
    set(handles.ImgDH_edit,'String',num2str(str2double(get(handles.ImgDW_edit,'String'))*EC.img.height/EC.img.width,'%f'));
    set(handles.ImgPH_edit,'String',num2str(str2double(get(handles.ImgPW_edit,'String'))*EC.img.height/EC.img.width,'%5.0f'));
end


% --- Executes during object creation, after setting all properties.
function ImgDW_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ImgDW_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in ImgDW_popupmenu.
function ImgDW_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to ImgDW_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ImgDW_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ImgDW_popupmenu
val=get(handles.ImgDW_popupmenu,'Value');
set(handles.ImgDH_popupmenu,'Value',val);
switch val
    case 1
        set(handles.ImgDW_edit,'String',num2str(str2double(get(handles.ImgPW_edit,'String'))/str2double(get(handles.ImgD_edit,'String'))*2.54,'%f'));
        set(handles.ImgDH_edit,'String',num2str(str2double(get(handles.ImgPH_edit,'String'))/str2double(get(handles.ImgD_edit,'String'))*2.54,'%f'));
    case 2
        set(handles.ImgDW_edit,'String',num2str(str2double(get(handles.ImgPW_edit,'String'))/str2double(get(handles.ImgD_edit,'String')),'%f'));
        set(handles.ImgDH_edit,'String',num2str(str2double(get(handles.ImgPH_edit,'String'))/str2double(get(handles.ImgD_edit,'String')),'%f'));
end



% --- Executes during object creation, after setting all properties.
function ImgDW_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ImgDW_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in ImgDH_popupmenu.
function ImgDH_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to ImgDH_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ImgDH_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ImgDH_popupmenu
val=get(handles.ImgDH_popupmenu,'Value');
set(handles.ImgDW_popupmenu,'Value',val);
switch val
    case 1
        set(handles.ImgDW_edit,'String',num2str(str2double(get(handles.ImgPW_edit,'String'))/str2double(get(handles.ImgD_edit,'String'))*2.54,'%f'));
        set(handles.ImgDH_edit,'String',num2str(str2double(get(handles.ImgPH_edit,'String'))/str2double(get(handles.ImgD_edit,'String'))*2.54,'%f'));
    case 2
        set(handles.ImgDW_edit,'String',num2str(str2double(get(handles.ImgPW_edit,'String'))/str2double(get(handles.ImgD_edit,'String')),'%f'));
        set(handles.ImgDH_edit,'String',num2str(str2double(get(handles.ImgPH_edit,'String'))/str2double(get(handles.ImgD_edit,'String')),'%f'));
end


% --- Executes during object creation, after setting all properties.
function ImgDH_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ImgDH_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in NodST_checkbox.
function NodST_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to NodST_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of NodST_checkbox
if get(handles.NodST_checkbox,'Value')==1
    set(handles.NodST_slider,'Enable','on');
    set(handles.NodST_edit,'Enable','on');
else
    set(handles.NodST_slider,'Enable','off');
    set(handles.NodST_edit,'Enable','off');
end
ChangeFlag(handles);


% --- Executes on button press in EdgST_checkbox.
function EdgST_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to EdgST_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of EdgST_checkbox
if get(handles.EdgST_checkbox,'Value')==1
    set(handles.EdgST_slider,'Enable','on');
    set(handles.EdgST_edit,'Enable','on');
else
    set(handles.EdgST_slider,'Enable','off');
    set(handles.EdgST_edit,'Enable','off');
end
ChangeFlag(handles);


% --- Executes on selection change in VolC_popupmenu.
function VolC_popupmenu_Callback(hObject, eventdata, handles)
%%% Mingrui Xia added on 20111104, define custome colorbar.
% hObject    handle to VolC_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns VolC_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from VolC_popupmenu
ChangeFlag(handles);
global EC
if get(hObject, 'Value') == 24
    prompt = {'Volume mapping colorbar: Please input a n*3 matrix.'};
    def = {EC.vol.cmstring};
    answer = inputdlg(prompt,'Custome colorbar defination',1,def);
    if ~isempty(answer)
        EC.vol.cmstring = answer{1};
    end
    tmp = eval([EC.vol.cmstring,';']);
    if size(tmp,2)~=3
        msgbox({'The colorbar inputed has wrong dimension.'},'Error','error');
        tmp = EC.vol.CMt;
    elseif max(tmp(:))>1 || min(tmp(:))<0
        msgbox({['The colorbar inputed exceed range (0-1).','The colorbar is auto arranged']},'Error','error');
        tmp = tmp/255;
        tmp(tmp<0) = 0;
    end
    EC.vol.CMt = tmp;
end

% --- Executes during object creation, after setting all properties.
function VolC_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VolC_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function VolNRn_edit_Callback(hObject, eventdata, handles)
% hObject    handle to VolNRn_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of VolNRn_edit as text
%        str2double(get(hObject,'String')) returns contents of VolNRn_edit as a double
ChangeFlag(handles);
if str2double(get(handles.VolNRn_edit,'String')) < str2double(get(handles.VolNRx_edit,'String'))
    set(handles.VolNRx_edit,'String',num2str(str2double(get(handles.VolNRn_edit,'String')) - 1));
end

% --- Executes during object creation, after setting all properties.
function VolNRn_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VolNRn_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function VolNRx_edit_Callback(hObject, eventdata, handles)
% hObject    handle to VolNRx_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of VolNRx_edit as text
%        str2double(get(hObject,'String')) returns contents of VolNRx_edit as a double
ChangeFlag(handles);
if str2double(get(handles.VolNRn_edit,'String')) < str2double(get(handles.VolNRx_edit,'String'))
    set(handles.VolNRx_edit,'String',num2str(str2double(get(handles.VolNRn_edit,'String')) - 1));
end

% --- Executes during object creation, after setting all properties.
function VolNRx_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VolNRx_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function VolPRn_edit_Callback(hObject, eventdata, handles)
% hObject    handle to VolPRn_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of VolPRn_edit as text
%        str2double(get(hObject,'String')) returns contents of VolPRn_edit as a double
ChangeFlag(handles);
if str2double(get(handles.VolPRn_edit,'String')) > str2double(get(handles.VolPRx_edit,'String'))
    set(handles.VolPRx_edit,'String',num2str(str2double(get(handles.VolPRn_edit,'String')) + 1));
end


% --- Executes during object creation, after setting all properties.
function VolPRn_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VolPRn_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function VolPRx_edit_Callback(hObject, eventdata, handles)
% hObject    handle to VolPRx_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of VolPRx_edit as text
%        str2double(get(hObject,'String')) returns contents of VolPRx_edit as a double
ChangeFlag(handles);
if str2double(get(handles.VolPRn_edit,'String')) > str2double(get(handles.VolPRx_edit,'String'))
    set(handles.VolPRx_edit,'String',num2str(str2double(get(handles.VolPRn_edit,'String')) + 1));
end

% --- Executes during object creation, after setting all properties.
function VolPRx_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VolPRx_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in VolD_popupmenu.
function VolD_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to VolD_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns VolD_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from VolD_popupmenu
val=get(hObject,'Value');
switch val
    case 1
        set(handles.VolNR_text,'Enable','on');
        set(handles.VolNRn_edit,'Enable','on');
        set(handles.VolNRx_edit,'Enable','on');
        set(handles.VolPR_text,'Enable','on');
        set(handles.VolPRn_edit,'Enable','on');
        set(handles.VolPRx_edit,'Enable','on');
    case 2
        set(handles.VolNR_text,'Enable','off');
        set(handles.VolNRn_edit,'Enable','off');
        set(handles.VolNRx_edit,'Enable','off');
        set(handles.VolPR_text,'Enable','on');
        set(handles.VolPRn_edit,'Enable','on');
        set(handles.VolPRx_edit,'Enable','on');
    case 3
        set(handles.VolPR_text,'Enable','off');
        set(handles.VolPRn_edit,'Enable','off');
        set(handles.VolPRx_edit,'Enable','off');
        set(handles.VolNR_text,'Enable','on');
        set(handles.VolNRn_edit,'Enable','on');
        set(handles.VolNRx_edit,'Enable','on');
        set(handles.VolPR_text,'Enable','on');
end
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function VolD_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VolD_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over VolNCS_pushbutton.
function VolNCS_pushbutton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to VolNCS_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(hObject,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- Executes on button press in EdgDInter_checkbox.
function EdgDInter_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to EdgDInter_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of EdgDInter_checkbox
ChangeFlag(handles);


% --- Executes on selection change in GlbM_popupmenu.
function GlbM_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to GlbM_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns GlbM_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from GlbM_popupmenu
Val = get(hObject,'Value');
switch Val
    case {1,2,3}
        set(handles.GlbMa_text,'Enable','off');
        set(handles.GlbMa_edit,'Enable','off');
        set(handles.GlbMd_text,'Enable','off');
        set(handles.GlbMd_edit,'Enable','off');
        set(handles.GlbMs_text,'Enable','off');
        set(handles.GlbMs_edit,'Enable','off');
    case 4
        set(handles.GlbMa_text,'Enable','on');
        set(handles.GlbMa_edit,'Enable','on');
        set(handles.GlbMd_text,'Enable','on');
        set(handles.GlbMd_edit,'Enable','on');
        set(handles.GlbMs_text,'Enable','on');
        set(handles.GlbMs_edit,'Enable','on');
end
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function GlbM_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GlbM_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function GlbMa_edit_Callback(hObject, eventdata, handles)
% hObject    handle to GlbMa_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of GlbMa_edit as text
%        str2double(get(hObject,'String')) returns contents of GlbMa_edit as a double
ChangeFlag(handles);

% --- Executes during object creation, after setting all properties.
function GlbMa_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GlbMa_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function GlbMd_edit_Callback(hObject, eventdata, handles)
% hObject    handle to GlbMd_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of GlbMd_edit as text
%        str2double(get(hObject,'String')) returns contents of GlbMd_edit as a double
ChangeFlag(handles);

% --- Executes during object creation, after setting all properties.
function GlbMd_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GlbMd_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function GlbMs_edit_Callback(hObject, eventdata, handles)
% hObject    handle to GlbMs_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of GlbMs_edit as text
%        str2double(get(hObject,'String')) returns contents of GlbMs_edit as a double
ChangeFlag(handles);

% --- Executes during object creation, after setting all properties.
function GlbMs_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GlbMs_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in GlbS_popupmenu.
function GlbS_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to GlbS_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns GlbS_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from GlbS_popupmenu
ChangeFlag(handles);

% --- Executes during object creation, after setting all properties.
function GlbS_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GlbS_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in GlbLA_popupmenu.
function GlbLA_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to GlbLA_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns GlbLA_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from GlbLA_popupmenu
ChangeFlag(handles);

% --- Executes during object creation, after setting all properties.
function GlbLA_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GlbLA_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in GlbLD_popupmenu.
function GlbLD_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to GlbLD_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns GlbLD_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from GlbLD_popupmenu
ChangeFlag(handles);

% --- Executes during object creation, after setting all properties.
function GlbLD_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GlbLD_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in GlbRd_popupmenu.
function GlbRd_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to GlbRd_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns GlbRd_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from GlbRd_popupmenu
ChangeFlag(handles);

% --- Executes during object creation, after setting all properties.
function GlbRd_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GlbRd_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function GlbGD_slider_Callback(hObject, eventdata, handles)
% hObject    handle to GlbGD_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
switch get(hObject,'Value')
    case 1
        set(handles.GlbGD_display_text,'String','Low');
    case 2
        set(handles.GlbGD_display_text,'String','Moderate');
    case 3
        set(handles.GlbGD_display_text,'String','High');
end
ChangeFlag(handles);

% --- Executes during object creation, after setting all properties.
function GlbGD_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GlbGD_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on selection change in GlbGD_popupmenu.
function GlbGD_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to GlbGD_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns GlbGD_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from GlbGD_popupmenu
ChangeFlag(handles);

% --- Executes during object creation, after setting all properties.
function GlbGD_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GlbGD_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function VolROICus_edit_Callback(hObject, eventdata, handles)
% hObject    handle to VolROICus_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of VolROICus_edit as text
%        str2double(get(hObject,'String')) returns contents of VolROICus_edit as a double
global EC
EC.vol.roi.drawcus = get(hObject,'String');
EC.vol.roi.drawt = eval(['[',EC.vol.roi.drawcus,'];']);
textcell = cell(length(EC.vol.roi.drawt),1);
for i = 1:length(textcell)
    textcell{i} = ['ROI ',num2str(EC.vol.roi.drawt(i))];
end
set(handles.VolROIColor_popupmenu,'String',textcell);
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function VolROICus_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VolROICus_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in VolROIDrawAll_checkbox.
function VolROIDrawAll_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to VolROIDrawAll_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of VolROIDrawAll_checkbox
global EC
global surf
if get(hObject,'Value') == 1
    set(handles.VolROICus_text,'Enable','off');
    set(handles.VolROICus_edit,'Enable','off');
    
    % Added by Mingrui 20140925, draw cluster in statistical files
    if ~strcmp(surf.test,'No')
        switch get(handles.VolStaCon_popupmenu,'Value')
            case 1
                rmm = 6;
            case 2
                rmm = 18;
            case 3
                rmm = 26;
        end
        vol_tmp = surf.vol;
        vol_tmp(vol_tmp < str2double(get(handles.VolStaThr_edit,'String')) & vol_tmp > -str2double(get(handles.VolStaThr_edit,'String'))) = 0;
        [L, num] = bwlabeln(vol_tmp,rmm);
        vol_tmp2 = zeros(size(vol_tmp));
        n = 0;
        for x = 1:num
            theCurrentCluster = L == x;
            if length(find(theCurrentCluster)) >= str2double(get(handles.VolStaClu_edit,'String'))
                n = n + 1;
                vol_tmp2(logical(theCurrentCluster)) = n;
            end
        end
    else
        vol_tmp2 = surf.vol;
    end
    
    EC.vol.roi.drawt = unique(vol_tmp2);
    EC.vol.roi.drawt(EC.vol.roi.drawt == 0) = [];
else
    if ~isempty(EC.vol.roi.drawcus)
        EC.vol.roi.drawt = eval(['[',EC.vol.roi.drawcus,'];']);
    end
    set(handles.VolROICus_text,'Enable','on');
    set(handles.VolROICus_edit,'Enable','on');
    set(handles.VolROIColor_popupmenu,'Value',1); %% Edited by Mingrui 20140509, fix the bug that the popupmenu disappeared when changing ROI selections
end
textcell = cell(length(EC.vol.roi.drawt),1);
for i = 1:length(textcell)
    textcell{i} = ['ROI ',num2str(EC.vol.roi.drawt(i))];
end
set(handles.VolROIColor_popupmenu,'String',textcell);
ChangeFlag(handles);


% --- Executes on selection change in VolROIColor_popupmenu.
function VolROIColor_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to VolROIColor_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns VolROIColor_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from VolROIColor_popupmenu
global EC
set(handles.VolROIColorSQ_pushbutton,'BackgroundColor',EC.vol.roi.colort(get(hObject,'Value'),:));


% --- Executes during object creation, after setting all properties.
function VolROIColor_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VolROIColor_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in VolROISmooth_checkbox.
function VolROISmooth_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to VolROISmooth_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of VolROISmooth_checkbox
if get(hObject,'value') == 1
    set(handles.VolROISmooth_popupmenu,'Enable','on');
else
    set(handles.VolROISmooth_popupmenu,'Enable','off');
end
ChangeFlag(handles); %% Add by Mingrui Xia, 20140729, fix the bug that apply button doesn't change when smooth checked

% --- Executes when selected object is changed in VolTS_uipanel.
function VolTS_uipanel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in VolTS_uipanel
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
global EC
global FLAG
global surf
if get(handles.VolVS_radiobutton,'Value') == 1
    set(handles.VolDR_text,'Enable','on');
    set(handles.VolD_text,'Enable','on');
    set(handles.VolD_popupmenu,'Enable','on');
    switch get(handles.VolD_popupmenu,'Value')
        case 1
            set(handles.VolD_popupmenu,'Value',1);
            set(handles.VolNR_text,'Enable','on');
            set(handles.VolNRn_edit,'Enable','on');
            set(handles.VolNRx_edit,'Enable','on');
            set(handles.VolPR_text,'Enable','on');
            set(handles.VolPRn_edit,'Enable','on');
            set(handles.VolPRx_edit,'Enable','on');
        case 2
            set(handles.VolD_popupmenu,'Value',2);
            set(handles.VolNR_text,'Enable','off');
            set(handles.VolNRn_edit,'Enable','off');
            set(handles.VolNRx_edit,'Enable','off');
            set(handles.VolPR_text,'Enable','on');
            set(handles.VolPRn_edit,'Enable','on');
            set(handles.VolPRx_edit,'Enable','on');
        case 3
            set(handles.VolD_popupmenu,'Value',3);
            set(handles.VolPR_text,'Enable','off');
            set(handles.VolPRn_edit,'Enable','off');
            set(handles.VolPRx_edit,'Enable','off');
            set(handles.VolNR_text,'Enable','on');
            set(handles.VolNRn_edit,'Enable','on');
            set(handles.VolNRx_edit,'Enable','on');
    end
    set(handles.VolNC_text,'Enable','on');
    set(handles.VolC_text,'Enable','on');
    set(handles.VolC_popupmenu,'Enable','on');
    set(handles.VolROIRange_text,'Enable','off');
    set(handles.VolROIDrawAll_checkbox,'Enable','off');
    set(handles.VolROICus_text,'Enable','off');
    set(handles.VolROICus_edit,'Enable','off');
    set(handles.VolROIColor_text,'Enable','off');
    set(handles.VolROIColor_popupmenu,'Enable','off');
    set(handles.VolROIColorSQ_pushbutton,'Enable','off');
    set(handles.VolROISmooth_checkbox,'Enable','off');
    set(handles.VolROISmooth_popupmenu,'Enable','off');
    set(handles.VolMapAlgorithm_text,'Enable','on');
    if FLAG.MAP == 2
        set(handles.VolMapAlgorithm_popupmenu,'Enable','on');
        set(handles.Vol_AdjustCM_checkbox,'Enable','on');
    end
    
    % Added by Mingrui, 20140926, auto set surface opacity when selecting
    % between volume mapping and ROI cluster
    if get(handles.MshA_slider,'Value') ~= 1
        set(handles.MshA_slider,'Value',1);
        set(handles.MshA_edit,'String','1');
    end
    
else
    set(handles.VolDR_text,'Enable','off');
    set(handles.VolD_text,'Enable','off');
    set(handles.VolD_popupmenu,'Enable','off');
    set(handles.VolNR_text,'Enable','off');
    set(handles.VolNRn_edit,'Enable','off');
    set(handles.VolNRx_edit,'Enable','off');
    set(handles.VolPR_text,'Enable','off');
    set(handles.VolPRn_edit,'Enable','off');
    set(handles.VolPRx_edit,'Enable','off');
    set(handles.VolNC_text,'Enable','off');
    set(handles.VolC_text,'Enable','off');
    set(handles.VolC_popupmenu,'Enable','off');
    set(handles.VolROIRange_text,'Enable','on');
    set(handles.VolROIDrawAll_checkbox,'Enable','on');
    if EC.vol.roi.drawall ~= 1
        set(handles.VolROICus_text,'Enable','on');
        set(handles.VolROICus_edit,'Enable','on');
    end
    set(handles.VolROIColor_text,'Enable','on');
    set(handles.VolROIColor_popupmenu,'Enable','on');
    set(handles.VolROIColorSQ_pushbutton,'Enable','on');
    set(handles.VolROISmooth_checkbox,'Enable','on');
    if get(handles.VolROISmooth_checkbox,'Value') == 1
        set(handles.VolROISmooth_popupmenu,'Enable','on');
    else
        set(handles.VolROISmooth_popupmenu,'Enable','off');
    end
    set(handles.VolMapAlgorithm_text,'Enable','off');
    set(handles.VolMapAlgorithm_popupmenu,'Enable','off');
    set(handles.Vol_AdjustCM_checkbox,'Enable','off');
    
    % Added by Mingrui 20140925, draw cluster in statistical files
    switch get(handles.VolStaCon_popupmenu,'Value')
        case 1
            rmm = 6;
        case 2
            rmm = 18;
        case 3
            rmm = 26;
    end
    if ~strcmp(surf.test,'No')
        vol_tmp = surf.vol;
        vol_tmp(vol_tmp < str2double(get(handles.VolStaThr_edit,'String')) & vol_tmp > -str2double(get(handles.VolStaThr_edit,'String'))) = 0;
        [L, num] = bwlabeln(vol_tmp,rmm);
        vol_tmp2 = zeros(size(vol_tmp));
        n = 0;
        for x = 1:num
            theCurrentCluster = L == x;
            if length(find(theCurrentCluster)) >= str2double(get(handles.VolStaClu_edit,'String'))
                n = n + 1;
                vol_tmp2(logical(theCurrentCluster)) = n;
            end
        end
    else
        vol_tmp2 = surf.vol;
    end
    
    EC.vol.roi.drawt = unique(vol_tmp2);
    EC.vol.roi.drawt(EC.vol.roi.drawt == 0) = [];
    
    textcell = cell(length(EC.vol.roi.drawt),1);
    for i = 1:length(textcell)
        textcell{i} = ['ROI ',num2str(EC.vol.roi.drawt(i))];
    end
    set(handles.VolROIColor_popupmenu,'String',textcell);
    
    set(handles.VolROICus_edit,'String',EC.vol.roi.drawcus);
    
    % Added by Mingrui, 20140926, auto set surface opacity when selecting
    % between volume mapping and ROI cluster
    if get(handles.MshA_slider,'Value') == 1
        set(handles.MshA_slider,'Value',0.3);
        set(handles.MshA_edit,'String','0.3');
    end
    
end
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function VolTS_uipanel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VolTS_uipanel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function NodD_panel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NodD_panel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over VolROIColorSQ_pushbutton.
function VolROIColorSQ_pushbutton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to VolROIColorSQ_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global EC
c=uisetcolor('Select Color');
if length(c)==3
    EC.vol.roi.colort(get(handles.VolROIColor_popupmenu,'Value'),:) = c;
    set(hObject,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- Executes on button press in EdgDDirected_checkbox.
function EdgDDirected_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to EdgDDirected_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of EdgDDirected_checkbox
ChangeFlag(handles);


% --- Executes on button press in Vol_AdjustCM_checkbox.
function Vol_AdjustCM_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to Vol_AdjustCM_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Vol_AdjustCM_checkbox
ChangeFlag(handles);


% --- Executes when Msh_panel is resized.
function Msh_panel_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to Msh_panel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in MshDoubleBrain_checkbox.
function MshDoubleBrain_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to MshDoubleBrain_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of MshDoubleBrain_checkbox
ChangeFlag(handles);
if get(hObject,'Value') == 1
    set(handles.LotS_radiobutton,'Value',1);
    set(handles.LotSS_radiobutton,'Enable','on');
    set(handles.LotSA_radiobutton,'Enable','on');
    set(handles.LotSC_radiobutton,'Enable','on');
    set(handles.LotF_radiobutton,'Enable','off');
    set(handles.LotLM_radiobutton,'Enable','off');
    set(handles.LotLMV_radiobutton,'Enable','off'); % Fix the bug that when double surface mode is selected, the vetral view is still active. By Mingrui, 20130208
    set(handles.LotLMD_radiobutton,'Enable','off');
else
    set(handles.LotF_radiobutton,'Enable','on');
    set(handles.LotLM_radiobutton,'Enable','on');
    set(handles.LotLMV_radiobutton,'Enable','on');
    set(handles.LotLMD_radiobutton,'Enable','on');
end


% --- Executes on selection change in VolMapAlgorithm_popupmenu.
function VolMapAlgorithm_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to VolMapAlgorithm_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns VolMapAlgorithm_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from VolMapAlgorithm_popupmenu
ChangeFlag(handles);

% --- Executes during object creation, after setting all properties.
function VolMapAlgorithm_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VolMapAlgorithm_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function LotSCusAz_edit_Callback(hObject, eventdata, handles)
% hObject    handle to LotSCusAz_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LotSCusAz_edit as text
%        str2double(get(hObject,'String')) returns contents of LotSCusAz_edit as a double
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function LotSCusAz_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LotSCusAz_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function LotSingleCustomEl_edit_Callback(hObject, eventdata, handles)
% hObject    handle to LotSingleCustomEl_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LotSingleCustomEl_edit as text
%        str2double(get(hObject,'String')) returns contents of LotSingleCustomEl_edit as a double
ChangeFlag(handles);

% --- Executes during object creation, after setting all properties.
function LotSingleCustomEl_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LotSingleCustomEl_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function VolStaThr_edit_Callback(hObject, eventdata, handles)
% hObject    handle to VolStaThr_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of VolStaThr_edit as text
%        str2double(get(hObject,'String')) returns contents of VolStaThr_edit as a double
global surf
global EC
ChangeFlag(handles);
Thrd = str2double(get(hObject,'String'));
switch get(handles.VolD_popupmenu,'Value')
    case 1
        set(handles.VolPRn_edit,'String',get(hObject,'String'));
        set(handles.VolNRn_edit,'String',['-',get(hObject,'String')]);
    case 2
        set(handles.VolPRn_edit,'String',get(hObject,'String'));
    case 3
        set(handles.VolNRn_edit,'String',['-',get(hObject,'String')]);
end
if str2double(get(handles.VolPRx_edit,'String')) < Thrd
    set(handles.VolPRx_edit,'String',num2str(Thrd + 1));
end
if str2double(get(handles.VolNRx_edit,'String')) > -Thrd
    set(handles.VolNRx_edit,'String',num2str(-Thrd - 1));
end
if ~strcmp(surf.test,'No')
    switch surf.test
        case 'T'
            P = 2*(1-tcdf(Thrd,surf.df));
        case 'F'
            P = 1-fcdf(Thrd,surf.df(1),surf.df(2));
        case 'R'
            P = 2*(1-tcdf(abs(Thrd)*sqrt((surf.df)/(1-Thrd*Thrd)),surf.df));
        case 'Z'
            P = 2*(1-normcdf(Thrd));
    end
    set(handles.VolStaP_edit,'String',num2str(P));
end

% Added by Mingrui 20140925, draw cluster in statistical files
if ~strcmp(surf.test,'No')
    switch get(handles.VolStaCon_popupmenu,'Value')
        case 1
            rmm = 6;
        case 2
            rmm = 18;
        case 3
            rmm = 26;
    end
    vol_tmp = surf.vol;
    vol_tmp(vol_tmp < str2double(get(handles.VolStaThr_edit,'String')) & vol_tmp > -str2double(get(handles.VolStaThr_edit,'String'))) = 0;
    [L, num] = bwlabeln(vol_tmp,rmm);
    vol_tmp2 = zeros(size(vol_tmp));
    n = 0;
    for x = 1:num
        theCurrentCluster = L == x;
        if length(find(theCurrentCluster)) >= str2double(get(handles.VolStaClu_edit,'String'))
            n = n + 1;
            vol_tmp2(logical(theCurrentCluster)) = n;
        end
    end
    DataLow = min(vol_tmp2(:));
    DataHigh = max(vol_tmp2(:));
    if DataLow == 0
        DataLow = min(vol_tmp2(vol_tmp2 ~= 0));
    end
    set(handles.VolROIRange_text,'String',['ROI Index Range:  ',num2str(DataLow,'%6d'),'   ',num2str(DataHigh,'%6d')]);
    EC.vol.roi.drawt = unique(vol_tmp2);
    EC.vol.roi.drawt(EC.vol.roi.drawt == 0) = [];
end
if get(handles.VolROIDrawAll_checkbox,'Value') ~= 1
    if ~isempty(EC.vol.roi.drawcus)
        EC.vol.roi.drawt = eval(['[',EC.vol.roi.drawcus,'];']);
    end
    set(handles.VolROIColor_popupmenu,'Value',1); %% Edited by Mingrui 20140509, fix the bug that the popupmenu disappeared when changing ROI selections
end
textcell = cell(length(EC.vol.roi.drawt),1);
for i = 1:length(textcell)
    textcell{i} = ['ROI ',num2str(EC.vol.roi.drawt(i))];
end
set(handles.VolROIColor_popupmenu,'String',textcell);





% --- Executes during object creation, after setting all properties.
function VolStaThr_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VolStaThr_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function VolStaP_edit_Callback(hObject, eventdata, handles)
% hObject    handle to VolStaP_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of VolStaP_edit as text
%        str2double(get(hObject,'String')) returns contents of VolStaP_edit as a double
global surf
global EC
ChangeFlag(handles);
P = str2double(get(hObject,'String'));
switch surf.test
    case 'T'
        Thrd = tinv(1 - P/2,surf.df);
    case 'F'
        Thrd = finv(1 - P, surf.df(1),surf.df(2));
    case 'R'
        TR = tinv(1 - P/2, surf.df);
        Thrd = sqrt(TR^2/(surf.df + TR^2));
    case 'Z'
        Thrd = norminv(1 - P/2);
end
set(handles.VolStaThr_edit,'String',num2str(Thrd));
switch get(handles.VolD_popupmenu,'Value')
    case 1
        set(handles.VolPRn_edit,'String',num2str(Thrd));
        set(handles.VolNRn_edit,'String',['-',num2str(Thrd)]);
    case 2
        set(handles.VolPRn_edit,'String',num2str(Thrd));
    case 3
        set(handles.VolNRn_edit,'String',['-',num2str(Thrd)]);
end
if str2double(get(handles.VolPRx_edit,'String')) < Thrd
    set(handles.VolPRx_edit,'String',num2str(Thrd + 1));
end
if str2double(get(handles.VolNRx_edit,'String')) > -Thrd
    set(handles.VolNRx_edit,'String',num2str(-Thrd - 1));
end

% Added by Mingrui 20140925, draw cluster in statistical files
switch get(handles.VolStaCon_popupmenu,'Value')
    case 1
        rmm = 6;
    case 2
        rmm = 18;
    case 3
        rmm = 26;
end
vol_tmp = surf.vol;
vol_tmp(vol_tmp < str2double(get(handles.VolStaThr_edit,'String')) & vol_tmp > -str2double(get(handles.VolStaThr_edit,'String'))) = 0;
[L, num] = bwlabeln(vol_tmp,rmm);
vol_tmp2 = zeros(size(vol_tmp));
n = 0;
for x = 1:num
    theCurrentCluster = L == x;
    if length(find(theCurrentCluster)) >= str2double(get(handles.VolStaClu_edit,'String'))
        n = n + 1;
        vol_tmp2(logical(theCurrentCluster)) = n;
    end
end
DataLow = min(vol_tmp2(:));
DataHigh = max(vol_tmp2(:));
if DataLow == 0
    DataLow = min(vol_tmp2(vol_tmp2 ~= 0));
end
set(handles.VolROIRange_text,'String',['ROI Index Range:  ',num2str(DataLow,'%6d'),'   ',num2str(DataHigh,'%6d')]);
EC.vol.roi.drawt = unique(vol_tmp2);
EC.vol.roi.drawt(EC.vol.roi.drawt == 0) = [];
if get(handles.VolROIDrawAll_checkbox,'Value') ~= 1
    if ~isempty(EC.vol.roi.drawcus)
        EC.vol.roi.drawt = eval(['[',EC.vol.roi.drawcus,'];']);
    end
    set(handles.VolROIColor_popupmenu,'Value',1); %% Edited by Mingrui 20140509, fix the bug that the popupmenu disappeared when changing ROI selections
end
textcell = cell(length(EC.vol.roi.drawt),1);
for i = 1:length(textcell)
    textcell{i} = ['ROI ',num2str(EC.vol.roi.drawt(i))];
end
set(handles.VolROIColor_popupmenu,'String',textcell);

% --- Executes during object creation, after setting all properties.
function VolStaP_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VolStaP_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function VolStaClu_edit_Callback(hObject, eventdata, handles)
% hObject    handle to VolStaClu_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of VolStaClu_edit as text
%        str2double(get(hObject,'String')) returns contents of VolStaClu_edit as a double
global surf
global EC
ChangeFlag(handles);

% Added by Mingrui 20140925, draw cluster in statistical files
if ~strcmp(surf.test,'No')
    switch get(handles.VolStaCon_popupmenu,'Value')
        case 1
            rmm = 6;
        case 2
            rmm = 18;
        case 3
            rmm = 26;
    end
    vol_tmp = surf.vol;
    vol_tmp(vol_tmp < str2double(get(handles.VolStaThr_edit,'String')) & vol_tmp > -str2double(get(handles.VolStaThr_edit,'String'))) = 0;
    [L, num] = bwlabeln(vol_tmp,rmm);
    vol_tmp2 = zeros(size(vol_tmp));
    n = 0;
    for x = 1:num
        theCurrentCluster = L == x;
        if length(find(theCurrentCluster)) >= str2double(get(handles.VolStaClu_edit,'String'))
            n = n + 1;
            vol_tmp2(logical(theCurrentCluster)) = n;
        end
    end
    DataLow = min(vol_tmp2(:));
    DataHigh = max(vol_tmp2(:));
    if DataLow == 0
        DataLow = min(vol_tmp2(vol_tmp2 ~= 0));
    end
    set(handles.VolROIRange_text,'String',['ROI Index Range:  ',num2str(DataLow,'%6d'),'   ',num2str(DataHigh,'%6d')]);
    EC.vol.roi.drawt = unique(vol_tmp2);
    EC.vol.roi.drawt(EC.vol.roi.drawt == 0) = [];
end
if get(handles.VolROIDrawAll_checkbox,'Value') ~= 1
    if ~isempty(EC.vol.roi.drawcus)
        EC.vol.roi.drawt = eval(['[',EC.vol.roi.drawcus,'];']);
    end
    set(handles.VolROIColor_popupmenu,'Value',1); %% Edited by Mingrui 20140509, fix the bug that the popupmenu disappeared when changing ROI selections
end
textcell = cell(length(EC.vol.roi.drawt),1);
for i = 1:length(textcell)
    textcell{i} = ['ROI ',num2str(EC.vol.roi.drawt(i))];
end
set(handles.VolROIColor_popupmenu,'String',textcell);

% --- Executes during object creation, after setting all properties.
function VolStaClu_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VolStaClu_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function VolStaCon_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to VolStaCon_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of VolStaCon_popupmenu as text
%        str2double(get(hObject,'String')) returns contents of VolStaCon_popupmenu as a double
global surf
global EC
ChangeFlag(handles);

% Added by Mingrui 20140925, draw cluster in statistical files
if ~strcmp(surf.test,'No')
    switch get(handles.VolStaCon_popupmenu,'Value')
        case 1
            rmm = 6;
        case 2
            rmm = 18;
        case 3
            rmm = 26;
    end
    vol_tmp = surf.vol;
    vol_tmp(vol_tmp < str2double(get(handles.VolStaThr_edit,'String')) & vol_tmp > -str2double(get(handles.VolStaThr_edit,'String'))) = 0;
    [L, num] = bwlabeln(vol_tmp,rmm);
    vol_tmp2 = zeros(size(vol_tmp));
    n = 0;
    for x = 1:num
        theCurrentCluster = L == x;
        if length(find(theCurrentCluster)) >= str2double(get(handles.VolStaClu_edit,'String'))
            n = n + 1;
            vol_tmp2(logical(theCurrentCluster)) = n;
        end
    end
    DataLow = min(vol_tmp2(:));
    DataHigh = max(vol_tmp2(:));
    if DataLow == 0
        DataLow = min(vol_tmp2(vol_tmp2 ~= 0));
    end
    set(handles.VolROIRange_text,'String',['ROI Index Range:  ',num2str(DataLow,'%6d'),'   ',num2str(DataHigh,'%6d')]);
    EC.vol.roi.drawt = unique(vol_tmp2);
    EC.vol.roi.drawt(EC.vol.roi.drawt == 0) = [];
end
if get(handles.VolROIDrawAll_checkbox,'Value') ~= 1
    if ~isempty(EC.vol.roi.drawcus)
        EC.vol.roi.drawt = eval(['[',EC.vol.roi.drawcus,'];']);
    end
    set(handles.VolROIColor_popupmenu,'Value',1); %% Edited by Mingrui 20140509, fix the bug that the popupmenu disappeared when changing ROI selections
end
textcell = cell(length(EC.vol.roi.drawt),1);
for i = 1:length(textcell)
    textcell{i} = ['ROI ',num2str(EC.vol.roi.drawt(i))];
end
set(handles.VolROIColor_popupmenu,'String',textcell);

% --- Executes during object creation, after setting all properties.
function VolStaCon_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VolStaCon_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EdgOpaSam_edit_Callback(hObject, eventdata, handles)
% hObject    handle to EdgOpaSam_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EdgOpaSam_edit as text
%        str2double(get(hObject,'String')) returns contents of EdgOpaSam_edit as a double
ChangeFlag(handles);

% --- Executes during object creation, after setting all properties.
function EdgOpaSam_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgOpaSam_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EdgOpaValMin_edit_Callback(hObject, eventdata, handles)
% hObject    handle to EdgOpaValMin_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EdgOpaValMin_edit as text
%        str2double(get(hObject,'String')) returns contents of EdgOpaValMin_edit as a double
ChangeFlag(handles);

% --- Executes during object creation, after setting all properties.
function EdgOpaValMin_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgOpaValMin_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EdgOpaValMax_edit_Callback(hObject, eventdata, handles)
% hObject    handle to EdgOpaValMax_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EdgOpaValMax_edit as text
%        str2double(get(hObject,'String')) returns contents of EdgOpaValMax_edit as a double
ChangeFlag(handles);

% --- Executes during object creation, after setting all properties.
function EdgOpaValMax_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgOpaValMax_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in EdgOpaAbs_checkbox.
function EdgOpaAbs_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to EdgOpaAbs_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of EdgOpaAbs_checkbox
ChangeFlag(handles);

% --- Executes when selected object is changed in EdgOpa_uipanel.
function EdgOpa_uipanel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in EdgOpa_uipanel
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
ChangeFlag(handles);
if get(handles.EdgOpaSam_radiobutton,'Value')==1
    set(handles.EdgOpaSam_edit,'Enable','on');
    set(handles.EdgOpaValMin_edit,'Enable','off');
    set(handles.EdgOpaValMax_edit,'Enable','off');
    set(handles.EdgOpaAbs_checkbox,'Enable','off');
else
    set(handles.EdgOpaSam_edit,'Enable','off');
    set(handles.EdgOpaValMin_edit,'Enable','on');
    set(handles.EdgOpaValMax_edit,'Enable','on');
    set(handles.EdgOpaAbs_checkbox,'Enable','on');
end



% --- Executes on button press in EdgColorCostum_pushbutton.
function EdgColorCostum_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to EdgColorCostum_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global EC
global surf
ChangeFlag(handles);
[filename,pathname]=uigetfile({'*.txt','Text files (*.txt)';'*.*','All Files (*.*)'});
if isequal(filename,0)||isequal(pathname,0)
    return;
else
    fpath=fullfile(pathname,filename);
    fid = fopen(fpath);
    data = textscan(fid,'%f','CommentStyle','#');
    EC.edg.color_custom_matrix = reshape(data{1},[sqrt(length(data{1})),sqrt(length(data{1}))])';
    fclose(fid);
    if isequal(size(EC.edg.color_custom_matrix),size(surf.net))
        H = BrainNet_EdgCostumColor;
    else
        msgbox('The size of the color matrix does not match the edge file','Warning','warn');
    end
end


% --- Executes on button press in VolNCS_pushbutton.
function VolNCS_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to VolNCS_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(hObject,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- Executes on button press in VolROIColorSQ_pushbutton.
function VolROIColorSQ_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to VolROIColorSQ_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global EC
c=uisetcolor('Select Color');
if length(c)==3
    EC.vol.roi.colort(get(handles.VolROIColor_popupmenu,'Value'),:) = c;
    set(hObject,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- Executes on button press in EdgCS_pushbutton.
function EdgCS_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to EdgCS_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.EdgCS_pushbutton,'BackgroundColor',c);
end
ChangeFlag(handles);


% --- Executes on button press in EdgCTL_pushbutton.
function EdgCTL_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to EdgCTL_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.EdgCTL_pushbutton,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- Executes on button press in EdgCTH_pushbutton.
function EdgCTH_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to EdgCTH_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.EdgCTH_pushbutton,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- Executes on button press in EdgCDL_pushbutton.
function EdgCDL_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to EdgCDL_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.EdgCDL_pushbutton,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- Executes on button press in EdgCDH_pushbutton.
function EdgCDH_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to EdgCDH_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.EdgCDH_pushbutton,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- Executes on button press in NodCS_pushbutton.
function NodCS_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to NodCS_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.NodCS_pushbutton,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- Executes on button press in NodCTL_pushbutton.
function NodCTL_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to NodCTL_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.NodCTL_pushbutton,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- Executes on button press in NodCTH_pushbutton.
function NodCTH_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to NodCTH_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.NodCTH_pushbutton,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- Executes on button press in MshC_pushbutton.
function MshC_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to MshC_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.MshC_pushbutton,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- Executes on button press in BakC_pushbutton.
function BakC_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to BakC_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c=uisetcolor('Select Color');
if length(c)==3
    set(handles.BakC_pushbutton,'BackgroundColor',c);
    ChangeFlag(handles);
end



function NodCC_low_edit_Callback(hObject, eventdata, handles)
% hObject    handle to NodCC_low_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NodCC_low_edit as text
%        str2double(get(hObject,'String')) returns contents of NodCC_low_edit as a double
if isnan(str2double(get(hObject,'String'))) == 1
    set(hObject,'String',num2str(0));
    msgbox('Please input a number.','Warning','warn');
    % elseif str2double(get(hObject,'String'))>str2double(get(handles.NodCC_high_edit,'String'))
    %     set(hObject,'String',str2double(get(handles.NodCC_high_edit,'String'))-1);
    %     msgbox('Please input a smaller number .','Warning','warn');
end
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function NodCC_low_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NodCC_low_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function NodCC_high_edit_Callback(hObject, eventdata, handles)
% hObject    handle to NodCC_high_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NodCC_high_edit as text
%        str2double(get(hObject,'String')) returns contents of NodCC_high_edit as a double
if isnan(str2double(get(hObject,'String'))) == 1 || str2double(get(hObject,'String'))<str2double(get(handles.NodCC_low_edit,'String'))
    set(hObject,'String',str2double(get(handles.NodCC_low_edit,'String'))+1);
    msgbox('Please input a number that is larger than the low end.','Warning','warn');
end
ChangeFlag(handles);

% --- Executes during object creation, after setting all properties.
function NodCC_high_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NodCC_high_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in NodCC_Range_popupmenu.
function NodCC_Range_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to NodCC_Range_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns NodCC_Range_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from NodCC_Range_popupmenu
if get(hObject,'Value')==1
    set(handles.NodCC_low_edit,'Enable','off');
    set(handles.NodCC_high_edit,'Enable','off');
else
    set(handles.NodCC_low_edit,'Enable','on');
    set(handles.NodCC_high_edit,'Enable','on');
end
ChangeFlag(handles);


% --- Executes on selection change in EdgCC_Range_popupmenu.
function EdgCC_Range_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to EdgCC_Range_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns EdgCC_Range_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from EdgCC_Range_popupmenu
if get(hObject,'Value')==1
    set(handles.EdgCC_low_edit,'Enable','off');
    set(handles.EdgCC_high_edit,'Enable','off');
else
    set(handles.EdgCC_low_edit,'Enable','on');
    set(handles.EdgCC_high_edit,'Enable','on');
end
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function EdgCC_Range_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgCC_Range_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EdgCC_low_edit_Callback(hObject, eventdata, handles)
% hObject    handle to EdgCC_low_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EdgCC_low_edit as text
%        str2double(get(hObject,'String')) returns contents of EdgCC_low_edit as a double
if isnan(str2double(get(hObject,'String'))) == 1
    set(hObject,'String',num2str(0));
    msgbox('Please input a number.','Warning','warn');
end
ChangeFlag(handles);

% --- Executes during object creation, after setting all properties.
function EdgCC_low_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgCC_low_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EdgCC_high_edit_Callback(hObject, eventdata, handles)
% hObject    handle to EdgCC_high_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EdgCC_high_edit as text
%        str2double(get(hObject,'String')) returns contents of EdgCC_high_edit as a double
if isnan(str2double(get(hObject,'String'))) == 1 || str2double(get(hObject,'String'))<str2double(get(handles.EdgCC_low_edit,'String'))
    set(hObject,'String',str2double(get(handles.EdgCC_low_edit,'String'))+1);
    msgbox('Please input a number that is larger than the low end.','Warning','warn');
end
ChangeFlag(handles);

% --- Executes during object creation, after setting all properties.
function EdgCC_high_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdgCC_high_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in VolROIColor_load_pushbutton.
function VolROIColor_load_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to VolROIColor_load_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global EC
[filename,pathname]=uigetfile({'*.txt','Text files (*.txt)';'*.*','All Files (*.*)'});
if isequal(filename,0)||isequal(pathname,0)
    return;
else
    fpath=fullfile(pathname,filename);
    fid = fopen(fpath);
    data = textscan(fid,'%f','CommentStyle','#');
    fclose(fid);
    tmp = reshape(data{1},[3,length(data{1})/3])';
    if max(tmp(:))>1
        tmp = tmp./255;
    end
    EC.vol.roi.colort(1:length(data{1})/3,:) = tmp;
    set(handles.VolROIColorSQ_pushbutton,'BackgroundColor',EC.vol.roi.colort(get(handles.VolROIColor_popupmenu,'Value'),:));
end
ChangeFlag(handles);


% --- Executes on button press in GlbLR_checkbox.
function GlbLR_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to GlbLR_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of GlbLR_checkbox
ChangeFlag(handles);


% --- Executes on selection change in VolROISmooth_popupmenu.
function VolROISmooth_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to VolROISmooth_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns VolROISmooth_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from VolROISmooth_popupmenu
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function VolROISmooth_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VolROISmooth_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Lbl_front_checkbox.
function Lbl_front_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to Lbl_front_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Lbl_front_checkbox
ChangeFlag(handles);


% --- Executes on selection change in Mesh_boundary_popupmenu.
function Mesh_boundary_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to Mesh_boundary_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Mesh_boundary_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Mesh_boundary_popupmenu
global EC
global surf
switch get(hObject,'Value')
    case 1
        set(handles.Mesh_boundary_edit,'Enable','off');
        set(handles.Mesh_boundary_pushbutton,'Enable','off');
    case 2
        set(handles.Mesh_boundary_edit,'Enable','off');
        set(handles.Mesh_boundary_pushbutton,'Enable','on');
    case 3
        set(handles.Mesh_boundary_edit,'Enable','on');
        set(handles.Mesh_boundary_pushbutton,'Enable','on');
    case 4
        set(handles.Mesh_boundary_edit,'Enable','off');
        set(handles.Mesh_boundary_pushbutton,'Enable','on');
        [filename,pathname]=uigetfile({'*.txt','Text files (*.txt)';'*.*','All Files (*.*)'});
        if isequal(filename,0)||isequal(pathname,0)
            set(hObject,'Value',EC.msh.boundary);
            return;
        else
            fpath=fullfile(pathname,filename);
            fid = fopen(fpath);
            data = textscan(fid,'%f','CommentStyle','#');
            fclose(fid);
            EC.msh.boundary_value_tmp = cell2mat(data);
            if length(EC.msh.boundary_value_tmp) ~= surf.vertex_number
                msgbox('The boundary file does not match this brain surface.','Error','error');
                set(hObject,'Value',EC.msh.boundary);
            end
        end
end
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function Mesh_boundary_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Mesh_boundary_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Mesh_boundary_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Mesh_boundary_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Mesh_boundary_edit as text
%        str2double(get(hObject,'String')) returns contents of Mesh_boundary_edit as a double
ChangeFlag(handles);


% --- Executes during object creation, after setting all properties.
function Mesh_boundary_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Mesh_boundary_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Mesh_boundary_pushbutton.
function Mesh_boundary_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Mesh_boundary_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c = uisetcolor('Select Color');
if length(c) == 3
    set(hObject,'BackgroundColor',c);
    ChangeFlag(handles);
end


% --- Executes on selection change in Mesh_color_popupmenu.
function Mesh_color_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to Mesh_color_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Mesh_color_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Mesh_color_popupmenu
global EC
global surf
switch get(hObject,'Value')
    case 1
        set(handles.MshC_pushbutton,'Enable','on');
    case 2
        set(handles.MshC_pushbutton,'Enable','off');
        [filename,pathname]=uigetfile({'*.txt','Text files (*.txt)';'*.*','All Files (*.*)'});
        if isequal(filename,0)||isequal(pathname,0)
            set(hObject,'Value',1);
            return;            
        else
            fpath=fullfile(pathname,filename);
            fid = fopen(fpath);
            data = textscan(fid,'%f','CommentStyle','#');
            fclose(fid);
            EC.msh.color_table_tmp = reshape(cell2mat(data),3,[])';
            if length(EC.msh.color_table_tmp) ~= surf.vertex_number
                msgbox('The color table does not match this brain surface.','Error','error');
                set(hObject,'Value',1);
            end
        end
end
ChangeFlag(handles);

% --- Executes during object creation, after setting all properties.
function Mesh_color_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Mesh_color_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
