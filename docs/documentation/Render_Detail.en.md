# Render detail

[中文](Render_Detail.zh-CN.md) · [Manual](../manual/en/index.md)

In **Visualization Settings → Global**, select **Render Detail** and click the shared **Apply** control. The choice is stored in the active Scene and in visualization presets.

| Choice | Node sphere detail | Edge-cylinder sides | Meaning |
|---|---:|---:|---|
| Adaptive (modern) | policy-selected | policy-selected | Default. The current renderer chooses its normal interactive/quality detail from workload and renderer mode. |
| Low (legacy) | 10 | 5 | Exact legacy `EC.glb.detail = 1` geometry values. |
| Moderate (legacy) | 50 | 10 | Exact legacy `EC.glb.detail = 2` geometry values. |
| High (legacy) | 100 | 20 | Exact legacy `EC.glb.detail = 3` geometry values. This can be expensive for large networks. |

This control changes node and edge geometry detail. It does not resample, smooth, register or otherwise change the surface mesh. Direct renderer `NodeDetail` or `EdgeSides` overrides remain authoritative for scripted use.

Legacy EC import maps numeric detail codes to Low, Moderate and High. Existing and new modern Scenes default to Adaptive so that they retain their prior workload-aware behavior. EC has no Adaptive code: exporting an Adaptive modern setting writes legacy High (3), the historical legacy default. Legacy numeric codes outside 1–3 follow the existing EC enum-clamping convention.

18 migration, validation, Scene/preset replay, EC import/export mapping, policy selection, and both Settings editors. It did not run the full regression suite, benchmark all scene sizes, or certify visual equivalence on every GPU/driver.
