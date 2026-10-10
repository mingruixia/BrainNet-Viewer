# 布局与相机控件

[English](../en/M04_Layout_Camera.md) · [手册目录](index.md) · [Layout 2细节](../../documentation/Layout_2.zh-CN.md)

控件位于 **Visualization Settings → Layout**。统一 **Apply** 提交并渲染；**Revert** 撤销待提交编辑。Scene和预设保留已生效布局，但预设不带当前相机。

| 控件 | 新设置默认值 | 作用及使用条件 |
|---|---|---|
| **Layout Preset** | **Single View** | 五项：Single View、Overview (6 / 8 Views)、Lateral / Medial、Lateral / Medial / Ventral、Lateral / Medial / Dorsal。多视图自行设置各子图方向并共享尺度，不是把单视角方向简单复制。 |
| **View Direction** | **Left (Sagittal)** | 单视图可选Left、Superior、Anterior、Custom、Right、Inferior、Posterior、Isometric；多视图由预设方向决定。视角名称不证明数据的解剖左右方向。 |
| **Custom Azimuth** | 未显式设值 | 选择Custom方向时启用；单位为度，范围−360至360。应用后的值可随Scene/预设保存。 |
| **Custom Elevation** | 未显式设值 | 选择Custom方向时启用；单位为度，范围−90至90。 |

**Overview (6 / 8 Views)** 仅在曲面可安全分成两组非空、顶点不交叠的X侧子网格时使用八个分半视图；否则回退到六个完整数据视图，不凭空补出缺失半脑。这是保守判断，不负责任意解剖分割或配准。保存的八视图相机若重放为六视图（反之亦然），会提示并重置相机；详见[Layout 2](../../documentation/Layout_2.zh-CN.md)。

若X侧分组共享顶点，还会检查曲面是否恰有两个独立连通分量，且各自至少95%的被面片引用顶点位于相反X侧。这样可保留FreeSurfer半球内侧局部跨X=0的顶点，每个半球整体显示，不沿中线切三角形。连续、单连通或分组歧义的曲面仍使用完整曲面视图。

启用**Zoom**后，在脑图上滚动滚轮只缩放该子图；在其他面板滚动不会改脑图相机。滚轮改变相机视角，不改变轴区域尺寸。

渲染后可用画布的 **Rotate**、**Pan**、**Zoom**、**Fit**、**Reset**。Fit按可见几何重新居中取景，不改变输入坐标；Reset恢复当前布局的初始相机。缩放窗体不会暗中Fit。**Pop Out** 打开独立观察副本，其后续操作不覆盖主画布相机。**Save Scene** 可记录有效的现代主画布相机，**Save Preset** 不记录相机；详见[相机与重放](../../documentation/Scene_Workflows.zh-CN.md)和[窗体大小](../../documentation/Window_Layout.zh-CN.md)。

**Double Brain**（见M06）是单视图的另一种显示方式，不是第六种布局。它只适用于带曲面的Left、Superior或Anterior方向，不支持标量映射/体输入。**Show Orientation Labels** 的视图标签见M05；未经绑定输入的解剖方向确认时，只表示坐标半区。
