function point=matlabDesktopAnchor()
%MATLABDESKTOPANCHOR Locate the MATLAB desktop's monitor in graphics pixels.
point=[NaN NaN];
try
    if usejava('desktop')
        % R2025a may expose an obsolete/stale MLDesktop frame. The active
        % window is a better anchor for a launch from the MATLAB desktop.
        frame=java.awt.KeyboardFocusManager.getCurrentKeyboardFocusManager().getActiveWindow();
        if isempty(frame) || ~frame.isShowing()
            try
                frame=com.mathworks.mde.desk.MLDesktop.getInstance().getMainFrame();
            catch
            end
        end
        if ~isempty(frame) && frame.isShowing()
            location=frame.getLocationOnScreen();
            size=frame.getSize();
            monitors=get(groot,'MonitorPositions');
            point=[double(location.x)+double(size.width)/2+1, ...
                double(monitors(1,4))-double(location.y)-double(size.height)/2+1];
        end
    end
catch
    % Fall through to the pointer when desktop internals are unavailable.
end
try
    % A launch from the desktop normally leaves the pointer there. It also
    % resolves mixed-DPI setups where AWT's coordinates map to screen #1.
    pointer=get(groot,'PointerLocation');
    monitors=get(groot,'MonitorPositions');
    point=brainnet.render.internal.selectDesktopAnchor(point,pointer,monitors);
catch
end
end
