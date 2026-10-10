# FreeSurfer 表面（.pial）

## 主界面操作

1. 启动软件，在 **Data Sources → Surface Mesh** 选择 `.pial`；**Add Files** 也能识别这一扩展名。
2. 阅读 **Scene** 中的 **FreeSurfer coordinates as stored; verify registration** 提示。新文件在替换当前曲面选择之前完成检查。
3. 在 **Visualization Settings → Layout / Surface** 调整显示，点击 **Render Scene**。单半球建议先选 **Single View**，需要时使用 **Fit**。
4. **Save Scene** 保存后续重放所需配置，**Export Figure** 导出图片；沿用PNG/JPEG/TIFF/BMP/PDF/SVG规则。

自定义导出尺寸保持脑形比例；画布宽高比不同时通过背景留白适配。位图按指定像素尺寸输出（实际尺寸根据DPI换算并取整）；舍入补偿只补齐画布，不裁切或拉伸脑图。

坏 `.pial` 文件会在替换输入引用和已加载数组之前拒绝；文件选择预检不会关闭已有绘图。界面可能显示错误，但无效文件不会因此成为已选曲面。通过完整Scene JSON切换文件仍遵循既有的Scene选择/加载流程。

## 支持范围

| 编码 | 文件中的数据 | 处理方式 |
|---|---|---|
| 三角网格，标识16777214 | 大端float32坐标、int32零基三角索引 | 保留坐标和面片顺序，索引转换为MATLAB一基 |
| 旧四边网格，标识16777215 | 大端int16坐标÷100，uint24索引/计数 | 按FreeSurfer官方规则拆分，保留顶点顺序 |
| 新四边网格，标识16777213 | 大端float32坐标、uint24索引/计数 | 使用同一拆分规则 |

四边拆分采用FreeSurfer当前C++实现的 `WHICH_FACE_SPLIT`，使用前两个零基顶点编号共同决定对角线。四边编码产生的重复索引退化三角面按该实现移除。它可能与NiBabel历史上的“首顶点奇偶”规则不同；独立NiBabel指纹用于**三角网格**标准样例，不用于判定四边拆分。

本步主界面和Scene仅为该读取器接入 `.pial`；其他FreeSurfer后缀、ASCII曲面、patch及 `.pial.gz` 未接入/未声明支持。修改文件扩展名并不能转换不兼容内容。

## 坐标及元数据边界

坐标按文件存储值保留。典型FreeSurfer皮层表面使用毫米单位的surface RAS，不能自动当作scanner RAS或MNI空间。读取器不执行配准、镜像、居中或附加标签中的变换。叠加节点、体数据或图谱之前须确认坐标一致；“成功读取”不等于“已经对齐”。参见[官方坐标说明](https://surfer.nmr.mgh.harvard.edu/fswiki/CoordinateSystems)。

返回的 `SurfaceData.Metadata` / 第二输出记录编码、数量、索引基数、创建说明、移除的退化面数及尾部字节数。尾部的体几何/标签明确**不解释、不应用**。界面选择文件时，这些信息也进入输入引用，随Scene保存。手工创建的Scene JSON仍保留调用者自身的元数据，读取器不会静默重写它。

默认安全上限：一千万顶点、两千万输出三角面，可通过读取器API显式调整。分配数组前会核对计数与剩余文件长度；三角文件两行头部文本各最多4096字节。非有限坐标、越界索引、未知标识和截断几何均拒绝读取。

## MATLAB / 命令行

```matlab
reference = brainnet.core.InputReference("surface", "subject/lh.pial");
[surface, info] = brainnet.io.readFreeSurferSurface(reference, "D:/my-data");
% Coordinates为3×N，Faces为F×3且索引从1开始。
scene = brainnet.core.Scene("LH_PIAL", "Left pial surface", 1, 0, {reference});
brainnet.io.writeScene(scene, "left-scene.json", "D:/my-data");
BrainNetRender("left-scene.json", "left.png", DataRoot="D:/my-data", ...
    ComputeBackend="cpu", Width=1200, Height=900);
```

运行时为独立MATLAB代码，不调用SPM、FreeSurfer、NiBabel或MEX。NiBabel仅用于开发对照验证。fsaverage标准样例及完整许可/来源保存在 `tests/fixtures/freesurfer`，不自动加入正式发布包。
