# 自定义色图

**Colors...** 编辑器只有四个独立目标：Surface、Nodes、Edges、Volume。Volume用**一张**带符号色图；Positive & Negative显示模式从中点分成正负两侧，不再存两张。ROI Label Index的类别色板及可选ROI ID图例在Volume设置中选择，不是编辑器目标。

新增Viridis、Plasma、Inferno、Magma、Cividis，采用Matplotlib固定256色参考表；Surface、Nodes、Edges、Volume及ROI Palette下拉框均可选择。Fiber设置数据模型也接受这些名称，但当前尚不提供纤维绘制。顺序色图适合有序数值，相邻ROI类别却可能难以区分；带正负号体数据会从色图中点分割，零点具有实际含义时宜选Blue-White-Red等发散色图。来源署名及许可见`NOTICE_CODE.md`与`LICENSE_MATPLOTLIB_COLORMAPS.txt`。

选择内置名称与 **Count**（2–4096）后点Generate，或导入TXT/JSON RGB表。Red/Green/Blue通道为[0,1]内有限数值。**Resample** 在RGB空间插值，**Reverse** 倒序，**Export...** 仅写出当前目标的表。**Use in Settings** 暂存四个目标并关闭编辑器；面板底部唯一的 **Apply** 提交**并渲染**，**Revert** 放弃待提交设置；Cancel/关闭编辑器放弃编辑器内的修改。

连续颜色模式采样为256色并在RGB空间插值。节点Mapped使用`.node`第4列；Node Threshold及Edge Threshold/Length使用固定颜色而非连续色图。Node Modules属于类别映射，类别数超过颜色数时可能循环；Edge Node Module的同模块连边继承Node模块色板，不使用Edge色板。未修改的内置色图保持名称，表格修改后变成内嵌数组。导入不执行表达式，非法名称不会静默改成parula。色图不改变数值、阈值、配准或统计结果；解读体映射前检查正负色限及色条。

RGB TXT支持每行三个数值（空格/逗号分列、分号/换行分行、可选外层方括号），导入上限1 MiB。JSON示例：`{"kind":"brainnet-colormap","schema_version":"1.0","colors":[[0,0,1],[1,0,0]]}`。覆盖已有文件需明确允许。已应用的数组嵌入现代Scene/预设设置；旧渲染器不支持时会报错，不擅自换色。旧版组合`EC.vol.CM`不能自动无损重建；只从可信旧软件导出RGB并人工复核正负映射。本版即使设置契约含纤维色图字段，也不提供纤维绘制/编辑目标。

[当前英文RGB编辑器示例](../tutorials/assets/captures/tutorial09-preset/09-volume-colormap-editor.png)展示五行Volume色表。相关章节：[节点配色](Node_Colors.zh-CN.md)、[连边配色](Edge_Colors.zh-CN.md)、[体映射](../manual/zh-CN/M09_Volume_Mapping.md)、[ROI](../manual/zh-CN/M10_ROI_Inspection.md)。
