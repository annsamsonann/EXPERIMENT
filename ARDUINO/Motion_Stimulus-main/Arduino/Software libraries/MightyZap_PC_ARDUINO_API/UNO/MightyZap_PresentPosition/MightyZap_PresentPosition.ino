#include <MightyZap.h>
#define ID_NUM 0

SoftwareSerial mySerial(8,9);
MightyZap m_zap(&mySerial,2);

int Position;
int cPosition;
int Display =1;

void setup() {
  Serial.begin(9600);    
  m_zap.begin(32);  
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

    m_zap.GoalPosition(ID_NUM,Position);
    delay(150);
    while(m_zap.presentOperatingRate(ID_NUM)) {
      cPosition = m_zap.presentPosition(ID_NUM);
      Serial.print("  - Position : ");
      Serial.println(cPosition);
    }   
    delay(200);
    cPosition = m_zap.presentPosition(ID_NUM);
    Serial.print("  - final Position : ");
    Serial.println(cPosition);
    Display = 1;
  }  
}
