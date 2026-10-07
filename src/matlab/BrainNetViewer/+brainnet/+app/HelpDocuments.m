classdef HelpDocuments
    %HELPDOCUMENTS Local documentation resolution and safe, read-only previews.
    methods (Static)
        function catalog=catalog(root)
            root=string(root); docs=fullfile(root,'docs');
            sourceDocs=fullfile(fileparts(fileparts(fileparts(root))),'docs');
            if ~isfolder(docs)&&isfile(fullfile(sourceDocs,'manual/en/index.md')), docs=sourceDocs; end
            catalog=struct('docs_root',char(docs),'manual_en',char(fullfile(docs,'manual/en/index.md')), ...
                'manual_zh',char(fullfile(docs,'manual/zh-CN/index.md')), ...
                'tutorials_en',char(fullfile(docs,'tutorials/unified/en/index.md')), ...
                'tutorials_zh',char(fullfile(docs,'tutorials/zh-CN/index.md')), ...
                'manual_pdf',char(fullfile(docs,'manual/en/BrainNet_Viewer_2_Unified_User_Manual_EN.pdf')));
        end
        function document=read(path,scope)
            path=brainnet.app.HelpDocuments.localPath(path,scope);
            [~,~,ext]=fileparts(path);
            if ~strcmpi(ext,'.md'), error('BNV:Help:UnsupportedDocument','Only Markdown pages can be previewed.'); end
            if ~isfile(path), error('BNV:Help:MissingDocument','Local documentation is missing: %s. Include the docs folder when installing this development build.',path); end
            info=dir(path);
            if info.bytes>2*1024*1024, error('BNV:Help:DocumentTooLarge','The help page exceeds the 2 MB preview limit.'); end
            fid=fopen(path,'r','n','UTF-8');
            if fid<0, error('BNV:Help:ReadFailed','Cannot read the local help page.'); end
            cleanup=onCleanup(@() fclose(fid)); content=string(fread(fid,Inf,'*char').');
            tokens=regexp(char(content),'!?\[([^\]]+)\]\(([^)]+)\)','tokens');
            links=struct('label',{},'target',{});
            for k=1:numel(tokens)
                links(end+1)=struct('label',tokens{k}{1},'target',tokens{k}{2}); %#ok<AGROW>
            end
            images=strings(1,numel(links));
            for k=1:numel(links)
                target=string(links(k).target);
                if contains(target,':')||startsWith(target,["/","\"]), continue; end
                try
                    media=brainnet.app.HelpDocuments.localPath(fullfile(fileparts(path),replace(target,'%20',' ')),scope);
                    [~,~,extension]=fileparts(media);
                    if ~ismember(lower(string(extension)),[".png",".jpg",".jpeg"])||~isfile(media), continue; end
                    mediaInfo=dir(media);
                    if mediaInfo.bytes>8*1024*1024, continue; end
                    mediaFile=fopen(media,'rb');
                    if mediaFile<0, continue; end
                    mediaCleanup=onCleanup(@() fclose(mediaFile));
                    bytes=fread(mediaFile,Inf,'*uint8'); clear mediaCleanup;
                    mime="image/png";
                    if ~strcmpi(extension,'.png'), mime="image/jpeg"; end
                    images(k)="data:"+mime+";base64,"+string(matlab.net.base64encode(bytes));
                catch
                    % Missing/out-of-scope images remain labelled resources.
                end
            end
            document=struct('path',char(path),'content',char(content),'links',links, ...
                'html',brainnet.app.HelpDocuments.render(content,links,images,path));
        end
        function path=localPath(path,scope)
            path=string(char(java.io.File(char(path)).getCanonicalPath()));
            scope=string(char(java.io.File(char(scope)).getCanonicalPath()));
            if ~startsWith(lower(path),lower(scope+string(filesep)))
                error('BNV:Help:OutsideDocumentation','The requested file is outside the documentation installation.');
            end
        end
        function html=render(content,links,images,page)
            if nargin<2, links=struct('label',{},'target',{}); end
            if nargin<3, images=strings(1,numel(links)); end
            if nargin<4, page=""; end
            % Escape source HTML; only this small Markdown subset becomes markup.
            rows=splitlines(string(content)); output=strings(0,1); code=false; table=false;
            for row=reshape(rows,1,[])
                if startsWith(strtrim(row),'```')
                    if table, output(end+1)="</table>"; table=false; end %#ok<AGROW>
                    if code, output(end+1)="</code></pre>"; else, output(end+1)="<pre><code>"; end %#ok<AGROW>
                    code=~code; continue;
                end
                escaped=brainnet.app.HelpDocuments.escape(row);
                if code, output(end+1)=escaped+newline; continue; end %#ok<AGROW>
                escaped=brainnet.app.HelpDocuments.inline(row,links,images);
                escaped=regexprep(escaped,'`([^`]+)`','<code>$1</code>');
                escaped=regexprep(escaped,'\*\*([^*]+)\*\*','<strong>$1</strong>');
                if startsWith(strtrim(row),'|')
                    if ~isempty(regexp(char(row),'^\s*\|[\s:|\-]+\|\s*$','once')), continue; end
                    if ~table, output(end+1)="<table>"; table=true; end %#ok<AGROW>
                    cells=split(strtrim(escaped),'|');
                    output(end+1)="<tr><td>"+join(cells(2:end-1),"</td><td>")+"</td></tr>"; %#ok<AGROW>
                    continue;
                end
                if table, output(end+1)="</table>"; table=false; end %#ok<AGROW>
                heading=regexp(char(row),'^(#{1,6})\s+','tokens','once');
                if ~isempty(heading)
                    level=string(numel(heading{1})); body=regexprep(escaped,'^#{1,6}\s+','');
                    output(end+1)="<h"+level+">"+body+"</h"+level+">"; %#ok<AGROW>
                elseif strlength(strtrim(row))>0
                    output(end+1)="<p>"+escaped+"</p>"; %#ok<AGROW>
                end
            end
            if code, output(end+1)="</code></pre>"; end
            if table, output(end+1)="</table>"; end
            html=char("<!doctype html><html><head><meta charset='utf-8'><style>"+ ...
                "body{font:15px Arial,sans-serif;padding:12px;color:#162338;background:#fff;line-height:1.5;overflow-wrap:anywhere}"+ ...
                "img{max-width:100%;height:auto;display:block;margin:12px auto}a{color:#075bc7;text-decoration:underline}"+ ...
                "table{border-collapse:collapse;width:100%}td{border:1px solid #ccd2da;padding:6px;vertical-align:top}"+ ...
                "pre{white-space:pre-wrap;background:#f1f4f8;padding:10px}code{font-family:monospace}"+ ...
                "</style><script>function setup(component){document.addEventListener('click',function(e){"+ ...
                "var a=e.target.closest('a[data-link]');if(!a)return;e.preventDefault();"+ ...
                "component.sendEventToMATLAB('HelpLink',{Index:Number(a.dataset.link),Page:document.body.dataset.page});"+ ...
                "});}</script></head><body data-page='"+brainnet.app.HelpDocuments.escape(page)+"'>"+ ...
                join(output,newline)+"</body></html>");
        end
        function html=inline(row,links,images)
            row=char(row);
            [starts,stops,tokens]=regexp(char(row),'(!?)\[([^\]]+)\]\(([^)]+)\)','start','end','tokens');
            html=""; offset=1;
            for k=1:numel(starts)
                html=html+brainnet.app.HelpDocuments.escape(row(offset:starts(k)-1));
                token=tokens{k}; label=brainnet.app.HelpDocuments.escape(token{2});
                index=find(strcmp({links.label},token{2})&strcmp({links.target},token{3}),1);
                if ~isempty(index)&&strcmp(token{1},'!')&&strlength(images(index))>0
                    html=html+"<img alt='"+label+"' src='"+images(index)+"'>";
                elseif ~isempty(index)&&isempty(token{1})
                    html=html+"<a href='#' data-link='"+string(index)+"'>"+label+"</a>";
                else
                    html=html+label;
                end
                offset=stops(k)+1;
            end
            html=html+brainnet.app.HelpDocuments.escape(row(offset:end));
        end
        function text=escape(text)
            text=replace(string(text),["&","<",">",'"',"'"],["&amp;","&lt;","&gt;","&quot;","&#39;"]);
        end
    end
end
