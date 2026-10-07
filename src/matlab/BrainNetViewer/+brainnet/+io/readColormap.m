function colors=readColormap(path)
%READCOLORMAP Read numeric RGB text or versioned JSON without evaluation.
arguments
    path (1,1) string
end
file=fopen(path,'r','n','UTF-8');
if file<0, error('BNV:Color:OpenFailed','Cannot open colormap file.'); end
cleanup=onCleanup(@() fclose(file));
fseek(file,0,'eof'); count=ftell(file); fseek(file,0,'bof');
if count>1048576, error('BNV:Color:FileLimit','Colormap file exceeds 1 MiB.'); end
text=fscanf(file,'%c');
if endsWith(lower(path),'.json')
    d=jsondecode(text);
    if ~isstruct(d) || ~isscalar(d) || ~isequal(sort(fieldnames(d)),sort({'kind';'schema_version';'colors'})) || ...
            ~isequal(d.kind,'brainnet-colormap') || ~isequal(d.schema_version,'1.0')
        error('BNV:Color:InvalidDocument','Expected a version 1.0 BrainNet colormap JSON.');
    end
    colors=brainnet.core.Colormap.validate(d.colors);
    if ~isnumeric(colors), error('BNV:Color:InvalidRGB','Colormap files must embed an RGB table.'); end
else
    colors=brainnet.core.Colormap.parse(text);
end
end
