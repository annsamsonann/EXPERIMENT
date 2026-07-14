// ==========================================
// Rotary Encoder for MATLAB App
// Arduino Mega 2560
//
// Green (A)  -> Pin 18
// White (B)  -> Pin 19
// Yellow (Z) -> Not used
//
// MATLAB serial protocol:
//   Command in : ZERO
//   Data out   : DATA,time_ms,count,distance_cm
//
// Updated calibration from your new measurements:
//   10.00 mm  = -400  counts
//   96.75 mm  = -3861 counts
//   124.34 mm = -4956 counts
//
// Best-fit calibration:
//   1 count ≈ 0.00251 cm
//
// Distance is measured from the current zero position.
// ==========================================

volatile long encoderCount = 0;
long zeroCount = 0;

const byte pinA = 18;
const byte pinB = 19;

// Updated calibration factor
const float cmPerCount = 0.00251f;

void encoderISR();
void handleSerialCommands();

void setup() {
  Serial.begin(115200);

  pinMode(pinA, INPUT_PULLUP);
  pinMode(pinB, INPUT_PULLUP);

  attachInterrupt(digitalPinToInterrupt(pinA), encoderISR, CHANGE);
  attachInterrupt(digitalPinToInterrupt(pinB), encoderISR, CHANGE);

  // Allow signals to settle
  delay(100);

  // Set current position as zero at startup
  noInterrupts();
  zeroCount = encoderCount;
  interrupts();
}

void loop() {
  static long lastRelativeCount = 999999999;

  handleSerialCommands();

  noInterrupts();
  long countNow = encoderCount;
  long zeroNow = zeroCount;
  interrupts();

  long relativeCount = countNow - zeroNow;

  if (relativeCount != lastRelativeCount) {
    float distance_cm = abs(relativeCount) * cmPerCount;

    Serial.print("DATA,");
    Serial.print(millis());
    Serial.print(",");
    Serial.print(relativeCount);
    Serial.print(",");
    Serial.println(distance_cm, 3);

    lastRelativeCount = relativeCount;
  }

  delay(10);
}

void handleSerialCommands() {
  if (Serial.available() <= 0) return;

  String cmd = Serial.readStringUntil('\n');
  cmd.trim();

  if (cmd.equalsIgnoreCase("ZERO")) {
    noInterrupts();
    zeroCount = encoderCount;
    interrupts();

    Serial.print("DATA,");
    Serial.print(millis());
    Serial.print(",");
    Serial.print(0);
    Serial.print(",");
    Serial.println(0.000, 3);
  }
}

void encoderISR() {
  static uint8_t lastState = 0;

  uint8_t A = digitalRead(pinA);
  uint8_t B = digitalRead(pinB);

  uint8_t currentState = (A << 1) | B;
  uint8_t transition = (lastState << 2) | currentState;

  switch (transition) {
    case 0b0001:
    case 0b0111:
    case 0b1110:
    case 0b1000:
      encoderCount++;
      break;

    case 0b0010:
    case 0b0100:
    case 0b1101:
    case 0b1011:
      encoderCount--;
      break;
  }

  lastState = currentState;
}