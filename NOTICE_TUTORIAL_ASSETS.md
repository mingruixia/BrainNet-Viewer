# BrainNet Viewer tutorial assets / BrainNet Viewer 教程资源

This notice applies only to the ten exact files and SHA-256 hashes below. The project owner confirmed their redistribution for BrainNet Viewer teaching. Keep this notice with any package containing them. This confirmation does not cover other files in the same directories, establish an independently archived upstream license, or validate anatomical registration.

本说明仅适用于下表十份确切文件及其 SHA-256。项目负责人确认其可用于 BrainNet Viewer 教学分发。任何包含这些文件的包均应保留本说明。该确认不涵盖同目录其他文件，不等于上游许可证已独立归档，也不证明解剖配准正确。

| Package-relative file / 包内相对路径 | SHA-256 | Attribution / 署名 |
|---|---|---|
| `src/matlab/BrainNetViewer/Data/SurfTemplate/BrainMesh_ICBM152.nv` | `471e43f955a1cb9f0350aaca2822f02fc74e393718d1e385fddaf0e578ffe572` | Surface provided by **Prof. Alan C. Evans (MNI)**. / 曲面由 Evans 教授（MNI）提供。 |
| `src/matlab/BrainNetViewer/Data/SurfTemplate/BrainMesh_ICBM152_smoothed.nv` | `aff1920baef51956971b8c1de068e8eee2d1279f21fc90452bcd0dba2794fdc5` | Owner-confirmed smoothed derivative of the Evans/MNI surface; retain that provider credit. / 据负责人说明，为上述曲面平滑版，保留 Evans/MNI 来源署名。 |
| `src/matlab/BrainNetViewer/Data/Tutorials/Tutorial02_ICBM152_Vertex_Nodes.node` | `e1c7660ee039a2d6142881c28cfaea597941dc714e718f92d1d5a2b42f08fcc5` | Project-created eight-node teaching table using exact vertices of the original ICBM152 surface. / 项目自制八节点教学表，坐标取自原版曲面顶点。 |
| `src/matlab/BrainNetViewer/Data/Tutorials/Tutorial03_Illustrative_Directed8.edge` | `4260badaace588975c79da3b4bad6727bed9ea7e8c289426ac7f163e443f9c00` | Project-created directed matrix with invented weights, paired with the eight-node order. / 项目自制有向矩阵，权重为演示编造值，须配合上述节点顺序。 |
| `src/matlab/BrainNetViewer/Data/ExampleFiles/AAL90/icbm_vertex_AAL_label.txt` | `7cd6b8aa19c2aae6161015d62d22770a1fdfdf61d7e29354e8174dbd7853d131` | Owner-identified MNI-derived AAL vertex labels. Cite Tzourio-Mazoyer et al. (2002); pair with the pinned smoothed surface. / 据负责人说明，为 MNI 来源的 AAL 顶点标签；引用 Tzourio-Mazoyer 等（2002），配合确切平滑曲面。 |
| `src/matlab/BrainNetViewer/Data/ExampleFiles/AAL90/aal.nii` | `2926fcc98efc709f77c8cca2f9c1d797eba3e9a1b222a8e0cfa70ab131394c80` | Historical AAL-derived MNI volume. Cite Tzourio-Mazoyer et al. (2002) and credit Neurofunctional Imaging Group (GIN) / MNI. / 历史 AAL 衍生 MNI 图谱体；引用 Tzourio-Mazoyer 等（2002），注明 GIN/MNI 来源。 |
| `src/matlab/BrainNetViewer/Data/Tutorials/OneSample_ROI11_NC.nii` | `e27d9eca7e20f31ed090e410fdb5b4a409565c2fafc3bc86dff21277e58aad5f` | Owner-supplied PCC-subregion-seeded one-sample connectivity T map. Cite Xia et al. (2014). / 负责人提供的 PCC 亚区种子单样本功能连接 T 图；引用 Xia 等（2014）。 |
| `docs/tutorials/assets/scenes/tutorial08-pcc-four-view.scene.json` | `7d0c9b11c734f8297235d000927d2fab28301176106683d729e2e20bba439ab0` | App-generated Scene with relative references to the exact smoothed surface and T map; no input data embedded. / App 生成的 Scene，仅以相对路径引用确切平滑曲面及 T 图，不内嵌数据。 |
| `docs/tutorials/assets/presets/tutorial09-pcc-diverging.preset.json` | `27f9037f5f50de4f24a4e2ce3edbc3a94cd69e498e7f9088a28b667bfcd7fad8` | App-generated display preset; reassess its threshold and layout before applying to different data. / App 生成的显示预设；应用到其他数据前须复核阈值与布局。 |
| `docs/tutorials/assets/tutorial09-pcc-diverging.colormap.json` | `b2d82b6fa3e65068ebfb394d86bd8daff27b29b69901e42bd31f39f77479e092` | Project-created five-row RGB teaching palette. / 项目自制五行 RGB 教学色表。 |

Both meshes have 81,924 vertices and 163,840 faces and share face indexing, but their coordinates differ. Their coordinate transform, units and registration were not independently validated here. The AAL vertex table has 81,924 labels, with only 78 positive IDs present; “AAL90” does not imply that all 90 regions occur. The exact historical upstream AAL archive/license, vertex projection method and smoothing transform have not been archived. Do not silently replace these inputs with newer atlas or surface files. The T map header records T with 37 degrees of freedom; it is **not** an Alzheimer's-versus-control group contrast. The tutorial's voxelwise P threshold is uncorrected and is not a vertex-level test or multiple-comparison correction. The nodes and edges are illustrative, not atlas centroids, measured connectivity or tractography. A Scene or preset does not establish registration.

两份曲面均为 81,924 顶点、163,840 面，面索引相同但坐标不同；其坐标变换、单位与配准尚未在此独立验证。AAL 顶点表有 81,924 个标签值，仅出现 78 个正编号；“AAL90”不表示本曲面出现全部 90 个区。历史 AAL 上游确切归档/许可证、顶点投影方法和平滑变换尚未留存，不能静默替换为新版图谱或曲面。T 图头文件记录自由度 37 的 T 统计量，**不是** AD 与对照组的组间差异图；教程的体素级 P 阈值未经校正，不代表顶点级检验或多重比较校正。节点与连边仅供演示，不是图谱质心、实测连接或纤维束。Scene 与预设不证明配准。

References / 参考文献：

- Tzourio-Mazoyer N et al. (2002). Automated anatomical labeling of activations in SPM using a macroscopic anatomical parcellation of the MNI MRI single-subject brain. *NeuroImage* 15:273–289.
- Xia M, Wang Z, Dai Z, Liang X, Song H, Shu N, Li K, He Y (2014). Differentially disrupted functional connectivity in posteromedial cortical subregions in Alzheimer's disease. *Journal of Alzheimer's Disease* 39:527–543. The included file is a one-sample teaching map, not the article's between-group contrast. / 附带文件是单样本教学图，不是论文中的组间对比。

This notice does not cover the documentation screenshots, Inspect lookup MAT files or other application resources. The full set of historical surfaces has a [separate notice](NOTICE_SURFACE_TEMPLATES.md); the bundled Inspect MATs have an [atlas notice](NOTICE_INSPECT_ATLASES.md). / 本说明不覆盖文档截图、Inspect 查表 MAT 文件或软件其他资源；历史曲面全集另有[独立说明](NOTICE_SURFACE_TEMPLATES.md)，内置 Inspect MAT 另有[图谱说明](NOTICE_INSPECT_ATLASES.md)。
