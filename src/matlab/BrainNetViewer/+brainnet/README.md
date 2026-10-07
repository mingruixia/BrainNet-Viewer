# `brainnet` MATLAB 包边界

本目录是现代 MATLAB 代码的命名空间，依赖方向如下：

```text
app -> core + io + render
render -> core
io -> core
core -> MATLAB 基础数值能力
regression -> 仅测试适配，不进入科学核心
```

约束：

- `core` 不得依赖 GUI 句柄、`global` 或旧 FIG 回调。
- `io` 记录格式版本、坐标空间、来源和转换；来源不清的旧解析代码不直接迁入。
- `render` 提供确定性无图形准备、缓存及未来图形适配器，为批处理、CPU/GPU 预处理和 Python 公共规范做准备。
- `app` 是 R2025a 界面与命令层，不包含科学算法。
- `regression` 只承担金标准场景适配。

`BrainNetRender` 提供现代 CLI；`brainnet.io.readScene/writeScene/importLegacyConfig` 负责 Scene 读取、保存及旧配置导入。
CLI 是工作流组合层：复用 `app.SceneSession` 这一无图形数据会话类，以及 render/io/export；不实例化 App，不进入旧 GUIDE。
参见项目根目录下 `docs/documentation/Scene_Workflows.en.md` 与 `Scene_Workflows.zh-CN.md`。
