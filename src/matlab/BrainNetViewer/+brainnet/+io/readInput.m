function value=readInput(input,root)
%READINPUT Shared independent reader dispatch for a Scene input reference.
arguments
    input (1,1) brainnet.core.InputReference
    root (1,1) string
end
switch input.Role
    case "surface"
        path=lower(input.RelativePath);
        if any(endsWith(path,[".gii",".gii.gz"])), value=brainnet.io.readGifti(input,root);
        elseif endsWith(path,'.nv'), value=brainnet.io.readSurface(input,root);
        elseif endsWith(path,'.pial'), value=brainnet.io.readFreeSurferSurface(input,root);
        elseif endsWith(path,'.mesh'), value=brainnet.io.readBrainVisaMesh(input,root);
        elseif endsWith(path,'.g'), value=brainnet.io.readByuSurface(input,root);
        elseif endsWith(path,'.obj'), value=brainnet.io.readMniObjSurface(input,root);
        elseif any(endsWith(path,[".mz3",".mz3.gz"])), value=brainnet.io.readMz3Surface(input,root);
        else, error('BNV:IO:UnsupportedSurfaceFormat','Unsupported surface format: %s',path);
        end
    case "node", value=brainnet.io.readNodes(input,root);
    case "edge", value=brainnet.io.readEdges(input,root);
    case "surface_map", value=brainnet.io.readSurfaceMap(input,root);
    case "volume", value=brainnet.io.readNifti(input,root);
end
end
