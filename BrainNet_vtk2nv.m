function BrainNet_vtk2nv(inputfilename,outputfilename)
fid = fopen(inputfilename);
tmp = textscan(fid,'%s',8,'CommentStyle','#');
vertex_number = str2double(tmp{1}{7});
coord = reshape(cell2mat(textscan(fid,'%f',3*vertex_number)),[3,vertex_number]);
tmp = textscan(fid,'%s',3);
ntri = str2double(tmp{1}{2});
tmp = reshape(cell2mat((textscan(fid,'%d',4*ntri))),[4,ntri]);
tri = tmp(2:end,:)'+1;
fclose(fid);
fid = fopen(outputfilename,'wt');
fprintf(fid,'%d\n',vertex_number);
for i = 1:vertex_number
    fprintf(fid,'%f %f %f\n',coord(1:3,i));
end
fprintf(fid, '%d\n', ntri);
for i = 1:ntri
    fprintf(fid,'%d %d %d\n',tri(i,1:3));
end
fclose(fid);



