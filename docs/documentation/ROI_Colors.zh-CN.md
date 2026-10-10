# ROI自定义配色

在 **Volume / ROI** 的ROI Color Mode选择 **Custom**，通过
**Load ROI Colors...** 导入，或直接编辑下方文本框。
统一 **Apply** 提交色表并渲染，**Revert** 恢复上次提交的色表；读取文件本身不改变绘图。

TXT/CSV每行是 `ROI_ID R G B`，空格或逗号分隔，不带表头。
编号为唯一正整数，RGB为0–1范围内有限值，不使用0–255。
最多10,000行，输入文件不超过2 MB。例如：

```text
8 1 0 0
42 0 0 1
```

要试用 **Load ROI Colors...**，可将上面两行复制到 `.txt` 文件。颜色绑定编号，而非色表行顺序或选择顺序。
允许多余编号，但体数据中实际存在且被选中的每个编号都必须有颜色；
缺色明确停止准备并报错，**不再回退索引色**。无有效ROI时不生成网格。
Uniform与Label Index模式保持原行为。

图谱使用体素原编号；统计ROI使用过滤后连续编号的簇。修改阈值或邻域后编号可能
变化，必须复核配色。色表不证明解剖配准，也未绑定特定图谱/文件；
详见[统计ROI规则](Statistical_ROI.zh-CN.md)。

## 保存与迁移

Settings **1.16**将色表存入 `roi.custom_colors`，随Scene/Preset JSON内嵌保存，
并参与准备缓存键。旧场景补空表；原Custom→Index回退已取消，须提供色表或明确
改用Label Index。记录迁移提示；有效相机绑定迁移，失效绑定不重新激活。

旧EC按位置配色：`vol.roi.color(i,:)`对应`draw(i)`。导入优先使用已应用的draw，
draw为空时用drawt；启用ROI且携带色表、但编号缺失或无效时拒绝猜配。
未提交的colort修改不导入。导出EC需关闭Draw All并提供非空明确选择，
颜色行按该选择重排。自定义ROI须使用Modern Batch，不通过旧GUI适配器渲染。
后续现支持[边界及小ROI处理](ROI_Geometry.zh-CN.md)，不承诺旧网格完全对等。
