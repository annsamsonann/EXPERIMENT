
function avgVel_cm_s = computeAverageEncoderVelocity(app, encoderSamples)
if size(encoderSamples, 1) < 2
    avgVel_cm_s = NaN;
    return
end

dt = diff(encoderSamples(:,1)) ./ 1000;
dx = diff(encoderSamples(:,3));

vel_cm_s = dx ./ dt;
vel_cm_s(dt <= 0) = NaN;

avgVel_cm_s = mean(abs(vel_cm_s), 'omitnan');
end
