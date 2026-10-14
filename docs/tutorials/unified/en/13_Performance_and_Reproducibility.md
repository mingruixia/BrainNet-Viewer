# Performance and reproducible figures

Identify which part of a visualization takes time, compare equivalent work, and retain enough information to recreate a figure. Numerical mapping, graphics drawing and file encoding are separate operations. This lesson explains their measurement; it does not supply a new benchmark or promise a universal speedup.

## Prepare a controlled real-data example

Follow [lesson 06](06_Statistical_Volume_to_Surface.md) with the real PCC one-sample connectivity T map and an exactly identified ICBM152 mesh. This is not a patient-versus-control contrast. Save your own same-edition Scene using [lesson 03](03_Scenes_and_Presets.md); no prebuilt Scene is supplied here.

For a local mapping comparison, choose algorithm **5, Trilinear**, four views, a fixed threshold and palette, and explicit output dimensions. Record whether you use the original or smoothed mesh. Do not change the algorithm, input geometry, threshold, camera, quality or output size between runs and then attribute the difference solely to hardware.

## Separate the processing stages

| Stage | What to record |
| --- | --- |
| File loading | Reading and validating inputs, including decompression where applicable |
| Numeric preparation | Thresholding, volume sampling, smoothing and prepared geometry; cache state |
| Graphics drawing | Construction and drawing of the requested views at a fixed canvas size |
| Figure or movie export | Output pixel size, annotations, encoding and file writing |

Timing the whole CLI command includes more than drawing. Timing an already prepared renderer excludes loading and preparation. State that boundary explicitly. Record first-run and warmed measurements separately, keep individual timings, and use the same number of repetitions. A fresh renderer in an existing process is not a fresh application/operating-system start.

For an informal local check, use three repeated runs under similar machine load and summarize the median alongside all three values. For formal performance claims, predefine representative datasets, repetition counts, uncertainty estimates and comparison baselines; three local timings alone are not a cross-platform study.

## Understand edition-specific acceleration

**MATLAB Desktop:** numerical volume mapping supports CPU execution for algorithms 1–8. The current GPU mapping path supports algorithms 1 and 5; unsupported algorithm requests fall back to CPU with a recorded reason. Auto selection is conditional on operation, input size and supported GPU availability. Inspect the effective backend, not just the requested setting. The [CLI lesson](10_Command_Line_Scene_Replay.md) shows explicit `ComputeBackend="cpu"` and `PerformanceMode="quality"` for a repeatable starting point.

Interactive simplification and publication-quality rendering are not equivalent workloads. Compare the same quality mode, and review full-quality outputs before publication. Numerical GPU mapping does not imply GPU acceleration of every graphics, ROI or export operation. CPU vectorization does not imply a running parallel pool or saturation of every logical processor.

**Python Desktop:** current numerical mapping uses NumPy/SciPy on the CPU. VTK/PyVista graphics rendering is a separate layer; its actual graphics backend depends on the environment. A GPU model in the footer is not proof of GPU volume mapping. The Python CLI has no MATLAB-style ComputeBackend option. Do not transfer MATLAB kernel timings or quality-mode controls to Python.

GPU setup and transfers can outweigh a small operation's savings. If acceleration is unavailable, record the reason and CPU fallback, not a fictitious zero-second GPU measurement. Avoid claiming all-core utilization or GPU video encoding without measurements of the relevant operation.

## Read the historical MATLAB measurement correctly

The existing [focused sample record](../../assets/performance/tutorial13-real-pcc-r2025a-public.json) describes one historical MATLAB R2025a Update 1 / Windows 64-bit run on an AMD Ryzen Threadripper 3970X and NVIDIA GeForce RTX 3080 Ti. It used the smoothed ICBM152 mesh, the real PCC map and algorithm 5. Its saved Scene settings are not assumed to match your new exercise.

| Historical measurement | Sample result | Scope |
| --- | --- | --- |
| Three CPU quality draws | 6.659, 2.180, 1.930 s; median 2.180 s | Four views, 960 × 720 target; fresh renderer per trial, no geometry-cache hits; loading/preparation and image-file export excluded |
| Warm trilinear CPU mapping | Median 0.0207873 s | Numerical mapping kernel only |
| Warm trilinear GPU mapping | Median 0.008836 s | Same kernel/input on the recorded GPU; CPU/GPU median ratio approximately 2.35 |
| CPU–GPU mapped-value comparison | Maximum absolute difference 0 | This exact local input and operation only |

The ratio describes this MATLAB mapping kernel only, not full-scene rendering or Python performance. Mapping timings were taken after warm-up. The first draw includes startup costs, and process, JIT and graphics caches may persist between trials. The benchmark script is not distributed; use these measurements as a reference for this run rather than as a prediction for another installation.

## Preserve a reproducible figure

Keep the input files and their identities, applied settings, layout/cameras, software edition/version, OS, relevant libraries/drivers, effective backend and export dimensions together. Use [lesson 10](10_Command_Line_Scene_Replay.md) to replay your own Scene with explicit units and DPI, then inspect the image and its provenance record. For animations, follow [lesson 12](12_Camera_Animation.md).

Preserve MATLAB's configured input root or Python's JSON/companion-assets bundle. A preset alone does not retain that complete session. Input hashes identify bytes; they do not establish registration, anatomical correspondence or scientific validity. An image hash identifies one particular output file, not equivalence across graphics drivers.

Compare numeric values and settings before comparing raster pixels. If a backend comparison changes values, report the discrepancy rather than claiming acceleration based on timing alone. For cross-edition comparisons, also check coordinate conventions, mapping/smoothing rules and camera restoration status. Do not assume arbitrary Scene interchange or pixel identity.

Review provenance for private paths, filenames, titles and metadata before sharing. Keep scientific-source attribution, including the PCC-data reference in lesson 06 and Prof. Alan C. Evans/MNI surface credit. The records are not digital signatures or validation of a statistical inference.

## Troubleshoot without changing the scientific question

If an input hash changes, find the changed file rather than bypassing validation. If timing varies, check competing machine load, first-run effects, cache state, canvas/output dimensions and which stages were included. Reducing selected edges or using a simpler layout can help exploration, but changes the displayed workload and is not an equivalent benchmark.

A mapping algorithm change is a display-method change, not merely a performance switch. Keep the scientific inputs intact and report exactly what changed. Use the checklist to record the data, parameters and environment for each measurement.
