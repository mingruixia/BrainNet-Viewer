# 曲面合并

BrainNet Viewer 2.0 开发版 · 开发版

单个输入请使用[单曲面转换NV](Surface_Conversion.zh-CN.md)。Merge要求2–64个输入；空间、单位及备注为可选元数据。

## 桌面操作

1. 从主窗口 **Tools → Merge Surfaces...** 打开独立工具窗口；当前Scene不变。
2. 点击 **Add Files...** 选择2–64份曲面；通过 **Remove / Move Up / Move Down** 删除或排序。同一规范路径不能重复加入。
3. 添加、删除或调整顺序后自动复核，显示完整路径、顶点/三角面数量、一基索引范围、坐标范围及SHA-256，不写文件；不足两个输入时不能保存。
4. **Space**、**Units**、**Note**可留空；空间和单位留空时记录为`unknown`，不再要求勾选Verify。工具不配准、不换算单位，解剖对齐仍需使用者自行判断。
5. 点击 **Save New .nv...**，选择新文件名。已有文件一律拒绝覆盖，即使系统对话框另有覆盖提示。发布前重新核对输入及GIfTI外部数组哈希。
6. 如需显示结果，回主界面通过 **Surface Mesh** 读取新文件，再设置并 **Render Scene**。与其他可移植Scene输入一样，文件须位于该App配置的数据根目录内：请保存到该目录下，或以合适的数据根目录启动App（`brainnet.app.launch(dataRoot)`）。保存不会擅自替换当前数据/配置或改变根目录。

打开、保存对话框确定或取消后，焦点返回Merge工具窗口。以下截图为简化控件前的界面，规模与坐标范围信息保持不变。

![浅色主题输入复核](../tutorials/assets/captures/tutorial11-merge-boundary/11-merge-review.png)

截图刻意混合FreeSurfer曲面与模板演示复核界面，**不是已配准组合，也没有保存**，不能照此作为科研合并范例。

## 格式与科学边界

复用独立读取器，支持 `.nv`、`.pial`、`.mesh`、BYU `.g`、MNI/BIC `.obj`、`.mz3/.mz3.gz` 和 `.gii/.gii.gz`，沿用各读取器现有限制。首版仅输出ASCII `.nv`。

按顺序拼接原始坐标，每份面片索引增加此前累计顶点数。重合顶点仍是不同顶点，面片方向保持不变。GIfTI矩阵和可用原生元数据记录为来源，**不自动应用变换**。不执行配准、缩放、镜像、焊接、平滑、交叉修复或孤立顶点删除；不转移颜色、标量、材质、法线及语义标签。

输出第二行`#`注释内嵌版本化JSON：来源路径/哈希、GIfTI外部数组哈希、源元数据、分段索引/坐标范围，以及用户填写的空间/单位/依据。绝对路径可能暴露本地目录名称，分享前请检查。普通`.nv`读取器忽略注释，因此该记录**不会自动成为Scene坐标空间**。合并不改变源资源再分发权限。

坐标以17位有效数字保存，发布前重新读取并逐项验证double数组完全一致。临时文件位于目标目录，以禁止替换的移动操作发布；受控失败时清理临时文件。复核后输入改变必须重新复核。此过程不是文件系统快照，不能保证最后哈希核对之后输入绝不再被修改。

默认合计上限为500万顶点、1000万面片，在各输入读取后、拼接前检查，并非各读取器分配内存前的限制。保存还需读回副本，大数据需要额外内存。本工具以文件处理为主，不声称GPU加速。

## MATLAB接口

```matlab
plan = brainnet.tools.SurfaceMergePlan(["D:/data/left.nv"; "D:/data/right.nv"]);
disp(plan.Report)
report = plan.write("D:/results/both.nv", ...
    CoordinateSpace="subject-01 native scanner frame", Units="mm", ...
    Note="Both surfaces exported from the same verified reconstruction");
```

三个元数据参数均可省略，直接调用`plan.write("D:/results/both.nv")`即可。声明须符合自己的数据。接口不覆盖文件；`report.output_sha256`标识最终输出，不递归写入文件自身。图谱查询配置不会随合并继承。
