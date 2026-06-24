function [trialRow] = runTrial(app, windowPtr, trialRow, flipSpeed, expTime_start) 
    isActive = trialRow.IsActive;
    speedCmSec = trialRow.Arm_Mov_Speed;
    speedArduino = trialRow.Arm_Mov_Speed_arduino;
    accArduino = trialRow.Arm_Mov_Acc_arduino;
    stepsArduino = trialRow.Arm_Mov_Steps_arduino;
    stimLagSec = ExpConfig.stimLag_sec;
    [moveDir, speedStr, no_motion_flag] = getTrialInfo(app,stepsArduino,speedArduino);
    threshold_cm = ExpConfig.encoderThreshold_cm;
    stimDurSec = trialRow.StimDuration_arduino / 1000;

    buttonPushed = [];
    respTime = [];
    encoderSamples = [];
    onsetSample =[];
    startStim = nan;
    stimEndTime = nan;
    startArmMov = NaN; 
    stimStarted = false;
    indentMovedDown = false;
    armMovStarted = false; 

    % ---------------------  TRIAL ONSET  ---------------------
    startTrial = GetSecs;
    trialRow.AbsExpStart = expTime_start;
    trialRow.AbsTrialStart = startTrial;
    trialRow.TrialStart_time = startTrial - expTime_start; %relative to the start of the experiment 
    %% Prints instructions with the ball moving until arm movement should start (1 se c or encoder senses motion)
    timeCueStart = startTrial;
    passiveCueDeadline = timeCueStart + 1.0; % runs for 1 sec 
    flushRotaryEncoderBuffer(app);
    writeline(app.rotaryEncoder, "ZERO");
    pause(0.05);

    if no_motion_flag %present no motion cue for 1 sec (same active and passive)
        printNoMotionCue(app, windowPtr,isActive);
        WaitSecs(1);
        startArmMov = GetSecs;
    else %present motion cue until motion sensed (active) or for 1 sec (passive) 
        motorCmdSent = false;
        while ~armMovStarted 
            showBall = true; 
            drawInstructionCue(app, windowPtr, isActive, speedCmSec, speedStr, moveDir, showBall, timeCueStart);
            if isActive
                newSamples = readAvailableEncoderSamples(app);
                if  ~isempty(newSamples) && isnan(startArmMov)
                    idx = find(abs(newSamples(:,3)) >= threshold_cm, 1, 'first');
                    if ~isempty(idx) %when a sample over the threshold was found 
                        encoderSamples = newSamples(idx:end,:);  
                        onsetSample = newSamples(idx,:);
                        startArmMov = GetSecs;
                        armMovStarted = true; 
                        break
                    end
          
                end
            else % Passive
                if ~motorCmdSent
                    writeline(app.LinearStage_motor, sprintf("S %d\n", speedArduino)); % if wrong speed - add pause between 
                    writeline(app.LinearStage_motor, sprintf("A %d\n", accArduino));
                    motorCmdSent = true;
                end
                if GetSecs >= passiveCueDeadline
                    startArmMov = GetSecs;
                    armMovStarted = true;
                end
            end 
            drawnow limitrate
            if app.stopGUI == 1
                app.stopGUI = 0;
                error('Experiment stopped');
            end
        
        end
    
    end 
    trialRow.Arm_Mov_Onset = startArmMov - expTime_start; %time relative to experiment start
    %% 

    if no_motion_flag % same active and passive,  no motion cue is still on until response or timeout 
        WaitSecs(stimLagSec); %0.25 sec to match motion trials 
        indentLoc = app.curIndent;
        write(app.indentationActuator, sprintf("%d %d\n", 1, indentLoc), "string");
        indentMovedDown = true;

        write(app.rotation_and_spin_motor, sprintf("%d %d %d\n", 3, ...
            flipSpeed * trialRow.StimSpeed_arduino, ...
            trialRow.StimDuration_arduino), "string");

        startStim = GetSecs;
        stimEndTime = startStim + stimDurSec;
        stimStarted = true;
        if stimStarted
            while true
                newSamples = readAvailableEncoderSamples(app);
                if ~isempty(newSamples)
                    encoderSamples = [encoderSamples; newSamples];
                end
                [~, ~, buttons] = GetMouse;
                if any(buttons)
                    buttonPushed = find(buttons ~= 0, 1);
                    respTime = GetSecs - startStim;
                    DrawFormattedText(windowPtr, '', 'center', 'center', [255 255 255]);
                    Screen('Flip', windowPtr);
                   % break
                end
                if GetSecs >= stimEndTime
                    DrawFormattedText(windowPtr, '', 'center', 'center', [255 255 255]);
                    Screen('Flip', windowPtr);
                    break
                end
                drawnow limitrate
                if app.stopGUI == 1
                    app.stopGUI = 0;
                    error('Experiment stopped');
                end
                
            end
        end
        if indentMovedDown %move stim up after rotation is done 
            indentLoc = app.indentZero;
            write(app.indentationActuator, sprintf("%d %d\n", 1, indentLoc), "string");
        end 

        if stimStarted && isempty(buttonPushed) % if did not respond before the end of stim rotation
            [buttonPushed, respTime] = waitForResponse(app, windowPtr, startStim);
        end 

    else
        showBall = false; 
        stopCollectingSamples = false;

        drawInstructionCue(app, windowPtr, isActive, speedCmSec, speedStr, moveDir, showBall, timeCueStart); % timeCueStart is irrelevant here since the ball is not drawn, this just updates the screen, no redrawing 
        if ~isActive 
            cmd = sprintf("M %d\n", stepsArduino);
            writeline(app.LinearStage_motor, cmd);
        end 

        while true
            if ~stopCollectingSamples
                newSamples = readAvailableEncoderSamples(app);
                if ~isempty(newSamples)
                    encoderSamples = [encoderSamples; newSamples];
                end
            end 

            if GetSecs >= (stimLagSec + startArmMov) && ~stimStarted
                indentLoc = app.curIndent;

                write(app.indentationActuator, sprintf("%d %d\n", 1, indentLoc), "string");
                indentMovedDown = true;
                write(app.rotation_and_spin_motor, sprintf("%d %d %d\n", 3, ...
                    flipSpeed * trialRow.StimSpeed_arduino, ...
                    trialRow.StimDuration_arduino), "string");
                startStim = GetSecs;
                stimEndTime = startStim + stimDurSec;
                stimStarted = true;
            end

            if stimStarted
                [~, ~, buttons] = GetMouse;
                if any(buttons)
                    buttonPushed = find(buttons ~= 0, 1);
                    respTime = GetSecs - startStim;
                    DrawFormattedText(windowPtr, '', 'center', 'center', [255 255 255]);
                    Screen('Flip', windowPtr);
                    stopCollectingSamples = true; 
                end
                if GetSecs >= stimEndTime
                    DrawFormattedText(windowPtr, '', 'center', 'center', [255 255 255]);
                    Screen('Flip', windowPtr);
                    break
                end
            end 
            drawnow limitrate
            if app.stopGUI == 1
                app.stopGUI = 0;
                error('Experiment stopped');
            end
        end 

        if indentMovedDown %move stim up after rotation is done 
            indentLoc = app.indentZero;
            write(app.indentationActuator, sprintf("%d %d\n", 1, indentLoc), "string");
        end 

        if stimStarted && isempty(buttonPushed) % if did not respond before the end of stim rotation
            [buttonPushed, respTime] = waitForResponse(app, windowPtr, startStim);
        end 



    end
    if ~stimStarted
        trialRow.StimOnset = nan;
    else
        trialRow.StimOnset = startStim - expTime_start;
    end
        
    avgVelocity = computeAverageEncoderVelocity(app, encoderSamples);
    trialRow.MeasuredSpeed_cm_s = avgVelocity;
    trialRow.EncoderSamples = {encoderSamples};
    trialRow.Response = buttonPushed;
    trialRow.ReactionTime = respTime;
    trialRow.OnsetSample = {onsetSample};
    updateCurrentSpeedDisplay(app, avgVelocity);
end

function  printNoMotionCue(app, windowPtr,isActive)
    if isActive
        textString = 'Stay in the same position';
    else
        textString = 'Arm will not be moved';
    end
    DrawFormattedText(windowPtr, textString, 'center', 'center', [255 255 255]);
    Screen('Flip', windowPtr);
end 


function drawInstructionCue(app, windowPtr, isActive, speedCmSec, speedStr, moveDir, showBall, timeCueStart)
    screenWidthCm = ExpConfig.screenWidthCm;
    ballDiamDeg = ExpConfig.ballDiamDeg;
    viewDistCm = ExpConfig.viewDistCm;
    padCm = ExpConfig.padCm; 
    moveDurSec = ExpConfig.StageMotionDur_sec;

    elapsed = mod(GetSecs - timeCueStart, moveDurSec); % this leads to update of the ball position every call 
    if elapsed < 0
        elapsed = 0;
    end
    if isActive
        textString = sprintf('Move %s %s', moveDir, speedStr);
    else 
        textString = sprintf('Arm will move %s %s', moveDir, speedStr);
    end
    % Clear screen
    Screen('FillRect', windowPtr, [0 0 0]);
    % Window geometry
    [screenX, screenY] = Screen('WindowSize', windowPtr);
    centerX = screenX / 2;
    centerY = screenY / 2;
    % Draw instruction text centered
    DrawFormattedText(windowPtr, textString, 'center', 'center', [255 255 255]);
    % Conversions
    pixPerCm = screenX / screenWidthCm;
    % Ball size: degrees -> cm -> pixels
    ballDiamCm = 2 * viewDistCm * tand(ballDiamDeg / 2);
    ballDiamPix = max(6, round(ballDiamCm * pixPerCm));
    ballRadiusPix = ballDiamPix / 2;
    % Motion distance
    dxCm = speedCmSec * elapsed;
    dxPix = dxCm * pixPerCm;
    totalDxCm = speedCmSec * moveDurSec;
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


    