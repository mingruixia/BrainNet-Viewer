function file=sceneRelativeFile(folder,relative)
%SCENERELATIVEFILE Resolve an archive reference without escaping its directory.
ref=brainnet.core.InputReference('surface',relative);
base=string(char(java.io.File(char(folder)).getCanonicalPath()));
file=string(char(java.io.File(char(ref.resolve(base))).getCanonicalPath()));
prefix=base+string(filesep);
if ispc,valid=startsWith(lower(file),lower(prefix));else,valid=startsWith(file,prefix);end
if ~valid,error('BNV:IO:SceneAssetOutside','Packaged input escapes its asset directory.');end
end
