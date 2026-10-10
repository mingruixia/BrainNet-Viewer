# 图像与相机动画导出

[English](../en/M12_Export.md) · [手册目录](index.md) · [真实数据图文导出](../../tutorials/zh-CN/07_Layout_and_Publication_Export.md) · [真实曲面动画教程](../../tutorials/zh-CN/12_Camera_Animation.md) · [动画专题](../../documentation/Movies.zh-CN.md) · [背景限制](../../documentation/Backgrounds.zh-CN.md)

必须先用 **Modern Batch Renderer** 完成当前场景渲染；仅加载而未渲染的Scene无法导出。导出不会改变科学数据或已应用设置。

## 导出静态图

加载、配置并渲染后，在Data Sources下方使用 **Export Figure**。选择格式、尺寸，点击按钮并指定文件。当前面板默认是 **PNG、300 DPI、1600 × 1200、Pixels、Automatic内容、White背景**。它们是导出面板默认值，不能与显示预设中`image`设置分区的默认值混同。

| 控件 | 当前选项和含义 |
|---|---|
| **Format** | PNG、JPEG、TIFF、BMP、PDF或SVG。前四者为像素图；PDF/SVG不保证三维内容仍是可编辑矢量。 |
| **DPI / Width / Height / Units** | DPI和尺寸为正数；单位为Pixels、Inches、Centimeters、Points。保存前按目标用途设置物理尺寸/分辨率，并检查实际文件尺寸。 |
| **Content** | 当前桌面面板提供Automatic和Image；Image强制像素内容，Automatic可能将复杂三维图形栅格化。不能假定PDF/SVG必然纯矢量。 |
| **Background** | White、Black或Transparent (Experimental)。JPEG/BMP不支持透明。PNG/TIFF优先使用原生Alpha；MATLAB将透明背景压成不透明时，以匹配的黑/白背景渲染恢复Alpha，不用颜色键删除黑色或白色物体。导出记录注明方法；在目标排版软件中检查结果。 |

文件选择器可能覆盖所选目标；若需保留原文件，请另选路径。成功导出会写图像及同目录的`.provenance.json`溯源文件，内含Scene/渲染器/导出信息；共享前检查其中的绝对输入路径和标题。现代App保存的Scene会包含导出偏好，加载显示预设不会改动它们。界面的Light/Dark主题并非图像背景色。

## 导出相机动画

先渲染并调整画布相机，再在Tools中选 **Export Animation**。对话框把*当前静态场景*导出到一个**新文件夹**；不会让连接随时间变化，也不会修改主画布/相机。默认 **960 × 720像素、5秒、24 fps、世界Z轴、0°→360°、Safe Fit开启**。可用格式为MATLAB提供MPEG-4 profile时的MP4、Motion JPEG AVI和PNG逐帧图。点击 **Export...**，在已有父目录下选一个新文件夹名；不覆盖已有输出文件夹。

**Safe Fit** 在私有渲染副本中居中并用正交投影保证旋转中的几何体尽量留在画面内；只有在更重视保留当前构图、且能接受裁切时才关闭。角度是相对当前相机、绕世界X/Y/Z轴的偏移。完整一圈不重复末帧。帧数=`round(时长 × fps)`，因此有效时长可能略有差别。导出速度不是播放速度，也不声称使用GPU视频编码。**Cancel Export** 会在当前帧/编解码操作后生效，并清理部分输出。

新文件夹包含`movie.mp4`或`movie.avi`，或`frame-000001.png`等帧文件，以及`preview.png`、`provenance.json`。后者可能包含Scene引用、输入元数据、相机及逐帧记录；**不会**复制原始输入。限制：单维128–3840像素、1–60 fps、2–1800帧、请求时长不超过120秒、总帧像素不超过十亿、非零旋转且不超过360°；视频长宽须为偶数。不提供透明电影或音轨，也不保证各平台编解码器可用或像素完全一致。

接口、取消和输出校验细节见[动画专题](../../documentation/Movies.zh-CN.md)。
