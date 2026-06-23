classdef ExpConfig
    properties (Constant)

        cm_per_step          = 0.00467;
        LinStage_range_steps = 3640;
        LinStage_range_cm    = 3640 * 0.00467;        % use literals here

        acc_constant         = 1000;                  % multiply speed by this
        StageMotionDur_sec   = 1.75;
        StimDur_sec          = 1.5;
        stimLag_sec          = 0.25;
        encoderThreshold_cm  = 1;

        max_steps            = 3640;                  % same as LinStage_range_steps
        max_speed_cm         = (3640 * 0.00467) / 1.75;

        fast_target          = 8;                     % cm/sec
        slow_target          = 3;                     % cm/sec

        fast_target_speed_steps = 1713 ; % round(8 / 0.00467);
        slow_target_speed_steps = 214; %round 1 / 0.00467;

        viewDistCm = 71;
        screenWidthCm = 47;
        ballDiamDeg = 1.0;

        ITI = 2; %sec
        %These are the setting to make sure the stage moves to the next
        %start (or start at the beggining of the block) in  under 1.5 sec -
        %to fit in the ITI and blovk start que 
        %expected about 1.22sec for fast target*1.2, 1.5 for the whole
        %stage length (3640) 
        betweenTrialsMotionSpeed_steps = 5000;
        betweenTrialsMotionAcc_steps = 10000;



               %  cm_per_step = 0.00467;
       %  LinStage_range_steps = 3640;
       % % LinStage_range_cm = LinStage_range_steps * cm_per_step ;
       % 
       %  acc_constant = 1000; %multiply speed by this value 
       % 
       %  StageMotionDur_sec = 1.75;  
       %  StimDur_sec = 1.5
       %  stimLag_sec = 0.25
       %  encoderThreshold_cm = 0.05
       % 
       % % max_steps = LinStage_range_cm /cm_per_step; %distance
       % % max_speed_cm = LinStage_range_cm/StageMotionDur_sec; % = 9.7971
       % 
       %  fast_target = 8; %cm/sec
       %  slow_target = 1; %cm/sec
       % 
       % % fast_target_speed_steps = fast_target / cm_per_step;
       % % slow_target_speed_steps = slow_target/ cm_per_step;



    end
end