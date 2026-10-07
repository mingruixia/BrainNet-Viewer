"""English reviewed-output dialogs; never alter the active Scene automatically."""
import re
from pathlib import Path
from PySide6 import QtWidgets as W
from .advanced_tools import SubdivisionPlan, AtlasNodePlan, verify_inputs


class ReviewedTool(W.QDialog):
    def __init__(self,parent,mode):
        super().__init__(parent); self.mode=mode; self.plan=None; self.reviewed=None; self.last_report=None
        subdivision=mode=="subdivide"
        self.setWindowTitle("Subdivide Surface" if subdivision else "Generate Atlas Nodes")
        outer=W.QVBoxLayout(self)
        help_text=("Linear midpoint refinement: each triangle becomes four. No smoothing, registration or transfer of vertex maps/colors. Load the new mesh separately."
                   if subdivision else "One node per nonzero integer label. Centroids use the atlas affine; no registration or MNI conversion. A centroid may lie outside its region.")
        label=W.QLabel(help_text); label.setWordWrap(True); outer.addWidget(label)
        row=W.QHBoxLayout(); self.input=W.QLineEdit(); self.input.setPlaceholderText("Choose a surface" if subdivision else "Choose a NIfTI label atlas")
        row.addWidget(self.input,1); browse=W.QPushButton("Browse..."); browse.clicked.connect(self.browse); row.addWidget(browse); outer.addLayout(row)
        form=W.QFormLayout()
        if subdivision:
            self.levels=W.QSpinBox(); self.levels.setRange(1,3); form.addRow("Subdivision Levels",self.levels)
            self.levels.valueChanged.connect(self.invalidate)
        else:
            self.regions=W.QLineEdit(); self.regions.setPlaceholderText("Blank = all; IDs separated by spaces or commas")
            self.module=W.QDoubleSpinBox(); self.module.setRange(-1e12,1e12); self.module.setDecimals(8)
            self.size=W.QDoubleSpinBox(); self.size.setRange(0,1e12); self.size.setDecimals(8)
            form.addRow("Region IDs",self.regions); form.addRow("Color / Module",self.module); form.addRow("Size Value",self.size)
            self.regions.textChanged.connect(self.invalidate); self.module.valueChanged.connect(self.invalidate); self.size.valueChanged.connect(self.invalidate)
        outer.addLayout(form)
        review=W.QPushButton("Review Surface" if subdivision else "Review Atlas"); review.clicked.connect(lambda:self.run(self.review)); outer.addWidget(review)
        self.summary=W.QPlainTextEdit(); self.summary.setReadOnly(True); outer.addWidget(self.summary,1)
        form=W.QFormLayout(); self.space=W.QLineEdit(); self.units=W.QLineEdit()
        form.addRow("Space (optional)" if subdivision else "Affine Space",self.space)
        form.addRow("Units (optional)" if subdivision else "Affine Units",self.units)
        if subdivision:
            self.note=W.QLineEdit(); form.addRow("Note (optional)",self.note); self.note.textChanged.connect(self.clear_confirmation)
        outer.addLayout(form)
        self.confirm=W.QCheckBox("I understand that subdivision changes geometry and does not transfer vertex attributes."
                                 if subdivision else "I verified that the atlas affine uses the declared space and units.")
        outer.addWidget(self.confirm); self.confirm.toggled.connect(self.update_save)
        self.status=W.QLabel("Review the input before saving." if subdivision else "Defaults: module = 0, size = 0. Set a positive size for visible uniform nodes. The active Scene is unchanged.")
        self.status.setWordWrap(True); outer.addWidget(self.status)
        row=W.QHBoxLayout(); self.save_button=W.QPushButton("Save New .nv..." if subdivision else "Save New .node...")
        self.save_button.setEnabled(False); self.save_button.clicked.connect(self.save)
        self.save_button.setObjectName("Primary")
        row.addWidget(self.save_button); close=W.QPushButton("Close"); close.clicked.connect(self.reject); row.addWidget(close); outer.addLayout(row)
        self.input.textChanged.connect(self.invalidate); self.space.textChanged.connect(self.clear_confirmation); self.units.textChanged.connect(self.clear_confirmation)

    def current_options(self):
        return ((self.input.text().strip(),self.levels.value()) if self.mode=="subdivide" else
                (self.input.text().strip(),self.regions.text().strip(),self.module.value(),self.size.value()))

    def clear_confirmation(self,*_): self.confirm.setChecked(False); self.update_save()

    def invalidate(self,*_):
        self.plan=None; self.reviewed=None; self.last_report=None
        self.clear_confirmation(); self.summary.setPlainText("Input or options changed. Review again before saving.")

    def update_save(self,*_):
        declared=self.mode=="subdivide" or all(v.text().strip() and v.text().strip().lower() not in ("unknown","unverified") for v in (self.space,self.units))
        self.save_button.setEnabled(self.plan is not None and self.confirm.isChecked() and declared)

    def review(self):
        self.invalidate(); options=self.current_options()
        if self.mode=="subdivide":
            candidate=SubdivisionPlan.review(options[0],options[1]); report=candidate.report
            lines=["SURFACE REVIEW — linear midpoint refinement",f"Source: {report['initial_vertices']:,} vertices · {report['initial_faces']:,} faces"]
            for k,(vertices,faces) in enumerate(report["level_counts"],1): lines.append(f"Level {k}: {vertices:,} vertices · {faces:,} faces")
            lines.append("Vertex maps, colors and active display transforms are not transferred.")
        else:
            tokens=[v for v in re.split(r"[,\s]+",options[1]) if v]
            try: regions=[float(token) for token in tokens]
            except ValueError: raise ValueError("Enter numeric region IDs separated by spaces or commas; ranges and expressions are not supported.") from None
            candidate=AtlasNodePlan.review(options[0],regions,options[2],options[3]); report=candidate.report
            lines=["ATLAS REVIEW — affine coordinates, no registration",f"{report['node_count']:,} nodes · dimensions {' × '.join(map(str,report['dimensions']))}",
                   f"Affine: {report['affine_method']} · module = {options[2]:g} · size = {options[3]:g}"]
            for label,count,point in zip(candidate.nodes.labels[:100],report["voxel_counts"][:100],candidate.nodes.positions[:100]):
                lines.append(f"ID {label}: {count} voxels; XYZ = "+", ".join(f"{value:.6g}" for value in point))
            if report["node_count"]>100: lines.append("Preview limited to 100 nodes; all reviewed nodes will be saved.")
        for source in report["sources"]: lines.extend([source["path"],"SHA-256: "+source["sha256"]])
        self.plan=candidate; self.reviewed=options; self.summary.setPlainText("\n".join(lines))
        self.status.setText("Review complete. Confirm before saving a new file."); self.update_save()

    def save_to(self,path):
        if self.plan is None or self.reviewed!=self.current_options():
            self.invalidate(); raise ValueError("Review the current input and options before saving.")
        try: verify_inputs(self.plan.report["sources"])
        except ValueError: self.invalidate(); raise
        options=dict(confirmed=self.confirm.isChecked(),space=self.space.text(),units=self.units.text())
        if self.mode=="subdivide": options["note"]=self.note.text()
        self.last_report=self.plan.write(path,**options)
        self.status.setText(f"Saved: {self.last_report['output_path']}. Load the new file when ready; the active Scene is unchanged.")
        return self.last_report

    def run(self,action):
        try: action()
        except Exception as error:
            self.status.setText(str(error)); W.QMessageBox.warning(self,self.windowTitle(),str(error))
        finally: self.raise_(); self.activateWindow()

    def browse(self):
        surface=self.mode=="subdivide"
        filters=("Surfaces (*.nv *.gii *.pial *.white *.inflated *.sphere *.orig *.surf *.mesh *.byu *.g *.obj *.mz3)"
                 if surface else "NIfTI (*.nii *.nii.gz *.hdr *.img)")
        parent=self.parentWidget()
        initial=str(Path(self.input.text()).parent) if self.input.text() else str(parent.input_directory("surface" if surface else "volume")) if hasattr(parent,"input_directory") else ""
        try:
            path,_=W.QFileDialog.getOpenFileName(self,"Choose Surface" if surface else "Choose Label Atlas",initial,filters)
            if path: self.input.setText(path); self.run(self.review)
        finally: self.raise_(); self.activateWindow()

    def save(self):
        extension=".nv" if self.mode=="subdivide" else ".node"
        try:
            path,_=W.QFileDialog.getSaveFileName(self,"Save New File","",f"BrainNet Output (*{extension})")
            if path: self.run(lambda:self.save_to(path))
        finally: self.raise_(); self.activateWindow()
