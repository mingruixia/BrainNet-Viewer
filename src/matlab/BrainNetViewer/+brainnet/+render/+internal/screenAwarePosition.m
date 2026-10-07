function position = screenAwarePosition(requestedSize, monitorPositions, options)
%SCREENAWAREPOSITION Center a bounded window inside a selected monitor.

arguments
    requestedSize (1, 2) double {mustBePositive} = [1600 1200]
    monitorPositions double = get(groot, 'MonitorPositions')
    options.Margin (1, 1) double {mustBeNonnegative} = 40
    options.MinimumSize (1, 2) double {mustBePositive} = [320 240]
    options.AdaptiveScale (1, 1) logical = false
    options.MonitorFraction (1, 2) double {mustBePositive} = [1 1]
    options.MaximumScale (1, 1) double {mustBePositive} = 1
    options.AnchorPoint (1, 2) double = [NaN NaN]
end

if any(options.MonitorFraction > 1)
    error('BNV:Render:InvalidMonitorFraction', ...
        'MonitorFraction values must not exceed 1.');
end

if isempty(monitorPositions) || size(monitorPositions, 2) ~= 4 || ...
        any(~isfinite(monitorPositions), 'all') || ...
        any(monitorPositions(:, 3:4) <= 0, 'all')
    monitorPositions = get(groot, 'ScreenSize');
end
monitor = monitorPositions(1, :);
if all(isfinite(options.AnchorPoint))
    point=options.AnchorPoint;
    inside=point(1)>=monitorPositions(:,1) & point(1)<monitorPositions(:,1)+monitorPositions(:,3) & ...
        point(2)>=monitorPositions(:,2) & point(2)<monitorPositions(:,2)+monitorPositions(:,4);
    if any(inside)
        monitor=monitorPositions(find(inside,1),:);
    else
        dx=max(max(monitorPositions(:,1)-point(1),0), ...
            point(1)-(monitorPositions(:,1)+monitorPositions(:,3)));
        dy=max(max(monitorPositions(:,2)-point(2),0), ...
            point(2)-(monitorPositions(:,2)+monitorPositions(:,4)));
        [~,nearest]=min(dx.^2+dy.^2);
        monitor=monitorPositions(nearest,:);
    end
end
available = max(monitor(3:4) - 2 * options.Margin, ...
    min(options.MinimumSize, monitor(3:4)));
if options.AdaptiveScale
    adaptiveAvailable = min(available, monitor(3:4) .* options.MonitorFraction);
    scale = min(adaptiveAvailable ./ requestedSize);
    scale = min(scale, options.MaximumScale);
    windowSize = requestedSize .* scale;
else
    windowSize = min(requestedSize, available);
end
windowSize = min(windowSize, available);
windowSize = max(windowSize, min(options.MinimumSize, monitor(3:4)));
origin = monitor(1:2) + (monitor(3:4) - windowSize) / 2;
position = round([origin windowSize]);
end
