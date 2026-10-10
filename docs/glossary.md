# Controlled UI glossary / 受控界面术语表

Updated 2026-09-23. The first column is the actual English UI/API term. Chinese prose explains the term without translating software buttons.

| English term | 中文解释 | Scope / 注意事项 |
|---|---|---|
| Data Sources | 数据来源 | 按角色选择，不要求所有文件同时读取 |
| Validate and Load | 校验并载入 | 不代表自动配准 |
| Visualization Settings | 可视化设置 | 右侧单开折叠面板 |
| Apply | 提交设置并渲染 | 当前App一次完成提交与渲染；Render Scene用于显式重绘 |
| Revert | 撤销未提交设置 | 不删除输入；不是全部恢复默认 |
| Render Scene | 显式重绘场景 | 不要求在成功Apply之后重复点击；加载预设后需重新渲染 |
| Reset | 恢复相机 | 画布按钮，不是重置全部配置 |
| Fit | 适配取景 | 改变相机，不改科学坐标 |
| Rotate / Pan / Zoom | 旋转 / 平移 / 缩放视图 | 不进行数据配准 |
| Inspect | 画布内查询 | 默认按类MNI坐标查AAL/Brodmann；不执行配准变换 |
| Scene | 场景 | 输入引用、设置及有效会话状态；不打包数据 |
| Preset | 显示预设 | 设置而非输入/相机/导出面板偏好 |
| Surface Map | 表面标量映射 | 不等于N×3顶点RGB |
| Node color value | 节点配色值 | .node第4列供Mapped/Threshold使用；大小值为第5列 |
| Node size value | 节点大小值 | .node第5列 |
| Connected Nodes | 有连接的节点 | 当前筛选后任一边的任一端点；不等于原始网络度数判断 |
| Threshold Values | 连边配色数值方式 | 只供Threshold颜色使用的Signed/Absolute，独立于筛选Value Mode |
| Low / High edge color | 连边低/高值色 | Threshold的<= / >两固定色；不是连续色图 |
| Short / Long edge color | 连边短/长距离色 | Length的< / >=两固定色，按原始XYZ欧氏距离；不自动认定毫米或纤维束长度 |
| Selection / Label Threshold | 节点选择/标签阈值 | 在原始第5或4列上独立做严格>比较；不使用映射后半径 |
| Raw node size | 原始节点大小 | 不归一化，来源值乘Scale作为坐标单位下的半径；旧EC size_value=2不表示Module |
| Size Threshold | 大小阈值 | 在映射/原始半径上比较；严格低于者置1，然后乘Scale，等于时保留 |
| Modern Automatic | 现代自动边界 | 与Legacy Automatic语义区分 |
| Custom Mask | 自定义边界掩码 | 原始顶点顺序，绑定几何 |
| Export Figure | 导出图像 | 左侧面板 |
| Export Animation... | 导出相机动画 | 不等于时变连接或实时Demo |
| Safe Fit | 旋转安全取景 | 只作用于电影导出副本 |
| Provenance | 溯源记录 | 文件身份不等于解剖/统计有效性 |
