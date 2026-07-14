#include <Arduino.h>
#include <SoftwareSerial.h>
#include <HerkulexServo.h>
#include <Servo.h>

#define SERVO_ID_SPEED 11 // Each motor has a code so the herkulex bus can identify which motor to send the command to. 

HerkulexServoBus herkulex_bus(Serial); // this is the transmission line for the herkulex motors. In other words, the bus goes to each motor and tells it which command to run. 
HerkulexServo    servoS(herkulex_bus, SERVO_ID_SPEED); // speed motor

int dirPin_1 = 2; // pin to move Mtr 1 motor CW or CCW
int pulPin_1 = 3; // pin to move Mtr 1 motor

int timeBetweenSteps = 200; // delay between microsteps
// int numSteps = 0; // total number of steps
int angleDirection = 0; // direction of motion to move (1 = CW; 0 = CCW)
int fullRevSteps = 6400; // number of steps for a full revolution 

void setup() {
  // put your setup code here, to run once:
  pinMode(dirPin_1, OUTPUT);
  pinMode(pulPin_1, OUTPUT);

  Serial.begin(115200);
  // Serial1.begin(115200);

  delay(500);
  
  // turn power on
  servoS.setTorqueOn();
  servoS.enableSpeedControlMode();
  servoS.setSpeed(560);
  servoS.setLedColor(HerkulexLed::White);
  
  delay(200);
  servoS.setSpeed(0);
  servoS.setLedColor(HerkulexLed::Off);
  delay(200);
}

void loop() {
  // put your main code here, to run repeatedly:

  if(Serial.available()>0)
  {
    int commandFromMatlab = Serial.parseInt();

    if (commandFromMatlab == 6){
      // Serial.println("Received input"); 
      // delay(1000);
      
      int mtrNum = Serial.parseInt(); 
      int angleDirection = Serial.parseInt();
      int numSteps = Serial.parseInt();

      // numSteps = fullRevSteps / (360 / angle); 

      if (mtrNum == 1){
        if (angleDirection == 1){
          digitalWrite(dirPin_1, LOW); // rotate CCW
        }
        else {
          digitalWrite(dirPin_1, HIGH); // rotate CW
        }

        for (int i = 0; i <= numSteps; i++)
        {
          digitalWrite(pulPin_1, HIGH);
          delayMicroseconds(timeBetweenSteps); 
          digitalWrite(pulPin_1, LOW);
          delayMicroseconds(timeBetweenSteps); 
        }
      }
    }

    else if (commandFromMatlab == 3) { // run motor with duration 
      unsigned long start_millis;

      servoS.setTorqueOn();
      servoS.enableSpeedControlMode();

      int givenSpeed = Serial.parseInt();
      int givenDuration = Serial.parseInt();
      
      servoS.setSpeed(givenSpeed);
      servoS.setLedColor(HerkulexLed::Green);

      start_millis = millis();
      while(millis() - start_millis <= givenDuration);
      servoS.setSpeed(0);
      servoS.setTorqueOff();
      servoS.setLedColor(HerkulexLed::Off);
    }

    else if (commandFromMatlab == 4) { // run motor without duration  

      servoS.setTorqueOn();
      servoS.enableSpeedControlMode();

      int givenSpeed = Serial.parseInt();
      
      servoS.setSpeed(givenSpeed);
      servoS.setLedColor(HerkulexLed::Green);

      if (givenSpeed == 0){
        servoS.setTorqueOff();
        servoS.setLedColor(HerkulexLed::Off);
      }
    }
  }
}