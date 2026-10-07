# MOVIE.BYU 曲面

开发版使用说明 · 开发版 · 2026-09-06

通过 **Surface Mesh → Add** 或 **Add Files** 选择ASCII MOVIE.BYU `.g`，调整 **Visualization Settings** 后点击 **Render Scene**。Scene JSON和`BrainNetRender`使用同一个读取器，运行时不需要Python、SPM或VTK。

当前支持**三角几何**及多部件文件。部件范围必须有序、非空、互不重叠，并完整覆盖第1至最后一个多边形。所有部件按原顺序保留为一个曲面；范围存入元数据，暂不作为可分别配色/选择的图层。顶点顺序、坐标和三角面绕序保持原样；每个三角面的末项负索引只是结束标记，不是坐标取反。

读取时验证计数/资源上限、部件范围、有限坐标、索引范围、逐面结束标记、数组完整性及尾部内容。新文件无效时保留原有输入和数据。四边形、任意多边形或错误的连接数组长度会明确拒绝，不静默三角化或只取一个部件。

不自动加载`.d`位移、`.s`标量或`.t`纹理伴随文件，也不做配准或单位转换。与节点、体数据、图谱叠加前，必须核对空间与单位。`.g`不是通用几何识别器；本步不支持BRL-CAD二进制`.g`，不接入`.g.gz`或`.byu`扩展名。支持空白分隔数值和相邻带符号科学计数坐标；不宣称支持无数字分隔的满宽正数字段。

```matlab
ref = brainnet.core.InputReference("surface", "cortex.g");
[surface, info] = brainnet.io.readByuSurface(ref, "D:/my-data");
info.part_polygon_ranges
```

默认上限为1,000万顶点、2,000万三角面、10万个部件，可通过`MaxVertices`、`MaxFaces`、`MaxParts`降低；头部计数必须为正的32位有符号整数。这里只验证结构，不保证曲面流形性、无自交或配准正确。

相比旧版按单部件三角数组直接读取，新实现验证完整部件表，但不修改旧实现。另见[Scene工作流](Scene_Workflows.zh-CN.md)及[格式矩阵](../compatibility/Surface_Format_Support.md)。研发测试使用自建多部件四面体、由FreeSurfer转换的皮层文件，以及作为明确拒绝样例的第三方四边形立方体。测试文件不会自动纳入软件资源包；如拟分发后两者，须另行落实FreeSurfer署名及立方体上游LGPL版本/NOTICE。
