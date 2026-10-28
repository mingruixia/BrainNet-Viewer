function runLocalSceneContractCI(sourceRoot,output)
% Focused JSON/ZIP contracts that do not require an App window in CI.
arguments
    sourceRoot (1,1) string
    output (1,1) string
end
assert(~isfolder(output),'Keep existing evidence; select a new output folder.');
mkdir(output);oldRoot=getenv('BNV_PROJECT_ROOT');oldPath=path;
cleanup=onCleanup(@() restoreEnvironment(oldRoot,oldPath)); %#ok<NASGU>
addpath(sourceRoot,fullfile(sourceRoot,'src','matlab','BrainNetViewer'),'-begin');
setenv('BNV_PROJECT_ROOT',sourceRoot);
suite=matlab.unittest.TestSuite.fromFile(fullfile(sourceRoot,'tests','matlab','TestLocalSceneReferences.m'));
methods={'externalGiftiCompanionTravelsAndIsVerified', ...
    'failedPackagePreservesExistingAndLocalJsonSealsHash', ...
    'archiveTraversalAndDuplicateAreRejected', ...
    'pairedNiftiFilesTravelAndMissingCompanionProtectsOutput'};
names=cellfun(@(s) ['TestLocalSceneReferences/' s],methods,'UniformOutput',false);
suite=suite(ismember({suite.Name},names));assert(numel(suite)==4,'Expected exactly four contracts.');
result=run(suite);writetable(table(result),fullfile(output,'results.csv'));
assert(numel(result)==4&&all([result.Passed]),'BNV:Test:LocalSceneCI','Scene contract failed or incomplete.');
end
function restoreEnvironment(root,oldPath)
setenv('BNV_PROJECT_ROOT',root);path(oldPath);
end
