function writeColormap(colors,path,options)
%WRITECOLORMAP Persist exact RGB rows as JSON or legacy-compatible text.
arguments
    colors
    path (1,1) string
    options.Overwrite (1,1) logical = false
end
colors=brainnet.core.Colormap.validate(colors);
if ~isnumeric(colors), error('BNV:Color:InvalidRGB','Sample a named map before exporting RGB rows.'); end
if isfile(path) && ~options.Overwrite, error('BNV:Color:FileExists','Colormap file already exists.'); end
if endsWith(lower(path),'.json')
    d=struct('kind','brainnet-colormap','schema_version','1.0','colors',colors);
    brainnet.io.internal.writeJsonFile(path,d,Overwrite=options.Overwrite);
elseif endsWith(lower(path),'.txt')
    file=fopen(path,'w','n','UTF-8');
    if file<0, error('BNV:Color:OpenFailed','Cannot create colormap file.'); end
    cleanup=onCleanup(@() fclose(file));
    fprintf(file,'[');
    for i=1:size(colors,1)
        if i>1, fprintf(file,';\n'); end
        fprintf(file,'%.17g %.17g %.17g',colors(i,:));
    end
    fprintf(file,']\n');
else
    error('BNV:Color:Extension','Use .json or .txt for a colormap file.');
end
end
