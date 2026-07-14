/*
 * MightyZap.cpp
 *
 *  Created on: 2016 12. 28.
 *      Author: BG. Shim
 */

#include "Arduino.h"
#include "IRROBOT_ServoTesterShield.h"

//#include <SoftwareSerial.h>

#define SERVO_CH1_PIN 5
#define SERVO_CH2_PIN 6
#define SERVO_CH3_PIN 10
#define SERVO_CH4_PIN 11
#define SERVO_CH5_PIN 3

/*
MightyZap::MightyZap(SoftwareSerial  *dev_serial, int DirectionPin) {
//SoftwareSerial mySerial(receivePin, transmitPin); // RX, TX
}
*/
IRROBOT_ServoTesterShield::~IRROBOT_ServoTesterShield() {
	// TODO Auto-generated destructor stub
}

void IRROBOT_ServoTesterShield::begin(void){


   // initialize the LED pin as an output:
   pinMode(userled_Pin, OUTPUT);
 
   MODE_0.begin();
   MODE_1.begin();
   MODE_2.begin();

 servo_CH1.attach(SERVO_CH1_PIN);  // attaches the servo on any pin  to the servo object
 servo_CH2.attach(SERVO_CH2_PIN);  //
 servo_CH3.attach(SERVO_CH3_PIN);  //
 servo_CH4.attach(SERVO_CH4_PIN);  //
 servo_CH5.attach(SERVO_CH5_PIN);  //

}
void IRROBOT_ServoTesterShield::onLED(void){
	digitalWrite(userled_Pin, LOW);
 }

 void IRROBOT_ServoTesterShield::offLED(void){
	 digitalWrite(userled_Pin, HIGH);
 }

 int IRROBOT_ServoTesterShield::readStep(short val)
 {
 int step;
 step= (unsigned int)((unsigned long)val*this->step_max/ (this->step_value_max-this->step_value_min));
 return step;
 }

 void IRROBOT_ServoTesterShield::setStep(int step_max, short min, short max)
 {
	 this->step_max	=step_max;
	 this->step_value_min	=	min;
	 this->step_value_max	=	max;
	 if( this->step_value_min	== this->step_value_max)
	 {
	  this->step_value_min	=	0;
	  this->step_value_max	=	1023;
	 }
 }