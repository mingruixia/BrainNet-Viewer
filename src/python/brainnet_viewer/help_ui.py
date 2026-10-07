"""Local shared-documentation navigation without constructing a VTK canvas."""
from pathlib import Path
from PySide6 import QtCore, QtGui, QtWidgets as W


class HelpBrowser(W.QTextBrowser):
    """Fit displayed image formats, without rewriting Markdown or image files."""
    def __init__(self, parent=None):
        super().__init__(parent)
        self._fit_timer = QtCore.QTimer(self)
        self._fit_timer.setSingleShot(True)
        self._fit_timer.timeout.connect(self.fit_images)

    def setMarkdown(self, text):
        super().setMarkdown(text)
        self._fit_timer.start(0)

    def resizeEvent(self, event):
        super().resizeEvent(event)
        if hasattr(self, '_fit_timer'):
            self._fit_timer.start(0)

    def fit_images(self):
        document = self.document()
        available = max(1.0, self.viewport().width() - 2 * document.documentMargin() - 8)
        updates = []
        block = document.begin()
        while block.isValid():
            iterator = block.begin()
            while not iterator.atEnd():
                fragment = iterator.fragment()
                if fragment.isValid() and fragment.charFormat().isImageFormat():
                    image_format = fragment.charFormat().toImageFormat()
                    url = document.baseUrl().resolved(QtCore.QUrl(image_format.name()))
                    image = document.resource(QtGui.QTextDocument.ImageResource, url)
                    if isinstance(image, (QtGui.QImage, QtGui.QPixmap)) and not image.isNull():
                        # Always use intrinsic dimensions, never a previously fitted size.
                        native_width = image.width() / image.devicePixelRatio()
                        native_height = image.height() / image.devicePixelRatio()
                        width = min(native_width, available)
                        height = native_height * width / native_width
                        if abs(image_format.width() - width) > .5 or abs(image_format.height() - height) > .5:
                            image_format.setWidth(width)
                            image_format.setHeight(height)
                            updates.append((fragment.position(), fragment.length(), image_format))
                iterator += 1
            block = block.next()
        # Update in place, preserving links, text, selection and page identity.
        cursor = QtGui.QTextCursor(document)
        cursor.beginEditBlock()
        for position, length, image_format in updates:
            cursor.setPosition(position)
            cursor.setPosition(position + length, QtGui.QTextCursor.KeepAnchor)
            cursor.setCharFormat(image_format)
        cursor.endEditBlock()


class HelpDialog(W.QDialog):
    def __init__(self, resource_root, parent=None):
        super().__init__(parent)
        self.resource_root = Path(resource_root).resolve()
        self.docs_root = self.resource_root / 'documentation/docs'
        self.setWindowTitle('BrainNet Viewer — Help')
        layout = W.QVBoxLayout(self)
        self.browser = HelpBrowser(self)
        self.browser.setOpenLinks(False)
        self.browser.setOpenExternalLinks(False)
        self.browser.anchorClicked.connect(self.open_link)
        layout.addWidget(self.browser)
        navigation = W.QHBoxLayout()
        for label, path in (
            ('Quick Help', self.resource_root / 'Help.en.md'),
            ('Shared Tutorials', self.docs_root / 'tutorials/unified/en/index.md'),
            ('User Manual (PDF)', self.docs_root / 'manual/en/BrainNet_Viewer_2_Unified_User_Manual_EN.pdf'),
        ):
            button = W.QPushButton(label)
            button.clicked.connect(lambda checked=False, target=path: self.open_local(target))
            navigation.addWidget(button)
        layout.addLayout(navigation)
        self.status = W.QLabel(); self.status.setWordWrap(True); layout.addWidget(self.status)
        close = W.QDialogButtonBox(W.QDialogButtonBox.Close)
        close.rejected.connect(self.reject); layout.addWidget(close)
        self.resize(820, 680)
        self.open_local(self.resource_root / 'Help.en.md')

    def open_local(self, path):
        path = Path(path).resolve()
        if not path.is_relative_to(self.resource_root):
            self.status.setText('This link is outside the installed documentation.'); return
        if not path.is_file():
            self.status.setText('Documentation is missing. Include the staged documentation when packaging.'); return
        if path.suffix.lower() == '.md':
            try:
                if path.stat().st_size > 2 * 1024 * 1024:
                    self.status.setText('This documentation page exceeds the preview size limit.'); return
                content = path.read_text(encoding='utf-8-sig')
            except (OSError, UnicodeError):
                self.status.setText('This documentation page could not be read.'); return
            self.current_page = path
            # Markdown image URLs resolve relative to the page, not the process cwd.
            self.browser.document().setBaseUrl(QtCore.QUrl.fromLocalFile(str(path.parent) + '/'))
            self.browser.setMarkdown(content)
            self.status.clear()
        elif path.suffix.lower() in {'.pdf', '.docx', '.png', '.jpg', '.jpeg', '.txt', '.json'}:
            if not QtGui.QDesktopServices.openUrl(QtCore.QUrl.fromLocalFile(str(path))):
                self.status.setText('No associated application could open this document.')
            else:
                self.status.clear()
        else:
            self.status.setText('This file type cannot be opened from Help.')

    def open_link(self, url):
        resolved = self.browser.document().baseUrl().resolved(url)
        if resolved.scheme() in {'http', 'https', 'mailto'}:
            QtGui.QDesktopServices.openUrl(resolved)
        elif resolved.isLocalFile():
            self.open_local(resolved.toLocalFile())
            if resolved.fragment():
                self.browser.scrollToAnchor(resolved.fragment())
        else:
            self.status.setText('Unsupported documentation link.')
