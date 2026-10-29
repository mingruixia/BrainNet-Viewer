classdef VisualizationSettingsAccordion < handle
    %VISUALIZATIONSETTINGSACCORDION Embedded single-open settings editor.

    properties (SetAccess = private)
        Parent
        Grid
        ContainerGrid
        ActiveCategory (1, 1) string = "layout"
    end

    properties (Access = private)
        Settings (1, 1) brainnet.core.VisualizationSettings
        ApplyCallback (1, 1) function_handle = @(settings) []
        ResetCallback (1, 1) function_handle = @() []
        SurfaceContext (1, 1) function_handle = @() []
        NodeContext (1, 1) function_handle = @() []
        ColorPicker (1, 1) function_handle = @uisetcolor
        FocusReturnCallback (1, 1) function_handle = @() []
        EdgeCustomDraft struct = struct
        EdgeCustomLoadButton = []
        EdgeCustomBindButton = []
        EdgeCustomStatus = []
        BoundaryDraft struct = struct
        BoundaryThresholdField = []
        BoundaryLoadButton = []
        BoundaryBindButton = []
        BoundaryStatus = []
        Categories (1, :) string = ...
            ["layout", "global", "surface", "nodes", "edges", "volume"]
        CategoryLabels (1, :) string = ...
            ["Layout", "Global", "Surface", "Nodes", "Edges", "Volume / ROI"]
        HeaderButtons (1, :) cell = {}
        ContentPanels (1, :) cell = {}
        ContentHeights (1, :) double = [180 504 518 801 999 1023]
        LayoutPresetDropDown = []
        ViewDirectionDropDown = []
        AzimuthField = []
        ElevationField = []
        ColorPreview = []
        ShadingDropDown = []
        LightingDropDown = []
        LightDirectionDropDown = []
        OrientationLabelsCheckBox = []
        ImageColorbarCheckBox = []
        ImageColorbarLocationDropDown = []
        ImageColorbarLabelField = []
        ImageTitleField = []
        RenderDetailDropDown = []
        MaterialProfileDropDown = []
        MaterialAmbientField = []
        MaterialDiffuseField = []
        MaterialSpecularField = []
        SurfaceColorModeDropDown = []
        SurfaceColorButton = []
        SurfaceOpacitySlider = []
        DoubleBrainCheckBox = []
        VertexRgbStatus = []
        SurfaceColormapField = []
        SurfaceLimitsField = []
        SurfaceColorbarCheckBox = []
        SurfaceBoundaryDropDown = []
        SurfaceBoundaryColorButton = []
        NodeSelectionDropDown = []
        NodeSelectionBasisDropDown = []
        NodeThresholdField = []
        NodeLabelModeDropDown = []
        NodeLabelBasisDropDown = []
        NodeLabelThresholdField = []
        NodeFontNameField = []
        NodeFontSizeField = []
        NodeFontWeightDropDown = []
        NodeFontAngleDropDown = []
        NodeFontUnitsDropDown = []
        NodeLabelColorButton = []
        NodeLabelFrontCheckBox = []
        NodeSizeModeDropDown = []
        NodeSizeBasisDropDown = []
        NodeSizeField = []
        NodeSizeScaleField = []
        NodeSizeThresholdField = []
        NodeColorModeDropDown = []
        NodeColorButton = []
        NodeColormapField = []
        NodeColorLimitsField = []
        NodeColorThresholdField = []
        NodeColorLowButton = []
        NodeSizeThresholdBasisDropDown = []
        NodeColorHighButton = []
        EdgeSelectionDropDown = []
        EdgeThresholdField = []
        EdgeSparsityField = []
        EdgeValueModeDropDown = []
        EdgeDirectedCheckBox = []
        EdgeArrowLengthField = []
        EdgeArrowWidthField = []
        EdgeInterHemisphereCheckBox = []
        EdgeSizeModeDropDown = []
        EdgeSizeField = []
        EdgeSizeScaleField = []
        EdgeSizeThresholdField = []
        EdgeSizeThresholdBasisDropDown = []
        EdgeSizeValueModeDropDown = []
        EdgeColorModeDropDown = []
        EdgeColorButton = []
        EdgeColorLowButton = []
        EdgeColorHighButton = []
        EdgeInterModuleColorButton = []
        EdgeThresholdValueModeDropDown = []
        EdgeMappedValueModeDropDown = []
        EdgeColormapField = []
        EdgeColorLimitsField = []
        EdgeColorThresholdField = []
        EdgeLengthThresholdField = []
        EdgeOpacityModeDropDown = []
        EdgeOpacityValueModeDropDown = []
        EdgeOpacityField = []
        EdgeOpacityRangeField = []
        VolumeDisplayCheckBox = []
        VolumeTypeDropDown = []
        VolumeMapAlgorithmDropDown = []
        VolumeThresholdModeDropDown = []
        VolumeThresholdField = []
        VolumePValueField = []
        VolumeClusterSizeField = []
        VolumeConnectivityDropDown = []
        VolumePositiveRangeField = []
        VolumeNegativeRangeField = []
        VolumeAutoRangeButton = []
        VolumeColormapField = []
        VolumeNullColorButton = []
        VolumeSignDropDown = []
        VolumeAdjustNullCheckBox = []
        RoiDrawAllCheckBox = []
        RoiSelectionField = []
        RoiColorModeDropDown = []
        RoiPaletteDropDown = []
        RoiLegendCheckBox = []
        RoiColorButton = []
        RoiColorsField = []
        RoiColorsLoadButton = []
        RoiSmoothingDropDown = []
        RoiKernelField = []
        Theme (1, 1) string = "light"
        PaletteEditor = []
    end

    methods
        function obj = VisualizationSettingsAccordion(parent, settings, options)
            arguments
                parent
                settings (1, 1) brainnet.core.VisualizationSettings
                options.ApplyCallback (1, 1) function_handle = @(settings) []
                options.ResetCallback (1, 1) function_handle = @() []
                options.SurfaceContext (1, 1) function_handle = @() []
                options.NodeContext (1, 1) function_handle = @() []
                options.ColorPicker (1, 1) function_handle = @uisetcolor
                options.FocusReturnCallback (1, 1) function_handle = @() []
            end
            obj.Parent = parent;
            obj.Settings = settings;
            obj.ApplyCallback = options.ApplyCallback;
            obj.ResetCallback = options.ResetCallback;
            obj.SurfaceContext = options.SurfaceContext;
            obj.NodeContext = options.NodeContext;
            obj.ColorPicker = options.ColorPicker;
            obj.FocusReturnCallback = options.FocusReturnCallback;
            obj.createComponents();
            obj.writeControls();
            obj.selectCategory("layout");
        end

        function loadBoundaryMask(obj, path, confirmed)
            if nargin<3 || ~isequal(confirmed,true)
                error('BNV:Boundary:ConfirmationRequired','Confirm the original surface vertex order.');
            end
            obj.stageBoundaryMask(brainnet.io.readBoundaryMask(path),string(path));
        end

        function bindBoundaryMask(obj, confirmed)
            if nargin<2 || ~isequal(confirmed,true)
                error('BNV:Boundary:ConfirmationRequired','Confirm the original surface vertex order.');
            end
            obj.stageBoundaryMask(obj.BoundaryDraft.boundary_mask,string(obj.BoundaryDraft.boundary_mask_source));
        end

        function replaceSettings(obj, settings)
            arguments
                obj (1, 1) brainnet.app.VisualizationSettingsAccordion
                settings (1, 1) brainnet.core.VisualizationSettings
            end
            obj.closeColormapEditor();
            obj.Settings = settings;
            obj.writeControls();
        end

        function loadCustomEdgeColors(obj,path,confirmed)
            if ~isequal(confirmed,true), error('BNV:EdgeCustom:Confirmation','Confirm the original node order.'); end
            [data,map]=brainnet.io.readEdgeColors(path,getMapField(obj.EdgeColormapField));
            data=brainnet.core.CustomEdgeColors.bind(data,obj.NodeContext(),true);
            obj.EdgeCustomDraft=data; setMapField(obj.EdgeColormapField,map);
            obj.EdgeColorModeDropDown.Value='custom'; obj.updateConditionalControls();
        end

        function bindCustomEdgeColors(obj,confirmed)
            obj.EdgeCustomDraft=brainnet.core.CustomEdgeColors.bind(obj.EdgeCustomDraft,obj.NodeContext(),confirmed);
            obj.updateConditionalControls();
        end

        function loadVertexColors(obj,path,confirmed)
            if nargin<3, confirmed=false; end
            if ~isequal(confirmed,true), error('BNV:VertexColors:ConfirmationRequired','Confirm the original surface vertex order.'); end
            obj.stageVertexColors(brainnet.io.readVertexColors(path),confirmed,string(path));
        end

        function bindVertexColors(obj,confirmed)
            if nargin<2, confirmed=false; end
            obj.stageVertexColors(obj.BoundaryDraft.vertex_colors,confirmed, ...
                string(obj.BoundaryDraft.vertex_colors_source));
        end

        function selectCategory(obj, category)
            arguments
                obj (1, 1) brainnet.app.VisualizationSettingsAccordion
                category (1, 1) string
            end
            category = lower(category);
            index = find(obj.Categories == category, 1);
            if isempty(index)
                error('BNV:App:UnknownSettingsCategory', ...
                    'Unknown visualization settings category: %s.', category);
            end
            obj.ActiveCategory = category;
            obj.updateExpandedRows(index);
        end

        function collapseAll(obj)
            obj.ActiveCategory = "";
            obj.updateExpandedRows([]);
        end

        function editor = openColormapEditor(obj, options)
            arguments
                obj
                options.Visible (1,1) logical = true
            end
            obj.closeColormapEditor();
            fields=obj.colormapFields();
            maps=cellfun(@getMapField,fields,'UniformOutput',false);
            obj.PaletteEditor=brainnet.app.ColormapEditor(maps, ...
                @(values) obj.stageColormaps(values,maps),Visible=options.Visible, ...
                Theme=obj.Theme,Parent=obj.Parent);
            editor=obj.PaletteEditor;
        end

        function loadRoiColors(obj, path)
            table=brainnet.core.RoiColors.read(path);
            obj.RoiColorsField.Value=brainnet.core.RoiColors.format(table);
            obj.RoiColorModeDropDown.Value='custom';
            obj.updateConditionalControls();
        end

        function closeColormapEditor(obj)
            if ~isempty(obj.PaletteEditor) && isvalid(obj.PaletteEditor), delete(obj.PaletteEditor); end
            obj.PaletteEditor=[];
        end

        function delete(obj)
            obj.closeColormapEditor();
        end

        function value = snapshot(obj)
            value = struct( ...
                'active_category', char(obj.ActiveCategory), ...
                'single_open', true, ...
                'all_collapsed', strlength(obj.ActiveCategory) == 0, ...
                'scrollable', strcmp(obj.Grid.Scrollable, 'on'), ...
                'categories', {cellstr(obj.Categories)});
        end

        function value = interfaceText(obj)
            value = ["Visualization Settings", obj.CategoryLabels, ...
                "Layout Preset", "View Direction", "Custom Azimuth", ...
                "Custom Elevation", "Background Color", "Surface Shading", ...
                "Lighting Model", "Light Direction", "Surface Material", ...
                "Ambient Strength", "Diffuse Strength", "Specular Strength", ...
                "Show Orientation Labels", "Figure Annotations", ...
                "Show Colorbars", "Colorbar Location", "Colorbar Label", ...
                "Figure Title", "Surface Color Mode", ...
                "Surface Opacity", "Surface Colormap", "Surface Color Limits", ...
                "Show Surface Colorbar", "Surface Boundary", ...
                "Node Selection", "Node Labels", "Node Size", "Node Color", ...
                "Edge Selection", "Edge Value Mode", "Directed Edges", ...
                "Edge Size", "Edge Color", "Edge Opacity", "Apply", "Revert", ...
                "Display Volume", "Volume Type", "Mapping Algorithm", ...
                "Threshold Mode", "Statistical Threshold", "P Value", ...
                "Cluster Size", "Voxel Connectivity", "Positive Range", ...
                "Negative Range", "Volume Colormap", ...
                "Null Color", "Draw All ROIs", "ROI Selection", ...
                "ROI Color Mode", "ROI Color", "ROI Smoothing", ...
                "Smoothing Kernel", ...
                "Planned for the next feature-parity task."];
        end

        function setTheme(obj, theme)
            arguments
                obj (1, 1) brainnet.app.VisualizationSettingsAccordion
                theme (1, 1) string {mustBeMember(theme, ["light", "dark"])}
            end
            obj.Theme = theme;
            if theme == "dark"
                panelColor = [0.094 0.129 0.173];
                textColor = [0.92 0.95 0.98];
                headerColor = [0.125 0.173 0.235];
            else
                panelColor = [1 1 1];
                textColor = [0.086 0.137 0.227];
                headerColor = [0.94 0.96 0.985];
            end
            obj.Grid.BackgroundColor = panelColor;
            % Nested page/action grids otherwise keep a light background
            % while their labels switch to light text in the dark theme.
            grids = findall(obj.Parent, '-isa', 'matlab.ui.container.GridLayout');
            for grid = reshape(grids, 1, [])
                grid.BackgroundColor = panelColor;
            end
            checkboxes = findall(obj.Parent, '-isa', 'matlab.ui.control.CheckBox');
            for checkbox = reshape(checkboxes, 1, [])
                checkbox.FontColor = textColor;
            end
            for index = 1:numel(obj.ContentPanels)
                panel = obj.ContentPanels{index};
                if ~isempty(panel) && isvalid(panel)
                    panel.BackgroundColor = panelColor;
                end
                button = obj.HeaderButtons{index};
                button.BackgroundColor = headerColor;
                button.FontColor = textColor;
            end
            labels = findall(obj.Parent, 'Type', 'uilabel');
            for label = reshape(labels, 1, [])
                label.FontColor = textColor;
            end
            textAreas = findall(obj.Parent, 'Type', 'uitextarea');
            for area = reshape(textAreas, 1, [])
                area.BackgroundColor = panelColor;
                area.FontColor = textColor;
            end
            obj.refreshColorPreview();
        end
    end

    methods (Access = private)
        function fields=colormapFields(obj)
            fields={obj.SurfaceColormapField,obj.NodeColormapField,obj.EdgeColormapField, ...
                obj.VolumeColormapField};
        end

        function stageColormaps(obj,maps,baseline)
            fields=obj.colormapFields();
            if ~isvalid(obj.Parent)
                error('BNV:Color:EditorClosed','The settings panel is closed.');
            end
            current=cellfun(@getMapField,fields,'UniformOutput',false);
            if ~isequaln(current,baseline)
                error('BNV:Color:StaleEditor','Colormap settings changed. Reopen the editor before staging.');
            end
            maps=cellfun(@brainnet.core.Colormap.validate,maps,'UniformOutput',false);
            for i=1:numel(fields), setMapField(fields{i},maps{i}); end
        end

        function createComponents(obj)
            obj.ContainerGrid = uigridlayout(obj.Parent,[2 1]);
            obj.ContainerGrid.RowHeight = {'1x',70};
            obj.ContainerGrid.Padding = [0 0 0 0];
            obj.ContainerGrid.RowSpacing = 4;
            obj.Grid = uigridlayout(obj.ContainerGrid, [12 1]);
            obj.Grid.Layout.Row = 1;
            heights = cell(1, 12);
            heights(1:2:end) = {36};
            heights(2:2:end) = {0};
            obj.Grid.RowHeight = heights;
            obj.Grid.ColumnWidth = {'1x'};
            obj.Grid.Padding = [0 0 0 0];
            obj.Grid.RowSpacing = 3;
            obj.Grid.Scrollable = 'on';

            obj.HeaderButtons = cell(1, numel(obj.Categories));
            obj.ContentPanels = cell(1, numel(obj.Categories));
            for index = 1:numel(obj.Categories)
                button = uibutton(obj.Grid, 'push', ...
                    'Text', char(obj.CategoryLabels(index) + " >"), ...
                    'FontWeight', 'bold', ...
                    'Tag', char("SettingsCategory_" + obj.Categories(index)), ...
                    'ButtonPushedFcn', @(~, ~) obj.toggleCategory(index));
                button.Layout.Row = 2 * index - 1;
                obj.HeaderButtons{index} = button;
                panel = uipanel(obj.Grid, 'BorderType', 'none', 'Visible', 'off');
                panel.Layout.Row = 2 * index;
                obj.ContentPanels{index} = panel;
            end
            obj.createLayoutPage(obj.ContentPanels{1});
            obj.createGlobalPage(obj.ContentPanels{2});
            obj.createSurfacePage(obj.ContentPanels{3});
            obj.createNodePage(obj.ContentPanels{4});
            obj.createEdgePage(obj.ContentPanels{5});
            obj.createVolumePage(obj.ContentPanels{6});
            obj.addActionButtons(obj.ContainerGrid,2);
        end

        function createLayoutPage(obj, parent)
            grid = uigridlayout(parent, [5 2]);
            grid.RowHeight = {28, 28, 28, 28, 34};
            grid.ColumnWidth = {112, '1x'};
            grid.Padding = [8 7 8 7];
            grid.RowSpacing = 5;
            obj.addLabel(grid, 'Layout Preset', 1);
            obj.LayoutPresetDropDown = uidropdown(grid, ...
                'Items', {'Single View', 'Overview (6 / 8 Views)', ...
                'Lateral / Medial', 'Lateral / Medial / Ventral', ...
                'Lateral / Medial / Dorsal'}, 'ItemsData', 1:5);
            obj.LayoutPresetDropDown.Tag='LayoutPreset';
            obj.LayoutPresetDropDown.Layout.Row = 1;
            obj.LayoutPresetDropDown.Layout.Column = 2;
            obj.addLabel(grid, 'View Direction', 2);
            obj.ViewDirectionDropDown = uidropdown(grid, ...
                'Items', {'Left (Sagittal)', 'Superior (Axial)', ...
                'Anterior (Coronal)', 'Custom', 'Right', 'Inferior', ...
                'Posterior', 'Isometric'}, 'ItemsData', 1:8, ...
                'ValueChangedFcn', @(~, ~) obj.updateCustomFields());
            obj.ViewDirectionDropDown.Layout.Row = 2;
            obj.ViewDirectionDropDown.Layout.Column = 2;
            obj.addLabel(grid, 'Custom Azimuth', 3);
            obj.AzimuthField = uieditfield(grid, 'numeric', ...
                'Limits', [-360 360], 'ValueDisplayFormat', '%.1f degrees');
            obj.AzimuthField.Layout.Row = 3;
            obj.AzimuthField.Layout.Column = 2;
            obj.addLabel(grid, 'Custom Elevation', 4);
            obj.ElevationField = uieditfield(grid, 'numeric', ...
                'Limits', [-90 90], 'ValueDisplayFormat', '%.1f degrees');
            obj.ElevationField.Layout.Row = 4;
            obj.ElevationField.Layout.Column = 2;
            note = uilabel(grid, 'Text', ...
                'Multi-view presets use their own camera directions.', 'WordWrap', 'on');
            note.Layout.Row = 5;
            note.Layout.Column = [1 2];
        end

        function createGlobalPage(obj, parent)
            grid = uigridlayout(parent, [15 2]);
            grid.RowHeight = repmat({28},1,15);
            grid.ColumnWidth = {112, '1x'};
            grid.Padding = [8 7 8 7];
            grid.RowSpacing = 5;
            obj.addLabel(grid, 'Background Color', 1);
            obj.ColorPreview = uibutton(grid, 'push', 'Text', 'Choose Color', ...
                'ButtonPushedFcn', @(~, ~) obj.onChooseColor());
            obj.ColorPreview.Layout.Row = 1;
            obj.ColorPreview.Layout.Column = 2;
            obj.addLabel(grid, 'Surface Shading', 2);
            obj.ShadingDropDown = uidropdown(grid, ...
                'Items', {'Flat', 'Faceted', 'Interpolated'}, ...
                'ItemsData', {'flat', 'faceted', 'interp'});
            obj.ShadingDropDown.Layout.Row = 2;
            obj.ShadingDropDown.Layout.Column = 2;
            obj.addLabel(grid, 'Lighting Model', 3);
            obj.LightingDropDown = uidropdown(grid, ...
                'Items', {'None', 'Flat', 'Gouraud', 'Phong'}, ...
                'ItemsData', {'none', 'flat', 'gouraud', 'phong'});
            obj.LightingDropDown.Layout.Row = 3;
            obj.LightingDropDown.Layout.Column = 2;
            obj.addLabel(grid, 'Light Direction', 4);
            obj.LightDirectionDropDown = uidropdown(grid, ...
                'Items', {'Headlight', 'Right', 'Left'}, ...
                'ItemsData', {'headlight', 'right', 'left'});
            obj.LightDirectionDropDown.Layout.Row = 4;
            obj.LightDirectionDropDown.Layout.Column = 2;
            obj.addLabel(grid, 'Surface Material', 5);
            obj.MaterialProfileDropDown = uidropdown(grid, ...
                'Items', {'Dull', 'Shiny', 'Metal', 'Custom'}, ...
                'ItemsData', {'dull', 'shiny', 'metal', 'custom'}, ...
                'Tag', 'MaterialProfile', ...
                'ValueChangedFcn', @(~,~) obj.updateMaterialControls());
            obj.MaterialProfileDropDown.Layout.Row = 5;
            obj.MaterialProfileDropDown.Layout.Column = 2;
            obj.MaterialProfileDropDown.Tooltip = 'Custom exposes the legacy Ambient, Diffuse, and Specular strengths.';
            materialLabels={'Ambient Strength','Diffuse Strength','Specular Strength'};
            materialProperties={'MaterialAmbientField','MaterialDiffuseField','MaterialSpecularField'};
            for index=1:3
                obj.addLabel(grid,materialLabels{index},5+index);
                field=uieditfield(grid,'numeric','Limits',[0 1],'ValueDisplayFormat','%.3f', ...
                    'Tag',['Material' erase(materialLabels{index},' Strength')]);
                field.Layout.Row=5+index;
                field.Layout.Column=2;
                obj.(materialProperties{index})=field;
            end
            obj.addLabel(grid, 'Render Detail', 9);
            obj.RenderDetailDropDown = uidropdown(grid, ...
                'Items', {'Adaptive (modern)', 'Low (legacy)', 'Moderate (legacy)', 'High (legacy)'}, ...
                'ItemsData', {'adaptive', 'low', 'moderate', 'high'},'Tag','RenderDetail');
            obj.RenderDetailDropDown.Layout.Row = 9;
            obj.RenderDetailDropDown.Layout.Column = 2;
            obj.RenderDetailDropDown.Tooltip = 'Low/Moderate/High use legacy node detail 10/50/100 and edge sides 5/10/20. Adaptive preserves the modern load-aware policy.';
            obj.OrientationLabelsCheckBox = uicheckbox(grid, ...
                'Text', 'Show Orientation Labels');
            obj.OrientationLabelsCheckBox.Layout.Row = 10;
            obj.OrientationLabelsCheckBox.Tooltip = ...
                'Shows coordinate half-space labels unless anatomical X direction and the X=0 midline are explicitly confirmed in the Scene. Labels identify panes, not screen-edge directions.';
            obj.OrientationLabelsCheckBox.Layout.Column = [1 2];
            obj.addSectionLabel(grid, 'Figure Annotations', 11);
            obj.ImageColorbarCheckBox = uicheckbox(grid, ...
                'Text','Show Colorbars','Tag','ImageShowColorbar');
            obj.ImageColorbarCheckBox.Layout.Row = 12;
            obj.ImageColorbarCheckBox.Layout.Column = [1 2];
            obj.addLabel(grid,'Colorbar Location',13);
            obj.ImageColorbarLocationDropDown = obj.dropDown(grid,13, ...
                {'Eastoutside','Westoutside','Southoutside','Northoutside'}, ...
                {'eastoutside','westoutside','southoutside','northoutside'});
            obj.ImageColorbarLocationDropDown.Tag = 'ImageColorbarLocation';
            obj.addLabel(grid,'Colorbar Label',14);
            obj.ImageColorbarLabelField = obj.textField(grid,14);
            obj.ImageColorbarLabelField.Tag = 'ImageColorbarLabel';
            obj.addLabel(grid, 'Figure Title', 15);
            obj.ImageTitleField = obj.textField(grid, 15);
            obj.ImageTitleField.Tag = 'ImageTitle';
            obj.ImageTitleField.Tooltip = 'Leave empty to hide the figure title.';
        end

        function createSurfacePage(obj, parent)
            grid = obj.pageGrid(parent, 15);
            obj.addLabel(grid, 'Color Mode', 1);
            obj.SurfaceColorModeDropDown = obj.dropDown(grid, 1, ...
                {'Uniform', 'Scalar Map', 'Vertex RGB'}, {'uniform', 'scalar', 'vertex-rgb'});
            obj.SurfaceColorModeDropDown.ValueChangedFcn = ...
                @(~, ~) obj.updateConditionalControls();
            obj.addLabel(grid, 'Uniform Color', 2);
            obj.SurfaceColorButton = obj.colorButton(grid, 2, ...
                'Choose Surface Color', @(~, ~) obj.chooseColor( ...
                'surface', 'color', obj.SurfaceColorButton, 'Choose Surface Color'));
            obj.addLabel(grid, 'Opacity', 3);
            obj.SurfaceOpacitySlider = uislider(grid, ...
                'Limits', [0 1], 'MajorTicks', [0 0.25 0.5 0.75 1], ...
                'Tooltip', ['0 is transparent and 1 is opaque. New surface-only ' ...
                'and surface-plus-map/volume scenes default to 1.']);
            obj.SurfaceOpacitySlider.Tag = 'SurfaceOpacitySlider';
            obj.SurfaceOpacitySlider.Layout.Row = 3;
            obj.SurfaceOpacitySlider.Layout.Column = 2;
            grid.RowHeight{3}=42;
            obj.addLabel(grid, 'Colormap', 4);
            names=cellstr(brainnet.core.Colormap.names());
            names=names(:);
            obj.SurfaceColormapField=obj.dropDown(grid,4, ...
                [names;{'Custom (Colors...)'}],[names;{'custom'}]);
            obj.SurfaceColormapField.Tag='SurfaceColormap';
            obj.addLabel(grid, 'Color Limits', 5);
            obj.SurfaceLimitsField = obj.textField(grid, 5);
            obj.SurfaceLimitsField.Tooltip = 'Enter Auto or two values, for example -2 2.';
            obj.SurfaceColorbarCheckBox = uicheckbox(grid, ...
                'Text', 'Show Surface Colorbar');
            obj.SurfaceColorbarCheckBox.Layout.Row = 6;
            obj.SurfaceColorbarCheckBox.Layout.Column = [1 2];
            obj.addLabel(grid, 'Boundary', 7);
            obj.SurfaceBoundaryDropDown = obj.dropDown(grid, 7, ...
                {'None', 'Automatic', 'Threshold', 'Custom Mask'}, ...
                {'none', 'automatic', 'threshold', 'custom'});
            obj.SurfaceBoundaryDropDown.ValueChangedFcn = ...
                @(~, ~) obj.updateConditionalControls();
            obj.addLabel(grid, 'Boundary Color', 8);
            obj.SurfaceBoundaryColorButton = obj.colorButton(grid, 8, ...
                'Choose Boundary Color', @(~, ~) obj.chooseColor( ...
                'surface', 'boundary_color', obj.SurfaceBoundaryColorButton, ...
                'Choose Surface Boundary Color'));
            obj.addLabel(grid,'Boundary Threshold',9);
            obj.BoundaryThresholdField=obj.numericField(grid,9,[-Inf Inf],'%.4g');
            actions=uigridlayout(grid,[1 2]); actions.Layout.Row=10; actions.Layout.Column=[1 2];
            actions.Padding=[0 0 0 0]; actions.ColumnWidth={'1x','1x'};
            obj.BoundaryLoadButton=uibutton(actions,'Text','Load Mask...', ...
                'ButtonPushedFcn',@(~,~) obj.onBoundaryMask(false));
            obj.BoundaryBindButton=uibutton(actions,'Text','Bind to Surface', ...
                'ButtonPushedFcn',@(~,~) obj.onBoundaryMask(true));
            obj.BoundaryStatus=uilabel(grid,'Text','No custom mask','WordWrap','on');
            obj.BoundaryStatus.Layout.Row=11; obj.BoundaryStatus.Layout.Column=[1 2];
            note = uilabel(grid, 'Text', ...
                'Modern: lines. Other modes: vertex colors.', ...
                'WordWrap', 'on');
            note.Layout.Row = 12;
            note.Layout.Column = [1 2];
            obj.DoubleBrainCheckBox=uicheckbox(grid,'Text','Double Brain', 'Tag','DoubleBrain');
            obj.DoubleBrainCheckBox.Layout.Row=13; obj.DoubleBrainCheckBox.Layout.Column=[1 2];
            obj.DoubleBrainCheckBox.Tooltip='Single View: Left, Superior or Anterior. Copies the surface; moves the LAST half of node rows to brain 2. Requires surface, no volume/map. Source coordinates stay unchanged.';
            actions=uigridlayout(grid,[1 2]); actions.Layout.Row=14; actions.Layout.Column=[1 2];
            actions.Padding=[0 0 0 0]; actions.ColumnWidth={'1x','1x'};
            uibutton(actions,'Text','Load RGB...','Tag','LoadVertexRGB', ...
                'ButtonPushedFcn',@(~,~) obj.onVertexColors(false));
            uibutton(actions,'Text','Bind RGB','Tag','BindVertexRGB', ...
                'ButtonPushedFcn',@(~,~) obj.onVertexColors(true));
            obj.VertexRgbStatus=uilabel(grid,'Text','No vertex RGB','WordWrap','on','Tag','VertexRGBStatus');
            obj.VertexRgbStatus.Layout.Row=15; obj.VertexRgbStatus.Layout.Column=[1 2];
            obj.VertexRgbStatus.Tooltip='N RGB rows for one brain; 2N for Double Brain, first N for brain 1 and next N for brain 2. Confirm the original surface vertex order.';
        end

        function stageVertexColors(obj,rgb,confirmed,source)
            if ~isequal(confirmed,true), error('BNV:VertexColors:ConfirmationRequired','Confirm the original surface vertex order.'); end
            mesh=obj.SurfaceContext();
            patch=brainnet.core.VertexColors.bind(rgb,mesh.coordinates,mesh.faces,obj.DoubleBrainCheckBox.Value,confirmed,source);
            for field=string(fieldnames(patch))', obj.BoundaryDraft.(field)=patch.(field); end
            obj.SurfaceColorModeDropDown.Value='vertex-rgb'; obj.updateConditionalControls();
        end

        function onVertexColors(obj,bindExisting)
            parent=ancestor(obj.Grid,'figure'); path="";
            if ~bindExisting
                [file,folder]=uigetfile({'*.txt','Vertex RGB text (*.txt)'},'Load Vertex RGB');
                if isequal(file,0), return; end
                path=fullfile(folder,file);
            end
            answer=uiconfirm(parent,'Do rows follow the original surface vertex order? Double Brain requires brain 1 rows followed by brain 2 rows. Binding cannot verify this initial correspondence.', ...
                'Confirm Vertex RGB Order','Options',{'Confirm','Cancel'},'DefaultOption',2,'CancelOption',2);
            if ~strcmp(answer,'Confirm'), return; end
            try
                if bindExisting, obj.bindVertexColors(true); else, obj.loadVertexColors(path,true); end
            catch failure
                uialert(parent,failure.message,'Vertex RGB');
            end
        end

        function stageBoundaryMask(obj,mask,source)
            surface=obj.SurfaceContext();
            if isempty(surface)
                error('BNV:Boundary:LoadSurface','Load a surface before binding a mask.');
            end
            patch=brainnet.core.BoundaryMask.bind(mask,surface.coordinates,surface.faces,source);
            names=fieldnames(patch);
            for k=1:numel(names), obj.BoundaryDraft.(names{k})=patch.(names{k}); end
            obj.SurfaceBoundaryDropDown.Value='custom';
            obj.updateConditionalControls();
        end

        function onBoundaryMask(obj,bindExisting)
            parent=ancestor(obj.Grid,'figure'); path="";
            if ~bindExisting
                [file,folder]=uigetfile({'*.txt','Binary vertex mask (*.txt)'},'Load Boundary Mask');
                if isequal(file,0), return; end
                path=fullfile(folder,file);
            end
            answer=uiconfirm(parent, ...
                'Does this mask follow the original vertex order of the loaded surface? Binding cannot verify the initial correspondence.', ...
                'Confirm Vertex Order','Options',{'Confirm','Cancel'},'DefaultOption',2,'CancelOption',2);
            if ~strcmp(answer,'Confirm'), return; end
            try
                if bindExisting, obj.bindBoundaryMask(true); else, obj.loadBoundaryMask(path,true); end
            catch exception
                uialert(parent,exception.message,'Boundary Mask');
            end
        end

        function onCustomEdgeColors(obj,bindExisting)
            parent=ancestor(obj.Grid,'figure'); path="";
            if ~bindExisting
                [file,folder]=uigetfile({'*.txt;*.edge;*.json','Color matrix or category/RGB JSON'},'Load Custom Edge Colors');
                if isequal(file,0), return; end
                path=fullfile(folder,file);
            end
            answer=uiconfirm(parent,'Do matrix rows and columns follow the original loaded node order? Binding cannot verify initial anatomical correspondence.', ...
                'Confirm Node Order','Options',{'Confirm','Cancel'},'DefaultOption',2,'CancelOption',2);
            if ~strcmp(answer,'Confirm'), return; end
            try
                if bindExisting, obj.bindCustomEdgeColors(true); else, obj.loadCustomEdgeColors(path,true); end
            catch exception
                uialert(parent,exception.message,'Custom Edge Colors');
            end
        end

        function createNodePage(obj, parent)
            grid = obj.pageGrid(parent, 24);
            obj.addSectionLabel(grid, 'Visibility', 1);
            obj.addLabel(grid, 'Selection', 2);
            obj.NodeSelectionDropDown = obj.dropDown(grid, 2, ...
                {'All Nodes', 'Threshold', 'Connected Nodes'}, ...
                {'all', 'threshold', 'connected'});
            obj.NodeSelectionDropDown.ValueChangedFcn = ...
                @(~, ~) obj.updateConditionalControls();
            obj.addLabel(grid, 'Selection Basis', 3);
            obj.NodeSelectionBasisDropDown = obj.dropDown(grid, 3, ...
                {'Node Value', 'Module'}, {'value', 'module'});
            obj.addLabel(grid, 'Threshold', 4);
            obj.NodeThresholdField = obj.numericField(grid, 4, [-inf inf], '%.4g');
            obj.NodeSelectionDropDown.Tag='NodeSelection';
            obj.NodeSelectionBasisDropDown.Tag='NodeSelectionBasis';
            obj.NodeThresholdField.Tag='NodeSelectionThreshold';
            obj.NodeSelectionDropDown.Tooltip='Threshold uses strict >. Connected uses either endpoint of selected edges, after edge filtering; isolated nodes are hidden.';
            obj.NodeSelectionBasisDropDown.Tooltip='Node Value: original column 5. Module: original column 4. Size mapping and Scale do not affect selection.';
            obj.NodeThresholdField.Tooltip='Show nodes whose original basis value is strictly greater than this threshold; equality is excluded.';

            obj.addSectionLabel(grid, 'Labels', 5);
            obj.addLabel(grid, 'Label Mode', 6);
            obj.NodeLabelModeDropDown = obj.dropDown(grid, 6, ...
                {'All Labels', 'No Labels', 'Threshold'}, ...
                {'all', 'none', 'threshold'});
            obj.NodeLabelModeDropDown.ValueChangedFcn = ...
                @(~, ~) obj.updateConditionalControls();
            obj.addLabel(grid, 'Label Basis', 7);
            obj.NodeLabelBasisDropDown = obj.dropDown(grid, 7, ...
                {'Node Value', 'Module'}, {'value', 'module'});
            obj.addLabel(grid, 'Label Threshold', 8);
            obj.NodeLabelThresholdField = obj.numericField(grid, 8, [-inf inf], '%.4g');
            obj.NodeLabelModeDropDown.Tag='NodeLabelMode';
            obj.NodeLabelBasisDropDown.Tag='NodeLabelBasis';
            obj.NodeLabelThresholdField.Tag='NodeLabelThreshold';
            obj.NodeLabelModeDropDown.Tooltip='Labels apply only to visible, nonzero-radius nodes. A single dash (-) is a no-label marker; hyphenated names remain valid.';
            obj.NodeLabelBasisDropDown.Tooltip='Node Value: original column 5. Module: original column 4. Label and node-selection thresholds are independent.';
            obj.NodeLabelThresholdField.Tooltip='Show labels only when the original basis value is strictly greater than this threshold; equality is excluded.';
            obj.addLabel(grid, 'Font', 9);
            obj.NodeFontNameField = obj.textField(grid, 9);
            obj.addLabel(grid, 'Font Size', 10);
            obj.NodeFontSizeField = obj.numericField(grid, 10, [eps 100], '%.4g');
            obj.addLabel(grid, 'Label Color', 11);
            obj.NodeLabelColorButton = obj.colorButton(grid, 11, ...
                'Choose Label Color', @(~, ~) obj.chooseColor( ...
                'node', 'label_color', obj.NodeLabelColorButton, 'Choose Node Label Color'));
            obj.NodeLabelFrontCheckBox = uicheckbox(grid, 'Text', 'Keep Labels in Front');
            obj.NodeLabelFrontCheckBox.Layout.Row = 12;
            obj.NodeLabelFrontCheckBox.Layout.Column = [1 2];

            obj.addSectionLabel(grid, 'Size', 13);
            obj.addLabel(grid, 'Size Mode', 14);
            obj.NodeSizeModeDropDown = obj.dropDown(grid, 14, ...
                {'Uniform', 'Mapped', 'Raw', 'Threshold'}, {'uniform', 'mapped', 'raw', 'threshold'});
            obj.NodeSizeModeDropDown.ValueChangedFcn = ...
                @(~, ~) obj.updateConditionalControls();
            obj.addLabel(grid, 'Size Source', 15);
            obj.NodeSizeBasisDropDown = obj.dropDown(grid, 15, ...
                {'Node Value', 'Module'}, {'value', 'module'});
            obj.addLabel(grid, 'Base Size / Scale', 16);
            sizeGrid = uigridlayout(grid, [1 2]);
            sizeGrid.Layout.Row = 16;
            sizeGrid.Layout.Column = 2;
            sizeGrid.ColumnWidth = {'1x', '1x'};
            sizeGrid.Padding = [0 0 0 0];
            obj.NodeSizeField = uieditfield(sizeGrid, 'numeric', ...
                'Limits', [eps inf], 'ValueDisplayFormat', '%.3g');
            obj.NodeSizeScaleField = uieditfield(sizeGrid, 'numeric', ...
                'Limits', [eps inf], 'ValueDisplayFormat', '%.3g');
            obj.addLabel(grid, 'Size Threshold', 17);
            thresholdSizeGrid=uigridlayout(grid,[1 2]);
            thresholdSizeGrid.Layout.Row=17; thresholdSizeGrid.Layout.Column=2;
            thresholdSizeGrid.ColumnWidth={'1x','1x'}; thresholdSizeGrid.Padding=[0 0 0 0];
            obj.NodeSizeThresholdBasisDropDown=uidropdown(thresholdSizeGrid, ...
                'Items',{'Mapped','Raw'},'ItemsData',{'mapped','raw'},'Tag','NodeSizeThresholdBasis');
            obj.NodeSizeThresholdField=uieditfield(thresholdSizeGrid,'numeric', ...
                'Limits',[-inf inf],'ValueDisplayFormat','%.4g');
            obj.NodeSizeModeDropDown.Tag='NodeSizeMode';
            obj.NodeSizeModeDropDown.Tooltip='Raw uses unnormalized source values as radii. All modes apply Scale once.';
            obj.NodeSizeBasisDropDown.Tooltip='Node Value: file column 5. Module: column 4 (modern-only size extension).';
            obj.NodeSizeScaleField.Tooltip='Multiplier applied once after uniform, mapping or threshold processing.';
            obj.NodeSizeThresholdField.Tooltip='Mapped or Raw radius below this value becomes 1; equality is retained. Scale is applied afterward.';

            obj.addSectionLabel(grid, 'Color', 18);
            obj.addLabel(grid, 'Color Mode', 19);
            obj.NodeColorModeDropDown = obj.dropDown(grid, 19, ...
                {'Uniform', 'Mapped', 'Modules', 'Threshold'}, ...
                {'uniform', 'mapped', 'modular', 'threshold'});
            obj.NodeColorModeDropDown.ValueChangedFcn = ...
                @(~, ~) obj.updateConditionalControls();
            colorGrid = uigridlayout(grid, [1 3]);
            colorGrid.Layout.Row = 20;
            colorGrid.Layout.Column = [1 2];
            colorGrid.ColumnWidth = {'1x', '1x', '1x'};
            colorGrid.Padding = [0 0 0 0];
            obj.NodeColorButton = uibutton(colorGrid, 'push', 'Text', 'Color', ...
                'ButtonPushedFcn', @(~, ~) obj.chooseColor( ...
                'node', 'color', obj.NodeColorButton, 'Choose Node Color'));
            names=cellstr(brainnet.core.Colormap.names());
            names=names(:);
            obj.NodeColormapField=uidropdown(colorGrid, ...
                'Items',[names;{'Custom (Colors...)'}], ...
                'ItemsData',[names;{'custom'}],'Tag','NodeColormap');
            obj.NodeColormapField.Tooltip = ['Mapped colors use node column 4, not size column 5. ' ...
                'Modules also use this palette by module ID; use Colors... for a custom RGB palette.'];
            obj.NodeColorLimitsField = uieditfield(colorGrid, 'text', 'Placeholder', 'Auto / low high');
            thresholdGrid = uigridlayout(grid, [1 2]);
            thresholdGrid.Layout.Row = 21;
            thresholdGrid.Layout.Column = [1 2];
            thresholdGrid.ColumnWidth = {112, '1x'};
            thresholdGrid.Padding = [0 0 0 0];
            uilabel(thresholdGrid, 'Text', 'Color Threshold');
            obj.NodeColorThresholdField = uieditfield(thresholdGrid, 'numeric', ...
                'Limits', [-inf inf], 'ValueDisplayFormat', '%.4g');
            obj.NodeColorThresholdField.Tooltip='Column 4 > threshold: High. Column 4 <= threshold: Low.';
            pairGrid=uigridlayout(grid,[1 2]); pairGrid.Layout.Row=22; pairGrid.Layout.Column=[1 2];
            pairGrid.ColumnWidth={'1x','1x'}; pairGrid.Padding=[0 0 0 0];
            obj.NodeColorLowButton=uibutton(pairGrid,'Text','Low (<=)', 'Tag','NodeColorLow', ...
                'ButtonPushedFcn',@(~,~) obj.chooseColor('node','color_low',obj.NodeColorLowButton,'Choose Low Node Color'));
            obj.NodeColorHighButton=uibutton(pairGrid,'Text','High (>)', 'Tag','NodeColorHigh', ...
                'ButtonPushedFcn',@(~,~) obj.chooseColor('node','color_high',obj.NodeColorHighButton,'Choose High Node Color'));
            % Insert typography rows directly below font size; keep later controls ordered.
            for child=reshape(grid.Children,1,[])
                if child.Layout.Row(1)>=11, child.Layout.Row=child.Layout.Row+2; end
            end
            obj.addLabel(grid,'Font Style',11);
            style=uigridlayout(grid,[1 2]); style.Layout.Row=11; style.Layout.Column=2;
            style.ColumnWidth={'1x','1x'}; style.Padding=[0 0 0 0];
            obj.NodeFontWeightDropDown=uidropdown(style,'Items',{'Normal','Bold'},'ItemsData',{'normal','bold'},'Tag','NodeFontWeight');
            obj.NodeFontAngleDropDown=uidropdown(style,'Items',{'Normal','Italic'},'ItemsData',{'normal','italic'},'Tag','NodeFontAngle');
            obj.addLabel(grid,'Font Units',12);
            obj.NodeFontUnitsDropDown=obj.dropDown(grid,12,{'Points','Pixels','Normalized','Inches','Centimeters'}, ...
                {'points','pixels','normalized','inches','centimeters'});
            obj.NodeFontUnitsDropDown.Tag='NodeFontUnits';
        end

        function createEdgePage(obj, parent)
            grid = obj.pageGrid(parent, 30);
            obj.addSectionLabel(grid, 'Visibility', 1);
            obj.addLabel(grid, 'Selection', 2);
            obj.EdgeSelectionDropDown = obj.dropDown(grid, 2, ...
                {'All Edges', 'Threshold', 'Sparsity (Top Count)'}, ...
                {'all', 'threshold', 'sparsity'});
            obj.EdgeSelectionDropDown.Tag='EdgeSelection';
            obj.EdgeSelectionDropDown.Tooltip='Sparsity ranks nonzero candidates and retains the requested top count.';
            obj.EdgeSelectionDropDown.ValueChangedFcn = ...
                @(~, ~) obj.updateConditionalControls();
            obj.addLabel(grid, 'Threshold', 3);
            obj.EdgeThresholdField = obj.numericField(grid, 3, [-inf inf], '%.4g');
            obj.addLabel(grid, 'Sparsity', 4);
            obj.EdgeSparsityField = obj.numericField(grid, 4, [0 1], '%.3f');
            obj.EdgeSparsityField.Tag='EdgeSparsity';
            obj.EdgeSparsityField.Tooltip='Fraction 0 to 1 of eligible nonzero edges.';
            obj.addLabel(grid, 'Selection Values', 5);
            obj.EdgeValueModeDropDown = obj.dropDown(grid, 5, ...
                {'Signed', 'Absolute'}, {'signed', 'absolute'});
            obj.EdgeDirectedCheckBox = uicheckbox(grid, 'Text', 'Directed Edges', ...
                'ValueChangedFcn',@(~,~) obj.updateConditionalControls());
            obj.EdgeDirectedCheckBox.Layout.Row = 6;
            obj.EdgeDirectedCheckBox.Layout.Column = 1;
            obj.EdgeInterHemisphereCheckBox = uicheckbox(grid,'Text','Inter Hemi Only','Tag','EdgeInterHemisphere');
            obj.EdgeInterHemisphereCheckBox.Layout.Row = 6;
            obj.EdgeInterHemisphereCheckBox.Layout.Column = 2;
            obj.EdgeInterHemisphereCheckBox.Tooltip = 'Keep opposite-side or midline endpoints using node x=0. Applied after selection; does not infer anatomical hemispheres.';

            obj.addSectionLabel(grid, 'Size', 7);
            obj.addLabel(grid, 'Size Mode', 8);
            obj.EdgeSizeModeDropDown = obj.dropDown(grid, 8, ...
                {'Uniform', 'Mapped', 'Raw', 'Threshold'}, {'uniform', 'mapped', 'raw', 'threshold'});
            obj.EdgeSizeModeDropDown.ValueChangedFcn = ...
                @(~, ~) obj.updateConditionalControls();
            obj.addLabel(grid, 'Base Size', 9);
            obj.EdgeSizeField = obj.numericField(grid, 9, [eps inf], '%.3g');
            obj.addLabel(grid, 'Size Scale', 10);
            obj.EdgeSizeScaleField = obj.numericField(grid, 10, [eps inf], '%.3g');
            obj.addLabel(grid, 'Size Threshold', 11);
            obj.EdgeSizeThresholdField = obj.numericField(grid, 11, [-inf inf], '%.4g');

            obj.EdgeSizeModeDropDown.Tag='EdgeSizeMode';
            obj.EdgeSizeField.Tag='EdgeSize';
            obj.EdgeSizeScaleField.Tag='EdgeSizeScale';
            obj.EdgeSizeThresholdField.Tag='EdgeSizeThreshold';
            obj.EdgeSizeThresholdField.Tooltip='Test original Signed/Absolute weights first (>=). Mapped normalizes only the retained subset; Raw caps at 6. Below threshold uses radius 0.4, then Size Scale applies.';
            obj.EdgeSizeField.Tooltip='Uniform radius in input coordinate units, multiplied by Size Scale.';
            obj.addLabel(grid,'Size Values',12);
            obj.EdgeSizeValueModeDropDown=obj.dropDown(grid,12,{'Signed','Absolute'},{'signed','absolute'});
            obj.EdgeSizeValueModeDropDown.Tag='EdgeSizeValueMode';
            obj.EdgeSizeValueModeDropDown.Tooltip='Independent of Selection Values, color and opacity. Raw clamps to [0.2,6] before scaling; Raw Threshold has different limits.';
            obj.addLabel(grid,'Threshold Basis',13);
            obj.EdgeSizeThresholdBasisDropDown=obj.dropDown(grid,13,{'Mapped','Raw'},{'mapped','raw'});
            obj.EdgeSizeThresholdBasisDropDown.Tag='EdgeSizeThresholdBasis';

            obj.addSectionLabel(grid, 'Color', 14);
            obj.addLabel(grid, 'Color Mode', 15);
            obj.EdgeColorModeDropDown = obj.dropDown(grid, 15, ...
                {'Uniform', 'Mapped', 'Threshold', 'Length', 'Node Module', 'Custom Matrix'}, ...
                {'uniform', 'mapped', 'threshold', 'length', 'node-module', 'custom'});
            obj.EdgeColorModeDropDown.ValueChangedFcn = ...
                @(~, ~) obj.updateConditionalControls();
            obj.EdgeColorModeDropDown.Tag = 'EdgeColorMode';
            colorGrid = uigridlayout(grid, [1 3]);
            colorGrid.Layout.Row = 16;
            colorGrid.Layout.Column = [1 2];
            colorGrid.ColumnWidth = {'1x', '1x', '1x'};
            colorGrid.Padding = [0 0 0 0];
            obj.EdgeColorButton = uibutton(colorGrid, 'push', 'Text', 'Color', ...
                'ButtonPushedFcn', @(~, ~) obj.chooseColor( ...
                'edge', 'color', obj.EdgeColorButton, 'Choose Edge Color'));
            names=cellstr(brainnet.core.Colormap.names());
            names=names(:);
            obj.EdgeColormapField = uidropdown(colorGrid, ...
                'Items',[names;{'Custom (Colors...)'}], ...
                'ItemsData',[names;{'custom'}],'Tag','EdgeColormap');
            obj.EdgeColorLimitsField = uieditfield(colorGrid, 'text', 'Placeholder', 'Auto / low high');
            obj.EdgeColormapField.Tooltip='Mapped and Custom Matrix modes use this palette. Node Module edges inherit the Node colormap; set Node Color Mode to Modules to match visible node colors.';
            obj.EdgeColorLimitsField.Tag='EdgeColorLimits';
            obj.EdgeColorLimitsField.Tooltip='Empty: range of selected color weights after sign handling. Or enter lower upper limits; equal limits use the last color.';
            obj.addLabel(grid, 'Color Threshold', 17);
            obj.EdgeColorThresholdField = obj.numericField(grid, 17, [-inf inf], '%.4g');
            obj.EdgeColorThresholdField.Tag = 'EdgeColorThreshold';
            obj.EdgeColorThresholdField.Tooltip = 'High color when the original signed or absolute edge weight is strictly greater than this threshold.';
            obj.addLabel(grid, 'Length Threshold', 18);
            obj.EdgeLengthThresholdField = obj.numericField(grid, 18, [0 inf], '%.4g');
            obj.EdgeLengthThresholdField.Tag = 'EdgeLengthThreshold';
            obj.EdgeLengthThresholdField.Tooltip = 'High color at or above this Euclidean distance between original node coordinates, in their coordinate units.';
            obj.addLabel(grid, 'Threshold Values', 19);
            obj.EdgeThresholdValueModeDropDown = obj.dropDown(grid, 19, ...
                {'Signed', 'Absolute'}, {'signed', 'absolute'});
            obj.EdgeThresholdValueModeDropDown.Tag = 'EdgeThresholdValueMode';
            obj.EdgeThresholdValueModeDropDown.Tooltip = 'Only for Threshold coloring. Independent of edge selection Value Mode, size, opacity and Length coloring.';
            obj.addLabel(grid,'Mapped Values',20);
            obj.EdgeMappedValueModeDropDown=obj.dropDown(grid,20,{'Signed','Absolute'},{'signed','absolute'});
            obj.EdgeMappedValueModeDropDown.Tag='EdgeMappedValueMode';
            obj.EdgeMappedValueModeDropDown.Tooltip='Only for Mapped coloring, before Auto/Fixed range mapping to 64 colors. Independent of selection, size and Threshold coloring.';
            pairGrid=uigridlayout(grid,[1 2]); pairGrid.Layout.Row=21; pairGrid.Layout.Column=[1 2];
            pairGrid.Padding=[0 0 0 0]; pairGrid.ColumnWidth={'1x','1x'};
            obj.EdgeColorLowButton=uibutton(pairGrid,'Text','Low (<=)','Tag','EdgeColorLow', ...
                'ButtonPushedFcn',@(~,~) obj.chooseColor('edge','color_low',obj.EdgeColorLowButton,'Choose Low Edge Color'));
            obj.EdgeColorHighButton=uibutton(pairGrid,'Text','High (>)','Tag','EdgeColorHigh', ...
                'ButtonPushedFcn',@(~,~) obj.chooseColor('edge','color_high',obj.EdgeColorHighButton,'Choose High Edge Color'));

            obj.addLabel(grid,'Inter-module Color',22);
            obj.EdgeInterModuleColorButton=uibutton(grid,'Text','Choose','Tag','EdgeInterModuleColor', ...
                'ButtonPushedFcn',@(~,~) obj.chooseColor('edge','inter_module_color',obj.EdgeInterModuleColorButton,'Choose Inter-module Color'));
            obj.EdgeInterModuleColorButton.Layout.Row=22; obj.EdgeInterModuleColorButton.Layout.Column=2;
            obj.EdgeInterModuleColorButton.Tooltip='Node Module mode: distinct endpoint modules use this color. Same-module edges inherit Node module colors.';
            actions=uigridlayout(grid,[1 2]); actions.Layout.Row=23; actions.Layout.Column=[1 2];
            actions.Padding=[0 0 0 0]; actions.ColumnWidth={'1x','1x'};
            obj.EdgeCustomLoadButton=uibutton(actions,'Text','Load Colors...','Tag','EdgeCustomLoad', ...
                'ButtonPushedFcn',@(~,~) obj.onCustomEdgeColors(false));
            obj.EdgeCustomBindButton=uibutton(actions,'Text','Bind to Nodes','Tag','EdgeCustomBind', ...
                'ButtonPushedFcn',@(~,~) obj.onCustomEdgeColors(true));
            obj.EdgeCustomStatus=uilabel(grid,'Text','No custom color matrix','Tag','EdgeCustomStatus');
            obj.EdgeCustomStatus.Layout.Row=24; obj.EdgeCustomStatus.Layout.Column=[1 2];
            obj.addSectionLabel(grid, 'Opacity', 25);
            obj.addLabel(grid, 'Opacity Mode', 26);
            obj.EdgeOpacityModeDropDown = obj.dropDown(grid, 26, ...
                {'Uniform', 'Mapped'}, {'uniform', 'mapped'});
            obj.EdgeOpacityModeDropDown.ValueChangedFcn = ...
                @(~, ~) obj.updateConditionalControls();
            obj.EdgeOpacityModeDropDown.Tag='EdgeOpacityMode';
            opacityGrid = uigridlayout(grid, [1 3]);
            opacityGrid.Layout.Row = 27;
            opacityGrid.Layout.Column = [1 2];
            opacityGrid.ColumnWidth = {76, '1x', '1x'};
            opacityGrid.Padding = [0 0 0 0];
            uilabel(opacityGrid, 'Text', 'Value / Range');
            obj.EdgeOpacityField = uieditfield(opacityGrid, 'numeric', ...
                'Limits', [0 1], 'ValueDisplayFormat', '%.2f');
            obj.EdgeOpacityRangeField = uieditfield(opacityGrid, 'text', ...
                'Placeholder', 'low high');
            obj.EdgeOpacityRangeField.Tag='EdgeOpacityRange';
            obj.EdgeOpacityRangeField.Tooltip='Output opacity range in [0,1], not input-weight limits. 0 is transparent; 1 is opaque. Constant weights use the upper opacity.';
            obj.addLabel(grid,'Opacity Values',28);
            obj.EdgeOpacityValueModeDropDown=obj.dropDown(grid,28,{'Signed','Absolute'},{'signed','absolute'});
            obj.EdgeOpacityValueModeDropDown.Tag='EdgeOpacityValueMode';
            obj.EdgeOpacityValueModeDropDown.Tooltip='Mapped opacity only; independent of selection, size and color signs.';
            obj.addSectionLabel(grid,'Arrowhead Shape',29);
            arrowGrid=uigridlayout(grid,[1 4]);
            arrowGrid.Layout.Row=30; arrowGrid.Layout.Column=[1 2];
            arrowGrid.ColumnWidth={54,'1x',48,'1x'}; arrowGrid.Padding=[0 0 0 0];
            uilabel(arrowGrid,'Text','Length');
            obj.EdgeArrowLengthField=uieditfield(arrowGrid,'numeric','Limits',[0.25 3], ...
                'ValueDisplayFormat','%.2f','Tag','EdgeArrowLength');
            uilabel(arrowGrid,'Text','Width');
            obj.EdgeArrowWidthField=uieditfield(arrowGrid,'numeric','Limits',[0.25 3], ...
                'ValueDisplayFormat','%.2f','Tag','EdgeArrowWidth');
            obj.EdgeArrowLengthField.Tooltip='Arrowhead length multiplier (0.25-3); capped to 35% of edge length.';
            obj.EdgeArrowWidthField.Tooltip='Arrowhead width multiplier (0.25-3).';
        end

        function createVolumePage(obj, parent)
            grid = obj.pageGrid(parent, 29);
            obj.VolumeDisplayCheckBox = uicheckbox(grid, ...
                'Text', 'Display Volume', ...
                'ValueChangedFcn', @(~, ~) obj.updateConditionalControls());
            obj.VolumeDisplayCheckBox.Layout.Row = 1;
            obj.VolumeDisplayCheckBox.Layout.Column = [1 2];
            obj.addLabel(grid, 'Volume Type', 2);
            obj.VolumeTypeDropDown = obj.dropDown(grid, 2, ...
                {'Surface Map', 'ROIs (Atlas / Statistical)'}, {'surface-map', 'roi'});
            obj.VolumeTypeDropDown.Tag = 'VolumeType';
            obj.VolumeTypeDropDown.ValueChangedFcn = ...
                @(~, ~) obj.updateConditionalControls();

            % Shared threshold controls precede the Surface Map-only group.
            obj.addLabel(grid, 'Threshold Mode', 3);
            obj.VolumeThresholdModeDropDown = obj.dropDown(grid, 3, ...
                {'None', 'Value', 'P Value', 'Cluster'}, ...
                {'none', 'value', 'p-value', 'cluster'});
            obj.VolumeThresholdModeDropDown.ValueChangedFcn = ...
                @(~, ~) obj.updateConditionalControls();
            obj.VolumeThresholdModeDropDown.Tooltip = ...
                'P Value converts SPM/REST/DPABI or NIfTI-intent T/F/R/Z maps to an uncorrected statistic cutoff. ROI mode also filters by Cluster Size.';
            obj.VolumeThresholdModeDropDown.Tag = 'VolumeThresholdMode';
            obj.addLabel(grid, 'Statistical Threshold', 4);
            obj.VolumeThresholdField = obj.numericField(grid, 4, [-inf inf], '%.4g');
            obj.VolumeThresholdField.Tag = 'VolumeStatisticalThreshold';
            obj.addLabel(grid, 'P Value (Uncorrected)', 5);
            obj.VolumePValueField = obj.numericField(grid, 5, [0 1], '%.4g');
            obj.VolumePValueField.Tag = 'VolumePValue';
            obj.addLabel(grid, 'Cluster Size', 6);
            obj.VolumeClusterSizeField = obj.numericField(grid, 6, [0 inf], '%.0f');
            obj.VolumeClusterSizeField.Tag = 'VolumeClusterSize';
            obj.addLabel(grid, 'Voxel Connectivity', 7);
            obj.VolumeConnectivityDropDown = obj.dropDown(grid, 7, ...
                {'6 Neighbors', '18 Neighbors', '26 Neighbors'}, [6 18 26]);
            obj.VolumeConnectivityDropDown.Tag = 'VolumeConnectivity';
            obj.addSectionLabel(grid, 'Surface Mapping', 8);
            obj.addLabel(grid, 'Mapping Algorithm', 9);
            obj.VolumeMapAlgorithmDropDown = obj.dropDown(grid, 9, ...
                {'1 - Nearest Voxel', '2 - Average Surface Neighbors', ...
                '3 - Average 3-by-3 Voxel Neighborhood', ...
                '4 - Gaussian Voxel Smoothing', ...
                '5 - Trilinear Interpolation', ...
                '6 - Maximum 3-by-3 Voxel Neighborhood', ...
                '7 - Minimum 3-by-3 Voxel Neighborhood', ...
                '8 - Extremum 3-by-3 Voxel Neighborhood'}, 1:8);
            obj.VolumeMapAlgorithmDropDown.Tag = 'VolumeMapAlgorithm';
            obj.addLabel(grid, 'Positive Range', 10);
            obj.VolumePositiveRangeField = obj.textField(grid, 10);
            obj.VolumePositiveRangeField.Tooltip = ...
                'Enter Auto or minimum and maximum; either bound may be Auto. Manual bounds persist when the volume file changes.';
            obj.VolumePositiveRangeField.Tag='VolumePositiveRange';
            obj.addLabel(grid, 'Negative Range', 11);
            obj.VolumeNegativeRangeField = obj.textField(grid, 11);
            obj.VolumeNegativeRangeField.Tooltip = ...
                'Enter Auto or minimum and maximum; either bound may be Auto. Manual bounds persist when the volume file changes.';
            obj.VolumeNegativeRangeField.Tag='VolumeNegativeRange';
            obj.addLabel(grid, 'Colormap', 12);
            names=brainnet.core.Colormap.names();
            obj.VolumeColormapField=obj.dropDown(grid,12, ...
                cellstr(["Blue-White-Red",upper(names(2:end)),"Custom RGB"]), ...
                cellstr([names,"custom"]));
            obj.VolumeColormapField.Tag='VolumeColormap';
            obj.VolumeColormapField.Tooltip='One palette: its lower half colors negative values and upper half colors positive values. Use Colors... for custom RGB.';
            rangeRow=uigridlayout(grid,[1 2]);
            rangeRow.Layout.Row=13; rangeRow.Layout.Column=[1 2];
            rangeRow.ColumnWidth={'1x',104}; rangeRow.Padding=[0 0 0 0];
            hint=uilabel(rangeRow,'Text','- Lower | + Upper','FontSize',11);
            hint.Tooltip='The lower half of the selected colormap represents negative values; the upper half represents positive values.';
            obj.VolumeAutoRangeButton=uibutton(rangeRow,'push','Text','Auto Ranges', ...
                'Tag','VolumeAutoRanges', ...
                'ButtonPushedFcn',@(~,~) obj.resetVolumeRanges());
            obj.VolumeAutoRangeButton.Tooltip= ...
                'Set both pending ranges to Auto; click Apply to commit and render.';
            obj.addLabel(grid, 'Null Color', 14);
            obj.VolumeNullColorButton = obj.colorButton(grid, 14, ...
                'Choose Null Color', @(~, ~) obj.chooseColor( ...
                'volume', 'null_color', obj.VolumeNullColorButton, 'Choose Null Color'));

            obj.addLabel(grid, 'Display Values', 15);
            obj.VolumeSignDropDown = obj.dropDown(grid,15, ...
                {'Positive & Negative','Positive Only','Negative Only'}, {'both','positive','negative'});
            obj.VolumeSignDropDown.Tag = 'VolumeDisplayMode';
            obj.VolumeSignDropDown.Tooltip = 'Color-axis selection, not data filtering. Out-of-range values clamp to the palette endpoints.';
            obj.VolumeAdjustNullCheckBox = uicheckbox(grid,'Text','Adjust for Null', ...
                'Tag','VolumeAdjustNull','Value',true, ...
                'ValueChangedFcn',@(~,~) obj.updateConditionalControls());
            obj.VolumeAdjustNullCheckBox.Layout.Row = 16;
            obj.VolumeAdjustNullCheckBox.Layout.Column = [1 2];
            obj.addSectionLabel(grid, 'Atlas / Statistical ROIs', 17);
            obj.RoiDrawAllCheckBox = uicheckbox(grid, ...
                'Text', 'Draw All ROIs', ...
                'ValueChangedFcn', @(~, ~) obj.updateConditionalControls());
            obj.RoiDrawAllCheckBox.Layout.Row = 18;
            obj.RoiDrawAllCheckBox.Layout.Column = [1 2];
            obj.addLabel(grid, 'ROI Selection', 19);
            obj.RoiSelectionField = obj.textField(grid, 19);
            obj.RoiSelectionField.Tag='RoiSelection';
            obj.RoiSelectionField.ValueChangedFcn = @(~,~) obj.onRoiSelectionChanged();
            obj.RoiSelectionField.Tooltip = ...
                'Turn off Draw All ROIs to enter IDs separated by spaces or commas.';
            obj.addLabel(grid, 'ROI Color Mode', 20);
            obj.RoiColorModeDropDown = obj.dropDown(grid, 20, ...
                {'Uniform', 'Label Index', 'Custom'}, ...
                {'uniform', 'index', 'custom'});
            obj.RoiColorModeDropDown.ValueChangedFcn = ...
                @(~, ~) obj.updateConditionalControls();
            obj.RoiColorModeDropDown.Tooltip = ...
                ['Label Index uses the selected categorical palette, cycling by ROI ID. ' ...
                 'A labelled ROI legend can be shown below; Custom provides exact ID / RGB colors.'];
            obj.addLabel(grid, 'ROI Palette', 21);
            names=cellstr(brainnet.core.Colormap.names());
            obj.RoiPaletteDropDown=obj.dropDown(grid,21,names,names);
            obj.RoiPaletteDropDown.Tag='RoiPalette';
            obj.RoiLegendCheckBox=uicheckbox(grid,'Text','Show ROI ID Legend', ...
                'Tag','RoiLegend');
            obj.RoiLegendCheckBox.Layout.Row=22;
            obj.RoiLegendCheckBox.Layout.Column=[1 2];
            obj.RoiLegendCheckBox.Tooltip='Categorical ROI ID and color key; not a continuous colorbar.';
            obj.addLabel(grid, 'ROI Color', 23);
            obj.RoiColorButton = obj.colorButton(grid, 23, ...
                'Choose ROI Color', @(~, ~) obj.chooseColor( ...
                'roi', 'color', obj.RoiColorButton, 'Choose ROI Color'));
            obj.addLabel(grid, 'ROI Smoothing', 24);
            obj.RoiSmoothingDropDown = obj.dropDown(grid, 24, ...
                {'None', 'Box', 'Gaussian'}, {'none', 'box', 'gaussian'});
            obj.RoiSmoothingDropDown.Tooltip = ...
                'Gaussian with kernel 3 is the default for new scenes. Tiny components are preserved.';
            obj.RoiSmoothingDropDown.ValueChangedFcn = ...
                @(~, ~) obj.updateConditionalControls();
            obj.addLabel(grid, 'Smoothing Kernel', 25);
            obj.RoiKernelField = obj.numericField(grid, 25, [1 inf], '%.0f');
            obj.RoiKernelField.Tooltip = ...
                'Odd voxel kernel size; 1 disables smoothing. Larger kernels can soften ROI boundaries further.';
            note = uilabel(grid, 'Text', ...
                'P Value creates statistical ROI IDs from supported NIfTI metadata. Review ROI Selection and Custom colors after threshold or Cluster Size changes.', ...
                'WordWrap', 'on');
            note.Layout.Row = 26;
            note.Layout.Column = [1 2];
            obj.RoiColorsLoadButton=uibutton(grid,'Text','Load ROI Colors...', ...
                'Tag','RoiColorsLoad','ButtonPushedFcn',@(~,~) obj.chooseRoiColors());
            obj.RoiColorsLoadButton.Layout.Row=27; obj.RoiColorsLoadButton.Layout.Column=[1 2];
            obj.RoiColorsField=uitextarea(grid,'Tag','RoiCustomColors','Value',{''});
            obj.RoiColorsField.Layout.Row=28; obj.RoiColorsField.Layout.Column=[1 2];
            obj.RoiColorsField.Tooltip='One row per ROI: ID R G B. Unique positive integer IDs; RGB in [0,1]. No header. Shared Apply/Revert.';
            hint=uilabel(grid,'Text','ROI_ID R G B (0-1)','FontSize',11);
            hint.Layout.Row=29; hint.Layout.Column=[1 2];
            % Remove implicit rows added by automatic placement of spanning controls.
            grid.RowHeight=[repmat({28},1,27),{85,28}];
        end

        function createPlannedPage(~, parent)
            grid = uigridlayout(parent, [1 1]);
            grid.Padding = [8 8 8 8];
            uilabel(grid, ...
                'Text', 'Planned for the next feature-parity task.', ...
                'WordWrap', 'on');
        end

        function grid = pageGrid(~, parent, rowCount)
            grid = uigridlayout(parent, [rowCount 2]);
            grid.RowHeight = repmat({28}, 1, rowCount);
            grid.ColumnWidth = {112, '1x'};
            grid.Padding = [8 7 8 7];
            grid.RowSpacing = 5;
        end

        function control = dropDown(~, grid, row, items, values)
            control = uidropdown(grid, 'Items', items, 'ItemsData', values);
            control.Layout.Row = row;
            control.Layout.Column = 2;
        end

        function control = numericField(~, grid, row, limits, format)
            control = uieditfield(grid, 'numeric', 'Limits', limits, ...
                'ValueDisplayFormat', format);
            control.Layout.Row = row;
            control.Layout.Column = 2;
        end

        function control = textField(~, grid, row)
            control = uieditfield(grid, 'text');
            control.Layout.Row = row;
            control.Layout.Column = 2;
        end

        function control = colorButton(~, grid, row, textValue, callback)
            control = uibutton(grid, 'push', 'Text', textValue, ...
                'ButtonPushedFcn', callback);
            control.Layout.Row = row;
            control.Layout.Column = 2;
        end

        function addActionButtons(obj, grid, row)
            actions = uigridlayout(grid, [2 2]);
            actions.Layout.Row = row;
            actions.Layout.Column = 1;
            actions.RowHeight = {28,28};
            actions.RowSpacing = 4;
            actions.ColumnWidth = {'1x', '1x'};
            actions.Padding = [4 5 4 5];
            reset=uibutton(actions,'push','Text','Restore Defaults...','Tag','SettingsRestoreDefaults', ...
                'Tooltip','Confirm replacing all display settings and pending edits. Inputs and export preferences are kept.', ...
                'ButtonPushedFcn',@(~,~) obj.ResetCallback());
            reset.Layout.Row=1; reset.Layout.Column=[1 2];
            revert=uibutton(actions, 'push', 'Text', 'Revert', 'Tag', 'SettingsRevert', ...
                'Tooltip', 'Discard pending changes in all settings sections', ...
                'ButtonPushedFcn', @(~, ~) obj.writeControls());
            revert.Layout.Row=2; revert.Layout.Column=1;
            apply = uibutton(actions, 'push', 'Text', 'Apply', 'Tag', 'SettingsApply', ...
                'Interruptible', 'off', 'BusyAction', 'cancel', ...
                'Tooltip', 'Apply pending changes from all settings sections', ...
                'ButtonPushedFcn', @(~, ~) obj.onApply());
            apply.Layout.Row=2; apply.Layout.Column=2;
            apply.BackgroundColor = [0.035 0.412 0.855];
            apply.FontColor = [1 1 1];
        end

        function addLabel(~, grid, textValue, row)
            label = uilabel(grid, 'Text', textValue);
            label.Layout.Row = row;
            label.Layout.Column = 1;
        end

        function addSectionLabel(~, grid, textValue, row)
            label = uilabel(grid, 'Text', textValue, 'FontWeight', 'bold');
            label.Layout.Row = row;
            label.Layout.Column = [1 2];
        end

        function toggleCategory(obj, index)
            if obj.ActiveCategory == obj.Categories(index)
                obj.collapseAll();
            else
                obj.selectCategory(obj.Categories(index));
            end
        end

        function updateExpandedRows(obj, activeIndex)
            heights = obj.Grid.RowHeight;
            for index = 1:numel(obj.Categories)
                open = ~isempty(activeIndex) && index == activeIndex;
                obj.ContentPanels{index}.Visible = onOff(open);
                if open
                    heights{2 * index} = obj.ContentHeights(index);
                    obj.HeaderButtons{index}.Text = char(obj.CategoryLabels(index) + " v");
                else
                    heights{2 * index} = 0;
                    obj.HeaderButtons{index}.Text = char(obj.CategoryLabels(index) + " >");
                end
            end
            obj.Grid.RowHeight = heights;
            drawnow limitrate;
        end

        function writeControls(obj)
            layout = obj.Settings.section("layout");
            globalSettings = obj.Settings.section("global");
            image = obj.Settings.section("image");
            surface = obj.Settings.section("surface");
            node = obj.Settings.section("node");
            edge = obj.Settings.section("edge");
            volume = obj.Settings.section("volume");
            roi = obj.Settings.section("roi");
            obj.LayoutPresetDropDown.Value = layout.preset;
            obj.ViewDirectionDropDown.Value = layout.view_direction;
            if isempty(layout.custom_azimuth)
                obj.AzimuthField.Value = -90;
                obj.ElevationField.Value = 0;
            else
                obj.AzimuthField.Value = layout.custom_azimuth;
                obj.ElevationField.Value = layout.custom_elevation;
            end
            obj.ColorPreview.BackgroundColor = globalSettings.background_color;
            obj.ShadingDropDown.Value = char(globalSettings.shading);
            obj.LightingDropDown.Value = char(globalSettings.lighting);
            obj.LightDirectionDropDown.Value = char(globalSettings.light_direction);
            obj.RenderDetailDropDown.Value = char(globalSettings.render_detail);
            obj.MaterialProfileDropDown.Value=char(globalSettings.material_profile);
            obj.MaterialAmbientField.Value=globalSettings.material_coefficients(1);
            obj.MaterialDiffuseField.Value=globalSettings.material_coefficients(2);
            obj.MaterialSpecularField.Value=globalSettings.material_coefficients(3);
            obj.OrientationLabelsCheckBox.Value = globalSettings.show_orientation_labels;
            obj.ImageColorbarCheckBox.Value = image.show_colorbar;
            obj.ImageColorbarLocationDropDown.Value = char(image.colorbar_location);
            obj.ImageColorbarLabelField.Value = char(image.colorbar_label);
            obj.ImageTitleField.Value = char(image.title);
            surfaceColorMode = string(surface.color_mode);
            obj.SurfaceColorModeDropDown.Value = char(surfaceColorMode);
            obj.SurfaceColorButton.BackgroundColor = surface.color;
            obj.SurfaceOpacitySlider.Value = surface.opacity;
            obj.DoubleBrainCheckBox.Value = surface.double_brain;
            setMapField(obj.SurfaceColormapField,surface.colormap);
            obj.SurfaceLimitsField.Value = obj.formatLimits(surface.color_limits);
            obj.SurfaceColorbarCheckBox.Value = surface.show_colorbar;
            boundaryMode=string(surface.boundary_mode);
            if boundaryMode=="legacy-automatic", boundaryMode="automatic"; end
            obj.SurfaceBoundaryDropDown.Value = char(boundaryMode);
            obj.BoundaryDraft=surface;
            obj.BoundaryThresholdField.Value=surface.boundary_threshold;
            obj.SurfaceBoundaryColorButton.BackgroundColor = surface.boundary_color;

            obj.NodeSelectionDropDown.Value = char(node.selection_mode);
            obj.NodeSelectionBasisDropDown.Value = char(node.selection_basis);
            obj.NodeThresholdField.Value = node.threshold;
            obj.NodeLabelModeDropDown.Value = char(node.label_mode);
            obj.NodeLabelBasisDropDown.Value = char(node.label_basis);
            obj.NodeLabelThresholdField.Value = node.label_threshold;
            obj.NodeFontNameField.Value = char(node.label_font_name);
            obj.NodeFontSizeField.Value = node.label_font_size;
            obj.NodeFontWeightDropDown.Value=node.label_font_weight;
            obj.NodeFontAngleDropDown.Value=node.label_font_angle;
            obj.NodeFontUnitsDropDown.Value=node.label_font_units;
            obj.NodeLabelColorButton.BackgroundColor = node.label_color;
            obj.NodeLabelFrontCheckBox.Value = node.label_in_front;
            obj.NodeSizeModeDropDown.Value = char(node.size_mode);
            obj.NodeSizeBasisDropDown.Value = char(node.size_basis);
            obj.NodeSizeField.Value = node.size;
            obj.NodeSizeScaleField.Value = node.size_scale;
            obj.NodeSizeThresholdField.Value = node.size_threshold;
            obj.NodeSizeThresholdBasisDropDown.Value = char(node.size_threshold_basis);
            nodeColorMode = string(node.color_mode);
            if nodeColorMode == "custom"
                nodeColorMode = "modular";
            end
            obj.NodeColorModeDropDown.Value = char(nodeColorMode);
            obj.NodeColorButton.BackgroundColor = node.color;
            setMapField(obj.NodeColormapField,node.colormap);
            obj.NodeColorLimitsField.Value = obj.formatLimits(node.color_limits);
            obj.NodeColorThresholdField.Value = node.color_threshold;
            obj.NodeColorLowButton.BackgroundColor = node.color_low;
            obj.NodeColorHighButton.BackgroundColor = node.color_high;

            obj.EdgeSelectionDropDown.Value = char(edge.selection_mode);
            obj.EdgeThresholdField.Value = edge.threshold;
            obj.EdgeSparsityField.Value = edge.sparsity;
            obj.EdgeValueModeDropDown.Value = char(edge.value_mode);
            obj.EdgeDirectedCheckBox.Value = edge.directed;
            % MATLAB can retain a pre-update VisualizationSettings class in
            % an existing desktop session after files change on disk.
            if isfield(edge,'arrow_length_scale')
                obj.EdgeArrowLengthField.Value = edge.arrow_length_scale;
            else
                obj.EdgeArrowLengthField.Value = 1;
            end
            if isfield(edge,'arrow_width_scale')
                obj.EdgeArrowWidthField.Value = edge.arrow_width_scale;
            else
                obj.EdgeArrowWidthField.Value = 1;
            end
            obj.EdgeInterHemisphereCheckBox.Value = edge.inter_hemisphere_only;
            obj.EdgeSizeModeDropDown.Value = char(edge.size_mode);
            obj.EdgeSizeField.Value = edge.size;
            obj.EdgeSizeScaleField.Value = edge.size_scale;
            obj.EdgeSizeThresholdField.Value = edge.size_threshold;
            obj.EdgeSizeThresholdBasisDropDown.Value = char(edge.size_threshold_basis);
            obj.EdgeSizeValueModeDropDown.Value = char(edge.size_value_mode);
            edgeColorMode = string(edge.color_mode);
            obj.EdgeCustomDraft=edge.custom_color;
            obj.EdgeColorModeDropDown.Value = char(edgeColorMode);
            obj.EdgeColorButton.BackgroundColor = edge.color;
            setMapField(obj.EdgeColormapField,edge.colormap);
            obj.EdgeColorLimitsField.Value = obj.formatLimits(edge.color_limits);
            obj.EdgeColorThresholdField.Value = edge.color_threshold;
            obj.EdgeLengthThresholdField.Value = edge.length_threshold;
            obj.EdgeThresholdValueModeDropDown.Value = edge.threshold_value_mode;
            obj.EdgeMappedValueModeDropDown.Value = edge.mapped_value_mode;
            obj.EdgeColorLowButton.BackgroundColor = edge.color_low;
            obj.EdgeColorHighButton.BackgroundColor = edge.color_high;
            obj.EdgeInterModuleColorButton.BackgroundColor = edge.inter_module_color;
            obj.EdgeOpacityModeDropDown.Value = char(edge.opacity_mode);
            obj.EdgeOpacityValueModeDropDown.Value = edge.opacity_value_mode;
            obj.EdgeOpacityField.Value = edge.opacity;
            obj.EdgeOpacityRangeField.Value = obj.formatLimits(edge.opacity_range);

            obj.VolumeDisplayCheckBox.Value = volume.display;
            obj.VolumeTypeDropDown.Value = char(volume.type);
            obj.VolumeMapAlgorithmDropDown.Value = volume.map_algorithm;
            obj.VolumeThresholdModeDropDown.Value = char(volume.threshold_mode);
            obj.VolumeThresholdField.Value = volume.statistical_threshold;
            obj.VolumePValueField.Value = volume.p_value;
            obj.VolumeClusterSizeField.Value = volume.cluster_size;
            obj.VolumeConnectivityDropDown.Value = volume.voxel_connectivity;
            obj.VolumePositiveRangeField.Value = obj.formatOptionalPair( ...
                volume.positive_minimum, volume.positive_maximum);
            obj.VolumeNegativeRangeField.Value = obj.formatOptionalPair( ...
                volume.negative_minimum, volume.negative_maximum);
            setMapField(obj.VolumeColormapField,volume.colormap);
            obj.VolumeNullColorButton.BackgroundColor = volume.null_color;
            obj.VolumeSignDropDown.Value = char(volume.display_mode);
            obj.VolumeAdjustNullCheckBox.Value = volume.adjust_null;
            obj.RoiDrawAllCheckBox.Value = roi.draw_all;
            obj.RoiSelectionField.Value = obj.formatIntegerList(roi.selection);
            obj.RoiColorModeDropDown.Value = char(roi.color_mode);
            obj.RoiPaletteDropDown.Value = char(roi.palette);
            obj.RoiLegendCheckBox.Value = roi.show_legend;
            obj.RoiColorButton.BackgroundColor = roi.color;
            obj.RoiColorsField.Value=brainnet.core.RoiColors.format(roi.custom_colors);
            obj.RoiSmoothingDropDown.Value = char(roi.smoothing);
            obj.RoiKernelField.Value = roi.smoothing_kernel;
            obj.updateCustomFields();
            obj.refreshColorPreview();
            obj.refreshSectionColorButtons();
            obj.updateMaterialControls();
            obj.updateConditionalControls();
        end

        function settings = readControls(obj)
            direction = obj.ViewDirectionDropDown.Value;
            if direction == 4
                azimuth = obj.AzimuthField.Value;
                elevation = obj.ElevationField.Value;
            else
                azimuth = [];
                elevation = [];
            end
            [positiveMinimum, positiveMaximum] = obj.parseOptionalPair( ...
                obj.VolumePositiveRangeField.Value);
            [negativeMinimum, negativeMaximum] = obj.parseOptionalPair( ...
                obj.VolumeNegativeRangeField.Value);
            patch = struct( ...
                'layout', struct('preset', obj.LayoutPresetDropDown.Value, ...
                    'view_direction', direction, ...
                    'custom_azimuth', azimuth, ...
                    'custom_elevation', elevation), ...
                'global', struct( ...
                    'background_color', obj.ColorPreview.BackgroundColor, ...
                    'shading', obj.ShadingDropDown.Value, ...
                    'lighting', obj.LightingDropDown.Value, ...
                    'light_direction', obj.LightDirectionDropDown.Value, ...
                    'render_detail', obj.RenderDetailDropDown.Value, ...
                    'material_profile', obj.MaterialProfileDropDown.Value, ...
                    'material_coefficients', [obj.MaterialAmbientField.Value obj.MaterialDiffuseField.Value obj.MaterialSpecularField.Value], ...
                    'show_orientation_labels', ...
                    logical(obj.OrientationLabelsCheckBox.Value)), ...
                'image', struct( ...
                    'show_colorbar',logical(obj.ImageColorbarCheckBox.Value), ...
                    'colorbar_location',obj.ImageColorbarLocationDropDown.Value, ...
                    'colorbar_label',obj.ImageColorbarLabelField.Value, ...
                    'title', obj.ImageTitleField.Value), ...
                'surface', struct( ...
                    'vertex_colors',obj.BoundaryDraft.vertex_colors, ...
                    'vertex_colors_mesh_sha256',obj.BoundaryDraft.vertex_colors_mesh_sha256, ...
                    'vertex_colors_source',obj.BoundaryDraft.vertex_colors_source, ...
                    'double_brain',logical(obj.DoubleBrainCheckBox.Value), ...
                    'color_mode', obj.SurfaceColorModeDropDown.Value, ...
                    'color', obj.SurfaceColorButton.BackgroundColor, ...
                    'opacity', obj.SurfaceOpacitySlider.Value, ...
                    'colormap', getMapField(obj.SurfaceColormapField), ...
                    'color_limits', obj.parseLimits(obj.SurfaceLimitsField.Value, true), ...
                    'show_colorbar', logical(obj.SurfaceColorbarCheckBox.Value), ...
                    'boundary_mode', obj.SurfaceBoundaryDropDown.Value, ...
                    'boundary_threshold', obj.BoundaryThresholdField.Value, ...
                    'boundary_mask', obj.BoundaryDraft.boundary_mask, ...
                    'boundary_mesh_sha256', obj.BoundaryDraft.boundary_mesh_sha256, ...
                    'boundary_mask_source', obj.BoundaryDraft.boundary_mask_source, ...
                    'boundary_color', obj.SurfaceBoundaryColorButton.BackgroundColor), ...
                'node', struct( ...
                    'selection_mode', obj.NodeSelectionDropDown.Value, ...
                    'selection_basis', obj.NodeSelectionBasisDropDown.Value, ...
                    'threshold', obj.NodeThresholdField.Value, ...
                    'label_mode', obj.NodeLabelModeDropDown.Value, ...
                    'label_basis', obj.NodeLabelBasisDropDown.Value, ...
                    'label_threshold', obj.NodeLabelThresholdField.Value, ...
                    'label_font_name', obj.NodeFontNameField.Value, ...
                    'label_font_size', obj.NodeFontSizeField.Value, ...
                    'label_font_weight', obj.NodeFontWeightDropDown.Value, ...
                    'label_font_angle', obj.NodeFontAngleDropDown.Value, ...
                    'label_font_units', obj.NodeFontUnitsDropDown.Value, ...
                    'label_color', obj.NodeLabelColorButton.BackgroundColor, ...
                    'label_in_front', logical(obj.NodeLabelFrontCheckBox.Value), ...
                    'size_mode', obj.NodeSizeModeDropDown.Value, ...
                    'size_basis', obj.NodeSizeBasisDropDown.Value, ...
                    'size', obj.NodeSizeField.Value, ...
                    'size_scale', obj.NodeSizeScaleField.Value, ...
                    'size_threshold', obj.NodeSizeThresholdField.Value, ...
                    'size_threshold_basis', obj.NodeSizeThresholdBasisDropDown.Value, ...
                    'color_mode', obj.NodeColorModeDropDown.Value, ...
                    'color', obj.NodeColorButton.BackgroundColor, ...
                    'colormap', getMapField(obj.NodeColormapField), ...
                    'color_limits', obj.parseLimits(obj.NodeColorLimitsField.Value, true), ...
                    'color_threshold', obj.NodeColorThresholdField.Value, ...
                    'color_low', obj.NodeColorLowButton.BackgroundColor, ...
                    'color_high', obj.NodeColorHighButton.BackgroundColor), ...
                'edge', struct( ...
                    'selection_mode', obj.EdgeSelectionDropDown.Value, ...
                    'threshold', obj.EdgeThresholdField.Value, ...
                    'sparsity', obj.EdgeSparsityField.Value, ...
                    'value_mode', obj.EdgeValueModeDropDown.Value, ...
                    'directed', logical(obj.EdgeDirectedCheckBox.Value), ...
                    'arrow_length_scale', obj.EdgeArrowLengthField.Value, ...
                    'arrow_width_scale', obj.EdgeArrowWidthField.Value, ...
                    'inter_hemisphere_only', logical(obj.EdgeInterHemisphereCheckBox.Value), ...
                    'size_mode', obj.EdgeSizeModeDropDown.Value, ...
                    'size', obj.EdgeSizeField.Value, ...
                    'size_scale', obj.EdgeSizeScaleField.Value, ...
                    'size_threshold', obj.EdgeSizeThresholdField.Value, ...
                    'size_threshold_basis', obj.EdgeSizeThresholdBasisDropDown.Value, ...
                    'size_value_mode', obj.EdgeSizeValueModeDropDown.Value, ...
                    'color_mode', obj.EdgeColorModeDropDown.Value, ...
                    'color', obj.EdgeColorButton.BackgroundColor, ...
                    'colormap', getMapField(obj.EdgeColormapField), ...
                    'color_limits', obj.parseLimits(obj.EdgeColorLimitsField.Value, true), ...
                    'color_threshold', obj.EdgeColorThresholdField.Value, ...
                    'length_threshold', obj.EdgeLengthThresholdField.Value, ...
                    'threshold_value_mode', obj.EdgeThresholdValueModeDropDown.Value, ...
                    'mapped_value_mode', obj.EdgeMappedValueModeDropDown.Value, ...
                    'color_low', obj.EdgeColorLowButton.BackgroundColor, ...
                    'color_high', obj.EdgeColorHighButton.BackgroundColor, ...
                    'inter_module_color', obj.EdgeInterModuleColorButton.BackgroundColor, ...
                    'custom_color', obj.EdgeCustomDraft, ...
                    'opacity_mode', obj.EdgeOpacityModeDropDown.Value, ...
                    'opacity_value_mode', obj.EdgeOpacityValueModeDropDown.Value, ...
                    'opacity', obj.EdgeOpacityField.Value, ...
                    'opacity_range', obj.parseLimits(obj.EdgeOpacityRangeField.Value, false)), ...
                'volume', struct( ...
                    'display', logical(obj.VolumeDisplayCheckBox.Value), ...
                    'type', obj.VolumeTypeDropDown.Value, ...
                    'map_algorithm', obj.VolumeMapAlgorithmDropDown.Value, ...
                    'threshold_mode', obj.VolumeThresholdModeDropDown.Value, ...
                    'statistical_threshold', obj.VolumeThresholdField.Value, ...
                    'p_value', obj.VolumePValueField.Value, ...
                    'cluster_size', obj.VolumeClusterSizeField.Value, ...
                    'voxel_connectivity', obj.VolumeConnectivityDropDown.Value, ...
                    'positive_minimum', positiveMinimum, ...
                    'positive_maximum', positiveMaximum, ...
                    'negative_minimum', negativeMinimum, ...
                    'negative_maximum', negativeMaximum, ...
                    'display_mode', obj.VolumeSignDropDown.Value, ...
                    'adjust_null', logical(obj.VolumeAdjustNullCheckBox.Value), ...
                    'null_color', obj.VolumeNullColorButton.BackgroundColor, ...
                    'colormap', getMapField(obj.VolumeColormapField)), ...
                'roi', struct( ...
                    'draw_all', logical(obj.RoiDrawAllCheckBox.Value), ...
                    'selection', obj.parseIntegerList(obj.RoiSelectionField.Value), ...
                    'color_mode', obj.RoiColorModeDropDown.Value, ...
                    'palette', obj.RoiPaletteDropDown.Value, ...
                    'show_legend', logical(obj.RoiLegendCheckBox.Value), ...
                    'color', obj.RoiColorButton.BackgroundColor, ...
                    'custom_colors', brainnet.core.RoiColors.parse(obj.RoiColorsField.Value), ...
                    'smoothing', obj.RoiSmoothingDropDown.Value, ...
                    'smoothing_kernel', obj.RoiKernelField.Value));
            if patch.volume.display && string(patch.volume.type) == "surface-map"
                patch.surface.color_mode = 'scalar';
            end
            currentEdge=obj.Settings.section('edge');
            if ~isfield(currentEdge,'arrow_length_scale')
                patch.edge=rmfield(patch.edge,'arrow_length_scale');
            end
            if ~isfield(currentEdge,'arrow_width_scale')
                patch.edge=rmfield(patch.edge,'arrow_width_scale');
            end
            settings = obj.Settings.withPatch(patch);
        end

        function onApply(obj)
            try
                settings = obj.readControls();
                obj.ApplyCallback(settings);
                obj.Settings = settings;
            catch exception
                figureHandle = ancestor(obj.Parent, 'figure');
                if ~isempty(figureHandle) && strcmp(figureHandle.Visible, 'on')
                    uialert(figureHandle, exception.message, ...
                        'Invalid Visualization Settings', 'Icon', 'error');
                else
                    rethrow(exception);
                end
            end
        end

        function resetVolumeRanges(obj)
            obj.VolumePositiveRangeField.Value='Auto';
            obj.VolumeNegativeRangeField.Value='Auto';
        end

        function updateCustomFields(obj)
            enabled = obj.ViewDirectionDropDown.Value == 4;
            obj.AzimuthField.Enable = onOff(enabled);
            obj.ElevationField.Enable = onOff(enabled);
        end

        function updateMaterialControls(obj)
            enabled=string(obj.MaterialProfileDropDown.Value)=="custom";
            for field=[obj.MaterialAmbientField,obj.MaterialDiffuseField,obj.MaterialSpecularField]
                field.Enable=onOff(enabled);
            end
        end

        function updateConditionalControls(obj)
            obj.updateLayoutPresetAvailability();
            mode=string(obj.SurfaceBoundaryDropDown.Value);
            obj.BoundaryThresholdField.Enable=onOff(mode=="threshold");
            obj.BoundaryLoadButton.Enable=onOff(mode=="custom");
            obj.BoundaryBindButton.Enable=onOff(mode=="custom" && ~isempty(obj.BoundaryDraft.boundary_mask));
            if isempty(obj.BoundaryDraft.boundary_mask)
                obj.BoundaryStatus.Text='No custom mask';
            elseif isempty(obj.BoundaryDraft.boundary_mesh_sha256)
                obj.BoundaryStatus.Text=sprintf('%d vertices; binding required',numel(obj.BoundaryDraft.boundary_mask));
            else
                obj.BoundaryStatus.Text=sprintf('%d vertices; mesh %s...',numel(obj.BoundaryDraft.boundary_mask),obj.BoundaryDraft.boundary_mesh_sha256(1:8));
            end
            scalarSurface = string(obj.SurfaceColorModeDropDown.Value) == "scalar";
            obj.SurfaceColorButton.Enable = onOff(string(obj.SurfaceColorModeDropDown.Value)=="uniform");
            count=size(obj.BoundaryDraft.vertex_colors,1);
            if count==0
                obj.VertexRgbStatus.Text='No vertex RGB';
            elseif isempty(obj.BoundaryDraft.vertex_colors_mesh_sha256)
                obj.VertexRgbStatus.Text=sprintf('%d RGB rows; binding required',count);
            else
                obj.VertexRgbStatus.Text=sprintf('%d RGB rows; mesh %s...',count,obj.BoundaryDraft.vertex_colors_mesh_sha256(1:8));
            end
            obj.SurfaceColormapField.Enable = onOff(scalarSurface);
            obj.SurfaceLimitsField.Enable = onOff(scalarSurface);
            obj.SurfaceColorbarCheckBox.Enable = onOff(scalarSurface);
            obj.SurfaceBoundaryColorButton.Enable = onOff( ...
                string(obj.SurfaceBoundaryDropDown.Value) ~= "none");

            nodeSelectionThreshold = string(obj.NodeSelectionDropDown.Value) == "threshold";
            obj.NodeSelectionBasisDropDown.Enable = onOff(nodeSelectionThreshold);
            obj.NodeThresholdField.Enable = onOff(nodeSelectionThreshold);
            nodeLabels = string(obj.NodeLabelModeDropDown.Value) ~= "none";
            nodeLabelThreshold = string(obj.NodeLabelModeDropDown.Value) == "threshold";
            obj.NodeLabelBasisDropDown.Enable = onOff(nodeLabelThreshold);
            obj.NodeLabelThresholdField.Enable = onOff(nodeLabelThreshold);
            obj.NodeFontNameField.Enable = onOff(nodeLabels);
            obj.NodeFontSizeField.Enable = onOff(nodeLabels);
            obj.NodeFontWeightDropDown.Enable=onOff(nodeLabels);
            obj.NodeFontAngleDropDown.Enable=onOff(nodeLabels);
            obj.NodeFontUnitsDropDown.Enable=onOff(nodeLabels);
            obj.NodeLabelColorButton.Enable = onOff(nodeLabels);
            obj.NodeLabelFrontCheckBox.Enable = onOff(nodeLabels);
            nodeSizeMode = string(obj.NodeSizeModeDropDown.Value);
            obj.NodeSizeBasisDropDown.Enable = onOff(nodeSizeMode ~= "uniform");
            obj.NodeSizeField.Enable = onOff(nodeSizeMode == "uniform");
            obj.NodeSizeScaleField.Enable = 'on';
            obj.NodeSizeThresholdField.Enable = onOff(nodeSizeMode == "threshold");
            obj.NodeSizeThresholdBasisDropDown.Enable = onOff(nodeSizeMode == "threshold");
            nodeColorMode = string(obj.NodeColorModeDropDown.Value);
            obj.NodeColorButton.Enable = onOff(nodeColorMode == "uniform");
            obj.NodeColormapField.Enable = onOff(any(nodeColorMode == ["mapped","modular","custom"]));
            obj.NodeColorLimitsField.Enable = onOff(nodeColorMode == "mapped");
            obj.NodeColorThresholdField.Enable = onOff(nodeColorMode == "threshold");
            obj.NodeColorLowButton.Enable = onOff(nodeColorMode == "threshold");
            obj.NodeColorHighButton.Enable = onOff(nodeColorMode == "threshold");

            edgeSelectionMode = string(obj.EdgeSelectionDropDown.Value);
            obj.EdgeThresholdField.Enable = onOff(edgeSelectionMode == "threshold");
            obj.EdgeSparsityField.Enable = onOff(any(edgeSelectionMode == ["sparsity","legacy-sparsity"]));
            edgeSizeMode = string(obj.EdgeSizeModeDropDown.Value);
            obj.EdgeSizeField.Enable = onOff(edgeSizeMode == "uniform");
            obj.EdgeSizeScaleField.Enable = 'on';
            obj.EdgeSizeThresholdBasisDropDown.Enable = onOff(edgeSizeMode == "threshold");
            obj.EdgeSizeValueModeDropDown.Enable = onOff(edgeSizeMode ~= "uniform");
            obj.EdgeSizeThresholdField.Enable = onOff(edgeSizeMode == "threshold");
            edgeColorMode = string(obj.EdgeColorModeDropDown.Value);
            obj.EdgeColorButton.Enable = onOff(edgeColorMode == "uniform");
            obj.EdgeColormapField.Enable = onOff(any(edgeColorMode == ["mapped", "custom"]));
            obj.EdgeCustomLoadButton.Enable=onOff(edgeColorMode=="custom");
            obj.EdgeCustomBindButton.Enable=onOff(edgeColorMode=="custom" && ~isempty(obj.EdgeCustomDraft.matrix));
            if isempty(obj.EdgeCustomDraft.matrix)
                obj.EdgeCustomStatus.Text='No custom color matrix';
            else
                status='binding saved'; if isempty(obj.EdgeCustomDraft.node_sha256), status='binding required'; end
                obj.EdgeCustomStatus.Text=sprintf('%d nodes; %d categories; %s',size(obj.EdgeCustomDraft.matrix,1),numel(obj.EdgeCustomDraft.indices),status);
            end
            obj.EdgeColorLimitsField.Enable = onOff(edgeColorMode == "mapped");
            obj.EdgeInterModuleColorButton.Enable=onOff(edgeColorMode=="node-module");
            currentEdge=obj.Settings.section('edge');
            arrowAvailable=isfield(currentEdge,'arrow_length_scale') && ...
                isfield(currentEdge,'arrow_width_scale');
            obj.EdgeArrowLengthField.Enable=onOff(obj.EdgeDirectedCheckBox.Value && arrowAvailable);
            obj.EdgeArrowWidthField.Enable=onOff(obj.EdgeDirectedCheckBox.Value && arrowAvailable);
            if ~arrowAvailable
                obj.EdgeArrowLengthField.Tooltip='Restart MATLAB to load the updated settings class and enable arrowhead proportions.';
                obj.EdgeArrowWidthField.Tooltip=obj.EdgeArrowLengthField.Tooltip;
            end
            twoColors=any(edgeColorMode==["threshold","length"]);
            obj.EdgeColorLowButton.Enable=onOff(twoColors);
            obj.EdgeColorHighButton.Enable=onOff(twoColors);
            obj.EdgeThresholdValueModeDropDown.Enable=onOff(edgeColorMode=="threshold");
            obj.EdgeMappedValueModeDropDown.Enable=onOff(edgeColorMode=="mapped");
            if edgeColorMode=="length"
                obj.EdgeColorLowButton.Text='Short (<)'; obj.EdgeColorHighButton.Text='Long (>=)';
            else
                obj.EdgeColorLowButton.Text='Low (<=)'; obj.EdgeColorHighButton.Text='High (>)';
            end
            obj.EdgeColorThresholdField.Enable = onOff(edgeColorMode == "threshold");
            obj.EdgeLengthThresholdField.Enable = onOff(edgeColorMode == "length");
            mappedOpacity = string(obj.EdgeOpacityModeDropDown.Value) == "mapped";
            obj.EdgeOpacityField.Enable = onOff(~mappedOpacity);
            obj.EdgeOpacityRangeField.Enable = onOff(mappedOpacity);
            obj.EdgeOpacityValueModeDropDown.Enable = onOff(mappedOpacity);

            volumeEnabled = logical(obj.VolumeDisplayCheckBox.Value);
            surfaceMap = string(obj.VolumeTypeDropDown.Value) == "surface-map";
            thresholdMode = string(obj.VolumeThresholdModeDropDown.Value);
            surfaceControls = {obj.VolumeMapAlgorithmDropDown, ...
                obj.VolumePositiveRangeField, ...
                obj.VolumeNegativeRangeField, obj.VolumeAutoRangeButton, obj.VolumeColormapField, ...
                obj.VolumeNullColorButton, ...
                obj.VolumeSignDropDown, obj.VolumeAdjustNullCheckBox};
            for index = 1:numel(surfaceControls)
                surfaceControls{index}.Enable = onOff(volumeEnabled && surfaceMap);
            end
            obj.VolumeNullColorButton.Enable = 'off';
            obj.VolumeNullColorButton.Text = 'Uses Surface Color';
            obj.VolumeNullColorButton.Text = 'Uses Surface Color';
            obj.VolumeNullColorButton.Tooltip = 'Adjust Null uses the original Surface Uniform Color.';
            obj.VolumeThresholdModeDropDown.Enable = onOff(volumeEnabled);
            obj.VolumeThresholdField.Enable = onOff(volumeEnabled && ...
                any(thresholdMode == ["value", "cluster"]));
            obj.VolumePValueField.Enable = onOff(volumeEnabled && ...
                thresholdMode == "p-value");
            obj.VolumeClusterSizeField.Enable = onOff(volumeEnabled && ...
                (thresholdMode == "cluster" || (~surfaceMap && thresholdMode == "p-value")));
            obj.VolumeConnectivityDropDown.Enable = onOff(volumeEnabled && ...
                (thresholdMode == "cluster" || (~surfaceMap && ...
                any(thresholdMode == ["value", "p-value"]))));
            roiEnabled = volumeEnabled && ~surfaceMap;
            obj.RoiDrawAllCheckBox.Enable = onOff(roiEnabled);
            obj.RoiSelectionField.Enable = onOff(roiEnabled && ~obj.RoiDrawAllCheckBox.Value);
            obj.RoiColorModeDropDown.Enable = onOff(roiEnabled);
            obj.RoiPaletteDropDown.Enable = onOff(roiEnabled && ...
                string(obj.RoiColorModeDropDown.Value)=="index");
            obj.RoiLegendCheckBox.Enable = onOff(roiEnabled);
            obj.RoiColorsLoadButton.Enable=onOff(roiEnabled);
            obj.RoiColorsField.Enable=onOff(roiEnabled && string(obj.RoiColorModeDropDown.Value)=="custom");
            obj.RoiColorButton.Enable = onOff(roiEnabled && ...
                string(obj.RoiColorModeDropDown.Value) == "uniform");
            obj.RoiSmoothingDropDown.Enable = onOff(roiEnabled);
            obj.RoiKernelField.Enable = onOff(roiEnabled && ...
                string(obj.RoiSmoothingDropDown.Value) ~= "none");
        end

        function updateLayoutPresetAvailability(obj)
            % Split-hemisphere layouts are meaningful only for a surface
            % that is already represented as two disjoint coordinate halves.
            allItems={'Single View','Overview (8 Views)', ...
                'Lateral / Medial','Lateral / Medial / Ventral', ...
                'Lateral / Medial / Dorsal'};
            allData=1:5;
            canSplit=true;
            try
                surface=obj.SurfaceContext();
                if ~isempty(surface) && isfield(surface,'coordinates') && isfield(surface,'faces')
                    coordinates=double(surface.coordinates);
                    faces=double(surface.faces);
                    if size(coordinates,1)==3 && size(coordinates,2)~=3
                        coordinates=coordinates.';
                    end
                    if size(coordinates,2)~=3 || isempty(faces)
                        error('BNV:App:InvalidLayoutSurface', ...
                            'Surface coordinates or faces are invalid for layout selection.');
                    end
                    payload=struct('SurfaceCoordinates',coordinates.', ...
                        'SurfaceFaces',faces);
                    policy=brainnet.render.internal.layout2Policy(payload);
                    canSplit=strcmp(policy.mode,'eight-split');
                end
            catch failure
                if strcmp(failure.identifier,'BNV:Boundary:LoadSurface')
                    % No surface has been chosen yet.
                    return;
                end
                rethrow(failure);
            end
            if canSplit
                obj.LayoutPresetDropDown.Items=allItems;
                obj.LayoutPresetDropDown.ItemsData=allData;
                obj.LayoutPresetDropDown.Tooltip='Multi-view presets use their own camera directions.';
                return;
            end
            if ~ismember(obj.LayoutPresetDropDown.Value,[1 2])
                obj.LayoutPresetDropDown.Value=2;
            end
            obj.LayoutPresetDropDown.Items={'Single View','Overview (6 Views)'};
            obj.LayoutPresetDropDown.ItemsData=[1 2];
            obj.LayoutPresetDropDown.Tooltip=['This surface is one connected mesh. ' ...
                'Hemisphere-split presets are unavailable.'];
        end

        function onRoiSelectionChanged(obj)
            if strlength(strtrim(string(obj.RoiSelectionField.Value)))>0
                obj.RoiDrawAllCheckBox.Value=false;
            end
            obj.updateConditionalControls();
        end

        function chooseRoiColors(obj)
            [file,folder]=uigetfile({'*.txt;*.csv','ROI ID / RGB table'},'Load ROI Colors');
            if isequal(file,0), return; end
            try
                obj.loadRoiColors(fullfile(folder,file));
            catch problem
                uialert(ancestor(obj.Grid,'figure'),problem.message,'ROI Color Table');
            end
        end

        function onChooseColor(obj)
            current = obj.ColorPreview.BackgroundColor;
            selected = obj.pickColor(current, 'Choose Background Color');
            if isequal(selected, 0)
                return;
            end
            obj.ColorPreview.BackgroundColor = selected;
            obj.refreshColorPreview();
        end

        function chooseColor(obj, ~, ~, button, titleValue)
            selected = obj.pickColor(button.BackgroundColor, titleValue);
            if ~isequal(selected, 0)
                button.BackgroundColor = selected;
                setButtonContrast(button);
            end
        end

        function selected = pickColor(obj, current, titleValue)
            restoreFocus = onCleanup(@() obj.FocusReturnCallback());
            selected = obj.ColorPicker(current, titleValue);
        end

        function refreshSectionColorButtons(obj)
            buttons = {obj.SurfaceColorButton, obj.SurfaceBoundaryColorButton, ...
                obj.NodeLabelColorButton, obj.NodeColorButton, obj.NodeColorLowButton, obj.NodeColorHighButton, obj.EdgeColorButton, obj.EdgeColorLowButton, obj.EdgeColorHighButton, obj.EdgeInterModuleColorButton, ...
                obj.VolumeNullColorButton, obj.RoiColorButton};
            for index = 1:numel(buttons)
                if ~isempty(buttons{index}) && isvalid(buttons{index})
                    setButtonContrast(buttons{index});
                end
            end
        end

        function textValue = formatLimits(~, limits)
            if isempty(limits)
                textValue = 'Auto';
            else
                textValue = sprintf('%.6g %.6g', limits(1), limits(2));
            end
        end

        function limits = parseLimits(~, textValue, allowAuto)
            value = strtrim(char(string(textValue)));
            if allowAuto && (isempty(value) || strcmpi(value, 'auto'))
                limits = [];
                return;
            end
            tokens = sscanf(strrep(value, ',', ' '), '%f');
            if numel(tokens) ~= 2 || any(~isfinite(tokens)) || tokens(1) > tokens(2)
                error('BNV:App:InvalidColorLimits', ...
                    'Enter two ordered finite values%s.', ...
                    ternary(allowAuto, ' or Auto', ''));
            end
            limits = reshape(tokens, 1, 2);
        end

        function textValue = formatOptionalPair(~, first, second)
            if isempty(first) && isempty(second)
                textValue = 'Auto';
                return;
            end
            textValue = sprintf('%s %s', optionalNumber(first), optionalNumber(second));
        end

        function [first, second] = parseOptionalPair(~, textValue)
            value = strtrim(char(string(textValue)));
            if isempty(value) || strcmpi(value, 'auto')
                first = [];
                second = [];
                return;
            end
            parts = regexp(strrep(value, ',', ' '), '\\s+', 'split');
            parts = parts(~cellfun('isempty', parts));
            if numel(parts) ~= 2
                error('BNV:App:InvalidVolumeRange', ...
                    'Enter two ordered values, using Auto for an unspecified bound.');
            end
            first = optionalValue(parts{1});
            second = optionalValue(parts{2});
            if ~isempty(first) && ~isempty(second) && first > second
                error('BNV:App:InvalidVolumeRange', ...
                    'Volume range bounds must be ordered.');
            end
        end

        function textValue = formatIntegerList(~, values)
            if isempty(values)
                textValue = '';
            else
                textValue = strjoin(compose('%d', values(:).'), ' ');
            end
        end

        function values = parseIntegerList(~, textValue)
            value = strtrim(char(string(textValue)));
            if isempty(value)
                values = [];
                return;
            end
            values = sscanf(strrep(value, ',', ' '), '%f').';
            if isempty(values) || any(~isfinite(values)) || ...
                    any(values < 1) || any(values ~= fix(values))
                error('BNV:App:InvalidRoiSelection', ...
                    'ROI Selection must contain positive integer labels.');
            end
            values = unique(values, 'stable');
        end

        function refreshColorPreview(obj)
            if isempty(obj.ColorPreview) || ~isvalid(obj.ColorPreview)
                return;
            end
            color = obj.ColorPreview.BackgroundColor;
            obj.ColorPreview.BackgroundColor = color;
            if dot(color, [0.2126 0.7152 0.0722]) < 0.48
                obj.ColorPreview.FontColor = [1 1 1];
            else
                obj.ColorPreview.FontColor = [0 0 0];
            end
        end
    end
end


function value=getMapField(field)
if isa(field,'matlab.ui.control.DropDown')
    if string(field.Value)=="custom"
        value=brainnet.core.Colormap.validate(field.UserData);
    else
        value=brainnet.core.Colormap.validate(field.Value);
    end
    return;
end
if isnumeric(field.UserData) && ~isempty(field.UserData) && strcmp(field.Value,sprintf('Custom (%d colors)',size(field.UserData,1)))
    value=brainnet.core.Colormap.validate(field.UserData);
else
    value=brainnet.core.Colormap.validate(field.Value);
end
end

function setMapField(field,value)
value=brainnet.core.Colormap.validate(value);
if isa(field,'matlab.ui.control.DropDown')
    if isnumeric(value), field.UserData=value; field.Value='custom';
    else, field.UserData=[]; field.Value=value; end
    if strcmp(field.Tag,'NodeColormap')
        field.Tooltip=['Mapped values use node column 4; Modules use the same ' ...
            'palette by module ID. Use Colors... for custom RGB rows.'];
    elseif strcmp(field.Tag,'EdgeColormap')
        field.Tooltip=['Mapped and Custom Matrix modes use this palette. ' ...
            'Node Module edges inherit the Node colormap.'];
    else
        field.Tooltip='Choose a named colormap; use Colors... for custom RGB rows.';
    end
    return;
end
if isnumeric(value)
    field.UserData=value; field.Value=sprintf('Custom (%d colors)',size(value,1));
else
    field.UserData=[]; field.Value=value;
end
field.Tooltip='Named colormap, or use Colors... to edit embedded RGB rows.';
end

function value = onOff(tf)
if tf
    value = 'on';
else
    value = 'off';
end
end

function setButtonContrast(button)
color = button.BackgroundColor;
if dot(color, [0.2126 0.7152 0.0722]) < 0.48
    button.FontColor = [1 1 1];
else
    button.FontColor = [0 0 0];
end
end

function value = ternary(condition, whenTrue, whenFalse)
if condition
    value = whenTrue;
else
    value = whenFalse;
end
end

function textValue = optionalNumber(value)
if isempty(value)
    textValue = 'Auto';
else
    textValue = sprintf('%.6g', value);
end
end

function value = optionalValue(textValue)
if strcmpi(textValue, 'auto')
    value = [];
else
    value = str2double(textValue);
    if ~isscalar(value) || ~isfinite(value)
        error('BNV:App:InvalidVolumeRange', ...
            'Volume range bounds must be finite numbers or Auto.');
    end
end
end
