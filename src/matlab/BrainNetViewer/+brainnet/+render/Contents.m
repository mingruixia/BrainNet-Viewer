% +RENDER  Renderer-independent geometry and MATLAB graphics adapters.
%
%   Numeric geometry generation is kept separate from graphics-object creation.
%   RenderPlanner    - Deterministic preparation and in-memory caching.
%   PreparedScene   - Immutable graphics-free render payload.
%   MatlabBatchRenderer - Bounded-object MATLAB graphics backend.
%   renderSceneFile - Load Scene JSON and export without opening the App.
%   CameraState - Shared-scale camera capture, restore, and projected fit.
%   Internal performance policy selects high-load LOD and CPU/GPU kernels.
