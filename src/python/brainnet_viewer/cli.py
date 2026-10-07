"""Off-screen Scene image export; no Qt application or desktop window."""
import argparse
import json
from pathlib import Path
import sys
from .scene import read_scene
from .io import sha256
from .session import KEY, signature, validate_session
from .export_size import figure_size
from .provenance import sidecar_path


def render_scene(scene_path, output, *, data_root=None, width=None, height=None,
                 dpi=None, units=None, transparent=None, overwrite=False, reset_view=False):
    import pyvista as pv
    from .rendering import prepare, layout, SceneRenderer
    from .matlab_session import validate_matlab_session, export_preferences, pending_session
    scene_path=Path(scene_path).resolve(); output=Path(output).resolve()
    if scene_path in (output,sidecar_path(output).resolve()):
        raise ValueError('Do not overwrite the input Scene.')
    if not output.parent.is_dir(): raise ValueError('Choose an existing output directory.')
    if not overwrite and (output.exists() or sidecar_path(output).exists()):
        raise FileExistsError('Image or provenance already exists; use --overwrite only to replace both.')
    original=sha256(scene_path)
    scene=read_scene(scene_path,data_root if data_root is not None else scene_path.parent)
    if sha256(scene_path)!=original: raise ValueError('Scene changed while being read.')
    settings=scene.settings; prepared=prepare(scene.paths,settings)
    identity=signature(prepared.input_hashes,settings)
    metadata=scene.document.get('metadata',{})
    preferences={'width':settings['image']['width'],'height':settings['image']['height'],
                 'dpi':settings['image']['dpi'],'units':'Pixels','transparent':False}
    state=None; matlab=None; warnings=[]
    if KEY in metadata:
        candidate=validate_session(metadata[KEY])
        if candidate['scene_signature']==identity:
            state=candidate; preferences=candidate['export']
        else: warnings.append('Stored Python session does not match current data/settings; using default camera and export preferences.')
    elif 'session_state' in metadata:
        if scene.matlab_signature_verified:
            matlab=validate_matlab_session(metadata['session_state'])
            preferences,notes=export_preferences(matlab); warnings.extend(notes)
        else: warnings.append('MATLAB session signature is unverified; using default camera and export preferences.')
    dpi=preferences['dpi'] if dpi is None else dpi
    units=preferences['units'] if units is None else units
    width=preferences['width'] if width is None else width
    height=preferences['height'] if height is None else height
    transparent=preferences['transparent'] if transparent is None else transparent
    pixels=figure_size(width,height,dpi,units)
    if int(dpi)!=dpi: raise ValueError('DPI must be an integer.')
    _,views=layout(settings['layout'],prepared.split)
    plot=pv.Plotter(shape=(1,len(views)),border=False,off_screen=True,window_size=pixels)
    renderer=SceneRenderer(plot)
    camera_status='default'
    try:
        with pv.VtkErrorCatcher(raise_errors=True):
            renderer.render(prepared)
            if not reset_view and (state is not None or matlab is not None):
                if matlab is not None: state=pending_session(matlab,renderer,identity)
                camera_status=renderer.restore_session(state)
                if camera_status not in ('restored','no-camera'): warnings.append('Saved camera not restored: '+camera_status)
            if sha256(scene_path)!=original: raise ValueError('Scene changed during rendering.')
            result=renderer.export(output,*pixels,int(dpi),transparent,overwrite=overwrite,paths=scene.paths,settings=settings,
                                   provenance_context={'entry_point':'headless-scene','scene':{'filename':scene_path.name,'sha256':original},
                                                       'camera_restore':camera_status,'reset_view':reset_view,'warnings':warnings})
        return {'image':str(output),**result,'camera_restore':camera_status,'warnings':warnings}
    finally:
        renderer.dispose(); plot.close()


def main(argv=None):
    parser=argparse.ArgumentParser(description='Render a BrainNet Scene without opening the desktop. Off-screen VTK graphics support is required.')
    parser.add_argument('--scene',required=True,type=Path)
    parser.add_argument('--output',required=True,type=Path)
    parser.add_argument('--data-root',type=Path,help='Asset root; defaults to the Scene directory.')
    parser.add_argument('--width',type=float); parser.add_argument('--height',type=float)
    parser.add_argument('--dpi',type=int)
    parser.add_argument('--units',choices=['Pixels','Millimetres','Centimetres','Inches','Points'])
    background=parser.add_mutually_exclusive_group()
    background.add_argument('--transparent',dest='transparent',action='store_true')
    background.add_argument('--opaque',dest='transparent',action='store_false')
    parser.set_defaults(transparent=None)
    parser.add_argument('--overwrite',action='store_true',help='Explicitly replace the output image and its provenance record.')
    parser.add_argument('--reset-view',action='store_true',help='Ignore the saved camera; retain Scene settings.')
    arguments=vars(parser.parse_args(argv)); arguments['scene_path']=arguments.pop('scene')
    try:
        result=render_scene(**arguments)
    except (ValueError,OSError,RuntimeError) as error:
        print('BrainNet render failed: '+str(error),file=sys.stderr); return 1
    print(json.dumps(result,ensure_ascii=False,allow_nan=False)); return 0


if __name__=='__main__': sys.exit(main())
