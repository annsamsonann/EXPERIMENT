#include <IRROBOT_ServoTesterShield.h>

SoftwareSerial mySerial(8,9);
IRROBOT_ServoTesterShield Tester(&mySerial);

void setup() {
  Serial1.begin(9600);
  Tester.begin();
}

void loop() {
  Serial.print("MODE0 = ");
  Serial.println(Tester.MODE_0.read());
  Serial.print("MODE1 = ");
  Serial.println(Tester.MODE_1.read());
  Serial.print("MODE2 = ");
  Serial.println(Tester.MODE_2.read());
  Serial.println();
  delay(1000);
}




