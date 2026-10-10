# 06 · 用真实AAL图谱显示双侧岛叶ROI

[English](../en/06_AAL_Insula_ROIs_and_Inspection.md) · [教程目录](index.md) · [ROI/Inspect手册](../../manual/zh-CN/M10_ROI_Inspection.md)

本教程使用内置历史版`aal.nii`绘制**左右岛叶**，不从统计T图生成ROI。详见[逐文件来源与版本说明](Resource_Attribution.md)。本地AAL90引用Tzourio-Mazoyer等，*NeuroImage* **15**:273–289（2002）。这份本地文件尚未与特定官方压缩包逐字节比对，不应直接用后续AAL3v2覆盖。配套曲面的Prof. Alan C. Evans（MNI）来源署名应单独保留。

这份确切`aal.nii`的SHA-256为`2926fcc98efc709f77c8cca2f9c1d797eba3e9a1b222a8e0cfa70ab131394c80`，其中**29 = Insula L**（15,025体素）、**30 = Insula R**（14,128体素）。它们是图谱类别，不是效应量或P值；内置AAL标签MAT对这两个ID的名称一致。类别图谱不应使用统计阈值。

| 控件 | 教学取值 | 目的 |
|---|---|---|
| Layout → Layout Preset / View Direction | Single View / Superior (Axial) | 单脑顶视图，同时观察双侧岛叶。 |
| Surface → Opacity | `0.15` | 透过解剖曲面显示较深的岛叶ROI。 |
| Volume / ROI → Display Volume / Volume Type | 开启 / ROIs (Atlas / Statistical) | 从AAL标签绘制三维ROI。 |
| Threshold Mode | None | 保留整数图谱编号，不作统计筛选。 |
| Draw All ROIs / ROI Selection | 关闭 / `29, 30` | 仅选双侧岛叶；Draw All开启时不能编辑Selection。 |
| ROI Color Mode / Custom Colors | Custom / `29 0.92 0.22 0.18`; `30 0.16 0.42 0.95` | 左红右蓝的稳定分类颜色。 |
| ROI Smoothing / Smoothing Kernel | Gaussian / `3` | 仅柔化显示网格，不改变源标签体。 |
| Show ROI ID Legend | 开启 | 显示29/30编号；这不是连续colorbar。 |

## 操作步骤

### Step 01

执行`app = BrainNetViewer;`。在**Data Sources → Add Files**中把[`BrainMesh_ICBM152_smoothed.nv`](../../../src/matlab/BrainNetViewer/Data/SurfTemplate/BrainMesh_ICBM152_smoothed.nv)选为**Surface Mesh**，把[`aal.nii`](../../../src/matlab/BrainNetViewer/Data/ExampleFiles/AAL90/aal.nii)选为**Volume / Atlas**，点击**Validate and Load**。确认体数据为181×217×181、1 mm。两份文件按其存储的类MNI坐标使用；App不执行配准，本教程也不构成独立的空间对齐审计。

### Step 02

把**Layout Preset**设为**Single View**、**View Direction**设为**Superior (Axial)**，**Surface → Opacity**设`0.15`。在**Volume / ROI**开启**Display Volume**，选**ROIs (Atlas / Statistical)**、**Threshold Mode → None**。关闭**Draw All ROIs**，在**ROI Selection**输入`29, 30`；**ROI Color Mode**选**Custom**，输入/加载表中的两行`ROI_ID R G B`。**ROI Smoothing**选**Gaussian**、**Smoothing Kernel**设`3`，开启**Show ROI ID Legend**，点击共用的**Apply**。结果应仅有两个岛叶网格，而非全部AAL区域。Custom Colors若提示缺行，须同时补全两个ID，不会静默使用回退颜色。

![BrainNet Viewer单脑顶视图中的AAL左右岛叶29和30](../assets/captures/tutorial06-roi/06-aal-bilateral-insula-full-window.png)

*当前构建的英文完整窗体图，仅在显示层隐藏本机路径。R2025a专项确认两个本地图谱ID、单脑顶视图中恰好两个ROI和ID图例，未绘制连续标量色条。AAL来源：GIN/MNI，引用Tzourio-Mazoyer等（2002）；曲面来源：Prof. Alan C. Evans（MNI）。*

![两个AAL岛叶ROI的单脑顶视图导出](../assets/captures/tutorial06-roi/06-aal-bilateral-insula-render.png)

*新App实例重开已保存Scene后导出的960×720 PNG；29/30的选择和分类图例均得到保留。*

### Step 03 · 继续学习曲面Inspect

**Inspect拾取可见曲面顶点或节点，不能拾取ROI网格。** 为在清晰着色的目标上作解剖查询，请接着操作[教程04 Step 05](04_Vertex_Maps_and_Boundaries.md)：使用AAL **surface vertex map**与单脑 **Left (Sagittal)** 视图。本教程双侧岛叶网格由`29, 30`两个ROI ID选择，Inspect不能代替该选择。Inspect假设坐标兼容内置类MNI图谱，**不会**配准或验证输入。

## 常见错误和限制

- **P Value**用于有正确统计元数据的统计图，**不用于**AAL整数标签；`None`保留原ID。
- AAL ID及Custom RGB表是类别编码。默认连续colorbar适用于标量图，ROI ID图例用于说明类别。
- Gaussian仅改变显示ROI网格，不改变NIfTI、标签ID或图谱原始边界；如需严格体素几何，选**ROI Smoothing → None**。
- AAL3v2可能具有不同分区、编号或空间；改用新版前须逐一复核选择、查询和已保存Scene。更换图谱版本时应核对兼容性。
