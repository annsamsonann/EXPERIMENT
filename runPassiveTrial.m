 function [trialRow, myTrialHistory] = runPassiveTrial(app, windowPtr, trialRow, n, expTime_start, myTrialHistory,speedStage,accStage,stepsStage)
    % ---------------------  PREPARE  ---------------------
            try
        
                buttonPushed = [];
                respTime = [];
                encoderSamples = [];
                startStim = nan;
                stimEndTime = nan;

                stimStarted = false;
                %stim ident (?) 
        
                % ---------------------  TRIAL ONSET  ---------------------
                startTrial = GetSecs;
                trialRow.TrialStart_time = startTrial - expTime_start;
        
 
        
                % SET the speed for the linear stage
                cmd = sprintf("S %d\n", speedStage);
                writeline(app.LinearStage_motor, cmd);
        
                curClock = GetSecs;
                while (GetSecs - curClock) < 0.5
                    drawnow limitrate
                    if app.stopGUI == 1
                        app.stopGUI = 0;
                        error('Experiment stopped');
                    end
                end
        
                % SET the acceleration for the linear stage
                cmd = sprintf("A %d\n", accStage);
                writeline(app.LinearStage_motor, cmd);
        
                curClock = GetSecs;
                while (GetSecs - curClock) < 0.25
                    drawnow limitrate
                    if app.stopGUI == 1
                        app.stopGUI = 0;
                        error('Experiment stopped');
                    end
                end
        
                % ---------------------  PASSIVE MOTION CUE ---------------------
                printPassiveMotionCue(app, windowPtr, w, w1, no_motion_flag);
        
                curClock = GetSecs;
                while (GetSecs - curClock) < 0.25
                    drawnow limitrate
                    if app.stopGUI == 1
                        app.stopGUI = 0;
                        error('Experiment stopped');
                    end
                end
        
                % ---------------------  MOTOR / STIM PREP ---------------------
                write(app.rotation_and_spin_motor, sprintf("%d %d %d\n", 3, ...
                    flipSpeed * trialRow.StimSpeed_arduino, ...
                    trialRow.StimDuration_arduino), "string");
        
                curClock = GetSecs;
                while (GetSecs - curClock) < 0.5
                    drawnow limitrate
                    if app.stopGUI == 1
                        app.stopGUI = 0;
                        error('Experiment stopped');
                    end
                end
        
                % ---------------------  PASSIVE ARM MOVEMENT ---------------------
                startArmMov = GetSecs;
                trialRow.Arm_Mov_Onset = startArmMov - expTime_start;
        
                flushRotaryEncoderBuffer(app);
                zeroRotaryEncoder(app);
                pause(0.05);
        
                cmd = sprintf("M %d\n", stepsStage);
                writeline(app.LinearStage_motor, cmd);
        
                stimDurSec = trialRow.StimDuration_arduino / 1000;
                app.stimLagSec = 0.25;
        
                while true
                    elapsed = GetSecs - startArmMov;
        
                    if ~stimStarted && elapsed >= app.stimLagSec
                        startStim = GetSecs;
                        trialRow.StimOnset = startStim - expTime_start;
                        stimEndTime = startStim + stimDurSec;
                        stimStarted = true;
        
                        printResponsePrompt(app, windowPtr);
        
                        indentLoc = app.curIndent;
                        write(app.indentationActuator, sprintf("%d %d\n", 1, indentLoc), "string");
                    end
        
                    % collect encoder from passive arm movement onset onward
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
        
                    drawnow limitrate
                    if app.stopGUI == 1
                        app.stopGUI = 0;
                        error('Experiment stopped');
                    end
                end
        
                % MOVE the wheel up
                indentLoc = app.indentZero;
                write(app.indentationActuator, sprintf("%d %d\n", 1, indentLoc), "string");
        
                % ---------------------  STIMULUS DONE ---------------------
                trialRow.EncoderSamples = {encoderSamples};
                trialRow.MeasuredSpeed_cm_s = computeAverageEncoderVelocity(app, encoderSamples);
                
                if stimStarted && isempty(buttonPushed)
                    [buttonPushed, respTime] = waitForResponse(app, windowPtr, startStim);
                elseif ~stimStarted
                    trialRow.StimOnset = nan;
                end
        
                trialRow.Response = buttonPushed;
                trialRow.ReactionTime = respTime;
                myTrialHistory = printResponseInfo(app, myTrialHistory, buttonPushed);
        
                curClock = GetSecs;
                while (GetSecs - curClock) < 0.5
                    drawnow limitrate
                    if app.stopGUI == 1
                        app.stopGUI = 0;
                        error('Experiment stopped');
                    end
                end
        
            catch ME
               rethrow(ME);
            end
        end

    function printResponsePrompt(app, windowPtr)
            textString = 'Left or Right Response';
            DrawFormattedText(windowPtr, textString, 'center', 'center', [255 255 255]);
            Screen('Flip', windowPtr);
    end

        function printPassiveMotionCue(app, windowPtr, w, w1, no_motion_flag)
    % DISPLAY Motion Direction cue to subject
    % Passive trial, motor on (arm moved by motor)

        if ~no_motion_flag
            textString = sprintf('Arm will be moved %s with %s speed', w, w1);
        else
            textString = 'Arm will not be moved';
        end
    
        DrawFormattedText(windowPtr, textString, 'center', 'center', [255 255 255]);
        Screen('Flip', windowPtr);
        WaitSecs(1);
    end

   