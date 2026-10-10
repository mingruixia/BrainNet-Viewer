# BrainVISA 表面（.mesh）

通过 **Data Sources → Surface Mesh** 或 **Add Files** 选择 `.mesh`。候选几何验证通过后才替换当前输入。在右侧分类中调整参数，点击底部统一 **Apply** 即提交**并渲染**；**Render Scene** 可显式重绘。**Save Scene** 与 **BrainNetRender** 使用同一独立读取器。

## 支持范围

支持AIMS ASCII、大端/小端二进制、`VOID`纹理、单时间步三角网格。可选法线检查数量与有限性，绘图法线由渲染器重新计算。ASCII坐标按格式约定解释为float32，与二进制一致；索引转换为MATLAB一基，顶点与面片顺序不变。

多时间步、线段、四边形、内嵌纹理、`.mesh.gz`及同样使用`.mesh`后缀的Medit格式明确不支持，不静默选帧或拆分多边形。默认上限为一千万顶点、两千万面，可通过API调整；`VOID`前空白最多4096字节。分配前核对计数及剩余字节，拒绝损坏括号、非有限数值、越界索引和多余尾部数据。

## 重要的旧版迁移差异

**坐标按文件存储值保留。** 旧BrainNet的`.mesh`分支曾对XYZ三轴统一取反；新读取器不执行这一隐式操作。因此不能假设旧场景具有相同方向或配准。叠加节点、体数据或图谱前须核对标志点与对齐。Scene信息会显示 **BrainVISA coordinates as stored; no legacy XYZ inversion; verify registration**。

相邻`.minf`文件不执行、不解析，其中的参考空间/变换也不应用；读取成功不代表已经对齐MNI或scanner空间。该边界随Scene元数据记录。应保留原文件，本读取器不是无损格式写出器。

```matlab
reference = brainnet.core.InputReference("surface", "subject/cortex.mesh");
[surface, info] = brainnet.io.readBrainVisaMesh(reference, "D:/my-data");
% Coordinates为3×N；Faces为F×3，索引从1开始。
```

运行时不需要AIMS、SPM、Python或MEX。

## 统一设置操作

分类标题改为 **Layout >**、**Surface >** 等，展开后箭头为后置 **v**。切换分类保留未提交编辑。底部 **Apply** 一次提交所有分类的修改；**Revert** 一次撤销所有未提交修改，恢复上次已接受配置。全局按钮不随内容区滚动，打开长分类或收起全部分类后仍可用。保存预设或Scene前请先Apply。
