# 显示配置预设复用

专项验证历史说明：当时P值预设可读取但不能应用。现在Surface Map和统计ROI的P值预设可提交，
前提是所选NIfTI有受支持的统计元数据；ROI模式还应用Cluster Size。Modern Batch Renderer已支持自定义ROI配色，
预设提示改为核对编号覆盖，不再称其未实现。空色表在选择ROI时需要补齐；实际渲染
遇到任何已选编号缺色均报错。更换图谱或统计阈值后需重新核对编号。当前写出Settings 1.22.0；下文旧版本描述仅供迁移参考。

预设按钮旁的 **Colors...** 可编辑自定义RGB，随已应用设置嵌入Scene和预设；详见[自定义色图](Colormaps.zh-CN.md)。当时写出1.2.0，当前写出1.22.0且旧配色可迁移；自定义边界掩码预设仅适用于绑定的几何，不是通用样式，升级与绑定规则见[曲面边界](Surface_Boundaries.zh-CN.md)。

## 主界面操作

1. 读取数据文件，或打开 Scene JSON。
2. 在右侧 **Visualization Settings** 中调整显示，点击面板底部统一 **Apply** 提交所有分类编辑**并渲染Scene**；同处的 **Revert** 撤销未提交编辑。这组按钮不随分类内容滚动。
3. 点击设置标题下方的 **Save Preset**，保存为 `*.preset.json`。只保存已经应用的显示配置，不关闭当前绘图。
4. 换一组数据，点击 **Load Preset**，阅读确认框和适用性提示，再选择 **Apply** 或 **Cancel**。
5. 检查适用于新数据的阈值、单位、颜色范围和 ROI 选择，点击 **Render Scene**，然后交互、导出。

没有选择数据时也可保存/加载预设，但与数据的适用性检查需要延后。两个按钮随右侧设置栏一起收起，不新增独立设置窗口。

加载经确认后会整体替换九个设置分区，并放弃面板中尚未 Apply 的编辑。当前 Scene 标识、输入路径/哈希、坐标空间声明和导出栏偏好保持不变。旧绘图关闭，相机清空，重新渲染后使用当前布局的默认视角。保存预设则不改变 Scene 或画布。

## 三类文件的区别

| 文件/入口 | 用途 | 数据路径 | 相机/导出偏好 |
|---|---|---|---|
| **Save Scene** / Scene JSON | 恢复某一次分析及其输入引用、显示配置 | 包含引用，不打包原始文件 | 现代 App 保存时包含 |
| **Save Preset** / 预设 JSON | 不同数据复用一套显示配置 | 不包含输入引用字段 | 不包含相机或导出栏会话状态 |
| **Import Settings** / 旧 MAT | 显式转换可信旧版 EC 配置 | 未选 Scene 时可能导入旧 File/FLAG 输入 | 不是现代会话快照 |

为保持配置契约一致，预设保留 `image` 分区，包括默认尺寸/DPI、图标题和色条样式。但加载预设时**不会覆盖当前导出栏**，实际输出尺寸/格式仍在 **Export Figure** 中设置。预设不保存计算后端选择或界面主题。

## 校验及边界

- 使用独立文件类型标识和版本号。Scene JSON、未知版本/多余字段、缺少分区、非法设置及显式输入/相机字段均在替换当前配置之前拒绝。
- 缺少对应输入、映射配色缺少映射数据等情况会提示复核。无输入的设置分区仍保留，但不添加或替换数据。文件角色检查不能保证解剖配准、数值单位、阈值合理性或 ROI 编号有效性。
- 本版本尚未实现纤维绘制和 p 值阈值，启用这两项的预设暂不允许应用。自定义ROI调色板已实现，但须覆盖所有被选ROI编号；警告需要审阅，缺少必需颜色会阻止渲染。
- 取消确认保留已应用配置、未提交编辑和当前绘图。读取/校验失败不替换配置、不关闭绘图；界面可显示错误提示。
- 图标题、标签和预设名称允许自由文本。分享前请检查敏感内容；不会自动上传。

## MATLAB API

```matlab
app = BrainNetViewer;
% 在界面调整并 Apply 后：
app.savePresetFile("network.preset.json", Name="Network overview");
[preset, report] = app.inspectPresetFile("network.preset.json"); % 只读检查
% 阅读 report.warnings 并接受提示后；阻断项不可绕过：
app.loadPresetFile("network.preset.json", AllowWarnings=true);
```

`AllowWarnings` 默认为 `false`，有复核提示时返回 `BNV:Preset:ReviewRequired`，需调用者明确接受。保存的 `Overwrite` 默认为 `false`。空加载路径按取消处理。独立的 `brainnet.io.readPreset` / `writePreset` 和 `brainnet.core.VisualizationPreset` 不依赖 App 图形，也不读取数据文件。

预设 Schema 复用既有显示配置契约。完整会话恢复与命令行渲染参见 [Scene 工作流](Scene_Workflows.zh-CN.md)。
