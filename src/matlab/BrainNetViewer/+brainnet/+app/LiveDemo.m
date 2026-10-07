classdef LiveDemo < handle
    %LIVEDEMO Non-blocking continuous camera orbit for an existing render.

    properties (SetAccess = private)
        IsRunning (1,1) logical = false
        ActiveAxes = []
    end

    properties (Access = private)
        Timer = []
        AngleDegrees (1,1) double = 5
    end

    methods
        function start(obj,axesHandles,options)
            arguments
                obj (1,1) brainnet.app.LiveDemo
                axesHandles
                options.AngleDegrees (1,1) double = 5
                options.Period (1,1) double = 0.12
            end
            if ~isscalar(options.AngleDegrees) || ~isfinite(options.AngleDegrees) || options.AngleDegrees<=0
                error('BNV:Demo:Angle','Demo angle must be a positive finite scalar.');
            end
            if ~isscalar(options.Period) || ~isfinite(options.Period) || options.Period<0.05
                error('BNV:Demo:Period','Demo period must be at least 0.05 seconds.');
            end
            valid=axesHandles(isgraphics(axesHandles,'axes'));
            if isempty(valid), error('BNV:Demo:RenderRequired','Render a scene before starting Live Demo.'); end
            obj.stop();
            obj.ActiveAxes=reshape(valid,1,[]);
            obj.AngleDegrees=options.AngleDegrees;
            obj.Timer=timer('ExecutionMode','fixedSpacing','Period',options.Period, ...
                'BusyMode','drop','TimerFcn',@(~,~) obj.tick(), ...
                'ErrorFcn',@(~,~) obj.stop());
            obj.IsRunning=true;
            start(obj.Timer);
        end

        function tick(obj)
            if ~obj.IsRunning || isempty(obj.ActiveAxes) || ~all(isgraphics(obj.ActiveAxes,'axes'))
                obj.stop(); return;
            end
            try
                for axesHandle=reshape(obj.ActiveAxes,1,[])
                    camorbit(axesHandle,obj.AngleDegrees,0,'camera');
                    lights=findall(axesHandle,'Type','light','Tag','brainnet-camera-light');
                    for lightHandle=reshape(lights,1,[])
                        direction="headlight";
                        if isstruct(lightHandle.UserData) && isfield(lightHandle.UserData,'brainnet_light_direction')
                            direction=string(lightHandle.UserData.brainnet_light_direction);
                        end
                        camlight(lightHandle,char(direction));
                    end
                end
                drawnow limitrate;
            catch
                obj.stop();
            end
        end

        function stop(obj)
            activeTimer=obj.Timer;
            obj.Timer=[];
            obj.IsRunning=false;
            obj.ActiveAxes=[];
            if isempty(activeTimer), return; end
            try
                stop(activeTimer);
            catch
            end
            try
                delete(activeTimer);
            catch
            end
        end

        function delete(obj)
            obj.stop();
        end
    end
end
