# Interface theme, canvas and export backgrounds

development build · Development build · 2026-09-20

- **Theme / Light / Dark** styles the interface, not the scientific canvas. Switching
  theme must not change the rendered background, Scene settings or camera.
- Choose the canvas color with **Visualization Settings → Global → Background Color → Choose Color**,
  then **Apply** to commit and render. The same Scene color is used by embedded and
  pop-out rendering. **Render Scene** can explicitly redraw; Revert discards pending edits.
- App export defaults to **current**: use the rendered target's exact RGB, including
  custom colors. CLI export also honors saved Scene export preferences; without
  saved preferences its default is current. This is not a black/white approximation.
- `app.configureExport(BackgroundColor="current")` restores this policy after an
  explicit white/black override. `white`, `black` and `none` remain supported.
  The Transparent checkbox selects none without changing the canvas; turning it
  off returns to the previous opaque policy. JPEG/BMP cannot be transparent.
  On this R2025a backend PNG/TIFF transparency is replaced with white by MATLAB;
  the exporter now detects missing alpha and rejects the export without replacing
  an existing image or sidecar. Transparency is not certified for every format.
- Scene save/reload retains the policy. Previously saved explicit white/black
  preferences remain explicit: the software cannot infer whether an older build
  chose them automatically. Set current explicitly if that is your intention.
- Export overrides never recolor the live canvas or reset the camera. Provenance
  retains `background_color` (requested policy) and adds `background_color_resolved`
  (RGB, or `none`). The low-level FigureExporter API retains its historical white
  default; pass current explicitly when calling it directly.

Focused verification covers custom-RGB embedded/window rendering, App/CLI replay,
PNG/TIFF/BMP backgrounds, explicit white/black and safe rejection of unsupported raster transparency. It does not
certify every vector format, all DPI environments, or annotation contrast against
an overridden background; check exported labels before publication. No schema
version change or new export-background panel is introduced.
