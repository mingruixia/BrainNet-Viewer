# 连边半径：Uniform、Mapped、Raw与Threshold

[English](Edge_Sizes.en.md) · [连边配色](Edge_Colors.zh-CN.md) · [迁移说明](Migration.zh-CN.md)

这里的大小是**输入坐标单位下的半径**，不是像素线宽或直径。输入为已选连边的原始权重；Selection Values、Size Values和配色的Threshold Values分别独立，改变粗细符号模式不会增加被选中的边，也不会重新分配配色组。

## 运算顺序

先按Size Values对原始已选权重使用Signed或Absolute；下表中的权重均指经过这一步符号处理、尚未归一化的值。再执行：

| Size Mode | 乘Size Scale之前的半径 |
|---|---|
| Uniform | Base Size，Size Values不参与。 |
| Mapped | 将全部已选权重线性映射到0.4–6；全部相同时为2。 |
| Raw | 将权重截限到0.2–6，并非无限制的原始半径。 |
| Threshold + Mapped | 在归一化前按权重`>= Size Threshold`找出达标子集，仅对子集映射到0.4–6；子集常量时为2。未达标者为0.4。 |
| Threshold + Raw | 未达标者设为0.4，达标者保留原值，上限截到6；本分支没有0.2下限。 |

最后所有半径统一乘**一次Size Scale**，包括Uniform及未达标的半径。Threshold不删除连边，选择由Visibility控制。达标子集为空时均为0.4，无已选连边时仍为空。这套规则不同于节点大小归一化。

例：Signed权重`[1, 2, 3]`，阈值2、Mapped基准、Scale 2，得到半径`[0.8, 0.8, 12]`。权重2属于达标子集，并映射为该子集最小半径；若达标子集只有一个值，其缩放前半径则为2。

Raw Threshold可能产生零半径，此时不生成管线及箭头几何，但不改变连边选择/Connected语义。负最终半径或数值溢出会给出英文错误，不静默改为绝对值；请根据科学含义提高阈值或选择Absolute。

## 桌面操作

1. 读取节点与连边，在右侧展开 **Edges >**。
2. 在Size区选择Uniform、Mapped、Raw或Threshold。
3. 设置Size Scale；Uniform启用Base Size，其他模式启用Size Values；Threshold额外启用Size Threshold和Threshold Basis。
4. 点击唯一的全局 **Apply** 提交并渲染；**Revert**恢复已应用设置。Save Scene/Save Preset不保存尚未提交的编辑。
5. Save Scene保存输入与视角，Save Preset仅保存设置；Export Figure仍位于Data Sources下方。

有向箭头现有形状规则不变，管线和箭头均使用更新后的半径。大小模式、符号、阈值基准或缩放改变时，几何缓存键随之改变。

![当前 Raw 连边大小设置，使用已获授权的示例数据](../tutorials/assets/captures/topic-guides/edge-size-raw.png)

![当前 Threshold 连边大小设置，使用已获授权的示例数据](../tutorials/assets/captures/topic-guides/edge-size-threshold.png)

## EC与旧配置文件

旧`EC.edg.size=1/2/3`分别为Uniform/加权/Threshold，`size_value=1/2`为Mapped/Raw；加权+Raw导入现代Raw。`size_abs=0/1`独立映射Signed/Absolute，不与draw_abs或color_abs混用。size_size、size_ratio、size_threshold保留各自数值。缺少size_value/size_abs时采用旧默认Mapped/Absolute；已提供但非法的编码会拒绝。导出写回这些字段，Uniform不生效的size_value会规范化。

Settings **1.7.0**增加`edge.size_threshold_basis`、`edge.size_value_mode`及Raw大小模式。Scene v0.1与预设v1.0外壳不变；当前版本缺少必填字段会拒绝。

Settings 1.0–1.6升级默认采用Mapped阈值基准与Absolute粗细取值。**这不能恢复此前被忽略的EC Raw/Signed意图，也不保留旧配置错误的Threshold外观。** Uniform现乘Scale，Threshold改为原始权重/达标子集规则，不再是两档固定半径。请复核旧文件或重新导入未修改的原EC。Scene元数据记录edge_size_upgrade；仅旧输入/设置签名有效时重绑相机，过期绑定保持过期；预设不含相机。

## 范围

改变半径或迁移旧Scene后，若变大的几何超出保留视野，请主动使用 **Fit**。有效的已保存相机会保留，不会静默重新取景。

Mapped配色的符号和范围见[连边颜色](Edge_Colors.zh-CN.md)。[透明度独立符号](Edge_Opacity.zh-CN.md)，现支持[自定义连边索引矩阵](Custom_Edge_Colors.zh-CN.md)。[Inter Hemi Only](Edge_Hemisphere.zh-CN.md)；现支持[稀疏度/并列值](Edge_Sparsity.zh-CN.md)。这些改动不改变连边选择、配色或透明度规则，导入旧配置时，请核对相应显示规则。
