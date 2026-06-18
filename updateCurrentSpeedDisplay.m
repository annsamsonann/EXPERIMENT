%THESE MUST BE CGANGED AND IMPLEMENTED TO SHOW AVG FOR THE TRIAL, NOT INST 
function updateCurrentSpeedDisplay(app, encoderSamples)
    vel_cm_s = computeInstantaneousSpeeds(app, encoderSamples);

    if isempty(vel_cm_s)
        app.CurrentArmMovementNALabel.Text = 'Current Arm Movement: N/A';
    else
        app.CurrentArmMovementNALabel.Text = sprintf('Current Arm Movement: %.2f cm/s', vel_cm_s(end));
    end
    drawnow limitrate
end

function vel_cm_s = computeInstantaneousSpeeds(app, encoderSamples)
    if size(encoderSamples,1) < 2
        vel_cm_s = [];
        return
    end

    dt = diff(encoderSamples(:,1)) ./ 1000;   % s
    dx = diff(encoderSamples(:,3));           % cm

    vel_cm_s = abs(dx ./ dt);
    vel_cm_s(dt <= 0) = NaN;
    vel_cm_s = vel_cm_s(~isnan(vel_cm_s) & isfinite(vel_cm_s));
end
