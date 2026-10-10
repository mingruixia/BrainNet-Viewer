# Network example files

`Data/ExampleFiles/AtlasNetworks/` contains matched atlas node/edge pairs. Its README lists all files and region counts. GroupFC node sizes represent absolute connection strength; colors represent network modules. The example matrices were generated from a group of healthy adults' resting-state fMRI data. AAL90 retains its supplied node and binary/weighted edge examples.

AAL90 auxiliary volumes, vertex labels and masks are separate in `resources/atlases/AAL90/` (repository/MATLAB archive) or `atlases/AAL90/` (Python/Docker resource library). Vertex maps require the corresponding surface vertex order. AAL90 IDs are not AAL3v2 IDs. Use AAL90 for the node/edge tutorials; AAL116 now has its own matched GroupFC edge matrix.

See `NOTICE_ATLAS_NETWORK_EXAMPLES.md` and the reference files for citations. Successful loading does not establish registration or statistical validity.
