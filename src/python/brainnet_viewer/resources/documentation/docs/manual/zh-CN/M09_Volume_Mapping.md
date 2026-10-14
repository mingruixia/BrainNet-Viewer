# 体到曲面映射与统计控件

[English](../en/M09_Volume_Mapping.md) · [手册目录](index.md) · [正负色轴规则](../../documentation/Volume_Display.zh-CN.md) · [真实T图教程](../../tutorials/zh-CN/05_Volume_to_Surface_Mapping.md)

NIfTI可读取并不等于与另一份曲面已配准。映射通过体数据仿射矩阵把曲面坐标换算为体素位置取样，**不会**执行图像配准。解释空间位置前须核实曲面/体坐标空间和单位。**Apply** 提交并渲染；**Revert** 撤销待提交设置。

Volume面板把 **Threshold Mode**、**Statistical Threshold**、**P Value**、**Cluster Size** 和 **Voxel Connectivity** 放在 **Surface Mapping** 分组上方，因为它们也控制统计ROI。控件按Volume Type及Threshold Mode启用；ROI的P Value使用Cluster Size，Surface Map的P Value不使用。

| 控件 | 新设置默认值 | 当前规则 |
|---|---|---|
| **Display Volume** | 关闭 | 启用所选Volume Type；载入文件本身不证明其科学适用性。 |
| **Volume Type** | Surface Map | Surface Map把三维体映射到已载入曲面；**ROIs (Atlas / Statistical)** 提取标签网格，使用M10控件。 |
| **Mapping Algorithm** | 2 | 只用于Surface Map。八种算法具有不同数值含义，并非简单的低/高质量档。 |
| **Threshold Mode** | None | None保留数值；Value保留有限且`abs(value) >= abs(Statistical Threshold)`的值；Cluster再按连通分量体素数过滤。P Value依据NIfTI统计元数据换算体素阈值；在ROI模式下还按Cluster Size过滤，见M10。 |
| **Statistical Threshold / P Value / Cluster Size / Voxel Connectivity** | 0 / 0.05 / 0 / 18邻域 | Value与Cluster使用数值阈值；Cluster再使用体素数及6/18/26邻域。P Value须满足`0 < P < 1`且统计元数据有效。源数据不被改写。 |

Value/Cluster中零是背景，非有限体素排除，绝对值阈值等号保留；Cluster删除**小于**Cluster Size的分量。6/18/26用于统计簇连通，不等同ROI平滑保护中的26连通检查。Cluster过滤可改变后续映射值及色标范围。详见[统计ROI规则](../../documentation/Statistical_ROI.zh-CN.md)。

P Value从SPM、REST或DPABI生成的NIfTI描述读取统计量与自由度（如`SPM{T_[20]}`、`REST{F_[3,20]}`、`DPABI{R_[20]}`或Z标记）；缺少描述时，可使用标准NIfTI CORREL/TTEST/FTEST/ZSCORE intent及其参数。缺少或无效自由度会明确报错，不会静默退回数值阈值。T、R、Z使用**双侧**未校正P；F使用**上尾**并排除负F值。渲染准备/溯源记录换算后的统计量阈值、自由度、检验尾部和元数据来源。先过滤体素再映射；插值或邻域平滑之后的顶点值不等同于逐体素P值检验。本功能不执行多重比较校正或空间配准。

## 映射算法（Surface Map）

| 编号/菜单 | 计算方式及边界提醒 |
|---|---|
| **1 · Nearest Voxel** | 对换算后的曲面位置四舍五入，取最近体素；无效/体外位置返回零。 |
| **2 · Average Surface Neighbors** | 先取算法1的值，再把每个顶点与其曲面网格邻点（含自身）平均。这是**曲面邻接平均**，不是3×3×3体素平均；结果依赖网格拓扑。 |
| **3 · Average 3-by-3 Voxel Neighborhood** | 先对体数据做3×3×3均值滤波，再最近体素取样；体边界依滤波实现处理。 |
| **4 · Gaussian Voxel Smoothing** | 先用MATLAB `smooth3(...,'gaussian')`平滑体数据，再最近体素取样；会改变数值，并可能混合邻近标签或符号。 |
| **5 · Trilinear Interpolation** | 在有效内部位置使用包围它的八个体素三线性插值；不在支持的内部范围时返回零。 |
| **6 · Maximum 3-by-3 Voxel Neighborhood** | 有效内部四舍五入位置取27个体素的最大值。 |
| **7 · Minimum 3-by-3 Voxel Neighborhood** | 有效内部四舍五入位置取27个体素的最小值。 |
| **8 · Extremum 3-by-3 Voxel Neighborhood** | 取27个体素中**绝对值最大**的样本，并**保留原符号**。 |

CPU支持全部八种算法。当前GPU映射路径只支持算法1、5；对其他算法显式请求GPU时，会记录原因并回退CPU。Auto仅在算法5、曲面足够大且有受支持GPU时选择GPU，否则用CPU。这是执行策略，不保证所有数据上都更快。

## 范围与正负显示

| 控件 | 新设置默认值 | 当前规则 |
|---|---|---|
| **Positive Range / Negative Range** | Auto / Auto | 可填`Auto`或最小/最大值（任一端点可Auto）。手动范围在切换体文件后仍保留，Scene摘要会标明；每换数据都应复核。**Auto Ranges**只重置*待提交*字段，仍须点 **Apply** 提交并渲染。 |
| **Colormap** | Blue-White-Red | 统一256级色图：下半部代表负值，上半部代表正值；可用Colors...指定自定义RGB。Surface面板的标量色图独立。 |
| **Display Values** | Positive & Negative | Both、Positive Only、Negative Only改变**色轴，并非删除其他顶点值**。Both即使正负幅度不同也使用围绕零的对称`[-M,+M]`；单侧模式使用对应半段色图。超范围值夹取到端点色。 |
| **Adjust for Null / Null Color** | 开启 / `[0.95 0.95 0.95]` | 开启时用Null Color显示零值附近色阶；关闭时有限值连续使用色图。仅开启时可编辑Null Color；不改取样数值。 |

Both使用对称色轴，幅度较小的一侧可能颜色较淡。请结合数值和色条判断，不要仅凭颜色推断效应是否存在。解剖解释还需核对体图与曲面的空间配准。见[正负色轴说明](../../documentation/Volume_Display.zh-CN.md)。

目前**没有**多重比较校正；解释结果前须核对源图的统计量、自由度、坐标对齐和研究所需的推断策略。
