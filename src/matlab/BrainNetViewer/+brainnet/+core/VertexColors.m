classdef VertexColors
    %VERTEXCOLORS Original-order, mesh-bound RGB tables; no implicit rescaling.
    methods (Static)
        function rgb=validate(rgb)
            if isempty(rgb), rgb=zeros(0,3); return; end
            if ~isnumeric(rgb) || ~isreal(rgb) || ~ismatrix(rgb) || size(rgb,2)~=3 || ...
                    size(rgb,1)>1000000 || any(~isfinite(rgb),'all') || any(rgb<0 | rgb>1,'all')
                error('BNV:VertexColors:InvalidTable','RGB must have three columns in [0,1], at most 1000000 rows, and no NaN/Inf.');
            end
            rgb=double(rgb);
        end
        function patch=bind(rgb,coordinates,faces,doubleBrain,confirmed,source)
            if ~isequal(confirmed,true)
                error('BNV:VertexColors:ConfirmationRequired','Confirm that rows follow the original surface vertex order.');
            end
            rgb=brainnet.core.VertexColors.validate(rgb);
            expected=size(coordinates,2)*(1+double(doubleBrain));
            if isempty(rgb) || size(rgb,1)~=expected
                error('BNV:VertexColors:RowCount','Expected %d RGB rows (N for one brain; 2N for Double Brain).',expected);
            end
            patch=struct('color_mode','vertex-rgb','vertex_colors',rgb, ...
                'vertex_colors_mesh_sha256',char(brainnet.core.BoundaryMask.signature(coordinates,faces)), ...
                'vertex_colors_source',char(source));
        end
        function requireBound(settings,coordinates,faces)
            if string(settings.color_mode)~="vertex-rgb", return; end
            brainnet.core.VertexColors.bind(settings.vertex_colors,coordinates,faces,settings.double_brain,true,'');
            if string(settings.vertex_colors_mesh_sha256)~=brainnet.core.BoundaryMask.signature(coordinates,faces)
                error('BNV:VertexColors:Binding','RGB table is unbound or belongs to different ordered surface geometry. Confirm and bind the table before rendering.');
            end
        end
    end
end
