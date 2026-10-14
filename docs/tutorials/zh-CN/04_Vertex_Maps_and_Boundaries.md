# 04 · 真实AAL顶点标签与曲面边界

[English](../en/04_Vertex_Maps_and_Boundaries.md) · [教程目录](index.md) · [曲面设置](../../manual/zh-CN/M06_Surface.md)

本教程在原配平滑ICBM152曲面上显示历史AAL顶点标签、类别边界，并查询可见曲面顶点。见[材料来源与解释说明](Resource_Attribution.md)。

## 数据与解释

将[`BrainMesh_ICBM152_smoothed.nv`](../../../src/matlab/BrainNetViewer/Data/SurfTemplate/BrainMesh_ICBM152_smoothed.nv)作为**Surface**、[`icbm_vertex_AAL_label.txt`](../../../resources/atlases/AAL90/icbm_vertex_AAL_label.txt)作为**Surface Map**。两份文件应按此组合使用。映射SHA-256为`7cd6b8aa19c2aae6161015d62d22770a1fdfdf61d7e29354e8174dbd7853d131`。文件含**81,924**个整数顶点标签，实际出现79个ID，范围0–90；ID 0有**7,352**个顶点，本教程将其作为未标注/背景，另有**74,572**个顶点为正ID。文件夹名“AAL90”不表示该曲面出现全部90个正ID。发表图片前请读[来源、兼容性和权利说明](Resource_Attribution.md)。

这是一份按类别编码的图谱衍生顶点投影，**不是统计图**。本地资料引用Tzourio-Mazoyer等，*NeuroImage* 15:273–289（2002），但没有独立记录确切图谱版本、投影算法或空间配准精度。使用本课指定的AAL表及原配曲面。截图使用Windows/MATLAB R2025a Update 1。

| 控件 | 练习值 | 含义 |
|---|---|---|
| Layout → Preset / View Direction | Lateral / Medial | 四个左右半球外侧和内侧视图 |
| Surface → Color Mode / Opacity | Scalar Map / 1 | 在不透明曲面上显示按原始顶点顺序排列的ID |
| Surface → Colormap / Color Limits | Jet / `0 90` | 给ID赋显示颜色；数字大小不表示解剖强弱 |
| Surface → Show Surface Colorbar | 开启 | 数字色条用于查询标签ID，不代表效应量大小，也不是带脑区名称的AAL图例 |
| Surface → Boundary / Boundary Color | Automatic / 黑色 | 勾勒不同整数标签的交界 |

## 操作步骤

### Step 01

在项目根目录运行`app = BrainNetViewer;`。在 **Data Sources → Add Files** 中把平滑版ICBM152 `.nv`选为**Surface**，再把AAL `.txt`选为**Surface Map**，单击 **Validate and Load**。预期一个81,924顶点、163,840面片曲面及一个81,924值的映射，没有节点、连边或NIfTI体数据。未平滑版ICBM152的面片索引相同，但坐标不同；本教程使用上述配套文件。

### Step 02

在 **Visualization Settings → Layout** 选择 **Lateral / Medial**。在 **Surface** 设置 **Color Mode → Scalar Map**、**Opacity → 1**、**Colormap → Jet**、**Color Limits → `0 90`**，开启 **Show Surface Colorbar**，选择 **Boundary → Automatic**，**Boundary Color**保持黑色。单击共用 **Apply** 提交并渲染。预期看到多个彩色图谱衍生区域及黑色交界线。颜色只编码ID，不代表排名、效应量或概率；边界沿网格过渡，局部可能呈折线。

![四个左右半球外侧和内侧视图显示AAL顶点标签及Surface设置](../assets/captures/manual-revision/04-aal-four-views.png)

*MATLAB完整窗口截图，已隐藏本机路径；显示设置及数据不变。来源曲面署名：Prof. Alan C. Evans（MNI）；图谱引用：Tzourio-Mazoyer等（2002）。*

### Step 03

在当前渲染后使用 **Tools → Save Boundary**，选择一个**新建**的`.txt`路径。此文件组合在Automatic模式下导出81,924个二值，其中**11,942**个边界顶点；这个数字仅对应固定文件组合和设置，并不是AAL脑区数量。不要覆盖此前的边界文件。输出有溯源注释，分享前需检查本机路径。

### Step 04

在项目根目录执行下列MATLAB代码，核对读到的文件：

```matlab
sourceRoot = fullfile(pwd,"src","matlab","BrainNetViewer");
addpath(sourceRoot);
ref = brainnet.core.InputReference("surface_map", ...
    "resources/atlases/AAL90/icbm_vertex_AAL_label.txt", ...
    Sha256="7cd6b8aa19c2aae6161015d62d22770a1fdfdf61d7e29354e8174dbd7853d131");
ids = brainnet.io.readSurfaceMap(ref,pwd);
[numel(ids),numel(unique(ids)),sum(ids==0)]  % [81924 79 7352]
```

**Apply**后可用 **Save Scene** 保存两份输入引用和显示设置；JSON不会嵌入图谱表。保存Scene后，在新App实例中重新读取相同输入并绘图，二值边界应仍包含**11,942**个顶点。换机重放仍须保证数据根下有两份精确文件，对外分享原始侧车前还需检查本机路径。

### Step 05 · 在左侧面AAL顶点图上使用Inspect

保持相同两份输入与标量映射设置，将 **Layout → Preset** 改为 **Single View**，**View Direction** 改为 **Left (Sagittal)**，点击 **Apply**。点击画布工具栏 **Inspect**，再点击可见的彩色曲面；标签会显示在画布内。再次点击 **Inspect** 退出并清除。拾取对象是源曲面顶点，不是脑区色块或边界线。

![左侧面AAL顶点图及画布内Inspect标签](../assets/captures/tutorial04-aal/04-aal-left-inspect-full-window.png)

*MATLAB中的AAL映射及Inspect标签。图示第3号顶点的映射ID和AAL查询ID均为**11**，查询显示 **Frontal Inf Oper L** 和 **Brodmann Area 48**。单点吻合不足以验证整张图的投影或配准。*

## 常见问题与解释

- **文件角色错误或缺失映射：** 应将`.txt`选为**Surface Map**。只改Scalar Map不会从曲面凭空产生脑区标签。
- **曲面或顶点顺序不同：** 行数相同不证明对应关系。不要为了得到一张看似合理的图而强行绑定无关曲面；科学使用前还需核对固定哈希及原始投影流程。
- **图谱ID是类别：** 不能认为`90 > 10`代表效应更强，也不能把Surface的 **Boundary Threshold** 当成统计检验。Automatic仅显示ID过渡，见[边界语义](../../documentation/Surface_Boundaries.zh-CN.md)。
- **版本与配准：** 本练习重现本地历史AAL衍生可视化。这不等于独立认证来源图谱版本、标签投射到曲面的算法或坐标变换。独立的体图谱Inspect查询图示单点的吻合不足以验证整张顶点表，仍需核对原始投影方法与坐标变换。
