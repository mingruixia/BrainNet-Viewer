# 渲染细节

[English](Render_Detail.en.md) · [手册](../manual/zh-CN/index.md)

在 **Visualization Settings → Global** 中选择 **Render Detail**，再点击共享的 **Apply**。该选项会保存到当前Scene和显示预设。

| 选项 | 节点球面细节 | 连边圆柱边数 | 含义 |
|---|---:|---:|---|
| Adaptive (modern) | 策略选择 | 策略选择 | 默认。现代渲染器按负载和渲染模式选择正常的交互/质量细节。 |
| Low (legacy) | 10 | 5 | 与旧版 `EC.glb.detail = 1` 的几何值严格对应。 |
| Moderate (legacy) | 50 | 10 | 与旧版 `EC.glb.detail = 2` 的几何值严格对应。 |
| High (legacy) | 100 | 20 | 与旧版 `EC.glb.detail = 3` 的几何值严格对应；大型网络可能耗时较高。 |

该选项只改变节点和连边的几何细节，不会重采样、平滑、配准或以其他方式修改曲面网格。脚本中直接传入的渲染器 `NodeDetail` 或 `EdgeSides` 仍具有最高优先级。

导入旧EC时，数值细节代码会对应Low、Moderate和High。已有及新建现代Scene默认使用Adaptive，从而保持原有按负载自适应的行为。旧EC没有Adaptive代码：导出Adaptive现代设置时会写为旧版High (3)，即旧版历史默认值。旧EC中超出1–3的数值沿用已有枚举夹取兼容规则。

提高细节会增加几何量和内存用量，密集网络尤其明显。探索数据时可选择较低细节，最终导出时再检查效果。
