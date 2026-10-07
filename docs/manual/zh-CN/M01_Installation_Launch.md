# M01 · 安装、启动与版本范围

[English](../en/M01_Installation_Launch.md) · [手册目录](index.md) · [首次启动教程](../../tutorials/zh-CN/00_First_Launch.md) · [环境要求](../../../README.zh-CN.md)

本章介绍的是**MATLAB开发版桌面应用**，不是公开安装包。目前已交核心团队的内部测试包标记为`2.0.0-internal-beta.1`（2026年9月23日）；之后工作区中的修改不会自动进入该ZIP。旧版BrainNet Viewer 1.7/1.8源码与2013年已发表论文均须与本版区分。旧版功能对等与发行验收尚未完成。

## 已验证的启动环境

当前经验证的桌面环境为**Windows、已安装并激活的MATLAB R2025a Update 1，以及可用图形会话**。仅有MATLAB Runtime、macOS/Linux打包或独立可执行程序均未认证。现代独立NIfTI/GIfTI读取器不要求SPM，但个别可选功能仍可能依赖MATLAB工具箱或GPU支持。见[项目README](../../../README.zh-CN.md)及[迁移限制](../../documentation/Migration.zh-CN.md)；成功启动不等于所有可选功能均通过。

将新`BrainNetViewer_2026`项目与原始BrainNet文件夹分开。在MATLAB把 **Current Folder** 设为新项目根目录，即包含顶层`BrainNetViewer.m`的目录，然后执行：

```matlab
app = BrainNetViewer;
```

该入口会自行添加`src/matlab/BrainNetViewer`。若从其他目录启动，只需先把**新项目根目录**加入MATLAB路径。不要使用`addpath(genpath(...))`，不要混用冻结旧版，也不要把另一安装位置的`BrainNetViewer`误认为本项目。可用`which BrainNetViewer -all`排查同名路径冲突。本章不提供安装器。

## 启动后应看到什么

英文主窗体显示启动脑图和构建信息。主要流程为 **Data Sources选文件 → Visualization Settings设显示 → 主画布渲染 → 交互/导出**。可用 **Add Files** 或各角色专用入口，点 **Validate and Load**，修改设置后点击共用 **Apply**；Apply同时提交并渲染。**Render Scene**用于显式重绘。本版设置入口不再是旧`BrainNet_Option.fig`。

建议从真实[ICBM152曲面教程](../../tutorials/zh-CN/00_First_Launch.md)开始，而不是随意选取数据目录里的模板。输入角色、坐标和数据根目录见[M02](M02_Data_Formats_Coordinates.md)；保存分析见[M03](M03_Scenes_Presets_Legacy.md)。

## 分享图片或安装包之前

界面版本/构建日期标识开发构建，不是公开发布日期。图片溯源可能包含本机路径。**文件处于某目录不等于可分发**；分享教学数据前须核对来源署名和随包声明。已交内部Beta 1 ZIP与当前工作区可能不同。对外声称版本或兼容性前，应核对[更新日志](../../../CHANGELOG.zh-CN.md)及实际软件包内容。
