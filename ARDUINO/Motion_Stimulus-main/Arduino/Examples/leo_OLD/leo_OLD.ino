#include <IRROBOT_ServoTesterShield.h>

IRROBOT_ServoTesterShield Tester(&Serial1);
int armHome = 900; 

void setup() {
  // In mightyZap's documentation 32 == 9600 baud rate, so esentially I am putting the servo shield and the 
  // Serial monitor on the same baud rate
  Serial.begin(9600);

  Tester.begin();
  Tester.servo_CH1.writeMicroseconds(armHome);
}

void loop() {
  // put your main code here, to run repeatedly:
  if (Serial.available()) {
    int type = Serial.parseInt();

    if (type == 1){
      int goalPos = Serial.parseInt();
      Tester.servo_CH1.writeMicroseconds(goalPos); 
    }
    else if (type == 2){ // experiment mode 
      int currentPos = Serial.parseInt(); //current position 
      int goalPos = Serial.parseInt(); // goal position 
      int duration = Serial.parseInt(); // in ms
      
      int stepAmount = 25;
      int distance = goalPos - currentPos; 
      int numSteps = abs(distance) / stepAmount; 
      int remaining = abs(distance) % stepAmount;

      int signOfMovement = ((distance > 0) - (distance < 0));
      int newPos = currentPos; 
      int originalPos = currentPos; 

      if (goalPos >= 900 && goalPos <= 2100) {
        //Move step by step to desired location
        for (int ins = 1; ins <= numSteps; ins++){
          if (ins == numSteps){
            newPos = currentPos + signOfMovement * stepAmount + signOfMovement * remaining;
          }
          else{
            newPos = currentPos + signOfMovement * stepAmount;
          }
          Tester.servo_CH1.writeMicroseconds(newPos);
          currentPos = newPos;
          delay(ins*10); 
        }
      }

      unsigned long start_millis = millis();
      while (millis() - start_millis <= duration);
      
      goalPos = originalPos; 
      distance = goalPos - currentPos; 
      numSteps = abs(distance) / stepAmount; 
      remaining = abs(distance) % stepAmount;
      signOfMovement = ((distance > 0) - (distance < 0));
      newPos = currentPos; 

      if (goalPos >= 900 && goalPos <= 2100) {
        //Move step by step to desired location
        for (int ins = 1; ins <= numSteps; ins++){
          if (ins == numSteps){
            newPos = currentPos + signOfMovement * stepAmount + signOfMovement * remaining;
          }
          else{
            newPos = currentPos + signOfMovement * stepAmount;
          }
          Tester.servo_CH1.writeMicroseconds(newPos);
          currentPos = newPos;
          delay(ins*10); 
        }
      }
    }
  }
  delay(0); 
}
