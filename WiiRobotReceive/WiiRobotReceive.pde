/*
    Program to control the two wheeled robot with the joystick or the accelerometer of the nunchuk.
*/ 

// Using the servo library
#include <Servo.h>        

//------------------- Constants / Defines -------------------

// LED Pin assignments.
const int LED_PIN_FRONT = 8;
const int LED_PIN_BACK = 9;
const int LED_PIN_LEFT = 10;
const int LED_PIN_RIGHT = 11;

#define SERIAL_DATA_SPEED_38400_BPS  (38400)

//------------------- Global Variables ------------------- 

/*
    Since dc motors are controlled with a parallax motor controller
    they will be given servo signals
*/
Servo leftMotor;
Servo rightMotor;

// Variable to store the Motor speed values.
int rightMotorVal;
int leftMotorVal;

// Data read variable
int incomingByte;

// LED variables
int count = 0;

//------------------- Functions -------------------

/*------
    Function: setup
    Description: Arduino setup hook, called once before the calls to loop() start.
*/
void setup()
{
    // Setup LED pins
    pinMode (LED_PIN_FRONT, OUTPUT);
    pinMode (LED_PIN_BACK, OUTPUT);
    pinMode (LED_PIN_LEFT, OUTPUT);
    pinMode (LED_PIN_RIGHT, OUTPUT);
    
    // Start Serial Communication
    Serial.begin(SERIAL_DATA_SPEED_38400_BPS);
    
    // Attach the left motor to  pin 5, right motor pin 4
    leftMotor.attach (5);      
    rightMotor.attach(4);
}

/*------
    Function: loop
    Description: Arduino main loop, called over and over again... forever...
*/
void loop()
{
    // are there any bytes available on the serial port??
    if (Serial.available())
    {
        // assign bytes to the variable incomingByte
        incomingByte = Serial.read();
        
        if (incomingByte == 254)
        {
            leftMotorVal = Serial.read();
        }
        else if (incomingByte == 255)
        {
            rightMotorVal = Serial.read();
        }
    }
    
    // All stop command?
    if (leftMotorVal == 90 && rightMotorVal == 90) blinkLED();
    
    // Write the values to the motors. 
    leftMotor.write(leftMotorVal);
    rightMotor.write(rightMotorVal);
    
    delay(15);
}

/*------
    Function: blinkLED
    Description: Blink (dimm? ) the LED 20 mSec on / 20 mSec off.
*/
void blinkLED()
{
    if ( count < 4 )
    {
        digitalWrite(LED_PIN_FRONT + count,HIGH);
        delay (20);
        digitalWrite(LED_PIN_FRONT + count,LOW);
        delay (20);
    }
    
    count = count + 1;
    if (count >= 4) count = 0;
}

