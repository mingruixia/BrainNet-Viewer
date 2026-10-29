# Changes in BrainNet Viewer

## 2.0.0 — Unreleased

- Expand the MATLAB scene summary into the unused space below Save Scene, including in smaller windows.

### Local files and Scenes

- Python Desktop and Docker/Web clearly reject MATLAB Scenes that reference local file paths, without replacing the current Scene.
- MATLAB reads selected local files without an import-confirmation dialog or automatic copies. Save Scene JSON keeps file references; choose a portable ZIP to include inputs and their required companions for migration. Older relative Scenes remain readable, and image/movie provenance omits local input paths.

### Rendering and server sessions

- Keep MATLAB transparent and opaque raster exports on the same pixel grid, preserving content when native exports add a blank boundary pixel.

- Fit horizontal surface scalar-bar tick density to the available width without shrinking physical text sizes, and restore screen tick density after export.

- Keep transparent raster exports aligned on macOS with MATLAB releases before R2025a by centering native matte padding at a common resolution.

- Preserve physical title and scalar-bar sizes in MATLAB PNG/PDF exports.
  Reserve space for annotations and align transparent matte renders, including
  one-pixel padding differences in older MATLAB releases. Restore the original
  canvas after successful or failed exports.
- Keep Web text and cameras stable when switching between interaction and still
  image sampling. Ignore provisional frames while a remote view is mounting.
- Restore normal server login and logout forms while retaining origin checks.
  Handle unsent disconnect-cleanup requests without hiding other errors.
- Verify that CPU mode actually uses software rendering on Linux systems with
  NVIDIA graphics; report an error if the selected device contradicts CPU mode.

### Installation and distribution

- Adapt launcher CPU quotas to the Docker engine, reject invalid limits before
  GPU probing, and use a conservative 1-CPU Compose default. Document beta upgrade
  steps that preserve old containers and saved Scenes.

- Synchronize the documentation bundled with Python and Web, including font
  notices and current installation requirements.
- Add versioned local and Linux-server Docker recipes and a Linux/macOS launcher
  that probes GPU rendering before selecting GPU or CPU. Explicit GPU requests
  fail rather than silently switching backends.
- Add release planning and archive checks for version, file membership, licences
  and source identity. Planning does not build or publish packages.

### Annotation text

- Use physical point sizes for titles, scalar bars and global legends in
  Python Desktop and Web exports, so higher-DPI figures retain readable text.
  Preserve selected node-label units, record effective annotation sizes in
  provenance, and restore screen typography after success or failure.

- Preserve the existing canvas when a new title cannot fit. When a window is too
  small, show a warning and temporarily hide the title; enlarging the window
  restores it. Exports fit the complete title to the output dimensions and
  restore the screen state after success or failure.

- Use bundled fonts for Chinese and supported Unicode titles, node labels and
  scalar-bar titles. Report missing glyphs before rendering rather than silently
  dropping characters. ASCII node labels retain their selected font family.
- Fit complete titles to the available canvas width. Keep annotation fonts and
  cameras unchanged after export, and preserve Unicode glyph outlines in PDF.

### Windows desktop

- Fix an OpenGL initialization crash when opening the drawing window on Windows.
  Load the Windows graphics entry points before initializing the Qt/VTK canvas.

### MATLAB rendering

- Display the configured figure title above the brain views in embedded and
  separate windows, and include it in image exports. Empty titles retain the
  existing layout.
- Allow the application to close cleanly after its drawing target has been cleared.

### Web display and startup

- Clear a failed drawing-window transfer and restore a usable canvas for retrying
  Apply, with input selections retained.

- Reuse the native drawing window across Apply, layout changes and Clear Figure,
  releasing the previous scene's geometry without repeatedly creating GPU contexts.
  Prepare new scenes before replacing the canvas; release remote-view subscriptions
  and image caches on retirement and reject late events for retired views.
- Align the Scene File / Open and Save Scene / Import Settings controls with the desktop editions.
- Use 2x sampling for sharper still images, while retaining label sizes and preventing
  repeated sampling on Apply. Lower stream resolution and JPEG quality during interaction.
- Reduce surface detail temporarily during CPU interaction. Restore the original geometry
  for still images, Inspect, Scene operations and export. GPU rendering keeps the full geometry.
- Test GPU rendering in a separate process at startup and use the CPU if it is unavailable.
  The local launcher also offers explicit Auto, GPU and CPU choices.
- Separate standalone Web startup from library calls so embedded use does not replace
  the calling process. Allow 90 seconds for graphics probing and service initialization.
- Retain optional WSL adapter selection and use consistent software-renderer detection.

### Input handling and security

- Update Pillow to 13.0.0 to fix image-processing security vulnerabilities.
  Current source builds now require Python 3.11 or newer on all platforms.

- Record the surface scalar display rule in export metadata. Exact zero and nonfinite
  values use the base surface color; small nonzero values retain the selected colormap.
  Python and Web also record a separate hash of the display rules. These fields
  distinguish the corrected rendering behavior from earlier beta exports.
- Keep small nonzero surface-map values in the selected colormap. Only exact zero
  and nonfinite values use the base surface color; the scalar legend stays continuous.
- Label statistical P values as voxelwise and uncorrected in the controls and
  export metadata. Statistical cutoffs and cluster-extent filtering are unchanged.
- Reclaim inactive server sessions even when a browser connection remains open,
  with an advance warning and an option to keep the session. Count failed sign-ins
  separately from successful access, add bounded audit records and cache static
  browser assets privately. Limit software-renderer threads in each server worker.
- Explain ignored cluster-size settings and asymmetric undirected edge matrices
  without changing threshold values or the upper-triangle selection rule.
- Add a Linux LAN server mode with HTTPS, a team access password and a separate
  application process for each browser session. Bound concurrent sessions and
  sign-in attempts; remove inactive workers after the configured idle period.
  Keep the local single-user recipe unchanged.
- Update pypdf to 6.21.2 to address PDF parsing vulnerabilities, including excessive processing of malformed references. Use defusedxml for XML entity protection.
- Preserve `#` within node labels in MATLAB and Python.
- Validate Python Scene paths, bound JSON reads and reject duplicate keys or nonfinite values.
  Check portable assets before saving a new Scene without replacing existing files.
- Check local Web Host/Origin headers and obtain a random startup key through a
  same-origin request. The server remains intended for one trusted local user.
- Build source Docker images on a pinned Python 3.12 base, check dependencies and
  report HTTP health. ARM64 source rendering remains unverified; released images are unchanged.
- Clarify GPL-3.0-or-later for project code while retaining bundled-resource terms.

### Documentation and development

- Check final, beta and maintenance version numbers against Python package metadata
  and the MATLAB display version when validating a wheel.

- Revise the English and Chinese guides, tutorials and illustrated manual for clearer instructions.
- Explain the trusted-local-user security model and configurable Compose resource limits.
- Add HTTP/WebSocket authentication, GIfTI preflight and affine-reader regression tests,
  with a MATLAB reader job in continuous integration.
- Use one source for Python version metadata and check its agreement with MATLAB during wheel verification.

## 2.0.0-beta.1

### Editions and workspace

- MATLAB Desktop with an App-style workspace and no SPM dependency.
- Independent Python Desktop using Qt and VTK.
- Docker-hosted Web edition on port 1031, with background startup and browser access.
- Shared Data Sources, collapsible Visualization Settings, direct Apply rendering,
  Light/Dark themes, scene summaries, mesh tools and contextual Help.

### Scientific visualization

- Surface, node, edge, vertex-map, volume and atlas-ROI displays with compact multi-view layouts.
- Independent rotation, pan and zoom for each view; camera Reset and Fit.
- Fractional node and edge size scales; default edge scale 0.7.
- Current sparsity selection, directed-arrow proportions, module colors and adjustable labels.
- Common scientific colormaps including viridis, plasma, inferno, magma and cividis.
- Zero/null surface-map values retain the base surface color.
- Statistical P-value thresholds from supported NIfTI metadata, cluster-size filtering,
  signed mapping, ROI selection ranges and smoothed ROI geometry.
- AAL and Brodmann Inspect labels for appropriately aligned MNI-space inputs.

### Files and output

- Independent input readers, portable Scenes, visualization presets and custom colors.
- Merge, Convert, Subdivide and Atlas Nodes tools; camera animation.
- Figure export with pixel or physical dimensions, DPI, transparency and provenance.
- Web image and sidecar downloads remain separate; portable Scenes download as ZIP.
- Improved window sizing, dialog focus, multi-view fitting and export-state restoration.

### Resources and documentation

- All 12 supplied surface templates are retained.
- AtlasNetworks retains AAL90 and includes fourteen matched GroupFC networks,
  including AAL116, Schaefer1000 and Brainnetome246. Brodmann82, Dos160,
  Fair34 and HOA112 now have GroupFC pairs with module colors and strength sizes.
- AAL90 volume/vertex-map support files are in the atlas library; node and edge
  tutorials use AAL90. AAL3v2 and Shen278 volume filenames match their library names.
- Unified illustrated English Word/PDF manual and shared tutorials; bilingual Python
  and Docker installation instructions.

Project code is GPL-3.0-or-later. Bundled resources retain their source credits and notices.
See the installation guides for deployment requirements and edition differences.
