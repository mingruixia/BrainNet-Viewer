# 坐标半区与解剖左右标记

**Show Orientation Labels**控制多视图布局2–5的两个分图标记；单视图无此标记。
标记表示非正X/正X半区所属的分图，不是相机旋转后的屏幕边缘方向。
Layout 2的[六完整数据视图回退](Layout_2.zh-CN.md)同样不显示半区标记。

未经确认的Scene现显示 **X<=0 / X>0**，不直接写解剖L/R。unknown、带MNI名称、
人脑、动物脑、原生或自定义坐标都遵循同一规则，不能凭名称认定方向或配准。
现有分区算法未变：节点按X符号，网格三角面按重心X分类；不意味着精确沿中线裁切。

## 明确确认解剖方向

只有核对所有显示输入处于预期共同坐标、X=0确为解剖中线、X轴正方向已知后，
才应封存输入哈希并确认。本步采用Scene/API，尚未新增图形化确认对话框：

```matlab
sealed = app.saveSceneFile("scene-before-orientation.json");
confirmed = brainnet.core.OrientationLabels.confirm(sealed, "right", ...
    MidlineIsXZero=true);
app.setScene(confirmed);
app.saveSceneFile("scene-confirmed.json");
app.renderCurrentScene(Target="embedded");
```

只有X增大指向解剖左侧时才用`"left"`。这只交换L/R文字，不变换几何、不交换相机，
也不执行配准。不要为了恢复旧外观而确认。缺少输入哈希或未确认X=0中线会报错。

可选的`metadata.orientation_labels`记录1.0版本、`x_positive`、
`midline_is_x_zero`和`input_signature`，绑定所有Scene输入引用（含哈希）及
坐标空间声明。输入/坐标声明改变、声明格式不正确或缺少哈希时，恢复坐标标记；
重新核对数据后才可再确认。显示预设不携带该Scene专属元数据。此确认仍是用户声明，
不代表软件已独立验证配准。

## 对比度、导出与兼容性

现代标记采用黑白文字与反色不透明底色，显式覆盖导出背景不会使文字与自身底色
失去对比；切换界面主题不改标记。渲染和导出溯源记录实际标记策略及原因。
本步不是全部节点文字的自动对比度修复。

现代App的Legacy Renderer适配入口在多视图标记未确认、确认失效或正X指向左时
明确拒绝：请改用Modern Batch Renderer，或关闭Show Orientation Labels。
原始旧版代码及外部旧版启动路径未改动，旧标记样式也不在本步现代化。

无Scene/Settings版本升级，无自动坐标推断、重采样或新增配准。动物数据可在同样
核对后使用L/R，物种本身不是方向依据；导出后应检查标签清晰度。
