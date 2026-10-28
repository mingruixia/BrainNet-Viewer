function scene=readPortableScene(path)
%READPORTABLESCENE Verify and cache an explicitly opened portable Scene ZIP.
arguments
    path (1,1) string
end
if ~isfile(path),error('BNV:IO:SceneOpenFailed','Portable Scene does not exist.');end
cacheRoot=fullfile(string(prefdir),'BrainNetViewer','scene-cache');
if ~isfolder(cacheRoot),mkdir(cacheRoot);end
hash=brainnet.io.internal.sha256File(path);cache=fullfile(cacheRoot,hash);
if ~isfolder(cache)
    stage=string(tempname(cacheRoot));mkdir(stage);cleanup=onCleanup(@() removeStage(stage));
    archive=java.util.zip.ZipFile(char(path));closeArchive=onCleanup(@() archive.close());
    if archive.size()>1024,error('BNV:IO:SceneZipLimit','Too many portable Scene members.');end
    entries=archive.entries();seen=strings(0,1);total=0;count=0;
    while entries.hasMoreElements()
        item=entries.nextElement();name=string(char(item.getName()));
        if item.isDirectory(),continue;end
        count=count+1;total=total+double(item.getSize());
        if count>512 || item.getSize()<0 || total>2*1024^3 || ...
                (name=="scene.json"&&item.getSize()>32*1024^2)
            error('BNV:IO:SceneZipLimit','Portable Scene exceeds its file or size limit.');
        end
        normalized=replace(name,"\","/");key=lower(normalized);
        if any(seen==key),error('BNV:IO:SceneZipDuplicate','Repeated portable asset name.');end
        seen(end+1)=key;
        if normalized~="scene.json"&&~startsWith(normalized,"assets/")
            error('BNV:IO:SceneZipEntry','Unexpected portable Scene member.');
        end
        destination=brainnet.io.internal.sceneRelativeFile(stage,normalized);
        parent=fileparts(destination);if ~isfolder(parent),mkdir(parent);end
        stream=archive.getInputStream(item);closeStream=onCleanup(@() stream.close());
        java.nio.file.Files.copy(stream,java.io.File(char(destination)).toPath(),javaArray('java.nio.file.CopyOption',0));
        clear closeStream;
    end
    clear closeArchive;
    if ~any(seen=="scene.json"),error('BNV:IO:SceneZipManifest','Portable Scene has no scene.json.');end
    checkManifest(stage);
    brainnet.io.readScene(fullfile(stage,'scene.json')); % Validate hashes before publishing cache.
    if ~isfolder(cache)
        try
            java.nio.file.Files.move(java.io.File(char(stage)).toPath(),java.io.File(char(cache)).toPath(),javaArray('java.nio.file.CopyOption',0));
        catch exception
            if ~isfolder(cache),rethrow(exception);end
        end
    end
end
checkManifest(cache);
scene=brainnet.io.readScene(fullfile(cache,'scene.json'));
end
function removeStage(folder)
if isfolder(folder),rmdir(folder,'s');end
end

function checkManifest(folder)
path=brainnet.io.internal.sceneRelativeFile(folder,'scene.json');
document=jsondecode(fileread(path));
if ~isfield(document,'metadata')||~isfield(document.metadata,'input_base')|| ...
        ~strcmp(document.metadata.input_base,'scene-directory')
    error('BNV:IO:SceneZipManifest','Portable Scene must declare its own asset directory.');
end
if isfield(document,'inputs')
    for role=reshape(string(fieldnames(document.inputs)),1,[])
        ref=document.inputs.(role);
        if isfield(ref,'local_path')&&strlength(string(ref.local_path))>0
            error('BNV:IO:PortableLocalPath','Portable Scene cannot reference a host-local path.');
        end
    end
end
end
