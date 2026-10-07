classdef SurfaceMergeWindow < handle
    %SURFACEMERGEWINDOW Review geometry before publishing a new mesh.
    properties (SetAccess=private)
        UIFigure
        Files
        Summary
        Space
        Units
        Note
        Confirmed
        SaveButton
        Status
        Paths string = strings(0,1)
        Plan = []
        LastReport struct = struct()
        Operation (1,1) string = "merge"
    end
    properties (Access=private)
        DialogFocusTimer = []
    end
    methods
        function obj=SurfaceMergeWindow(options)
            arguments
                options.Visible (1,1) logical=true
                options.Theme (1,1) string="light"
                options.Operation (1,1) string {mustBeMember(options.Operation,["merge","convert"])}="merge"
                options.Parent = []
            end
            obj.Operation=options.Operation; converting=obj.Operation=="convert";
            obj.UIFigure=uifigure('Name','Merge Surfaces','Tag','SurfaceMergeWindow','Visible','off', ...
                'CloseRequestFcn',@(~,~) delete(obj));
            if converting, obj.UIFigure.Name='Convert Surface to NV'; obj.UIFigure.Tag='SurfaceConversionWindow'; end
            obj.UIFigure.Position=brainnet.render.internal.screenAwarePosition( ...
                [800 740],MinimumSize=[620 580], ...
                AnchorPoint=brainnet.render.internal.figureAnchorPoint(options.Parent));
            g=uigridlayout(obj.UIFigure,[10 1]);
            g.RowHeight={42,'1x',32,'1x',28,28,28,42,38,32};
            if ~converting, g.RowHeight{8}=0; end
            description='Join 2 to 64 surfaces in list order. Coordinates and triangle winding are retained; no registration, vertex welding or color/map transfer.';
            if converting, description='Convert ONE surface to NV. Raw coordinates, vertex order and triangles are retained. Colors, maps and active coordinate transforms are NOT transferred.'; end
            uilabel(g,'Text',description, ...
                'WordWrap','on');
            obj.Files=uilistbox(g,'Items',{},'Multiselect','off');
            a=uigridlayout(g,[1 5]); a.Layout.Row=3; a.Padding=[0 0 0 0];
            select=uibutton(a,'Text','Add Files...','ButtonPushedFcn',@(~,~) obj.run(@() obj.chooseFiles()));
            if converting, select.Text='Choose File...'; end
            uibutton(a,'Text','Remove','ButtonPushedFcn',@(~,~) obj.run(@() obj.removeSelected()));
            up=uibutton(a,'Text','Move Up','ButtonPushedFcn',@(~,~) obj.run(@() obj.moveSelected(-1)));
            down=uibutton(a,'Text','Move Down','ButtonPushedFcn',@(~,~) obj.run(@() obj.moveSelected(1)));
            if converting
                uibutton(a,'Text','Review Inputs','Tag','ReviewMergeInputs','ButtonPushedFcn',@(~,~) obj.run(@() obj.review()));
            else
                a.ColumnWidth={'1x','1x','1x','1x'};
            end
            if converting, delete(up); delete(down); a.ColumnWidth={'1x','1x',0,0,'1x'}; end
            obj.Summary=uitextarea(g,'Editable','off','Value',{'Add at least two surfaces. Inputs are reviewed automatically.'});
            if converting, obj.Summary.Value={'Choose a file, then Review Inputs to inspect geometry.'}; end
            obj.Summary.Layout.Row=4;
            obj.Space=obj.textField(g,5,'Space (optional)','For example: subject-01 native scanner space; blank is unknown');
            obj.Units=obj.textField(g,6,'Units (optional)','For example: mm; no unit conversion');
            obj.Note=obj.textField(g,7,'Note (optional)','Optional provenance note');
            if converting
                obj.Space.Placeholder='Optional: raw coordinate space; blank is unknown';
                obj.Units.Placeholder='Optional: raw coordinate units; no conversion';
                obj.Note.Placeholder='Optional provenance note';
                label=findall(g,'Type','uilabel','Text','Space (optional)'); label.Text='Raw space';
            end
            if converting
            obj.Confirmed=uicheckbox(g,'Text','I reviewed geometry-only conversion; colors/maps and active transforms are not transferred.', ...
                'WordWrap','on','ValueChangedFcn',@(~,~) obj.updateSave()); obj.Confirmed.Layout.Row=8;
            end
            obj.Status=uilabel(g,'Text','No input files are modified. A shared name is not proof of registration.', ...
                'WordWrap','on'); obj.Status.Layout.Row=9;
            if converting, obj.Status.Text='No source or active Scene is modified. Space and units may remain unknown.'; end
            actions=uigridlayout(g,[1 2]); actions.Layout.Row=10; actions.Padding=[0 0 0 0];
            obj.SaveButton=uibutton(actions,'Text','Save New .nv...','Enable','off','Tag','SaveMergedSurface', ...
                'ButtonPushedFcn',@(~,~) obj.run(@() obj.chooseOutput()));
            uibutton(actions,'Text','Close','ButtonPushedFcn',@(~,~) delete(obj));
            obj.setTheme(options.Theme); obj.UIFigure.Visible=matlab.lang.OnOffSwitchState(options.Visible);
        end
        function setFiles(obj,paths)
            paths=string(paths(:));
            if obj.Operation=="convert" && numel(paths)>1
                error('BNV:Merge:InputCount','Choose exactly one surface to convert.');
            end
            obj.Paths=paths; obj.Files.Items=cellstr(paths); obj.Files.ItemsData=cellstr(string(1:numel(paths)));
            if ~isempty(paths), obj.Files.Value='1'; end
            obj.invalidate();
            if obj.Operation=="merge" && numel(paths)>=2, obj.review(); end
        end
        function review(obj)
            obj.invalidate(); drawnow;
            candidate=brainnet.tools.SurfaceMergePlan(obj.Paths,Operation=obj.Operation);
            lines=["INPUT REVIEW — raw coordinates, no transforms applied"; ...
                string(candidate.Report.vertices)+" vertices | "+string(candidate.Report.faces)+" triangles"];
            for k=1:numel(candidate.Report.components)
                c=candidate.Report.components{k}; b=c.bounds;
                lines=[lines;"";string(k)+". "+string(c.path); ...
                    sprintf('%d vertices [%d:%d] | %d faces [%d:%d]',c.vertices,c.vertex_range,c.faces,c.face_range); ...
                    sprintf('Bounds XYZ: [%g, %g] / [%g, %g] / [%g, %g]',b(:,1),b(:,2),b(:,3)); ...
                    "SHA-256: "+string(c.sha256)]; %#ok<AGROW>
            end
            obj.Plan=candidate; obj.Summary.Value=cellstr(lines);
            obj.Status.Text='Inputs reviewed. Ready to save; space, units and note are optional. No registration is applied.';
            if obj.Operation=="convert", obj.Status.Text='Review complete. Confirm raw geometry-only conversion before saving.'; end
            obj.updateSave();
        end
        function report=saveTo(obj,path)
            if isempty(obj.Plan), error('BNV:Merge:ReviewRequired','Review the current inputs before saving.'); end
            report=obj.Plan.write(path,CoordinateSpace=string(obj.Space.Value),Units=string(obj.Units.Value), ...
                Note=string(obj.Note.Value),Confirmed=isempty(obj.Confirmed)||obj.Confirmed.Value);
            obj.LastReport=report;
            obj.Status.Text=['Saved: ' report.output_path '. Load it through Surface Mesh when ready.'];
        end
        function setTheme(obj,theme)
            if string(theme)=="dark", bg=[.094 .129 .173]; fg=[.92 .95 .98];
            else, bg=[.96 .96 .96]; fg=[.086 .137 .227]; end
            obj.UIFigure.Color=bg;
            for g=reshape(findall(obj.UIFigure,'-isa','matlab.ui.container.GridLayout'),1,[]), g.BackgroundColor=bg; end
            for l=reshape(findall(obj.UIFigure,'Type','uilabel'),1,[]), l.FontColor=fg; end
            if ~isempty(obj.Confirmed), obj.Confirmed.FontColor=fg; end
            obj.Summary.BackgroundColor=bg; obj.Summary.FontColor=fg;
        end
        function delete(obj)
            obj.stopDialogFocusTimer();
            if ~isempty(obj.UIFigure) && isvalid(obj.UIFigure), delete(obj.UIFigure); end
        end
    end
    methods (Access=private)
        function field=textField(obj,parent,row,title,placeholder)
            g=uigridlayout(parent,[1 2]); g.Layout.Row=row; g.Padding=[0 0 0 0]; g.ColumnWidth={125,'1x'};
            uilabel(g,'Text',title); field=uieditfield(g,'text','Placeholder',placeholder, ...
                'ValueChangedFcn',@(~,~) obj.clearConfirmation());
        end
        function clearConfirmation(obj)
            if ~isempty(obj.Confirmed), obj.Confirmed.Value=false; end
            obj.updateSave();
        end
        function invalidate(obj)
            obj.Plan=[]; obj.LastReport=struct(); obj.clearConfirmation();
            obj.Summary.Value={'Add at least two surfaces. Inputs are reviewed automatically.'};
            if obj.Operation=="convert", obj.Summary.Value={'Inputs changed. Review Inputs before saving.'}; end
            obj.Status.Text='No output has been written for this selection.';
        end
        function updateSave(obj)
            obj.SaveButton.Enable=matlab.lang.OnOffSwitchState(~isempty(obj.Plan) && (isempty(obj.Confirmed)||obj.Confirmed.Value));
        end
        function chooseFiles(obj)
            focusCleanup=onCleanup(@() obj.restoreDialogFocus()); %#ok<NASGU>
            if obj.Operation=="convert"
                [file,folder]=uigetfile({'*.nv;*.pial;*.mesh;*.g;*.obj;*.mz3;*.mz3.gz;*.gii;*.gii.gz','Supported surface files'},'Select one surface to convert');
                if isequal(file,0), return; end
                obj.setFiles(fullfile(folder,file)); return;
            end
            [files,folder]=uigetfile({'*.nv;*.pial;*.mesh;*.g;*.obj;*.mz3;*.mz3.gz;*.gii;*.gii.gz','Supported surface files'}, ...
                'Select surfaces to merge','MultiSelect','on');
            if isequal(files,0), return; end
            obj.setFiles([obj.Paths;reshape(fullfile(string(folder),string(files)),[],1)]);
        end
        function removeSelected(obj)
            if isempty(obj.Paths), return; end
            index=str2double(obj.Files.Value); paths=obj.Paths; paths(index)=[]; obj.setFiles(paths);
        end
        function moveSelected(obj,offset)
            if isempty(obj.Paths), return; end
            index=str2double(obj.Files.Value); target=index+offset;
            if target<1 || target>numel(obj.Paths), return; end
            paths=obj.Paths; paths([index target])=paths([target index]); obj.setFiles(paths); obj.Files.Value=char(string(target));
        end
        function chooseOutput(obj)
            focusCleanup=onCleanup(@() obj.restoreDialogFocus()); %#ok<NASGU>
            title='Save a new merged surface'; name='merged.nv';
            if obj.Operation=="convert", title='Save a new converted surface'; name='converted.nv'; end
            [file,folder]=uiputfile({'*.nv','BrainNet surface'},title,name);
            if isequal(file,0), return; end
            obj.saveTo(fullfile(folder,file));
        end
        function run(obj,action)
            try
                action();
            catch failure
                obj.Status.Text=failure.message;
                if strcmp(failure.identifier,'BNV:Merge:InputChanged')
                    obj.Plan=[]; obj.clearConfirmation();
                end
            end
        end
        function restoreDialogFocus(obj)
            if ~isvalid(obj) || ~isgraphics(obj.UIFigure) || strcmp(obj.UIFigure.Visible,'off'), return; end
            figure(obj.UIFigure);
            obj.stopDialogFocusTimer();
            obj.DialogFocusTimer=timer('ExecutionMode','singleShot','StartDelay',0.15, ...
                'TimerFcn',@(~,~) obj.finishDialogFocus());
            start(obj.DialogFocusTimer);
        end
        function finishDialogFocus(obj)
            if isgraphics(obj.UIFigure) && strcmp(obj.UIFigure.Visible,'on')
                figure(obj.UIFigure);
            end
            obj.stopDialogFocusTimer();
        end
        function stopDialogFocusTimer(obj)
            pending=obj.DialogFocusTimer; obj.DialogFocusTimer=[];
            if ~isempty(pending)&&isvalid(pending), stop(pending); delete(pending); end
        end
    end
end
