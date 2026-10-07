# M13 · 曲面格式与网格工具

[English](../en/M13_Surface_Tools.md) · [手册目录](index.md) · [格式矩阵](../../compatibility/Surface_Format_Support.md)

开发版首批正文；2026年9月23日对照当前Tools入口及格式专题核对。网格读取成功**不等于**已配准到MNI、单位与手性一致，或拥有再分发许可。现代读取器保留原始几何，不擅自套用某个数据集的坐标变换。

## 读取与核对曲面

在 **Data Sources → Surface Mesh** 选择支持的网格，随后 **Validate and Load**，配置显示，按 **Apply** 渲染。桌面、Scene JSON和`BrainNetRender`共用独立读取器。支持`.nv`、FreeSurfer `.pial`、BrainVISA `.mesh`、BYU/MOVIE.BYU `.g`、MNI/BIC `.obj`、MZ3 `.mz3/.mz3.gz`及GIfTI `.gii/.gii.gz`，但均以各读取器的具体限制为准。这里的`.obj`是MNI/BIC多边形格式，**不是**通用Wavefront OBJ；`.mesh`不代表Medit格式。桌面宣称支持的FreeSurfer后缀是`.pial`，不能据此推断其他后缀或`.pial.gz`也可用。编码及拒绝条件见[FreeSurfer](../../documentation/FreeSurfer_Surfaces.zh-CN.md)、[BrainVISA](../../documentation/BrainVISA_Surfaces.zh-CN.md)、[BYU](../../documentation/BYU_Surfaces.zh-CN.md)、[MNI/BIC](../../documentation/MNI_BIC_Surfaces.zh-CN.md)与[MZ3](../../documentation/MZ3_Surfaces.zh-CN.md)专题。

读取器保留坐标及三角面绕向，磁盘索引内部转换为从1开始。BrainVISA `.mesh`**不**再套用旧BrainNet隐含的XYZ取反；FreeSurfer surface RAS不自动等于scanner RAS/MNI。网格工具记录GIfTI变换元数据，但不自动应用。MZ3内嵌RGBA/标量会被校验，但不会自动变成显示设置或Surface Map。将曲面与节点、体数据、图谱或其他曲面结合前，需核实空间和几何对齐。单个不可分曲面应使用适用的整体布局，不能凭文件名认定可拆成双半球。

## 产生新数据的工具

| **Tools**中的工具 | 输入和操作 | 输出及注意 |
|---|---|---|
| **Merge Surfaces** | 自动审核2–64个网格的顺序、边界、规模和SHA-256；空间、单位及备注可留空，无Verify勾选。 | 坐标与面拼接成新ASCII `.nv`；不配准、焊接、平滑、修复或转移颜色/标量属性。 |
| **Convert Surface to NV** | 审核一个支持的网格及可选空间/单位声明。 | 新`.nv`保留读取器输出的几何；不做旧`.mesh`隐式取反或属性转移。 |
| **Subdivide Surface to NV** | 审核一个网格，选1–3级线性中点细分（每级面数×4）。 | 更密的新`.nv`；不平滑、不保留曲率，也不自动建立节点/映射对应关系。 |
| **Generate Nodes from Atlas** | 审核离散整数NIfTI标签图谱、所选区域ID、仿射矩阵及声明的空间/单位。 | 新`.node`；每区用未加权体素中心质心，凹形/不连通区域的质心可落在区外。不配准或自动查名称。 |

各工具都有审核步骤，发布前重新核对源文件/依赖指纹，**只写新目标**、不替换已有文件，也不改当前Scene。网格工具默认合并上限为500万顶点/1000万三角面，但读取与分配仍可能耗用大量内存。`.nv`/`.node`输出含`#` JSON溯源注释，可能暴露绝对路径；共享前检查隐私和许可。注释中的空间声明**不会**自动设定Scene坐标系或执行变换。新文件需在Data Sources显式加载；制作可迁移Scene时放在已配置的数据根目录内，或改用合适的根目录。准确审核字段、格式和限制见[合并](../../documentation/Surface_Merging.zh-CN.md)、[转换](../../documentation/Surface_Conversion.zh-CN.md)、[细分](../../documentation/Surface_Subdivision.zh-CN.md)和[图谱节点](../../documentation/Atlas_Nodes.zh-CN.md)专题。

本章说明可用几何操作，不等于经过科学验证的曲面配准流程。跨格式使用时须核对坐标、单位和解剖位置。

## FreeSurfer半球使用流程

选取同一被试或模板、同一次曲面重建的`lh.pial`和`rh.pial`，按左后右合并，保留文件原坐标，再显式加载新NV。可分离的双半球启用内外侧及八视图；单半球不会凭空补成双半球。内侧局部跨X=0按[布局](M04_Layout_Camera.md)中的保守连通分量规则处理。

顶点Surface Map应按相同左后右顺序拼接，每个原始合并顶点对应一个数值；准备映射后不要重排顶点或细分网格。`.annot`不能直接作为Surface Map读入，需先在外部结合对应半球的注释/标签表解码成逐顶点脑区ID，再把区域统计值赋给相应顶点并拼接；注释颜色代码本身不是区域统计值。当前版不会自动解码或转移注释。节点坐标也须与网格空间一致。FreeSurfer原始曲面坐标不自动等于MNI；未经验证对齐，不应直接作MNI体图映射或AAL/Brodmann Inspect。完整图文案例将在发布前手册修订时补充。
