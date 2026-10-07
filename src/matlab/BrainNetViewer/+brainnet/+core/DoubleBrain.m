classdef DoubleBrain
    %DOUBLEBRAIN Legacy display transform; never changes source data.
    methods (Static)
        function requireScene(options,scene)
            hasSurface=true; hasMapping=false;
            if ~isempty(scene)
                roles=string(cellfun(@(x) char(x.Role),scene.Inputs,'UniformOutput',false));
                hasSurface=any(roles=="surface"); hasMapping=any(ismember(roles,["volume","surface_map"]));
            end
            brainnet.core.DoubleBrain.requireSupported(options,hasSurface,hasMapping);
        end
        function requireSupported(options, hasSurface, hasMapping)
            s=options.section('surface');
            if ~s.double_brain, return; end
            if options.Layout~=1 || ~ismember(options.ViewDirection,1:3)
                error('BNV:DoubleBrain:Layout','Double Brain requires Single View and Left, Superior or Anterior direction.');
            end
            if ~hasSurface || hasMapping || ~ismember(string(s.color_mode),["uniform","vertex-rgb"])
                error('BNV:DoubleBrain:Inputs','Double Brain requires a surface with optional nodes/edges and uniform or vertex RGB color; volume, ROI and scalar maps are not supported.');
            end
        end
        function value=transform(prepared,options)
            s=options.section('surface');
            value=struct('enabled',logical(s.double_brain),'matrix',eye(3), ...
                'offset',[0 0 0],'first_moved_node',floor(prepared.NodeCount/2)+1);
            brainnet.core.DoubleBrain.requireSupported(options,prepared.FaceCount>0, ...
                prepared.RoiCount>0 || ~isempty(prepared.SurfaceValues));
            if ~value.enabled, return; end
            xyz=prepared.SurfaceCoordinates'; span=max(xyz)-min(xyz);
            switch options.ViewDirection
                case 1
                    value.matrix=diag([-1 -1 1]);
                    value.offset=[0 2*min(xyz(:,2))-0.1*span(2) 0]; separation=span(2);
                case 2
                    value.offset=[1.1*span(1) 0 0]; separation=span(1);
                case 3
                    value.offset=[-1.1*span(1) 0 0]; separation=span(1);
            end
            if separation<=0
                error('BNV:DoubleBrain:DegenerateSurface','The surface has zero extent in the Double Brain separation direction.');
            end
        end
        function xyz=forward(xyz,transform)
            xyz=xyz*transform.matrix'+transform.offset;
        end
        function xyz=inverse(xyz,transform)
            xyz=(xyz-transform.offset)*transform.matrix;
        end
        function point=sourcePoint(graphic,point,index)
            % Pick the displayed glyph before converting its hit coordinate.
            if nargin<3, index=0; end
            data=graphic.UserData;
            if isstruct(data) && isfield(data,'double_brain')
                transform=data.double_brain;
                if index==0 || index>=transform.first_moved_node
                    point=brainnet.core.DoubleBrain.inverse(point,transform);
                end
            end
        end
    end
end
