%return UNSIGNED 
function S = generatePassiveCommands(activeBehavior)
    fast_target_speed_steps = ExpConfig.fast_target_speed_steps;
    slow_target_speed_steps = ExpConfig.slow_target_speed_steps; 
    isFast = activeBehavior.Arm_Mov_Speed_arduino == fast_target_speed_steps;
    isSlow = activeBehavior.Arm_Mov_Speed_arduino == slow_target_speed_steps;
    cm_per_step = ExpConfig.cm_per_step;
    t = ExpConfig.StageMotionDur_sec;

    fast_upper_speed_threshold = ExpConfig.max_speed_cm;
    fast_lower_speed_threshold = ExpConfig.fast_target * 0.8;
    slow_upper_speed_threshold = ExpConfig.slow_target * 1.2;
    slow_lower_speed_threshold = ExpConfig.slow_target * 0.8;

    FastTrialsGoodMask = isFast ...
        & activeBehavior.MeasuredSpeed_cm_s <= fast_upper_speed_threshold ...
        & activeBehavior.MeasuredSpeed_cm_s >= fast_lower_speed_threshold;

    SlowTrialsGoodMask = isSlow ...
        & activeBehavior.MeasuredSpeed_cm_s <= slow_upper_speed_threshold ...
        & activeBehavior.MeasuredSpeed_cm_s >= slow_lower_speed_threshold;

    FastTrialsGood = activeBehavior.MeasuredSpeed_cm_s(FastTrialsGoodMask);
    SlowTrialsGood = activeBehavior.MeasuredSpeed_cm_s(SlowTrialsGoodMask);

    S.avgFast = mean(FastTrialsGood, 'omitnan');
    S.avgSlow = mean(SlowTrialsGood, 'omitnan');

    S.new_speed_fast = round(S.avgFast / cm_per_step);
    S.new_speed_slow = round(S.avgSlow / cm_per_step);

    S.new_acc_fast = round(S.new_speed_fast * 1000);
    S.new_acc_slow = round(S.new_speed_slow * 1000);

    S.new_dist_fast = round((S.avgFast * t) / cm_per_step);
    S.new_dist_slow = round((S.avgSlow * t) / cm_per_step);

    S.nFastInRange = sum(FastTrialsGoodMask);
    S.nSlowInRange = sum(SlowTrialsGoodMask);
end