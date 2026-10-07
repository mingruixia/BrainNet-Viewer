classdef SurfaceSubdivisionWindow < handle
    %SURFACESUBDIVISIONWINDOW Review linear refinement before saving a new NV.
    properties (SetAccess=private)
        UIFigure
        File
        Levels
        Summary
        Space
        Units
        Note
        Confirmed
        SaveButton
        Status
        Plan=[]
        LastReport struct=struct()
    end
    properties (Access=private)
        ReviewedFile string=""
        ReviewedLevels double=[]
    end
    methods
        function obj=SurfaceSubdivisionWindow(options)
            arguments
                options.Visible (1,1) logical=true
                options.Theme (1,1) string="light"
                options.Parent = []
            end
            obj.UIFigure=uifigure('Name','Subdivide Surface to NV','Tag','SurfaceSubdivisionWindow','Visible','off','CloseRequestFcn',@(~,~) delete(obj));
            obj.UIFigure.Position=brainnet.render.internal.screenAwarePosition( ...
                [780 660],MinimumSize=[600 520], ...
                AnchorPoint=brainnet.render.internal.figureAnchorPoint(options.Parent));
            g=uigridlayout(obj.UIFigure,[10 1]); g.RowHeight={48,32,32,32,'1x',28,28,28,42,32};
            uilabel(g,'Text','Linear midpoint subdivision: every triangle becomes four. This changes geometry; it does not smooth, register, or transfer colors/maps.','WordWrap','on');
            row=uigridlayout(g,[1 2]); row.Layout.Row=2; row.Padding=[0 0 0 0]; row.ColumnWidth={'1x',110};
            obj.File=uieditfield(row,'text','Placeholder','One supported surface','ValueChangedFcn',@(~,~) obj.invalidate());
            uibutton(row,'Text','Browse...','ButtonPushedFcn',@(~,~) obj.run(@() obj.chooseInput()));
            row=uigridlayout(g,[1 3]); row.Layout.Row=3; row.Padding=[0 0 0 0]; row.ColumnWidth={125,'1x',110};
            uilabel(row,'Text','Subdivision levels'); obj.Levels=uieditfield(row,'numeric','Limits',[1 3],'RoundFractionalValues','on','Value',1,'ValueChangedFcn',@(~,~) obj.invalidate());
            uibutton(row,'Text','Review','ButtonPushedFcn',@(~,~) obj.run(@() obj.review()));
            uilabel(g,'Text','Level 1 creates 4 faces per original face; level 2 creates 16; level 3 creates 64. Large meshes can exceed limits.','WordWrap','on');
            obj.Summary=uitextarea(g,'Editable','off','Value',{'Choose a surface and Review.'}); obj.Summary.Layout.Row=5;
            obj.Space=obj.textField(g,6,'Raw space','Optional: blank remains unknown'); obj.Units=obj.textField(g,7,'Raw units','Optional: no conversion'); obj.Note=obj.textField(g,8,'Note','Optional provenance note');
            obj.Confirmed=uicheckbox(g,'Text','I reviewed the geometry change and accept that attributes/transforms are not transferred.','WordWrap','on','ValueChangedFcn',@(~,~) obj.updateSave()); obj.Confirmed.Layout.Row=9;
            row=uigridlayout(g,[1 3]); row.Layout.Row=10; row.Padding=[0 0 0 0]; row.ColumnWidth={140,80,'1x'};
            obj.SaveButton=uibutton(row,'Text','Save New .nv...','Enable','off','ButtonPushedFcn',@(~,~) obj.run(@() obj.chooseOutput())); uibutton(row,'Text','Close','ButtonPushedFcn',@(~,~) delete(obj));
            obj.Status=uilabel(row,'Text','No source or active Scene is changed.','HorizontalAlignment','right');
            obj.setTheme(options.Theme); obj.UIFigure.Visible=matlab.lang.OnOffSwitchState(options.Visible);
        end
        function setInput(obj,path), obj.File.Value=char(path); obj.invalidate(); end
        function review(obj)
            obj.invalidate(); candidate=brainnet.tools.SurfaceSubdivisionPlan(string(obj.File.Value),Levels=obj.Levels.Value);
            r=candidate.Report; lines=["SUBDIVISION REVIEW — linear midpoint, no smoothing"; "Source: "+string(r.components{1}.path); ...
                "Original: "+r.initial_vertices+" vertices | "+r.initial_faces+" triangles"; ...
                "Output: "+r.vertices+" vertices | "+r.faces+" triangles"; strings(r.levels+1,1)];
            for k=1:r.levels, lines(4+k)="Level "+k+": "+r.level_counts(k,1)+" vertices | "+r.level_counts(k,2)+" triangles"; end
            lines(end)="SHA-256: "+string(r.components{1}.sha256); obj.Plan=candidate; obj.ReviewedFile=string(obj.File.Value); obj.ReviewedLevels=obj.Levels.Value; obj.Summary.Value=cellstr(lines); obj.Status.Text='Review complete. Confirm before saving.'; obj.updateSave();
        end
        function report=saveTo(obj,path)
            if isempty(obj.Plan) || string(obj.File.Value)~=obj.ReviewedFile || obj.Levels.Value~=obj.ReviewedLevels
                obj.invalidate(); error('BNV:Subdivision:ReviewRequired','Review the current source and subdivision level before saving.');
            end
            report=obj.Plan.write(path,CoordinateSpace=string(obj.Space.Value),Units=string(obj.Units.Value),Note=string(obj.Note.Value),Confirmed=obj.Confirmed.Value); obj.LastReport=report; obj.Status.Text=['Saved: ' report.output_path '. Load through Surface Mesh when ready.'];
        end
        function setTheme(obj,theme)
            if string(theme)=="dark", bg=[.094 .129 .173]; fg=[.92 .95 .98]; else, bg=[.96 .96 .96]; fg=[.086 .137 .227]; end
            obj.UIFigure.Color=bg; for g=reshape(findall(obj.UIFigure,'-isa','matlab.ui.container.GridLayout'),1,[]), g.BackgroundColor=bg; end
            for l=reshape(findall(obj.UIFigure,'Type','uilabel'),1,[]), l.FontColor=fg; end
            obj.Confirmed.FontColor=fg; obj.Summary.BackgroundColor=bg; obj.Summary.FontColor=fg;
        end
        function delete(obj), if ~isempty(obj.UIFigure)&&isvalid(obj.UIFigure), delete(obj.UIFigure); end, end
    end
    methods (Access=private)
        function field=textField(obj,parent,row,title,placeholder)
            g=uigridlayout(parent,[1 2]); g.Layout.Row=row; g.Padding=[0 0 0 0]; g.ColumnWidth={125,'1x'}; uilabel(g,'Text',title); field=uieditfield(g,'text','Placeholder',placeholder,'ValueChangedFcn',@(~,~) obj.clearConfirmation());
        end
        function clearConfirmation(obj), obj.Confirmed.Value=false; obj.updateSave(); end
        function invalidate(obj), obj.Plan=[]; obj.ReviewedFile=""; obj.ReviewedLevels=[]; obj.LastReport=struct(); obj.clearConfirmation(); obj.Summary.Value={'Input or level changed. Review before saving.'}; end
        function updateSave(obj), obj.SaveButton.Enable=matlab.lang.OnOffSwitchState(~isempty(obj.Plan)&&obj.Confirmed.Value); end
        function chooseInput(obj)
            [file,folder]=uigetfile({'*.nv;*.pial;*.mesh;*.g;*.obj;*.mz3;*.mz3.gz;*.gii;*.gii.gz','Supported surface files'},'Select one surface to subdivide'); if isequal(file,0), return; end; obj.setInput(fullfile(folder,file));
        end
        function chooseOutput(obj)
            [file,folder]=uiputfile({'*.nv','BrainNet surface'},'Save a new subdivided surface','subdivided.nv'); if isequal(file,0), return; end; obj.saveTo(fullfile(folder,file));
        end
        function run(obj,action)
            try
                action();
            catch failure
                obj.Status.Text=failure.message;
                if strcmp(failure.identifier,'BNV:Merge:InputChanged'), obj.clearConfirmation(); end
            end
        end
    end
end
