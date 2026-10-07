# Tutorial resource attribution and limits

中文 (repository reference) · Tutorial index (repository reference)

This page describes the tutorial materials, exact file hashes, source credits and interpretation. Resource links identify the files used by the exercises; a documentation-only download may not include the data.

| Exact file in `src/matlab/BrainNetViewer/` | SHA-256 | Source and required credit |
|---|---|---|
| `Data/SurfTemplate/BrainMesh_ICBM152.nv` | `471e43f955a1cb9f0350aaca2822f02fc74e393718d1e385fddaf0e578ffe572` | MNI ICBM152 surface provided by **Prof. Alan C. Evans**; retain his provider credit. |
| `Data/SurfTemplate/BrainMesh_ICBM152_smoothed.nv` | `aff1920baef51956971b8c1de068e8eee2d1279f21fc90452bcd0dba2794fdc5` | Smoothed derivative of the Evans/MNI surface; retain the source-surface credit. |
| `Data/Tutorials/Tutorial02_ICBM152_Vertex_Nodes.node` | `e1c7660ee039a2d6142881c28cfaea597941dc714e718f92d1d5a2b42f08fcc5` | Project-created eight-node teaching table, using exact vertices of the credited ICBM152 mesh. |
| `Data/Tutorials/Tutorial03_Illustrative_Directed8.edge` | `4260badaace588975c79da3b4bad6727bed9ea7e8c289426ac7f163e443f9c00` | Project-created 8 × 8 directed example, paired with the eight-node table; weights are invented. |
| `Data/ExampleFiles/AAL90/icbm_vertex_AAL_label.txt` | `7cd6b8aa19c2aae6161015d62d22770a1fdfdf61d7e29354e8174dbd7853d131` | MNI-derived AAL vertex labels; cite Tzourio-Mazoyer et al. (2002) separately from the Evans/MNI surface credit. |
| `Data/Tutorials/OneSample_ROI11_NC.nii` | `e27d9eca7e20f31ed090e410fdb5b4a409565c2fafc3bc86dff21277e58aad5f` | PCC-subregion-seeded one-sample functional-connectivity T map; cite Xia et al. (2014). |
| `Data/ExampleFiles/AAL90/aal.nii` | `2926fcc98efc709f77c8cca2f9c1d797eba3e9a1b222a8e0cfa70ab131394c80` | Historical AAL90 ROI volume; cite Tzourio-Mazoyer et al. (2002). |
| `BrainNet_AAL_Label.mat` | `1fe217ef443cff395884e3c5f672891085cb10858a028048b454d02591316ec9` | AAL lookup derived from NIfTI; exact conversion chain is not archived. |
| `BrainNet_Brodmann_Label.mat` | `ed057cd513391e3aefae46e4ade5dea5b23b72da5b7cdb0064b7ebb44f347f8e` | Brodmann lookup derived from an official NIfTI; exact source release, space and conversion chain are not independently matched. |

## ICBM152 surfaces

Both surfaces contain 81,924 vertices and 163,840 triangles. The smoothed and unsmoothed files share face indexing but differ in coordinates. The source template is MNI ICBM152; this note does not independently verify coordinate units, transform, registration accuracy or anatomical labels. Neither file is a participant scan. Match the exact mesh and version used in each exercise.

## Teaching nodes and edges

Tutorials 02–03 now use the original bundled AAL90 pair rather than the eight-node teaching fixture: `Node_AAL90.node` (repository reference), SHA-256 `2ff2562b55d91f502ee8f3bf86716ea268956391729e502584ca156c2ccdd4ba`, and `Edge_AAL90_Weighted.edge` (repository reference), SHA-256 `90c7c6a536ca1131e5645d1bde15a347938a96eb9d5f9a3f41a2e17e6504e3d0`. The pair has 90 node rows and a symmetric 90 × 90 weighted matrix. Colors use the supplied column-4 module values; mapped sizes use column 5. Do not assume these stored display values are Yeo assignments or recomputed strengths. Cite Tzourio-Mazoyer et al. (2002) for AAL, and Prof. Alan C. Evans for the displayed ICBM152 surface. 

The eight node XYZ rows are exact vertices of the unsmoothed teaching surface, **not** verified atlas centroids. Node columns 4–5 are invented display values and column 6 contains teaching labels. The edge matrix has 10 nonzero, asymmetric invented weights; row/column order must match the eight-node table. It is **not** measured connectivity, fiber-tract data, an effect map or evidence of axonal direction. Prof. Evans is credited for the source geometry, not for the invented network.

## AAL vertex labels

The local file has 81,924 integer labels, including 0 for unlabelled vertices; only 78 positive IDs occur on this particular surface. The folder name “AAL90” does not prove that all 90 regions are represented. Use the historically paired **smoothed** ICBM152 mesh; index correspondence does not independently validate the original volume-to-surface projection or spatial registration. The exact local atlas release and projection algorithm are not archived. IDs are categories, not statistical values.

## PCC one-sample T map

This file is the standard-MNI one-sample connectivity map from PCC-subregion seed analysis, **not** an Alzheimer's disease versus control group contrast. Its header describes a T statistic with 37 degrees of freedom. Tutorial 05's two-sided `P = 0.001` is an **uncorrected voxelwise** threshold, applied before surface sampling; it is not FWE/FDR control or a vertex-level significance test. Verify affine alignment before anatomical interpretation. Interpolation may alter displayed boundary values. The paired smoothed surface needs separate Evans/MNI credit.

## AAL and Brodmann lookup

In this exact `aal.nii`, labels 29 and 30 identify left and right insula. Its historical AAL90 version has not been matched byte-for-byte to a particular upstream archive; do not silently substitute a newer AAL release. The two MAT lookup files are derivatives, but their exact source/version and conversion records remain incomplete. Inspect assumes compatible MNI-like coordinates and performs **no registration**; label IDs are categorical, not a continuous statistic.

## Citations

- Tzourio-Mazoyer N et al. (2002). Automated anatomical labeling of activations in SPM using a macroscopic anatomical parcellation of the MNI MRI single-subject brain. *NeuroImage* 15:273–289.
- Xia M, Wang Z, Dai Z, Liang X, Song H, Shu N, Li K, He Y (2014). Differentially disrupted functional connectivity in posteromedial cortical subregions in Alzheimer's disease. *Journal of Alzheimer's Disease* 39:527–543. The specific tutorial file is a one-sample map, not the group comparison suggested by the article title.
