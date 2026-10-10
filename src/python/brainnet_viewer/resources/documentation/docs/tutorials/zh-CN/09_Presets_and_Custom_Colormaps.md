# 09 · 自定义色图与可复用显示预设

[English](../en/09_Presets_and_Custom_Colormaps.md) · [教程目录](index.md) · [色图/预设手册](../../manual/zh-CN/M11_Colormaps_Presets.md) · [真实数据解释](05_Volume_to_Surface_Mapping.md)

本教程复用教程05–08中真实PCC亚区**单样本连接T图**和平滑ICBM152曲面，演示自定义*显示*色图及显示预设。它们都不改变源NIfTI、统计阈值、数值或配准。本图不是AD与对照组差异图。对外发表时仍须保留[统计图来源说明](Resource_Attribution.md)及Prof. Alan C. Evans（MNI）曲面署名。

项目自制的[五行蓝—近白—红RGB文件](../assets/tutorial09-pcc-diverging.colormap.json)是本练习的确切色图（SHA-256 `b2d82b6fa3e65068ebfb394d86bd8daff27b29b69901e42bd31f39f77479e092`）。附带的[显示预设](../assets/presets/tutorial09-pcc-diverging.preset.json)由当前App生成（SHA-256 `27f9037f5f50de4f24a4e2ce3edbc3a94cd69e498e7f9088a28b667bfcd7fad8`）。两者均为用于显示的项目资源；都不打包输入文件。预设还保存本真实示例的布局、`P=0.001`及体映射设置，因此**不可未经复核直接套用到另一组数据**。

| 控件 | 教学取值 | 含义 |
|---|---|---|
| **Colors... → Target** | Volume | 编辑Volume → Surface Map使用的一张色图，而非Surface/Node/Edge颜色。 |
| **Import...** | 附带的`...colormap.json` | 读取[0,1]内五行有限RGB值，不执行表达式。 |
| **Use in Settings → Apply** | 按顺序依次点击 | 先暂存色图，再提交并渲染。 |
| **Save Preset / Load Preset** | 新建`*.preset.json` / 同一文件 | 复用已应用的显示设置，不替换输入文件。 |

## 操作步骤

### Step 01 · 恢复真实数据Scene

在 **Scene File → Open** 打开[教程08四视图Scene](../assets/scenes/tutorial08-pcc-four-view.scene.json)，再点击 **Validate and Load → Render Scene**。配置的数据根目录下必须有相同的确切输入文件。初始画面应是四个外侧/内侧脑图、一条带符号色条，以及教程05所述REST T(37)、双侧未校正`P=0.001`映射。这一步不重新进行统计分析。

### Step 02 · 导入并应用自定义Volume色图

在Visualization Settings点击 **Colors...**。编辑器中选 **Target → Volume**，点击 **Import...** 并选附带的RGB JSON。核对五行RGB值及蓝—近白—红预览。编辑器的 **Preset** 下拉框是 **Generate** 的来源，不能单凭它判断当前导入色表；应以表格和预览为准。点击 **Use in Settings** 暂存，再点右侧设置面板底部唯一的 **Apply** 提交并渲染。体映射仍是带符号的：同一张色图在中点拆分给负、正方向。只选命名`bwr`或`jet`不等于这张自定义表。

![英文RGB编辑器内的五行自定义Volume色图](../assets/captures/tutorial09-preset/09-volume-colormap-editor.png)

*当前构建编辑器截图。项目自制RGB值仅用于教学；蓝红颜色本身不是推断方法，平滑预览也不保证感知均匀或色觉可及。*

![Apply后使用自定义带符号色图的真实T图四视图](../assets/captures/tutorial09-preset/09-pcc-diverging-full-window.png)

*R2025a当前构建英文完整窗体，路径仅在显示层隐藏。专项确认恰好一条色条、每个视图都使用导入RGB表。修改颜色未改变NIfTI、`P=0.001`或映射算法。*

### Step 03 · 保存、扰动并重放预设

点击 **Save Preset**，选择一个**新建**的`.preset.json`路径。它保存经 **Apply** 提交的设置，不保存待提交编辑。为检查重放，可暂把 **Volume / ROI → Colormap** 设为 **Blue-White-Red** 并点击 **Apply**；随后点击 **Load Preset** 选刚保存的文件（也可先查看附带示例），阅读兼容性提示并确认。加载预设会保留当前数据引用，但清除旧渲染/相机；再点击 **Render Scene**。五行自定义色图和四视图应恢复。R2025a专项确认重放后数值RGB表一致，输入引用未被替换。

![自定义显示预设加载后的仅含渲染图](../assets/captures/tutorial09-preset/09-pcc-diverging-replay.png)

*当前构建重放后960×720图像。应核对带符号色条和分布，不应假定另一显示器或图形驱动产生逐像素一致的结果。*

可选MATLAB文件级核对：先将BrainNet Viewer源码目录加到路径，然后运行：

```matlab
rgb = brainnet.io.readColormap("docs/tutorials/assets/tutorial09-pcc-diverging.colormap.json");
size(rgb)  % [5 3]
preset = brainnet.io.readPreset("docs/tutorials/assets/presets/tutorial09-pcc-diverging.preset.json");
volume = preset.Settings.section("volume");
volume.colormap  % 五行RGB
```

## 科学与流程边界

- **色图不是统计量：** 改颜色不改变带符号T值、REST T(37)头、体素级`P=0.001`、插值或多重比较状态；显示时会在RGB行之间插值。
- **预设不是Scene：** 显示预设不含输入路径、相机、导出面板偏好或数据字节。[Save Scene](08_Command_Line_and_Scene_Replay.md)则记录特定数据的引用和可选会话状态。
- **更换数据集：** 本例预设在其他影像上可能保留不合适的P阈值、色限、ROI选择或布局。须复核提示、统计元数据、单位、配准及成图；兼容性不等于科学有效性。
- **Cancel / Revert / 覆盖：** 编辑器 **Cancel** 放弃编辑，设置面板 **Revert** 放弃暂存改动；未按 **Apply** 就保存预设会得到旧的已应用设置。除非明确要覆盖，否则为输出选择新文件名。
