function [trialRow] = runTrial(app, windowPtr, trialRow, flipSpeed, expTime_start) 
    speedCmSec = trialRow.Arm_Mov_Speed;
    speedArduino = trialRow.Arm_Mov_Speed_arduino;
    accArduino = trialRow.Arm_Mov_Acc_arduino;
    stepsArduino = trialRow.Arm_Mov_Steps_arduino;
    [moveDir, speedStr, no_motion_flag] = getTrialInfo(app,stepsArduino,speedArduino);
    

end