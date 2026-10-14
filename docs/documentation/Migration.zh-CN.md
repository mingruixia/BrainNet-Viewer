# 从BrainNet Viewer 1.7/1.8迁移

[English](Migration.en.md) · [手册M15](../manual/zh-CN/M15_Migration_Troubleshooting.md)

## 实际迁移路径

1. 保留旧数据及EC MAT配置原件。从当前项目根目录运行现代`BrainNetViewer`启动器，不把旧程序递归加入MATLAB路径。通过Data Sources → **Validate and Load**读取各输入角色，或用 **Open Scene JSON**打开现代Scene。根目录外文件需获准暂存或选择适当数据根目录。
2. 用右侧Visualization Settings替代`BrainNet_Option.fig`。共用 **Apply提交并渲染**；Revert放弃未提交编辑。Render Scene显式重绘；Clear Figure只清视图；相机Reset不等于Restore Defaults。
3. **Import Settings**只导入可信EC MAT。保存现代Scene之前，复核`fields_requiring_review`、输入角色、`.node`第4/5列、阈值等号归属、模块颜色、ROI/统计模式及空间假设。标为已映射的字段并不保证科学语义或像素完全相同。
4. 用 **Save Scene**保留一次分析的输入引用/哈希与已应用设置，可带现代相机/导出状态。用 **Save/Load Preset**跨数据集复用显示配置，**不带**输入路径、相机或导出面板偏好。两者均不授予资源再分发权。
5. 几何方面，Tools提供Merge Surfaces（2–64份）、Convert Surface to NV（单份）、Subdivide Surface to NV和Generate Nodes from Atlas。它们经审核后写**新**文件，不配准，也不套用旧`.mesh`隐式坐标取反。静态自动化用`BrainNetRender`，不要假设它与`BrainNet_MapCfg`参数直接兼容。动画是静态场景相机旋转；没有现代内置打印功能。

<a id="known-limitations"></a>

## 需显式复核的差异

- 独立NIfTI读取器支持NIfTI-1/2与成对NIfTI头/图像，不支持纯Analyze 7.5。MNI/BIC `.obj`不是Wavefront OBJ。BrainVISA `.mesh`保留原XYZ，不再整体取反。FreeSurfer/MNI文件名及Inspect显示的AAL/Brodmann脑区**不**证明配准；Inspect不做仿射变换。
- Layout 2在可识别半球时使用分半总览，不可分网格有保守整体曲面回退。现代布局编号和相机控件见[M04](../manual/zh-CN/M04_Layout_Camera.md)；请按当前布局名称选择视图。
- 节点/连边配色、大小、筛选和阈值端点，带符号体色图及ROI生成采用当前显示规则。旧Scene的外观可能变化；判定迁移等价前，用[节点](../manual/zh-CN/M07_Nodes.md)、[连边](../manual/zh-CN/M08_Edges.md)、[体映射](../manual/zh-CN/M09_Volume_Mapping.md)、[ROI](../manual/zh-CN/M10_ROI_Inspection.md)章节及独立边界值样例复核。
- Surface Map及统计ROI的P值模式现可换算受支持的NIfTI统计元数据；图谱/统计自动分类、多重比较校正和簇水平显著性推断仍未提供。纤维绘制、任意Plot Edit、GIF/EPS/EMF输出和内置打印不是本版能力。本公测不提供MATLAB Runtime-only程序。Docker/Web部署见安装指南。

Scene、图像和电影溯源可能含本地路径和元数据。哈希证明文件身份，不证明解剖配准、统计有效性或共享许可。按现象排查见[手册M15](../manual/zh-CN/M15_Migration_Troubleshooting.md#出现问题时)。
