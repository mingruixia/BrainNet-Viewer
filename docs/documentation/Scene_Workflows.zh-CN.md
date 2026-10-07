# Scene 保存、旧配置导入与命令行绘图

专项验证新增[Clear Figure](Clear_Figure.zh-CN.md)：释放绘图而不删除输入或已应用配置，可通过Render Scene恢复主相机视图。

开发版新增可选且绑定输入的[坐标与图谱查询](Scene_Inspection.zh-CN.md)配置，随Save Scene保存；不属于显示预设，也不自动推断配准。

MOVIE.BYU `.g`三角曲面已接入共享App/Scene/CLI流程，参见[BYU几何与多部件边界](BYU_Surfaces.zh-CN.md)。

开发版使用说明 · BrainNet Viewer 2.0 · 开发版 · 2026-09-06

## 主界面操作

1. 从含顶层入口的项目根目录运行 `BrainNetViewer`，或先将该根目录加入MATLAB路径，详见[入门指南](Getting_Started.zh-CN.md)。
2. 在 **Data Sources** 选择文件并 **Validate and Load**，然后调整 **Visualization Settings**。统一 **Apply** 提交并渲染；**Render Scene** 用于显式重绘。
3. 检查绘图并按需交互或导出。
4. 点击文件列表下方的 **Save Scene** 保存 UTF-8 Scene JSON；保存不会清除当前绘图。
5. 在Data Sources用 **Open Scene JSON** 恢复已保存的输入与显示配置，重新验证/读取并渲染。

![Scene 工作流入口](../tutorials/assets/captures/tutorial03-edges/03-directed-all-full-window.png)

Scene 保存文件引用、输入 SHA-256、坐标空间/资源再分发元数据，以及已应用的 Visualization Settings。**Save Scene 现同时保存现代主渲染器的相机状态与导出面板偏好**，写入可选的 `metadata.session_state`（1.0版）。不打包原始数据或授权文件，不保存尚未 Apply 的编辑。没有会话状态的旧 Scene 文件仍可使用。

### 相机控制与重放规则

- **Reset**：恢复当前配置布局的初始方向、中心、距离和尺度，不再把所有子图设成同一个三维方向。
- **Fit**：保留各子图方向，按科学几何居中，用统一正交相机距离与尺度适配，并保留8%的余量。不改变轴区域位置；文字标签和色条不参与几何边界计算。
- 多视图允许单个子图独立旋转/平移，所有子图的相机距离与视角尺度保持联动；缩放同步。主动放大会裁切单个子图内的内容，Fit可恢复完整取景。多视图禁用单视角方向下拉，避免破坏布局含义。
- 关闭前先 Save Scene，才能保留相机状态。输入或显示配置变化会使旧相机绑定失效，采用新布局默认视角，但保留导出偏好。绑定是确定性的场景内容指纹，不是用于身份认证的安全签名。
- **Pop Out** 从主渲染器当前视角开始，但属于独立观察副本；弹出窗口后续鼠标调整不反向覆盖主画布的保存/导出状态。
- 保存的是世界坐标方向、中心、相机距离和视角尺度，不保存窗口像素几何。改变窗口纵横比可能改变取景范围，必要时重新 Fit。鼠标操作不会自动写入磁盘。
- 相机持久化针对现代渲染器，不覆盖旧 GUIDE 回退窗口。图像溯源记录导出时的实际相机。

### 调整主窗口大小

最小支持窗体为960×680。画布工具栏依据实际可用宽度自动分为一、二或三行，折叠设置列时也会更新。**Render Scene**和**Pop Out**不需横向滚动即可访问。唯一一组**Revert / Apply**固定在可滚动设置分类下方；调整窗口不会丢弃未提交编辑。

窗口变化时，轴区域保持归一化布局位置。缩放窗体**不会暗中执行Fit或Reset**：保留相机方向、目标、距离和缩放，包括用户主动设置的偏心视图。画布纵横比改变可能改变取景范围；如需重新居中并完整显示几何，请主动点击**Fit**。这些操作仅控制取景，不改变科学数据坐标。

## 文件路径与数据根目录

所有输入路径均相对于 **DataRoot**，不是相对于 Scene JSON 所在目录，也不是 MATLAB 当前目录。App 使用启动时指定的根目录；本项目默认是 `src/matlab/BrainNetViewer`。迁移电脑时，应保持数据相对目录结构，并明确选择新的数据根目录。只复制 Scene JSON 并不等于复制了数据包。

在App中选择根目录外文件时，须先确认复制校验副本至`user-data/imports/<hash>/`，原文件不改动；API调用`selectInputPath`则须显式使用`ExternalImportApproved=true`。支持的配套文件可一起暂存，但暂存不授予再分发权。保存时会验证已有哈希，并补齐缺失哈希。输入文件缺失或已变化会阻止保存，保留原 JSON。程序调用默认禁止覆盖已有 Scene、图像及溯源文件，只有明确设置 `Overwrite=true` 才覆盖；App 保存对话框负责覆盖确认。

## 导入可信的旧版 MAT 配置

点击 **Import Settings**，选择含 `EC` 的可信 `.mat` 文件。

- 已有 Scene：仅导入配置，保留当前文件与映射模式；MAT 中的 `File`、`FLAG` 即使存在也会忽略，并在报告中记录。
- 尚无 Scene：必须同时有标量结构 `EC`、`File`、`FLAG`。`File.MF/NI/NT/VF` 相对路径按数据根目录解析；根目录外的数据需要手动重新选择，不自动复制。
- 这是配置转换，不启动旧 GUIDE，也不保证每项旧行为完全一致。MAT 缺失的设置使用现代迁移器默认值，并不是保留当前 Scene 的同名设置。
- 导入后先复核外观，再保存。`metadata.legacy_config_import` 记录源文件哈希、已映射字段、警告、全部输入末级字段及 `fields_requiring_review`。待复核列表较保守，包含迁移器未逐字段认证的转换，不全都是“不支持”；`lossless_claimed` 始终为 false。

仅导入可信 MAT：MATLAB 的文件加载不能视为针对不可信序列化对象的安全沙箱。本流程只加载相关顶层变量，不执行任意自定义 colormap 表达式。

## 不打开 App 的命令行绘图

在项目目录调用：

```matlab
record = BrainNetRender("my-scene.json", "figure.png", ...
    DataRoot="D:/my-data", ComputeBackend="cpu", ...
    Width=2000, Height=1500, Resolution=300);
```

入口会读取 Scene、校验数据、准备现代数值场景、创建隐藏绘图窗口，然后导出图片与 `figure.png.provenance.json`。不打开 BrainNet App，不调用旧 `BrainNet_MapCfg`。仍需要可用的 MATLAB 图形环境与许可证；目前不是无需显示服务的 Docker 渲染器。旧 `BrainNet_MapCfg` 的调用方式保持不变，本入口不声称与其签名直接兼容。

格式支持 `.png`、`.jpg/.jpeg`、`.tif/.tiff`、`.bmp`、`.pdf`、`.svg`。复杂场景的 PDF/SVG 可能包含栅格图，溯源记录会说明；栅格格式不能指定 `ContentType="vector"`。

| 选项 | 含义 |
|---|---|
| `ComputeBackend` | `auto`、`cpu`、`gpu`；各运算仍遵循已有 GPU 可用性和回退规则。 |
| `PerformanceMode` | 默认 `quality`；也支持 `interactive`、`auto`。 |
| `Width`、`Height` | 同时提供或同时省略；省略时优先采用保存的导出尺寸，否则使用 Scene 的 `image.width/height` 像素尺寸。 |
| `Resolution` | DPI；省略时优先采用保存的导出DPI，否则使用 `image.dpi`。 |
| `Units` | 恢复保存尺寸时沿用保存单位；显式尺寸未指定单位时用像素。支持 pixels、millimeters、centimeters、inches、points。 |
| `BackgroundColor` | 省略时优先沿用保存偏好，否则为 current；显式参数优先。JPEG/BMP不支持none。 |
| `ContentType` | 输出扩展名与保存格式一致时沿用保存偏好，否则auto；显式参数优先，仍受格式限制。 |
| `LegacyConfig` | 渲染前导入可信 EC MAT，缺失设置按迁移器默认值处理。 |
| `Overwrite` | 默认 false，保护已有图像和溯源文件。 |
| `Planner` | 同一 MATLAB 进程可复用 `brainnet.render.RenderPlanner` 准备缓存。 |

论文出图建议明确使用 `PerformanceMode="quality"` 与 `ComputeBackend="cpu"`。不保证不同 MATLAB、驱动或操作系统的像素逐一一致；验收比较数值指纹、缓存标识、配置和场景结构，而不是图片文件哈希。

```matlab
scene = brainnet.io.readScene("my-scene.json");
[converted, report] = brainnet.io.importLegacyConfig( ...
    "old-settings.mat", "D:/my-data", Scene=scene);
brainnet.io.writeScene(converted, "converted.json", "D:/my-data");
```

溯源 JSON 可能包含本地输入/配置路径及元数据。公开发布前请检查敏感标识与资源许可；软件不会自动上传这些文件。

若只想在不同数据间复用显示配置，请使用右侧 **Save Preset / Load Preset**，而不是打开 Scene。适用性检查、输入/相机隔离和 API 示例见[显示配置预设](Visualization_Presets.zh-CN.md)。

通过 **Tools → Merge Surfaces...** 合并曲面，不替换当前Scene；必须核对共同空间/单位且不覆盖输入，详见[曲面合并指南](Surface_Merging.zh-CN.md)。

启用Automatic边界并渲染后，通过 **Tools → Save Surface Boundary...** 按原始顶点顺序保存二值掩码；与旧版的数值差异和使用边界详见[曲面边界指南](Surface_Boundaries.zh-CN.md)。

FreeSurfer `.pial` 已接入共享App/Scene/CLI读取流程，编码和坐标配准边界见[FreeSurfer表面](FreeSurfer_Surfaces.zh-CN.md)。

BrainVISA `.mesh` 使用独立单时间步三角网格读取器，参见[BrainVISA表面](BrainVISA_Surfaces.zh-CN.md)，尤其注意与旧版XYZ取反行为的明确差异。

MNI/BIC `.obj` 使用独立单对象三角网格读取器，支持ASCII和二进制。字节序、颜色/法线、配准边界见[MNI/BIC曲面](MNI_BIC_Surfaces.zh-CN.md)；不支持Wavefront OBJ。

MZ3 `.mz3` / `.mz3.gz` 支持原始/GZip曲面几何，参见[MZ3曲面](MZ3_Surfaces.zh-CN.md)。嵌入RGBA/标量经过校验，不自动应用为显示配置或曲面映射；纯MZ3覆盖层尚未接入Surface Map。
