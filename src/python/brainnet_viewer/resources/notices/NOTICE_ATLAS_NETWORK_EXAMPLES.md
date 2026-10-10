# Atlas network examples

`Data/ExampleFiles/AtlasNetworks/` provides fourteen matched GroupFC node/edge pairs and the AAL90 examples. GroupFC connectivity matrices were generated from a group of healthy adults' resting-state fMRI data. These are visualization examples, not normative connectivity estimates. Node sizes represent absolute connection strength; node colors represent Yeo seven-network assignments for Schaefer or data-derived communities for the other GroupFC examples. Use Modular colors and Mapped sizes to display these fields. Keep node coordinates and paired row orders unchanged.

| Example family | Atlas source / citation |
|---|---|
| AAL90 / AAL116 | Tzourio-Mazoyer et al. (2002), NeuroImage 15:273–289; [AAL project](https://www.gin.cnrs.fr/fr/outils/aal/) |
| AAL3v2 | [AAL project](https://www.gin.cnrs.fr/fr/outils/aal/) |
| Brodmann82 / Dos160 / Fair34 / HOA112 | Accompanying `*_Reference.txt` files; [GRETNA atlas distribution](https://github.com/sandywang/GRETNA) |
| Brainnetome246 | Fan et al. (2016), Cerebral Cortex 26:3508–3526; [Brainnetome atlas](https://atlas.brainnetome.org/) |
| Glasser360 | [AFNI HCP-MMP/Glasser distribution](https://afni.nimh.nih.gov/pub/dist/atlases/MNI_HCP/MNI_Glasser_HCP_2019_v1.0/) |
| Power264 | [Power264 resource](https://github.com/brainspaces/power264) |
| Shen278 | [Shen atlas distribution](https://www.nitrc.org/frs/download.php/5785/shenetal_neuroimage2013_funcatlas.zip) |
| Schaefer100/200/400/1000Yeo7 | [Schaefer atlas and Yeo labels](https://github.com/ThomasYeoLab/CBIG/tree/master/stable_projects/brain_parcellation/Schaefer2018_LocalGlobal/Parcellations/MNI) |

Source atlas volumes are separate from example connectivity. The repository and MATLAB archive contain `resources/atlases/`: AAL90 support files, AAL3v2, Glasser360, Power264, Shen278, and the four Schaefer resolutions with LUTs and source/license notices. Python and Docker contain the node/edge library and AAL90 support files; the other source volumes are available in the source archive.

`AAL3v2.nii.gz` and `AAL3v2_labels.txt` are readable aliases for the files distributed in the AAL3v2 archive with AAL3v1 names. `Shen278_2mm.nii` is an alias for `fconn_atlas_150_2mm.nii`; 278 describes its represented labels. Renaming does not change voxels, label values, affine transforms, or atlas revision. The accompanying source-name record preserves the original names.

Atlas-derived node positions are not exact surface parcel boundaries. A display mesh provides context and does not establish registration. AAL90 retains its supplied example weights and is not relabeled as GroupFC. No Scene JSON is bundled for these examples.
