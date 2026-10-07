classdef CustomEdgeColors
    %CUSTOMEDGECOLORS Explicit category matrix bound to ordered node coordinates.
    methods (Static)
        function d=empty()
            d=struct('matrix',[],'indices',[],'node_sha256','','source','');
        end
        function d=validate(d)
            template=brainnet.core.CustomEdgeColors.empty();
            if ~isstruct(d) || ~isscalar(d) || ~isequal(sort(fieldnames(d)),sort(fieldnames(template)))
                error('BNV:EdgeCustom:Contract','Custom colors require matrix, indices, node_sha256 and source.');
            end
            m=d.matrix; codes=d.indices;
            if ~isnumeric(m) || ~isreal(m) || ~ismatrix(m) || numel(m)>4000000 || ...
                    size(m,1)~=size(m,2) || any(~isfinite(m),'all')
                error('BNV:EdgeCustom:Matrix','Custom colors require a finite square matrix with at most 4 million entries.');
            end
            if ~isnumeric(codes) || ~isreal(codes) || (~isempty(codes)&&~isvector(codes)) || ...
                    numel(codes)>4096 || any(~isfinite(codes),'all') || numel(unique(codes))~=numel(codes) || xor(isempty(m),isempty(codes))
                error('BNV:EdgeCustom:Indices','Provide 1-to-4096 unique finite category values for a nonempty matrix.');
            end
            if ~(ischar(d.node_sha256)||(isstring(d.node_sha256)&&isscalar(d.node_sha256))) || ...
                    (~isempty(d.node_sha256)&&isempty(regexp(char(d.node_sha256),'^[0-9a-f]{64}$','once')))
                error('BNV:EdgeCustom:Binding','Node binding must be empty or a lowercase SHA-256.');
            end
            if ~(ischar(d.source)||(isstring(d.source)&&isscalar(d.source)))
                error('BNV:EdgeCustom:Contract','Source must be text.');
            end
            d.matrix=double(m); d.indices=reshape(double(codes),1,[]); d.node_sha256=char(d.node_sha256); d.source=char(d.source);
            if isempty(m), d.matrix=[]; d.indices=[]; end
        end
        function hash=signature(coordinates)
            if ~isnumeric(coordinates)||~isreal(coordinates)||~ismatrix(coordinates)||size(coordinates,2)~=3||any(~isfinite(coordinates),'all')
                error('BNV:EdgeCustom:Nodes','Binding requires finite N-by-3 node coordinates in original order.');
            end
            hash=brainnet.core.BoundaryMask.signature(double(coordinates.'),zeros(0,3));
        end
        function d=bind(d,coordinates,confirmed)
            if ~isequal(confirmed,true), error('BNV:EdgeCustom:Confirmation','Confirm the matrix follows the original node order.'); end
            d=brainnet.core.CustomEdgeColors.validate(d);
            if isempty(d.matrix) || size(d.matrix,1)~=size(coordinates,1)
                error('BNV:EdgeCustom:Size','Color matrix dimensions must match the loaded node count.');
            end
            d.node_sha256=char(brainnet.core.CustomEdgeColors.signature(coordinates));
        end
        function colors=palette(map,count)
            if isnumeric(map)
                map=brainnet.core.Colormap.validate(map);
                if size(map,1)<count, error('BNV:EdgeCustom:Palette','The RGB table needs one row per category.'); end
            else
                map=brainnet.core.Colormap.sample(map,max(2,count));
            end
            colors=map(1:count,:);
        end
        function colors=resolve(d,map,coordinates,pairs)
            d=brainnet.core.CustomEdgeColors.validate(d);
            if isempty(d.matrix)||size(d.matrix,1)~=size(coordinates,1)
                error('BNV:EdgeCustom:Size','Load a color matrix matching the original node count.');
            end
            if isempty(d.node_sha256)||~strcmp(d.node_sha256,brainnet.core.CustomEdgeColors.signature(coordinates))
                error('BNV:EdgeCustom:Binding','Confirm and bind the color matrix to the currently loaded node order.');
            end
            if isempty(pairs), colors=zeros(0,3); return; end
            values=d.matrix(sub2ind(size(d.matrix),pairs(:,1),pairs(:,2)));
            [found,indices]=ismember(values,d.indices);
            if ~all(found), error('BNV:EdgeCustom:UnmappedCategory','A selected edge has no category-to-color mapping.'); end
            palette=brainnet.core.CustomEdgeColors.palette(map,numel(d.indices)); colors=palette(indices,:);
        end
    end
end
