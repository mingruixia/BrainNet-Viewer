function report=runLocalSceneReferenceReview(sourceRoot,output)
% Targeted source validation, not an installed-package or manual acceptance.
arguments
    sourceRoot (1,1) string
    output (1,1) string
end
assert(~isfolder(output),'Preserve previous evidence; choose a new output directory.');
mkdir(output);oldRoot=getenv('BNV_PROJECT_ROOT');oldPath=path;
cleanup=onCleanup(@()restoreEnvironment(oldRoot,oldPath)); %#ok<NASGU>
sourceRoot=string(char(java.io.File(char(sourceRoot)).getCanonicalPath()));
addpath(sourceRoot,fullfile(sourceRoot,'src/matlab/BrainNetViewer'),fullfile(sourceRoot,'tests/matlab'),'-begin');
assert(startsWith(string(which('brainnet.app.BrainNetApp')),sourceRoot+filesep),'Wrong application source.');
setenv('BNV_PROJECT_ROOT',sourceRoot);
identityPath=fullfile(sourceRoot,'validation/local-scene-reference-20261027/mac-source-identity.json');
identity=jsondecode(fileread(identityPath));
for item=reshape(identity.files,1,[])
    actual=brainnet.io.internal.sha256File(fullfile(sourceRoot,item.path));
    assert(strcmp(actual,item.sha256),'BNV:Test:SourceIdentity','Source differs: %s',item.path);
end
evidence=fullfile(sourceRoot,'validation/local-scene-reference-20261027');if ~isfolder(evidence),mkdir(evidence);end
suite=matlab.unittest.TestSuite.fromFile(fullfile(sourceRoot,'tests/matlab/TestLocalSceneReferences.m'));
assert(numel(suite)==9,'Expected exactly nine methods; empty or stale suite is not a pass.');
diary(fullfile(output,'matlab.log'));diaryCleanup=onCleanup(@()diary('off')); %#ok<NASGU>
results=run(suite);writetable(table(results),fullfile(output,'results.csv'));
report=struct('passed',numel(results)==9&&all([results.Passed]),'method_count',numel(results), ...
 'matlab',version,'release',version('-release'),'java',version('-java'),'architecture',computer, ...
 'source',which('brainnet.app.BrainNetApp'),'identity_path',identityPath, ...
 'evidence','Program-driven MATLAB UIAxes, Scene IO and PNG readback; not native chooser/manual acceptance');
try,report.renderer=rendererinfo;catch,report.renderer=struct('status','not available without target');end
fid=fopen(fullfile(output,'result.json'),'w','n','UTF-8');assert(fid>0);
done=onCleanup(@()fclose(fid));fprintf(fid,'%s',jsonencode(report,PrettyPrint=true));clear done;
assert(report.passed,'BNV:Test:LocalSceneReview','One or more targeted methods failed. Retain all logs.');
end
function restoreEnvironment(root,oldPath)
setenv('BNV_PROJECT_ROOT',root);path(oldPath);
end
