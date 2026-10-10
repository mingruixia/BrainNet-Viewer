# 体映射显示与Adjust for Null

在 **Volume / ROI** 的Surface Map模式下使用 **Display Values** 和
**Adjust for Null**，仍由统一Apply/Revert提交或撤销；ROI几何模式禁用这两项。

| Display Values | 色标范围 | 开启Adjust for Null |
|---|---|---|
| Positive & Negative | 对称范围 `[-M, M]`，M为两端绝对值的较大者 | 中间空值区间使用Null Color |
| Positive Only | Positive minimum至Positive maximum | 首个色阶保留为Null Color |
| Negative Only | Negative minimum至Negative maximum | 最后色阶保留为Null Color |

这是**显示范围，不是按正负号删除数据**。超出范围的值按MATLAB规则夹到色标端点。
单侧模式下，等于空值侧端点的值及落在同一离散色阶内的邻近值均为空值色。
关闭调整后，空值区间和夹到端点的异号数值也按普通色标着色。
不改写原始/映射数据，不隐藏顶点，也不改变透明度。

双侧使用一个256色色图：前128色对应负值，后128色对应正值。对称色轴让零值始终
位于中点，包括正负极值不对称时。开启Adjust for Null时空值区间使用Null Color；
关闭时连续通过零值。单侧模式将对应半段重采样为256色。关闭调整时Null Color按钮禁用。

Auto：双侧先取有限数据极值，再把绝对值较小的一侧扩展为对称范围；因此较小幅度
一侧的色彩对比可能变浅。正侧从0至正值最大值（无正值时回退1）；负侧从负值最小值
（无负值时回退-1）至0。手动端点参与同样的范围计算；退化范围将上限加1。
常量数据应人工复核色标。更换体文件时手动范围会保留，Scene摘要会提示；在Volume
面板点击 **Auto Ranges** 将两个待提交范围置为Auto，再点击统一的 **Apply** 才会
生效并重新渲染。Revert可撤销尚未提交的编辑。

Settings **1.15**新增 `volume.display_mode` 和 `volume.adjust_null`。
旧场景默认Both/开启，保持原现代映射；有效相机绑定随版本迁移，失效绑定不重新激活。
EC的 `vol.display` 1/2/3对应双侧/正侧/负侧，`vol.adjustCM` 0/1对应关闭/开启。
旧配置EC导入曾丢失这些意图，需从原EC重新导入；0为兼容的关闭值。

Settings **1.22**改为单一色图；旧双图Scene迁移为组合自定义色表。
**不承诺旧版逐像素配色对等**：旧1000色阶、方向、插值和自动范围仍可能不同。
Surface Map现可依受支持的NIfTI统计元数据换算P值阈值，但不执行多重比较校正。
