function [trialRow, no_motion_flag, moveDir] = runTrial(app, windowPtr, trialRow, flipSpeed, expTime_start) 
    isActive = trialRow.IsActive;
    speedCmSec = trialRow.Arm_Mov_Speed;
    speedArduino = trialRow.Arm_Mov_Speed_arduino;
    accArduino = trialRow.Arm_Mov_Acc_arduino;
    stepsArduino = trialRow.Arm_Mov_Steps_arduino;
    stimLagSec = ExpConfig.stimLag_sec;
    no_motion_flag = false;
    if strcmpi(trialRow.ArmDirection, "Right to left")
        moveDir = "left";
    elseif strcmpi(trialRow.ArmDirection, "Left to right")
        moveDir = "right";
    elseif strcmpi(trialRow.ArmDirection, "no movement")
        moveDir = "None";
        no_motion_flag = true;
    else
    end
    cuedSpeed = trialRow.Cued_Speed;
    if cuedSpeed == 0
        speedStr = 'no';
        no_motion_flag = true;
    elseif cuedSpeed == 1
        speedStr = 'slow';
    elseif cuedSpeed == 2
        speedStr = 'fast';
    else
        speedStr = 'NA';
    end



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
    flushRotaryEncoderBuffer(app); 


    if no_motion_flag %present no motion cue for 1 sec (same active and passive)
        printNoMotionCue(app, windowPtr,isActive);
        WaitSecs(1);
        startArmMov = GetSecs;
    else %present motion cue until motion sensed (active) or for 1 sec (passive) 
        motorCmdSent = false;
        seenZeroAfterReset = false;
        zeroTol = 0.5;   % cm, adjust
        cleanSamples = [];

        while ~armMovStarted
            showBall = true;

            drawInstructionCue(app, windowPtr, isActive, speedStr, moveDir, showBall, timeCueStart, cuedSpeed);

            if isActive
                newSamples = readAvailableEncoderSamples(app);
                if ~isempty(newSamples)
                    if ~seenZeroAfterReset
                        zidx = find(abs(newSamples(:,3)) <= zeroTol, 1, 'first');
                        if ~isempty(zidx)
                            seenZeroAfterReset = true;
                            newSamples = newSamples(zidx:end,:);
                        else
                            newSamples = [];
                        end
                    end

                    if ~isempty(newSamples)
                        cleanSamples = [cleanSamples; newSamples];
                        idx = find(abs(cleanSamples(:,3)) >= threshold_cm, 1, 'first');
                        if ~isempty(idx)
                            onsetSample = cleanSamples(1:idx,:);
                            encoderSamples = cleanSamples(idx:end,:);
                            startArmMov = GetSecs;
                            armMovStarted = true;
                            break
                        end
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
    trialRow.Arm_Mov_Onset_Trial = startArmMov- startTrial; % time relative to the start of trial 
    %% 

    if no_motion_flag % same for active and passive,  no motion cue is still on until response or timeout 
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
            moveUpTime = GetSecs - startStim;
            indentLoc = app.indentZero;
            write(app.indentationActuator, sprintf("%d %d\n", 1, indentLoc), "string");
        end 

        if stimStarted && isempty(buttonPushed) % if did not respond before the end of stim rotation
            [buttonPushed, respTime] = waitForResponse(app, windowPtr, startStim);
        end 

    else
        showBall = false; 
        stopCollectingSamples = false;

        drawInstructionCue(app, windowPtr, isActive, speedStr, moveDir, showBall, timeCueStart,cuedSpeed); % timeCueStart is irrelevant here since the ball is not drawn, this just updates the screen, no redrawing 
        if ~isActive 
            cmd = sprintf("M %d\n", stepsArduino);
            writeline(app.LinearStage_motor, cmd);
           
            armMoveDurSec = trialRow.Measured_Arm_Mov_Duration_s; %For JH  abs(stepsArduino / speedArduino); % not correct computation 
            armMovStopTime = startArmMov + armMoveDurSec;
                
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
                if isActive
                    endTime = stimEndTime;
                elseif ~isActive
                    endTime = armMovStopTime;
                end
                   
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
                if  GetSecs >= stimEndTime || GetSecs >= endTime % break and move up if time is more than 1.5 sec from stim start, or time is more than motion duration (for cases when motion duration is < 1.75 sec) 
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
            moveUpTime = GetSecs - startStim;
           
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
    [avgVelocity,elapsedTime_s,totalDist_cm] = computeAverageEncoderVelocity(app, encoderSamples, onsetSample);
    trialRow.MeasuredSpeed_cm_s = avgVelocity;
    trialRow.Measured_Arm_Mov_Duration_s  = elapsedTime_s;
    trialRow.Measured_Arm_Mov_Dist_cm = totalDist_cm; 
    trialRow.EncoderSamples = {encoderSamples};
    trialRow.Response = buttonPushed;
    trialRow.ReactionTime = respTime;
    trialRow.OnsetSample = {onsetSample};
    trialRow.StimMoveUp = moveUpTime; %Remove for AC and JH 
    updateCurrentSpeedDisplay(app, avgVelocity);
    if ~isActive && ~no_motion_flag %Makes sure that the next motor command is sent only after this one is finished, otherwise the stage would not travvel the whole dista
        secLeftToMove = armMovStopTime - GetSecs; 
        if secLeftToMove > 0
            pause(secLeftToMove);
        end
    end
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

function drawInstructionCue(app, windowPtr, isActive, speedStr, moveDir, showBall, timeCueStart, cuedSpeed)

    % Access config
 
    % Resolve speed from cue code
    if cuedSpeed == 1
        speedCmSec = ExpConfig.slow_target;
    elseif cuedSpeed == 2
        speedCmSec = ExpConfig.fast_target;
    else
        error('cuedSpeed must be 1 (slow) or 2 (fast).');
    end

    % Config values
    screenWidthCm = ExpConfig.screenWidthCm;
    ballDiamDeg   = ExpConfig.ballDiamDeg;
    viewDistCm    = ExpConfig.viewDistCm;
    padCm         = ExpConfig.padCm;
    moveDurSec    = ExpConfig.StageMotionDur_sec;

    % Time elapsed within one motion cycle
    elapsed = mod(GetSecs - timeCueStart, moveDurSec);
    if elapsed < 0
        elapsed = 0;
    end

    % Instruction text
    dirStr = lower(strtrim(string(moveDir)));
    if isActive
        textString = sprintf('Move %s %s', char(dirStr), speedStr);
    else
        textString = sprintf('Arm will move %s %s', char(dirStr), speedStr);
    end

    % Clear screen
    Screen('FillRect', windowPtr, [0 0 0]);

    % Window geometry
    [screenX, screenY] = Screen('WindowSize', windowPtr);
    centerX = screenX / 2;
    centerY = screenY / 2;

    % Draw centered instruction text
    DrawFormattedText(windowPtr, textString, 'center', 'center', [255 255 255]);

    % Pixels per cm
    pixPerCm = screenX / screenWidthCm;

    % Ball size: visual angle -> cm -> pixels
    ballDiamCm    = 2 * viewDistCm * tand(ballDiamDeg / 2);
    ballDiamPix   = max(6, round(ballDiamCm * pixPerCm));
    ballRadiusPix = ballDiamPix / 2;

    % Motion distance covered so far
    dxCm  = speedCmSec * elapsed;
    dxPix = dxCm * pixPerCm;

    % Total motion distance over full cue duration
    totalDxCm  = speedCmSec * moveDurSec;
    totalDxPix = totalDxCm * pixPerCm;

    % Padded motion corridor
    padPix     = padCm * pixPerCm;
    leftBound  = padPix + ballRadiusPix;
    rightBound = screenX - padPix - ballRadiusPix;
    usableWidth = rightBound - leftBound;

    if totalDxPix > usableWidth
        error('Motion path too long for screen width and chosen padding.');
    end

    % Center the path inside the padded corridor
    extraSpace = usableWidth - totalDxPix;
    pathLeft   = leftBound  + extraSpace / 2;
    pathRight  = rightBound - extraSpace / 2;

    % Ball position: RIGHT means left->right, LEFT means right->left
    if dirStr == "right"
        ballX = pathLeft + dxPix;
    elseif dirStr == "left"
        ballX = pathRight - dxPix;
    else
        error('moveDir must be ''left'' or ''right''. Got: %s', char(dirStr));
    end

    % Clamp for safety
    ballX = max(leftBound, min(rightBound, ballX));

    % Ball vertical position below text
    ballY = centerY + 80;

    % Build rect centered on (ballX, ballY)
    baseRect = [0 0 ballDiamPix ballDiamPix];
    ballRect = CenterRectOnPointd(baseRect, ballX, ballY);
    % 
    % % Optional debug print to MATLAB command window
    % fprintf('dir=%s | elapsed=%.3f | dxPix=%.2f | pathLeft=%.2f | pathRight=%.2f | ballX=%.2f\n', ...
    %     char(dirStr), elapsed, dxPix, pathLeft, pathRight, ballX);

    % Draw ball
    if showBall
        Screen('FillOval', windowPtr, [255 0 0], ballRect);
    end

    % Flip to screen
    Screen('Flip', windowPtr);

end

