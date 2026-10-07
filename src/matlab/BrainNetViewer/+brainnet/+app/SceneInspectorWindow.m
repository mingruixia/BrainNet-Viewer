classdef SceneInspectorWindow < handle
    %SCENEINSPECTORWINDOW Direct MNI lookup for AAL and Brodmann labels.
    properties (SetAccess=private)
        UIFigure
        Output
        Atlas
        Status
    end
    properties (Access=private)
        Callback function_handle
        Settings struct
        ClosedFcn function_handle
    end
    methods
        function obj=SceneInspectorWindow(settings,callback,options)
            arguments
                settings (1,1) struct
                callback (1,1) function_handle
                options.Visible (1,1) logical=true
                options.ClosedFcn (1,1) function_handle=@() []
                options.Theme (1,1) string="light"
            end
            obj.Settings=brainnet.query.InspectionSettings.validate(settings);
            if ~ismember(string(obj.Settings.atlas),["aal","brodmann"])
                error('BNV:Query:UnsupportedInspectAtlas', ...
                    'The Inspect window currently supports AAL and Brodmann only.');
            end
            obj.Callback=callback;
            obj.ClosedFcn=options.ClosedFcn;
            obj.UIFigure=uifigure('Name','Scene Inspector','Tag','SceneInspector', ...
                'Visible','off','CloseRequestFcn',@(~,~) delete(obj));
            obj.UIFigure.Position=brainnet.render.internal.screenAwarePosition( ...
                [580 470],MinimumSize=[470 350]);
            grid=uigridlayout(obj.UIFigure,[5 1]);
            grid.RowHeight={44,36,'1x',44,34};
            uilabel(grid,'Text', ...
                'Click a rendered surface or node to inspect its source vertex, values and atlas label.', ...
                'WordWrap','on');
            row=uigridlayout(grid,[1 2]);
            row.Layout.Row=2; row.Padding=[0 0 0 0]; row.ColumnWidth={85,'1x'};
            uilabel(row,'Text','Atlas');
            obj.Atlas=uidropdown(row,'Items',{'AAL','Brodmann'}, ...
                'ItemsData',{'aal','brodmann'},'Value',obj.Settings.atlas, ...
                'Tag','InspectAtlas', ...
                'ValueChangedFcn',@(~,~) obj.run(@() obj.apply()));
            obj.Output=uitextarea(grid,'Editable','off', ...
                'Value',{'No point selected. Click a rendered surface or node.'});
            obj.Output.Layout.Row=3;
            obj.Status=uilabel(grid,'Text', ...
                ['Coordinates are assumed to be in MNI space. No registration ' ...
                 'or affine transform is applied; verify your input coordinates.'], ...
                'WordWrap','on');
            obj.Status.Layout.Row=4;
            closeButton=uibutton(grid,'Text','Close', ...
                'ButtonPushedFcn',@(~,~) delete(obj));
            closeButton.Layout.Row=5;
            obj.setTheme(options.Theme);
            obj.UIFigure.Visible=matlab.lang.OnOffSwitchState(options.Visible);
        end

        function setTheme(obj,theme)
            if string(theme)=="dark", background=[.094 .129 .173]; foreground=[.92 .95 .98];
            else, background=[.96 .96 .96]; foreground=[.086 .137 .227]; end
            obj.UIFigure.Color=background;
            for grid=reshape(findall(obj.UIFigure,'-isa','matlab.ui.container.GridLayout'),1,[])
                grid.BackgroundColor=background;
            end
            for label=reshape(findall(obj.UIFigure,'Type','uilabel'),1,[])
                label.FontColor=foreground;
            end
            obj.Output.BackgroundColor=background;
            obj.Output.FontColor=foreground;
        end

        function showResult(obj,result)
            obj.Output.Value=cellstr(brainnet.query.SceneInspector.describe(result));
        end

        function showError(obj,message)
            obj.Output.Value={char(message)};
        end

        function apply(obj)
            settings=obj.Settings;
            settings.atlas=obj.Atlas.Value;
            settings.scene_to_atlas=eye(4);
            settings.source_space='MNI (assumed for Inspect)';
            settings.atlas_space='MNI (legacy AAL/Brodmann)';
            settings.transform_note= ...
                'Direct MNI lookup; no registration or coordinate transform was performed.';
            settings.confirmed=true;
            settings=brainnet.query.InspectionSettings.validate(settings);
            obj.Callback(settings);
            obj.Settings=settings;
            obj.Output.Value={'Atlas changed. Click the rendered surface or node again.'};
        end

        function delete(obj)
            if ~isempty(obj.UIFigure) && isvalid(obj.UIFigure)
                obj.ClosedFcn();
                delete(obj.UIFigure);
            end
        end
    end
    methods (Access=private)
        function run(obj,action)
            try
                action();
            catch failure
                obj.showError(failure.message);
            end
        end
    end
end
