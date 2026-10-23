"""English desktop workflow. Development build, not a release candidate."""
from copy import deepcopy
from pathlib import Path
import argparse
import json
import math
import re
import sys
from PySide6 import QtCore, QtGui, QtWidgets as W
from .qt_rendering import QtInteractor
from . import __version__
from .settings import DEFAULTS, normalize
from .scene import read_scene, portable_scene
from .rendering import prepare, layout, SceneRenderer, PALETTES
from .inspect import lookup
from .io import read_surface
from .rendering import hemispheres
from .export_size import figure_size, unit_scale
from .session import KEY, signature, content_hashes, validate_session
from .palettes import palette
from .hardware import mac_hardware
from .help_ui import HelpDialog
from .desktop_style import Accordion, FitImage, SettingsChoice, CompactNumber, card, stylesheet, section_label, GROUPS, field_label, choice_label

ROOT = Path(__file__).resolve().parents[3]
RESOURCE_ROOT = Path(__file__).resolve().parent / "resources"
DEVELOPMENT_LIBRARY = ROOT / "src/matlab/BrainNetViewer"
_PACKAGED_LIBRARY_READY = (RESOURCE_ROOT / "BrainNet_AAL_Label.mat").is_file() and (RESOURCE_ROOT / "Data/SurfTemplate").is_dir()
LIBRARY = RESOURCE_ROOT if _PACKAGED_LIBRARY_READY else DEVELOPMENT_LIBRARY
HELP_FILE = RESOURCE_ROOT / "Help.en.md"
ENUMS = {
    "shading":["interp","flat","faceted"], "selection_mode":["all","threshold","connected"],
    "selection_basis":["value","module"], "size_mode":["uniform","mapped","raw","threshold"],
    "size_basis":["value","module"], "size_threshold_basis":["mapped","raw"], "value_mode":["absolute","signed"],
    "size_value_mode":["absolute","signed"], "mapped_value_mode":["absolute","signed"],
    "threshold_value_mode":["absolute","signed"], "label_mode":["none","all","threshold"], "label_basis":["value","module"],
    "threshold_mode":["none","value","cluster","p-value"], "type":["surface-map","roi"],
    "display_mode":["both","positive","negative"], "smoothing":["gaussian","box","none"],
    "label_font_weight":["normal","bold"], "label_font_angle":["normal","italic"],
    "label_font_units":["points","pixels","normalized","inches","centimeters"],
}
class ModulePaletteDialog(W.QDialog):
    """Edit RGB rows without changing committed settings until accepted."""
    def __init__(self, colors, parent=None, *, module_order=True):
        super().__init__(parent); self.setWindowTitle("Module Colors")
        box=W.QVBoxLayout(self)
        note=W.QLabel("Rows follow sorted module order. Colors repeat if there are fewer rows than modules." if module_order else "Rows run from the lower to the upper end of the mapped value range. RGB colors must be between 0 and 1."); note.setWordWrap(True); box.addWidget(note)
        self.table=W.QTableWidget(0,2); self.table.setHorizontalHeaderLabels(["Order","Color"])
        self.table.horizontalHeader().setSectionResizeMode(W.QHeaderView.Stretch)
        self.table.setSelectionBehavior(W.QAbstractItemView.SelectRows); box.addWidget(self.table)
        for rgb in colors: self.add_color(rgb)
        row=W.QHBoxLayout(); self.add_button=W.QPushButton("Add Color"); self.remove_button=W.QPushButton("Remove Selected")
        self.add_button.clicked.connect(lambda:self.add_color([.5,.5,.5])); self.remove_button.clicked.connect(self.remove_colors)
        row.addWidget(self.add_button); row.addWidget(self.remove_button); box.addLayout(row)
        self.buttons=W.QDialogButtonBox(W.QDialogButtonBox.Ok|W.QDialogButtonBox.Cancel)
        self.buttons.accepted.connect(self.accept); self.buttons.rejected.connect(self.reject); box.addWidget(self.buttons)
        self.resize(420,420); self.update_buttons()

    def add_color(self, rgb):
        if self.table.rowCount()>=4096: return
        index=self.table.rowCount(); self.table.insertRow(index)
        item=W.QTableWidgetItem(str(index+1)); item.setFlags(item.flags() & ~QtCore.Qt.ItemIsEditable); self.table.setItem(index,0,item)
        button=W.QPushButton("Choose…"); button.setProperty("rgb",list(rgb)); self.table.setCellWidget(index,1,button)
        def swatch():
            color=QtGui.QColor.fromRgbF(*button.property("rgb")); button.setStyleSheet(f"background-color: {color.name()}; color: {'black' if color.lightnessF()>.5 else 'white'};")
        def choose():
            color=W.QColorDialog.getColor(QtGui.QColor.fromRgbF(*button.property("rgb")),self,"Module color")
            if color.isValid(): button.setProperty("rgb",[color.redF(),color.greenF(),color.blueF()]); swatch()
            self.raise_(); self.activateWindow()
        swatch(); button.clicked.connect(choose)
        if hasattr(self,"buttons"): self.update_buttons()

    def remove_colors(self):
        indices=sorted({item.row() for item in self.table.selectedIndexes()},reverse=True)
        for index in indices:
            if self.table.rowCount()>2: self.table.removeRow(index)
        for index in range(self.table.rowCount()): self.table.item(index,0).setText(str(index+1))
        self.update_buttons()

    def update_buttons(self):
        self.add_button.setEnabled(self.table.rowCount()<4096)
        self.remove_button.setEnabled(self.table.rowCount()>2)
        self.buttons.button(W.QDialogButtonBox.Ok).setEnabled(self.table.rowCount()>=2)

    def colors(self):
        colors=[list(self.table.cellWidget(index,1).property("rgb")) for index in range(self.table.rowCount())]
        palette(colors)  # retain original rows; validation does not resample the result
        return colors


class SettingsPanel(W.QWidget):
    changed = QtCore.Signal()
    binding_requested = QtCore.Signal(str)

    def __init__(self, settings):
        super().__init__()
        self.settings = deepcopy(settings)
        self.readers = {}
        self.controls = {}
        self.build()

    def build(self):
        outer=W.QVBoxLayout(self); outer.setContentsMargins(0,0,0,0)
        self.box=Accordion(); outer.addWidget(self.box)
        for category,groups in GROUPS.items():
            inner=W.QWidget(); form=W.QFormLayout(inner)
            form.setContentsMargins(9,5,9,10); form.setVerticalSpacing(7); form.setHorizontalSpacing(9)
            form.setFieldGrowthPolicy(W.QFormLayout.AllNonFixedFieldsGrow)
            form.setRowWrapPolicy(W.QFormLayout.WrapLongRows)
            for heading,section,keys in groups:
                if heading: form.addRow(section_label(heading))
                for key in keys.split():
                    value=self.settings[section][key]; control,reader=self.control(section,key,value)
                    self.readers[(section,key)]=reader; self.controls[(section,key)]=control
                paired={
                    ("node","label_font_weight"):("Font Style",("label_font_weight","label_font_angle")),
                    ("node","size"):("Base Size / Scale",("size","size_scale")),
                    ("node","size_threshold"):("Size Threshold",("size_threshold_basis","size_threshold")),
                    ("node","color_low"):("",("color_low","color_high")),
                    ("edge","color_low"):("",("color_low","color_high")),
                    ("edge","inter_hemisphere_only"):("",("directed","inter_hemisphere_only")),
                    ("edge","arrow_length_scale"):("",("arrow_length_scale","arrow_width_scale")),
                    ("volume","positive_minimum"):("Positive Range",("positive_minimum","positive_maximum")),
                    ("volume","negative_minimum"):("Negative Range",("negative_minimum","negative_maximum")),
                }
                skip=set()
                for key in keys.split():
                    if key in skip: continue
                    control=self.controls[(section,key)]; value=self.settings[section][key]
                    if (section,key) in paired:
                        label,members=paired[(section,key)]; pair=W.QWidget(); row=W.QHBoxLayout(pair); row.setContentsMargins(0,0,0,0); row.setSpacing(6)
                        for member in members:
                            widget=self.controls[(section,member)]; skip.add(member)
                            widget.setMinimumWidth(0); widget.setSizePolicy(W.QSizePolicy.Ignored,W.QSizePolicy.Preferred)
                            if member in ("color_low","color_high"): widget.setText("Low (<=)" if member=="color_low" else "High (>)")
                            if isinstance(widget,W.QCheckBox): widget.setText(field_label(section,member))
                            if member in ("arrow_length_scale","arrow_width_scale"): row.addWidget(W.QLabel("Length" if member=="arrow_length_scale" else "Width"))
                            if section=="volume": widget.setToolTip("Lower bound" if member.endswith("minimum") else "Upper bound")
                            row.addWidget(widget,1)
                        form.addRow(label,pair) if label else form.addRow(pair)
                        continue
                    label=field_label(section,key)
                    if key in ("material_coefficients","custom_colors","color_limits","opacity_range","boundary_mask","vertex_colors","custom_color"):
                        if key=="material_coefficients": label="Custom Material"
                        if key=="custom_colors": label="Custom ROI Colors"
                        form.addRow(W.QLabel(label)); form.addRow(control)
                    elif isinstance(value,bool):
                        control.setText(label); form.addRow(control)
                    else: form.addRow(label,control)
            if category=="layout":
                note=W.QLabel("Multi-view presets use their own camera directions."); note.setWordWrap(True); note.setObjectName("Muted"); form.addRow(note)
            self.box.addItem(inner,{"node":"Nodes","edge":"Edges"}.get(category,category.title()))
        self.changed.connect(self.update_dependencies); self.update_dependencies()

    def update_dependencies(self):
        def get(section,key):
            widget=self.controls[(section,key)]
            if isinstance(widget,W.QCheckBox): return widget.isChecked()
            if isinstance(widget,W.QComboBox): return widget.currentData()
            return self.readers[(section,key)]()
        def enable(section,keys,value):
            for key in keys.split(): self.controls[(section,key)].setEnabled(bool(value))
        custom=get("layout","preset")==1 and get("layout","view_direction")==4
        enable("layout","view_direction",get("layout","preset")==1)
        enable("layout","custom_azimuth custom_elevation",custom)
        enable("global","material_coefficients",get("global","material_profile")=="custom")
        surface=get("surface","color_mode")
        enable("surface","color",surface=="uniform"); enable("surface","colormap color_limits show_colorbar",surface=="scalar")
        enable("surface","boundary_color boundary_threshold",get("surface","boundary_mode")!="none")
        enable("surface","boundary_mask",get("surface","boundary_mode")=="custom")
        enable("surface","vertex_colors",surface=="vertex-rgb")
        enable("node","selection_basis threshold",get("node","selection_mode")=="threshold")
        labels=get("node","label_mode")
        enable("node","label_basis label_threshold",labels=="threshold")
        enable("node","label_font_name label_font_size label_font_weight label_font_angle label_font_units label_color label_in_front",labels!="none")
        size=get("node","size_mode")
        enable("node","size",size=="uniform"); enable("node","size_basis",size!="uniform")
        enable("node","size_threshold size_threshold_basis",size=="threshold")
        mode=get("node","color_mode")
        enable("node","color",mode=="uniform"); enable("node","colormap",mode in ("mapped","modular","custom"))
        enable("node","color_limits",mode=="mapped"); enable("node","color_threshold color_low color_high",mode=="threshold")
        selection=get("edge","selection_mode")
        enable("edge","threshold",selection=="threshold"); enable("edge","sparsity",selection=="sparsity")
        size=get("edge","size_mode")
        enable("edge","size",size=="uniform"); enable("edge","size_value_mode",size!="uniform")
        enable("edge","size_threshold size_threshold_basis",size=="threshold")
        mode=get("edge","color_mode")
        enable("edge","color",mode=="uniform"); enable("edge","colormap",mode in ("mapped","custom"))
        enable("edge","color_limits mapped_value_mode",mode=="mapped")
        enable("edge","custom_color",mode=="custom"); enable("edge","inter_module_color",mode=="node-module")
        enable("edge","color_threshold threshold_value_mode",mode=="threshold"); enable("edge","length_threshold",mode=="length")
        enable("edge","color_low color_high",mode in ("threshold","length"))
        self.controls[("edge","color_low")].setText("Short (<)" if mode=="length" else "Low (<=)")
        self.controls[("edge","color_high")].setText("Long (>=)" if mode=="length" else "High (>)")
        enable("edge","arrow_length_scale arrow_width_scale",get("edge","directed"))
        mapped=get("edge","opacity_mode")=="mapped"
        enable("edge","opacity",not mapped); enable("edge","opacity_range opacity_value_mode",mapped)
        display=get("volume","display"); roi=display and get("volume","type")=="roi"
        smap=display and not roi; threshold=get("volume","threshold_mode")
        enable("volume","type threshold_mode",display)
        enable("volume","statistical_threshold",display and threshold in ("value","cluster"))
        enable("volume","p_value",display and threshold=="p-value")
        enable("volume","cluster_size",display and (threshold=="cluster" or roi and threshold=="p-value"))
        enable("volume","voxel_connectivity",display and (threshold=="cluster" or roi and threshold in ("value","p-value")))
        enable("volume","map_algorithm positive_minimum positive_maximum negative_minimum negative_maximum colormap display_mode adjust_null",smap)
        enable("volume","null_color",False)  # Adjust Null follows the base surface color.
        self.controls[("volume","null_color")].setText("Uses Surface Color")
        self.controls[("volume","null_color")].setToolTip("Adjust Null uses Surface Uniform Color, not an independent null color.")
        self.controls[("volume","null_color")].setText("Uses Surface Color")
        self.controls[("volume","null_color")].setToolTip("Adjust Null uses Surface Uniform Color, not an independent null color.")
        enable("roi","draw_all color_mode show_legend smoothing",roi)
        enable("roi","selection",roi and not get("roi","draw_all"))
        mode=get("roi","color_mode")
        enable("roi","palette",roi and mode=="index"); enable("roi","custom_colors",roi and mode=="custom")
        enable("roi","color",roi and mode=="uniform"); enable("roi","smoothing_kernel",roi and get("roi","smoothing")!="none")

    def control(self, section, key, value):
        if (section,key) in (("surface","boundary_mask"),("surface","vertex_colors"),("edge","custom_color")):
            kind={"boundary_mask":"boundary","vertex_colors":"rgb","custom_color":"edge"}[key]
            widget=W.QWidget(); row=W.QVBoxLayout(widget); row.setContentsMargins(0,0,0,0)
            size=len(value.get("matrix",[])) if isinstance(value,dict) else len(value)
            info=W.QLabel(f"{size:,} rows loaded" if size else "No data loaded"); info.setWordWrap(True); info.setObjectName("Muted"); row.addWidget(info)
            if kind=="edge" and isinstance(value,dict):
                info.setText(f"{size:,} × {size:,} color-index matrix · {len(value.get('indices',[])):,} categories")
                info.setToolTip(str(value.get("source","")))
            button=W.QPushButton({"boundary":"Load and Bind Mask…","rgb":"Load and Bind RGB…","edge":"Load and Bind Matrix…"}[kind])
            button.clicked.connect(lambda:self.binding_requested.emit(kind)); row.addWidget(button)
            return widget,lambda:deepcopy(value)
        if section=="surface" and key=="opacity":
            widget=W.QWidget(); row=W.QHBoxLayout(widget); row.setContentsMargins(0,0,0,0)
            slider=W.QSlider(QtCore.Qt.Horizontal); slider.setRange(0,1000); slider.setValue(round(value*1000))
            field=W.QDoubleSpinBox(); field.setDecimals(3); field.setRange(0,1); field.setSingleStep(.05); field.setValue(value); field.setFixedWidth(70)
            field.setButtonSymbols(W.QAbstractSpinBox.NoButtons)
            row.addWidget(slider,1); row.addWidget(field); edited=[False]
            def moved(number): field.setValue(number/1000)
            def typed(number):
                slider.blockSignals(True); slider.setValue(round(number*1000)); slider.blockSignals(False); edited[0]=True; self.changed.emit()
            slider.valueChanged.connect(moved); field.valueChanged.connect(typed)
            return widget,lambda:field.value() if edited[0] else value
        if section=="layout" and key in ("custom_azimuth","custom_elevation"):
            widget=W.QLineEdit("" if value==[] else repr(value)); widget.setPlaceholderText("Default (leave both empty)")
            widget.setToolTip("Degrees: azimuth −360 to 360, elevation −90 to 90. Enter both, or clear both for the default custom view.")
            widget.textChanged.connect(self.changed)
            def read_angle():
                text=widget.text().strip()
                if not text: return []
                try: angle=float(text)
                except ValueError: raise ValueError("Custom view angles must be finite numbers in degrees.") from None
                if not math.isfinite(angle): raise ValueError("Custom view angles must be finite.")
                return angle
            return widget,read_angle
        if key=="colormap":
            widget=W.QWidget(); row=W.QHBoxLayout(widget); row.setContentsMargins(0,0,0,0)
            choice=SettingsChoice(); choice.setObjectName("ModulePaletteChoice")
            for name in PALETTES: choice.addItem(name,name)
            if not isinstance(value,str): choice.addItem("Custom (Colors...)","Custom RGB"); choice.setCurrentText("Custom RGB")
            else: choice.setCurrentText(value)
            custom=[deepcopy(value) if not isinstance(value,str) else None]
            button=W.QPushButton("Colors…"); button.setObjectName("ModulePaletteEdit")
            row.addWidget(choice,1); row.addWidget(button)
            choice.currentTextChanged.connect(self.changed)
            widget.setToolTip("Mapped values use this colormap; modular colors follow sorted module order. Colors… edits RGB rows." if section=="node" else "Choose a named colormap or use Colors… to edit RGB rows.")
            def edit():
                colors=custom[0] if choice.currentData()=="Custom RGB" else palette(choice.currentData(),7 if section=="node" else 256).tolist()
                dialog=ModulePaletteDialog(colors,self,module_order=section=="node")
                if section!="node": dialog.setWindowTitle("Colormap RGB Colors")
                from .desktop_style import style_dialog
                style_dialog(dialog,460,500)
                try:
                    if dialog.exec()==W.QDialog.Accepted:
                        custom[0]=dialog.colors()
                        if choice.findData("Custom RGB")<0: choice.addItem("Custom (Colors...)","Custom RGB")
                        choice.setCurrentText("Custom RGB"); self.changed.emit()
                finally: dialog.deleteLater(); self.window().raise_(); self.window().activateWindow()
            button.clicked.connect(edit)
            return widget,lambda: deepcopy(custom[0]) if choice.currentData()=="Custom RGB" else choice.currentData()
        if key in ("color_limits","opacity_range") or section=="volume" and key in ("positive_minimum","positive_maximum","negative_minimum","negative_maximum"):
            widget=W.QWidget(); row=W.QHBoxLayout(widget); row.setContentsMargins(0,0,0,0)
            pair=key in ("color_limits","opacity_range"); automatic=key!="opacity_range"
            auto=W.QCheckBox("Auto"); auto.setObjectName("RangeAuto"); auto.setChecked(value==[])
            fields=[]
            if automatic: row.addWidget(auto)
            for index in range(2 if pair else 1):
                original=value[index] if pair and value else value if not pair and value!=[] else None
                field=W.QLineEdit("" if original is None else repr(original)); field.setObjectName("RangeMin" if index==0 else "RangeMax")
                field.setPlaceholderText(("Min" if index==0 else "Max") if pair else "Number"); field.setToolTip(("Minimum" if index==0 else "Maximum") if pair else "Numeric bound; scientific notation is accepted"); field.setMinimumWidth(45)
                field.setSizePolicy(W.QSizePolicy.Ignored,W.QSizePolicy.Fixed)
                field.textChanged.connect(self.changed); row.addWidget(field); fields.append(field)
            def enable(checked):
                for field in fields: field.setEnabled(not checked)
            if automatic: auto.toggled.connect(enable); auto.toggled.connect(self.changed); enable(auto.isChecked())
            def read_range():
                if automatic and auto.isChecked(): return []
                try: bounds=[float(field.text()) for field in fields]
                except ValueError: raise ValueError(f"{section}.{key}: enter finite numbers or select Auto.") from None
                if not all(math.isfinite(bound) for bound in bounds): raise ValueError(f"{section}.{key}: numbers must be finite.")
                return bounds if pair else bounds[0]
            return widget,read_range
        if section=="roi" and key=="custom_colors":
            widget=W.QWidget(); box=W.QVBoxLayout(widget); box.setContentsMargins(0,0,0,0)
            table=W.QTableWidget(0,2); table.setObjectName("ROIColors"); table.setHorizontalHeaderLabels(["ROI ID","Color"])
            table.horizontalHeader().setSectionResizeMode(W.QHeaderView.Stretch); table.setSelectionBehavior(W.QAbstractItemView.SelectRows)
            table.setMinimumHeight(120); box.addWidget(table)
            def append(label,rgb):
                index=table.rowCount(); table.insertRow(index)
                item=W.QTableWidgetItem(str(label)); table.setItem(index,0,item)
                button=W.QPushButton("Choose…"); button.setProperty("rgb",list(rgb)); table.setCellWidget(index,1,button)
                def swatch():
                    color=QtGui.QColor.fromRgbF(*button.property("rgb")); button.setStyleSheet(f"background-color: {color.name()}; color: {'black' if color.lightnessF()>.5 else 'white'};")
                def pick():
                    color=W.QColorDialog.getColor(QtGui.QColor.fromRgbF(*button.property("rgb")),self,"ROI color")
                    if color.isValid(): button.setProperty("rgb",[color.redF(),color.greenF(),color.blueF()]); swatch(); self.changed.emit()
                swatch(); button.clicked.connect(pick)
            for label,*rgb in value: append(label,rgb)
            table.itemChanged.connect(self.changed)
            actions=W.QHBoxLayout(); add=W.QPushButton("Add ROI"); remove=W.QPushButton("Remove Selected"); actions.addWidget(add); actions.addWidget(remove); box.addLayout(actions)
            def add_row():
                used={table.item(i,0).text() for i in range(table.rowCount())}; label=1
                while str(label) in used: label+=1
                append(label,[.5,.5,.5]); self.changed.emit()
            def remove_rows():
                for index in sorted({item.row() for item in table.selectedIndexes()},reverse=True): table.removeRow(index)
                self.changed.emit()
            add.clicked.connect(add_row); remove.clicked.connect(remove_rows)
            def read_colors():
                colors=[]; seen=set()
                for index in range(table.rowCount()):
                    try: label=float(table.item(index,0).text())
                    except ValueError: raise ValueError("Custom ROI Colors require positive integer IDs.") from None
                    if not math.isfinite(label) or label<1 or label!=int(label) or label in seen: raise ValueError("Custom ROI Colors require unique positive integer IDs.")
                    seen.add(label); colors.append([int(label),*table.cellWidget(index,1).property("rgb")])
                return colors
            return widget,read_colors
        if section=="roi" and key=="selection":
            widget=W.QLineEdit(" ".join(str(label) for label in value)); edited=[False]
            widget.setPlaceholderText("29 30 or 29, 30")
            widget.setToolTip("Positive integer ROI labels separated by spaces or commas. JSON lists are also accepted.")
            widget.textChanged.connect(lambda _:edited.__setitem__(0,True)); widget.textChanged.connect(self.changed)
            def read_selection():
                if not edited[0]: return list(value)
                text=widget.text().strip()
                try:
                    entries=json.loads(text) if text.startswith("[") else re.split(r"[,\s]+",text) if text else []
                    if not isinstance(entries,list): raise ValueError()
                    numbers=[float(item) for item in entries]
                    if any(isinstance(item,bool) for item in entries) or any(not math.isfinite(n) or n<1 or n!=int(n) for n in numbers): raise ValueError()
                    return list(dict.fromkeys(int(n) for n in numbers))
                except (ValueError,TypeError,OverflowError):
                    raise ValueError("ROI Selection must contain positive integer labels separated by spaces or commas.") from None
            return widget,read_selection
        if section=="volume" and key=="voxel_connectivity":
            widget=W.QComboBox()
            for neighbors in (6,18,26): widget.addItem(f"{neighbors} Neighbors",neighbors)
            widget.setCurrentIndex(widget.findData(value)); widget.currentIndexChanged.connect(self.changed)
            return widget,widget.currentData
        if section=="volume" and key=="p_value":
            widget=W.QLineEdit(repr(value)); widget.setPlaceholderText("0.05 or 1e-8")
            widget.setToolTip("Voxelwise, uncorrected P value (0 < P < 1). Cluster size is an extent filter, not a corrected cluster P value. Scientific notation is accepted.")
            widget.textChanged.connect(self.changed)
            def read_p():
                try: result=float(widget.text())
                except ValueError: raise ValueError("P value must be a finite number, such as 0.05 or 1e-8.") from None
                if not math.isfinite(result): raise ValueError("P value must be finite.")
                return result
            return widget,read_p
        if section=="global" and key=="material_coefficients":
            widget=W.QWidget(); form=W.QFormLayout(widget); form.setContentsMargins(0,0,0,0)
            fields=[]; defaults=list(value)+[10,1][max(0,len(value)-3):]; edited=[False]*5
            for index,label in enumerate(("Ambient","Diffuse","Specular","Exponent","Color Mix")):
                field=W.QDoubleSpinBox(); field.setObjectName("Material"+label.replace(" ",""))
                field.setDecimals(5); field.setRange(0,max(128,value[3]) if index==3 and len(value)>3 else 128 if index==3 else 1)
                field.setSingleStep(1 if index==3 else .05); field.setValue(defaults[index])
                field.setToolTip("Specular color reflectance: 0 uses object and light color; 1 uses only light color." if index==4 else
                                 "Specular exponent: renderer supports 0–128." if index==3 else label+" strength (0–1).")
                field.valueChanged.connect(lambda _value,i=index:edited.__setitem__(i,True))
                field.valueChanged.connect(self.changed); form.addRow(label,field); fields.append(field)
            def read_material():
                current=[field.value() if edited[i] else defaults[i] for i,field in enumerate(fields)]
                count=5 if len(value)==5 or current[4]!=1 else 4 if len(value)>=4 or current[3]!=10 else 3
                return current[:count]
            return widget,read_material
        if section=="layout" and key in ("preset","view_direction") or section=="volume" and key=="map_algorithm":
            labels={"preset":["Single View","Overview (8 Views)","Lateral / Medial","Lateral / Medial / Ventral","Lateral / Medial / Dorsal"],
                    "view_direction":["Left (Sagittal)","Superior (Axial)","Anterior (Coronal)","Custom","Right","Inferior","Posterior","Isometric"],
                    "map_algorithm":["Nearest","Nearest + Surface Smoothing","Box Mean","Gaussian","Trilinear","Maximum","Minimum","Maximum Absolute"]}[key]
            widget=W.QComboBox()
            for code,label in enumerate(labels,1): widget.addItem(label,code)
            widget.setCurrentIndex(widget.findData(value)); widget.currentIndexChanged.connect(self.changed)
            return widget,widget.currentData
        if isinstance(value,bool):
            widget=W.QCheckBox(); widget.setChecked(value); widget.toggled.connect(self.changed)
            return widget,widget.isChecked
        if key in ("color","background_color","label_color","color_low","color_high","null_color","inter_module_color","boundary_color") and isinstance(value,list) and len(value)==3:
            widget=W.QPushButton("Choose color…"); widget.setProperty("rgb",list(value))
            def swatch():
                color=QtGui.QColor.fromRgbF(*widget.property("rgb"))
                pixmap=QtGui.QPixmap(20,14); pixmap.fill(color); widget.setIcon(QtGui.QIcon(pixmap))
                widget.setToolTip("Current color: "+color.name())
            def pick():
                color=W.QColorDialog.getColor(QtGui.QColor.fromRgbF(*widget.property("rgb")),self,"Choose color")
                if color.isValid(): widget.setProperty("rgb",[color.redF(),color.greenF(),color.blueF()]); swatch(); self.changed.emit()
                self.window().raise_(); self.window().activateWindow()
            swatch(); widget.clicked.connect(pick)
            return widget,lambda: list(widget.property("rgb"))
        choices = ENUMS.get(key)
        if key=="shading": choices=["flat","faceted","interp"]
        if key=="lighting": choices=["none","flat","gouraud","phong"]
        if key=="render_detail": choices=["adaptive","low","moderate","high"]
        if key=="label_font_name": choices=["Arial","Times","Courier"]
        if key=="light_direction": choices=["headlight","right","left"]
        if key=="material_profile": choices=["dull","shiny","metal","custom"]
        if key in ("colormap","palette") and isinstance(value,str): choices=PALETTES
        if key=="color_mode": choices={"surface":["uniform","scalar","vertex-rgb"],"node":["uniform","mapped","modular","threshold","custom"],"edge":["uniform","mapped","threshold","length","node-module","custom"],"roi":["index","uniform","custom"]}[section]
        if key=="boundary_mode": choices=["none","automatic","threshold","custom"]
        if key=="opacity_mode": choices=["uniform","mapped"]
        if key=="colorbar_location": choices=["eastoutside","westoutside","southoutside","northoutside"]
        if section=="edge" and key=="selection_mode": choices=["all","threshold","sparsity"]
        if choices:
            widget=SettingsChoice()
            names={"modular":"Modules"} if section=="node" and key=="color_mode" else {"all":"All Edges","sparsity":"Sparsity (Top Count)","legacy-sparsity":"Sparsity (Legacy Threshold)"} if section=="edge" and key=="selection_mode" else {"roi":"ROIs (Atlas / Statistical)"} if section=="volume" and key=="type" else {"value":"Node Value","module":"Module"} if section=="node" and key=="size_basis" else {}
            for choice in choices: widget.addItem(names.get(choice,choice if key in ("colormap","palette","label_font_name") else choice_label(choice)),choice)
            if str(value) not in choices: widget.addItem(str(value),value)
            widget.setCurrentText(str(value)); widget.currentTextChanged.connect(self.changed)
            if key=="render_detail":
                widget.setToolTip("Adaptive uses fewer sphere/tube segments at 300 nodes or 1,500 selected edges. Surface vertices are preserved.")
            if section=="edge" and key=="selection_mode": widget.setToolTip("Sparsity ranks nonzero candidates and retains the requested top count.")
            return widget,widget.currentData
        if isinstance(value,(float,int)):
            widget=CompactNumber(); widget.setDecimals(5); widget.setRange(-1e9,1e9)
            integer=isinstance(value,int) and key not in ("statistical_threshold","size_scale")
            if integer: widget.setDecimals(0)
            if key=="size_scale": widget.setSingleStep(.1)
            if key=="statistical_threshold": widget.setSingleStep(.1); widget.setMinimumWidth(85)
            if key in ("opacity","sparsity"): widget.setRange(0,1); widget.setSingleStep(.05)
            elif key=="preset": widget.setRange(1,5)
            elif key=="view_direction" or key=="map_algorithm": widget.setRange(1,8)
            elif key in ("cluster_size","smoothing_kernel","size","size_scale","arrow_length_scale","arrow_width_scale"): widget.setRange(0,1e6)
            if key in ("arrow_length_scale","arrow_width_scale"): widget.setRange(.25,3); widget.setSingleStep(.05)
            widget.setRange(min(widget.minimum(),value),max(widget.maximum(),value))
            widget.setValue(value); edited=[False]
            widget.valueChanged.connect(lambda _:edited.__setitem__(0,True)); widget.valueChanged.connect(self.changed)
            return widget,lambda: value if not edited[0] else int(widget.value()) if integer else widget.value()
        widget=W.QLineEdit(json.dumps(value) if not isinstance(value,str) else value)
        widget.textChanged.connect(self.changed)
        return widget,(lambda: json.loads(widget.text())) if not isinstance(value,str) else widget.text

    def value(self):
        result=deepcopy(self.settings)
        for (section,key),reader in self.readers.items(): result[section][key]=reader()
        return normalize({"visualization_settings":result})

    def set_splittable(self, splittable):
        widget=self.controls[("layout","preset")]
        widget.setItemText(1,"Overview (8 Views)" if splittable else "Overview (6 Views)")
        for i in (2,3,4): widget.model().item(i).setEnabled(splittable)
        if not splittable and widget.currentData() in (3,4,5): widget.setCurrentIndex(1)


class BrainNetWindow(W.QMainWindow):
    def __init__(self):
        super().__init__()
        self.paths={}; self.settings=deepcopy(DEFAULTS); self.data_root=LIBRARY
        self.surface_opacity_explicit=False
        self.plotter=None; self.renderer=None; self.inspect_on=False; self.busy=False
        from .animation_ui import LiveDemo
        self.live_demo=LiveDemo(self)
        self.scene_document=None
        self.pending_session=None; self.last_export_format="png"
        self.surface_policy_cache=None
        self.resize_timer=QtCore.QTimer(self); self.resize_timer.setSingleShot(True)
        self.resize_timer.setInterval(100); self.resize_timer.timeout.connect(self.fit_canvas)
        self.popout_dialog=None; self.scene_path=None
        from .desktop_shell import build_shell
        build_shell(self,LIBRARY)


    def role_action(self, role):
        from .desktop_shell import FILTERS
        if role=="scene": self.open_scene(); return
        if role not in self.paths: self.choose(role,FILTERS[role]); return
        menu=W.QMenu(self); menu.addAction("Replace File…",lambda:self.choose(role,FILTERS[role])); menu.addAction("Remove File",lambda:self.remove(role))
        control=self.role_buttons[role]; menu.exec(control.mapToGlobal(control.rect().bottomLeft()))

    def add_files(self):
        filenames,_=W.QFileDialog.getOpenFileNames(self,"Add Files",str(LIBRARY/"Data"),"BrainNet data (*.nv *.node *.edge *.txt *.nii *.nii.gz *.hdr *.img *.gii *.pial *.white *.inflated *.sphere *.surf *.orig *.mesh *.byu *.g *.obj *.mz3)")
        if filenames: self.guarded(lambda:self.accept_files(filenames))
        else: self.raise_(); self.activateWindow()

    def accept_files(self, filenames):
        additions={}
        for filename in filenames:
            path=Path(filename).resolve(); suffix=path.suffix.lower()
            if suffix==".gii":
                import nibabel as nib
                role="surface" if any(array.intent==1008 for array in nib.load(path).darrays) else "surface_map"
            elif suffix in (".node",".edge"): role=suffix[1:]
            elif suffix==".txt": role="surface_map"
            elif suffix in (".nii",".hdr",".img") or path.name.lower().endswith(".nii.gz"): role="volume"
            elif suffix in (".nv",".pial",".white",".inflated",".sphere",".surf",".orig",".mesh",".byu",".g",".obj",".mz3"): role="surface"
            else: raise ValueError(f"Unsupported input: {path.name}")
            if role in additions and not (role=="volume" and path.stem==additions[role].stem and {suffix,additions[role].suffix.lower()}=={".hdr",".img"}):
                raise ValueError("Select one file per input type. Use Merge for multiple surfaces.")
            additions[role]=path
        if "volume" in additions and "surface_map" in additions: raise ValueError("Select either a Volume or a Surface Map for this scene.")
        self.change_inputs(additions)

    def change_inputs(self, additions, removed=None):
        """Retain pending controls and export preferences when replacing data."""
        settings=self.settings_value(); paths=dict(self.paths)
        for role,path in additions.items():
            path=Path(path).resolve()
            if not path.is_file(): raise ValueError(f"Input file does not exist: {path}")
            paths[role]=path
        if removed is not None: paths.pop(removed,None)
        if "volume" in additions:
            paths.pop("surface_map",None); settings["volume"]["display"]=True
            settings["surface"]["color_mode"]="scalar"
        elif "surface_map" in additions:
            paths.pop("volume",None); settings["volume"]["display"]=False
            settings["surface"]["color_mode"]="scalar"
        elif removed=="volume": settings["volume"]["display"]=False
        # Check hemisphere policy before committing a new surface, so a broken
        # surface cannot leave the current scene partially replaced.
        policy=None
        if "surface" in additions:
            path=paths["surface"]
            policy=((path,path.stat().st_size,path.stat().st_mtime_ns),hemispheres(read_surface(path)) is not None)
        explicit=self.surface_opacity_explicit if paths else False
        if paths and not explicit:
            roles=set(paths)
            opaque=roles=={"surface"} or roles in ({"surface","surface_map"},{"surface","volume"})
            settings["surface"]["opacity"]=1. if opaque else .3
        self.paths=paths; self.settings=settings; self.surface_opacity_explicit=explicit
        if policy is not None: self.surface_policy_cache=policy
        self.scene_document=None; self.install_settings(preserve_export=True); self.refresh_sources(); self.dirty()

    def dragEnterEvent(self,event):
        if event.mimeData().hasUrls() and all(url.isLocalFile() for url in event.mimeData().urls()): event.acceptProposedAction()

    def dropEvent(self,event):
        self.guarded(lambda:self.accept_files([url.toLocalFile() for url in event.mimeData().urls()]))
        event.acceptProposedAction()

    def validate_inputs(self):
        def validate():
            from .io import read_nodes,read_edges,read_volume,read_surface_map
            details={}; mesh=read_surface(self.paths["surface"]) if "surface" in self.paths else None
            nodes=read_nodes(self.paths["node"]) if "node" in self.paths else None
            if mesh: details["surface"]=f"{len(mesh.points):,} vertices · {len(mesh.faces):,} faces"
            if nodes: details["node"]=f"{len(nodes.positions):,} nodes"
            if "edge" in self.paths:
                if nodes is None: raise ValueError("Add Nodes before validating Edges.")
                matrix=read_edges(self.paths["edge"],len(nodes.positions)); details["edge"]=f"{matrix.shape[0]} × {matrix.shape[1]} matrix"
            if "surface_map" in self.paths:
                if mesh is None: raise ValueError("Add Surface before validating a Surface Map.")
                values=read_surface_map(self.paths["surface_map"],len(mesh.points)); details["surface_map"]=f"{len(values):,} vertices"
            if "volume" in self.paths:
                volume=read_volume(self.paths["volume"]); details["volume"]=" × ".join(str(n) for n in volume.data.shape)+" voxels"
            self.show_summary(details); self.statusBar().showMessage("Inputs validated. Configure display settings, then Render Scene.")
        self.guarded(validate)

    def show_summary(self, details=None):
        from html import escape
        rows=["<b>Scene</b>"]
        for role,path in self.paths.items():
            label={"surface":"Surface Mesh","node":"Nodes","edge":"Edges","surface_map":"Surface Map","volume":"Volume / Atlas"}.get(role,role.title())
            extra=(details or {}).get(role,"")
            rows.append(f"<p><b>{label}:</b> {escape(str(path))}"+(f"<br>{escape(extra)}" if extra else "")+"</p>")
        self.summary.setHtml("".join(rows))

    def toolbar_view(self):
        if not self.renderer: return
        self.stop_demo(); direction=self.view_choice.currentData()
        if direction is None: self.reset_view(); return
        import numpy as np
        angles={1:(-90,0),5:(90,0),3:(180,0),7:(0,0),2:(0,90),6:(0,-90)}
        az,el=np.deg2rad(angles[direction]); vector=np.array([np.cos(el)*np.sin(az),-np.cos(el)*np.cos(az),np.sin(el)])
        for renderer in self.plotter.renderers:
            camera=renderer.camera; focus=np.asarray(camera.focal_point); distance=np.linalg.norm(np.asarray(camera.position)-focus)
            camera.position=focus+vector*distance; camera.up=(0,1,0) if abs(vector[2])>.99 else (0,0,1); renderer.ResetCameraClippingRange()
        self.plotter.render()

    def clear_figure(self):
        if not self.renderer: return
        self.stop_demo(); self.pending_session=self.capture_session(self.settings)
        self.renderer.dispose(); self.plotter.clear(); self.renderer.background.RemoveAllViewProps(); self.renderer.pick_actors=[]
        self.inspect_on=False; self.inspect_button.setChecked(False); self.inspect_label.hide()
        self.export_button.setEnabled(False); self.demo_start_action.setEnabled(False); self.boundary_export_button.setEnabled(False)
        self.plotter.render(); self.statusBar().showMessage("Figure cleared. Inputs and settings retained; Render Scene restores the scene.")

    def pop_out(self):
        if self.popout_dialog: self.popout_dialog.raise_(); self.popout_dialog.activateWindow(); return
        dialog=W.QDialog(self); dialog.setWindowTitle("BrainNet Viewer — Render Canvas"); dialog.setModal(False)
        layout=W.QVBoxLayout(dialog); layout.setContentsMargins(6,6,6,6)
        self.center_layout.removeWidget(self.canvas_host); layout.addWidget(self.canvas_host)
        self.canvas_placeholder=W.QLabel("Canvas is open in a separate window. Close it to return here."); self.canvas_placeholder.setWordWrap(True); self.canvas_placeholder.setAlignment(QtCore.Qt.AlignCenter); self.center_layout.addWidget(self.canvas_placeholder,1)
        def restore():
            layout.removeWidget(self.canvas_host); self.center_layout.removeWidget(self.canvas_placeholder); self.canvas_placeholder.deleteLater()
            self.center_layout.addWidget(self.canvas_host,1); self.canvas_host.show(); self.popout_dialog=None; dialog.deleteLater(); self.resize_timer.start()
        dialog.finished.connect(restore); self.popout_dialog=dialog
        area=self.screen().availableGeometry(); dialog.resize(min(1100,area.width()-80),min(850,area.height()-80)); dialog.move(area.center()-dialog.rect().center()); dialog.show(); self.resize_timer.start()

    def save_boundary(self):
        if not self.renderer or self.renderer.prepared.boundary is None: return
        filename,_=W.QFileDialog.getSaveFileName(self,"Save Surface Boundary","","Text (*.txt)")
        if filename:
            def save():
                import numpy as np
                with Path(filename).open("x",encoding="utf-8") as stream: np.savetxt(stream,self.renderer.prepared.boundary.astype(int),fmt="%d")
            self.guarded(save)
        else: self.raise_(); self.activateWindow()

    def request_defaults(self):
        if W.QMessageBox.question(self,"Restore Defaults","Restore all display settings? Input files and the current canvas will be retained.",W.QMessageBox.Yes|W.QMessageBox.No,W.QMessageBox.No)==W.QMessageBox.Yes: self.defaults()

    def update_resources(self):
        import os,platform
        name=platform.processor() or platform.machine()
        mac_memory=None
        if sys.platform=="darwin":
            brand,mac_memory=mac_hardware()
            if brand: name=brand
        if os.name=="nt":
            try:
                import winreg
                with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE,r"HARDWARE\DESCRIPTION\System\CentralProcessor\0") as key: name=winreg.QueryValueEx(key,"ProcessorNameString")[0].strip()
            except OSError: pass
        name=re.sub(r"\s+(\d+-Core Processor|Processor|CPU|@.*)$","",name).strip()
        memory="Memory: —"
        if sys.platform=="darwin" and mac_memory is not None:
            memory=f"Memory: {mac_memory/2**30:g} GiB total"
        if os.name=="nt":
            import ctypes
            class Memory(ctypes.Structure):
                _fields_=[("length",ctypes.c_ulong),("load",ctypes.c_ulong)]+[(key,ctypes.c_ulonglong) for key in ("total","available","page_total","page_available","virtual_total","virtual_available","extended")]
            state=Memory(); state.length=ctypes.sizeof(state)
            if ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(state)): memory=f"Memory: {state.available/2**30:.1f} / {state.total/2**30:.0f} GB available"
        gpu="GPU: available after rendering"
        if self.plotter:
            report=self.plotter.render_window.ReportCapabilities()
            match=re.search(r"OpenGL renderer string:\s*([^\n]+)",report)
            if match: gpu="GPU: "+match.group(1).strip()
        text=f"CPU: {name} · {os.cpu_count()} logical cores   |   {memory}   |   {gpu}"
        self.resource_label.setText(text); self.resource_label.setToolTip(text)

    def install_settings(self, preserve_export=False):
        active=self.panel.box.currentIndex() if hasattr(self,"panel") else -1
        if hasattr(self,"panel"):
            self.right_layout.removeWidget(self.panel); self.panel.hide(); self.panel.deleteLater()
        self.panel=SettingsPanel(self.settings); self.panel.changed.connect(self.dirty)
        self.panel.binding_requested.connect(self.bind_data)
        opacity=self.panel.controls[("surface","opacity")]
        for field in opacity.findChildren(W.QDoubleSpinBox):
            field.valueChanged.connect(self.mark_surface_opacity_explicit)
            field.editingFinished.connect(self.mark_surface_opacity_explicit)
        self.right_layout.insertWidget(0,self.panel,1)
        self.panel.box.setCurrentIndex(active)
        if not preserve_export:
            self.export_units.blockSignals(True); self.export_units.setCurrentText("Pixels"); self.export_units.blockSignals(False)
            self.export_size_mode="Pixels"
            for field,key in ((self.export_width,"width"),(self.export_height,"height"),(self.export_dpi,"dpi")):
                if key != "dpi": field.setDecimals(0)
                field.setValue(self.settings["image"][key])
        self.update_surface_policy()
        self.view_choice.setEnabled(self.panel.controls[("layout","preset")].currentData()==1)

    def mark_surface_opacity_explicit(self, *args):
        self.surface_opacity_explicit=True

    def change_export_units(self, units):
        dpi = self.export_dpi.value()
        ratio = unit_scale(self.export_size_mode,dpi)/unit_scale(units,dpi)
        dimensions = [field.value()*ratio for field in (self.export_width,self.export_height)]
        for field,value in zip((self.export_width,self.export_height),dimensions):
            field.setDecimals(0 if units=="Pixels" else 5); field.setValue(value)
        self.export_size_mode=units

    def settings_value(self):
        settings=self.panel.value()
        width,height=figure_size(self.export_width.value(),self.export_height.value(),self.export_dpi.value(),self.export_size_mode)
        settings["image"].update(width=width,height=height,dpi=self.export_dpi.value())
        return settings

    def update_surface_policy(self):
        path=self.paths.get("surface")
        if path is None: self.panel.set_splittable(True); return
        stamp=(path,path.stat().st_size,path.stat().st_mtime_ns)
        if not self.surface_policy_cache or self.surface_policy_cache[0]!=stamp:
            self.surface_policy_cache=(stamp,hemispheres(read_surface(path)) is not None)
        self.panel.set_splittable(self.surface_policy_cache[1])

    def guarded(self, action):
        try: action()
        except Exception as error:
            self.statusBar().showMessage(str(error)); W.QMessageBox.warning(self,"BrainNet Viewer",str(error))
        finally: self.raise_(); self.activateWindow()

    def dirty(self, *_):
        if hasattr(self,"view_choice"): self.view_choice.setEnabled(self.panel.controls[("layout","preset")].currentData()==1)
        self.stop_demo(); self.demo_start_action.setEnabled(False)
        self.pending_session=None
        self.export_button.setEnabled(False)
        self.statusBar().showMessage("Configuration/data changed. Apply or Render Scene before export.")

    def choose(self, role, file_filter):
        initial=self.input_directory(role)
        filename,_=W.QFileDialog.getOpenFileName(self,"Add "+role.replace("_"," "),str(initial),file_filter)
        if filename:
            self.guarded(lambda:self.change_inputs({role:Path(filename)}))
        self.raise_(); self.activateWindow()

    def input_directory(self, role):
        """Use the loaded file's folder, paired network folder, or packaged library."""
        if role in self.paths and self.paths[role].parent.is_dir(): return self.paths[role].parent
        paired={"node":"edge","edge":"node"}.get(role)
        if paired in self.paths and self.paths[paired].parent.is_dir(): return self.paths[paired].parent
        if role=="surface": return LIBRARY/"Data/SurfTemplate"
        if role in ("surface_map","volume") and (LIBRARY/"atlases/AAL90").is_dir():
            return LIBRARY/"atlases/AAL90"
        networks=LIBRARY/"Data/ExampleFiles/AtlasNetworks"
        return networks if role in ("node","edge") and networks.is_dir() else LIBRARY/"Data"

    def remove(self, role):
        self.guarded(lambda:self.change_inputs({},removed=role))

    def refresh_sources(self):
        for role,label in self.file_labels.items():
            path=self.paths.get(role,self.scene_path if role=="scene" else None)
            label.setText(path.name if path else "Requires Nodes" if role=="edge" else "Not selected")
            label.setToolTip(str(path) if path else "No file selected.")
            if role!="scene": self.role_buttons[role].setText("…" if path else "Add")
        self.show_summary()

    def apply(self):
        self.render_scene()

    def revert(self): self.install_settings()

    def defaults(self):
        export=(self.export_units.currentText(),self.export_width.value(),self.export_height.value(),self.export_dpi.value())
        self.settings=deepcopy(DEFAULTS); self.install_settings(); self.dirty()
        self.export_dpi.setValue(export[3]); self.export_units.setCurrentText(export[0])
        self.export_width.setValue(export[1]); self.export_height.setValue(export[2])
        self.statusBar().showMessage("Defaults restored. Current canvas retained; Render Scene to update it.")

    def render_scene(self):
        if self.busy: return
        self.stop_demo()
        self.busy=True; self.render_button.setEnabled(False); self.export_button.setEnabled(False)
        def render():
            settings=self.settings_value(); prepared=prepare(self.paths,settings)
            _,views=layout(settings["layout"],prepared.split)
            if self.plotter is None or len(self.plotter.renderers)!=len(views):
                if self.plotter:
                    self.renderer.dispose()
                    self.canvas_stack.removeWidget(self.plotter.interactor); self.plotter.close(); self.plotter.deleteLater()
                self.plotter=QtInteractor(self.canvas_host,shape=(1,len(views)),border=False)
                self.plotter.interactor.installEventFilter(self)
                self.canvas_stack.addWidget(self.plotter.interactor)
                self.startup_content.hide()
                self.renderer=SceneRenderer(self.plotter)
                self.plotter.iren.interactor.AddObserver("LeftButtonPressEvent",self.pick,1.)
                self.canvas_stack.activate()
                W.QApplication.processEvents(QtCore.QEventLoop.ExcludeUserInputEvents)
            self.renderer.render(prepared); self.settings=settings; self.interaction(self.mode.currentText())
            self.inspect_label.setText("Inspect: click a surface vertex · XYZ uses the default MNI frame." if self.inspect_on else "")
            self.inspect_label.setVisible(self.inspect_on)
            if self.inspect_on: self.inspect_label.raise_()
            camera_status = None
            if self.pending_session:
                state=self.pending_session
                if state.get("producer")=="matlab":
                    from .matlab_session import pending_session
                    identity=signature(prepared.input_hashes,prepared.settings)
                    if identity!=state["python_identity"]: camera_status="MATLAB data-or-settings-mismatch"
                    elif state["state"]["camera"] is not None and (state["state"]["camera"]["layout"]!=prepared.settings["layout"]["preset"] or
                            len(state["state"]["camera"]["views"])!=len(self.renderer.viewports)):
                        camera_status="MATLAB layout-or-view-count-mismatch; fitted camera retained"
                    else:
                        camera_status="MATLAB "+self.renderer.restore_session(pending_session(state["state"],self.renderer,identity))+" (axes limits retained as metadata)"
                else: camera_status = self.renderer.restore_session(state)
                self.pending_session = None
            self.export_button.setEnabled(True)
            self.popout_button.setEnabled(True)
            self.boundary_export_button.setEnabled(prepared.boundary is not None)
            self.demo_start_action.setEnabled(True)
            summary=[]
            if prepared.surface: summary.append(f"Surface: {len(prepared.surface.points):,} vertices · {len(prepared.surface.faces):,} faces · {'splittable' if prepared.split is not None else 'continuous/full surface'}")
            if prepared.nodes: summary.append(f"Nodes: {len(prepared.nodes.positions):,}")
            summary.append(f"Displayed edges: {len(prepared.pairs):,}")
            policy=self.renderer.detail_policy
            summary.append(f"Render detail: {policy.level.title()} · Node segments: {policy.node_detail} · Edge sides: {policy.edge_sides}")
            if prepared.rois: summary.append(f"ROI meshes: {len(prepared.rois)}")
            details={"surface":summary[0] if prepared.surface else "", "node":f"{len(prepared.nodes.positions):,} nodes" if prepared.nodes else "", "edge":f"{len(prepared.pairs):,} displayed edges"}
            self.show_summary(details); self.update_resources()
            message = "Rendered. Rotate/Pan/Zoom acts on the current subplot."
            if camera_status: message += f" Saved camera: {camera_status}."
            if prepared.diagnostics: message += ' ' + ' '.join(prepared.diagnostics)
            self.statusBar().showMessage(message)
        try: self.guarded(render)
        finally: self.busy=False; self.render_button.setEnabled(True)

    def interaction(self, mode):
        if hasattr(self,"mode_buttons"): self.mode_buttons[mode].setChecked(True)
        if self.plotter: self.plotter.enable_custom_trackball_style(left={"Rotate":"rotate","Pan":"pan","Zoom":"dolly"}[mode])

    def eventFilter(self, watched, event):
        if self.plotter and watched is self.plotter.interactor and event.type()==QtCore.QEvent.MouseButtonPress:
            self.stop_demo()
        if self.plotter and watched is self.plotter.interactor and event.type()==QtCore.QEvent.Resize:
            self.resize_timer.start()
        return super().eventFilter(watched,event)

    def fit_canvas(self):
        if self.renderer and not self.renderer.exporting and not self.busy:
            self.renderer.resize_fit(*self.plotter.window_size); self.plotter.render()

    def reset_view(self):
        self.stop_demo()
        if self.renderer: self.renderer.reset()

    def start_demo(self):
        def start():
            if self.busy or not self.export_button.isEnabled(): raise ValueError("Render the current Scene before starting Live Demo.")
            self.live_demo.start(self.renderer); self.demo_stop_action.setEnabled(True)
            self.demo_start_action.setEnabled(False); self.statusBar().showMessage("Live Demo running. Stop Demo or click the canvas to stop.")
        self.guarded(start)

    def stop_demo(self):
        was_running=self.live_demo.running; self.live_demo.stop()
        if hasattr(self,"demo_stop_action"):
            self.demo_stop_action.setEnabled(False)
            self.demo_start_action.setEnabled(self.renderer is not None and self.export_button.isEnabled())
        if was_running: self.statusBar().showMessage("Live Demo stopped. Current camera angles retained.")

    def toggle_inspect(self):
        self.inspect_on=not self.inspect_on
        if hasattr(self,"inspect_button"): self.inspect_button.setChecked(self.inspect_on)
        self.inspect_label.setText("Inspect: click a surface vertex · XYZ uses the default MNI frame." if self.inspect_on else "")
        self.inspect_label.setVisible(self.inspect_on)
        if self.inspect_on: self.inspect_label.raise_()

    def pick(self, native, _):
        if not self.inspect_on or not self.renderer: return
        record=self.renderer.inspect_vertex(*native.GetEventPosition())
        if record:
            try: regions=lookup(LIBRARY,record["xyz"])
            except ValueError as error: self.inspect_label.setText(str(error)); return
            self.inspect_label.setText(f"Vertex {record['vertex']} · XYZ: "+", ".join(f"{x:.3f}" for x in record["xyz"])+f" · {regions['brodmann']} · AAL: {regions['aal']}")
            self.inspect_label.adjustSize(); self.inspect_label.raise_()

    def open_scene(self):
        filename,_=W.QFileDialog.getOpenFileName(self,"Open Scene",str(self.data_root),"Scene JSON (*.json)")
        if not filename: self.raise_(); self.activateWindow(); return
        def load():
            scene=read_scene(filename,self.data_root,resolve=False)
            try: scene.resolve()
            except ValueError:
                folder=W.QFileDialog.getExistingDirectory(self,"Select the data root used by this Scene",str(Path(filename).parent))
                if not folder: return
                scene.data_root=Path(folder); scene.resolve()
            self.data_root=scene.data_root; self.paths=scene.paths; self.settings=scene.settings
            self.surface_opacity_explicit=True
            self.scene_document=scene.document; self.scene_path=Path(filename); self.install_settings(); self.refresh_sources(); self.dirty()
            self.load_session(scene.document,matlab_verified=scene.matlab_signature_verified)
        self.guarded(load)

    def save_scene(self):
        if not self.paths: return
        filename,_=W.QFileDialog.getSaveFileName(self,"Save portable Scene with copied assets","","Scene JSON (*.json)")
        if not filename: self.raise_(); self.activateWindow(); return
        def save():
            settings=self.settings_value()
            session=self.capture_session(settings)
            scene=portable_scene(self.paths,settings,filename,self.scene_document,session=session)
            self.scene_document=scene.document; self.scene_path=Path(filename); self.refresh_sources()
            self.statusBar().showMessage(f"Portable Scene saved. Data root: {scene.data_root}")
        self.guarded(save)

    def capture_session(self, settings):
        camera=None; hashes=content_hashes(self.paths)
        identity=signature(hashes,settings)
        if self.renderer and self.export_button.isEnabled():
            if identity==signature(self.renderer.prepared.input_hashes,self.renderer.prepared.settings):
                camera=self.renderer.capture_camera()
        format_=self.last_export_format
        if self.transparent.isChecked() and format_ not in ("png","tif","pdf","svg"): format_="png"
        return validate_session({"version":"1.0","producer":"python-vtk","scene_signature":identity,"camera":camera,
            "export":{"units":self.export_size_mode,"width":self.export_width.value(),"height":self.export_height.value(),
                      "dpi":self.export_dpi.value(),"transparent":self.transparent.isChecked(),"format":format_}})

    def load_session(self, document, *, matlab_verified=False):
        self.pending_session=document.get("metadata",{}).get(KEY)
        if self.pending_session:
            state=validate_session(self.pending_session); export=state["export"]
            self.export_dpi.setValue(export["dpi"]); self.export_units.setCurrentText(export["units"])
            self.export_width.setValue(export["width"]); self.export_height.setValue(export["height"])
            self.transparent.setChecked(export["transparent"]); self.last_export_format=export["format"]
            self.export_format.setCurrentIndex(self.export_format.findData(export["format"]))
        elif document.get("metadata",{}).get("session_state"):
            from .matlab_session import validate_matlab_session, export_preferences
            state=validate_matlab_session(document["metadata"]["session_state"])
            if not matlab_verified:
                self.statusBar().showMessage("MATLAB session binding did not match the source JSON or lacks an external-data fingerprint. Metadata retained; camera/preferences not restored.")
                return
            try: export,warnings=export_preferences(state)
            except ValueError as error:
                self.statusBar().showMessage(f"MATLAB export preferences exceed Python limits: {error}. Metadata retained.")
                return
            self.export_dpi.setValue(export["dpi"]); self.export_units.setCurrentText(export["units"])
            self.export_width.setValue(export["width"]); self.export_height.setValue(export["height"])
            self.transparent.setChecked(export["transparent"]); self.last_export_format=export["format"]
            self.export_format.setCurrentIndex(self.export_format.findData(export["format"]))
            self.pending_session={"producer":"matlab","state":state,"python_identity":signature(content_hashes(self.paths),self.settings_value())}
            self.statusBar().showMessage("MATLAB session verified; camera queued for render. Axis limits retained as metadata. "+" ".join(warnings))

    def export(self):
        if self.busy or self.renderer is None or not self.export_button.isEnabled(): return
        self.stop_demo()
        selected_filter={"png":"PNG (*.png)","tif":"TIFF (*.tif)","jpg":"JPEG (*.jpg)","bmp":"BMP (*.bmp)","pdf":"PDF (*.pdf)","svg":"SVG (*.svg)"}[self.export_format.currentData()]
        filename,selected=W.QFileDialog.getSaveFileName(self,"Export Figure","", "PNG (*.png);;TIFF (*.tif);;JPEG (*.jpg);;BMP (*.bmp);;PDF (*.pdf);;SVG (*.svg)",selected_filter,
            options=W.QFileDialog.Option.DontConfirmOverwrite)
        if filename:
            def save():
                nonlocal filename
                if not Path(filename).suffix:
                    filename += "."+{"TIFF":"tif","JPEG":"jpg","BMP":"bmp","PDF":"pdf","SVG":"svg"}.get(selected.split(" ")[0],"png")
                from .provenance import sidecar_path
                overwrite=Path(filename).exists() or sidecar_path(filename).exists()
                if overwrite and W.QMessageBox.question(self,"Replace Figure?","Replace the existing figure and provenance record? Source files cannot be replaced.",
                        W.QMessageBox.StandardButton.Yes|W.QMessageBox.StandardButton.No,W.QMessageBox.StandardButton.No)!=W.QMessageBox.StandardButton.Yes:
                    return
                size=figure_size(self.export_width.value(),self.export_height.value(),self.export_dpi.value(),self.export_size_mode)
                self.busy=True
                try:
                    result=self.renderer.export(filename,*size,self.export_dpi.value(),self.transparent.isChecked(),overwrite=overwrite,
                                                paths=self.paths,settings=self.settings_value(),provenance_context={'entry_point':'desktop'})
                finally: self.busy=False
                self.last_export_format={"jpeg":"jpg","tiff":"tif"}.get(Path(filename).suffix.lower()[1:],Path(filename).suffix.lower()[1:])
                self.export_format.setCurrentIndex(self.export_format.findData(self.last_export_format))
                self.statusBar().showMessage(f"Figure saved: {result['content']} ({size[0]} x {size[1]} pixels at {self.export_dpi.value()} DPI).")
                W.QMessageBox.information(self,"Figure Saved",f"Saved: {filename}\n{size[0]} × {size[1]} pixels · {self.export_dpi.value():g} DPI\nProvenance: {result['provenance_file']}")
            self.guarded(save)
        else: self.raise_(); self.activateWindow()

    def set_theme(self, name):
        self.setStyleSheet(stylesheet(name=="Dark"))
        if hasattr(self,"theme_choice"):
            self.theme_choice.blockSignals(True); self.theme_choice.setCurrentText(name); self.theme_choice.blockSignals(False)

    def open_tool(self, mode):
        from .tools import SurfaceTool, ColormapTool
        from .tool_windows import ReviewedTool
        from .animation_ui import MovieExportWindow
        def show():
            dialog=(MovieExportWindow(self) if mode=="movie" else ReviewedTool(self,mode) if mode in ("subdivide","atlas") else
                    ColormapTool(self) if mode=="colormap" else SurfaceTool(self,mode))
            from .desktop_style import style_dialog
            style_dialog(dialog,760 if mode=="colormap" else 650,650 if mode=="colormap" else 600 if mode in ("subdivide","atlas") else 500)
            try: dialog.exec()
            finally: self.raise_(); self.activateWindow(); dialog.deleteLater()
        self.guarded(show)

    def open_preset(self):
        filename,_=W.QFileDialog.getOpenFileName(self,"Open Settings Preset","","Preset JSON (*.json)")
        def load():
            document=json.loads(Path(filename).read_text(encoding="utf-8-sig"))
            if document.get("kind")!="brainnet-visualization-preset" or document.get("schema_version")!="1.0": raise ValueError("Not a supported settings preset.")
            settings=normalize({"visualization_settings":document["settings"]})
            self.settings=settings; self.surface_opacity_explicit=True; self.install_settings(); self.dirty()
        if filename: self.guarded(load)
        else: self.raise_(); self.activateWindow()

    def save_preset(self):
        filename,_=W.QFileDialog.getSaveFileName(self,"Save Settings Preset","","Preset JSON (*.json)")
        def save():
            document={"kind":"brainnet-visualization-preset","schema_version":"1.0","name":Path(filename).stem,"settings":self.settings_value()}
            with Path(filename).open("x",encoding="utf-8") as stream: json.dump(document,stream,ensure_ascii=False,allow_nan=False,indent=2)
        if filename: self.guarded(save)
        else: self.raise_(); self.activateWindow()

    def import_ec(self):
        if self.busy: return
        if not self.paths:
            W.QMessageBox.information(self,"Import Legacy EC","Add scene files first. EC imports settings only; File/FLAG do not load files.")
            return
        filename,_=W.QFileDialog.getOpenFileName(self,"Import trusted legacy EC settings","","MATLAB EC (*.mat)")
        if not filename: self.raise_(); self.activateWindow(); return
        def load():
            from .legacy_config import read_ec
            settings,report=read_ec(filename,2 if "volume" in self.paths else 1 if "surface_map" in self.paths else 0)
            review=report["fields_requiring_review"]
            text=f"Mapped {len(report['mapped_fields'])} fields. {len(review)} fields require review.\n\n"+"\n".join(report["warnings"])
            message=W.QMessageBox(self); message.setWindowTitle("Review Legacy EC Import"); message.setText(text)
            message.setDetailedText("Fields requiring review:\n"+"\n".join(review)+"\n\nMapped fields:\n"+"\n".join(report["mapped_fields"]))
            message.setStandardButtons(W.QMessageBox.StandardButton.Apply|W.QMessageBox.StandardButton.Cancel); message.setDefaultButton(W.QMessageBox.StandardButton.Cancel)
            if message.exec()!=W.QMessageBox.StandardButton.Apply: return
            if sha256(Path(filename))!=report["source_sha256"]: raise ValueError("EC file changed during review. Import it again.")
            self.settings=settings; self.surface_opacity_explicit=True; self.install_settings(); self.dirty()
            if self.scene_document is None: self.scene_document={"metadata":{}}
            self.scene_document.setdefault("metadata",{})["legacy_config_import"]=report
            self.statusBar().showMessage("Legacy EC settings applied; current files/canvas retained. Review unmapped fields and bindings, then render.")
        from .io import sha256
        self.guarded(load)

    def bind_data(self, kind):
        import numpy as np
        from .binding import geometry_signature, node_signature
        from .io import read_surface_map, read_edges, read_nodes
        role="node" if kind=="edge" else "surface"
        if role not in self.paths: self.statusBar().showMessage(f"Add {role} data first."); return
        filename,_=W.QFileDialog.getOpenFileName(self,"Load Original-Order Data","","Text (*.txt *.csv *.edge)")
        def bind():
            answer=W.QMessageBox.question(self,"Confirm Original Order","Does this file follow the original loaded vertex/node order? No reordering or registration will be applied.")
            if answer!=W.QMessageBox.Yes: return
            settings=self.settings_value()
            if kind=="edge":
                nodes=read_nodes(self.paths["node"]); matrix=read_edges(filename,len(nodes.positions))
                settings["edge"].update(color_mode="custom",custom_color={"matrix":matrix.tolist(),"indices":np.unique(matrix).tolist(),"node_sha256":node_signature(nodes.positions),"source":str(filename)})
            else:
                surface=read_surface(self.paths["surface"])
                count=len(surface.points)*(2 if kind=="rgb" and settings["surface"]["double_brain"] else 1)
                values=read_surface_map(filename,count); signature=geometry_signature(surface.points,surface.faces)
                if kind=="rgb":
                    if values.ndim!=2: raise ValueError("Vertex RGB needs three columns in [0,1].")
                    settings["surface"].update(color_mode="vertex-rgb",vertex_colors=values.tolist(),vertex_colors_mesh_sha256=signature,vertex_colors_source=str(filename))
                else:
                    if values.ndim!=1 or not np.isin(values,[0,1]).all(): raise ValueError("Boundary mask needs one binary column.")
                    settings["surface"].update(boundary_mode="custom",boundary_mask=values.tolist(),boundary_mesh_sha256=signature,boundary_mask_source=str(filename))
            self.settings=settings; self.install_settings(preserve_export=True); self.dirty()
        if filename: self.guarded(bind)
        else: self.raise_(); self.activateWindow()

    def help(self):
        dialog=HelpDialog(RESOURCE_ROOT, self)
        dialog.move(self.geometry().center()-dialog.rect().center()); dialog.exec()
        self.raise_(); self.activateWindow()
    def about(self): W.QMessageBox.information(self,"About",f"BrainNet Viewer {__version__}\nMingrui Xia\nmxia@bnu.edu.cn · mingruixia@gmail.com\nGPL-3.0\nXia M, Wang J, He Y (2013). PLoS ONE 8: e68910.")
    def closeEvent(self,event):
        if self.popout_dialog: self.popout_dialog.close()
        self.stop_demo()
        self.resize_timer.stop()
        if self.renderer: self.renderer.dispose()
        self.renderer = None
        if self.plotter: self.plotter.close(); self.plotter = None
        event.accept()


def main():
    parser=argparse.ArgumentParser(); parser.add_argument("--scene",type=Path); parser.add_argument("--data-root",type=Path,default=LIBRARY)
    parser.add_argument("--smoke",action="store_true",help="Run a development smoke capture and exit.")
    args=parser.parse_args()
    app=W.QApplication.instance() or W.QApplication(sys.argv[:1])
    window=BrainNetWindow(); window.data_root=args.data_root; window.show()
    if args.scene:
        scene=read_scene(args.scene,args.data_root); window.paths=scene.paths; window.settings=scene.settings
        window.surface_opacity_explicit=True
        window.scene_document=scene.document
        window.install_settings(); window.refresh_sources()
        window.load_session(scene.document)
        QtCore.QTimer.singleShot(300,window.render_scene)
    if args.smoke:
        def capture():
            destination=ROOT/"tmp/python-desktop-workflow"; destination.mkdir(parents=True,exist_ok=True)
            window.grab().save(str(destination/"desktop-window.png"))
            status={"rendered":window.renderer is not None,"export_enabled":window.export_button.isEnabled(),"version":__version__}
            (destination/"smoke.json").write_text(json.dumps(status,indent=2),encoding="utf-8")
            window.close(); app.quit()
        QtCore.QTimer.singleShot(3500,capture)
    return app.exec()


if __name__=="__main__": raise SystemExit(main())
