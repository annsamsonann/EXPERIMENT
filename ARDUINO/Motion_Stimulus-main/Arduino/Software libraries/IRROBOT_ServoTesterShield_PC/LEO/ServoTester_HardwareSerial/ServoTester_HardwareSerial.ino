#include <IRROBOT_ServoTesterShield.h>
#define APPLICATION_MAX 3

#define ID_MAX 11
#define ID_SELECT_VR  Tester.VR_1    // analog pin used to select the application

IRROBOT_ServoTesterShield Tester(&Serial1);
short position_val;

int Application_num;    // variable to read the value from analog pin used to select the application

void (*List_application[APPLICATION_MAX])(void);
void application_1(void);
void application_2(void);
void application_3(void);

void setup() {
    Tester.begin();  
    Tester.MightyZap.begin(32);  // Data Mode Baudrate set to 57600bps
    Tester.setStep(ID_MAX,0,1023);
    List_application[0]=application_1;
    List_application[1]=application_2;
    List_application[2]=application_3;
   // Serial.begin(9600);    // Monitoring PORT
     
}


void loop() {
  void (*application)(void)=NULL;
  Application_num = 0; 
   application = List_application[0];
(*application)();
  
}

  void application_1(void)
  {
  
#define MANUAL_POSITION_VR  Tester.VR_2 // analog pin used to move the position of stroke when manual mode
#define MIN_STROKE_VR       Tester.VR_3    // analog pin used to set minimum stroke position
#define MAX_STROKE_VR       Tester.VR_4  // analog pin used to set maximum stroke position
#define AUTO_SPEED_VR       Tester.VR_5    // analog pin used to set speed or step when auto mode
#define AUTO_DELAY_VR       Tester.VR_6    // analog pin used to set delay time when auto mode

#define VR_MIN 0
#define VR_MAX 1023

#define VAL_MIN 0
#define VAL_MAX 4095

#define SERVO_MIN 35 //30
#define SERVO_MAX 150 //150

#define IS_AUTO_MODE_ON Tester.MODE_0.isON()
#define IS_CHECK_POSITION_MODE_ON Tester.MODE_1.isON()
#define IS_PATTERN_DIRECTION_ON Tester.MODE_2.isON()

#define IS_PULSE_MANUAL_MODE_ON Tester.MODE_1.isON()

#define ID_NUM 0

unsigned char MightyZap_actID=ID_NUM;
    short Manual_positon_val; // variable to read the value from analog pin used to move the position of stroke when manual mode
    short Min_stroke_val;    // variable to read the value from analog pin used to set minimum stroke position
    short Max_stroke_val;  // variable to read the value from analog pin used to set maximum stroke position
    short Auto_speed_val;    // variable to read the value from analog pin used to set speed or step when auto mode
    short Auto_delay_val;    // variable to read the value from analog pin used to set delay time when auto mode

MightyZap_actID = Tester.readStep(ID_SELECT_VR.read());   // reads the value of the ID (value between 0 and 1023)

 
  Manual_positon_val  = map(MANUAL_POSITION_VR.read(),  VR_MIN, VR_MAX,  VAL_MIN, VAL_MAX);     // reads the value of the position of stroke (value between 0 and 1023)  
  
  Min_stroke_val = map(MIN_STROKE_VR.read(),  VR_MIN, VR_MAX,  VAL_MIN, VAL_MAX);     // reads the value of the minimum stroke position (value between 0 and 1023)
  Max_stroke_val = map(MAX_STROKE_VR.read(),  VR_MIN, VR_MAX,  VAL_MIN, VAL_MAX);   // reads the value of the maximum stroke position (value between 0 and 1023) 
  Auto_speed_val = map(AUTO_SPEED_VR.read(),  VR_MIN, VR_MAX,  VAL_MIN, VAL_MAX);    // reads the value of the speed or step (value between 0 and 1023)
  Auto_delay_val = map(AUTO_DELAY_VR.read(),  VR_MIN, VR_MAX,  VAL_MIN, VAL_MAX);   // reads the value of the delay time (value between 0 and 1023)
 
  int min_stroke_limit, max_stroke_limit, stroke_limit_dir;

  if(Max_stroke_val<Min_stroke_val) //Limit Reverse
  {
    min_stroke_limit=Max_stroke_val;
    max_stroke_limit=Min_stroke_val;
    stroke_limit_dir=1;
  }
  else
  {
    min_stroke_limit=Min_stroke_val;
    max_stroke_limit=Max_stroke_val;
    stroke_limit_dir=0;
  }

  if(IS_AUTO_MODE_ON) 
  {
    static short auto_position_val=min_stroke_limit;
    static short auto_mode_count=0 ,auto_mode_dir=0, auto_mode_in_pose=0,auto_delay_time=0;
    short auto_speed, auto_delay;
      
    auto_speed = map(Auto_speed_val, VAL_MIN, VAL_MAX,  1,  4095);    
    auto_delay = map(Auto_delay_val, VAL_MIN, VAL_MAX,  3,  1000);
    
    if(IS_CHECK_POSITION_MODE_ON)
    {
      short inByte = Tester.MightyZap.readint(ID_NUM,0x86);
      
      if((auto_position_val>(inByte-15))&&(auto_position_val<(inByte+15)))
      {
        auto_mode_in_pose=1;
      }
    }
   
    if(auto_mode_count>=auto_delay_time)
    {
      if(auto_mode_dir)   auto_position_val-=auto_speed;
      else  auto_position_val+=auto_speed;
    
      if(auto_position_val<=min_stroke_limit)
      {
        auto_position_val=min_stroke_limit;
        auto_mode_dir=0;
      }
      else if(auto_position_val>=max_stroke_limit)
      {
        auto_position_val=max_stroke_limit;
        auto_mode_dir=1;
      }
      
      auto_delay_time=auto_delay;
      position_val=auto_position_val;
      
      if( IS_PATTERN_DIRECTION_ON)
      {
        if(stroke_limit_dir)
        {
          if(auto_position_val<=min_stroke_limit)
          {
            auto_position_val=max_stroke_limit;
            auto_mode_dir=1;
              auto_delay_time=auto_delay*3;
          }
        }
        else
        {
          if(auto_position_val>=max_stroke_limit)
          {
            auto_position_val=min_stroke_limit;
            auto_mode_dir=0;
            auto_delay_time=auto_delay*3;
           
          }
        }
      }
      if(IS_CHECK_POSITION_MODE_ON)
      {
          auto_mode_in_pose=0;  
      }
      auto_mode_count=0;
    }
    else
    {
      auto_mode_count++;
      position_val=auto_position_val;
    }
   
    Tester.onLED(); // to indicate that Auto mode is ON
  }
  else
  {
    if(IS_PULSE_MANUAL_MODE_ON)  position_val = Manual_positon_val;   
    else    position_val = map(Manual_positon_val, VAL_MIN, VAL_MAX, min_stroke_limit, max_stroke_limit);
    
    Tester.offLED(); // to indicate that Auto mode is OFF
  }

// Servo Reverse

// Data Port
 Tester.MightyZap.GoalPosition(MightyZap_actID, position_val); //ID 0 MightZap moves to the position 
   
//Pulse Range Scale  
  position_val = map(position_val, VAL_MIN, VAL_MAX, SERVO_MIN, SERVO_MAX);     // scale it to use it with the servo (value between 0 and 180)
  Min_stroke_val = map(Min_stroke_val, VAL_MIN, VAL_MAX, SERVO_MIN, SERVO_MAX);     // scale it to use it with the servo (value between 0 and 180)
  Max_stroke_val = map(Max_stroke_val, VAL_MIN, VAL_MAX, SERVO_MIN, SERVO_MAX);     // scale it to use it with the servo (value between 0 and 180)
  Auto_speed_val = map(Auto_speed_val, VAL_MIN, VAL_MAX, SERVO_MIN, SERVO_MAX);     // scale it to use it with the servo (value between 0 and 180)
  Auto_delay_val = map(Auto_delay_val, VAL_MIN, VAL_MAX, SERVO_MIN, SERVO_MAX);     // scale it to use it with the servo (value between 0 and 180)
  
  Tester.servo_CH1.write(position_val);                  // sets the servo position according to the scaled value
  Tester.servo_CH2.write(Auto_delay_val);                  // sets the servo position according to the scaled value
  Tester.servo_CH3.write(Auto_speed_val);                  // sets the servo position according to the scaled value  
  Tester.servo_CH4.write(Max_stroke_val);                  // sets the servo position according to the scaled value  
  Tester.servo_CH5.write(Min_stroke_val);                  // sets the servo position according to the scaled value
  delay(15);                           // waits for the servo to get there
}

  void application_2(void)
  {
    
  }
  
  void application_3(void)
  {
    
  }