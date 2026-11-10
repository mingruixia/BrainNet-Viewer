# Third-party notices / 第三方声明

Code licence: [GPL-3.0-or-later](LICENSE). The following notices retain their original attribution and resource terms. / 以下汇总保留来源署名、资源条款及许可证原文。

<a id="notice-1"></a>

## NOTICE_CODE.md

# BrainNet Viewer code licence and attribution

The BrainNet Viewer project code is distributed under the GNU General Public License, version 3.0 or, at your option, any later version (SPDX: GPL-3.0-or-later). The complete licence text is in [`LICENSE`](LICENSE). Source changes and their dates are summarized in `CHANGELOG.md` and `CHANGELOG.zh-CN.md`.

The historical code identifies Mingrui Xia and Beijing Normal University; the software-copyright certificate for BrainNet Viewer V1.1 records Beijing Normal University as registrant. The original scientific publication is Xia M, Wang J, He Y (2013), *PLoS ONE* 8:e68910, https://doi.org/10.1371/journal.pone.0068910. Scientific authorship, copyright ownership, and individual code contributions are distinct; this notice does not reassign any rights.

**Applies to:** GPL-3.0-or-later applies to the project code. It does not automatically relicense included or user-supplied atlases, meshes, sample data, images, fonts, manuals, or other third-party materials. Each resource must retain its own applicable terms and attribution. In particular, a GPL program may import a Brainnetome atlas obtained separately under the Brainnetome Center's terms; that does not put the atlas under GPL or remove its non-commercial conditions. See `NOTICE_TUTORIAL_ASSETS.md` for the included teaching inputs and the final package's resource manifest for everything actually included.

The `viridis`, `plasma`, `inferno`, `magma`, and `cividis` RGB lookup tables in `brainnet.core.scientificColormap` reproduce the 256-entry tables from Matplotlib 3.10.0 (`lib/matplotlib/_cm_listed.py`). Copyright (c) 2012- Matplotlib Development Team; All Rights Reserved. Their source licence is retained in [`LICENSE_MATPLOTLIB_COLORMAPS.txt`](#notice-7); the BrainNet Viewer GPL-3.0-or-later licence does not remove that notice.


Python/Web annotation fonts are distributed under SIL Open Font License 1.1,
not the code's GPL licence. The modified BrainNet Sans family combines Noto
Sans SC and complementary Noto Sans glyphs; attribution, source identities and
both OFL notices are retained in
[font notices](src/python/brainnet_viewer/resources/fonts/NOTICE.txt).

No trademark licence, warranty, scientific-validity guarantee, or blanket permission for external datasets is granted by this notice. The GPL text's own disclaimer and conditions govern the code.


<a id="notice-2"></a>

## NOTICE_ATLAS_NETWORK_EXAMPLES.md

# Atlas network examples

`Data/ExampleFiles/AtlasNetworks/` provides fourteen matched GroupFC node/edge pairs and the AAL90 examples. GroupFC connectivity matrices were generated from a group of healthy adults' resting-state fMRI data. These are visualization examples, not normative connectivity estimates. Node sizes represent absolute connection strength; node colors represent Yeo seven-network assignments for Schaefer or data-derived communities for the other GroupFC examples. Use Modular colors and Mapped sizes to display these fields. Keep node coordinates and paired row orders unchanged.

| Example family | Atlas source / citation |
|---|---|
| AAL90 / AAL116 | Tzourio-Mazoyer et al. (2002), NeuroImage 15:273–289; [AAL project](https://www.gin.cnrs.fr/fr/outils/aal/) |
| AAL3v2 | [AAL project](https://www.gin.cnrs.fr/fr/outils/aal/) |
| Brodmann82 / Dos160 / Fair34 / HOA112 | Accompanying `*_Reference.txt` files; [GRETNA atlas distribution](https://github.com/sandywang/GRETNA) |
| Brainnetome246 | Fan et al. (2016), Cerebral Cortex 26:3508–3526; [Brainnetome atlas](https://atlas.brainnetome.org/) |
| Glasser360 | [AFNI HCP-MMP/Glasser distribution](https://afni.nimh.nih.gov/pub/dist/atlases/MNI_HCP/MNI_Glasser_HCP_2019_v1.0/) |
| Power264 | [Power264 resource](https://github.com/brainspaces/power264) |
| Shen278 | [Shen atlas distribution](https://www.nitrc.org/frs/download.php/5785/shenetal_neuroimage2013_funcatlas.zip) |
| Schaefer100/200/400/1000Yeo7 | [Schaefer atlas and Yeo labels](https://github.com/ThomasYeoLab/CBIG/tree/master/stable_projects/brain_parcellation/Schaefer2018_LocalGlobal/Parcellations/MNI) |

Source atlas volumes are separate from example connectivity. The repository and MATLAB archive contain `resources/atlases/`: AAL90 support files, AAL3v2, Glasser360, Power264, Shen278, and the four Schaefer resolutions with LUTs and source/license notices. Python and Docker contain the node/edge library and AAL90 support files; the other source volumes are available in the source archive.

`AAL3v2.nii.gz` and `AAL3v2_labels.txt` are readable aliases for the files distributed in the AAL3v2 archive with AAL3v1 names. `Shen278_2mm.nii` is an alias for `fconn_atlas_150_2mm.nii`; 278 describes its represented labels. Renaming does not change voxels, label values, affine transforms, or atlas revision. The accompanying source-name record preserves the original names.

Atlas-derived node positions are not exact surface parcel boundaries. A display mesh provides context and does not establish registration. AAL90 retains its supplied example weights and is not relabeled as GroupFC. No Scene JSON is bundled for these examples.


<a id="notice-3"></a>

## NOTICE_NETWORK_EXAMPLES.md

# Network example files

`Data/ExampleFiles/AtlasNetworks/` contains matched atlas node/edge pairs. Its README lists all files and region counts. GroupFC node sizes represent absolute connection strength; colors represent network modules. The example matrices were generated from a group of healthy adults' resting-state fMRI data. AAL90 retains its supplied node and binary/weighted edge examples.

AAL90 auxiliary volumes, vertex labels and masks are separate in `resources/atlases/AAL90/` (repository/MATLAB archive) or `atlases/AAL90/` (Python/Docker resource library). Vertex maps require the corresponding surface vertex order. AAL90 IDs are not AAL3v2 IDs. Use AAL90 for the node/edge tutorials; AAL116 now has its own matched GroupFC edge matrix.

See `NOTICE_ATLAS_NETWORK_EXAMPLES.md` and the reference files for citations. Successful loading does not establish registration or statistical validity.


<a id="notice-4"></a>

## NOTICE_INSPECT_ATLASES.md

# BrainNet Viewer 2.0 bundled Inspect atlases / 内置 Inspect 图谱说明

BrainNet Viewer includes the AAL and Brodmann lookup files listed below. Keep this attribution with these files. The software licence does not change the terms of atlas data.

BrainNet Viewer包含下列AAL和Brodmann查表文件，分发时保留来源署名。软件许可证不改变图谱数据的适用条款。

| Package-relative file | SHA-256 | Source and citation |
|---|---|---|
| `src/matlab/BrainNetViewer/BrainNet_AAL_Label.mat` | `1fe217ef443cff395884e3c5f672891085cb10858a028048b454d02591316ec9` | Historical AAL lookup derived from an AAL NIfTI. Cite Tzourio-Mazoyer et al. (2002), *NeuroImage* 15:273–289; credit the Neurofunctional Imaging Group (GIN) and MNI. |
| `src/matlab/BrainNetViewer/BrainNet_Brodmann_Label.mat` | `ed057cd513391e3aefae46e4ade5dea5b23b72da5b7cdb0064b7ebb44f347f8e` | Historical Brodmann-area lookup derived from the `brodmann.nii` distributed with MRIcroN; credit MRIcroN/Chris Rorden for that distribution and cite Brodmann's original anatomical work as relevant. |

The two numeric volumes were compared in full against matching historical NIfTI files: both contain 181×217×181 voxels with zero differing values, and their one-based MAT affines correspond to the NIfTI sforms. AAL contains 116 positive region IDs; the Brodmann image contains 41 positive IDs.

These are **direct coordinate lookups**, not subject-to-template registration. They should be used only when the displayed data are in the corresponding MNI-like space; no anatomical label is guaranteed for an arbitrary subject-space image. The Brodmann volume is a historical digitized approximation, not cytoarchitectonic ground truth. Its regional assignments have been questioned in the [R-fMRI Network discussion](https://rfmri.org/content/different-brodmann-atlas-dpabi-and-rest). Do not use these labels for diagnosis or treat a displayed boundary as precise histology.

两份数值体数据均与对应历史 NIfTI 进行了全体素比较，181×217×181 个体素均无差异，MAT 的一基坐标仿射与 NIfTI 的零基 sform 对应。AAL 含 116 个正标签编号，Brodmann 含 41 个。本功能只做坐标直接查表，不执行个体图像到标准空间的配准；仅适用于空间已匹配的数据。Brodmann 图是历史数字化近似图谱，不是精确的细胞构筑边界，也不应用于诊断。

This notice records provenance and limitations for these exact files. It does not confer rights to other atlas, surface, node or edge resources in the package.


<a id="notice-5"></a>

## NOTICE_SURFACE_TEMPLATES.md

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


<a id="notice-6"></a>

## NOTICE_TUTORIAL_ASSETS.md

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

This notice does not cover the documentation screenshots, Inspect lookup MAT files or other application resources. The full set of historical surfaces has a [separate notice](#notice-5); the bundled Inspect MATs have an [atlas notice](#notice-4). / 本说明不覆盖文档截图、Inspect 查表 MAT 文件或软件其他资源；历史曲面全集另有[独立说明](#notice-5)，内置 Inspect MAT 另有[图谱说明](#notice-4)。


<a id="notice-7"></a>

## LICENSE_MATPLOTLIB_COLORMAPS.txt

License agreement for matplotlib versions 1.3.0 and later
=========================================================

1. This LICENSE AGREEMENT is between the Matplotlib Development Team
("MDT"), and the Individual or Organization ("Licensee") accessing and
otherwise using matplotlib software in source or binary form and its
associated documentation.
2. Subject to the terms and conditions of this License Agreement, MDT
hereby grants Licensee a nonexclusive, royalty-free, world-wide license
to reproduce, analyze, test, perform and/or display publicly, prepare
derivative works, distribute, and otherwise use matplotlib
alone or in any derivative version, provided, however, that MDT's
License Agreement and MDT's notice of copyright, i.e., "Copyright (c)
2012- Matplotlib Development Team; All Rights Reserved" are retained in
matplotlib  alone or in any derivative version prepared by
Licensee.
3. In the event Licensee prepares a derivative work that is based on or
incorporates matplotlib or any part thereof, and wants to
make the derivative work available to others as provided herein, then
Licensee hereby agrees to include in any such work a brief summary of
the changes made to matplotlib .
4. MDT is making matplotlib available to Licensee on an "AS
IS" basis.  MDT MAKES NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR
IMPLIED.  BY WAY OF EXAMPLE, BUT NOT LIMITATION, MDT MAKES NO AND
DISCLAIMS ANY REPRESENTATION OR WARRANTY OF MERCHANTABILITY OR FITNESS
FOR ANY PARTICULAR PURPOSE OR THAT THE USE OF MATPLOTLIB
WILL NOT INFRINGE ANY THIRD PARTY RIGHTS.
5. MDT SHALL NOT BE LIABLE TO LICENSEE OR ANY OTHER USERS OF MATPLOTLIB
 FOR ANY INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES OR
LOSS AS A RESULT OF MODIFYING, DISTRIBUTING, OR OTHERWISE USING
MATPLOTLIB , OR ANY DERIVATIVE THEREOF, EVEN IF ADVISED OF
THE POSSIBILITY THEREOF.

6. This License Agreement will automatically terminate upon a material
breach of its terms and conditions.
7. Nothing in this License Agreement shall be deemed to create any
relationship of agency, partnership, or joint venture between MDT and
Licensee.  This License Agreement does not grant permission to use MDT
trademarks or trade name in a trademark sense to endorse or promote
products or services of Licensee, or any third party.

8. By copying, installing or otherwise using matplotlib ,
Licensee agrees to be bound by the terms and conditions of this License
Agreement.
License agreement for matplotlib versions prior to 1.3.0
========================================================

1. This LICENSE AGREEMENT is between John D. Hunter ("JDH"), and the
Individual or Organization ("Licensee") accessing and otherwise using
matplotlib software in source or binary form and its associated
documentation.
2. Subject to the terms and conditions of this License Agreement, JDH
hereby grants Licensee a nonexclusive, royalty-free, world-wide license
to reproduce, analyze, test, perform and/or display publicly, prepare
derivative works, distribute, and otherwise use matplotlib
alone or in any derivative version, provided, however, that JDH's
License Agreement and JDH's notice of copyright, i.e., "Copyright (c)
2002-2011 John D. Hunter; All Rights Reserved" are retained in
matplotlib  alone or in any derivative version prepared by
Licensee.
3. In the event Licensee prepares a derivative work that is based on or
incorporates matplotlib  or any part thereof, and wants to
make the derivative work available to others as provided herein, then
Licensee hereby agrees to include in any such work a brief summary of
the changes made to matplotlib.
4. JDH is making matplotlib  available to Licensee on an "AS
IS" basis.  JDH MAKES NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR
IMPLIED.  BY WAY OF EXAMPLE, BUT NOT LIMITATION, JDH MAKES NO AND
DISCLAIMS ANY REPRESENTATION OR WARRANTY OF MERCHANTABILITY OR FITNESS
FOR ANY PARTICULAR PURPOSE OR THAT THE USE OF MATPLOTLIB
WILL NOT INFRINGE ANY THIRD PARTY RIGHTS.
5. JDH SHALL NOT BE LIABLE TO LICENSEE OR ANY OTHER USERS OF MATPLOTLIB
 FOR ANY INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES OR
LOSS AS A RESULT OF MODIFYING, DISTRIBUTING, OR OTHERWISE USING
MATPLOTLIB , OR ANY DERIVATIVE THEREOF, EVEN IF ADVISED OF
THE POSSIBILITY THEREOF.

6. This License Agreement will automatically terminate upon a material
breach of its terms and conditions.
7. Nothing in this License Agreement shall be deemed to create any
relationship of agency, partnership, or joint venture between JDH and
Licensee.  This License Agreement does not grant permission to use JDH
trademarks or trade name in a trademark sense to endorse or promote
products or services of Licensee, or any third party.

8. By copying, installing or otherwise using matplotlib,
Licensee agrees to be bound by the terms and conditions of this License
Agreement.


