# Atlas network examples

The Python package includes seven matched node/edge pairs under `resources/Data/ExampleFiles/AtlasNetworks`: AAL3v2, Glasser360, Power264, Shen278 and Schaefer100/200/400Yeo7. These are unchanged copies of the current approved BrainNet Viewer examples. No Scene JSON or source atlas NIfTI is included in this Python example collection.

The example connectivity matrices were generated from group-level resting-state fMRI data from a group of healthy adults. They are visualization examples, not normative connectivity estimates. Load matching `.node` and `.edge` names together, with an original BrainNet surface as display context.

Node coordinates are atlas-derived volume centroids, module/color identifiers describe network assignments, and node values encode connection strength. Coordinates are supplied unchanged. The historical surfaces are not exact boundaries of these volume parcels; visualization is not proof of atlas-to-surface registration.

## Atlas sources

- AAL3v2: https://www.gin.cnrs.fr/fr/outils/aal/
- Glasser360: https://afni.nimh.nih.gov/pub/dist/atlases/MNI_HCP/MNI_Glasser_HCP_2019_v1.0/
- Power264: https://github.com/brainspaces/power264
- Shen278: https://www.nitrc.org/frs/download.php/5785/shenetal_neuroimage2013_funcatlas.zip
- Schaefer100/200/400Yeo7: https://github.com/ThomasYeoLab/CBIG/tree/master/stable_projects/brain_parcellation/Schaefer2018_LocalGlobal/Parcellations/MNI

Cite the appropriate atlas source when using an atlas. Software licensing and atlas/data attribution are separate.
