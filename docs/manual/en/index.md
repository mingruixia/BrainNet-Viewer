# BrainNet Viewer 2.0 User Manual

中文 (repository reference) · README (repository reference) · [Shared tutorials](../../tutorials/unified/en/index.md)

Use the [unified English Word manual](BrainNet_Viewer_2_Unified_User_Manual_EN_Candidate.docx) or its matching [unified English PDF manual](BrainNet_Viewer_2_Unified_User_Manual_EN.pdf) for MATLAB/Python desktop instructions.  The existing MATLAB English Word manual (repository reference) and MATLAB English PDF manual (repository reference) remain edition-specific references. The Markdown chapters below remain searchable MATLAB topic guides and should not be treated as identical Python controls.

For step-by-step learning, use the thirteen [shared desktop tutorials](../../tutorials/unified/en/index.md), then consult the [topic coverage map](../../tutorials/unified/en/Topic_Coverage.md) for differences in installation, file/session handling, tools, export and acceleration. Tutorial coverage is not a new software acceptance result.

## Core workflow

Use the main-window **Help** button for the edition's installed help. The MATLAB local bilingual documentation navigator (repository reference) describes its packaged routes; publishing the unified manual here does not replace installed Help links. The original legacy PDF is not part of the modern-app package.

Open the app → select files in Data Sources → Validate and Load → Visualization Settings → Apply (commits **and renders**) → interact / export. **Render Scene** can explicitly redraw. Revert discards uncommitted edits; canvas Reset restores the camera only. Follow the paired getting-started chapter (repository reference) for installation, data-root staging, coordinate cautions, and Scene versus Preset.

The illustrated Word/PDF edition includes reviewed application and scientific-view screenshots; release-build privacy and current-version checks remain pending.

## Chapter map

| ID | Chapter | Status | Existing reference (not a complete chapter) |
|---|---|---|---|
| M01 | Installation, launch and version scope | first-pass body | Installation and launch (repository reference) · Getting started (repository reference) |
| M02 | Data roles, file formats and coordinates | first-pass body | Data and coordinates (repository reference) · [Format matrix](../../compatibility/Surface_Format_Support.md) |
| M03 | Scene, presets and legacy configurations | first-pass body | Scenes and presets (repository reference) · Scene workflows (repository reference) |
| M04 | Layout, camera and interactions | first-pass body | Layout/camera controls (repository reference) · Scene replay (repository reference) · Live Demo (repository reference) |
| M05 | Global appearance and performance | first-pass body | Global controls/defaults (repository reference) · Backgrounds (repository reference) · Restore Defaults (repository reference) |
| M06 | Surface appearance, maps, boundaries and Inspect | first-pass body | Surface controls/defaults (repository reference) · Boundaries (repository reference) · Double Brain (repository reference) · Vertex RGB (repository reference) · Inspect limits (repository reference) |
| M07 | Nodes: selection, sizes, colors and labels | first-pass body | Node controls/defaults (repository reference) · Selection/labels (repository reference) · Typography (repository reference); dense-label and DPI review remains |
| M08 | Edges: selection, direction and appearance | first-pass body | Edge controls/defaults (repository reference) · Colors (repository reference) · Sparsity/ties (repository reference); current-build integrated acceptance remains pending |
| M09 | Volume mapping and statistical assumptions | first-pass body | Volume controls and eight algorithms (repository reference) · Signed display (repository reference) |
| M10 | Atlas and statistical ROIs | first-pass body | ROI controls (repository reference) · Statistical IDs (repository reference) |
| M11 | Custom colormaps and visualization presets | first-pass body | Colormap/preset controls (repository reference) · Reference (repository reference) |
| M12 | Image and camera-movie export | first-pass body | Figure/animation controls (repository reference) · Reference (repository reference) |
| M13 | Mesh tools and additional surface formats | first-pass body | Formats and mesh tools (repository reference) · Reference (repository reference) |
| M14 | Command line, batch workflows and provenance | first-pass body | Batch rendering and provenance (repository reference) · Reference (repository reference) |
| M15 | Migration, limitations and troubleshooting | first-pass body | Migration and troubleshooting (repository reference) · Reference (repository reference) |

## Existing paired topic guides

- Scene Workflows (repository reference)
- Live Demo (repository reference)
- Visualization Presets (repository reference)
- Render Detail (repository reference)
- Material Settings (repository reference)
- Colormaps (repository reference)
- FreeSurfer Surfaces (repository reference)
- BrainVISA Surfaces (repository reference)
- BYU Surfaces (repository reference)
- MNI BIC Surfaces (repository reference)
- MZ3 Surfaces (repository reference)
- Scene Inspection (repository reference)
- Surface Merging (repository reference)
- Convert Surface to NV (repository reference)
- Subdivide Surface to NV (repository reference)
- Generate Atlas Nodes (repository reference)
- Surface Boundaries (repository reference)
- Movies (repository reference)

## Before release

Check defaults, source columns, units, threshold inequalities, color/size encodings, spatial assumptions and failure behavior per control. Pair translations and reproducible examples for every chapter. Do not describe inactive controls as implemented features. Usability, resource clearance and the complete platform/toolbox matrix remain open.

Glossary (repository reference)
