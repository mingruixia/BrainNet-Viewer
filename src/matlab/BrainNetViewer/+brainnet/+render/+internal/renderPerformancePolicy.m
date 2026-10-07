function value = renderPerformancePolicy(prepared, options)
%RENDERPERFORMANCEPOLICY Resolve quality and acceleration for a scene.

arguments
    prepared (1, 1) brainnet.render.PreparedScene
    options.Mode (1, 1) string = "auto"
    options.NodeDetail double = []
    options.EdgeSides double = []
    options.SurfaceFaceFraction double = []
    options.DetailLevel (1, 1) string = "adaptive"
    options.ComputeBackend (1, 1) string = "auto"
end

if ~any(options.Mode == ["auto", "interactive", "quality"])
    error('BNV:Render:UnsupportedPerformanceMode', ...
        'Performance mode must be auto, interactive, or quality.');
end
if ~any(options.ComputeBackend == ["auto", "cpu", "gpu"])
    error('BNV:Render:UnsupportedComputeBackend', ...
        'Compute backend must be auto, cpu, or gpu.');
end
if ~any(options.DetailLevel == ["adaptive","low","moderate","high"])
    error('BNV:Render:UnsupportedDetailLevel','Render detail must be adaptive, low, moderate, or high.');
end
highLoad = prepared.NodeCount >= 300 || prepared.EdgeCount >= 1500;
effectiveMode = options.Mode;
if effectiveMode == "auto"
    if highLoad
        effectiveMode = "interactive";
    else
        effectiveMode = "quality";
    end
end
if effectiveMode == "interactive"
    defaults = [8 6 0.25];
else
    defaults = [12 8 1.00];
end
legacyCode=0;
if options.DetailLevel~="adaptive"
    switch options.DetailLevel
        case "low", defaults(1:2)=[10 5]; legacyCode=1;
        case "moderate", defaults(1:2)=[50 10]; legacyCode=2;
        case "high", defaults(1:2)=[100 20]; legacyCode=3;
    end
end
nodeDetail = scalarOrDefault(options.NodeDetail, defaults(1), 4, true, 'NodeDetail');
edgeSides = scalarOrDefault(options.EdgeSides, defaults(2), 3, true, 'EdgeSides');
surfaceFraction = scalarOrDefault(options.SurfaceFaceFraction, defaults(3), 0, false, ...
    'SurfaceFaceFraction');
if surfaceFraction <= 0 || surfaceFraction > 1
    error('BNV:Render:InvalidSurfaceFaceFraction', ...
        'SurfaceFaceFraction must be greater than 0 and at most 1.');
end
if ~isempty(prepared.SurfaceValues)
    surfaceFraction = 1;
end
capabilities = brainnet.render.internal.accelerationCapabilities();
value = struct( ...
    'requested_mode', char(options.Mode), ...
    'effective_mode', char(effectiveMode), ...
    'high_load', highLoad, ...
    'node_detail', nodeDetail, ...
    'edge_sides', edgeSides, ...
    'surface_face_fraction', surfaceFraction, ...
    'detail_level', char(options.DetailLevel), ...
    'legacy_detail_code', legacyCode, ...
    'compute_backend', char(options.ComputeBackend), ...
    'capabilities', capabilities, ...
    'rationale', char(rationale(effectiveMode, highLoad, surfaceFraction)));
end


function value = scalarOrDefault(candidate, defaultValue, minimum, integerRequired, name)
if isempty(candidate)
    value = defaultValue;
    return;
end
if ~isscalar(candidate) || ~isfinite(candidate) || candidate < minimum || ...
        (integerRequired && candidate ~= fix(candidate))
    error('BNV:Render:InvalidPerformanceOption', ...
        '%s is outside its supported range.', name);
end
value = candidate;
end


function value = rationale(mode, highLoad, surfaceFraction)
if mode == "interactive" && highLoad
    value = "high-load interactive LOD with vectorized geometry";
elseif mode == "interactive"
    value = "explicit interactive LOD with vectorized geometry";
elseif surfaceFraction < 1
    value = "explicit surface LOD with quality mesh settings";
else
    value = "full-quality vectorized geometry";
end
end
