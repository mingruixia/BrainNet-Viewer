function report=runAnnotationMarginReview(sourceRoot,output,options)
% Targeted physical-font exports/restoration; not full or manual acceptance.
arguments
    sourceRoot (1,1) string
    output (1,1) string
    options.CaseIndices (1,:) double = 1:4
    options.IncludeHighDPI (1,1) logical = true
end
assert(~isfolder(output));mkdir(output);addpath(fullfile(sourceRoot,'src/matlab/BrainNetViewer'),'-begin');
report=struct('passed',false,'evidence','Real native MATLAB PNG/PDF, font metadata, full state snapshots', ...
    'source',which('brainnet.export.FigureExporter'),'matlab',version,'cases',[]);app=[];
try
    app=brainnet.app.BrainNetApp(sourceRoot,Visible=true,UseStartupImage=false);
    cleanup=onCleanup(@()deleteIfValid(app)); %#ok<NASGU>
    app.setDocumentationCaptureMode(true);
    roles={'surface','src/matlab/BrainNetViewer/Data/SurfTemplate/BrainMesh_ICBM152.nv'; ...
        'surface_map','resources/atlases/AAL90/icbm_vertex_AAL_label.txt'; ...
        'node','src/matlab/BrainNetViewer/Data/ExampleFiles/AtlasNetworks/Schaefer100Yeo7_GroupFC.node'; ...
        'edge','src/matlab/BrainNetViewer/Data/ExampleFiles/AtlasNetworks/Schaefer100Yeo7_GroupFC.edge'};
    for j=1:size(roles,1)
        path=fullfile(sourceRoot,roles{j,2});app.selectInputPath(roles{j,1},path);
        report.inputs.(roles{j,1})=char(brainnet.io.internal.sha256File(path));
    end
    nodes=readmatrix(fullfile(sourceRoot,roles{3,2}),'FileType','text','Delimiter','\t');
    app.patchVisualizationSettings(struct('surface',struct('color_mode','scalar','show_colorbar',true,'opacity',.45), ...
        'edge',struct('selection_mode','sparsity','sparsity',.02), ...
        'node',struct('label_mode','threshold','label_threshold',max(nodes(:,5))-.001,'label_font_units','points','label_font_size',10)));
    app.loadCurrentScene();
    short='Linux font 12pt';long='Linux Schaefer100 / 长标题';
    for index=options.CaseIndices
        preset=1+mod(index-1,2);
        if index<=2,app.UIFigure.Position=[40 40 1800 680];app.setSettingsPanelCollapsed(true);
        else,app.UIFigure.Position=[40 40 960 900];app.setSettingsPanelCollapsed(false);end
        drawnow;pause(.2);
        title=short;if index==3,title=long;end
        units='points';if preset==2,units='pixels';end
        app.patchVisualizationSettings(struct('layout',struct('preset',preset),'image',struct('title',title), ...
            'node',struct('label_font_units',units)));
        app.renderCurrentScene(Target='embedded');drawnow;pause(.2);
        before=snapshot(app);
        assert(strcmp(before.title_units,'points')&&before.title_font==12);
        assert(~isempty(before.node_labels),'Node unit sentinel labels missing.');
        item=struct('index',index,'preset',preset,'title',title,'before',before, ...
            'graphics',rendererinfo(app.BatchRenderer.ActiveAxes(1)),'exports',[],'consecutive',struct());
        count=2;
        for k=1:count
            file=fullfile(output,sprintf('case-%d-transparent-%d.png',index,k));
            [exp,rgb,alpha]=oneExport(app,file,before,800,600,200,"none");
            if index==3,assert(exp.text_rendering.title_font_points<12&&exp.text_rendering.title_font_points>=6);end
            item.exports=[item.exports exp]; %#ok<AGROW>
            if k==1,first=rgb;firstAlpha=alpha;else
                d=abs(double(first)-double(rgb));item.consecutive=struct('changed_rgb_pixels',nnz(any(d>0,3)), ...
                    'max_rgb_delta',max(d(:)),'changed_alpha_pixels',nnz(alpha~=firstAlpha), ...
                    'max_alpha_delta',max(abs(double(alpha(:))-double(firstAlpha(:)))));
            end
        end
        file=fullfile(output,sprintf('case-%d-default.pdf',index));
        exp=oneExport(app,file,before,800,600,200,"white");item.exports=[item.exports exp]; %#ok<AGROW>
        if index==1 && options.IncludeHighDPI
            for dpi=600
                width=2000;if dpi==600,width=4000;end
                file=fullfile(output,sprintf('case-1-dpi-%d.png',dpi));
                exp=oneExport(app,file,before,width,width*.75,dpi,"none");item.exports=[item.exports exp]; %#ok<AGROW>
            end
        end
        exportapp(app.UIFigure,fullfile(output,sprintf('case-%d-window.png',index)));
        fid=fopen(fullfile(output,sprintf('case-%d-result.json',index)),'w','n','UTF-8');fprintf(fid,'%s',jsonencode(item,PrettyPrint=true));fclose(fid);
        report.cases=[report.cases item]; %#ok<AGROW>
        fprintf('Physical-font case %d layout=%d complete; state and selected node units restored.\n',index,preset);
    end
    % A title that cannot fit at 6pt must fail before publishing either file.
    t=findall(app.BatchRenderer.ActiveTarget,'Tag','brainnet-image-title');saved=t.String;
    t.String=repmat('Unfittable_long_title ',1,30);drawnow;before=snapshot(app);
    identifier='';file=fullfile(output,'must-not-exist.png');
    try,app.exportCurrentFigure(file,Width=800,Height=600,Resolution=200,BackgroundColor="none");catch e,identifier=e.identifier;end
    assert(strcmp(identifier,'BNV:Export:TitleTooLong'));
    assert(~isfile(file)&&~isfile(file+".provenance.json"));assertRestored(app,before);
    t.String=saved;drawnow;report.unfittable_title=struct('identifier',identifier,'restored',true,'no_output',true);
    report.vector_fixture=verifyVector(output);
    report.mid_render_failure=verifyLateFailure(output);
    report.mismatched_matte_guard=verifyMismatchGuard(output);
    report.passed=true;
catch e
    report.error_id=e.identifier;report.error=getReport(e,'extended','hyperlinks','off');
end
fid=fopen(fullfile(output,'result.json'),'w','n','UTF-8');assert(fid>0);fprintf(fid,'%s',jsonencode(report,PrettyPrint=true));fclose(fid);
if ~isempty(app),deleteIfValid(app);end
if ~report.passed,error('BNV:Test:PhysicalAnnotationReview','%s',report.error);end
end
function [exp,rgb,alpha]=oneExport(app,file,before,width,height,dpi,background)
record=app.exportCurrentFigure(file,Width=width,Height=height,Resolution=dpi,Units="pixels",BackgroundColor=background);
immediate=snapshot(app);assert(isequaln(before,immediate),'Immediate export state changed.');
drawnow;pause(.2);stable=snapshot(app);assert(isequaln(before,stable),'Stable export state changed.');
saved=jsondecode(fileread(file+".provenance.json"));assert(strcmp(saved.export.sha256,brainnet.io.internal.sha256File(file)));
exp=struct('path',file,'text_rendering',record.text_rendering,'immediate',immediate,'stable',stable,'restored',true);
rgb=[];alpha=[];
if endsWith(file,'.png')
    [rgb,~,alpha]=imread(file);assert(isequal(size(rgb),[height width 3]));
    if background=="none",assert(~isempty(alpha)&&min(alpha(:))==0&&max(alpha(:))==255);end
end
end
function s=snapshot(app)
target=app.BatchRenderer.ActiveTarget;t=findall(target,'Tag','brainnet-image-title');v=app.snapshot();
s=struct('camera',app.BatchRenderer.captureCamera(),'window',app.UIFigure.Position,'canvas',target.Position, ...
    'title',t.String,'title_font',t.FontSize,'title_units',t.FontUnits,'title_position',t.Position, ...
    'export_settings',v.export_settings,'axes',[],'bars',[],'node_labels',[]);
for a=reshape(findall(target,'Type','axes'),1,[])
    s.axes=[s.axes struct('units',a.Units,'position',a.Position,'outer',a.OuterPosition,'limits',a.CLim,'map',colormap(a), ...
        'camera_position',a.CameraPosition,'camera_target',a.CameraTarget,'camera_up',a.CameraUpVector,'view_angle',a.CameraViewAngle, ...
        'camera_modes',{{a.CameraPositionMode,a.CameraTargetMode,a.CameraUpVectorMode,a.CameraViewAngleMode}}, ...
        'data_aspect',a.DataAspectRatio,'plot_aspect',a.PlotBoxAspectRatio)]; %#ok<AGROW>
end
for b=reshape(findall(target,'Type','ColorBar'),1,[])
    s.bars=[s.bars struct('units',b.Units,'position',b.Position,'font',b.FontSize,'name',b.FontName, ...
        'ticks',b.Ticks,'tick_labels',{b.TickLabels},'ticks_mode',b.TicksMode,'limits',b.Limits)]; %#ok<AGROW>
end
for l=reshape(findall(target,'Tag','brainnet-node-label'),1,[])
    s.node_labels=[s.node_labels struct('string',l.String,'units',l.FontUnits,'font',l.FontSize,'position',l.Position,'visible',l.Visible,'clipping',l.Clipping)]; %#ok<AGROW>
end
end
function assertRestored(app,before)
assert(isequaln(before,snapshot(app)));drawnow;pause(.2);assert(isequaln(before,snapshot(app)));
end
function result=verifyVector(output)
% Small native vector fixture avoids forcing a huge 3D mesh to vector paths.
f=figure('Visible','off','Position',[100 100 1280 360]);fc=onCleanup(@()delete(f)); %#ok<NASGU>
p=f;
a=axes(p,'Units','normalized','Position',[.05 .2 .9 .6]);
imagesc(a,repmat(linspace(0,1,64),64,1));a.Visible='off';colormap(a,parula(256));
b=colorbar(a,'southoutside');b.Position=[.35 .08 .3 .02];b.FontSize=8;b.FontName='Arial';
tax=axes(p,'Units','normalized','Position',[.015 .932 .97 .06],'Visible','off', ...
    'Color','none','XLim',[0 1],'YLim',[0 1]);
t=text(tax,.5,.5,'FontProbe_12pt','Units','normalized','FontUnits','points','FontSize',12, ...
    'FontName','Arial','FontWeight','bold','Interpreter','none','HorizontalAlignment','center','Tag','brainnet-image-title');drawnow;
scene=brainnet.core.Scene("font-vector","Native vector font fixture",0,0,{});
prepared=brainnet.render.PreparedScene(scene,"fixture",struct(),struct(),"font-vector");
ex=brainnet.export.FigureExporter(output);result=ex.exportFigure(p,"font-vector.pdf",scene,prepared,struct(), ...
    Width=800,Height=600,Resolution=200,ContentType="vector");
assert(t.FontSize==12&&strcmp(t.FontUnits,'points')&&b.FontSize==8);
end
function removeFixture(folder)
if contains(path,char(folder)),rmpath(folder);end
clear exportgraphics;if isfolder(folder),rmdir(folder,'s');end
end
function deleteIfValid(app)
if isvalid(app),delete(app);end
end

function result=verifyMismatchGuard(output)
% Inject inconsistent RGB mattes only for this fail-closed unit check.
% This fixture is not native-rendering evidence.
fixture=string(tempname);mkdir(fixture);
fixtureCleanup=onCleanup(@()removeFixture(fixture)); %#ok<NASGU>
code=join(["function exportgraphics(~,path,varargin)"; ...
    "pixels=repmat(uint8(100),4,5,3);"; ...
    "index=find(strcmp(varargin(1:2:end),'BackgroundColor'),1)*2;"; ...
    "background=varargin{index};"; ...
    "if isnumeric(background)&&background(1)>.5,pixels(2,3,1)=30;end"; ...
    "imwrite(pixels,path);";"end"],newline);
fid=fopen(fullfile(fixture,'exportgraphics.m'),'w');assert(fid>0);fprintf(fid,'%s',code);fclose(fid);
addpath(fixture,'-begin');clear exportgraphics;
window=figure('Visible','off');windowCleanup=onCleanup(@()delete(window)); %#ok<NASGU>
scene=brainnet.core.Scene("matte-guard","Matte guard",0,0,{});
prepared=brainnet.render.PreparedScene(scene,"fixture",struct(),struct(),"matte-guard");
folder=fullfile(output,'mismatch-guard');mkdir(folder);exporter=brainnet.export.FigureExporter(folder);
identifier='';
try
    exporter.exportFigure(window,"must-not-exist.png",scene,prepared,struct(), ...
        Width=5,Height=4,Resolution=100,BackgroundColor="none");
catch caughtError
    identifier=caughtError.identifier;
end
assert(strcmp(identifier,'BNV:Export:TransparencyUnavailable'),'Inconsistent mattes were not rejected.');
entries=dir(folder);assert(all([entries.isdir]),'Rejected export left output or temporary files.');
result=struct('passed',true,'identifier',identifier,'no_output_or_sidecar',true, ...
    'evidence','Injected inconsistent-matte unit fixture; not a hardware frame');
end

function result=verifyLateFailure(output)
f=uifigure('Visible','on','Position',[100 100 1400 800]);fc=onCleanup(@()delete(f)); %#ok<NASGU>
p=uipanel(f,'Position',[1 1 1280 360],'BorderType','none','AutoResizeChildren','off');
a=uiaxes(p,'Units','normalized','Position',[.05 .2 .9 .6]);imagesc(a,repmat(linspace(0,1,64),64,1));a.Visible='off';a.Tag='margin-data-axis';colormap(a,parula(256));
b=colorbar(a,'southoutside');b.Position=[.35 .08 .3 .02];b.FontSize=8;b.FontName='Arial';
tax=uiaxes(p,'Units','normalized','Position',[.015 .932 .97 .06],'Visible','off','Color','none','XLim',[0 1],'YLim',[0 1]);
t=text(tax,.5,.5,'Review title','Units','normalized','FontUnits','points','FontSize',12,'FontName','Arial','FontWeight','bold', ...
    'Interpreter','none','HorizontalAlignment','center','Tag','brainnet-image-title');drawnow;
text(a,.5,.5,'Node sentinel','Units','normalized','FontUnits','pixels','FontSize',10,'Clipping','on','Tag','brainnet-node-label');
scene=brainnet.core.Scene("review-edge","Font review",0,0,{});prepared=brainnet.render.PreparedScene(scene,"fixture",struct(),struct(),"review-edge");

 t.String='Late failure sentinel';t.FontUnits='pixels';t.FontSize=12;drawnow;before=fixtureSnapshot(f,p,t,b,a);
 fixture=string(tempname);mkdir(fixture);pc=onCleanup(@()removeFixture(fixture)); %#ok<NASGU>
 code=join(["function exportgraphics(target,path,varargin)"; ...
  "global BNVReviewTrace; BNVReviewTrace.count=BNVReviewTrace.count+1;"; ...
  "wi=find(strcmp(varargin(1:2:end),'Width'),1)*2;hi=find(strcmp(varargin(1:2:end),'Height'),1)*2;bi=find(strcmp(varargin(1:2:end),'BackgroundColor'),1)*2;"; ...
  "w=varargin{wi};h=varargin{hi};bg=varargin{bi}; tt=findall(target,'Tag','brainnet-image-title');bb=findall(target,'Type','ColorBar');"; ...
  "row=struct('call',BNVReviewTrace.count,'width',w,'height',h,'background',{bg},'title_font',tt.FontSize,'bar_font',bb.FontSize,'axis_position',findobj(target,'Tag','margin-data-axis').Position,'node_clipping',findobj(target,'Tag','brainnet-node-label').Clipping);BNVReviewTrace.calls=[BNVReviewTrace.calls row];"; ...
  "if isnumeric(bg)&&bg(1)>.5&&BNVReviewTrace.count>=7,error('BNV:Review:LateMatteFailure','Injected error during shared white matte replay.');end"; ...
  "sz=[ceil(h) ceil(w)];if w==800&&h==600&&isnumeric(bg),sz(2)=801;if bg(1)>.5,sz(1)=601;end;end"; ...
  "value=255;if isnumeric(bg),value=round(bg(1)*255);end;pixels=repmat(uint8(value),sz(1),sz(2),3);imwrite(pixels,path);";"end"],newline);
 fid=fopen(fullfile(fixture,'exportgraphics.m'),'w');fprintf(fid,'%s',code);fclose(fid);addpath(fixture,'-begin');clear exportgraphics;
 global BNVReviewTrace;BNVReviewTrace=struct('count',0,'calls',[]);
 reject=fullfile(output,'late-failure');mkdir(reject);rex=brainnet.export.FigureExporter(reject);identifier='';
 try,rex.exportFigure(p,'failure.png',scene,prepared,struct(),Width=800,Height=600,Resolution=200,BackgroundColor='none');catch e,identifier=e.identifier;end
 assert(strcmp(identifier,'BNV:Review:LateMatteFailure'));assert(BNVReviewTrace.count==7);
 r1=BNVReviewTrace.calls(6);r2=BNVReviewTrace.calls(7);assert(~isequal(r1.axis_position,before.axis_position));assert(strcmp(r1.node_clipping,'on'));assert(r1.width==r2.width&&r1.height==r2.height&&r1.title_font==r2.title_font&&r1.bar_font==r2.bar_font);
 assert(isequaln(before,fixtureSnapshot(f,p,t,b,a)));drawnow;assert(isequaln(before,fixtureSnapshot(f,p,t,b,a)));files=dir(reject);assert(all([files.isdir]));
 result=struct('identifier',identifier,'calls',BNVReviewTrace.calls,'shared_geometry_and_fonts',true,'restored',true,'no_files',true,'evidence','Injected control-flow fixture, not a native rendering frame');
 % Failure after moving the title/bar, before a scientific viewport fits.
 t.String='X';drawnow;before=fixtureSnapshot(f,p,t,b,a);identifier='';
 try,rex.exportFigure(p,'no-space.png',scene,prepared,struct(),Width=800,Height=600,Resolution=2000);catch e,identifier=e.identifier;end
 assert(strcmp(identifier,'BNV:Export:AnnotationSpaceUnavailable'));assert(BNVReviewTrace.count==7);
 assert(isequaln(before,fixtureSnapshot(f,p,t,b,a)));drawnow;assert(isequaln(before,fixtureSnapshot(f,p,t,b,a)));files=dir(reject);assert(all([files.isdir]));
 result.insufficient_space=struct('identifier',identifier,'restored',true,'no_render_or_files',true);

end
function s=fixtureSnapshot(f,p,t,b,a)
s=struct('window',f.Position,'canvas',p.Position,'title',t.String,'units',t.FontUnits,'font',t.FontSize,'position',t.Position,'title_axis_position',t.Parent.Position,'title_axis_units',t.Parent.Units,'node_clipping',findobj(p,'Tag','brainnet-node-label').Clipping, ...
 'bar_position',b.Position,'bar_font',b.FontSize,'ticks',b.Ticks,'tick_labels',{b.TickLabels},'tick_mode',b.TicksMode, ...
 'axis_position',a.Position,'camera_position',a.CameraPosition,'camera_target',a.CameraTarget,'camera_up',a.CameraUpVector, ...
 'view_angle',a.CameraViewAngle,'camera_modes',{{a.CameraPositionMode,a.CameraTargetMode,a.CameraUpVectorMode,a.CameraViewAngleMode}}, ...
 'data_aspect',a.DataAspectRatio,'plot_aspect',a.PlotBoxAspectRatio,'clim',a.CLim,'colormap',colormap(a));
end
