"""Simple desktop tools sharing the same safe geometry and palette readers."""
from pathlib import Path
import numpy as np
from PySide6 import QtWidgets as W
from .io import Surface, read_surface
from .colormap_ui import ColormapTool
from .advanced_tools import source_records, verify_inputs, publish_new
from .surface_geometry import merge_surfaces


def write_nv(surface, path):
    path=Path(path)
    if path.suffix.lower()!=".nv": raise ValueError("Choose an .nv output filename.")
    with path.open("x",encoding="utf-8",newline="\n") as stream:
        stream.write(f"{len(surface.points)}\n"); np.savetxt(stream,surface.points,fmt="%.17g")
        stream.write(f"{len(surface.faces)}\n"); np.savetxt(stream,surface.faces+1,fmt="%d")


class SurfaceTool(W.QDialog):
    def __init__(self,parent,mode):
        super().__init__(parent); self.mode=mode; self.sources=[]; self.records=[]
        self.setWindowTitle("Merge Surfaces" if mode=="merge" else "Convert Surface to NV")
        outer=W.QVBoxLayout(self)
        hint=W.QLabel("Coordinates and vertex order are preserved. No registration or resampling is applied."); hint.setWordWrap(True); outer.addWidget(hint)
        self.list=W.QListWidget(); outer.addWidget(self.list,1)
        row=W.QHBoxLayout()
        for text,handler in (("Add Files",self.add),("Remove Selected",self.remove),("Move Up",lambda:self.move(-1)),("Move Down",lambda:self.move(1))):
            button=W.QPushButton(text); button.clicked.connect(handler); row.addWidget(button)
        outer.addLayout(row)
        form=W.QFormLayout(); self.optional=[]
        for key in ("Space (optional)","Units (optional)","Note (optional)"):
            control=W.QLineEdit(); form.addRow(key,control); self.optional.append(control)
        outer.addLayout(form)
        self.status=W.QLabel("Add files to review geometry automatically."); self.status.setWordWrap(True); outer.addWidget(self.status)
        row=W.QHBoxLayout(); self.save_button=W.QPushButton("Save NV"); self.save_button.setObjectName("Primary"); self.save_button.setEnabled(False)
        self.save_button.clicked.connect(self.save); row.addWidget(self.save_button)
        close=W.QPushButton("Close"); close.clicked.connect(self.reject); row.addWidget(close); outer.addLayout(row)

    def restore_focus(self): self.raise_(); self.activateWindow()

    def add(self):
        parent=self.parentWidget(); initial=str(parent.input_directory("surface")) if hasattr(parent,"input_directory") else ""
        paths,_=W.QFileDialog.getOpenFileNames(self,"Add Surfaces",initial,"Surfaces (*.nv *.gii *.pial *.white *.inflated *.sphere *.orig *.surf *.mesh *.byu *.g *.obj *.mz3)")
        try:
            records=[source_records(path) for path in paths]
            additions=[read_surface(path) for path in paths]
            verify_inputs([item for group in records for item in group])
            if self.mode=="convert" and len(self.sources)+len(additions)>1: raise ValueError("Conversion accepts one surface at a time.")
            self.sources.extend(additions); self.records.extend(records); self.review()
        except Exception as error: W.QMessageBox.warning(self,"Surface Tool",str(error))
        finally: self.restore_focus()

    def remove(self):
        index=self.list.currentRow()
        if index>=0: self.sources.pop(index); self.records.pop(index); self.review()

    def move(self, offset):
        index=self.list.currentRow(); target=index+offset
        if index<0 or not 0<=target<len(self.sources): return
        for items in (self.sources,self.records): items[index],items[target]=items[target],items[index]
        self.review(); self.list.setCurrentRow(target)

    def review(self):
        self.list.clear()
        for s in self.sources:
            item=W.QListWidgetItem(f"{s.path.name} · {len(s.points):,} vertices · {len(s.faces):,} faces"); item.setToolTip(str(s.path)); self.list.addItem(item)
        self.save_button.setEnabled(len(self.sources)>=2 if self.mode=="merge" else len(self.sources)==1)
        self.status.setText(f"{len(self.sources)} file(s) · {sum(len(s.points) for s in self.sources):,} vertices · {sum(len(s.faces) for s in self.sources):,} faces. Optional text does not affect merging.")

    def save(self):
        filename,_=W.QFileDialog.getSaveFileName(self,"Save NV","merged.nv" if self.mode=="merge" else "converted.nv","BrainNet Surface (*.nv)")
        try:
            if not filename: return
            self.save_to(filename)
        except Exception as error: W.QMessageBox.warning(self,"Surface Tool",str(error))
        finally: self.restore_focus()

    def save_to(self, filename):
        valid=len(self.sources)>=2 if self.mode=="merge" else len(self.sources)==1
        if not valid:
            raise ValueError("Add at least two surfaces to merge." if self.mode=="merge" else "Add one surface to convert.")
        surface=merge_surfaces(self.sources) if self.mode=="merge" else self.sources[0]
        report={"kind":"brainnet-surface-"+self.mode,"sources":[item for group in self.records for item in group]}
        def writer(stream):
            stream.write(f"{len(surface.points)}\n"); np.savetxt(stream,surface.points,fmt="%.17g")
            stream.write(f"{len(surface.faces)}\n"); np.savetxt(stream,surface.faces+1,fmt="%d")
        def matches(other):
            return np.array_equal(other.points,surface.points) and np.array_equal(other.faces,surface.faces)
        result=publish_new(filename,".nv",report,writer,read_surface,matches)
        self.status.setText(f"Saved: {filename}. Source files are unchanged.")
        return result


