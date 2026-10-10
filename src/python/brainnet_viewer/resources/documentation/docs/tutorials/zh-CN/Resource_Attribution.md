# 教程资源署名与使用边界

[English](../en/Resource_Attribution.md) · [教程目录](index.md)

本页介绍教程材料、确切文件哈希、来源署名与解释。资源链接指明练习使用的文件；仅含文档的下载包可能不包含数据。

| `src/matlab/BrainNetViewer/` 下的确切文件 | SHA-256 | 来源及署名 |
|---|---|---|
| `Data/SurfTemplate/BrainMesh_ICBM152.nv` | `471e43f955a1cb9f0350aaca2822f02fc74e393718d1e385fddaf0e578ffe572` | MNI ICBM152 曲面，由 **Prof. Alan C. Evans** 提供；须保留来源署名。 |
| `Data/SurfTemplate/BrainMesh_ICBM152_smoothed.nv` | `aff1920baef51956971b8c1de068e8eee2d1279f21fc90452bcd0dba2794fdc5` | Evans/MNI 曲面的平滑衍生版；须保留原曲面署名。 |
| `Data/Tutorials/Tutorial02_ICBM152_Vertex_Nodes.node` | `e1c7660ee039a2d6142881c28cfaea597941dc714e718f92d1d5a2b42f08fcc5` | 项目新建的八节点教学表，坐标来自上述曲面的确切顶点。 |
| `Data/Tutorials/Tutorial03_Illustrative_Directed8.edge` | `4260badaace588975c79da3b4bad6727bed9ea7e8c289426ac7f163e443f9c00` | 项目新建的 8 × 8 有向示例，与八节点表配对；权重为自拟教学数值。 |
| `Data/ExampleFiles/AAL90/icbm_vertex_AAL_label.txt` | `7cd6b8aa19c2aae6161015d62d22770a1fdfdf61d7e29354e8174dbd7853d131` | MNI 来源的 AAL 顶点标签；须单独引用 Tzourio-Mazoyer 等（2002），不可用 Evans/MNI 曲面署名替代。 |
| `Data/Tutorials/OneSample_ROI11_NC.nii` | `e27d9eca7e20f31ed090e410fdb5b4a409565c2fafc3bc86dff21277e58aad5f` | Xia 等（2014）研究中的 PCC 亚区种子点的单样本功能连接 T 图；引用 Xia 等（2014）。 |
| `Data/ExampleFiles/AAL90/aal.nii` | `2926fcc98efc709f77c8cca2f9c1d797eba3e9a1b222a8e0cfa70ab131394c80` | 历史 AAL90 ROI 体图；引用 Tzourio-Mazoyer 等（2002）。 |
| `BrainNet_AAL_Label.mat` | `1fe217ef443cff395884e3c5f672891085cb10858a028048b454d02591316ec9` | 由 NIfTI 制作的 AAL 查询表；完整转换链尚未归档。 |
| `BrainNet_Brodmann_Label.mat` | `ed057cd513391e3aefae46e4ade5dea5b23b72da5b7cdb0064b7ebb44f347f8e` | 由 NIfTI 制作的 Brodmann 查询表；确切上游版本、空间及转换链未独立比对。 |

## ICBM152 曲面

两份曲面均有 81,924 个顶点及 163,840 个三角面；平滑版与原版面片索引相同，但坐标不同。来源模板为 MNI ICBM152；本文**不独立证明**坐标单位、变换、配准精度或解剖标签。它们不是被试扫描。使用每项练习指定的确切曲面版本。

## 教学节点与连边

教程02–03现使用原配AAL90文件，而非八节点教学数据：[`Node_AAL90.node`](../../../src/matlab/BrainNetViewer/Data/ExampleFiles/AtlasNetworks/AAL90.node)，SHA-256 `2ff2562b55d91f502ee8f3bf86716ea268956391729e502584ca156c2ccdd4ba`；[`Edge_AAL90_Weighted.edge`](../../../src/matlab/BrainNetViewer/Data/ExampleFiles/AtlasNetworks/AAL90_Weighted.edge)，SHA-256 `90c7c6a536ca1131e5645d1bde15a347938a96eb9d5f9a3f41a2e17e6504e3d0`。两文件为90行节点和对称90 × 90加权矩阵；颜色使用第4列已有模块值，映射大小使用第5列。不要将这些既有显示值解释为Yeo标签或新计算的连接强度。AAL引用Tzourio-Mazoyer等（2002），ICBM152曲面署名Prof. Alan C. Evans。

八个节点 XYZ 是原版教学曲面的确切顶点，**并非**经验证的脑区中心。节点第 4–5 列是自拟显示数值，第 6 列是教学标签。连边矩阵含 10 个非零、非对称的自拟权重，行列顺序必须与八节点表一致。它**不是**测得的脑连接、白质纤维、效应图或轴突方向证据。Prof. Evans 的署名针对来源曲面，不针对自拟网络。

## AAL 顶点标签

该文件有 81,924 个整数标签，0 表示未标注顶点；这份曲面上实际仅出现 78 个正 ID。“AAL90”文件夹名不证明图中包含全部 90 个脑区。应配合历史原配的 **ICBM152 平滑曲面**使用；顶点索引对应不等于原体到曲面投射或空间配准已被独立验证。确切图谱版本和投射算法尚未归档。ID 是类别，不是统计值。

## PCC 单样本 T 图

这是标准 MNI 空间、PCC 亚区种子点单样本连接图，**不是**阿尔茨海默病组与对照组的差异图。头信息描述自由度 37 的 T 统计量。教程 05 的双侧 `P = 0.001` 是**未经多重比较校正的逐体素**阈值，先于曲面取样；它不是 FWE/FDR 校正或顶点层显著性检验。解剖解释前应独立核对仿射对齐。插值可改变边缘显示值。配套平滑曲面须另保留 Evans/MNI 署名。

## AAL 与 Brodmann 查询表

在这份确切 `aal.nii` 中，29 和 30 分别为左、右岛叶。其历史 AAL90 文件尚未与某一上游压缩包逐字节比对；不能静默替换为新版 AAL。两份 MAT 是 NIfTI 衍生查询表，但确切来源、版本和生成记录尚不完整。Inspect 假定输入坐标与内置类 MNI 图谱相容，**不执行配准**；标签 ID 为分类编码，不是连续统计量。

## 文献

- Tzourio-Mazoyer N 等（2002）。Automated anatomical labeling of activations in SPM using a macroscopic anatomical parcellation of the MNI MRI single-subject brain. *NeuroImage* 15:273–289。
- Xia M, Wang Z, Dai Z, Liang X, Song H, Shu N, Li K, He Y（2014）。Differentially disrupted functional connectivity in posteromedial cortical subregions in Alzheimer's disease. *Journal of Alzheimer's Disease* 39:527–543。此处教学文件是单样本图，不是论文题目可能让人联想到的组间比较图。
