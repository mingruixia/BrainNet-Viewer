"""Compact labelled Web forms matching the desktop panel layout."""

CSS = """
.bnv-heading {padding:7px 10px;font-size:13px}
.bnv-left-scroll {padding:8px;display:flex;flex-direction:column;gap:6px}
.bnv-hint {padding:4px;border:0;margin:0;font-size:12px}
.bnv .v-btn {height:30px!important;padding:0 8px}
.bnv .bnv-banner .v-btn {height:34px!important}.bnv .bnv-toggle {height:28px!important}
.bnv-data-actions {margin:0;gap:4px}.bnv-data-actions .v-btn {height:30px;font-size:11px}
.bnv-source-row {grid-template-columns:80px minmax(0,1fr) 36px 26px;gap:3px;align-items:center}
.bnv-source-row>label {font-size:11px;font-weight:600;line-height:1.2}
.bnv-source-row .v-btn {height:30px;padding:0 3px}.bnv-file {margin:0;min-width:0}
.bnv-summary {flex:1;min-height:95px;max-height:none;margin:0;padding:6px;font:12px/1.45 'Segoe UI',Arial,sans-serif}
.bnv-control-row {display:grid;grid-template-columns:108px minmax(0,1fr);align-items:center;gap:6px;margin-bottom:5px;min-width:0}
.bnv-control-row>label {font-size:12px;line-height:1.25;overflow-wrap:anywhere}
.bnv-control-row:has(.v-input--disabled)>label {opacity:.5}
.bnv-control-row .v-input,.bnv-source-row .v-input {min-width:0}
.bnv-control-row .v-field,.bnv-source-row .v-field {--v-input-control-height:30px;--v-field-padding-top:0px;--v-field-padding-bottom:0px;--v-field-padding-start:6px;--v-field-padding-end:4px}
.bnv-control-row .v-field__input,.bnv-source-row .v-field__input {min-height:30px;padding-top:3px;padding-bottom:3px}
.bnv-control-row .v-select__selection,.bnv-source-row .v-select__selection {margin-top:0;margin-bottom:0}
.bnv-control-row input[type=color] {height:30px;padding:3px;cursor:pointer}
.bnv-field-pair {align-items:start;gap:6px}
.bnv-field-pair .bnv-control-row {grid-template-columns:minmax(0,1fr);gap:3px}
.bnv-opacity {display:grid;grid-template-columns:minmax(0,1fr) 76px;gap:6px;align-items:center}
.bnv-opacity .bnv-control-row {display:block;margin:0}
.bnv-opacity .bnv-control-row>label {position:absolute;width:1px;height:1px;overflow:hidden;clip-path:inset(50%)}
.bnv .v-selection-control {--v-input-control-height:30px;min-height:30px}
.bnv .v-checkbox .v-input__details {display:none}
.bnv-export {padding:7px}.bnv-export h3 {margin-bottom:6px}
.bnv-export-grid {grid-template-columns:minmax(75px,1fr) minmax(62px,.85fr) minmax(88px,1fr);gap:5px}
.bnv-export-grid .bnv-control-row {grid-template-columns:minmax(0,1fr);gap:3px;margin:0}
.bnv-export-grid .v-checkbox {grid-column:auto;align-self:end}
.bnv-export-grid .v-selection-control__wrapper {width:23px}.bnv-export-grid .v-label {font-size:11px!important}
.bnv-export .v-btn {height:30px}.bnv-export .v-field__input {min-height:30px;padding-top:3px;padding-bottom:3px}
.bnv-toolbar {padding:6px;gap:4px}.bnv-toolbar .v-btn {height:30px}
.bnv-right-header {min-height:36px;padding:4px 8px}.bnv-right-header h3 {font-size:13px}
.bnv-settings-body {gap:5px;padding:0 6px 6px}
.bnv .v-expansion-panel-title,.bnv .v-expansion-panel-title--active {min-height:32px!important;padding:6px 8px}
.bnv .v-expansion-panel--active:not(:first-child),.bnv .v-expansion-panel--active + .v-expansion-panel {margin-top:0}
.bnv .v-expansion-panel-text__wrapper {padding:7px 4px}
.bnv .v-expansion-panel-text h4 {margin:7px 0 4px;font-size:12px}
.bnv-pending {padding:3px 0;font-size:11px;line-height:1.35}
.bnv-canvas-status {padding:4px 8px;font-size:11px}.bnv-strip {padding:4px 8px;font-size:11px}
.bnv-tools {border-top:1px solid var(--border);padding-top:5px}.bnv-tools h4 {font-size:12px;margin-bottom:4px}
.bnv-three-actions {grid-template-columns:repeat(3,minmax(0,1fr))}
.bnv-merge {max-height:calc(100dvh - 48px);overflow:auto;font-family:'Segoe UI',Arial,sans-serif}
.bnv-merge .bnv-control-row {grid-template-columns:112px minmax(0,1fr)}
.bnv-merge .v-field {background:var(--panel);color:var(--ink);font-size:12px}
.bnv-merge .v-input__details {display:none}.bnv-merge .v-btn {height:30px!important}
.bnv-merge-library {display:grid;grid-template-columns:minmax(0,1fr) 110px;align-items:center;gap:6px;margin:8px 0}
.bnv-merge-list {display:block;width:100%;height:145px;margin:8px 0;background:var(--panel);color:var(--ink);border:1px solid #789;border-radius:4px;font:12px/1.4 'Segoe UI',Arial,sans-serif}
.bnv-merge-list option {padding:4px 6px}
.bnv-merge-actions {display:flex;gap:6px;flex-wrap:wrap;margin:8px 0}
.bnv-convert-review {min-height:55px;margin:8px 0;flex:none;overflow-wrap:anywhere}
@media(max-width:1100px) and (min-width:961px) {.bnv-grid{grid-template-columns:260px minmax(0,1fr) 280px}.bnv-grid.collapsed{grid-template-columns:260px minmax(0,1fr) 44px}.bnv-source-row{grid-template-columns:76px minmax(0,1fr) 30px 24px}.bnv-control-row{grid-template-columns:96px minmax(0,1fr)}}
@media(max-width:960px) {.bnv-control-row{grid-template-columns:108px minmax(0,1fr)}}
"""


class CompactControls:
    def __init__(self, widgets, html):
        self.widgets, self.html = widgets, html

    def __getattr__(self, name):
        widget = getattr(self.widgets, name)
        if name not in ('VSelect', 'VTextField'):
            return widget

        def field(*args, **kwargs):
            label = kwargs.pop('label', '')
            control_id = 'bnv-' + kwargs['v_model'][0]
            visibility = {key: kwargs.pop(key) for key in ('v_if', 'v_show') if key in kwargs}
            with self.html.Div(classes='bnv-control-row', **visibility):
                self.html.Label(label, **{'for': control_id})
                kwargs.update(id=control_id, density='compact', variant='outlined', hide_details=True)
                return widget(*args, **kwargs)
        return field
