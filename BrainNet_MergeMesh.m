function varargout = BrainNet_MergeMesh(varargin)
%BrainNet Viewer, a graph-based brain network mapping tool, by Mingrui Xia
%Function to merge two hemisphere files into one
%-----------------------------------------------------------
%	Copyright(c) 2017
%	State Key Laboratory of Cognitive Neuroscience and Learning, Beijing Normal University
%	Written by Mingrui Xia
%	Mail to Author:  <a href="mingruixia@gmail.com">Mingrui Xia</a>
%   Version 1.6;
%   Date 20110531;
%   Last edited 20170330
%-----------------------------------------------------------
%
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

function [vertex, faces, vertex_number, face_number] = loadg(filename)
fid = fopen(filename);
fscanf(fid,'%f',1);
vertex_number = fscanf(fid,'%f',1);
face_number = fscanf(fid,'%f',1);
fscanf(fid,'%f',3);
vertex = fscanf(fid,'%f',[3,vertex_number]);
tri = fscanf(fid,'%d',[3,ntri])';
faces(:,3) = -tri(:,3);
fclose(fid);

function [vertex, faces, vertex_number, face_number] = loadobjsurf(filename)
fid = fopen(filename);
FirstChar = fscanf(fid,'%1s',1);
if FirstChar == 'P' % ASCII
    fscanf(fid,'%f',5);
    vertex_number = fscanf(fid,'%f',1);
    vertex = fscanf(fid,'%f',[3,vertex_number]);
    fscanf(fid,'%f',[3,vertex_number]);
    face_number = fscanf(fid,'%f',1);
    ind = fscanf(fid,'%f',1);
    if ind == 0
        fscanf(fid,'%f',4);
    else
        fscanf(fid,'%f',[4,vertex_number]);
    end
    fscanf(fid,'%f',face_number);
    faces = fscanf(fid,'%f',[3,face_number])'+1;
    fclose(fid);
else
    fclose(fid);
    fid = fopen(filename,'r','b');
    FirstChar = fread(fid,1);
    if FirstChar == uint8(112) % binary
        fread(fid,5,'float');
        vertex_number = fread(fid,1,'int');
        vertex = fread(fid,[3,vertex_number],'float');
        fread(fid,[3,vertex_number],'float');
        face_number = fread(fid,1,'int');
        ind = fread(fid,1,'int');
        if ind == 0
            uint8(fread(fid,4,'uint8'));
        else
            uint8(fread(fid,[4,vertex_number],'uint8'));
        end
        fread(fid,face_number,'int');
        faces = fread(fid,[3,face_number],'int')'+1;
        fclose(fid);
    end
end

function [vertex, faces, vertex_number, face_number] = loadgii(filename)
g = gifti(filename);
vertex_number = size(g.vertices,1);
vertex = g.vertices';
face_number = size(g.faces,1);
faces = g.faces;

function [vertex, faces, vertex_number, face_number] = loadmz3(filename)
streamCopier = com.mathworks.mlwidgets.io.InterruptibleStreamCopier.getInterruptibleStreamCopier;
baos = java.io.ByteArrayOutputStream;
fis  = java.io.FileInputStream(filename);
zis  = java.util.zip.GZIPInputStream(fis);
streamCopier.copyStream(zis,baos);
fis.close;
data = baos.toByteArray;
%mz3 ALWAYS little endian
machine = 'ieee-le';
magic = typecast(data(1:2),'uint16');
if magic ~= 23117, fprintf('Signature is not MZ3\n'); return; end;
%attr reports attributes and version
attr = typecast(data(3:4),'uint16');
if (attr == 0) || (attr > 7), fprintf('This file uses unsupported features\n'); end;
isFace = bitand(attr,1);
isVert = bitand(attr,2);
isRGBA = bitand(attr,4);
isSCALAR = bitand(attr,8);
%read attributes
nFace = typecast(data(5:8),'uint32');
nVert = typecast(data(9:12),'uint32');
nSkip = typecast(data(13:16),'uint32');
hdrSz = 16+nSkip; %header size in bytes
%read faces
if isFace
    facebytes = nFace * 3 * 4; %each face has 3 indices, each 4 byte int
    faces = typecast(data(hdrSz+1:hdrSz+facebytes),'int32');
    faces = double(faces')+1; %matlab indices arrays from 1 not 0
    %faces = reshape(faces,3,nFace)';
    faces = reshape(faces,3, nFace)';
    hdrSz = hdrSz + facebytes;
end
%read vertices
if isVert
    vertbytes = nVert * 3 * 4; %each vertex has 3 values (x,y,z), each 4 byte float
    vertices = typecast(data(hdrSz+1:hdrSz+vertbytes),'single');
    vertices = double(vertices); %matlab wants doubles
    %vertices = reshape(vertices,nVert,3);
    vertices = reshape(vertices,3,nVert);
    hdrSz = hdrSz + vertbytes;
end
vertex_number = nVert;
vertex = vertices;
face_number = nFace;


function [vertex_number, coord, ntri, tri] = loadnv(filename)
fid=fopen(filename);
        data = textscan(fid,'%f','CommentStyle','#');
        vertex_number = data{1}(1);
        coord  = reshape(data{1}(2:1+3*vertex_number),[3,vertex_number]);
        ntri = data{1}(3*vertex_number+2);
        tri = reshape(data{1}(3*vertex_number+3:end),[3,ntri])';
        fclose(fid);

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
            [surf.coord, surf.tri, surf.vertex_number, surf.ntri] = loadpial(filename1);
        case '.g'
            [surf.coord, surf.tri, surf.vertex_number, surf.ntri] = loadg(filename1);
        case '.obj'
            [surf.coord, surf.tri, surf.vertex_number, surf.ntri] = loadobjsurf(filename1);
        case '.gii'
            [surf.coord, surf.tri, surf.vertex_number, surf.ntri] = loadgii(filename1);
        case '.mz3'
            [surf.coord, surf.tri, surf.vertex_number, surf.ntri] = loadmz3(filename1);
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
%             fid = fopen(filename1);
%             vertex_number1 = fscanf(fid,'%f',1);
%             vertex1 = fscanf(fid,'%f',[3,vertex_number1]);
%             
%             faces_number1 = fscanf(fid,'%f',1);
%             faces1 = fscanf(fid,'%d',[3,faces_number1])';
%             fclose(fid);
            [vertex_number1, vertex1, faces_number1, faces1] = loadnv(filename1);
        case '.mesh'
            [vertex1, faces1, vertex_number1, faces_number1] = loadmesh(filename1);
            vertex1(:,1)=91-vertex1(:,1);
            vertex1(:,2)=91-vertex1(:,2);
            vertex1(:,3)=109-vertex1(:,3);
            faces1=faces1+1;
            vertix1 = vertex1';
        case '.pial'
            [vertex1, faces1, vertex_number1, faces_number1] =loadpial(filename1);
        case '.g'
            [vertex1, faces1, vertex_number1, faces_number1] = loadg(filename1);
        case '.obj'
            [vertex1, faces1, vertex_number1, faces_number1] = loadobjsurf(filename1);
        case '.gii'
            [vertex1, faces1, vertex_number1, faces_number1] = loadgii(filename1);
        case '.mz3'
            [vertex1, faces1, vertex_number1, faces_number1] = loadmz3(filename1);
    end
    [pathstr,name,ext] = fileparts(filename2);
    switch ext
        % Edited by Mingrui 20120930, add support for nv file.
        case '.nv'
%             fid = fopen(filename2);
%             vertex_number2 = fscanf(fid,'%f',1);
%             vertex2 = fscanf(fid,'%f',[3,vertex_number2]);
%             
%             faces_number2 = fscanf(fid,'%f',1);
%             faces2 = fscanf(fid,'%d',[3,faces_number2])';
%             fclose(fid);
            [vertex_number2, vertex2, faces_number2, faces2] = loadnv(filename2);
        case '.mesh'
            [vertex2, faces2, vertex_number2, faces_number2] = loadmesh(filename2);
            vertex2(:,1)=91-vertex2(:,1);
            vertex2(:,2)=91-vertex2(:,2);
            vertex2(:,3)=109-vertex2(:,3);
            faces2=faces2+1;
            vertex2=vertex2';
        case '.pial'
            [vertex2, faces2, vertex_number2, faces_number2] =loadpial(filename2);
        case '.g'
            [vertex2, faces2, vertex_number2, faces_number2] = loadg(filename2);
        case '.obj'
            [vertex2, faces2, vertex_number2, faces_number2] = loadobjsurf(filename2);
        case '.gii'
            [vertex2, faces2, vertex_number2, faces_number2] = loadgii(filename2);
        case '.mz3'
            [vertex2, faces2, vertex_number2, faces_number2] = loadmz3(filename2);
    end
    
    surf.vertex_number=vertex_number1+vertex_number2;
    surf.coord=[vertex1,vertex2];
    surf.ntri=faces_number1+faces_number2;
    surf.tri=[(faces1);(faces2+double(vertex_number1))];
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
[filename,pathname]=uigetfile({'*.nv','NetViewer Files (*.nv)';'*.mesh',...
    'BrainVISA Mesh (*.mesh)';'*.pial','FreeSurfer Mesh (*.pial)';...
    '*.g','BYU file (*.g)';'*.obj','Objective Files (*.obj)';...
    '*.gii','GIfTI Files (*.gii)';...
    '*.mz3','Surf Ice Files (*.mz3)';...
    '*.*','All Files (*.*)'});
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
[filename,pathname]=uigetfile({'*.nv','NetViewer Files (*.nv)';'*.mesh',...
    'BrainVISA Mesh (*.mesh)';'*.pial','FreeSurfer Mesh (*.pial)';...
    '*.g','BYU file (*.g)';'*.obj','Objective Files (*.obj)';...
    '*.gii','GIfTI Files (*.gii)';...
    '*.mz3','Surf Ice Files (*.mz3)';...
    '*.*','All Files (*.*)'});
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
