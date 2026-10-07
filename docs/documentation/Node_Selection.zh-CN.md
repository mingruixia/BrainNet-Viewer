# 节点选择、标签与Connected

后续更新：[开发版 / Settings 1.6连边配色](Edge_Colors.zh-CN.md)保留本页节点规则，并增加连边迁移复核要求；下文版本号描述本节点专题对应阶段。

BrainNet Viewer 2.0开发版 · 开发版 · Settings 1.5

[English](Node_Selection.en.md) · [节点大小](Node_Sizes.zh-CN.md) · [节点配色](Node_Colors.zh-CN.md)

## 显示规则

| 控件 | 规则 |
|---|---|
| Selection: All Nodes | 显示全部输入节点，但最终半径须有效且非零 |
| Selection: Threshold | 原始依据值严格 **> Threshold**，等于时排除 |
| Selection: Connected Nodes | 当前连边筛选结果中任一边的任一端点 |
| Label Mode: All Labels | 显示可见、非零半径节点的标签，排除单独的短横线标记 |
| Label Mode: No Labels | 不显示节点标签 |
| Label Mode: Threshold | 在可见节点中，原始标签依据值严格 **> Label Threshold**，且不是短横线标记 |

两种阈值的 **Node Value** 均指.node原始第5列，**Module** 指第4列；Selection Basis和Label Basis相互独立。比较不使用映射半径、Scale、节点颜色或计算出的网络度数。Module仍是数值`>`比较，不是“等于某个模块编号”。

标签恰好为 `-` 时不显示文字，但节点仍可绘制；`C-D`等含短横线名称保留。标签按原文字显示，不解释为TeX。标签筛选仅对可见节点再次过滤，不能让隐藏节点重新出现；零半径沿用[大小规则](Node_Sizes.zh-CN.md)。

## Connected的含义

旧版在Nettrans筛选连边之后检查`surf.cylinder(:,1:2)`中的节点编号。现代EdgePairs已有这个含义；开发版保留该实现并增加反例验证，不改成按原始矩阵判断。

- 无向模式使用非零上三角元素，有向模式使用非零非对角元素；节点既可为起点，也可为终点，不自动对称化原矩阵。
- 对角线不使节点成为Connected；没有保留下来的边时，不显示Connected节点。
- 连边Threshold在Signed/Absolute规则后保留 **>=阈值** 的边，与节点/标签的 **>** 有意不同。All模式或阈值允许时可保留负边。
- 现代Sparsity沿用其当前保留的边集合；其分母和并列值策略不在本轮旧版等价保证内。
- Connected在半球/视图拆分前全局判断。跨半球边可使两端节点成为Connected，即使该边本身不在某个半球视图中绘制。

Connected是显示规则，不表示被隐藏节点在原始网络中的度数为零。改变连边筛选可改变Connected节点及标签；节点筛选本身不删除输入边。旧Inter Hemi Edges仍为开放兼容项，不能由本轮结论推断已支持。

## 界面操作

1. 读取节点，使用Connected时还需读取连边。展开 **Visualization Settings → Nodes >**。
2. 在Visibility选择Selection；Threshold启用依据与阈值，Connected使用连边配置并禁用不生效的节点阈值控件。
3. 在Labels选择Label Mode；Threshold启用独立的Label Basis与Label Threshold。
4. 用底部唯一 **Apply** 提交并渲染；**Revert**恢复上次提交。Save Scene/Save Preset保存已应用的值。

![节点选择和标签控件](../tutorials/assets/captures/tutorial02-nodes/02-nodes-threshold-full-window.png)

GS05内部验收截图，不是已清权公开教程，可能包含本机路径。控件保持英文；本轮不保证标签无碰撞、强制前置、字重/字形支持或原生鼠标对话框体验。

## EC与迁移

保留EC对应：nod.draw=1/2/3为All/Threshold/Connected，nod.draw_threshold_type=1/2为第5/4列；lbl=1/2/3为All/None/Threshold，lbl_threshold_type=1/2为第5/4列；nod.draw_threshold与lbl_threshold为独立阈值。两种依据均有往返测试，原EC不改写。

Settings 1.0–1.4升级到 **1.5**，仅标记语义版本，不新增控件字段。恰等阈值时节点/标签可能减少，单独的`-`文字会消失，旧开发图像须复核。保留阈值和依据，不自动调数值来模拟此前错误的`>=`结果；Connected行为不变。

旧Scene元数据附node_selection_upgrade，仅核对旧规范化输入/设置签名有效后重绑相机，过期不重绑。预设只升级设置，不带相机；Scene v0.1、预设v1.0外层不变，不保证旧构建读取Settings 1.5。此前配色和大小迁移要求仍适用。

参见[剩余兼容限制](Migration.zh-CN.md#known-limitations)。连边颜色/大小/透明度语义及标签布局仍为独立后续任务。
