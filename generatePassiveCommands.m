%return UNSIGNED 
function [new_speed_fast, new_acc_fast, new_dist_fast, new_speed_slow, new_acc_slow, new_dist_slow] = generatePassiveCommands(activeBehavior,fastMotionCommanded,slowMotionCommanded)
      isFast = activeBehavior.Arm_Mov_Acc_arduino == fastMotionCommanded;
      isSlow = activeBehavior.Arm_Mov_Acc_arduino == slowMotionCommanded;
      cm_per_step = ExpConfig.cm_per_step;
      t           = ExpConfig.StageMotionDur_sec;


      % Discard trials that are over max speed or thresholds
      fast_upper_speed_threshold = ExpConfig.max_speed_cm;
      fast_lower_speed_threshold = ExpConfig.fast_target * 0.8;
      
      slow_upper_speed_threshold = ExpConfig.slow_target * 1.2;
      slow_lower_speed_threshold = ExpConfig.slow_target * 0.8;
      
      % logical masks over all trials
      FastTrialsGoodMask = isFast ...
          & activeBehavior.MeasuredSpeed_cm_s <= fast_upper_speed_threshold ...
          & activeBehavior.MeasuredSpeed_cm_s >= fast_lower_speed_threshold;
      
      SlowTrialsGoodMask = isSlow ...
          & activeBehavior.MeasuredSpeed_cm_s <= slow_upper_speed_threshold ...
          & activeBehavior.MeasuredSpeed_cm_s >= slow_lower_speed_threshold;
      
      % extract the speeds that pass the criteria
      FastTrialsGood  = activeBehavior.MeasuredSpeed_cm_s(FastTrialsGoodMask);
      SlowTrialsGood  = activeBehavior.MeasuredSpeed_cm_s(SlowTrialsGoodMask);
      
      avgFast = mean(FastTrialsGood, 'omitnan');
      avgSlow = mean(SlowTrialsGood, 'omitnan');

      % In your latest calibration: commanded == observed
      cmdFast_cm_s = avgFast;
      cmdSlow_cm_s = avgSlow;

      % % Convert to step-domain motor commands
      new_speed_fast = round(cmdFast_cm_s / cm_per_step);          % steps/s
      new_speed_slow = round(cmdSlow_cm_s / cm_per_step);          % steps/s
      
      new_acc_fast   = round(new_speed_fast * 1000);               % stage accel units used in your test
      new_acc_slow   = round(new_speed_slow * 1000);
      new_dist_fast  = round((cmdFast_cm_s * t) / cm_per_step);    % steps
      new_dist_slow  = round((cmdSlow_cm_s * t) / cm_per_step);    % steps
    nFastInRange = sum(FastTrialsGoodMask);
nSlowInRange = sum(SlowTrialsGoodMask);
    if nFastInRange == 0
        fprintf('FAST avg is NaN because no fast trials passed the threshold.\n');
    end
    
    if nSlowInRange == 0
        fprintf('SLOW avg is NaN because no slow trials passed the threshold.\n');
    end


end
