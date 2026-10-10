function folder = inputStartFolder(rootPath, role)
%INPUTSTARTFOLDER Choose a useful initial folder without restricting input paths.

folder = string(rootPath);
if string(role) == "surface"
    library = fullfile(folder, "Data", "SurfTemplate");
    if isfolder(library)
        folder = library;
    end
end
if any(string(role) == ["node", "edge"])
    library = fullfile(string(rootPath), "Data", "ExampleFiles", "AtlasNetworks");
    if isfolder(library)
        folder = library;
    end
end
if any(string(role) == ["volume", "surface_map"])
    projectRoot = fileparts(fileparts(fileparts(string(rootPath))));
    library = fullfile(projectRoot, "resources", "atlases", "AAL90");
    if isfolder(library)
        folder = library;
    end
end
end
