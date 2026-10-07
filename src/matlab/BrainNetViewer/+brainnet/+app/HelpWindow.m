classdef HelpWindow < handle
    %HELPWINDOW Offline help navigator; opening help never changes a Scene.
    properties (SetAccess=private)
        UIFigure
        Catalog struct
        Document struct = struct()
        LastExternalUrl string = ""
    end
    properties (Access=private)
        Viewer
        Links
        Status
        Scope string
        History string = strings(0,1)
        ExternalOpener
    end
    methods
        function obj=HelpWindow(root,options)
            arguments
                root (1,1) string
                options.Visible (1,1) logical = true
                options.ExternalOpener (1,1) function_handle = @(url) web(char(url),'-browser')
                options.Parent = []
            end
            obj.Catalog=brainnet.app.HelpDocuments.catalog(root);
            obj.Scope=string(fileparts(obj.Catalog.docs_root)); obj.ExternalOpener=options.ExternalOpener;
            obj.UIFigure=uifigure('Name','BrainNet Viewer Help','Tag','BrainNetHelpWindow','Visible','off', ...
                'CloseRequestFcn',@(~,~) delete(obj));
            obj.UIFigure.Position=brainnet.render.internal.screenAwarePosition( ...
                [1000 800],MinimumSize=[700 540], ...
                AnchorPoint=brainnet.render.internal.figureAnchorPoint(options.Parent));
            grid=uigridlayout(obj.UIFigure,[7 1]); grid.RowHeight={42,34,'1x',24,90,32,42};
            label=uilabel(grid,'Text','Browse the BrainNet Viewer 2.0 manuals and tutorials for supported workflows and current limitations.', ...
                'WordWrap','on'); label.Layout.Row=1;
            nav=uigridlayout(grid,[1 4]); nav.Layout.Row=2; nav.Padding=[0 0 0 0]; nav.ColumnWidth={'1x','1x','1x','1x'};
            names=["Manual - English","Manual - Chinese","Tutorials - English","Tutorials - Chinese"];
            keys=["manual_en","manual_zh","tutorials_en","tutorials_zh"];
            for k=1:4
                key=keys(k);
                uibutton(nav,'Text',names(k),'Tag',"Help_"+key,'ButtonPushedFcn',@(~,~) obj.openPage(key));
            end
            obj.Viewer=uihtml(grid,'Tag','HelpDocumentViewer', ...
                'HTMLEventReceivedFcn',@(~,event) obj.receiveLink(event)); obj.Viewer.Layout.Row=3;
            label=uilabel(grid,'Text','Related pages and resources (select below, then Open Selected):'); label.Layout.Row=4;
            obj.Links=uilistbox(grid,'Items',{'No related resources'},'ItemsData',0,'Value',0,'Tag','HelpRelatedPages'); obj.Links.Layout.Row=5;
            actions=uigridlayout(grid,[1 3]); actions.Layout.Row=6; actions.Padding=[0 0 0 0]; actions.ColumnWidth={'1x','1x','1x'};
            uibutton(actions,'Text','Back','ButtonPushedFcn',@(~,~) obj.back());
            uibutton(actions,'Text','Open Selected','Tag','HelpOpenSelected','ButtonPushedFcn',@(~,~) obj.openSelected());
            uibutton(actions,'Text','User Manual (PDF)','Tag','HelpManualPdf','ButtonPushedFcn',@(~,~) obj.openManualPdf());
            obj.Status=uilabel(grid,'Text','','WordWrap','on','Tag','HelpStatus'); obj.Status.Layout.Row=7;
            obj.openPage("manual_en"); obj.UIFigure.Visible=matlab.lang.OnOffSwitchState(options.Visible);
        end
        function openPage(obj,key)
            if ~ismember(string(key),["manual_en","manual_zh","tutorials_en","tutorials_zh"])
                error('BNV:Help:UnknownPage','Unknown help entry.');
            end
            obj.openPath(string(obj.Catalog.(key)));
        end
        function openSelected(obj)
            index=obj.Links.Value;
            if index==0, return; end
            try
                obj.openReference(obj.Document.links(index).target);
            catch exception
                obj.Status.Text=exception.message;
            end
        end
        function openReference(obj,target)
            target=string(target);
            if startsWith(target,["https://","http://"])
                obj.openExternal(target); return;
            end
            if contains(target,':')||startsWith(target,["/","\"])
                error('BNV:Help:UnsafeLink','Unsupported help link.');
            end
            target=extractBefore(target+"#","#"); target=replace(target,'%20',' ');
            if strlength(target)==0, return; end
            path=brainnet.app.HelpDocuments.localPath(fullfile(fileparts(obj.Document.path),target),obj.Scope);
            [~,~,ext]=fileparts(path);
            if strcmpi(ext,'.md'), obj.openPath(path); return; end
            if ~ismember(lower(string(ext)),[".pdf",".png",".jpg",".jpeg"])
                error('BNV:Help:UnsupportedResource','Only documentation pages, PDF and image resources can be opened.');
            end
            obj.openLocalResource(path);
        end
        function openManualPdf(obj)
            obj.openLocalResource(string(obj.Catalog.manual_pdf));
        end
        function back(obj)
            if numel(obj.History)<2, return; end
            obj.History(end)=[]; path=obj.History(end); obj.History(end)=[]; obj.openPath(path);
        end
        function delete(obj)
            if ~isempty(obj.UIFigure)&&isvalid(obj.UIFigure), delete(obj.UIFigure); end
        end
    end
    methods (Access=private)
        function receiveLink(obj,event)
            if string(event.HTMLEventName)~="HelpLink"||~isfield(obj.Document,'path'), return; end
            data=event.HTMLEventData;
            if ~isstruct(data)||~isfield(data,'Index')||~isfield(data,'Page')|| ...
                    ~isequal(string(data.Page),string(obj.Document.path)), return; end
            index=data.Index;
            if ~isnumeric(index)||~isscalar(index)||~isfinite(index)|| ...
                    index~=fix(index)||index<1||index>numel(obj.Document.links), return; end
            try
                obj.openReference(obj.Document.links(index).target);
            catch exception
                obj.Status.Text=exception.message;
            end
        end
        function openPath(obj,path)
            try
                document=brainnet.app.HelpDocuments.read(path,obj.Scope);
                obj.Document=document; obj.Viewer.HTMLSource=document.html;
                if isempty(document.links)
                    obj.Links.Items={'No related resources'}; obj.Links.ItemsData=0; obj.Links.Value=0;
                else
                    obj.Links.Items=cellstr(string(1:numel(document.links))+". "+string({document.links.label}));
                    obj.Links.ItemsData=1:numel(document.links); obj.Links.Value=1;
                end
                obj.History(end+1)=string(document.path); obj.Status.Text=document.path;
            catch exception
                obj.Status.Text=exception.message;
                obj.Viewer.HTMLSource=brainnet.app.HelpDocuments.render("# Documentation unavailable"+newline+exception.message);
                obj.Document=struct(); obj.Links.Items={'No related resources'}; obj.Links.ItemsData=0; obj.Links.Value=0;
            end
        end
        function openLocalResource(obj,path)
            if ~isfile(path)
                obj.Status.Text="Resource is missing: "+path; return;
            end
            obj.openExternal(string(char(java.io.File(char(path)).toURI().toASCIIString())));
        end
        function openExternal(obj,url)
            obj.LastExternalUrl=url;
            try
                obj.ExternalOpener(url); obj.Status.Text="Opened: "+url;
            catch exception
                obj.Status.Text="Could not open resource: "+string(exception.message);
            end
        end
    end
end
