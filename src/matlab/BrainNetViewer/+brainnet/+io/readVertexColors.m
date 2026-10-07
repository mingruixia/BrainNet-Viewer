function rgb=readVertexColors(path)
%READVERTEXCOLORS Strict whitespace-separated TXT rows, optional # comments.
info=dir(path);
if numel(info)~=1 || info.isdir || info.bytes>64*1024*1024
    error('BNV:VertexColors:File','Choose one RGB text file no larger than 64 MiB.');
end
lines=splitlines(string(fileread(path))); rgb=zeros(min(numel(lines),1000000),3); count=0;
for index=1:numel(lines)
    line=strtrim(regexprep(lines(index),'#.*$',''));
    if strlength(line)==0, continue; end
    fields=regexp(char(line),'\s+','split'); values=str2double(fields);
    if numel(values)~=3 || any(~isfinite(values)) || any(values<0 | values>1)
        error('BNV:VertexColors:TextRow','Line %d must contain exactly three RGB numbers in [0,1].',index);
    end
    count=count+1;
    if count>1000000, error('BNV:VertexColors:TooManyRows','RGB tables are limited to 1000000 rows.'); end
    rgb(count,:)=reshape(values,1,3);
end
if count==0, error('BNV:VertexColors:EmptyTable','The RGB table is empty.'); end
rgb=brainnet.core.VertexColors.validate(rgb(1:count,:));
end
