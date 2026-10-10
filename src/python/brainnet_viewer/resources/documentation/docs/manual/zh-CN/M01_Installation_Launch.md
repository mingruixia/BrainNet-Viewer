# 安装、启动与版本范围

[English](../en/M01_Installation_Launch.md) · [手册目录](index.md) · [首次启动教程](../../tutorials/zh-CN/00_First_Launch.md) · [环境要求](../../../README.zh-CN.md)

本章介绍MATLAB桌面版安装与启动。Python桌面版和Docker/Web版的部署见相应安装指南；三版共享主要科学数据与可视化流程。

## 已验证的启动环境

MATLAB桌面版需要已安装、激活的MATLAB及可用图形会话。Windows R2024b/R2025a及macOS R2024a可作为起点。独立NIfTI/GIfTI读取器无需SPM；部分可选GPU功能需要相应硬件及MATLAB工具箱。本公测不提供Runtime-only安装或独立可执行程序。

将新`BrainNetViewer_2026`项目与原始BrainNet文件夹分开。在MATLAB把 **Current Folder** 设为新项目根目录，即包含顶层`BrainNetViewer.m`的目录，然后执行：

```matlab
app = BrainNetViewer;
```

该入口会自行添加`src/matlab/BrainNetViewer`。若从其他目录启动，只需先把**新项目根目录**加入MATLAB路径。不要使用`addpath(genpath(...))`，不要混用不同安装版本，也不要把另一安装位置的`BrainNetViewer`误认为本项目。可用`which BrainNetViewer -all`排查同名路径冲突。本章不提供安装器。

## 启动后应看到什么

英文主窗体显示启动脑图和构建信息。主要流程为 **Data Sources选文件 → Visualization Settings设显示 → 主画布渲染 → 交互/导出**。可用 **Add Files** 或各角色专用入口，点 **Validate and Load**，修改设置后点击共用 **Apply**；Apply同时提交并渲染。**Render Scene**用于显式重绘。

建议从真实[ICBM152曲面教程](../../tutorials/zh-CN/00_First_Launch.md)开始，而不是随意选取数据目录里的模板。输入角色、坐标和数据根目录见[M02](M02_Data_Formats_Coordinates.md)；保存分析见[M03](M03_Scenes_Presets_Legacy.md)。

## 分享图片或安装包之前

图片溯源可能包含本机路径。**文件处于某目录不等于可分发**；分享教学数据前须核对来源署名和随包声明。对外声称版本或兼容性前，应核对[更新日志](../../../CHANGELOG.zh-CN.md)及实际软件包内容。
