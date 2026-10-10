# 迁移、限制与故障排查

[English](../en/M15_Migration_Troubleshooting.md) · [手册目录](index.md) · [迁移专题](../../documentation/Migration.zh-CN.md)

BrainNet Viewer 2.0提供MATLAB、Python桌面和Docker/Web三版。本章介绍MATLAB配置迁移、限制与故障排查。

## 从BrainNet Viewer 1.7/1.8迁移

| 旧流程 | 当前入口 | 需核对之处 |
|---|---|---|
| GUIDE主窗口 / Load File | `BrainNetViewer`；Data Sources → Validate and Load | 使用当前项目启动器和明确的数据根目录。根目录外文件须经App询问后暂存；Scene JSON不打包输入。 |
| BrainNet_Option.fig与OK/Apply | 右侧Visualization Settings → 共用 **Apply** | Apply**提交并渲染**；**Revert**丢弃未提交编辑；画布**Reset**只恢复相机；**Restore Defaults**经确认后重置显示设置。 |
| Save/Load Option MAT | **Save/Load Preset**复用外观；可信EC MAT用 **Import Settings** | 预设不含输入/相机/导出面板偏好。EC导入是须审核的转换，不保证无损；保留原MAT并查看`fields_requiring_review`。 |
| 保存/重新打开一次分析 | **Save Scene / Open Scene JSON** | Scene记录输入引用/哈希及已应用设置，可带现代相机/导出状态。保留对应数据根目录结构，复核哈希及空间对齐。 |
| Redraw / Clear Figure | **Render Scene**显式重绘；**Clear Figure**只清画布 | 清图保留输入/设置；按角色Clear会移除该输入。 |
| Get position | 画布内 **Inspect** | 在假定MNI-like坐标下查AAL/Brodmann；**不**配准或变换输入。引用脑区前先核实来源。 |
| Merge Mesh / 生成坐标 | **Merge Surfaces**、**Convert Surface to NV**、**Subdivide Surface to NV**、**Generate Nodes from Atlas** | 审核后写新文件，不静默覆盖源文件或执行配准。转换仅保留几何，不沿用旧`.mesh`隐式坐标取反。 |
| Movie / Print / 脚本 | **Export Animation**、**Export Figure**、`BrainNetRender` | 动画是静态场景的相机旋转；打印需先导出图像/PDF再用外部程序；现代CLI与`BrainNet_MapCfg`参数不直接互换。 |

当前Settings版本为1.22.0。旧Scene/预设/EC数值可能迁移，但节点/连边阈值端点、模块色、带符号体色图、ROI编号/平滑等语义已澄清或修复，外观可能变化。应使用`.node`第4/5列独立变化、并含恰好等于阈值数据的小样例复核科学设置，不要仅凭图像相似就判定对等。各项规则见[节点](M07_Nodes.md)、[连边](M08_Edges.md)、[体映射](M09_Volume_Mapping.md)、[ROI/Inspect](M10_ROI_Inspection.md)与[色图](M11_Colormaps_Presets.md)。

## 当前边界，不作默认承诺

- 独立NIfTI读取器支持NIfTI-1/2单文件及成对头/图像（含已支持的gzip变体）；缺少NIfTI magic的**纯Analyze 7.5**会被拒绝。MNI/BIC `.obj`不是Wavefront OBJ；FreeSurfer `.pial`、BrainVISA `.mesh`、MZ3和GIfTI各有更窄限制。几何读取成功不证明坐标配准。
- ROI **P Value**现可换算受支持的统计NIfTI元数据，但不自动判断输入是图谱还是统计图、不做多重比较校正，也不能证明簇水平显著性。纤维束绘制、任意 **Plot Edit**、GIF/EPS/EMF导出和内置打印仍未提供；仅Runtime部署也未验证。Python桌面版和Docker/Web版各有独立安装指南。
- 当前桌面目标为Windows MATLAB R2025a Update 1。其他MATLAB版本、平台、全部显卡驱动/显示器DPI组合及工具箱矩阵未完全认证。
- GPU只覆盖具体支持的运算，不代表所有渲染或视频编码均走GPU。复杂PDF/SVG可能栅格化；JPEG/BMP不透明；PNG/TIFF透明性取决于真实alpha输出。哈希和溯源证明数据/配置身份，不证明解剖有效性、发表权利或跨系统逐像素一致。

## 出现问题时

| 现象 | 首先核查 / 安全处理 |
|---|---|
| 找不到启动器，或启动了另一份BrainNet | 使用含`BrainNetViewer.m`的当前项目根目录，必要时把该根目录加入MATLAB路径，并从当前会话移除冲突的*路径项*；不修改原软件文件夹。见[入门](../../documentation/Getting_Started.zh-CN.md)。 |
| 外部输入无法写入可迁移Scene | 在App提示时选 **Stage and Add**，或有意识地用合适数据根目录启动。不要手工把绝对路径塞进可迁移Scene引用；核查复制的配套文件和权限。 |
| Scene/预设JSON打不开，或文件/哈希不符 | Scene用 **Open Scene JSON**，`*.preset.json`用 **Load Preset**，两种结构不能互换。检查版本/必需字段、数据根相对路径、配套文件及原始哈希；不要通过改哈希绕过校验。 |
| 选了新文件仍见旧图，或不能导出 | 先 **Validate and Load**，再 **Apply**（提交并渲染）或显式 **Render Scene**。导出要求当前Modern Batch渲染。加载预设会清除旧渲染，需再Render Scene。换数据时检查Scene摘要中保留的手动体数值范围。 |
| 左右、比例、图谱区不对，或分半视图为空 | 核实真实坐标系、方向、单位、曲面/体对齐及半球可分性。App不负责配准；不可分网格应选整体布局；Inspect的AAL/Brodmann结果只能暂作参考。 |
| ROI P Value元数据错误、不支持的文件或自定义色错误 | 核对NIfTI统计量类型与自由度，不应把图谱当作统计图；否则改用兼容文件格式，或为每个选中ROI ID提供颜色；见[ROI规则](M10_ROI_Inspection.md)。 |
| GPU、透明或动画导出失败 | 相关计算可先用已记录的CPU后端；核查输出格式、真实alpha支持、视频编解码器、视频偶数尺寸、帧数/尺寸上限及**新的**动画文件夹。不要覆盖或发表部分结果。 |

若问题可重复，记录构建/MATLAB版本、数据角色与非敏感规模、准确错误、最小步骤、计算后端和输出格式。未经授权不要在公开报告中放入受试者数据或绝对溯源路径；分享结果前请以实际软件包核对限制。
