# BrainNet Viewer 2.0 bundled Inspect atlases / 内置 Inspect 图谱说明

The project owner has approved including the following two exact historical lookup files in the BrainNet Viewer 2.0 distribution. Keep this notice with any package containing them. The software's GPL-3.0 licence must not be read as an assertion that the atlas data themselves have the same licence.

项目负责人决定在 BrainNet Viewer 2.0 中发行以下两份确切的历史查表文件。包含这些文件的发行包应保留本说明。软件代码的 GPL-3.0 许可不代表在此推定图谱数据适用相同许可证。

| Package-relative file | SHA-256 | Source and citation |
|---|---|---|
| `src/matlab/BrainNetViewer/BrainNet_AAL_Label.mat` | `1fe217ef443cff395884e3c5f672891085cb10858a028048b454d02591316ec9` | Historical AAL lookup derived from an AAL NIfTI. Cite Tzourio-Mazoyer et al. (2002), *NeuroImage* 15:273–289; credit the Neurofunctional Imaging Group (GIN) and MNI. |
| `src/matlab/BrainNetViewer/BrainNet_Brodmann_Label.mat` | `ed057cd513391e3aefae46e4ade5dea5b23b72da5b7cdb0064b7ebb44f347f8e` | Historical Brodmann-area lookup derived from the `brodmann.nii` distributed with MRIcroN; credit MRIcroN/Chris Rorden for that distribution and cite Brodmann's original anatomical work as relevant. |

In the standalone Python package, byte-identical copies are installed at `brainnet_viewer/resources/BrainNet_AAL_Label.mat` and `brainnet_viewer/resources/BrainNet_Brodmann_Label.mat`.

The two numeric volumes were compared in full against matching historical NIfTI files: both contain 181×217×181 voxels with zero differing values, and their one-based MAT affines correspond to the NIfTI sforms. AAL contains 116 positive region IDs; the Brodmann image contains 41 positive IDs. The project retains a separate internal source-match record with the exact NIfTI hashes and validation limits.

These are **direct coordinate lookups**, not subject-to-template registration. They should be used only when the displayed data are in the corresponding MNI-like space; no anatomical label is guaranteed for an arbitrary subject-space image. The Brodmann volume is a historical digitized approximation, not cytoarchitectonic ground truth. Its regional assignments have been questioned in the [R-fMRI Network discussion](https://rfmri.org/content/different-brodmann-atlas-dpabi-and-rest). Do not use these labels for diagnosis or treat a displayed boundary as precise histology.

两份数值体数据均与对应历史 NIfTI 进行了全体素比较，181×217×181 个体素均无差异，MAT 的一基坐标仿射与 NIfTI 的零基 sform 对应。AAL 含 116 个正标签编号，Brodmann 含 41 个。本功能只做坐标直接查表，不执行个体图像到标准空间的配准；仅适用于空间已匹配的数据。Brodmann 图是历史数字化近似图谱，不是精确的细胞构筑边界，也不应用于诊断。

This notice records provenance and limitations for these exact files. It does not confer rights to other atlas, surface, node or edge resources in the package.
