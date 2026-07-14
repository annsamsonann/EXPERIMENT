#include <IRROBOT_ServoTesterShield.h>

SoftwareSerial mySerial(8,9);
IRROBOT_ServoTesterShield Tester(&mySerial);

#define APPLICATION_VR      Tester.VR_1 
#define MANUAL_POSITION_VR  Tester.VR_2 
#define MIN_STROKE_VR       Tester.VR_3 
#define MAX_STROKE_VR       Tester.VR_4 
#define SPEED_VR            Tester.VR_5 
#define DELAY_VR            Tester.VR_6 
 
void setup() {
  Serial1.begin(9600);
  Tester.begin();
}

void loop() {
  Serial.print("APPLICATION = ");
  Serial.println(APPLICATION_VR.read());
  Serial.print("MANUAL POSITION = ");
  Serial.println(MANUAL_POSITION_VR.read());
  Serial.print("MIN STROKE= ");
  Serial.println(MIN_STROKE_VR.read());
  Serial.print("MAX STROK = ");
  Serial.println(MAX_STROKE_VR.read());
  Serial.print("SPEED = ");
  Serial.println(SPEED_VR.read());
  Serial.print("DELAY = ");
  Serial.println(DELAY_VR.read());
  Serial.println();
  delay(1000);
}






