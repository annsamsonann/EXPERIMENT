function generate_debugTrials(parDir, subjID, taskType)
% DEBUG VERSION: Generates 4 blocks of 10 trials each with controlled initial conditions.

fast_speed = ExpConfig.fast_target;
slow_speed = ExpConfig.slow_target;
pickArmMovSpeed = [0 slow_speed fast_speed]; 
pickStimDirection_trial = [0 45 75 85 90 95 105 135 180 225 255 265 270 275 285 315];
armPosture = [90, 53, 15]; % Will pick the first posture for debug tracking consistency
isActiveLevels = [1];
pickArmMovSpeed_arduino = [0 ExpConfig.slow_target_speed_steps ExpConfig.fast_target_speed_steps];
pickArmMovAcc_arduino = pickArmMovSpeed .* ExpConfig.acc_constant;
pickArmMovSteps_arduino = round(pickArmMovSpeed_arduino .* ExpConfig.StageMotionDur_sec);
durationArm_mov = ExpConfig.StageMotionDur_sec;

tactileMotion_speed = 30; 
tactileMotion_stimIndent = 1; 
tactileMotion_duration = 1.5; 
tactileMotion_speed_arduino = 600;
tactileMotion_indent_arduino = 1200;
tactileMotion_duration_arduino = tactileMotion_duration * 1000;

outDir = fullfile(parDir, subjID);
if ~isfolder(outDir)
    mkdir(outDir);
end

VarNames = { ...
    'Trial_num', 'PairID', 'ArmDirection', 'Arm_Mov_Speed', 'HandPosture', ...
    'StimDirection', 'Stim_Speed', 'StimDuration', 'StimIndentation', 'Arm_mov_StartPosition', ...
    'Arm_mov_StartPosition_arduino', 'Arm_Mov_Speed_arduino', 'Arm_Mov_Acc_arduino', 'Arm_Mov_Steps_arduino', 'Arm_Mov_StepsAbs_arduino', ...
    'StimDirection_arduino', 'StimSpeed_arduino', 'StimDuration_arduino', 'StimIndentation_arduino', 'IsActive', ...
    'Arm_Mov_Onset', 'StimOnset', 'Arm_Mov_Onset_Trial', 'InterTrialInterval', 'Response', ...
    'ReactionTime', 'TrialStart_time', 'MeasuredSpeed_cm_s', 'Measured_Arm_Mov_Duration_s', 'Measured_Arm_Mov_Dist_cm', ...
    'EncoderSamples', 'OnsetSample', 'AbsExpStart', 'AbsTrialStart', 'isRep' ...
};
VarType = { ...
    'double', 'double', 'string', 'double', 'double', ...
    'double', 'double', 'double', 'double', 'double', ...
    'double', 'double', 'double', 'double', 'double', ...
    'double', 'double', 'double', 'double', 'double', ...
    'double', 'double', 'double', 'double', 'double', ...
    'double', 'double', 'double', 'double', 'double', ...
    'cell',   'cell',   'double', 'double', 'double' ...
};

% =========================================================================
% 1) Build pools of trials based on original distributions
% =========================================================================
% We'll create specialized pools to easily satisfy the block rules.
noMovePoolRight = []; % ArmSpeedAbs = 0, StartPosition = 1 (Right to Left Setup)
noMovePoolLeft  = []; % ArmSpeedAbs = 0, StartPosition = 0 (Left to Right Setup)
movingPool      = []; % ArmSpeedAbs > 0

% Balanced assignment generation template
for ip = 1:length(armPosture)
    for is = 1:length(pickArmMovSpeed)
        for id = 1:length(pickStimDirection_trial)
            speed = pickArmMovSpeed(is);
            stimDir = pickStimDirection_trial(id);
            posture = armPosture(ip);
            
            if speed == 0
                % "No movement" distributions
                noMovePoolRight = [noMovePoolRight; posture, 0, stimDir, 0, 1]; % format: [posture, speed, stimDir, sign, startPos]
                noMovePoolLeft  = [noMovePoolLeft;  posture, 0, stimDir, 0, 0];
            else
                % Half left-to-right (-1), half right-to-left (1)
                movingPool = [movingPool; posture, speed, stimDir, -1, 0];
                movingPool = [movingPool; posture, speed, stimDir,  1, 1];
            end
        end
    end
end

% Shuffle pools cleanly
noMovePoolRight = noMovePoolRight(randperm(size(noMovePoolRight, 1)), :);
noMovePoolLeft  = noMovePoolLeft(randperm(size(noMovePoolLeft, 1)), :);
movingPool      = movingPool(randperm(size(movingPool, 1)), :);

% Track read pointers across pools
idxNoMoveRight = 1; 
idxNoMoveLeft  = 1; 
idxMoving      = 1;

% =========================================================================
% 2) Generate 4 Targeted Blocks (10 Trials Each)
% =========================================================================
for b = 1:4
    blockRows = zeros(10, 5); % structure: [posture, speed, stimDir, sign, startPos]
    
    for t = 1:10
        if b == 1 && t == 1
            % Block 1 begins with a no motion trial on the right (startPos = 1)
            blockRows(t, :) = noMovePoolRight(idxNoMoveRight, :);
            idxNoMoveRight = idxNoMoveRight + 1;
            
        elseif b == 2 && t == 1
            % Block 2 begins with a no motion trial on the left (startPos = 0)
            blockRows(t, :) = noMovePoolLeft(idxNoMoveLeft, :);
            idxNoMoveLeft = idxNoMoveLeft + 1;
            
        elseif b == 2 && t == 2
            % Block 2 second trial is a no motion trial on the right (startPos = 1)
            blockRows(t, :) = noMovePoolRight(idxNoMoveRight, :);
            idxNoMoveRight = idxNoMoveRight + 1;
            
        else
            % All other trials in all blocks must be moving trials
            blockRows(t, :) = movingPool(idxMoving, :);
            idxMoving = idxMoving + 1;
        end
    end
    
    % =========================================================================
    % 3) Construct MATLAB Table
    % =========================================================================
    TrialStim_param = table('Size', [10 length(VarNames)], ...
        'VariableNames', VarNames, 'VariableTypes', VarType);
    
    for n = 1:10
        currentPosture = blockRows(n, 1);
        armSpeedAbs    = blockRows(n, 2);
        stimDir        = blockRows(n, 3);
        armSign        = blockRows(n, 4);
        startPosConfig = blockRows(n, 5);
        
        TrialStim_param.Trial_num(n) = n;
        TrialStim_param.PairID(n) = b;
        TrialStim_param.StimDirection(n) = stimDir;
        TrialStim_param.Stim_Speed(n) = tactileMotion_speed;
        TrialStim_param.StimDuration(n) = tactileMotion_duration;
        TrialStim_param.StimIndentation(n) = tactileMotion_stimIndent;
        TrialStim_param.StimDirection_arduino(n) = stimDir;
        TrialStim_param.StimSpeed_arduino(n) = tactileMotion_speed_arduino;
        TrialStim_param.StimDuration_arduino(n) = tactileMotion_duration_arduino;
        TrialStim_param.StimIndentation_arduino(n) = tactileMotion_indent_arduino;
        TrialStim_param.HandPosture(n) = currentPosture;
        TrialStim_param.Measured_Arm_Mov_Duration_s(n) = durationArm_mov; % corrected from old field
       
        ardIdx = find(armSpeedAbs == pickArmMovSpeed, 1);
        
        if armSign == 0
            % Handled No Movement states cleanly
            TrialStim_param.ArmDirection(n) = "No movement";
            TrialStim_param.Arm_Mov_Speed(n) = 0;
            TrialStim_param.Arm_mov_StartPosition(n) = startPosConfig;
            if startPosConfig == 0
                TrialStim_param.Arm_mov_StartPosition_arduino(n) = 0;
            else
                TrialStim_param.Arm_mov_StartPosition_arduino(n) = -1 * ExpConfig.LinStage_range_steps;
            end
            TrialStim_param.Arm_Mov_Steps_arduino(n) = 0;
        elseif armSign < 0
            TrialStim_param.Arm_Mov_Speed(n) = -abs(armSpeedAbs);
            TrialStim_param.Arm_mov_StartPosition(n) = 0;
            TrialStim_param.Arm_mov_StartPosition_arduino(n) = 0;
            TrialStim_param.Arm_Mov_Steps_arduino(n) = -1 * pickArmMovSteps_arduino(ardIdx);
            TrialStim_param.ArmDirection(n) = "Left to Right";
        else
            TrialStim_param.Arm_Mov_Speed(n) = abs(armSpeedAbs);
            TrialStim_param.Arm_mov_StartPosition(n) = 1;
            TrialStim_param.Arm_mov_StartPosition_arduino(n) = -1 * ExpConfig.LinStage_range_steps;
            TrialStim_param.Arm_Mov_Steps_arduino(n) = pickArmMovSteps_arduino(ardIdx);
            TrialStim_param.ArmDirection(n) = "Right to Left";
        end
        
        % Populate boilerplate Nans and cells
        TrialStim_param.Arm_Mov_StepsAbs_arduino(n) = abs(TrialStim_param.Arm_Mov_Steps_arduino(n));
        TrialStim_param.Arm_Mov_Speed_arduino(n) = pickArmMovSpeed_arduino(ardIdx);
        TrialStim_param.Arm_Mov_Acc_arduino(n) = pickArmMovAcc_arduino(ardIdx);
        TrialStim_param.IsActive(n) = 1;
        TrialStim_param.isRep(n) = 0;
        [TrialStim_param.Arm_Mov_Onset(n), TrialStim_param.Arm_Mov_Onset_Trial(n), ...
         TrialStim_param.StimOnset(n), TrialStim_param.InterTrialInterval(n), ...
         TrialStim_param.Response(n), TrialStim_param.ReactionTime(n), ...
         TrialStim_param.TrialStart_time(n), TrialStim_param.AbsExpStart(n), ...
         TrialStim_param.AbsTrialStart(n), TrialStim_param.MeasuredSpeed_cm_s(n), ...
         TrialStim_param.Measured_Arm_Mov_Dist_cm(n)] = deal(nan);
        TrialStim_param.EncoderSamples(n) = {[]};
        TrialStim_param.OnsetSample(n) = {[]};
    end
    
    % Save out each debug block configuration
    fileName = fullfile(outDir, ...
        [subjID '_' taskType ...
        '_DEBUG_block_' sprintf('%02d', b) '_ACTIVE.mat']);
    save(fileName, 'TrialStim_param');
    disp(['DEBUG Block #' num2str(b) ' generated and saved successfully.']);
end
end