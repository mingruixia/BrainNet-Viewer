# Inter-hemisphere edge filtering — development build

In **Visualization Settings → Edges**, enable **Inter Hemi Only**, then click the global **Apply** to commit and render. Revert discards uncommitted changes. Disabled (default) means no hemisphere restriction; Directed Edges remains independent.

The legacy rule uses **node x coordinates and x=0 as the midline**: remove pairs whose endpoints are both strictly positive or both strictly negative. Retain opposite signs and any pair with a zero endpoint, including two midline nodes. This is not an anatomical classifier: confirm axis orientation and origin for the dataset, particularly non-human or transformed coordinates. No tolerance or automatic recentering is introduced. Sign comparisons avoid multiplication underflow for very small coordinates.

Filtering occurs **after** All/Threshold/Sparsity selection. It preserves the selected edge order, direction and original weights; it does not refill the requested sparsity after removing same-side edges. Connected node display uses the remaining pairs. Existing per-view hemisphere clipping is unchanged. The current version supports explicit [sparsity/tie modes](Edge_Sparsity.en.md).

Settings **1.12.0** adds logical `edge.inter_hemisphere_only`, saved in Scene and presets and included in render-cache keys. EC `edg.interhemiedges` accepts only scalar 0/1 and round-trips the flag. Older settings default to off: earlier development EC imports ignored this field, so reimport the original EC to recover its intent. Scene migration flags review; only valid old camera signatures are rebound. No new data files are needed.

 This step does not certify full legacy parity, all UI layouts or coordinate registration.
