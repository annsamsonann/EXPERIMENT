classdef ExpConfig
    properties (Constant)

        cm_per_step          = 0.00467;
        LinStage_range_steps = 3634;
        LinStage_range_cm    = 3634 * 0.00467;        % use literals here

        acc_constant         = 1000;                  % multiply speed by this
        StageMotionDur_sec   = 1.75;
        StimDur_sec          = 1.5;
        stimLag_sec          = 0.25;
        encoderThreshold_cm  = 1;

        max_steps            = 3634;                  % same as LinStage_range_steps
        max_speed_cm         = (3634 * 0.00467) / 1.75; % if restricted by 1.75 sec duration 

        fast_target          = 8;                     % cm/sec
        slow_target          = 3;                     % cm/sec

        fast_target_speed_steps = 1713 ; % round(8 / 0.00467);
        slow_target_speed_steps = 642; % 214 steps for round 1cm/sec / 0.00467;

        ITI = 2; 
        viewDistCm = 71;
        screenWidthCm = 47;
        ballDiamDeg = 1.0;
        padCm = 0;
        %sec
        %These are the setting to make sure the stage moves to the next
        %start (or start at the beggining of the block) in  under 1.5 sec -
        %to fit in the ITI and blovk start que 
        %expected about 1.22sec for fast target*1.2, 1.5 for the whole
        %stage length (3640) 
        betweenTrialsMotionSpeed_steps = 5000;
        betweenTrialsMotionAcc_steps = 10000;



    end
end