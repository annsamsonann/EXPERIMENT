#include <IRROBOT_ServoTesterShield.h>

#define ID_NUM 0

IRROBOT_ServoTesterShield Tester(&Serial1);


void setup() {
  Tester.MightyZap.begin(32);  
}

void loop() {     
  Tester.MightyZap.ledOn(ID_NUM,RED);
  delay(1000);  
  Tester.MightyZap.ledOn(ID_NUM,GREEN);  
  delay(1000);
}
