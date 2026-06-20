function [trialRow, myTrialHistory] = runActiveTrial(app, windowPtr, trialRow, n, expTime_start, myTrialHistory,speedStage,accStage,stepsStage,no_motion_flag,  w, w1,flipSpeed)

buttonPushed = [];
respTime = [];
encoderSamples = [];
startStim = nan;
stimEndTime = nan;

stimStarted = false;
indentMovedDown = false;

viewDistCm = 71;
screenWidthCm = 47;
ballDiamDeg = 1.0;
padCm = 0;

if w1 =="fast"
    speedToTrain = ExpConfig.fast_target;
elseif w1 == "slow"
    speedToTrain = ExpConfig.slow_target;
end 
moveDir = w;
    % ---------------------  TRIAL ONSET  ---------------------
startTrial = GetSecs;
trialRow.TrialStart_time = startTrial - expTime_start;

printActiveMotionCue(app, windowPtr, w, w1, no_motion_flag);

if no_motion_flag
    startArmMov = GetSecs;
    trialRow.Arm_Mov_Onset = startArmMov - expTime_start;
else
    [startArmMov, onsetSample] = waitForEncoderMotion(app, app.encoderThreshold_cm);
    if isempty(onsetSample)
        encoderSamples = [];
    else
        encoderSamples = onsetSample;
    end
    trialRow.Arm_Mov_Onset = startArmMov - expTime_start;

    drawActiveMovementCountdown(app, windowPtr, w, ExpConfig.StageMotionDur_sec, startArmMov, ...
                    false, speedToTrain, moveDir, screenWidthCm, ballDiamDeg, viewDistCm, padCm)
end

stimDurSec = trialRow.StimDuration_arduino / 1000;

while true
    elapsed = GetSecs - startArmMov;

    if ~stimStarted && elapsed >= app.stimLagSec
        write(app.rotation_and_spin_motor, sprintf("%d %d %d\n", 3, ...
            flipSpeed * trialRow.StimSpeed_arduino, ...
            trialRow.StimDuration_arduino), "string");

        startStim = GetSecs;
        trialRow.StimOnset = startStim - expTime_start;
        stimEndTime = startStim + stimDurSec;
        stimStarted = true;

        indentLoc = app.curIndent;
        write(app.indentationActuator, sprintf("%d %d\n", 1, indentLoc), "string");
        indentMovedDown = true;
    end

    if no_motion_flag
        if stimStarted
            printResponsePrompt(app, windowPtr);
        end
    else
        drawActiveMovementCountdown(app, windowPtr, w, ExpConfig.StageMotionDur_sec, startArmMov, ...
                        stimStarted, speedToTrain, moveDir, screenWidthCm, ballDiamDeg, viewDistCm, padCm)
    end

    % collect encoder from arm movement onset onward
    newSamples = readAvailableEncoderSamples(app);
    if ~isempty(newSamples)
        encoderSamples = [encoderSamples; newSamples];
       
    end

    if stimStarted
        [~, ~, buttons] = GetMouse;
        if any(buttons)
            buttonPushed = find(buttons ~= 0, 1);
            respTime = GetSecs - startStim;
            DrawFormattedText(windowPtr, 'Wait...', 'center', 'center', [255 255 255]);
            Screen('Flip', windowPtr);
            break;
        end

        if GetSecs >= stimEndTime
            break;
        end
    end

    if ~no_motion_flag && elapsed >= app.moveDurSec && ~stimStarted
        break;
    end

    drawnow limitrate
    if app.stopGUI == 1
        app.stopGUI = 0;
        error('Experiment stopped');
    end
end

if indentMovedDown
    indentLoc = app.indentZero;
    write(app.indentationActuator, sprintf("%d %d\n", 1, indentLoc), "string");
end
avgVelocity = computeAverageEncoderVelocity(app, encoderSamples);
updateCurrentSpeedDisplay(app, avgVelocity);
trialRow.MeasuredSpeed_cm_s = avgVelocity;
trialRow.EncoderSamples = {encoderSamples};



if stimStarted && isempty(buttonPushed)
    [buttonPushed, respTime] = waitForResponse(app, windowPtr, startStim);
elseif ~stimStarted
    trialRow.StimOnset = nan;
end

trialRow.Response = buttonPushed;
trialRow.ReactionTime = respTime;
%myTrialHistory = printResponseInfo(app, myTrialHistory, buttonPushed);
end
% 
% function drawActiveMovementCountdown(app, windowPtr, w, moveDurSec, startArmMov, showResponsePrompt)
% elapsed = GetSecs - startArmMov;
% if elapsed > moveDurSec
%     elapsed = moveDurSec;
% elseif elapsed < 0
%     elapsed = 0;
% end
% 
% remaining = max(0, moveDurSec - elapsed);
% frac = min(1, elapsed / moveDurSec);
% 
% Screen('FillRect', windowPtr, [0 0 0]);
% 
% [screenX, screenY] = Screen('WindowSize', windowPtr);
% 
% Screen('TextFont', windowPtr, 'Arial');
% Screen('TextSize', windowPtr, 28);
% Screen('TextStyle', windowPtr, 0);
% 
% centerY = screenY / 2;
% 
% instrY = round(centerY - 140);
% respY  = round(centerY - 60);
% timerY = round(centerY + 20);
% barY   = round(centerY + 120);
% 
% DrawFormattedText(windowPtr, sprintf('Keep moving your arm %s', w), ...
%     'center', instrY, [255 255 255]);
% 
% if showResponsePrompt
%     DrawFormattedText(windowPtr, 'Left or Right Response', ...
%         'center', respY, [255 255 255]);
% end
% 
% DrawFormattedText(windowPtr, sprintf('Time left: %.1f s', remaining), ...
%     'center', timerY, [255 255 255]);
% 
% barW = 500;
% barH = 24;
% barX = round((screenX - barW) / 2);
% 
% Screen('FrameRect', windowPtr, [255 255 255], ...
%     [barX, barY, barX + barW, barY + barH], 2);
% 
% Screen('FillRect', windowPtr, [255 255 255], ...
%     [barX, barY, barX + round(barW * frac), barY + barH]);
% 
% Screen('Flip', windowPtr);
% end

function printActiveMotionCue(app, windowPtr, w, w1, no_motion_flag)
if ~no_motion_flag
    textString = sprintf('Move your arm %s with %s speed', w, w1);
else
    textString = 'Keep you arm in the same position';
end
DrawFormattedText(windowPtr, textString, 'center', 'center', [255 255 255]);
Screen('Flip', windowPtr);
WaitSecs(2);
end

function drawActiveMovementCountdown(app, windowPtr, w, moveDurSec, startArmMov, ...
    showResponsePrompt, speedCmPerSec, moveDir, screenWidthCm, ballDiamDeg, ...
    viewDistCm, padCm)

% elapsed time
elapsed = GetSecs - startArmMov;
if elapsed > moveDurSec
    elapsed = moveDurSec;
elseif elapsed < 0
    elapsed = 0;
end

% clear screen
Screen('FillRect', windowPtr, [0 0 0]);

% window geometry
[screenX, screenY] = Screen('WindowSize', windowPtr);
centerY = screenY / 2;

% text settings
Screen('TextFont', windowPtr, 'Arial');
Screen('TextSize', windowPtr, 28);
Screen('TextStyle', windowPtr, 0);

instrY = round(centerY - 140);
respY  = round(centerY - 60);

DrawFormattedText(windowPtr, sprintf('Keep moving your arm %s', w), ...
    'center', instrY, [255 255 255]);

if showResponsePrompt
    DrawFormattedText(windowPtr, 'Left or Right Response', ...
        'center', respY, [255 255 255]);
end

% ----------------------------
% conversions
% ----------------------------
pixPerCm = screenX / screenWidthCm;

% ball size: degrees -> cm -> pixels
ballDiamCm = 2 * viewDistCm * tand(ballDiamDeg / 2);
ballDiamPix = max(6, round(ballDiamCm * pixPerCm));
ballRadiusPix = ballDiamPix / 2;

% motion distance
dxCm = speedCmPerSec * elapsed;
dxPix = dxCm * pixPerCm;

totalDxCm = speedCmPerSec * moveDurSec;
totalDxPix = totalDxCm * pixPerCm;

% padding corridor
padPix = padCm * pixPerCm;

leftBound  = padPix + ballRadiusPix;
rightBound = screenX - padPix - ballRadiusPix;
usableWidth = rightBound - leftBound;
% fprintf('screenX=%g, screenY=%g\n', screenX, screenY);
% fprintf('screenWidthCm=%g, viewDistCm=%g, ballDiamDeg=%g, padCm=%g\n', ...
%     screenWidthCm, viewDistCm, ballDiamDeg, padCm);
% fprintf('pixPerCm=%g\n', pixPerCm);
% fprintf('ballDiamCm=%g, ballDiamPix=%g\n', ballDiamCm, ballDiamPix);
% fprintf('speedCmPerSec=%g, moveDurSec=%g\n', speedCmPerSec, moveDurSec);
% fprintf('totalDxCm=%g, totalDxPix=%g\n', totalDxCm, totalDxPix);
% fprintf('leftBound=%g, rightBound=%g, usableWidth=%g\n', ...
%     leftBound, rightBound, usableWidth);

if totalDxPix > usableWidth
    error('Motion path too long for screen width and chosen padding.');
end

% center the full path within the padded corridor
pathLeft = leftBound + (usableWidth - totalDxPix) / 2;
pathRight = rightBound - (usableWidth - totalDxPix) / 2;

if strcmpi(moveDir, 'right')
    ballX = pathLeft + dxPix;
elseif strcmpi(moveDir, 'left')
    ballX = pathRight - dxPix;
else
    error('moveDir must be ''left'' or ''right''.');
end

% optional clamp for safety
ballX = max(leftBound, min(rightBound, ballX));

% vertical location of ball
ballY = centerY + 40;

ballRect = [ballX - ballRadiusPix, ballY - ballRadiusPix, ...
    ballX + ballRadiusPix, ballY + ballRadiusPix];

% draw ball
Screen('FillOval', windowPtr, [255 255 255], ballRect);

% optional: draw motion corridor for debugging
% Screen('FrameRect', windowPtr, [100 100 100], ...
%     [leftBound, ballY - 40, rightBound, ballY + 40], 1);

Screen('Flip', windowPtr);

end




function [startArmMov, onsetSample] = waitForEncoderMotion(app, threshold_cm)
startArmMov = NaN;
onsetSample = [];

flushRotaryEncoderBuffer(app);
writeline(app.rotaryEncoder, "ZERO"); %zeroRotaryEncoder(app);
pause(0.05);

while isnan(startArmMov)
    samples = readAvailableEncoderSamples(app);

    if ~isempty(samples)
        idx = find(abs(samples(:,3)) >= threshold_cm, 1, 'first');

        if ~isempty(idx)
            startArmMov = GetSecs;
            onsetSample = samples(idx,:);   % [t_ms count dist_cm]
            break;
        end
    end

    drawnow limitrate
    if app.stopGUI == 1
        app.stopGUI = 0;
        error('Experiment stopped');
    end
end
end
