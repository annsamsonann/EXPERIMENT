clear all; close all; clc

allDirections = [0 45 75 85 90 95 105 135 180 225 255 265 270 275 285 315];
allPostures = [15 53 90];
allArmSpeeds = [0 2.93 7.44];
taskType = 'PASSIVE';
prefix1 = 'TG_Motion_Direction_ElbowPosture_';
prefix2 = '_pair_';
prefix3 = '_block_';
prefix4 = '_behavior';

subjID = 'TG';
parDir = 'C:\Users\ramirezlab\Desktop\motion_experiment_clean\SUBJECTS\';

parDir = [parDir subjID '\' subjID '_data\'];
theFiles = dir(parDir);
theFiles = {theFiles.name}';

psychData = zeros(length(allDirections), length(allPostures), length(allArmSpeeds));
psychData_count = psychData;
y = 0;

countTrials = 0;

for pp = 1 : length(allPostures)

    for ff = 1 : length(theFiles)
        tmpName = theFiles{ff};
        
        if strfind(tmpName,['ElbowPosture_' num2str(allPostures(pp))]) & ...
                strfind(tmpName,taskType) %load file
            load([parDir tmpName]);

            
            %experimentTrial_Matrix.Arm_Mov_Speed = round(experimentTrial_Matrix.Arm_Mov_Speed .* 100)/100;
            allArmSpeeds = unique(experimentTrial_Matrix.Arm_Mov_Speed);
        
            countTrials = countTrials + size(experimentTrial_Matrix,1);
            for ss = 1 : length(allArmSpeeds) 

                for dd = 1 : length(allDirections)

                    curTrials = find(experimentTrial_Matrix.StimDirection == allDirections(dd) & ...
                        experimentTrial_Matrix.Arm_Mov_Speed == allArmSpeeds(ss));
                    respTrials = experimentTrial_Matrix.Response(curTrials);
                    respTrials(find(respTrials == 3)) = 0;

                    psychData(dd,pp,ss) = psychData(dd,pp,ss) + sum(respTrials);
                    psychData_count(dd,pp,ss) = psychData_count(dd,pp,ss) + length(curTrials);
                end
            end
        else
        end
    end    
end
    

% dirTrials = [];
% armSpeedTrials = [];
% handPostureTrials = [];
% 
% dirTrials = experimentTrial_Matrix.StimDirection;
% armSpeedTrials = round(experimentTrial_Matrix.Arm_Mov_Speed,2);
% handPostureTrials = experimentTrial_Matrix.HandPosture;
