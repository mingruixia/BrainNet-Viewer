"""Serve approved local documentation with escaped, dependency-free previews."""
from html import escape
from pathlib import Path
import re
from urllib.parse import urlsplit,quote,unquote


def render_page(text,source,root):
    def link(match):
        image,label,target=match.groups(); parts=urlsplit(target)
        if parts.scheme:
            url=target if parts.scheme in ('http','https','mailto') else ''
        else:
            path=(source.parent/unquote(parts.path)).resolve()
            if not path.is_relative_to(root): url=''
            else:
                suffix='.html' if path.suffix=='.md' else path.suffix
                relative=path.relative_to(root).with_suffix(suffix).as_posix()
                url=('/bnv-help-pages/' if path.suffix=='.md' else '/bnv-help-assets/')+quote(relative)
                if parts.fragment: url+='#'+quote(parts.fragment)
        if not url: return escape(label)
        if image: return f'<img alt="{escape(label)}" src="{escape(url,quote=True)}">'
        return f'<a href="{escape(url,quote=True)}">{escape(label)}</a>'
    def inline(line):
        result=[]; offset=0
        for match in re.finditer(r'(!?)\[([^\]]*)\]\(([^\s)]+)\)',line):
            result.extend((escape(line[offset:match.start()]),link(match))); offset=match.end()
        result.append(escape(line[offset:])); return ''.join(result)
    rows=[]; code=False; table=False
    for line in text.splitlines():
        if not code and line.startswith('|'):
            if re.fullmatch(r'[|\s:-]+',line): continue
            cells=line.strip().strip('|').split('|')
            if not table: rows.append('<table>'); table=True
            rows.append('<tr>'+''.join('<td>'+inline(cell.strip())+'</td>' for cell in cells)+'</tr>')
            continue
        if table: rows.append('</table>'); table=False
        if line.startswith('```'):
            rows.append('</pre>' if code else '<pre>'); code=not code; continue
        if code: rows.append(escape(line)+'\n'); continue
        heading=re.match(r'^(#{1,6})\s+(.+)',line)
        if heading:
            level=len(heading[1]); anchor=re.sub(r'[^\w -]','',heading[2].lower()).replace(' ','-')
            rows.append(f'<h{level} id="{escape(anchor)}">{inline(heading[2])}</h{level}>')
        elif line.strip(): rows.append('<p>'+inline(line)+'</p>')
    if code: rows.append('</pre>')
    if table: rows.append('</table>')
    return '<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>BrainNet Viewer Help</title><style>body{max-width:980px;margin:24px auto;padding:0 18px;font:15px/1.55 Arial;color:#10244b}img{max-width:100%;height:auto}table{border-collapse:collapse;width:100%}td{border:1px solid #dce3ef;padding:8px}tr:first-child{font-weight:bold;background:#f5f7fc}pre{white-space:pre-wrap;background:#f5f7fc;padding:12px}a{color:#0754e9}</style><nav><a href="/bnv-help-pages/docs/tutorials/unified/en/index.html">Shared Tutorials</a> · <a href="/bnv-help-assets/docs/manual/en/BrainNet_Viewer_2_Unified_User_Manual_EN.pdf">User Manual (PDF)</a></nav>'+''.join(rows)


def prepare_help(server,workspace):
    root=workspace.root/'documentation'
    pages=workspace.scratch/'help-pages'; pages.mkdir(exist_ok=True)
    if root.is_dir():
        for source in root.rglob('*.md'):
            if source.stat().st_size>2*1024*1024: continue
            output=pages/source.relative_to(root).with_suffix('.html'); output.parent.mkdir(parents=True,exist_ok=True)
            output.write_text(render_page(source.read_text(encoding='utf-8-sig'),source,root.resolve()),encoding='utf-8')
        server.enable_module({'serve':{'bnv-help-assets':str(root),'bnv-help-pages':str(pages)}})
    return root.is_dir()
