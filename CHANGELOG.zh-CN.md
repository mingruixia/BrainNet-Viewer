# BrainNet Viewer 更新记录

## 尚未发行

- 分离Web命令启动试绘与库调用，嵌入/测试调用不再替换当前进程。
- 保留WSL可选显卡选择、统一软件绘图识别，启动就绪等待延长至90秒。
- 增加真实HTTP/WebSocket认证及GIfTI预检回归、仿射读取夹具和限定MATLAB读取CI。
- wheel检查核对MATLAB/Python版本对应，Python包版本来源集中管理。
- 补充受信任本机单用户安全模型及Compose资源限额配置。

- Web的Scene File/Open及Save Scene/Import Settings布局与桌面版对齐。
- 静止画面采用2倍采样，保持文字大小，避免Apply后采样叠加；交互期间降低传输分辨率及JPEG质量。
- CPU交互临时降低曲面细节，静止、Inspect、Scene及导出恢复原几何；GPU始终使用完整几何。
- 启动时通过隔离试绘核验GPU，不可用则回退CPU；本机启动工具支持Auto/GPU/CPU选择。
- pypdf升级至6.19.0，XML使用defusedxml防止实体扩展。
- MATLAB及Python节点读取保留标签内部的`#`。
- Python Scene强化路径、重复键、非有限值及JSON大小检查；便携资产先暂存核验，再提交新Scene，避免覆盖已有文件。
- 本机Web限制Host/Origin，通过同源请求取得每次启动的随机认证key；适用范围仍为本机单用户。
- 源码Docker构建使用固定Python 3.12底座，增加依赖核验及HTTP健康检查；ARM64源码绘图尚未验证，已发布镜像不变。
- 明确项目代码使用GPL-3.0-or-later，随附资源保留各自条款。

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

软件代码使用GPL-3.0-or-later，附带资源保留来源、引文及相应说明。
部署要求和各版本差异见安装指南。
