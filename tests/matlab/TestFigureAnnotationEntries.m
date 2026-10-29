classdef TestFigureAnnotationEntries < matlab.unittest.TestCase
    methods (Test)
        function signedAndAbsoluteRanges(t)
            p=fixture();s=brainnet.core.VisualizationSettings().withPatch(struct( ...
                'image',struct('show_colorbar',true),'node',struct('color_mode','mapped'), ...
                'edge',struct('color_mode','mapped','mapped_value_mode','absolute')));
            e=brainnet.render.internal.figureAnnotationEntries(p,s);
            t.verifyEqual({e.name},{'Node','Edge'});
            t.verifyEqual(e(1).limits,[-2 3]);t.verifyEqual(e(2).limits,[.7 .8]);
            s=s.withPatch(struct('node',struct('color_limits',[-5 5]), ...
                'edge',struct('mapped_value_mode','signed','color_limits',[-1 1])));
            e=brainnet.render.internal.figureAnnotationEntries(p,s);
            t.verifyEqual(e(1).limits,[-5 5]);t.verifyEqual(e(2).limits,[-1 1]);
        end
        function categoryLabelsAndColors(t)
            p=fixture();map=[1 0 0;0 1 0;0 0 1];
            s=brainnet.core.VisualizationSettings().withPatch(struct('image',struct('show_colorbar',true), ...
                'node',struct('color_mode','modular','colormap',map), ...
                'edge',struct('color_mode','node-module','inter_module_color',[.5 .5 .5])));
            e=brainnet.render.internal.figureAnnotationEntries(p,s);
            t.verifyEqual(e(1).labels,["-2";"1";"3"]);t.verifyEqual(e(1).map,map);
            t.verifyEqual(e(2).labels,["Module -2";"Module 1";"Module 3";"Between modules"]);
            t.verifyEqual(e(2).map,[map;.5 .5 .5]);
            s=s.withPatch(struct('node',struct('color_mode','uniform'),'edge',struct('color_mode','length','length_threshold',75)));
            e=brainnet.render.internal.figureAnnotationEntries(p,s);
            t.verifyEqual(e.labels,["Length < 75";"Length >= 75"]);
        end
        function switchAndMissingData(t)
            p=fixture();s=brainnet.core.VisualizationSettings();
            t.verifyEmpty(brainnet.render.internal.figureAnnotationEntries(p,s));
            s=s.withPatch(struct('image',struct('show_colorbar',true)));
            p.NodeCount=0;t.verifyEmpty(brainnet.render.internal.figureAnnotationEntries(p,s));
        end
    end
end
function p=fixture()
p=struct('NodeCount',3,'EdgeCount',2,'NodeModules',[-2;1;3],'EdgeValues',[-.7;.8],'RoiMeshes',[]);
end
