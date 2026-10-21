function report=runTitleCloseReview(sourceRoot,output)
% Associated cleanup after closing a titled native render target.
addpath(fullfile(sourceRoot,'src/matlab/BrainNetViewer'),'-begin');
app=brainnet.app.BrainNetApp(sourceRoot,Visible=true,UseStartupImage=false);
cleanup=onCleanup(@()deleteIfValid(app)); %#ok<NASGU>
app.selectInputPath('surface',fullfile(sourceRoot,'src/matlab/BrainNetViewer/Data/SurfTemplate/BrainMesh_ICBM152.nv'));
app.patchVisualizationSettings(struct('image',struct('title','Close title')));
app.loadCurrentScene();app.renderCurrentScene(Target="embedded");drawnow;
titleHandle=findall(app.BatchRenderer.ActiveTarget,'Tag','brainnet-image-title');
assert(numel(titleHandle)==1);
app.BatchRenderer.closeActiveFigure();assert(~isgraphics(titleHandle));
lastwarn('');delete(app);pause(.3);drawnow;
[warningText,warningID]=lastwarn;
assert(~contains(warningText,'destructor')&&~contains(warningText,'timer'),'Cleanup warning remains.');
report=struct('passed',true,'warning',warningText,'warning_id',warningID,'matlab',version);
fid=fopen(output,'w');fwrite(fid,jsonencode(report),'char');fclose(fid);disp(jsonencode(report));
end
function deleteIfValid(app)
if isvalid(app),delete(app);end
end
