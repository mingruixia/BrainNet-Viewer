# M14 · 命令行渲染、批处理与溯源

[English](../en/M14_Batch_Provenance.md) · [手册目录](index.md) · [真实数据CLI图文教程](../../tutorials/zh-CN/08_Command_Line_and_Scene_Replay.md) · [真实数据性能教程](../../tutorials/zh-CN/13_Performance_and_Reproducibility.md) · [Scene流程专题](../../documentation/Scene_Workflows.zh-CN.md)

开发版首批正文；2026年9月23日对照`BrainNetRender`与`renderSceneFile`核对。命令行入口无需打开桌面App，使用**现代**Scene/渲染器；它不取代旧`BrainNet_MapCfg`调用签名。仍需MATLAB许可证和可用图形环境；这不是规划中的浏览器/Docker版。

## 准备可重放Scene

在桌面版选文件、**Validate and Load**、调整Visualization Settings，按 **Apply**（提交并渲染），然后用 **Save Scene** 写出JSON。它记录已应用设置、相对输入引用/哈希、坐标/再分发元数据，以及现代App保存时可选的相机/导出面板状态。它**不**内嵌源数据、不记录未提交编辑、不证明空间配准、也不授予文件共享权。数据根目录须明确：引用相对该根目录解析，而不是相对Scene JSON所在目录。App选取外部文件时经用户同意可在既定根目录下暂存核实后的副本；手写Scene或命令行运行不会静默复制根目录外的数据。

无需打开App渲染一张图：

```matlab
record = BrainNetRender("D:/results/scene.json", "D:/results/figure.png", ...
    DataRoot="D:/project-data", ComputeBackend="cpu", ...
    PerformanceMode="quality", Width=2000, Height=1500, ...
    Resolution=300, Overwrite=false);
```

命令读取并校验输入文件、准备数据、隐藏窗口渲染现代图形，写图像和`figure.png.provenance.json`。输出后缀支持PNG、JPEG、TIFF、BMP、PDF、SVG；复杂PDF/SVG场景可能含栅格化三维内容。默认保护已有图像和侧车文件，不覆盖。每次使用独立文件名，或检查目标后显式设`Overwrite=true`。可以在MATLAB循环里对不同Scene/输出路径重复调用；本版不声称自带独立任务调度器或数据集自动发现。

## 每次运行需核对的选项

| 选项 | 当前行为 |
|---|---|
| `DataRoot` | 默认安装的BrainNetViewer目录；可迁移项目数据应显式指定。 |
| `ComputeBackend` | 默认`auto`，另有`cpu`、`gpu`；GPU仅用于各具体运算支持的部分。 |
| `PerformanceMode` | 默认`quality`，另有`interactive`、`auto`；论文出图建议明确选择quality。 |
| `Width`、`Height`、`Resolution`、`Units` | 宽高同时指定或同时省略；省略时采用已保存的App导出偏好，否则回退到Scene的`image`默认值。显式宽高未指定单位时使用像素；DPI和物理单位由导出器解释。 |
| `BackgroundColor`、`ContentType` | 显式值覆盖已保存偏好。JPEG/BMP不支持透明`none`，像素格式拒绝vector内容；Auto/PDF/SVG不保证纯矢量。 |
| `LegacyConfig` | 渲染前可选的可信旧EC MAT转换；不是旧GUI完整重放，也不为不可信MAT提供沙箱。 |
| `Planner` | 可选复用`brainnet.render.RenderPlanner`对象；同一MATLAB进程中键匹配时可重用准备结果。不代表GPU加速或像素完全一致。 |

Scene加载核对输入身份/哈希；文件缺失或改变应停止，不能静默替换数据。可选相机仅在内容签名仍兼容时恢复，否则使用布局默认视角。跨机器/版本比较时，检查溯源JSON中的设置、数值指纹、渲染器/版本和相机记录，不要求不同驱动下的图片哈希完全一致。**侧车可能包含本地路径、标题及敏感元数据**；发表前审核它和输入资源许可。软件不会自动上传。若只复用外观而不带输入路径，应使用显示预设而非Scene JSON，见[M11](M11_Colormaps_Presets.md)。

[当前构建真实数据CLI教程](../../tutorials/zh-CN/08_Command_Line_and_Scene_Replay.md)现展示一个可迁移Scene和两种输出格式；更广泛的多Scene批量验收、侧车隐私审核及跨平台/驱动验收仍开放。本章不是Docker部署指南，也不表示发行验收完成。
