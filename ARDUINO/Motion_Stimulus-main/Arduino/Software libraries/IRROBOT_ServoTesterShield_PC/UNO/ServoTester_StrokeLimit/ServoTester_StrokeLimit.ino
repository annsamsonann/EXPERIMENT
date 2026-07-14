#include <IRROBOT_ServoTesterShield.h>

#define ID_NUM 0

SoftwareSerial mySerial(8,9);
IRROBOT_ServoTesterShield Tester(&mySerial);

void setup() {
  Tester.MightyZap.begin(32);  
}

void loop() {     
  Tester.MightyZap.LongStrokeLimit(ID_NUM,4095);  
  Tester.MightyZap.GoalPosition(ID_NUM,4095);      
  delay(5000);
   
  Tester.MightyZap.ShortStrokeLimit(ID_NUM,0);  
  Tester.MightyZap.GoalPosition(ID_NUM,0);         
  delay(5000);   
}
