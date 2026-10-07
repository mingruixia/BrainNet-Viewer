"""MATLAB-aligned desktop shell components; settings values stay in the core."""
from PySide6 import QtCore, QtGui, QtWidgets as W
from pathlib import Path


class SettingsChoice(W.QComboBox):
    """Friendly labels with stable serialized values and programmatic aliases."""
    def setCurrentText(self, text):
        index=self.findData(text)
        super().setCurrentIndex(index) if index>=0 else super().setCurrentText(text)


class CompactNumber(W.QDoubleSpinBox):
    def textFromValue(self,value):
        text=super().textFromValue(value); point=self.locale().decimalPoint()
        return text.rstrip("0").rstrip(point) if point in text else text


class ExportUnitChoice(W.QComboBox):
    """Compact selected unit; popup and serialized value retain the full name."""
    def paintEvent(self,event):
        painter=W.QStylePainter(self); option=W.QStyleOptionComboBox(); self.initStyleOption(option)
        painter.setFont(self.font())
        option.currentText={"Millimetres":"mm","Centimetres":"cm","Inches":"in","Points":"pt"}.get(self.currentText(),self.currentText())
        painter.drawComplexControl(W.QStyle.CC_ComboBox,option); painter.drawControl(W.QStyle.CE_ComboBoxLabel,option)


class StatusStrip(W.QStatusBar):
    def __init__(self):
        super().__init__(); self.message=W.QLabel("Ready"); self.message.setMaximumWidth(450)
        self.message.setSizePolicy(W.QSizePolicy.Ignored,W.QSizePolicy.Preferred); self.message.setMinimumWidth(180)
        self.addPermanentWidget(self.message,1); self.text="Ready"

    def showMessage(self,text,timeout=0):
        self.text=text; self.message.setText(text); self.message.setToolTip(text)

    def currentMessage(self): return self.text


class FitImage(W.QLabel):
    def __init__(self, path, parent=None):
        super().__init__(parent); self.original=QtGui.QPixmap(str(path))
        self.setAlignment(QtCore.Qt.AlignCenter)
        self.setMinimumSize(1,1); self.setSizePolicy(W.QSizePolicy.Ignored,W.QSizePolicy.Ignored)

    def resizeEvent(self,event):
        if not self.original.isNull(): self.setPixmap(self.original.scaled(self.size()*0.9,QtCore.Qt.KeepAspectRatio,QtCore.Qt.SmoothTransformation))
        super().resizeEvent(event)


class Accordion(W.QScrollArea):
    """One scroll surface, a single expanded category, click again to collapse."""
    def __init__(self):
        super().__init__(); self.setWidgetResizable(True); self.setFrameShape(W.QFrame.NoFrame)
        self.setHorizontalScrollBarPolicy(QtCore.Qt.ScrollBarAlwaysOff)
        self.body=W.QWidget(); self.body.setObjectName("AccordionBody")
        self.rows=W.QVBoxLayout(self.body); self.rows.setContentsMargins(0,0,0,0); self.rows.setSpacing(3); self.rows.addStretch()
        self.setWidget(self.body); self.headers=[]; self.pages=[]; self.labels=[]; self.active=-1

    def addItem(self,page,label):
        index=len(self.pages); label=label.removesuffix(" >")
        header=W.QPushButton(label+" >"); header.setObjectName("AccordionHeader"); header.setCheckable(True); header.setFixedHeight(36)
        header.clicked.connect(lambda:self.setCurrentIndex(-1 if self.active==index else index))
        page.setSizePolicy(W.QSizePolicy.Expanding,W.QSizePolicy.Fixed); page.setVisible(False)
        self.rows.insertWidget(self.rows.count()-1,header); self.rows.insertWidget(self.rows.count()-1,page)
        self.headers.append(header); self.pages.append(page); self.labels.append(label)

    def setCurrentIndex(self,index):
        self.active=index
        for i,(header,page,label) in enumerate(zip(self.headers,self.pages,self.labels)):
            header.setChecked(i==index); header.setText(label+(" v" if i==index else " >")); page.setVisible(i==index)
        self.rows.activate()

    def currentIndex(self): return self.active

    def widget(self,index=None):
        return self.body if index is None else self.pages[index]


def section_label(text):
    label=W.QLabel(text); label.setObjectName("SectionLabel"); return label


def theme_icon(dark=False):
    """Small native-painted icons, without a font-dependent symbol."""
    pixmap=QtGui.QPixmap(24,24); pixmap.fill(QtCore.Qt.transparent)
    painter=QtGui.QPainter(pixmap); painter.setRenderHint(QtGui.QPainter.Antialiasing)
    painter.setPen(QtGui.QPen(QtGui.QColor("#75adff"),2))
    if dark:
        path=QtGui.QPainterPath(); path.addEllipse(3,3,18,18)
        cut=QtGui.QPainterPath(); cut.addEllipse(9,0,18,18)
        painter.fillPath(path.subtracted(cut),QtGui.QColor("#75adff"))
    else:
        painter.drawEllipse(7,7,10,10)
        for x,y,a,b in ((12,1,12,4),(12,20,12,23),(1,12,4,12),(20,12,23,12),(4,4,6,6),(18,18,20,20),(4,20,6,18),(18,6,20,4)):
            painter.drawLine(x,y,a,b)
    painter.end(); return QtGui.QIcon(pixmap)


def card(title):
    frame=W.QFrame(); frame.setObjectName("Card")
    layout=W.QVBoxLayout(frame); layout.setContentsMargins(10,8,10,10); layout.setSpacing(7)
    label=W.QLabel(title); label.setObjectName("CardTitle"); layout.addWidget(label)
    return frame,layout


def stylesheet(dark=False):
    arrow=(Path(__file__).parent/"resources/assets/ui/chevron-down.svg").as_posix()
    up_arrow=(Path(__file__).parent/"resources/assets/ui/chevron-up.svg").as_posix()
    bg,panel,ink,muted,border,field,hover=("#101c30","#182840","#e5edf9","#a7bad3","#334660","#20334e","#263e60") if dark else ("#f5f7fc","#ffffff","#10244b","#61728e","#dce3ef","#ffffff","#edf3ff")
    return f"""
    QWidget {{font-family: 'Segoe UI', 'Arial'; font-size:12px; color:{ink};}}
    QMainWindow, QWidget#Workspace {{background:{bg};}}
    QDialog {{background:{panel};}}
    QFrame#Card {{background:{panel}; border:1px solid {border}; border-radius:7px;}}
    QFrame#Banner {{background:qlineargradient(x1:0,y1:0,x2:1,y2:0,stop:0 #041a42,stop:1 #063d89);border-radius:7px;}}
    QLabel#BrandTitle {{color:white;font-size:29px;font-weight:700;background:transparent;}}
    QLabel#BrandSubtitle {{color:#96c9ff;font-size:14px;background:transparent;}}
    QLabel#CardTitle {{font-size:14px;font-weight:700;color:{ink};padding:3px 2px 8px;border-bottom:1px solid {border};}}
    QLabel#SectionLabel {{font-weight:700;color:{ink};padding:9px 0 4px;border-bottom:1px solid {border};}}
    QLabel#Muted {{color:{muted};}}
    QLabel#StartupInfo {{font-size:14px;font-weight:600;}}
    QLabel#Citation {{color:#ca303d;font-size:13px;font-weight:600;}}
    QLabel#DropHint {{background:{bg};color:{muted};border:1px dashed {border};border-radius:5px;padding:9px;}}
    QPushButton,QToolButton {{background:{field};border:1px solid {border};border-radius:4px;padding:4px 7px;min-height:19px;}}
    QPushButton:hover,QToolButton:hover {{background:{hover};border-color:#8eb8fa;}}
    QPushButton:checked {{background:#e7efff;color:#084bcd;border-color:#8eb8fa;}}
    QPushButton:disabled,QToolButton:disabled {{color:{muted};background:{bg};}}
    QPushButton#Primary {{background:#0754e9;color:white;border:1px solid #0754e9;font-weight:600;}}
    QPushButton#Primary:hover {{background:#1769f5;}}
    QPushButton#Primary:disabled {{background:{bg};color:{muted};border-color:{border};}}
    QFrame#Banner QPushButton {{background:transparent;color:white;border-color:#688bb8;border-radius:6px;}}
    QFrame#Banner QPushButton:checked {{background:white;color:#0754e9;border-color:#8eb8fa;}}
    QPushButton#AccordionHeader {{text-align:left;background:{bg};border:0;border-bottom:1px solid {border};font-weight:700;padding-left:12px;border-radius:0;}}
    QPushButton#AccordionHeader:checked {{background:{hover};color:{ink};}}
    QScrollArea, QWidget#AccordionBody, QWidget#PanelContent {{background:{panel};border:0;}}
    QLineEdit,QComboBox,QSpinBox,QDoubleSpinBox,QTextEdit,QPlainTextEdit,QTableWidget {{background:{field};color:{ink};border:1px solid {border};border-radius:4px;padding:4px;selection-background-color:#0754e9;}}
    QLineEdit:disabled,QComboBox:disabled,QSpinBox:disabled,QDoubleSpinBox:disabled {{color:{muted};background:{bg};}}
    /* Native Windows spin buttons may be horizontal. Explicit geometry keeps
       the line editor out of the complete right-hand up/down hit areas. */
    QSpinBox,QDoubleSpinBox {{min-height:24px;padding:2px 3px 2px 5px;}}
    QSpinBox::up-button,QDoubleSpinBox::up-button {{subcontrol-origin:border;subcontrol-position:top right;width:20px;height:14px;border-left:1px solid {border};background:{bg};border-top-right-radius:4px;}}
    QSpinBox::down-button,QDoubleSpinBox::down-button {{subcontrol-origin:border;subcontrol-position:bottom right;width:20px;height:14px;border-left:1px solid {border};background:{bg};border-bottom-right-radius:4px;}}
    QSpinBox::up-button:hover,QDoubleSpinBox::up-button:hover,QSpinBox::down-button:hover,QDoubleSpinBox::down-button:hover {{background:{hover};}}
    QSpinBox::up-arrow,QDoubleSpinBox::up-arrow {{image:url("{up_arrow}");width:10px;height:6px;}}
    QSpinBox::down-arrow,QDoubleSpinBox::down-arrow {{image:url("{arrow}");width:10px;height:6px;}}
    QComboBox {{min-height:19px;padding-right:19px;}}
    QComboBox QAbstractItemView {{font-family:'Segoe UI','Arial';font-size:12px;background:{field};color:{ink};}}
    QFrame#Banner QComboBox {{background:#093368;color:white;border:1px solid #688bb8;border-radius:6px;}}
    QComboBox::drop-down {{border:0;width:18px;}}
    QComboBox::down-arrow {{image:url("{arrow}");width:12px;height:8px;}}
    QCheckBox {{spacing:7px;}}
    QCheckBox::indicator {{width:14px;height:14px;}}
    QSlider::groove:horizontal {{height:4px;background:{border};border-radius:2px;}}
    QSlider::sub-page:horizontal {{background:#0754e9;border-radius:2px;}}
    QSlider::handle:horizontal {{background:#0754e9;width:12px;height:12px;margin:-4px 0;border-radius:6px;}}
    QGroupBox {{border:1px solid {border};border-radius:5px;margin-top:11px;padding:10px 5px 5px;font-weight:600;}}
    QGroupBox::title {{subcontrol-origin:margin;left:8px;padding:0 3px;}}
    QScrollBar:vertical {{background:transparent;width:9px;margin:0;}}
    QScrollBar::handle:vertical {{background:#b6c4d8;min-height:30px;border-radius:4px;}}
    QScrollBar::add-line:vertical,QScrollBar::sub-line:vertical {{height:0;}}
    QSplitter::handle {{background:transparent;width:8px;}}
    QStatusBar {{background:{panel};border-top:1px solid {border};color:{muted};font-size:11px;}}
    QMenu {{background:{panel};border:1px solid {border};}}
    QMenu::item {{padding:6px 20px;}}
    QMenu::item:selected {{background:{hover};}}
    QToolTip {{background:{panel};color:{ink};border:1px solid {border};}}
    QHeaderView::section {{background:{bg};color:{ink};border:1px solid {border};padding:5px;font-weight:600;}}
    QTableCornerButton::section {{background:{bg};border:1px solid {border};}}
    QScrollBar::add-page:vertical,QScrollBar::sub-page:vertical {{background:transparent;}}
    """


GROUPS={
    "layout":[("", "layout", "preset view_direction custom_azimuth custom_elevation")],
    "global":[("", "global", "background_color shading lighting light_direction material_profile material_coefficients render_detail show_orientation_labels"),
              ("Figure Annotations", "image", "show_colorbar colorbar_location colorbar_label title")],
    "surface":[("", "surface", "color_mode color opacity colormap color_limits show_colorbar boundary_mode boundary_color boundary_threshold boundary_mask double_brain vertex_colors")],
    "node":[("Visibility","node","selection_mode selection_basis threshold"),
            ("Labels","node","label_mode label_basis label_threshold label_font_name label_font_size label_font_weight label_font_angle label_font_units label_color label_in_front"),
            ("Size","node","size_mode size_basis size size_scale size_threshold size_threshold_basis"),
            ("Color","node","color_mode color colormap color_limits color_threshold color_low color_high")],
    "edge":[("Visibility","edge","selection_mode threshold sparsity value_mode inter_hemisphere_only directed"),
            ("Size","edge","size_mode size size_scale size_threshold size_value_mode size_threshold_basis"),
            ("Color","edge","color_mode color colormap color_limits custom_color color_threshold length_threshold threshold_value_mode mapped_value_mode color_low color_high inter_module_color"),
            ("Opacity","edge","opacity_mode opacity opacity_range opacity_value_mode"),
            ("Arrowhead Shape","edge","arrow_length_scale arrow_width_scale")],
    "volume":[("","volume","display type threshold_mode statistical_threshold p_value cluster_size voxel_connectivity"),
              ("Surface Mapping","volume","map_algorithm positive_minimum positive_maximum negative_minimum negative_maximum colormap display_mode adjust_null null_color"),
              ("Atlas / Statistical ROIs","roi","draw_all selection color_mode palette show_legend color smoothing smoothing_kernel custom_colors")]
}

LABELS={"layout.preset":"Layout Preset","global.shading":"Surface Shading","global.lighting":"Lighting Model","global.material_profile":"Surface Material",
        "selection_mode":"Selection","color":"Uniform Color","size_basis":"Size Source","size":"Base Size","boundary_mode":"Boundary",
        "volume.type":"Volume Type","volume.display":"Display Volume","map_algorithm":"Mapping Algorithm","display_mode":"Display Values",
        "label_font_name":"Font","label_font_size":"Font Size","label_font_weight":"Font Weight","label_font_angle":"Font Angle","label_font_units":"Font Units",
        "roi.draw_all":"Draw All ROIs","roi.selection":"ROI Selection","roi.color_mode":"ROI Color Mode","roi.palette":"ROI Palette","roi.color":"ROI Color","roi.smoothing":"ROI Smoothing",
        "surface.show_colorbar":"Show Surface Colorbar","roi.show_legend":"Show ROI Legend","edge.directed":"Directed Edges","edge.inter_hemisphere_only":"Inter Hemi Only",
        "edge.size_threshold_basis":"Threshold Basis","node.label_in_front":"Labels in Front","node.label_color":"Label Color",
        "value_mode":"Selection Values","mapped_value_mode":"Mapped Values","threshold_value_mode":"Threshold Values","size_value_mode":"Size Values","opacity_value_mode":"Opacity Values"}


def style_dialog(dialog,width=650,height=500):
    """Use the main window's monitor, theme and heading proportions."""
    heading=W.QLabel(dialog.windowTitle()); heading.setObjectName("CardTitle")
    layout=dialog.layout(); layout.setContentsMargins(16,12,16,14); layout.setSpacing(9); layout.insertWidget(0,heading)
    for form in dialog.findChildren(W.QFormLayout):
        form.setRowWrapPolicy(W.QFormLayout.WrapLongRows)
        form.setFieldGrowthPolicy(W.QFormLayout.AllNonFixedFieldsGrow)
        form.setVerticalSpacing(8)
    parent=dialog.parentWidget(); screen=parent.screen() if parent else W.QApplication.primaryScreen()
    area=screen.availableGeometry(); dialog.resize(min(width,int(area.width()*.9)),min(height,int(area.height()*.9)))
    centre=parent.frameGeometry().center() if parent else area.center()
    position=centre-dialog.rect().center()
    # Tools may expose width/height fields or a move-source method.
    position.setX(max(area.left(),min(position.x(),area.right()-W.QWidget.width(dialog)+1)))
    position.setY(max(area.top(),min(position.y(),area.bottom()-W.QWidget.height(dialog)+1)))
    W.QWidget.move(dialog,position)
    for field in dialog.findChildren(W.QLabel): field.setWordWrap(True)


def field_label(section,key): return LABELS.get(section+"."+key,LABELS.get(key,key.replace("_"," ").title()))


def choice_label(value):
    return {"interp":"Interpolated","vertex-rgb":"Vertex RGB","scalar":"Scalar Map","surface-map":"Surface Map","roi":"ROI",
            "node-module":"Node Module","legacy-sparsity":"Legacy Threshold","p-value":"P Value","index":"Label Index",
            "both":"Positive & Negative","headlight":"Headlight","gaussian":"Gaussian","absolute":"Absolute"}.get(value,value.replace("-"," ").title())
