function varargout = BrainNet_EdgCostumColor(varargin)
% BrainNet_EdgCostumColor MATLAB code for BrainNet_EdgCostumColor.fig
%      BrainNet_EdgCostumColor, by itself, creates a new BrainNet_EdgCostumColor or raises the existing
%      singleton*.
%
%      H = BrainNet_EdgCostumColor returns the handle to a new BrainNet_EdgCostumColor or the handle to
%      the existing singleton*.
%
%      BrainNet_EdgCostumColor('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BrainNet_EdgCostumColor.M with the given input arguments.
%
%      BrainNet_EdgCostumColor('Property','Value',...) creates a new BrainNet_EdgCostumColor or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BrainNet_EdgCostumColor_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BrainNet_EdgCostumColor_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BrainNet_EdgCostumColor

% Last Modified by GUIDE v2.5 20-Jan-2015 10:09:48

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @BrainNet_EdgCostumColor_OpeningFcn, ...
    'gui_OutputFcn',  @BrainNet_EdgCostumColor_OutputFcn, ...
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


% --- Executes just before BrainNet_EdgCostumColor is made visible.
function BrainNet_EdgCostumColor_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to BrainNet_EdgCostumColor (see VARARGIN)

% Choose default command line output for BrainNet_EdgCostumColor
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes BrainNet_EdgCostumColor wait for user response (see UIRESUME)
% uiwait(handles.EdgColorCostum_fig);
% h_EP=findobj('Tag','EP_fig');
% h_EP=guihandles(h_EP);
% setappdata(handles.EdgColorCostum_fig,'h_EP',h_EP);
movegui(handles.EdgColorCostum_fig,'center');

global EC
EC.edg.color_custom_index = sort(unique(EC.edg.color_custom_matrix(:)));
textcell = cell(length(EC.edg.color_custom_index),1);
EC.edg.CM_tmp = EC.edg.CM_custom;
for i = 1:length(textcell)
    textcell{i} = ['Index',num2str(EC.edg.color_custom_index(i))];
end
set(handles.popupmenu1,'String',textcell);
set(handles.popupmenu2,'String',textcell);
set(handles.popupmenu3,'String',textcell);
set(handles.popupmenu4,'String',textcell);
set(handles.popupmenu5,'String',textcell);
set(handles.popupmenu6,'String',textcell);

for i = 5:-1:0
    if length(textcell) > i
        for j = (i+1):-1:1
            ind = num2str(j);
            eval(['set(handles.text',ind ',''BackgroundColor'',EC.edg.CM_tmp(',ind,',:));']);
            eval(['set(handles.popupmenu',ind,',''Value'',',ind,');']);
        end
        for j = 6:-1:i+2
            ind = num2str(j);
            eval(['set(handles.text',ind ',''Enable'',''off'');']);
            eval(['set(handles.popupmenu',ind,',''Enable'',''off'');']);
        end
        break;
    end    
end
        
% 
% set(handles.text1,'BackgroundColor',EC.edg.CM_tmp(1,:));
% set(handles.text2,'BackgroundColor',EC.edg.CM_tmp(2,:));
% set(handles.text3,'BackgroundColor',EC.edg.CM_tmp(3,:));
% set(handles.text4,'BackgroundColor',EC.edg.CM_tmp(4,:));
% set(handles.text5,'BackgroundColor',EC.edg.CM_tmp(5,:));
% set(handles.text6,'BackgroundColor',EC.edg.CM_tmp(6,:));




% --- Outputs from this function are returned to the command line.
function varargout = BrainNet_EdgCostumColor_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1
global EC
val=get(handles.popupmenu1,'Value');
set(handles.text1,'BackgroundColor',EC.edg.CM_tmp(val,:));


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global EC
EC.edg.CM_custom = EC.edg.CM_tmp;
close(findobj('Tag','EdgColorCostum_fig'));


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(findobj('Tag','EdgColorCostum_fig'));


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over text1.
function text1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to text1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global EC
c = uisetcolor('Select Color');
if length(c)==3
    set(handles.text1,'BackgroundColor',c);
    EC.edg.CM_tmp(get(handles.popupmenu1,'Value'),:) = c;
end


% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2
global EC
val = get(handles.popupmenu2,'Value');
set(handles.text2,'BackgroundColor',EC.edg.CM_tmp(val,:));


% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu3.
function popupmenu3_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu3
global EC
val = get(handles.popupmenu3,'Value');
set(handles.text3,'BackgroundColor',EC.edg.CM_tmp(val,:));


% --- Executes during object creation, after setting all properties.
function popupmenu3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu4.
function popupmenu4_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu4
global EC
val = get(handles.popupmenu4,'Value');
set(handles.text4,'BackgroundColor',EC.edg.CM_tmp(val,:));


% --- Executes during object creation, after setting all properties.
function popupmenu4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu5.
function popupmenu5_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu5 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu5
global EC
val = get(handles.popupmenu5,'Value');
set(handles.text5,'BackgroundColor',EC.edg.CM_tmp(val,:));


% --- Executes during object creation, after setting all properties.
function popupmenu5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu6.
function popupmenu6_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu6 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu6
global EC
val = get(handles.popupmenu6,'Value');
set(handles.text6,'BackgroundColor',EC.edg.CM_tmp(val,:));


% --- Executes during object creation, after setting all properties.
function popupmenu6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over text2.
function text2_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to text2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global EC
c = uisetcolor('Select Color');
if length(c)==3
    set(handles.text2,'BackgroundColor',c);
    EC.edg.CM_tmp(get(handles.popupmenu2,'Value'),:) = c;
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over text3.
function text3_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to text3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global EC
c = uisetcolor('Select Color');
if length(c)==3
    set(handles.text3,'BackgroundColor',c);
    EC.edg.CM_tmp(get(handles.popupmenu3,'Value'),:) = c;
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over text4.
function text4_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to text4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global EC
c = uisetcolor('Select Color');
if length(c)==3
    set(handles.text4,'BackgroundColor',c);
    EC.edg.CM_tmp(get(handles.popupmenu4,'Value'),:) = c;
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over text5.
function text5_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to text5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global EC
c = uisetcolor('Select Color');
if length(c)==3
    set(handles.text5,'BackgroundColor',c);
    EC.edg.CM_tmp(get(handles.popupmenu5,'Value'),:) = c;
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over text6.
function text6_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to text6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global EC
c = uisetcolor('Select Color');
if length(c)==3
    set(handles.text6,'BackgroundColor',c);
    EC.edg.CM_tmp(get(handles.popupmenu6,'Value'),:) = c;
end
