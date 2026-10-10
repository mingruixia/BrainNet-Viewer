# 曲面材质

[English](Material_Settings.en.md) · [手册](../manual/zh-CN/index.md)

在 **Visualization Settings → Global** 中选择 **Surface Material**，再点击共享的 **Apply**。该设置会保存到Scene和显示预设。

| 配置 | 行为 |
|---|---|
| Dull | MATLAB 的 `material dull` 预设；也是原 BrainNet Viewer 默认值。 |
| Shiny | MATLAB 的 `material shiny` 预设。 |
| Metal | MATLAB 的 `material metal` 预设。 |
| Custom | 使用下方三项旧版材质强度。 |

选择 **Custom** 时，可分别设置 0–1 的 **Ambient Strength**、**Diffuse Strength** 和 **Specular Strength**。它们严格对应旧版 `EC.glb.material_ka`、`material_kd`、`material_ks`，并以 MATLAB 的三分量材质向量传入。控件影响渲染视图中的受光照 patch 几何；可见效果受光照/着色模式、视角、透明度和图形驱动影响。

导入旧EC时支持 `dull`、`shiny`、`metal`，以及历史自定义形式 `([ka kd ks])`，且不会执行任何文本。导出保留这些形式并写入三个旧版系数字段。未知材质字符串或非有限/超范围自定义系数会明确拒绝。

专项验证验证覆盖Settings 1.19迁移、Scene/预设持久化、旧配置映射、隐藏窗口下 MATLAB 实际写入的三项patch材质强度及两套Settings编辑界面；未认证不同图形驱动上的像素一致性，也未运行完整回归。
