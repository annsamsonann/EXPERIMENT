%% STAGE SPEED + DURATION CALIBRATION (trapezoid-solved S/A)
% Same working protocol as your validated script (E 0, ZERO, T <steps>
% telemetry codes, M for return), but now sweeps BOTH target speed AND
% target duration, and solves (S_steps, A_steps) per condition from the
% distance/duration constraint instead of the naive A = S*1000 rule.
%
% Cross-checks THREE independent measurements per trial:
%   - stage telemetry (firmware's own step-timed report from "T")
%   - encoder-measured average speed (position samples)
%   - encoder-measured move duration (first->last actual position change)
clear; clc;

%% SERIAL SETUP
stage_port   = "COM7";
encoder_port = "COM5";
baud         = 115200;

LinearStage_motor = serialport(stage_port, baud);
configureTerminator(LinearStage_motor, "LF");
LinearStage_motor.Timeout = 20;

rotaryEncoder = serialport(encoder_port, baud);
configureTerminator(rotaryEncoder, "LF");
rotaryEncoder.Timeout = 2;

pause(2.5);   % let the Arduino finish its auto-reset/boot fully before we touch it

% Drain startup banners. flush() clears whatever is sitting in the buffer
% without needing complete lines, so it can't hang/miss data the way a
% readline-based drain can if a boot line arrives a moment late.
flush(LinearStage_motor);
flush(rotaryEncoder);

writeline(LinearStage_motor, "E 0");   % engage driver so it obeys T / M
pause(0.3);
flush(LinearStage_motor, "input");     % discard any stray echo/response to E 0 before trial 1

%% TEST CONDITIONS
cm_per_step          = 0.00467;   % stage calibration
LinStage_range_steps = 3640;      % full stage travel (~17.0 cm)
% Set to the full physical range (no software cushion) so all 111 of your
% real recorded pairs are included -- the max required distance among them
% is ~16.96 cm vs. ~17.0 cm total travel, so there is very little
% mechanical margin left on the fastest/longest trials. You said you'll be
% watching the stage, but keep an eye especially on trials needing >15 cm
% (the ones with speed ~8-10.5 cm/s paired with duration >1.6 s).
rangeSafetyFactor    = 1.0;
accSafetyMargin      = 1.15;      % a_steps = margin * a_min (gentler than naive S*1000)

num_repeats          = 1;   % 111 conditions x N repeats -- bump up once you've watched a full pass

maxRangeSteps = round(rangeSafetyFactor * LinStage_range_steps);

target_pairs_cmps_s = [    % [speed_cm_s, duration_s] -- your real recorded arm-move data
    5.19736842, 1.44400000;
    5.65169316, 1.44700000;
    5.65167785, 1.49000000;
    8.85953177, 1.49500000;
    6.13193117, 1.56900000;
    10.49721362, 1.61500000;
    4.60109290, 1.64700000;
    3.66485507, 1.65600000;
    6.61910448, 1.67500000;
    4.47602131, 1.68900000;
    3.28462887, 1.71100000;
    6.68107477, 1.71200000;
    5.08989391, 1.79100000;
    6.44723893, 1.82900000;
    2.67752269, 1.87300000;
    7.81154050, 1.88900000;
    3.68797565, 1.97100000;
    4.31338892, 2.03900000;
    4.19365854, 2.05000000;
    4.78471889, 2.08100000;
    6.58433445, 2.08100000;
    5.89947343, 2.08900000;
    3.90917782, 2.09200000;
    3.71857143, 2.10000000;
    5.94933712, 2.11200000;
    6.08411654, 2.12800000;
    6.22652966, 2.14100000;
    3.37348273, 2.14200000;
    4.30726257, 2.14800000;
    6.03669299, 2.15300000;
    5.33914640, 2.17900000;
    6.96115174, 2.18800000;
    3.85902683, 2.19900000;
    2.75374091, 2.33900000;
    3.06694215, 2.42000000;
    10.75422535, 1.42000000;
    9.37027027, 1.48000000;
    9.89094514, 1.51300000;
    7.81639344, 1.52500000;
    8.27777778, 1.53000000;
    9.25802616, 1.68200000;
    5.27955083, 1.69200000;
    8.56615215, 1.81400000;
    4.00652884, 1.83800000;
    5.71352218, 1.87100000;
    8.47530536, 1.88300000;
    8.80935065, 1.92500000;
    6.88412455, 1.95900000;
    6.65921788, 1.96900000;
    6.90261044, 1.99200000;
    5.15215215, 1.99800000;
    7.08947108, 2.02300000;
    3.25900345, 2.02700000;
    5.14432990, 2.03700000;
    6.89960823, 2.04200000;
    7.96042990, 2.04700000;
    4.36918605, 2.06400000;
    3.41210654, 2.06500000;
    3.64742665, 2.07900000;
    4.93067426, 2.10600000;
    3.13636364, 2.15600000;
    5.89282429, 2.17400000;
    6.32505747, 2.17500000;
    3.95185695, 2.18100000;
    3.33196721, 2.19600000;
    3.28157537, 2.20900000;
    3.91092211, 2.23400000;
    3.62000859, 2.32900000;
    2.99632859, 2.17900000;
    3.35121681, 1.80800000;
    3.39382239, 1.55400000;
    3.62423095, 2.11300000;
    3.72689844, 2.18600000;
    3.82292232, 1.84100000;
    4.08819539, 2.21100000;
    4.20342034, 2.22200000;
    4.54689093, 1.96200000;
    4.56481980, 1.85900000;
    4.80302315, 2.11700000;
    5.00485143, 1.64900000;
    5.29020032, 1.84700000;
    6.01600000, 2.25000000;
    6.09101796, 2.50500000;
    6.43482587, 2.01000000;
    6.86656520, 1.97100000;
    7.05807522, 1.80800000;
    7.26343154, 1.73100000;
    7.40364440, 1.81100000;
    7.70250000, 1.60000000;
    7.77402446, 1.71700000;
    7.80486158, 1.48100000;
    7.92642140, 1.49500000;
    8.04658902, 1.80300000;
    8.05110837, 1.62400000;
    9.06233933, 1.55600000;
    5.31613611, 1.82200000;
    5.45227698, 1.60300000;
    5.45297718, 1.79700000;
    5.98695652, 1.84000000;
    6.01948394, 1.89900000;
    6.03661327, 1.74800000;
    6.09890656, 2.01200000;
    6.32929399, 1.89800000;
    6.33030091, 1.42900000;
    6.43547320, 1.51100000;
    6.58361093, 1.50100000;
    6.70365778, 1.61300000;
    6.90344828, 1.45000000;
    7.46131472, 1.71900000;
    7.58055556, 1.44000000;
    8.30132939, 1.35400000;
];

cond_speed     = target_pairs_cmps_s(:,1);
cond_duration  = target_pairs_cmps_s(:,2);
num_conditions = numel(cond_speed);

fprintf('%d unique speed/duration pairs x %d repeat(s) = %d trials. At ~9-10 s/trial that''s roughly %.0f min.\n', ...
    num_conditions, num_repeats, num_conditions*num_repeats, num_conditions*num_repeats*9.5/60);

% Pre-solve (S_steps, A_steps, d_steps, feasible) for every condition once
cond_Sstep   = nan(num_conditions,1);
cond_Astep   = nan(num_conditions,1);
cond_dstep   = nan(num_conditions,1);
cond_feasible = false(num_conditions,1);
for i = 1:num_conditions
    [S_steps, A_steps, feasible, d_steps] = solveTrapezoid_local( ...
        cond_speed(i), cond_duration(i), cm_per_step, accSafetyMargin, maxRangeSteps);
    cond_Sstep(i)    = S_steps;
    cond_Astep(i)    = A_steps;
    cond_dstep(i)    = d_steps;
    cond_feasible(i) = feasible;
    if ~feasible
        fprintf('Condition %d: v=%.1f cm/s, T=%.2f s -> INFEASIBLE (distance %.1f cm), will be skipped.\n', ...
            i, cond_speed(i), cond_duration(i), cond_speed(i)*cond_duration(i));
    end
end

%% RESULTS
results = repmat(struct( ...
    'repeat',              NaN, ...
    'condition',           NaN, ...
    'target_speed_cm_s',   NaN, ...
    'target_duration_s',   NaN, ...
    'target_distance_cm',  NaN, ...
    'S_steps',             NaN, ...
    'A_steps',             NaN, ...
    'move_time_ms',        NaN, ...   % stage telemetry
    'distance_cm',         NaN, ...   % stage telemetry
    'distance_steps',      NaN, ...   % stage telemetry
    'steps_per_sec',       NaN, ...   % stage telemetry
    'cm_per_sec',          NaN, ...   % stage telemetry
    'enc_move_time_ms',    NaN, ...   % encoder-measured
    'enc_cm_per_sec',      NaN, ...   % encoder-measured
    'moveConfirmed',       false), ...% true only if stage sent a full 100..199 telemetry sequence
    num_conditions, num_repeats);

%% TEST LOOP
for r = 1:num_repeats
    fprintf('\n================ REPEAT %d / %d ================\n', r, num_repeats);
    for i = 1:num_conditions
        if ~cond_feasible(i)
            continue
        end
        pause(3);
        v = cond_speed(i); T = cond_duration(i);
        d_steps = cond_dstep(i); S_steps = cond_Sstep(i); A_steps = cond_Astep(i);

        fprintf('\n--- Condition %d/%d | Repeat %d/%d | v=%.1f cm/s, T=%.2f s -> steps=%d, S=%d, A=%d ---\n', ...
            i, num_conditions, r, num_repeats, v, T, d_steps, S_steps, A_steps);

        flushRotaryEncoderBuffer(rotaryEncoder);
        zeroRotaryEncoder(rotaryEncoder);
        pause(0.05);

        % Clear any stray bytes left over from a previous command/response
        % so the telemetry parser below can't accidentally pick up stale
        % data and can't miss the real "100 ... 199" sequence for THIS move.
        flush(LinearStage_motor, "input");

        writeline(LinearStage_motor, "E 0");
        pause(0.1);
        writeline(LinearStage_motor, sprintf("S %d", S_steps));
        pause(0.1);
        writeline(LinearStage_motor, sprintf("A %d", A_steps));
        pause(0.1);
        writeline(LinearStage_motor, sprintf("T %d", -d_steps));   % negative = outbound from leftmost start

        temp = readOneSpeedTestWithEncoder(LinearStage_motor, rotaryEncoder);

        results(i,r).repeat             = r;
        results(i,r).condition          = i;
        results(i,r).target_speed_cm_s  = v;
        results(i,r).target_duration_s  = T;
        results(i,r).target_distance_cm = v * T;
        results(i,r).S_steps            = S_steps;
        results(i,r).A_steps            = A_steps;
        results(i,r).move_time_ms       = temp.move_time_ms;
        results(i,r).distance_cm        = temp.distance_cm;
        results(i,r).distance_steps     = temp.distance_steps;
        results(i,r).steps_per_sec      = temp.steps_per_sec;
        results(i,r).cm_per_sec         = temp.cm_per_sec;
        results(i,r).enc_move_time_ms   = temp.enc_move_time_ms;
        results(i,r).enc_cm_per_sec     = temp.enc_cm_per_sec;
        results(i,r).moveConfirmed      = temp.success;

        if ~temp.success
            % No "199" completion telemetry was ever seen for this T command
            % -- the outbound move did NOT happen (or we can't confirm it did).
            % Do NOT send the return move: the stage is very likely still at
            % the left start, and blindly commanding M here is exactly what
            % drives it into the edge. Skip and let you inspect before continuing.
            warning(['Trial %d/%d (repeat %d): no completion telemetry received for T %d. ' ...
                'Skipping the return move -- check the stage/connection before the next trial.'], ...
                i, num_conditions, r, -d_steps);
            continue
        end

        fprintf('Target:  v=%.2f cm/s | T=%.2f s\n', v, T);
        fprintf('Stage:   v=%.2f cm/s | T=%.2f s\n', results(i,r).cm_per_sec, results(i,r).move_time_ms/1000);
        fprintf('Encoder: v=%.2f cm/s | T=%.2f s\n', results(i,r).enc_cm_per_sec, results(i,r).enc_move_time_ms/1000);

        pause(3);

        % Move back to the left start (positive = right-to-left on your stage)
        flush(LinearStage_motor, "input");
        writeline(LinearStage_motor, sprintf("M %d", d_steps));
        pause(0.2);
    end
end

%% BUILD RESULTS TABLE
rows = struct2table(results(:));
rows = rows(~isnan(rows.repeat), :);   % drop skipped/infeasible entries
rows.SpeedError_pct    = 100 * (rows.cm_per_sec - rows.target_speed_cm_s) ./ rows.target_speed_cm_s;
rows.DurationError_pct = 100 * (rows.move_time_ms/1000 - rows.target_duration_s) ./ rows.target_duration_s;
rows.EncSpeedError_pct    = 100 * (rows.enc_cm_per_sec - rows.target_speed_cm_s) ./ rows.target_speed_cm_s;
rows.EncDurationError_pct = 100 * (rows.enc_move_time_ms/1000 - rows.target_duration_s) ./ rows.target_duration_s;

disp(rows);
writetable(rows, fullfile(pwd, 'stage_speed_duration_calibration_raw.csv'));

nUnconfirmed = sum(~rows.moveConfirmed);
if nUnconfirmed > 0
    fprintf('\n%d of %d trials had no confirmed move (telemetry timeout) -- excluded from error stats/plots below.\n', ...
        nUnconfirmed, height(rows));
end
rows = rows(rows.moveConfirmed, :);   % only confirmed moves count toward accuracy stats

%% AVERAGE PER CONDITION
avgTbl = groupsummary(rows, {'condition'}, 'mean', ...
    {'target_speed_cm_s','target_duration_s','target_distance_cm', ...
     'S_steps','A_steps','move_time_ms','distance_cm','cm_per_sec', ...
     'enc_move_time_ms','enc_cm_per_sec','SpeedError_pct','DurationError_pct', ...
     'EncSpeedError_pct','EncDurationError_pct'});
disp(avgTbl);
writetable(avgTbl, fullfile(pwd, 'stage_speed_duration_calibration_avg.csv'));

fprintf('\n--- Summary across all confirmed trials ---\n');
fprintf('Stage telemetry:  mean |speed error| = %.2f %%, mean |duration error| = %.2f %%\n', ...
    mean(abs(rows.SpeedError_pct), 'omitnan'), mean(abs(rows.DurationError_pct), 'omitnan'));
fprintf('Encoder-measured: mean |speed error| = %.2f %%, mean |duration error| = %.2f %%\n', ...
    mean(abs(rows.EncSpeedError_pct), 'omitnan'), mean(abs(rows.EncDurationError_pct), 'omitnan'));

%% PLOTS
figure('Color','w','Name','Speed calibration');
subplot(1,2,1);
scatter(rows.target_speed_cm_s, rows.cm_per_sec, 50, rows.target_duration_s, 'filled', 'DisplayName','Stage'); hold on;
scatter(rows.target_speed_cm_s, rows.enc_cm_per_sec, 50, rows.target_duration_s, 'd', 'DisplayName','Encoder');
lims = [0, max([rows.target_speed_cm_s; rows.cm_per_sec; rows.enc_cm_per_sec])*1.1];
plot(lims, lims, 'k--', 'HandleVisibility','off');
xlabel('Target speed (cm/s)'); ylabel('Measured speed (cm/s)');
title('Speed: target vs. measured'); legend('Location','best');
cb = colorbar; cb.Label.String = 'Duration (s)'; grid on; axis square;

subplot(1,2,2);
scatter(rows.target_duration_s, rows.move_time_ms/1000, 50, rows.target_speed_cm_s, 'filled', 'DisplayName','Stage'); hold on;
scatter(rows.target_duration_s, rows.enc_move_time_ms/1000, 50, rows.target_speed_cm_s, 'd', 'DisplayName','Encoder');
lims2 = [0, max([rows.target_duration_s; rows.move_time_ms/1000; rows.enc_move_time_ms/1000])*1.1];
plot(lims2, lims2, 'k--', 'HandleVisibility','off');
xlabel('Target duration (s)'); ylabel('Measured duration (s)');
title('Duration: target vs. measured'); legend('Location','best');
cb2 = colorbar; cb2.Label.String = 'Speed (cm/s)'; grid on; axis square;

%% CLEANUP
% delete(LinearStage_motor); delete(rotaryEncoder); clear LinearStage_motor rotaryEncoder

%% ========================= LOCAL FUNCTIONS =========================
function [S_steps, A_steps, feasible, d_steps] = solveTrapezoid_local( ...
    v_cmps, T_s, cm_per_step, accSafetyMargin, maxRangeSteps)
d_cm = v_cmps * T_s;
d_steps = round(abs(d_cm) / cm_per_step);
feasible = true;

if d_steps < 1 || d_steps > maxRangeSteps
    S_steps = NaN; A_steps = NaN; feasible = false;
    return
end

a_min = 4 * d_steps / T_s^2;
a_steps = accSafetyMargin * a_min;
disc = (a_steps * T_s)^2 - 4 * a_steps * d_steps;
iter = 0;
while disc < 0 && iter < 50
    a_steps = a_steps * 1.05;
    disc = (a_steps * T_s)^2 - 4 * a_steps * d_steps;
    iter = iter + 1;
end
if disc < 0
    S_steps = NaN; A_steps = NaN; feasible = false;
    return
end

v_p = (a_steps * T_s - sqrt(disc)) / 2;
S_steps = round(v_p);
A_steps = round(a_steps);
if S_steps < 1
    feasible = false;
end
end

function result = readOneSpeedTestWithEncoder(LinearStage_motor, rotaryEncoder)
result = struct( ...
    'move_time_ms',      NaN, ...
    'enc_move_time_ms',  NaN, ...
    'distance_cm',       NaN, ...
    'distance_steps',    NaN, ...
    'steps_per_sec',     NaN, ...
    'cm_per_sec',        NaN, ...
    'enc_cm_per_sec',    NaN, ...
    'success',           false);   % true only if we actually saw the 199 "done" code
encoderSamples = [];
started = false;
t0 = tic;
max_wait_s = 25;
while toc(t0) < max_wait_s
    encoderSamples = [encoderSamples; readAvailableEncoderSamples(rotaryEncoder)]; %#ok<AGROW>
    if LinearStage_motor.NumBytesAvailable <= 0
        pause(0.01);
        continue
    end
    line = strtrim(readline(LinearStage_motor));
    disp("STAGE >> " + line);
    parts = split(line, ",");
    if numel(parts) < 1
        continue
    end
    code = str2double(parts{1});
    if isnan(code)
        continue
    end
    if ~started
        if code == 100
            started = true;
        end
        continue
    end
    if numel(parts) < 3
        continue
    end
    value = str2double(parts{3});
    switch code
        case 101
            result.move_time_ms = value;
        case 102
            result.distance_cm = value;
        case 103
            result.distance_steps = value;
        case 104
            result.steps_per_sec = value;
        case 105
            result.cm_per_sec = value;
        case 199
            result.success = true;
            break
    end
end
if ~result.success
    disp('WARNING: timed out waiting for stage telemetry -- no "100...199" sequence seen for this move.');
end
pause(0.05);
encoderSamples = [encoderSamples; readAvailableEncoderSamples(rotaryEncoder)];
[result.enc_cm_per_sec, elapsedTime_s] = computeAverageEncoderVelocity_local(encoderSamples);
result.enc_move_time_ms = elapsedTime_s * 1000;
end

function flushRotaryEncoderBuffer(rotaryEncoder)
if ~isempty(rotaryEncoder) && rotaryEncoder.NumBytesAvailable > 0
    read(rotaryEncoder, rotaryEncoder.NumBytesAvailable, "char");
end
end

function zeroRotaryEncoder(rotaryEncoder)
writeline(rotaryEncoder, "ZERO");
end

function samples = readAvailableEncoderSamples(rotaryEncoder)
samples = [];
while rotaryEncoder.NumBytesAvailable > 0
    line = strtrim(readline(rotaryEncoder));
    toks = split(line, ",");
    if numel(toks) == 4 && strcmp(strtrim(toks{1}), "DATA")
        t_ms    = str2double(toks{2});
        count   = str2double(toks{3});
        dist_cm = str2double(toks{4});
        if ~any(isnan([t_ms, count, dist_cm]))
            samples(end+1,:) = [t_ms, count, dist_cm]; %#ok<AGROW>
        end
    end
end
end

function [avgVel_cm_s, elapsedTime_s] = computeAverageEncoderVelocity_local(encoderSamples)
% Mirrors your production computeAverageEncoderVelocity(app, encoderSamples, onsetSamples):
%   elapsedTime_s = (last sample time - onset time) / 1000
%   totalDist_cm  = last (zero-referenced) position reading
%   avgVel_cm_s   = totalDist_cm / elapsedTime_s   (single distance/time ratio,
%                   so speed and duration can never disagree with each other)
%
% We have no separate onsetSamples phase in this bench test (the encoder is
% zeroed right before each move via "ZERO"), so the first sample collected
% after zeroing stands in for the onset time.
if size(encoderSamples, 1) < 2
    avgVel_cm_s   = NaN;
    elapsedTime_s = NaN;
    return
end
timeStart     = encoderSamples(1,1);
elapsedTime_s = (encoderSamples(end,1) - timeStart) / 1000;
totalDist_cm  = encoderSamples(end,3);
if elapsedTime_s <= 0
    avgVel_cm_s = NaN;
else
    avgVel_cm_s = totalDist_cm / elapsedTime_s;
end
end
