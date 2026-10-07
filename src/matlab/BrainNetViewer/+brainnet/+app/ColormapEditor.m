classdef ColormapEditor < handle
    %COLORMAPEDITOR RGB-table editor; stages settings for the shared Apply action.
    properties (SetAccess=private)
        UIFigure
        Table
        Preview
        Target
        Preset
        Count
        Status
        Maps cell
    end
    properties (Access=private)
        Callback function_handle
        Index (1,1) double = 1
    end
    methods
        function obj=ColormapEditor(maps,callback,options)
            arguments
                maps (1,4) cell
                callback (1,1) function_handle
                options.Visible (1,1) logical = true
                options.Theme (1,1) string = "light"
                options.Parent = []
            end
            obj.Maps=cellfun(@brainnet.core.Colormap.validate,maps,'UniformOutput',false);
            obj.Callback=callback;
            obj.UIFigure=uifigure('Name','Colormap Editor','Visible','off', ...
                'Tag','ColormapEditor','CloseRequestFcn',@(~,~) delete(obj));
            obj.UIFigure.Position=brainnet.render.internal.screenAwarePosition( ...
                [760 650],MinimumSize=[580 460],MonitorFraction=[.85 .85], ...
                AnchorPoint=brainnet.render.internal.figureAnchorPoint(options.Parent));
            grid=uigridlayout(obj.UIFigure,[6 1]);
            grid.RowHeight={32,32,70,'1x',40,34};
            top=uigridlayout(grid,[1 2]); top.Layout.Row=1;
            top.ColumnWidth={70,'1x'}; top.Padding=[0 0 0 0];
            uilabel(top,'Text','Target');
            obj.Target=uidropdown(top,'Items',{'Surface','Nodes','Edges','Volume'}, ...
                'ItemsData',1:4,'ValueChangedFcn',@(~,~) obj.switchTarget());
            tools=uigridlayout(grid,[1 5]); tools.Layout.Row=2;
            tools.ColumnWidth={'1x',65,80,80,75}; tools.Padding=[0 0 0 0];
            obj.Preset=uidropdown(tools,'Items',cellstr(brainnet.core.Colormap.names()));
            obj.Count=uieditfield(tools,'numeric','Limits',[2 4096],'RoundFractionalValues','on','Value',256, ...
                'Tooltip','Number of RGB rows for Generate / Resample');
            uibutton(tools,'Text','Generate','ButtonPushedFcn',@(~,~) obj.run(@() obj.generate()));
            uibutton(tools,'Text','Resample','ButtonPushedFcn',@(~,~) obj.run(@() obj.resample()));
            uibutton(tools,'Text','Reverse','ButtonPushedFcn',@(~,~) obj.run(@() obj.reverse()));
            obj.Preview=uiaxes(grid); obj.Preview.Layout.Row=3;
            obj.Table=uitable(grid,'Data',zeros(2,3),'ColumnName',{'Red','Green','Blue'}, ...
                'ColumnEditable',true(1,3),'ColumnFormat',{'numeric','numeric','numeric'}, ...
                'CellEditCallback',@(~,~) obj.run(@() obj.acceptTable()));
            obj.Table.Layout.Row=4;
            obj.Status=uilabel(grid,'Text','RGB range: 0 to 1. Use in Settings stages changes; then choose Apply.', ...
                'WordWrap','on'); obj.Status.Layout.Row=5;
            actions=uigridlayout(grid,[1 4]); actions.Layout.Row=6;
            actions.Padding=[0 0 0 0]; actions.ColumnWidth={'1x','1x','1x','1x'};
            uibutton(actions,'Text','Import...','ButtonPushedFcn',@(~,~) obj.run(@() obj.onImport()));
            uibutton(actions,'Text','Export...','ButtonPushedFcn',@(~,~) obj.run(@() obj.onExport()));
            uibutton(actions,'Text','Cancel','ButtonPushedFcn',@(~,~) delete(obj));
            uibutton(actions,'Text','Use in Settings','Tag','UseColormap', ...
                'ButtonPushedFcn',@(~,~) obj.run(@() obj.use()));
            if options.Theme=="dark"
                obj.UIFigure.Color=[.094 .129 .173];
                for g=reshape(findall(obj.UIFigure,'-isa','matlab.ui.container.GridLayout'),1,[])
                    g.BackgroundColor=obj.UIFigure.Color;
                end
                for label=reshape(findall(obj.UIFigure,'Type','uilabel'),1,[])
                    label.FontColor=[.92 .95 .98];
                end
            end
            obj.showMap();
            if options.Visible
                obj.UIFigure.WindowStyle='modal'; obj.UIFigure.Visible='on';
            end
        end
        function setMap(obj,index,map)
            map=brainnet.core.Colormap.validate(map);
            obj.Maps{index}=map;
            obj.Index=index; obj.Target.Value=index; obj.showMap();
        end
        function importFile(obj,path)
            obj.setMap(obj.Index,brainnet.io.readColormap(path));
        end
        function exportFile(obj,path,varargin)
            obj.acceptTable();
            brainnet.io.writeColormap(obj.Table.Data,path,varargin{:});
        end
        function use(obj)
            if isempty(obj.UIFigure) || ~isvalid(obj.UIFigure)
                error('BNV:Color:EditorClosed','The colormap editor is closed.');
            end
            obj.acceptTable(); obj.Callback(obj.Maps); delete(obj);
        end
        function reverse(obj)
            obj.acceptTable(); obj.setMap(obj.Index,flipud(obj.Table.Data));
        end
        function resample(obj)
            obj.acceptTable(); obj.setMap(obj.Index,brainnet.core.Colormap.sample(obj.Table.Data,obj.Count.Value));
        end
        function delete(obj)
            if ~isempty(obj.UIFigure) && isvalid(obj.UIFigure), delete(obj.UIFigure); end
        end
    end
    methods (Access=private)
        function generate(obj)
            obj.setMap(obj.Index,brainnet.core.Colormap.sample(obj.Preset.Value,obj.Count.Value));
        end
        function acceptTable(obj)
            map=brainnet.core.Colormap.validate(obj.Table.Data);
            % Viewing a named palette alone does not turn it into a custom map.
            original=obj.Maps{obj.Index};
            if isnumeric(original) || ~isequal(map,brainnet.core.Colormap.sample(original,size(map,1)))
                obj.Maps{obj.Index}=map;
            end
            obj.drawPreview(map);
        end
        function switchTarget(obj)
            next=obj.Target.Value;
            try
                obj.acceptTable(); obj.Index=next; obj.showMap();
            catch failure
                obj.Target.Value=obj.Index; obj.Status.Text=failure.message;
            end
        end
        function showMap(obj)
            map=obj.Maps{obj.Index}; count=256;
            if isnumeric(map), count=size(map,1); end
            obj.Table.Data=brainnet.core.Colormap.sample(map,count); obj.Count.Value=count;
            obj.drawPreview(obj.Table.Data);
        end
        function drawPreview(obj,map)
            image(obj.Preview,reshape(brainnet.core.Colormap.sample(map,256),[1 256 3]));
            obj.Preview.Visible='off'; obj.Preview.XLim=[.5 256.5]; obj.Preview.YLim=[.5 1.5];
            obj.Status.Text=sprintf('%d RGB rows. Use in Settings, then choose Apply to render.',size(map,1));
        end
        function run(obj,action)
            try
                action();
            catch failure
                if ~isempty(obj.UIFigure) && isvalid(obj.UIFigure), obj.Status.Text=failure.message; end
            end
        end
        function onImport(obj)
            [name,folder]=uigetfile({'*.json;*.txt','RGB colormap (*.json, *.txt)'},'Import Colormap');
            if ~isequal(name,0), obj.importFile(string(fullfile(folder,name))); end
        end
        function onExport(obj)
            [name,folder]=uiputfile({'*.json','Colormap JSON';'*.txt','RGB Text'},'Export Colormap');
            if isequal(name,0), return; end
            path=string(fullfile(folder,name)); overwrite=false;
            if isfile(path)
                answer=uiconfirm(obj.UIFigure,'Replace the existing colormap file?','Overwrite Colormap', ...
                    'Options',{'Replace','Cancel'},'DefaultOption',2,'CancelOption',2);
                if ~strcmp(answer,'Replace'), return; end
                overwrite=true;
            end
            obj.exportFile(path,Overwrite=overwrite);
        end
    end
end
