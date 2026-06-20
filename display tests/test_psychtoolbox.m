try
    Screen('Preference', 'SkipSyncTests', 1);
    screenNum = max(Screen('Screens'));
    [win, rect] = Screen('OpenWindow', screenNum, [128 128 128]);

    textString = ['Judge if stimulus moves left or right relative to your trunk' newline newline newline newline ...
                  'Experiment will begin in 3 seconds'];

    DrawFormattedText(win, textString, 'center', 'center', [255 255 255]); % <-- win, not screenNum
    Screen('Flip', win);  % <-- win, not screenNum

    KbWait;
    Screen('CloseAll');
catch e
    Screen('CloseAll');
    rethrow(e);
end