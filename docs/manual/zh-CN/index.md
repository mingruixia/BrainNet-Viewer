# BrainNet Viewer 2.0 用户手册

[English](../en/index.md) · [README](../../../README.zh-CN.md) · [教程](../../tutorials/zh-CN/index.md)

状态：开发版手册与专题导航，2026-09-23核对。不是完整发行版手册；outline只表示写作范围，专题指南和专项测试也不等于逐控件覆盖或当前构建发行验收通过。

## 核心流程

打开主界面 → Data Sources选择文件 → Validate and Load → Visualization Settings → Apply（**提交并渲染**）→ 交互 / 导出。**Render Scene**可显式重绘；Revert撤销未提交配置，画布Reset只恢复相机。安装、数据根目录暂存、坐标注意事项和Scene/预设区别见[成对入门章节](../../documentation/Getting_Started.zh-CN.md)。

发行版主界面截图将在完成隐私与当前构建复核后加入。

## 章节目录

| ID | 章节 | Status | 现有参考（不等于完整章节） |
|---|---|---|---|
| M01 | 安装、启动与版本范围 | 首批正文 | [安装与启动](M01_Installation_Launch.md) · [入门](../../documentation/Getting_Started.zh-CN.md) |
| M02 | 数据角色、文件格式与坐标 | 首批正文 | [数据与坐标](M02_Data_Formats_Coordinates.md) · [格式矩阵](../../compatibility/Surface_Format_Support.md) |
| M03 | Scene、预设与旧配置 | 首批正文 | [Scene与预设](M03_Scenes_Presets_Legacy.md) · [Scene流程](../../documentation/Scene_Workflows.zh-CN.md) |
| M04 | 布局、相机与交互 | 首批正文 | [布局/相机控件](M04_Layout_Camera.md) · [Scene重放](../../documentation/Scene_Workflows.zh-CN.md) · [实时演示](../../documentation/Live_Demo.zh-CN.md) |
| M05 | 全局外观与性能 | 首批正文 | [全局控件/默认值](M05_Global_Appearance.md) · [背景规则](../../documentation/Backgrounds.zh-CN.md) · [恢复默认](../../documentation/Restore_Defaults.zh-CN.md) |
| M06 | 曲面外观、映射与边界 | 首批正文 | [曲面控件/默认值](M06_Surface.md) · [边界](../../documentation/Surface_Boundaries.zh-CN.md) · [Double Brain](../../documentation/Double_Brain.zh-CN.md) · [Vertex RGB](../../documentation/Vertex_RGB.zh-CN.md) |
| M07 | 节点：选择、大小、颜色与标签 | 首批正文 | [节点控件/默认值](M07_Nodes.md) · [选择/标签](../../documentation/Node_Selection.zh-CN.md) · [字体/位置](../../documentation/Node_Labels.zh-CN.md)；密集标签及DPI复核仍待完成 |
| M08 | 连边：筛选、方向与外观 | 首批正文 | [连边控件/默认值](M08_Edges.md) · [配色](../../documentation/Edge_Colors.zh-CN.md) · [稀疏度/并列值](../../documentation/Edge_Sparsity.zh-CN.md)；当前构建集成验收仍待完成 |
| M09 | 体映射与统计假设 | 首批正文 | [体映射控件与八种算法](M09_Volume_Mapping.md) · [正负显示](../../documentation/Volume_Display.zh-CN.md) |
| M10 | 图谱ROI与坐标查询 | 首批正文 | [ROI/Inspect控件](M10_ROI_Inspection.md) · [统计编号](../../documentation/Statistical_ROI.zh-CN.md) · [Inspect限制](../../documentation/Scene_Inspection.zh-CN.md) |
| M11 | 自定义色图与显示预设 | 首批正文 | [色图/预设控件](M11_Colormaps_Presets.md) · [参考](../../documentation/Colormaps.zh-CN.md) |
| M12 | 图像与相机电影导出 | 首批正文 | [图像/动画导出控件](M12_Export.md) · [参考](../../documentation/Movies.zh-CN.md) |
| M13 | 曲面工具与其他格式 | 首批正文 | [格式与网格工具](M13_Surface_Tools.md) · [参考](../../documentation/Surface_Merging.zh-CN.md) |
| M14 | 命令行、批处理与溯源 | 首批正文 | [批处理渲染与溯源](M14_Batch_Provenance.md) · [参考](../../documentation/Scene_Workflows.zh-CN.md) |
| M15 | 迁移、限制与故障排查 | 首批正文 | [迁移与故障排查](M15_Migration_Troubleshooting.md) · [参考](../../documentation/Migration.zh-CN.md) |

## 现有双语专题

- [Scene Workflows](../../documentation/Scene_Workflows.zh-CN.md)
- [实时演示](../../documentation/Live_Demo.zh-CN.md)
- [Visualization Presets](../../documentation/Visualization_Presets.zh-CN.md)
- [渲染细节](../../documentation/Render_Detail.zh-CN.md)
- [材质设置](../../documentation/Material_Settings.zh-CN.md)
- [Colormaps](../../documentation/Colormaps.zh-CN.md)
- [FreeSurfer Surfaces](../../documentation/FreeSurfer_Surfaces.zh-CN.md)
- [BrainVISA Surfaces](../../documentation/BrainVISA_Surfaces.zh-CN.md)
- [BYU Surfaces](../../documentation/BYU_Surfaces.zh-CN.md)
- [MNI BIC Surfaces](../../documentation/MNI_BIC_Surfaces.zh-CN.md)
- [MZ3 Surfaces](../../documentation/MZ3_Surfaces.zh-CN.md)
- [Scene Inspection](../../documentation/Scene_Inspection.zh-CN.md)
- [Surface Merging](../../documentation/Surface_Merging.zh-CN.md)
- [单曲面转换NV](../../documentation/Surface_Conversion.zh-CN.md)
- [曲面细分并另存NV](../../documentation/Surface_Subdivision.zh-CN.md)
- [从图谱生成节点](../../documentation/Atlas_Nodes.zh-CN.md)
- [Surface Boundaries](../../documentation/Surface_Boundaries.zh-CN.md)
- [Movies](../../documentation/Movies.zh-CN.md)

## 发布前门槛

逐控件核对默认值、输入列、单位、阈值严格性、颜色/尺寸编码、空间假设和失败行为；每章配对翻译并关联可复现样例。未开放的控件不得写成可用功能。用户体验、资源许可及完整平台/工具箱矩阵仍待验收。

[术语表](../../glossary.md)
