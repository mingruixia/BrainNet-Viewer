function varargout = BrainNet_MergeMesh(varargin)
% BrainNet_MergeMesh MATLAB code for BrainNet_MergeMesh.fig
%      BrainNet_MergeMesh, by itself, creates a new BrainNet_MergeMesh or raises the existing
%      singleton*.
%
%      H = BrainNet_MergeMesh returns the handle to a new BrainNet_MergeMesh or the handle to
%      the existing singleton*.
%
%      BrainNet_MergeMesh('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BrainNet_MergeMesh.M with the given input arguments.
%
%      BrainNet_MergeMesh('Property','Value',...) creates a new BrainNet_MergeMesh or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BrainNet_MergeMesh_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BrainNet_MergeMesh_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BrainNet_MergeMesh

% Last Modified by GUIDE v2.5 26-Oct-2011 19:56:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @BrainNet_MergeMesh_OpeningFcn, ...
    'gui_OutputFcn',  @BrainNet_MergeMesh_OutputFcn, ...
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


% --- Executes just before BrainNet_MergeMesh is made visible.
function BrainNet_MergeMesh_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to BrainNet_MergeMesh (see VARARGIN)

% Choose default command line output for BrainNet_MergeMesh
handles.output = hObject;
guidata(hObject, handles);
h_NV=findobj('Tag','NV_fig');
h_NV=guihandles(h_NV);
setappdata(handles.MM_fig,'h_NV',h_NV);
movegui(handles.MM_fig,'center');


% Update handles structure


% UIWAIT makes BrainNet_MergeMesh wait for user response (see UIRESUME)
% uiwait(handles.MM_fig);


% --- Outputs from this function are returned to the command line.
function varargout = BrainNet_MergeMesh_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in OK_button.
function OK_button_Callback(hObject, eventdata, handles)
% hObject    handle to OK_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

Mesh.ML=get(handles.ML_edit,'string');
Mesh.MR=get(handles.MR_edit,'string');
Mesh.MN=get(handles.MN_edit,'string');
if isempty(Mesh.ML)&&isempty(Mesh.MR)
    h=msgbox('Please select mesh files!','Error','error');
    uiwait(h);
    return;
elseif isempty(Mesh.MN)
    h=msgbox('Please select save files!','Error','error');
    uiwait(h);
    return;
end
if isempty(Mesh.ML)
    MergeMesh1(Mesh.MR,Mesh.MN);
elseif isempty(Mesh.MR)
    MergeMesh1(Mesh.ML,Mesh.MN);
else
    MergeMesh1(Mesh.ML,Mesh.MR,Mesh.MN);
end

function [vertex, faces, vertex_number, face_number] =loadpial(filename)
fid = fopen(filename, 'rb', 'b') ;
b1 = fread(fid, 1, 'uchar') ;
b2 = fread(fid, 1, 'uchar') ;
b3 = fread(fid, 1, 'uchar') ;
magic = bitshift(b1, 16) + bitshift(b2,8) + b3 ;
fgets(fid);
fgets(fid);
v = fread(fid, 1, 'int32') ;
t = fread(fid, 1, 'int32') ;
vertex= fread(fid, [3 v], 'float32') ;
faces= fread(fid, [3 t], 'int32')' + 1 ;
fclose(fid) ;
vertex_number=size(vertex,2);
face_number=size(faces,1);




function MergeMesh1(filename1,filename2,filename3)
if nargin<3
    [pathstr,name,ext] = fileparts(filename1);
    switch ext
        case '.mesh'
            [vertex1, faces1, surf.vertex_number, surf.ntri] = loadmesh(filename1);
            surf.coord=vertex1';
            surf.coord(1,:)=91-surf.coord(1,:);
            surf.coord(2,:)=91-surf.coord(2,:);
            surf.coord(3,:)=109-surf.coord(3,:);
            surf.tri=faces1+1;
        case '.pial'
            [surf.coord, surf.tri, surf.vertex_number, surf.ntri] =loadpial(filename1);
    end
    fid = fopen(filename2,'wt');
    fprintf(fid,'%d\n',surf.vertex_number);
    for i=1:surf.vertex_number
        fprintf(fid,'%f %f %f\n',surf.coord(1:3,i));
    end
    fprintf(fid, '%d\n', surf.ntri);
    for i=1:surf.ntri
        fprintf(fid,'%d %d %d\n',surf.tri(i,1:3));
    end
    fclose(fid);
    msgbox('Mesh was successfully created!','Success','help');
else
    [pathstr,name,ext] = fileparts(filename1);
    switch ext
        % Edited by Mingrui 20120930, add support for nv file.
        case '.nv'
            fid = fopen(filename1);
            vertex_number1 = fscanf(fid,'%f',1);
            vertex1 = fscanf(fid,'%f',[3,vertex_number1]);
            vertex1 = vertex1';
            faces_number1 = fscanf(fid,'%f',1);
            faces1 = fscanf(fid,'%d',[3,faces_number1])';
            fclose(fid);        
        case '.mesh'
            [vertex1, faces1, vertex_number1, faces_number1] = loadmesh(filename1);
            vertex1(:,1)=91-vertex1(:,1);
            vertex1(:,2)=91-vertex1(:,2);
            vertex1(:,3)=109-vertex1(:,3);
            faces1=faces1+1;
        case '.pial'
            [vertex1, faces1, vertex_number1, faces_number1] =loadpial(filename1);
            vertex1=vertex1';
    end
    [pathstr,name,ext] = fileparts(filename2);
    switch ext
        % Edited by Mingrui 20120930, add support for nv file.
        case '.nv'
            fid = fopen(filename2);
            vertex_number2 = fscanf(fid,'%f',1);
            vertex2 = fscanf(fid,'%f',[3,vertex_number2]);
            vertex2 = vertex2';
            faces_number2 = fscanf(fid,'%f',1);
            faces2 = fscanf(fid,'%d',[3,faces_number2])';
            fclose(fid);
        case '.mesh'
            [vertex2, faces2, vertex_number2, faces_number2] = loadmesh(filename2);
            vertex2(:,1)=91-vertex2(:,1);
            vertex2(:,2)=91-vertex2(:,2);
            vertex2(:,3)=109-vertex2(:,3);
            faces2=faces2+1;
        case '.pial'
            [vertex2, faces2, vertex_number2, faces_number2] =loadpial(filename2);
            vertex2=vertex2';
    end
    
    surf.vertex_number=vertex_number1+vertex_number2;
    surf.coord=[vertex1',vertex2'];
    surf.ntri=faces_number1+faces_number2;
    surf.tri=[(faces1)',(faces2+vertex_number1)']';
%     surf.coord(3,:) = surf.coord(3,:) + 13;
%     surf.coord(2,:) = surf.coord(2,:) -13;
    
    fid = fopen(filename3,'wt');
    fprintf(fid,'%d\n',surf.vertex_number);
    for i=1:surf.vertex_number
        fprintf(fid,'%f %f %f\n',surf.coord(1:3,i));
    end
    fprintf(fid, '%d\n', surf.ntri);
    for i=1:surf.ntri
        fprintf(fid,'%d %d %d\n',surf.tri(i,1:3));
    end
    fclose(fid);
    msgbox('Mesh was successfully created!','Success','help');
end


% --- Executes on button press in ML_button.
function ML_button_Callback(hObject, eventdata, handles)
% hObject    handle to ML_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Edited by Mingrui 20120930, add support for nv file.
[filename,pathname]=uigetfile({'*.nv','BrainNet Surface (*.nv)';...
    '*.mesh','BrainVISA Mesh (*.mesh)';...
    '*.pial','FreeSurfer Mesh (*.pial)';'*.*','All Files (*.*)'});
if isequal(filename,0)||isequal(pathname,0)
    return;
else
    fpath=fullfile(pathname,filename);
    set(handles.ML_edit,'string',fpath);
end


function ML_edit_Callback(hObject, eventdata, handles)
% hObject    handle to ML_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ML_edit as text
%        str2double(get(hObject,'String')) returns contents of ML_edit as a double


% --- Executes during object creation, after setting all properties.
function ML_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ML_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function [vertex, faces, vertex_number, faces_number] = loadmesh(filename)

error(nargchk(1,1,nargin));

fid = fopen(filename,'r');
if fid == -1, error(sprintf('[loadmesh] Cannot open %s.',filename)); end

[pathstr, name, format] = fileparts(filename);
if ~ismember(lower(format),{'.mesh'})
    error(sprintf('[loadmesh] Unknown format %s.',format));
end

[file_format, COUNT]       = fread(fid, 5, 'uchar');  %- 'ascii' or 'binar'

switch char(file_format)'
    case 'binar'
        [byte_swapping, COUNT]     = fread(fid, 1, 'uint32'); %- 'ABCD' or 'DCBA'
        ff = strcmp(dec2hex(byte_swapping),'41424344');
        if ~ff
            [fn, pm, mf] = fopen(1); %- machine format
            fclose(fid);
            if strmatch(mf,'ieee-le');
                fid = fopen(filename,'r','ieee-be');
            else
                fid = fopen(filename,'r','ieee-le');
            end
            [file_format, COUNT]   = fread(fid, 5, 'uchar');
            [byte_swapping, COUNT] = fread(fid, 1, 'uint32');
        end
        [arg_size, COUNT]          = fread(fid, 1, 'uint32'); %- length('VOID')
        [VOID, COUNT]              = fread(fid, arg_size, 'uchar'); %- VOID
        
        
        [polygon_dimension, COUNT] = fread(fid, 1, 'uint32'); %- 3 for triangles
        [mesh_time, COUNT]         = fread(fid, 1, 'uint32'); %- number of meshes
        
        vertex = cell(1,mesh_time);
        normals = cell(1,mesh_time);
        faces = cell(1,mesh_time);
        for i=1:mesh_time
            [mesh_step, COUNT]     = fread(fid, 1, 'uint32'); %- [0 ... mesh_time-1]
            
            %- Get vertices
            [vertex_number, COUNT] = fread(fid, 1, 'uint32');
            [vtx, COUNT]           = fread(fid, 3*vertex_number, 'float32');
            vertex{i} = reshape(vtx, 3, vertex_number)';
            
            %- Get normals
            [normal_number, COUNT] = fread(fid, 1, 'uint32');
            [nrml, COUNT]          = fread(fid, 3*normal_number, 'float32');
            normal{i} = reshape(nrml, 3, normal_number)';
            
            [arg_size, COUNT]      = fread(fid, 1, 'uint32'); %- no data ('VOID')
            
            %- Get faces
            [faces_number, COUNT]  = fread(fid, 1, 'uint32');
            [fcs, COUNT] = fread(fid, polygon_dimension*faces_number, 'uint32');
            faces{i} = reshape(fcs, polygon_dimension, faces_number)';
        end
    case 'ascii'
        VOID = fscanf(fid,'%s',1);
        polygon_dimension = fscanf(fid,'%d',1);
        mesh_time = fscanf(fid,'%d',1);
        
        for i=1:mesh_time
            mesh_step = fscanf(fid,'\n%d',1);
            
            vertex_number = fscanf(fid,'\n%d\n',1);
            vtx = fscanf(fid,'(%f ,%f ,%f) ',3*vertex_number);
            vertex{i} = reshape(vtx, 3, vertex_number)';
            
            normal_number = fscanf(fid,'\n%d\n',1);
            nrml = fscanf(fid,'(%f ,%f ,%f) ',3*normal_number);
            normal{i} = reshape(nrml, 3, normal_number)';
            
            arg_size = fscanf(fid,'\n%d\n',1);
            
            faces_number = fscanf(fid,'\n%d\n',1);
            fcs = fscanf(fid,'(%d ,%d ,%d) ',polygon_dimension*faces_number);
            faces{i} = reshape(fcs, polygon_dimension, faces_number)';
        end
end

if mesh_time == 1
    vertex = vertex{1};
    normal = normal{1};
    faces = faces{1};
end

fclose(fid);
if fid == -1, error(sprintf('[loadmesh] Cannot close %s.',filename)); end



% --- Executes on button press in Cancel_button.
function Cancel_button_Callback(hObject, eventdata, handles)
% hObject    handle to Cancel_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(findobj('Tag','MM_fig'));


function MR_edit_Callback(hObject, eventdata, handles)
% hObject    handle to MR_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MR_edit as text
%        str2double(get(hObject,'String')) returns contents of MR_edit as a double


% --- Executes during object creation, after setting all properties.
function MR_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MR_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in MR_button.
function MR_button_Callback(hObject, eventdata, handles)
% hObject    handle to MR_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Edited by Mingrui 20120930, add support for nv file.
[filename,pathname]=uigetfile({'*.nv','BrainNet Surface (*.nv)';...
    '*.mesh','BrainVISA Mesh (*.mesh)';...
    '*.pial','FreeSurfer Mesh (*.pial)';'*.*','All Files (*.*)'});
if isequal(filename,0)||isequal(pathname,0)
    return;
else
    fpath=fullfile(pathname,filename);
    set(handles.MR_edit,'string',fpath);
end



% --- Executes on button press in Reset_button.
function Reset_button_Callback(hObject, eventdata, handles)
% hObject    handle to Reset_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.ML_edit,'string','');
set(handles.MR_edit,'string','');
set(handles.MN_edit,'string','');


function MN_edit_Callback(hObject, eventdata, handles)
% hObject    handle to MN_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MN_edit as text
%        str2double(get(hObject,'String')) returns contents of MN_edit as a double


% --- Executes during object creation, after setting all properties.
function MN_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MN_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in MN_button.
function MN_button_Callback(hObject, eventdata, handles)
% hObject    handle to MN_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename,pathname]=uiputfile({'*.nv','Net Viewer file (*.nv)'});
if isequal(filename,0)||isequal(pathname,0)
    return;
else
    fpath=fullfile(pathname,filename);
    set(handles.MN_edit,'string',fpath);
end
