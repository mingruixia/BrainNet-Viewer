function [scene, report] = importLegacyConfig(path, dataRoot, options)
%IMPORTLEGACYCONFIG Import an EC MAT file, optionally with File and FLAG.
% EC-only files require Scene. Full-state files use LegacyStateAdapter.
% Only user-selected, trusted MATLAB configuration files should be imported.
arguments
    path (1, 1) string
    dataRoot (1, 1) string
    options.Scene brainnet.core.Scene = brainnet.core.Scene.empty
    options.Id (1, 1) string = "IMPORTED_SCENE"
    options.Name (1, 1) string = "Imported legacy scene"
end
variables = whos('-file', path);
names = string({variables.name});
selected = variables(ismember(names, ["EC", "File", "FLAG"]));
if ~any(names == "EC") || any(string({selected.class}) ~= "struct")
    error('BNV:IO:LegacyConfigStructure', ...
        'A legacy configuration must contain an EC structure; File and FLAG must also be structures.');
end
payload = load(path, 'EC');
if ~isscalar(payload.EC)
    error('BNV:IO:LegacyConfigStructure', 'EC must be a scalar structure.');
end
if isempty(options.Scene)
    if ~all(ismember(["File", "FLAG"], names))
        error('BNV:IO:LegacySceneRequired', ...
            'An EC-only configuration needs an existing Scene with selected input files.');
    end
    state = load(path, 'File', 'FLAG');
    if ~isscalar(state.File) || ~isscalar(state.FLAG)
        error('BNV:IO:LegacyConfigStructure', 'File and FLAG must be scalar structures.');
    end
    fileNames = {'MF', 'NI', 'NT', 'VF'};
    for index = 1:numel(fileNames)
        field = fileNames{index};
        if isfield(state.File, field) && ~isempty(state.File.(field))
            p = string(state.File.(field));
            if ~java.io.File(char(p)).isAbsolute()
                state.File.(field) = char(fullfile(dataRoot, p));
            end
        end
    end
    scene = brainnet.core.LegacyStateAdapter.fromLegacy(options.Id, ...
        options.Name, state.File, state.FLAG, payload.EC, dataRoot);
    mode = 'full-state';
else
    scene = options.Scene;
    mode = 'settings-only';
end
[renderOptions, migration] = brainnet.core.RenderOptions.fromLegacy(payload.EC, scene.MapMode);
report = migration;
report.import_mode = mode;
report.source_sha256 = char(brainnet.io.internal.sha256File(path));
report.source_file = char(path);
report.input_fields = cellstr(leafFields(payload.EC, "EC"));
report.fields_requiring_review = cellstr(setdiff( ...
    string(report.input_fields), string(report.mapped_fields), 'stable'));
report.lossless_claimed = false;
report.warnings{end + 1} = ...
    'Review fields_requiring_review: it includes ignored fields and conversions not individually certified by the legacy mapper.';
if ~isempty(options.Scene) && any(ismember(["File", "FLAG"], names))
    report.warnings{end + 1} = 'File and FLAG were ignored; the supplied Scene owns input files and map mode.';
end
value = scene.toStruct();
value.options = renderOptions.toStruct();
value.metadata.legacy_config_import = report;
scene = brainnet.core.Scene.fromStruct(value);
end

function paths = leafFields(value, prefix)
paths = strings(0, 1);
for name = string(fieldnames(value)).'
    path = prefix + "." + name;
    child = value.(name);
    if isstruct(child) && isscalar(child) && ~isempty(fieldnames(child))
        paths = [paths; leafFields(child, path)]; %#ok<AGROW>
    else
        paths(end + 1, 1) = path; %#ok<AGROW>
    end
end
end
