classdef Colormap
    %COLORMAP Safe named/RGB palettes and deterministic RGB interpolation.
    methods (Static)
        function names=names()
            names=["bwr","viridis","plasma","inferno","magma","cividis", ...
                "parula","jet","turbo","hsv","hot","cool","spring", ...
                "summer","autumn","winter","gray","bone","copper","pink", ...
                "lines","colorcube","prism","flag"];
        end
        function value=validate(value)
            if ischar(value) || (isstring(value) && isscalar(value) && ~ismissing(value))
                if ~isrow(value), error('BNV:Color:InvalidName','Colormap name must be scalar text.'); end
                value=lower(strtrim(string(value)));
                if ~any(value==brainnet.core.Colormap.names())
                    error('BNV:Color:InvalidName','Choose a supported colormap name or an RGB table; expressions are not executed.');
                end
                value=char(value);
            elseif isnumeric(value) && isreal(value) && ismatrix(value) && size(value,2)==3 && ...
                    size(value,1)>=2 && size(value,1)<=4096 && all(isfinite(value),'all') && ...
                    all(value>=0 & value<=1,'all')
                value=double(value);
            else
                error('BNV:Color:InvalidRGB','A colormap must be a real finite 2-to-4096 by 3 RGB table in [0,1].');
            end
        end
        function colors=sample(value,count)
            arguments
                value
                count (1,1) double {mustBeInteger,mustBePositive} = 256
            end
            value=brainnet.core.Colormap.validate(value);
            if ischar(value)
                if strcmp(value,'bwr')
                    colors=interp1([0 .5 1],[0 0 1;1 1 1;1 0 0], ...
                        linspace(0,1,count),'linear');
                elseif any(strcmp(value,{'viridis','plasma','inferno','magma','cividis'}))
                    reference=brainnet.core.scientificColormap(value);
                    if count==256
                        colors=reference;
                    else
                        colors=interp1(linspace(0,1,256),reference, ...
                            linspace(0,1,count),'linear');
                    end
                else
                    colors=feval(value,count); % Fixed whitelist only.
                end
            elseif size(value,1)==count
                colors=value;
            else
                colors=interp1(linspace(0,1,size(value,1)),value,linspace(0,1,count),'linear');
                colors=min(max(colors,0),1);
            end
        end
        function value=parse(text)
            text=strtrim(char(string(text)));
            if startsWith(text,'[') && endsWith(text,']'), text=text(2:end-1); end
            rows=regexp(strrep(text,sprintf('\r'),''),'[;\n]','split');
            rows=rows(~cellfun(@(x) isempty(strtrim(x)),rows));
            if numel(rows)<2 || numel(rows)>4096
                error('BNV:Color:InvalidRGB','Expected 2 to 4096 RGB rows.');
            end
            number='[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?';
            pattern=['^\s*(' number ')[\s,]+(' number ')[\s,]+(' number ')\s*$'];
            value=zeros(numel(rows),3);
            for i=1:numel(rows)
                tokens=regexp(rows{i},pattern,'tokens','once');
                if isempty(tokens), error('BNV:Color:InvalidText','Use three RGB numbers per row, not MATLAB expressions.'); end
                value(i,:)=str2double(tokens);
            end
            value=brainnet.core.Colormap.validate(value);
        end
        function yes=hasCustom(settings)
            d=settings.toStruct();
            yes=isnumeric(d.surface.colormap) || isnumeric(d.node.colormap) || ...
                isnumeric(d.edge.colormap) || isnumeric(d.volume.colormap) || ...
                isnumeric(d.fiber.colormap);
        end
    end
end
