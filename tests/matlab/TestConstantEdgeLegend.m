classdef TestConstantEdgeLegend < matlab.unittest.TestCase
    % A degenerate Edge domain maps to the final LUT entry, not the first.
    methods (Test)
        function signedConstantUsesHighEndpoint(t)
            for value=[-2 0 1 1e100]
                [p,s]=fixture([value;value],'signed',[]);
                entry=brainnet.render.internal.figureAnnotationEntries(p,s);
                t.verifyEqual(entry.limits(2),value);
                t.verifyLessThan(entry.limits(1),entry.limits(2));
                t.verifyTrue(all(isfinite(entry.limits)));
                colors=brainnet.render.internal.mappedEdgeColors(p.EdgeValues,s.section('edge'));
                t.verifyEqual(colors,repmat(entry.map(end,:),2,1));
            end
        end
        function absoluteConstantUsesTransformedEndpoint(t)
            [p,s]=fixture([-2;-2],'absolute',[]);
            entry=brainnet.render.internal.figureAnnotationEntries(p,s);
            t.verifyEqual(entry.limits(2),2);
            colors=brainnet.render.internal.mappedEdgeColors(p.EdgeValues,s.section('edge'));
            t.verifyEqual(colors,repmat(entry.map(end,:),2,1));
        end
        function explicitDegenerateRangeKeepsMappedColor(t)
            [p,s]=fixture([-1;2],'signed',[.5 .5]);
            entry=brainnet.render.internal.figureAnnotationEntries(p,s);
            t.verifyEqual(entry.limits(2),.5);
            colors=brainnet.render.internal.mappedEdgeColors(p.EdgeValues,s.section('edge'));
            t.verifyEqual(colors,repmat(entry.map(end,:),2,1));
        end
        function nonconstantAndNodeConventionsStayUnchanged(t)
            [p,s]=fixture([-2;3],'signed',[]);
            s=s.withPatch(struct('node',struct('color_mode','mapped')));
            entries=brainnet.render.internal.figureAnnotationEntries(p,s);
            t.verifyEqual({entries.name},{'Node','Edge'});
            t.verifyEqual(entries(1).limits,[1 2]);
            t.verifyEqual(entries(2).limits,[-2 3]);
            s=s.withPatch(struct('edge',struct('color_limits',[-5 5])));
            entries=brainnet.render.internal.figureAnnotationEntries(p,s);
            t.verifyEqual(entries(2).limits,[-5 5]);
        end
        function minimumFiniteValueHasFiniteSingleColorLegend(t)
            [p,s]=fixture([-realmax;-realmax],'signed',[]);
            entry=brainnet.render.internal.figureAnnotationEntries(p,s);
            t.verifyTrue(all(isfinite(entry.limits)));
            t.verifyLessThan(entry.limits(1),entry.limits(2));
            colors=brainnet.render.internal.mappedEdgeColors(p.EdgeValues,s.section('edge'));
            t.verifyEqual(entry.map,repmat(colors(1,:),64,1));
            t.verifyLessThanOrEqual(entry.limits(1),-realmax);
            t.verifyGreaterThanOrEqual(entry.limits(2),-realmax);
        end
    end
end
function [p,s]=fixture(values,mode,limits)
p=struct('NodeCount',2,'EdgeCount',numel(values),'NodeModules',[1;1], ...
    'EdgeValues',values,'RoiMeshes',[]);
s=brainnet.core.VisualizationSettings().withPatch(struct('image',struct('show_colorbar',true), ...
    'node',struct('color_mode','uniform'), ...
    'edge',struct('color_mode','mapped','mapped_value_mode',mode,'color_limits',limits)));
end
