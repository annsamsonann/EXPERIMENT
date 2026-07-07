
function [avgVel_cm_s,elapsedTime_s,totalDist_cm]  = computeAverageEncoderVelocity(app, encoderSamples)
if isempty(encoderSamples) || size(encoderSamples, 1) < 2
    avgVel_cm_s   = NaN;
    elapsedTime_s = NaN;   % Or NaN, depending on your preference
    totalDist_cm  = NaN;   % Or NaN
    return
end

dt = diff(encoderSamples(:,1)) ./ 1000;
dx = diff(encoderSamples(:,3));

vel_cm_s = dx ./ dt;
vel_cm_s(dt <= 0) = NaN;

avgVel_cm_s = mean(abs(vel_cm_s), 'omitnan');
elapsedTime_s = (encoderSamples(end,1) - encoderSamples(1,1)) / 1000;
totalDist_cm = encoderSamples(end,3) - encoderSamples(1,3);
end
