# BrainNet Viewer tutorial assets / BrainNet Viewer 教程资源

The bundled tutorial inputs are listed below with their source credits and file hashes. Retain this attribution when distributing these teaching materials.

下表列出附带教程输入的来源署名与文件校验值，分发教学材料时保留署名。

| Package-relative file / 包内相对路径 | SHA-256 | Attribution / 署名 |
|---|---|---|
| `src/matlab/BrainNetViewer/Data/SurfTemplate/BrainMesh_ICBM152.nv` | `471e43f955a1cb9f0350aaca2822f02fc74e393718d1e385fddaf0e578ffe572` | Surface provided by **Prof. Alan C. Evans (MNI)**. / 曲面由 Evans 教授（MNI）提供。 |
| `src/matlab/BrainNetViewer/Data/SurfTemplate/BrainMesh_ICBM152_smoothed.nv` | `aff1920baef51956971b8c1de068e8eee2d1279f21fc90452bcd0dba2794fdc5` | Smoothed derivative of the Evans/MNI surface; retain that provider credit. / 上述曲面的平滑版，保留 Evans/MNI 来源署名。 |
| `src/matlab/BrainNetViewer/Data/ExampleFiles/AtlasNetworks/AAL90.node` | `2ff2562b55d91f502ee8f3bf86716ea268956391729e502584ca156c2ccdd4ba` | AAL90 matched network example; retain atlas citation Tzourio-Mazoyer et al. (2002). / AAL90配套网络示例，保留图谱引文。 |
| `src/matlab/BrainNetViewer/Data/ExampleFiles/AtlasNetworks/AAL90_Weighted.edge` | `90c7c6a536ca1131e5645d1bde15a347938a96eb9d5f9a3f41a2e17e6504e3d0` | AAL90 matched network example; retain atlas citation Tzourio-Mazoyer et al. (2002). / AAL90配套网络示例，保留图谱引文。 |
| `resources/atlases/AAL90/icbm_vertex_AAL_label.txt` | `7cd6b8aa19c2aae6161015d62d22770a1fdfdf61d7e29354e8174dbd7853d131` | MNI-derived AAL vertex labels. Cite Tzourio-Mazoyer et al. (2002); pair with the pinned smoothed surface. / MNI 来源的 AAL 顶点标签；引用 Tzourio-Mazoyer 等（2002），配合确切平滑曲面。 |
| `resources/atlases/AAL90/aal.nii` | `2926fcc98efc709f77c8cca2f9c1d797eba3e9a1b222a8e0cfa70ab131394c80` | Historical AAL-derived MNI volume. Cite Tzourio-Mazoyer et al. (2002) and credit Neurofunctional Imaging Group (GIN) / MNI. / 历史 AAL 衍生 MNI 图谱体；引用 Tzourio-Mazoyer 等（2002），注明 GIN/MNI 来源。 |
| `src/matlab/BrainNetViewer/Data/Tutorials/OneSample_ROI11_NC.nii` | `e27d9eca7e20f31ed090e410fdb5b4a409565c2fafc3bc86dff21277e58aad5f` | Mingrui Xia supplied PCC-subregion-seeded one-sample connectivity T map. Cite Xia et al. (2014). / Mingrui Xia提供的 PCC 亚区种子单样本功能连接 T 图；引用 Xia 等（2014）。 |

Both meshes have 81,924 vertices and 163,840 faces and share face indexing, but their coordinates differ. Their coordinate transform, units and registration were not independently validated here. The AAL vertex table has 81,924 labels, with only 78 positive IDs present; “AAL90” does not imply that all 90 regions occur. Do not silently replace these inputs with newer atlas or surface files. The T map header records T with 37 degrees of freedom; it is **not** an Alzheimer's-versus-control group contrast. The tutorial's voxelwise P threshold is uncorrected and is not a vertex-level test or multiple-comparison correction. The node/edge lessons use the AAL90 network examples; they do not represent directed axonal connections. A Scene or preset does not establish registration.

两份曲面均为 81,924 顶点、163,840 面，面索引相同但坐标不同；其坐标变换、单位与配准尚未在此独立验证。AAL 顶点表有 81,924 个标签值，仅出现 78 个正编号；“AAL90”不表示本曲面出现全部 90 个区。不能静默替换为新版图谱或曲面。T 图头文件记录自由度 37 的 T 统计量，**不是** AD 与对照组的组间差异图；教程的体素级 P 阈值未经校正，不代表顶点级检验或多重比较校正。节点与连边教程使用AAL90网络示例，不表示轴突方向或纤维束。Scene 与预设不证明配准。

References / 参考文献：

- Tzourio-Mazoyer N et al. (2002). Automated anatomical labeling of activations in SPM using a macroscopic anatomical parcellation of the MNI MRI single-subject brain. *NeuroImage* 15:273–289.
- Xia M, Wang Z, Dai Z, Liang X, Song H, Shu N, Li K, He Y (2014). Differentially disrupted functional connectivity in posteromedial cortical subregions in Alzheimer's disease. *Journal of Alzheimer's Disease* 39:527–543. The included file is a one-sample teaching map, not the article's between-group contrast. / 附带文件是单样本教学图，不是论文中的组间对比。

This notice does not cover the documentation screenshots, Inspect lookup MAT files or other application resources. The full set of historical surfaces has a [separate notice](NOTICE_SURFACE_TEMPLATES.md); the bundled Inspect MATs have an [atlas notice](NOTICE_INSPECT_ATLASES.md). / 本说明不覆盖文档截图、Inspect 查表 MAT 文件或软件其他资源；历史曲面全集另有[独立说明](NOTICE_SURFACE_TEMPLATES.md)，内置 Inspect MAT 另有[图谱说明](NOTICE_INSPECT_ATLASES.md)。
