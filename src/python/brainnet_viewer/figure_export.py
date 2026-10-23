"""Physical-size mixed graphics and transparent raster containers."""
import base64
import io
import json
import os
from pathlib import Path
import shutil
import tempfile
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image
from pypdf import PdfReader, PdfWriter
from pypdf.generic import (NameObject, NumberObject, DictionaryObject,
                           DecodedStreamObject, ContentStream, FloatObject)


def _outline_graphics_states(page, writer):
    """Normalize GL2PS glyph-path alpha into valid PDF graphics states.

    GL2PS emits standalone `ca` commands and undeclared /GS<n> names for
    outlined text. Repair only this generated path, not arbitrary input PDFs.
    """
    resources = page['/Resources']
    states = resources.get('/ExtGState', DictionaryObject())
    states = states.get_object()
    resources[NameObject('/ExtGState')] = states
    stream = ContentStream(page.get_contents(), writer)
    operations = []
    for operands, operator in stream.operations:
        if operator == b'gs' and operands[0] not in states:
            import re
            if not re.fullmatch(r'/GS\d+', str(operands[0])):
                raise ValueError('Undefined graphics state in generated PDF.')
            continue
        if operator == b'ca':
            alpha = float(operands[0])
            if len(operands) != 1 or not np.isfinite(alpha) or not 0 <= alpha <= 1:
                raise ValueError('Invalid glyph opacity in generated PDF.')
            name = NameObject(f'/BNVTextAlpha{len(states)}')
            state = DictionaryObject({NameObject('/Type'):NameObject('/ExtGState'),
                                      NameObject('/ca'):FloatObject(alpha)})
            states[name] = writer._add_object(state)
            operands, operator = [name], b'gs'
        operations.append((operands, operator))
    stream.operations = operations
    page.replace_contents(stream)


def alpha_pdf(image, width_pt, height_pt, destination):
    """Embed RGB plus a PDF soft mask; no flattened white background."""
    if image.ndim != 3 or image.shape[2] != 4:
        raise ValueError("Transparent PDF requires an RGBA scene capture.")
    writer=PdfWriter(); writer.pdf_header=b"%PDF-1.4"; page=writer.add_blank_page(width_pt,height_pt)
    height,width=image.shape[:2]
    def stream(values, space):
        obj=DecodedStreamObject(); obj.set_data(np.ascontiguousarray(values).tobytes())
        obj.update({NameObject("/Type"):NameObject("/XObject"),NameObject("/Subtype"):NameObject("/Image"),
                    NameObject("/Width"):NumberObject(width),NameObject("/Height"):NumberObject(height),
                    NameObject("/ColorSpace"):NameObject(space),NameObject("/BitsPerComponent"):NumberObject(8)})
        return obj.flate_encode()
    mask=writer._add_object(stream(image[:,:,3],"/DeviceGray"))
    rgb=stream(image[:,:,:3],"/DeviceRGB"); rgb[NameObject("/SMask")]=mask
    image_ref=writer._add_object(rgb)
    page[NameObject("/Resources")]=DictionaryObject({NameObject("/XObject"):DictionaryObject({NameObject("/Scene"):image_ref})})
    content=DecodedStreamObject(); content.set_data(f"q {width_pt:.12g} 0 0 {height_pt:.12g} 0 0 cm /Scene Do Q\n".encode("ascii"))
    page[NameObject("/Contents")]=writer._add_object(content)
    writer.add_metadata({"/Creator":"BrainNet Viewer Python", "/Subject":"Transparent raster scene; not pure vector"})
    with destination.open("wb") as target: writer.write(target)


def graphic(plotter, image, width, height, dpi, transparent, destination, *, font_text_as_path=False):
    suffix=destination.suffix.lower(); width_pt=width*72/dpi; height_pt=height*72/dpi
    if transparent:
        if image.shape[2]!=4: raise ValueError("Transparent capture did not produce an alpha channel.")
        if suffix==".pdf": alpha_pdf(image,width_pt,height_pt,destination)
        else:
            buffer=io.BytesIO(); Image.fromarray(image).save(buffer,format="PNG")
            xml=(f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{width_pt:.12g}pt" height="{height_pt:.12g}pt" '
                 f'viewBox="0 0 {width} {height}"><desc>BrainNet Viewer transparent raster scene; not pure vector</desc>'
                 f'<image width="{width}" height="{height}" xlink:href="data:image/png;base64,{base64.b64encode(buffer.getvalue()).decode()}"/></svg>')
            destination.write_text(xml,encoding="utf-8")
    else:
        from vtkmodules.vtkIOExportGL2PS import vtkGL2PSExporter
        raw=destination.parent/"mixed"
        exporter=vtkGL2PSExporter(); exporter.SetRenderWindow(plotter.render_window)
        exporter.SetFilePrefix(str(raw)); exporter.CompressOff(); exporter.Write3DPropsAsRasterImageOn()
        if suffix==".pdf": exporter.SetFileFormatToPDF(); exporter.SetTextAsPath(font_text_as_path)
        else: exporter.SetFileFormatToSVG(); exporter.SetTextAsPath(True)
        exporter.Write(); raw=raw.with_suffix(suffix)
        if not raw.is_file() or raw.stat().st_size==0: raise RuntimeError("VTK did not produce the requested graphic.")
        background=plotter.renderers[0].GetBackground()
        if suffix==".pdf":
            reader=PdfReader(raw); writer=PdfWriter()
            if len(reader.pages)!=1: raise ValueError("Scene export must have one PDF page.")
            page=writer.add_page(reader.pages[0]); page.scale_to(width_pt,height_pt)
            if font_text_as_path:
                _outline_graphics_states(page, writer)
            content=DecodedStreamObject()
            backdrop=f"q {background[0]:.12g} {background[1]:.12g} {background[2]:.12g} rg 0 0 {width_pt:.12g} {height_pt:.12g} re f Q\n".encode("ascii")
            content.set_data(backdrop+page.get_contents().get_data())
            page[NameObject("/Contents")]=writer._add_object(content)
            writer.add_metadata({"/Creator":"BrainNet Viewer Python", "/Subject":"Mixed raster scene and vector annotations; not pure vector"})
            with destination.open("wb") as target: writer.write(target)
        else:
            # QtSvg needs the default SVG namespace, not an ns0-prefixed tree.
            ET.register_namespace("","http://www.w3.org/2000/svg")
            ET.register_namespace("xlink","http://www.w3.org/1999/xlink")
            document=ET.parse(raw); root=document.getroot()
            root.set("width",f"{width_pt:.12g}pt"); root.set("height",f"{height_pt:.12g}pt")
            root.set("viewBox",f"0 0 {width} {height}")
            root.insert(0,ET.Element("{http://www.w3.org/2000/svg}rect",width=str(width),height=str(height),
                                   fill=f"rgb({','.join(str(int(np.floor(v*255+.5))) for v in background)})"))
            document.write(destination,encoding="utf-8",xml_declaration=True)
    if suffix==".pdf":
        reader=PdfReader(destination)
        if len(reader.pages)!=1 or not np.allclose([float(reader.pages[0].mediabox.width),float(reader.pages[0].mediabox.height)],
                                                  [width_pt,height_pt],rtol=0,atol=1e-6):
            raise ValueError("PDF page dimensions failed verification.")
    else:
        root=ET.parse(destination).getroot()
        if root.tag.rsplit("}",1)[-1]!="svg": raise ValueError("Invalid SVG output.")


def save_figure(plotter, image, filename, width, height, dpi, transparent, *, overwrite=False, before_publish=None, provenance=None, font_text_as_path=False):
    """Stage locally; exclusive create by default, explicit replacement only."""
    target=Path(filename).absolute()
    from .provenance import sidecar_path
    from .io import sha256
    sidecar=sidecar_path(target)
    if not target.parent.is_dir(): raise ValueError("Choose an existing output directory.")
    if target.exists() and not overwrite: raise FileExistsError("Output already exists. Confirm replacement or choose another filename.")
    if provenance is not None and sidecar.exists() and not overwrite:
        raise FileExistsError("Provenance file already exists. Confirm replacement or choose another filename.")
    result={"format":target.suffix.lower()[1:], "width":width,"height":height,"dpi":dpi,
            "width_pt":width*72/dpi,"height_pt":height*72/dpi,"transparent":transparent,
            "content":"transparent raster" if transparent and target.suffix.lower() in (".pdf",".svg") else
                      "mixed raster/vector" if target.suffix.lower() in (".pdf",".svg") else "raster"}
    if font_text_as_path and not transparent and target.suffix.lower() in ('.pdf', '.svg'):
        result['annotation_text'] = 'glyph outlines'
    with tempfile.TemporaryDirectory(prefix=".brainnet-export-",dir=target.parent) as folder:
        stage=Path(folder)/("figure"+target.suffix.lower())
        if target.suffix.lower() in (".pdf",".svg"):
            graphic(plotter,image,width,height,dpi,transparent,stage,font_text_as_path=font_text_as_path)
        else: Image.fromarray(image).save(stage,dpi=(dpi,dpi))
        if not stage.is_file() or not stage.stat().st_size: raise RuntimeError("Figure export produced an empty file.")
        publications=[(stage,target)]
        if provenance is not None:
            document=provenance(dict(result))
            document['image']={'filename':target.name,'sha256':sha256(stage)}
            staged_sidecar=Path(folder)/'provenance.json'
            staged_sidecar.write_text(json.dumps(document,ensure_ascii=False,allow_nan=False,indent=2)+'\n',encoding='utf-8')
            publications.append((staged_sidecar,sidecar))
        if before_publish: before_publish()
        published=[]; backups={}
        try:
            if overwrite:
                for index,(_,destination) in enumerate(publications):
                    if destination.exists():
                        backup=Path(folder)/f'backup-{index}'
                        shutil.copy2(destination,backup); backups[destination]=backup
                for source,destination in publications:
                    os.replace(source,destination); published.append(destination)
            else:
                # Claim both names before filling either, avoiding competing-file deletion.
                for _,destination in publications:
                    with destination.open('xb'): pass
                    published.append(destination)
                for source,destination in publications:
                    with source.open('rb') as input_,destination.open('wb') as output:
                        shutil.copyfileobj(input_,output)
        except Exception:
            for destination in reversed(published):
                if destination in backups: os.replace(backups[destination],destination)
                else: destination.unlink(missing_ok=True)
            raise
    if provenance is not None: result['provenance_file']=str(sidecar)
    return result
