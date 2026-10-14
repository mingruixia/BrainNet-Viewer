# 00 · 首次启动与第一张图

[English](../en/00_First_Launch.md) · [教程目录](index.md) · [入门](../../documentation/Getting_Started.zh-CN.md)

本教程介绍在MATLAB桌面App中读取ICBM152脑曲面、在主画布渲染，并保存PNG及溯源侧车。

## 输入与前提

使用项目中现有的[`BrainMesh_ICBM152.nv`](../../../src/matlab/BrainNetViewer/Data/SurfTemplate/BrainMesh_ICBM152.nv)，路径为`src/matlab/BrainNetViewer/Data/SurfTemplate/BrainMesh_ICBM152.nv`，SHA-256为`471e43f955a1cb9f0350aaca2822f02fc74e393718d1e385fddaf0e578ffe572`。这是真实人脑曲面模板，**81,924顶点、163,840三角面**，不是被试扫描。分发时保留 **Prof. Alan C. Evans（MNI）** 署名；见[来源与坐标说明](Resource_Attribution.md)。

本教程使用Windows、MATLAB R2025a Update 1及项目根目录。软件不提供仅依赖MATLAB Runtime的安装包；其他平台的要求见安装指南。从干净MATLAB路径开始，不要同时加载另一套BrainNet Viewer安装目录。

## 操作步骤

### Step 01

将MATLAB的 **Current Folder** 设为本项目根目录（包含顶层`BrainNetViewer.m`），运行：

```matlab
app = BrainNetViewer;
```

预期：英文BrainNet Viewer主窗口打开。若MATLAB解析到另一份`BrainNetViewer`，先修正路径。

### Step 02

在 **Data Sources** 点击 **Add Files**，把`Data/SurfTemplate/BrainMesh_ICBM152.nv`作为 **Surface** 选择。该文件已位于App数据根目录内，正常情况下**不需要 Stage and Add**；若选择的是数据根目录外的另一份副本，App才可能提示受控导入。`.nv`不能用 **Open Scene JSON** 读取。

### Step 03

点击 **Validate and Load**。预期：Scene摘要出现Surface来源，不报文件缺失。网格应为**81,924顶点、163,840三角面**；本练习不加载节点、连边、体数据或标量映射。不要仅凭文件名推断立体定位坐标已经过独立核验。

### Step 04

在 **Visualization Settings → Layout** 选择 **Single View** 和 **View Direction → Left (Sagittal)**；在 **Surface** 选择 **Color Mode → Uniform**，把 **Opacity** 设为 **1**。点击统一的 **Apply** 一次，它会提交设置**并渲染**中央画布上的脑曲面。仅需显式重绘时才用 **Render Scene**。

![BrainNet Viewer主窗口以左矢状单视图渲染Evans署名的MNI ICBM152脑曲面](../assets/captures/real-icbm152/00-ICBM152-first-render.png)

*MATLAB完整窗口截图，已隐藏本机路径和机器信息。曲面由Prof. Alan C. Evans（MNI）提供。*

### Step 05

如曲面过小或偏离中心，点击画布 **Fit**。在Data Sources下方的 **Export Figure** 设置 **PNG**、**Pixels**、**1600 × 1200**、**300 DPI**，保持白色背景。点击导出按钮（随窗口宽度显示为 **Export...** 或 **Export Figure**），选择新的`first-view.png`。预期同时生成`first-view.png`和`first-view.png.provenance.json`。核实图像像素尺寸；分享前检查侧车中的本机路径及模板再分发权限。

**重新选择**这份路径和哈希均匹配的内置文件后，App会在Scene和侧车中写入[来源元数据及Evans/MNI署名](Resource_Attribution.md)。旧导出产物可能仍带早期通用标记`user-provided-not-for-redistribution`；不要私自改写历史溯源。

## 核对、错例与图位

- 正确首图：单视图的脑皮层曲面，无节点、连边或统计色条。具体像素依图形环境而异，不是科学指纹。
- 若 **Validate and Load** 报文件缺失，核对所选路径或重做已获确认的导入步骤，不要静默改用其他脑模板。
- 若 **Export Figure** 不可用，先确认Apply已完成当前渲染；不要覆盖需要保留的旧输出。

继续[01 · 曲面基础](01_Surface_Basics.md)。本展示练习不验证配准精度或统计推断。
