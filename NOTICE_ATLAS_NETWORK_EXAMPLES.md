# Atlas network examples

The `Data/ExampleFiles/AtlasNetworks/` collection contains seven `.node`/`.edge` pairs: AAL3v2, Glasser360, Power264, Shen278, and Schaefer100/200/400Yeo7. No Scene JSON file is distributed for these examples. Users may load a pair with a suitable original BrainNet Viewer surface and adjust the display settings. Example connectivity matrices were generated from group-level resting-state fMRI data. The files are intended as visualization examples, not as normative connectivity estimates.

The atlas source is separate from the example connectivity data. Cite the appropriate source when using an atlas:

| Example family | Atlas source |
|---|---|
| AAL3v2 | [AAL project](https://www.gin.cnrs.fr/fr/outils/aal/) |
| Glasser360 | [AFNI HCP-MMP/Glasser atlas distribution](https://afni.nimh.nih.gov/pub/dist/atlases/MNI_HCP/MNI_Glasser_HCP_2019_v1.0/) |
| Power264 | [Power264 resource](https://github.com/brainspaces/power264) |
| Shen278 | [Shen functional atlas distribution](https://www.nitrc.org/frs/download.php/5785/shenetal_neuroimage2013_funcatlas.zip) |
| Schaefer100/200/400Yeo7 | [Schaefer atlas and 7-network labels](https://github.com/ThomasYeoLab/CBIG/tree/master/stable_projects/brain_parcellation/Schaefer2018_LocalGlobal/Parcellations/MNI) |

Corresponding source atlas volumes are included under `resources/atlases/`: AAL3v2 (`AAL3v1.nii.gz` plus its label text), Glasser360 (`MNI_Glasser_HCP_v1.0.nii.gz` plus AFNI descriptor/notes), Power264 (`power264MNI.nii.gz` plus node and community tables), Shen278 (`fconn_atlas_150_2mm.nii`), and the three Schaefer 2-mm NIfTIs with matching LUTs and their original source/license notice. These source-volume filenames are preserved from their distributions; the AAL3v2 download contains an `AAL3v1`-named volume.

Node locations are atlas-derived volume centroids. The included historical BrainNet Viewer meshes provide a display context; their surfaces must not be interpreted as exact boundaries of these volume parcels. The `.node` coordinates and `.edge` values are supplied unchanged from the validated example candidates.
