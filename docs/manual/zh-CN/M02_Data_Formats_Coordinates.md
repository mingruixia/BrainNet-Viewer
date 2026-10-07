# M02 · 数据角色、文件格式与坐标

[English](../en/M02_Data_Formats_Coordinates.md) · [手册目录](index.md) · [曲面格式矩阵](../../compatibility/Surface_Format_Support.md) · [数据根目录流程](../../documentation/Getting_Started.zh-CN.md)

选择文件时要确定其**角色**，不能只看扩展名。在 **Data Sources** 中可用 **Add Files** 自动分类候选；有歧义时使用各角色专用入口。**Validate and Load**先读取并核查输入组合，再解释图像。桌面版默认数据根目录是`src/matlab/BrainNetViewer`，不是Scene JSON所在目录。

| Data Sources角色 | 常见输入 | 关键对应规则 |
|---|---|---|
| **Surface Mesh** | `.nv`、`.gii/.gii.gz`、`.pial`、`.mesh`、`.g`、MNI/BIC `.obj`、`.mz3/.mz3.gz` | 几何提供XYZ和面片；读得出不等于已知MNI/受试者空间。详见[M13](M13_Surface_Tools.md)。 |
| **Nodes** | BrainNet `.node` | 每行是带坐标和显示字段的标记。与边矩阵配对须保持行序；教学字段并非自动代表实测量。详见[M07](M07_Nodes.md)。 |
| **Edges** | BrainNet `.edge` | 矩阵行列必须对应节点行；有向性及阈值语义由设置决定。详见[M08](M08_Edges.md)。 |
| **Surface Map** | 按原始顶点顺序排列的标量文本 | 与曲面顶点**顺序**逐一对应；数量相等不能证明图谱匹配。详见[M06](M06_Surface.md)。 |
| **Volume** | NIfTI-1/2 `.nii/.nii.gz`或支持的配对`.hdr/.img` | 头、仿射和统计量元数据很重要。体图能读取不等于已与独立曲面配准。详见[M09](M09_Volume_Mapping.md)、[M10](M10_ROI_Inspection.md)。 |
| **Scene File** | 现代`.scene.json` | 保存分析引用，不是网格或体图；输入相对配置的数据根目录解析。详见[M03](M03_Scenes_Presets_Legacy.md)。 |

现代独立NIfTI/GIfTI读取器**不依赖SPM**。缺少NIfTI magic的纯Analyze 7.5 `.hdr/.img`不支持。GIfTI外部二进制数组在读取器约束内可用，移动数据时须保留伴随文件。曲面`.obj`指**MNI/BIC**而非Wavefront；`.mesh`指支持的BrainVISA编码，不等于任意Medit格式。FreeSurfer `.pial`保留存储坐标，不能自动视为scanner RAS或MNI；BrainVISA不再套用旧版隐式XYZ整体取反。GIfTI变换/元数据可被记录，但不因此自动执行配准。MZ3内含标量/RGBA可被解析，并不自动进入显示配置。明确不支持的变体见[详细格式矩阵](../../compatibility/Surface_Format_Support.md)和[M13](M13_Surface_Tools.md)。

## 根目录外文件与可迁移性

对根目录外文件，桌面应用询问 **Stage and Add** 或 **Cancel**。批准后会在`user-data/imports/<hash>/`下生成经过验证的副本并暂存支持的伴随文件；原件不变。这**不赋予**公开分发副本的权利。程序调用`selectInputPath`须明确批准外部导入；CLI不会悄悄暂存任意绝对路径。可迁移Scene保存**相对引用及哈希**，不包含输入数据字节；移动时须在新的数据根目录下保留相对目录结构。详见[M03](M03_Scenes_Presets_Legacy.md)。

## 科学空间对应检查

组合输入前确认物种/模板或受试者、XYZ习惯和左右手性、物理单位、曲面顶点顺序、体图仿射以及图谱/统计图含义。体映射可以利用NIfTI仿射采样体素，但**不替两份数据执行配准**。Inspect对AAL/Brodmann查询假设坐标与其类MNI空间兼容，不实施仿射配准。文件哈希只能证明身份，不能证明空间对齐、分发许可或统计有效性；这些信息不明时应暂停解剖解释并记录不确定性。真实[顶点AAL教程](../../tutorials/zh-CN/04_Vertex_Maps_and_Boundaries.md)与[T图教程](../../tutorials/zh-CN/05_Volume_to_Surface_Mapping.md)展示了有边界说明的确切文件组合。
