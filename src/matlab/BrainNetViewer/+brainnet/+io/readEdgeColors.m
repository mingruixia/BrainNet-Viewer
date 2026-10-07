function [data,map]=readEdgeColors(path,map)
%READEDGECOLORS Read strict whitespace matrix or JSON matrix/indices/colors.
path=string(path); info=dir(path);
if ~isscalar(info)||info.isdir||info.bytes>64000000
    error('BNV:EdgeCustom:File','Choose a color matrix file no larger than 64 MB.');
end
[folder,name,extension]=fileparts(path); data=brainnet.core.CustomEdgeColors.empty();
if strcmpi(extension,'.json')
    value=jsondecode(fileread(path));
    if ~isstruct(value)||~isscalar(value)||~all(isfield(value,{'matrix','indices','colors'}))
        error('BNV:EdgeCustom:File','JSON requires matrix, indices and colors.');
    end
    data.matrix=value.matrix; data.indices=value.indices; map=value.colors;
    if isnumeric(map)&&isequal(size(map),[1 3]), map=[map;map]; end
    map=brainnet.core.Colormap.validate(map);
else
    if ~any(strcmpi(extension,{'.txt','.edge'})), error('BNV:EdgeCustom:File','Choose .txt, .edge or .json.'); end
    if strlength(folder)==0, folder=string(pwd); end
    reference=brainnet.core.InputReference('edge',name+extension);
    edge=brainnet.io.readEdges(reference,folder); data.matrix=edge.Matrix;
    data.indices=unique(data.matrix(:),'sorted').';
end
data.source=char(path); data=brainnet.core.CustomEdgeColors.validate(data);
brainnet.core.CustomEdgeColors.palette(map,numel(data.indices));
end
