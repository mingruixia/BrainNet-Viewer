function saved=writePortableScene(scene,destination,dataRoot,options)
%WRITEPORTABLESCENE Explicitly package a Scene and its local dependencies.
arguments
    scene (1,1) brainnet.core.Scene
    destination (1,1) string
    dataRoot (1,1) string
    options.Overwrite (1,1) logical = false
end
[folder,~,ext]=fileparts(destination);if folder=="",folder=string(pwd);end
if lower(ext)~=".zip",error('BNV:IO:SceneZipExtension','Portable Scene requires .zip.');end
if ~isfolder(folder),error('BNV:IO:OutputFolderMissing','Output folder does not exist.');end
if isfolder(destination),error('BNV:IO:DestinationIsFolder','Destination is a folder.');end
if isfile(destination)&&~options.Overwrite,error('BNV:IO:OutputExists','Output exists.');end
stage=string(tempname(folder));mkdir(stage);mkdir(fullfile(stage,'assets'));temporary=string(tempname(folder))+".zip";
cleanup=onCleanup(@() removeStage(stage,temporary));
value=scene.toStruct();state=brainnet.core.SessionState.fromScene(scene);
restore=~isempty(state)&&strcmp(state.scene_signature,brainnet.core.SessionState.signature(scene));
allFiles=struct('relative_path',{},'sha256',{});
for index=1:numel(scene.Inputs)
    input=scene.Inputs{index};source=brainnet.io.internal.resolveAndVerify(input,dataRoot,input.Role);
    [~,name,extension]=fileparts(source);relative="assets/"+input.Role+"/"+string(name)+string(extension);
    allFiles(end+1)=copyInput(source,relative,stage);
    companions=brainnet.io.internal.inputCompanions(source);
    for companion=companions
        allFiles(end+1)=copyInput(companion.source,"assets/"+input.Role+"/"+replace(companion.relative,"\","/"),stage);
    end
    ref=input.toStruct();ref.relative_path=char(relative);ref.sha256=allFiles(end-numel(companions)).sha256;
    if isfield(ref,'local_path'),ref=rmfield(ref,'local_path');end
    value.inputs.(input.Role)=ref;
end
value.metadata.input_base='scene-directory';value.metadata.packaged_files=allFiles;
saved=brainnet.core.Scene.fromStruct(value);
if restore,saved=brainnet.core.SessionState.attach(saved,state.camera,state.export);end
brainnet.io.internal.writeJsonFile(fullfile(stage,'scene.json'),saved.toStruct());
zip(char(temporary),{'scene.json','assets'},char(stage));
% Check that the generated archive includes the copied payload members.
archive=java.util.zip.ZipFile(char(temporary));closeArchive=onCleanup(@() archive.close());
if archive.size()<numel(allFiles)+1
    error('BNV:IO:SceneZipIncomplete','Portable archive is incomplete.');
end
clear closeArchive;
opts=javaArray('java.nio.file.CopyOption',double(options.Overwrite));
if options.Overwrite,opts(1)=java.nio.file.StandardCopyOption.REPLACE_EXISTING;end
java.nio.file.Files.move(java.io.File(char(temporary)).toPath(),java.io.File(char(destination)).toPath(),opts);
end
function item=copyInput(source,relative,root)
destination=brainnet.io.internal.sceneRelativeFile(root,relative);parent=fileparts(destination);
if ~isfolder(parent),mkdir(parent);end
hash=brainnet.io.internal.sha256File(source);
if isfile(destination)
    if brainnet.io.internal.sha256File(destination)~=hash,error('BNV:IO:SceneAssetCollision','Conflicting companion name.');end
else
    [ok,message]=copyfile(source,destination);if ~ok,error('BNV:IO:SceneCopy',message);end
end
if brainnet.io.internal.sha256File(destination)~=hash,error('BNV:IO:ChecksumMismatch','Packaged copy changed.');end
item=struct('relative_path',char(relative),'sha256',char(hash));
end
function removeStage(folder,file)
if isfolder(folder),rmdir(folder,'s');end
if isfile(file),delete(file);end
end
