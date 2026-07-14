#include <IRROBOT_ServoTesterShield.h>
#define MANUAL_POSITION_VR  Tester.VR_2 

IRROBOT_ServoTesterShield Tester(&Serial1);

int Manual_positon_val;

void setup() {
  Tester.begin();
}

void loop() {
  Manual_positon_val = MANUAL_POSITION_VR.read();
  Manual_positon_val = map(Manual_positon_val, 0, 1023, 900, 2100);
  Tester.servo_CH1.writeMicroseconds(Manual_positon_val);         
  delay(15);                          
}



