#include <IRROBOT_ServoTesterShield.h>

IRROBOT_ServoTesterShield Tester(&Serial1);
#define APPLICATION_VR      Tester.VR_1 
#define MANUAL_POSITION_VR  Tester.VR_2 
#define MIN_STROKE_VR       Tester.VR_3 
#define MAX_STROKE_VR       Tester.VR_4 
#define SPEED_VR            Tester.VR_5 
#define DELAY_VR            Tester.VR_6 

int position_val;
int MIN_STROKE_VAL, min_stroke_limit;
int MAX_STROKE_VAL, max_stroke_limit ;

void setup() {
  Serial1.begin(9600);
  Tester.begin();
}

void loop() {
  //Reads analoge
  MIN_STROKE_VAL = MIN_STROKE_VR.read();
  MAX_STROKE_VAL = MAX_STROKE_VR.read();
  position_val   = MANUAL_POSITION_VR.read();

  //VR Resverse
  if(MAX_STROKE_VAL<MIN_STROKE_VAL) {
    min_stroke_limit=MAX_STROKE_VAL;
    max_stroke_limit=MIN_STROKE_VAL;
  }else {
    min_stroke_limit=MIN_STROKE_VAL;
    max_stroke_limit=MAX_STROKE_VAL;
  }  
  // position Limit
  if(position_val>=max_stroke_limit)
    position_val = max_stroke_limit;
  else if(position_val<=min_stroke_limit)
    position_val = min_stroke_limit;    
      
  position_val = map(position_val, 0, 1023, 900, 2100);  
  Tester.servo_CH1.writeMicroseconds(position_val); 
  delay(15);  
}



