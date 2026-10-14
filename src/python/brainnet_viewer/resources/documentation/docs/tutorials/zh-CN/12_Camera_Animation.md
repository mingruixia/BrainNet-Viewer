# 12 · 真实脑曲面的相机动画

[English](../en/12_Camera_Animation.md) · [教程目录](index.md) · [导出手册](../../manual/zh-CN/M12_Export.md) · [动画机制](../../documentation/Movies.zh-CN.md)

本教程是**围绕静态曲面旋转相机**，并非脑活动或连接随时间变化。使用真实`BrainMesh_ICBM152_smoothed.nv`（SHA-256 `aff1920baef51956971b8c1de068e8eee2d1279f21fc90452bcd0dba2794fdc5`）。分发曲面或衍生图时保留Prof. Alan C. Evans（MNI）署名。先用仅4帧的PNG序列核对流程；需要流畅展示时，检查结果和耗时后再增加帧数。

| 控件 | 练习参数 | 含义 |
|---|---|---|
| Layout → Preset / View Direction | Single View / Isometric | 一个三维相机；绕世界轴旋转不改变解剖坐标。 |
| Surface → Color Mode / Opacity | Uniform / 1 | 不透明中性曲面，无标量映射或色条。 |
| Animation → Format / Width / Height | PNG / 640 / 480像素 | 可迁移逐帧序列，不依赖视频编码器。 |
| Duration / Frame rate | 1秒 / 4 fps | 用于检查的4帧，故意不是流畅播放设置。 |
| World rotation axis / offsets | Z / 0° → 360° | 相对当前相机绕行一周，省略重复的360°末帧。 |
| Safe Fit | On | 在独立导出渲染器中让整段旋转尽量保持几何完整。 |

## 步骤 01 · 读取并渲染

在新项目根目录执行`app = BrainNetViewer;`。通过 **Data Sources → Add Files** 把`Data/SurfTemplate/BrainMesh_ICBM152_smoothed.nv`选为 **Surface Mesh**，点 **Validate and Load**。在 **Visualization Settings** 选择 **Single View**、**Isometric**、**Uniform**、**Opacity 1**、**Boundary None**，再点共用 **Apply**。必须先有当前Modern Batch Renderer渲染结果，动画导出入口才可用。可先点 **Fit** 或 **Rotate** 设定起始相机；它改变绕行基准，不改变曲面坐标。

## 步骤 02 · 设置4帧PNG绕行

选择 **Tools → Export Animation...**，按表格设置。该窗口把*当前已渲染Scene*导出为**新文件夹**，不是单个`.png`，也不会替换主画布。点 **Export...**，在已有父目录下选一个新名称，如`icbm-orbit-check`。再次运行须另选新名称，已有结果文件夹会被拒绝。

![真实ICBM152四帧PNG练习所用英文动画设置窗口](../assets/captures/tutorial12-animation/12-animation-controls.png)

*MATLAB动画窗口。Safe Fit可减少旋转期间的裁切，但导出的脑可能比交互画布中小。*

## 步骤 03 · 检查帧和溯源

结果文件夹应包含`frame-000001.png`至`frame-000004.png`、`preview.png`和`provenance.json`。四帧是同一静态曲面的连续观察角度，不是神经影像数据的四个时间点。导出后检查640 × 480像素、四帧清单、各帧及源曲面哈希，并确认主画布相机保持不变。

![绕行第1帧](../assets/captures/tutorial12-animation/12-orbit-1.png) ![绕行第2帧](../assets/captures/tutorial12-animation/12-orbit-2.png)

![绕行第3帧](../assets/captures/tutorial12-animation/12-orbit-3.png) ![绕行第4帧](../assets/captures/tutorial12-animation/12-orbit-4.png)

*均来自真实曲面。第4帧接近但不重复起始角度；这四张静帧记录轨迹，4 fps不建议用于最终展示。*

核对成功后可重新打开 **Export Animation...**，以**新文件夹**试用默认 **5秒 / 24 fps / 960 × 720** 以获得更流畅结果。只有MATLAB提供MPEG-4配置时才显示MP4，AVI也取决于安装环境；本教程选PNG以避开视频编码器依赖。导出是离线计算，24 fps仅表示播放速度，不代表实时渲染或GPU编码。分享前检查`provenance.json`中的本机路径和敏感元数据；原`.nv`文件被引用，不会自动复制到结果文件夹。

## 常见问题与局限

- **Export Animation不可用：**先读取、**Apply**并渲染；仅选择文件不够。
- **取景不如预期：**Safe Fit只作用于导出副本，使用正交、旋转安全的取景；关闭后部分角度可能被裁切，应逐帧查看。
- **角度含义：**Z是世界坐标轴；正向遵循右手规则且相对当前相机，不证明解剖方位或空间配准。
- **禁止覆盖：**选择新文件夹；取消或失败不应发布不完整结果。
- **科学含义：**这是单个静态曲面的相机电影，不展示动态功能连接、时变统计、曲面形变或纤维追踪。
