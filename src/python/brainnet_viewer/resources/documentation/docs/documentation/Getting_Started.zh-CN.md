# BrainNet Viewer 2.0 入门

[English](Getting_Started.en.md) · [手册](../manual/zh-CN/index.md) · [Scene与预设细节](Scene_Workflows.zh-CN.md)

适用于BrainNet Viewer `2.0.0`。请使用对应版本的源码或安装包，核对发行说明和校验值；需安装MATLAB，不是MATLAB Runtime独立程序。验证范围及限制请以README为准。

## 1. 安装与启动

验证包括Windows MATLAB R2025a Update 1、Windows R2024b Update 1关联检查及macOS R2024a团队工作流检查。需安装并激活MATLAB；尚未认证仅MATLAB Runtime运行或Linux。部分功能需要额外工具箱，见[环境与限制](../../README.zh-CN.md#安装与启动)。

将MATLAB的 **Current Folder** 设为包含顶层`BrainNetViewer.m`的项目根目录，然后运行：

```matlab
app = BrainNetViewer;
```

这个入口会自行加入`src/matlab/BrainNetViewer`。若从其他工作目录启动，先将**项目根目录**加入MATLAB搜索路径一次，再调用同一函数。不要递归加入全项目、另一套BrainNet Viewer安装目录。目前没有MATLAB Compiler安装包。

## 2. 选择和读取数据

在 **Data Sources** 中使用 **Add Files**，或分别选择Surface、Nodes、Edges、Volume等输入。**Open Scene JSON** 用于打开已保存的Scene，而不是NIfTI或曲面文件。选择相容的数据后点击 **Validate and Load**，在绘图前读取文件并检查输入错误。曲面可以单独显示；其他输入组合取决于所需可视化。角色及格式边界见[README](../../README.zh-CN.md#安装与启动)和[曲面格式矩阵](../compatibility/Surface_Format_Support.md)。

MATLAB直接读取所选本机文件，不再弹出导入确认，也不自动复制数据。普通 **Save Scene** JSON只保存路径引用和哈希，不包含数据；引用文件须保留在记录的位置。需要共享或迁移时，在保存对话框选择 **Portable Scene with data (*.zip)**，将输入及支持的成对或外部数据文件打包；目标电脑用 **Open Scene** 打开ZIP。旧版相对数据根目录的Scene JSON仍可读取。含本机绝对引用的普通JSON适合同一电脑使用，路径将改变时应选择ZIP。

科学解释前须核对单位、坐标轴、物种及图谱/体数据对齐。NIfTI头信息并不能自动证明另一份曲面已与该体数据配准；格式可读不等于坐标吻合。

## 3. 设置、渲染、交互和导出

展开右侧 **Visualization Settings** 分类。统一 **Apply** 提交待修改设置，**并渲染**已加载的Scene；**Revert** 仅撤销待提交编辑，不改已生效设置。**Render Scene** 用于显式重绘当前Scene，例如相机或数据变化后。首次Apply若需读取输入，也会经过读取与验证流程。更换输入文件时App会清除旧画面，不能把旧图当成新数据结果。

画布工具可Rotate、Pan、Zoom、Fit或Reset。**Inspect** 在已渲染画布上显示所点位置的标签；再点一次Inspect可清除。AAL和Brodmann查询使用假设的类MNI坐标解释，不进行配准变换；未经核对输入空间，不应把标签当作确定的解剖定位。Data Sources下方的 **Export Figure** 支持PNG、JPEG、TIFF、BMP、PDF和SVG，并可设置尺寸/分辨率；复杂三维矢量输出可能含栅格图。导出会生成provenance JSON侧车，其中可能包含本机路径，分享前须检查。

## 4. 保存与复用

需要重开同一次分析时使用 **Save Scene**。其JSON保存输入引用与哈希、已生效显示设置、相关坐标/权限元数据，以及有效时的现代相机/导出偏好；**不**嵌入原始数据。移动Scene时须保持所选数据根目录下的相对结构；用 **Open Scene JSON** 打开后再 **Validate and Load** 并渲染。未Apply的编辑不作为已生效设置保存。

只想在不同数据集复用外观时使用 **Save Preset**。预设不含输入路径、相机状态或导出面板偏好。**Load Preset** 先核查兼容性，确认后替换全部显示设置、放弃待提交编辑并重置相机；随后需要再次渲染。每换数据都要复核阈值、色图范围和ROI编号。**Import Settings** 则通过另一条转换路径读取*可信*的旧EC `.mat`配置，保存现代Scene前应阅读迁移警告。详见[Scene工作流](Scene_Workflows.zh-CN.md)、[预设](Visualization_Presets.zh-CN.md)及[迁移说明](Migration.zh-CN.md)。

附带资源的来源与引文见随包说明。
