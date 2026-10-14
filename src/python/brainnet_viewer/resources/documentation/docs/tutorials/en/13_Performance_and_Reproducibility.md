# 13 · Performance and reproducibility with real data

[中文](../zh-CN/13_Performance_and_Reproducibility.md) · [Tutorial index](index.md) · [Command-line/provenance manual](../../manual/en/M14_Batch_Provenance.md) · [Real T-map interpretation](05_Volume_to_Surface_Mapping.md)

This lesson explains how to measure rendering and mapping separately, using the PCC-subregion one-sample connectivity T map and smoothed ICBM152 surface from Tutorials 05 and 08. The [timing record](../assets/performance/tutorial13-real-pcc-r2025a-public.json) contains measurements for this dataset and hardware; it does not predict performance on other installations. The benchmark script is not included. The T map is **not** an Alzheimer's-versus-control contrast. Retain the [data citation](Resource_Attribution.md) and Prof. Alan C. Evans (MNI) surface credit when sharing figures.

## Step 01 · Pin inputs and the execution contract

Use the supplied [four-view Scene](../assets/scenes/tutorial08-pcc-four-view.scene.json), SHA-256 `7d0c9b11c734f8297235d000927d2fab28301176106683d729e2e20bba439ab0`. Its referenced surface SHA-256 is `aff1920baef51956971b8c1de068e8eee2d1279f21fc90452bcd0dba2794fdc5`; NIfTI SHA-256 is `e27d9eca7e20f31ed090e410fdb5b4a409565c2fafc3bc86dff21277e58aad5f`. The Scene's mapped volume uses algorithm **5 (trilinear)** and its saved statistical/visual settings. Do not compare numbers after silently changing input, threshold, layout or mapping method.

The measured environment was **MATLAB R2025a Update 1 / Windows 64-bit**, AMD Ryzen Threadripper 3970X (32 cores, 64 logical processors), NVIDIA GeForce RTX 3080 Ti. For full rendering the contract was **CPU backend, Publication Quality, 960 × 720 target position, four views**. The renderer was newly constructed for each of three trials, with no geometry-cache hit. Data loading and numeric preparation were **excluded** from those render timings. MATLAB JIT/graphics and operating-system caches still persist within the process: these are not three independent MATLAB cold starts. The mapping-kernel CPU/GPU timings were taken **after a warm-up call**.

![Four-view render of the real PCC-subregion T map used in this exercise](../assets/captures/tutorial08-cli/08-pcc-four-view-cli.png)

*The real-data figure is reused from Tutorial 08 to show which Scene is timed. It is not a performance chart and does not imply anatomical registration or new statistical inference.*

## Step 02 · Reproduce the focused measurement

The reported run used a MATLAB benchmark script that is not included. To independently reproduce its method in a source checkout, first obtain the exact authorized Scene, surface and NIfTI and verify the SHA-256 values above. Use the normal loader; prepare twice on CPU with geometry cache disabled, recording coordinate/value fingerprints and the cache key. Create a fresh renderer for each of three CPU Publication Quality draws at 960 × 720, excluding loading, numeric preparation and file export. Warm the algorithm-5 trilinear mapping kernel, then time three CPU calls and, only if available, three GPU calls on the **same input**. Compare CPU/GPU mapped values before comparing medians. Record MATLAB release/update, OS, actual CPU/GPU models, backend status, cache state, individual timings and any GPU failure reason. Keep the resulting report beside input hashes and Scene; do not treat a missing GPU as a zero-second measurement.

The benchmark script is not included. The measurements below describe the recorded run; to repeat them, use a script that measures the same stages with the same inputs and settings.

## Step 03 · Interpret the timing results

The sample JSON records the following measurements on the machine described above:

| Measurement | Observed sample | Scope |
|---|---:|---|
| Three quality CPU renders | 6.659, 2.180, 1.930 s; median **2.180 s** | Each new renderer; data loading/preparation and image-file export excluded. First-trial startup remains visible. |
| Warm trilinear mapping, CPU | median **0.0208 s** | Only algorithm-5 mapping of this real NIfTI to 81,924 surface vertices. |
| Warm trilinear mapping, GPU | median **0.00884 s** | Same mapping kernel on this RTX 3080 Ti; **2.35×** CPU/GPU median ratio for this small local test. |
| CPU–GPU map values | maximum absolute difference **0** | Numerical output for this exact case; not proof that every algorithm, GPU or image is identical. |

The GPU ratio is **not** a full-scene rendering speedup. The GPU path covers supported mapping operations; MATLAB graphics creation/drawing and PNG/video encoding have separate costs. CPU vectorization does not mean that a MATLAB `parpool` was started or that 64 processors were each saturated. On other hardware, the GPU path may be unavailable or slower after setup and transfer overhead. Do not quote this four-view sample as a universal BrainNet Viewer benchmark; for a paper, predefine datasets, repeated-run protocol, hardware, confidence intervals and comparison baselines.

## Step 04 · Preserve a reproducible figure

For publication-quality rerendering of this same Scene, use [Tutorial 08's `BrainNetRender` workflow](08_Command_Line_and_Scene_Replay.md) with `DataRoot` set explicitly, `ComputeBackend="cpu"` and `PerformanceMode="quality"`, then keep the Scene JSON, input hashes, output sidecar, MATLAB/renderer versions and export dimensions together. The sample benchmark records a preparation cache key plus numeric geometry/value fingerprints; the two uncached preparation passes agreed exactly. These hashes establish **file and computed-value identity**, not anatomical alignment or statistical validity. Image pixels and elapsed time can differ across MATLAB versions, drivers, operating systems, thermal states and background load. The report contains hardware labels and hashes, not absolute local paths; still review any exported image sidecar before sharing.

## Failure checks

- **Missing/changed input:** stop and restore the exact data root; do not silence a hash failure.
- **GPU unavailable:** use CPU and record the reason. `ComputeBackend="gpu"` is operation-specific, not a guarantee of GPU rendering.
- **Unexpected timings:** repeat under controlled load, record warm-up and cache state, and distinguish numeric preparation, drawing and export instead of reducing everything to one “render time.”
- **Different image:** compare Scene/input hashes, settings, camera, quality/backend and numeric fingerprints before comparing raster pixels.
