#include <IRROBOT_ServoTesterShield.h>

IRROBOT_ServoTesterShield Tester(&Serial1);
#define APPLICATION_VR      Tester.VR_1 
#define MANUAL_POSITION_VR  Tester.VR_2 
#define MIN_STROKE_VR       Tester.VR_3 
#define MAX_STROKE_VR       Tester.VR_4 
#define SPEED_VR            Tester.VR_5 
#define DELAY_VR            Tester.VR_6 
#define SPEED_VR_MAX        1023

int goal_position,pre_position;
int position_val=0;
int MIN_STROKE_VAL, min_stroke_limit;
int MAX_STROKE_VAL, max_stroke_limit ;
int SPEED_VAL;

void setup() {
  Serial.begin(9600);
  Tester.begin();
}

void loop() {
  //Reads analoge
  MIN_STROKE_VAL = MIN_STROKE_VR.read();
  MAX_STROKE_VAL = MAX_STROKE_VR.read();
  goal_position  = MANUAL_POSITION_VR.read();        
  SPEED_VAL      = SPEED_VR.read(); 
  
  SPEED_VAL = map(SPEED_VAL, 0, 1023, 3, 1023);

  if(goal_position < pre_position) {
    //pre_position -= SPEED_VAL;
    pre_position --;
    if(goal_position > pre_position)
      pre_position=goal_position;
  }else {
    //pre_position += SPEED_VAL;
    pre_position ++;
    if(goal_position < pre_position)
      pre_position=goal_position;
  }
  
  //VR Resverse
  if(MAX_STROKE_VAL<MIN_STROKE_VAL) {
    min_stroke_limit=MAX_STROKE_VAL;
    max_stroke_limit=MIN_STROKE_VAL;
  }else {
    min_stroke_limit=MIN_STROKE_VAL;
    max_stroke_limit=MAX_STROKE_VAL;
  }
  
  // position Limit
  if(pre_position>=max_stroke_limit){
    pre_position = max_stroke_limit;  
  }
  else if(pre_position<=min_stroke_limit){
    pre_position = min_stroke_limit;  
  }
 
  position_val = map(pre_position, 0, 1023, 900, 2100);  
  Tester.servo_CH1.writeMicroseconds(position_val); 
  delay((SPEED_VR_MAX - SPEED_VAL)/100);
}

