classdef BrainNetApp < matlab.apps.AppBase
    %BRAINNETAPP Programmatic R2025a desktop shell for explicit scenes.

    events (NotifyAccess = private)
        RenderingStarted
    end

    properties (SetAccess = private)
        UIFigure matlab.ui.Figure
        Session brainnet.app.SceneSession
        Planner brainnet.render.RenderPlanner
        BatchRenderer brainnet.render.MatlabBatchRenderer
        PopoutRenderer brainnet.render.MatlabBatchRenderer
        LegacyAdapter brainnet.app.LegacyRenderAdapter
        ProductInfo struct
        HelpWindow = []
        LastRenderInfo struct = struct('backend', '', 'status', 'not-rendered')
        LastExportInfo struct = struct('status', 'not-exported')
        LastMigrationReport struct = struct()
        LastPresetReport struct = struct()
    end

    properties (Access = private)
        RootLayoutGrid = []
        RootPanel = []
        MainGrid = []
        HeaderPanel = []
        HeaderGrid = []
        HeaderActionGrid = []
        BrandImage = []
        TitleLabel = []
        WelcomeLabel = []
        ThemeLabel = []
        ThemeSwitch = []
        HelpButton = []
        AboutButton = []
        WorkGrid = []
        DataPanel = []
        DataGrid = []
        DataActionGrid = []
        DataRoleGrid = []
        RoleDetailLabels struct = struct()
        RoleActionButtons struct = struct()
        SceneFilePath (1, 1) string = ""
        DropHintLabel = []
        RoleDropDown = []
        SelectInputButton = []
        OpenSceneButton = []
        SaveSceneButton = []
        ImportSettingsButton = []
        SceneActionGrid = []
        LoadButton = []
        InputTable = []
        SummaryArea = []
        SceneSummaryText cell = {}
        SceneSummaryRows struct = struct('title', {}, 'value', {})
        PreviewPanel = []
        PreviewGrid = []
        PreviewToolbarGrid = []
        PreviewToolbarRows (1,1) double = 0
        ResetViewButton = []
        ClearFigureButton = []
        MovieExportInProgress (1,1) logical = false
        RenderingInProgress (1,1) logical = false
        RotateButton = []
        InspectButton = []
        MergeWindow = []
        SurfaceConversionWindow = []
        SurfaceSubdivisionWindow = []
        AtlasNodeWindow = []
        ToolsPanel = []
        ToolsContainerGrid = []
        ToolsToggleButton = []
        ToolsPanelCollapsed (1,1) logical = true
        ToolsGrid = []
        MergeSurfacesToolButton = []
        ConvertSurfaceToolButton = []
        SubdivideSurfaceToolButton = []
        GenerateAtlasNodesToolButton = []
        SaveBoundaryToolButton = []
        ExportAnimationToolButton = []
        MovieWindow = []
        LiveDemo brainnet.app.LiveDemo
        DemoButton = []
        StopDemoButton = []
        LastInspection struct = struct()
        PanButton = []
        ZoomButton = []
        CameraTool (1,1) string = ""
        CameraGestureActive (1,1) logical = false
        CameraGesturePoint (1,2) double = [0 0]
        CameraGestureAxis = []
        FitButton = []
        ViewDropDown = []
        PreviewImage = []
        PreviewCanvasGrid = []
        StartupPanel = []
        StartupGrid = []
        StartupImage = []
        StartupInfoArea = []
        StartupCitationLabel = []
        RenderCanvasPanel = []
        PopOutButton = []
        PreviewFooterGrid = []
        ComputeLabel = []
        RendererDropDown = []
        RenderButton = []
        SettingsPanel = []
        SettingsGrid = []
        SettingsHeaderGrid = []
        PresetActionGrid = []
        LoadPresetButton = []
        SavePresetButton = []
        ColormapEditorButton = []
        SettingsTitleLabel = []
        SettingsCollapseButton = []
        SettingsAccordion = []
        SettingsPanelCollapsed (1, 1) logical = false
        QuickPanel = []
        QuickGrid = []
        SurfaceOpacitySlider = []
        NodeSizeSlider = []
        EdgeThicknessSlider = []
        VolumeThresholdField = []
        FiberVisibilitySwitch = []
        FullSettingsPanel = []
        FullSettingsGrid = []
        SettingsCategoryList = []
        OpenFullSettingsButton = []
        BottomGrid = []
        ViewportPanel = []
        ViewportGrid = []
        CanvasBackgroundDropDown = []
        GridCheckBox = []
        LightingDropDown = []
        ClippingDropDown = []
        ExportPanel = []
        ExportGrid = []
        ExportFormatLabel = []
        ExportFormatDropDown = []
        ExportResolutionLabel = []
        ExportResolutionField = []
        ExportWidthLabel = []
        ExportWidthField = []
        ExportHeightLabel = []
        ExportHeightField = []
        ExportUnitsLabel = []
        ExportUnitsDropDown = []
        ExportContentLabel = []
        ExportContentDropDown = []
        ExportBackgroundLabel = []
        ExportBackgroundDropDown = []
        ExportSizeModeDropDown = []
        ExportTransparencyCheckBox = []
        ExportButton = []
        ExportContentType (1, 1) string = "auto"
        ExportBackgroundPreference (1, 1) string = "current"
        TipPanel = []
        TipLabel = []
        ResourcePanel = []
        ResourceGrid = []
        CpuResourceLabel = []
        MemoryResourceLabel = []
        GpuResourceLabel = []
        NetworkResourceLabel = []
        StatusLamp = []
        StatusLabel = []
        LastPreparedScene = []
        DraftInputs (1, :) cell = {}
        DraftOptions brainnet.core.RenderOptions = brainnet.core.RenderOptions()
        SurfaceOpacityIsExplicit (1, 1) logical = false
        DropSupported (1, 1) logical = false
        StartupImageLoaded (1, 1) logical = false
        AdjustingWindowSize (1, 1) logical = false
        Theme (1, 1) string = "light"
        LayoutDensity (1, 1) string = "regular"
        ResourceSnapshot struct = struct()
        ResourceTimer = []
        LegacyUiMontageFitTimer = []
        LegacyUiFocusTimer = []
        LegacyUiMainFocusCount (1, 1) double = 0
        Closing (1, 1) logical = false
        DocumentationCaptureMode (1, 1) logical = false
        LastNetworkBytes (1, 2) double = [NaN NaN]
        LastNetworkSample = []
        SettingsDialog = []
    end

    methods
        function app = BrainNetApp(rootPath, options)
            arguments
                rootPath (1, 1) string
                options.Visible (1, 1) logical = true
                options.Name (1, 1) string = ""
                options.UseStartupImage (1, 1) logical = true
            end
            app.Session = brainnet.app.SceneSession(rootPath);
            app.Planner = brainnet.render.RenderPlanner;
            app.BatchRenderer = brainnet.render.MatlabBatchRenderer;
            app.PopoutRenderer = brainnet.render.MatlabBatchRenderer;
            app.LegacyAdapter = brainnet.app.LegacyRenderAdapter(rootPath);
            app.LiveDemo=brainnet.app.LiveDemo;
            app.ProductInfo = brainnet.app.productInfo(rootPath);
            if strlength(options.Name) == 0
                options.Name = string(app.ProductInfo.display_name);
            end
            app.createComponents(options.Name, options.UseStartupImage);
            registerApp(app, app.UIFigure);
            app.UIFigure.Visible = onOff(options.Visible);
            app.refreshView();
            if options.Visible
                app.startResourceTimer();
            end
            if nargout == 0
                clear app
            end
        end

        function setScene(app, scene)
            arguments
                app (1, 1) brainnet.app.BrainNetApp
                scene (1, 1) brainnet.core.Scene
            end
            brainnet.query.InspectionSettings.fromScene(scene);
            app.stopLegacyUiMontageFitTimer();
            scene = brainnet.core.SessionState.normalizeScene(scene);
            state = brainnet.core.SessionState.fromScene(scene);
            app.closeInspector();
            app.BatchRenderer.closeActiveFigure();
            app.PopoutRenderer.closeActiveFigure();
            app.LegacyAdapter.closeActiveFigure();
            app.DraftInputs = scene.Inputs;
            app.DraftOptions = scene.Options;
            % Loaded Scene, preset and legacy values are explicit user data.
            app.SurfaceOpacityIsExplicit = true;
            app.LastRenderInfo = struct('backend', '', 'status', 'not-rendered');
            app.LastExportInfo = struct('status', 'not-exported');
            app.LastPreparedScene = [];
            app.SceneFilePath = "";
            app.LastMigrationReport = struct();
            app.Session.setScene(scene);
            if ~isempty(state)
                e = state.export;
                background = string(e.background_color);
                app.configureExport(Format=string(e.format), Width=e.width, Height=e.height, ...
                    Resolution=e.resolution_dpi, Units=string(e.units), ...
                    ContentType=string(e.content_type), BackgroundColor=background);
            end
            app.synchronizeSettingsDialog();
            app.refreshView();
        end

        function setDocumentationCaptureMode(app, enabled)
            % Display-only redaction for publication/tutorial captures.
            % Scene inputs, export records and provenance remain unchanged.
            arguments
                app (1, 1) brainnet.app.BrainNetApp
                enabled (1, 1) logical
            end
            app.DocumentationCaptureMode = enabled;
            app.refreshView();
        end

        function importSceneFile(app, pathValue)
            arguments
                app (1, 1) brainnet.app.BrainNetApp
                pathValue (1, 1) string
            end
            if ~isfile(pathValue)
                error('BNV:App:SceneFileNotFound', 'Scene file does not exist: %s', pathValue);
            end
            try
                scene = brainnet.io.readScene(pathValue);
                app.setScene(scene);
                app.SceneFilePath = pathValue;
                app.refreshView();
            catch exception
                app.Session.recordError(exception);
                app.refreshView();
                rethrow(exception);
            end
        end

        function saved = saveSceneFile(app, pathValue, options)
            arguments
                app (1, 1) brainnet.app.BrainNetApp
                pathValue (1, 1) string
                options.Overwrite (1, 1) logical = false
            end
            if isempty(app.Session.Scene)
                error('BNV:App:SceneRequired', 'Select input files before saving a Scene.');
            end
            if endsWith(lower(pathValue),".zip")
                saved=brainnet.io.writePortableScene(app.sceneWithSessionState(),pathValue, ...
                    app.Session.RootPath,Overwrite=options.Overwrite);
            else
                saved = brainnet.io.writeScene(app.sceneWithSessionState(), pathValue, ...
                    app.Session.RootPath, Overwrite=options.Overwrite);
            end
            % Saving must not discard an existing rendered canvas.
            app.SceneFilePath = pathValue;
            app.refreshView();
        end

        function report = importLegacyConfigFile(app, pathValue)
            arguments
                app (1, 1) brainnet.app.BrainNetApp
                pathValue (1, 1) string
            end
            if isempty(app.Session.Scene)
                [scene, report] = brainnet.io.importLegacyConfig(pathValue, app.Session.RootPath);
            else
                [scene, report] = brainnet.io.importLegacyConfig(pathValue, ...
                    app.Session.RootPath, Scene=app.Session.Scene);
            end
            app.setScene(scene);
            app.LastMigrationReport = report;
        end

        function scene = sceneWithSessionState(app)
            scene = app.Session.Scene;
            if isempty(scene), error('BNV:App:SceneRequired', 'Select a Scene first.'); end
            camera = [];
            if app.Session.Status=="rendered" && ~isempty(app.BatchRenderer.ActiveTarget) && isgraphics(app.BatchRenderer.ActiveTarget)
                camera = app.BatchRenderer.captureCamera();
            else
                previous = brainnet.core.SessionState.fromScene(scene);
                if ~isempty(previous) && strcmp(previous.scene_signature, ...
                        brainnet.core.SessionState.signature(scene))
                    camera = previous.camera;
                end
            end
            scene = brainnet.core.SessionState.attach(scene, camera, app.exportSettings());
        end

        function clearFigure(app)
            app.disableCameraTool();
            app.stopLiveDemo();
            if app.MovieExportInProgress || (~isempty(app.MovieWindow)&&isvalid(app.MovieWindow)&&app.MovieWindow.Busy)
                error('BNV:App:ExportInProgress','Wait for animation export to finish or cancel it before clearing the figure.');
            end
            if ~isempty(app.Session.Scene)
                state=brainnet.core.SessionState.fromScene(app.sceneWithSessionState());
                app.Session.clearRenderedState(state);
            end
            app.closeInspector();
            if ~isempty(app.MovieWindow)&&isvalid(app.MovieWindow), app.MovieWindow.requestClose(); end
            app.MovieWindow=[];
            app.BatchRenderer.closeActiveFigure();
            app.PopoutRenderer.closeActiveFigure();
            app.LegacyAdapter.closeActiveFigure();
            app.LastPreparedScene=[];
            app.LastRenderInfo=struct('backend','','status','cleared');
            app.LastExportInfo=struct('status','not-exported');
            app.showRenderCanvas(false);
            app.refreshView(PreservePendingSettings=true);
        end

        function report=resetVisualizationSettings(app,options)
            arguments
                app (1,1) brainnet.app.BrainNetApp
                options.Confirmed (1,1) logical = false
            end
            report=struct('status','cancelled');
            if ~options.Confirmed, return; end
            % Image/output preferences are not display styling and stay intact.
            imageSettings=app.DraftOptions.section('image');
            defaults=brainnet.core.VisualizationSettings().withPatch(struct('image',struct( ...
                'width',imageSettings.width,'height',imageSettings.height,'dpi',imageSettings.dpi)));
            candidate=brainnet.core.RenderOptions.fromVisualizationStruct(defaults.toStruct());
            replacement=[];
            if ~isempty(app.Session.Scene)
                value=app.Session.Scene.toStruct(); value.options=candidate.toStruct();
                replacement=brainnet.core.Scene.fromStruct(value);
                replacement=brainnet.core.SessionState.attach(replacement,[],app.exportSettings());
            end
            if app.MovieExportInProgress || (~isempty(app.MovieWindow)&&isvalid(app.MovieWindow)&&app.MovieWindow.Busy)
                error('BNV:App:ExportInProgress','Wait for animation export to finish or cancel it before restoring defaults.');
            end
            % Keep existing graphics intact as a preview, not an exportable
            % rendering of the newly restored settings.
            app.disableCameraTool();
            app.stopLiveDemo();
            app.closeInspector();
            app.DraftOptions=candidate;
            if ~isempty(replacement), app.Session.setScene(replacement); end
            app.LastPreparedScene=[];
            app.synchronizeSettingsDialog();
            app.refreshView();
            report.status='restored';
            app.StatusLabel.Text = 'Defaults restored. Current canvas kept; click Apply or Render Scene to redraw.';
            app.StatusLabel.Tooltip = app.StatusLabel.Text;
        end

        function applyScrollZoom(app, point, scrollCount)
            arguments
                app (1,1) brainnet.app.BrainNetApp
                point (1,2) double
                scrollCount (1,1) double
            end
            if app.CameraTool~="zoom" || app.RenderingInProgress || ...
                    ~all(isfinite([point scrollCount])) || scrollCount==0, return; end
            for a=reshape(app.BatchRenderer.ActiveAxes,1,[])
                if ~isgraphics(a), continue; end
                bounds=getpixelposition(a,true);
                if all(point>=bounds(1:2)) && all(point<=bounds(1:2)+bounds(3:4))
                    count=max(-10,min(10,scrollCount));
                    app.BatchRenderer.applyCameraGesture("zoom",[0 -12*count],a);
                    return;
                end
            end
        end

        function applyViewAction(app, action)
            % Public non-dialog equivalent of the modern canvas controls.
            app.stopLegacyUiMontageFitTimer();
            switch string(action)
                case "reset", app.BatchRenderer.resetCamera();
                case "fit", app.BatchRenderer.fitCamera();
                otherwise, app.BatchRenderer.setStandardView(string(action));
            end
        end

        function startLiveDemo(app)
            app.stopLegacyUiMontageFitTimer();
            app.disableCameraTool();
            if app.MovieExportInProgress || (~isempty(app.MovieWindow)&&isvalid(app.MovieWindow)&&app.MovieWindow.Busy)
                error('BNV:Demo:ExportInProgress','Wait for animation export to finish or cancel it before starting Live Demo.');
            end
            target=app.activeRenderTarget();
            if isempty(target), error('BNV:Demo:RenderRequired','Render a scene before starting Live Demo.'); end
            axesHandles=findall(target,'Type','axes');
            app.LiveDemo.start(axesHandles);
            app.refreshView(PreservePendingSettings=true);
        end

        function stopLiveDemo(app)
            if ~isempty(app.LiveDemo) && isvalid(app.LiveDemo), app.LiveDemo.stop(); end
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure), app.refreshView(PreservePendingSettings=true); end
        end

        function settings=inspectionSettings(app)
            if isempty(app.Session.Scene), error('BNV:Query:SceneRequired','Select a Scene first.'); end
            previous=brainnet.query.InspectionSettings.fromScene(app.Session.Scene);
            atlas=string(previous.atlas);
            if ~ismember(atlas,["aal","brodmann"]), atlas="aal"; end
            settings=brainnet.query.InspectionSettings.directMni(app.Session.Scene,atlas);
        end

        function configureInspection(app,settings)
            settings=brainnet.query.InspectionSettings.validate(settings);
            settings=brainnet.query.InspectionSettings.directMni(app.Session.Scene,string(settings.atlas));
            app.Session.setInspection(settings); app.LastInspection=struct();
        end

        function window=openMovieExporter(app,options)
            arguments
                app
                options.Visible (1,1) logical=true
            end
            if isempty(app.MovieWindow)||~isvalid(app.MovieWindow)
                app.MovieWindow=brainnet.app.MovieExportWindow(@(varargin) app.exportMovie(varargin{:}), ...
                    Visible=options.Visible,Theme=app.Theme,Parent=app.UIFigure);
            else
                app.MovieWindow.UIFigure.Visible=matlab.lang.OnOffSwitchState(options.Visible);
            end
            window=app.MovieWindow;
            app.positionChildWindow(window.UIFigure);
        end
        function record=exportMovie(app,destination,varargin)
            if app.MovieExportInProgress, error('BNV:Movie:Busy','An animation export is already running.'); end
            if app.Session.Status~="rendered" || ~strcmp(app.LastRenderInfo.backend,'batch') || isempty(app.LastPreparedScene)
                error('BNV:Movie:RenderRequired','Render with Modern Batch Renderer before exporting an animation.');
            end
            app.MovieExportInProgress=true;
            cleanup=onCleanup(@() app.finishMovieExport());
            record=brainnet.export.MovieExporter.export(app.BatchRenderer,app.sceneWithSessionState(), ...
                app.LastPreparedScene,string(destination),varargin{:});
        end
        function report=saveBoundaryFile(app,path)
            if app.Session.Status~="rendered" || ~strcmp(app.LastRenderInfo.backend,'batch') || isempty(app.LastPreparedScene)
                error('BNV:Boundary:RenderRequired','Render a mapped surface with Modern Batch Renderer before saving its boundary.');
            end
            report=brainnet.io.writeBoundary(app.Session.Scene,app.LastPreparedScene,path,app.Session.RootPath);
        end
        function surface=boundarySurface(app)
            if isempty(app.Session.Scene)
                error('BNV:Boundary:LoadSurface','Select a surface before binding a custom mask.');
            end
            inputs=app.Session.Scene.Inputs;
            selected=find(cellfun(@(input) input.Role=="surface",inputs),1);
            if isempty(selected)
                error('BNV:Boundary:LoadSurface','Select a surface before binding a custom mask.');
            end
            % Read only this input; binding must work before the first render
            % and must not discard pending settings or mutate session status.
            data=brainnet.io.readInput(inputs{selected},app.Session.RootPath); c=data.Coordinates;
            if isa(data,'brainnet.io.GiftiData'), c=c.'; end
            surface=struct('coordinates',c,'faces',data.Faces);
        end
        function coordinates=customColorNodes(app)
            if isempty(app.Session.Scene), error('BNV:EdgeCustom:Nodes','Load a node file before binding custom colors.'); end
            inputs=app.Session.Scene.Inputs; selected=find(cellfun(@(input) input.Role=="node",inputs),1);
            if isempty(selected), error('BNV:EdgeCustom:Nodes','Load a node file before binding custom colors.'); end
            data=brainnet.io.readInput(inputs{selected},app.Session.RootPath); coordinates=data.Coordinates;
        end

        function window=openSurfaceMerger(app,options)
            arguments
                app
                options.Visible (1,1) logical=true
            end
            if isempty(app.MergeWindow) || ~isvalid(app.MergeWindow)
                app.MergeWindow=brainnet.app.SurfaceMergeWindow( ...
                    Visible=options.Visible,Theme=app.Theme,Parent=app.UIFigure);
            else
                app.MergeWindow.UIFigure.Visible=matlab.lang.OnOffSwitchState(options.Visible);
            end
            window=app.MergeWindow;
            app.positionChildWindow(window.UIFigure);
        end
        function closeSurfaceMerger(app)
            if ~isempty(app.MergeWindow) && isvalid(app.MergeWindow), delete(app.MergeWindow); end
            app.MergeWindow=[];
        end
        function window=openSurfaceConverter(app,options)
            arguments
                app
                options.Visible (1,1) logical=true
            end
            if isempty(app.SurfaceConversionWindow) || ~isvalid(app.SurfaceConversionWindow)
                app.SurfaceConversionWindow=brainnet.app.SurfaceMergeWindow( ...
                    Operation="convert",Visible=options.Visible,Theme=app.Theme,Parent=app.UIFigure);
            else
                app.SurfaceConversionWindow.UIFigure.Visible=matlab.lang.OnOffSwitchState(options.Visible);
            end
            window=app.SurfaceConversionWindow;
            app.positionChildWindow(window.UIFigure);
        end
        function closeSurfaceConverter(app)
            if ~isempty(app.SurfaceConversionWindow) && isvalid(app.SurfaceConversionWindow), delete(app.SurfaceConversionWindow); end
            app.SurfaceConversionWindow=[];
        end
        function window=openSurfaceSubdivision(app,options)
            arguments
                app
                options.Visible (1,1) logical=true
            end
            if isempty(app.SurfaceSubdivisionWindow) || ~isvalid(app.SurfaceSubdivisionWindow)
                app.SurfaceSubdivisionWindow=brainnet.app.SurfaceSubdivisionWindow( ...
                    Visible=options.Visible,Theme=app.Theme,Parent=app.UIFigure);
            else
                app.SurfaceSubdivisionWindow.UIFigure.Visible=matlab.lang.OnOffSwitchState(options.Visible);
            end
            window=app.SurfaceSubdivisionWindow;
            app.positionChildWindow(window.UIFigure);
        end
        function closeSurfaceSubdivision(app)
            if ~isempty(app.SurfaceSubdivisionWindow) && isvalid(app.SurfaceSubdivisionWindow), delete(app.SurfaceSubdivisionWindow); end
            app.SurfaceSubdivisionWindow=[];
        end
        function window=openAtlasNodeGenerator(app,options)
            arguments
                app
                options.Visible (1,1) logical=true
            end
            if isempty(app.AtlasNodeWindow) || ~isvalid(app.AtlasNodeWindow)
                app.AtlasNodeWindow=brainnet.app.AtlasNodeWindow( ...
                    Visible=options.Visible,Theme=app.Theme,Parent=app.UIFigure);
            else
                app.AtlasNodeWindow.UIFigure.Visible=matlab.lang.OnOffSwitchState(options.Visible);
            end
            window=app.AtlasNodeWindow;
            app.positionChildWindow(window.UIFigure);
        end
        function closeAtlasNodeGenerator(app)
            if ~isempty(app.AtlasNodeWindow) && isvalid(app.AtlasNodeWindow), delete(app.AtlasNodeWindow); end
            app.AtlasNodeWindow=[];
        end
        function active=openInspector(app,options)
            arguments
                app
                options.Visible (1,1) logical=true
            end
            if isempty(app.BatchRenderer.ActiveTarget) || ~isgraphics(app.BatchRenderer.ActiveTarget)
                error('BNV:Query:RenderRequired','Render with Modern Batch Renderer before inspecting points.');
            end
            app.disableCameraTool();
            app.BatchRenderer.enableInspection(@(p,xyz) app.onInspectHit(p,xyz),true);
            if ~isempty(app.PopoutRenderer.ActiveTarget) && isgraphics(app.PopoutRenderer.ActiveTarget)
                app.PopoutRenderer.enableInspection(@(p,xyz) app.onInspectHit(p,xyz),true);
            end
            active=true;
        end

        function result=inspectPoint(app,role,point,index)
            arguments
                app
                role (1,1) string
                point (1,3) double
                index (1,1) double=0
            end
            result=brainnet.query.SceneInspector.queryDirectMni(app.Session.Scene,app.Session.Data, ...
                app.LastPreparedScene,role,point,index);
            app.LastInspection=result;
        end

        function stopInspection(app)
            for renderer={app.BatchRenderer,app.PopoutRenderer}
                if ~isempty(renderer{1}) && isvalid(renderer{1}) && renderer{1}.InspectEnabled
                    renderer{1}.enableInspection([],false);
                end
            end
            app.clearInspectionLabels();
        end

        function closeInspector(app)
            app.stopInspection();
            app.LastInspection=struct();
        end

        function selectInputPath(app, role, pathValue, options)
            arguments
                app (1, 1) brainnet.app.BrainNetApp
                role (1, 1) string
                pathValue (1, 1) string
                options.ExternalImportApproved (1, 1) logical = false
            end
            try
                if role == "auto"
                    role = app.classifyPath(pathValue);
                end
                [relative, inputPath, importMetadata, localPath] = app.makeRelative(pathValue, ...
                    ExternalImportApproved=options.ExternalImportApproved);
                app.validateRoleExtension(role, relative);
                hash = brainnet.io.internal.sha256File(inputPath);
                curated = brainnet.app.curatedInputMetadata(role,relative,hash);
                if isfield(curated.metadata,'curated_resource')
                    importMetadata.curated_resource = curated.metadata.curated_resource;
                end
                reference = brainnet.core.InputReference(role, relative, Sha256=hash, ...
                    CoordinateSpace=string(curated.coordinate_space), ...
                    RedistributionStatus=string(curated.redistribution_status), ...
                    Metadata=importMetadata, LocalPath=localPath);
                if role == "surface" && endsWith(lower(relative), ".pial")
                    % Validate the new mesh before replacing current inputs.
                    [~, information] = brainnet.io.readFreeSurferSurface(reference, app.Session.RootPath);
                    importMetadata.freesurfer=information;
                    reference = brainnet.core.InputReference(role, relative, Sha256=hash, ...
                        CoordinateSpace="FreeSurfer as-stored; registration unverified", ...
                        RedistributionStatus="user-provided-not-for-redistribution", ...
                        Metadata=importMetadata, LocalPath=localPath);
                elseif role == "surface" && endsWith(lower(relative), ".mesh")
                    [~, information] = brainnet.io.readBrainVisaMesh(reference, app.Session.RootPath);
                    importMetadata.brainvisa=information;
                    reference = brainnet.core.InputReference(role, relative, Sha256=hash, ...
                        CoordinateSpace="BrainVISA as-stored; registration unverified; no legacy XYZ inversion", ...
                        RedistributionStatus="user-provided-not-for-redistribution", ...
                        Metadata=importMetadata, LocalPath=localPath);
                elseif role == "surface" && endsWith(lower(relative), ".g")
                    [~, information] = brainnet.io.readByuSurface(reference, app.Session.RootPath);
                    importMetadata.byu=information;
                    reference = brainnet.core.InputReference(role, relative, Sha256=hash, ...
                        CoordinateSpace="BYU as-stored; registration and units unverified", ...
                        RedistributionStatus="user-provided-not-for-redistribution", ...
                        Metadata=importMetadata, LocalPath=localPath);
                elseif role == "surface" && endsWith(lower(relative), ".obj")
                    [~, information] = brainnet.io.readMniObjSurface(reference, app.Session.RootPath);
                    importMetadata.mni_bic=information;
                    reference = brainnet.core.InputReference(role, relative, Sha256=hash, ...
                        CoordinateSpace="MNI/BIC as-stored; registration and units unverified", ...
                        RedistributionStatus="user-provided-not-for-redistribution", ...
                        Metadata=importMetadata, LocalPath=localPath);
                elseif role == "surface" && any(endsWith(lower(relative), [".mz3", ".mz3.gz"]))
                    [~, information] = brainnet.io.readMz3Surface(reference, app.Session.RootPath);
                    importMetadata.mz3=information;
                    reference = brainnet.core.InputReference(role, relative, Sha256=hash, ...
                        CoordinateSpace="MZ3 as-stored; registration and units unverified", ...
                        RedistributionStatus="user-provided-not-for-redistribution", ...
                        Metadata=importMetadata, LocalPath=localPath);
                end
                roles = string(cellfun(@(item) char(item.Role), app.DraftInputs, 'UniformOutput', false));
                remove = roles == role;
                app.DraftInputs(remove) = [];
                app.DraftInputs{end + 1} = reference;
                app.applySurfaceOpacityDefaultForDraft();
                draftScene=app.buildDraftScene();
                app.closeInspector();
                app.BatchRenderer.closeActiveFigure();
                app.PopoutRenderer.closeActiveFigure();
                app.LegacyAdapter.closeActiveFigure();
                app.LastPreparedScene=[];
                app.LastRenderInfo=struct('backend','','status','not-rendered');
                app.LastExportInfo=struct('status','not-exported');
                app.Session.setScene(draftScene);
                app.refreshView();
            catch exception
                app.Session.recordError(exception);
                app.refreshView();
                rethrow(exception);
            end
        end

        function loaded = loadCurrentScene(app)
            try
                app.BatchRenderer.closeActiveFigure();
                app.PopoutRenderer.closeActiveFigure();
                app.LegacyAdapter.closeActiveFigure();
                app.LastPreparedScene = [];
                app.LastRenderInfo = struct('backend', '', 'status', 'not-rendered');
                app.LastExportInfo = struct('status', 'not-exported');
                app.Session.beginLoading();
                app.refreshView();
                drawnow limitrate;
                loaded = app.Session.loadScene();
                app.refreshView();
            catch exception
                app.refreshView();
                rethrow(exception);
            end
        end

        function figureHandle = renderCurrentScene(app, options)
            arguments
                app (1, 1) brainnet.app.BrainNetApp
                options.Visible (1, 1) logical = true
                options.Backend (1, 1) string = ""
                options.Target (1, 1) string = "auto"
            end
            if app.RenderingInProgress
                figureHandle = [];
                return;
            end
            app.setRenderBusy(true);
            renderCleanup = onCleanup(@() app.finishRender()); %#ok<NASGU>
            backend = options.Backend;
            app.disableCameraTool();
            app.stopLegacyUiMontageFitTimer();
            app.stopLiveDemo();
            if strlength(backend) == 0
                % The modern renderer is the single supported interactive backend.
                backend = "batch";
            end
            try
                if app.Session.Status ~= "loaded" && app.Session.Status ~= "rendered"
                    drawnow limitrate;
                    brainnet.core.DoubleBrain.requireScene(app.DraftOptions,app.Session.Scene);
                    brainnet.core.VolumeThresholdPolicy.requireSupported(app.DraftOptions.section('volume'));
                    app.Session.loadScene();
                end
                brainnet.core.VolumeThresholdPolicy.requireSupported(app.Session.Scene.Options.section('volume'));
                brainnet.core.DoubleBrain.requireScene(app.Session.Scene.Options,app.Session.Scene);
                if ~any(backend == ["batch", "legacy"])
                    error('BNV:App:UnsupportedRenderBackend', ...
                        'Renderer backend must be batch or legacy.');
                end
                target = lower(options.Target);
                if ~any(target == ["auto", "embedded", "window"])
                    error('BNV:App:UnsupportedRenderTarget', ...
                        'Render target must be auto, embedded, or window.');
                end
                if target == "auto"
                    if backend == "batch" && strcmp(app.UIFigure.Visible, 'on')
                        target = "embedded";
                    else
                        target = "window";
                    end
                end
                if backend == "legacy"
                    target = "window";
                end
                totalTimer = tic;
                drawnow limitrate;
                notify(app,'RenderingStarted');
                app.closeInspector();
                if backend == "batch"
                    replayScene = app.sceneWithSessionState();
                    replayState = brainnet.core.SessionState.fromScene(replayScene);
                    app.LegacyAdapter.closeActiveFigure();
                    [prepared, preparation] = app.Planner.prepare( ...
                        app.Session.Scene, app.Session.Data);
                    if target == "embedded"
                        app.showRenderCanvas(true);
                        drawnow limitrate;
                        [figureHandle, renderMetrics] = app.BatchRenderer.render( ...
                            prepared, app.Session.Scene.Options, ...
                            Visible=true, Parent=app.RenderCanvasPanel);
                    else
                        [figureHandle, renderMetrics] = app.BatchRenderer.render( ...
                            prepared, app.Session.Scene.Options, Visible=options.Visible);
                    end
                    renderMetrics.camera_restore = app.BatchRenderer.restoreCamera( ...
                        replayState.camera, AllowLayout2Fallback=true);
                    renderMetrics.camera_state = app.BatchRenderer.captureCamera();
                    app.LastRenderInfo = struct( ...
                        'backend', 'batch', ...
                        'target', char(target), ...
                        'status', 'pass', ...
                        'cache_hit', preparation.cache_hit, ...
                        'cache_key', preparation.cache_key, ...
                        'preparation_seconds', preparation.request_seconds, ...
                        'render_seconds', renderMetrics.total_seconds, ...
                        'total_seconds', toc(totalTimer), ...
                        'prepared', prepared.summary(), ...
                        'render_metrics', renderMetrics);
                    app.LastPreparedScene = prepared;
                else
                    app.BatchRenderer.closeActiveFigure();
                    app.LastPreparedScene = [];
                    figureHandle = app.LegacyAdapter.render( ...
                        app.Session.Scene, Visible=options.Visible);
                    app.LastRenderInfo = struct( ...
                        'backend', 'legacy', ...
                        'target', 'window', ...
                        'status', 'pass', ...
                        'cache_hit', false, ...
                        'cache_key', '', ...
                        'preparation_seconds', 0, ...
                        'render_seconds', toc(totalTimer), ...
                        'total_seconds', toc(totalTimer), ...
                        'warning', app.LegacyAdapter.LastWarning);
                end
                app.Session.markRendered(backend);
                app.LastExportInfo = struct('status', 'not-exported');
                app.refreshView();
                if backend == "batch" && target == "embedded"
                    % UIAxes viewports settle asynchronously after Apply on
                    % R2025a too, not only the older MATLAB releases.
                    app.LastRenderInfo.render_metrics.legacy_ui_viewport_refit = 'scheduled';
                    app.scheduleLegacyUiMontageFit(replayState.camera, ...
                        renderMetrics.camera_restore);
                end
            catch exception
                app.LastRenderInfo = struct( ...
                    'backend', char(backend), ...
                    'target', char(options.Target), ...
                    'status', 'error', ...
                    'identifier', exception.identifier, ...
                    'message', exception.message);
                app.Session.recordError(exception);
                app.refreshView();
                rethrow(exception);
            end
        end

        function configureExport(app, options)
            arguments
                app (1, 1) brainnet.app.BrainNetApp
                options.Format (1, 1) string = string(app.ExportFormatDropDown.Value)
                options.Resolution (1, 1) double {mustBeInteger, mustBePositive} = app.ExportResolutionField.Value
                options.Width (1, 1) double {mustBePositive} = app.ExportWidthField.Value
                options.Height (1, 1) double {mustBePositive} = app.ExportHeightField.Value
                options.Units (1, 1) string = string(app.ExportUnitsDropDown.Value)
                options.ContentType (1, 1) string = app.ExportContentType
                options.BackgroundColor (1, 1) string = app.selectedExportBackground()
            end
            if ~any(options.Format == ["png", "jpg", "tif", "bmp", "pdf", "svg"])
                error('BNV:App:UnsupportedExportFormat', ...
                    'Export format must be PNG, JPEG, TIFF, BMP, PDF, or SVG.');
            end
            if ~any(options.Units == ["pixels", "millimeters", "inches", "centimeters", "points"])
                error('BNV:App:UnsupportedExportUnits', 'Export units are not supported.');
            end
            if ~any(options.ContentType == ["auto", "image", "vector"])
                error('BNV:App:UnsupportedExportContent', ...
                    'Export content must be automatic, image, or vector.');
            end
            if ~any(options.BackgroundColor == ["current", "white", "black", "none"])
                error('BNV:App:UnsupportedExportBackground', ...
                    'Export background must be current, white, black, or transparent.');
            end
            if any(options.Format == ["png", "jpg", "tif", "bmp"]) && ...
                    options.ContentType == "vector"
                error('BNV:App:VectorRasterUnsupported', ...
                    'Raster formats support image content only.');
            end
            if any(options.Format == ["jpg", "bmp"]) && options.BackgroundColor == "none"
                error('BNV:App:TransparentRasterUnsupported', ...
                    'JPEG and BMP do not support a transparent background.');
            end
            app.ExportFormatDropDown.Value = char(options.Format);
            app.updateContentChoices(options.Format);
            app.ExportResolutionField.Value = options.Resolution;
            app.ExportWidthField.Value = options.Width;
            app.ExportHeightField.Value = options.Height;
            app.ExportUnitsDropDown.Value = char(options.Units);
            app.ExportContentType = options.ContentType;
            if options.BackgroundColor == "none"
                app.ExportTransparencyCheckBox.Value = true;
            else
                app.ExportTransparencyCheckBox.Value = false;
                app.ExportBackgroundPreference = options.BackgroundColor;
            end
            app.refreshView();
        end

        function value = visualizationSettings(app)
            value = app.DraftOptions.toVisualizationStruct();
        end

        function patchVisualizationSettings(app, patch)
            arguments
                app (1, 1) brainnet.app.BrainNetApp
                patch (1, 1) struct
            end
            candidate=app.DraftOptions.withPatch(patch);
            app.validateVertexColors(candidate);
            brainnet.core.DoubleBrain.requireScene(candidate,app.Session.Scene);
            brainnet.core.VolumeThresholdPolicy.requireSupported(candidate.section('volume'));
            app.DraftOptions = candidate;
            app.synchronizeDraftOptions();
            app.refreshView();
        end

        function preset = savePresetFile(app, pathValue, options)
            arguments
                app (1,1) brainnet.app.BrainNetApp
                pathValue (1,1) string
                options.Name (1,1) string = "Custom"
                options.Overwrite (1,1) logical = false
            end
            % Save applied settings, not pending edits in the accordion.
            preset = brainnet.core.VisualizationPreset(app.DraftOptions.Settings, options.Name);
            brainnet.io.writePreset(preset, pathValue, Overwrite=options.Overwrite);
        end

        function [preset, report] = inspectPresetFile(app, pathValue)
            preset = brainnet.io.readPreset(pathValue);
            report = preset.checkCompatibility(app.Session.Scene);
        end

        function report = loadPresetFile(app, pathValue, options)
            arguments
                app (1,1) brainnet.app.BrainNetApp
                pathValue (1,1) string
                options.AllowWarnings (1,1) logical = false
            end
            if pathValue == ""
                report = struct('status', 'cancelled');
                return;
            end
            [preset, report] = app.inspectPresetFile(pathValue);
            if ~isempty(report.blockers)
                error('BNV:Preset:UnsupportedFeature', '%s', strjoin(report.blockers, newline));
            end
            if ~isempty(report.warnings) && ~options.AllowWarnings
                error('BNV:Preset:ReviewRequired', '%s', strjoin(report.warnings, newline));
            end
            % Build the complete candidate before changing any App state.
            candidate = brainnet.core.RenderOptions.fromVisualizationStruct(preset.Settings.toStruct());
            if isempty(app.Session.Scene)
                app.DraftOptions = candidate;
                app.synchronizeSettingsDialog();
            else
                current = app.Session.Scene;
                replacement = brainnet.core.Scene(current.Id, current.Name, ...
                    current.LoadFile, current.MapMode, current.Inputs, Options=candidate, ...
                    SchemaVersion=current.SchemaVersion, CoordinateSpace=current.CoordinateSpace, ...
                    RedistributionStatus=current.RedistributionStatus, Metadata=current.Metadata);
                % Explicitly discard old cameras even when settings happen to match.
                replacement = brainnet.core.SessionState.attach(replacement, [], app.exportSettings());
                scenePath = app.SceneFilePath;
                app.setScene(replacement);
                app.SceneFilePath = scenePath;
            end
            report.status = 'applied';
            app.LastPresetReport = report;
            app.refreshView();
        end

        function dialog = openVisualizationSettings(app, options)
            arguments
                app (1, 1) brainnet.app.BrainNetApp
                options.Visible (1, 1) logical = true
                options.Tab (1, 1) string = "layout"
            end
            if isempty(app.SettingsDialog) || ...
                    ~isvalid(app.SettingsDialog) || ~app.SettingsDialog.isOpen()
                app.SettingsDialog = brainnet.app.VisualizationSettingsDialog( ...
                    app.DraftOptions.Settings, Parent=app.UIFigure, ...
                    Visible=options.Visible, ...
                    ApplyCallback=@(settings) app.applyVisualizationSettings(settings), ...
                    CloseCallback=@() app.onSettingsDialogClosed(), ...
                    FocusReturnCallback=@() app.scheduleLegacyUiMainFocus());
            elseif options.Visible
                app.SettingsDialog.show();
            end
            tabName = lower(options.Tab);
            if ~any(tabName == ["layout", "global"])
                tabName = "layout";
            end
            app.SettingsDialog.selectTab(tabName);
            dialog = app.SettingsDialog;
            app.positionChildWindow(dialog.UIFigure);
        end

        function setTheme(app, value)
            arguments
                app (1, 1) brainnet.app.BrainNetApp
                value (1, 1) string {mustBeMember(value, ["light", "dark"])}
            end
            app.Theme = value;
            app.ThemeSwitch.Value = char(upper(extractBefore(value, 2)) + ...
                extractAfter(value, 1));
            app.applyTheme();
        end

        function setSettingsPanelCollapsed(app, value)
            arguments
                app (1, 1) brainnet.app.BrainNetApp
                value (1, 1) logical
            end
            app.SettingsPanelCollapsed = value;
            app.applySettingsPanelState();
            app.applyResponsiveLayout();
        end

        function selectSettingsCategory(app, category)
            arguments
                app (1, 1) brainnet.app.BrainNetApp
                category (1, 1) string
            end
            app.SettingsAccordion.selectCategory(category);
        end

        function editor=openColormapEditor(app,options)
            arguments
                app
                options.Visible (1,1) logical = true
            end
            editor=app.SettingsAccordion.openColormapEditor(Visible=options.Visible);
            app.positionChildWindow(editor.UIFigure);
        end

        function figureHandle = popOutCurrentScene(app, options)
            arguments
                app (1, 1) brainnet.app.BrainNetApp
                options.Visible (1, 1) logical = true
            end
            if app.Session.Status ~= "loaded" && app.Session.Status ~= "rendered"
                app.Session.loadScene();
            end
            if isempty(app.LastPreparedScene)
                [prepared, ~] = app.Planner.prepare(app.Session.Scene, app.Session.Data);
            else
                prepared = app.LastPreparedScene;
            end
            [figureHandle, ~] = app.PopoutRenderer.render( ...
                prepared, app.Session.Scene.Options, Visible=options.Visible, ...
                WindowMode="centered");
            state = brainnet.core.SessionState.fromScene(app.sceneWithSessionState());
            app.PopoutRenderer.restoreCamera(state.camera);
            if app.BatchRenderer.InspectEnabled
                app.PopoutRenderer.enableInspection(@(p,xyz) app.onInspectHit(p,xyz),true);
            end
        end

        function record = exportCurrentFigure(app, outputPath, options)
            arguments
                app (1, 1) brainnet.app.BrainNetApp
                outputPath (1, 1) string
                options.Resolution (1, 1) double {mustBeInteger, mustBePositive} = app.ExportResolutionField.Value
                options.Width (1, 1) double {mustBePositive} = app.ExportWidthField.Value
                options.Height (1, 1) double {mustBePositive} = app.ExportHeightField.Value
                options.Units (1, 1) string = string(app.ExportUnitsDropDown.Value)
                options.ContentType (1, 1) string = app.ExportContentType
                options.BackgroundColor (1, 1) string = app.selectedExportBackground()
                options.Overwrite (1, 1) logical = false
            end
            try
                if app.Session.Status ~= "rendered" || ...
                        ~strcmp(app.LastRenderInfo.backend, 'batch') || ...
                        isempty(app.LastPreparedScene) || ...
                        isempty(app.BatchRenderer.ActiveTarget) || ...
                        ~isgraphics(app.BatchRenderer.ActiveTarget)
                    error('BNV:App:NoExportableFigure', ...
                        'Render the scene with Modern Batch Renderer before exporting.');
                end
                absolute = string(char(java.io.File(char(outputPath)).getCanonicalPath()));
                [folder, name, extension] = fileparts(absolute);
                if strlength(folder) == 0 || strlength(name) == 0 || strlength(extension) == 0
                    error('BNV:App:InvalidExportPath', ...
                        ['Choose an output path with a PNG, JPEG, TIFF, BMP, ' ...
                        'PDF, or SVG extension.']);
                end
                exporter = brainnet.export.FigureExporter(folder);
                timer = tic;
                metrics = app.LastRenderInfo.render_metrics;
                metrics.camera_state = app.BatchRenderer.captureCamera();
                record = exporter.exportFigure(app.BatchRenderer.ActiveTarget, ...
                    string(name) + string(extension), app.sceneWithSessionState(), ...
                    app.LastPreparedScene, metrics, ...
                    Resolution=options.Resolution, Width=options.Width, ...
                    Height=options.Height, Units=options.Units, ...
                    ContentType=options.ContentType, ...
                    BackgroundColor=options.BackgroundColor, ...
                    Overwrite=options.Overwrite);
                app.LastExportInfo = struct( ...
                    'status', 'pass', ...
                    'output_path', char(absolute), ...
                    'sidecar_path', char(absolute + ".provenance.json"), ...
                    'elapsed_seconds', toc(timer), ...
                    'record', record);
                app.refreshView();
            catch exception
                app.LastExportInfo = struct( ...
                    'status', 'error', ...
                    'identifier', exception.identifier, ...
                    'message', exception.message);
                app.refreshView();
                rethrow(exception);
            end
        end

        function value = snapshot(app)
            app.enforceMinimumWindowSize();
            value = app.Session.summary();
            value.product = app.ProductInfo;
            value.figure_visible = char(app.UIFigure.Visible);
            value.rendering_in_progress = app.RenderingInProgress;
            value.legacy_ui_main_focus_count = app.LegacyUiMainFocusCount;
            value.figure_position = app.UIFigure.Position;
            value.window_state = char(app.UIFigure.WindowState);
            value.viewport_position = getpixelposition(app.RootPanel, true);
            value.input_roles = cellfun(@(item) char(item.Role), app.DraftInputs, 'UniformOutput', false);
            value.input_paths = cellfun(@(item) char(item.RelativePath), app.DraftInputs, 'UniformOutput', false);
            value.scene_summary_text = app.SceneSummaryText;
            if isprop(app.SummaryArea, 'HTMLSource')
                value.scene_summary_html = char(app.SummaryArea.HTMLSource);
            else
                value.scene_summary_html = '';
            end
            value.render_enabled = strcmp(app.RenderButton.Enable, 'on');
            value.export_enabled = strcmp(app.ExportButton.Enable, 'on');
            value.renderer_backend = 'batch';
            value.available_renderers = {'batch'};
            value.render_cache = app.Planner.statistics();
            value.last_render = app.LastRenderInfo;
            value.last_export = app.LastExportInfo;
            value.export_settings = app.exportSettings();
            value.theme = char(app.Theme);
            value.layout_density = char(app.LayoutDensity);
            value.resources = app.ResourceSnapshot;
            value.visualization_settings = app.DraftOptions.toVisualizationStruct();
            value.full_settings_open = ~app.SettingsPanelCollapsed;
            value.settings_panel_collapsed = app.SettingsPanelCollapsed;
            value.tools_panel_collapsed = app.ToolsPanelCollapsed;
            value.settings_accordion = app.SettingsAccordion.snapshot();
            value.embedded_render_active = ...
                ~isempty(app.BatchRenderer.ActiveTarget) && ...
                isgraphics(app.BatchRenderer.ActiveTarget) && ...
                isempty(app.BatchRenderer.ActiveFigure);
            if isfield(app.LastRenderInfo, 'target')
                value.render_target = app.LastRenderInfo.target;
            else
                value.render_target = '';
            end
            value.component_ownership = struct( ...
                'scene_data', 'Data Sources', ...
                'view_and_render', 'Render Canvas', ...
                'object_style', 'Visualization Settings', ...
                'canvas_style', 'Visualization Settings', ...
                'output', 'Export Figure', ...
                'output_parent', 'Data Sources', ...
                'telemetry', 'Resource Status');
            value.drop_callback_configured = app.DropSupported;
            value.startup_image_available = isfile(app.ProductInfo.startup_image_path);
            value.startup_image_loaded = app.StartupImageLoaded;
            value.startup_image_path = app.ProductInfo.startup_image_path;
            value.startup_info_font_size = app.StartupInfoArea.FontSize;
            value.startup_info_font_weight = char(app.StartupInfoArea.FontWeight);
            value.startup_citation_font_size = app.StartupCitationLabel.FontSize;
            value.startup_citation_font_weight = char(app.StartupCitationLabel.FontWeight);
            value.startup_citation_font_color = app.StartupCitationLabel.FontColor;
            value.minimum_window_size = app.ProductInfo.minimum_window_size;
            value.header_control_sizes = struct( ...
                'theme', app.ThemeSwitch.Position(3:4), ...
                'help', app.HelpButton.Position(3:4), ...
                'about', app.AboutButton.Position(3:4));
            value.data_action_control_sizes = struct( ...
                'add_files', app.SelectInputButton.Position(3:4), ...
                'validate_load', app.LoadButton.Position(3:4));
            value.data_action_row_height = app.DataActionGrid.RowHeight{1};
            value.startup_info_text = char(app.StartupInfoArea.Text);
            value.startup_citation_text = char(app.StartupCitationLabel.Text);
            if app.StartupImageLoaded && isvalid(app.StartupImage)
                value.startup_canvas_image_position = app.StartupImage.Position;
            else
                value.startup_canvas_image_position = [];
            end
            if app.StartupImageLoaded && isvalid(app.BrandImage)
                value.startup_image_scale_method = char(app.BrandImage.ScaleMethod);
                value.startup_image_display_position = app.BrandImage.Position;
            else
                value.startup_image_scale_method = '';
                value.startup_image_display_position = [];
            end
            roleNames = ["Surface Mesh"; "Nodes"; "Edges"; "Surface Map"; ...
                "Volume / Atlas"; "Scene File"];
            roleKeys = ["surface", "node", "edge", "surface_map", ...
                "volume", "scene"];
            roleText = strings(0, 1);
            for roleIndex = 1:numel(roleKeys)
                key = char(roleKeys(roleIndex));
                roleText(end + 1, 1) = string(app.RoleDetailLabels.(key).Text); %#ok<AGROW>
                roleText(end + 1, 1) = string(app.RoleActionButtons.(key).Text); %#ok<AGROW>
            end
            visibleText = [string(app.TitleLabel.Text); string(app.WelcomeLabel.Text); ...
                string(app.ThemeLabel.Text); string(app.ThemeSwitch.Items(:)); ...
                string(app.HelpButton.Text); string(app.AboutButton.Text); ...
                string(app.DataPanel.Title); string(app.DropHintLabel.Text); ...
                roleNames; roleText; string(app.SelectInputButton.Text); ...
                string(app.LoadButton.Text); string(app.SaveSceneButton.Text); ...
                string(app.ImportSettingsButton.Text); ...
                string(app.LoadPresetButton.Text); string(app.SavePresetButton.Text); ...
                string(app.ColormapEditorButton.Text); ...
                string(app.ToolsToggleButton.Text); ...
                string(app.MergeSurfacesToolButton.Text); ...
                string(app.ConvertSurfaceToolButton.Text); ...
                string(app.SubdivideSurfaceToolButton.Text); ...
                string(app.GenerateAtlasNodesToolButton.Text); ...
                string(app.SaveBoundaryToolButton.Text); ...
                string(app.ExportAnimationToolButton.Text); ...
                string(app.SceneSummaryText(:)); string(app.PreviewPanel.Title); ...
                string(app.StartupInfoArea.Text); ...
                string(app.StartupCitationLabel.Text); ...
                string(app.ResetViewButton.Text); string(app.RotateButton.Text); string(app.InspectButton.Text); ...
                string(app.PanButton.Text); string(app.ZoomButton.Text); ...
                string(app.FitButton.Text); string(app.ViewDropDown.Items(:)); ...
                string(app.PopOutButton.Text); string(app.RenderButton.Text); ...
                app.SettingsAccordion.interfaceText().'; ...
                string(app.ExportPanel.Title); ...
                string(app.ExportFormatLabel.Text); string(app.ExportFormatDropDown.Items(:)); ...
                string(app.ExportResolutionLabel.Text); string(app.ExportWidthLabel.Text); ...
                string(app.ExportHeightLabel.Text); string(app.ExportUnitsLabel.Text); ...
                string(app.ExportUnitsDropDown.Items(:)); ...
                string(app.ExportTransparencyCheckBox.Text); ...
                string(app.ExportButton.Text); string(app.CpuResourceLabel.Text); ...
                string(app.MemoryResourceLabel.Text); string(app.GpuResourceLabel.Text); ...
                string(app.NetworkResourceLabel.Text); string(app.StatusLabel.Text)];
            value.interface_text = cellstr(visibleText);
        end

        function value = showAbout(app)
            value = [ ...
                string(app.ProductInfo.display_name) + " (" + string(app.ProductInfo.version) + ")"; ...
                "Developer: " + string(app.ProductInfo.developer); ...
                string(app.ProductInfo.citation); ...
                "DOI: " + string(app.ProductInfo.doi); ...
                "License: " + string(app.ProductInfo.license); ...
                "Repository: " + string(app.ProductInfo.repository)];
            if strcmp(app.UIFigure.Visible, 'on')
                uialert(app.UIFigure, join(value, newline), ...
                    'About BrainNet Viewer 2.0', 'Icon', 'info');
            end
        end

        function value = showHelp(app)
            catalog=brainnet.app.HelpDocuments.catalog(app.Session.RootPath);
            value = [ ...
                "Workflow"; ...
                "1. Select input files or open a Scene JSON or ZIP."; ...
                "2. Validate and load the scene."; ...
                "3. Configure visualization settings and Apply."; ...
                "4. Render and interact with the figure."; ...
                "5. Save or export the result."; ...
                "BrainNet Viewer 2.0 manuals and tutorials:"; ...
                "Manual - English: " + string(catalog.manual_en); ...
                "Manual - Chinese: " + string(catalog.manual_zh); ...
                "Tutorials - English: " + string(catalog.tutorials_en); ...
                "Tutorials - Chinese: " + string(catalog.tutorials_zh); ...
                "User Manual (PDF): " + string(app.ProductInfo.manual_path); ...
                "Project website: " + string(app.ProductInfo.website)];
            if strcmp(app.UIFigure.Visible, 'on')
                app.openHelpWindow();
            end
        end

        function window = openHelpWindow(app,options)
            arguments
                app (1,1) brainnet.app.BrainNetApp
                options.Visible (1,1) logical = true
            end
            if isempty(app.HelpWindow)||~isvalid(app.HelpWindow)||~isgraphics(app.HelpWindow.UIFigure)
                app.HelpWindow=brainnet.app.HelpWindow(app.Session.RootPath, ...
                    Visible=options.Visible,Parent=app.UIFigure);
            else
                app.HelpWindow.UIFigure.Visible=matlab.lang.OnOffSwitchState(options.Visible);
            end
            window=app.HelpWindow;
            app.positionChildWindow(window.UIFigure);
        end

        function close(app)
            app.Closing = true;
            app.stopLiveDemo();
            app.stopLegacyUiMontageFitTimer();
            app.stopLegacyUiFocusTimer();
            if ~isempty(app.HelpWindow)&&isvalid(app.HelpWindow), delete(app.HelpWindow); end
            if ~isempty(app.MovieWindow)&&isvalid(app.MovieWindow), app.MovieWindow.requestClose(); end
            app.closeSurfaceMerger();
            app.closeSurfaceConverter();
            app.closeSurfaceSubdivision();
            app.closeAtlasNodeGenerator();
            app.closeInspector();
            app.BatchRenderer.closeActiveFigure();
            app.PopoutRenderer.closeActiveFigure();
            app.LegacyAdapter.closeActiveFigure();
            app.stopResourceTimer();
            app.closeSettingsDialog();
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end

        function delete(app)
            app.Closing = true;
            app.stopLiveDemo();
            app.stopLegacyUiMontageFitTimer();
            app.stopLegacyUiFocusTimer();
            if ~isempty(app.HelpWindow)&&isvalid(app.HelpWindow), delete(app.HelpWindow); end
            if ~isempty(app.MovieWindow)&&isvalid(app.MovieWindow), app.MovieWindow.requestClose(); end
            app.closeSurfaceMerger();
            app.closeSurfaceConverter();
            app.closeSurfaceSubdivision();
            app.closeAtlasNodeGenerator();
            app.closeInspector();
            app.stopResourceTimer();
            if ~isempty(app.SettingsAccordion) && isvalid(app.SettingsAccordion)
                delete(app.SettingsAccordion);
            end
            app.closeSettingsDialog();
            if ~isempty(app.BatchRenderer) && isvalid(app.BatchRenderer)
                app.BatchRenderer.closeActiveFigure();
                delete(app.BatchRenderer);
            end
            if ~isempty(app.PopoutRenderer) && isvalid(app.PopoutRenderer)
                app.PopoutRenderer.closeActiveFigure();
                delete(app.PopoutRenderer);
            end
            if ~isempty(app.LegacyAdapter) && isvalid(app.LegacyAdapter)
                delete(app.LegacyAdapter);
            end
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end

    methods (Access = private)
        function positionChildWindow(app, child)
            if ~isgraphics(child) || ~isgraphics(app.UIFigure)
                return;
            end
            child.Position = brainnet.render.internal.screenAwarePosition( ...
                child.Position(3:4), ...
                AnchorPoint=brainnet.render.internal.figureAnchorPoint(app.UIFigure));
            if verLessThan('matlab','25.1') && ...
                    ~isappdata(child,'brainnet_main_focus_listener')
                listener=addlistener(child,'ObjectBeingDestroyed', ...
                    @(~,~) app.scheduleLegacyUiMainFocus());
                setappdata(child,'brainnet_main_focus_listener',listener);
            end
        end

        function onSaveBoundary(app)
            try
                [file,folder]=app.saveFileDialog({'*.txt','Per-vertex boundary mask'},'Save a new surface boundary mask','boundary.txt');
                if isequal(file,0), return; end
                report=app.saveBoundaryFile(fullfile(folder,file));
                uialert(app.UIFigure,sprintf('Saved %d boundary vertices of %d.\n%s', ...
                    report.boundary_vertices,report.vertices,report.output_path),'Boundary Saved','Icon','success');
            catch failure
                % A file-save failure must not invalidate the rendered Scene.
                uialert(app.UIFigure,failure.message,'Boundary Not Saved','Icon','error');
            end
        end
        function onInspectHit(app,source,point)
            try
                hitPoint=point;
                if strcmp(source.Tag,'brainnet-nodes')
                    [index,pickMethod]=brainnet.query.GraphicsPicker.nodeIndex(source,point);
                    point=brainnet.core.DoubleBrain.sourcePoint(source,point,index);
                    result=app.inspectPoint("node",point,index);
                    result.method=[result.method '; ' pickMethod];
                else
                    [index,pickMethod]=brainnet.query.GraphicsPicker.surfaceIndex(source,point);
                    point=brainnet.core.DoubleBrain.sourcePoint(source,point);
                    result=app.inspectPoint("surface",point,index);
                    result.method=[result.method '; ' pickMethod];
                end
                app.LastInspection=result;
                app.showInspectionLabel(ancestor(source,'axes'),hitPoint,result);
            catch failure
                app.showInspectionError(ancestor(source,'axes'),failure.message);
            end
        end
        function showInspectionLabel(app,axesHandle,~,result)
            app.clearInspectionLabels();
            if isempty(axesHandle) || ~isgraphics(axesHandle), return; end
            lines=brainnet.query.SceneInspector.canvasLabel(result);
            app.drawInspectionLabel(axesHandle,lines);
        end
        function showInspectionError(app,axesHandle,message)
            app.clearInspectionLabels();
            if isempty(axesHandle) || ~isgraphics(axesHandle), return; end
            app.drawInspectionLabel(axesHandle,"Inspect: "+string(message));
        end
        function drawInspectionLabel(app,axesHandle,lines)
            if app.Theme=="dark", background=[.12 .17 .24]; foreground=[.96 .97 .99];
            else, background=[1 1 1]; foreground=[.08 .13 .23]; end
            text(axesHandle,.06,.98,0,cellstr(lines), ...
                'Units','normalized','Tag','brainnet-inspect-label', ...
                'Interpreter','none','FontName','Arial','FontSize',10, ...
                'FontWeight','bold','Color',foreground, ...
                'BackgroundColor',background,'EdgeColor',[.55 .60 .68], ...
                'Margin',6,'HorizontalAlignment','left','VerticalAlignment','top', ...
                'HitTest','off','PickableParts','none','Clipping','on');
        end
        function clearInspectionLabels(app)
            for renderer={app.BatchRenderer,app.PopoutRenderer}
                if isempty(renderer{1}) || ~isvalid(renderer{1}), continue; end
                for axesHandle=reshape(renderer{1}.ActiveAxes,1,[])
                    if isgraphics(axesHandle)
                        delete(findall(axesHandle,'Tag','brainnet-inspect-label'));
                    end
                end
            end
        end
        function createComponents(app, titleText, useStartupImage)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Name = char(titleText);
            app.UIFigure.Position = ...
                brainnet.render.internal.screenAwarePosition( ...
                    app.ProductInfo.window_reference_size, ...
                    AdaptiveScale=true, ...
                    MonitorFraction=app.ProductInfo.window_monitor_fraction, ...
                    MaximumScale=1.15, ...
                    AnchorPoint=brainnet.render.internal.matlabDesktopAnchor(), ...
                    MinimumSize=app.ProductInfo.minimum_window_size);
            if isprop(app.UIFigure, 'WindowDropFcn')
                app.UIFigure.WindowDropFcn = @(source, event) app.onDrop(source, event);
                app.DropSupported = true;
            end

            app.createViewport();
            app.MainGrid = uigridlayout(app.RootPanel, [3 1]);
            app.MainGrid.RowHeight = {76, '1x', 28};
            app.MainGrid.ColumnWidth = {'1x'};
            app.MainGrid.Padding = [10 10 10 10];
            app.MainGrid.RowSpacing = 8;

            app.createHeader(useStartupImage);
            app.createWorkspace();
            app.createResourceBar();
            app.ResourceSnapshot = systemResourceSnapshot();
            app.UIFigure.SizeChangedFcn = ...
                @(source, event) app.onFigureSizeChanged(source, event);
            app.RootPanel.SizeChangedFcn = @(~,~) app.applyResponsiveLayout();
            app.enforceMinimumWindowSize();
            app.applyResponsiveLayout();
            app.applyTheme();
        end

        function createHeader(app, useStartupImage)
            app.HeaderPanel = uipanel(app.MainGrid, 'BorderType', 'none');
            app.HeaderPanel.Layout.Row = 1;
            app.HeaderPanel.Layout.Column = 1;
            app.HeaderGrid = uigridlayout(app.HeaderPanel, [2 3]);
            app.HeaderGrid.RowHeight = {42, 22};
            app.HeaderGrid.ColumnWidth = {126, '1x', 368};
            app.HeaderGrid.Padding = [8 5 8 5];
            app.HeaderGrid.RowSpacing = 0;
            app.HeaderGrid.ColumnSpacing = 8;

            if useStartupImage && isfile(app.ProductInfo.startup_image_path)
                app.BrandImage = uiimage(app.HeaderGrid);
                app.BrandImage.ImageSource = app.ProductInfo.startup_image_path;
                app.BrandImage.ScaleMethod = 'fit';
                app.BrandImage.Tooltip = ...
                    'Author-created BrainNet Viewer network visualization.';
                app.BrandImage.Layout.Row = [1 2];
                app.BrandImage.Layout.Column = 1;
                app.StartupImageLoaded = true;
            else
                app.HeaderGrid.ColumnWidth{1} = 0;
            end

            app.TitleLabel = uilabel(app.HeaderGrid);
            app.TitleLabel.Text = 'BrainNet Viewer';
            app.TitleLabel.FontSize = 26;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Layout.Row = 1;
            app.TitleLabel.Layout.Column = 2;

            app.WelcomeLabel = uilabel(app.HeaderGrid);
            app.WelcomeLabel.Text = 'Brain Connectome Visualization';
            app.WelcomeLabel.FontSize = 13;
            app.WelcomeLabel.Layout.Row = 2;
            app.WelcomeLabel.Layout.Column = 2;

            app.HeaderActionGrid = uigridlayout(app.HeaderGrid, [1 4]);
            app.HeaderActionGrid.Layout.Row = [1 2];
            app.HeaderActionGrid.Layout.Column = 3;
            app.HeaderActionGrid.RowHeight = {36};
            app.HeaderActionGrid.ColumnWidth = {48, 112, 88, 88};
            app.HeaderActionGrid.Padding = [0 10 0 10];
            app.HeaderActionGrid.ColumnSpacing = 8;

            app.ThemeLabel = uilabel(app.HeaderActionGrid, 'Text', 'Theme');
            app.ThemeLabel.HorizontalAlignment = 'right';
            app.ThemeLabel.FontWeight = 'bold';
            app.ThemeLabel.Layout.Column = 1;

            app.ThemeSwitch = uidropdown(app.HeaderActionGrid);
            app.ThemeSwitch.Items = {'Light', 'Dark'};
            app.ThemeSwitch.Value = 'Light';
            app.ThemeSwitch.ValueChangedFcn = ...
                @(source, event) app.onThemeChanged(source, event);
            app.ThemeSwitch.Layout.Column = 2;

            app.HelpButton = uibutton(app.HeaderActionGrid, 'push');
            app.HelpButton.Text = 'Help';
            app.HelpButton.FontWeight = 'bold';
            app.HelpButton.Tooltip = 'Open local manuals, illustrated tutorials and the unified English PDF for MATLAB and Python Desktop.';
            app.HelpButton.ButtonPushedFcn = @(source, event) app.onHelp(source, event);
            app.HelpButton.Layout.Column = 3;

            app.AboutButton = uibutton(app.HeaderActionGrid, 'push');
            app.AboutButton.Text = 'About';
            app.AboutButton.FontWeight = 'bold';
            app.AboutButton.Tooltip = ...
                'Show version, authorship, citation, and license information.';
            app.AboutButton.ButtonPushedFcn = @(source, event) app.onAbout(source, event);
            app.AboutButton.Layout.Column = 4;
        end

        function createWorkspace(app)
            app.WorkGrid = uigridlayout(app.MainGrid, [1 3]);
            app.WorkGrid.Layout.Row = 2;
            app.WorkGrid.Layout.Column = 1;
            app.WorkGrid.ColumnWidth = {270, '1x', 330};
            app.WorkGrid.RowHeight = {'1x'};
            app.WorkGrid.Padding = [0 0 0 0];
            app.WorkGrid.ColumnSpacing = 8;
            app.createDataPanel();
            app.createPreviewPanel();
            app.createSettingsPanel();
        end

        function createDataPanel(app)
            app.DataPanel = uipanel(app.WorkGrid, 'Title', 'Data Sources', ...
                'FontWeight', 'bold');
            app.DataPanel.Layout.Row = 1;
            app.DataPanel.Layout.Column = 1;
            app.DataGrid = uigridlayout(app.DataPanel, [5 1]);
            app.DataGrid.RowHeight = {34, 36, 248, '1x', 154};
            app.DataGrid.ColumnWidth = {'1x'};
            app.DataGrid.Padding = [8 6 8 6];
            app.DataGrid.RowSpacing = 5;
            app.DataGrid.Scrollable = 'on';

            app.DropHintLabel = uilabel(app.DataGrid);
            app.DropHintLabel.Text = 'Drop supported files here or use Add Files.';
            app.DropHintLabel.WordWrap = 'on';
            app.DropHintLabel.HorizontalAlignment = 'center';
            app.DropHintLabel.Layout.Row = 1;
            app.DataActionGrid = uigridlayout(app.DataGrid, [1 2]);
            app.DataActionGrid.Layout.Row = 2;
            app.DataActionGrid.RowHeight = {32};
            app.DataActionGrid.ColumnWidth = {'1x', '1x'};
            app.DataActionGrid.Padding = [0 0 0 0];
            app.DataActionGrid.ColumnSpacing = 5;
            app.SelectInputButton = uibutton(app.DataActionGrid, 'push', ...
                'Text', 'Add Files', ...
                'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(source, event) app.onSelectInput(source, event));
            app.SelectInputButton.Layout.Row = 1;
            app.SelectInputButton.Layout.Column = 1;
            app.LoadButton = uibutton(app.DataActionGrid, 'push');
            app.LoadButton.Text = 'Validate and Load';
            app.LoadButton.FontWeight = 'bold';
            app.LoadButton.ButtonPushedFcn = @(source, event) app.onLoad(source, event);
            app.LoadButton.Layout.Row = 1;
            app.LoadButton.Layout.Column = 2;

            app.DataRoleGrid = uigridlayout(app.DataGrid, [7 3]);
            app.DataRoleGrid.Layout.Row = 3;
            app.DataRoleGrid.RowHeight = repmat({32}, 1, 7);
            app.DataRoleGrid.ColumnWidth = {92, '1x', 52};
            app.DataRoleGrid.Padding = [0 0 0 0];
            app.DataRoleGrid.RowSpacing = 4;
            app.DataRoleGrid.ColumnSpacing = 4;
            roles = ["surface", "node", "edge", "surface_map", ...
                "volume", "scene"];
            labels = ["Surface Mesh", "Nodes", "Edges", "Surface Map", ...
                "Volume / Atlas", "Scene File"];
            for index = 1:numel(roles)
                key = char(roles(index));
                label = uilabel(app.DataRoleGrid, 'Text', char(labels(index)));
                label.FontWeight = 'bold';
                label.Layout.Row = index;
                label.Layout.Column = 1;
                detail = uilabel(app.DataRoleGrid, 'Text', 'Not selected');
                detail.Tooltip = 'No file selected.';
                detail.Layout.Row = index;
                detail.Layout.Column = 2;
                button = uibutton(app.DataRoleGrid, 'push', 'Text', 'Add', ...
                    'ButtonPushedFcn', @(~, ~) app.onRoleAction(roles(index)));
                button.FontWeight = 'bold';
                button.Layout.Row = index;
                button.Layout.Column = 3;
                app.RoleDetailLabels.(key) = detail;
                app.RoleActionButtons.(key) = button;
            end
            app.RoleDetailLabels.edge.Text = 'Requires Nodes';
            app.RoleActionButtons.scene.Text = 'Open';
            app.OpenSceneButton = app.RoleActionButtons.scene;

            app.SceneActionGrid = uigridlayout(app.DataRoleGrid, [1 2]);
            app.SceneActionGrid.Layout.Row = 7;
            app.SceneActionGrid.Layout.Column = [1 3];
            app.SceneActionGrid.RowHeight = {32};
            app.SceneActionGrid.ColumnWidth = {'1x', '1x'};
            app.SceneActionGrid.Padding = [0 0 0 0];
            app.SceneActionGrid.ColumnSpacing = 5;
            app.SaveSceneButton = uibutton(app.SceneActionGrid, 'push', ...
                'Text', 'Save Scene', 'Tag', 'SaveScene', ...
                'Tooltip', ['JSON saves file paths on this computer without copying data. ' ...
                    'To move or share the data, choose Portable Scene with data (*.zip).'], ...
                'ButtonPushedFcn', @(~, ~) app.onSaveScene());
            app.SaveSceneButton.FontWeight = 'bold';
            app.ImportSettingsButton = uibutton(app.SceneActionGrid, 'push', ...
                'Text', 'Import Settings', 'Tag', 'ImportSettings', ...
                'Tooltip', 'Import a trusted legacy EC MAT configuration.', ...
                'ButtonPushedFcn', @(~, ~) app.onImportLegacyConfig());
            app.ImportSettingsButton.FontWeight = 'bold';

            app.SummaryArea = uihtml(app.DataGrid,'Tag','SceneSummary');
            app.SummaryArea.Layout.Row = 4;
            app.createExportPanel();
        end

        function createPreviewPanel(app)
            app.PreviewPanel = uipanel(app.WorkGrid, 'Title', 'Render Canvas', ...
                'FontWeight', 'bold');
            app.PreviewPanel.Layout.Row = 1;
            app.PreviewPanel.Layout.Column = 2;
            app.PreviewGrid = uigridlayout(app.PreviewPanel, [2 1]);
            app.PreviewGrid.RowHeight = {34, '1x'};
            app.PreviewGrid.ColumnWidth = {'1x'};
            app.PreviewGrid.Padding = [6 5 6 5];
            app.PreviewGrid.RowSpacing = 5;

            app.PreviewToolbarGrid = uigridlayout(app.PreviewGrid, [1 12]);
            app.PreviewToolbarGrid.Layout.Row = 1;
            app.PreviewToolbarGrid.ColumnWidth = ...
                {50, 54, 44, 48, 40, 60, 54, 62, '1x', 96, 72, 110};
            app.PreviewToolbarGrid.Padding = [0 0 0 0];
            app.PreviewToolbarGrid.ColumnSpacing = 4;
            app.ResetViewButton = app.toolbarButton('Reset', 1, 'reset');
            app.RotateButton = app.toolbarButton('Rotate', 2, 'rotate');
            app.PanButton = app.toolbarButton('Pan', 3, 'pan');
            app.ZoomButton = app.toolbarButton('Zoom', 4, 'zoom');
            app.RotateButton.Tooltip='Drag on a brain view to rotate only that view.';
            app.PanButton.Tooltip='Drag on a brain view to pan only that view.';
            app.ZoomButton.Tooltip='Drag upward to magnify or downward to reduce only that brain view.';
            app.FitButton = app.toolbarButton('Fit', 5, 'fit');
            app.DemoButton=uibutton(app.PreviewToolbarGrid,'Text','Live Demo','Tag','StartLiveDemo', ...
                'Tooltip','Continuously rotate the current rendered view. This is not animation export.', ...
                'ButtonPushedFcn',@(~,~) app.runUiAction(@() app.startLiveDemo()));
            app.DemoButton.Layout.Column=6;
            app.StopDemoButton=uibutton(app.PreviewToolbarGrid,'Text','Stop Demo','Tag','StopLiveDemo', ...
                'Tooltip','Stop the live camera rotation and retain the current camera position.', ...
                'ButtonPushedFcn',@(~,~) app.stopLiveDemo());
            app.StopDemoButton.Layout.Column=7;
            app.InspectButton = app.toolbarButton('Inspect',8,'inspect');
            app.InspectButton.Tag='InspectScene';
            app.InspectButton.Tooltip='Click a surface or node to show AAL and Brodmann labels on the canvas; click Inspect again to clear.';
            app.ViewDropDown = uidropdown(app.PreviewToolbarGrid);
            app.ViewDropDown.Items = {'Layout / Custom', 'Left Lateral', 'Right Lateral', ...
                'Anterior', 'Posterior', 'Superior', 'Inferior'};
            app.ViewDropDown.ItemsData = {'layout', 'left', 'right', 'anterior', ...
                'posterior', 'superior', 'inferior'};
            app.ViewDropDown.Value = 'layout';
            app.ViewDropDown.ValueChangedFcn = ...
                @(source, event) app.onViewChanged(source, event);
            app.ViewDropDown.Layout.Row = 1;
            app.ViewDropDown.Layout.Column = 9;

            app.PopOutButton = uibutton(app.PreviewToolbarGrid, 'push');
            app.PopOutButton.Text = 'Pop Out';
            app.PopOutButton.Tooltip = ...
                'Open the current scene in a centered interactive figure.';
            app.PopOutButton.ButtonPushedFcn = @(source, event) app.onPopOut(source, event);
            app.PopOutButton.Layout.Column = 11;
            app.ClearFigureButton=uibutton(app.PreviewToolbarGrid,'Text','Clear Figure','Tag','ClearFigure', ...
                'Tooltip','Clear rendered views, retaining inputs, applied settings and the current camera for Render Scene.', ...
                'ButtonPushedFcn',@(~,~) app.runPresetAction(@() app.clearFigure()));
            app.ClearFigureButton.Layout.Column=10;
            app.RenderButton = uibutton(app.PreviewToolbarGrid, 'push');
            app.RenderButton.Text = 'Render Scene';
            app.RenderButton.FontWeight = 'bold';
            app.RenderButton.ButtonPushedFcn = @(source, event) app.onRender(source, event);
            app.RenderButton.Layout.Column = 12;

            app.PreviewCanvasGrid = uigridlayout(app.PreviewGrid, [1 1]);
            app.PreviewCanvasGrid.Layout.Row = 2;
            app.PreviewCanvasGrid.Padding = [0 0 0 0];
            app.StartupPanel = uipanel(app.PreviewCanvasGrid, 'BorderType', 'none');
            app.StartupPanel.Layout.Row = 1;
            app.StartupPanel.Layout.Column = 1;
            app.StartupGrid = uigridlayout(app.StartupPanel, [3 3]);
            app.StartupGrid.RowHeight = {'1x', 78, 56};
            app.StartupGrid.ColumnWidth = {'0.6x', '4x', '0.6x'};
            app.StartupGrid.Padding = [20 16 20 12];
            app.StartupGrid.RowSpacing = 4;
            app.StartupGrid.ColumnSpacing = 0;
            if app.StartupImageLoaded
                app.StartupImage = uiimage(app.StartupGrid, ...
                    'ImageSource', app.ProductInfo.startup_image_path, ...
                    'ScaleMethod', 'fit', ...
                    'Tooltip', 'Author-created BrainNet Viewer network visualization.');
                app.StartupImage.Layout.Row = 1;
                app.StartupImage.Layout.Column = 2;
                app.PreviewImage = app.StartupImage;
            end
            startupVersion = ['Version ' app.ProductInfo.version ' · ' ...
                app.ProductInfo.release_status];
            if ~isempty(app.ProductInfo.build_date)
                startupVersion = [startupVersion ' · ' app.ProductInfo.build_date];
            end
            app.StartupInfoArea = uilabel(app.StartupGrid, ...
                'Text', [startupVersion ...
                ' · Developer: ' app.ProductInfo.developer newline ...
                'Project: ' app.ProductInfo.repository], ...
                'HorizontalAlignment', 'center','WordWrap','on');
            app.StartupInfoArea.FontSize = 15;
            app.StartupInfoArea.FontWeight = 'bold';
            app.StartupInfoArea.Layout.Row = 2;
            app.StartupInfoArea.Layout.Column = [1 3];
            app.StartupCitationLabel = uilabel(app.StartupGrid, ...
                'Text', app.ProductInfo.citation, 'WordWrap', 'on', ...
                'HorizontalAlignment', 'center');
            app.StartupCitationLabel.FontSize = 14;
            app.StartupCitationLabel.FontWeight = 'bold';
            app.StartupCitationLabel.FontColor = [.80 .12 .16];
            app.StartupCitationLabel.Layout.Row = 3;
            app.StartupCitationLabel.Layout.Column = [1 3];

            app.RenderCanvasPanel = uipanel(app.PreviewCanvasGrid, ...
                'BorderType', 'none', 'Visible', 'off', 'AutoResizeChildren', 'off');
            app.RenderCanvasPanel.Layout.Row = 1;
            app.RenderCanvasPanel.Layout.Column = 1;
            app.PreviewPanel.AutoResizeChildren = 'off';
            app.PreviewPanel.SizeChangedFcn = @(~,~) app.layoutPreviewToolbar();
            app.layoutPreviewToolbar();
        end

        function button = toolbarButton(app, textValue, column, action)
            button = uibutton(app.PreviewToolbarGrid, 'push');
            button.Text = textValue;
            button.ButtonPushedFcn = ...
                @(source, event) app.onViewAction(action, source, event);
            button.Layout.Row = 1;
            button.Layout.Column = column;
        end

        function createSettingsPanel(app)
            app.SettingsPanel = uipanel(app.WorkGrid, 'BorderType', 'none');
            app.SettingsPanel.Layout.Row = 1;
            app.SettingsPanel.Layout.Column = 3;
            app.SettingsGrid = uigridlayout(app.SettingsPanel, [4 1]);
            app.SettingsGrid.RowHeight = {34, 30, '1x', 30};
            app.SettingsGrid.Padding = [0 0 0 0];
            app.SettingsGrid.RowSpacing = 3;
            app.SettingsHeaderGrid = uigridlayout(app.SettingsGrid, [1 2]);
            app.SettingsHeaderGrid.Layout.Row = 1;
            app.SettingsHeaderGrid.RowHeight = {34};
            app.SettingsHeaderGrid.ColumnWidth = {'1x', 34};
            app.SettingsHeaderGrid.Padding = [8 0 0 0];
            app.SettingsTitleLabel = uilabel(app.SettingsHeaderGrid, ...
                'Text', 'Visualization Settings', 'FontWeight', 'bold');
            app.SettingsTitleLabel.Layout.Column = 1;
            app.SettingsCollapseButton = uibutton(app.SettingsHeaderGrid, 'push', ...
                'Text', '<', 'Tooltip', 'Collapse visualization settings', ...
                'ButtonPushedFcn', @(~, ~) app.toggleSettingsPanel());
            app.SettingsCollapseButton.Layout.Column = 2;
            app.PresetActionGrid = uigridlayout(app.SettingsGrid, [1 3]);
            app.PresetActionGrid.ColumnWidth = {'1x','1x',64};
            app.PresetActionGrid.Layout.Row = 2;
            app.PresetActionGrid.RowHeight = {28};
            app.PresetActionGrid.Padding = [4 0 4 0];
            app.LoadPresetButton = uibutton(app.PresetActionGrid, ...
                'Text', 'Load Preset', 'Tag', 'LoadPreset', ...
                'Tooltip', 'Reuse display settings without replacing input files', ...
                'ButtonPushedFcn', @(~,~) app.onLoadPreset());
            app.LoadPresetButton.FontWeight = 'bold';
            app.SavePresetButton = uibutton(app.PresetActionGrid, ...
                'Text', 'Save Preset', 'Tag', 'SavePreset', ...
                'Tooltip', 'Save applied display settings only; apply pending edits first', ...
                'ButtonPushedFcn', @(~,~) app.onSavePreset());
            app.SavePresetButton.FontWeight = 'bold';
            app.ColormapEditorButton = uibutton(app.PresetActionGrid, ...
                'Text','Colors...','Tag','EditColormaps', ...
                'Tooltip','Edit Surface, Node, Edge and Volume colormaps; stage changes before Apply', ...
                'ButtonPushedFcn',@(~,~) app.runUiAction(@() app.openColormapEditor()));
            app.ColormapEditorButton.FontWeight = 'bold';
            app.FullSettingsPanel = uipanel(app.SettingsGrid, ...
                'BorderType', 'none');
            app.FullSettingsPanel.Layout.Row = 3;
            app.SettingsAccordion = brainnet.app.VisualizationSettingsAccordion( ...
                app.FullSettingsPanel, app.DraftOptions.Settings, ...
                ApplyCallback=@(settings) app.applyVisualizationSettings(settings), ...
                ResetCallback=@() app.runPresetAction(@() app.requestRestoreDefaults()), ...
                SurfaceContext=@() app.boundarySurface(),NodeContext=@() app.customColorNodes(), ...
                FocusReturnCallback=@() app.scheduleLegacyUiMainFocus());
            app.FullSettingsGrid = app.SettingsAccordion.Grid;
            app.createToolsPanel();
        end

        function createToolsPanel(app)
            app.ToolsPanel = uipanel(app.SettingsGrid, 'BorderType', 'none', ...
                'Tag', 'BrainNetToolsPanel');
            app.ToolsPanel.Layout.Row = 4;
            app.ToolsContainerGrid = uigridlayout(app.ToolsPanel, [2 1]);
            app.ToolsContainerGrid.RowHeight = {28, 0};
            app.ToolsContainerGrid.Padding = [0 0 0 0];
            app.ToolsContainerGrid.RowSpacing = 3;
            app.ToolsToggleButton = uibutton(app.ToolsContainerGrid, 'push', ...
                'Text', 'Tools >', 'FontWeight', 'bold', 'Tag', 'ToolsToggle', ...
                'Tooltip', 'Expand tools', 'ButtonPushedFcn', @(~,~) app.toggleToolsPanel());
            app.ToolsToggleButton.Layout.Row = 1;
            app.ToolsGrid = uigridlayout(app.ToolsContainerGrid, [3 2]);
            app.ToolsGrid.Layout.Row = 2;
            app.ToolsGrid.Visible = 'off';
            app.ToolsGrid.RowHeight = {24, 24, 24};
            app.ToolsGrid.ColumnWidth = {'1x', '1x'};
            app.ToolsGrid.Padding = [5 4 5 4];
            app.ToolsGrid.RowSpacing = 3;
            app.ToolsGrid.ColumnSpacing = 4;
            app.MergeSurfacesToolButton = app.toolButton('Merge', 1, 1, ...
                'Merge Surfaces', @() app.openSurfaceMerger());
            app.ConvertSurfaceToolButton = app.toolButton('Convert', 1, 2, ...
                'Convert Surface to NV', @() app.openSurfaceConverter());
            app.SubdivideSurfaceToolButton = app.toolButton('Subdivide', 2, 1, ...
                'Subdivide Surface to NV', @() app.openSurfaceSubdivision());
            app.GenerateAtlasNodesToolButton = app.toolButton('Atlas Nodes', 2, 2, ...
                'Generate Nodes from Atlas', @() app.openAtlasNodeGenerator());
            app.SaveBoundaryToolButton = app.toolButton('Save Boundary', 3, 1, ...
                'Save Surface Boundary', @() app.onSaveBoundary());
            app.SaveBoundaryToolButton.Enable = 'off';
            app.ExportAnimationToolButton = app.toolButton('Animation', 3, 2, ...
                'Export Animation', @() app.openMovieExporter());
            app.ExportAnimationToolButton.Enable = 'off';
        end

        function button = toolButton(app, textValue, row, column, tooltip, action)
            button = uibutton(app.ToolsGrid, 'push', 'Text', textValue, ...
                'Tag', char("Tool_" + replace(string(textValue), " ", "")), ...
                'Tooltip', tooltip, 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~,~) app.runUiAction(action));
            button.Layout.Row = row;
            button.Layout.Column = column;
        end

        function addQuickLabel(app, textValue, row)
            label = uilabel(app.QuickGrid, 'Text', textValue);
            label.Layout.Row = row;
            label.Layout.Column = 1;
        end

        function createBottomWorkspace(app)
            app.BottomGrid = uigridlayout(app.MainGrid, [1 1]);
            app.BottomGrid.Layout.Row = 3;
            app.BottomGrid.ColumnWidth = {'1x'};
            app.BottomGrid.Padding = [0 0 0 0];
            app.createExportPanel();
        end

        function createViewportPanel(app)
            app.ViewportPanel = uipanel(app.BottomGrid, 'Title', 'Viewport');
            app.ViewportPanel.Layout.Column = 1;
            app.ViewportGrid = uigridlayout(app.ViewportPanel, [4 2]);
            app.ViewportGrid.RowHeight = repmat({25}, 1, 4);
            app.ViewportGrid.ColumnWidth = {105, '1x'};
            app.ViewportGrid.Padding = [6 5 6 5];
            app.ViewportGrid.RowSpacing = 2;
            app.addViewportLabel('Canvas Background', 1);
            app.CanvasBackgroundDropDown = uidropdown(app.ViewportGrid);
            app.CanvasBackgroundDropDown.Items = {'White', 'Black', 'Light Gray'};
            app.CanvasBackgroundDropDown.ItemsData = {'white', 'black', 'gray'};
            app.CanvasBackgroundDropDown.Value = 'white';
            app.CanvasBackgroundDropDown.ValueChangedFcn = ...
                @(source, event) app.onViewportChanged(source, event);
            app.CanvasBackgroundDropDown.Layout.Row = 1;
            app.CanvasBackgroundDropDown.Layout.Column = 2;
            app.addViewportLabel('Grid', 2);
            app.GridCheckBox = uicheckbox(app.ViewportGrid, 'Text', 'Show', 'Value', false);
            app.GridCheckBox.ValueChangedFcn = ...
                @(source, event) app.onViewportChanged(source, event);
            app.GridCheckBox.Layout.Row = 2;
            app.GridCheckBox.Layout.Column = 2;
            app.addViewportLabel('Lighting', 3);
            app.LightingDropDown = uidropdown(app.ViewportGrid);
            app.LightingDropDown.Items = {'Studio', 'Headlight', 'None'};
            app.LightingDropDown.ItemsData = {'studio', 'headlight', 'none'};
            app.LightingDropDown.Value = 'studio';
            app.LightingDropDown.ValueChangedFcn = ...
                @(source, event) app.onViewportChanged(source, event);
            app.LightingDropDown.Layout.Row = 3;
            app.LightingDropDown.Layout.Column = 2;
            app.addViewportLabel('Clipping', 4);
            app.ClippingDropDown = uidropdown(app.ViewportGrid);
            app.ClippingDropDown.Items = {'Off', 'X Plane', 'Y Plane', 'Z Plane'};
            app.ClippingDropDown.ItemsData = {'off', 'x', 'y', 'z'};
            app.ClippingDropDown.Value = 'off';
            app.ClippingDropDown.Enable = 'off';
            app.ClippingDropDown.Tooltip = ...
                'Enabled with the interactive clipping implementation.';
            app.ClippingDropDown.Layout.Row = 4;
            app.ClippingDropDown.Layout.Column = 2;
        end

        function addViewportLabel(app, textValue, row)
            label = uilabel(app.ViewportGrid, 'Text', textValue);
            label.Layout.Row = row;
            label.Layout.Column = 1;
        end

        function createExportPanel(app)
            app.ExportPanel = uipanel(app.DataGrid, 'Title', 'Export Figure', ...
                'FontWeight', 'bold');
            app.ExportPanel.Layout.Row = 5;
            app.ExportGrid = uigridlayout(app.ExportPanel, [5 3]);
            app.ExportGrid.RowHeight = {17, 24, 17, 24, 28};
            app.ExportGrid.ColumnWidth = {'1x', '0.85x', '1.25x'};
            app.ExportGrid.Padding = [5 3 5 4];
            app.ExportGrid.RowSpacing = 2;
            app.ExportGrid.ColumnSpacing = 4;

            app.ExportFormatLabel = app.exportLabel('Format', 1);
            app.ExportFormatDropDown = uidropdown(app.ExportGrid);
            app.ExportFormatDropDown.Items = {'PNG', 'JPEG', 'TIFF', 'BMP', 'PDF', 'SVG'};
            app.ExportFormatDropDown.ItemsData = {'png', 'jpg', 'tif', 'bmp', 'pdf', 'svg'};
            app.ExportFormatDropDown.Value = 'png';
            app.ExportFormatDropDown.ValueChangedFcn = ...
                @(source, event) app.onExportFormatChanged(source, event);
            app.ExportFormatDropDown.Layout.Row = 2;
            app.ExportFormatDropDown.Layout.Column = 1;

            app.ExportWidthLabel = app.exportLabel('Width', 2);
            app.ExportWidthField = uieditfield(app.ExportGrid, 'numeric');
            app.ExportWidthField.Limits = [0.01 Inf];
            app.ExportWidthField.Value = 1600;
            app.ExportWidthField.Layout.Row = 2;
            app.ExportWidthField.Layout.Column = 2;

            app.ExportHeightLabel = app.exportLabel('Height', 3);
            app.ExportHeightField = uieditfield(app.ExportGrid, 'numeric');
            app.ExportHeightField.Limits = [0.01 Inf];
            app.ExportHeightField.Value = 1200;
            app.ExportHeightField.Layout.Row = 2;
            app.ExportHeightField.Layout.Column = 3;

            app.ExportUnitsLabel = app.exportLabel('Units', 1);
            app.ExportUnitsLabel.Layout.Row = 3;
            app.ExportUnitsDropDown = uidropdown(app.ExportGrid);
            app.ExportUnitsDropDown.Items = ...
                {'Pixels', 'Millimeters', 'Centimeters', 'Inches', 'Points'};
            app.ExportUnitsDropDown.ItemsData = ...
                {'pixels', 'millimeters', 'centimeters', 'inches', 'points'};
            app.ExportUnitsDropDown.Value = 'pixels';
            app.ExportUnitsDropDown.Layout.Row = 4;
            app.ExportUnitsDropDown.Layout.Column = 1;

            app.ExportResolutionLabel = uilabel(app.ExportGrid, 'Text', 'DPI');
            app.ExportResolutionLabel.Layout.Row = 3;
            app.ExportResolutionLabel.Layout.Column = 2;
            app.ExportResolutionField = uieditfield(app.ExportGrid, 'numeric');
            app.ExportResolutionField.Limits = [1 Inf];
            app.ExportResolutionField.RoundFractionalValues = 'on';
            app.ExportResolutionField.Value = 300;
            app.ExportResolutionField.Layout.Row = 4;
            app.ExportResolutionField.Layout.Column = 2;

            app.ExportTransparencyCheckBox = uicheckbox(app.ExportGrid, ...
                'Text', 'Transparent', 'Value', false);
            app.ExportTransparencyCheckBox.ValueChangedFcn = ...
                @(source, event) app.onTransparencyChanged(source, event);
            app.ExportTransparencyCheckBox.Layout.Row = 4;
            app.ExportTransparencyCheckBox.Layout.Column = 3;
            app.ExportTransparencyCheckBox.FontSize = 11;
            app.ExportTransparencyCheckBox.Tooltip = ...
                'Export with a transparent background when supported.';

            app.ExportButton = uibutton(app.ExportGrid, 'push');
            app.ExportButton.Text = 'Export...';
            app.ExportButton.FontWeight = 'bold';
            app.ExportButton.Tooltip = ...
                'Export the current modern-renderer figure and provenance sidecar.';
            app.ExportButton.ButtonPushedFcn = @(source, event) app.onExport(source, event);
            app.ExportButton.Layout.Row = 5;
            app.ExportButton.Layout.Column = [1 3];
        end

        function label = exportLabel(app, textValue, column)
            label = uilabel(app.ExportGrid, 'Text', textValue, 'FontWeight', 'bold');
            label.Layout.Row = 1;
            label.Layout.Column = column;
        end

        function createTipPanel(app)
            app.TipPanel = uipanel(app.BottomGrid, 'Title', 'Tip');
            app.TipPanel.Layout.Column = 3;
            tipGrid = uigridlayout(app.TipPanel, [1 1]);
            tipGrid.Padding = [10 8 10 8];
            app.TipLabel = uilabel(tipGrid);
            app.TipLabel.Text = 'Select input files or open a Scene JSON or ZIP.';
            app.TipLabel.WordWrap = 'on';
            app.TipLabel.HorizontalAlignment = 'center';
        end

        function createResourceBar(app)
            app.ResourcePanel = uipanel(app.MainGrid, 'BorderType', 'none');
            app.ResourcePanel.Layout.Row = 3;
            app.ResourceGrid = uigridlayout(app.ResourcePanel, [1 6]);
            app.ResourceGrid.ColumnWidth = {'1x', '1x', '1x', '1x', 18, 90};
            app.ResourceGrid.Padding = [6 0 6 0];
            app.ResourceGrid.ColumnSpacing = 8;
            app.CpuResourceLabel = uilabel(app.ResourceGrid, 'Text', 'CPU: Detecting');
            app.CpuResourceLabel.Layout.Column = 1;
            app.MemoryResourceLabel = uilabel(app.ResourceGrid, 'Text', 'RAM: Detecting');
            app.MemoryResourceLabel.Layout.Column = 2;
            app.GpuResourceLabel = uilabel(app.ResourceGrid, 'Text', 'GPU: Detecting');
            app.GpuResourceLabel.Layout.Column = 3;
            app.NetworkResourceLabel = uilabel(app.ResourceGrid, 'Text', 'Network: Idle');
            app.NetworkResourceLabel.Layout.Column = 4;
            app.StatusLamp = uilamp(app.ResourceGrid);
            app.StatusLamp.Layout.Column = 5;
            app.StatusLabel = uilabel(app.ResourceGrid, 'Text', 'Ready');
            app.StatusLabel.Layout.Column = 6;
        end

        function createClassicComponents(app, titleText, useStartupImage)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Name = char(titleText);
            app.UIFigure.Position = ...
                brainnet.render.internal.screenAwarePosition( ...
                    app.ProductInfo.window_reference_size, ...
                    AdaptiveScale=true, ...
                    MonitorFraction=app.ProductInfo.window_monitor_fraction, ...
                    MaximumScale=1.35, ...
                    AnchorPoint=brainnet.render.internal.matlabDesktopAnchor(), ...
                    MinimumSize=app.ProductInfo.minimum_window_size);
            if isprop(app.UIFigure, 'WindowDropFcn')
                app.UIFigure.WindowDropFcn = @(source, event) app.onDrop(source, event);
                app.DropSupported = true;
            end

            app.createViewport();
            app.MainGrid = uigridlayout(app.RootPanel, [6 4]);
            app.MainGrid.RowHeight = {72, 42, '1x', 108, 86, 36};
            app.MainGrid.ColumnWidth = {145, '1x', 210, 175};
            app.MainGrid.Padding = [16 14 16 14];
            app.MainGrid.RowSpacing = 10;
            app.MainGrid.ColumnSpacing = 10;

            app.HeaderPanel = uipanel(app.MainGrid, 'BorderType', 'none');
            app.HeaderPanel.Layout.Row = 1;
            app.HeaderPanel.Layout.Column = [1 4];
            app.HeaderGrid = uigridlayout(app.HeaderPanel, [2 4]);
            app.HeaderGrid.RowHeight = {38, 26};
            app.HeaderGrid.ColumnWidth = {0, '1x', 82, 82};
            app.HeaderGrid.Padding = [0 0 0 0];
            app.HeaderGrid.ColumnSpacing = 8;

            if useStartupImage && isfile(app.ProductInfo.startup_image_path)
                app.HeaderGrid.ColumnWidth{1} = 112;
                app.BrandImage = uiimage(app.HeaderGrid);
                app.BrandImage.ImageSource = app.ProductInfo.startup_image_path;
                app.BrandImage.ScaleMethod = 'fit';
                app.BrandImage.Tooltip = ...
                    'BrainNet Viewer 2.0 network visualization identity.';
                app.BrandImage.Layout.Row = [1 2];
                app.BrandImage.Layout.Column = 1;
                app.StartupImageLoaded = true;
            end

            app.TitleLabel = uilabel(app.HeaderGrid);
            app.TitleLabel.Text = 'BrainNet Viewer 2.0';
            app.TitleLabel.FontSize = 23;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Layout.Row = 1;
            app.TitleLabel.Layout.Column = 2;

            app.WelcomeLabel = uilabel(app.HeaderGrid);
            app.WelcomeLabel.Text = app.ProductInfo.startup_message;
            app.WelcomeLabel.FontColor = [0.25 0.32 0.40];
            app.WelcomeLabel.WordWrap = 'on';
            app.WelcomeLabel.Layout.Row = 2;
            app.WelcomeLabel.Layout.Column = 2;

            app.HelpButton = uibutton(app.HeaderGrid, 'push');
            app.HelpButton.Text = 'Help';
            app.HelpButton.Tooltip = 'Open local manuals, illustrated tutorials and the unified English PDF for MATLAB and Python Desktop.';
            app.HelpButton.ButtonPushedFcn = @(source, event) app.onHelp(source, event);
            app.HelpButton.Layout.Row = [1 2];
            app.HelpButton.Layout.Column = 3;

            app.AboutButton = uibutton(app.HeaderGrid, 'push');
            app.AboutButton.Text = 'About';
            app.AboutButton.Tooltip = 'Show version, authorship, citation, and license information.';
            app.AboutButton.ButtonPushedFcn = @(source, event) app.onAbout(source, event);
            app.AboutButton.Layout.Row = [1 2];
            app.AboutButton.Layout.Column = 4;

            app.RoleDropDown = uidropdown(app.MainGrid);
            app.RoleDropDown.Items = {'Surface', 'Nodes', 'Edges', 'Surface Map', 'NIfTI Volume'};
            app.RoleDropDown.ItemsData = {'surface', 'node', 'edge', 'surface_map', 'volume'};
            app.RoleDropDown.Value = 'surface';
            app.RoleDropDown.Layout.Row = 2;
            app.RoleDropDown.Layout.Column = 1;

            app.SelectInputButton = uibutton(app.MainGrid, 'push');
            app.SelectInputButton.Text = 'Select Input File';
            app.SelectInputButton.ButtonPushedFcn = @(source, event) app.onSelectInput(source, event);
            app.SelectInputButton.Layout.Row = 2;
            app.SelectInputButton.Layout.Column = 2;

            app.OpenSceneButton = uibutton(app.MainGrid, 'push');
            app.OpenSceneButton.Text = 'Open Scene';
            app.OpenSceneButton.ButtonPushedFcn = @(source, event) app.onOpenScene(source, event);
            app.OpenSceneButton.Layout.Row = 2;
            app.OpenSceneButton.Layout.Column = 3;

            app.LoadButton = uibutton(app.MainGrid, 'push');
            app.LoadButton.Text = 'Validate and Load';
            app.LoadButton.ButtonPushedFcn = @(source, event) app.onLoad(source, event);
            app.LoadButton.Layout.Row = 2;
            app.LoadButton.Layout.Column = 4;

            app.InputTable = uitable(app.MainGrid);
            app.InputTable.ColumnName = {'Type', 'Relative Path', 'Status'};
            app.InputTable.ColumnEditable = [false false false];
            app.InputTable.ColumnWidth = {110, 'auto', 90};
            app.InputTable.RowName = {};
            app.InputTable.Layout.Row = 3;
            app.InputTable.Layout.Column = [1 4];

            app.SummaryArea = uitextarea(app.MainGrid);
            app.SummaryArea.Editable = 'off';
            app.SummaryArea.Layout.Row = 4;
            app.SummaryArea.Layout.Column = [1 4];

            app.ExportPanel = uipanel(app.MainGrid);
            app.ExportPanel.Title = 'Export Settings';
            app.ExportPanel.Layout.Row = 5;
            app.ExportPanel.Layout.Column = [1 4];
            app.ExportGrid = uigridlayout(app.ExportPanel, [2 8]);
            app.ExportGrid.RowHeight = {18, 28};
            app.ExportGrid.ColumnWidth = {70, 75, 75, 75, 95, 105, 105, '1x'};
            app.ExportGrid.Padding = [6 4 6 4];
            app.ExportGrid.RowSpacing = 3;
            app.ExportGrid.ColumnSpacing = 6;

            app.ExportFormatLabel = uilabel(app.ExportGrid, 'Text', 'Format');
            app.ExportFormatLabel.Layout.Row = 1;
            app.ExportFormatLabel.Layout.Column = 1;
            app.ExportFormatDropDown = uidropdown(app.ExportGrid);
            app.ExportFormatDropDown.Items = {'PNG', 'JPEG', 'TIFF', 'BMP', 'PDF', 'SVG'};
            app.ExportFormatDropDown.ItemsData = {'png', 'jpg', 'tif', 'bmp', 'pdf', 'svg'};
            app.ExportFormatDropDown.Value = 'png';
            app.ExportFormatDropDown.ValueChangedFcn = ...
                @(source, event) app.onExportFormatChanged(source, event);
            app.ExportFormatDropDown.Layout.Row = 2;
            app.ExportFormatDropDown.Layout.Column = 1;

            app.ExportResolutionLabel = uilabel(app.ExportGrid, 'Text', 'DPI');
            app.ExportResolutionLabel.Layout.Row = 1;
            app.ExportResolutionLabel.Layout.Column = 2;
            app.ExportResolutionField = uieditfield(app.ExportGrid, 'numeric');
            app.ExportResolutionField.Limits = [1 Inf];
            app.ExportResolutionField.RoundFractionalValues = 'on';
            app.ExportResolutionField.Value = 300;
            app.ExportResolutionField.Layout.Row = 2;
            app.ExportResolutionField.Layout.Column = 2;

            app.ExportWidthLabel = uilabel(app.ExportGrid, 'Text', 'Width');
            app.ExportWidthLabel.Layout.Row = 1;
            app.ExportWidthLabel.Layout.Column = 3;
            app.ExportWidthField = uieditfield(app.ExportGrid, 'numeric');
            app.ExportWidthField.Limits = [0.01 Inf];
            app.ExportWidthField.Value = 1600;
            app.ExportWidthField.Layout.Row = 2;
            app.ExportWidthField.Layout.Column = 3;

            app.ExportHeightLabel = uilabel(app.ExportGrid, 'Text', 'Height');
            app.ExportHeightLabel.Layout.Row = 1;
            app.ExportHeightLabel.Layout.Column = 4;
            app.ExportHeightField = uieditfield(app.ExportGrid, 'numeric');
            app.ExportHeightField.Limits = [0.01 Inf];
            app.ExportHeightField.Value = 1200;
            app.ExportHeightField.Layout.Row = 2;
            app.ExportHeightField.Layout.Column = 4;

            app.ExportUnitsLabel = uilabel(app.ExportGrid, 'Text', 'Units');
            app.ExportUnitsLabel.Layout.Row = 1;
            app.ExportUnitsLabel.Layout.Column = 5;
            app.ExportUnitsDropDown = uidropdown(app.ExportGrid);
            app.ExportUnitsDropDown.Items = {'Pixels', 'Inches', 'Centimeters', 'Points'};
            app.ExportUnitsDropDown.ItemsData = {'pixels', 'inches', 'centimeters', 'points'};
            app.ExportUnitsDropDown.Value = 'pixels';
            app.ExportUnitsDropDown.Layout.Row = 2;
            app.ExportUnitsDropDown.Layout.Column = 5;

            app.ExportContentLabel = uilabel(app.ExportGrid, 'Text', 'Content');
            app.ExportContentLabel.Layout.Row = 1;
            app.ExportContentLabel.Layout.Column = 6;
            app.ExportContentDropDown = uidropdown(app.ExportGrid);
            app.ExportContentDropDown.Items = {'Automatic', 'Image'};
            app.ExportContentDropDown.ItemsData = {'auto', 'image'};
            app.ExportContentDropDown.Value = 'auto';
            app.ExportContentDropDown.Layout.Row = 2;
            app.ExportContentDropDown.Layout.Column = 6;

            app.ExportBackgroundLabel = uilabel(app.ExportGrid, 'Text', 'Background');
            app.ExportBackgroundLabel.Layout.Row = 1;
            app.ExportBackgroundLabel.Layout.Column = 7;
            app.ExportBackgroundDropDown = uidropdown(app.ExportGrid);
            app.ExportBackgroundDropDown.Items = ...
                {'White', 'Black', 'Transparent (Experimental)'};
            app.ExportBackgroundDropDown.ItemsData = {'white', 'black', 'none'};
            app.ExportBackgroundDropDown.Value = 'white';
            app.ExportBackgroundDropDown.Layout.Row = 2;
            app.ExportBackgroundDropDown.Layout.Column = 7;

            app.ExportButton = uibutton(app.ExportGrid, 'push');
            app.ExportButton.Text = 'Export Figure';
            app.ExportButton.Tooltip = ...
                'Export the current modern-renderer figure and provenance sidecar.';
            app.ExportButton.ButtonPushedFcn = @(source, event) app.onExport(source, event);
            app.ExportButton.Layout.Row = [1 2];
            app.ExportButton.Layout.Column = 8;

            app.StatusLamp = uilamp(app.MainGrid);
            app.StatusLamp.Layout.Row = 6;
            app.StatusLamp.Layout.Column = 1;

            app.StatusLabel = uilabel(app.MainGrid);
            app.StatusLabel.Text = 'No scene selected.';
            app.StatusLabel.Layout.Row = 6;
            app.StatusLabel.Layout.Column = 2;

            app.RendererDropDown = uidropdown(app.MainGrid);
            app.RendererDropDown.Items = {'Modern Batch Renderer'};
            app.RendererDropDown.ItemsData = {'batch'};
            app.RendererDropDown.Value = 'batch';
            app.RendererDropDown.Tooltip = 'Modern Batch Renderer is the supported interactive renderer.';
            app.RendererDropDown.Layout.Row = 6;
            app.RendererDropDown.Layout.Column = 3;

            app.RenderButton = uibutton(app.MainGrid, 'push');
            app.RenderButton.Text = 'Render Scene';
            app.RenderButton.ButtonPushedFcn = @(source, event) app.onRender(source, event);
            app.RenderButton.Layout.Row = 6;
            app.RenderButton.Layout.Column = 4;

            app.UIFigure.SizeChangedFcn = ...
                @(source, event) app.onFigureSizeChanged(source, event);
            app.RootPanel.SizeChangedFcn = @(~,~) app.applyResponsiveLayout();
            app.enforceMinimumWindowSize();
        end

        function scene = buildDraftScene(app)
            if isempty(app.DraftInputs)
                error('BNV:App:NoInputs', 'Select at least one input file.');
            end
            bits = struct('surface', 1, 'node', 2, 'edge', 4, 'surface_map', 8, 'volume', 8);
            loadFile = 0;
            mapMode = 0;
            for index = 1:numel(app.DraftInputs)
                role = app.DraftInputs{index}.Role;
                loadFile = loadFile + bits.(char(role));
                if role == "surface_map"
                    mapMode = 1;
                elseif role == "volume"
                    mapMode = 2;
                end
            end
            coordinateSpace = "mixed-or-unverified";
            redistributionStatus = "user-provided-not-for-redistribution";
            inputStatuses = string(cellfun(@(item) char(item.RedistributionStatus), ...
                app.DraftInputs,'UniformOutput',false));
            if all(inputStatuses == ...
                    "project-owner-confirmed-redistributable-with-provider-credit")
                redistributionStatus = inputStatuses(1);
                inputSpaces = string(cellfun(@(item) char(item.CoordinateSpace), ...
                    app.DraftInputs,'UniformOutput',false));
                if all(inputSpaces == inputSpaces(1))
                    coordinateSpace = inputSpaces(1);
                end
            end
            scene = brainnet.core.Scene("APP_SCENE", "Interactive scene", ...
                loadFile, mapMode, app.DraftInputs, Options=app.DraftOptions, ...
                CoordinateSpace=coordinateSpace, ...
                RedistributionStatus=redistributionStatus, ...
                Metadata=struct('created_by', 'brainnet.app.BrainNetApp'));
        end

        function applySurfaceOpacityDefaultForDraft(app)
            if app.SurfaceOpacityIsExplicit || isempty(app.DraftInputs)
                return;
            end
            roles = string(cellfun(@(item) char(item.Role), app.DraftInputs, ...
                'UniformOutput', false));
            surfaceOnly = numel(roles) == 1 && roles(1) == "surface";
            surfaceMapped = numel(roles) == 2 && roles(1) ~= roles(2) && ...
                any(roles == "surface") && any(ismember(roles, ["surface_map", "volume"]));
            if surfaceOnly || surfaceMapped
                opacity = 1;
            else
                opacity = 0.3;
            end
            app.DraftOptions = app.DraftOptions.withPatch( ...
                struct('surface', struct('opacity', opacity)));
        end

        function [relative, effectivePath, metadata, localPath] = makeRelative(app, pathValue, options)
            arguments
                app
                pathValue (1, 1) string
                options.ExternalImportApproved (1, 1) logical = false
            end
            % ExternalImportApproved remains accepted for older scripts; no copy is made.
            if ~isfile(pathValue)
                error('BNV:App:InputNotFound','Selected input does not exist: %s',pathValue);
            end
            effectivePath=string(char(java.io.File(char(pathValue)).getCanonicalPath()));
            prefix=app.Session.RootPath+string(filesep);
            if ispc, inside=startsWith(lower(effectivePath),lower(prefix));
            else, inside=startsWith(effectivePath,prefix); end
            metadata=struct();localPath="";
            if inside
                relative=replace(extractAfter(effectivePath,strlength(prefix)),"\","/");
            else
                [~,name,ext]=fileparts(effectivePath);
                relative=string(name)+string(ext);localPath=effectivePath;
            end
        end

        function role = classifyPath(~, pathValue)
            path = lower(pathValue);
            if endsWith(path, ".gii") || endsWith(path, ".gii.gz") || ...
                    any(endsWith(path, [".nv", ".pial", ".mesh", ".g", ".obj", ".mz3", ".mz3.gz"]))
                role = "surface";
            elseif endsWith(path, ".node")
                role = "node";
            elseif endsWith(path, ".edge")
                role = "edge";
            elseif endsWith(path, ".txt")
                role = "surface_map";
            elseif any(endsWith(path, [".nii", ".nii.gz", ".hdr", ".hdr.gz", ".img", ".img.gz"]))
                role = "volume";
            else
                error('BNV:App:UnsupportedInputFormat', 'Dropped file format is not supported: %s', pathValue);
            end
        end

        function validateRoleExtension(app, role, pathValue)
            classified = app.classifyPath(pathValue);
            if classified ~= role
                error('BNV:App:InputRoleExtensionMismatch', ...
                    'File %s is classified as %s, not %s.', pathValue, classified, role);
            end
        end

        function finishMovieExport(app)
            app.MovieExportInProgress=false;
        end

        function refreshView(app,options)
            arguments
                app
                options.PreservePendingSettings (1,1) logical = false
            end
            roles = strings(numel(app.DraftInputs), 1);
            loadedRoles = string(fieldnames(app.Session.Data));
            roleKeys = ["surface", "node", "edge", "surface_map", "volume"];
            for role = roleKeys
                key = char(role);
                app.RoleDetailLabels.(key).Text = 'Not selected';
                app.RoleDetailLabels.(key).Tooltip = 'No file selected.';
                app.RoleActionButtons.(key).Text = 'Add';
            end
            app.RoleDetailLabels.edge.Text = 'Requires Nodes';
            if strlength(app.SceneFilePath) > 0
                [~, sceneName, sceneExtension] = fileparts(app.SceneFilePath);
                app.RoleDetailLabels.scene.Text = char(string(sceneName) + string(sceneExtension));
                app.RoleDetailLabels.scene.Tooltip = char(app.SceneFilePath);
            else
                app.RoleDetailLabels.scene.Text = 'Open or drop JSON';
                app.RoleDetailLabels.scene.Tooltip = 'Open Scene JSON references or a portable Scene ZIP.';
            end
            for index = 1:numel(app.DraftInputs)
                input = app.DraftInputs{index};
                roles(index) = roleLabel(input.Role);
                [~, fileName, extension] = fileparts(input.RelativePath);
                key = char(input.Role);
                detail = string(fileName) + string(extension);
                if any(loadedRoles == input.Role)
                    detail = detail + " · " + app.inputDetail(input.Role);
                end
                app.RoleDetailLabels.(key).Text = char(detail);
                app.RoleDetailLabels.(key).Tooltip = char(input.RelativePath);
                app.RoleActionButtons.(key).Text = 'Clear';
            end
            app.StatusLabel.Text = char(statusSummary(app.Session.Status, app.Session.Message));
            app.StatusLabel.Tooltip = char(app.Session.Message);
            switch app.Session.Status
                case {"loaded", "rendered"}
                    app.StatusLamp.Color = [0.20 0.68 0.34];
                case "loading"
                    app.StatusLamp.Color = [0.95 0.65 0.15];
                case "error"
                    app.StatusLamp.Color = [0.85 0.25 0.25];
                otherwise
                    app.StatusLamp.Color = [0.55 0.58 0.62];
            end
            hasScene = ~isempty(app.Session.Scene);
            app.LoadButton.Enable = onOff(hasScene);
            app.SaveSceneButton.Enable = onOff(hasScene);
            app.RenderButton.Enable = onOff(hasScene && ~app.RenderingInProgress);
            app.PopOutButton.Enable = onOff(hasScene);
            hasBatchFigure = ~isempty(app.BatchRenderer.ActiveTarget) && ...
                isgraphics(app.BatchRenderer.ActiveTarget);
            hasLegacyFigure = ~isempty(app.LegacyAdapter.ActiveFigure) && ...
                isgraphics(app.LegacyAdapter.ActiveFigure, 'figure');
            hasPopout=~isempty(app.PopoutRenderer.ActiveTarget)&&isgraphics(app.PopoutRenderer.ActiveTarget);
            app.ClearFigureButton.Enable=onOff(hasBatchFigure||hasLegacyFigure||hasPopout);
            canInteract = app.Session.Status == "rendered" && ...
                (hasBatchFigure || hasLegacyFigure);
            viewControls = {app.ResetViewButton, app.RotateButton, app.PanButton, ...
                app.ZoomButton, app.FitButton, app.ViewDropDown};
            for index = 1:numel(viewControls)
                viewControls{index}.Enable = onOff(canInteract);
            end
            app.InspectButton.Enable=onOff(canInteract && hasBatchFigure);
            app.DemoButton.Enable=onOff(canInteract && ~app.MovieExportInProgress && ~app.LiveDemo.IsRunning);
            app.StopDemoButton.Enable=onOff(app.LiveDemo.IsRunning);
            if hasScene && app.Session.Scene.Options.Layout > 1
                app.ViewDropDown.Enable = 'off';
                app.ViewDropDown.Value = 'layout';
                app.ViewDropDown.Tooltip = 'Multi-view layouts retain their own directions. Use Rotate to adjust a pane.';
            else
                app.ViewDropDown.Tooltip = 'Single-view camera override. Reset restores the configured layout view.';
            end
            canExport = app.Session.Status == "rendered" && ...
                strcmp(app.LastRenderInfo.backend, 'batch') && ...
                ~isempty(app.LastPreparedScene) && ...
                ~isempty(app.BatchRenderer.ActiveTarget) && ...
                isgraphics(app.BatchRenderer.ActiveTarget) && ~app.LiveDemo.IsRunning;
            app.ExportButton.Enable = onOff(canExport);
            canSaveBoundary=false;
            if canExport
                surfaceSettings=app.Session.Scene.Options.section('surface');
                canSaveBoundary=~strcmp(surfaceSettings.boundary_mode,'none') && ...
                    (~isempty(app.LastPreparedScene.SurfaceValues)||strcmp(surfaceSettings.boundary_mode,'custom')) && ...
                    app.LastPreparedScene.VertexCount>0;
            end
            app.SaveBoundaryToolButton.Enable=onOff(canSaveBoundary);
            app.ExportAnimationToolButton.Enable=onOff(canExport);
            summary = app.Session.summary();
            if app.DropSupported
                app.DropHintLabel.Text = 'Drop supported files here or use Add Files.';
            else
                app.DropHintLabel.Text = 'Use Add Files or open a Scene JSON or ZIP.';
            end
            [app.SceneSummaryText, app.SceneSummaryRows] = ...
                app.sceneSummaryLines(summary, roles);
            app.refreshSceneSummaryHtml();
            if ~options.PreservePendingSettings && ~isempty(app.SettingsAccordion) && isvalid(app.SettingsAccordion)
                app.SettingsAccordion.replaceSettings(app.DraftOptions.Settings);
            end
            if ~hasBatchFigure && ~hasLegacyFigure
                app.showRenderCanvas(false);
            end
            if isempty(fieldnames(app.ResourceSnapshot))
                app.ResourceSnapshot = systemResourceSnapshot();
            end
            app.refreshResourceLabels();
        end

        function value = inputDetail(app, role)
            value = "Loaded";
            try
                data = app.Session.Data.(char(role));
                switch role
                    case "surface"
                        value = sprintf('%d vertices | %d faces', ...
                            data.VertexCount, data.FaceCount);
                    case "node"
                        value = sprintf('%d nodes', data.Count);
                    case "edge"
                        value = sprintf('%d x %d matrix', data.Dimension, data.Dimension);
                    case "volume"
                        value = sprintf('%d x %d x %d volume', data.Dimensions);
                    case "surface_map"
                        value = sprintf('%d values', numel(data));
                end
            catch
            end
        end

        function [lines, rows] = sceneSummaryLines(app, summary, roles)
            inputCount = numel(app.DraftInputs);
            hasSceneFile = strlength(app.SceneFilePath) > 0;
            hasVolume=any(cellfun(@(item) item.Role=="volume",app.DraftInputs));
            volumeSettings=app.DraftOptions.section('volume');
            showVolumeRange=hasVolume && volumeSettings.display && ...
                string(volumeSettings.type)=="surface-map";
            lineCount = 2 + inputCount + double(hasSceneFile) + ...
                double(inputCount == 0) + double(showVolumeRange);
            lines = cell(lineCount, 1);
            rows = repmat(struct('title', '', 'value', ''), lineCount, 1);
            lineIndex = 0;
            if showVolumeRange
                lineIndex=lineIndex+1;
                rows(lineIndex).title='Volume range:';
                bounds={volumeSettings.positive_minimum,volumeSettings.positive_maximum, ...
                    volumeSettings.negative_minimum,volumeSettings.negative_maximum};
                if all(cellfun(@isempty,bounds))
                    rows(lineIndex).value='Auto from mapped values on each render.';
                else
                    rows(lineIndex).value=['Manual bounds are retained across files. ' ...
                        'Use Auto Ranges, then Apply.'];
                end
                lines{lineIndex}=[rows(lineIndex).title ' ' rows(lineIndex).value];
            end
            lineIndex=lineIndex+1;
            rows(lineIndex).title = 'Scene:';
            rows(lineIndex).value = sprintf('%s | %d file(s)', ...
                summary.scene_name, summary.input_count);
            lines{lineIndex} = [rows(lineIndex).title ' ' rows(lineIndex).value];
            if hasSceneFile
                lineIndex = lineIndex + 1;
                rows(lineIndex).title = 'Scene File:';
                if app.DocumentationCaptureMode
                    [~, sceneName, sceneExtension] = fileparts(app.SceneFilePath);
                    rows(lineIndex).value = char("[selected folder]/" + sceneName + sceneExtension);
                else
                    rows(lineIndex).value = char(app.SceneFilePath);
                end
                lines{lineIndex} = [rows(lineIndex).title ' ' rows(lineIndex).value];
            end
            for index = 1:inputCount
                input = app.DraftInputs{index};
                absolutePath = input.resolve(app.Session.RootPath);
                lineIndex = lineIndex + 1;
                rows(lineIndex).title = char(roles(index) + ":");
                if app.DocumentationCaptureMode
                    displayPath = char("[data root]/" + string(input.RelativePath));
                else
                    displayPath = absolutePath;
                end
                rows(lineIndex).value = sprintf('%s | %s', displayPath, ...
                    app.inputScaleSummary(input));
                lines{lineIndex} = [rows(lineIndex).title ' ' rows(lineIndex).value];
            end
            if inputCount == 0
                lineIndex = lineIndex + 1;
                rows(lineIndex).title = 'Data:';
                rows(lineIndex).value = 'No files selected.';
                lines{lineIndex} = [rows(lineIndex).title ' ' rows(lineIndex).value];
            end
            lineIndex = lineIndex + 1;
            rows(lineIndex).title = 'Export:';
            if app.DocumentationCaptureMode && ...
                    isfield(app.LastExportInfo,'status') && ...
                    strcmp(app.LastExportInfo.status,'pass')
                [~, exportName, exportExtension] = fileparts(app.LastExportInfo.output_path);
                rows(lineIndex).value = char("[selected folder]/" + exportName + exportExtension);
            else
                rows(lineIndex).value = exportSummaryValue(app.LastExportInfo);
            end
            lines{lineIndex} = [rows(lineIndex).title ' ' rows(lineIndex).value];
        end

        function refreshSceneSummaryHtml(app)
            if isempty(app.SummaryArea) || ~isvalid(app.SummaryArea) || ...
                    ~isprop(app.SummaryArea, 'HTMLSource')
                return;
            end
            if app.Theme == "dark"
                background = '#18212c';
                foreground = '#ebf2fa';
                muted = '#c0ccda';
            else
                background = '#ffffff';
                foreground = '#16233a';
                muted = '#34435a';
            end
            fragments = strings(numel(app.SceneSummaryRows) + 2, 1);
            fragments(1) = "<html><head><style>html,body{margin:0;padding:0;" + ...
                "width:100%;height:100%;overflow:hidden;" + ...
                "background:" + background + ";color:" + foreground + ...
                ";font-family:'Segoe UI',Arial,sans-serif;font-size:12px;}" + ...
                ".summary{width:100%;height:100%;box-sizing:border-box;" + ...
                "overflow-y:scroll;overflow-x:hidden;border:1px solid #8b8b8b;" + ...
                "padding:5px 7px;display:grid;align-content:start;" + ...
                "grid-template-columns:max-content minmax(0,1fr);" + ...
                "column-gap:5px;row-gap:5px;scrollbar-gutter:stable;}" + ...
                ".title{font-weight:700;white-space:nowrap;}" + ...
                ".value{color:" + muted + ";overflow-wrap:anywhere;" + ...
                "word-break:break-word;}</style></head><body><div class='summary'>";
            for index = 1:numel(app.SceneSummaryRows)
                fragments(index + 1) = "<div class='title'>" + ...
                    htmlEscape(app.SceneSummaryRows(index).title) + ...
                    "</div><div class='value'>" + ...
                    htmlEscape(app.SceneSummaryRows(index).value) + "</div>";
            end
            fragments(end) = "</div></body></html>";
            app.SummaryArea.HTMLSource = char(join(fragments, ''));
        end

        function value = inputScaleSummary(app, input)
            details = strings(2, 1);
            detailCount = 0;
            if isfield(app.Session.Data, char(input.Role))
                data = app.Session.Data.(char(input.Role));
                switch input.Role
                    case "surface"
                        detailCount = detailCount + 1;
                        details(detailCount) = sprintf('%s vertices, %s faces', ...
                            groupedInteger(data.VertexCount), ...
                            groupedInteger(data.FaceCount));
                    case "node"
                        detailCount = detailCount + 1;
                        details(detailCount) = sprintf('%s nodes', ...
                            groupedInteger(data.Count));
                    case "edge"
                        detailCount = detailCount + 1;
                        details(detailCount) = sprintf('%s x %s matrix, %s nonzero', ...
                            groupedInteger(data.Dimension), ...
                            groupedInteger(data.Dimension), ...
                            groupedInteger(nnz(data.Matrix)));
                    case "volume"
                        dimensions = join(string(data.Dimensions), ' x ');
                        detailCount = detailCount + 1;
                        details(detailCount) = dimensions + " voxels";
                    case "surface_map"
                        detailCount = detailCount + 1;
                        details(detailCount) = sprintf('%s values', ...
                            groupedInteger(numel(data)));
                end
            end
            absolutePath = input.resolve(app.Session.RootPath);
            fileInfo = dir(absolutePath);
            if ~isempty(fileInfo)
                detailCount = detailCount + 1;
                details(detailCount) = string(formatFileSize(fileInfo(1).bytes));
            end
            if detailCount == 0
                value = 'Not loaded';
            else
                value = char(join(details(1:detailCount), ' | '));
            end
            if input.Role == "surface" && endsWith(lower(input.RelativePath), ".pial")
                value = [value ' | FreeSurfer coordinates as stored; verify registration'];
            elseif input.Role == "surface" && endsWith(lower(input.RelativePath), ".mesh")
                value = [value ' | BrainVISA coordinates as stored; no legacy XYZ inversion; verify registration'];
            elseif input.Role == "surface" && endsWith(lower(input.RelativePath), ".g")
                value = [value ' | BYU coordinates as stored; all parts; verify registration and units'];
            elseif input.Role == "surface" && endsWith(lower(input.RelativePath), ".obj")
                value = [value ' | MNI/BIC coordinates as stored; appearance from settings; verify registration and units'];
            elseif input.Role == "surface" && any(endsWith(lower(input.RelativePath), [".mz3", ".mz3.gz"]))
                value = [value ' | MZ3 coordinates as stored; appearance from settings; verify registration and units'];
            end
        end

        function value = exportSettings(app)
            if string(app.ExportUnitsDropDown.Value) == "pixels"
                sizeMode = 'pixels';
            else
                sizeMode = 'physical';
            end
            value = struct( ...
                'format', app.ExportFormatDropDown.Value, ...
                'resolution_dpi', app.ExportResolutionField.Value, ...
                'width', app.ExportWidthField.Value, ...
                'height', app.ExportHeightField.Value, ...
                'units', app.ExportUnitsDropDown.Value, ...
                'size_mode', sizeMode, ...
                'content_type', char(app.ExportContentType), ...
                'background_color', char(app.selectedExportBackground()), ...
                'transparent', logical(app.ExportTransparencyCheckBox.Value));
        end

        function value = selectedExportBackground(app)
            if app.ExportTransparencyCheckBox.Value
                value = "none";
            else
                value = app.ExportBackgroundPreference;
            end
        end

        function updateContentChoices(app, format)
            if any(format == ["png", "jpg", "tif", "bmp"])
                if app.ExportContentType == "vector"
                    app.ExportContentType = "auto";
                end
            end
        end

        function onSelectInput(app, ~, ~)
            filters = {'*.nv;*.pial;*.mesh;*.g;*.obj;*.mz3;*.mz3.gz;*.gii;*.gii.gz;*.node;*.edge;*.txt;*.nii;*.nii.gz;*.hdr;*.hdr.gz;*.img;*.img.gz', ...
                'Supported BrainNet data files'; '*.*', 'All files'};
            [name, folder] = app.openFileDialog(filters, 'Add BrainNet Data', ...
                char(app.Session.RootPath), 'MultiSelect', 'on');
            if isequal(name, 0)
                return;
            end
            names = string(name);
            for item = names(:).'
                app.addSelectedInput("auto", string(fullfile(folder, item)));
            end
        end

        function onRoleAction(app, role)
            if role == "scene"
                app.onOpenScene([], []);
                return;
            end
            if role == "fiber"
                return;
            end
            selectedRoles = string(cellfun(@(item) char(item.Role), ...
                app.DraftInputs, 'UniformOutput', false));
            if any(selectedRoles == role)
                app.clearInputRole(role);
                return;
            end
            startFolder = brainnet.app.inputStartFolder(app.Session.RootPath, role);
            [name, folder] = app.openFileDialog(roleFilters(role), ...
                ['Select ' char(roleLabel(role))], char(startFolder));
            if isequal(name, 0)
                return;
            end
            app.addSelectedInput(role, string(fullfile(folder, name)));
        end

        function [name, folder] = openFileDialog(app, varargin)
            wasVisible = isgraphics(app.UIFigure) && strcmp(app.UIFigure.Visible, 'on');
            restore = onCleanup(@() app.restoreAfterFileDialog(wasVisible));
            if ismac && verLessThan('matlab', '25.1') && wasVisible
                app.UIFigure.Visible = 'off';
                drawnow;
            end
            [name, folder] = uigetfile(varargin{:});
        end

        function [name, folder, filterIndex] = saveFileDialog(app, varargin)
            wasVisible = isgraphics(app.UIFigure) && strcmp(app.UIFigure.Visible, 'on');
            restore = onCleanup(@() app.restoreAfterFileDialog(wasVisible));
            if ismac && verLessThan('matlab', '25.1') && wasVisible
                app.UIFigure.Visible = 'off';
                drawnow;
            end
            [name, folder, filterIndex] = uiputfile(varargin{:});
        end

        function restoreAfterFileDialog(app, wasVisible)
            if ~wasVisible || ~isgraphics(app.UIFigure) || ...
                    ~(isunix || verLessThan('matlab','25.1'))
                return;
            end
            app.UIFigure.Visible = 'on';
            drawnow;
            figure(app.UIFigure);
            % Linux desktop choosers may activate MATLAB after returning.
            % Repeat once after their close event; never focus a closed app.
            if isunix && ~ismac, app.scheduleLegacyUiMainFocus(); end
        end

        function clearInputRole(app, role)
            selectedRoles = string(cellfun(@(item) char(item.Role), ...
                app.DraftInputs, 'UniformOutput', false));
            app.DraftInputs(selectedRoles == role) = [];
            if isempty(app.DraftInputs)
                % A subsequent fresh selection is eligible for contextual defaults.
                app.SurfaceOpacityIsExplicit = false;
            end
            app.applySurfaceOpacityDefaultForDraft();
            app.BatchRenderer.closeActiveFigure();
            app.PopoutRenderer.closeActiveFigure();
            app.LegacyAdapter.closeActiveFigure();
            app.LastPreparedScene = [];
            app.LastRenderInfo = struct('backend', '', 'status', 'not-rendered');
            app.LastExportInfo = struct('status', 'not-exported');
            if isempty(app.DraftInputs)
                app.Session.clearScene();
            else
                app.Session.setScene(app.buildDraftScene());
            end
            app.refreshView();
        end

        function onOpenScene(app, ~, ~)
            [name, folder] = app.openFileDialog({'*.json;*.zip', 'Scene JSON or ZIP (*.json, *.zip)'}, ...
                'Open BrainNet Scene', char(app.Session.RootPath));
            if isequal(name, 0)
                return;
            end
            app.runUiAction(@() app.importSceneFile(string(fullfile(folder, name))));
        end

        function onSaveScene(app)
            suggested = app.SceneFilePath;
            if suggested == "", suggested = fullfile(pwd, 'scene.json'); end
            if endsWith(lower(suggested),".zip")
                [folderPart,stem]=fileparts(suggested);suggested=fullfile(folderPart,stem+".json");
            end
            [name, folder, filterIndex] = app.saveFileDialog({'*.json','Scene references (local file paths) (*.json)'; ...
                '*.zip','Portable Scene with data (*.zip)'}, ...
                'Save BrainNet Scene', char(suggested));
            if isequal(name, 0), return; end
            if filterIndex==2 && ~endsWith(lower(string(name)),".zip")
                [~,stem]=fileparts(string(name));name=stem+".zip";
            end
            app.runUiAction(@() app.saveSceneFile( ...
                string(fullfile(folder, name)), Overwrite=true));
        end

        function onImportLegacyConfig(app)
            [name, folder] = app.openFileDialog({'*.mat', 'Legacy settings (*.mat)'}, ...
                'Import Trusted Legacy Settings', char(app.Session.RootPath));
            if isequal(name, 0), return; end
            app.runUiAction(@() app.importLegacyConfigFile(string(fullfile(folder, name))));
            if app.Session.Status ~= "error" && isfield(app.LastMigrationReport, 'input_fields')
                message = sprintf(['Legacy settings imported. Review %d fields before rendering. ' ...
                    'The migration report is included when you save the Scene.'], ...
                    numel(app.LastMigrationReport.fields_requiring_review));
                uialert(app.UIFigure, message, 'Settings Import', 'Icon', 'info');
            end
        end

        function onSavePreset(app)
            [name, folder] = app.saveFileDialog({'*.json', 'Visualization preset (*.json)'}, ...
                'Save Applied Visualization Settings', 'display.preset.json');
            if isequal(name, 0), return; end
            [~, presetName] = fileparts(name);
            app.runPresetAction(@() app.savePresetFile(string(fullfile(folder, name)), ...
                Name=string(presetName), Overwrite=true));
        end

        function onLoadPreset(app)
            [name, folder] = app.openFileDialog({'*.json', 'Visualization preset (*.json)'}, ...
                'Load Visualization Preset');
            if isequal(name, 0), return; end
            app.runPresetAction(@() app.confirmPreset(string(fullfile(folder, name))));
        end

        function confirmPreset(app, pathValue)
            [preset, report] = app.inspectPresetFile(pathValue);
            if ~isempty(report.blockers)
                error('BNV:Preset:UnsupportedFeature', '%s', strjoin(report.blockers, newline));
            end
            message = sprintf(['Apply "%s"? Display settings and pending edits will be replaced. ' ...
                'Input files and export preferences are retained. The camera will reset; render again.'], preset.Name);
            if ~isempty(report.warnings)
                message = message + newline + newline + strjoin(string(report.warnings), newline);
            end
            choice = uiconfirm(app.UIFigure, message, 'Load Preset', ...
                'Options', {'Apply', 'Cancel'}, 'DefaultOption', 2, 'CancelOption', 2);
            if strcmp(choice, 'Apply')
                app.loadPresetFile(pathValue, AllowWarnings=true);
            end
        end

        function runPresetAction(app, action)
            try
                action();
            catch exception
                % A preset error must not turn a valid rendered session into
                % an error state or refresh away uncommitted editor values.
                if strcmp(app.UIFigure.Visible, 'on')
                    uialert(app.UIFigure, exception.message, 'Visualization Preset');
                end
            end
        end

        function onLoad(app, ~, ~)
            app.runUiAction(@() app.loadCurrentScene());
        end

        function onRender(app, ~, ~)
            app.runUiAction(@() app.renderCurrentScene(Visible=true));
        end

        function onPopOut(app, ~, ~)
            app.runUiAction(@() app.popOutCurrentScene(Visible=true));
        end

        function onExportFormatChanged(app, ~, ~)
            format = string(app.ExportFormatDropDown.Value);
            app.updateContentChoices(format);
            app.ExportContentType = "auto";
            if any(format == ["jpg", "bmp"])
                app.ExportTransparencyCheckBox.Value = false;
                app.ExportTransparencyCheckBox.Enable = 'off';
            else
                app.ExportTransparencyCheckBox.Enable = 'on';
            end
            app.refreshView();
        end

        function onSizeModeChanged(app, ~, ~)
            app.refreshView();
        end

        function onTransparencyChanged(app, ~, ~)
            format = string(app.ExportFormatDropDown.Value);
            if app.ExportTransparencyCheckBox.Value && any(format == ["jpg", "bmp"])
                app.ExportTransparencyCheckBox.Value = false;
            end
            app.refreshView();
        end

        function onThemeChanged(app, ~, ~)
            app.setTheme(lower(string(app.ThemeSwitch.Value)));
        end

        function onSurfaceOpacityChanged(app, ~, ~)
            patch = struct('surface', struct( ...
                'opacity', app.SurfaceOpacitySlider.Value));
            app.DraftOptions = app.DraftOptions.withPatch(patch);
            app.synchronizeDraftOptions();
        end

        function synchronizeDraftOptions(app)
            if isempty(app.Session.Scene)
                app.synchronizeSettingsDialog();
                app.refreshView();
                return;
            end
            current = app.Session.Scene;
            metadata = current.Metadata;
            if isfield(metadata, 'session_state')
                % Internal Apply must retain current, possibly unsaved,
                % export edits instead of reloading the last saved defaults.
                metadata.session_state.export = app.exportSettings();
            end
            scene = brainnet.core.Scene(current.Id, current.Name, ...
                current.LoadFile, current.MapMode, current.Inputs, ...
                Options=app.DraftOptions, SchemaVersion=current.SchemaVersion, ...
                CoordinateSpace=current.CoordinateSpace, ...
                RedistributionStatus=current.RedistributionStatus, ...
                Metadata=metadata);
            scenePath = app.SceneFilePath;
            app.setScene(scene);
            app.SceneFilePath = scenePath;
            app.refreshView();
        end

        function onOpenFullSettings(app, ~, ~)
            category = app.SettingsAccordion.ActiveCategory;
            if ~any(category == ["layout", "global"])
                category = "layout";
            end
            app.openVisualizationSettings(Visible=true, Tab=category);
        end

        function toggleSettingsPanel(app)
            app.setSettingsPanelCollapsed(~app.SettingsPanelCollapsed);
        end

        function toggleToolsPanel(app)
            app.ToolsPanelCollapsed = ~app.ToolsPanelCollapsed;
            app.applySettingsPanelState();
        end

        function applySettingsPanelState(app)
            if isempty(app.SettingsPanel) || ~isvalid(app.SettingsPanel)
                return;
            end
            if app.SettingsPanelCollapsed
                app.PresetActionGrid.Visible = 'off';
                app.SettingsGrid.RowHeight = {34, 0, '1x', 0};
                app.SettingsTitleLabel.Visible = 'off';
                app.FullSettingsPanel.Visible = 'off';
                app.ToolsPanel.Visible = 'off';
                app.SettingsCollapseButton.Text = '>';
                app.SettingsCollapseButton.Tooltip = 'Expand visualization settings';
                app.SettingsHeaderGrid.ColumnWidth = {0, 34};
                app.SettingsHeaderGrid.Padding = [0 0 0 0];
            else
                app.PresetActionGrid.Visible = 'on';
                if app.ToolsPanelCollapsed
                    toolsHeight = 30;
                    app.ToolsContainerGrid.RowHeight = {28, 0};
                    app.ToolsGrid.Visible = 'off';
                    app.ToolsToggleButton.Text = 'Tools >';
                    app.ToolsToggleButton.Tooltip = 'Expand tools';
                else
                    toolsHeight = 116;
                    app.ToolsContainerGrid.RowHeight = {28, 84};
                    app.ToolsGrid.Visible = 'on';
                    app.ToolsToggleButton.Text = 'Tools v';
                    app.ToolsToggleButton.Tooltip = 'Collapse tools';
                end
                app.SettingsGrid.RowHeight = {34, 30, '1x', toolsHeight};
                app.SettingsTitleLabel.Visible = 'on';
                app.FullSettingsPanel.Visible = 'on';
                app.ToolsPanel.Visible = 'on';
                app.SettingsCollapseButton.Text = '<';
                app.SettingsCollapseButton.Tooltip = 'Collapse visualization settings';
                app.SettingsHeaderGrid.ColumnWidth = {'1x', 34};
                app.SettingsHeaderGrid.Padding = [8 0 0 0];
            end
        end

        function showRenderCanvas(app, rendered)
            if isempty(app.StartupPanel) || ~isvalid(app.StartupPanel)
                return;
            end
            app.StartupPanel.Visible = onOff(~rendered);
            app.RenderCanvasPanel.Visible = onOff(rendered);
        end

        function validateVertexColors(app,options)
            settings=options.section('surface');
            if string(settings.color_mode)~="vertex-rgb", return; end
            mesh=app.boundarySurface();
            brainnet.core.VertexColors.requireBound(settings,mesh.coordinates,mesh.faces);
        end

        function applyVisualizationSettings(app, settings)
            if app.RenderingInProgress, return; end
            brainnet.core.VolumeThresholdPolicy.requireSupported(settings.section('volume'));
            candidate = brainnet.core.RenderOptions.fromVisualizationStruct(settings.toStruct());
            if ~isempty(app.Session.Scene)
                app.validateVertexColors(candidate);
                brainnet.core.DoubleBrain.requireScene(candidate, app.Session.Scene);
            end
            app.DraftOptions = candidate;
            app.SurfaceOpacityIsExplicit = true;
            app.synchronizeDraftOptions();
            if isempty(app.Session.Scene)
                app.refreshView();
                return;
            end
            % Apply is the commit-and-render action for a usable Scene.
            app.renderCurrentScene(Visible=strcmp(app.UIFigure.Visible, 'on'));
        end

        function synchronizeSettingsDialog(app)
            if ~isempty(app.SettingsAccordion) && isvalid(app.SettingsAccordion)
                app.SettingsAccordion.replaceSettings(app.DraftOptions.Settings);
            end
            if ~isempty(app.SettingsDialog) && isvalid(app.SettingsDialog) && ...
                    app.SettingsDialog.isOpen()
                app.SettingsDialog.replaceSettings(app.DraftOptions.Settings);
            end
        end

        function onSettingsDialogClosed(app)
            app.SettingsDialog = [];
        end

        function closeSettingsDialog(app)
            if ~isempty(app.SettingsDialog) && isvalid(app.SettingsDialog)
                dialog = app.SettingsDialog;
                app.SettingsDialog = [];
                delete(dialog);
            end
        end

        function onViewAction(app, action, ~, ~)
            if string(action)=="inspect"
                if app.BatchRenderer.InspectEnabled
                    app.stopInspection();
                else
                    app.runUiAction(@() app.openInspector());
                end
                return;
            end
            app.stopLiveDemo();
            app.stopInspection();
            target = app.activeRenderTarget();
            if isempty(target)
                return;
            end
            figureHandle = ancestor(target, 'figure');
            axesHandles = findall(target, 'Type', 'axes');
            switch string(action)
                case {"rotate","pan","zoom"}
                    if strcmp(app.LastRenderInfo.backend,'batch') && ...
                            isequal(figureHandle,app.UIFigure)
                        app.enableCameraTool(string(action));
                    else
                        switch string(action)
                            case "rotate", rotate3d(figureHandle,'on');
                            case "pan", pan(figureHandle,'on');
                            case "zoom", zoom(figureHandle,'on');
                        end
                    end
                case "fit"
                    app.disableCameraTool();
                    if strcmp(app.LastRenderInfo.backend, 'batch')
                        app.applyViewAction("fit");
                    else
                        for axesHandle = reshape(axesHandles, 1, []), axis(axesHandle, 'tight'); end
                    end
                otherwise
                    app.disableCameraTool();
                    if strcmp(app.LastRenderInfo.backend, 'batch')
                        app.applyViewAction("reset");
                    else
                        app.renderCurrentScene(Backend="legacy");
                    end
            end
        end

        function enableCameraTool(app, action)
            app.stopLegacyUiMontageFitTimer();
            app.CameraTool=action;
            app.CameraGestureActive=false;
            app.CameraGestureAxis=[];
            for a=reshape(app.BatchRenderer.ActiveAxes,1,[])
                if isgraphics(a) && isprop(a,'Interactions'), a.Interactions=[]; end
            end
            app.UIFigure.WindowButtonDownFcn=@(~,~) app.beginCameraGesture();
            app.UIFigure.WindowButtonMotionFcn=@(~,~) app.moveCameraGesture();
            app.UIFigure.WindowButtonUpFcn=@(~,~) app.endCameraGesture();
            app.UIFigure.WindowScrollWheelFcn=@(~,event) app.applyScrollZoom( ...
                double(app.UIFigure.CurrentPoint),event.VerticalScrollCount);
        end

        function disableCameraTool(app)
            app.CameraTool="";
            app.CameraGestureActive=false;
            app.CameraGestureAxis=[];
            if isgraphics(app.UIFigure)
                app.UIFigure.WindowButtonDownFcn=[];
                app.UIFigure.WindowButtonMotionFcn=[];
                app.UIFigure.WindowButtonUpFcn=[];
                app.UIFigure.WindowScrollWheelFcn=[];
            end
        end

        function beginCameraGesture(app)
            if app.CameraTool=="" || ~strcmp(app.UIFigure.SelectionType,'normal')
                return;
            end
            app.CameraGestureActive=false;
            app.CameraGestureAxis=[];
            point=double(app.UIFigure.CurrentPoint);
            for a=reshape(app.BatchRenderer.ActiveAxes,1,[])
                if ~isgraphics(a), continue; end
                bounds=getpixelposition(a,true);
                if point(1)>=bounds(1) && point(1)<=bounds(1)+bounds(3) && ...
                        point(2)>=bounds(2) && point(2)<=bounds(2)+bounds(4)
                    app.CameraGesturePoint=point;
                    app.CameraGestureAxis=a;
                    app.CameraGestureActive=true;
                    return;
                end
            end
        end

        function moveCameraGesture(app)
            if ~app.CameraGestureActive, return; end
            if isempty(app.CameraGestureAxis) || ~isgraphics(app.CameraGestureAxis) || ...
                    ~any(app.BatchRenderer.ActiveAxes==app.CameraGestureAxis)
                app.endCameraGesture();
                return;
            end
            point=double(app.UIFigure.CurrentPoint);
            delta=point-app.CameraGesturePoint;
            if ~all(isfinite(delta)) || ~any(delta), return; end
            app.CameraGesturePoint=point;
            app.BatchRenderer.applyCameraGesture(app.CameraTool,delta,app.CameraGestureAxis);
        end

        function endCameraGesture(app)
            app.CameraGestureActive=false;
            app.CameraGestureAxis=[];
        end

        function onViewChanged(app, ~, ~)
            app.stopLiveDemo();
            target = app.activeRenderTarget();
            if isempty(target)
                return;
            end
            direction = string(app.ViewDropDown.Value);
            if strcmp(app.LastRenderInfo.backend, 'batch')
                if direction == "layout", direction = "reset"; end
                app.applyViewAction(direction);
                return;
            end
            if direction == "layout", return; end
            angles = struct('left', [-90 0], 'right', [90 0], ...
                'anterior', [180 0], 'posterior', [0 0], ...
                'superior', [0 90], 'inferior', [0 -90]);
            value = angles.(char(direction));
            axesHandles = findall(target, 'Type', 'axes');
            for axesHandle = reshape(axesHandles, 1, [])
                view(axesHandle, value);
            end
        end

        function onViewportChanged(app, ~, ~)
            target = app.activeRenderTarget();
            if isempty(target) || isempty(app.CanvasBackgroundDropDown)
                return;
            end
            figureHandle = ancestor(target, 'figure');
            background = viewportColor(string(app.CanvasBackgroundDropDown.Value));
            if isgraphics(target, 'figure')
                figureHandle.Color = background;
            elseif isprop(target, 'BackgroundColor')
                target.BackgroundColor = background;
            end
            axesHandles = findall(target, 'Type', 'axes');
            for axesHandle = reshape(axesHandles, 1, [])
                axesHandle.Color = background;
                grid(axesHandle, onOff(app.GridCheckBox.Value));
                delete(findall(axesHandle, 'Type', 'light'));
                lightingMode = string(app.LightingDropDown.Value);
                if lightingMode == "studio"
                    app.addCameraLight(axesHandle,'headlight');
                    app.addCameraLight(axesHandle,'right');
                elseif lightingMode == "headlight"
                    app.addCameraLight(axesHandle,'headlight');
                end
            end
        end

        function addCameraLight(~,axesHandle,direction)
            lightHandle=camlight(axesHandle,char(direction));
            lightHandle.Tag='brainnet-camera-light';
            lightHandle.UserData=struct('brainnet_light_direction',char(direction));
        end

        function updateActiveCameraLights(app)
            for axesHandle=reshape(app.BatchRenderer.ActiveAxes,1,[])
                app.BatchRenderer.synchronizeCameraLighting(axesHandle);
            end
            for axesHandle=reshape(app.PopoutRenderer.ActiveAxes,1,[])
                app.PopoutRenderer.synchronizeCameraLighting(axesHandle);
            end
        end

        function target = activeRenderTarget(app)
            target = [];
            if isgraphics(app.BatchRenderer.ActiveTarget)
                target = app.BatchRenderer.ActiveTarget;
            elseif isgraphics(app.LegacyAdapter.ActiveFigure, 'figure')
                target = app.LegacyAdapter.ActiveFigure;
            end
        end

        function onExport(app, ~, ~)
            try
                if ~strcmp(app.ExportButton.Enable, 'on')
                    error('BNV:App:NoExportableFigure', ...
                        'Render the scene with Modern Batch Renderer before exporting.');
                end
                format = string(app.ExportFormatDropDown.Value);
                sceneId = string(app.Session.Scene.Id);
                defaultName = sceneId + "." + format;
                [name, folder] = app.saveFileDialog(exportFileFilters(format), ...
                    'Export BrainNet Figure', char(fullfile(pwd, defaultName)));
                if isequal(name, 0)
                    return
                end
                app.exportCurrentFigure(string(fullfile(folder, name)), Overwrite=true);
                app.presentExportSuccess();
            catch exception
                app.presentExportError(exception);
            end
        end

        function requestRestoreDefaults(app)
            if ~strcmp(app.UIFigure.Visible,'on'), return; end
            choice=uiconfirm(app.UIFigure, ...
                ['Replace all display settings and pending edits with defaults? ' ...
                 'Current figures stay visible until you render again. ' ...
                 'Inputs, coordinate declarations, export preferences and theme are kept. ' ...
                 'No files are changed. Click Apply or Render Scene afterwards.'], ...
                'Restore Display Defaults', 'Options',{'Restore Defaults','Cancel'}, ...
                'DefaultOption',2,'CancelOption',2,'Icon','warning');
            if strcmp(choice,'Restore Defaults'), app.resetVisualizationSettings(Confirmed=true); end
        end

        function onHelp(app, ~, ~)
            app.showHelp();
        end

        function onAbout(app, ~, ~)
            app.showAbout();
        end

        function onFigureSizeChanged(app, ~, ~)
            app.enforceMinimumWindowSize();
            app.applyResponsiveLayout();
        end

        function applyResponsiveLayout(app)
            if isempty(app.UIFigure) || ~isvalid(app.UIFigure) || isempty(app.WorkGrid)
                return;
            end
            width = app.RootPanel.InnerPosition(3);
            if width >= 1220
                app.LayoutDensity = "regular";
                dataWidth = 260;
                settingsWidth = 350;
                app.HeaderGrid.ColumnWidth = {126, '1x', 368};
                app.HeaderActionGrid.ColumnWidth = {48, 112, 88, 88};
                app.ExportGrid.ColumnWidth = {'1x', '0.85x', '1.25x'};
                app.TitleLabel.FontSize = 26;
            elseif width >= 1000
                app.LayoutDensity = "compact";
                dataWidth = 240;
                settingsWidth = 310;
                app.HeaderGrid.ColumnWidth = {96, '1x', 344};
                app.HeaderActionGrid.ColumnWidth = {44, 104, 82, 82};
                app.ExportGrid.ColumnWidth = {'1x', '0.85x', '1.25x'};
                app.TitleLabel.FontSize = 22;
            else
                app.LayoutDensity = "minimum-safe";
                dataWidth = 225;
                settingsWidth = 270;
                app.HeaderGrid.ColumnWidth = {78, '1x', 316};
                app.HeaderActionGrid.ColumnWidth = {40, 94, 75, 75};
                app.ExportGrid.ColumnWidth = {'1x', '0.85x', '1.25x'};
                app.TitleLabel.FontSize = 19;
            end
            if app.SettingsPanelCollapsed
                settingsWidth = 36;
            end
            app.WorkGrid.ColumnWidth = {dataWidth, '1x', settingsWidth};
            if app.RootPanel.InnerPosition(4)<760
                % Keep Scene Summary usable in the scrollable data column.
                app.DataGrid.RowHeight={34,36,248,190,154};
            else
                app.DataGrid.RowHeight={34,36,248,'1x',154};
            end
            if app.LayoutDensity=="minimum-safe"
                app.LoadButton.Text='Load Data';
                app.ImportSettingsButton.Text='Import EC';
            else
                app.LoadButton.Text='Validate and Load';
                app.ImportSettingsButton.Text='Import Settings';
            end
            app.applySettingsPanelState();
            app.layoutPreviewToolbar();
        end

        function layoutPreviewToolbar(app)
            % Use the panel's settled width, not the window breakpoint: the
            % settings column may also be collapsed without a window resize.
            if isempty(app.RenderButton) || ~isvalid(app.RenderButton) || ...
                    isempty(app.PreviewToolbarGrid), return; end
            width = app.PreviewPanel.InnerPosition(3)-12;
            rows = 3;
            if width>=950
                rows = 1;
            elseif width>=580
                rows = 2;
            end
            if app.PreviewToolbarRows==rows, return; end
            app.PreviewToolbarRows = rows;
            controls = {app.ResetViewButton,app.RotateButton,app.PanButton, ...
                app.ZoomButton,app.FitButton,app.DemoButton,app.StopDemoButton,app.InspectButton, ...
                app.ViewDropDown,app.ClearFigureButton,app.PopOutButton,app.RenderButton};
            app.PreviewToolbarGrid.Scrollable = 'off';
            app.PreviewToolbarGrid.RowSpacing = 4;
            for i = 1:numel(controls)
                controls{i}.Layout.Row = 1;
                controls{i}.Layout.Column = 1;
            end
            if rows==1
                app.PreviewToolbarGrid.ColumnWidth = {50,54,44,48,40,60,54,62,'1x',96,72,110};
                for i=1:numel(controls), controls{i}.Layout.Column = i; end
            else
                app.PreviewToolbarGrid.ColumnWidth = repmat({'1x'},1,14);
                for i=1:7, controls{i}.Layout.Column = [2*i-1,2*i]; end
                for i=8:12, controls{i}.Layout.Row = 2; end
                if rows==2
                    app.InspectButton.Layout.Column = [1 2];
                    app.ViewDropDown.Layout.Column = [3 5];
                    app.ClearFigureButton.Layout.Column = [6 8];
                    app.PopOutButton.Layout.Column = [9 11];
                    app.RenderButton.Layout.Column = [12 14];
                else
                    app.InspectButton.Layout.Column = [1 4];
                    app.ViewDropDown.Layout.Column = [5 9];
                    app.ClearFigureButton.Layout.Column = [10 14];
                    app.PopOutButton.Layout.Row = 3;
                    app.RenderButton.Layout.Row = 3;
                    app.PopOutButton.Layout.Column = [1 6];
                    app.RenderButton.Layout.Column = [7 14];
                end
            end
            app.PreviewToolbarGrid.RowHeight = repmat({34},1,rows);
            app.PreviewGrid.RowHeight = {34*rows+4*(rows-1),'1x'};
        end

        function applyTheme(app)
            if ~isempty(app.MergeWindow) && isvalid(app.MergeWindow)
                app.MergeWindow.setTheme(app.Theme);
            end
            if ~isempty(app.SurfaceConversionWindow) && isvalid(app.SurfaceConversionWindow)
                app.SurfaceConversionWindow.setTheme(app.Theme);
            end
            if ~isempty(app.SurfaceSubdivisionWindow) && isvalid(app.SurfaceSubdivisionWindow)
                app.SurfaceSubdivisionWindow.setTheme(app.Theme);
            end
            if ~isempty(app.AtlasNodeWindow) && isvalid(app.AtlasNodeWindow)
                app.AtlasNodeWindow.setTheme(app.Theme);
            end
            if ~isempty(app.MovieWindow)&&isvalid(app.MovieWindow), app.MovieWindow.setTheme(app.Theme); end
            if isempty(app.UIFigure) || ~isvalid(app.UIFigure)
                return;
            end
            % R2025a controls otherwise inherit the MATLAB desktop's theme.
            % Explicitly bind this window's base theme to the app selection.
            if isprop(app.UIFigure, 'Theme')
                app.UIFigure.Theme = char(app.Theme);
            end
            if app.Theme == "dark"
                windowColor = [0.067 0.094 0.129];
                panelColor = [0.094 0.129 0.173];
                textColor = [0.92 0.95 0.98];
                mutedColor = [0.67 0.72 0.78];
                headerColor = [0.024 0.118 0.247];
                primaryColor = [0.184 0.506 0.969];
            else
                windowColor = [0.953 0.965 0.980];
                panelColor = [1 1 1];
                textColor = [0.086 0.137 0.227];
                mutedColor = [0.318 0.38 0.463];
                headerColor = [0.024 0.173 0.388];
                primaryColor = [0.035 0.412 0.855];
            end
            app.UIFigure.Color = windowColor;
            app.RootPanel.BackgroundColor = windowColor;
            app.MainGrid.BackgroundColor = windowColor;
            app.WorkGrid.BackgroundColor = windowColor;
            panels = {app.DataPanel, app.PreviewPanel, app.SettingsPanel, ...
                app.FullSettingsPanel, app.StartupPanel, ...
                app.ExportPanel, app.ResourcePanel, app.ToolsPanel};
            for index = 1:numel(panels)
                if ~isempty(panels{index}) && isvalid(panels{index})
                    panels{index}.BackgroundColor = panelColor;
                    if isprop(panels{index}, 'ForegroundColor')
                        panels{index}.ForegroundColor = textColor;
                    end
                end
            end
            grids = {app.DataGrid, app.DataActionGrid, app.DataRoleGrid, app.SceneActionGrid, ...
                app.PreviewGrid, app.PreviewToolbarGrid, app.PreviewCanvasGrid, ...
                app.StartupGrid, app.SettingsGrid, app.SettingsHeaderGrid, ...
                app.FullSettingsGrid, app.PresetActionGrid, app.ExportGrid, app.ResourceGrid, ...
                app.ToolsGrid, app.ToolsContainerGrid};
            for index = 1:numel(grids)
                if ~isempty(grids{index}) && isvalid(grids{index})
                    grids{index}.BackgroundColor = panelColor;
                end
            end
            app.HeaderPanel.BackgroundColor = headerColor;
            app.HeaderGrid.BackgroundColor = headerColor;
            app.HeaderActionGrid.BackgroundColor = headerColor;
            app.TitleLabel.FontColor = [1 1 1];
            app.WelcomeLabel.FontColor = [0.72 0.84 0.98];
            app.ThemeLabel.FontColor = [1 1 1];
            app.HelpButton.FontColor = [1 1 1];
            app.HelpButton.BackgroundColor = headerColor;
            app.AboutButton.FontColor = [1 1 1];
            app.AboutButton.BackgroundColor = headerColor;
            labels = findall(app.UIFigure, 'Type', 'uilabel');
            for label = reshape(labels, 1, [])
                if label ~= app.TitleLabel && label ~= app.WelcomeLabel && ...
                        label ~= app.ThemeLabel
                    label.FontColor = textColor;
                end
            end
            app.DropHintLabel.FontColor = mutedColor;
            app.SelectInputButton.BackgroundColor = primaryColor;
            app.SelectInputButton.FontColor = [1 1 1];
            app.RenderButton.BackgroundColor = primaryColor;
            app.RenderButton.FontColor = [1 1 1];
            app.ExportButton.BackgroundColor = primaryColor;
            app.ExportButton.FontColor = [1 1 1];
            app.ToolsToggleButton.BackgroundColor = panelColor;
            app.ToolsToggleButton.FontColor = textColor;
            app.ExportTransparencyCheckBox.FontColor = textColor;
            if isprop(app.SummaryArea, 'HTMLSource')
                app.refreshSceneSummaryHtml();
            else
                app.SummaryArea.BackgroundColor = panelColor;
                app.SummaryArea.FontColor = textColor;
            end
            app.StartupInfoArea.FontColor = textColor;
            if app.Theme=="dark", app.StartupCitationLabel.FontColor=[1 .39 .43];
            else, app.StartupCitationLabel.FontColor=[.80 .12 .16]; end
            if ~isempty(app.SettingsAccordion) && isvalid(app.SettingsAccordion)
                app.SettingsAccordion.setTheme(app.Theme);
            end
        end

        function setRenderBusy(app, busy)
            app.RenderingInProgress = busy;
            controls = [app.RenderButton; findall(app.UIFigure, 'Tag', 'SettingsApply')];
            for control = reshape(controls, 1, [])
                if ~isgraphics(control), continue; end
                control.Enable = onOff(~busy);
                control.Interruptible = 'off';
                control.BusyAction = 'cancel';
            end
            if busy
                app.StatusLabel.Text = 'Rendering... Please wait.';
                app.UIFigure.Pointer = 'watch';
            else
                app.UIFigure.Pointer = 'arrow';
            end
        end

        function finishRender(app)
            if ~isvalid(app) || ~isgraphics(app.UIFigure), return; end
            app.setRenderBusy(false);
            app.refreshView();
        end

        function styleInputTable(app)
            if isempty(app.InputTable) || ~isvalid(app.InputTable)
                return;
            end
            removeStyle(app.InputTable);
            data = app.InputTable.Data;
            if isempty(data)
                return;
            end
            if app.Theme == "dark"
                style = uistyle('BackgroundColor', [0.094 0.129 0.173], ...
                    'FontColor', [0.92 0.95 0.98]);
            else
                style = uistyle('BackgroundColor', [1 1 1], ...
                    'FontColor', [0.086 0.137 0.227]);
            end
            [rows, columns] = ndgrid(1:height(data), 1:width(data));
            addStyle(app.InputTable, style, 'cell', [rows(:), columns(:)]);
        end

        function refreshResourceLabels(app)
            if app.DocumentationCaptureMode
                app.CpuResourceLabel.Text = 'CPU: Hidden for documentation';
                app.MemoryResourceLabel.Text = 'RAM: Hidden for documentation';
                app.GpuResourceLabel.Text = 'GPU: Hidden for documentation';
                app.NetworkResourceLabel.Text = 'Network: Hidden for documentation';
                return;
            end
            resource = app.ResourceSnapshot;
            app.CpuResourceLabel.Text = char("CPU: " + string(resource.cpu));
            app.MemoryResourceLabel.Text = char("RAM: " + string(resource.memory));
            app.GpuResourceLabel.Text = char("GPU: " + string(resource.gpu));
            app.NetworkResourceLabel.Text = char("Network: " + string(resource.network));
        end

        function scheduleLegacyUiMontageFit(app, savedCamera, restoreStatus)
            % Embedded UIAxes can retain stale viewport bounds on both
            % current and older MATLAB until the layout settles after render.
            axesHandles = app.BatchRenderer.ActiveAxes;
            app.LegacyUiMontageFitTimer = timer( ...
                'ExecutionMode', 'singleShot', 'StartDelay', 0.1, ...
                'TimerFcn', @(source, ~) app.commitLegacyUiMontageFit( ...
                    source, axesHandles, savedCamera, restoreStatus));
            start(app.LegacyUiMontageFitTimer);
        end

        function commitLegacyUiMontageFit(app, source, axesHandles, savedCamera, restoreStatus)
            try
                if ~isempty(app.UIFigure) && isvalid(app.UIFigure) && ...
                        isequal(app.LegacyUiMontageFitTimer, source) && ...
                        isequal(app.BatchRenderer.ActiveAxes, axesHandles) && ...
                        all(isgraphics(axesHandles))
                    drawnow;
                    app.BatchRenderer.fitCamera();
                    if strcmp(restoreStatus, 'restored')
                        app.BatchRenderer.restoreCamera(savedCamera);
                    end
                    app.LastRenderInfo.render_metrics.camera_state = ...
                        app.BatchRenderer.captureCamera();
                    app.LastRenderInfo.render_metrics.legacy_ui_viewport_refit = 'completed';
                    drawnow;
                end
            catch exception
                app.LastRenderInfo.render_metrics.legacy_ui_viewport_refit = 'error';
                warning('BNV:App:LegacyUiMontageFit', ...
                    'The older MATLAB montage viewport could not be refreshed: %s', ...
                    exception.message);
            end
            if isequal(app.LegacyUiMontageFitTimer, source)
                app.LegacyUiMontageFitTimer = [];
            end
            if isvalid(source)
                stop(source);
                delete(source);
            end
        end

        function stopLegacyUiMontageFitTimer(app)
            if isempty(app.LegacyUiMontageFitTimer), return; end
            pending = app.LegacyUiMontageFitTimer;
            app.LegacyUiMontageFitTimer = [];
            if isvalid(pending)
                stop(pending);
                delete(pending);
            end
        end

        function scheduleLegacyUiMainFocus(app)
            if app.Closing || ~isgraphics(app.UIFigure) || ...
                    strcmp(app.UIFigure.Visible,'off')
                return;
            end
            app.stopLegacyUiFocusTimer();
            app.LegacyUiFocusTimer = timer('ExecutionMode','singleShot', ...
                'StartDelay',0.05, ...
                'TimerFcn',@(~,~) app.restoreLegacyUiMainFocus());
            start(app.LegacyUiFocusTimer);
        end

        function restoreLegacyUiMainFocus(app)
            if ~app.Closing && isgraphics(app.UIFigure) && ...
                    strcmp(app.UIFigure.Visible,'on')
                drawnow;
                figure(app.UIFigure);
                app.LegacyUiMainFocusCount = app.LegacyUiMainFocusCount + 1;
            end
            app.stopLegacyUiFocusTimer();
        end

        function stopLegacyUiFocusTimer(app)
            if isempty(app.LegacyUiFocusTimer), return; end
            pending = app.LegacyUiFocusTimer;
            app.LegacyUiFocusTimer = [];
            if isvalid(pending)
                stop(pending);
                delete(pending);
            end
        end

        function startResourceTimer(app)
            app.stopResourceTimer();
            app.LastNetworkBytes = networkByteCount();
            app.LastNetworkSample = datetime('now');
            app.ResourceTimer = timer( ...
                'ExecutionMode', 'fixedSpacing', ...
                'Period', 3, ...
                'BusyMode', 'drop', ...
                'TimerFcn', @(~, ~) app.onResourceTimer());
            start(app.ResourceTimer);
        end

        function stopResourceTimer(app)
            if isempty(app.ResourceTimer)
                return;
            end
            resourceTimer = app.ResourceTimer;
            app.ResourceTimer = [];
            try
                stop(resourceTimer);
            catch
            end
            try
                delete(resourceTimer);
            catch
            end
        end

        function onResourceTimer(app)
            if isempty(app.UIFigure) || ~isvalid(app.UIFigure)
                app.stopResourceTimer();
                return;
            end
            currentBytes = networkByteCount();
            currentTime = datetime('now');
            elapsed = seconds(currentTime - app.LastNetworkSample);
            resource = systemResourceSnapshot();
            if elapsed > 0 && all(isfinite(currentBytes)) && ...
                    all(isfinite(app.LastNetworkBytes))
                rates = max(0, currentBytes - app.LastNetworkBytes) / elapsed;
                resource.network = sprintf('Down %s/s | Up %s/s', ...
                    formatByteRate(rates(1)), formatByteRate(rates(2)));
            end
            app.LastNetworkBytes = currentBytes;
            app.LastNetworkSample = currentTime;
            app.ResourceSnapshot = resource;
            app.refreshResourceLabels();
        end

        function enforceMinimumWindowSize(app)
            if app.AdjustingWindowSize || isempty(app.UIFigure) || ...
                    ~isvalid(app.UIFigure)
                return;
            end
            position = app.UIFigure.Position;
            minimumSize = app.ProductInfo.minimum_window_size;
            targetSize = max(position(3:4), minimumSize);
            if strcmp(app.UIFigure.WindowState,'normal') && ~isequal(targetSize, position(3:4))
                app.AdjustingWindowSize = true;
                cleanup = onCleanup(@() app.finishWindowAdjustment());
                app.UIFigure.Position = ...
                    brainnet.render.internal.screenAwarePosition(targetSize, ...
                        AnchorPoint=brainnet.render.internal.figureAnchorPoint(app.UIFigure));
            end
        end

        function createViewport(app)
            % The layout manager follows the native client area. Do not copy
            % possibly stale figure Position dimensions into a pixel panel.
            app.RootLayoutGrid=uigridlayout(app.UIFigure,[1 1],'Tag','BrainNetViewport');
            app.RootLayoutGrid.Padding=[0 0 0 0];
            app.RootLayoutGrid.RowHeight={'1x'}; app.RootLayoutGrid.ColumnWidth={'1x'};
            app.RootPanel=uipanel(app.RootLayoutGrid,'BorderType','none', ...
                'Tag','BrainNetRoot','AutoResizeChildren','off');
            app.RootPanel.Layout.Row=1; app.RootPanel.Layout.Column=1;
        end

        function finishWindowAdjustment(app)
            app.AdjustingWindowSize = false;
        end

        function onDrop(app, ~, event)
            try
                paths = string(event.Data);
                for path = paths(:).'
                    if endsWith(lower(path), ".json")
                        app.importSceneFile(path);
                    else
                        app.addSelectedInput("auto", path);
                    end
                end
            catch exception
                app.presentError(exception);
            end
        end

        function runUiAction(app, action)
            try
                action();
            catch exception
                app.presentError(exception);
            end
        end

        function addSelectedInput(app,role,pathValue)
            app.runUiAction(@() app.selectInputPath(role,pathValue));
        end

        function presentError(app, exception)
            app.Session.recordError(exception);
            app.refreshView();
            if strcmp(app.UIFigure.Visible, 'on')
                uialert(app.UIFigure, exception.message, 'BrainNet Viewer');
            end
        end

        function presentExportError(app, exception)
            app.LastExportInfo = struct( ...
                'status', 'error', ...
                'identifier', exception.identifier, ...
                'message', exception.message);
            app.refreshView();
            if strcmp(app.UIFigure.Visible, 'on')
                uialert(app.UIFigure, exception.message, 'BrainNet Viewer Export');
            end
        end

        function presentExportSuccess(app)
            if ~strcmp(app.UIFigure.Visible, 'on')
                return;
            end
            record = app.LastExportInfo;
            message = sprintf('Export complete.\n%s\nProvenance: %s', ...
                record.output_path, record.sidecar_path);
            uialert(app.UIFigure, message, 'Export Complete', 'Icon', 'success');
        end
    end
end


function value = onOff(tf)
if tf
    value = 'on';
else
    value = 'off';
end
end


function value = viewportColor(name)
switch name
    case "black"
        value = [0.03 0.04 0.06];
    case "gray"
        value = [0.90 0.92 0.95];
    otherwise
        value = [1 1 1];
end
end


function value = systemResourceSnapshot()
if ismac
    % MATLAB's memory() system view and Windows processor environment
    % variable do not describe macOS hardware. GPU compute availability is
    % also distinct from the physical GPU shown in the status bar.
    hardware = macHardwareProfile();
    cpu = hardware.cpu;
    memoryText = hardware.memory;
    gpuText = hardware.gpu;
elseif isunix
    hardware=brainnet.app.internal.linuxHardwareProfile();
    cpu=hardware.cpu;
    memoryText=hardware.memory;
    capabilities=brainnet.render.internal.accelerationCapabilities();
    if capabilities.available_gpu_count>0
        gpuText=gpuResourceText(capabilities.available_gpu_count);
    else
        gpuText='Not available';
    end
else
    capabilities = brainnet.render.internal.accelerationCapabilities();
    processorName = processorModel();
    logicalCount = capabilities.logical_processor_count;
    physicalCount = physicalCoreCount(processorName, logicalCount);
    cpu = sprintf('%s | %dC/%dT', ...
        abbreviateResource(processorName, 30), physicalCount, logicalCount);

    memoryText = "Usage unavailable";
    try
        [~, systemView] = memory;
        if isfield(systemView, 'PhysicalMemory')
            available = double(systemView.PhysicalMemory.Available) / 1024^3;
            total = double(systemView.PhysicalMemory.Total) / 1024^3;
            memoryText = sprintf('%.1f / %.1f GB', total - available, total);
        end
    catch
        try
            runtime = java.lang.Runtime.getRuntime();
            available = double(runtime.freeMemory()) / 1024^3;
            total = double(runtime.totalMemory()) / 1024^3;
            memoryText = sprintf('%.1f / %.1f GB heap', total - available, total);
        catch
        end
    end

    if capabilities.available_gpu_count > 0
        gpuText = gpuResourceText(capabilities.available_gpu_count);
    else
        gpuText = 'Not available';
    end
end
value = struct( ...
    'cpu', char(cpu), ...
    'memory', char(memoryText), ...
    'gpu', char(gpuText), ...
    'network', 'Idle', ...
    'network_probe_performed', false, ...
    'sampled_at', char(datetime('now', 'TimeZone', 'local', ...
        'Format', 'yyyy-MM-dd''T''HH:mm:ssXXX')));
end


function value = macHardwareProfile()
persistent cached
if isempty(cached)
    model = macSysctl('machdep.cpu.brand_string');
    if strlength(model) == 0, model = "Unknown processor"; end
    physical = str2double(macSysctl('hw.physicalcpu'));
    logical = str2double(macSysctl('hw.logicalcpu'));
    cpu = abbreviateResource(model, 30);
    if isfinite(physical) && physical > 0 && isfinite(logical) && logical > 0
        cpu = sprintf('%s | %dC/%dT', cpu, physical, logical);
    end
    installed = str2double(macSysctl('hw.memsize'));
    memoryText = "Unknown";
    if isfinite(installed) && installed > 0
        memoryText = sprintf('%.1f GB installed', installed / 1024^3);
    end
    gpuText = "Unknown";
    [status, output] = system('system_profiler SPDisplaysDataType -json');
    if status == 0
        try
            report = jsondecode(output);
            displays = report.SPDisplaysDataType;
            if ~isempty(displays)
                gpu = displays(1);
                if isfield(gpu, 'sppci_model')
                    gpuText = string(gpu.sppci_model);
                end
                if isfield(gpu, 'sppci_cores')
                    gpuText = gpuText + " " + string(gpu.sppci_cores) + "-core";
                end
                if isfield(gpu, 'spdisplays_mtlgpufamilysupport') && ...
                        startsWith(string(gpu.spdisplays_mtlgpufamilysupport), 'spdisplays_metal')
                    gpuText = gpuText + " (Metal)";
                end
            end
        catch
        end
    end
    cached = struct('cpu', char(cpu), 'memory', char(memoryText), 'gpu', char(gpuText));
end
value = cached;
end


function value = macSysctl(key)
% Only fixed, source-owned sysctl keys are passed by callers.
[status, output] = system(['sysctl -n ' char(key)]);
value = "";
if status == 0, value = strtrim(string(output)); end
end


function value = processorModel()
value = "";
if ispc
    try
        value = string(winqueryreg('HKEY_LOCAL_MACHINE', ...
            'HARDWARE\DESCRIPTION\System\CentralProcessor\0', ...
            'ProcessorNameString'));
    catch
    end
end
if strlength(strtrim(value)) == 0
    value = string(getenv('PROCESSOR_IDENTIFIER'));
end
if strlength(strtrim(value)) == 0
    value = string(computer('arch'));
end
value = strtrim(value);
if contains(value, "Threadripper 3970X", 'IgnoreCase', true)
    value = "AMD Threadripper 3970X";
else
    value = regexprep(value, '\s+\d+-Core Processor$', '', 'ignorecase');
    value = regexprep(value, '\s+CPU\s+@.*$', '', 'ignorecase');
end
end


function value = physicalCoreCount(processorName, logicalCount)
if contains(processorName, "Threadripper 3970X", 'IgnoreCase', true)
    value = 32;
elseif logicalCount > 1 && mod(logicalCount, 2) == 0
    value = logicalCount / 2;
else
    value = logicalCount;
end
end


function value = gpuResourceText(count)
value = sprintf('%d available', count);
try
    device = gpuDevice(1);
    available = double(device.AvailableMemory) / 1024^3;
    total = double(device.TotalMemory) / 1024^3;
    name = regexprep(string(device.Name), '^NVIDIA\s+GeForce\s+', '', 'ignorecase');
    name = regexprep(name, '^NVIDIA\s+', '', 'ignorecase');
    value = sprintf('%s | %.1f/%.1f GB free', ...
        abbreviateResource(name, 22), available, total);
catch
end
end


function value = networkByteCount()
value = [NaN NaN];
try
    interfaces = System.Net.NetworkInformation.NetworkInterface.GetAllNetworkInterfaces();
    received = 0;
    sent = 0;
    for index = 1:interfaces.Length
        adapter = interfaces(index);
        if adapter.OperationalStatus ~= ...
                System.Net.NetworkInformation.OperationalStatus.Up || ...
                adapter.NetworkInterfaceType == ...
                System.Net.NetworkInformation.NetworkInterfaceType.Loopback
            continue;
        end
        statistics = adapter.GetIPv4Statistics();
        received = received + double(statistics.BytesReceived);
        sent = sent + double(statistics.BytesSent);
    end
    value = [received sent];
catch
end
end


function value = formatByteRate(bytesPerSecond)
if bytesPerSecond >= 1024^2
    value = sprintf('%.1f MB', bytesPerSecond / 1024^2);
elseif bytesPerSecond >= 1024
    value = sprintf('%.1f KB', bytesPerSecond / 1024);
else
    value = sprintf('%.0f B', bytesPerSecond);
end
end


function value = formatFileSize(bytes)
if bytes >= 1024^3
    value = sprintf('%.2f GB', bytes / 1024^3);
elseif bytes >= 1024^2
    value = sprintf('%.2f MB', bytes / 1024^2);
elseif bytes >= 1024
    value = sprintf('%.1f KB', bytes / 1024);
else
    value = sprintf('%d B', bytes);
end
end


function value = groupedInteger(number)
value = regexprep(sprintf('%.0f', number), ...
    '(\d)(?=(\d{3})+$)', '$1,');
end


function value = abbreviateResource(text, maximumLength)
value = char(text);
if strlength(text) > maximumLength
    value = char(extractBefore(text, maximumLength - 2) + "...");
end
end


function value = roleLabel(role)
switch role
    case "surface"
        value = "Surface";
    case "node"
        value = "Nodes";
    case "edge"
        value = "Edges";
    case "surface_map"
        value = "Surface Map";
    case "volume"
        value = "NIfTI Volume";
    otherwise
        value = role;
end
end


function value = statusSummary(status, message)
switch status
    case "rendered"
        value = "Rendered.";
    case "loaded"
        value = "Scene data loaded.";
    case "loading"
        value = "Loading scene data...";
    case "ready"
        value = "Scene ready.";
    case "error"
        value = "Action failed. See details above.";
    otherwise
        value = string(message);
end
end


function filters = roleFilters(role)
switch role
    case "surface"
        filters = {'*.nv;*.pial;*.mesh;*.g;*.obj;*.mz3;*.mz3.gz;*.gii;*.gii.gz', 'Surface (*.nv,*.pial,*.mesh,*.g,*.obj,*.mz3,*.mz3.gz,*.gii,*.gii.gz)'};
    case "node"
        filters = {'*.node', 'Node (*.node)'};
    case "edge"
        filters = {'*.edge', 'Edge (*.edge)'};
    case "surface_map"
        filters = {'*.txt', 'Surface map (*.txt)'};
    case "volume"
        filters = {'*.nii;*.nii.gz;*.hdr;*.hdr.gz;*.img;*.img.gz', 'NIfTI volume'};
    otherwise
        filters = {'*.*', 'All files'};
end
end


function value = exportSummaryValue(lastExport)
if ~isfield(lastExport, 'status') || strcmp(lastExport.status, 'not-exported')
    value = 'Not exported.';
elseif strcmp(lastExport.status, 'pass')
    value = lastExport.output_path;
else
    value = ['Error: ' lastExport.message];
end
end


function value = htmlEscape(text)
value = string(text);
value = replace(value, '&', '&amp;');
value = replace(value, '<', '&lt;');
value = replace(value, '>', '&gt;');
value = replace(value, '"', '&quot;');
value = replace(value, '''', '&#39;');
end


function filters = exportFileFilters(format)
switch format
    case "png"
        filters = {'*.png', 'PNG image (*.png)'};
    case "jpg"
        filters = {'*.jpg;*.jpeg', 'JPEG image (*.jpg, *.jpeg)'};
    case "tif"
        filters = {'*.tif;*.tiff', 'TIFF image (*.tif, *.tiff)'};
    case "bmp"
        filters = {'*.bmp', 'BMP image (*.bmp)'};
    case "pdf"
        filters = {'*.pdf', 'PDF document (*.pdf)'};
    case "svg"
        filters = {'*.svg', 'SVG document (*.svg)'};
    otherwise
        filters = {'*.*', 'All files'};
end
end
