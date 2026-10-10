# 曲面外观、映射与边界

[English](../en/M06_Surface.md) · [手册目录](index.md) · [边界细节](../../documentation/Surface_Boundaries.zh-CN.md)

Apply提交并渲染；已载入的Scene或预设保留自身显式值，除非用户修改。

| 控件 | 新设置默认值 | 含义与启用条件 |
|---|---|---|
| **Color Mode** | Uniform | **Uniform** 使用单一RGB；**Scalar Map** 依据加载的曲面标量图或支持的体→曲面映射为顶点着色；**Vertex RGB** 使用明确绑定、按原始顶点顺序排列的RGB表。应按数据类型选择，不只是按想要的色图选择。 |
| **Uniform Color** | `[0.95 0.95 0.95]` | 仅Uniform启用；**Choose Surface Color** 修改单色。 |
| **Opacity** | Settings默认0.3 | 滑动范围0（透明）至1（不透明）。但*新建*仅曲面或曲面＋映射/体草稿会改以 **1** 起始；显式Scene/预设值不被覆盖。该透明度只改变显示，不改输入数值。 |
| **Colormap** | Parula | 加载曲面标量图时启用；可选具名色图或 **Custom (Colors...)**。体→曲面着色使用 **Volume** 面板的独立色图；Vertex RGB不使用标量色图。 |
| **Color Limits** | Auto | Scalar Map可填`Auto`或两个端点，如`-2 2`。固定范围只影响颜色缩放，不过滤顶点值；更换数据后须复核。 |
| **Show Surface Colorbar** | 开启 | 显示曲面标量图或体到曲面映射的单条连续色条；Uniform和Vertex RGB无对应数值色条。已有Scene/预设中显式关闭的设置保持不变。图谱ROI编号图例是另一种分类图例。 |
| **Boundary** | None | **Automatic** 显示类别过渡线；**Threshold** 按严格阈值标记顶点；**Custom Mask** 使用按原始顶点顺序排列的二值掩码。除Custom Mask外需相应映射数据。 |
| **Boundary Color** | 黑色`[0 0 0]` | 选择边界模式后启用，只改变显示颜色。 |
| **Boundary Threshold** | 0 | 仅Threshold启用，分类条件为`value > threshold`，不是`>=`。 |
| **Load Mask... / Bind to Surface** | 无掩码 | Custom Mask下可用。须核对原始顶点顺序后导入或绑定二值表；仅行数相同不能证明解剖对应。状态行显示绑定情况。 |
| **Double Brain** | 关闭 | 在Single View的Left/Superior/Anterior方向复制显示同一曲面；可带按明确行序组织的节点/连边，不可带曲面映射/体输入；不是任意双受试者合成。 |
| **Load RGB... / Bind RGB** | 无RGB表 | 单脑要求原始顶点顺序的N×3、值在[0,1]的有限RGB文本；Double Brain要求2N×3。必须绑定，绑定也不能独立证明最初对应关系。状态行显示绑定情况。 |

当前面板的 **Automatic** 是现代线条式边界；旧Legacy Automatic设置可为兼容读取，但不再作为独立面板选项。Threshold和Custom Mask采用顶点着色，并非几何等值线。详见[边界算法与掩码安全](../../documentation/Surface_Boundaries.zh-CN.md)。**Vertex RGB**启用时保留原始曲面网格，大曲面可能较耗时；它不是标量图或统计阈值。见[RGB格式/绑定](../../documentation/Vertex_RGB.zh-CN.md)和[Double Brain行序](../../documentation/Double_Brain.zh-CN.md)。

体映射算法、正负值/阈值及ROI绘制位于 **Volume** 分类，区别于Surface标量色图，将在M09说明。图像看起来合理并不证明网格与体数据已配准；解剖解释前须核对空间。

使用真实历史AAL衍生顶点标签、**Automatic**边界及二值掩码导出，可参见[教程04](../../tutorials/zh-CN/04_Vertex_Maps_and_Boundaries.md)。图谱ID是类别，不是效应量。使用该标签表时须保持与原配平滑曲面的顶点顺序一致；图谱确切版本、投影方法和空间配准仍须核对。
