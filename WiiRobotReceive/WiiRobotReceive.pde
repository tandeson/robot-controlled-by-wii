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

// Servo mapping information.
const int MOTOR_VALUE_MIN = 50;
const int MOTOR_VALUE_MAX = 140;
const int MOTOR_VALUE_STOP = 90;

// Motor control info
const unsigned long COMMUNICATION_SHUTDOWN_TIMEOUT_MS = 500;

/*
    Commands / data rates / etc
    
    This section MUST match between send and
    receive code!
    
    ** Section Start **
*/
const long SERIAL_DATA_SPEED_38400_BPS = 38400;

const int SERIAL_COMMAND_SET_RIGHT_MOTOR = 255;
const int SERIAL_COMMAND_SET_LEFT_MOTOR =   254;

// 1 byte for which servo + 1 byte for values * 2 motors = 4 bytes.
const int NUMBER_OF_BYTES_IN_A_COMMAND = 4;

// Normalized value range.
const int NORMALIZED_RANGE_MIN = -100;
const int NORMALIZED_RANGE_MAX = 100;
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
    init_LedHarware();
    init_MotorHardware();
    
    // Start Serial Communication
    Serial.begin(SERIAL_DATA_SPEED_38400_BPS);
}

/*------
    Function: loop
    Description: Arduino main loop, called over and over again... forever...
*/
void loop()
{
    // Variable to store the Motor speed values.
    static char rightMotorVal = 0;
    static char leftMotorVal = 0;
    
    if (checkForNewData(&leftMotorVal,&rightMotorVal) )
    {
        // Write the values to the motors. 
        motor_SetValues(leftMotorVal,rightMotorVal);
    }
    
    // Deal with the LED
    updateLed(leftMotorVal,rightMotorVal);
}

/*------
    Function: checkForNewData
    Description: Looks for new Serial data, if we have it. Upated
       the motor values. If we have not got the data after a timeout, then
       set both motors to stop.
       
       motor values are normalized from -100 to +100 representing a percenage.
       0 is off.
*/
char checkForNewData(char* pLeftMotor, char* pRightMotor)
{
    // Use this to keep track of our Last good message time stamp.
    static unsigned long lastGoodCommandTime = 0;
    
    // Let the calling funciton know if anything has changed.
    char didValuesChange = false;
    
    // are there any bytes available on the serial port??
    if (Serial.available() > NUMBER_OF_BYTES_IN_A_COMMAND)
    {
        int incomingByte = 0;
        
        // assign bytes to the variable incomingByte
        incomingByte = Serial.read();
        
        if (SERIAL_COMMAND_SET_LEFT_MOTOR == incomingByte)
        {
            *pLeftMotor = Serial.read();
            lastGoodCommandTime = millis();
            didValuesChange = true;
        }
        else if (SERIAL_COMMAND_SET_RIGHT_MOTOR == incomingByte)
        {
            *pRightMotor = Serial.read();
            lastGoodCommandTime = millis();
            didValuesChange = true;
        }
    }
    
    // If the timeout has expired - kill the motors.
    if ((millis() - lastGoodCommandTime) > COMMUNICATION_SHUTDOWN_TIMEOUT_MS)
    {
        *pLeftMotor = 0;
        *pRightMotor = 0;
        didValuesChange = true;
        
        /* 
            While it's pretty much unthinkable, make sure we don't circle around 
            and hit this again.
        */
        lastGoodCommandTime = millis() - COMMUNICATION_SHUTDOWN_TIMEOUT_MS;
    }
    
    return didValuesChange;
}

//------------------- LED Code -------------------

/*------
    Function: init_LedHarware()
    Description: Setup the Hardware so we can use the LEDs.
*/
void init_LedHarware()
{
    // Set LED pins to output, and ensure they are driven low.
    for(int ledPinIndex = 0; ledPinIndex < NUMBER_OF_LEDS; ledPinIndex++)
    {
        pinMode(LED_pins[ledPinIndex],OUTPUT);
        digitalWrite(LED_pins[ledPinIndex],LOW);
    }
}

/*------
    Function: updateLed
    Description: set LED based on Motor value.
*/
void updateLed(int normalizedLeft,int normalizedRight)
{
    // if we are 0%, blink the LED.
    if ((normalizedLeft == 0) && (normalizedRight == 0))
    { 
        blinkLED();
    }
    else
    {
        setLedByMotor(normalizedLeft,0,2);
        setLedByMotor(normalizedRight,1,3);
    }
}

/*------
    Function: blinkLED
    Description: Blink (dimm? ) the LED 20 mSec on / 20 mSec off.
*/
void blinkLED()
{
    static unsigned long lastActionTime = 0;
    static int blinkLedArrayIndex = 0;
    
    if ( (millis() - lastActionTime) > 250)
    {
        if ( blinkLedArrayIndex < NUMBER_OF_LEDS )
        {
           digitalWrite(LED_pins[blinkLedArrayIndex],LOW);
           
           // Move to the next LED
           blinkLedArrayIndex++;
           if (blinkLedArrayIndex >= NUMBER_OF_LEDS) blinkLedArrayIndex = 0;
    
           digitalWrite(LED_pins[blinkLedArrayIndex],HIGH);
        }
        else
        {
            blinkLedArrayIndex = 0;
        }
        
        // Update our time stamp.
        lastActionTime = millis();
    }
}

/*------
    Function: setLedByMotor
    Description: Set LED on / off based on
*/
void setLedByMotor(int motorValue,char ledFront, char ledBack)
{
    if ( motorValue > 0 )
    {
        digitalWrite(LED_pins[ledFront],HIGH);
        digitalWrite(LED_pins[ledBack],LOW);
    }
    else
    {
        digitalWrite(LED_pins[ledFront],LOW);
        digitalWrite(LED_pins[ledBack],HIGH);
    }
}
//------------------- Motor Code -------------------

/*------
    Function: init_MotorHardware()
    Description: Setup the Hardware so we can use the Servo libraries to control
        the two motors.
*/
void init_MotorHardware()
{
    // Attach the left motor and ensure it is stopped.
    leftMotor.attach (MOTOR_PIN_LEFT);
    leftMotor.write(MOTOR_VALUE_STOP);
    
    // Attach the right motor and ensure it is stopped.
    rightMotor.attach(MOTOR_PIN_RIGHT);
    rightMotor.write(MOTOR_VALUE_STOP);
}

/*------
    Function: motor_SetValues
    Description: Set motors via normlized values of +100 to -100 
       representing the percent power.
*/
void motor_SetValues(int normalizedLeft, int normalizedRight)
{    
    leftMotor.write(convertNormalizedToServo(normalizedLeft));
    rightMotor.write(convertNormalizedToServo(normalizedRight));
}

/*------
    Function: convertNormalizedToServo
    Description: Takes a int from +100 to -100, and returns
       a servo number.
*/
int convertNormalizedToServo(int normalized)
{
    if(0 == normalized)
    {
        return MOTOR_VALUE_STOP;
    }
    else if(normalized > 0)
    {
        return map(normalized,0,NORMALIZED_RANGE_MAX,MOTOR_VALUE_STOP,MOTOR_VALUE_MAX);
    }
    else
    {
        return map(normalized,NORMALIZED_RANGE_MIN,0,MOTOR_VALUE_MIN,MOTOR_VALUE_STOP);
    }
}

