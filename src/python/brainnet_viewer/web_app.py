"""Local single-user browser prototype; no desktop Qt dependency."""
import argparse
import base64
import json
from copy import deepcopy
from .web_workspace import WebWorkspace
from .web_fields import seed, read
from .web_export import preferences


def create_app(server=None, workspace=None):
    from trame.app import get_server
    import pyvista as pv
    server=server or get_server('brainnet-web',client_type='vue3')
    workspace=workspace or WebWorkspace()
    state,ctrl=server.state,server.controller
    server.options['ws_max_msg_size']=72*1024*1024
    state.update({'status':'Select inputs, configure, then Apply.','error':'','preset':1,'view_direction':1,
                  'opacity':.3,'node_scale':1.,'edge_scale':.7,'width':2000,'height':1500,'dpi':300,
                  'transparent':False,'export_format':'png','export_units':'Pixels','export_ready':False,
                  'interaction':'Rotate','rendered':False,'volume_mode':'surface-map',
                  'inspect_on':False,'inspect_text':'','boundary_ready':False,'boundary_busy':False})
    for role in workspace.catalog: state[role]=''
    seed(state,workspace.settings)
    state.update({'upload_open':False,'scene_open':False,'upload_role':'auto','upload_files':[],
                  'scene_files':[],'splittable':True,'bind_open':False,'bind_kind':'boundary','bind_files':[],
                  'bind_order_confirmed':False})
    bindings={}; edge_bindings={}; map_selection=None
    pending_base=None
    state.update({'demo_running':False,'toolbar_direction':0,'canvas_expanded':False,
                  'legacy_open':False,'legacy_files':[],'legacy_trusted':False,
                  'legacy_ready':False,'legacy_error':'','legacy_review':''})
    legacy_pending=None
    def legacy_review(legacy_files=None,**_):
        nonlocal legacy_pending
        from trame.app.file_upload import ClientFile
        from .legacy_config import read_ec
        legacy_pending=None; state.legacy_ready=False; state.legacy_error=''; state.legacy_review=''
        try:
            files=legacy_files if legacy_files is not None else state.legacy_files
            if not files: return
            if not state.legacy_trusted: raise ValueError('Confirm that the EC file comes from a trusted source.')
            if len(files)!=1: raise ValueError('Choose one EC MAT file.')
            item=ClientFile(files[0]); data=item.content
            if not data or len(data)>4*1024*1024: raise ValueError('Web EC import is limited to 4 MiB.')
            path=workspace.scratch/'legacy-import.mat'
            try:
                path.write_bytes(data)
                settings,report=read_ec(path,2 if state.volume else 1 if state.surface_map else 0)
            finally: path.unlink(missing_ok=True)
            report['source_file']=Path(item.name).name
            legacy_pending=settings
            state.legacy_review=(f'Mapped {len(report["mapped_fields"])} fields. '
                f'{len(report["fields_requiring_review"])} fields require review.\n\n'+
                '\n'.join(report['warnings'])+'\n\nFields requiring review:\n'+
                '\n'.join(report['fields_requiring_review'])+'\n\nMapped fields:\n'+'\n'.join(report['mapped_fields']))
            state.legacy_ready=True
        except Exception as error: state.legacy_error=str(error)
    def legacy_use():
        nonlocal pending_base,legacy_pending
        if not state.legacy_trusted or legacy_pending is None: return
        pending_base=deepcopy(legacy_pending); bindings.clear(); edge_bindings.clear(); controls(pending_base)
        legacy_pending=None; state.legacy_ready=False; state.legacy_files=[]; state.legacy_open=False
        state.status='Legacy EC settings staged. Review bindings/unmapped fields, then Apply. Files and canvas retained.'
    from pathlib import Path
    from .web_atlas import WebAtlasNodes
    from .movies import available_formats
    formats=available_formats()
    state.update({'animation_open':False,'animation_busy':False,'animation_error':'',
                  'animation_status':'Export the currently rendered scene; camera and canvas remain unchanged.',
                  'animation_formats':[{'title':f.upper() if f!='png' else 'PNG Frames','value':f} for f in formats],
                  'animation_format':formats[0],'animation_width':640,'animation_height':480,
                  'animation_duration':3.,'animation_fps':12,'animation_axis':'z',
                  'animation_start':0.,'animation_end':360.,'animation_fit':True})
    atlas_tool=WebAtlasNodes(workspace)
    state.update({'atlas_open':False,'atlas_library':'','atlas_files':[],'atlas_regions':'',
                  'atlas_module':0.,'atlas_size':0.,'atlas_space':'','atlas_units':'',
                  'atlas_confirmed':False,'atlas_ready':False,'atlas_error':'','atlas_preview':'',
                  'atlas_status':'Choose a discrete label atlas.','atlas_busy':False})
    def atlas_review():
        state.atlas_ready=False; state.atlas_confirmed=False; state.atlas_preview=''; state.atlas_error=''
        try:
            plan=atlas_tool.review(state.atlas_library,state.atlas_regions,state.atlas_module,state.atlas_size)
            state.atlas_preview='\n'.join(f'{label}: '+', '.join(f'{v:.3f}' for v in point)
                for label,point in list(zip(plan.nodes.labels,plan.nodes.positions))[:12])
            state.atlas_status=f'{len(plan.nodes.labels):,} nodes · {plan.report["affine_method"]} affine · numeric region labels.'
            state.atlas_ready=True
        except Exception as error: state.atlas_error=str(error); state.atlas_status='No valid node output.'
    @state.change('atlas_library','atlas_regions','atlas_module','atlas_size')
    def atlas_inputs_changed(**_):
        if state.atlas_library: atlas_review()
        else:
            atlas_tool.plan=None; state.atlas_ready=False; state.atlas_confirmed=False
            state.atlas_preview=''; state.atlas_error=''; state.atlas_status='Choose a discrete label atlas.'
    @state.change('atlas_files')
    def atlas_upload(atlas_files,**_):
        if not atlas_files: return
        from trame.app.file_upload import ClientFile
        try:
            files=[ClientFile(item) for item in atlas_files]
            key=atlas_tool.upload([(item.name,item.content) for item in files],state.atlas_regions,state.atlas_module,state.atlas_size)
            catalogs(); state.atlas_library=key; atlas_review()
        except Exception as error: state.atlas_error=str(error)
        finally: state.atlas_files=[]
    def atlas_payload():
        return atlas_tool.export(state.atlas_space,state.atlas_units,state.atlas_confirmed)
    @ctrl.trigger('export_brainnet_atlas')
    def atlas_export():
        try:
            payload=atlas_payload(); state.atlas_error=''; state.atlas_status='Node file generated for download. Check browser Downloads.'
            return {'name':'atlas.node','mime':'text/plain','data':base64.b64encode(payload).decode('ascii')}
        except Exception as error: state.atlas_error=str(error); raise
    def atlas_use():
        try:
            key=atlas_tool.use(atlas_payload()); catalogs(); state.node=key; state.edge=''
            edge_bindings.clear()
            state.atlas_error=''; state.atlas_status='Atlas nodes selected; previous edges cleared. Click Apply to render.'
            state.status=state.atlas_status
        except Exception as error: state.atlas_error=str(error)
    from .web_merge import WebMerge,WebConvert,WebSubdivide
    merge_tool=WebMerge(workspace)
    subdivide_tool=WebSubdivide(workspace)
    state.update({'subdivide_open':False,'subdivide_library':'','subdivide_files':[],'subdivide_items':[],
                  'subdivide_space':'','subdivide_units':'','subdivide_note':'','subdivide_error':'',
                  'subdivide_levels':1,'subdivide_ready':False,'subdivide_status':'Add one surface to review geometry automatically.','subdivide_busy':False})
    def subdivide_review():
        state.subdivide_items=subdivide_tool.summary(); state.subdivide_error=''
        state.subdivide_ready=False
        if not subdivide_tool.entries:
            state.subdivide_status='Add one surface to review geometry automatically.'; return
        state.subdivide_status='Reviewing subdivision output…'
        try:
            subdivide_tool.levels=state.subdivide_levels
            result=subdivide_tool.output_surface()
            state.subdivide_status=f'Output: {len(result.points):,} vertices · {len(result.faces):,} faces.'
            state.subdivide_ready=True
        except Exception as error:
            state.subdivide_error=str(error)
            state.subdivide_status='No output for the selected levels. Reduce Levels or choose a smaller surface.'
    @state.change('subdivide_levels')
    def subdivide_level_change(**_): subdivide_review()
    def subdivide_add():
        try: subdivide_tool.add([state.subdivide_library]); subdivide_review()
        except Exception as error: state.subdivide_error=str(error)
    @state.change('subdivide_files')
    def subdivide_upload(subdivide_files,**_):
        if not subdivide_files: return
        from trame.app.file_upload import ClientFile
        try:
            files=[ClientFile(item) for item in subdivide_files]
            subdivide_tool.upload([(item.name,item.content) for item in files]); catalogs(); subdivide_review()
        except Exception as error: state.subdivide_error=str(error)
        finally: state.subdivide_files=[]
    def subdivide_remove():
        if subdivide_tool.entries: subdivide_tool.edit(0)
        subdivide_tool._cache=None
        subdivide_review()
    def subdivide_payload():
        subdivide_tool.levels=state.subdivide_levels
        return subdivide_tool.export()
    @ctrl.trigger('export_brainnet_subdivide')
    def subdivide_export():
        try:
            payload=subdivide_payload(); state.subdivide_error=''
            state.subdivide_status='Subdivided NV generated for download. Check browser Downloads.'
            return {'name':'subdivided.nv','mime':'text/plain','data':base64.b64encode(payload).decode('ascii')}
        except Exception as error: state.subdivide_error=str(error); raise
    def subdivide_use():
        try:
            key=subdivide_tool.use(subdivide_payload()); catalogs()
            state.surface=key; state.surface_map=''; state.surface_color_mode='uniform'; state.surface_boundary_mode='none'
            bindings.clear()
            state.subdivide_error=''; state.subdivide_status='Subdivided surface selected in Data Sources. Click Apply to render.'
            state.status=state.subdivide_status
        except Exception as error: state.subdivide_error=str(error)
    convert_tool=WebConvert(workspace)
    state.update({'convert_open':False,'convert_library':'','convert_files':[],'convert_items':[],
                  'convert_space':'','convert_units':'','convert_note':'','convert_error':'',
                  'convert_status':'Add one surface to review geometry automatically.','convert_busy':False})
    def convert_review():
        state.convert_items=convert_tool.summary(); state.convert_error=''
        state.convert_status=state.convert_items[0]['title'] if state.convert_items else 'Add one surface to review geometry automatically.'
    def convert_add():
        try: convert_tool.add([state.convert_library]); convert_review()
        except Exception as error: state.convert_error=str(error)
    @state.change('convert_files')
    def convert_upload(convert_files,**_):
        if not convert_files: return
        from trame.app.file_upload import ClientFile
        try:
            files=[ClientFile(item) for item in convert_files]
            convert_tool.upload([(item.name,item.content) for item in files]); catalogs(); convert_review()
        except Exception as error: state.convert_error=str(error)
        finally: state.convert_files=[]
    def convert_remove():
        if convert_tool.entries: convert_tool.edit(0)
        convert_review()
    def convert_payload():
        return convert_tool.export(state.convert_space,state.convert_units,state.convert_note)
    @ctrl.trigger('export_brainnet_convert')
    def convert_export():
        try:
            payload=convert_payload(); state.convert_error=''
            state.convert_status='Converted NV generated for download. Check browser Downloads.'
            return {'name':'converted.nv','mime':'text/plain','data':base64.b64encode(payload).decode('ascii')}
        except Exception as error: state.convert_error=str(error); raise
    def convert_use():
        try:
            key=convert_tool.use(convert_payload()); catalogs()
            state.surface=key; state.surface_map=''; state.surface_color_mode='uniform'; state.surface_boundary_mode='none'
            bindings.clear()
            state.convert_error=''; state.convert_status='Converted surface selected in Data Sources. Click Apply to render.'
            state.status=state.convert_status
        except Exception as error: state.convert_error=str(error)
    state.update({'merge_open':False,'merge_library':'','merge_files':[], 'merge_items':[],
                  'merge_index':-1,'merge_space':'','merge_units':'','merge_note':'',
                  'merge_error':'','merge_status':'Add surfaces to review geometry automatically.','merge_busy':False})
    def merge_review():
        state.merge_items=merge_tool.summary()
        points=sum(len(s.points) for _,s,_ in merge_tool.entries)
        faces=sum(len(s.faces) for _,s,_ in merge_tool.entries)
        state.merge_status=f'{len(merge_tool.entries)} file(s) · {points:,} vertices · {faces:,} faces.'
        state.merge_error=''
    def merge_add():
        try:
            merge_tool.add([state.merge_library]); merge_review()
            state.merge_index=len(merge_tool.entries)-1
        except Exception as error: state.merge_error=str(error)
    @state.change('merge_files')
    def merge_upload(merge_files,**_):
        if not merge_files: return
        from trame.app.file_upload import ClientFile
        try:
            files=[ClientFile(item) for item in merge_files]
            merge_tool.upload([(item.name,item.content) for item in files])
            catalogs(); merge_review(); state.merge_index=len(merge_tool.entries)-1
        except Exception as error: state.merge_error=str(error)
        finally: state.merge_files=[]
    def merge_edit(operation):
        try:
            index=state.merge_index
            if isinstance(index,str): index=int(index)
            state.merge_index=merge_tool.edit(index,{'up':-1,'down':1,'remove':None}[operation])
            merge_review()
        except Exception as error: state.merge_error=str(error)
    def merge_payload():
        return merge_tool.export(state.merge_space,state.merge_units,state.merge_note)
    @ctrl.trigger('export_brainnet_merge')
    def merge_export():
        try:
            payload=merge_payload(); state.merge_error=''
            state.merge_status='Merged NV generated for download. Check browser Downloads.'
            return {'name':'merged.nv','mime':'text/plain','data':base64.b64encode(payload).decode('ascii')}
        except Exception as error: state.merge_error=str(error); raise
    def merge_use():
        try:
            key=merge_tool.use(merge_payload()); catalogs()
            state.surface=key; state.surface_map=''; state.surface_color_mode='uniform'; state.surface_boundary_mode='none'
            bindings.clear()
            state.merge_error=''; state.merge_status='Merged surface selected in Data Sources. Click Apply to render.'
            state.status=state.merge_status
        except Exception as error: state.merge_error=str(error)
    def bind_edge_colors():
        import io
        import numpy as np
        from pathlib import PureWindowsPath
        from trame.app.file_upload import ClientFile
        from .io import read_nodes
        from .binding import node_signature
        from .web_assets import FILE_LIMIT
        try:
            if not state.edge_order_confirmed: raise ValueError('Confirm the original loaded node order.')
            if len(state.edge_bind_files)!=1: raise ValueError('Choose one numeric color-index matrix.')
            path=workspace.catalog['node'].get(state.node)
            if path is None: raise ValueError('Select a node file first.')
            nodes=read_nodes(path)
            if len(nodes.positions)**2>4_000_000: raise ValueError('Color matrix exceeds four million entries.')
            item=ClientFile(state.edge_bind_files[0])
            if not item.content or len(item.content)>FILE_LIMIT: raise ValueError('Color matrix upload must be nonempty and at most 32 MiB.')
            matrix=np.loadtxt(io.BytesIO(item.content),ndmin=2)
            if matrix.shape!=(len(nodes.positions),len(nodes.positions)) or not np.isfinite(matrix).all():
                raise ValueError('Color matrix must be finite N-by-N in the original loaded node order.')
            categories=np.unique(matrix)
            if len(categories)>4096: raise ValueError('Color matrix supports at most 4096 categories.')
            source=PureWindowsPath(item.name).name
            descriptor={'matrix':matrix.tolist(),'indices':categories.tolist(),'node_sha256':node_signature(nodes.positions),'source':source}
            edge_bindings['custom_color']=descriptor
            state.edge_custom_source=source; state.edge_color_mode='custom'
            state.edge_bind_files=[]; state.edge_order_confirmed=False; state.edge_bind_open=False
            state.error=''; state.status='Color matrix bound to ordered nodes. Apply to render.'
        except Exception as error: state.error=str(error)
    def node_color_rows():
        import json
        from .palettes import palette
        rows=json.loads(state.node_colors_draft)
        palette(rows)  # validate without resampling the supplied rows
        return rows
    @state.change('node_colors_open')
    def open_node_colors(node_colors_open,**_):
        if not node_colors_open: return
        import json
        import numpy as np
        from .palettes import palette
        from .web_fields import hex_color
        try:
            source=json.loads(state.node_custom_palette) if state.node_palette=='custom' else state.node_palette
            if source==[]: source=workspace.settings['node']['colormap']
            if isinstance(source,list): rows=source; palette(rows)
            else:
                count=256
                if state.node_color_mode in ('modular','custom'):
                    from .io import read_nodes
                    path=workspace.catalog['node'].get(state.node)
                    count=max(2,len(np.unique(read_nodes(path).modules))) if path else 2
                rows=palette(source,count).tolist()
            state.node_colors_draft=json.dumps(rows); state.node_colors_order=1
            state.node_colors_color=hex_color(rows[0]); state.node_colors_count=len(rows)
            state.node_colors_error=''
        except Exception as error: state.node_colors_error=str(error)
    @state.change('node_colors_order')
    def choose_node_color(node_colors_order,**_):
        if not state.node_colors_open: return
        from .web_fields import hex_color
        try:
            rows=node_color_rows(); order=float(node_colors_order)
            if not order.is_integer(): raise ValueError('Color Row must be an integer.')
            index=int(order)-1
            if not 0<=index<len(rows): raise ValueError('Choose an existing color row.')
            state.node_colors_color=hex_color(rows[index]); state.node_colors_error=''
        except Exception as error: state.node_colors_error=str(error)
    def edit_node_color(operation):
        import json
        from .web_fields import color,hex_color
        try:
            rows=node_color_rows(); order=float(state.node_colors_order)
            if not order.is_integer(): raise ValueError('Color Row must be an integer.')
            index=int(order)-1
            if not 0<=index<len(rows): raise ValueError('Choose an existing color row.')
            if operation=='set': rows[index]=color(state.node_colors_color,rows[index])
            elif operation=='add':
                if len(rows)>=4096: raise ValueError('At most 4096 color rows are supported.')
                rows.append([.5,.5,.5]); index=len(rows)-1
            elif operation=='remove':
                if len(rows)<=2: raise ValueError('Keep at least two color rows.')
                rows.pop(index); index=min(index,len(rows)-1)
            else: raise ValueError('Unknown color edit operation.')
            state.node_colors_draft=json.dumps(rows); state.node_colors_count=len(rows)
            state.node_colors_order=index+1; state.node_colors_color=hex_color(rows[index])
            state.node_colors_error=''
        except Exception as error: state.node_colors_error=str(error)
    def accept_node_colors():
        import json
        try:
            rows=node_color_rows()
            state.node_palette='custom'; state.node_custom_palette=json.dumps(rows)
            state.node_colors_open=False; state.node_colors_error=''
            state.status='Colors updated in pending settings. Apply to render.'
        except Exception as error: state.node_colors_error=str(error)
    initial=pv.Plotter(off_screen=True,window_size=(1200,900)); initial.set_background('white')
    def controls(settings):
        seed(state,settings)
    from .web_preferences import load_preset,save_preset,rgb_rows,import_rgb,export_rgb,json_input
    state.update({'preset_open':False,'preset_files':[],'preset_error':'','preset_busy':False,
                  'colors_open':False,'colors_target':'surface','colors_named':'viridis','colors_count':256,
                  'colors_draft':'[]','colors_error':'','colors_files':[],'colors_format':'json','colors_gradient':''})
    color_maps={}; color_active='surface'; color_original=''
    def pending_settings():
        paths=dict(workspace.paths)
        if state.volume_display: paths.setdefault('volume',True)
        return read(state,pending_base or workspace.settings,paths,bindings,edge_bindings)
    @state.change('preset_files')
    def preset_upload(preset_files,**_):
        nonlocal pending_base
        if not preset_files: return
        from trame.app.file_upload import ClientFile
        try:
            if len(preset_files)!=1: raise ValueError('Choose one preset JSON.')
            settings=load_preset(ClientFile(preset_files[0]).content)
            controls(settings); pending_base=settings; bindings.clear(); edge_bindings.clear()
            state.preset_error=''; state.preset_open=False
            state.status='Preset loaded into pending settings. Apply to render; Revert discards it.'
        except Exception as error: state.preset_error=str(error)
        finally: state.preset_files=[]
    @ctrl.trigger('export_brainnet_preset')
    def preset_export():
        try:
            payload=save_preset(pending_settings()); state.error=''
            state.status='Settings preset generated for download.'
            return {'name':'BrainNet.preset.json','mime':'application/json','data':base64.b64encode(payload).decode('ascii')}
        except Exception as error: state.error=str(error); raise
    def color_accept_draft():
        rows=rgb_rows(json_input(state.colors_draft.encode('utf-8')))
        if state.colors_draft!=color_original: color_maps[color_active]=rows
        return rows
    def colors_show():
        nonlocal color_original
        from .palettes import palette
        from .web_fields import hex_color
        value=color_maps[color_active]
        if isinstance(value,str): state.colors_named=value
        rows=palette(value,256).tolist() if isinstance(value,str) else rgb_rows(value)
        state.colors_draft=json.dumps(rows); color_original=state.colors_draft
        state.colors_count=len(rows); state.colors_error=''
        state.colors_gradient='linear-gradient(to right,'+','.join(hex_color(row) for row in palette(rows,32))+')'
    @state.change('colors_open')
    def colors_opened(colors_open,**_):
        nonlocal color_maps,color_active
        if not colors_open: return
        try:
            settings=pending_settings()
            color_maps={target:deepcopy(settings[target]['colormap']) for target in ('surface','node','edge','volume')}
            color_active=state.colors_target; colors_show()
        except Exception as error: state.colors_error=str(error)
    @state.change('colors_target')
    def colors_target_changed(colors_target,**_):
        nonlocal color_active
        if not state.colors_open: return
        if colors_target==color_active: return
        try:
            if colors_target not in color_maps: raise ValueError('Choose an existing colormap target.')
            color_accept_draft(); color_active=colors_target; colors_show()
        except Exception as error: state.colors_error=str(error); state.colors_target=color_active
    def colors_edit(operation):
        from .palettes import palette
        try:
            count=float(state.colors_count)
            if not count.is_integer() or not 2<=count<=4096: raise ValueError('Choose 2–4096 RGB rows.')
            if operation=='generate': rows=palette(state.colors_named,int(count)).tolist()
            elif operation=='resample': rows=palette(color_accept_draft(),int(count)).tolist()
            elif operation=='reverse': rows=color_accept_draft()[::-1]
            elif operation=='preview': rows=color_accept_draft()
            else: raise ValueError('Unknown palette operation.')
            color_maps[color_active]=rows; colors_show()
        except Exception as error: state.colors_error=str(error)
    def colors_use():
        try:
            color_accept_draft()
            for target,value in color_maps.items():
                state[target+'_palette']=value if isinstance(value,str) else 'custom'
                state[target+'_custom_palette']='[]' if isinstance(value,str) else json.dumps(value)
            state.colors_open=False; state.colors_error=''; state.status='Colormaps staged. Apply to render; Revert discards changes.'
        except Exception as error: state.colors_error=str(error)
    @state.change('colors_files')
    def colors_upload(colors_files,**_):
        if not colors_files: return
        from trame.app.file_upload import ClientFile
        try:
            if len(colors_files)!=1: raise ValueError('Choose one RGB table.')
            file=ClientFile(colors_files[0]); rows=import_rgb(file.name,file.content)
            color_maps[color_active]=rows; colors_show()
        except Exception as error: state.colors_error=str(error)
        finally: state.colors_files=[]
    @ctrl.trigger('export_brainnet_colors')
    def colors_export():
        try:
            payload=export_rgb(color_accept_draft(),state.colors_format); state.colors_error=''
            return {'name':'BrainNet.colors.'+state.colors_format,'mime':'application/json' if state.colors_format=='json' else 'text/plain',
                    'data':base64.b64encode(payload).decode('ascii')}
        except Exception as error: state.colors_error=str(error); raise
    def catalogs():
        for role,entries in workspace.catalog.items():
            state['catalog_'+role]=[{'title':'Not selected','value':''}]+[{'title':p.name,'value':k} for k,p in entries.items()]
    def layout_choices():
        names=['Single View','Overview (8 Views)' if state.splittable else 'Overview (6 Views)',
               'Lateral / Medial','Lateral / Medial / Ventral','Lateral / Medial / Dorsal']
        state.layouts=[{'title':n,'value':i,'props':{'disabled':not state.splittable and i>2}} for i,n in enumerate(names,1)]
        if not state.splittable and int(state.preset)>2: state.preset=2
    def validate():
        nonlocal map_selection
        from .io import read_surface, read_nodes, read_edges, read_surface_map, read_volume
        from .rendering import hemispheres
        workspace.select({role:state[role] for role in workspace.catalog})
        surface=read_surface(workspace.paths['surface']); state.splittable=hemispheres(surface) is not None
        layout_choices()
        counts={'surface':f'{len(surface.points):,} vertices, {len(surface.faces):,} faces'}
        nodes=read_nodes(workspace.paths['node']) if 'node' in workspace.paths else None
        if nodes is not None: counts['node']=f'{len(nodes.positions):,} nodes'
        if 'edge' in workspace.paths:
            edges=read_edges(workspace.paths['edge'],len(nodes.positions)); counts['edge']=f'{edges.shape[0]} × {edges.shape[1]} matrix'
        if 'surface_map' in workspace.paths:
            mapped=read_surface_map(workspace.paths['surface_map'],len(surface.points)); counts['surface_map']=f'{len(mapped):,} vertex values'
        selected=(state.surface_map,state.volume,state.volume_mode)
        if selected!=map_selection:
            if map_selection is None or selected[1]!=map_selection[1]: state.volume_display=bool(state.volume)
            if state.surface_map: state.surface_color_mode='vertex-rgb' if mapped.ndim==2 else 'scalar'
            elif state.volume and state.volume_mode=='surface-map': state.surface_color_mode='scalar'
            map_selection=selected
        if 'volume' in workspace.paths:
            volume=read_volume(workspace.paths['volume']); counts['volume']=' × '.join(map(str,volume.data.shape))+' voxels'
        state.summary='Scene: Interactive scene\n'+'\n'.join(f'{role.replace("_"," ").title()}: {path} | {counts[role]} | {path.stat().st_size/1024/1024:.2f} MB' for role,path in workspace.paths.items())
        state.error=''; state.status='Files validated. Configure settings, then Apply.'
    def validate_action():
        try: validate()
        except Exception as error: state.error=str(error); state.status='Input validation failed; current canvas retained.'
    def upload():
        from trame.app.file_upload import ClientFile
        from .web_assets import upload_files
        try:
            files=[ClientFile(item) for item in state.upload_files]
            chosen=upload_files(workspace,[(item.name,item.content) for item in files],None if state.upload_role=='auto' else state.upload_role)
            catalogs(); state.update(chosen); state.upload_files=[]; state.upload_open=False
            # Surface maps and volumes are mutually exclusive inputs.
            if 'surface_map' in chosen: state.volume=''
            if 'volume' in chosen: state.surface_map=''
            state.error=''; state.status='Files uploaded. Validate and Load, then configure and Apply.'
        except Exception as error: state.error=str(error)
    def bind_surface():
        from trame.app.file_upload import ClientFile
        from .web_assets import upload_files
        from .io import read_surface,read_surface_map
        from .binding import geometry_signature
        import numpy as np
        try:
            if not state.bind_order_confirmed: raise ValueError('Confirm that this data follows the original loaded vertex order.')
            workspace.select({role:state[role] for role in workspace.catalog})
            surface=read_surface(workspace.paths['surface'])
            files=[ClientFile(item) for item in state.bind_files]
            chosen=upload_files(workspace,[(item.name,item.content) for item in files],'surface_map')
            path=workspace.catalog['surface_map'][chosen['surface_map']]
            count=len(surface.points)*(2 if state.bind_kind=='rgb' and state.surface_double_brain else 1)
            values=read_surface_map(path,count); fingerprint=geometry_signature(surface.points,surface.faces)
            if state.bind_kind=='rgb':
                if values.ndim!=2: raise ValueError('Vertex RGB needs three columns in [0,1].')
                bindings.update(vertex_colors=values.tolist(),vertex_colors_mesh_sha256=fingerprint,vertex_colors_source=path.name)
                state.surface_color_mode='vertex-rgb'; state.surface_rgb_source=path.name
            else:
                if values.ndim!=1 or not np.isin(values,[0,1]).all(): raise ValueError('Boundary mask needs one binary value per vertex.')
                bindings.update(boundary_mask=values.tolist(),boundary_mesh_sha256=fingerprint,boundary_mask_source=path.name)
                state.surface_boundary_mode='custom'; state.surface_boundary_source=path.name
            catalogs(); state.bind_files=[]; state.bind_order_confirmed=False; state.bind_open=False
            state.error=''; state.status='Data bound to original geometry. Apply to render.'
        except Exception as error: state.error=str(error)
    def open_scene():
        nonlocal pending_base
        nonlocal map_selection
        from trame.app.file_upload import ClientFile
        from .web_assets import open_bundle
        try:
            if len(state.scene_files)!=1: raise ValueError('Choose one Scene JSON or ZIP.')
            item=ClientFile(state.scene_files[0]); chosen=open_bundle(workspace,item.name,item.content)
            catalogs()
            for role in workspace.catalog: state[role]=chosen.get(role,'')
            bindings.clear(); edge_bindings.clear(); controls(workspace.settings); state.scene_open=False; state.scene_files=[]
            pending_base=None
            map_selection=(state.surface_map,state.volume,state.volume_mode)
            validate(); state.status='Scene loaded. Apply to render; current canvas retained.'
            session=workspace.pending_session
            if session:
                export=session['export']
                from .web_export import preferences
                try:
                    preferences(**export)
                    for key in ('width','height','dpi','transparent'): state[key]=export[key]
                    export_unit[0]=export['units']
                    state.export_format=export['format']; state.export_units=export['units']
                except ValueError:
                    state.status+=' Its export preferences exceed Web limits and were not applied.'
        except Exception as error: state.error=str(error)
    @ctrl.trigger('save_brainnet_scene')
    def save_scene():
        from .web_assets import save_bundle
        from .session import signature, content_hashes, validate_session
        try:
            validate(); settings=read(state,pending_base or workspace.settings,workspace.paths,bindings,edge_bindings)
            identity=signature(content_hashes(workspace.paths),settings)
            camera=None
            if workspace.renderer and identity==signature(workspace.renderer.prepared.input_hashes,workspace.renderer.prepared.settings):
                camera=workspace.renderer.capture_camera()
            session=validate_session({'version':'1.0','producer':'python-vtk','scene_signature':identity,'camera':camera,
                                      'export':preferences(
                                          state.width,state.height,state.dpi,state.transparent,state.export_format,state.export_units)[0]})
            payload=save_bundle(workspace,settings,session)
            state.error=''; state.status='Portable Scene generated for download.'
            return base64.b64encode(payload).decode('ascii')
        except Exception as error: state.error=str(error); raise
    catalogs(); layout_choices()
    def revert():
        nonlocal pending_base
        pending_base=None
        bindings.clear(); edge_bindings.clear(); controls(workspace.settings)
    def defaults():
        nonlocal pending_base
        pending_base=None
        from .settings import DEFAULTS
        bindings.clear(); edge_bindings.clear(); workspace.settings=deepcopy(DEFAULTS); controls(workspace.settings)
        state.status='Default settings restored. Current canvas retained until Apply.'
    def clear():
        navigation.stop()
        view.replace_view(initial.render_window); workspace.close_render()
        state.inspect_on=False; state.inspect_text=''
        state.rendered=False; state.boundary_ready=False; state.error=''; state.status='Figure cleared. Input files retained.'
    def apply():
        nonlocal pending_base
        navigation.stop()
        try:
            current_window=workspace.plotter.render_window if workspace.plotter else initial.render_window
            canvas_size=tuple(current_window.GetSize())
            validate()
            settings=read(state,pending_base or workspace.settings,workspace.paths,bindings,edge_bindings)
            previous=workspace.settings; workspace.settings=settings
            try: workspace.render()
            except Exception: workspace.settings=previous; raise
            workspace.plotter.render_window.SetSize(*canvas_size)
            bindings.clear(); edge_bindings.clear(); view.replace_view(workspace.plotter.render_window)
            pending_base=None
            set_interaction(state.interaction)
            state.inspect_text='Click a surface vertex (default MNI coordinates).' if state.inspect_on else ''
            state.rendered=True; state.error=''; state.status=f'Rendered {len(workspace.renderer.viewports)} view(s).'
            state.boundary_ready=workspace.renderer.prepared.boundary is not None
            navigation.refresh()
        except Exception as error:
            state.error=str(error); state.status='Apply failed; correct the inputs/settings.'
    def reset():
        navigation.stop()
        if workspace.renderer: workspace.renderer.reset(); view.update()
    def set_interaction(interaction,**_):
        if workspace.plotter:
            workspace.plotter.enable_custom_trackball_style(left={'Rotate':'rotate','Pan':'pan','Zoom':'dolly'}.get(interaction,'rotate'))
    def toggle_inspect():
        state.inspect_on=not state.inspect_on
        state.inspect_text='Click a surface vertex (default MNI coordinates).' if state.inspect_on else ''
    def inspect_event(event):
        if not state.inspect_on: return
        position=event if isinstance(event,dict) else {}
        inspect_position(position.get('x'),position.get('y'))
    def inspect_position(x,y):
        if not state.inspect_on or not workspace.renderer: return
        try:
            import math
            if isinstance(x,bool) or isinstance(y,bool) or not all(isinstance(v,(int,float)) and math.isfinite(v) for v in (x,y)):
                raise ValueError('Invalid Inspect canvas position.')
            width,height=workspace.plotter.render_window.GetSize()
            if not (0<=x<width and 0<=y<height): return
            record=workspace.renderer.inspect_vertex(x,y)
            if record is None: return
            from .inspect import lookup
            regions=lookup(workspace.root,record['xyz'])
            state.inspect_text=(f"Vertex {record['vertex']} · XYZ: "+
                                ', '.join(f'{x:.3f}' for x in record['xyz'])+
                                f" · {regions['brodmann']} · AAL: {regions['aal']}")
            state.flush()
        except Exception as error:
            state.error=str(error); state.flush()
    state.change('interaction')(set_interaction)
    export_unit=['Pixels']
    @state.change('export_units')
    def change_units(export_units,**_):
        from .export_size import unit_scale
        try:
            ratio=unit_scale(export_unit[0],float(state.dpi))/unit_scale(export_units,float(state.dpi))
            for key in ('width','height'):
                value=float(state[key])*ratio
                state[key]=int(value+.5) if export_units=='Pixels' else round(value,6)
            export_unit[0]=export_units
        except (ValueError,TypeError): pass
    @state.change('export_format')
    def change_format(export_format,**_):
        from .web_export import TRANSPARENT
        if export_format not in TRANSPARENT: state.transparent=False
    def download():
        try:
            payload=workspace.download(state.width,state.height,state.dpi,state.transparent,state.export_format,state.export_units)
            state.error=''; state.status='Figure and provenance generated for download.'
            return payload
        except Exception as error:
            state.export_ready=False; state.error=str(error); state.status='Export failed; current canvas retained.'; raise
    @ctrl.trigger('download_brainnet_zip')
    def download_zip():
        # A plain text RPC payload avoids browser-specific binary object decoding.
        return base64.b64encode(download()).decode('ascii')
    @ctrl.trigger('export_brainnet_files')
    def export_files():
        navigation.stop()
        try:
            files=workspace.export_files(state.width,state.height,state.dpi,state.transparent,
                                         state.export_format,state.export_units)
            if sum(len(data) for data in files.values())>48*1024*1024:
                raise ValueError('Export payload exceeds 48 MiB; reduce dimensions.')
            import mimetypes
            state.error=''; state.status='Figure and sidecar generated for download.'
            return [{'name':name,'mime':mimetypes.guess_type(name)[0] or 'application/octet-stream',
                     'data':base64.b64encode(data).decode('ascii')} for name,data in files.items()]
        except Exception as error:
            state.error=str(error); state.status='Export failed; current canvas retained.'; raise
    @ctrl.trigger('export_brainnet_boundary')
    def boundary_export():
        try:
            payload=workspace.boundary_file(); state.error=''
            state.status='Rendered surface boundary generated for download. Check browser Downloads.'
            return {'name':'BrainNet_Boundary.txt','mime':'text/plain','data':base64.b64encode(payload).decode('ascii')}
        except Exception as error: state.error=str(error); raise
    animation_job=None
    state.animation_progress=0; state.animation_total=0; state.animation_cancel_pending=False
    @ctrl.trigger('cancel_brainnet_animation')
    def animation_cancel():
        if animation_job is not None:
            animation_job.cancel.set(); state.animation_cancel_pending=True
            state.animation_status='Cancelling animation; waiting for renderer cleanup…'
    @ctrl.trigger('export_brainnet_animation')
    async def animation_export():
        navigation.stop()
        nonlocal animation_job
        if animation_job is not None: raise ValueError('An animation export is already running.')
        import asyncio
        import time
        from .web_animation import AnimationJob
        try:
            def integer(value):
                if isinstance(value,bool) or not float(value).is_integer(): raise ValueError('Dimensions and frame rate must be integers.')
                return int(float(value))
            options=dict(format=state.animation_format,width=integer(state.animation_width),
                height=integer(state.animation_height),duration=float(state.animation_duration),frame_rate=integer(state.animation_fps),
                axis=state.animation_axis,start_angle=float(state.animation_start),end_angle=float(state.animation_end),safe_fit=state.animation_fit)
            animation_job=AnimationJob(workspace,options)
            state.animation_busy=True; state.animation_cancel_pending=False; state.animation_error=''
            state.animation_progress=0; state.animation_total=animation_job.total
            state.animation_status='Preparing isolated animation renderer…'; state.flush()
            started=time.monotonic(); exited=0; complete=False
            while not complete:
                await asyncio.sleep(.1)
                for event in animation_job.poll():
                    if event[0]=='progress':
                        state.animation_progress=event[1]
                        if not state.animation_cancel_pending: state.animation_status=f'Rendered frame {event[1]} of {event[2]}; verifying output after rendering.'
                    elif event[0]=='cancelled':
                        state.animation_status='Animation cancelled; no downloads started.'; return []
                    elif event[0]=='error': raise ValueError(event[1])
                    elif event[0]=='done': complete=True
                state.flush()
                if time.monotonic()-started>180: raise ValueError('Animation worker exceeded the 180-second time limit.')
                exited=exited+1 if not animation_job.process.is_alive() else 0
                if exited>10 and not complete: raise ValueError('Animation worker exited without a result.')
            if animation_job.cancel.is_set():
                state.animation_status='Animation cancelled; no downloads started.'; return []
            files=animation_job.files()
            state.animation_error=''; state.animation_status='Animation files generated for download. Check browser Downloads.'
            import mimetypes
            return [{'name':name,'mime':mimetypes.guess_type(name)[0] or 'application/octet-stream',
                     'data':base64.b64encode(data).decode('ascii')} for name,data in files.items()]
        except Exception as error: state.animation_error=str(error); raise
        finally:
            if animation_job is not None: animation_job.close(); animation_job=None
            state.animation_busy=False; state.animation_cancel_pending=False; state.flush()
    from .web_parity import WebNavigation
    navigation=WebNavigation(state,workspace,lambda:view.update())
    from .web_help import prepare_help
    state.help_available=prepare_help(server,workspace)
    @state.change('legacy_files','legacy_trusted')
    def legacy_changed(**_): legacy_review()
    @state.change('legacy_open')
    def legacy_closed(legacy_open,**_):
        nonlocal legacy_pending
        if not legacy_open:
            legacy_pending=None; state.legacy_ready=False; state.legacy_files=[]
    @state.change('toolbar_direction')
    def toolbar_changed(toolbar_direction,**_): navigation.direction(toolbar_direction)
    from .web_shell import build_shell
    actions={'apply':apply,'reset':reset,'clear':clear,'defaults':defaults,'revert':revert,'toggle_inspect':toggle_inspect,'inspect_event':inspect_event,
             'upload':upload,'validate':validate_action,'open_scene':open_scene,'save_scene':save_scene,'bind_surface':bind_surface,
             'bind_edge_colors':bind_edge_colors,'edit_node_color':edit_node_color,'accept_node_colors':accept_node_colors,
             'merge_add':merge_add,'merge_edit':merge_edit,'merge_use':merge_use,
             'convert_add':convert_add,'convert_remove':convert_remove,'convert_use':convert_use,
             'subdivide_add':subdivide_add,'subdivide_remove':subdivide_remove,'subdivide_use':subdivide_use,
             'atlas_review':atlas_review,'atlas_use':atlas_use,
             'colors_edit':colors_edit,'colors_use':colors_use,
             'open_node_colors':open_node_colors,'choose_node_color':choose_node_color,
             'demo_start':navigation.start,'demo_stop':navigation.stop,'toolbar_view':navigation.direction,
             'resources_refresh':navigation.refresh,'legacy_review':legacy_review,'legacy_use':legacy_use}
    view=build_shell(server,workspace,initial,actions)
    navigation.refresh()
    def close(*_,**__):
        navigation.stop()
        if animation_job is not None: animation_job.close()
        view.release_resources(); workspace.close(); initial.close()
    ctrl.on_server_exited.add(close)
    actions.update(download=download,download_zip=download_zip,export_files=export_files,close=close,
                   merge_export=merge_export,merge_tool=merge_tool,merge_upload=merge_upload,
                   convert_export=convert_export,convert_tool=convert_tool,convert_upload=convert_upload,
                   subdivide_export=subdivide_export,subdivide_tool=subdivide_tool,
                   subdivide_upload=subdivide_upload,subdivide_review=subdivide_review,
                   atlas_export=atlas_export,atlas_tool=atlas_tool,atlas_upload=atlas_upload,
                   boundary_export=boundary_export,animation_export=animation_export,animation_cancel=animation_cancel,
                   preset_export=preset_export,preset_upload=preset_upload,colors_export=colors_export,
                   colors_open=colors_opened,colors_target=colors_target_changed,colors_upload=colors_upload)
    return server,workspace,actions


def main(argv=None):
    parser=argparse.ArgumentParser(description='BrainNet Web local single-user prototype.')
    parser.add_argument('--host',default='127.0.0.1'); parser.add_argument('--port',type=int,default=1031)
    parser.add_argument('--container',action='store_true',help='Permit wildcard bind inside a locally published container only.')
    args=parser.parse_args(argv)
    if args.host not in ('127.0.0.1','localhost','::1') and not (args.container and args.host=='0.0.0.0'):
        parser.error('Only loopback is supported; server multi-user deployment is not implemented.')
    server,_,_=create_app()
    # A background container stays available until explicitly stopped.
    server.start(host=args.host,port=args.port,open_browser=False,
                 timeout=0 if args.container else None)


if __name__=='__main__': main()
