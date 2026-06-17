%return UNSIGNED 
function [new_speed_fast, new_acc_fast, new_dist_fast, new_speed_slow, new_acc_slow, new_dist_slow] = generatePassiveCommands(activeBehavior,fastMotionCommanded,slowMotionCommanded)
      isFast = activeBehavior.Arm_Mov_Acc_arduino == fastMotionCommanded;
      isSlow = activeBehavior.Arm_Mov_Acc_arduino == slowMotionCommanded;

      avgFast = mean(activeBehavior.MeasuredSpeed_cm_s(isFast), 'omitnan');
      avgSlow = mean(activeBehavior.MeasuredSpeed_cm_s(isSlow), 'omitnan');
      % Discard trials that are 
            %we should choose the fast speed so that fast speed is less than max speed by 20 % 
                  %max speed defined by dist from one end to the other is 
                  %max speed from the middle is: ? 

      t = 1.75;              % movement duration in sec
      cm_per_step = 0.00467;
      range_cm = 17.145;
      max_steps = range_cm /cm_per_step;
      max_speed = range_cm/t;

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


end
