function [buttonPushed, respTime] = waitForResponse(app, windowPtr, startStim)
    % Helper function to wait for a mouse response after the stimulus period
    % if no response was given yet.
    while true
        [~, ~, buttons] = GetMouse;
        if any(buttons)
            buttonPushed = find(buttons ~= 0, 1);
            respTime = GetSecs - startStim;
            DrawFormattedText(windowPtr, 'Wait...', 'center', 'center', [255 255 255]);
            Screen('Flip', windowPtr);

            return
        end

        drawnow limitrate
        if app.stopGUI == 1
            app.stopGUI = 0;
            error('Experiment stopped');
        end
    end
end
