# Surface material

[中文](Material_Settings.zh-CN.md) · [Manual](../manual/en/index.md)

In **Visualization Settings → Global**, choose **Surface Material** and click the shared **Apply** control. The setting is stored in Scenes and visualization presets.

| Profile | Behavior |
|---|---|
| Dull | MATLAB's `material dull` preset; the default and the original BrainNet Viewer default. |
| Shiny | MATLAB's `material shiny` preset. |
| Metal | MATLAB's `material metal` preset. |
| Custom | Uses the legacy three strengths below. |

For **Custom**, set **Ambient Strength**, **Diffuse Strength**, and **Specular Strength** individually from 0 to 1. These are the original `EC.glb.material_ka`, `material_kd`, and `material_ks` semantics. They are passed as MATLAB's three-component material vector. The controls affect shaded patch geometry in a rendered view; their visible result depends on the selected lighting/shading mode, viewing angle, transparency and graphics driver.

Legacy EC import recognizes `dull`, `shiny`, `metal`, and the historical custom `([ka kd ks])` form without evaluating text. Export preserves those forms and writes the three legacy coefficient fields. Unsupported material strings or non-finite/out-of-range custom coefficients are rejected.

19 migration, Scene/preset persistence, legacy mapping, a hidden-window renderer check of MATLAB's actual three patch strengths, and both Settings editors. It does not certify pixel identity across graphics drivers or run the full regression suite.
