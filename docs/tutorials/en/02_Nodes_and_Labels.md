# 02 Nodes and labels

[中文](../zh-CN/02_Nodes_and_Labels.md) · [Tutorial index](index.md) · [Node controls](../../manual/en/M07_Nodes.md)

Display the bundled AAL90 regional nodes on ICBM152 in four views.

## Inputs

Use [BrainMesh_ICBM152.nv](../../../src/matlab/BrainNetViewer/Data/SurfTemplate/BrainMesh_ICBM152.nv) and [Node_AAL90.node](../../../src/matlab/BrainNetViewer/Data/ExampleFiles/AtlasNetworks/AAL90.node), with 90 rows. Each row is `X Y Z module value label`: columns 1–3 give coordinates, column 4 supplies module/color IDs, column 5 supplies mapped-size values, and column 6 is the region label. The two numeric columns are independent. Module IDs are not automatically Yeo assignments; a node marker does not prove registration.

## Steps

1. Use **Surface Mesh → Add** and **Nodes → Add** for the two files, then **Validate and Load**. Keep the original coordinates and row order.
2. Choose **Layout → Lateral / Medial** for four panes of the same Scene.
3. Choose **Surface → Uniform** gray and **Opacity 0.3** to show internal regional markers.
4. In Nodes, set **All Nodes**, **Mapped** size, **Node Value** size source, and **Modules** color. Column 4 drives colors; column 5 drives size. Use the module-color editor to change colors without changing IDs.
5. Choose **No Labels** for the initial overview and click **Apply**.

![AAL90 nodes in four lateral and medial views](../assets/captures/manual-revision/05-aal90-nodes.png)

## Labels and selection

Try **All Labels**, suitable font size and **Keep Labels in Front**. Dense labels may overlap: increase export size or select labels, rather than moving atlas coordinates. **Node Value** selection uses column 5; module selection uses column 4. Set a threshold, Apply and check the selected basis, then restore All Nodes.

## Save and reuse

Save a Scene for input references and applied settings, or a preset for appearance only. Resolve missing files, changed hashes or matrix-size errors before reuse. See [resource credits](Resource_Attribution.md) for the ICBM152 provider and atlas references. Node values and module colors do not establish statistical significance.
