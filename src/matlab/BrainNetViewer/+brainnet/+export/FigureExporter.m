classdef FigureExporter
    %FIGUREEXPORTER Export figures and write reproducibility sidecars.

    properties (SetAccess = private)
        RootPath (1, 1) string
    end

    methods
        function obj = FigureExporter(rootPath)
            arguments
                rootPath (1, 1) string
            end
            if strlength(rootPath) == 0
                error('BNV:Export:EmptyRoot', 'An export root is required.');
            end
            if ~isfolder(rootPath)
                [created, message] = mkdir(rootPath);
                if ~created
                    error('BNV:Export:CreateRootFailed', ...
                        'Could not create the export root: %s', message);
                end
            end
            obj.RootPath = string(char(java.io.File(char(rootPath)).getCanonicalPath()));
        end

        function record = exportFigure(obj, figureHandle, relativePath, scene, prepared, renderMetrics, options)
            arguments
                obj (1, 1) brainnet.export.FigureExporter
                figureHandle (1, 1)
                relativePath (1, 1) string
                scene (1, 1) brainnet.core.Scene
                prepared (1, 1) brainnet.render.PreparedScene
                renderMetrics (1, 1) struct
                options.Resolution (1, 1) double {mustBeInteger, mustBePositive} = 300
                options.Width double = []
                options.Height double = []
                options.Units (1, 1) string = "pixels"
                options.BackgroundColor (1, 1) string = "white"
                options.ContentType (1, 1) string = "auto"
                options.Overwrite (1, 1) logical = false
            end
            if ~isgraphics(figureHandle) || ...
                    ~(isgraphics(figureHandle, 'figure') || ...
                    isgraphics(figureHandle, 'uipanel'))
                error('BNV:Export:InvalidFigure', ...
                    'A valid MATLAB figure or render panel is required.');
            end
            if xor(isempty(options.Width), isempty(options.Height))
                error('BNV:Export:IncompleteDimensions', ...
                    'Width and Height must be provided together.');
            end
            if ~isempty(options.Width) && ...
                    (~isscalar(options.Width) || ~isfinite(options.Width) || options.Width <= 0 || ...
                    ~isscalar(options.Height) || ~isfinite(options.Height) || options.Height <= 0)
                error('BNV:Export:InvalidDimensions', ...
                    'Width and Height must be finite positive scalars.');
            end
            allowedUnits = ["pixels", "millimeters", "inches", "centimeters", "points"];
            if ~any(options.Units == allowedUnits)
                error('BNV:Export:InvalidUnits', 'Unsupported export units: %s', options.Units);
            end
            allowedContent = ["auto", "image", "vector"];
            if ~any(options.ContentType == allowedContent)
                error('BNV:Export:InvalidContentType', ...
                    'ContentType must be auto, image, or vector.');
            end

            background = resolveBackground(figureHandle, options.BackgroundColor);

            [destination, normalizedRelative, format] = obj.resolve(relativePath);
            rasterFormats = ["png", "jpg", "jpeg", "tif", "tiff", "bmp"];
            if options.BackgroundColor == "none" && any(format == ["jpg", "jpeg", "bmp"])
                error('BNV:Export:TransparentBackgroundUnsupported', ...
                    'JPEG and BMP output do not support a transparent background.');
            end
            sidecar = destination + ".provenance.json";
            if ~options.Overwrite && (isfile(destination) || isfile(sidecar))
                error('BNV:Export:OutputExists', ...
                    'Export output already exists. Set Overwrite=true to replace it.');
            end
            parent = string(fileparts(destination));
            if ~isfolder(parent)
                [created, message] = mkdir(parent);
                if ~created
                    error('BNV:Export:CreateFolderFailed', ...
                        'Could not create the export folder: %s', message);
                end
            end

            temporaryOutput = string(tempname(parent)) + "." + format;
            temporarySidecar = string(tempname(parent)) + ".json";
            temporaryRaster = string(tempname(parent)) + ".png";
            cleanup = onCleanup(@() cleanupFiles( ...
                [temporaryOutput temporarySidecar temporaryRaster]));
            [contentType, selectionReason, estimatedPrimitives] = ...
                obj.selectContentType(format, options.ContentType, prepared);
            nameValues = {'ContentType', char(contentType), ...
                'Resolution', options.Resolution, ...
                'BackgroundColor', background, ...
                'Padding', 'figure'};
            actualWidth = options.Width;
            actualHeight = options.Height;
            actualUnits = options.Units;
            if actualUnits == "millimeters" && ~isempty(actualWidth)
                actualWidth = actualWidth / 10;
                actualHeight = actualHeight / 10;
                actualUnits = "centimeters";
            end
            if ~any(format == rasterFormats) && actualUnits == "pixels" && ~isempty(actualWidth)
                actualWidth = actualWidth / options.Resolution;
                actualHeight = actualHeight / options.Resolution;
                actualUnits = "inches";
            end
            if ~isempty(options.Width)
                nameValues = [nameValues, {'Width', actualWidth, ...
                    'Height', actualHeight, 'Units', char(actualUnits), ...
                    'PreserveAspectRatio', 'on'}]; % Pad, never distort scientific geometry.
            end
            [annotationCleanup, prepareAnnotations, annotationRecord] = ...
                annotationExport(figureHandle, options, format, contentType); %#ok<ASGLU>
            if format == "bmp"
                exportWithExactRasterSize(figureHandle, temporaryRaster, nameValues, options, true, prepareAnnotations);
                [pixels, ~, alpha] = imread(temporaryRaster);
                if ~isempty(alpha)
                    matte = repmat(reshape(255 * background,1,1,3),size(pixels,1),size(pixels,2));
                    weight = double(alpha) / double(intmax(class(alpha)));
                    pixels = cast(double(pixels) .* weight + ...
                        matte .* (1 - weight), 'like', pixels);
                end
                imwrite(pixels, temporaryOutput, 'bmp');
            else
                exportWithExactRasterSize(figureHandle, temporaryOutput, nameValues, ...
                    options, any(format == rasterFormats), prepareAnnotations);
            end
            if ~isfile(temporaryOutput) || dir(temporaryOutput).bytes == 0
                error('BNV:Export:EmptyOutput', 'The graphics export did not create a nonempty file.');
            end
            transparencyMethod = 'not-requested'; matteAlignment=[0 0];
            if options.BackgroundColor == "none" && any(format == rasterFormats)
                transparencyMethod = 'native-alpha';
                [pixels, ~, alpha] = imread(temporaryOutput);
                if isempty(alpha) && size(pixels,3) ~= 4
                    % Some MATLAB raster backends silently flatten "none".
                    % Recover composited alpha from matched near-black/white mattes,
                    % never from a color key (which erases dark/white anatomy).
                    matteAlignment=exportRasterAlpha(figureHandle,temporaryOutput,nameValues,options,prepareAnnotations);
                    transparencyMethod = 'matched-near-black-white-mattes';
                end
            end

            record = obj.buildRecord(normalizedRelative, format, temporaryOutput, ...
                scene, prepared, renderMetrics, options, contentType, ...
                selectionReason, estimatedPrimitives, ...
                actualWidth, actualHeight, actualUnits);
            % Record both the requested policy and the exact resolved canvas RGB.
            record.export.background_color_resolved = background;
            record.export.transparency_method = transparencyMethod;
            record.export.matte_padding_alignment_pixels=matteAlignment;
            record.text_rendering = annotationRecord();
            writeJson(temporarySidecar, record);
            movefile(temporaryOutput, destination, 'f');
            movefile(temporarySidecar, sidecar, 'f');
        end

        function value = supportedFormats(~)
            value = struct( ...
                'png', struct('content', 'image', 'multipage', false), ...
                'jpg', struct('content', 'image', 'multipage', false), ...
                'tif', struct('content', 'image', 'multipage', false), ...
                'bmp', struct('content', 'image-fallback', 'multipage', false), ...
                'pdf', struct('content', 'vector-or-mixed', 'multipage', false), ...
                'svg', struct('content', 'vector-or-mixed', 'multipage', false));
        end

        function value = assessedFormats(~)
            value = struct( ...
                'gif', struct('decision', 'defer', ...
                    'reason', 'Static indexed output adds little value before movie export is redesigned.'), ...
                'eps', struct('decision', 'defer', ...
                    'reason', 'Legacy publication format; add only with verified user demand and regression coverage.'), ...
                'emf', struct('decision', 'do-not-enable-cross-platform', ...
                    'reason', 'Windows-only output conflicts with the cross-platform format baseline.'));
        end
    end

    methods (Access = private)
        function [destination, normalized, format] = resolve(obj, relativePath)
            normalized = replace(relativePath, "\", "/");
            if strlength(normalized) == 0 || startsWith(normalized, "/") || ...
                    startsWith(normalized, "\") || ...
                    ~isempty(regexp(normalized, '^[A-Za-z]:[/\\]', 'once'))
                error('BNV:Export:InvalidRelativePath', ...
                    'Export paths must be nonempty and relative to the export root.');
            end
            segments = split(normalized, "/");
            if any(segments == "..")
                error('BNV:Export:ParentTraversal', ...
                    'Export paths cannot contain parent traversal.');
            end
            [~, ~, extension] = fileparts(normalized);
            format = lower(extractAfter(string(extension), 1));
            if ~any(format == ["png", "jpg", "jpeg", "tif", "tiff", "bmp", "pdf", "svg"])
                error('BNV:Export:UnsupportedFormat', ...
                    ['Supported export extensions are .png, .jpg/.jpeg, ' ...
                    '.tif/.tiff, .bmp, .pdf, and .svg.']);
            end
            destination = string(char(java.io.File(char(fullfile(obj.RootPath, ...
                replace(normalized, "/", filesep)))).getCanonicalPath()));
            prefix = obj.RootPath + string(filesep);
            if ispc
                inside = startsWith(lower(destination), lower(prefix));
            else
                inside = startsWith(destination, prefix);
            end
            if ~inside
                error('BNV:Export:OutsideRoot', 'Export output must remain inside the export root.');
            end
        end

        function record = buildRecord(obj, relativePath, format, outputPath, ...
                scene, prepared, renderMetrics, options, contentType, ...
                selectionReason, estimatedPrimitives, ...
                actualWidth, actualHeight, actualUnits)
            record = struct;
            record.schema_version = '1.0';
            record.display_rules = struct('version', '1.0', ...
                'surface_scalar_null_color_rule', 'exact-zero-or-nonfinite', ...
                'surface_scalar_legend', 'continuous-colormap');
            record.kind = 'brainnet-viewer-export-provenance';
            record.generated_at = char(datetime('now', 'TimeZone', 'local', ...
                'Format', 'yyyy-MM-dd''T''HH:mm:ssXXX'));
            record.matlab_release = version('-release');
            record.scene = scene.toStruct();
            record.prepared_scene = prepared.summary();
            record.renderer = renderMetrics;
            record.export = struct( ...
                'relative_path', char(relativePath), ...
                'format', char(format), ...
                'content_type_requested', char(options.ContentType), ...
                'content_type_used', char(contentType), ...
                'content_selection_reason', char(selectionReason), ...
                'estimated_graphics_primitives', estimatedPrimitives, ...
                'resolution_dpi', options.Resolution, ...
                'width', options.Width, ...
                'height', options.Height, ...
                'units', char(options.Units), ...
                'effective_width', actualWidth, ...
                'effective_height', actualHeight, ...
                'effective_units', char(actualUnits), ...
                'preserve_aspect_ratio', true, ...
                'background_color', char(options.BackgroundColor), ...
                'size_bytes', dir(outputPath).bytes, ...
                'sha256', char(brainnet.io.internal.sha256File(outputPath)), ...
                'sidecar_relative_path', char(relativePath + ".provenance.json"));
            if any(format == ["png", "jpg", "jpeg", "tif", "tiff", "bmp"])
                information = imfinfo(outputPath);
                record.export.actual_width_pixels = information.Width;
                record.export.actual_height_pixels = information.Height;
            elseif format == "pdf"
                record.export.page_count = 1;
            end
            record.export_root = char(obj.RootPath);
        end

        function [contentType, reason, estimatedPrimitives] = ...
                selectContentType(~, format, requested, prepared)
            estimatedPrimitives = prepared.FaceCount + ...
                264 * prepared.NodeCount + 16 * prepared.EdgeCount;
            if any(format == ["png", "jpg", "jpeg", "tif", "tiff", "bmp"])
                if requested == "vector"
                    error('BNV:Export:ContentTypeFormatMismatch', ...
                        'Raster output supports image content only.');
                end
                contentType = "image";
                reason = format + "-image-only";
            elseif requested ~= "auto"
                contentType = requested;
                reason = "explicit-user-selection";
            elseif estimatedPrimitives > 5000
                contentType = "image";
                reason = "adaptive-image-for-complex-3d-scene";
            else
                contentType = "vector";
                reason = "adaptive-vector-for-simple-scene";
            end
        end
    end
end


function background = resolveBackground(target, requested)
switch requested
    case "current"
        if isgraphics(target,'figure')
            background = target.Color;
        else
            background = target.BackgroundColor;
        end
    case "white"
        background = [1 1 1];
    case "black"
        background = [0 0 0];
    case "none"
        background = 'none';
    otherwise
        error('BNV:Export:InvalidBackground', ...
            'Export background must be current, white, black, or none.');
end
end

function [cleanup,prepare,record] = annotationExport(target,options,format,contentType)
cleanup = []; prepare = []; record = @() struct('sizing','unchanged');
if ~any(format == ["png","pdf"]), return; end
titles = findall(target,'Tag','brainnet-image-title');
bars = findall(target,'Type','ColorBar');
if isempty(titles) && isempty(bars), return; end
oldTitles = cell(numel(titles),2); oldBars = cell(numel(bars),1);
for k=1:numel(titles)
    oldTitles(k,:) = {titles(k).FontUnits,titles(k).FontSize};
end
for k=1:numel(bars), oldBars{k} = bars(k).FontSize; end
layout = captureAnnotationLayout(target,titles,bars);
cleanup = onCleanup(@() restoreAnnotations(titles,bars,oldTitles,oldBars,layout));
ppi = get(groot,'ScreenPixelsPerInch');
position = getpixelposition(target); canvasInches = position(3:4)/ppi;
isImage = format == "png" || contentType == "image";
if isImage, step = 72/options.Resolution; else, step = 72/ppi; end
% Native backends quantize font ems to device pixels. Round to the nearest
% available em and report it, rather than claiming every backend emits 8pt.
resolved = repmat(round(12/step)*step,numel(titles),1);
scalarPoints = round(8/step)*step;
lastScale = 1; layoutAdjusted = false; lastGeometry = [];
prepare = @apply; record = @metadata;
    function apply(values)
        geometry=values;
        backgroundIndex=find(strcmp(values(1:2:end),'BackgroundColor'),1)*2;
        geometry{backgroundIndex}=[];
        % Black/white replay must share one settled layout. Reassigning
        % UIAxes positions/modes between identical renders can reflow it.
        if isequaln(geometry,lastGeometry), return; end
        widthIndex = find(strcmp(values(1:2:end),'Width'),1)*2;
        if ~isempty(widthIndex)
            heightIndex = find(strcmp(values(1:2:end),'Height'),1)*2;
            unitIndex = find(strcmp(values(1:2:end),'Units'),1)*2;
            switch string(values{unitIndex})
                case "pixels", inchesPerUnit = 1/options.Resolution;
                case "inches", inchesPerUnit = 1;
                case "centimeters", inchesPerUnit = 1/2.54;
                case "millimeters", inchesPerUnit = 1/25.4;
                case "points", inchesPerUnit = 1/72;
            end
            physicalSize = [values{widthIndex} values{heightIndex}]*inchesPerUnit;
            lastScale = min(physicalSize./canvasInches);
        else
            % Older MATLAB sizes image exports through Resolution, then pads.
            resolutionIndex = find(strcmp(values(1:2:end),'Resolution'),1)*2;
            lastScale = values{resolutionIndex}/options.Resolution;
        end
        for j=1:numel(bars)
            bars(j).FontSize = scalarPoints/lastScale*(1+1e-10);
        end
        for j=1:numel(titles)
            t = titles(j); t.FontUnits = 'points';
            for attempt=1:4
                t.FontSize = resolved(j)/lastScale*(1+1e-10);
                drawnow nocallbacks;
                % Renderer-owned titles have normalized positions and a
                % single-line literal string. Fit width, never truncate it.
                extent = t.Extent;
                if extent(3) <= .96, break; end
                next = floor(resolved(j)*.96/extent(3)/step)*step;
                if next < ceil(6/step)*step
                    error('BNV:Export:TitleTooLong', ...
                        'The complete title cannot fit at the minimum 6pt size.');
                end
                resolved(j) = min(resolved(j)-step,next);
            end
            if t.Extent(3) > .98
                error('BNV:Export:TitleTooLong','The complete title does not fit the export canvas.');
            end
        end
        adjusted = reserveAnnotationSpace(layout,titles,bars,ppi,lastScale,position(4));
        if layoutAdjusted && ~adjusted, restoreAnnotationLayout(layout); end
        layoutAdjusted=adjusted; lastGeometry=geometry;
    end
    function value = metadata
        value = struct('sizing','physical-points','title_target_points',12, ...
            'title_minimum_points',6,'title_font_points',reshape(resolved,1,[]), ...
            'scalar_target_points',8,'scalar_font_points',scalarPoints, ...
            'native_em_step_points',step,'render_scale',lastScale, ...
            'node_label_units','preserved','vertical_gutters_applied',layoutAdjusted);
    end
end

function restoreAnnotations(titles,bars,oldTitles,oldBars,layout)
restoreAnnotationLayout(layout);
for j=1:numel(titles)
    if isgraphics(titles(j))
        set(titles(j),'FontUnits',oldTitles{j,1},'FontSize',oldTitles{j,2});
    end
end
for j=1:numel(bars)
    if isgraphics(bars(j)), bars(j).FontSize = oldBars{j}; end
end
end

function layout = captureAnnotationLayout(target,titles,bars)
layout = struct('axes',[],'titleAxes',[],'bars',[]);
parents = gobjects(0);
for t=reshape(titles,1,[]), parents(end+1)=t.Parent; end
allAxes = findall(target,'Type','axes');
for a=reshape(allAxes,1,[])
    if ~isequal(a.Parent,target), continue; end
    state = struct('handle',a,'units',a.Units,'position',a.Position, ...
        'normalized',hgconvertunits(ancestor(a,'figure'),a.Position,a.Units,'normalized',a.Parent), ...
        'cameraModes',{{a.CameraPositionMode,a.CameraTargetMode,a.CameraUpVectorMode,a.CameraViewAngleMode}});
    if any(a==parents), layout.titleAxes=[layout.titleAxes state];
    else, layout.axes=[layout.axes state]; end
end
for b=reshape(bars,1,[])
    layout.bars=[layout.bars struct('handle',b,'units',b.Units,'position',b.Position, ...
        'normalized',hgconvertunits(ancestor(b,'figure'),b.Position,b.Units,'normalized',b.Parent))];
end
end

function restoreAnnotationLayout(layout)
for s=[layout.axes layout.titleAxes]
    a=s.handle; if ~isgraphics(a), continue; end
    if ~strcmp(a.Units,s.units), a.Units=s.units; end
    if ~isequal(a.Position,s.position), a.Position=s.position; end
    set(a,'CameraPositionMode',s.cameraModes{1},'CameraTargetMode',s.cameraModes{2}, ...
        'CameraUpVectorMode',s.cameraModes{3},'CameraViewAngleMode',s.cameraModes{4});
end
for s=layout.bars
    b=s.handle; if ~isgraphics(b), continue; end
    if ~strcmp(b.Units,s.units), b.Units=s.units; end
    if ~isequal(b.Position,s.position), b.Position=s.position; end
end
end

function adjusted = reserveAnnotationSpace(layout,titles,bars,ppi,scale,height)
% Font compensation can exceed fixed normalized gutters on a wide canvas.
% Reserve space in the source panel before rasterization, not in final padding.
padding = (2/scale)*ppi/72/height; % 2 physical points at the output size.
need = false; top = 1; bottom = 0;
for t=reshape(titles,1,[])
    index=find(arrayfun(@(s)isequal(s.handle,t.Parent),layout.titleAxes),1);
    if isempty(index), continue; end
    pos=layout.titleAxes(index).normalized; em=t.FontSize*ppi/72/height;
    anchor=pos(2)+t.Position(2)*pos(4);
    need=need || anchor+.6*em>1-padding/2;
end
for k=1:numel(bars)
    pos=layout.bars(k).normalized; em=bars(k).FontSize*ppi/72/height;
    need=need || pos(2)<1.25*em;
end
adjusted=need;
if ~need, return; end
for s=layout.titleAxes
    ts=titles(arrayfun(@(t)isequal(t.Parent,s.handle),titles)); pos=s.normalized;
    % Use the physical font em, not UIAxes normalized Extent: very short
    % UIAxes have a minimum inner plot box that differs from their Position.
    em=max([ts.FontSize])*ppi/72/height;
    anchor=pos(2)+ts(1).Position(2)*pos(4);
    pos(2)=pos(2)+min(0,1-padding-.75*em-anchor);
    if ~strcmp(s.handle.Units,'normalized')||~isequal(s.handle.Position,pos),set(s.handle,'Units','normalized','Position',pos);end
    top=min(top,pos(2)+ts(1).Position(2)*pos(4)-.75*em-padding);
end
for k=1:numel(bars)
    pos=layout.bars(k).normalized; em=bars(k).FontSize*ppi/72/height;
    pos(2)=max(pos(2),1.5*em+padding);
    if ~strcmp(bars(k).Units,'normalized')||~isequal(bars(k).Position,pos),set(bars(k),'Units','normalized','Position',pos);end
    bottom=max(bottom,pos(2)+pos(4)+padding);
end
if top-bottom<=0
    error('BNV:Export:AnnotationSpaceUnavailable','The canvas cannot hold physical annotation gutters (top=%g bottom=%g padding=%g height=%g scale=%g).',top,bottom,padding,height,scale);
end
if isempty(layout.axes), return; end
positions=vertcat(layout.axes.normalized); low=min(positions(:,2)); high=max(positions(:,2)+positions(:,4));
bottom=max(bottom,low); top=min(top,high);
if top<=bottom, error('BNV:Export:AnnotationSpaceUnavailable','No scientific viewport remains between annotation gutters.'); end
for s=layout.axes
    a=s.handle; pos=s.normalized;
    % Freeze the existing camera while changing viewport size; equal data
    % aspect ratios still preserve anatomy. Restore modes after old positions.
    set(a,'CameraPositionMode','manual','CameraTargetMode','manual','CameraUpVectorMode','manual','CameraViewAngleMode','manual');
    pos(2)=bottom+(pos(2)-low)*(top-bottom)/(high-low);
    pos(4)=pos(4)*(top-bottom)/(high-low);
    if ~strcmp(a.Units,'normalized')||~isequal(a.Position,pos),set(a,'Units','normalized','Position',pos);end
end
drawnow nocallbacks;
end

function renderPrepared(target,path,values,prepareAnnotations)
if ~isempty(prepareAnnotations), prepareAnnotations(values); end
exportgraphics(target,path,values{:});

end

function alignment=exportRasterAlpha(target,path,nameValues,options,prepareAnnotations)
alignment=[0 0];
blackPath = string(tempname(fileparts(path))) + ".png";
whitePath = string(tempname(fileparts(path))) + ".png";
cleanup = onCleanup(@() cleanupFiles([blackPath whitePath])); %#ok<NASGU>
backgroundIndex = find(strcmp(nameValues(1:2:end),'BackgroundColor'),1)*2;
% Pure black/white can make matching annotations disappear from MATLAB's
% content bounds, so the two exports acquire different padding even though
% their output sizes match. Keep both endpoints one code value inside RGB8.
low = 1/255; high = 254/255;
modernPair=~verLessThan('matlab','25.1') && ~isempty(options.Width);
if modernPair
    wi=find(strcmp(nameValues(1:2:end),'Width'),1)*2;
    hi=find(strcmp(nameValues(1:2:end),'Height'),1)*2;
    ui=find(strcmp(nameValues(1:2:end),'Units'),1)*2;
    ri=find(strcmp(nameValues(1:2:end),'Resolution'),1)*2;
    switch string(nameValues{ui})
        case "pixels", factor=1;
        case "inches", factor=options.Resolution;
        case "centimeters", factor=options.Resolution/2.54;
        case "millimeters", factor=options.Resolution/25.4;
        case "points", factor=options.Resolution/72;
    end
    nameValues{wi}=max(1,round(nameValues{wi}*factor));
    nameValues{hi}=max(1,round(nameValues{hi}*factor));
    nameValues{ui}='pixels';
    % Binary internal DPI makes integer pixel bounds exactly representable
    % in inches. Output pixels are native, never resampled; imwrite below
    % records the requested DPI. Annotation preparation uses options DPI.
    nameValues{ri}=2^ceil(log2(options.Resolution));
end
nameValues{backgroundIndex} = repmat(low,1,3);
blackPlan = exportWithExactRasterSize(target,blackPath,nameValues,options,true,prepareAnnotations);
nameValues{backgroundIndex} = repmat(high,1,3);
whitePlan = exportWithExactRasterSize(target,whitePath,nameValues,options,true,prepareAnnotations);
% Matte colors can change the native bounds by a pixel. Independent exact-
% size retries must not give the two renders different scales or origins.
if ~isempty(blackPlan) && ~isempty(whitePlan) && (modernPair || ~isequaln(blackPlan.geometry,whitePlan.geometry))
    plan = blackPlan;
    if whitePlan.scale < blackPlan.scale, plan = whitePlan; end
    baseValues = plan.values;
    for attempt=1:3
        inset=[.25 .5 .75]; inset=inset(attempt);
        values = baseValues;
        if ~verLessThan('matlab','25.1')
            wi = find(strcmp(values(1:2:end),'Width'),1)*2;
            hi = find(strcmp(values(1:2:end),'Height'),1)*2;
            ui = find(strcmp(values(1:2:end),'Units'),1)*2;
            switch string(values{ui})
                case "pixels", pixelsPerUnit = 1;
                case "inches", pixelsPerUnit = options.Resolution;
                case "centimeters", pixelsPerUnit = options.Resolution/2.54;
                case "millimeters", pixelsPerUnit = options.Resolution/25.4;
                case "points", pixelsPerUnit = options.Resolution/72;
            end
            % Avoid an integer-pixel boundary where native floating-point bounds
            % can round in opposite directions for the two matte colors.
            canvas=getpixelposition(target);
            if nameValues{wi}/canvas(3) < nameValues{hi}/canvas(4)
                % On a wide panel width sets the scientific scale. Keep its
                % original value; remove only empty vertical page padding.
                values{wi}=nameValues{wi};
                values{hi}=max(.5,nameValues{hi}*pixelsPerUnit-2*attempt)/pixelsPerUnit;
            elseif modernPair
                values{wi}=max(.5,nameValues{wi}-2*attempt);
                values{hi}=max(.5,nameValues{hi}-2*attempt);
            else
                ratio = values{hi}/values{wi};
                values{wi} = max(.5,floor(values{wi}*pixelsPerUnit)-inset)/pixelsPerUnit;
                values{hi} = values{wi}*ratio;
            end
            plan = [];
        end
        values{backgroundIndex} = repmat(low,1,3);
        plan = exportWithExactRasterSize(target,blackPath,values,options,true,prepareAnnotations,plan);
        values = plan.values;
        values{backgroundIndex} = repmat(high,1,3);
        try
            whitePlan=exportWithExactRasterSize(target,whitePath,values,options,true,prepareAnnotations,plan);
            blackPlan=plan;
            break;
        catch exception
            if ~strcmp(exception.identifier,'BNV:Export:MatteBoundsMismatch') || attempt==3
                rethrow(exception);
            end
            plan=[];
        end
    end
end
black = imread(blackPath); white = imread(whitePath);
if ~isequal(size(black),size(white)) || size(black,3)~=3
    error('BNV:Export:TransparencyUnavailable','Matched RGB matte renders are required for transparent output.');
end
black = double(black)/255; white = double(white)/255;
difference = white-black;
% Raising the matte must not darken a pixel or exceed the matte span.
% Allow RGB8 rounding; multisample blending can differ slightly by channel.
tolerance = 3/255+eps(1);
if any(difference < -tolerance | difference > high-low+tolerance,'all') && modernPair
    % Two legal center-padding roundings can differ by one pixel. Try only
    % those integer origins, only for a one-pixel non-scale-setting bound
    % difference, and only if the discarded edge is entirely blank padding.
    canvas=getpixelposition(target); primary=1;
    if nameValues{wi}/canvas(3)>=nameValues{hi}/canvas(4),primary=2;end
    secondary=3-primary;
    if blackPlan.size(primary)==whitePlan.size(primary) && ...
            abs(blackPlan.size(secondary)-whitePlan.size(secondary))==1
        for shift=[-1 1]
            candidate=shiftMattePadding(white,secondary,shift);
            if isempty(candidate),continue;end
            delta=candidate-black;
            if ~any(delta < -tolerance | delta > high-low+tolerance,'all')
                white=candidate;difference=delta;alignment(secondary)=shift;break;
            end
        end
    end
end
if any(difference < -tolerance | difference > high-low+tolerance,'all')
    error('BNV:Export:TransparencyUnavailable', ...
        'Matte renders are inconsistent; transparent output was not written.');
end
alpha = min(1,max(0,1-max(difference,[],3)/(high-low)));
rgb = uint8(255*min(1,max(0,(black-low*(1-alpha))./max(alpha,1/255))));
alpha = uint8(round(255*alpha));
[~,~,extension] = fileparts(path);
if strcmpi(extension,'.png')
    imwrite(rgb,path,'Alpha',alpha,'ResolutionUnit','meter', ...
        'XResolution',options.Resolution/0.0254,'YResolution',options.Resolution/0.0254);
else
    output = Tiff(char(path),'w');
    closeOutput = onCleanup(@() close(output)); %#ok<NASGU>
    tags = struct('ImageLength',size(rgb,1),'ImageWidth',size(rgb,2), ...
        'Photometric',Tiff.Photometric.RGB,'Compression',Tiff.Compression.LZW, ...
        'BitsPerSample',8,'SamplesPerPixel',4,'RowsPerStrip',32, ...
        'PlanarConfiguration',Tiff.PlanarConfiguration.Chunky, ...
        'ExtraSamples',Tiff.ExtraSamples.UnassociatedAlpha, ...
        'ResolutionUnit',Tiff.ResolutionUnit.Inch, ...
        'XResolution',options.Resolution,'YResolution',options.Resolution);
    setTag(output,tags); write(output,cat(3,rgb,alpha));
end
end

function plan = exportWithExactRasterSize(target, path, nameValues, options, isRaster, prepareAnnotations, sharedPlan)
if nargin < 7, sharedPlan = []; end
plan = [];
% R2025a can quantize aspect-preserving padding to two-pixel steps.
% On mismatch, render slightly smaller and center-pad; never crop/resample.
legacyOptions = verLessThan('matlab', '25.1');
if legacyOptions
    % R2024a accepts ContentType/Resolution/BackgroundColor, but none of
    % Padding/Width/Height/Units/PreserveAspectRatio. Size raster output by
    % resolution and center-pad without stretching the rendered anatomy.
    if ~isRaster && ~isempty(options.Width)
        error('BNV:Export:VectorDimensionsUnavailable', ...
            'This MATLAB release cannot set exact PDF/SVG dimensions. Use a raster format or a newer MATLAB release.');
    end
    nameValues = nameValues(1:6);
end
renderPrepared(target,path,nameValues,prepareAnnotations);
if ~isRaster || isempty(options.Width), return; end
switch options.Units
    case "pixels", pixelsPerUnit = 1;
    case "inches", pixelsPerUnit = options.Resolution;
    case "centimeters", pixelsPerUnit = options.Resolution / 2.54;
    case "millimeters", pixelsPerUnit = options.Resolution / 25.4;
    case "points", pixelsPerUnit = options.Resolution / 72;
end
expected = max(1,round([options.Width options.Height] * pixelsPerUnit));
info = imfinfo(path);
if isempty(sharedPlan)
    if isequal([info.Width info.Height],expected)
        plan = rasterPlan(nameValues,[info.Width info.Height],[0 0],legacyOptions);
        return;
    end
    if all([info.Width info.Height] <= expected)
        rasterPath = path;
    elseif legacyOptions
        rasterPath = path;
        for attempt = 1:4
            if all([info.Width info.Height] <= expected), break; end
            oldResolution = nameValues{4};
            nameValues{4} = max(1, min(oldResolution-1, ...
                floor(oldResolution * min(max(1,expected-2)./[info.Width info.Height]))));
            renderPrepared(target,rasterPath,nameValues,prepareAnnotations);
            info = imfinfo(rasterPath);
        end
    else
        widthIndex = find(strcmp(nameValues(1:2:end),'Width'),1)*2;
        heightIndex = find(strcmp(nameValues(1:2:end),'Height'),1)*2;
        original = [nameValues{widthIndex} nameValues{heightIndex}];
        rasterPath = string(tempname(fileparts(path))) + ".png";
        cleanup = onCleanup(@() cleanupFiles(rasterPath));
        factor = min(max(1,expected-2)./[info.Width info.Height]);
        for attempt = 1:3
            nameValues{widthIndex} = original(1)*factor;
            nameValues{heightIndex} = original(2)*factor;
            renderPrepared(target,rasterPath,nameValues,prepareAnnotations);
            info = imfinfo(rasterPath);
            if all([info.Width info.Height] <= expected), break; end
            factor = factor * min(max(1,expected-2)./[info.Width info.Height]);
        end
    end
    if any([info.Width info.Height] > expected)
        error('BNV:Export:RasterSizeMismatch', ...
            'Could not produce the requested raster dimensions without distortion.');
    end
    offset = floor((expected-[info.Width info.Height])/2);
    plan = rasterPlan(nameValues,[info.Width info.Height],offset,legacyOptions);
else
    rasterPath = path;
    offset = sharedPlan.offset;
    % Native viewport rounding can move the 3D frame even by one pixel.
    % Require equal bounds in the scale-setting dimension. One padding pixel
    % in the other dimension retains a shared origin and the RGB guard below.
    actual=[info.Width info.Height];
    wi=find(strcmp(nameValues(1:2:end),'Width'),1)*2;
    if isempty(wi)
        % Pre-R2025a has Resolution-only exports; retain its original bounds
        % policy and the unchanged RGB matte guard.
        if any(abs(actual-sharedPlan.size)>1)||any(offset+actual>expected)
            error('BNV:Export:MatteBoundsMismatch','Matched matte bounds changed unexpectedly.');
        end
    else
        hi=find(strcmp(nameValues(1:2:end),'Height'),1)*2;
        canvas=getpixelposition(target); primary=1;
        if nameValues{wi}/canvas(3)>=nameValues{hi}/canvas(4),primary=2;end
        secondary=3-primary;
        content=ceil(sharedPlan.size(primary)*canvas(secondary)/canvas(primary));
        % Center the same native panel, rather than independently rounding two
        % nested padding offsets. A one-pixel page-bound difference can otherwise
        % move an identical 3D viewport by a pixel. This is integer padding only.
        offset(secondary)=offset(secondary)+floor((sharedPlan.size(secondary)-content)/2)-floor((actual(secondary)-content)/2);
        if any(offset<0) || any(abs(actual-sharedPlan.size)>1) || actual(primary)~=sharedPlan.size(primary) || ...
                any(offset+actual>expected)
            error('BNV:Export:MatteBoundsMismatch', ...
                'Matched matte viewport changed (%dx%d versus %dx%d).',actual(1),actual(2),sharedPlan.size(1),sharedPlan.size(2));
        end
    end
    plan = sharedPlan; plan.size=actual; plan.offset=offset;
end
[pixels,map,alpha] = imread(rasterPath);
if ~isempty(map), pixels = uint8(255*ind2rgb(pixels,map)); end
if size(pixels,3)==1, pixels = repmat(pixels,1,1,3); end
background = pixels(1,1,:);
canvas = repmat(background,expected(2),expected(1),1);
rows = offset(2)+(1:info.Height); columns = offset(1)+(1:info.Width);
canvas(rows,columns,:) = pixels;
if ~isempty(alpha)
    paddedAlpha = zeros(expected(2),expected(1),'like',alpha);
    paddedAlpha(rows,columns) = alpha;
    alpha = paddedAlpha;
end
[~,~,extension] = fileparts(path);
switch lower(extension)
    case '.png'
        parameters = {'ResolutionUnit','meter','XResolution',options.Resolution/0.0254, ...
            'YResolution',options.Resolution/0.0254};
        if ~isempty(alpha), parameters = [parameters,{'Alpha',alpha}]; end
        imwrite(canvas,path,parameters{:});
    case {'.tif','.tiff'}
        if isempty(alpha)
            imwrite(canvas,path,'Compression','lzw','Resolution',options.Resolution);
        else
            output = Tiff(char(path),'w');
            closeOutput = onCleanup(@() close(output));
            tags = struct('ImageLength',expected(2),'ImageWidth',expected(1), ...
                'Photometric',Tiff.Photometric.RGB,'Compression',Tiff.Compression.LZW, ...
                'BitsPerSample',8,'SamplesPerPixel',4,'RowsPerStrip',32, ...
                'PlanarConfiguration',Tiff.PlanarConfiguration.Chunky, ...
                'ExtraSamples',Tiff.ExtraSamples.UnassociatedAlpha, ...
                'ResolutionUnit',Tiff.ResolutionUnit.Inch, ...
                'XResolution',options.Resolution,'YResolution',options.Resolution);
            setTag(output,tags); write(output,cat(3,canvas,alpha));
        end
    case {'.jpg','.jpeg'}
        imwrite(canvas,path,'Quality',95);
    otherwise
        imwrite(canvas,path);
end
end


function shifted=shiftMattePadding(pixels,dimension,shift)
% Reposition uniform padding only. No content cropping or resampling.
background=pixels(1,1,:); shifted=[];
if dimension==2
    edge=pixels(end,:,:);if shift<0,edge=pixels(1,:,:);end
else
    edge=pixels(:,end,:);if shift<0,edge=pixels(:,1,:);end
end
if ~all(edge==background,'all'),return;end
shifted=repmat(background,size(pixels,1),size(pixels,2),1);
if dimension==2
    if shift<0,shifted(1:end-1,:,:)=pixels(2:end,:,:);else,shifted(2:end,:,:)=pixels(1:end-1,:,:);end
else
    if shift<0,shifted(:,1:end-1,:)=pixels(:,2:end,:);else,shifted(:,2:end,:)=pixels(:,1:end-1,:);end
end
end

function plan = rasterPlan(values,size,offset,legacy)
geometry = values;
backgroundIndex = find(strcmp(values(1:2:end),'BackgroundColor'),1)*2;
geometry{backgroundIndex} = [];
if legacy
    index = find(strcmp(values(1:2:end),'Resolution'),1)*2;
else
    index = find(strcmp(values(1:2:end),'Width'),1)*2;
end
plan = struct('values',{values},'geometry',{{geometry,size,offset}}, ...
    'scale',values{index},'size',size,'offset',offset);
end


function writeJson(pathValue, value)
text = jsonencode(value, 'PrettyPrint', true);
handle = fopen(pathValue, 'w', 'n', 'UTF-8');
if handle < 0
    error('BNV:Export:SidecarOpenFailed', 'Could not open the provenance sidecar.');
end
cleanup = onCleanup(@() fclose(handle));
fprintf(handle, '%s', text);
end


function cleanupFiles(paths)
for pathValue = paths
    if isfile(pathValue)
        delete(pathValue);
    end
end
end
