# M07 · 节点：可见性、标签、大小与颜色

[English](../en/M07_Nodes.md) · [手册目录](index.md) · [节点数据规则](../../documentation/Node_Selection.zh-CN.md)

开发版首批正文，2026年9月23日对照 **Visualization Settings → Nodes** 和Settings 1.22.0核查。`.node`每行的1–3列是XYZ坐标，**第4列供模块/颜色使用**，第5列供节点大小使用，第6列为标签。单位和解剖空间须按输入核实，不能从扩展名推断。统一 **Apply** 提交并渲染；**Revert** 撤销待提交编辑。

## 可见性与标签

| 控件 | 新设置默认值 | 当前规则 |
|---|---|---|
| **Selection** | All Nodes | Threshold保留原始**Selection Basis > Threshold**的节点，等于阈值不保留。Connected Nodes保留*连边筛选之后*仍存在的边的任一端点；没有选中连边就没有Connected节点。 |
| **Selection Basis / Threshold** | Node Value / 0 | Threshold下启用。Node Value取第5列；Module取第4列。Module仍按数值`>`比较，并非匹配指定模块ID。映射半径和Scale不影响此筛选。 |
| **Label Mode** | No Labels | 可选All Labels、No Labels、Threshold。标签只显示在可见且绘制半径非零的节点上；标签恰为`-`时隐藏，含连字符的正常名称不受影响。 |
| **Label Basis / Label Threshold** | Node Value / 0 | Threshold标签下启用。对第5或第4列原值用严格`>`比较，与节点可见性阈值独立。 |
| **Font / Font Size** | Arial / 10 | 字体名称与正数字号（编辑器上限100）。Font Units默认Points，也提供Pixels、Normalized、Inches、Centimeters。 |
| **Font Style / Label Color / Keep Labels in Front** | Normal + Normal / 黑色 / 关闭 | 粗细Normal/Bold，倾斜Normal/Italic。前置只改变显示层级，不改数据坐标，也不能保证密集标签不重叠。 |

## 节点大小

| 控件 | 新设置默认值 | 当前规则 |
|---|---|---|
| **Size Mode** | Mapped | Uniform用Base Size；Mapped归一化源值后确定半径；Raw使用未归一化源值；Threshold先按Mapped或Raw计算，再把**严格低于**Size Threshold的半径替换为1，等于阈值者保留。 |
| **Size Source** | Node Value | 默认第5列；Module/第4列是现代扩展。Uniform时不启用。此选择不改变配色方式。 |
| **Base Size / Scale** | 3 / 1 | Base Size用于Uniform；正数Scale在所有模式下只对最终半径乘一次。半径单位跟随输入坐标，不是屏幕像素。 |
| **Size Threshold: Mapped/Raw、数值** | Mapped / 0 | 仅Threshold启用；在Scale之前比较，低于阈值的半径先变为1再缩放。此阈值改变大小，不负责隐藏节点。 |

Mapped大小沿用旧版归一化规则，动态范围大时包括对数压缩；常量输入在Scale前半径为4。Raw负值/无效最终半径会报错，不静默取绝对值。最终半径为零时不画该节点球体及标签，但不删除输入节点或其边；详见[数值大小规则](../../documentation/Node_Sizes.zh-CN.md)。

## 节点颜色

| 控件 | 新设置默认值 | 当前规则 |
|---|---|---|
| **Color Mode** | Uniform | Uniform用单色Color；Mapped按**第4列**取色图；Modules按第4列唯一模块编号排序配色；Threshold按第4列分成两色。第5列不是默认颜色来源。 |
| **Color / Colormap / Color Limits** | RGB `[37 89 152]/255` / Jet / Auto | Color按钮仅Uniform启用。Mapped或Modules可选具名/自定义色图；固定`low high`范围作用于Mapped，越界值夹取。Auto使用输入第4列全范围，不只使用可见节点。 |
| **Color Threshold / Low (<=) / High (>)** | 0 / `[37 89 152]/255` / 红色 | Threshold中第4列值`<=`阈值用Low，`>`用High；Mapped范围/色图不影响这两个固定颜色。 |

Modules使用 **Nodes** 的colormap；当Edges选择Node Module时，同模块边可继承其模块颜色。自定义色图不同于与曲面几何绑定的Vertex RGB表。详见[节点配色](../../documentation/Node_Colors.zh-CN.md)、[选择与标签](../../documentation/Node_Selection.zh-CN.md)及[标签位置](../../documentation/Node_Labels.zh-CN.md)。

本章记录当前控件及数值含义，不代表发行验收完成；密集标签、各DPI与当前构建发行验收集成复核仍待完成。
