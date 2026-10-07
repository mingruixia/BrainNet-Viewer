% +IO  Versioned readers, writers, provenance, and format validation.
%
%   Third-party or legacy-derived parsers require explicit provenance review.
%   readSurface - Read and validate a BrainNet ASCII .nv surface.
%   readInput - Independent dispatch for a Scene input reference.
%   writeBoundary - Save a new original-order binary boundary map with provenance.
%   readFreeSurferSurface - Read big-endian FreeSurfer triangle/quad geometry.
%   readBrainVisaMesh - Read ASCII/binary single-frame AIMS triangle meshes.
%   readByuSurface - Read single/multipart MOVIE.BYU ASCII triangle geometry.
%   readMniObjSurface - Read ASCII/binary MNI/BIC triangle geometry, not Wavefront.
%   readMz3Surface - Read bounded raw/GZip MZ3 geometry and optional attribute arrays.
%   readNodes   - Read and validate a BrainNet ASCII .node file.
%   readEdges   - Read and validate a BrainNet ASCII .edge matrix.
%   readSurfaceMap - Read a finite numeric per-vertex text map.
%   readNifti   - Read NIfTI-1/2 single or paired files without SPM.
%   readGifti   - Read embedded/external GIfTI surfaces without a toolbox.
%   readScene   - Read UTF-8 Scene JSON independently of the current folder.
%   writeScene  - Verify input hashes and safely save a Scene JSON.
%   importLegacyConfig - Convert trusted EC MAT settings with a review report.
%   readPreset / writePreset - Strict UTF-8 settings-only preset persistence.
%   readColormap / writeColormap - Safe RGB text/JSON palette persistence.
