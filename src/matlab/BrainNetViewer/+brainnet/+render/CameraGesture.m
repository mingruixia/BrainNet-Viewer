classdef CameraGesture
    %CAMERAGESTURE Pixel-based camera manipulation without axes resizing.
    methods (Static)
        function apply(axesHandles, action, delta)
            arguments
                axesHandles
                action (1,1) string
                delta (1,2) double
            end
            if ~any(action == ["rotate","pan","zoom"]) || ~all(isfinite(delta))
                error('BNV:Render:InvalidCameraGesture', 'Unsupported camera gesture.');
            end
            if ~any(delta), return; end
            for a = reshape(axesHandles,1,[])
                if ~isgraphics(a), continue; end
                target = double(a.CameraTarget);
                position = double(a.CameraPosition);
                forward = position-target;
                distance = norm(forward);
                if distance < eps, continue; end
                forward = forward/distance;
                up = double(a.CameraUpVector);
                up = up/norm(up);
                right = cross(up,forward);
                if norm(right)<eps, continue; end
                right = right/norm(right);
                up = cross(forward,right);
                switch action
                    case "rotate"
                        % Orbit the camera around the existing target. Neither
                        % viewport size nor the fitted camera angle changes.
                        yaw = -0.35*delta(1);
                        pitch = -0.35*delta(2);
                        forward = brainnet.render.CameraGesture.rotateVector(forward,up,yaw);
                        right = brainnet.render.CameraGesture.rotateVector(right,up,yaw);
                        forward = brainnet.render.CameraGesture.rotateVector(forward,right,pitch);
                        up = brainnet.render.CameraGesture.rotateVector(up,right,pitch);
                        a.CameraPosition = target + distance*forward;
                        a.CameraUpVector = up;
                    case "pan"
                        pixels = getpixelposition(a);
                        shortSide = max(min(pixels(3),pixels(4)),1);
                        unitsPerPixel = 2*distance*tand(a.CameraViewAngle/2)/shortSide;
                        shift = -unitsPerPixel*(delta(1)*right + delta(2)*up);
                        a.CameraTarget = target+shift;
                        a.CameraPosition = position+shift;
                    case "zoom"
                        angle = double(a.CameraViewAngle);
                        magnification = exp(-0.01*delta(2));
                        angle = 2*atand(tand(angle/2)*magnification);
                        a.CameraViewAngle = min(max(angle,1),170);
                end
            end
        end
    end
    methods (Static, Access=private)
        function vector = rotateVector(vector,axis,degrees)
            radians = deg2rad(degrees);
            vector = vector*cos(radians) + cross(axis,vector)*sin(radians) + ...
                axis*dot(axis,vector)*(1-cos(radians));
        end
    end
end
