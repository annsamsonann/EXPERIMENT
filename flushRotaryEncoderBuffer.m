    function flushRotaryEncoderBuffer(app)
        % Helper function to clear any unread encoder bytes from the serial buffer.
        % This prevents stale lines from a previous trial from being used in the new trial.
        if ~isempty(app.rotaryEncoder) && app.rotaryEncoder.NumBytesAvailable > 0
            read(app.rotaryEncoder, app.rotaryEncoder.NumBytesAvailable, "char");
        end
    end
    