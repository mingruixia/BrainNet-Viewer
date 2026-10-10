# Figure and camera-movie export

[中文](../zh-CN/M12_Export.md) · [Manual index](index.md) · [Illustrated figure export](../../tutorials/en/07_Layout_and_Publication_Export.md) · [Real-surface animation tutorial](../../tutorials/en/12_Camera_Animation.md) · [Animation details](../../documentation/Movies.en.md) · [Background limitations](../../documentation/Backgrounds.en.md)

Export requires a currently rendered Scene; a loaded but unrendered Scene cannot be exported. Export is an output operation, not a change to the scientific data or applied settings.

## Export a still figure

After loading, configuring and rendering, use **Export Figure** below Data Sources. Select the format and size, then click the button and choose a file. The current panel defaults are **PNG**, **300 DPI**, **1600 × 1200**, **Pixels**, **Automatic** content and **White** background. These are export-panel defaults, distinct from the `image` settings section in a visualization preset.

| Control | Current choices and meaning |
|---|---|
| **Format** | PNG, JPEG, TIFF, BMP, PDF or SVG. Raster formats produce pixels; PDF/SVG do not guarantee editable vector 3-D content. |
| **DPI**, **Width**, **Height**, **Units** | Positive DPI and dimensions; units are Pixels, Inches, Centimeters or Points. Set the target's intended physical size and resolution before saving; inspect the actual output dimensions. |
| **Content** | Automatic or Image in the current desktop panel. Image forces raster content; Automatic may rasterize complex 3-D graphics. Do not assume a PDF/SVG is vector-only. |
| **Background** | White, Black or Transparent (Experimental). JPEG/BMP cannot be transparent. PNG/TIFF use native alpha when available; when MATLAB flattens transparency, matched black/white renders recover alpha without color-keying away black or white objects. Export metadata records the method. Check the result in the intended downstream software. |

The file chooser may replace the selected output; choose a new path if an existing file must be preserved. A successful export writes the figure **and** a neighboring `.provenance.json` sidecar with Scene/renderer/export information. Review that JSON and any absolute input paths or titles before sharing. Output preferences are part of an App-saved Scene session, but loading a display preset does not change them. The interface Light/Dark theme is not the figure background.

## Export a camera animation

Render first and adjust the canvas camera, then choose **Export Animation** in Tools. The animation dialog exports the current static scene into a **new folder**; it does not animate changing connectivity or edit the main canvas/camera. Its defaults are **960 × 720 pixels**, **5 seconds**, **24 fps**, world **Z** axis, **0°→360°**, and **Safe Fit on**. Available formats are MP4 when MATLAB's MPEG-4 profile exists, Motion JPEG AVI, and PNG frame sequence. Choose **Export...** and a new folder name under an existing parent; existing bundle paths are never overwritten.

**Safe Fit** centers and orthographically frames geometry across the orbit on a private rendering copy; disable it only if preserving current framing matters more than possible cropping. Angles are offsets from the current camera around the chosen world X/Y/Z axis. A full turn omits its duplicated endpoint. Frame count is `round(duration × fps)`, so effective duration may differ slightly. Export speed is not playback speed; no GPU video-encoder claim is made. The dialog's **Cancel Export** takes effect after the current frame/codec operation; partial output is cleaned up.

The new folder contains `movie.mp4` or `movie.avi`, or `frame-000001.png` etc., plus `preview.png` and `provenance.json`. The latter can contain Scene references, input metadata, cameras and per-frame records; source inputs are **not** copied. Limits: 128–3840 pixels per dimension, 1–60 fps, 2–1800 frames, at most 120 requested seconds, one billion total frame-pixels, and a nonzero orbit no greater than 360°. Video dimensions must be even; there is no transparent movie or audio. Codec availability and pixel-identical results across platforms are not guaranteed. See the [animation guide](../../documentation/Movies.en.md) for API and verification details.
