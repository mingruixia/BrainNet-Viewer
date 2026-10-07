classdef GraphicsPicker
    %GRAPHICSPICKER Resolve a merged node glyph to its original node index.
    methods (Static)
        function [index,method]=surfaceIndex(p,point)
            %SURFACEINDEX Resolve a displayed surface hit to its source vertex.
            if ~isstruct(p.UserData) || ~isfield(p.UserData,'surface_indices')
                error('BNV:Query:SurfacePickData','The rendered surface has no source-vertex mapping.');
            end
            vertices=p.Vertices;
            [~,vertex]=min(sum((vertices-point).^2,2));
            indices=p.UserData.surface_indices;
            if vertex>numel(indices)
                error('BNV:Query:SurfacePickData','The rendered surface vertex mapping is inconsistent.');
            end
            index=indices(vertex);
            method='nearest displayed surface vertex';
        end

        function [index,method]=nodeIndex(p,point)
            ids=p.UserData.brainnet_node_indices;
            vertices=p.Vertices; faces=p.Faces;
            % Match the reported intersection against triangles, avoiding a
            % nearest-centre heuristic when glyph radii differ or overlap.
            a=vertices(faces(:,1),:); u=vertices(faces(:,2),:)-a; v=vertices(faces(:,3),:)-a;
            w=point-a; uu=sum(u.*u,2); vv=sum(v.*v,2); uv=sum(u.*v,2);
            wu=sum(w.*u,2); wv=sum(w.*v,2); denominator=uu.*vv-uv.^2;
            s=(wu.*vv-wv.*uv)./denominator; t=(wv.*uu-wu.*uv)./denominator;
            normal=cross(u,v,2); normalLength=sqrt(sum(normal.^2,2));
            planeDistance=abs(sum(w.*normal,2))./normalLength;
            tolerance=1e-5*max(1,max(max(vertices)-min(vertices)));
            hit=find(planeDistance<=tolerance & s>=-1e-5 & t>=-1e-5 & s+t<=1+1e-5 & denominator>0,1);
            if isempty(hit)
                [~,vertex]=min(sum((vertices-point).^2,2));
                method='nearest displayed glyph vertex fallback';
            else
                vertex=faces(hit,1); method='displayed glyph triangle intersection';
            end
            perNode=size(vertices,1)/numel(ids);
            index=ids(1+floor((vertex-1)/perNode));
        end
    end
end
