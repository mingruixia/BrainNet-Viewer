"""Desktop-aligned Web controls without Qt; preserve numeric precision."""
from copy import deepcopy
import json
import re
from .settings import merge, normalize
from .palettes import PALETTES

CHOICES={
    'shading':['interp','flat','faceted'], 'lighting':['none','flat','gouraud','phong'],
    'light_direction':['headlight','right','left'], 'render_detail':['adaptive','low','moderate','high'],
    'material_profile':['dull','shiny','metal','custom'],
    'colorbar_location':['eastoutside','westoutside','southoutside','northoutside'],
}

NODE_ENUMS={
    'selection_mode':['all','threshold','connected'], 'selection_basis':['value','module'],
    'label_mode':['none','all','threshold'], 'label_basis':['value','module'],
    'label_font_weight':['normal','bold'], 'label_font_angle':['normal','italic'],
    'label_font_units':['points','pixels','normalized','inches','centimeters'],
    'size_mode':['uniform','mapped','raw','threshold'], 'size_basis':['value','module'],
    'size_threshold_basis':['mapped','raw'], 'color_mode':['uniform','mapped','modular','threshold','custom'],
}
NODE_NUMBERS=('threshold','label_threshold','label_font_size','size','size_threshold','color_threshold')
NODE_COLORS=('color','label_color','color_low','color_high')
EDGE_ENUMS={
    'selection_mode':['all','threshold','sparsity'], 'value_mode':['absolute','signed'],
    'size_mode':['uniform','mapped','raw','threshold'], 'size_threshold_basis':['mapped','raw'],
    'size_value_mode':['absolute','signed'], 'color_mode':['uniform','mapped','threshold','length','node-module','custom'],
    'threshold_value_mode':['absolute','signed'], 'mapped_value_mode':['absolute','signed'],
    'opacity_mode':['uniform','mapped'], 'opacity_value_mode':['absolute','signed'],
}
EDGE_NUMBERS=('threshold','sparsity','size','size_threshold','color_threshold','length_threshold','opacity','arrow_length_scale','arrow_width_scale')
EDGE_COLORS=('color','color_low','color_high','inter_module_color')
VOLUME_ENUMS={'threshold_mode':['none','value','cluster','p-value'],'map_algorithm':list(range(1,9)),
              'display_mode':['both','positive','negative'],'voxel_connectivity':[6,18,26]}
VOLUME_NUMBERS=('statistical_threshold','p_value','cluster_size')
VOLUME_RANGES=('positive_minimum','positive_maximum','negative_minimum','negative_maximum')


def hex_color(values):
    return '#'+''.join(f'{round(255*v):02x}' for v in values)


def color(value, original):
    if value==hex_color(original): return original
    if not isinstance(value,str) or len(value)!=7 or not value.startswith('#'):
        raise ValueError('Enter a six-digit hexadecimal color.')
    return [int(value[i:i+2],16)/255 for i in (1,3,5)]


def seed(state, settings):
    for group in ('layout','global'):
        for key,value in settings[group].items():
            if key not in ('background_color','material_coefficients'):
                state[key]=deepcopy(value)
    state.background=hex_color(settings['global']['background_color'])
    coefs=list(settings['global']['material_coefficients'])
    coefs=coefs+[10,1] if len(coefs)==3 else coefs+[1] if len(coefs)==4 else coefs
    for key,value in zip(('ambient','diffuse','specular','exponent','reflectance'),coefs): state[key]=value
    for key in ('show_colorbar','colorbar_location','colorbar_label','title'): state[key]=settings['image'][key]
    state.opacity=settings['surface']['opacity']; state.node_scale=settings['node']['size_scale']
    state.edge_scale=settings['edge']['size_scale']; state.volume_mode=settings['volume']['type']
    surface=settings['surface']
    for key in ('color_mode','show_colorbar','boundary_mode','boundary_threshold','double_brain'):
        state['surface_'+key]=surface[key]
    state.surface_color=hex_color(surface['color']); state.surface_boundary_color=hex_color(surface['boundary_color'])
    state.surface_palette=surface['colormap'] if isinstance(surface['colormap'],str) else 'custom'
    state.surface_custom_palette=json.dumps(surface['colormap']) if not isinstance(surface['colormap'],str) else '[]'
    limits=surface['color_limits']; state.surface_range_auto=not limits
    state.surface_min=limits[0] if limits else ''; state.surface_max=limits[1] if limits else ''
    state.surface_boundary_source=surface['boundary_mask_source'] or 'Not loaded'
    state.surface_rgb_source=surface['vertex_colors_source'] or 'Not loaded'
    node=settings['node']
    for key in (*NODE_ENUMS,*NODE_NUMBERS,'label_font_name','label_in_front'):
        state['node_'+key]=node[key]
    for key in NODE_COLORS: state['node_'+key]=hex_color(node[key])
    state.node_palette=node['colormap'] if isinstance(node['colormap'],str) else 'custom'
    state.node_custom_palette=json.dumps(node['colormap']) if not isinstance(node['colormap'],str) else '[]'
    limits=node['color_limits']; state.node_range_auto=not limits
    state.node_min=limits[0] if limits else ''; state.node_max=limits[1] if limits else ''
    edge=settings['edge']
    for key in (*EDGE_ENUMS,*EDGE_NUMBERS,'directed','inter_hemisphere_only'): state['edge_'+key]=edge[key]
    for key in EDGE_COLORS: state['edge_'+key]=hex_color(edge[key])
    state.edge_palette=edge['colormap'] if isinstance(edge['colormap'],str) else 'custom'
    state.edge_custom_palette=json.dumps(edge['colormap']) if not isinstance(edge['colormap'],str) else '[]'
    limits=edge['color_limits']; state.edge_range_auto=not limits
    state.edge_min=limits[0] if limits else ''; state.edge_max=limits[1] if limits else ''
    state.edge_opacity_min,state.edge_opacity_max=edge['opacity_range']
    state.edge_custom_source=edge['custom_color']['source'] or 'Not loaded'
    volume=settings['volume']; roi=settings['roi']
    for key in (*VOLUME_ENUMS,*VOLUME_NUMBERS,'display','adjust_null'): state['volume_'+key]=volume[key]
    for key in VOLUME_RANGES: state['volume_'+key]=volume[key] if volume[key]!=[] else ''
    state.volume_palette=volume['colormap'] if isinstance(volume['colormap'],str) else 'custom'
    state.volume_custom_palette=json.dumps(volume['colormap']) if not isinstance(volume['colormap'],str) else '[]'
    for key in ('draw_all','color_mode','palette','show_legend','smoothing','smoothing_kernel'): state['roi_'+key]=roi[key]
    state.roi_selection=' '.join(map(str,roi['selection'])); state.roi_color=hex_color(roi['color'])
    state.roi_custom_colors=json.dumps(roi['custom_colors'])


def read(state, settings, paths, bindings=None, edge_bindings=None):
    patch={'layout':{'preset':int(state.preset),'view_direction':int(state.view_direction)},
           'global':{},'image':{},'surface':{'opacity':float(state.opacity)},
           'node':{'size_scale':float(state.node_scale)},'edge':{'size_scale':float(state.edge_scale)},
           'volume':{'display':state.volume_display and 'volume' in paths,'type':state.volume_mode},'roi':{}}
    for key in ('custom_azimuth','custom_elevation'):
        value=state[key]; patch['layout'][key]=[] if value in (None,'',[]) else float(value)
    for key in (*CHOICES.keys(),'show_orientation_labels'):
        if key!='colorbar_location': patch['global'][key]=state[key]
    original=settings['global']['background_color']
    if state.background==hex_color(original): patch['global']['background_color']=original
    else:
        value=state.background
        if not isinstance(value,str) or len(value)!=7 or not value.startswith('#'):
            raise ValueError('Background color requires a six-digit hexadecimal color.')
        patch['global']['background_color']=[int(value[i:i+2],16)/255 for i in (1,3,5)]
    coefs=[float(state[key]) for key in ('ambient','diffuse','specular','exponent','reflectance')]
    old=list(settings['global']['material_coefficients'])
    expanded=old+[10,1] if len(old)==3 else old+[1] if len(old)==4 else old
    patch['global']['material_coefficients']=old if coefs==expanded else coefs
    for key in ('show_colorbar','colorbar_location','colorbar_label','title'): patch['image'][key]=state[key]
    for key in ('color_mode','show_colorbar','boundary_mode','double_brain'):
        patch['surface'][key]=state['surface_'+key]
    patch['surface'].update(color=color(state.surface_color,settings['surface']['color']),
                            boundary_color=color(state.surface_boundary_color,settings['surface']['boundary_color']),
                            boundary_threshold=float(state.surface_boundary_threshold),
                            color_limits=[] if state.surface_range_auto else [float(state.surface_min),float(state.surface_max)],
                            colormap=json.loads(state.surface_custom_palette) if state.surface_palette=='custom' else state.surface_palette)
    patch['surface'].update(bindings or {})
    for key in (*NODE_ENUMS,'label_font_name','label_in_front'):
        patch['node'][key]=state['node_'+key]
    for key in NODE_NUMBERS: patch['node'][key]=float(state['node_'+key])
    for key in NODE_COLORS: patch['node'][key]=color(state['node_'+key],settings['node'][key])
    patch['node'].update(colormap=json.loads(state.node_custom_palette) if state.node_palette=='custom' else state.node_palette,
                         color_limits=[] if state.node_range_auto else [float(state.node_min),float(state.node_max)])
    for key in (*EDGE_ENUMS,'directed','inter_hemisphere_only'): patch['edge'][key]=state['edge_'+key]
    for key in EDGE_NUMBERS: patch['edge'][key]=float(state['edge_'+key])
    for key in EDGE_COLORS: patch['edge'][key]=color(state['edge_'+key],settings['edge'][key])
    patch['edge'].update(colormap=json.loads(state.edge_custom_palette) if state.edge_palette=='custom' else state.edge_palette,
                         color_limits=[] if state.edge_range_auto else [float(state.edge_min),float(state.edge_max)],
                         opacity_range=[float(state.edge_opacity_min),float(state.edge_opacity_max)])
    patch['edge'].update(edge_bindings or {})
    for key in VOLUME_ENUMS: patch['volume'][key]=state['volume_'+key]
    for key in VOLUME_NUMBERS: patch['volume'][key]=float(state['volume_'+key])
    for key in VOLUME_RANGES:
        value=state['volume_'+key]; patch['volume'][key]=[] if value in ('',None,[]) else float(value)
    patch['volume'].update(adjust_null=state.volume_adjust_null,
                            colormap=json.loads(state.volume_custom_palette) if state.volume_palette=='custom' else state.volume_palette)
    for key in ('draw_all','color_mode','palette','show_legend','smoothing'): patch['roi'][key]=state['roi_'+key]
    text=state.roi_selection.strip()
    entries=json.loads(text) if text.startswith('[') else re.split(r'[,\s]+',text) if text else []
    if not isinstance(entries,list): raise ValueError('ROI Selection needs positive integer labels.')
    labels=[]
    for entry in entries:
        number=float(entry)
        if isinstance(entry,bool) or not number.is_integer() or number<1: raise ValueError('ROI Selection needs positive integer labels.')
        if int(number) not in labels: labels.append(int(number))
    patch['roi'].update(selection=labels,smoothing_kernel=float(state.roi_smoothing_kernel),
                         color=color(state.roi_color,settings['roi']['color']),custom_colors=json.loads(state.roi_custom_colors))
    return normalize({'visualization_settings':merge(settings,patch)})


def panel(index,state,v3,html):
    if index==0:
        v3.VSelect(v_model=('preset',1),label='Layout Preset',items=('layouts',[]))
        v3.VSelect(v_model=('view_direction',1),label='View Direction',disabled=('preset !== 1',),
                   items=('directions',[{'title':n,'value':i} for i,n in ((1,'Left'),(2,'Dorsal'),(3,'Anterior'),(4,'Custom'),(5,'Right'),(6,'Ventral'),(7,'Posterior'),(8,'Oblique'))]))
        for key,label in (('custom_azimuth','Custom Azimuth'),('custom_elevation','Custom Elevation')):
            v3.VTextField(v_model=(key,None),type='number',label=label,disabled=('preset !== 1 || view_direction !== 4',))
        html.P('Multi-view presets use their own camera directions.',classes='bnv-pending')
    else:
        v3.VTextField(v_model=('background','#ffffff'),type='color',label='Background Color')
        for key,label in (('shading','Surface Shading'),('lighting','Lighting Model'),('light_direction','Light Direction'),
                          ('material_profile','Surface Material'),('render_detail','Render Detail')):
            v3.VSelect(v_model=(key,state[key]),items=('choices_'+key,CHOICES[key]),label=label)
        with html.Div(v_if="material_profile === 'custom'"):
            for key,label,maximum in (('ambient','Ambient',1),('diffuse','Diffuse',1),('specular','Specular',1),
                                      ('exponent','Exponent',128),('reflectance','Reflectance',1)):
                v3.VTextField(v_model=(key,state[key]),type='number',min=0,max=maximum,step=.1,label=label)
        v3.VCheckbox(v_model=('show_orientation_labels',False),label='Orientation Labels',hide_details=True)
        html.H4('Figure Annotations')
        v3.VCheckbox(v_model=('show_colorbar',False),label='Show Colorbars',hide_details=True)
        v3.VSelect(v_model=('colorbar_location','eastoutside'),items=('choices_colorbar_location',CHOICES['colorbar_location']),label='Colorbar Location')
        v3.VTextField(v_model=('colorbar_label',''),label='Colorbar Label')
        v3.VTextField(v_model=('title',''),label='Figure Title')


def surface_panel(state,v3,html):
    v3.VSelect(v_model=('surface_color_mode','uniform'),label='Color Mode',items=('surface_modes',[
        {'title':'Uniform','value':'uniform'},{'title':'Scalar Map','value':'scalar'},{'title':'Vertex RGB','value':'vertex-rgb'}]))
    v3.VTextField(v_model=('surface_color',state.surface_color),type='color',label='Uniform Color',disabled=("surface_color_mode !== 'uniform'",))
    with html.Div(classes='bnv-opacity'):
        v3.VSlider(v_model=('opacity',state.opacity),min=0,max=1,step=.01,label='Opacity',hide_details=True)
        v3.VTextField(v_model=('opacity',state.opacity),type='number',min=0,max=1,step=.01,label='Value',hide_details=True)
    scalar="surface_color_mode !== 'scalar'"
    v3.VSelect(v_model=('surface_palette',state.surface_palette),items=('surface_palettes',PALETTES+['custom']),label='Colormap',disabled=(scalar,))
    v3.VTextarea(v_model=('surface_custom_palette','[]'),label='Custom Colormap RGB Rows',rows=3,v_if="surface_palette === 'custom'",disabled=(scalar,))
    v3.VCheckbox(v_model=('surface_range_auto',True),label='Color Limits: Auto',hide_details=True,disabled=(scalar,))
    with html.Div(classes='bnv-field-pair'):
        for key,label in (('surface_min','Min'),('surface_max','Max')):
            v3.VTextField(v_model=(key,state[key]),label=label,type='number',disabled=(scalar+' || surface_range_auto',))
    v3.VCheckbox(v_model=('surface_show_colorbar',True),label='Show Surface Colorbar',hide_details=True,disabled=(scalar,))
    v3.VSelect(v_model=('surface_boundary_mode','none'),label='Boundary',items=('boundary_modes',[
        {'title':name,'value':value} for name,value in [('None','none'),('Automatic','automatic'),('Threshold','threshold'),('Custom','custom')]]))
    v3.VTextField(v_model=('surface_boundary_color',state.surface_boundary_color),type='color',label='Boundary Color',disabled=("surface_boundary_mode === 'none'",))
    v3.VTextField(v_model=('surface_boundary_threshold',state.surface_boundary_threshold),type='number',label='Boundary Threshold',disabled=("surface_boundary_mode === 'none'",))
    with html.Div(v_if="surface_boundary_mode === 'custom'"):
        html.P('{{ surface_boundary_source }}',classes='bnv-pending')
        v3.VBtn('Load and Bind Mask…',click="bind_kind = 'boundary'; bind_open = true",variant='outlined')
    with html.Div(v_if="surface_color_mode === 'vertex-rgb'"):
        html.P('{{ surface_rgb_source }}',classes='bnv-pending')
        v3.VBtn('Load and Bind RGB…',click="bind_kind = 'rgb'; bind_open = true",variant='outlined')
    v3.VCheckbox(v_model=('surface_double_brain',False),label='Double Brain',hide_details=True)


def node_panel(state,v3,html):
    def select(key,label,condition='false'):
        choices=[{'title':'Modules' if value=='modular' else value.title(),'value':value} for value in NODE_ENUMS[key]]
        v3.VSelect(v_model=('node_'+key,state['node_'+key]),items=('node_choices_'+key,choices),label=label,disabled=('!node || '+condition,))
    def number(key,label,condition='false',**bounds):
        v3.VTextField(v_model=('node_'+key,state['node_'+key]),label=label,type='number',step='any',disabled=('!node || '+condition,),**bounds)
    def rgb(key,label,condition):
        v3.VTextField(v_model=('node_'+key,state['node_'+key]),label=label,type='color',disabled=('!node || '+condition,))
    html.P('Select a node file to configure its display.',v_if='!node',classes='bnv-pending')
    html.H4('Visibility')
    select('selection_mode','Selection')
    select('selection_basis','Selection Basis',"node_selection_mode !== 'threshold'")
    number('threshold','Threshold',"node_selection_mode !== 'threshold'")
    html.P('Connected displays only nodes incident to the selected edges.',v_if="node_selection_mode === 'connected'",classes='bnv-pending')
    html.H4('Labels')
    select('label_mode','Label Mode')
    select('label_basis','Label Basis',"node_label_mode !== 'threshold'")
    number('label_threshold','Label Threshold',"node_label_mode !== 'threshold'")
    no_labels="node_label_mode === 'none'"
    v3.VTextField(v_model=('node_label_font_name',state.node_label_font_name),label='Font',disabled=('!node || '+no_labels,))
    number('label_font_size','Font Size',no_labels,min=.00001,max=100)
    with html.Div(classes='bnv-field-pair'):
        select('label_font_weight','Font Weight',no_labels); select('label_font_angle','Font Angle',no_labels)
    select('label_font_units','Font Units',no_labels)
    rgb('label_color','Label Color',no_labels)
    v3.VCheckbox(v_model=('node_label_in_front',False),label='Labels in Front',hide_details=True,disabled=('!node || '+no_labels,))
    html.H4('Size')
    select('size_mode','Size Mode')
    select('size_basis','Size Source',"node_size_mode === 'uniform'")
    with html.Div(classes='bnv-field-pair'):
        number('size','Base Size',"node_size_mode !== 'uniform'",min=.00001)
        v3.VTextField(v_model=('node_scale',state.node_scale),type='number',step='any',min=.00001,label='Size Scale',disabled=('!node',))
    with html.Div(classes='bnv-field-pair'):
        select('size_threshold_basis','Threshold Basis',"node_size_mode !== 'threshold'")
        number('size_threshold','Size Threshold',"node_size_mode !== 'threshold'")
    html.H4('Color')
    select('color_mode','Color Mode')
    rgb('color','Uniform Color',"node_color_mode !== 'uniform'")
    palette_disabled="!node || !['mapped','modular','custom'].includes(node_color_mode)"
    v3.VSelect(v_model=('node_palette',state.node_palette),items=('node_palettes',PALETTES+['custom']),label='Colormap',disabled=(palette_disabled,))
    v3.VBtn('Edit Colors…',click='node_colors_open = true',variant='outlined',disabled=(palette_disabled,))
    html.P('Module colors follow sorted module order; rows repeat when fewer colors are supplied.',v_if="['modular','custom'].includes(node_color_mode)",classes='bnv-pending')
    v3.VCheckbox(v_model=('node_range_auto',True),label='Color Limits: Auto',hide_details=True,disabled=("!node || node_color_mode !== 'mapped'",))
    with html.Div(classes='bnv-field-pair'):
        for key,label in (('node_min','Min'),('node_max','Max')):
            v3.VTextField(v_model=(key,state[key]),label=label,type='number',step='any',disabled=("!node || node_color_mode !== 'mapped' || node_range_auto",))
    number('color_threshold','Color Threshold',"node_color_mode !== 'threshold'")
    with html.Div(classes='bnv-field-pair'):
        rgb('color_low','Low (<=)',"node_color_mode !== 'threshold'")
        rgb('color_high','High (>)',"node_color_mode !== 'threshold'")


def edge_panel(state,v3,html):
    base='!node || !edge'
    def select(key,label,condition='false'):
        titles={'all':'All Edges','sparsity':'Sparsity (Top Count)','node-module':'Node Module'}
        items=[{'title':titles.get(v,v.replace('-',' ').title()),'value':v} for v in EDGE_ENUMS[key]]
        v3.VSelect(v_model=('edge_'+key,state['edge_'+key]),items=('edge_choices_'+key,items),label=label,disabled=(base+' || '+condition,))
    def number(key,label,condition='false',**bounds):
        v3.VTextField(v_model=('edge_'+key,state['edge_'+key]),type='number',step='any',label=label,disabled=(base+' || '+condition,),**bounds)
    def rgb(key,label,condition):
        v3.VTextField(v_model=('edge_'+key,state['edge_'+key]),type='color',label=label,disabled=(base+' || '+condition,))
    html.P('Select paired node and edge files to configure connections.',v_if=base,classes='bnv-pending')
    html.H4('Visibility')
    select('selection_mode','Selection')
    number('threshold','Threshold',"edge_selection_mode !== 'threshold'")
    number('sparsity','Sparsity',"edge_selection_mode !== 'sparsity'",min=0,max=1)
    select('value_mode','Selection Values')
    v3.VCheckbox(v_model=('edge_directed',False),label='Directed Edges',disabled=(base,),hide_details=True)
    v3.VCheckbox(v_model=('edge_inter_hemisphere_only',False),label='Inter Hemi Only',disabled=(base,),hide_details=True)
    html.H4('Size')
    select('size_mode','Size Mode')
    with html.Div(classes='bnv-field-pair'):
        number('size','Base Size',"edge_size_mode !== 'uniform'",min=.00001)
        v3.VTextField(v_model=('edge_scale',state.edge_scale),type='number',step='any',min=.00001,label='Size Scale',disabled=(base,))
    select('size_value_mode','Size Values',"edge_size_mode === 'uniform'")
    with html.Div(classes='bnv-field-pair'):
        select('size_threshold_basis','Threshold Basis',"edge_size_mode !== 'threshold'")
        number('size_threshold','Size Threshold',"edge_size_mode !== 'threshold'")
    html.H4('Color')
    select('color_mode','Color Mode')
    rgb('color','Uniform Color',"edge_color_mode !== 'uniform'")
    palette_disabled=base+" || !['mapped','custom'].includes(edge_color_mode)"
    v3.VSelect(v_model=('edge_palette',state.edge_palette),items=('edge_palettes',PALETTES+['custom']),label='Colormap',disabled=(palette_disabled,))
    v3.VTextarea(v_model=('edge_custom_palette','[]'),label='Custom Colormap RGB Rows',rows=3,v_if="edge_palette === 'custom'",disabled=(palette_disabled,))
    v3.VCheckbox(v_model=('edge_range_auto',True),label='Color Limits: Auto',hide_details=True,disabled=(base+" || edge_color_mode !== 'mapped'",))
    with html.Div(classes='bnv-field-pair'):
        for key,label in (('edge_min','Min'),('edge_max','Max')):
            v3.VTextField(v_model=(key,state[key]),label=label,type='number',step='any',disabled=(base+" || edge_color_mode !== 'mapped' || edge_range_auto",))
    select('mapped_value_mode','Mapped Values',"edge_color_mode !== 'mapped'")
    with html.Div(v_if="edge_color_mode === 'custom'"):
        html.P('{{ edge_custom_source }}',classes='bnv-pending')
        v3.VBtn('Load and Bind Color Matrix…',click="edge_bind_open = true",variant='outlined',disabled=(base,))
    number('color_threshold','Color Threshold',"edge_color_mode !== 'threshold'")
    select('threshold_value_mode','Threshold Values',"edge_color_mode !== 'threshold'")
    number('length_threshold','Length Threshold',"edge_color_mode !== 'length'")
    with html.Div(classes='bnv-field-pair'):
        for key,label in [('color_low',"edge_color_mode === 'length' ? 'Short (<)' : 'Low (<=)'"),('color_high',"edge_color_mode === 'length' ? 'Long (>=)' : 'High (>)'")]:
            rgb(key,(label,),"!['threshold','length'].includes(edge_color_mode)")
    rgb('inter_module_color','Inter Module Color',"edge_color_mode !== 'node-module'")
    html.P('Within-module connections use the node module palette.',v_if="edge_color_mode === 'node-module'",classes='bnv-pending')
    html.H4('Opacity')
    select('opacity_mode','Opacity Mode')
    number('opacity','Opacity',"edge_opacity_mode !== 'uniform'",min=0,max=1)
    select('opacity_value_mode','Opacity Values',"edge_opacity_mode !== 'mapped'")
    with html.Div(classes='bnv-field-pair'):
        for key,label in [('edge_opacity_min','Min Opacity'),('edge_opacity_max','Max Opacity')]:
            v3.VTextField(v_model=(key,state[key]),type='number',step='any',min=0,max=1,label=label,disabled=(base+" || edge_opacity_mode !== 'mapped'",))
    html.H4('Arrowhead Shape')
    with html.Div(classes='bnv-field-pair'):
        number('arrow_length_scale','Length', '!edge_directed',min=.25,max=3)
        number('arrow_width_scale','Width', '!edge_directed',min=.25,max=3)


def volume_panel(state,v3,html):
    off='!volume || !volume_display'
    smap=off+" || volume_mode !== 'surface-map'"
    roi=off+" || volume_mode !== 'roi'"
    def number(key,label,disabled,**bounds):
        v3.VTextField(v_model=(key,state[key]),type='number',step='any',label=label,disabled=(disabled,),**bounds)
    html.P('Select a volume/atlas, then Validate and Load to configure it.',v_if='!volume',classes='bnv-pending')
    v3.VCheckbox(v_model=('volume_display',False),label='Display Volume',disabled=('!volume',),hide_details=True)
    v3.VSelect(v_model=('volume_mode','surface-map'),items=('volume_modes',[{'title':'Surface Mapping','value':'surface-map'},{'title':'ROIs','value':'roi'}]),label='Volume Type',disabled=(off,))
    html.H4('Statistical Threshold')
    v3.VSelect(v_model=('volume_threshold_mode','none'),label='Threshold Mode',disabled=(off,),items=('volume_threshold_modes',[
        {'title':name,'value':value} for name,value in [('None','none'),('Value','value'),('Cluster','cluster'),('P Value','p-value')]]))
    number('volume_statistical_threshold','Statistical Threshold',off+" || !['value','cluster'].includes(volume_threshold_mode)")
    number('volume_p_value','P Value',off+" || volume_threshold_mode !== 'p-value'",min=0,max=1)
    number('volume_cluster_size','Cluster Size',off+" || !(volume_threshold_mode === 'cluster' || (volume_mode === 'roi' && volume_threshold_mode === 'p-value'))",min=0)
    v3.VSelect(v_model=('volume_voxel_connectivity',18),label='Voxel Connectivity',items=('volume_connectivity',[6,18,26]),disabled=(off+" || !(volume_threshold_mode === 'cluster' || (volume_mode === 'roi' && ['value','p-value'].includes(volume_threshold_mode)))",))
    html.P('P values use supported NIfTI intent or SPM/REST/DPABI statistical metadata. Missing or conflicting metadata is rejected.',v_if="volume_threshold_mode === 'p-value'",classes='bnv-pending')
    html.H4('Surface Mapping')
    algorithms=['Nearest','Nearest + Surface Smoothing','Box Mean','Gaussian','Trilinear','Maximum','Minimum','Maximum Absolute']
    v3.VSelect(v_model=('volume_map_algorithm',2),label='Mapping Algorithm',items=('volume_algorithms',[{'title':name,'value':index} for index,name in enumerate(algorithms,1)]),disabled=(smap,))
    for direction in ('positive','negative'):
        with html.Div(classes='bnv-field-pair'):
            for suffix,label in [('minimum','Min'),('maximum','Max')]:
                number('volume_'+direction+'_'+suffix,direction.title()+' '+label,smap)
    v3.VSelect(v_model=('volume_palette',state.volume_palette),items=('volume_palettes',PALETTES+['custom']),label='Colormap',disabled=(smap,))
    v3.VTextarea(v_model=('volume_custom_palette','[]'),label='Custom Colormap RGB Rows',rows=3,v_if="volume_palette === 'custom'",disabled=(smap,))
    v3.VSelect(v_model=('volume_display_mode','both'),label='Display Values',items=('volume_display_values',[{'title':n,'value':v} for n,v in [('Positive & Negative','both'),('Positive','positive'),('Negative','negative')]]),disabled=(smap,))
    v3.VCheckbox(v_model=('volume_adjust_null',True),label='Adjust Null',disabled=(smap,),hide_details=True)
    html.P('Zero/null values use the base Surface Color; one colormap is split at its midpoint for Positive & Negative.',classes='bnv-pending')
    html.H4('Atlas / Statistical ROIs')
    v3.VCheckbox(v_model=('roi_draw_all',True),label='Draw All ROIs',disabled=(roi,),hide_details=True)
    v3.VTextField(v_model=('roi_selection',''),label='ROI Selection',placeholder='29 30 or 29, 30',disabled=(roi+' || roi_draw_all',))
    v3.VSelect(v_model=('roi_color_mode','index'),label='ROI Color Mode',items=('roi_color_modes',[{'title':n,'value':v} for n,v in [('Label Index','index'),('Uniform','uniform'),('Custom','custom')]]),disabled=(roi,))
    v3.VSelect(v_model=('roi_palette','hsv'),items=('roi_palettes',PALETTES),label='ROI Palette',disabled=(roi+" || roi_color_mode !== 'index'",))
    v3.VTextField(v_model=('roi_color',state.roi_color),type='color',label='ROI Color',disabled=(roi+" || roi_color_mode !== 'uniform'",))
    v3.VTextarea(v_model=('roi_custom_colors','[]'),label='Custom ROI Colors (ID, R, G, B)',rows=3,disabled=(roi+" || roi_color_mode !== 'custom'",))
    v3.VCheckbox(v_model=('roi_show_legend',False),label='Show ROI Legend',disabled=(roi,),hide_details=True)
    v3.VSelect(v_model=('roi_smoothing','gaussian'),label='ROI Smoothing',items=('roi_smoothing_modes',[{'title':v.title(),'value':v} for v in ['gaussian','box','none']]),disabled=(roi,))
    number('roi_smoothing_kernel','Smoothing Kernel',roi+" || roi_smoothing === 'none'",min=1)
