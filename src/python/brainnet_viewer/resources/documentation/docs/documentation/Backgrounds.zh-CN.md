# 界面主题、画布与导出背景

- **Theme / Light / Dark**只改变软件界面，不改变科研画布的背景、Scene设置或相机。
- 在 **Visualization Settings → Global → Background Color → Choose Color** 选画布颜色，
  再点 **Apply** 提交并渲染。内嵌及弹出渲染使用同一Scene背景；**Render Scene**
  可显式重绘，Revert撤销待提交编辑。
- App默认以 **current** 导出，保留实际渲染目标的精确RGB，包括自定义颜色，不再
  按亮度简化成黑白。CLI遵循Scene中保存的导出偏好，没有保存偏好时也默认current。
- 曾显式选择白/黑后，可用 `app.configureExport(BackgroundColor="current")`
  恢复跟随画布。仍支持white、black和none。Transparent复选框选择none而不改变
  画布；取消勾选恢复此前的不透明背景策略。JPEG/BMP不支持透明。
  本机R2025a后端会将PNG/TIFF透明请求降级为白底；导出器现检查Alpha是否存在，
  缺失即拒绝，且不替换已有图片及溯源文件。导出后应检查透明度。
- Scene保存/读取保留此策略。已有文件中的显式white/black仍原样保留，无法判断
  它来自用户选择还是旧配置自动换算；如需跟随画布，请明确改设current。
- 导出覆盖不修改当前画布或相机。溯源保留`background_color`请求策略，并补记
  `background_color_resolved`实际RGB或none。底层FigureExporter接口保留历史默认
  白色；直接调用该接口时，需显式传入current才能跟随画布。

发表前，请检查导出图片的背景、透明度和标签对比度。图形后端、输出格式及显示缩放
可能影响结果，尤其是在导出背景与画布背景不同时。
