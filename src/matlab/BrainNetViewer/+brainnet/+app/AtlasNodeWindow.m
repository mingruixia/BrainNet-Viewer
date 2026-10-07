classdef AtlasNodeWindow < handle
    %ATLASNODEWINDOW Review an atlas before writing a new, independent node file.
    properties (SetAccess=private)
        UIFigure
        File
        Regions
        Module
        Size
        Summary
        Space
        Units
        Confirmed
        SaveButton
        Status
        Plan = []
        LastReport struct = struct()
    end
    properties (Access=private)
        ReviewedOptions = []
    end
    methods
        function obj=AtlasNodeWindow(options)
            arguments
                options.Visible (1,1) logical=true
                options.Theme (1,1) string="light"
                options.Parent = []
            end
            obj.UIFigure=uifigure('Name','Generate Nodes from Atlas','Tag','AtlasNodeWindow','Visible','off', ...
                'CloseRequestFcn',@(~,~) delete(obj));
            obj.UIFigure.Position=brainnet.render.internal.screenAwarePosition( ...
                [800 700],MinimumSize=[620 580], ...
                AnchorPoint=brainnet.render.internal.figureAnchorPoint(options.Parent));
            g=uigridlayout(obj.UIFigure,[11 1]); g.RowHeight={48,32,32,32,32,'1x',28,28,42,42,32};
            uilabel(g,'Text','Generate one node per nonzero integer label. Centroids use the atlas affine; no registration or MNI conversion. A centroid may lie outside its region.', 'WordWrap','on');
            row=uigridlayout(g,[1 2]); row.Layout.Row=2; row.Padding=[0 0 0 0]; row.ColumnWidth={'1x',110};
            obj.File=uieditfield(row,'text','Placeholder','NIfTI label atlas','ValueChangedFcn',@(~,~) obj.invalidate());
            uibutton(row,'Text','Browse...','ButtonPushedFcn',@(~,~) obj.run(@() obj.chooseInput()));
            obj.Regions=obj.textField(g,3,'Region IDs','Blank: all labels; or IDs separated by spaces / commas');
            obj.Regions.ValueChangedFcn=@(~,~) obj.invalidate();
            row=uigridlayout(g,[1 4]); row.Layout.Row=4; row.Padding=[0 0 0 0]; row.ColumnWidth={125,'1x',100,'1x'};
            uilabel(row,'Text','Color / module'); obj.Module=uieditfield(row,'numeric','Value',0,'ValueChangedFcn',@(~,~) obj.invalidate());
            uilabel(row,'Text','Size value'); obj.Size=uieditfield(row,'numeric','Limits',[0 Inf],'Value',0,'ValueChangedFcn',@(~,~) obj.invalidate());
            b=uibutton(g,'Text','Review Atlas','ButtonPushedFcn',@(~,~) obj.run(@() obj.review())); b.Layout.Row=5;
            obj.Summary=uitextarea(g,'Editable','off','Value',{'Choose an atlas and Review Atlas. Zero is background.'}); obj.Summary.Layout.Row=6;
            obj.Space=obj.textField(g,7,'Affine space','For example: subject-01 native scanner space');
            obj.Units=obj.textField(g,8,'Affine units','Verify from the atlas metadata / documentation');
            obj.Confirmed=uicheckbox(g,'Text','I verified that the atlas affine uses the declared space and units.', ...
                'WordWrap','on','ValueChangedFcn',@(~,~) obj.updateSave()); obj.Confirmed.Layout.Row=9;
            obj.Status=uilabel(g,'Text','Legacy defaults: color/module = 0, size = 0. No source or active Scene is changed.','WordWrap','on'); obj.Status.Layout.Row=10;
            row=uigridlayout(g,[1 2]); row.Layout.Row=11; row.Padding=[0 0 0 0];
            obj.SaveButton=uibutton(row,'Text','Save New .node...','Enable','off','ButtonPushedFcn',@(~,~) obj.run(@() obj.chooseOutput()));
            uibutton(row,'Text','Close','ButtonPushedFcn',@(~,~) delete(obj));
            obj.setTheme(options.Theme); obj.UIFigure.Visible=matlab.lang.OnOffSwitchState(options.Visible);
        end
        function setInput(obj,path)
            obj.File.Value=char(path); obj.invalidate();
        end
        function review(obj)
            obj.invalidate(); opts=obj.currentOptions();
            raw=strtrim(string(opts.regions)); regions=[];
            if strlength(raw)>0
                tokens=split(regexprep(raw,'[,\s]+',' ')); regions=str2double(tokens);
                if any(~isfinite(regions)), error('BNV:AtlasNodes:Regions','Enter numeric region IDs separated by spaces or commas; ranges and expressions are not supported.'); end
            end
            candidate=brainnet.tools.AtlasNodePlan(string(opts.file),Regions=regions,Module=opts.module,Size=opts.size);
            r=candidate.Report; lines=["ATLAS REVIEW — affine coordinates, no registration"; ...
                string(r.node_count)+" nodes | dimensions "+join(string(r.dimensions)," x "); ...
                "Affine: "+string(r.affine_method); "Label = original region ID | color/module = "+r.module_value+" | size = "+r.size_value];
            for source=r.sources
                lines=[lines;string(source.path);"SHA-256: "+string(source.sha256)]; %#ok<AGROW>
            end
            for k=1:min(r.node_count,100)
                lines(end+1)=sprintf('ID %s: %d voxels; XYZ = %.6g, %.6g, %.6g',candidate.Labels(k),r.voxel_counts(k),candidate.Values(k,1:3)); %#ok<AGROW>
            end
            if r.node_count>100, lines(end+1)="Preview limited to 100 nodes; all reviewed nodes will be saved."; end
            obj.Plan=candidate; obj.ReviewedOptions=opts; obj.Summary.Value=cellstr(lines);
            obj.Status.Text='Review complete. Verify affine space and units, then confirm before saving.'; obj.updateSave();
        end
        function report=saveTo(obj,path)
            if isempty(obj.Plan) || ~isequal(obj.currentOptions(),obj.ReviewedOptions)
                obj.invalidate(); error('BNV:AtlasNodes:ReviewRequired','Review the current atlas and options before saving.');
            end
            report=obj.Plan.write(path,CoordinateSpace=string(obj.Space.Value),Units=string(obj.Units.Value),Confirmed=obj.Confirmed.Value);
            obj.LastReport=report; obj.Status.Text=['Saved: ' report.output_path '. Load through Node Coordinates when ready.'];
        end
        function setTheme(obj,theme)
            if string(theme)=="dark", bg=[.094 .129 .173]; fg=[.92 .95 .98];
            else, bg=[.96 .96 .96]; fg=[.086 .137 .227]; end
            obj.UIFigure.Color=bg;
            for g=reshape(findall(obj.UIFigure,'-isa','matlab.ui.container.GridLayout'),1,[]), g.BackgroundColor=bg; end
            for l=reshape(findall(obj.UIFigure,'Type','uilabel'),1,[]), l.FontColor=fg; end
            obj.Confirmed.FontColor=fg; obj.Summary.BackgroundColor=bg; obj.Summary.FontColor=fg;
        end
        function delete(obj)
            if ~isempty(obj.UIFigure) && isvalid(obj.UIFigure), delete(obj.UIFigure); end
        end
    end
    methods (Access=private)
        function opts=currentOptions(obj)
            opts=struct('file',obj.File.Value,'regions',obj.Regions.Value,'module',obj.Module.Value,'size',obj.Size.Value);
        end
        function field=textField(obj,parent,row,title,placeholder)
            g=uigridlayout(parent,[1 2]); g.Layout.Row=row; g.Padding=[0 0 0 0]; g.ColumnWidth={125,'1x'};
            uilabel(g,'Text',title); field=uieditfield(g,'text','Placeholder',placeholder,'ValueChangedFcn',@(~,~) obj.clearConfirmation());
        end
        function clearConfirmation(obj)
            obj.Confirmed.Value=false; obj.updateSave();
        end
        function invalidate(obj)
            obj.Plan=[]; obj.ReviewedOptions=[]; obj.LastReport=struct(); obj.clearConfirmation();
            obj.Summary.Value={'Input or options changed. Review Atlas before saving.'};
        end
        function updateSave(obj)
            obj.SaveButton.Enable=matlab.lang.OnOffSwitchState(~isempty(obj.Plan) && obj.Confirmed.Value);
        end
        function chooseInput(obj)
            [file,folder]=uigetfile({'*.nii;*.nii.gz;*.hdr;*.img;*.hdr.gz;*.img.gz','NIfTI label atlas'},'Select label atlas');
            if isequal(file,0), return; end
            obj.setInput(fullfile(folder,file));
        end
        function chooseOutput(obj)
            [file,folder]=uiputfile({'*.node','BrainNet nodes'},'Save new atlas nodes','atlas.node');
            if isequal(file,0), return; end
            obj.saveTo(fullfile(folder,file));
        end
        function run(obj,action)
            try
                action();
            catch failure
                obj.Status.Text=failure.message;
                if strcmp(failure.identifier,'BNV:AtlasNodes:InputChanged'), obj.clearConfirmation(); end
            end
        end
    end
end
