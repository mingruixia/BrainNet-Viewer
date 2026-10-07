classdef MoviePlan
    %MOVIEPLAN Deterministic world-axis camera orbit; no scientific data edits.
    methods (Static)
        function plan=create(options)
            arguments
                options.Format (1,1) string {mustBeMember(options.Format,["mp4","avi","png"])}="mp4"
                options.Width (1,1) double {mustBeInteger,mustBeFinite}=960
                options.Height (1,1) double {mustBeInteger,mustBeFinite}=720
                options.Duration (1,1) double {mustBeFinite}=5
                options.FrameRate (1,1) double {mustBeInteger,mustBeFinite}=24
                options.Axis (1,1) string {mustBeMember(options.Axis,["x","y","z"])}="z"
                options.StartAngle (1,1) double {mustBeFinite}=0
                options.EndAngle (1,1) double {mustBeFinite}=360
                options.SafeFit (1,1) logical=true
            end
            count=round(options.Duration*options.FrameRate);
            delta=options.EndAngle-options.StartAngle;
            if any([options.Width options.Height]<128) || any([options.Width options.Height]>3840) || ...
                    options.Duration<=0 || options.Duration>120 || options.FrameRate<1 || options.FrameRate>60 || ...
                    count<2 || count>1800 || count*options.Width*options.Height>1e9 || ...
                    abs(options.StartAngle)>360 || abs(options.EndAngle)>720 || delta==0 || abs(delta)>360
                error('BNV:Movie:InvalidPlan','Use 128-3840 pixels, 1-60 fps, 2-1800 frames, at most 120 seconds / 1 billion frame-pixels, and a nonzero orbit up to 360 degrees.');
            end
            if options.Format~="png" && any(mod([options.Width options.Height],2))
                error('BNV:Movie:EvenDimensions','Video width and height must be even. PNG sequences allow odd dimensions.');
            end
            loop=abs(delta)==360;
            denominator=count-1; if loop, denominator=count; end
            angles=options.StartAngle+(0:count-1)*delta/denominator;
            plan=struct('version','1.0','format',char(options.Format),'width',options.Width,'height',options.Height, ...
                'requested_duration',options.Duration,'frame_rate',options.FrameRate,'frame_count',count, ...
                'actual_duration',count/options.FrameRate,'axis',char(options.Axis),'start_angle',options.StartAngle, ...
                'end_angle',options.EndAngle,'omit_duplicate_endpoint',loop,'angles',angles,'safe_fit',options.SafeFit);
        end
        function camera=orbit(base,axis,angle)
            arguments
                base struct
                axis (1,1) string {mustBeMember(axis,["x","y","z"])}
                angle (1,1) double {mustBeFinite}
            end
            c=cosd(angle); s=sind(angle);
            switch axis
                case "x", rotation=[1 0 0;0 c -s;0 s c];
                case "y", rotation=[c 0 s;0 1 0;-s 0 c];
                case "z", rotation=[c -s 0;s c 0;0 0 1];
            end
            camera=base;
            for k=1:numel(base.views)
                v=base.views(k);
                camera.views(k).position=(v.target(:)+rotation*(v.position(:)-v.target(:))).';
                camera.views(k).up=(rotation*v.up(:)).';
            end
        end
    end
end
