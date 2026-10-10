# 图谱/统计ROI与画布点位查询

[English](../en/M10_ROI_Inspection.md) · [手册目录](index.md) · [统计ROI规则](../../documentation/Statistical_ROI.zh-CN.md) · [AAL双侧岛叶教程](../../tutorials/zh-CN/06_AAL_Insula_ROIs_and_Inspection.md) · [AAL顶点图Inspect练习](../../tutorials/zh-CN/04_Vertex_Maps_and_Boundaries.md)

开启 **Display Volume** 并选择 **Volume Type → ROIs (Atlas / Statistical)** 才会绘制ROI。**Apply** 提交并渲染；**Revert** 撤销待提交编辑。ROI编号是标签，不是连续定量值。

共用阈值控件位于Volume面板的 **Surface Mapping** 分组上方，而不是曲面专属分组内。ROI模式选择P Value时，P Value及Cluster Size同时可用；Value/Cluster模式则使用Statistical Threshold。

## ROI控件

| 控件 | 新设置默认值 | 当前规则 |
|---|---|---|
| **Threshold Mode** | None | None保留图谱原有正整数ID。Value/Cluster按`abs(value) >= abs(Statistical Threshold)`生成统计簇，Cluster再过滤小簇。P Value依据受支持的NIfTI T/F/R/Z元数据换算阈值，再按Cluster Size过滤并编号。 |
| **Statistical Threshold / P Value / Cluster Size / Voxel Connectivity** | 0 / 0.05 / 0 / 18邻域 | Value/Cluster使用数值阈值；P Value须满足`0 < P < 1`且统计元数据有效。T/R/Z双侧，F仅上尾。P Value与Cluster使用体素数而非mm³表示的Cluster Size。零及非有限体素排除；可选6、18、26邻域。 |
| **Draw All ROIs** | 开启 | 绘制全部有效正整数ID；开启时 **ROI Selection** 不可编辑。 |
| **ROI Selection** | 空 | 关闭Draw All后，可输入以空格或逗号分隔的正整数ID。输入非空列表也会自动取消Draw All。图谱模式使用原ID；统计Value/Cluster/P Value使用重新连续编号的分量ID，阈值、Cluster Size或邻域变化后可能改变。 |
| **ROI Color Mode** | Label Index | Uniform用单一ROI Color；Label Index按ID循环使用所选分类ROI Palette；Custom需要明确的`ROI_ID R G B`表。颜色模式不改变区域成员。 |
| **ROI Palette** | HSV | Label Index可选所有具名色图，包括Viridis、Plasma、Inferno、Magma、Cividis；256色按正整数ROI ID循环。这是**分类索引**，并非连续定量色条。HSV和Lines通常更利于区分类别，顺序渐变色图中的邻近标签可能相似。 |
| **Show ROI ID Legend** | 关闭 | 在第一幅渲染视图显示可选的ROI编号/颜色图例；最多列16项，超出时标明剩余数。不是数值色条。 |
| **ROI Color / Load ROI Colors... / Custom表** | `[0.8 0.2 0.2]` / 无表 | ROI Color仅Uniform使用。Custom可输入/读取`ROI_ID R G B`行：ID为不重复的正整数，RGB有限且在[0,1]。体数据中存在且选中的每个ID都要有颜色；缺色报错，不自动回退。 |
| **ROI Smoothing / Smoothing Kernel** | Gaussian / 3 | 可选None、Box、Gaussian。核大小单位为体素；1表示不平滑，有效较大的奇数核会柔化边界。这是显示网格处理，不修改所存体数据或科学簇ID。 |

ROI P Value按旧版顺序：P换算统计量阈值、剔除未达阈值/非有限体素、删除小于Cluster Size的分量、为余下分量编号。接触的正负T/R/Z体素可能组成同一ROI；F排除负值。准备阶段溯源记录阈值、自由度、元数据来源、移除的簇和结果编号。元数据缺失或矛盾会报错。这是**未校正的逐体素阈值**；Cluster Size本身不能证明簇水平显著性，也不执行多重比较校正或配准。图谱通常应使用None，不应使用P Value。

ROI网格使用0.5等值面及虚拟零背景外沿，关闭接触体边界的区域。平滑时对每个原始26连通分量做存续检查；如有分量会消失，则保守地让**整块原ROI**回退未平滑。它**不保证**体积、细分支或完整拓扑保持。核>1的有效平滑依赖Image Processing Toolbox的`bwconncomp`；无此工具箱可选None或核1。详见[ROI几何](../../documentation/ROI_Geometry.zh-CN.md)、[自定义颜色](../../documentation/ROI_Colors.zh-CN.md)及[统计编号](../../documentation/Statistical_ROI.zh-CN.md)。统计筛选改变ID后须复核Custom表。不提供图谱/统计类型自动分类。

## 已渲染画布的Inspect

点击画布工具栏 **Inspect**，再点击已渲染的**曲面顶点或节点**。该视图内出现简洁标签，显示源对象/序号、可用值/模块信息、假设MNI的XYZ，以及可用时的 **Brodmann Area** 与 **AAL region**。点另一处会替换；再次点击 **Inspect** 退出并清除，不弹出独立对话框。连边、箭头、ROI网格和纤维目前不可点选；ROI叠层不拦截可见曲面的拾取。曲面点击报告最近的显示源顶点，不对鼠标精确命中位置插值。

桌面版目前把输入坐标直接当作与内置AAL/Brodmann资源相符的类MNI空间查询，**不执行配准、仿射/非线性变换，也不核实这个前提**。原生空间、动物、不同尺度或未配准的数据可能得到看似合理但错误的标签。报告脑区前须独立核实坐标来源；见[Inspect限制](../../documentation/Scene_Inspection.zh-CN.md)。程序查询结果比画布短标签包含更多来源信息。

历史`aal.nii`及内置AAL/Brodmann查询MAT的材料介绍见[逐文件来源说明](../../tutorials/zh-CN/Resource_Attribution.md)。[教程04左侧面AAL顶点图](../../tutorials/zh-CN/04_Vertex_Maps_and_Boundaries.md)展示一个局部ID相符的实例；它不能证明与当前AAL3v2/AFNI文件版本相同或整个曲面的空间配准。
