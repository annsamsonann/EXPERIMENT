 function [trialRow, myTrialHistory] = runActiveTrial(app, windowPtr, trialRow, n, expTime_start, myTrialHistory,speedStage,accStage,stepsStage)
    
        buttonPushed = [];
        respTime = [];
        encoderSamples = [];
        startStim = nan;
        stimEndTime = nan;
    
        stimStarted = false;
        indentMovedDown = false;
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
            drawActiveMovementCountdown(app, windowPtr, w, app.moveDurSec, startArmMov, false);
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
                drawActiveMovementCountdown(app, windowPtr, w, app.moveDurSec, startArmMov, stimStarted);
            end

            % collect encoder from arm movement onset onward
            newSamples = readAvailableEncoderSamples(app);
            if ~isempty(newSamples)
                encoderSamples = [encoderSamples; newSamples]; 
                updateCurrentSpeedDisplay(app, encoderSamples);
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
    
        trialRow.MeasuredSpeed_cm_s = computeAverageEncoderVelocity(app, encoderSamples);
        trialRow.EncoderSamples = {encoderSamples};
  
    
        if stimStarted && isempty(buttonPushed)
            [buttonPushed, respTime] = waitForResponse(app, windowPtr, startStim);
        elseif ~stimStarted
            trialRow.StimOnset = nan;
        end
    
        trialRow.Response = buttonPushed;
        trialRow.ReactionTime = respTime;
        myTrialHistory = printResponseInfo(app, myTrialHistory, buttonPushed);
    end

    function drawActiveMovementCountdown(app, windowPtr, w, moveDurSec, startArmMov, showResponsePrompt)
        elapsed = GetSecs - startArmMov;
        if elapsed > moveDurSec
            elapsed = moveDurSec;
        elseif elapsed < 0
            elapsed = 0;
        end
    
        remaining = max(0, moveDurSec - elapsed);
        frac = min(1, elapsed / moveDurSec);
    
        Screen('FillRect', windowPtr, [0 0 0]);
    
        [screenX, screenY] = Screen('WindowSize', windowPtr);
    
        Screen('TextFont', windowPtr, 'Arial');
        Screen('TextSize', windowPtr, 28);
        Screen('TextStyle', windowPtr, 0);
    
        centerY = screenY / 2;
    
        instrY = round(centerY - 140);
        respY  = round(centerY - 60);
        timerY = round(centerY + 20);
        barY   = round(centerY + 120);
    
        DrawFormattedText(windowPtr, sprintf('Keep moving your arm %s', w), ...
            'center', instrY, [255 255 255]);
    
        if showResponsePrompt
            DrawFormattedText(windowPtr, 'Left or Right Response', ...
                'center', respY, [255 255 255]);
        end
    
        DrawFormattedText(windowPtr, sprintf('Time left: %.1f s', remaining), ...
            'center', timerY, [255 255 255]);
    
        barW = 500;
        barH = 24;
        barX = round((screenX - barW) / 2);
    
        Screen('FrameRect', windowPtr, [255 255 255], ...
            [barX, barY, barX + barW, barY + barH], 2);
    
        Screen('FillRect', windowPtr, [255 255 255], ...
            [barX, barY, barX + round(barW * frac), barY + barH]);
    
        Screen('Flip', windowPtr);
    end

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
    
   
    
   
        function [startArmMov, onsetSample] = waitForEncoderMotion(app, threshold_cm)
            startArmMov = NaN;
            onsetSample = [];
        
            flushRotaryEncoderBuffer(app);
            zeroRotaryEncoder(app);
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
    