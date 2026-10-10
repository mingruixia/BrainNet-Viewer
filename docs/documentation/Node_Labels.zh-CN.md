# 节点标签字体与位置

在 **Visualization Settings → Nodes** 设置Label Mode、字体/字号、**Font Style**（Normal/Bold、Normal/Italic）、**Font Units**、Label Color及Keep Labels in Front。唯一全局Apply会提交并渲染；Revert放弃未提交编辑。标签按字面显示，下划线和反斜线不解释为TeX；单独`-`不显示。专项验证的可见性及严格阈值规则不变。

现在完整往返旧`EC.lbl_font.FontName/FontSize/FontWeight/FontAngle/FontUnits`。支持points、pixels、normalized、inches、centimeters；字号按所选单位必须大于0且不超过100。切换单位不换算原数值，尤其使用normalized或物理单位时需重新选择合适字号；实际字形依赖本机字体，论文图建议使用points。

标签按当前节点实际绘制半径加1个坐标单位，沿相机画面向上方向放置。每个视图独立计算，旋转、恢复相机、Fit及Reset时更新。这是对旧版按视图编号分别偏移x/y/z并混合左右对齐的现代替代，不承诺逐像素复现；节点科学坐标及几何不变。

Keep Labels in Front将锚点投影到显示几何边界前的相机朝向平面；透视模式保持锚点投影位置，它仅解决深度位置，**不是标签自动避让**：密集标签仍可能相互重叠。渲染器检查投影字框，将越界标签整条暂时隐藏；相机/尺寸变化时重算可见性，可根据情况缩放、平移、扩大面板或减小字号恢复。不截短文字或自动缩放字号；未提供标签自动避让。相机进入几何包围盒时不存在既位于全部几何前又位于观察者前的平面，此时回退到半径偏移锚点。标签不阻挡节点/图谱拾取。

Settings **1.14.0**新增粗细、斜体及单位。旧现代配置保持Normal/Normal/Points默认值；先前遗漏的字体属性需重新导入原EC恢复。Scene提示复核标签位置，仅有效旧相机签名重绑；Scene/预设保存字体配置。位置修正可能改变已有截图外观。
