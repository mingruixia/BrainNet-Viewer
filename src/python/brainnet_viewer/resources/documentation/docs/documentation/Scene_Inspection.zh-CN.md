# 查询节点、曲面顶点与图谱区域

[English](Scene_Inspection.en.md) · [手册ROI与Inspect章节](../manual/zh-CN/M10_ROI_Inspection.md) · [真实AAL顶点图教程](../tutorials/zh-CN/04_Vertex_Maps_and_Boundaries.md)

## 在画布内查询

1. 加载并渲染Scene，在主画布工具栏点击 **Inspect**。
2. 点击可见节点或曲面；所选视图中直接显示紧凑标签，**不会弹出独立Inspector窗口**。再次点选可更新标签。
3. 标签报告源节点/顶点编号、按MNI空间解释的XYZ、可用的数值或模块信息，以及查询到的 **Brodmann Area** 和 **AAL region**。
4. 再次点击 **Inspect** 可退出并清除标签。重新渲染或切换Scene也会清除。Inspect处于启用状态时，弹出的绘图视图可点选。

标签不显示文件路径、体素索引、图谱ID或内部查询方法；程序接口的结果仍可包含更详细的来源和状态字段。曲面点选返回最近的**已显示源顶点**，不是鼠标精确交点的插值；节点点选返回源节点。边、箭头、ROI网格和纤维对象不支持点选。

## 科学限制

桌面Inspect目前**假设**输入坐标已与内置AAL和Brodmann图谱采用的MNI空间一致；它不验证该假设，也不进行仿射/非线性配准。个体原生空间、非人脑、FreeSurfer surface RAS、不同MNI变体或单位不一致的坐标都可能得到误导性区域名。解释标签前须独立核对坐标来源和配准。

旧的程序接口`brainnet.query.SceneInspector.query`仍可接受显式变换设置，供内部/旧版流程使用；**当前桌面Inspect界面不提供仿射设置或外部体图谱标签字典**。保存Scene可保留其已有Inspect元数据，但桌面直接查询以AAL/Brodmann两套区域名为主。

如需可复现的程序查询，参见[英文专题的MATLAB API示例](Scene_Inspection.en.md#matlab-api)。
