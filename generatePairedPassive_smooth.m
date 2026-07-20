function [passiveBlocks]=  generatePairedPassive_smooth(experimentTrial_Matrix)
cm_per_step = ExpConfig.cm_per_step;
accSafetyMargin  = 1.15;   % same margin validated in stageSpeedDurationCalibration.m
rangeSafetyFactor = 0.97;  % max allowed travel = 97% of the stage's physical range (unsupervised run -> keep a real cushion)
maxRangeSteps = round(rangeSafetyFactor * ExpConfig.LinStage_range_steps);  % NOTE: rename this field if ExpConfig uses a different name for the physical stage range in steps
idx = [];
passiveBlocks = [];
idx = randperm(size(experimentTrial_Matrix,1));
passiveBlocks = experimentTrial_Matrix(idx,:);
a = 1:size(passiveBlocks,1);
%fixed trial number
passiveBlocks.Trial_num = a';
passiveBlocks.Arm_Mov_Speed = passiveBlocks.MeasuredSpeed_cm_s;
passiveBlocks.Arm_Mov_Speed(isnan(passiveBlocks.Arm_Mov_Speed)) = 0;
motionTrialsIdx = find(passiveBlocks.Arm_Mov_Speed ~= 0);
NoMotionTrialsIdx = find(passiveBlocks.Arm_Mov_Speed == 0);
negativeVelocity = ones(size(passiveBlocks,1),1);
negativeVelocity(find(contains(passiveBlocks.ArmDirection, "Left to Right") == 1)) = -1;
negativeVelocity = negativeVelocity(motionTrialsIdx);
t = passiveBlocks.Measured_Arm_Mov_Duration_s(motionTrialsIdx);

% Target distance (signed steps) from measured speed * duration
d_steps_target = round(abs(passiveBlocks.Arm_Mov_Speed(motionTrialsIdx) .* t) ./ cm_per_step);

% --- RANGE LIMIT: clamp distance so the stage never exceeds its physical travel ---
% Duration (t) is kept fixed to match the paired active trial's timing; distance is
% capped at maxRangeSteps for any trial that would otherwise exceed it. Capped trials
% will therefore run at a lower average speed than their paired active trial.
passiveBlocks.Arm_Mov_DistanceClamped = false(size(passiveBlocks,1),1);
passiveBlocks.Arm_Mov_DistanceClamped(motionTrialsIdx) = d_steps_target > maxRangeSteps;
d_steps = min(d_steps_target, maxRangeSteps);

passiveBlocks.Arm_Mov_Steps_arduino(motionTrialsIdx) = negativeVelocity .* d_steps;
passiveBlocks.Arm_Mov_StepsAbs_arduino(motionTrialsIdx) = d_steps;

% Trapezoid-based (S_steps, A_steps) solve -- matches solveTrapezoid_local in stageSpeedDurationCalibration.m.
% Jointly reconciles commanded peak speed and acceleration so the trapezoid profile actually
% covers d_steps (now range-limited) in time t, instead of assuming S = v/cm_per_step directly.
%   a_min   = 4*d_steps / t^2   (minimum accel for a symmetric trapezoid to fit d_steps into time t)
%   a_steps = accSafetyMargin * a_min
%   v_p     = peak/cruise velocity consistent with a_steps, d_steps, and t
a_min   = 4 .* d_steps ./ (t.^2);
a_steps = accSafetyMargin .* a_min;
disc    = (a_steps .* t).^2 - 4 .* a_steps .* d_steps;
disc(disc < 0) = 0;   % safety guard; with accSafetyMargin > 1 this is analytically always >= 0
v_p     = (a_steps .* t - sqrt(disc)) ./ 2;

passiveBlocks.Arm_Mov_Speed_arduino(motionTrialsIdx) = negativeVelocity .* round(v_p);
passiveBlocks.Arm_Mov_Acc_arduino(motionTrialsIdx)   = round(a_steps);

if any(passiveBlocks.Arm_Mov_DistanceClamped)
    nClamped = sum(passiveBlocks.Arm_Mov_DistanceClamped);
    fprintf('generatePairedPassive: %d trial(s) had their distance clamped to stay within %.1f%% of the stage''s physical range. See Arm_Mov_DistanceClamped column.\n', ...
        nClamped, rangeSafetyFactor*100);
end

passiveBlocks.IsActive = zeros(size(passiveBlocks,1),1);
passiveBlocks.Arm_Mov_Onset = nan(size(passiveBlocks,1),1);
passiveBlocks.StimOnset = nan(size(passiveBlocks,1),1);
passiveBlocks.Arm_Mov_Onset_Trial = nan(size(passiveBlocks,1),1);
passiveBlocks.InterTrialInterval = nan(size(passiveBlocks,1),1);
passiveBlocks.Response = nan(size(passiveBlocks,1),1);
passiveBlocks.ReactionTime = nan(size(passiveBlocks,1),1);
passiveBlocks.TrialStart_time = nan(size(passiveBlocks,1),1);
passiveBlocks.MeasuredSpeed_cm_s = nan(size(passiveBlocks,1),1);
passiveBlocks.Measured_Arm_Mov_Dist_cm = nan(size(passiveBlocks,1),1);
passiveBlocks.EncoderSamples = cell(size(passiveBlocks,1), 1);
passiveBlocks.OnsetSample = cell(size(passiveBlocks,1), 1);
passiveBlocks.AbsExpStart = nan(size(passiveBlocks,1),1);
passiveBlocks.AbsTrialStart = nan(size(passiveBlocks,1),1);
end
