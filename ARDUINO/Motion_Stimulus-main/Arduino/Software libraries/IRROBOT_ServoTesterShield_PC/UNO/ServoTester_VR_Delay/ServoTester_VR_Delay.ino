#include <IRROBOT_ServoTesterShield.h>

SoftwareSerial mySerial(8,9);
IRROBOT_ServoTesterShield Tester(&mySerial);

#define APPLICATION_VR      Tester.VR_1 
#define MANUAL_POSITION_VR  Tester.VR_2 
#define MIN_STROKE_VR       Tester.VR_3 
#define MAX_STROKE_VR       Tester.VR_4 
#define SPEED_VR            Tester.VR_5 
#define DELAY_VR            Tester.VR_6 

#define SPEED_VR_MAX        1023

int DELAY_val,DELAY_cnt;
int pre_position;
int position_val=0;
int MIN_STROKE_VAL, min_stroke_limit;
int MAX_STROKE_VAL, max_stroke_limit ;
int Direction=0;
int SPEED_VAL;
void setup() {
  Serial.begin(9600);
  Tester.begin();
  pre_position=900;
}

void loop() {
  //Reads analoge
  MIN_STROKE_VAL = MIN_STROKE_VR.read();
  MAX_STROKE_VAL = MAX_STROKE_VR.read();
  //goal_position  = MANUAL_POSITION_VR.read();
  SPEED_VAL      = SPEED_VR.read(); 
  DELAY_val      = DELAY_VR.read();
  
  SPEED_VAL = map(SPEED_VAL, 0, 1023, 3, 1023);  
  DELAY_val = map(DELAY_val, 0, 1023, 0, 3000);

  if(DELAY_cnt>DELAY_val){
    DELAY_cnt=0;
    
    if(Direction ==1) {
      Direction=0;
    }else {
      Direction=1;
    }
  }else {
    DELAY_cnt++;
  }

  if(Direction ==1) {
      pre_position --;
      if(pre_position<0)pre_position=0;
    }else {
      pre_position ++;
      if(pre_position>1023)pre_position=1023;
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
