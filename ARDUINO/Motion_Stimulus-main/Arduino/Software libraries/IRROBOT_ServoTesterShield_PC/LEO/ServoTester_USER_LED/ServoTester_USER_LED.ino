#include <IRROBOT_ServoTesterShield.h>

IRROBOT_ServoTesterShield Tester(&Serial1);

void setup() {
  Tester.begin();
}

void loop() {
  Tester.onLED();
  delay(1000);
  Tester.offLED();
  delay(1000);
}



