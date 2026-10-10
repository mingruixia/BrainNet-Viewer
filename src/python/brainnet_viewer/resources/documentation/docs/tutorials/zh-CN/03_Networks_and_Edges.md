# 03 网络与连边

[English](../en/03_Networks_and_Edges.md) · [教程索引](index.md) · [连边设置](../../manual/zh-CN/M08_Edges.md)

使用原配套AAL90加权网络，以四视图展示。矩阵的行列顺序必须与节点表一致。

## 输入

使用 [ICBM152](../../../../Data/SurfTemplate/BrainMesh_ICBM152.nv)、[AAL90节点](../../../../Data/ExampleFiles/AtlasNetworks/AAL90.node)及 [Edge_AAL90_Weighted.edge](../../../../Data/ExampleFiles/AtlasNetworks/AAL90_Weighted.edge)。该示例是对称90×90矩阵，不是八节点有向教学网络。

## 步骤

1. 在Data Sources各行分别添加曲面、节点与连边并加载，Scene中确认90节点和90×90矩阵。
2. Layout选择 **Lateral / Medial**，Surface灰色且 **Opacity 0.3**。
3. Nodes选择 **Modules**、**Mapped** 大小与 **No Labels**。
4. Edges选择 **Threshold 0.5**、**Selection Values → Absolute**、关闭Directed Edges、**Uniform** 大小 **0.25**、**Node Module** 颜色。
5. 点击 **Apply**，该阈值下示例包含231个无向连接对。同模块连边继承模块颜色，跨模块连边使用跨模块配色。

![AAL90加权网络四视图](../assets/captures/manual-revision/06-aal90-edges.png)

## 进一步操作

调整阈值并Apply以比较网络密度；连接权重阈值不是P值检验。映射大小或颜色可显示权重，需说明按有符号值还是绝对值筛选。Sparsity选择合格连边的比例，不等于固定权重阈值。保存前恢复本例设置。

仅在源矩阵具有方向意义时使用箭头；本例对称，因此关闭有向绘制。图论连线不是实测白质纤维，欧氏距离不是纤维长度。

## 导出

渲染后设置Export Figure格式、像素/实际尺寸及分辨率。Scene可保存输入顺序和已应用配置。保留[图谱与曲面署名](Resource_Attribution.md)；绘图程序不会推断所给权重的生物学意义或统计显著性。
