function angle = correctDirection_forcalibration(curArd,desiredAngle)
    fullRevSteps = 6400; 
    mtrNum = 1;


    % 1. Determine Direction (Based on your Arduino logic: 0=CCW, 1=CW)
    if desiredAngle < 0
        dirSteps = 0;
    else
        dirSteps = 1;
    end
    % 
    % % 1. Determine Direction (Based on your Arduino logic: 1=CCW, 0=CW)
    % if desiredAngle < 0
    %     dirSteps = 1; % Negative = Counter-Clockwise
    % else
    %     dirSteps = 0; % Positive = Clockwise
    % end

    % 2. Calculate Steps based purely on the input amount
    steps = round(abs(desiredAngle) * (fullRevSteps / 360));

    % 3. Send Command
    if steps > 0
        % \n is crucial for Arduino's Serial.parseInt()
        cmd = sprintf("%d %d %d %d\n", 6, mtrNum, dirSteps, steps);
        writeline(curArd, cmd);
    end

    % Configuration
    % fullRevSteps = 6400; 
    % mtrNum = 1;
    % 
    % % 1. Normalize angle to 0-359 range
    % % normAngle = mod(desiredAngle, 360); 
    % % 
    % % 2. Map angles > 180 back to the upper half (0-180)
    % % This forces the cylinder to stay in the top arc and toggles the spin direction.
    % if normAngle > 180
    %     target = normAngle - 180; 
    %     flipSpin = -1; % Reverse spin for bottom-half targets           
    % else
    %     target = normAngle;       
    %     flipSpin = 1;  % Normal spin for top-half targets           
    % end
    % 
    % 3. Calculate relative movement
    % delta = target - curAngle;
    % 
    % 4. Determine Stepper Direction
    % 0 for clockwise, 1 for counter-clockwise (adjust based on your wiring)
    % if delta >= 0
    %     dirSteps = 0; 
    % else
    %     dirSteps = 1; 
    % end
    % 
    % 5. Convert angle difference to motor steps
    % steps = round(abs(delta) * (fullRevSteps / 360));
    % 
    % 6. Send Command to Arduino
    % Added flipSpin as a 5th parameter so the Arduino can set the cylinder direction
    % if steps > 0
    %     cmd = sprintf("%d %d %d %d %d", 6, mtrNum, dirSteps, steps, flipSpin);
    %     writeline(curArd, cmd);
    % end
    % 
    % Update the tracked angle to the new target
    % angle = target;