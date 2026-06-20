#include <AccelStepper.h>

// ===== Pin Definitions =====
const int stepPin = 9;
const int dirPin  = 8;
const int mfPin   = 10;

// ===== Stepper Setup =====
AccelStepper stepper(AccelStepper::DRIVER, stepPin, dirPin);

// ===== Motion Parameters =====
float maxSpeed = 1000.0;       // steps/s
float acceleration = 500.0;    // steps/s^2

unsigned long moveStartTimeMs = 0;

bool isMoving = false;
bool motorFree = false;        // false = engaged, true = free

// ===== Calibration =====
const float cmPerStep = 0.00467;

// ===== Speed Test State =====
bool speedTestActive = false;
long speedTestSteps = 0;

// =====================================================
// Motor enable/free
// =====================================================
void setMotorEngaged(bool engaged) {
  if (engaged) {
    digitalWrite(mfPin, LOW);   
    motorFree = false;
  } else {
    digitalWrite(mfPin, HIGH);  
    motorFree = true;
  }
}

// =====================================================
// Setup
// =====================================================
void setup() {
  pinMode(mfPin, OUTPUT);
  setMotorEngaged(true);

  Serial.begin(115200);
  Serial.setTimeout(50);

  // Configure native library instances
  stepper.setMaxSpeed(maxSpeed);
  stepper.setAcceleration(acceleration);

  Serial.println("Motor 3 X-axis Ready");
  Serial.println("Commands:");
  Serial.println("S <speed_steps_per_s>");
  Serial.println("A <accel_steps_per_s2>");
  Serial.println("M <relative_steps>");
  Serial.println("T <relative_steps>");
  Serial.println("P");
  Serial.println("Z");
  Serial.println("E 1");
  Serial.println("E 0");
}

// =====================================================
// Main loop
// =====================================================
void loop() {
  handleSerial();
  updateMotor();
}

// =====================================================
// Motion update
// =====================================================
void updateMotor() {
  if (motorFree) {
    return;
  }

  // Native AccelStepper execution call (Must run continuously in loop)
  stepper.run();

  // Check if a running movement just finished running out of steps
  if (isMoving && !stepper.isRunning()) {
    unsigned long moveTime = millis() - moveStartTimeMs;

    if (speedTestActive && moveTime > 0) {
      float moveTime_s = moveTime / 1000.0;
      float actualStepsPerSec = abs(speedTestSteps) / moveTime_s;
      float totalDistance_cm = abs(speedTestSteps) * cmPerStep;
      float avgCmPerSec = totalDistance_cm / moveTime_s;
      
      Serial.println("100,test_begin,0");
      Serial.print("101,move_time_ms,");
      Serial.println(moveTime);
      Serial.print("102,distance_cm,");  
      Serial.println(totalDistance_cm, 4);
      Serial.print("103,steps,");      
      Serial.println(speedTestSteps);
      Serial.print("104,steps_per_sec,");
      Serial.println(actualStepsPerSec, 3);
      Serial.print("105,cm_per_sec,");
      Serial.println(avgCmPerSec, 3);
      Serial.println("199,test_end,0");
    }

    speedTestActive = false;
    isMoving = false;
  }
}

// =====================================================
// Serial command handling
// =====================================================
void handleSerial() {
  if (!Serial.available()) return;

  char cmd = Serial.read();

  if (cmd == 'S') {
    maxSpeed = Serial.parseFloat();
    stepper.setMaxSpeed(maxSpeed);
  }

  else if (cmd == 'A') {
    acceleration = Serial.parseFloat();
    stepper.setAcceleration(acceleration);
  }

  else if (cmd == 'M') {
    long steps = Serial.parseInt();
    moveStartTimeMs = millis();
    isMoving = true;
    speedTestActive = false;
    
    // Command relative motion using library methods
    stepper.move(steps); 
  }

  else if (cmd == 'T') {
    long steps = Serial.parseInt();
    moveStartTimeMs = millis();
    isMoving = true;
    speedTestActive = true;
    speedTestSteps = steps;

    Serial.print("Speed test steps ");
    Serial.println(steps);
    
    // Command relative motion using library methods
    stepper.move(steps); 
  }

  else if (cmd == 'E') {
    int val = Serial.parseInt();
    if (val == 1) {
      setMotorEngaged(false);
      stepper.disableOutputs(); // Safe library shutdown
    } else {
      setMotorEngaged(true);
    }
  }

  while (Serial.available()) {
    Serial.read();
  }
}
