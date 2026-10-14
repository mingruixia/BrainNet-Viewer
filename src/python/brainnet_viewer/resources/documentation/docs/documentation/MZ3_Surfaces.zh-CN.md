# MZ3 曲面

通过 **Surface Mesh → Add** 或 **Add Files** 选择 `.mz3` / `.mz3.gz`，
调整 **Visualization Settings** 后点击 **Render Scene**。Scene JSON 与
`BrainNetRender` 使用同一读取器；新文件校验失败不替换当前输入和数据。
无需 SPM、Surfice、Python 运行依赖；GZip 使用已验证 MATLAB 环境随附的 Java。

支持同时含三角面和顶点的 little-endian 几何。按文件前导字节识别原始二进制或
GZip，包括只用 `.mz3` 后缀的压缩文件。原坐标、顶点顺序和绕序保留，
磁盘零基索引转为 MATLAB 一基。格式采用 MNI 坐标约定，但不能据此证明某文件
已经正确配准；叠加其他数据前仍须核对空间和单位。

读取并校验逐顶点 RGBA 与单/双精度多层标量，但**不自动覆盖显示配置**。
标量 NaN 作为缺失值保留，Inf 拒绝；标量层数由剩余字节推导，必须是完整非空
顶点数组。RGBA 与标量共存不自动认定为有效图谱，不做标签取整或配色套用。

```matlab
ref = brainnet.core.InputReference("surface", "cortex.mz3");
[surface, info, arrays] = brainnet.io.readMz3Surface(ref, "D:/my-data");
% arrays.RGBA：N×4 uint8，取值0..255；没有颜色时为空
% arrays.Scalars：N×L double，保留源精度对应数值与NaN
```

大型属性数组不写入 Scene 元数据；元数据只记录计数、标志位、编码、标量精度/
层数/缺失数量及显示策略。完整输入文件由哈希绑定。跳过的私有头部按不透明字节
处理，不执行、不推断变换，也不解释为操作指令。

| 直接调用参数 | 默认上限 |
|---|---:|
| `MaxVertices` | 1000万 |
| `MaxFaces` | 2000万 |
| `MaxBytes`（输入及解压字节） | 1,073,741,824 |
| `MaxSkipBytes` | 16,777,216 |
| `MaxScalarLayers` | 256 |

GZip 分块解压到唯一临时文件，检查字节上限、CRC/大小，成功或失败后均清理。
此限制不是 MATLAB 峰值内存配额。读取检查长度、标志位、坐标有限值和索引边界。
没有标量标志时拒绝尾部多余数据；有标量标志时，新增完整一层本身属于合法表示，
因为格式头中没有独立层数字段。

曲面读取入口不支持纯覆盖层文件、点云、环境遮蔽标志、嵌入JSON查色表标志、
未来标志、同时声明单/双精度标量或大端MZ3。验证范围是单成员GZip，
不承诺嵌套或多成员容器兼容。结构验证不等于流形、无自交、图谱标签或配准质量认证。

参见[Scene工作流](Scene_Workflows.zh-CN.md)与
[格式矩阵](../compatibility/Surface_Format_Support.md)。
