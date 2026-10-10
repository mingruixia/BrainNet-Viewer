# BrainNet Viewer 2.0 surface templates / 曲面模板

The 12 bundled NV surface templates are listed below with their source credits. Keep this attribution with the files. Check coordinate alignment before combining templates with subject data.

附带的12份NV曲面及来源署名列于下表，分发时保留署名。与个体数据叠加前应核对坐标与配准。

All paths in the table start with `src/matlab/BrainNetViewer/Data/SurfTemplate/`.

| File | SHA-256 | Source credit |
|---|---|---|
| `BrainMesh_ICBM152.nv` | `471e43f955a1cb9f0350aaca2822f02fc74e393718d1e385fddaf0e578ffe572` | Surface provided by Prof. Alan C. Evans (MNI). |
| `BrainMesh_ICBM152_smoothed.nv` | `aff1920baef51956971b8c1de068e8eee2d1279f21fc90452bcd0dba2794fdc5` | Smoothed Evans/MNI derivative. |
| `BrainMesh_ICBM152_tal.nv` | `06adff39e0ed7043e6d6d57944bd5a6d8846621b252752a921787afd5731d14d` | Evans/MNI-derived historical Talairach-labelled variant. |
| `BrainMesh_ICBM152_smoothed_tal.nv` | `3faf7cabbaf3a7d93c4fcde6472202a94b95ba8e419da92d9c3c8f9e40c787cc` | Smoothed Evans/MNI-derived historical Talairach-labelled variant. |
| `BrainMesh_ICBM152Left.nv` | `12c37dc6eb02b4bd037ff9783d47a9748ae3541a54a0609da0e703fa189ab061` | Left-hemisphere Evans/MNI derivative. |
| `BrainMesh_ICBM152Left_smoothed.nv` | `0e21eee007d7aa1e7379f47b65d272c885eee8ec4d6809ca1078cb4af0780fea` | Left-hemisphere smoothed Evans/MNI derivative. |
| `BrainMesh_ICBM152Right.nv` | `cd94c0719e1f7f8c1a521147167a2552cc3854bbcd3b9092d0a2c1c947a0aabe` | Right-hemisphere Evans/MNI derivative. |
| `BrainMesh_ICBM152Right_smoothed.nv` | `2422ff0724a6dea9c326f6b866c007ba39eab5ec289bdcf87dcfb854104b441a` | Right-hemisphere smoothed Evans/MNI derivative. |
| `BrainMesh_Ch2.nv` | `6e1f110f8732268f4d2d3ac0de2259a8e9a7dd88836f7c11418cda2f71b9b226` | Historical Colin27/Ch2 mesh prepared with BrainVISA; credit Louis Collins, MNI/McGill and BrainVISA. |
| `BrainMesh_Ch2_smoothed.nv` | `e3b6c7a19dd78584a6294d5f96a96cb0410e826322a9f7826bfde92d5267af70` | Smoothed derivative of the historical Colin27/Ch2 mesh; same source credits. |
| `BrainMesh_Ch2withCerebellum.nv` | `b0f5408c34c064476a80a9ea6944ed525c45782a146dee2383eded3da49d684e` | Historical Ch2-derived mesh with cerebellum; credit Colin27/MNI–McGill and BrainVISA as recorded in the old manual/update log. Its file header instead says MATLAB `isosurface`, so the exact method is not asserted. |
| `BrainMesh_Cerebellum.nv` | `44faea7e04dc4132fc15bbd086d4b78e5dc76b2ea09dbdc17e8f228aee5b54bc` | File header credits **Longfei Su**, College of Mechatronics and Automation, National University of Defense Technology. Preserve this contributor credit. |

The historical [BrainNet Viewer manual](https://www.nitrc.org/docman/view.php/504/77994/BrainNet%20Viewer%20Manual%201.61.pdf) identifies the Ch2 cortical surface as Colin27 and credits BrainVISA conversion. The [McGill BIC Colin27 page](https://www.mcgill.ca/bic/software/tools-data-analysis/anatomical-mri/atlases/colin-27) identifies the original template and Holmes et al. (1998). Those references do not establish a recovered byte-for-byte source mesh or conversion script. `Ch2withCerebellum` is not a simple concatenation of the separate Ch2 and cerebellum files. An old [NITRC forum answer](https://www.nitrc.org/forum/forum.php?forum_id=2178&thread_id=5905) describes a similarly named cerebellum mesh as standard MNI; exact-file identity with this copy was not established. The `tal` filenames are historical space labels, not a fresh validation of their coordinate transform. Verify space and alignment before combining any of these surfaces with subject data, nodes, volumes or Inspect labels.

原版手册将 Ch2 皮层曲面标为 Colin27，并注明 BrainVISA 制作；McGill 页面提供原始模板与 Holmes 等（1998）文献来源。现未找到这些确切曲面的原始网格与转换脚本。`Ch2withCerebellum` 不是另外两份文件的简单合并；独立小脑曲面保留 Longfei Su 署名。`tal` 后缀仅为历史空间标记，不代表已重新验证其变换。与节点、体图或 Inspect 标签叠加前，应核对坐标空间与配准。
