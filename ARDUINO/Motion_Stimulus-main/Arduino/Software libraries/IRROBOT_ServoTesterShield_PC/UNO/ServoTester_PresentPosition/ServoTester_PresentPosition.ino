#include <IRROBOT_ServoTesterShield.h>

#define ID_NUM 0

SoftwareSerial mySerial(8,9);
IRROBOT_ServoTesterShield Tester(&mySerial);

int Position;
int cPosition;
int Display =1;


void setup() {
  Serial.begin(9600);  
  Tester.MightyZap.begin(32);  
  while (! Serial);
}

void loop() {     
  if(Display == 1){
    Serial.print("*New Position[0~4095] : ");
    Display = 0;
  }
  if(Serial.available())  {
    Position = Serial.parseInt(); 
    Serial.println(Position);    
    delay(200);

    Tester.MightyZap.GoalPosition(ID_NUM,Position);
    delay(150);
    while(Tester.MightyZap.presentOperatingRate(ID_NUM)) {
      cPosition = Tester.MightyZap.presentPosition(ID_NUM);
      Serial.print("  - Position : ");
      Serial.println(cPosition);
    }   
    delay(50);
    cPosition = Tester.MightyZap.presentPosition(ID_NUM);
    Serial.print("  - final Position : ");
    Serial.println(cPosition);
    Display = 1;
  }  
}
