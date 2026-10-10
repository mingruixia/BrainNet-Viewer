"""BrainNet Viewer shell aligned with the MATLAB desktop and approved design."""
import sys
from PySide6 import QtCore, QtGui, QtWidgets as W
from . import __version__
from .desktop_style import card, FitImage, StatusStrip, ExportUnitChoice, theme_icon

FILTERS={"surface":"Surface (*.nv *.gii *.pial *.white *.inflated *.sphere *.surf *.orig *.mesh *.byu *.g *.obj *.mz3)",
         "node":"Nodes (*.node)","edge":"Edges (*.edge)","surface_map":"Surface map (*.txt *.gii)","volume":"Volume (*.nii *.nii.gz *.hdr *.img)"}


def button(text,handler,primary=False):
    widget=W.QPushButton(text); widget.clicked.connect(handler)
    if primary: widget.setObjectName("Primary")
    return widget



class MacCanvasToolbar(W.QWidget):
    """Keep native Mac button labels readable when the canvas is narrow."""
    def __init__(self, grid):
        super().__init__()
        self.grid=grid
        self.wide=[]
        for index in range(grid.count()):
            self.wide.append((grid.itemAt(index).widget(),grid.getItemPosition(index)))
        self.compact=None
        grid.setSizeConstraint(W.QLayout.SetNoConstraint)
        self.setLayout(grid)
        self.setSizePolicy(W.QSizePolicy.Ignored,W.QSizePolicy.Fixed)

    def resizeEvent(self,event):
        super().resizeEvent(event)
        self.reflow()

    def reflow(self):
        widgets=[item[0] for item in self.wide]
        spacing=self.grid.horizontalSpacing()
        threshold=sum(w.sizeHint().width() for w in widgets[:6])+6*spacing+max(
            widgets[6].sizeHint().width(),sum(w.sizeHint().width() for w in widgets[-2:])+spacing)
        compact=self.width()<threshold
        if compact==self.compact:
            return
        self.compact=compact
        positions=[(0,0,1,1),(0,1,1,1),(0,2,1,1),(0,3,1,1),
                   (1,0,1,1),(1,1,1,1),(1,2,1,2),
                   (2,0,1,2),(2,2,1,2),(3,0,1,2),(3,2,1,1),(3,3,1,1)]
        for widget,_ in self.wide:
            self.grid.removeWidget(widget)
        for index,(widget,wide_position) in enumerate(self.wide):
            self.grid.addWidget(widget,*(positions[index] if compact else wide_position))
        self.updateGeometry()


def build_shell(app,library):
    app.setWindowTitle(f"BrainNet Viewer {__version__} — Python development")
    central=W.QWidget(); central.setObjectName("Workspace"); root=W.QVBoxLayout(central)
    root.setContentsMargins(8,6,8,0); root.setSpacing(8)
    banner=W.QFrame(); banner.setObjectName("Banner"); banner.setFixedHeight(86)
    head=W.QHBoxLayout(banner); head.setContentsMargins(16,6,18,6); head.setSpacing(14)
    brand=FitImage(library/"assets/branding/BrainNet_Viewer_2_Startup_PSD-v1.png"); brand.setFixedSize(112,74); brand.setSizePolicy(W.QSizePolicy.Fixed,W.QSizePolicy.Fixed); head.addWidget(brand)
    titles=W.QVBoxLayout(); titles.setSpacing(0)
    title=W.QLabel("BrainNet Viewer"); title.setObjectName("BrandTitle"); titles.addWidget(title)
    subtitle=W.QLabel("Brain Connectome Visualization"); subtitle.setObjectName("BrandSubtitle"); titles.addWidget(subtitle); head.addLayout(titles,1)
    app.theme_choice=W.QComboBox(); app.theme_choice.setFixedSize(128,34)
    for name in ("Light","Dark"): app.theme_choice.addItem(theme_icon(name=="Dark"),name)
    app.theme_choice.currentTextChanged.connect(app.set_theme); head.addWidget(app.theme_choice)
    head.addSpacing(12)
    for text,handler in (("Help",app.help),("About",app.about)):
        control=button(text,handler); control.setFixedSize(80,34); head.addWidget(control)
    root.addWidget(banner)
    app.columns=W.QSplitter(); app.columns.setHandleWidth(8); app.columns.setChildrenCollapsible(False); root.addWidget(app.columns,1)

    left,left_outer=card("Data Sources"); left.setMinimumWidth(250)
    left_scroll=W.QScrollArea(); left_scroll.setWidgetResizable(True); left_scroll.setFrameShape(W.QFrame.NoFrame)
    left_scroll.setHorizontalScrollBarPolicy(QtCore.Qt.ScrollBarAlwaysOff)
    left_content=W.QWidget(); left_content.setObjectName("PanelContent"); left_layout=W.QVBoxLayout(left_content); left_layout.setContentsMargins(0,0,0,0); left_layout.setSpacing(7)
    left_scroll.setWidget(left_content); left_outer.addWidget(left_scroll,1)
    hint=W.QLabel("Drop supported files here or use Add Files."); hint.setObjectName("DropHint"); hint.setWordWrap(True); hint.setAlignment(QtCore.Qt.AlignCenter); left_layout.addWidget(hint)
    row=W.QHBoxLayout(); row.addWidget(button("Add Files",app.add_files,True)); row.addWidget(button("Validate and Load",app.validate_inputs)); left_layout.addLayout(row)
    files=W.QGridLayout(); files.setContentsMargins(0,3,0,2); files.setHorizontalSpacing(4); files.setVerticalSpacing(6); files.setColumnStretch(1,1)
    app.file_labels={}; app.role_buttons={}
    for index,(role,label) in enumerate((("surface","Surface Mesh"),("node","Nodes"),("edge","Edges"),("surface_map","Surface Map"),("volume","Volume / Atlas"),("scene","Scene File"))):
        name=W.QLabel(label); name.setStyleSheet("font-weight:600"); files.addWidget(name,index,0)
        info=W.QLabel("Requires Nodes" if role=="edge" else "Not selected"); info.setObjectName("Muted"); info.setMinimumWidth(35); info.setSizePolicy(W.QSizePolicy.Ignored,W.QSizePolicy.Preferred)
        files.addWidget(info,index,1); app.file_labels[role]=info
        action=button("Open" if role=="scene" else "Add",lambda checked=False,r=role:app.role_action(r)); action.setFixedWidth(48)
        files.addWidget(action,index,2); app.role_buttons[role]=action
    left_layout.addLayout(files)
    row=W.QHBoxLayout(); row.addWidget(button("Save Scene",app.save_scene)); row.addWidget(button("Import Settings",app.import_ec)); left_layout.addLayout(row)
    app.summary=W.QTextEdit(); app.summary.setReadOnly(True); app.summary.setMinimumHeight(95); app.summary.setPlaceholderText("Scene\nSelect input files to review paths and data size."); left_layout.addWidget(app.summary,1)
    export_box=W.QGroupBox("Export Figure"); export_grid=W.QGridLayout(export_box); export_grid.setContentsMargins(6,10,6,6); export_grid.setSpacing(4)
    app.export_format=W.QComboBox()
    for label,value in (("PNG","png"),("JPEG","jpg"),("TIFF","tif"),("BMP","bmp"),("PDF","pdf"),("SVG","svg")): app.export_format.addItem(label,value)
    app.export_format.currentIndexChanged.connect(lambda: setattr(app,"last_export_format",app.export_format.currentData()))
    app.export_units=ExportUnitChoice(); app.export_units.addItems(["Pixels","Millimetres","Centimetres","Inches","Points"]); app.export_size_mode="Pixels"
    app.export_units.setStyleSheet("font-size:11px;padding-right:13px;")
    app.export_units.currentTextChanged.connect(app.export_units.setToolTip)
    export_grid.setColumnMinimumWidth(0,82); export_grid.setColumnMinimumWidth(1,44); export_grid.setColumnMinimumWidth(2,80)
    app.export_width=W.QDoubleSpinBox(); app.export_height=W.QDoubleSpinBox()
    for field,value in ((app.export_width,2000),(app.export_height,1500)):
        field.setDecimals(0); field.setRange(.001,16000); field.setValue(value); field.setButtonSymbols(W.QAbstractSpinBox.NoButtons); field.setMinimumWidth(45)
    app.export_dpi=W.QSpinBox(); app.export_dpi.setRange(1,2400); app.export_dpi.setValue(300); app.export_dpi.setButtonSymbols(W.QAbstractSpinBox.NoButtons)
    app.transparent=W.QCheckBox("Transparent")
    app.transparent.setStyleSheet("font-size:11px;")
    for control in (app.export_format,app.export_units,app.export_width,app.export_height,app.export_dpi):
        control.setSizePolicy(W.QSizePolicy.Ignored,W.QSizePolicy.Fixed); control.setMinimumWidth(35)
    for index,(label,control) in enumerate((("Format",app.export_format),("Width",app.export_width),("Height",app.export_height),("Units",app.export_units),("DPI",app.export_dpi))):
        row=index//3*2; col=index%3; export_grid.addWidget(W.QLabel(label),row,col); export_grid.addWidget(control,row+1,col)
    export_grid.addWidget(app.transparent,3,2)
    app.export_button=button("Export Figure",app.export,True); app.export_button.setEnabled(False); export_grid.addWidget(app.export_button,4,0,1,3)
    app.export_units.currentTextChanged.connect(app.change_export_units); left_outer.addWidget(export_box)
    app.columns.addWidget(left)

    center,center_layout=card("Render Canvas"); center.setMinimumWidth(430); app.center_layout=center_layout
    toolbar=W.QGridLayout(); toolbar.setContentsMargins(0,0,0,0); toolbar.setHorizontalSpacing(4); toolbar.setVerticalSpacing(5)
    app.mode=W.QComboBox(); app.mode.addItems(["Rotate","Pan","Zoom"]); app.mode.currentTextChanged.connect(app.interaction); app.mode.hide()
    app.mode_group=W.QButtonGroup(app); app.mode_buttons={}
    toolbar.addWidget(button("Reset",app.reset_view),0,0)
    for i,name in enumerate(("Rotate","Pan","Zoom"),1):
        control=button(name,lambda checked=False,n=name:app.mode.setCurrentText(n)); control.setCheckable(True)
        app.mode_group.addButton(control); app.mode_buttons[name]=control; toolbar.addWidget(control,0,i)
    app.mode_buttons["Rotate"].setChecked(True)
    toolbar.addWidget(button("Fit",app.reset_view),0,4)
    app.inspect_button=button("Inspect",app.toggle_inspect); app.inspect_button.setCheckable(True); toolbar.addWidget(app.inspect_button,0,5)
    app.view_choice=W.QComboBox()
    for label,value in (("Layout / Custom",None),("Left Lateral",1),("Right Lateral",5),("Anterior",3),("Posterior",7),("Superior",2),("Inferior",6)): app.view_choice.addItem(label,value)
    app.view_choice.currentIndexChanged.connect(app.toolbar_view); toolbar.addWidget(app.view_choice,0,6,1,2)
    app.demo_start_action=button("Live Demo",app.start_demo); app.demo_start_action.setEnabled(False); toolbar.addWidget(app.demo_start_action,1,0,1,2)
    app.demo_stop_action=button("Stop Demo",app.stop_demo); app.demo_stop_action.setEnabled(False); toolbar.addWidget(app.demo_stop_action,1,2,1,2)
    toolbar.addWidget(button("Clear Figure",app.clear_figure),1,4,1,2)
    app.popout_button=button("Pop Out",app.pop_out); app.popout_button.setEnabled(False); toolbar.addWidget(app.popout_button,1,6)
    app.render_button=button("Render Scene",app.render_scene,True); toolbar.addWidget(app.render_button,1,7)
    if sys.platform == "darwin":
        app.canvas_toolbar=MacCanvasToolbar(toolbar)
        center_layout.addWidget(app.canvas_toolbar)
    else:
        center_layout.addLayout(toolbar)
    app.startup_content=W.QWidget(); app.startup_content.setObjectName("PanelContent"); app.canvas_layout=W.QVBoxLayout(app.startup_content); app.canvas_layout.setContentsMargins(24,16,24,16)
    app.startup=FitImage(library/"assets/branding/BrainNet_Viewer_2_Startup_PSD-v1.png"); app.canvas_layout.addWidget(app.startup,1)
    info=W.QLabel(f"Version {__version__} · Public Beta 1 · Developer: Mingrui Xia\nProject: https://github.com/mingruixia/BrainNet-Viewer")
    info.setObjectName("StartupInfo"); info.setWordWrap(True); info.setAlignment(QtCore.Qt.AlignCenter); app.canvas_layout.addWidget(info)
    citation=W.QLabel("Xia M, Wang J, He Y (2013). BrainNet Viewer: A Network Visualization Tool for Human Brain Connectomics. PLoS ONE 8: e68910.")
    citation.setObjectName("Citation"); citation.setWordWrap(True); citation.setAlignment(QtCore.Qt.AlignCenter); app.canvas_layout.addWidget(citation)
    app.canvas_host=W.QWidget(); app.canvas_host.setMinimumSize(200,200)
    app.canvas_stack=W.QStackedLayout(app.canvas_host); app.canvas_stack.setStackingMode(W.QStackedLayout.StackAll); app.canvas_stack.setContentsMargins(0,0,0,0); app.canvas_stack.addWidget(app.startup_content)
    app.inspect_label=W.QLabel(app.canvas_host); app.inspect_label.setWordWrap(True); app.inspect_label.setAlignment(QtCore.Qt.AlignLeft|QtCore.Qt.AlignTop)
    app.inspect_label.setAttribute(QtCore.Qt.WA_TransparentForMouseEvents); app.inspect_label.setStyleSheet("QLabel {color:white;background:rgba(20,35,55,220);padding:8px 12px;border-radius:5px;}")
    app.inspect_label.setMaximumWidth(520); app.inspect_label.setMaximumHeight(65); app.inspect_label.setSizePolicy(W.QSizePolicy.Maximum,W.QSizePolicy.Maximum)
    center_layout.addWidget(app.inspect_label); app.inspect_label.hide()
    center_layout.addWidget(app.canvas_host,1); app.columns.addWidget(center)

    app.right,settings_layout=card("Visualization Settings"); app.right.setMinimumWidth(310)
    app.settings_title=settings_layout.itemAt(0).widget()
    settings_layout.removeWidget(app.settings_title)
    app.settings_header=W.QWidget(); app.settings_header.setFixedHeight(32)
    heading=W.QHBoxLayout(app.settings_header); heading.setContentsMargins(0,0,0,0); heading.addWidget(app.settings_title,1)
    app.settings_toggle=W.QPushButton("<"); app.settings_toggle.setFixedWidth(28); app.settings_toggle.setToolTip("Collapse settings panel"); heading.addWidget(app.settings_toggle)
    settings_layout.addWidget(app.settings_header)
    app.settings_body=W.QWidget(); app.settings_body.setObjectName("PanelContent"); settings_layout.addWidget(app.settings_body,1)
    # When the body is hidden, consume unused height below the header rather
    # than letting the sole remaining row drift into the middle of the column.
    app.settings_collapsed_fill=W.QWidget(); app.settings_collapsed_fill.hide()
    settings_layout.addWidget(app.settings_collapsed_fill,1)
    settings_layout=W.QVBoxLayout(app.settings_body); settings_layout.setContentsMargins(0,0,0,0); settings_layout.setSpacing(7)
    def toggle_settings():
        collapsed=app.settings_body.isHidden()
        if not collapsed: app.expanded_columns=app.columns.sizes()
        app.settings_body.setVisible(collapsed); app.settings_title.setVisible(collapsed)
        app.settings_collapsed_fill.setVisible(not collapsed)
        app.right.setMinimumWidth(310 if collapsed else 50); app.right.setMaximumWidth(16777215 if collapsed else 50)
        app.settings_toggle.setText("<" if collapsed else ">"); app.settings_toggle.setToolTip("Collapse settings panel" if collapsed else "Expand settings panel")
        if collapsed: app.columns.setSizes(app.expanded_columns)
        else:
            left,canvas,settings=app.expanded_columns
            app.columns.setSizes([left,canvas+settings-50,50])
        app.resize_timer.start()
    app.settings_toggle.clicked.connect(toggle_settings)
    row=W.QHBoxLayout()
    for title,handler in (("Load Preset",app.open_preset),("Save Preset",app.save_preset),("Colors…",lambda:app.open_tool("colormap"))): row.addWidget(button(title,handler))
    settings_layout.addLayout(row)
    editor=W.QWidget(); app.right_layout=W.QVBoxLayout(editor); app.right_layout.setContentsMargins(0,0,0,0); settings_layout.addWidget(editor,1)
    app.install_settings()
    settings_layout.addWidget(button("Restore Defaults…",app.request_defaults))
    row=W.QHBoxLayout(); row.addWidget(button("Revert",app.revert)); row.addWidget(button("Apply",app.apply,True)); settings_layout.addLayout(row)
    tools=W.QWidget(); tools.setObjectName("PanelContent")
    tools_layout=W.QVBoxLayout(tools); tools_layout.setContentsMargins(0,0,0,0); tools_layout.setSpacing(4)
    app.tools_toggle=W.QPushButton("Tools >"); app.tools_toggle.setObjectName("AccordionHeader")
    app.tools_toggle.setCheckable(True); app.tools_toggle.setFixedHeight(36)
    app.tools_toggle.setToolTip("Expand tools"); tools_layout.addWidget(app.tools_toggle)
    app.tools_body=W.QWidget(); tools_layout.addWidget(app.tools_body); app.tools_body.hide()
    def toggle_tools(expanded):
        app.tools_body.setVisible(expanded)
        app.tools_toggle.setText("Tools v" if expanded else "Tools >")
        app.tools_toggle.setToolTip("Collapse tools" if expanded else "Expand tools")
    app.tools_toggle.toggled.connect(toggle_tools)
    grid=W.QGridLayout(app.tools_body); grid.setContentsMargins(6,0,6,6); grid.setSpacing(4)
    for i,(title,mode) in enumerate((("Merge","merge"),("Convert","convert"),("Subdivide","subdivide"),("Atlas Nodes","atlas"),("Save Boundary",None),("Animation","movie"))):
        control=button(title,app.save_boundary if mode is None else lambda checked=False,m=mode:app.open_tool(m)); grid.addWidget(control,i//2,i%2)
        if mode is None: app.boundary_export_button=control; control.setEnabled(False)
    settings_layout.addWidget(tools); app.columns.addWidget(app.right)
    app.columns.setStretchFactor(0,0); app.columns.setStretchFactor(1,1); app.columns.setStretchFactor(2,0)
    app.columns.setSizes([270,920,330]); app.setCentralWidget(central)
    # VTK calls winId on its first widget. Promote the host before showing the
    # main window so Qt need not hide/recreate visible native ancestors later.
    app.canvas_host.winId()
    app.setStatusBar(StatusStrip())
    app.resource_label=W.QLabel(); app.resource_label.setObjectName("Muted"); app.resource_label.setSizePolicy(W.QSizePolicy.Ignored,W.QSizePolicy.Preferred); app.statusBar().addWidget(app.resource_label,3)
    app.statusBar().showMessage("Select input files or open a Scene JSON.",5000)
    app.set_theme("Light"); app.setAcceptDrops(True)
    screen=W.QApplication.screenAt(QtGui.QCursor.pos()) or W.QApplication.primaryScreen()
    area=screen.availableGeometry(); app.resize(min(1600,int(area.width()*.94)),min(980,int(area.height()*.92)))
    app.move(area.center()-app.rect().center()); app.update_resources()
