# BrainNet Viewer — Changes

## Unreleased — development source only

- Align the Python development package version to 2.0.0b1 for the planned BrainNet Viewer 2.0.0-beta.1 public beta. Existing internal packages and running containers retain their original versions; public candidate builds are still being prepared.

- Complete Windows amd64 association checks for the container idle-exit repair and provide a separate repaired offline image. The local browser Scene is restored; both architecture-specific offline candidates have existing-engine load evidence.

- Prepare a separate Linux/arm64 offline Docker image package with matching bilingual instructions, source/image identity and checksums. Existing Apple M2 Mac engine load/readback passes and native Scene restoration is user-reported. Fresh-engine loading remains unverified.

- Disable the Web server's automatic browser idle exit in container mode so a local background service remains available until explicitly stopped. Non-container startup retains the library default. Earlier images retain their original behavior; targeted installed ARM64 and amd64 lifecycle evidence is recorded separately.

- Add matching English/Chinese local Docker installation and session-lifetime guidance, plus an optional Windows start/stop/restart/status/logs helper with exact image and loopback-port checks. Lifecycle checks use an isolated container without interrupting the accepted service.

- Accept Trame state keyword arguments in the Web exit callback so owned workspaces and rendering resources are cleaned instead of raising a shutdown TypeError.

- Complete Web View shortcuts, asynchronous Live Demo/Stop Demo, same-tab canvas expansion/return, reviewed data-only legacy EC staging and unified tutorial/PDF Help links. Add refreshable rendering-host CPU/RAM/GPU information and align initial export settings with desktop defaults (2000×1500, 300 DPI). Include the existing pinned movie encoder in Web dependencies. Focused callback checks are separate from browser and container acceptance.

- Add desktop-schema Web Load/Save Preset and a four-target Colormap Editor with generation, resampling, reversal, JSON row preview and RGB table import/export. Changes stage until Apply; Revert restores committed settings. Bounded configuration/RGB callback tests pass; native page/file acceptance remains pending.

- Web Animation now uses a spawned rendering process with asynchronous frame progress, cooperative Cancel and one-job protection. Cancel before delivery starts no downloads; startup preparation can briefly delay. Focused real PNG/MP4 and cancellation lifecycle checks pass; native page acceptance remains pending.

- Add bounded Web Animation export with shared isolated orbit rendering, Safe Fit, available MP4/AVI or PNG frames and separate file downloads. Short exports run synchronously without cancellation; the main canvas/camera stay unchanged. Focused real-PNG/MP4 checks pass; native playback and wider performance acceptance remain pending.

- Add Web Save Boundary for the committed rendered surface mask: direct plain-text download with one binary value per original vertex, matching desktop output. Pending settings or failed Apply do not change the saved mask; Clear disables saving. Focused real-boundary readback passes; native download receipt remains pending.

- Web Atlas Nodes accepts inclusive ascending Region ID ranges such as `1-90`, mixed with individual IDs. Reject duplicate/overlapping or oversized selections; keep input order and existing atlas-label checks.

- Add Web Atlas Nodes with automatic discrete-label atlas review, region selection, uniform Module/Size, affine-centroid preview, declared coordinate space/units and direct node download/use. Reuse the desktop algorithm and exact writer; selecting generated nodes clears old edges. Focused real-AAL/callback checks pass; native download receipt awaits confirmation.

- Add Web Subdivide Surface using the desktop linear midpoint algorithm, automatic output counts, bounded Levels, direct NV download and selection for Apply. Original vertices are retained; vertex maps are not transferred. Focused geometry/callback checks pass; native download receipt awaits confirmation.

- Add Web Convert Surface to NV with automatic input review, optional metadata, direct download and selection for Apply. Original coordinates, vertex order and face connectivity are preserved. Focused Convert and related Merge checks pass; browser pial upload/render passes, actual download receipt awaits confirmation.

- Web adds Merge Surfaces with library selection or multiple-file upload, automatic geometry review, input ordering and optional metadata. Save NV directly downloads the merged surface with embedded provenance; Use Merged Surface selects it for Apply. Desktop and Web share the original coordinate-preserving merge algorithm. Focused readback and browser checks pass; actual download receipt awaits owner confirmation.

- Align Web panel density with desktop: side-by-side labels and controls, compact data rows, two-row export settings, consistent button heights and reduced accordion spacing. Narrow windows preserve readable fields and stack panels when needed.

- Web Inspect reports the original surface vertex, default-MNI XYZ, Brodmann Area and AAL region below the canvas. Toggle Inspect to clear; Apply resets the old result and Clear Figure disables picking. Focused real-VTK/callback and browser Single-view checks pass; native multi-view picking awaits owner acceptance. Desktop code and atlas resources are unchanged.

- Web Export Figure directly starts separate image and provenance-sidecar downloads in one click, without ZIP or an application save dialog. Save locations and multiple-download permission follow browser settings. Focused source/browser checks pass; both-file disk saving awaits owner confirmation.

- Web exports PNG, TIFF, JPEG, BMP, PDF and SVG with pixel/physical size units and shared restoration. JPEG/BMP disable transparency. Transparent PDF/SVG are raster containers. Focused readback checks pass.

- Fix Web settings entries disappearing after collapsing a scrolled panel. Titles remain mounted and arrows follow the actual expanded state; other categories remain selectable.

- Web adds desktop-aligned Volume/ROI thresholds, metadata-based P values, mapping algorithms and signed colormap ranges, null-to-surface coloring, ROI selection/colors/legend and smoothing. Focused real-data tests and representative browser mapping/insula checks pass; complete browser acceptance remains pending. Desktop packages and resources are unchanged.

- Web adds desktop-aligned edge filtering, sizing, colors, opacity and directed-arrow controls, preserving decimal scale and the current defaults. Custom color matrices bind to the original node order and are saved in portable Scenes. Focused real-data/source and browser checks pass; native matrix upload and full platform/visual acceptance remain pending.

- Web adds desktop-aligned node visibility, label/font, sizing and color controls with conditional enablement, decimal scale and shared Apply/Revert. Node colors can be edited as ordered module or mapped RGB rows without modifying source data. Focused real-data/API and browser checks pass; complete platform and desktop parity acceptance remains pending.

- Web preview preserves the last image's aspect ratio while a resized frame is pending, preventing temporary stretching when folding or unfolding settings. A brief proportional letterbox may appear during the remote update.

- Web cameras now fit the actual canvas when the browser or settings panel changes size. Apply inherits the current canvas size; independent camera edits and export restoration are preserved. Focused checks cover narrow-window clipping and aspect ratio; desktop packages remain unchanged.

- Web Surface controls now include uniform/scalar/RGB modes, opacity, shared colormaps/custom RGB rows, color limits/colorbar, boundaries and original-order mask/RGB binding. Explicit color mode choices are retained on Apply; a failed render preserves prior settings/canvas. Focused Surface/Scene checks and server-side independent camera-event checks pass; actual browser drags and complete desktop/platform parity remain pending.

- Web adds bounded uploads, per-input Add/Clear, data validation and file/size summaries, portable Scene ZIP save/open and bundled-library Scene JSON loading. Matching Python cameras restore on Apply. Layout and Global expose custom views, unsplittable-surface detection, background, shading/lighting/material, orientation and figure annotations. Full desktop parity remains in progress; desktop archives and the historical Docker image are unchanged.
- Actual Web Export Figure ZIP saving is owner-confirmed. Scene save generation/API readback and browser Scene opening pass focused checks; native Scene-download disk readback and camera gestures remain pending.

- Web gains a desktop-aligned banner and original brain imagery, Light/Dark selection, compact left export panel, central toolbar, single-category settings accordion, shared Apply/Revert/default restoration, right-panel collapse and narrow-window layout. Static remote previews use full quality. ZIP download decoding errors are now visible; actual browser save acceptance remains pending.

- The Web application and Docker recipe now default to port 1031. The Web design targets the accepted MATLAB/Python desktop appearance, panel behavior and complete functional coverage; implementation is ongoing.

- Web export accepts integer dimensions edited in browser number fields while retaining strict bounds. Container caches use temporary storage under a read-only filesystem. Focused Linux software-EGL rendering/export checks passed; browser disk-save acceptance and responsive/interaction refinement remain pending.

- An initial local single-user Web prototype reuses the Python scientific core for bundled-data rendering and PNG/provenance download. A restricted CPU Docker recipe is added. This is not full desktop parity, a tested container release or an authenticated multi-user service; desktop test archives remain unchanged.

- Python Node/Edge Size Scale controls accept fractional values, including imported integer values. Default Edge Size Scale is 0.7 in both editions; explicitly saved scales are retained.

- MATLAB embedded views now refresh their fitted viewport after Apply on current as well as older releases, avoiding a corner-only or clipped initial montage. Deferred fitting retains restored cameras and is cancelled when a subsequent camera action begins. Focused Windows source checks cover single and multiple layouts.
- Prepared desktop installation readmes omit internal version-history, testing and feedback sections. The Chinese Python instructions match the English Windows/macOS commands and resource-discovery guidance. Existing distributed archives are unchanged; repackaging awaits desktop feedback.

- Internal Test Edition 2 is packaged for MATLAB and Python using the accepted unchanged application archives. Installation notes and checksum identities accompany the distribution. Package integrity checks passed; no new full regression or public release is implied.

- The owner confirms the remaining Windows Help manual checks for the accepted desktop candidates. An additional Mac Help check is waived, not counted as a pass. Preparation for Internal Test Edition 2 preserves the accepted application bytes; package generation is still pending. No application changes or new full regression are implied.

- Current manuals and tutorials describe lesson content and materials without project-owner approval or distribution-status statements. Sources, credits, lesson settings and technical limitations are retained. The current Python source documentation staging is synchronized; existing wheels are unchanged. Both English Word documents received visual review, and the unified/MATLAB PDFs retain 48/41 pages. This wording update has not received a new native Help check.

- MATLAB Help displays local tutorial screenshots inline with proportional width fitting and supports direct page links through the safe documentation navigator. The related-resource list remains available, and Help tooltips describe the unified desktop manual. Focused source checks and normal-window Windows native image/navigation checks pass; the owner also confirms the requested native resize/navigation follow-up. The user also confirms the requested native Mac MATLAB R2024a Help checks. Automatic external-reader focus and fresh-package acceptance remain unverified. The subsequent documentation wording update is recorded separately; application code and existing packages are unchanged.

- The exact dev22 candidate completes the focused Apple M2 Mac Help acceptance: independent installation and 51 installed API/file checks pass; the owner confirms native Help/tutorial image resize/navigation, default-reader opening of the unified English 48-page manual and normal main-window return. Passive observations confirm the PDF/Close button signals and visible/active main after closure; native visual acceptance is owner-reported, not additional automated passes. The initial Quick Help checker assumption and original evidence remain documented. No application, resource or package change; no rendering or full regression suite.

- The owner confirms native Windows Help resizing and navigation for the responsive-Help candidate. Mac verification remains pending; scoped documentation acceptance is not full-release validation.

- A separate responsive-Help candidate passes fresh Windows installation and targeted installed resize/navigation checks. Normal-window native Help images fit correctly. Native narrow/wide resize confirmation and Mac checks remain pending; no full-release acceptance is implied.

- Help screenshots now fit the reading area and resize proportionally without enlarging small images or modifying the originals. Focused development-source checks pass; a new installed candidate and native platform checks remain pending.

- A separate documentation candidate passes fresh Windows installation and focused Help navigation/PDF opening checks. Tutorial screenshots load, but their original width can require horizontal scrolling in Help; responsive sizing remains pending. This does not establish Mac or full-release acceptance.

- Help now points to the shared desktop tutorials and approved unified English PDF. Python Help resolves illustrated pages relative to their location; packaging rules include the shared manuals, lessons and direct assets while leaving repository-only references as labelled text in bundled copies. These changes await a separately built and installed candidate; existing accepted packages are unchanged.

- The original dev19 Mac native PNG follow-up now passes file/provenance verification and late stable-state read-back after locating and moving the owner-saved output. The agreed Apple M2/single-display targeted retest can close with explicitly versioned dev19/native and dev20/repair evidence. Immediate native-save instrumentation was not captured; dev20 Windows association remains pending. No application or package change.

- The owner confirms the original dev19 Mac native PNG save workflow and normal post-dialog display. This is recorded as user-reported acceptance; the actual saved path is still required for independent native-file/provenance read-back. No application or package change.

- dev20 aligns the independent Surface scalar bar with the brain area after side-legend reservation. A separate candidate passes targeted installed Apple M2 Mac west/east full-window review, related Surface-only layouts and 96 export/error-restoration read-back checks. Previous wheels and all resource/data payloads remain unchanged. Original dev19 native Mac save is still pending; dev20 Windows association and broader platform acceptance have not been run.

- The exact dev19 candidate installs in a new Apple M2 Mac environment with its fixed desktop dependencies. Focused installed PNG/PDF and nonexistent-parent error checks preserve screen fonts, DPI, window and cameras; complete-window review confirms the repaired heading and horizontal Node/Edge spacing. A west-positioned Overview combination still lets the independent Surface minimum label touch the lower-left brain outline; native Mac save confirmation is pending. This verification changes evidence and documentation only and does not establish full desktop acceptance.

- The owner accepted all five final dev18 colorbar refinements. The agreed Apple M2/single-display Mac core phase is closed using explicitly versioned installed/source/manual evidence. This confirmation changes documentation only; the accepted wheel/hash is unchanged. Multiple displays/scaling, Intel Mac, Linux and current Windows remain untested. The next phase starts with independent Windows installation/startup of the exact accepted candidate, followed by targeted associated checks.

- dev18 refines surface colorbar positions by actual layout, brings Single/Ventral bars closer, aligns Dorsal bars with lateral surfaces, reserves space for unsplittable six-view meshes, and enlarges scalar-bar text to 12. Corresponding Mac source methods and a separate final installed candidate pass layout/export checks, including 21 file/state checks and exact font/DPI/camera/window restoration. The initial top-annotation margin failure was corrected with the original test assertion retained. Previous wheels remain unchanged; final appearance review and Windows associated tests are pending.

- dev17 shortens surface colorbars, increases single/six-view separation and slightly enlarges scalar-bar text. Four focused Mac source methods and the separate final installed candidate’s layout/export checks pass, including 16 file/state checks and exact font/DPI/camera/window restoration. The first candidate’s six-view spacing issue and wheel are retained separately; the final revision corrects it. The owner confirmed the preceding dev16 core manual group. Final presentation review and Windows associated checks remain pending.

- The owner confirms the dev16 single-view colorbar correction visually. Installed Mac PCC four-view mapping and historical AAL 29/30 top-view ROI fixtures and transparent PNG read-backs pass; native/manual review, Draw All/Selection linkage, precise focus returns and overwrite paths remain pending. No application or wheel changes; Windows associated testing awaits Mac closeout.

- dev16 reserves a bottom gutter for a visible surface colorbar in Single View and places horizontal scalar-bar numbers below the strip. Four focused Mac source checks and a separate installed Apple M2 candidate’s visible single/resize/eight-view rendering, transparent PNG/PDF and 11 output/state checks passed. Native UI setup was not repeated; Windows associated layout checks remain pending. Original wheels are unchanged. Investigation of the earlier automated Mac crash stopped at the owner’s request, with historical evidence retained.

- The unchanged installed dev15 Mac candidate completed the focused modular transparent TIFF and active AAL Inspect transparent PDF follow-up. Manual mouse/clear observations passed; independent output review confirms full composition, dimensions, transparency and provenance, with exact font/DPI/window/camera restoration. No application or package change. Remaining PCC/ROI, precise dialog-focus limits, environment-dependent coverage and the historical automated crash cause remain open.

- The unchanged installed dev15 Mac candidate passed the manual eight-view modular network transparent TIFF follow-up: 800 × 600 / 200 DPI, complete composition, fifteen legend labels, alpha and provenance, with exact font/DPI/window/eight-camera restoration. The owner does not require DPI arrows. Active Inspect transparent PDF remains pending manual acceptance; no application or package change.

- The unchanged installed dev15 Mac follow-up passed eight-view network Apply/resize, collapse/expand, visual Pan/Zoom/Reset, both system color paths and representative dialog returns. Remaining numeric/annotation exports are paused at a native-file automation input blocker pending one manual selection; precise focus limits and an incidental Scene save followed by a rejected further save are recorded. No application or package change.

- Prepared a direct manual comparison of the Mac Qt accessibility crash using the unchanged installed dev15 entry point with fault-handler logging and no accessibility polling. Related package files match the wheel; the owner reports all requested manual steps normal without a crash. The earlier automated crash remains recorded and its cause unconfirmed. No application or package change.

- The installed dev15 Mac interaction session stopped after SIGSEGV in the Qt Cocoa accessibility hierarchy during automation. Startup themes/Help and native Add checks passed; manual crash reproduction and remaining candidate interactions are unverified. No application source, dependency or wheel changed.

- Reconciled original Mac package and separately installed repair-candidate evidence, preserving historical failures and distinguishing source checks from installed GUI acceptance. Corrected stale Scene/CLI checklist status and documented remaining candidate interaction and environment-dependent checks. Documentation only; no application or package change.

- The separately installed dev15 Apple M2 candidate passed portable eight-view Scene relocation/open, exact saved-camera and export-preference restoration, and installed CLI export with no warnings. GUI/CLI camera records agree; 24 focused file/state checks passed. No application source or wheel changed; broader platform acceptance remains incomplete.

- The separately installed dev15 Apple M2 candidate passed three eight-view Millimetres GUI exports (normal/transparent PNG and normal PDF at 160 × 120 mm / 200 DPI), with complete composition, 21 output/state checks and normal exit. No application source or wheel changed in this follow-up; wider platform acceptance remains incomplete.

- Python dev15 restores actual macOS Qt annotation font sizes after export, retaining screen DPI/camera/window state. Twelve focused source checks and an independent installed candidate’s native Cancel plus four TIFF/PNG/PDF/SVG saves passed, including 22 output/state checks. Broader platform acceptance remains incomplete. Existing wheels and MATLAB are unchanged.

- Python dev14 corrects macOS Qt raster export cropping with a synchronous framebuffer draw before capture. A separate installed Mac candidate passed the focused composition checks; post-export colorbar font restoration remains open. Existing packages and MATLAB are unchanged.

- Added Python desktop installation instructions, illustrated real-data companion tutorials and a Chinese README. Updated cross-platform acceptance instructions and added a result form; Python macOS/Linux verification remains pending. Documentation is separate from the existing verified development wheel.

- Python dev12 development wheel passed fresh Windows virtual-environment installation, dependency checks and installed-only desktop/resource/CLI smoke checks. This is not cross-platform release acceptance.

- Completed Python Windows source-stage regression; updated obsolete test expectations while preserving the approved application behavior. Fresh installed-package and cross-platform acceptance remain separate steps.

- Python development source adds off-screen Scene image rendering and automatic image provenance records for desktop/console exports, with verified saved-camera restoration, data fingerprints, path privacy, overwrite confirmation and error rollback. Existing MATLAB builds and release packages are unchanged.

- Python source now includes approved original example resources and real-data tutorials accessible from Help; targeted package, network dimension, mapping and ROI checks added. No Scene files or excluded resources added; MATLAB and existing release packages unchanged.

- Windows Python workspace startup no longer retains its command window; startup errors are logged locally and reported with the log location. Existing packages and MATLAB are unchanged.
- Python desktop dev10: keep the settings collapse/expand arrow at the top-right without shifting it to the panel centre. Canvas expansion is retained; MATLAB and frozen packages are unchanged.
- Python desktop dev9: fix numeric up/down button hit areas overlapping the text editor on Windows. Use shared vertical arrow controls across settings and tools in both themes; retain button-free fields. MATLAB and frozen packages are unchanged.
- Python desktop dev8: fix main-window Merge/Convert/Animation launch, fractional statistical-threshold steps, vertex-map zero/NaN coloring and layout-specific Surface colorbar placement. MATLAB source also maps zero/NaN vertex values to the original surface color and restores per-layout colorbar positions, including the eight-view central-bottom gap. Scientific input values remain unchanged; frozen packages remain unchanged.
- MATLAB: retain only current Sparsity selection, migrate older Legacy Sparsity settings to it, and default edge length threshold to 75. Adjust Null uses the original surface color and reserves both zero-adjacent bins in signed colorbars. Existing frozen beta packages are unchanged.
- Python desktop dev7: direct Apply rendering, stable first-render window, compact external Inspect information, corrected lighting and colorbars, hemisphere ROI restriction, save confirmation and theme/setting display refinements. See the Python changelog for details. Not yet an updated public package.

## 2.0.0-beta.1

Build date: 1 October 2026. MATLAB public beta for evaluation and feedback before the stable 2.0 version. The build date is not a statement of the actual publication date.

### Interface and interaction

- English-language main-window workflow: load files, configure visualization, render in the embedded canvas, interact and export. Collapsible settings, Light/Dark themes, responsive layouts and same-monitor utility windows.
- Independent Rotate, Pan and Zoom for each brain view; wheel zoom affects only the hovered view while Zoom is active. Reset restores the configured layout without resizing the drawing area.
- File, color and tool dialogs restore their owner window's focus. Compatibility handling includes older MATLAB desktop versions and delayed fitting of multi-view layouts.
- Render-in-progress protection prevents concurrent Apply/Render requests. Restore Defaults retains inputs and the current canvas, and prompts for Apply/Render to redraw.

### Visualization and data

- Expanded surface, node, edge, volume-mapping and ROI controls, including directed-edge proportions, module-based colors and adjustable visibility/size.
- Independent NIfTI-1/2 and GIfTI readers, supported paired NIfTI and external GIfTI binary arrays, plus surface formats described in the [format guide](docs/compatibility/Surface_Format_Support.md).
- Split views support suitable disconnected hemisphere components with local medial crossings of X=0. FreeSurfer geometry/map guidance is included; direct annotation import is not implied.
- Volume-to-surface mapping, smoothed atlas ROI visualization and uncorrected P-value thresholds from supported statistical metadata, with cluster-size filtering.
- AAL and Brodmann information displayed by Inspect as labels in the main canvas for appropriate MNI-space inputs.
- Viridis, Plasma, Inferno, Magma and Cividis palettes, colormap dropdowns and custom RGB editing. Matplotlib reference-table attribution and license are retained.
- Scene JSON, reusable display presets and reviewed legacy-configuration migration.
- Fixed column-oriented migration-report field appends for fixed-range and custom legacy edge colors.
- Surface conversion, subdivision, merging and boundary output. Merge Surfaces automatically reviews inputs, permits blank space/units/note without a verification checkbox, and does not perform registration.
- Focused rendering optimizations; measured performance depends on data, hardware and the operation, not universal GPU acceleration.

### Export, resources and documentation

- PNG, JPEG, TIFF, BMP, PDF and SVG exports with provenance records, plus documented camera-animation export.
- Transparent PNG/TIFF fallback uses matched black/white renders when alpha is flattened, preserving black, white and translucent objects without color-key deletion.
- Original 12-surface library and retained historical templates with resource notices.
- Updated AAL3v2, Glasser360, Power264, Shen278 and Schaefer 100/200/400 node/edge examples, with corresponding atlas volumes/labels. Updated connections derive from resting-state fMRI data from a group of adult healthy participants; module colors and strength-based node sizes are documented. No example Scene JSON is distributed.
- Real-data bilingual tutorials and a 41-page English Word/PDF manual covering the workflow, settings, Inspect, export and utilities. Resource credits accompany the examples.

### Compatibility and limitations

- Validation includes Windows MATLAB R2025a Update 1 regression and targeted follow-up, focused Windows R2024b Update 1 checks and macOS R2024a team workflow checks; not every configuration is certified.
- MATLAB must be installed and activated. Standalone executables, MATLAB Runtime-only use, Linux and browser/Docker deployment are not certified; fiber-tract rendering and Python are not included in this MATLAB beta.
- Paired .hdr/.img inputs must be NIfTI, not plain Analyze 7.5. Statistical thresholds require valid metadata and do not provide multiple-comparison correction.
- Inspect and mesh tools do not establish registration. Check coordinates, units, atlas correspondence and scientific interpretation for each dataset.
- Complete legacy feature equivalence, pixel-identical historical output, EPS/EMF, arbitrary Plot Edit and application-integrated printing are not promised. Exact-size vector export has documented limitations on older MATLAB releases.
- Software code is GPL-3.0; third-party resources retain their own notices, terms and citations. See the [manual](docs/manual/en/index.md) and [migration guide](docs/documentation/Migration.en.md) for detailed scope.
