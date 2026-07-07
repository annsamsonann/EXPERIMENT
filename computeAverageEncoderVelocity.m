
function [avgVel_cm_s,elapsedTime_s,totalDist_cm]  = computeAverageEncoderVelocity(app, encoderSamples,onsetSamples)
if isempty(encoderSamples) || size(encoderSamples, 1) < 2  || isempty(onsetSamples)
    avgVel_cm_s   = NaN;
    elapsedTime_s = NaN;   % Or NaN, depending on your preference
    totalDist_cm  = NaN;   % Or NaN
    return
end
startIdx = [];
curPts = onsetSamples;
[timeStart startIdx] = min(curPts(:,3));

if length(startIdx) > 1
    startIdx = startIdx(end);
    timeStart = timeStart(end);
else
end

timeStart = curPts(startIdx,1);


% dt = diff(encoderSamples(:,1)) ./ 1000;
% dx = diff(encoderSamples(:,3));
% 
% vel_cm_s = dx ./ dt;
% vel_cm_s(dt <= 0) = NaN;
% 
% avgVel_cm_s = mean(abs(vel_cm_s), 'omitnan');
elapsedTime_s = (encoderSamples(end,1) - timeStart) / 1000;
totalDist_cm = encoderSamples(end,3);% encoderSamples(end,3) - encoderSamples(1,3);

avgVel_cm_s = totalDist_cm/elapsedTime_s;
end
