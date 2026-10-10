# BrainNet Viewer 更新记录

## 2.0.0-beta.1

- MATLAB App式桌面界面，移除SPM依赖；新增独立Python桌面版与Docker/Web版。
- 默认1031端口，Docker后台运行，通过浏览器访问。
- 统一文件入口、折叠设置、Apply直接绘图、浅深色主题、场景信息及帮助入口。
- 优化曲面、节点、连边、体图和ROI显示，以及多视图布局和独立相机交互。
- 节点与连边大小支持小数，连边默认缩放0.7；改进稀疏度筛选、有向箭头与模块配色。
- 增加viridis等常用色图；0/null曲面映射值保留原曲面色。
- 根据支持的NIfTI统计描述计算P值阈值，支持簇大小筛选、有符号映射与ROI范围输入。
- 提供AAL/Brodmann坐标Inspect、曲面工具、相机动画、Scene及显示Preset。
- 图片支持像素/实际尺寸、DPI、透明度及溯源；Web图片与sidecar分别下载，Scene打包下载。
- 改善窗口自适应、弹窗焦点、多脑视图和导出后的画布状态恢复。
- 保留12份曲面模板与AAL90网络示例；AtlasNetworks提供14套GroupFC配对文件，包含AAL116、Schaefer1000与Brainnetome246，并更新Brodmann82、Dos160、Fair34、HOA112的连边、模块及连接强度。
- AAL90体积、顶点标签与辅助文件归入图谱资源库，节点/连边教程统一使用AAL90；AAL3v2和Shen278体积文件名与目录名称一致。
- 提供统一英文图文Word/PDF手册、共享教程及中英文Python/Docker安装说明。

软件代码沿用GPL-3.0，附带资源保留来源、引文及相应说明。
部署要求和各版本差异见安装指南。
