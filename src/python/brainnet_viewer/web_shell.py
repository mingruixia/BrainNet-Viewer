"""Desktop-aligned browser shell; no Qt imports."""
import base64
import os
from . import __version__
from .web_controls import CompactControls, CSS as COMPACT_CSS

CSS = """
html,body {margin:0;overflow:hidden;font-family:'Segoe UI',Arial,sans-serif}
.bnv {--bg:#f5f7fc;--panel:#fff;--ink:#10244b;--muted:#61728e;--border:#dce3ef;--field:#fff;
 background:var(--bg);color:var(--ink);height:100dvh;display:flex;flex-direction:column;padding:8px;gap:8px;font-size:12px}
.bnv.dark {--bg:#101c30;--panel:#182840;--ink:#e5edf9;--muted:#a7bad3;--border:#334660;--field:#20334e;color-scheme:dark}
.bnv-banner {height:86px;flex-shrink:0;border-radius:7px;background:linear-gradient(90deg,#041a42,#063d89);display:flex;align-items:center;padding:6px 18px;gap:14px;color:white}
.bnv-banner img {width:112px;height:74px;object-fit:contain}
.bnv-brand {flex:1;min-width:0}.bnv-brand h1 {font-size:29px;font-weight:700;line-height:1.15;margin:0}
.bnv-brand p {font-size:14px;color:#96c9ff;margin:4px 0 0}
.bnv-banner .v-btn {width:80px;height:34px;background:transparent;color:white;border:1px solid #688bb8}
.bnv-theme {max-width:136px;color:white}
.bnv-grid {display:grid;grid-template-columns:270px minmax(0,1fr) 330px;gap:8px;flex:1;min-height:0}
.bnv-grid.collapsed {grid-template-columns:270px minmax(0,1fr) 44px}
.bnv-grid.expanded {grid-template-columns:minmax(0,1fr)}
.bnv-grid.expanded .bnv-left,.bnv-grid.expanded .bnv-right {display:none}
.bnv-card {background:var(--panel);border:1px solid var(--border);border-radius:7px;display:flex;flex-direction:column;min-width:0;min-height:0;overflow:hidden}
.bnv-heading {font-size:14px;font-weight:700;padding:10px 12px;border-bottom:1px solid var(--border);margin:0;flex-shrink:0}
.bnv-left-scroll {overflow:auto;padding:10px;flex:1;min-height:0}.bnv-hint {color:var(--muted);padding:8px;border:1px dashed var(--border);border-radius:5px;text-align:center;margin-bottom:10px}
.bnv .v-field {font-family:inherit;font-size:12px;color:var(--ink);background:var(--field)}
.bnv .v-label,.bnv input,.bnv .v-select__selection-text {font-size:12px!important;font-family:inherit}
.bnv .v-btn {font-family:inherit;text-transform:none;font-size:12px;letter-spacing:0;min-width:0;border-radius:4px;box-shadow:none}
.bnv .v-btn--variant-outlined {border-color:var(--border);background:var(--field);color:var(--ink)}
.bnv .v-selection-control {min-height:30px}.bnv .v-input {color:var(--ink)}
.bnv-file {margin-bottom:8px}.bnv-summary {border:1px solid var(--border);border-radius:4px;padding:8px;min-height:90px;max-height:160px;overflow:auto;overflow-wrap:anywhere;white-space:pre-wrap;color:var(--muted)}
.bnv-export {padding:8px;border-top:1px solid var(--border);flex-shrink:0}.bnv-export h3 {font-size:13px;margin:0 0 8px}.bnv-export-grid {display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:6px}.bnv-export .v-field__input {padding:8px 5px;min-height:40px}
.bnv-export .v-field-label {font-size:10px!important}.bnv-export .v-field--variant-filled .v-field-label--floating{transform:translateY(-50%);top:9px}.bnv-export .v-field--variant-filled .v-field__input{padding-top:18px;padding-bottom:3px}.bnv-export .v-checkbox{grid-column:span 3}.bnv-export .v-btn{width:100%}
.bnv-toolbar {display:grid;grid-template-columns:repeat(6,minmax(0,1fr));gap:5px;padding:8px}.bnv-toolbar .v-btn {height:32px}.bnv-toolbar .v-select{min-width:0!important;max-width:none!important}.bnv-toolbar .v-field{height:32px;font-size:12px}.bnv-toolbar .v-field__input{min-height:32px;padding-top:4px;padding-bottom:4px}
@media(max-width:1300px){.bnv-toolbar{grid-template-columns:repeat(4,minmax(0,1fr))}}
.bnv-canvas {flex:1;min-height:0;position:relative;background:white;overflow:hidden}.bnv-view {position:absolute;inset:0}
/* Keep the last remote frame proportional until the resized frame arrives. */
.bnv-view img {object-fit:contain!important;object-position:center}
.bnv-welcome {height:100%;display:flex;flex-direction:column;align-items:center;padding:20px 24px;gap:10px;color:var(--ink);background:var(--panel)}
.bnv-welcome img {flex:1;min-height:0;width:78%;max-width:700px;object-fit:contain}
.bnv-welcome-info {text-align:center;font-weight:700;font-size:15px;overflow-wrap:anywhere}.bnv-citation {color:#c8243d;text-align:center;font-size:14px;font-weight:600}
.bnv-canvas-status {padding:6px 10px;color:var(--muted);font-size:12px}
.bnv-inspect {padding:5px 10px;font-size:12px;overflow-wrap:anywhere;border-top:1px solid var(--border);color:var(--ink);flex-shrink:0}
.bnv-field-pair {display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:6px}
.bnv-right-header {display:flex;align-items:center;gap:4px;padding:8px;min-height:43px}.bnv-right-header h3 {flex:1;font-size:14px;margin:0}.bnv-toggle {width:28px!important;min-width:28px!important;height:28px!important;margin-left:auto}
.bnv-settings-body {display:flex;flex-direction:column;flex:1;min-height:0;padding:0 8px 8px;gap:8px}
.bnv-accordion {flex:1;overflow:auto;min-height:0}.bnv .v-expansion-panel {background:var(--panel);color:var(--ink);border-bottom:1px solid var(--border);box-shadow:none}
.bnv .v-expansion-panel-title {font-size:13px;font-weight:700;min-height:36px;padding:8px 10px;background:var(--bg)}
.bnv .v-expansion-panel-title--active {min-height:36px}
.bnv .v-expansion-panel-title::after {content:' >';white-space:pre;margin-right:auto}
.bnv .v-expansion-panel-title[aria-expanded='true']::after {content:' v'}
.bnv .v-expansion-panel-title__icon {display:none}.bnv .v-expansion-panel-text__wrapper {padding:10px 4px}
.bnv-actions {display:grid;grid-template-columns:1fr 1fr;gap:6px}.bnv-pending {font-size:12px;color:var(--muted);margin:0;padding:5px}
.bnv-source-row {display:grid;grid-template-columns:minmax(0,1fr) 42px 38px;gap:4px;align-items:start}.bnv-source-row .v-btn{height:40px}.bnv-data-actions{display:grid;grid-template-columns:1fr 1fr;gap:5px;margin-bottom:8px}.bnv-data-actions .v-btn{height:32px}.bnv-dialog{background:#fff;color:#10244b}.bnv .v-expansion-panel-text h4{font-size:13px;font-weight:700;margin:10px 0}
.bnv-strip {flex-shrink:0;background:var(--panel);border-top:1px solid var(--border);padding:6px 10px;display:flex;flex-wrap:wrap;gap:6px 18px;justify-content:space-between;color:var(--muted)}.bnv-strip>span:first-child{flex:1;min-width:0;overflow-wrap:anywhere}
.bnv-dialog {background:var(--panel,#fff);color:var(--ink,#10244b);padding:20px}.bnv-dialog h3 {margin-bottom:12px}
.bnv-dialog.dark {--panel:#182840;--ink:#e5edf9;color-scheme:dark}
.bnv-dialog .v-btn {font-family:'Segoe UI',Arial,sans-serif;text-transform:none;letter-spacing:0;font-size:12px}
@media(max-width:1100px) and (min-width:801px) {.bnv-grid{grid-template-columns:220px minmax(0,1fr) 280px}.bnv-grid.collapsed{grid-template-columns:220px minmax(0,1fr) 44px}.bnv-brand h1{font-size:24px}}
@media(max-width:960px) {html,body{overflow:auto}.bnv{height:auto;min-height:100dvh}.bnv-banner{height:auto;min-height:86px;flex-wrap:wrap;padding:8px}.bnv-brand{flex:1 0 calc(100% - 100px)}.bnv-brand h1{font-size:22px}.bnv-banner img{width:80px;height:60px}.bnv-grid,.bnv-grid.collapsed{display:flex;flex-direction:column;flex:none}.bnv-center{order:0;min-height:600px}.bnv-left{order:1}.bnv-right{order:2}.bnv-settings-body{min-height:300px}.bnv-left-scroll{overflow:visible}.bnv-strip{flex-wrap:wrap}.bnv-canvas{min-height:440px}.bnv-welcome{min-height:440px}.bnv-welcome img{height:280px;flex:none}}
"""


DOWNLOAD_FILES_JS = "export_busy = true; trigger('export_brainnet_files').then(files => { for (const file of files) { utils.download(file.name, utils.get('Uint8Array').from(utils.get('atob')(file.data), c => c.charCodeAt(0)), file.mime); } status = 'Image and sidecar downloads started. Check both files in browser Downloads.'; export_busy = false; }).catch(cause => { error = 'Download failed: ' + (cause.message || JSON.stringify(cause)); export_busy = false; })"
MERGE_DOWNLOAD_JS = "merge_busy = true; trigger('export_brainnet_merge').then(file => { utils.download(file.name, utils.get('Uint8Array').from(utils.get('atob')(file.data), c => c.charCodeAt(0)), file.mime); merge_busy = false; }).catch(cause => { merge_error = 'Merge failed: ' + (cause.message || JSON.stringify(cause)); merge_busy = false; })"
CONVERT_DOWNLOAD_JS = "convert_busy = true; trigger('export_brainnet_convert').then(file => { utils.download(file.name, utils.get('Uint8Array').from(utils.get('atob')(file.data), c => c.charCodeAt(0)), file.mime); convert_busy = false; }).catch(cause => { convert_error = 'Conversion failed: ' + (cause.message || JSON.stringify(cause)); convert_busy = false; })"
SUBDIVIDE_DOWNLOAD_JS = "subdivide_busy = true; trigger('export_brainnet_subdivide').then(file => { utils.download(file.name, utils.get('Uint8Array').from(utils.get('atob')(file.data), c => c.charCodeAt(0)), file.mime); subdivide_busy = false; }).catch(cause => { subdivide_error = 'Subdivision failed: ' + (cause.message || JSON.stringify(cause)); subdivide_busy = false; })"


def build_shell(server, workspace, initial, actions):
    from trame.ui.vuetify3 import VAppLayout
    from trame.widgets import html, vtk, vuetify3 as v3
    compact=CompactControls(v3,html)
    state=server.state
    logo=workspace.root/'assets/branding/BrainNet_Viewer_2_Startup_PSD-v1.png'
    state.brand_image='data:image/png;base64,'+base64.b64encode(logo.read_bytes()).decode() if logo.is_file() else ''
    state.update({'theme':'Light','settings_open':True,'section':[],'help_open':False,'about_open':False,
                  'node_colors_open':False,'node_colors_error':'','node_colors_draft':'',
                  'node_colors_order':1,'node_colors_color':'#808080','node_colors_count':2,
                  'edge_bind_open':False,'edge_bind_files':[],'edge_order_confirmed':False,
                  'export_busy':False,
                  'summary':'Scene: Select input files to review paths and data size.',
                  'resources':f'CPU: {os.cpu_count()} logical cores · Renderer: server host'})
    state.trame__title='BrainNet Viewer — Web'
    # Vue templates omit style elements; load CSS through Trame's module assets.
    server.enable_module({'styles':['data:text/css;base64,'+base64.b64encode((CSS+COMPACT_CSS).encode()).decode()]})
    with VAppLayout(server,theme=("theme === 'Dark' ? 'dark' : 'light'",)):
        with html.Div(classes=("'bnv '+(theme === 'Dark' ? 'dark' : '')",)):
            with html.Header(classes='bnv-banner'):
                html.Img(src=('brand_image',),alt='BrainNet Viewer brain image')
                with html.Div(classes='bnv-brand'):
                    html.H1('BrainNet Viewer'); html.P('Brain Connectome Visualization')
                v3.VSelect(v_model=('theme','Light'),items=('themes',['Light','Dark']),prepend_inner_icon=("theme === 'Dark' ? 'mdi-weather-night' : 'mdi-white-balance-sunny'",),label='Theme',hide_details=True,density='compact',classes='bnv-theme')
                v3.VBtn('Help',click='help_open = true'); v3.VBtn('About',click='about_open = true')
            with html.Div(classes=("'bnv-grid '+(canvas_expanded ? 'expanded' : (settings_open ? '' : 'collapsed'))",)):
                with html.Section(classes='bnv-card bnv-left'):
                    html.H2('Data Sources',classes='bnv-heading')
                    with html.Div(classes='bnv-left-scroll'):
                        html.Div('Add your files or select from the bundled library.',classes='bnv-hint')
                        with html.Div(classes='bnv-data-actions'):
                            v3.VBtn('Add Files',click="upload_role = 'auto'; upload_open = true",color='#0754e9')
                            v3.VBtn('Validate and Load',click=actions['validate'],variant='outlined')
                        for role,label in (('surface','Surface Mesh'),('node','Nodes'),('edge','Edges'),('surface_map','Surface Map'),('volume','Volume / Atlas')):
                            items=[{'title':'Not selected','value':''}]+[{'title':p.name,'value':k} for k,p in workspace.catalog[role].items()]
                            with html.Div(classes='bnv-source-row'):
                                html.Label(label,**{'for':'bnv-file-'+role})
                                v3.VSelect(v_model=(role,''),items=('catalog_'+role,items),id='bnv-file-'+role,title=(role,),variant='outlined',density='compact',hide_details=True,classes='bnv-file')
                                v3.VBtn('Add',click=f"upload_role = '{role}'; upload_open = true",variant='outlined',title='Upload '+label)
                                v3.VBtn('×',click=f"{role} = ''",variant='outlined',title='Clear '+label)
                        with html.Div(classes='bnv-data-actions'):
                            v3.VBtn('Open Scene',click='scene_open = true',variant='outlined')
                            v3.VBtn('Save Scene',variant='outlined',click="trigger('save_brainnet_scene').then(data => utils.download('BrainNet.scene.zip', utils.get('Uint8Array').from(utils.get('atob')(data), c => c.charCodeAt(0)), 'application/zip')).catch(cause => { error = 'Scene save failed: ' + (cause.message || JSON.stringify(cause)); })")
                        v3.VBtn('Import Settings',click='legacy_open = true',variant='outlined',block=True,classes='mb-2')
                        html.Pre('{{ summary }}',classes='bnv-summary')
                    with html.Div(classes='bnv-export'):
                        html.H3('Export Figure')
                        with html.Div(classes='bnv-export-grid'):
                            compact.VSelect(v_model=('export_format','png'),items=('export_formats',[{'title':{'tif':'TIFF','jpg':'JPEG'}.get(f,f.upper()),'value':f} for f in ('png','tif','jpg','bmp','pdf','svg')]),label='Format')
                            for key,label in (('width','Width'),('height','Height')):
                                compact.VTextField(v_model=(key,state[key]),label=label,type='number',step=("export_units === 'Pixels' ? 1 : 0.1",))
                            compact.VSelect(v_model=('export_units','Pixels'),items=('export_unit_options',['Pixels','Millimetres','Centimetres','Inches','Points']),label='Units')
                            compact.VTextField(v_model=('dpi',state.dpi),label='DPI',type='number')
                            v3.VCheckbox(v_model=('transparent',False),label='Transparent',disabled=("['jpg','bmp'].includes(export_format)",),hide_details=True,density='compact')
                        v3.VBtn('Export Figure',disabled=('!rendered || export_busy',),color='#0754e9',block=True,classes='mt-2',click=DOWNLOAD_FILES_JS)
                with html.Section(classes='bnv-card bnv-center'):
                    html.H2('Render Canvas',classes='bnv-heading')
                    with html.Div(classes='bnv-toolbar'):
                        v3.VBtn('Reset',click=actions['reset'],variant='outlined')
                        for mode in ('Rotate','Pan','Zoom'):
                            v3.VBtn(mode,click=f"interaction = '{mode}'",variant='outlined',color=(f"interaction === '{mode}' ? '#0754e9' : undefined",))
                        v3.VBtn('Fit',click=actions['reset'],variant='outlined')
                        v3.VBtn('Clear Figure',click=actions['clear'],variant='outlined')
                        v3.VBtn('Inspect',click=actions['toggle_inspect'],disabled=('!rendered',),variant='outlined',color=("inspect_on ? '#0754e9' : undefined",))
                        v3.VSelect(v_model=('toolbar_direction',0),items=('toolbar_views',[{'title':label,'value':code} for label,code in [('Layout / Custom',0),('Left Lateral',1),('Right Lateral',5),('Anterior',3),('Posterior',7),('Superior',2),('Inferior',6)]]),density='compact',hide_details=True,disabled=('!rendered || demo_running',),style='min-width:140px;max-width:175px',title='View shortcut')
                        v3.VBtn('Live Demo',click=actions['demo_start'],disabled=('!rendered || demo_running || animation_busy',),variant='outlined')
                        v3.VBtn('Stop Demo',click=actions['demo_stop'],disabled=('!demo_running',),variant='outlined')
                        v3.VBtn('{{ canvas_expanded ? "Return" : "Pop Out" }}',click='canvas_expanded = !canvas_expanded',variant='outlined',title='Expand canvas in this browser tab')
                        v3.VBtn('Render Scene',click=actions['apply'],color='#0754e9')
                    with html.Div(classes='bnv-canvas'):
                        # Keep the remote view mounted while switching from the welcome image.
                        with html.Div(classes='bnv-view',style=("rendered ? '' : 'visibility:hidden'",)):
                            view=vtk.VtkRemoteView(initial.render_window,interactive_ratio=1,interactive_quality=95,
                                                   interactor_events=('inspect_events',['LeftButtonPress']),
                                                   LeftButtonPress=(actions['inspect_event'],'[$event.position]'),
                                                   still_ratio=1,still_quality=100,style='height:100%;width:100%')
                        with html.Div(classes='bnv-welcome',v_if='!rendered'):
                            html.Img(src=('brand_image',),alt='BrainNet Viewer startup brain')
                            html.Div(f'Version {__version__} · Public Beta 1 · Developer: Mingrui Xia',classes='bnv-welcome-info')
                            html.Div('Project: https://github.com/mingruixia/BrainNet-Viewer',classes='bnv-welcome-info')
                            html.Div('Xia M, Wang J, He Y (2013). BrainNet Viewer: A Network Visualization Tool for Human Brain Connectomics. PLoS ONE 8: e68910.',classes='bnv-citation')
                    html.Div('{{ inspect_text }}',v_if='inspect_on',classes='bnv-inspect')
                    html.Div('{{ status }}',classes='bnv-canvas-status')
                    v3.VAlert('{{ error }}',v_if='error',type='error',density='compact')
                with html.Section(classes='bnv-card bnv-right'):
                    with html.Div(classes='bnv-right-header'):
                        html.H3('Visualization Settings',v_if='settings_open')
                        v3.VBtn('{{ settings_open ? "<" : ">" }}',click='settings_open = !settings_open',classes='bnv-toggle',variant='outlined',title=("settings_open ? 'Collapse settings panel' : 'Expand settings panel'",))
                    with html.Div(classes='bnv-settings-body',v_show='settings_open'):
                        with html.Div(classes='bnv-actions bnv-three-actions'):
                            v3.VBtn('Load Preset',click='preset_open = true',variant='outlined')
                            v3.VBtn('Save Preset',click="preset_busy = true; trigger('export_brainnet_preset').then(file => { utils.download(file.name, utils.get('Uint8Array').from(utils.get('atob')(file.data), c => c.charCodeAt(0)), file.mime); preset_busy = false; }).catch(cause => { error = 'Preset export failed: ' + (cause.message || JSON.stringify(cause)); preset_busy = false; })",variant='outlined',disabled=('preset_busy',))
                            v3.VBtn('Colors…',click='colors_open = true',variant='outlined')
                        with html.Div(classes='bnv-accordion'):
                            # Titles stay mounted regardless of the model's empty form.
                            with v3.VExpansionPanels(v_model=('section',[])):
                                for index,title in enumerate(('Layout','Global','Surface','Nodes','Edges','Volume / ROI')):
                                    with v3.VExpansionPanel(value=index):
                                        v3.VExpansionPanelTitle(title)
                                        with v3.VExpansionPanelText():
                                            if index in (0,1):
                                                from .web_fields import panel
                                                panel(index,state,compact,html)
                                            elif index==2:
                                                from .web_fields import surface_panel
                                                surface_panel(state,compact,html)
                                            elif index==3:
                                                from .web_fields import node_panel
                                                node_panel(state,compact,html)
                                            elif index==4:
                                                from .web_fields import edge_panel
                                                edge_panel(state,compact,html)
                                            else:
                                                from .web_fields import volume_panel
                                                volume_panel(state,compact,html)
                        v3.VBtn('Restore Defaults…',click=actions['defaults'],variant='outlined')
                        with html.Div(classes='bnv-actions'):
                            v3.VBtn('Revert',click=actions['revert'],variant='outlined')
                            v3.VBtn('Apply',click=actions['apply'],color='#0754e9')
                        with html.Div(classes='bnv-tools'):
                            html.H4('Tools')
                            with html.Div(classes='bnv-actions'):
                                v3.VBtn('Merge',click='merge_open = true',variant='outlined')
                                v3.VBtn('Convert',click='convert_open = true',variant='outlined')
                            with html.Div(classes='bnv-actions'):
                                v3.VBtn('Subdivide',click='subdivide_open = true',variant='outlined')
                                v3.VBtn('Atlas Nodes',click='atlas_open = true',variant='outlined')
                            with html.Div(classes='bnv-actions'):
                                v3.VBtn('Save Boundary',click="boundary_busy = true; trigger('export_brainnet_boundary').then(file => { utils.download(file.name, utils.get('Uint8Array').from(utils.get('atob')(file.data), c => c.charCodeAt(0)), file.mime); boundary_busy = false; }).catch(cause => { error = 'Boundary export failed: ' + (cause.message || JSON.stringify(cause)); boundary_busy = false; })",variant='outlined',disabled=('!boundary_ready || boundary_busy',))
                                v3.VBtn('Animation',click='animation_open = true',variant='outlined',disabled=('!rendered',))
            with html.Footer(classes='bnv-strip'):
                html.Span('{{ resources }}'); v3.VBtn('Refresh',click=actions['resources_refresh'],variant='text',size='small',title='Refresh rendering-host resources'); html.Span('{{ rendered ? "Ready" : "Select input files" }}')
            with v3.VDialog(v_model=('preset_open',False),max_width=560):
                with html.Div(classes=("'bnv-dialog bnv-merge '+(theme === 'Dark' ? 'dark' : '')",)):
                    html.H3('Load Settings Preset')
                    html.P('Desktop-compatible preset JSON, up to 4 MiB. Loads pending settings only; inputs and canvas are retained. Apply to render, Revert to discard.',classes='bnv-pending')
                    v3.VFileInput(v_model=('preset_files',[]),multiple=True,label='Upload Preset',accept='.json',density='compact',hide_details=True)
                    v3.VAlert('{{ preset_error }}',v_if='preset_error',type='error',density='compact')
                    v3.VBtn('Close',click='preset_open = false',variant='outlined')
            with v3.VDialog(v_model=('colors_open',False),max_width=760):
                with html.Div(classes=("'bnv-dialog bnv-merge '+(theme === 'Dark' ? 'dark' : '')",)):
                    html.H3('Colormap Editor')
                    compact.VSelect(v_model=('colors_target','surface'),label='Target',items=('color_targets',[{'title':name,'value':key} for name,key in [('Surface','surface'),('Nodes','node'),('Edges','edge'),('Volume','volume')]]))
                    from .palettes import PALETTES
                    compact.VSelect(v_model=('colors_named','viridis'),label='Named Colormap',items=('colors_named_choices',PALETTES))
                    compact.VTextField(v_model=('colors_count',256),label='RGB Row Count',type='number',min=2,max=4096,step=1)
                    with html.Div(classes='bnv-actions'):
                        for name,operation in [('Generate','generate'),('Resample','resample'),('Reverse','reverse')]:
                            v3.VBtn(name,click=(actions['colors_edit'],f"['{operation}']"),variant='outlined')
                    html.Div(style=("'height:24px;margin:8px 0;background:'+colors_gradient",))
                    v3.VTextarea(v_model=('colors_draft','[]'),label='RGB Rows (JSON)',rows=6,density='compact',hide_details=True)
                    v3.VBtn('Preview RGB Rows',click=(actions['colors_edit'],"['preview']"),variant='outlined')
                    html.P('Rows run from low to high mapped values; Nodes modular colors follow sorted module IDs. RGB channels are 0–1. Changes remain in this editor until Use in Settings.',classes='bnv-pending')
                    v3.VFileInput(v_model=('colors_files',[]),multiple=True,label='Import RGB Table',accept='.json,.txt,.csv',density='compact',hide_details=True)
                    compact.VSelect(v_model=('colors_format','json'),label='Export Format',items=('colors_formats',['json','txt','csv']))
                    v3.VAlert('{{ colors_error }}',v_if='colors_error',type='error',density='compact')
                    with html.Div(classes='bnv-merge-actions'):
                        v3.VBtn('Export RGB',click="trigger('export_brainnet_colors').then(file => { utils.download(file.name, utils.get('Uint8Array').from(utils.get('atob')(file.data), c => c.charCodeAt(0)), file.mime); }).catch(cause => { colors_error = 'Color export failed: ' + (cause.message || JSON.stringify(cause)); })",variant='outlined')
                        v3.VBtn('Cancel',click='colors_open = false',variant='outlined')
                        v3.VBtn('Use in Settings',click=actions['colors_use'],color='#0754e9')
            with v3.VDialog(v_model=('animation_open',False),max_width=760):
                with html.Div(classes=("'bnv-dialog bnv-merge '+(theme === 'Dark' ? 'dark' : '')",)):
                    html.H3('Export Animation')
                    compact.VSelect(v_model=('animation_format','mp4'),items=('animation_formats',[]),label='Format',disabled=('animation_busy',))
                    for key,label in [('width','Width (px)'),('height','Height (px)'),('duration','Duration (s)'),('fps','Frame Rate'),('start','Start Angle'),('end','End Angle')]:
                        compact.VTextField(v_model=('animation_'+key,state['animation_'+key]),label=label,type='number',step='any',disabled=('animation_busy',))
                    compact.VSelect(v_model=('animation_axis','z'),items=('animation_axes',[{'title':v.upper(),'value':v} for v in ('x','y','z')]),label='World Axis',disabled=('animation_busy',))
                    v3.VCheckbox(v_model=('animation_fit',True),label='Safe Fit',density='compact',hide_details=True,disabled=('animation_busy',))
                    html.P('Export the committed scene in an isolated renderer. Orbit each view about its target; keep the main canvas and cameras unchanged. Static orientation labels are omitted.',classes='bnv-pending')
                    html.P('Web limit: 120 frames / 120 million frame-pixels / 48 MiB / 180 seconds. Isolated background process; Cancel stops before downloads. PNG frames start separate downloads; browser permission may be required.',classes='bnv-pending')
                    html.P('{{ animation_status }}',classes='bnv-pending')
                    v3.VProgressLinear(v_if='animation_busy',model_value=('animation_total ? 100 * animation_progress / animation_total : 0',),color='#0754e9')
                    v3.VAlert('{{ animation_error }}',v_if='animation_error',type='error',density='compact')
                    with html.Div(classes='bnv-merge-actions'):
                        v3.VBtn('Export Animation',click="animation_busy = true; trigger('export_brainnet_animation').then(files => { for (const file of files) { utils.download(file.name, utils.get('Uint8Array').from(utils.get('atob')(file.data), c => c.charCodeAt(0)), file.mime); } animation_busy = false; }).catch(cause => { animation_error = 'Animation export failed: ' + (cause.message || JSON.stringify(cause)); animation_busy = false; })",color='#0754e9',disabled=('!rendered || animation_busy',))
                        v3.VBtn('Cancel',click="trigger('cancel_brainnet_animation')",variant='outlined',disabled=('!animation_busy || animation_cancel_pending',))
                        v3.VBtn('Close',click='animation_open = false',variant='outlined',disabled=('animation_busy',))
            with v3.VDialog(v_model=('atlas_open',False),max_width=800):
                with html.Div(classes=("'bnv-dialog bnv-merge '+(theme === 'Dark' ? 'dark' : '')",)):
                    html.H3('Atlas Nodes')
                    html.P('Generate unweighted region centroids in the atlas affine frame. No registration or snapping; centroids may fall outside a region.',classes='bnv-pending')
                    compact.VSelect(v_model=('atlas_library',''),items=('catalog_volume',[]),label='Atlas Library',disabled=('atlas_busy',))
                    v3.VFileInput(v_model=('atlas_files',[]),multiple=True,label='Upload Atlas',accept='.nii,.nii.gz,.hdr,.img',density='compact',hide_details=True,disabled=('atlas_busy',))
                    compact.VTextField(v_model=('atlas_regions',''),label='Region IDs',placeholder='Blank: all labels; e.g. 1-90 or 1-10,29,30',disabled=('atlas_busy',))
                    for key,label in [('atlas_module','Module'),('atlas_size','Size')]:
                        compact.VTextField(v_model=(key,0.),label=label,type='number',step='any',disabled=('atlas_busy',))
                    html.Pre('{{ atlas_preview }}',classes='bnv-summary bnv-convert-review')
                    html.P('{{ atlas_status }}',classes='bnv-pending')
                    for key,label in [('atlas_space','Coordinate Space'),('atlas_units','Units')]:
                        compact.VTextField(v_model=(key,''),label=label,disabled=('atlas_busy',))
                    v3.VCheckbox(v_model=('atlas_confirmed',False),label='I have reviewed the atlas coordinates, space and units.',density='compact',hide_details=True,disabled=('!atlas_ready || atlas_busy',))
                    html.P('Web limits: 32 million voxels / 10,000 output nodes. Labels retain numeric atlas IDs; Module and Size are uniform values, not computed connectivity measures.',classes='bnv-pending')
                    v3.VAlert('{{ atlas_error }}',v_if='atlas_error',type='error',density='compact')
                    with html.Div(classes='bnv-merge-actions'):
                        v3.VBtn('Save Node',click="atlas_busy = true; trigger('export_brainnet_atlas').then(file => { utils.download(file.name, utils.get('Uint8Array').from(utils.get('atob')(file.data), c => c.charCodeAt(0)), file.mime); atlas_busy = false; }).catch(cause => { atlas_error = 'Node export failed: ' + (cause.message || JSON.stringify(cause)); atlas_busy = false; })",color='#0754e9',disabled=('!atlas_ready || !atlas_confirmed || !atlas_space || !atlas_units || atlas_busy',))
                        v3.VBtn('Use Atlas Nodes',click=actions['atlas_use'],variant='outlined',disabled=('!atlas_ready || !atlas_confirmed || !atlas_space || !atlas_units || atlas_busy',))
                        v3.VBtn('Close',click='atlas_open = false',variant='outlined',disabled=('atlas_busy',))
            with v3.VDialog(v_model=('subdivide_open',False),max_width=800):
                with html.Div(classes=("'bnv-dialog bnv-merge '+(theme === 'Dark' ? 'dark' : '')",)):
                    html.H3('Subdivide Surface')
                    html.P('Linear midpoint subdivision: each triangle becomes four. Original vertices are retained; no smoothing or map transfer.',classes='bnv-pending')
                    with html.Div(classes='bnv-merge-library'):
                        compact.VSelect(v_model=('subdivide_library',''),items=('catalog_surface',[]),label='Surface Library',disabled=('subdivide_busy',))
                        v3.VBtn('Add Selected',click=actions['subdivide_add'],variant='outlined',disabled=('!subdivide_library || subdivide_items.length > 0 || subdivide_busy',))
                    v3.VFileInput(v_model=('subdivide_files',[]),multiple=True,label='Upload Surface',accept='.nv,.gii,.pial,.white,.inflated,.sphere,.surf,.orig,.mesh,.byu,.g,.obj,.mz3,.bin,.dat',density='compact',hide_details=True,show_size=True,disabled=('subdivide_busy || subdivide_items.length > 0',))
                    html.P('Choose one surface with any external GIfTI binary arrays. Geometry is reviewed automatically.',classes='bnv-pending')
                    with html.Div(classes='bnv-summary bnv-subdivide-review'):
                        html.Div('{{ item.title }}',v_for='item in subdivide_items')
                        html.Div('No input selected.',v_if='subdivide_items.length === 0')
                    v3.VBtn('Remove Input',click=actions['subdivide_remove'],variant='outlined',disabled=('subdivide_items.length === 0 || subdivide_busy',),classes='my-2')
                    compact.VSelect(v_model=('subdivide_levels',1),items=('subdivide_level_choices',[{'title':str(i),'value':i} for i in (1,2,3)]),label='Levels',disabled=('subdivide_busy',))
                    html.P('Web limits: 500,000 vertices / 1,000,000 faces; NV download up to 48 MiB.',classes='bnv-pending')
                    html.P('{{ subdivide_status }}',classes='bnv-pending')
                    v3.VAlert('{{ subdivide_error }}',v_if='subdivide_error',type='error',density='compact')
                    with html.Div(classes='bnv-merge-actions'):
                        v3.VBtn('Save NV',click=SUBDIVIDE_DOWNLOAD_JS,color='#0754e9',disabled=('!subdivide_ready || subdivide_busy',))
                        v3.VBtn('Use Subdivided Surface',click=actions['subdivide_use'],variant='outlined',disabled=('!subdivide_ready || subdivide_busy',))
                        v3.VBtn('Close',click='subdivide_open = false',variant='outlined',disabled=('subdivide_busy',))
            with v3.VDialog(v_model=('convert_open',False),max_width=800):
                with html.Div(classes=("'bnv-dialog bnv-merge '+(theme === 'Dark' ? 'dark' : '')",)):
                    html.H3('Convert Surface to NV')
                    html.P('Coordinates, vertex order and face connectivity are preserved. No registration or resampling is applied.',classes='bnv-pending')
                    with html.Div(classes='bnv-merge-library'):
                        compact.VSelect(v_model=('convert_library',''),items=('catalog_surface',[]),label='Surface Library',disabled=('convert_busy',))
                        v3.VBtn('Add Selected',click=actions['convert_add'],variant='outlined',disabled=('!convert_library || convert_items.length > 0 || convert_busy',))
                    v3.VFileInput(v_model=('convert_files',[]),multiple=True,label='Upload Surface',accept='.nv,.gii,.pial,.white,.inflated,.sphere,.surf,.orig,.mesh,.byu,.g,.obj,.mz3,.bin,.dat',density='compact',hide_details=True,show_size=True,disabled=('convert_busy || convert_items.length > 0',))
                    html.P('Choose one surface with any external GIfTI binary arrays. Geometry is reviewed automatically.',classes='bnv-pending')
                    with html.Div(classes='bnv-summary bnv-convert-review'):
                        html.Div('{{ item.title }}',v_for='item in convert_items')
                        html.Div('No input selected.',v_if='convert_items.length === 0')
                    v3.VBtn('Remove Input',click=actions['convert_remove'],variant='outlined',disabled=('convert_items.length === 0 || convert_busy',),classes='my-2')
                    for key,label in [('convert_space','Space (optional)'),('convert_units','Units (optional)'),('convert_note','Note (optional)')]:
                        compact.VTextField(v_model=(key,''),label=label,disabled=('convert_busy',))
                    html.P('{{ convert_status }}',classes='bnv-pending')
                    v3.VAlert('{{ convert_error }}',v_if='convert_error',type='error',density='compact')
                    with html.Div(classes='bnv-merge-actions'):
                        v3.VBtn('Save NV',click=CONVERT_DOWNLOAD_JS,color='#0754e9',disabled=('convert_items.length !== 1 || convert_busy',))
                        v3.VBtn('Use Converted Surface',click=actions['convert_use'],variant='outlined',disabled=('convert_items.length !== 1 || convert_busy',))
                        v3.VBtn('Close',click='convert_open = false',variant='outlined',disabled=('convert_busy',))
            with v3.VDialog(v_model=('merge_open',False),max_width=800):
                with html.Div(classes=("'bnv-dialog bnv-merge '+(theme === 'Dark' ? 'dark' : '')",)):
                    html.H3('Merge Surfaces')
                    html.P('Coordinates and vertex order are preserved. No registration or resampling is applied.',classes='bnv-pending')
                    with html.Div(classes='bnv-merge-library'):
                        compact.VSelect(v_model=('merge_library',''),items=('catalog_surface',[]),label='Surface Library',disabled=('merge_busy',))
                        v3.VBtn('Add Selected',click=actions['merge_add'],variant='outlined',disabled=('!merge_library || merge_busy',))
                    v3.VFileInput(v_model=('merge_files',[]),multiple=True,label='Upload Surfaces',accept='.nv,.gii,.pial,.white,.inflated,.sphere,.surf,.orig,.mesh,.byu,.g,.obj,.mz3,.bin,.dat',density='compact',hide_details=True,show_size=True,disabled=('merge_busy',))
                    html.P('Files are reviewed automatically after upload. Include any external GIfTI binary arrays.',classes='bnv-pending')
                    with html.Select(v_model=('merge_index',-1),size=5,classes='bnv-merge-list',disabled=('merge_busy',),**{'aria-label':'Merge Inputs'}):
                        html.Option('{{ item.title }}',v_for='(item,index) in merge_items',value=('index',))
                    with html.Div(classes='bnv-merge-actions'):
                        for name,operation,condition in [('Remove Selected','remove','merge_index < 0'),('Move Up','up','merge_index <= 0'),('Move Down','down','merge_index < 0 || merge_index >= merge_items.length - 1')]:
                            v3.VBtn(name,click=(actions['merge_edit'],f"['{operation}']"),variant='outlined',disabled=(condition+' || merge_busy',))
                    for key,label in [('merge_space','Space (optional)'),('merge_units','Units (optional)'),('merge_note','Note (optional)')]:
                        compact.VTextField(v_model=(key,''),label=label,disabled=('merge_busy',))
                    html.P('{{ merge_status }}',classes='bnv-pending')
                    v3.VAlert('{{ merge_error }}',v_if='merge_error',type='error',density='compact')
                    with html.Div(classes='bnv-merge-actions'):
                        v3.VBtn('Save NV',click=MERGE_DOWNLOAD_JS,color='#0754e9',disabled=('merge_items.length < 2 || merge_busy',))
                        v3.VBtn('Use Merged Surface',click=actions['merge_use'],variant='outlined',disabled=('merge_items.length < 2 || merge_busy',))
                        v3.VBtn('Close',click='merge_open = false',variant='outlined',disabled=('merge_busy',))
            with v3.VDialog(v_model=('node_colors_open',False),max_width=560):
                with html.Div(classes=("'bnv-dialog '+(theme === 'Dark' ? 'dark' : '')",)):
                    html.H3('Node Colors')
                    html.P("{{ ['modular','custom'].includes(node_color_mode) ? 'Rows follow sorted module order. Colors repeat if fewer rows than modules are supplied.' : 'Rows run from the lower to the upper mapped value. RGB channels are between 0 and 1.' }}")
                    with html.Div(classes='bnv-field-pair'):
                        v3.VTextField(v_model=('node_colors_order',1),label='Color Row',type='number',min=1,max=('node_colors_count',),step=1)
                        v3.VTextField(v_model=('node_colors_color','#808080'),label='Row Color',type='color')
                    v3.VBtn('Set Color',click=(actions['edit_node_color'],"['set']"),variant='outlined')
                    v3.VBtn('Add Color',click=(actions['edit_node_color'],"['add']"),variant='outlined',classes='ml-2')
                    v3.VBtn('Remove Selected',click=(actions['edit_node_color'],"['remove']"),variant='outlined',classes='ml-2',disabled=('node_colors_count <= 2',))
                    v3.VTextarea(v_model=('node_colors_draft',''),label='RGB Rows (JSON)',rows=5,classes='mt-2')
                    v3.VAlert('{{ node_colors_error }}',v_if='node_colors_error',type='error',density='compact')
                    v3.VBtn('Cancel',click='node_colors_open = false',variant='outlined')
                    v3.VBtn('Use Colors',click=actions['accept_node_colors'],color='#0754e9',classes='ml-2')
            with v3.VDialog(v_model=('edge_bind_open',False),max_width=560):
                with html.Div(classes=("'bnv-dialog '+(theme === 'Dark' ? 'dark' : '')",)):
                    html.H3('Load and Bind Edge Colors')
                    html.P('Choose a finite N-by-N numeric color-index matrix in the original loaded node order. Sorted unique values define color categories. No node reordering is applied. Maximum 32 MiB, four million entries and 4096 categories.')
                    v3.VFileInput(v_model=('edge_bind_files',[]),multiple=True,accept='.txt,.edge',label='Color Matrix')
                    v3.VCheckbox(v_model=('edge_order_confirmed',False),label='I confirm the original loaded node order',hide_details=True)
                    v3.VAlert('{{ error }}',v_if='error',type='error',density='compact')
                    v3.VBtn('Cancel',click='edge_bind_open = false; edge_bind_files = []; edge_order_confirmed = false',variant='outlined')
                    v3.VBtn('Bind',click=actions['bind_edge_colors'],color='#0754e9',classes='ml-2')
            with v3.VDialog(v_model=('upload_open',False),max_width=560):
                with html.Div(classes='bnv-dialog'):
                    html.H3('Add Files')
                    html.P('Choose one primary file per type. Upload paired HDR/IMG or external GIfTI arrays together. Up to 32 MiB per file, 64 MiB per batch; session limit 128 MiB. Files are temporary and removed when the server closes.')
                    v3.VFileInput(v_model=('upload_files',[]),multiple=True,label='Data Files',show_size=True)
                    v3.VAlert('{{ error }}',v_if='error',type='error',density='compact')
                    v3.VBtn('Cancel',click='upload_open = false; upload_files = []',variant='outlined')
                    v3.VBtn('Upload',click=actions['upload'],color='#0754e9',classes='ml-2')
            with v3.VDialog(v_model=('scene_open',False),max_width=560):
                with html.Div(classes='bnv-dialog'):
                    html.H3('Open Scene')
                    html.P('Open a portable Scene ZIP, or a Scene JSON referencing the bundled library. Maximum ZIP size: 64 MiB. External data must be included in the ZIP.')
                    v3.VFileInput(v_model=('scene_files',[]),multiple=True,accept='.json,.zip',label='Scene JSON / ZIP')
                    v3.VAlert('{{ error }}',v_if='error',type='error',density='compact')
                    v3.VBtn('Cancel',click='scene_open = false; scene_files = []',variant='outlined')
                    v3.VBtn('Open',click=actions['open_scene'],color='#0754e9',classes='ml-2')
            with v3.VDialog(v_model=('bind_open',False),max_width=560):
                with html.Div(classes='bnv-dialog'):
                    html.H3('{{ bind_kind === "rgb" ? "Load and Bind RGB" : "Load and Bind Mask" }}')
                    html.P('Use the original loaded vertex order. No registration or reordering is applied. A mask needs one binary column; RGB needs three columns in [0,1]. Include any external GIfTI arrays.')
                    v3.VFileInput(v_model=('bind_files',[]),multiple=True,label='Original-Order Data')
                    v3.VCheckbox(v_model=('bind_order_confirmed',False),label='I confirm the original loaded vertex order',hide_details=True)
                    v3.VAlert('{{ error }}',v_if='error',type='error',density='compact')
                    v3.VBtn('Cancel',click='bind_open = false; bind_files = []; bind_order_confirmed = false',variant='outlined')
                    v3.VBtn('Bind',click=actions['bind_surface'],color='#0754e9',classes='ml-2')
            with v3.VDialog(v_model=('legacy_open',False),max_width=720):
                with html.Div(classes='bnv-dialog'):
                    html.H3('Import Legacy EC Settings')
                    html.P('Settings only; current files and canvas are retained. Choose a trusted MATLAB v7 EC MAT file, at most 4 MiB. Text is never executed.')
                    v3.VCheckbox(v_model=('legacy_trusted',False),label='I trust the source of this EC file',hide_details=True)
                    v3.VFileInput(v_model=('legacy_files',[]),accept='.mat',label='EC MAT file',disabled=('!legacy_trusted',),show_size=True)
                    html.Pre('{{ legacy_review }}',style='max-height:300px;overflow:auto;white-space:pre-wrap')
                    v3.VAlert('{{ legacy_error }}',v_if='legacy_error',type='error')
                    v3.VBtn('Cancel',click='legacy_open = false',variant='outlined')
                    v3.VBtn('Use in Settings',click=actions['legacy_use'],disabled=('!legacy_ready || !legacy_trusted',),color='#0754e9',classes='ml-2')
            for key,title,text in (('help_open','Help','Select files, configure, Apply to render, then interact or export. Figure and provenance download separately; save locations follow browser settings. Pop Out expands the existing canvas in this tab; Return restores the panels. Resource information describes the rendering host.'),
                                   ('about_open','About',f'BrainNet Viewer {__version__} — Web development. Developer: Mingrui Xia. mxia@bnu.edu.cn · mingruixia@gmail.com')):
                with v3.VDialog(v_model=(key,False),max_width=620):
                    with html.Div(classes='bnv-dialog'):
                        html.H3(title); html.P(text)
                        if key=='help_open':
                            with html.Div(v_if='help_available'):
                                html.A('Shared Tutorials',href='/bnv-help-pages/docs/tutorials/unified/en/index.html',target='_blank',rel='noopener',classes='mr-3')
                                html.A('User Manual (PDF)',href='/bnv-help-assets/docs/manual/en/BrainNet_Viewer_2_Unified_User_Manual_EN.pdf',target='_blank',rel='noopener')
                            html.P('Bundled documentation is unavailable.',v_if='!help_available')
                        v3.VBtn('Close',click=f'{key} = false',classes='mt-3')
    return view
