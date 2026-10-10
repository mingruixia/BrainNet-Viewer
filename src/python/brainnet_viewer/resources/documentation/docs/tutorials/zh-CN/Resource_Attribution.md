# 教程资源署名与使用边界

[English](../en/Resource_Attribution.md) · [教程目录](index.md)

本页介绍教程材料、确切文件哈希、来源署名与解释。资源链接指明练习使用的文件；仅含文档的下载包可能不包含数据。

| `src/matlab/BrainNetViewer/` 下的确切文件 | SHA-256 | 来源及署名 |
|---|---|---|
| `Data/SurfTemplate/BrainMesh_ICBM152.nv` | `471e43f955a1cb9f0350aaca2822f02fc74e393718d1e385fddaf0e578ffe572` | MNI ICBM152 曲面，由 **Prof. Alan C. Evans** 提供；须保留来源署名。 |
| `Data/SurfTemplate/BrainMesh_ICBM152_smoothed.nv` | `aff1920baef51956971b8c1de068e8eee2d1279f21fc90452bcd0dba2794fdc5` | Evans/MNI 曲面的平滑衍生版；须保留原曲面署名。 |
| `Data/ExampleFiles/AtlasNetworks/AAL90.node` | `2ff2562b55d91f502ee8f3bf86716ea268956391729e502584ca156c2ccdd4ba` | AAL90 matched network example; retain atlas citation Tzourio-Mazoyer et al. (2002). / AAL90配套网络示例，保留图谱引文。 |
| `Data/ExampleFiles/AtlasNetworks/AAL90_Weighted.edge` | `90c7c6a536ca1131e5645d1bde15a347938a96eb9d5f9a3f41a2e17e6504e3d0` | AAL90 matched network example; retain atlas citation Tzourio-Mazoyer et al. (2002). / AAL90配套网络示例，保留图谱引文。 |
| `resources/atlases/AAL90/icbm_vertex_AAL_label.txt` | `7cd6b8aa19c2aae6161015d62d22770a1fdfdf61d7e29354e8174dbd7853d131` | MNI 来源的 AAL 顶点标签；须单独引用 Tzourio-Mazoyer 等（2002），不可用 Evans/MNI 曲面署名替代。 |
| `Data/Tutorials/OneSample_ROI11_NC.nii` | `e27d9eca7e20f31ed090e410fdb5b4a409565c2fafc3bc86dff21277e58aad5f` | Xia 等（2014）研究中的 PCC 亚区种子点的单样本功能连接 T 图；引用 Xia 等（2014）。 |
| `resources/atlases/AAL90/aal.nii` | `2926fcc98efc709f77c8cca2f9c1d797eba3e9a1b222a8e0cfa70ab131394c80` | 历史 AAL90 ROI 体图；引用 Tzourio-Mazoyer 等（2002）。 |
| `BrainNet_AAL_Label.mat` | `1fe217ef443cff395884e3c5f672891085cb10858a028048b454d02591316ec9` | 由 NIfTI 制作的 AAL 查询表；完整转换链尚未归档。 |
| `BrainNet_Brodmann_Label.mat` | `ed057cd513391e3aefae46e4ade5dea5b23b72da5b7cdb0064b7ebb44f347f8e` | 由 NIfTI 制作的 Brodmann 查询表；确切上游版本、空间及转换链未独立比对。 |

## ICBM152 曲面

两份曲面均有 81,924 个顶点及 163,840 个三角面；平滑版与原版面片索引相同，但坐标不同。来源模板为 MNI ICBM152；本文**不独立证明**坐标单位、变换、配准精度或解剖标签。它们不是被试扫描。使用每项练习指定的确切曲面版本。

## AAL90节点与连边

教程使用AAL90.node及其配套Weighted/Binary连边矩阵，节点行与矩阵行列一一对应。这些示例与GroupFC库分开，不代表有向纤维连接；保留Tzourio-Mazoyer等（2002）引文。

## AAL 顶点标签

该文件有 81,924 个整数标签，0 表示未标注顶点；这份曲面上实际仅出现 78 个正 ID。“AAL90”文件夹名不证明图中包含全部 90 个脑区。应配合历史原配的 **ICBM152 平滑曲面**使用；顶点索引对应不等于原体到曲面投射或空间配准已被独立验证。确切图谱版本和投射算法尚未归档。ID 是类别，不是统计值。

## PCC 单样本 T 图

这是标准 MNI 空间、PCC 亚区种子点单样本连接图，**不是**阿尔茨海默病组与对照组的差异图。头信息描述自由度 37 的 T 统计量。教程 05 的双侧 `P = 0.001` 是**未经多重比较校正的逐体素**阈值，先于曲面取样；它不是 FWE/FDR 校正或顶点层显著性检验。解剖解释前应独立核对仿射对齐。插值可改变边缘显示值。配套平滑曲面须另保留 Evans/MNI 署名。

## AAL 与 Brodmann 查询表

在这份确切 `aal.nii` 中，29 和 30 分别为左、右岛叶。其历史 AAL90 文件尚未与某一上游压缩包逐字节比对；不能静默替换为新版 AAL。两份 MAT 是 NIfTI 衍生查询表，但确切来源、版本和生成记录尚不完整。Inspect 假定输入坐标与内置类 MNI 图谱相容，**不执行配准**；标签 ID 为分类编码，不是连续统计量。

## 文献

- Tzourio-Mazoyer N 等（2002）。Automated anatomical labeling of activations in SPM using a macroscopic anatomical parcellation of the MNI MRI single-subject brain. *NeuroImage* 15:273–289。
- Xia M, Wang Z, Dai Z, Liang X, Song H, Shu N, Li K, He Y（2014）。Differentially disrupted functional connectivity in posteromedial cortical subregions in Alzheimer's disease. *Journal of Alzheimer's Disease* 39:527–543。此处教学文件是单样本图，不是论文题目可能让人联想到的组间比较图。
