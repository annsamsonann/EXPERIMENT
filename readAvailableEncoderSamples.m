
function samples = readAvailableEncoderSamples(app)
samples = [];

if isempty(app.rotaryEncoder)
    return
end

while app.rotaryEncoder.NumBytesAvailable > 0
    line = strtrim(readline(app.rotaryEncoder));
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
