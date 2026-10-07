classdef MovieExportWindow < handle
    %MOVIEEXPORTWINDOW Compact English controls with cancellable bundle export.
    properties (SetAccess=private)
        UIFigure
        Format
        Width
        Height
        Duration
        FrameRate
        Axis
        StartAngle
        EndAngle
        SafeFit
        ExportButton
        CancelButton
        Status
        LastReport struct=struct()
        Busy logical=false
    end
    properties (Access=private)
        ExportCallback function_handle
        CancelRequested logical=false
        ClosePending logical=false
    end
    methods
        function obj=MovieExportWindow(callback,options)
            arguments
                callback (1,1) function_handle
                options.Visible (1,1) logical=true
                options.Theme (1,1) string="light"
                options.Parent = []
            end
            obj.ExportCallback=callback;
            obj.UIFigure=uifigure('Name','Export Animation','Tag','MovieExportWindow','Visible','off', ...
                'CloseRequestFcn',@(~,~) obj.requestClose());
            obj.UIFigure.Position=brainnet.render.internal.screenAwarePosition( ...
                [600 510],MinimumSize=[500 450], ...
                AnchorPoint=brainnet.render.internal.figureAnchorPoint(options.Parent));
            grid=uigridlayout(obj.UIFigure,[12 2]); grid.ColumnWidth={160,'1x'};
            grid.RowSpacing=5; grid.Scrollable='on';
            grid.RowHeight={42,30,30,30,30,30,30,30,30,38,42,32};
            tip=uilabel(grid,'Text','Export the CURRENT rendered scene into a NEW folder. Your canvas and camera remain unchanged.', ...
                'WordWrap','on'); tip.Layout.Row=1; tip.Layout.Column=[1 2];
            obj.label(grid,2,'Format'); formats=brainnet.export.MovieExporter.availableFormats();
            obj.Format=uidropdown(grid,'Items',cellstr(upper(formats)),'ItemsData',cellstr(formats)); obj.place(obj.Format,2);
            obj.Width=obj.number(grid,3,'Width (pixels)',960,[128 3840]);
            obj.Height=obj.number(grid,4,'Height (pixels)',720,[128 3840]);
            obj.Duration=obj.number(grid,5,'Duration (seconds)',5,[.01 120]);
            obj.FrameRate=obj.number(grid,6,'Frame rate (fps)',24,[1 60]);
            obj.label(grid,7,'World rotation axis');
            obj.Axis=uidropdown(grid,'Items',{'X','Y','Z'},'ItemsData',{'x','y','z'},'Value','z'); obj.place(obj.Axis,7);
            obj.StartAngle=obj.number(grid,8,'Start offset (degrees)',0,[-360 360]);
            obj.EndAngle=obj.number(grid,9,'End offset (degrees)',360,[-720 720]);
            obj.SafeFit=uicheckbox(grid,'Text','Safe Fit: keep geometry inside every rotating view','Value',true);
            obj.SafeFit.Layout.Row=10; obj.SafeFit.Layout.Column=[1 2];
            obj.Status=uilabel(grid,'Text','A full turn omits the duplicate endpoint. PNG exports one image per frame.', ...
                'WordWrap','on'); obj.Status.Layout.Row=11; obj.Status.Layout.Column=[1 2];
            obj.ExportButton=uibutton(grid,'Text','Export...','Tag','ExportMovie', ...
                'ButtonPushedFcn',@(~,~) obj.chooseDestination()); obj.ExportButton.Layout.Row=12;
            obj.CancelButton=uibutton(grid,'Text','Close','ButtonPushedFcn',@(~,~) obj.onCancelButton());
            obj.CancelButton.Layout.Row=12; obj.CancelButton.Layout.Column=2;
            obj.setTheme(options.Theme); obj.UIFigure.Visible=matlab.lang.OnOffSwitchState(options.Visible);
        end
        function report=exportTo(obj,path)
            if obj.Busy, error('BNV:Movie:Busy','An export is already running.'); end
            obj.Busy=true; obj.CancelRequested=false; obj.ExportButton.Enable='off'; obj.CancelButton.Text='Cancel Export';
            obj.enableInputs('off');
            obj.UIFigure.WindowStyle='modal'; cleanup=onCleanup(@() obj.finish());
            try
                report=obj.ExportCallback(path,Format=string(obj.Format.Value),Width=obj.Width.Value,Height=obj.Height.Value, ...
                    Duration=obj.Duration.Value,FrameRate=obj.FrameRate.Value,Axis=string(obj.Axis.Value), ...
                    StartAngle=obj.StartAngle.Value,EndAngle=obj.EndAngle.Value,SafeFit=obj.SafeFit.Value, ...
                    Cancel=@() obj.CancelRequested,Progress=@(done,total) obj.progress(done,total));
                obj.LastReport=report; obj.Status.Text=['Saved: ' report.output_folder];
            catch failure
                obj.Status.Text=failure.message; rethrow(failure);
            end
        end
        function cancel(obj)
            if obj.Busy, obj.CancelRequested=true; obj.Status.Text='Cancelling after the current frame...'; end
        end
        function requestClose(obj)
            if obj.Busy, obj.ClosePending=true; obj.cancel(); else, delete(obj); end
        end
        function setTheme(obj,theme)
            if string(theme)=="dark", bg=[.094 .129 .173]; fg=[.92 .95 .98];
            else, bg=[.96 .96 .96]; fg=[.086 .137 .227]; end
            obj.UIFigure.Color=bg;
            for g=reshape(findall(obj.UIFigure,'-isa','matlab.ui.container.GridLayout'),1,[]), g.BackgroundColor=bg; end
            for l=reshape(findall(obj.UIFigure,'Type','uilabel'),1,[]), l.FontColor=fg; end
            obj.SafeFit.FontColor=fg;
        end
        function delete(obj)
            if ~isempty(obj.UIFigure)&&isvalid(obj.UIFigure), delete(obj.UIFigure); end
        end
    end
    methods (Access=private)
        function enableInputs(obj,state)
            controls={obj.Format,obj.Width,obj.Height,obj.Duration,obj.FrameRate,obj.Axis,obj.StartAngle,obj.EndAngle,obj.SafeFit};
            for k=1:numel(controls), controls{k}.Enable=state; end
        end
        function onCancelButton(obj)
            if obj.Busy, obj.cancel(); else, obj.requestClose(); end
        end
        function finish(obj)
            obj.Busy=false;
            if obj.ClosePending, delete(obj); return; end
            obj.UIFigure.WindowStyle='normal'; obj.ExportButton.Enable='on'; obj.CancelButton.Text='Close';
            obj.enableInputs('on');
        end
        function progress(obj,done,total)
            obj.Status.Text=sprintf('Rendering frame %d / %d. Encoding / verification follows.',done,total);
        end
        function chooseDestination(obj)
            [name,folder]=uiputfile({'*.*','New output folder'},'Choose a NEW output folder name','brainnet-movie');
            if isequal(name,0), return; end
            try
                obj.exportTo(string(fullfile(folder,name)));
            catch failure
                if isvalid(obj)&&isgraphics(obj.UIFigure)&&~strcmp(failure.identifier,'BNV:Movie:Cancelled')
                    uialert(obj.UIFigure,failure.message,'Animation Not Saved');
                end
            end
        end
    end
    methods (Static,Access=private)
        function label(grid,row,text)
            l=uilabel(grid,'Text',text); l.Layout.Row=row; l.Layout.Column=1;
        end
        function place(control,row)
            control.Layout.Row=row; control.Layout.Column=2;
        end
        function f=number(grid,row,label,value,limits)
            brainnet.app.MovieExportWindow.label(grid,row,label);
            f=uieditfield(grid,'numeric','Value',value,'Limits',limits);
            brainnet.app.MovieExportWindow.place(f,row);
        end
    end
end
