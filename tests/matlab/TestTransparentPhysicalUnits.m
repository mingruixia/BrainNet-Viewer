classdef TestTransparentPhysicalUnits < matlab.unittest.TestCase
    methods (Test)
        function matteReplayUsesNormalizedPixelUnits(testCase)
            testCase.assumeFalse(verLessThan('matlab','25.1'));
            folder=string(tempname);mkdir(folder);
            cleanup=onCleanup(@()removeFixture(folder)); %#ok<NASGU>
            % Intercept only the native renderer: catch an oversized replay
            % before allocation, while exercising the real export transaction.
            code=join(["function exportgraphics(~,path,varargin)"; ...
                "global BNVPhysicalUnitsTrace;"; ...
                "get=@(key)varargin{find(strcmp(varargin(1:2:end),key),1)*2};"; ...
                "units=string(get('Units'));w=get('Width');h=get('Height');dpi=get('Resolution');"; ...
                "row=struct('units',units,'width',w,'height',h);BNVPhysicalUnitsTrace=[BNVPhysicalUnitsTrace row];"; ...
                "if numel(BNVPhysicalUnitsTrace)>1 && units~='pixels',error('BNV:Test:MatteUnitMismatch','Matte replay used %g x %g %s instead of normalized pixels.',w,h,units);end"; ...
                "factor=1;switch units,case 'inches',factor=dpi;case 'centimeters',factor=dpi/2.54;case 'millimeters',factor=dpi/25.4;case 'points',factor=dpi/72;end"; ...
                "w=round(w*factor);h=round(h*factor);assert(w<=400&&h<=300,'Oversized synthetic frame.');"; ...
                "bg=get('BackgroundColor');if ~isnumeric(bg),bg=[1 1 1];end"; ...
                "pixels=repmat(reshape(uint8(round(255*bg)),1,1,3),h,w,1);"; ...
                "pixels(41:90,51:120,:)=repmat(reshape(uint8([20 80 140]),1,1,3),50,70,1);imwrite(pixels,path);"; ...
                "end"],newline);
            f=fopen(fullfile(folder,'exportgraphics.m'),'w');fprintf(f,'%s',code);fclose(f);
            addpath(folder,'-begin');clear exportgraphics;
            window=figure('Visible','off','Position',[100 100 1000 300]);
            cleanupWindow=onCleanup(@()delete(window)); %#ok<NASGU>
            scene=brainnet.core.Scene("units-fixture","Physical units",0,0,{});
            prepared=brainnet.render.PreparedScene(scene,"fixture",struct(),struct(),"units-fixture");
            exporter=brainnet.export.FigureExporter(fullfile(folder,'output'));
            units=["pixels","inches","centimeters","millimeters","points"];
            widths=[400 4 10.16 101.6 288];heights=[300 3 7.62 76.2 216];
            global BNVPhysicalUnitsTrace;
            for k=1:numel(units)
                BNVPhysicalUnitsTrace=[];name="units-"+k+".png";
                record=exporter.exportFigure(window,name,scene,prepared,struct(), ...
                    Width=widths(k),Height=heights(k),Units=units(k),Resolution=100,BackgroundColor="none");
                [rgb,~,alpha]=imread(fullfile(folder,'output',name));
                testCase.verifySize(rgb,[300 400 3]);testCase.verifyEqual([min(alpha(:)) max(alpha(:))],uint8([0 255]));
                testCase.verifyEqual(string(record.export.units),units(k));
                testCase.verifyEqual(record.export.width,widths(k));
                testCase.verifyGreaterThanOrEqual(numel(BNVPhysicalUnitsTrace),3);
                testCase.verifyTrue(all(string({BNVPhysicalUnitsTrace(2:end).units})=="pixels"));
            end
        end
    end
end
function removeFixture(folder)
if contains(path,char(folder)),rmpath(folder);end
clear exportgraphics;clear global BNVPhysicalUnitsTrace;
if isfolder(folder),rmdir(folder,'s');end
end
