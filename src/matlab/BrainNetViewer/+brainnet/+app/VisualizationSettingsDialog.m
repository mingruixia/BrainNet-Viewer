classdef VisualizationSettingsDialog < handle
    %VISUALIZATIONSETTINGSDIALOG Transactional editor for settings v1.0.

    properties (SetAccess = private)
        UIFigure matlab.ui.Figure
        CommittedSettings brainnet.core.VisualizationSettings
        DraftSettings brainnet.core.VisualizationSettings
        LastAction (1, 1) string = "opened"
    end

    properties (Access = private)
        ApplyCallback function_handle = @(settings) []
        CloseCallback function_handle = @() []
        ColorPicker function_handle = @uisetcolor
        FocusReturnCallback function_handle = @() []
        TabGroup = []
        LayoutTab = []
        GlobalTab = []
        LayoutPresetDropDown = []
        ViewDirectionDropDown = []
        AzimuthField = []
        ElevationField = []
        RedField = []
        GreenField = []
        BlueField = []
        ColorPreview = []
        ShadingDropDown = []
        LightingDropDown = []
        LightDirectionDropDown = []
        OrientationLabelsCheckBox = []
        RenderDetailDropDown = []
        MaterialProfileDropDown = []
        MaterialAmbientField = []
        MaterialDiffuseField = []
        MaterialSpecularField = []
        ResetButton = []
        CancelButton = []
        ApplyButton = []
        OkButton = []
        Closed (1, 1) logical = false
    end

    methods
        function obj = VisualizationSettingsDialog(initialSettings, options)
            arguments
                initialSettings (1, 1) brainnet.core.VisualizationSettings
                options.Parent = []
                options.Visible (1, 1) logical = true
                options.ApplyCallback function_handle = @(settings) []
                options.CloseCallback function_handle = @() []
                options.ColorPicker function_handle = @uisetcolor
                options.FocusReturnCallback function_handle = @() []
            end
            obj.CommittedSettings = initialSettings;
            obj.DraftSettings = initialSettings;
            obj.ApplyCallback = options.ApplyCallback;
            obj.CloseCallback = options.CloseCallback;
            obj.ColorPicker = options.ColorPicker;
            obj.FocusReturnCallback = options.FocusReturnCallback;
            obj.createComponents(options.Parent);
            obj.writeControls(initialSettings);
            obj.UIFigure.Visible = onOff(options.Visible);
        end

        function tf = isOpen(obj)
            tf = ~obj.Closed && ~isempty(obj.UIFigure) && isvalid(obj.UIFigure);
        end

        function show(obj)
            if obj.isOpen()
                obj.UIFigure.Visible = 'on';
            end
        end

        function selectTab(obj, name)
            arguments
                obj (1, 1) brainnet.app.VisualizationSettingsDialog
                name (1, 1) string
            end
            name = lower(name);
            if ~any(name == ["layout", "global"])
                error('BNV:App:UnknownSettingsTab', ...
                    'Settings tab must be Layout or Global.');
            end
            if name == "layout"
                obj.TabGroup.SelectedTab = obj.LayoutTab;
            else
                obj.TabGroup.SelectedTab = obj.GlobalTab;
            end
        end

        function setDraft(obj, patch)
            arguments
                obj (1, 1) brainnet.app.VisualizationSettingsDialog
                patch (1, 1) struct
            end
            obj.requireOpen();
            obj.DraftSettings = obj.DraftSettings.withPatch(patch);
            obj.writeControls(obj.DraftSettings);
            obj.LastAction = "edited";
        end

        function replaceSettings(obj, settings)
            arguments
                obj (1, 1) brainnet.app.VisualizationSettingsDialog
                settings (1, 1) brainnet.core.VisualizationSettings
            end
            if ~obj.isOpen()
                return;
            end
            obj.CommittedSettings = settings;
            obj.DraftSettings = settings;
            obj.writeControls(settings);
            obj.LastAction = "synchronized";
        end

        function settings = apply(obj)
            obj.requireOpen();
            settings = obj.readControls();
            obj.ApplyCallback(settings);
            obj.CommittedSettings = settings;
            obj.DraftSettings = settings;
            obj.LastAction = "applied";
        end

        function settings = accept(obj)
            settings = obj.apply();
            obj.LastAction = "accepted";
            obj.closeWindow();
        end

        function cancel(obj)
            if ~obj.isOpen()
                return;
            end
            obj.DraftSettings = obj.CommittedSettings;
            obj.LastAction = "cancelled";
            obj.closeWindow();
        end

        function reset(obj)
            obj.requireOpen();
            obj.DraftSettings = brainnet.core.VisualizationSettings;
            obj.writeControls(obj.DraftSettings);
            obj.LastAction = "reset-pending";
        end

        function value = snapshot(obj)
            value = struct;
            value.open = obj.isOpen();
            value.last_action = char(obj.LastAction);
            value.committed_settings = obj.CommittedSettings.toStruct();
            value.draft_settings = obj.DraftSettings.toStruct();
            value.interface_text = {
                'Visualization Settings'; 'Layout'; 'Global'; 'Layout Preset';
                'View Direction'; 'Custom Azimuth'; 'Custom Elevation';
                'Background Color'; 'Red'; 'Green'; 'Blue'; 'Choose Color';
                'Surface Shading'; 'Lighting Model'; 'Light Direction'; 'Surface Material';
                'Ambient Strength'; 'Diffuse Strength'; 'Specular Strength';
                'Show Orientation Labels'; 'Reset'; 'Cancel'; 'Apply'; 'OK'};
            if obj.isOpen()
                value.visible = char(obj.UIFigure.Visible);
                value.position = obj.UIFigure.Position;
                value.resizable = char(obj.UIFigure.Resize);
                value.active_tab = obj.TabGroup.SelectedTab.Title;
                value.custom_fields_enabled = char(obj.AzimuthField.Enable);
                value.dirty = ~strcmp(obj.readControls().toJson(), ...
                    obj.CommittedSettings.toJson());
            else
                value.visible = 'off';
                value.position = [];
                value.resizable = 'off';
                value.active_tab = '';
                value.custom_fields_enabled = 'off';
                value.dirty = false;
            end
        end

        function delete(obj)
            if obj.isOpen()
                obj.closeWindow();
            end
        end
    end

    methods (Access = private)
        function createComponents(obj, parent)
            obj.UIFigure = uifigure('Visible', 'off', ...
                'Name', 'Visualization Settings', 'Resize', 'on');
            obj.UIFigure.Position = brainnet.render.internal.screenAwarePosition( ...
                [760 590], AdaptiveScale=true, MonitorFraction=[0.72 0.76], ...
                MaximumScale=1.15, MinimumSize=[650 510], ...
                AnchorPoint=brainnet.render.internal.figureAnchorPoint(parent));
            obj.UIFigure.CloseRequestFcn = @(~, ~) obj.cancel();
            obj.UIFigure.WindowKeyPressFcn = @(~, event) obj.onKeyPress(event);
            if ~isempty(parent) && isvalid(parent)
                obj.UIFigure.Name = 'Visualization Settings — BrainNet Viewer 2.0';
            end

            root = uigridlayout(obj.UIFigure, [3 1]);
            root.RowHeight = {52, '1x', 56};
            root.ColumnWidth = {'1x'};
            root.Padding = [18 14 18 14];
            root.RowSpacing = 10;

            heading = uigridlayout(root, [2 1]);
            heading.RowHeight = {28, 20};
            heading.Padding = [0 0 0 0];
            titleLabel = uilabel(heading, 'Text', 'Visualization Settings');
            titleLabel.FontSize = 20;
            titleLabel.FontWeight = 'bold';
            subtitle = uilabel(heading, ...
                'Text', 'Layout and global rendering controls · Settings schema v1.0');
            subtitle.FontColor = [0.35 0.40 0.47];

            obj.TabGroup = uitabgroup(root);
            obj.LayoutTab = uitab(obj.TabGroup, 'Title', 'Layout');
            obj.GlobalTab = uitab(obj.TabGroup, 'Title', 'Global');
            obj.createLayoutTab();
            obj.createGlobalTab();

            buttons = uigridlayout(root, [1 6]);
            buttons.ColumnWidth = {'1x', 88, 88, 88, 88, 0};
            buttons.Padding = [0 6 0 2];
            obj.ResetButton = uibutton(buttons, 'Text', 'Reset', ...
                'ButtonPushedFcn', @(~, ~) obj.onReset());
            obj.ResetButton.Layout.Column = 2;
            obj.CancelButton = uibutton(buttons, 'Text', 'Cancel', ...
                'ButtonPushedFcn', @(~, ~) obj.cancel());
            obj.CancelButton.Layout.Column = 3;
            obj.ApplyButton = uibutton(buttons, 'Text', 'Apply', ...
                'ButtonPushedFcn', @(~, ~) obj.onApply());
            obj.ApplyButton.Layout.Column = 4;
            obj.OkButton = uibutton(buttons, 'Text', 'OK', ...
                'ButtonPushedFcn', @(~, ~) obj.onAccept());
            obj.OkButton.Layout.Column = 5;
            obj.OkButton.BackgroundColor = [0.035 0.412 0.855];
            obj.OkButton.FontColor = [1 1 1];
        end

        function createLayoutTab(obj)
            grid = uigridlayout(obj.LayoutTab, [7 2]);
            grid.RowHeight = {36, 36, 18, 36, 36, '1x', 28};
            grid.ColumnWidth = {190, '1x'};
            grid.Padding = [22 20 22 16];
            grid.RowSpacing = 10;

            obj.addLabel(grid, 'Layout Preset', 1);
            obj.LayoutPresetDropDown = uidropdown(grid, ...
                'Items', {'Single View', 'Overview (6 / 8 Views)', ...
                'Lateral / Medial', 'Lateral / Medial / Ventral', ...
                'Lateral / Medial / Dorsal'}, ...
                'ItemsData', 1:5);
            obj.LayoutPresetDropDown.Layout.Row = 1;
            obj.LayoutPresetDropDown.Layout.Column = 2;

            obj.addLabel(grid, 'View Direction', 2);
            obj.ViewDirectionDropDown = uidropdown(grid, ...
                'Items', {'Left (Sagittal)', 'Superior (Axial)', ...
                'Anterior (Coronal)', 'Custom', 'Right', 'Inferior', ...
                'Posterior', 'Isometric'}, 'ItemsData', 1:8, ...
                'ValueChangedFcn', @(~, ~) obj.onDirectionChanged());
            obj.ViewDirectionDropDown.Layout.Row = 2;
            obj.ViewDirectionDropDown.Layout.Column = 2;

            note = uilabel(grid, 'Text', ...
                'View direction affects Single View; multi-view presets define their own cameras.');
            note.FontColor = [0.35 0.40 0.47];
            note.Layout.Row = 3;
            note.Layout.Column = [1 2];

            obj.addLabel(grid, 'Custom Azimuth', 4);
            obj.AzimuthField = uieditfield(grid, 'numeric', ...
                'Limits', [-360 360], 'ValueDisplayFormat', '%.1f°');
            obj.AzimuthField.Layout.Row = 4;
            obj.AzimuthField.Layout.Column = 2;

            obj.addLabel(grid, 'Custom Elevation', 5);
            obj.ElevationField = uieditfield(grid, 'numeric', ...
                'Limits', [-90 90], 'ValueDisplayFormat', '%.1f°');
            obj.ElevationField.Layout.Row = 5;
            obj.ElevationField.Layout.Column = 2;

            help = uitextarea(grid, 'Editable', 'off', ...
                'Value', {'Compatibility note'; ...
                'Directions 1–4 preserve the legacy sagittal, axial, coronal, and custom meanings.'; ...
                'Angles are validated before Apply or OK changes the active Scene.'});
            help.Layout.Row = 6;
            help.Layout.Column = [1 2];
        end

        function createGlobalTab(obj)
            grid = uigridlayout(obj.GlobalTab, [13 4]);
            grid.RowHeight = {32, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, '1x'};
            grid.ColumnWidth = {155, '1x', '1x', '1x'};
            grid.Padding = [22 20 22 16];
            grid.RowSpacing = 9;

            obj.addLabel(grid, 'Background Color', 1);
            obj.ColorPreview = uibutton(grid, 'Text', 'Choose Color', ...
                'ButtonPushedFcn', @(~, ~) obj.onChooseColor());
            obj.ColorPreview.Layout.Row = 1;
            obj.ColorPreview.Layout.Column = [2 4];

            obj.addLabel(grid, 'Red', 2);
            obj.RedField = uieditfield(grid, 'numeric', 'Limits', [0 1], ...
                'ValueDisplayFormat', '%.3f', ...
                'ValueChangedFcn', @(~, ~) obj.refreshColorPreview());
            obj.RedField.Layout.Row = 2;
            obj.RedField.Layout.Column = [2 4];
            obj.addLabel(grid, 'Green', 3);
            obj.GreenField = uieditfield(grid, 'numeric', 'Limits', [0 1], ...
                'ValueDisplayFormat', '%.3f', ...
                'ValueChangedFcn', @(~, ~) obj.refreshColorPreview());
            obj.GreenField.Layout.Row = 3;
            obj.GreenField.Layout.Column = [2 4];
            obj.addLabel(grid, 'Blue', 4);
            obj.BlueField = uieditfield(grid, 'numeric', 'Limits', [0 1], ...
                'ValueDisplayFormat', '%.3f', ...
                'ValueChangedFcn', @(~, ~) obj.refreshColorPreview());
            obj.BlueField.Layout.Row = 4;
            obj.BlueField.Layout.Column = [2 4];

            obj.addLabel(grid, 'Surface Shading', 5);
            obj.ShadingDropDown = uidropdown(grid, ...
                'Items', {'Flat', 'Faceted', 'Interpolated'}, ...
                'ItemsData', {'flat', 'faceted', 'interp'});
            obj.ShadingDropDown.Layout.Row = 5;
            obj.ShadingDropDown.Layout.Column = [2 4];

            obj.addLabel(grid, 'Lighting Model', 6);
            obj.LightingDropDown = uidropdown(grid, ...
                'Items', {'None', 'Flat', 'Gouraud', 'Phong'}, ...
                'ItemsData', {'none', 'flat', 'gouraud', 'phong'});
            obj.LightingDropDown.Layout.Row = 6;
            obj.LightingDropDown.Layout.Column = 2;
            obj.addLabel(grid, 'Light Direction', 6, 3);
            obj.LightDirectionDropDown = uidropdown(grid, ...
                'Items', {'Headlight', 'Right', 'Left'}, ...
                'ItemsData', {'headlight', 'right', 'left'});
            obj.LightDirectionDropDown.Layout.Row = 6;
            obj.LightDirectionDropDown.Layout.Column = 4;

            obj.addLabel(grid, 'Surface Material', 7);
            obj.MaterialProfileDropDown = uidropdown(grid, ...
                'Items', {'Dull', 'Shiny', 'Metal', 'Custom'}, ...
                'ItemsData', {'dull', 'shiny', 'metal', 'custom'}, ...
                'Tag', 'MaterialProfile', ...
                'ValueChangedFcn', @(~,~) obj.updateMaterialControls());
            obj.MaterialProfileDropDown.Layout.Row = 7;
            obj.MaterialProfileDropDown.Layout.Column = [2 4];
            materialLabels={'Ambient Strength','Diffuse Strength','Specular Strength'};
            materialProperties={'MaterialAmbientField','MaterialDiffuseField','MaterialSpecularField'};
            for index=1:3
                obj.addLabel(grid,materialLabels{index},7+index);
                field=uieditfield(grid,'numeric','Limits',[0 1],'ValueDisplayFormat','%.3f', ...
                    'Tag',['Material' erase(materialLabels{index},' Strength')]);
                field.Layout.Row=7+index;
                field.Layout.Column=[2 4];
                obj.(materialProperties{index})=field;
            end
            obj.addLabel(grid, 'Render Detail', 11);
            obj.RenderDetailDropDown = uidropdown(grid, ...
                'Items', {'Adaptive (modern)', 'Low (legacy)', 'Moderate (legacy)', 'High (legacy)'}, ...
                'ItemsData', {'adaptive', 'low', 'moderate', 'high'},'Tag','RenderDetail');
            obj.RenderDetailDropDown.Layout.Row = 11;
            obj.RenderDetailDropDown.Layout.Column = [2 4];
            obj.RenderDetailDropDown.Tooltip = 'Legacy levels use node detail 10/50/100 and edge sides 5/10/20.';

            obj.OrientationLabelsCheckBox = uicheckbox(grid, ...
                'Text', 'Show Orientation Labels');
            obj.OrientationLabelsCheckBox.Layout.Row = 12;
            obj.OrientationLabelsCheckBox.Tooltip = ...
                'Shows coordinate half-space labels unless anatomical X direction and the X=0 midline are explicitly confirmed in the Scene. Labels identify panes, not screen-edge directions.';
            obj.OrientationLabelsCheckBox.Layout.Column = [2 4];
        end

        function label = addLabel(~, grid, textValue, row, column)
            if nargin < 5
                column = 1;
            end
            label = uilabel(grid, 'Text', textValue);
            label.FontWeight = 'bold';
            label.Layout.Row = row;
            label.Layout.Column = column;
        end

        function writeControls(obj, settings)
            layout = settings.section("layout");
            globalSettings = settings.section("global");
            obj.LayoutPresetDropDown.Value = layout.preset;
            obj.ViewDirectionDropDown.Value = layout.view_direction;
            if isempty(layout.custom_azimuth)
                obj.AzimuthField.Value = -90;
                obj.ElevationField.Value = 0;
            else
                obj.AzimuthField.Value = layout.custom_azimuth;
                obj.ElevationField.Value = layout.custom_elevation;
            end
            obj.RedField.Value = globalSettings.background_color(1);
            obj.GreenField.Value = globalSettings.background_color(2);
            obj.BlueField.Value = globalSettings.background_color(3);
            obj.ShadingDropDown.Value = char(globalSettings.shading);
            obj.LightingDropDown.Value = char(globalSettings.lighting);
            obj.LightDirectionDropDown.Value = char(globalSettings.light_direction);
            obj.RenderDetailDropDown.Value = char(globalSettings.render_detail);
            obj.MaterialProfileDropDown.Value=char(globalSettings.material_profile);
            obj.MaterialAmbientField.Value=globalSettings.material_coefficients(1);
            obj.MaterialDiffuseField.Value=globalSettings.material_coefficients(2);
            obj.MaterialSpecularField.Value=globalSettings.material_coefficients(3);
            obj.OrientationLabelsCheckBox.Value = globalSettings.show_orientation_labels;
            obj.updateMaterialControls();
            obj.updateCustomFields();
            obj.refreshColorPreview();
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
            patch = struct( ...
                'layout', struct('preset', obj.LayoutPresetDropDown.Value, ...
                    'view_direction', direction, ...
                    'custom_azimuth', azimuth, ...
                    'custom_elevation', elevation), ...
                'global', struct( ...
                    'background_color', [obj.RedField.Value, ...
                        obj.GreenField.Value, obj.BlueField.Value], ...
                    'shading', obj.ShadingDropDown.Value, ...
                    'lighting', obj.LightingDropDown.Value, ...
                    'light_direction', obj.LightDirectionDropDown.Value, ...
                    'render_detail', obj.RenderDetailDropDown.Value, ...
                    'material_profile', obj.MaterialProfileDropDown.Value, ...
                    'material_coefficients', [obj.MaterialAmbientField.Value obj.MaterialDiffuseField.Value obj.MaterialSpecularField.Value], ...
                    'show_orientation_labels', obj.OrientationLabelsCheckBox.Value));
            settings = obj.DraftSettings.withPatch(patch);
        end

        function onDirectionChanged(obj)
            obj.updateCustomFields();
        end

        function updateMaterialControls(obj)
            enabled=string(obj.MaterialProfileDropDown.Value)=="custom";
            for field=[obj.MaterialAmbientField,obj.MaterialDiffuseField,obj.MaterialSpecularField]
                field.Enable=onOff(enabled);
            end
        end

        function updateCustomFields(obj)
            enabled = obj.ViewDirectionDropDown.Value == 4;
            obj.AzimuthField.Enable = onOff(enabled);
            obj.ElevationField.Enable = onOff(enabled);
        end

        function onChooseColor(obj)
            current = [obj.RedField.Value obj.GreenField.Value obj.BlueField.Value];
            restoreFocus = onCleanup(@() obj.FocusReturnCallback());
            selected = obj.ColorPicker(current, 'Choose Background Color');
            if isequal(selected, 0)
                return;
            end
            obj.RedField.Value = selected(1);
            obj.GreenField.Value = selected(2);
            obj.BlueField.Value = selected(3);
            obj.refreshColorPreview();
        end

        function refreshColorPreview(obj)
            color = [obj.RedField.Value obj.GreenField.Value obj.BlueField.Value];
            obj.ColorPreview.BackgroundColor = color;
            if dot(color, [0.2126 0.7152 0.0722]) < 0.48
                obj.ColorPreview.FontColor = [1 1 1];
            else
                obj.ColorPreview.FontColor = [0 0 0];
            end
        end

        function onApply(obj)
            try
                obj.apply();
            catch exception
                obj.presentError(exception);
            end
        end

        function onAccept(obj)
            try
                obj.accept();
            catch exception
                obj.presentError(exception);
            end
        end

        function onReset(obj)
            obj.reset();
        end

        function onKeyPress(obj, event)
            if strcmpi(event.Key, 'escape')
                obj.cancel();
            elseif strcmpi(event.Key, 'return') && ...
                    any(strcmpi(event.Modifier, {'control', 'command'}))
                obj.onApply();
            end
        end

        function presentError(obj, exception)
            if obj.isOpen() && strcmp(obj.UIFigure.Visible, 'on')
                uialert(obj.UIFigure, exception.message, ...
                    'Invalid Visualization Settings', 'Icon', 'error');
            else
                rethrow(exception);
            end
        end

        function requireOpen(obj)
            if ~obj.isOpen()
                error('BNV:App:SettingsDialogClosed', ...
                    'The Visualization Settings window is closed.');
            end
        end

        function closeWindow(obj)
            if obj.Closed
                return;
            end
            obj.Closed = true;
            if ~isempty(obj.UIFigure) && isvalid(obj.UIFigure)
                obj.UIFigure.CloseRequestFcn = [];
                delete(obj.UIFigure);
            end
            callback = obj.CloseCallback;
            obj.CloseCallback = @() [];
            callback();
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
