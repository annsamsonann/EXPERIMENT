#include <IRROBOT_ServoTesterShield.h>

IRROBOT_ServoTesterShield Tester(&Serial1);

int Position;

void setup() {
  Tester.begin();
}

void loop() {
  for(Position = 900 ; Position <= 2100 ; Position += 1)
  {
    Tester.servo_CH1.writeMicroseconds(Position);
    delay(3);
  }
	delay(3600);
  for(Position = 2100 ; Position >= 900 ; Position -= 1)
  {
    Tester.servo_CH1.writeMicroseconds(Position);
    delay(3);
  }
	 delay(3600);
}

















