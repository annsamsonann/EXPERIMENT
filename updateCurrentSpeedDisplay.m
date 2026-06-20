%THESE MUST BE CGANGED AND IMPLEMENTED TO SHOW AVG FOR THE TRIAL, NOT INST 
function updateCurrentSpeedDisplay(app, vel_cm_s)

    if isempty(vel_cm_s)
        app.CurrentArmMovementNALabel.Text = 'Current Arm Movement: N/A';
    else
        app.CurrentArmMovementNALabel.Text = sprintf('Current Arm Movement: %.2f cm/s', vel_cm_s(end));
    end
    drawnow limitrate
end

