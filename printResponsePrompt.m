
function printResponsePrompt(app, windowPtr)
    textString = 'Left or Right Response';
    DrawFormattedText(windowPtr, textString, 'center', 'center', [255 255 255]);
    Screen('Flip', windowPtr);
end