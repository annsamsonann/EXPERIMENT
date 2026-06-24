function [trialRow] = runTrial(app, windowPtr, trialRow, flipSpeed, expTime_start) 
    speedCmSec = trialRow.Arm_Mov_Speed;
    speedArduino = trialRow.Arm_Mov_Speed_arduino;
    accArduino = trialRow.Arm_Mov_Acc_arduino;
    stepsArduino = trialRow.Arm_Mov_Steps_arduino;
    [moveDir, speedStr, no_motion_flag] = getTrialInfo(app,stepsArduino,speedArduino);
    threshold_cm = ExpConfig.encoderThreshold_cm;

    buttonPushed = [];
    respTime = [];
    encoderSamples = [];
    startStim = nan;
    stimEndTime = nan;
    startArmMov = NaN; 
    stimStarted = false;
    indentMovedDown = false;
    responded = false ; 

    % ---------------------  TRIAL ONSET  ---------------------
    startTrial = GetSecs;
    trialRow.AbsExpStart = expTime_start;
    trialRow.AbsTrialStart = startTrial;
    trialRow.TrialStart_time = startTrial - expTime_start; %relative to the start of the experiment 

    if no_motion_flag
        printNoMotionCue(app, windowPtr,isActive) % same for active and passive 
        WaitSecs(1);
    else
        while true 
        end
    
    end 
        
        
        
        
    startArmMov = GetSecs;





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


function drawInstructionCue(app, windowPtr, isActive, speedCmSec, speedStr, moveDir, showBall, startCue)
    screenWidthCm = ExpConfig.screenWidthCm;
    ballDiamDeg = ExpConfig.ballDiamDeg;
    viewDistCm = ExpConfig.viewDistCm;
    padCm = ExpConfig.padCm; 
    moveDurSec = ExpConfig.StageMotionDur_sec;

    elapsed = mod(GetSecs - startCue, moveDurSec); % this leads to update of the ball position every call 
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


    function printActiveMotionCue(app, windowPtr, w, w1, no_motion_flag)
    if ~no_motion_flag
        textString = sprintf('Move %s with %s speed', w, w1);
    else
        textString = 'Stay in the same position';
    end
    DrawFormattedText(windowPtr, textString, 'center', 'center', [255 255 255]);
    Screen('Flip', windowPtr);
end