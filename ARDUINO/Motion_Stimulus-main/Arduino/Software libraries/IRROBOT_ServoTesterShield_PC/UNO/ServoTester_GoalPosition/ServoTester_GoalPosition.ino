#include <IRROBOT_ServoTesterShield.h>

#define ID_NUM 0

SoftwareSerial mySerial(8,9);
IRROBOT_ServoTesterShield Tester(&mySerial);

int ForceLimit;

void setup() {
  Tester.MightyZap.begin(32);  
}

void loop() {     
  Tester.MightyZap.GoalPosition(ID_NUM, 0); //ID 0 MightZap moves to position 0
  delay(3000);
  Tester.MightyZap.GoalPosition(ID_NUM, 4095);//ID 0 MightZap moves to position 4095
  delay(3000);
}
