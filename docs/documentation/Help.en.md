# Local Help

Click **Help** in the main window. The non-modal Help window opens the English
manual by default; its four top buttons select English/Chinese manuals or
English/Chinese tutorials. Interface controls remain English in either language.

Pages are read locally as UTF-8. Headings, tables and code blocks are previewed;
choose a link in **Related pages and resources**, then **Open Selected**, to visit
another topic. **Back** returns to the previous page. Image/PDF resources and HTTP(S)
links open externally only after selection; images are not embedded in the preview.
Fragments currently open the containing page, not a particular heading.

**User Manual (PDF)** opens the illustrated BrainNet Viewer 2.0 English manual.
The Markdown chapters provide searchable topic guidance; the original manual
PDF is not distributed with the modern application. Final release-build review
of all documentation remains pending.

For the current launch → select/load → Apply/render → interact/export path, use
the [getting-started guide](Getting_Started.en.md). Its paired Chinese page is
available from that guide. Applied display changes render immediately; the old
historical manual describes a different interface.

Source checkouts use the project `docs` directory. A relocated installation should
include `docs` beside the MATLAB entry point directory (with manuals, tutorials,
topic guides and referenced assets); a missing page produces a local message,
without silently switching to historical content or fetching a website. Existing
relative README links also require the corresponding README beside `docs`.

Help reuses one centered, resizable window and closes with the App. It neither
changes visualization settings nor loads/renders scientific data. The document
preview is light-colored independently of the main UI theme. Embedded source HTML
is escaped; scripts and arbitrary local executables are not launched from links.
