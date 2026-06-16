function test_countdown_layout_minimal
    AssertOpenGL;
    Screen('Preference', 'SkipSyncTests', 1);

    screens = Screen('Screens');
    screenNumber = max(screens);
    [windowPtr, rect] = Screen('OpenWindow', screenNumber, [0 0 0]);

    try
        Screen('TextFont', windowPtr, 'Arial');
        Screen('TextSize', windowPtr, 28);
        Screen('TextStyle', windowPtr, 0);

        moveDurSec = 1.6;
        startT = GetSecs;

        while true
            elapsed = GetSecs - startT;
            if elapsed > moveDurSec
                break;
            end

            remaining = max(0, moveDurSec - elapsed);
            frac = min(1, elapsed / moveDurSec);
            showResponsePrompt = elapsed >= 0.25;

            Screen('FillRect', windowPtr, [0 0 0]);

            screenX = rect(3);
            screenY = rect(4);

            instrY = 120;
           
         
            centerY = screenY / 2;
            
            instrY = round(centerY - 140);
            timerY = round(centerY + 20);
            respY  =  round(centerY - 60);
            barY   = round(centerY + 120);

            DrawFormattedText(windowPtr, 'Keep moving your arm left', ...
                'center', instrY, [255 255 255]);

            DrawFormattedText(windowPtr, sprintf('Time left: %.1f s', remaining), ...
                'center', timerY, [255 255 255]);

            if showResponsePrompt
                DrawFormattedText(windowPtr, 'Left or Right Response', ...
                    'center', respY, [255 255 255]);
            end

            barW = 500;
            barH = 24;
            barX = round((screenX - barW) / 2);

            Screen('FrameRect', windowPtr, [255 0 0], ...
                [barX, barY, barX + barW, barY + barH], 2);

            Screen('FillRect', windowPtr, [255 255 255], ...
                [barX, barY, barX + round(barW * frac), barY + barH]);

            Screen('Flip', windowPtr);

            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown && keyCode(KbName('ESCAPE'))
                break;
            end
        end

        KbStrokeWait;
        Screen('CloseAll');

    catch ME
        Screen('CloseAll');
        rethrow(ME);
    end
end