"""MATLAB-style colormap table; stage palettes without redrawing the canvas."""
from copy import deepcopy
import json
from pathlib import Path
import numpy as np
from PySide6 import QtCore, QtGui, QtWidgets as W
from .palettes import palette, PALETTES


class PalettePreview(W.QWidget):
    def __init__(self):
        super().__init__(); self.rgb=np.zeros((2,3)); self.setMinimumHeight(48)

    def set_colors(self,rgb): self.rgb=palette(rgb,256); self.update()

    def paintEvent(self,event):
        painter=QtGui.QPainter(self)
        gradient=QtGui.QLinearGradient(0,0,self.width(),0)
        for index,color in enumerate(self.rgb): gradient.setColorAt(index/(len(self.rgb)-1),QtGui.QColor.fromRgbF(*color))
        painter.fillRect(self.rect().adjusted(0,4,0,-4),gradient)


class ColormapTool(W.QDialog):
    def __init__(self,parent):
        super().__init__(parent); self.setWindowTitle("Colormap Editor")
        settings=parent.panel.value()
        self.maps={label:deepcopy(settings[section]["colormap"]) for label,section in
                   (("Surface","surface"),("Nodes","node"),("Edges","edge"),("Volume","volume"))}
        self.active="Surface"; self.loading=False; self.table_dirty=False
        outer=W.QVBoxLayout(self)
        row=W.QHBoxLayout(); row.addWidget(W.QLabel("Target")); self.target=W.QComboBox(); self.target.addItems(self.maps); row.addWidget(self.target,1); outer.addLayout(row)
        row=W.QHBoxLayout(); self.choice=W.QComboBox(); self.choice.addItems(PALETTES); row.addWidget(self.choice,1)
        self.count=W.QSpinBox(); self.count.setRange(2,4096); self.count.setValue(256); self.count.setFixedWidth(72)
        self.count.setToolTip("Number of RGB rows for Generate / Resample"); row.addWidget(self.count)
        for title,handler in (("Generate",self.generate),("Resample",self.resample),("Reverse",self.reverse)):
            button=W.QPushButton(title); button.clicked.connect(lambda checked=False,action=handler:self.run(action)); row.addWidget(button)
        outer.addLayout(row); self.preview=PalettePreview(); outer.addWidget(self.preview)
        self.table=W.QTableWidget(0,3); self.table.setHorizontalHeaderLabels(["Red","Green","Blue"])
        self.table.horizontalHeader().setSectionResizeMode(W.QHeaderView.Stretch); self.table.setAlternatingRowColors(False)
        self.table.itemChanged.connect(self.edited); outer.addWidget(self.table,1)
        self.status=W.QLabel(); self.status.setWordWrap(True); outer.addWidget(self.status)
        row=W.QHBoxLayout()
        for title,handler in (("Import...",self.load),("Export...",self.save),("Cancel",self.reject),("Use in Settings",self.apply)):
            button=W.QPushButton(title); button.clicked.connect(handler)
            if title=="Use in Settings": button.setObjectName("Primary")
            row.addWidget(button)
        outer.addLayout(row); self.target.currentTextChanged.connect(self.switch_target); self.show_map()

    def set_rows(self,colors):
        colors=np.asarray(colors,float); palette(colors)
        self.loading=True; self.table.blockSignals(True)
        try:
            self.table.setRowCount(len(colors))
            for index,color in enumerate(colors):
                for channel,value in enumerate(color): self.table.setItem(index,channel,W.QTableWidgetItem(repr(float(value))))
            self.count.setValue(len(colors)); self.preview.set_colors(colors); self.table_dirty=False
            self.status.setText(f"{len(colors)} RGB rows · range 0 to 1. Use in Settings stages changes; then choose Apply and Render Scene.")
        finally: self.table.blockSignals(False); self.loading=False

    def show_map(self):
        value=self.maps[self.active]
        if isinstance(value,str): self.choice.setCurrentText(value)
        self.set_rows(palette(value,256) if isinstance(value,str) else value)

    def values(self):
        try: colors=np.array([[float(self.table.item(row,col).text()) for col in range(3)] for row in range(self.table.rowCount())])
        except (ValueError,AttributeError): raise ValueError("Enter a number in each Red, Green and Blue cell.") from None
        palette(colors); return colors

    def accept_table(self):
        colors=self.values()
        if self.table_dirty: self.maps[self.active]=colors.tolist()
        self.preview.set_colors(colors); return colors

    def edited(self,*_):
        if self.loading: return
        self.table_dirty=True
        try: self.accept_table(); self.status.setText(f"{self.table.rowCount()} RGB rows. Use in Settings, then Apply and Render Scene.")
        except ValueError as error: self.status.setText(str(error))

    def switch_target(self,target):
        try: self.accept_table()
        except ValueError as error:
            self.target.blockSignals(True); self.target.setCurrentText(self.active); self.target.blockSignals(False)
            self.status.setText(str(error)); return
        self.active=target; self.show_map()

    def set_map(self,colors):
        palette(colors); self.maps[self.active]=np.asarray(colors).tolist(); self.set_rows(colors)

    def generate(self): self.set_map(palette(self.choice.currentText(),self.count.value()))
    def resample(self): self.set_map(palette(self.accept_table(),self.count.value()))
    def reverse(self): self.set_map(self.accept_table()[::-1])

    def run(self,action):
        try: action()
        except (ValueError,OSError,TypeError,json.JSONDecodeError) as error: self.status.setText(str(error))
        finally: self.raise_(); self.activateWindow()

    def import_file(self,path):
        path=Path(path)
        if path.suffix.lower()==".json":
            value=json.loads(path.read_text(encoding="utf-8-sig"))
            if isinstance(value,dict): value=value.get("rgb",value.get("colors"))
            colors=np.asarray(value,dtype=float)
        else: colors=np.loadtxt(path,delimiter="," if path.suffix.lower()==".csv" else None,ndmin=2)
        self.set_map(colors)

    def export_file(self,path):
        colors=self.accept_table(); path=Path(path)
        if path.suffix.lower() not in (".txt",".csv",".json"): raise ValueError("Choose an RGB .txt, .csv or .json file.")
        with path.open("x",encoding="utf-8") as stream:
            if path.suffix.lower()==".json": json.dump(colors.tolist(),stream,indent=2,allow_nan=False)
            else: np.savetxt(stream,colors,fmt="%.17g",delimiter="," if path.suffix.lower()==".csv" else " ")
        self.status.setText(f"Saved {len(colors)} RGB rows: {path}")

    def load(self):
        path,_=W.QFileDialog.getOpenFileName(self,"Import Colormap","","RGB Tables (*.json *.txt *.csv)")
        self.run(lambda:self.import_file(path)) if path else self.run(lambda:None)

    def save(self):
        path,_=W.QFileDialog.getSaveFileName(self,"Export Colormap","","RGB Text (*.txt);;Colormap JSON (*.json);;RGB CSV (*.csv)")
        self.run(lambda:self.export_file(path)) if path else self.run(lambda:None)

    def apply(self):
        def stage():
            self.accept_table(); parent=self.parentWidget(); settings=parent.settings_value()
            for label,section in (("Surface","surface"),("Nodes","node"),("Edges","edge"),("Volume","volume")):
                settings[section]["colormap"]=deepcopy(self.maps[label])
            units=parent.export_units.currentText(); width=parent.export_width.value(); height=parent.export_height.value()
            parent.settings=settings; parent.install_settings()
            parent.export_units.setCurrentText(units); parent.export_width.setValue(width); parent.export_height.setValue(height)
            parent.dirty(); parent.statusBar().showMessage("Colormaps staged. Choose Apply and Render Scene."); self.accept()
        self.run(stage)
