# Historical example files

The original BrainNet Viewer example library includes older `.node`, `.edge`, `.txt`, and `.mat` templates under `Data/ExampleFiles/`. They are retained to help reproduce historical workflows and illustrate file formats. They are **not** the seven newly prepared atlas-network examples under `Data/ExampleFiles/AtlasNetworks/`, and their edges must not be described as the new group-level resting-state connectivity matrices.

Matching node counts and square matrix dimensions establish only basic format compatibility. The historical files do not carry a verified atlas ID–node row–edge row crosswalk or complete provenance for edge weights. In particular, `AAL90/Node_AAL116.node` has 116 rows and must not be paired with the 90 × 90 AAL90 edge files. `Brodmann82` is a separate historical example, not the built-in Brodmann Inspect lookup atlas. `AAL90/Cover.mat` is a legacy configuration object, not a connectivity matrix or an assured import format for the modern app. Boundary and mask text files may depend on a particular surface vertex order.

For current atlas-based network demonstrations, use the seven documented pairs in `Data/ExampleFiles/AtlasNetworks/` and cite their corresponding atlas sources. Do not interpret any visualization against an original display surface as proof of exact atlas-to-surface registration.
