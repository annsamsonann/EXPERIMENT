function [moveDir, speedStr, no_motion_flag] = getTrialInfo(app, stepsArduino, speedArduino)
no_motion_flag = false;
if stepsArduino < 0
    moveDir = 'right';
elseif stepsArduino > 0
    moveDir = 'left';
else
    moveDir = 'none';
    no_motion_flag = true;
end

if speedArduino >= ExpConfig.fast_target_speed_steps*0.8
    speedStr = 'fast';
elseif speedArduino < ExpConfig.slow_target_speed_steps*1.2 && speedArduino > 0
    speedStr = 'slow';
elseif speedArduino == 0
    speedStr = 'no';
end
end