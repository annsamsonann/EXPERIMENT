

function generate_trials_MotionDirection(parDir, subjID, taskType)

pickMov_trial = 2; % 2 values = no-mov and mov
pickArmMovSpeed = [0 ExpConfig.slow_target ExpConfig.fast_target]; % 3 values = no (0 cm/s), slow (1.36 cm/s), fast (7.56 cm/s)
pickArmMovSpeed_arduino = [0 ExpConfig.slow_target_speed_steps ExpConfig.fast_target_speed_steps]; % values that will displace the stage with the speed indicated above !!!!!
pickArmMovAcc_arduino =  pickArmMovSpeed * ExpConfig.acc_constant; % values that will displace the stage with the acceleration
pickArmMovSteps_arduino = pickArmMovSpeed_arduino  * ExpConfig.StageMotionDur_sec ; % values that will displace the stage with the desired distance
durationArm_mov = ExpConfig.StageMotionDur_sec; % in seconds, motion of the arm

pickStimDirection_trial = [0 45 75 85 90 95 105 135 180 225 255 265 270 275 285 315];
tactileMotion_speed = 30; % in cm/s
tactileMotion_stimIndent = 1; % in mm
tactileMotion_duration = 1.5; % in seconds, motion of the tactile stimulus
tactileMotion_speed_arduino = 600;
tactileMotion_indent_arduino = 1200;
tactileMotion_duration_arduino = tactileMotion_duration * 1000;

armPosture = [90 53 15];

ISI = nan; %#ok<NASGU>
ITI = ExpConfig.ITI; 

%-------------------------------------
nTrials_condition_posture1 = zeros(1, length(pickStimDirection_trial)) + 10;
nTrials_condition_posture2 = nTrials_condition_posture1;

curMov = randi([0 1], 1, 1); %#ok<NASGU>


blocks_per_posture = 16; % total blocks per posture 
total_blocks = blocks_per_posture * length(armPosture); % n blocks for the subject 

n_active_blocks = blocks_per_posture / 2;
n_passive_blocks = blocks_per_posture / 2;


outDir = fullfile(parDir, subjID);
if ~isfolder(outDir)
    mkdir(outDir);
end

if mod(blocks_per_posture, 2) ~= 0
    error('blocks_per_posture must be even so active/passive pairs can be formed.');
end

globalPairID = 0;

for post = 1:length(armPosture)

    tacDirectionTrials = [];
    trialDist = [];

    if post == 1
        trialDist = nTrials_condition_posture1;
    else
        trialDist = nTrials_condition_posture2;
    end

    for ss = 1:length(pickArmMovSpeed)
        for nn = 1:length(trialDist)
            tmp = [ ...
                zeros(trialDist(nn),1) + pickStimDirection_trial(nn), ...
                zeros(trialDist(nn),1) + pickArmMovSpeed(ss), ...
                zeros(trialDist(nn),1) + armPosture(post)];
            tacDirectionTrials = cat(1, tacDirectionTrials, tmp);
        end
    end

    % permuting the order of trials
    c = randperm(size(tacDirectionTrials,1))';
    tacDirectionTrials = tacDirectionTrials(c,:);

    % assigning speed direction
    speedDir = find(tacDirectionTrials(:,2) ~= 0);
    tmp = randperm(length(speedDir));
    speedDir = speedDir(tmp(1:round(length(speedDir)/2)));
    tacDirectionTrials(speedDir,2) = -1 * tacDirectionTrials(speedDir,2);

    % assigning starting hand position
    w = find(tacDirectionTrials(:,2) == 0);
    tacDirectionTrials(w,4) = randi([0 1], length(w), 1);

    w = find(tacDirectionTrials(:,2) < 0);
    tacDirectionTrials(w,4) = 0;

    w = find(tacDirectionTrials(:,2) > 0);
    tacDirectionTrials(w,4) = 1;

    %-------------------------------------
    nTrials = size(tacDirectionTrials,1);

    %        experimentTrial_Matrix.MeasuredSpeed_cm_s = nan(nTrials, 1);
    experimentTrial_Matrix.EncoderSamples     = cell(nTrials, 1);

    VarNames = {'Trial_num', 'PairID', 'ArmDirection', 'Arm_Mov_Speed', 'Arm_Mov_duration', 'Arm_Mov_Onset', ...
    'StimDirection', 'Stim_Speed', 'StimDuration', 'StimIndentation', 'StimOnset', 'HandPosture', ...
    'Arm_mov_StartPosition', 'Arm_mov_StartPosition_arduino', 'Arm_Mov_Speed_arduino', ...
    'Arm_Mov_Acc_arduino', 'Arm_Mov_Steps_arduino', 'Arm_Mov_StepsAbs_arduino', ...
    'StimDirection_arduino', 'StimSpeed_arduino', 'StimDuration_arduino', ...
    'StimIndentation_arduino', 'InterTrialInterval', 'Response', 'ReactionTime', ...
    'TrialStart_time', 'IsActive', 'MeasuredSpeed_cm_s', 'EncoderSamples'};

    VarType = {'double', 'double', 'string', 'double', 'double', 'double', ...
    'double', 'double', 'double', 'double', 'double', 'double', ...
    'double', 'double', 'double', 'double', 'double', 'double', ...
    'double', 'double', 'double', 'double', 'double', 'double', ...
    'double', 'double', 'double', 'double', 'cell'};

    startBlock = 1;
    endBlock = round(nTrials / blocks_per_posture);

    for bb = 1:blocks_per_posture

        if mod(bb,2) == 1
            globalPairID = globalPairID + 1;
            pairID = globalPairID;
            blockTypeStr = 'ACTIVE';
            isActiveBlock = 1;
        else
            pairID = globalPairID;
            blockTypeStr = 'PASSIVE';
            isActiveBlock = 0;
        end

        TrialStim_param = table('Size', [(endBlock - startBlock + 1) length(VarNames)], ...
            'VariableNames', VarNames, 'VariableTypes', VarType);

        for n = 1:(endBlock - startBlock + 1)
            idx = startBlock - 1 + n;

            TrialStim_param.Trial_num(n) = n;
            TrialStim_param.PairID(n) = pairID;
        

            TrialStim_param.StimDirection(n) = tacDirectionTrials(idx,1);
            TrialStim_param.HandPosture(n) = tacDirectionTrials(idx,3);
            TrialStim_param.Arm_Mov_Speed(n) = tacDirectionTrials(idx,2);
            TrialStim_param.Stim_Speed(n) = tactileMotion_speed;
            TrialStim_param.Arm_Mov_Onset(n) = nan;
            TrialStim_param.MeasuredSpeed_cm_s(n) = nan;
            TrialStim_param.EncoderSamples(n) = {[]};

            if tacDirectionTrials(idx,4) == 0
                TrialStim_param.Arm_mov_StartPosition(n) = 0;
                TrialStim_param.Arm_mov_StartPosition_arduino(n) = 0;
            else
                TrialStim_param.Arm_mov_StartPosition(n) = 1;
                TrialStim_param.Arm_mov_StartPosition_arduino(n) = -1 * max(pickArmMovSteps_arduino);
            end

            TrialStim_param.Arm_Mov_duration(n) = durationArm_mov;
            TrialStim_param.StimDuration(n) = tactileMotion_duration;
            TrialStim_param.StimIndentation(n) = tactileMotion_stimIndent;
            TrialStim_param.StimOnset(n) = nan;

            ardIdx = find(abs(tacDirectionTrials(idx,2)) == pickArmMovSpeed, 1);

            if TrialStim_param.Arm_Mov_Speed(n) == 0
                TrialStim_param.ArmDirection(n) = "No movement";
                TrialStim_param.Arm_Mov_Steps_arduino(n) = pickArmMovSteps_arduino(ardIdx);
            else
                if TrialStim_param.Arm_mov_StartPosition(n) == 1
                    TrialStim_param.Arm_Mov_Speed(n) = abs(TrialStim_param.Arm_Mov_Speed(n));
                    TrialStim_param.Arm_Mov_Steps_arduino(n) = pickArmMovSteps_arduino(ardIdx);
                    TrialStim_param.ArmDirection(n) = "Right to Left";
                else
                    TrialStim_param.Arm_Mov_Speed(n) = -1 * abs(TrialStim_param.Arm_Mov_Speed(n));
                    TrialStim_param.Arm_Mov_Steps_arduino(n) = -1 * pickArmMovSteps_arduino(ardIdx);
                    TrialStim_param.ArmDirection(n) = "Left to Right";
                end
            end

            TrialStim_param.Arm_Mov_StepsAbs_arduino(n) = abs(TrialStim_param.Arm_Mov_Steps_arduino(n));
            TrialStim_param.Arm_Mov_Speed_arduino(n) = pickArmMovSpeed_arduino(ardIdx);
            TrialStim_param.Arm_Mov_Acc_arduino(n) = pickArmMovAcc_arduino(ardIdx);
            TrialStim_param.StimDirection_arduino(n) = TrialStim_param.StimDirection(n);
            TrialStim_param.StimSpeed_arduino(n) = tactileMotion_speed_arduino;
            TrialStim_param.StimDuration_arduino(n) = tactileMotion_duration_arduino;
            TrialStim_param.StimIndentation_arduino(n) = tactileMotion_indent_arduino;
            TrialStim_param.InterTrialInterval(n) = ITI;
            TrialStim_param.Response(n) = nan;
            TrialStim_param.ReactionTime(n) = nan;
            TrialStim_param.TrialStart_time(n) = nan;

            % block-level active/passive assignment
            TrialStim_param.IsActive(n) = isActiveBlock;
        end

        fileName = fullfile(outDir, ...
            [subjID '_' taskType ...
            '_ElbowPosture_' num2str(armPosture(post)) ...
            '_pair_' sprintf('%02d', pairID) ...
            '_block_' sprintf('%02d', bb) ...   % <--- add block number here
            '_' blockTypeStr '.mat']);
        save(fileName, 'TrialStim_param');
        disp(['Pair #' num2str(pairID) ' (' blockTypeStr ') of elbow posture ' ...
            num2str(armPosture(post)) ' saved'])

        startBlock = endBlock + 1;

        if bb < (blocks_per_posture - 1)
            endBlock = endBlock + round(nTrials / blocks_per_posture);
        else
            endBlock = nTrials;
        end
    end
end
end


