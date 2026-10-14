# 07 · 多视图布局与出版图片导出

[English](../en/07_Layout_and_Publication_Export.md) · [教程目录](index.md) · [布局手册](../../manual/zh-CN/M04_Layout_Camera.md) · [导出手册](../../manual/zh-CN/M12_Export.md)

本教程复用[教程05](05_Volume_to_Surface_Mapping.md)中真实**PCC亚区单样本功能连接T图**及平滑ICBM152曲面。它不是阿尔茨海默病与对照组的比较。四视图用于演示排版和导出控件；科学解释及来源与解释说明仍按教程05。

| 控件 | 教学取值 | 用途 |
|---|---|---|
| Layout → Layout Preset | Overview（8视图）；Lateral / Medial（4）；＋Ventral（6）；＋Dorsal（5） | 以统一尺度观察互补视角；选用能回答科学问题且不过于拥挤的排版。 |
| Surface → Show Surface Colorbar | 开启 | 保留连续的带符号T值色条。 |
| Export Figure → Format | TIFF | 导出无损栅格图，便于后续排版。 |
| Export Figure → Units / Width / Height | Pixels / `1800` / `1350` | 指定实际像素数；按每英寸300像素，预期排版尺寸为6×4.5英寸。 |
| Export Figure → DPI / Transparent | `300` / 关闭 | 在白底上请求300 DPI元数据；需核对下游文件及期刊要求。 |

## 操作步骤

### Step 01 · 恢复真实数据四视图Scene

完成[教程05的Step 01–02](05_Volume_to_Surface_Mapping.md)，或打开该教程保存的Scene JSON，点击 **Validate and Load → Render Scene**。输入必须是教程05中的确切`BrainMesh_ICBM152_smoothed.nv`和`OneSample_ROI11_NC.nii`。保持P值、映射算法及色图不变，仅切换 **Layout Preset** 并点击共用 **Apply**。四种布局分别显示8、4、6、5个视图，各配一条带符号色条。多视图预设自带相机方向，单视图 **View Direction** 在此不起作用。只有曲面能安全拆分成双半球（如本示例）时，Overview才显示**8视图**；不可拆分曲面回退为6个完整曲面视图。

### 同一T图的多视图图库

**Overview (8 Views)** 汇总外侧、内侧、顶侧、底侧、前侧和后侧信息，适合总览；单个脑图较小，窄版面投稿图未必适用。

![真实单样本T图的八视图总览](../assets/captures/tutorial07-export/07-layout-2-full-window.png)

**Lateral / Medial (4 views)** 放大两侧外侧面与内侧面；这些曲面承载主要结果时适合采用，也是下面的导出示例。

![真实T图的四视图外侧面和内侧面](../assets/captures/tutorial07-export/07-layout-3-full-window.png)

**Lateral / Medial / Ventral (6 views)** 增加两个向外旋转的底面；需在最终排版尺寸下核看色条及底面细节。

![真实T图的六视图外侧面、内侧面和底面](../assets/captures/tutorial07-export/07-layout-4-full-window.png)

**Lateral / Medial / Dorsal (5 views)** 在中央增加一个完整脑顶视图，不重复放置第二个顶面。

![真实T图的五视图外侧面、内侧面和顶面](../assets/captures/tutorial07-export/07-layout-5-full-window.png)

*四张MATLAB截图使用相同的单样本T图、平滑ICBM152曲面和带符号色阶，仅布局不同，分别显示8、4、6、5个视图。截图中的本机路径已隐藏。*

### Step 02 · 设定输出尺寸

返回 **Lateral / Medial** 并点击 **Apply**。在Data Sources下方的 **Export Figure** 选择 **TIFF**、**Pixels**、**Width 1800**、**Height 1350**、**DPI 300**，保持 **Transparent** 关闭。导出对象是已渲染的Scene，不是整个App窗体的截图。点击 **Export...**，选择一个**新建**的`.tif`路径；覆盖旧图前需仔细确认。

![真实T图四视图及TIFF、1800×1350像素、300 DPI导出设置](../assets/captures/tutorial07-export/07-four-view-export-full-window.png)

*MATLAB导出设置示例：TIFF为**1800×1350像素**，同时生成`.provenance.json`。截图中的本机路径已隐藏。该图为单样本功能连接T图，不是疾病组间差异；数据来自Xia等（2014），曲面由Prof. Alan C. Evans（MNI）提供。*

### Step 03 · 投稿前核验

下面的AAL90示例用红框标出同一个 **Export Figure** 面板，设置为TIFF、1800 × 1400像素及300 DPI。这是补充示例，不是上方统计图导出的尺寸。

![AAL90四视图网络及红框标出的Export Figure设置](../assets/captures/manual-revision/07-export-highlight.png)

用目标排版/投稿软件打开TIFF，确认预定版面尺寸下四个视图及色条可读，并检查像素尺寸。检查TIFF格式、**1800×1350**像素及输入记录，并在投稿或排版软件中确认实际印刷尺寸、DPI解释、颜色要求和字体显示。分享前检查`.provenance.json`，其中原始路径可能暴露本机信息。若期刊要求矢量图，须在目标工作流实际测试PDF/SVG：三维图即使包装在矢量格式中也可能被栅格化。

## 常见错误与限制

- **导出不可用：** 必须先渲染Scene；仅加载文件或Scene不够。
- **子图过小或裁剪：** 使用 **Fit** 或重新选择布局，最终以*导出文件*检查，不只看交互窗。
- **尺度混淆：** `1800×1350`是像素数，`300 DPI`是排版/元数据请求，二者都不会提高原始数据的解剖精度。
- **科学边界：** 原始阈值来自REST T(37)，为双侧未校正体素级`P=0.001`；四视图布局不改变统计推断。不要把单样本连接示例标作AD与对照组差异。
