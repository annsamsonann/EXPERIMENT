function [outputArg1,outputArg2] = runTrial(app,windowPtr,isActive, speedStr, speedCmSec, moveDir)
buttonPushed = [];
respTime = [];
encoderSamples = [];
startStim = nan;
stimEndTime = nan;
stimStarted = false;
indentMovedDown = false;
startArmMov = NaN;
threshold_cm = ExpConfig.encoderThreshold_cm;
responded = false;


% ---------------------  TRIAL ONSET  ---------------------
startTrial = GetSecs;
trialRow.TrialStart_time = startTrial - expTime_start;

if no_motion_flag
    printNoMotionCue(app,windowPtr,isActive)
    WaitSecs(1);
 %   startArmMov = GetSecs;
else
    flushRotaryEncoderBuffer(app);
    writeline(app.rotaryEncoder, "ZERO");
    pause(0.05);
    while true
        showBall = true;
        drawInstructionCue(app, windowPtr, speedStr, speedCmPerSec, moveDir, startTrial, showBall)
        %% Is active - waits for encoder to sense motion
        if isActive % waits for encoder to sense motion
            newSamples = readAvailableEncoderSamples(app);
            if ~isempty(newSamples)
                if isnan(startArmMov)
                    idx = find(abs(newSamples(:,3)) >= threshold_cm, 1, 'first');
                    if ~isempty(idx)
                        %onsetSample = newSamples(idx,:);
                        startArmMov = GetSecs;
                        encoderSamples = newSamples(idx:end,:);   % optional
                        break
                    end
                end
            end
        %% Is passive - waits 1 sec 
        elseif ~isActive
            curClock = GetSecs;
            while (GetSecs - curClock) < 1
            end
        end 



        drawnow limitrate
        if app.stopGUI == 1
            app.stopGUI = 0;
            error('Experiment stopped');
        end
    end
end
trialRow.Arm_Mov_Onset = startArmMov - expTime_start;

stimDurSec = trialRow.StimDuration_arduino / 1000;

while true
    elapsed = GetSecs - startArmMov;
    showBall = false;
    if ~no_motion_flag
        drawInstructionCue(app, windowPtr, w1, ExpConfig.StageMotionDur_sec, ...
            false, speedToTrain, moveDir, startTrial, moveDir, showBall);
    end
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
            DrawFormattedText(windowPtr, '', 'center', 'center', [255 255 255]);
            Screen('Flip', windowPtr);
            break
            % if GetSecs >= stimEndTime
            %     break;
            % end
        end

        if GetSecs >= stimEndTime
            DrawFormattedText(windowPtr, '', 'center', 'center', [255 255 255]);
            Screen('Flip', windowPtr);
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

while GetSecs < stimEndTime % wait to show return cue if they have responded before stim end
    WaitSecs('YieldSecs', 0.001);
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

end
function printNoMotionCue (app,windowPtr,isActive)
    if isActive
       textString = 'Stay in the same position';
    else
        textString = 'Arm will stay in the same position';
    end
    DrawFormattedText(windowPtr, textString, 'center', 'center', [255 255 255]);
    Screen('Flip', windowPtr); 
end



function drawInstructionCue(app, windowPtr, speedStr, speedCmPerSec, moveDir, startCue, showBall)
moveDurSec = ExpConfig.StageMotionDur_sec;


viewDistCm = ExpConfig.viewDistCm;
screenWidthCm = ExpConfig.screenWidthCm;
ballDiamDeg = ExpConfig.ballDiamDeg;
padCm = ExpConfig.padCm;

elapsed = mod(GetSecs - startCue, moveDurSec);
if elapsed < 0
    elapsed = 0;
end

textString = sprintf('Move %s %s', moveDir, speedStr);


% Clear screen
Screen('FillRect', windowPtr, [0 0 0]);

% Window geometry
[screenX, screenY] = Screen('WindowSize', windowPtr);
centerX = screenX / 2;
centerY = screenY / 2;

% Text settings
Screen('TextFont', windowPtr, 'Arial');
Screen('TextSize', windowPtr, 28);
Screen('TextStyle', windowPtr, 0);

% Draw instruction text centered
DrawFormattedText(windowPtr, textString, 'center', 'center', [255 255 255]);

% Conversions
pixPerCm = screenX / screenWidthCm;

% Ball size: degrees -> cm -> pixels
ballDiamCm = 2 * viewDistCm * tand(ballDiamDeg / 2);
ballDiamPix = max(6, round(ballDiamCm * pixPerCm));
ballRadiusPix = ballDiamPix / 2;

% Motion distance
dxCm = speedCmPerSec * elapsed;
dxPix = dxCm * pixPerCm;

totalDxCm = speedCmPerSec * moveDurSec;
totalDxPix = totalDxCm * pixPerCm;

% Padding corridor
padPix = padCm * pixPerCm;
leftBound  = padPix + ballRadiusPix;
rightBound = screenX - padPix - ballRadiusPix;
usableWidth = rightBound - leftBound;

if totalDxPix > usableWidth
    error('Motion path too long for screen width and chosen padding.');
end

% Center the full path within the padded corridor
pathLeft  = leftBound  + (usableWidth - totalDxPix) / 2;
pathRight = rightBound - (usableWidth - totalDxPix) / 2;

if strcmpi(moveDir, 'right')
    ballX = pathLeft + dxPix;
elseif strcmpi(moveDir, 'left')
    ballX = pathRight - dxPix;
else
    error('moveDir must be ''left'' or ''right''.');
end

% Safety clamp
ballX = max(leftBound, min(rightBound, ballX));

% Ball below centered text
ballY = centerY + 80;

ballRect = [ballX - ballRadiusPix, ballY - ballRadiusPix, ...
    ballX + ballRadiusPix, ballY + ballRadiusPix];

% Draw ball if requested
if showBall
    Screen('FillOval', windowPtr, [255 0 0], ballRect);
end

Screen('Flip', windowPtr);
end

