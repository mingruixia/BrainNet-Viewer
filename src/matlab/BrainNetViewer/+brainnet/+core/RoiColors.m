classdef RoiColors
    %ROICOLORS Explicit positive ROI ID to RGB mapping, never positional.
    methods (Static)
        function table = validate(table)
            if isnumeric(table) && isempty(table), table=zeros(0,4); return; end
            if ~isnumeric(table) || ~isreal(table) || ~ismatrix(table) || ...
                    size(table,2)~=4 || size(table,1)>10000 || any(~isfinite(table),'all') || ...
                    any(table(:,1)<1 | table(:,1)>flintmax | table(:,1)~=fix(table(:,1))) || ...
                    numel(unique(table(:,1)))~=size(table,1) || ...
                    any(table(:,2:4)<0 | table(:,2:4)>1,'all')
                error('BNV:ROI:InvalidColors','Use up to 10000 unique positive integer ROI IDs with three finite RGB values in [0,1].');
            end
            table=double(table);
        end
        function rgb = lookup(table, ids)
            table=brainnet.core.RoiColors.validate(table);
            [found,rows]=ismember(ids(:),table(:,1));
            if any(~found)
                missing=ids(~found); missing=missing(1:min(10,numel(missing)));
                error('BNV:ROI:MissingColor','Custom colors are missing for ROI IDs: %s.',mat2str(missing));
            end
            rgb=table(rows,2:4);
        end
        function table = parse(text)
            lines=splitlines(replace(join(string(text),newline),';',newline));
            lines=strip(lines); lines(lines=="")=[];
            table=zeros(numel(lines),4);
            for k=1:numel(lines)
                words=regexp(char(lines(k)),'[\s,]+','split');
                if numel(words)~=4
                    error('BNV:ROI:InvalidColors','Each row must contain ROI_ID R G B, without a header.');
                end
                table(k,:)=str2double(words);
            end
            table=brainnet.core.RoiColors.validate(table);
        end
        function lines = format(table)
            table=brainnet.core.RoiColors.validate(table);
            lines=strings(size(table,1),1);
            for k=1:size(table,1), lines(k)=sprintf('%.17g %.17g %.17g %.17g',table(k,:)); end
            if isempty(lines), lines=""; end
        end
        function table = read(path)
            [~,~,ext]=fileparts(path); info=dir(path);
            if ~any(strcmpi(ext,{'.txt','.csv'})) || numel(info)~=1 || info.isdir || info.bytes>2e6
                error('BNV:ROI:InvalidColorFile','Choose a TXT or CSV color table smaller than 2 MB.');
            end
            table=brainnet.core.RoiColors.parse(fileread(path));
        end
    end
end
