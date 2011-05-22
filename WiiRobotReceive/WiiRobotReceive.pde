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

const int NUMBER_OF_LEDS = 4;
const int LED_pins[NUMBER_OF_LEDS] = {
    LED_PIN_FRONT,
    LED_PIN_BACK,
    LED_PIN_LEFT,
    LED_PIN_RIGHT
};

// Motor Pin Assignment
const int MOTOR_PIN_LEFT = 5;
const int MOTOR_PIN_RIGHT = 4;

/*
    Commands / data rates / etc
    
    This section MUST match between send and
    receive code!
    
    ** Section Start **
*/
const long SERIAL_DATA_SPEED_38400_BPS = 38400;

const int SERIAL_COMMAND_SET_RIGHT_MOTOR = 255;
const int SERIAL_COMMAND_SET_LEFT_MOTOR =   254;

const int MOTOR_VALUE_MIN = 50;
const int MOTOR_VALUE_MAX = 140;
const int MOTOR_VALUE_SPECIAL_CODE_STOP = 90;

// ** Section end **

//------------------- Global Variables ------------------- 

/*
    Since dc motors are controlled with a parallax motor controller
    they will be given servo signals
*/
Servo leftMotor;
Servo rightMotor;

//------------------- Functions -------------------

/*------
    Function: setup
    Description: Arduino setup hook, called once before the calls to loop() start.
*/
void setup()
{
    // Set LED pins to output, and ensure they are driven low.
    for(int ledPinIndex = 0; ledPinIndex < NUMBER_OF_LEDS; ledPinIndex++)
    {
        pinMode(LED_pins[ledPinIndex],OUTPUT);
        digitalWrite(LED_pins[ledPinIndex],LOW);
    }

    // Start Serial Communication
    Serial.begin(SERIAL_DATA_SPEED_38400_BPS);
    
    // Attach the left motor and ensure it is stopped.
    leftMotor.attach (MOTOR_PIN_LEFT);
    leftMotor.write(MOTOR_VALUE_SPECIAL_CODE_STOP);
    
    // Attach the right motor and ensure it is stopped.
    rightMotor.attach(MOTOR_PIN_RIGHT);
    rightMotor.write(MOTOR_VALUE_SPECIAL_CODE_STOP);
}

/*------
    Function: loop
    Description: Arduino main loop, called over and over again... forever...
*/
void loop()
{
    // Variable to store the Motor speed values.
    static int rightMotorVal = MOTOR_VALUE_SPECIAL_CODE_STOP;
    static int leftMotorVal = MOTOR_VALUE_SPECIAL_CODE_STOP;

    // are there any bytes available on the serial port??
    if (Serial.available())
    {
        int incomingByte = 0;
        
        // assign bytes to the variable incomingByte
        incomingByte = Serial.read();
        
        if (SERIAL_COMMAND_SET_LEFT_MOTOR == incomingByte)
        {
            leftMotorVal = Serial.read();
        }
        else if (SERIAL_COMMAND_SET_RIGHT_MOTOR == incomingByte)
        {
            rightMotorVal = Serial.read();
        }
    }
    
    // All stop command?
    if (
        (leftMotorVal == MOTOR_VALUE_SPECIAL_CODE_STOP) && 
        (rightMotorVal == MOTOR_VALUE_SPECIAL_CODE_STOP)
    )
    { 
        blinkLED();
    }
    
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
    static int blinkLedArrayIndex = 0;
    
    if ( blinkLedArrayIndex < NUMBER_OF_LEDS )
    {
        digitalWrite(LED_pins[blinkLedArrayIndex],HIGH);
        delay (20);
        digitalWrite(LED_pins[blinkLedArrayIndex],LOW);
        delay (20);
    }

    // Move to the next LED
    blinkLedArrayIndex++;
    if (blinkLedArrayIndex >= NUMBER_OF_LEDS) blinkLedArrayIndex = 0;
}
