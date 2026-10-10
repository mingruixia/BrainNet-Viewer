# Atlas network examples

Load a `.node` file and its matched `.edge` from this folder. Do not combine different atlas row orders.

| Atlas | Nodes | Node file | Edge file |
|---|---:|---|---|
| AAL90 | 90 | `AAL90.node` | `AAL90_Binary.edge` or `AAL90_Weighted.edge` |
| AAL116 | 116 | `AAL116_GroupFC.node` | `AAL116_GroupFC.edge` |
| AAL3v2 | 166 | `AAL3v2_GroupFC.node` | `AAL3v2_GroupFC.edge` |
| Brodmann82 | 82 | `Brodmann82_GroupFC.node` | `Brodmann82_GroupFC.edge` |
| Brainnetome246 | 246 | `Brainnetome246_GroupFC.node` | `Brainnetome246_GroupFC.edge` |
| Dos160 | 160 | `Dos160_GroupFC.node` | `Dos160_GroupFC.edge` |
| Fair34 | 34 | `Fair34_GroupFC.node` | `Fair34_GroupFC.edge` |
| Glasser360 | 360 | `Glasser360_GroupFC.node` | `Glasser360_GroupFC.edge` |
| HOA112 | 112 | `HOA112_GroupFC.node` | `HOA112_GroupFC.edge` |
| Power264 | 264 | `Power264_GroupFC.node` | `Power264_GroupFC.edge` |
| Schaefer100Yeo7 | 100 | `Schaefer100Yeo7_GroupFC.node` | `Schaefer100Yeo7_GroupFC.edge` |
| Schaefer200Yeo7 | 200 | `Schaefer200Yeo7_GroupFC.node` | `Schaefer200Yeo7_GroupFC.edge` |
| Schaefer400Yeo7 | 400 | `Schaefer400Yeo7_GroupFC.node` | `Schaefer400Yeo7_GroupFC.edge` |
| Schaefer1000Yeo7 | 1000 | `Schaefer1000Yeo7_GroupFC.node` | `Schaefer1000Yeo7_GroupFC.edge` |
| Shen278 | 278 | `Shen278_GroupFC.node` | `Shen278_GroupFC.edge` |

GroupFC matrices were generated from a group of healthy adults' resting-state fMRI data. They are visualization examples, not normative connectivity estimates. Their node size values encode absolute connection strength. Schaefer nodes encode the atlas's Yeo seven-network assignment; other GroupFC nodes encode data-derived network communities. Module indices are display categories, not anatomical labels or statistical scores.

AAL90 retains its supplied node, binary-edge and weighted-edge examples. The GroupFC descriptions do not change the interpretation of these AAL90 files. AAL116 includes cerebellar parcels; AAL3v2 has 166 represented labels, and its numbering is not interchangeable with AAL90/AAL116. Keep all node coordinates and row orders as supplied.

AAL90 volume and vertex-label support files are in `resources/atlases/AAL90/` from the repository/MATLAB archive root, or `atlases/AAL90/` inside the Python package resource library. The AAL vertex map requires its matched ICBM152 vertex order. In `aal.nii`, ROI IDs 29 and 30 identify the insulae.

See `NOTICE_ATLAS_NETWORK_EXAMPLES.md` and the `*_Reference.txt` files for atlas citations. No Scene JSON is required or bundled for these examples.
