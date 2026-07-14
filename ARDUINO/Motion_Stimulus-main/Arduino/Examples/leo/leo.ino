#include <IRROBOT_ServoTesterShield.h>
//#include <Utility.h>

#define ID_NUM 0

IRROBOT_ServoTesterShield Tester(&Serial1);

int inPin = 10;
int outPin = 9;
int analogOutPin = A0;
int alreadyRetracted = 0;

void setup() {
  // In mightyZap's documentation 32 == 9600 baud rate, so esentially I am putting the servo shield and the 
  // Serial monitor on the same baud rate
  Tester.MightyZap.begin(32);
  Serial.begin(9600);

  // Testing related variables
  pinMode(inPin, INPUT);
  pinMode(outPin, OUTPUT);
  pinMode(analogOutPin, OUTPUT);
  digitalWrite(outPin, LOW);  
  while (!Serial);
}

void loop() {
  if (Serial.available()) {
    // yes I am talking to you in experiment mode
    int type = Serial.parseInt(); // Shouldn't be a problem due to different Baud Rates
    if(type == 4){
    // EXPERIMENT MODE
    // if information is available as well as there is signal to start from the DAQ

    // communicate that I have received the information
    // so it lets DAQ know that I am active.
    digitalWrite(outPin, HIGH);

    // The packet I recieve is of the following order:
    // [goal position, stay time, retract position]
    int goalPos = Serial.parseInt();
    int internalCommandFromMatlab = 0;
    int period = Serial.parseInt();
    int retractPos = Serial.parseInt();
    
    Tester.MightyZap.GoalPosition(ID_NUM, goalPos);
    Tester.MightyZap.ledOn(ID_NUM, GREEN);

//    delay(150);
//    Serial.print(Tester.MightyZap.Moving(ID_NUM));
    //    Serial.println(Tester.MightyZap.presentOperatingRate(ID_NUM));
//        while (Tester.MightyZap.Moving(ID_NUM)) {
//        Serial.print("!");
//        }

    unsigned long start_millis = millis();
    
    while (millis() - start_millis <= period) {
      analogWrite(A0, Tester.MightyZap.presentPosition(ID_NUM)/4095);
      internalCommandFromMatlab = Serial.parseInt();
      if (internalCommandFromMatlab == 16) {
        int discard = Serial.parseInt();
        Tester.MightyZap.GoalPosition(ID_NUM, retractPos);

        Tester.MightyZap.ledOn(ID_NUM, BLUE);
        alreadyRetracted = 1;
        digitalWrite(outPin, LOW); // Available again
        analogWrite(A0, 0);
        break;
      }
    }
    if (!alreadyRetracted) {
      Tester.MightyZap.GoalPosition(ID_NUM, retractPos);
      digitalWrite(outPin, LOW);
      analogWrite(A0, 0);
    }
    alreadyRetracted = 0;
  }


  
  else if (type == 5){
    Tester.MightyZap.ledOn(ID_NUM, BLUE);
//    Tester.MightyZap.Acceleration(ID_NUM, 2);
//    Tester.MightyZap.Deceleration(ID_NUM, 2);
    // step size of the movement
    int stepAmount = 25;
    // Final position
    int goalPos = Serial.parseInt();
    // current position
    int presPos = Tester.MightyZap.presentPosition(ID_NUM);
    // This is from the documentation
    int estimatePresPos = (presPos + 50) / 100 * 100;

    // amount of movement
    int distance = goalPos - estimatePresPos;
    // number of steps to achieve that movement
    int numSteps = abs(distance) / stepAmount;
    // if the step size is larger than the remaining movement
    int remaining = abs(distance) % stepAmount;
    
    int signOfMovement = ((distance > 0) - (distance < 0));
    int newPos = presPos;
    
    if (signOfMovement > 0){
      digitalWrite(outPin, HIGH);
      delay(5);
      digitalWrite(outPin, LOW);
    }
    
        
    // Putting hard boundaries on the actuator so it does not ever reach its extremes
    if (goalPos >= 500 && goalPos <= 4000) {
        // Moving step by step to the desired location
        for (int ins = 1; ins <= numSteps; ins++){
          if (ins == numSteps){
              newPos = presPos + signOfMovement * stepAmount + signOfMovement * remaining;
          }
          else{
            newPos = presPos + signOfMovement * stepAmount;
          }
          // This is the action code line
          Tester.MightyZap.GoalPosition(ID_NUM, presPos + signOfMovement * stepAmount);
          presPos = newPos;
          delay(ins * 5);
        }
    }
    Tester.MightyZap.ledOn(ID_NUM, GREEN);
    int finalPos = Tester.MightyZap.presentPosition(ID_NUM);
    Serial.println(finalPos);
  }
}
}
