function [TrialStim_param_rand] = generatePairedPassiveOLD(activeBehavior)
%%before MGR
    cm_per_step = ExpConfig.cm_per_step;
    TrialStim_param = activeBehavior;
    motionTrialsIdx = (TrialStim_param.Arm_Mov_Speed ~= 0);
    t = TrialStim_param.Measured_Arm_Mov_Duration_s(motionTrialsIdx);

    
    % I need to take all active trials with mesured speeds etc
    % 1) remove all behavior / recorded stuff (make it have the same format as
    % generate trials initially (trialStimParam)

    % 1. Default everything to the positive duration value and assign signs

    TrialStim_param.Arm_Mov_Speed (motionTrialsIdx) = TrialStim_param.MeasuredSpeed_cm_s(motionTrialsIdx) ;
    isNegative = TrialStim_param.Arm_Mov_Steps_arduino < 0;
    TrialStim_param.Arm_Mov_Speed(isNegative) = TrialStim_param.MeasuredSpeed_cm_s(isNegative) * -1;

    numRows = height(TrialStim_param);

    % 2. Reset numerical columns using vectors of the correct size
    TrialStim_param.IsActive                     = zeros(numRows, 1);
    TrialStim_param.Arm_Mov_Onset                = NaN(numRows, 1);
    TrialStim_param.Arm_Mov_Onset_Trial          = NaN(numRows, 1);
    TrialStim_param.StimOnset                    = NaN(numRows, 1);
    TrialStim_param.InterTrialInterval            = NaN(numRows, 1);
    TrialStim_param.Response                     = NaN(numRows, 1);
    TrialStim_param.ReactionTime                 = NaN(numRows, 1);
    TrialStim_param.TrialStart_time              = NaN(numRows, 1);
    TrialStim_param.AbsExpStart                  = NaN(numRows, 1);
    TrialStim_param.AbsTrialStart                = NaN(numRows, 1);
    TrialStim_param.Measured_Arm_Mov_Duration_s  = NaN(numRows, 1);
    TrialStim_param.Measured_Arm_Mov_Dist_cm     = NaN(numRows, 1);
    TrialStim_param.MeasuredSpeed_cm_s           = NaN(numRows, 1);

    % 3. Reset cell array columns using a cell vector of the correct size
    TrialStim_param.EncoderSamples               = cell(numRows, 1);
    TrialStim_param.OnsetSample                  = cell(numRows, 1);

    % 2) overwrite arduino commands based on the arm measured speed and
    % duration of arm motion

    TrialStim_param.Arm_Mov_Speed_arduino(motionTrialsIdx) = round(TrialStim_param.Arm_Mov_Speed(motionTrialsIdx) ./ cm_per_step);
    TrialStim_param.Arm_Mov_Acc_arduino(motionTrialsIdx) = round(abs(TrialStim_param.Arm_Mov_Speed_arduino(motionTrialsIdx)) .* 1000);
    TrialStim_param.Arm_Mov_Steps_arduino(motionTrialsIdx) = round((TrialStim_param.Arm_Mov_Speed(motionTrialsIdx) .* t) ./ cm_per_step);
    TrialStim_param.Arm_Mov_StepsAbs_arduino(motionTrialsIdx) = abs(TrialStim_param.Arm_Mov_Steps_arduino(motionTrialsIdx));

    % 3) Randomize the order

    randomIndices = randperm(numRows);
    TrialStim_param_rand = TrialStim_param(randomIndices, :);
end