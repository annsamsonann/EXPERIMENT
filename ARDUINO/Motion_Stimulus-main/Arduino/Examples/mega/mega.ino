#include <Arduino.h>
#include <SoftwareSerial.h>
#include <HerkulexServo.h>
#include <Servo.h>

#define SERVO_ID_SPEED 11 // Each motor has a code so the herkulex bus can identify which motor to send the command to. 
#define SERVO_ID_ROTATION 10
#define SERVO_ID_ROTATION_FOR_SPEED_TEST 12 // not in use
#define digitalPulseOutputPin 49 // not in use

HerkulexServoBus herkulex_bus(Serial1); // this is the transmission line for the herkulex motors. In other words, the bus goes to each motor and tells it which command to run. 
HerkulexServo    servoS(herkulex_bus, SERVO_ID_SPEED); // speed motor
HerkulexServo    servoR(herkulex_bus, SERVO_ID_ROTATION); // rotation motor
HerkulexServo    servoRS(herkulex_bus, SERVO_ID_ROTATION_FOR_SPEED_TEST); // not in use

uint16_t evaluatePos (int);

// Each serial packet consists of two commands: motor_type, motor_action

// motor_type:
// 1. Speed Motor: [1, -1023-+1024] SpeedControlMode
// 2. Rotation Motor [2, -pi/2 - pi/2] enablePositionControlMode

void setup() {
  Serial.begin(115200);
  Serial1.begin(115200);

  delay(500);
  
  // turn power on
  servoS.setTorqueOn();
  servoR.setTorqueOn();
  servoRS.setTorqueOn();
  servoS.enableSpeedControlMode();
  servoS.setSpeed(560);
  servoS.setLedColor(HerkulexLed::White);
  
  delay(200);
  servoS.setSpeed(0);
  servoS.setLedColor(HerkulexLed::Off);
  delay(200);

  servoR.setPosition(evaluatePos(30), 30, HerkulexLed::Blue);
  delay(200);
  servoR.setPosition(evaluatePos(0), 30, HerkulexLed::Off);
  delay(200);
  
  // for the test motor
  servoRS.setPosition(evaluatePos(30), 30, HerkulexLed::Blue);
  delay(200);
  servoRS.setPosition(evaluatePos(0), 30, HerkulexLed::Off);
  delay(200);

  // NO PIN OUTPUT CURRENTLY, discard lines below
  pinMode(digitalPulseOutputPin,OUTPUT);
  digitalWrite(digitalPulseOutputPin,LOW);
}


void loop() {
  
  if(Serial.available()>0)
  
    {
      int commandFromMatlab = Serial.parseInt();
  
      if (commandFromMatlab == 1) {
        // It's the speed Control Motor
        servoS.setTorqueOn();
        servoS.enableSpeedControlMode();
        int givenSpeed = Serial.parseInt();
        // This line of code below assigns the speed of the motor. 
        servoS.setSpeed(givenSpeed);
        
        int duration = Serial.parseInt();
        delay(duration);
        
        if (givenSpeed == 0){
          servoS.setTorqueOff();
          servoS.setLedColor(HerkulexLed::Off);
        }
        else{
          servoS.setLedColor(HerkulexLed::Green);
        }
        
        delay(50);
      }

//      else if (commandFromMatlab == 3) {
//        // It's the Speed Test Motor -- supposed to behave like a rotation motor
//        //
//        servoRS.setTorqueOn();
//        int pos_degree = Serial.parseFloat();
//        int newServoPosition = evaluatePos(pos_degree);
//        
//        int currentServoPosition = servoRS.getPosition();
//
//        int playtime = currentServoPosition > newServoPosition ? (int)((currentServoPosition - newServoPosition)*0.2) : (int)((newServoPosition - currentServoPosition)*0.2);
//
//        servoRS.setPosition(newServoPosition, playtime, HerkulexLed::Off); 
//        herkulex_bus.update();
//        delay(50);
//        //NOTE? Check if playtime is required, aim is to have minimum playtime
////        servoR.setTorqueOff();
//      }


      else if (commandFromMatlab == 2) {
        // It's the RotationMotor
        servoR.setTorqueOn();
        int toPosDegree = Serial.parseInt();
        int fromServoPosition = servoR.getPosition();
        float fromPosDeg = evaluateDegreeFromPos(fromServoPosition);
        int toServoPosition = evaluatePos(toPosDegree);
        
//        Serial.print("Starting from: ");
//        Serial.println(fromPosDeg);  
//        Serial.print("Going to:");
//        Serial.println(toPosDegree);
//        int rotShift = fromServoPosition > toServoPosition ? (int)(fromServoPosition - toServoPosition) : (int)(toServoPosition - fromServoPosition);
//        float calcFromPosDeg = evaluateDegreeFromPos(fromServoPosition);
//        float calcToPosDeg = evaluateDegreeFromPos(toServoPosition);
//        Serial.print("Total CALCULATED Degree displacement: ");
//        Serial.println(calcToPosDeg - calcFromPosDeg);


        // This piece of code determines the amount of time it takes the motor to move from its current position (fromPosDeg) to its final position
        // (toPosDegree). This way, the motor does not jerk too hard when rotating between big rotations.        
        int time_ms_per_degree = 5;
        float absRotShiftDeg = (fromPosDeg > toPosDegree) ? (fromPosDeg - toPosDegree): (toPosDegree - fromPosDeg);
        uint8_t totalTimeMS = (uint8_t)(time_ms_per_degree * absRotShiftDeg);
        uint8_t playtime = evaluatePlaytime(totalTimeMS);
        
//        Serial.print("Playtime in Herkulex units: ");
//        Serial.println(playtime);
        
        
        // THIS IS THE ACTION PIECE OF CODE -- setting the new position of the rotation motor
        
        servoR.setPosition(toServoPosition, playtime, HerkulexLed::Off); 
        herkulex_bus.update();
        delay(totalTimeMS);
        
//        Serial.print("Total MS Delay: ");    
//        Serial.println(totalTimeMS);
        //NOTE? Check if playtime is required, aim is to have minimum playtime
//        servoR.setTorqueOff();
      }

       else if (commandFromMatlab == 18) 
       {
        unsigned long start_millis;
        
        servoS.setTorqueOn();
        servoS.enableSpeedControlMode();
        
        int givenSpeed = Serial.parseInt();
        int givenDuration = Serial.parseInt();
        servoS.setSpeed(givenSpeed);
        servoS.setLedColor(HerkulexLed::Green);

        bool interrupted = false;
 
        start_millis = millis();
        while(millis() - start_millis <= givenDuration);
        servoS.setSpeed(0);
        servoS.setTorqueOff();
       }
      else if (commandFromMatlab == 19) {
        Serial.println("Hello from Arduino Test");
      }

    }

    herkulex_bus.update();
}

uint16_t evaluatePos (int pos_degree) {
  uint16_t pos = 512 + uint16_t(pos_degree / 0.325f);
  return pos;
}

float evaluateDegreeFromPos (uint16_t pos_servo){
  float pos_degree = (float)((float)pos_servo - 512) * 0.325f;
  return pos_degree;
}

uint8_t evaluatePlaytime (uint8_t time_ms){
  uint8_t playtime = uint8_t(time_ms / 11.2f);
  return playtime;
}
