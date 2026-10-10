# 连边稀疏度与并列权重

在 **Visualization Settings → Edges → Selection** 选择模式、输入0–1比例，再点击全局 **Apply** 提交并渲染。两种稀疏度模式均要求 **Modern Batch Renderer**。

| 模式 | 排序及截断 | 并列值与端点 |
|---|---|---|
| Sparsity (Top Count) | 仅按非零、非对角候选边排序；无向取上三角，有向取双向。保留ceil(比例×候选数)条。 | 并列时按MATLAB列优先线性索引升序；比例0不选边，1保留全部候选边。 |
| Sparsity (Legacy Threshold) | 整个N×N矩阵排序，含对角、零值及双三角；比例×N²四舍五入并限于[1,N²]，取对应权重，再按旧界面保留6位小数作为阈值。 | 非零、非对角候选边满足>=阈值即保留，包含全部阈值并列边。比例0仍取最大值；若最大值在对角上可能没有可见边。阈值向上舍入也可能排除对应原边。 |

Selection Values控制Signed/Absolute排序，原始边权不变。无向模式取上三角，不对非对称矩阵求平均。半球筛选在其后执行且不补足边数；Connected节点使用最终边集。比例不保证最终密度：零值、并列权重、方向、半球及后续外观设置均会影响结果。Top Count在固定节点顺序下可复现，但并列边的选择不具有节点重编号不变性。已有Scene/预设保留原Top Count结果。

Settings **1.13.0**新增`selection_mode="legacy-sparsity"`；原`sparsity`仍为Top Count。Scene/预设保存模式和比例，仅有效旧相机绑定可迁移。

旧EC存的是阈值，**不是稀疏度比例**，因此导入为Threshold是正确行为，不能反推原比例。需要针对具体数据转换时，`settings.toLegacy(edgeMatrix)`用准确矩阵换算Legacy Threshold，并提示丢失自适应比例；重导入在该矩阵上保留相同边集，但换矩阵后阈值不会自动变化。未提供矩阵明确拒绝。Top Count在边界并列时通常无法用单阈值表示，因此拒绝EC转换，请用Scene/预设或明确设置阈值。旧配置若将无关Threshold字段静默写入EC，缺少源设置/数据时不能修复。
