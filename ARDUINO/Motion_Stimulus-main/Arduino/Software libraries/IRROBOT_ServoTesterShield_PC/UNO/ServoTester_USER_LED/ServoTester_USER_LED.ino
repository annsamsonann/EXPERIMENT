#include <IRROBOT_ServoTesterShield.h>

SoftwareSerial mySerial(8,9);
IRROBOT_ServoTesterShield Tester(&mySerial);

void setup() {
  Tester.begin();
}

void loop() {
  Tester.onLED();
  delay(1000);
  Tester.offLED();
  delay(1000);
}



