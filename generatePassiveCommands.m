%return UNSIGNED 
function [new_speed_fast, new_acc_fast, new_dist_fast, ...
          new_speed_slow, new_acc_slow, new_dist_slow] = ...
          generatePassiveCommands(activeBehavior)


      isFast = activeBehavior.Arm_Mov_Acc_arduino == app.fastMotionCommanded;
      isSlow = activeBehavior.Arm_Mov_Acc_arduino == app.slowMotionCommanded;

      avgFast = mean(activeBehavior.MeasuredSpeed_cm_s(isFast), 'omitnan');
      avgSlow = mean(activeBehavior.MeasuredSpeed_cm_s(isSlow), 'omitnan');

    t = 1.6;              % movement duration in sec
    cm_per_step = 0.00467;

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


     % TEST
     % new_speed_fast = 50000;          % steps/s
     % new_speed_slow = 10;          % steps/s
     % 
     % new_acc_fast   = 50000;             % stage accel units used in your test
     % new_acc_slow   = 10;
     % 
     % new_dist_fast  = 50000;    % steps
     % new_dist_slow  = 10;    % steps
end
