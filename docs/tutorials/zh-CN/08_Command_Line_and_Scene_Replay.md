# 08 · 命令行渲染与Scene重放

[English](../en/08_Command_Line_and_Scene_Replay.md) · [教程目录](index.md) · [批处理/溯源手册](../../manual/zh-CN/M14_Batch_Provenance.md) · [真实T图教程](05_Volume_to_Surface_Mapping.md)

本练习使用教程05和07的同一份**真实PCC亚区单样本连接T图**，但通过已保存的Scene JSON渲染，**不打开**BrainNet Viewer桌面App。该NIfTI不是AD与对照组差异图。[资源说明](Resource_Attribution.md)以及平滑ICBM152曲面Prof. Alan C. Evans（MNI）的署名要求仍适用。运行仍需要MATLAB许可证和可用图形环境；这不是规划中的Docker/浏览器版。

提供的[四视图Scene JSON](../assets/scenes/tutorial08-pcc-four-view.scene.json)是可迁移的*引用*，不是内嵌数据包。它由当前App保存，包含`P=0.001`、三线性映射、带符号色阶、四视图布局及输入哈希。其SHA-256为`7d0c9b11c734f8297235d000927d2fab28301176106683d729e2e20bba439ab0`。文件不含本机绝对路径，但相对于**数据根目录**引用确切的`Data/SurfTemplate/BrainMesh_ICBM152_smoothed.nv`和`Data/Tutorials/OneSample_ROI11_NC.nii`。应保持源码树内这两份文件及相对结构，或指定具有同样结构的数据根。Scene不能证明配准，也不自动授予新输入的再分发权。

## 操作步骤

### Step 01 · 在新项目根目录启动MATLAB

将MATLAB Current Folder设为**新项目**`BrainNetViewer_2026`根目录，而不是旧版原始源码目录。运行：

```matlab
projectRoot = string(pwd);
sourceRoot = fullfile(projectRoot,"src","matlab","BrainNetViewer");
addpath(sourceRoot);
scenePath = fullfile(projectRoot,"docs","tutorials","assets", ...
    "scenes","tutorial08-pcc-four-view.scene.json");
outputDir = fullfile(projectRoot,"tmp","tutorial08-cli");
if ~isfolder(outputDir), mkdir(outputDir); end
```

若MATLAB从其他位置启动，应明确将`projectRoot`设为**新项目**根目录。下面的`DataRoot`是`sourceRoot`，不是Scene JSON所在目录。本练习无需改动或复制原始BrainNet文件夹。

### Step 02 · 不打开App导出PNG

```matlab
pngPath = fullfile(outputDir,"pcc-four-view.png");
record = BrainNetRender(scenePath,pngPath, ...
    DataRoot=sourceRoot,ComputeBackend="cpu", ...
    PerformanceMode="quality",Width=960,Height=720, ...
    Resolution=150,Units="pixels",BackgroundColor="white");
info = imfinfo(pngPath);
[info.Width info.Height]  % [960 720]
```

下图展示四个曲面视图和带符号色条；导出时同时生成`pcc-four-view.png.provenance.json`。CLI用隐藏的现代绘图窗体，不启动App，并在渲染前核对输入哈希。它与桌面版示例视觉可比较，但不保证跨显卡驱动或版本像素完全相同。

![命令行重放真实单样本T图的四视图导出](../assets/captures/tutorial08-cli/08-pcc-four-view-cli.png)

*R2025a Update 1用所附Scene导出的当前构建960×720 PNG。它是单样本连接T图，不是组间差异；未校正体素级阈值和插值的限制仍按教程05。*

### Step 03 · 同一Scene输出第二种图片

使用**不同文件名**导出1200×900 TIFF。保存后检查格式、像素尺寸及相邻溯源记录。

```matlab
tifPath = fullfile(outputDir,"pcc-four-view-1200x900.tif");
BrainNetRender(scenePath,tifPath, ...
    DataRoot=sourceRoot,ComputeBackend="cpu", ...
    PerformanceMode="quality",Width=1200,Height=900, ...
    Resolution=300,Units="pixels",BackgroundColor="white");
imfinfo(tifPath)  % 核对Width、Height和Format
```

两次调用构成一个小型批量示例：科学Scene固定，只改变*输出*规格。请求`300` DPI不等于独立验证各下游软件中的实际印刷尺寸。若有多组不同分析，应分别保存并验证Scene，而不是手工修改JSON输入路径。

### Step 04 · 检查溯源和重放规则

```matlab
sidecar = jsondecode(fileread(pngPath + ".provenance.json"));
sidecar.kind
sidecar.scene.inputs.volume.sha256
sidecar.export.actual_width_pixels
```

导出后检查输入哈希、960像素宽度及溯源记录。**分享原始侧车前须检查路径和元数据。** 默认不覆盖已有图片或侧车，除非显式指定`Overwrite=true`；日常建议使用新文件名。错误的`DataRoot`会使输入解析失败，不会偷偷替换成别的体图。只有Scene内容签名兼容时才会恢复保存的相机；窗口或图形后端不同仍可能影响取景，因此应逐图检查。Scene保存的是输入引用与已应用设置，不内嵌NIfTI/曲面字节、不记录未提交编辑，也不证明配准。

## 常见问题

- **找不到输入/哈希不符：** 将`DataRoot`指向具有确切两份文件及相对结构的`BrainNetViewer`源码目录；不要指向JSON所在目录，也不要静默替换改变了的文件。
- **输出已存在：** 更换文件名，或核看图片和侧车后显式批准覆盖。默认情况下，已有输出不会被覆盖。
- **渲染/图形错误：** 虽然不需要桌面App窗口，MATLAB仍需要可用图形环境。无头服务器使用前应核对图形支持。
