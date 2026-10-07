"""Nonblocking live demo and cancellable, isolated animation export."""
import numpy as np
from PySide6 import QtCore, QtWidgets as W
from .movies import movie_plan, export_movie, available_formats, MovieCancelled


class LiveDemo(QtCore.QObject):
    def __init__(self,parent=None):
        super().__init__(parent); self.renderer=None; self.angle=5.
        self.timer=QtCore.QTimer(self); self.timer.timeout.connect(self.tick)

    @property
    def running(self): return self.timer.isActive()

    def start(self,renderer,angle=5.,period=.12):
        if not np.isfinite(angle) or angle<=0: raise ValueError("Demo angle must be positive and finite.")
        if not np.isfinite(period) or period<.05: raise ValueError("Demo period must be at least 0.05 seconds.")
        if renderer is None or renderer.prepared is None: raise ValueError("Render a scene before starting Live Demo.")
        self.stop(); self.renderer=renderer; self.angle=angle; self.timer.start(int(np.floor(period*1000+.5)))

    def tick(self):
        if not self.running or self.renderer is None: self.stop(); return
        try:
            for view in self.renderer.plotter.renderers:
                view.camera.Azimuth(self.angle); view.ResetCameraClippingRange()
            self.renderer.update_label_records(); self.renderer.plotter.render()
        except Exception: self.stop()

    def stop(self): self.timer.stop(); self.renderer=None


class MovieExportWindow(W.QDialog):
    def __init__(self,parent):
        super().__init__(parent); self.setWindowTitle("Export Animation")
        self.exporting=False; self.last_record=None; outer=W.QVBoxLayout(self)
        text=W.QLabel("World-axis orbit of all views using an isolated render. Main canvas cameras are unchanged. Save to a new output folder; existing folders are never overwritten.")
        text.setWordWrap(True); outer.addWidget(text); form=W.QFormLayout()
        self.format=W.QComboBox(); self.format.addItems(available_formats())
        self.width=W.QSpinBox(); self.width.setRange(128,3840); self.width.setValue(960)
        self.height=W.QSpinBox(); self.height.setRange(128,3840); self.height.setValue(720)
        self.duration=W.QDoubleSpinBox(); self.duration.setRange(.001,120); self.duration.setDecimals(3); self.duration.setValue(5)
        self.fps=W.QSpinBox(); self.fps.setRange(1,60); self.fps.setValue(24)
        self.axis=W.QComboBox(); self.axis.addItems(["z","y","x"])
        self.start_angle=W.QDoubleSpinBox(); self.start_angle.setRange(-360,360); self.start_angle.setDecimals(3)
        self.end_angle=W.QDoubleSpinBox(); self.end_angle.setRange(-720,720); self.end_angle.setDecimals(3); self.end_angle.setValue(360)
        for name,field in (("Format",self.format),("Width (pixels)",self.width),("Height (pixels)",self.height),
                           ("Duration (seconds)",self.duration),("Frame Rate",self.fps),("World Axis",self.axis),
                           ("Start Angle (degrees)",self.start_angle),("End Angle (degrees)",self.end_angle)): form.addRow(name,field)
        outer.addLayout(form); self.safe_fit=W.QCheckBox("Safe Fit: include the complete brain throughout the orbit"); self.safe_fit.setChecked(True); outer.addWidget(self.safe_fit)
        self.status=W.QLabel("PNG is lossless; MP4/AVI use lossy encoding. No duplicate endpoint for a full turn."); self.status.setWordWrap(True); outer.addWidget(self.status)
        row=W.QHBoxLayout(); self.save_button=W.QPushButton("Export to New Folder..."); self.save_button.clicked.connect(self.choose)
        self.save_button.setObjectName("Primary")
        row.addWidget(self.save_button); close=W.QPushButton("Close"); close.clicked.connect(self.reject); row.addWidget(close); outer.addLayout(row)

    def plan(self):
        return movie_plan(self.format.currentText(),self.width.value(),self.height.value(),self.duration.value(),self.fps.value(),
                          self.axis.currentText(),self.start_angle.value(),self.end_angle.value(),self.safe_fit.isChecked())

    def export_to(self,path,*,cancel=lambda:False,progress=lambda d,t:None):
        parent=self.parent()
        if self.exporting or parent.busy: raise ValueError("Another operation is already running.")
        if parent.renderer is None or not parent.export_button.isEnabled(): raise ValueError("Apply and Render Scene before exporting an animation.")
        plan=self.plan(); settings=parent.settings_value(); paths=dict(parent.paths); parent.stop_demo()
        self.exporting=True; parent.busy=True; self.save_button.setEnabled(False)
        try:
            self.last_record=export_movie(parent.renderer,path,plan,paths=paths,settings=settings,cancel=cancel,progress=progress)
            self.status.setText(f"Saved {self.last_record['verified_frames']} verified frames: {path}")
            return self.last_record
        finally: self.exporting=False; parent.busy=False; self.save_button.setEnabled(True)

    def choose(self):
        progress_dialog=None
        try:
            plan=self.plan(); destination,_=W.QFileDialog.getSaveFileName(self,"New Output Folder","","Output Folder (*)")
            if not destination: return
            progress_dialog=W.QProgressDialog("Preparing isolated render...","Cancel",0,plan["frame_count"],self)
            progress_dialog.setWindowModality(QtCore.Qt.ApplicationModal); progress_dialog.setMinimumDuration(0)
            progress_dialog.setAutoClose(False); progress_dialog.setAutoReset(False); progress_dialog.show()
            def progress(done,total):
                progress_dialog.setLabelText(f"Rendering frame {done} of {total}; verifying encoded video after rendering.")
                progress_dialog.setValue(done); W.QApplication.processEvents()
            self.export_to(destination,cancel=progress_dialog.wasCanceled,progress=progress)
        except MovieCancelled as error: self.status.setText(str(error))
        except Exception as error: self.status.setText(str(error)); W.QMessageBox.warning(self,"Export Animation",str(error))
        finally:
            if progress_dialog is not None: progress_dialog.close()
            self.raise_(); self.activateWindow()
