function report=runImageTitleReview(project,sourceRoot,output)
% Targeted native title/transparent export review; not manual acceptance.
arguments
    project (1,1) string
    sourceRoot (1,1) string
    output (1,1) string
end
assert(~isfolder(output),'Preserve previous evidence.');mkdir(output);
addpath(fullfile(sourceRoot,'src/matlab/BrainNetViewer'),'-begin');
app=brainnet.app.BrainNetApp(sourceRoot,Visible=true,UseStartupImage=false);
cleanup=onCleanup(@()delete(app)); %#ok<NASGU>
app.setDocumentationCaptureMode(true);
app.selectInputPath('surface',fullfile(sourceRoot,'src/matlab/BrainNetViewer/Data/SurfTemplate/BrainMesh_ICBM152.nv'));
app.selectInputPath('surface_map',fullfile(sourceRoot,'resources/atlases/AAL90/icbm_vertex_AAL_label.txt'));
titleValue='Title_sample <literal> 2.0';
app.patchVisualizationSettings(struct('layout',struct('preset',1), ...
    'surface',struct('color_mode','scalar','show_colorbar',true), ...
    'image',struct('title',titleValue)));
app.loadCurrentScene();app.renderCurrentScene(Target='embedded');pause(1);drawnow;
verifyTitle(app,titleValue,1);
camera=app.BatchRenderer.captureCamera();position=app.UIFigure.Position;
for k=1:2
    name=fullfile(output,sprintf('title-%d.png',k));
    app.exportCurrentFigure(name,Width=800,Height=600,Resolution=200,BackgroundColor="none");
    [rgb,~,alpha]=imread(name);
    assert(isequal(size(rgb),[600 800 3])&&nnz(alpha==0)>1000&&nnz(alpha>200)>1000);
    ink=alpha(1:70,:)>100 & max(rgb(1:70,:,:),[],3)<150;
    assert(nnz(ink)>20,'Product title missing from exported top strip.');
    assert(isequaln(camera,app.BatchRenderer.captureCamera()));
    assert(isequal(position,app.UIFigure.Position));
    if k==1,first=rgb;firstAlpha=alpha;else,assert(isequal(first,rgb)&&isequal(firstAlpha,alpha));end
end
exportapp(app.UIFigure,fullfile(output,'single-window.png'));
app.patchVisualizationSettings(struct('layout',struct('preset',2)));
app.renderCurrentScene(Target='embedded');pause(1);drawnow;verifyTitle(app,titleValue,8);
for ax=reshape(app.BatchRenderer.ActiveAxes,1,[])
    assert(ax.Position(2)+ax.Position(4)<=.926);
end
app.applyViewAction('reset');drawnow;verifyTitle(app,titleValue,8);
exportapp(app.UIFigure,fullfile(output,'overview-window.png'));
app.patchVisualizationSettings(struct('image',struct('title','')));
app.renderCurrentScene(Target='embedded');pause(.5);drawnow;
assert(isempty(findall(app.BatchRenderer.ActiveTarget,'Tag','brainnet-image-title')));
assert(numel(app.BatchRenderer.ActiveAxes)==8);
assert(max(arrayfun(@(a)a.Position(2)+a.Position(4),app.BatchRenderer.ActiveAxes))>.93);
app.patchVisualizationSettings(struct('image',struct('title',titleValue), ...
    'global',struct('background_color',[0 0 0])));
app.renderCurrentScene(Target='window',Visible=false);drawnow;verifyTitle(app,titleValue,8);
t=findall(app.BatchRenderer.ActiveTarget,'Tag','brainnet-image-title');assert(isequal(t.Color,[1 1 1]));
app.BatchRenderer.closeActiveFigure();assert(~isgraphics(t));
report=struct('passed',true,'matlab',version,'source',which('brainnet.render.MatlabBatchRenderer'), ...
    'cases',{{'embedded Single literal title','consecutive transparent PNG and restoration', ...
    'Overview title/reset and reserved strip','empty title restores original area', ...
    'standalone dark contrast and cleanup'}}, ...
    'evidence','Windows native graphics API and PNG readback; no manual/Mac acceptance');
fid=fopen(fullfile(output,'result.json'),'w','n','UTF-8');fwrite(fid,jsonencode(report),'char');fclose(fid);
disp(jsonencode(report));
end
function verifyTitle(app,value,count)
t=findall(app.BatchRenderer.ActiveTarget,'Tag','brainnet-image-title');
assert(numel(t)==1&&strcmp(t.String,value)&&strcmp(t.Interpreter,'none'));
assert(numel(app.BatchRenderer.ActiveAxes)==count);
assert(~ismember(t.Parent,app.BatchRenderer.ActiveAxes));
end
