function folder = inputStartFolder(rootPath, role)
%INPUTSTARTFOLDER Choose a useful initial folder without restricting input paths.

folder = string(rootPath);
if string(role) == "surface"
    library = fullfile(folder, "Data", "SurfTemplate");
    if isfolder(library)
        folder = library;
    end
end
end
