#include <IRROBOT_ServoTesterShield.h>
#include <MightyZap.h>

#define ID_NUM 0

IRROBOT_ServoTesterShield Tester(&Serial1);

void setup() {
  Serial.begin(9600);    
  Tester.MightyZap.begin(32);  
  while (! Serial);    
}

void loop() 
{     
  if(Serial.available())  {    
    char ch = Serial.read();
    if(ch=='d')    {
      Serial.print("Model Number        : ");  Serial.println((unsigned int)Tester.MightyZap.getModelNumber(ID_NUM));
      Serial.print("Firmware Version    : ");  Serial.println(Tester.MightyZap.Version(ID_NUM)*0.1);           
      Serial.print("Present Temperature : ");  Serial.println(Tester.MightyZap.presentTemperature(ID_NUM));
    }
  }
}
