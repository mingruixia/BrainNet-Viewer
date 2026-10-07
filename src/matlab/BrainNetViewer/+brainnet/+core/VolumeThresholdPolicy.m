classdef VolumeThresholdPolicy
    %VOLUMETHRESHOLDPOLICY Shared threshold-mode preflight for modern entries.
    methods (Static)
        function reason = blocker(settings)
            reason="";
            % Metadata are checked after loading the NIfTI; P itself can be
            % validated before an App Apply, preset or CLI render.
            if string(settings.threshold_mode)=="p-value" && ...
                    (~isfinite(settings.p_value) || settings.p_value<=0 || settings.p_value>=1)
                reason="P Value must be strictly between 0 and 1.";
            end
        end
        function requireSupported(settings)
            reason=brainnet.core.VolumeThresholdPolicy.blocker(settings);
            if strlength(reason)>0
                error('BNV:Volume:InvalidPValue','%s',reason);
            end
        end
    end
end
