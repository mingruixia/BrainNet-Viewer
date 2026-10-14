# 图谱ROI与统计簇ROI

在 **Volume / ROI** 启用 Display，选择 **ROIs (Atlas / Statistical)**，
仍通过右侧统一的 **Apply** / **Revert** 提交或撤销。

| Threshold Mode | ROI Selection中的编号含义 |
|---|---|
| None | 图谱原有正整数编号不变；不应用数值阈值和簇大小 |
| Value | 对有限非零且 `abs(value) >= abs(threshold)` 的体素连通成簇；不筛选最小簇大小 |
| Cluster | 先执行上述数值阈值，再移除体素数小于Cluster Size的簇 |
| P Value | 依据受支持的NIfTI T/F/R/Z元数据换算未校正统计量阈值，再移除小于Cluster Size的簇 |

Value、Cluster和P Value按MATLAB `bwlabeln`的连通分量顺序，在**过滤后**从1连续编号，
不是按簇大小排序。修改阈值、簇大小或6/18/26邻域后，编号可能变化。
ROI Selection选择此时的簇编号；Draw All选择全部保留簇。
相邻正负值合为同一簇，与旧版非零掩码规则一致，不是正负分别检验。

数值阈值和最小簇大小均保留等号；阈值为0时零仍为背景。NaN/Inf在连通前排除。
簇大小为0或1保留所有非空簇。统计ROI用簇编号构建网格；表面映射仍保留过滤后的
统计数值。原始输入及空间仿射不变。准备阶段溯源记录表示类型、过滤情况、
符号规则及保留簇体素数。

## 迁移与限制

- 复现旧统计ROI的数值＋簇大小过滤，应选 **Cluster**，数值阈值为0时也一样。
  EC配置不包含旧版运行时的 `surf.test` 标志；导入EC后须核对数据类型及所有参数。
  软件不会根据元数据自动判断输入是否为统计图。
- 旧配置ROI分支忽略阈值设置；已有Value/Cluster场景本次会有意改变输出，
  图谱应选None。序列化字段和Settings 1.14版本号不变。
- ROI P Value现与Surface Map共用NIfTI描述/intent换算，并按旧版ROI顺序在逐体素筛选后
  再使用Cluster Size；见[手册M09](../manual/zh-CN/M09_Volume_Mapping.md)和
  [M10](../manual/zh-CN/M10_ROI_Inspection.md)。这不能证明簇水平显著性，也不提供多重比较校正。
  现支持[按编号自定义ROI配色](ROI_Colors.zh-CN.md)，缺色不再回退。
- 现支持[边界闭合及整ROI未平滑回退](ROI_Geometry.zh-CN.md)，应检查
  `roi_geometry.unsmoothed_fallback_labels`和`skipped_labels`。
  现支持逐分量保守存续检查并在风险时整ROI回退，不承诺完整拓扑或旧膨胀几何/像素对等。

详
