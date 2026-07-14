/*
 * Mightyzap.h
 *
 * Created: 2017-02-21 오전 11:26:49
 *  Author: Shim
 */ 

#ifndef IRROBOT_ServoTesterShield_H_
#define IRROBOT_ServoTesterShield_H_

#include <MightyZap.h>
#include <Servo.h>
#include "utility/VR.h"
#include "utility/MODE_SW.h"
#include "utility/STEP_VR.h"

#define DATA_ENABLE_PIN 2

#define MODE0_PIN 4
#define MODE1_PIN 7
#define MODE2_PIN 12

class IRROBOT_ServoTesterShield {
public:
	IRROBOT_ServoTesterShield();
	IRROBOT_ServoTesterShield(HardwareSerial  *dev_serial)
	:MightyZap(dev_serial,DATA_ENABLE_PIN),
	VR_1(A0),	VR_2(A1),	VR_3(A2),	VR_4(A3),	VR_5(A4),	VR_6(A5),
	MODE_0(MODE0_PIN),	MODE_1(MODE1_PIN),	MODE_2(MODE2_PIN){};

	IRROBOT_ServoTesterShield(SoftwareSerial  *dev_serial)
	:MightyZap(dev_serial,DATA_ENABLE_PIN),
	VR_1(A0),	VR_2(A1),	VR_3(A2),	VR_4(A3),	VR_5(A4),	VR_6(A5),
	MODE_0(MODE0_PIN),	MODE_1(MODE1_PIN),	MODE_2(MODE2_PIN){};

	//IRROBOT_ServoTesterShield(SoftwareSerial  *dev_serial, int DirectionPin);
	virtual ~IRROBOT_ServoTesterShield();
	void begin(void);
	void onLED(void);
	void offLED(void);
	void setStep(int step_max, short min, short max);
	int readStep(short val);

	const int userled_Pin =  13;      // the number of the LED pin
	int step_max;
	short step_value_min;
	short step_value_max;

	VR VR_1;
	VR VR_2;
	VR VR_3;
	VR VR_4;
	VR VR_5;
	VR VR_6;

	MODE_SW MODE_0;
	MODE_SW MODE_1;
	MODE_SW MODE_2;

	Mightyzap MightyZap;

	Servo servo_CH1;  // create servo object to control a servo channel #1
	Servo servo_CH2;  // create servo object to control a servo channel #2
	Servo servo_CH3;  // create servo object to control a servo channel #3
	Servo servo_CH4;  // create servo object to control a servo channel #4
	Servo servo_CH5;  // create servo object to control a servo channel #5

private:


};


#endif /* IRROBOT_ServoTesterShield_H_ */
