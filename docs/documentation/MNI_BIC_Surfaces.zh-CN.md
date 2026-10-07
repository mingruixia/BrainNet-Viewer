# MNI/BIC OBJ 曲面

开发版指南 · 开发版 · 2026-09-06

从 **Surface Mesh → Add** 或 **Add Files** 选择 MNI/BIC `.obj`，调整
**Visualization Settings** 后点击 **Render Scene**。Scene JSON 与
`BrainNetRender` 使用相同读取器，无需 SPM、BICPL、VTK 或 Python 运行依赖。
新文件预检失败时，原输入和数据保持不变。

支持单个未压缩的三角多边形对象：ASCII `P`、二进制 `p`；三角面长度表可为
累计值 `3,6,9,...` 或逐面大小 `3,3,3,...`。二进制整数/浮点为 int32/float32，
自动完整验证大小端，只接受唯一有效解释，不能可靠识别时明确拒绝。格式本身没有
通用字节序标识。

这不是 Wavefront OBJ；文件名中的 MNI 也不证明坐标已经位于 MNI 标准空间。
原坐标、顶点顺序和绕序保留，不自动取反、缩放或配准。ASCII 保留双精度解析值，
二进制保留原 float32 值。与节点、体数据、图谱叠加前须核对配准和单位。

正确区分整体、逐面、逐顶点三种颜色表长度。ASCII 使用 [0,1] RGBA 浮点值，
二进制使用 ABGR 四字节，而非四个浮点数。文件内材质、颜色、法线经过校验，
但**不自动覆盖显示配置**。元数据记录材质值、颜色模式/数量、颜色和法线指纹，
整体颜色还记录 RGBA；不将大型颜色/法线数组塞入 Scene。法线要求有限值，
不强制严格单位长度，渲染器重新计算法线。

本轮不支持 Wavefront OBJ、压缩拓扑、四边形/任意多边形、Q quadmesh、
线/标记/文本/像素/外部模型引用、多个对象或 `.obj.gz` 路由；不静默三角化或仅取首对象。
ASCII 允许尾部空白；二进制数组后必须恰好结束文件。

```matlab
ref = brainnet.core.InputReference("surface", "cortex.obj");
[surface, info] = brainnet.io.readMniObjSurface(ref, "D:/my-data");
% 仅在字节序已有独立依据时：
[surface, info] = brainnet.io.readMniObjSurface(ref, "D:/my-data", ByteOrder="big");
```

`ByteOrder` 支持 auto/little/big，仅为直接调用选项，不是 Scene 配置；
App/Scene/CLI 使用 auto。默认上限为 1000 万顶点、2000 万三角面，
可通过 `MaxVertices`/`MaxFaces` 降低。读取检查计数、最小文件长度、有限值、
三角面长度、索引、哈希和尾部数据，但不保证流形拓扑、无自交、配准正确或单位法线。

参见[格式矩阵](../compatibility/Surface_Format_Support.md)与
[Scene 工作流](Scene_Workflows.zh-CN.md)。研发验证使用项目自建的小型 polygon 文件及由 FreeSurfer fsaverage 转换的皮层文件；后者**不是**原生 MNI/BIC 样例，也不随本文分发。若另行分发该测试文件，须保留 FreeSurfer 来源署名和许可。
