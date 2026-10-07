# M11 · 自定义色图与显示预设

[English](../en/M11_Colormaps_Presets.md) · [手册目录](index.md) · [真实数据图文练习](../../tutorials/zh-CN/09_Presets_and_Custom_Colormaps.md) · [色图专题](../../documentation/Colormaps.zh-CN.md) · [预设专题](../../documentation/Visualization_Presets.zh-CN.md)

开发版首批正文；2026年9月23日对照当前桌面控件与Settings 1.22.0核对。色图只改变外观，不改变数值、阈值或空间配准；预设只复用显示设置，不打包数据文件。

## 自定义RGB色图

在右侧Visualization Settings的 **Load Preset / Save Preset** 下方打开 **Colors...**。编辑器有四个独立 **Target**：**Surface**、**Nodes**、**Edges**、**Volume**。体数据采用一张带符号色图，不再分正负两张。新增Viridis、Plasma、Inferno、Magma、Cividis具名选项，各目标的色图下拉框亦可直接选择。选内置 **Preset** 及 **Count**（2–4096行）后点 **Generate**；**Resample** 将当前表插值至指定行数，**Reverse** 反转行顺序。Red/Green/Blue表格仅接受[0,1]内的有限数值；有效编辑会更新预览。**Import...** 读取RGB TXT/JSON；**Export...** 只导出当前目标的表，不应用到场景。导出目标已存在时需决定是否覆盖。

**Use in Settings** 将四张色图暂存到右侧面板并关闭编辑器；**Cancel**/关闭则放弃本次编辑。只查看内置名称不会自动转为数值数组；实际修改后才嵌入自定义数组。选择会消费对应色图的显示模式，再按面板底部唯一的 **Apply**，即提交设置**并渲染**；**Revert** 放弃尚未提交的面板编辑。成功Apply后不需再次点Render Scene。

Surface Scalar、Node Mapped/Modules、Edge Mapped、Volume Surface Map是典型使用场景。**Edge Node Module**模式下，同模块连边继承**Node**模块色板，不使用Edge色图。节点/连边的固定阈值颜色不使用连续色图。体数据 **Display Values = Positive & Negative** 时，将同一张色图在中点分成负、正两侧；应检查带符号色条及数值范围。ROI **Label Index** 色板是Volume设置里的独立类别选择器，不是编辑器目标。数值色图在RGB空间插值，不自动保证感知均匀或色觉可及。科学解读前参见[节点](M07_Nodes.md)、[连边](M08_Edges.md)、[体映射](M09_Volume_Mapping.md)和[ROI](M10_ROI_Inspection.md)章节。

RGB TXT每行三个数值通道，不执行表达式；JSON采用`kind: brainnet-colormap`、版本`1.0`和`colors`数组。导入文件上限1 MiB。Scene和预设JSON保存已应用的自定义数组；编辑器Export...只建立可单独交换的色图文件。旧渲染器不会将不支持的自定义数组静默替换成别的颜色。旧MAT配置仅导入可信文件；旧版组合体色图需人工核对。

## 保存和加载显示预设

1. 加载数据，编辑Visualization Settings，按 **Apply** 提交并渲染。
2. 按 **Save Preset** 写出`*.preset.json`。它保存**已应用**设置，不保存待提交编辑、输入路径、相机、主题、计算后端或导出面板偏好。
3. 更换数据后按 **Load Preset**，阅读兼容性提示并确认或取消。确认后替换九个显示设置分区及待提交编辑，保留当前输入引用和导出偏好，并清除旧渲染/相机。加载后按 **Render Scene**。
4. 导出前重新核对该数据的色限、阈值、单位、ROI ID及解剖对应关系。角色兼容性提示不能证明空间配准或科学有效性。

**Save Scene** 不同：记录一次Scene的输入引用、设置以及现代App保存时的相机/导出偏好；输入文件仅引用，不打包。格式无效、未知版本或夹带输入/相机字段的预设会被拒绝。取消或校验失败不会替换当前设置。本版不提供纤维绘制；Surface Map和统计ROI的P值预设都须依赖所选NIfTI中有效的统计元数据。预设名称/标题可能含私人信息，共享前须核查。

[真实数据图文练习](../../tutorials/zh-CN/09_Presets_and_Custom_Colormaps.md)现覆盖自定义Volume RGB暂存、Apply及预设重放，并有R2025a专项截图。人工UI验收、可及性复核与发行验收集成仍待进行；本章不代表发行验收完成。
