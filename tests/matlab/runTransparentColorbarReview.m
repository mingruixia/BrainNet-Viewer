function report = runTransparentColorbarReview(sourceRoot, output, options)
% Targeted native MATLAB matte/colorbar regression; no manual acceptance.
arguments
    sourceRoot (1,1) string
    output (1,1) string
    options.CaseIndices (1,:) double = 1:3
end
assert(~isfolder(output),'Preserve previous evidence.'); mkdir(output);
addpath(fullfile(sourceRoot,'src/matlab/BrainNetViewer'),'-begin');
report=struct('passed',false,'evidence','Program-driven native MATLAB UI and actual PNG readback', ...
    'matlab',version,'source',which('brainnet.export.FigureExporter'),'cases',[]);
app=[];
try
    app=brainnet.app.BrainNetApp(sourceRoot,Visible=true,UseStartupImage=false);
    cleanup=onCleanup(@()deleteIfValid(app)); %#ok<NASGU>
    app.setDocumentationCaptureMode(true);
    paths={ 'surface','src/matlab/BrainNetViewer/Data/SurfTemplate/BrainMesh_ICBM152.nv'; ...
        'surface_map','resources/atlases/AAL90/icbm_vertex_AAL_label.txt'; ...
        'node','src/matlab/BrainNetViewer/Data/ExampleFiles/AtlasNetworks/Schaefer100Yeo7_GroupFC.node'; ...
        'edge','src/matlab/BrainNetViewer/Data/ExampleFiles/AtlasNetworks/Schaefer100Yeo7_GroupFC.edge'};
    for k=1:size(paths,1)
        path=fullfile(sourceRoot,paths{k,2});app.selectInputPath(paths{k,1},path);
        report.inputs.(paths{k,1})=char(brainnet.io.internal.sha256File(path));
    end
    app.patchVisualizationSettings(struct('surface',struct('color_mode','scalar','show_colorbar',true,'opacity',.45), ...
        'edge',struct('selection_mode','sparsity','sparsity',.02), ...
        'image',struct('title','Linux MATLAB 透明色条验证 — Schaefer100 / Yeo7')));
    app.loadCurrentScene();
    % Light Single/Overview reproduce the failure; dark Single covers white text.
    for caseIndex=options.CaseIndices
        preset=1;if caseIndex==2,preset=2;end
        background="white";rgbBackground=[1 1 1];
        if caseIndex==3,background="black";rgbBackground=[0 0 0];end
        app.patchVisualizationSettings(struct('layout',struct('preset',preset), ...
            'global',struct('background_color',rgbBackground)));
        app.renderCurrentScene(Target='embedded');drawnow;pause(.3);
        before=snapshot(app);
        referencePath=fullfile(output,sprintf('case-%d-reference.png',caseIndex));
        app.exportCurrentFigure(referencePath,Width=800,Height=600,Resolution=200,Units="pixels",BackgroundColor=background);
        assertRestored(app,before); reference=imread(referencePath);
        expected=1;if preset==2,expected=8;end
        assert(numel(app.BatchRenderer.ActiveAxes)==expected);
        item=struct('preset',preset,'background',background,'views',expected, ...
            'graphics',rendererinfo(app.BatchRenderer.ActiveAxes(1)),'before',before,'exports',[]);
        for k=1:2
            path=fullfile(output,sprintf('case-%d-transparent-%d.png',caseIndex,k));
            record=app.exportCurrentFigure(path,Width=800,Height=600,Resolution=200,Units="pixels",BackgroundColor="none");
            immediate=snapshot(app);assert(isequaln(before,immediate),'Immediate state changed.');
            drawnow;pause(.2);stable=snapshot(app);assert(isequaln(before,stable),'Stable state changed.');
            [rgb,~,alpha]=imread(path);
            assert(isequal(size(rgb),[600 800 3])&&~isempty(alpha)&&min(alpha(:))==0&&max(alpha(:))==255);
            saved=jsondecode(fileread(path+".provenance.json"));
            assert(strcmp(saved.export.sha256,brainnet.io.internal.sha256File(path)),'Provenance hash mismatch.');
            % Compare actual colored legend pixels, not merely size/alpha/hash.
            mask=max(reference,[],3)-min(reference,[],3)>40;
            mask(1:450,:)=false;mask(:,1:200)=false;mask(:,601:end)=false;
            rows=find(sum(mask,2)>100);assert(~isempty(rows),'Reference colorbar missing.');
            % The last contiguous horizontal colored band is the legend;
            % lower brain anatomy can also occupy the bottom quarter.
            lastRow=rows(end);firstRow=lastRow;
            while firstRow>1 && sum(mask(firstRow-1,:))>100,firstRow=firstRow-1;end
            mask(1:firstRow-1,:)=false;mask(lastRow+1:end,:)=false;
            weight=double(alpha)/255;
            composite=double(rgb).*weight+reshape(255*rgbBackground,1,1,3).*(1-weight);
            comparisonOffset=[0 0];
            if verLessThan('matlab','25.1') && any(record.export.matte_padding_alignment_pixels)
                % Resolution-only exports can center the same native panel at
                % adjacent integer padding origins. Compare scientific pixels
                % after at most one pixel of blank-border registration. Keep
                % the saved file unchanged and retain the original RGB guard.
                [composite,comparisonOffset]=registeredBlankPadding(composite,reference,alpha,mask,rgbBackground);
            end
            delta=max(abs(composite-double(reference)),[],3);
            assert(max(delta(mask))<=3,'BNV:Test:ColorbarMismatch', ...
                'Transparent colorbar differs from the actual opaque reference.');
            colored=max(composite,[],3)-min(composite,[],3)>35;
            assert(nnz(colored & mask)>=.99*nnz(mask),'Transparent legend lost its color.');
            % A complete recomposite should agree beyond the legend too.
            assert(nnz(delta>3)<.001*numel(delta),'BNV:Test:MatteMismatch', ...
                'Transparent recomposite has a material geometry/content difference.');
            exp=struct('path',path,'transparency_method',record.export.transparency_method, ...
                'matte_alignment_pixels',record.export.matte_padding_alignment_pixels, ...
                'comparison_padding_offset_pixels',comparisonOffset, ...
                'legend_rows',[firstRow lastRow],'legend_pixels',nnz(mask),'legend_max_delta',max(delta(mask)), ...
                'recomposite_max_delta',max(delta(:)),'pixels_delta_over_3',nnz(delta>3), ...
                'immediate',immediate,'stable',stable,'restored',true);
            item.exports=[item.exports exp]; %#ok<AGROW>
            if k==1,first=rgb;firstAlpha=alpha;else
                change=abs(double(first)-double(rgb));
                item.consecutive_difference=struct('changed_rgb_pixels',nnz(any(change>0,3)), ...
                    'max_rgb_delta',max(change(:)),'changed_alpha_pixels',nnz(firstAlpha~=alpha), ...
                    'max_alpha_delta',max(abs(double(firstAlpha(:))-double(alpha(:)))));
            end
        end
        exportapp(app.UIFigure,fullfile(output,sprintf('case-%d-window.png',caseIndex)));
        report.cases=[report.cases item]; %#ok<AGROW>
        fprintf('Transparent colorbar case %d passed: layout %d, %s, consecutive PNGs and state restoration.\n',caseIndex,preset,background);
    end
    report.mismatched_matte_guard=verifyMismatchGuard(output);
    report.java=version('-java');report.passed=true;
catch caughtError
    report.error_identifier=caughtError.identifier;
    report.error=getReport(caughtError,'extended','hyperlinks','off');
end
fid=fopen(fullfile(output,'result.json'),'w','n','UTF-8');assert(fid>0);
fprintf(fid,'%s',jsonencode(report,PrettyPrint=true));fclose(fid);
if ~isempty(app),deleteIfValid(app);end
if ~report.passed,error('BNV:Test:TransparentColorbarReview','%s',report.error);end
end
function s=snapshot(app)
target=app.BatchRenderer.ActiveTarget;title=findall(target,'Tag','brainnet-image-title');
publicState=app.snapshot();
s=struct('camera',app.BatchRenderer.captureCamera(),'window',app.UIFigure.Position, ...
    'canvas',target.Position,'background',target.BackgroundColor,'title',title.String, ...
    'title_position',title.Position,'font_size',title.FontSize,'font_units',title.FontUnits, ...
    'export_settings',publicState.export_settings,'axes',[],'bars',[]);
for a=reshape(findall(target,'Type','axes'),1,[])
    s.axes=[s.axes struct('position',a.Position,'outer_position',a.OuterPosition, ...
        'color',a.Color,'colormap',colormap(a),'limits',a.CLim)]; %#ok<AGROW>
end
for b=reshape(findall(target,'Type','ColorBar'),1,[])
    s.bars=[s.bars struct('position',b.Position,'units',b.Units,'font_size',b.FontSize, ...
        'font_name',b.FontName,'color',b.Color,'limits',b.Limits)]; %#ok<AGROW>
end
end
function assertRestored(app,before)
assert(isequaln(before,snapshot(app)),'Opaque export changed state.');drawnow;pause(.2);
assert(isequaln(before,snapshot(app)),'Opaque export changed stable state.');
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
function removeFixture(folder)
if contains(path,char(folder)),rmpath(folder);end
clear exportgraphics;
if isfolder(folder),rmdir(folder,'s');end
end

function [comp,offset]=registeredBlankPadding(comp,reference,alpha,mask,background)
% Independent file comparison only; never transform the exported file.
offset=[0 0];baseline=max(abs(comp-double(reference)),[],3);
if max(baseline(mask))<=3 && nnz(baseline>3)<.001*numel(baseline),return;end
for axis=1:2
    for shift=[-1 1]
        if axis==1
            edge=alpha(:,end);if shift<0,edge=alpha(:,1);end
        else
            edge=alpha(end,:);if shift<0,edge=alpha(1,:);end
        end
        if any(edge(:)~=0),continue;end
        candidate=repmat(reshape(255*background,1,1,3),size(comp,1),size(comp,2),1);
        if axis==1
            if shift<0,candidate(:,1:end-1,:)=comp(:,2:end,:);else,candidate(:,2:end,:)=comp(:,1:end-1,:);end
        else
            if shift<0,candidate(1:end-1,:,:)=comp(2:end,:,:);else,candidate(2:end,:,:)=comp(1:end-1,:,:);end
        end
        delta=max(abs(candidate-double(reference)),[],3);
        if max(delta(mask))<=3 && nnz(delta>3)<.001*numel(delta)
            comp=candidate;offset(axis)=shift;return;
        end
    end
end
end
