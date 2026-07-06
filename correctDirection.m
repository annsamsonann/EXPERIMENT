%function that rotates the wheel across different angles
% function angle = correctDirection(curArd,curAngle,desiredAngle)    
function [angle, flipSpin] = correctDirection(curArd, curAngle, desiredAngle)
    % % fullRevSteps = 6400;   % your system setting
    % % mtrNum = 1;
    % % 
    % % desiredAngle = -1 * desiredAngle; %making clockwise (negative values), and counterclockwise positive
    % % 
    % % angle = (curAngle - desiredAngle);
    % % if angle < 0
    % %     dirSteps = 0;
    % % else
    % %     dirSteps = 1;
    % % end
    % % steps = round(fullRevSteps / (360 / abs(angle)));
    % % cmd = sprintf("%d %d %d %d\n", 6, mtrNum, dirSteps, steps);
    % % write(curArd, cmd, "string");
    % % pause(.1);
    % 
    % fullRevSteps = 6400; 
    % mtrNum = 1;
    % 
    % % 1. Normalize angle to 0-359
    % normAngle = mod(desiredAngle, 360); 
    % 
    % % 2. Flip Logic (to stay within 0-180 physical arc)
    % if normAngle > 180
    %     target = normAngle - 180; 
    %     flipSpin = -1;            
    % else
    %     target = normAngle;       
    %     flipSpin = 1;             
    % end
    % 
    % 
    % % 3. Calculate trip
    % delta = target - curAngle;
    % 
    % % 4. DIRECTION FIX:
    % % Based on your description, we need to swap these:
    % if delta >= 0
    %     dirSteps = 0; % Change this to 0 if 1 was going the wrong way
    % else
    %     dirSteps = 1; % Change this to 1 if 0 was going the wrong way
    % end
    % 
    % % 5. Move Motor
    % steps = round(abs(delta) * (fullRevSteps / 360));
    % if steps > 0
    %     % Added \n and space formatting for Serial.parseInt()
    %     cmd = sprintf("%d %d %d %d\n", 6, mtrNum, dirSteps, steps);
    %     writeline(curArd, cmd);
    % end
    % 
    % angle = target; 

    % Configuration
    fullRevSteps = 6400; 
    mtrNum = 1;
    
    % 1. Normalize angle to 0-359 range
    normAngle = mod(desiredAngle, 360); 

    % 2. Map angles > 180 back to the upper half (0-180)
    % This forces the cylinder to stay in the top arc and toggles the spin direction.
    if normAngle > 180
        target = normAngle - 180; 
        flipSpin = 1; % Reverse spin for bottom-half targets           
    else
        target = normAngle;       
        flipSpin = -1;  % Normal spin for top-half targets           
    end

    % 3. Calculate relative movement
    delta = target - curAngle;

    % 4. Determine Stepper Direction
    % 0 for clockwise, 1 for counter-clockwise (adjust based on your wiring)
    if delta >= 0
        dirSteps = 0; 
    else
        dirSteps = 1; 
    end

    % 5. Convert angle difference to motor steps
    steps = round(abs(delta) * (fullRevSteps / 360));

    % 6. Send Command to Arduino
    % Added flipSpin as a 5th parameter so the Arduino can set the cylinder direction
    if steps > 0
        cmd = sprintf("%d %d %d %d %d", 6, mtrNum, dirSteps, steps, flipSpin);
        writeline(curArd, cmd);
    end

    % Update the tracked angle to the new target
    angle = target;