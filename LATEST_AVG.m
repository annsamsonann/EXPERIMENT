%% SPEED TEST WITH ENCODER - 5 REPEATS + AVERAGE
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

pause(1.0);

% Drain startup banner from stage
while LinearStage_motor.NumBytesAvailable > 0
    disp("BOOT >> " + strtrim(readline(LinearStage_motor)));
end

% Drain any startup lines from encoder
while rotaryEncoder.NumBytesAvailable > 0
    disp("ENC BOOT >> " + strtrim(readline(rotaryEncoder)));
end

%% TEST CONDITIONS
t = 1.6;                    % sec
cm_per_step = 0.00467;      % stage calibration
target_speeds = [0.5 1 3 5 7];

target_speeds_steps = target_speeds / cm_per_step;

% Regression parameters (actual = intercept + slope * commanded)
% slope     = 0.6706477469670711;
%intercept = 0.1771377816291162;

slope = 1;
intercept = 0;

% Send commands with these
speeds = (target_speeds - intercept) ./ slope;     % cm/s
%distances = target_speeds * t;                     % cm (FIXED: Separated target distance from scaled speed command)
distances = speeds * t;    
steps_speeds = speeds / cm_per_step;               % steps/s
%steps_acc = steps_speeds;                          % same choice as your test
steps_acc = steps_speeds * 1000;                          % same choice as your test
steps_distances = distances / cm_per_step;         % steps

num_repeats = 5;
num_conditions = numel(steps_speeds);

%% RESULTS
results = repmat(struct( ...
    'repeat',            NaN, ...
    'condition',         NaN, ...
    'target_speed_cm_s', NaN, ...
    'cmd_speed_cm_s',    NaN, ...
    'cmd_distance_cm',   NaN, ...
    'move_time_ms',      NaN, ...
    'enc_move_time_ms',  NaN, ... % Added field for encoder time tracking
    'distance_cm',       NaN, ...
    'distance_steps',    NaN, ...
    'steps_per_sec',     NaN, ...
    'cm_per_sec',        NaN, ...
    'enc_cm_per_sec',    NaN), ...
    num_conditions, num_repeats);

%% TEST LOOP
for r = 1:num_repeats
    fprintf('\n================ REPEAT %d / %d ================\n', r, num_repeats);

    for i = 1:num_conditions
        pause(3);
        fprintf('\n--- Condition %d / %d | Repeat %d / %d ---\n', i, num_conditions, r, num_repeats);
        fprintf('Target speed: %.3f cm/s | Commanded speed: %.3f cm/s | distance: %.3f cm\n', ...
            target_speeds(i), speeds(i), distances(i));

        % Clear stale encoder data and zero encoder
        flushRotaryEncoderBuffer(rotaryEncoder);
        zeroRotaryEncoder(rotaryEncoder);
        pause(0.05);

        % Same stage command pattern that worked in the minimal test
        writeline(LinearStage_motor, "E 0");
        pause(0.1);

        cmd = sprintf("S %d", round(steps_speeds(i)));
        writeline(LinearStage_motor, cmd);
        pause(0.1);

        cmd = sprintf("A %d", round(steps_acc(i)));
        writeline(LinearStage_motor, cmd);
        pause(0.1);

        cmd = sprintf("T %d", -round(steps_distances(i)));   % same sign convention
        writeline(LinearStage_motor, cmd);

        % Read stage result block and encoder samples
        temp = readOneSpeedTestWithEncoder(LinearStage_motor, rotaryEncoder);

        % Store metadata + measurement
        results(i, r).repeat            = r;
        results(i, r).condition         = i;
        results(i, r).target_speed_cm_s = target_speeds(i);
        results(i, r).cmd_speed_cm_s    = speeds(i);
        results(i, r).cmd_distance_cm   = distances(i);
        results(i, r).move_time_ms      = temp.move_time_ms;
        results(i, r).enc_move_time_ms  = temp.enc_move_time_ms; % Captured encoder time
        results(i, r).distance_cm       = temp.distance_cm;
        results(i, r).distance_steps    = temp.distance_steps;
        results(i, r).steps_per_sec     = temp.steps_per_sec;
        results(i, r).cm_per_sec        = temp.cm_per_sec;
        results(i, r).enc_cm_per_sec    = temp.enc_cm_per_sec;

        pause(3);

        % Move back
        cmd = sprintf("M %d", round(steps_distances(i)));
        writeline(LinearStage_motor, cmd);

        fprintf('Stage:   %.3f cm/s | Time: %.1f ms\n', results(i, r).cm_per_sec, results(i, r).move_time_ms);
        fprintf('Encoder: %.3f cm/s | Time: %.1f ms\n', results(i, r).enc_cm_per_sec, results(i, r).enc_move_time_ms);
        pause(0.2);
    end
end

%% RAW MATRICES FOR AVERAGING
recorded_time_ms      = reshape([results.move_time_ms],   num_conditions, num_repeats);
encoder_time_ms       = reshape([results.enc_move_time_ms], num_conditions, num_repeats); % Process encoder time matrix
recorded_distances_cm = reshape([results.distance_cm],    num_conditions, num_repeats);
recorded_speeds_cm    = reshape([results.cm_per_sec],     num_conditions, num_repeats);
encoder_speeds_cm     = reshape([results.enc_cm_per_sec], num_conditions, num_repeats);
recorded_steps_sec    = reshape([results.steps_per_sec],  num_conditions, num_repeats);
recorded_dist_steps   = reshape([results.distance_steps], num_conditions, num_repeats);

%% AVERAGES ACROSS REPEATS
avg_time_ms        = mean(recorded_time_ms,      2, 'omitnan');
avg_enc_time_ms    = mean(encoder_time_ms,       2, 'omitnan'); % Process average encoder time
avg_distance_cm    = mean(recorded_distances_cm, 2, 'omitnan');
avg_speed_cm       = mean(recorded_speeds_cm,    2, 'omitnan');
avg_enc_speed_cm   = mean(encoder_speeds_cm,     2, 'omitnan');
avg_steps_per_sec  = mean(recorded_steps_sec,    2, 'omitnan');
avg_distance_steps = mean(recorded_dist_steps,   2, 'omitnan');

%% RAW TABLE (ALL REPEATS)
Repeat            = reshape(repmat(1:num_repeats, num_conditions, 1), [], 1);
Condition         = reshape(repmat((1:num_conditions)', 1, num_repeats), [], 1);
TargetSpeed_cm_s  = reshape(repmat(target_speeds(:), 1, num_repeats), [], 1);
CmdSpeed_cm_s     = reshape(repmat(speeds(:), 1, num_repeats), [], 1);
CmdDistance_cm    = reshape(repmat(distances(:), 1, num_repeats), [], 1);
MoveTime_ms       = recorded_time_ms(:);
EncoderMoveTime_ms= encoder_time_ms(:); % Added variable to table mapping
StageDistance_cm  = recorded_distances_cm(:);
StageDistance_steps = recorded_dist_steps(:);
StageSpeed_cm_s   = recorded_speeds_cm(:);
StageSpeed_steps_s = recorded_steps_sec(:);
EncoderSpeed_cm_s = encoder_speeds_cm(:);

rawResultsTable = table( ...
    Repeat, ...
    Condition, ...
    TargetSpeed_cm_s, ...
    CmdSpeed_cm_s, ...
    CmdDistance_cm, ...
    MoveTime_ms, ...
    EncoderMoveTime_ms, ... % Table tracking raw encoder time
    StageDistance_cm, ...
    StageDistance_steps, ...
    StageSpeed_cm_s, ...
    StageSpeed_steps_s, ...
    EncoderSpeed_cm_s);

disp(rawResultsTable);

%% AVERAGE TABLE
avgResultsTable = table( ...
    target_speeds(:), ...
    speeds(:), ...
    distances(:), ...
    avg_time_ms, ...
    avg_enc_time_ms, ... % Table tracking average encoder time
    avg_distance_cm, ...
    avg_distance_steps, ...
    avg_speed_cm, ...
    avg_steps_per_sec, ...
    avg_enc_speed_cm, ...
    'VariableNames', { ...
    'TargetSpeed_cm_s', ...
    'CmdSpeed_cm_s', ...
    'CmdDistance_cm', ...
    'AvgMoveTime_ms', ...
    'AvgEncoderMoveTime_ms', ... % Naming the encoder time column
    'AvgStageDistance_cm', ...
    'AvgStageDistance_steps', ...
    'AvgStageSpeed_cm_s', ...
    'AvgStageSpeed_steps_s', ...
    'AvgEncoderSpeed_cm_s'});

disp(avgResultsTable);

%% SAVE CSV FILES
writetable(rawResultsTable, 'ZERO_SCALING_all_repeats.csv');
writetable(avgResultsTable, 'ZERO_SCALING__avg.csv');

%% PLOTS - AVERAGES
figure('Color','w');

subplot(2,1,1);
plot(distances, target_speeds, 'o-', 'LineWidth', 1.5, 'DisplayName', 'Target speed');
hold on;
plot(avg_distance_cm, avg_speed_cm, 'x-', 'LineWidth', 1.5, 'DisplayName', 'Stage average');
plot(avg_distance_cm, avg_enc_speed_cm, 's-', 'LineWidth', 1.5, 'DisplayName', 'Encoder average');
hold off;
xlabel('Distance (cm)');
ylabel('Speed (cm/s)');
title('Average Speed vs Distance (cm)');
legend('Location','best');
grid on;

subplot(2,1,2);
plot(steps_distances, target_speeds_steps, 'o-', 'LineWidth', 1.5, 'DisplayName', 'Target speed');
hold on;
plot(avg_distance_steps, avg_steps_per_sec, 'x-', 'LineWidth', 1.5, 'DisplayName', 'Stage average');
plot(avg_distance_steps, avg_enc_speed_cm ./ cm_per_step, 's-', 'LineWidth', 1.5, 'DisplayName', 'Encoder average');
hold off;
xlabel('Distance (steps)');
ylabel('Speed (steps/s)');
title('Average Speed vs Distance (steps)');
legend('Location','best');
grid on;

% Updated plot tracking both Stage time and Encoder time profiles
figure('Color','w');
plot(speeds, avg_time_ms ./ 1000, 'o-', 'LineWidth', 1.5, 'DisplayName', 'Stage Controller Time');
hold on;
plot(speeds, avg_enc_time_ms ./ 1000, 's--', 'LineWidth', 1.5, 'DisplayName', 'Encoder Measured Time');
hold off;
xlabel('Commanded speed (cm/s)');
ylabel('Average recorded move time (s)');
title('Average recorded arm move times');
legend('Location','best');
grid on;

%% CLEANUP
% clear LinearStage_motor rotaryEncoder

%% ========================= LOCAL FUNCTIONS =========================
function result = readOneSpeedTestWithEncoder(LinearStage_motor, rotaryEncoder)
    result = struct( ...
        'move_time_ms',      NaN, ...
        'enc_move_time_ms',  NaN, ... % Added field for encoder time tracking
        'distance_cm',       NaN, ...
        'distance_steps',    NaN, ...
        'steps_per_sec',     NaN, ...
        'cm_per_sec',        NaN, ...
        'enc_cm_per_sec',    NaN);

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
                break
        end
    end

    pause(0.05);
    encoderSamples = [encoderSamples; readAvailableEncoderSamples(rotaryEncoder)];
    
    % Compute average velocity
    result.enc_cm_per_sec = computeAverageEncoderVelocity(encoderSamples);
    
    % Compute Encoder Total Move Time
    result.enc_move_time_ms = computeEncoderTotalMoveTime(encoderSamples);
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

function avgVel_cm_s = computeAverageEncoderVelocity(encoderSamples)
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

function totalTime_ms = computeEncoderTotalMoveTime(encoderSamples)
    if size(encoderSamples, 1) < 2
        totalTime_ms = NaN;
        return
    end
    
    % Isolates when the position count actually increments or decrements
    counts = encoderSamples(:, 2);
    movingIndices = find(diff(counts) ~= 0);
    
    if isempty(movingIndices)
        totalTime_ms = NaN;
        return
    end
    
    % Determines true delta time between movement initialization and termination
    firstMoveTime = encoderSamples(movingIndices(1), 1);
    lastMoveTime  = encoderSamples(movingIndices(end) + 1, 1);
    
    totalTime_ms = lastMoveTime - firstMoveTime;
end
