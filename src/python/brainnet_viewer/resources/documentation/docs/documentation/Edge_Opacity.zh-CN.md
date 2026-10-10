# 连边透明度

[English](Edge_Opacity.en.md) · [配色](Edge_Colors.zh-CN.md)

在 **Edges > Opacity** 中，Uniform使用Value；Mapped通过 **Opacity Values** 独立选择Signed/Absolute，不改变筛选、粗细或配色符号。填写两个输出不透明度上下限，满足`0 <= low <= high <= 1`；不是输入权重范围。0为透明，1为不透明，继续共用全局Apply/Revert。

Mapped将经过符号处理的已选权重最小/最大值线性映射到输出范围，并截限浮点误差。常量权重取上限，避免旧版除零；相同输出上下限产生固定透明度。极小但非零的权重差异正常映射，不再按eps当作常量。拒绝非有限/复数权重及范围溢出。透明度为0不等于删除连边，不改变Connected语义；实际视觉仍受光照、遮挡和图形后端影响。

EC的`opacity=1/2`、`opacity_abs=0/1`、`opacity_same`、`opacity_min/max`支持往返；缺少符号/范围时采用旧默认Absolute/[0.1,0.9]。非法编码和空/倒置/越界范围会拒绝。Settings **1.9.0** 新增`edge.opacity_value_mode`，旧1.0–1.8配置迁移默认Absolute；此前忽略的原EC Signed意图需重新导入原EC。Scene附复核提示，仅重绑有效旧相机签名；Scene/预设外层版本不变。
