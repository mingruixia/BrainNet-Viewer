# 全局外观与渲染细节

[English](../en/M05_Global_Appearance.md) · [手册目录](index.md) · [背景规则](../../documentation/Backgrounds.zh-CN.md)

**Apply** 提交并渲染。已保存的Scene或预设可能带有不同显式值；下表描述新设置，不会覆盖已载入配置。

| 控件 | 新设置默认值 | 含义与限制 |
|---|---|---|
| **Background Color → Choose Color** | 白色`[1 1 1]` | 设置科研画布背景，不改变界面的Light/Dark主题；App导出选 **current** 时跟随实际画布颜色。 |
| **Surface Shading** | **Interpolated** | Flat、Faceted、Interpolated。Faceted显示黑色网格边线，密集网格可能较耗时。这是显示着色，不是几何平滑。 |
| **Lighting Model** | **Phong** | None、Flat、Gouraud、Phong；外观还取决于材质、视角和图形后端。 |
| **Light Direction** | **Right** | Headlight、Right、Left。手动旋转后宜目视检查光照；选择不会改变数据坐标。 |
| **Surface Material** | **Dull** | Dull、Shiny、Metal、Custom；选择Custom才启用下面三个强度字段。 |
| **Ambient / Diffuse / Specular Strength** | 储存值`[0.5 0.5 0.5]` | Custom材质下各可填0–1；影响受光外观，不改变标量数据。 |
| **Render Detail** | **Adaptive (modern)** | Adaptive依负载采用现代策略。旧版Low/Moderate/High分别采用节点球面细节10/50/100、连边圆柱边数5/10/20；High可能耗时。曲面拓扑不变。 |
| **Show Orientation Labels** | 关闭 | 多视图默认显示X<=0 / X>0坐标半区；仅在Scene对输入作了明确、绑定哈希的解剖X方向声明后才可显示L/R。标签表示子图，不表示旋转后屏幕边缘。Single View及六完整视图Overview没有半区标签。 |

顶部 **Theme** 仅改变界面颜色。导出背景选 **current** 时保留实际科研画布色；无法可靠透明导出的栅格格式可能被拒绝，而非静默压白。详见[背景规则](../../documentation/Backgrounds.zh-CN.md)。材质和旧细节数值见[材质设置](../../documentation/Material_Settings.zh-CN.md)、[渲染细节](../../documentation/Render_Detail.zh-CN.md)。

App不会从文件名或物种推断解剖方向。显示解剖L/R前须核实坐标单位、共同配准、X=0中线与X正方向，再用[Scene/API流程](../../documentation/Orientation_Labels.zh-CN.md)将声明绑定到输入哈希。未声明时，勾选 **Show Orientation Labels** 仍只显示坐标半区。导出后检查方向标签清晰度。
