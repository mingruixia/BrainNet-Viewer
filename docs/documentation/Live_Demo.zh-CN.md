# 实时演示

[English](Live_Demo.en.md) · [手册](../manual/zh-CN/index.md)

渲染Scene后，在 Render Canvas 工具栏点击 **Live Demo**。它以每步5°连续旋转当前相机，对应旧版 Presentation 的演示行为。点击 **Stop Demo** 可立即停止并保留当前相机位置；点击 Reset 可恢复配置中的相机。

新版使用非阻塞计时器，而不是阻塞循环。重新渲染、清除图窗、改变视图控件或关闭App前都会自动停止。演示期间禁用动画导出；动画导出进行中也不能启动演示。实时演示不会写文件或改变Scene显示设置；停止后正常保存Scene时，当前相机可经既有会话状态路径保存。

该功能需要已渲染的画布。它与 **Rotate**（手动鼠标旋转）及 **Export Animation...**（生成文件，不是交互演示）刻意分开。

Live Demo仅在已有有效渲染时可用，用于演示相机旋转，不用于测量帧率。
