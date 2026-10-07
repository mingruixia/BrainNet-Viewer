# M08 · 连边：筛选、方向、大小、颜色与透明度

[English](../en/M08_Edges.md) · [手册目录](index.md) · [稀疏度细节](../../documentation/Edge_Sparsity.zh-CN.md)

开发版首批正文，2026年9月23日对照 **Visualization Settings → Edges** 和Settings 1.22.0核查。`.edge`矩阵行列须对应已加载`.node`的原始行序。权重、坐标距离和有向关系须在数据自身的科学语境下解释；连边长度和箭头均不等于白质纤维束。统一 **Apply** 提交并渲染；**Revert** 撤销待提交编辑。

## 可见性与方向

| 控件 | 新设置默认值 | 当前规则 |
|---|---|---|
| **Selection** | All Edges | All保留符合条件的非零、非对角边。Threshold保留筛选值`>= Threshold`（包含等号）。Sparsity (Top Count)对非零候选排序，保留确定数量。Sparsity (Legacy Threshold)排序整个N×N矩阵，把排位值化为六位小数截点，再保留所有符合条件的截点并列边；两种稀疏度**不等价**。 |
| **Threshold / Sparsity** | 0 / 0.1 | Threshold数值仅在Threshold模式使用；Sparsity比例为0–1，供两种稀疏度模式使用。Top Count比例0不选边；Legacy Threshold比例0仍取矩阵最大值，该值在对角线上时可无可见边。 |
| **Selection Values** | Absolute | Signed/Absolute只改变筛选/排序，不改源权重；大小、颜色、透明度各有独立符号选项。 |
| **Directed Edges** | 关闭 | 关闭时使用非零上三角候选；开启时使用非零、非对角的有序节点对，并画箭头。矩阵不会自动对称化。 |
| **Inter Hemi Only** | 关闭 | 筛选之后按节点X=0保留跨X侧或涉及中线的端点；这是坐标规则，不是解剖半球检测。 |

Top Count遇到并列权重按MATLAB列主序线性索引决定；Legacy Threshold可能保留全部并列边，所以最终密度未必等于所填比例。M07的Connected Nodes依赖最终选出的连边对。详见[稀疏度与并列值](../../documentation/Edge_Sparsity.zh-CN.md)和[X侧筛选](../../documentation/Edge_Hemisphere.zh-CN.md)。

## 大小与箭头

| 控件 | 新设置默认值 | 当前规则 |
|---|---|---|
| **Size Mode** | Mapped | Uniform用Base Size；Mapped把保留边权重映射为0.4–6半径（常量集合为2）；Raw夹取到0.2–6；Threshold先以原始符号处理后的权重比较`>= Size Threshold`，再按Mapped或Raw计算达标边。低于阈值者用0.4半径，不删除边。 |
| **Base Size / Size Scale** | 1 / 1 | Base Size仅Uniform使用；正数Size Scale在所有模式下只乘一次。数值是输入坐标单位下的半径，不是像素线宽。 |
| **Size Threshold / Threshold Basis** | 0 / Mapped | 仅Threshold启用；Basis选Mapped或Raw，阈值比较发生在归一化和缩放之前。 |
| **Size Values** | Absolute | Signed/Absolute与Selection Values及颜色/透明度符号独立。负的无效最终半径会报错，不静默取正。 |
| **Arrowhead Shape: Length / Width** | 1 / 0.7 | 仅Directed Edges启用；比例范围0.25–3，长度最多为边长的35%。边管在箭头底部终止，避免重叠。只改变几何，不改变矩阵方向或权重。 |

Threshold+Raw的最小半径规则不同于普通Raw，详见[完整半径计算](../../documentation/Edge_Sizes.zh-CN.md)。零半径边可能不绘制几何，但不改变筛选或Connected语义。

## 颜色与透明度

| 控件 | 新设置默认值 | 当前规则 |
|---|---|---|
| **Color Mode** | Uniform | Uniform用单色。Mapped用64级色图。Threshold在值`<= Color Threshold`时用Low，`>`用High；Length按原始节点欧氏距离`< Length Threshold`用Short，`>=`用Long。Node Module比较两端模块；Custom Matrix使用明确绑定节点行序的颜色索引矩阵。 |
| **Color / Colormap / Color Limits** | `[1 0.9 0.73]` / Jet / Auto | Color按钮用于Uniform；Mapped/Custom Matrix使用下拉选择的具名色图或Custom (Colors...)，固定`low high`只用于Mapped。Auto采用选中边的颜色权重范围（完成符号处理后）；上下限相等时取色图末色。 |
| **Color Threshold / Length Threshold** | 0 / 0 | Threshold配色使用原始权重及其独立符号选项，等号归Low。Length使用输入XYZ坐标单位，不是纤维束/测地长度；等号归Long。 |
| **Threshold Values / Mapped Values** | Absolute / Absolute | 分别只用于对应颜色模式的Signed/Absolute；不改变Selection Values、半径或透明度。 |
| **Low / High；Inter-module Color** | 灰`[.38 .38 .38]` / `[1 .9 .73]`；灰`[.5 .5 .5]` | Low/High用于Threshold或Length（按钮变成Short/Long）。Node Module下同模块边取Nodes模块色图，异模块边取Inter-module Color；若希望可见节点颜色一致，请选Nodes → Modules。 |
| **Load Colors... / Bind to Nodes** | 无矩阵 | 仅Custom Matrix使用。须核对矩阵大小及原始节点行序；绑定不能独立证明科学对应关系。 |
| **Opacity Mode / Value / Range** | Uniform / 0.7 / `[0.1 0.9]` | Uniform使用单一0–1透明度；Mapped把已选边权重映射至[0,1]内的两个**输出**透明度端点，常量权重取上端点。透明边仍是已选边。 |
| **Opacity Values** | Absolute | 仅Mapped透明度的Signed/Absolute，与筛选、大小及颜色独立。 |

**Node Module**色图来自Nodes的colormap；Edges色图下拉框不能覆盖它。此模式最多支持20个不同模块，超出会报错而非循环复用颜色。Custom Matrix配色需[明确绑定并核对格式](../../documentation/Custom_Edge_Colors.zh-CN.md)。颜色阈值/长度端点详见[连边配色](../../documentation/Edge_Colors.zh-CN.md)，映射透明度见[连边透明度](../../documentation/Edge_Opacity.zh-CN.md)。显示选项不修改`.edge`文件，也不证明配准。

当前构建集成数值/目视复核、高负载性能与发行截图仍属发行验收工作；本章不保证与旧渲染器逐像素一致。
