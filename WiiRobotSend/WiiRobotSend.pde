/*
    Program to gather the nunchuk data and place in a small packet to send it wirelessly to the
    receiver.
    
    /-------------\   /---------\   /------\
    |Wii Nunchuck |-->| Arduino |-->| xBee |
    \-------------/   \---------/   \------/
    
    This code deal with data from an input source (in this case a Wii Nunchuck), and uses it to
    send left and right motor values to a slave device (via a xBee transceiver).
    
    Normalized values are from 100 to -100 , representing 100% to -100%.
    
    Initial Code based on:
    The nunchuk code was borrowed from http://www.windmeadow.com/node/42

    This program is like sender program 5 except the accleration values are not adjusted to the left 2 places
    after the reading. This keeps the reading in a smaller range.
*/

// Using the Wire library because of the two wire communication to the nunchuk.

// Override the wire library i2c speed (from 100Khz to 400 Khz)
#define TWI_FREQ 400000L

#include <Wire.h>;

//------------------- Constants / Defines -------------------

// ---- Wii Constants ----
// Wii Nunchuk allowable value range. (Accelerometer)
const int WII_NUNCHUK_MIN = 320;
const int WII_NUNCHUK_MAX = 720;

// Wii Joystick allowable value range.
const int WII_JOYSTICK_MIN = 28;
const int WII_JOYSTICK_MAX = 225;

const int WII_BUTTON_PRESSED = 1;

// ---- Program Constants ----
// Normalized value range.
const int NORMALIZED_RANGE_MIN = -100;
const int NORMALIZED_RANGE_MAX = 100;

const int NORMALIZED_DEAD_ZONE = 10;

const int GET_DATA_OK = 1;
const int GET_DATA_FAIL = 0;

// ---- Delay and watch times, in milliSeconds ----
const unsigned long TIME_BETWEEN_GET_DATA = 75;

/*
    Commands / data rates / etc
    
    This section MUST match between send and
    receive code!
    
    ** Section Start **
*/
const long SERIAL_DATA_SPEED_38400_BPS = 38400;

const int SERIAL_COMMAND_SET_RIGHT_MOTOR = 255;
const int SERIAL_COMMAND_SET_LEFT_MOTOR =   254;

// ** Section end **

//------------------- Global Variables -------------------

// Timer to control when we get new data from the Wii.
unsigned long lastGetDataTimer;

/*
   Returns normlized data from the input device.
   
   pNormalizedX = pointer to the int where we will put the returned X value.
   pNormalizedY = pointer to the int where we will put the returned Y value.
   
   return = 0 if there was an error, non-zero if there was no error. Note that if there was an 
      error, the pNormalizedX and pNormalizedY values cannot be trusted.
*/
unsigned char getNormalizedInput(int* pNormalizedX, int* pNormalizedY);

//------------------- Functions -------------------

/*------
    Function: setup
    Description: Arduino setup hook, called once before the calls to loop() start.
*/
void setup()
{
  Serial.begin(SERIAL_DATA_SPEED_38400_BPS);
 
  // Setup the Wii nunchuk power, and start communicating.
  nunchuk_init();
  
  lastGetDataTimer = millis();
}

/*------
    Function: loop
    Description: Arduino main loop, called over and over again... forever...
*/
void loop()
{
     // Input Device data.
     int normalized_x = 0;                    
     int normalized_y = 0;
     
     // Flag to signal when data needs servicing.
     unsigned char processNewData = false;
     
     // Get new Wii data on a schedule.
     if(hasTimeoutExpired(lastGetDataTimer,TIME_BETWEEN_GET_DATA))
     {
         // Good Wii Data - work with it. 
         if(getNormalizedInput(&normalized_x, &normalized_y))
         {
             // let other code know we have updated the inputs.
             processNewData = true;
             
             // if we got good data, reset our counter.
             lastGetDataTimer = millis();
         }
     }
     else
     {
         // Bad Wii Data - Stop the Slave.
         
         // Send zeros if we loose communication.
         SendNewMotorValues(0,0);
         
         // Try again on our next scheduled time.
         lastGetDataTimer = millis();
     }
     
     // Apply any additional formatting to our x and y data.
     if(processNewData)
     {     
         // Do Any needed preprocessing of the data.
         applyFilterToInput(&normalized_x, &normalized_y);
         applyDeadZone(&normalized_x, &normalized_y);
         
         // Input Device data.
         int motor_right = 0;                    
         int motor_left = 0;   
         
         // Convert from joystick to motor values
         convertInputToMotor(normalized_x,normalized_y,&motor_left,&motor_right);
         
         // Convert to non-normalized values - temporary until rec code changes.
         motor_left = map(motor_left,NORMALIZED_RANGE_MIN,NORMALIZED_RANGE_MAX,50,140);
         motor_right = map(motor_right,NORMALIZED_RANGE_MIN,NORMALIZED_RANGE_MAX,50,140);
       
         // Send.
         SendNewMotorValues(motor_left,motor_right);
         
         // Clear the flag since we serviced this data.
         processNewData = false;
     }
}

/*------
    Function:  hasTimeoutExpired
    Description: Helper function for timers.
*/
bool hasTimeoutExpired(unsigned long counter, unsigned long timeout)
{
    return((millis() - counter) > timeout);
}

// See function description at the top of the file.
unsigned char getNormalizedInput(int* pNormalizedX, int* pNormalizedY)
{
    unsigned char didWeGetData = GET_DATA_FAIL;
    
    // Call the subroutine to read the data from the nunchuk, if we get new data.. process.
    if (nunchuk_get_data() )
    {
        didWeGetData = GET_DATA_OK;
        
        // Determine which data source to use.
        if (WII_BUTTON_PRESSED == get_nunchuk_zbutton())
        {
            // If the Z button is pushed then use the data from the accelerometer to control the motors.
            
            // map the incoming values to a symmetric scale of NORMALIZED_RANGE_MIN to NORMALIZED_RANGE_MAX
            *pNormalizedX = map(
                constrain(
                    nunchuk_accelx(), 
                    WII_NUNCHUK_MIN, 
                    WII_NUNCHUK_MAX
                ),
                WII_NUNCHUK_MIN,
                WII_NUNCHUK_MAX,
                NORMALIZED_RANGE_MIN,
                NORMALIZED_RANGE_MAX
            );
            
            *pNormalizedY = map(
                constrain(
                    nunchuk_accely(), 
                    WII_NUNCHUK_MIN, 
                    WII_NUNCHUK_MAX
                ),
                WII_NUNCHUK_MIN,
                WII_NUNCHUK_MAX,
                NORMALIZED_RANGE_MIN,
                NORMALIZED_RANGE_MAX
            );
        }
        else 
        {
            // used for 0 offset, 
            static int joystick_x_offset = 120;
            static int joystick_y_offset = 120;
            
            // Use the 'c' button to calibrate the offset.
            if(get_nunchuk_cbutton())
            {
                joystick_x_offset = nunchuk_joyx();
                joystick_y_offset = nunchuk_joyy();
            }
            
            // map the incoming values to a symmetric scale of NORMALIZED_RANGE_MIN to NORMALIZED_RANGE_MAX
            *pNormalizedX = constrain(
                (nunchuk_joyx() - joystick_x_offset),
                NORMALIZED_RANGE_MIN,
                NORMALIZED_RANGE_MAX
            ); 
            
            *pNormalizedY =  constrain(
                (nunchuk_joyy() - joystick_y_offset),
                NORMALIZED_RANGE_MIN,
                NORMALIZED_RANGE_MAX
            );
        }
    }
    else
    {
        // if we didn't get any data, zero the x and y values in case someone uses them without checking.
        *pNormalizedX = 0;
        *pNormalizedY = 0;
    }
    
    return didWeGetData; 
}

/*------
    Function: applyFilterToInput
    Description: Apply a rolling average filter to the input vaules
*/
const unsigned char FILTER_BUFFER_SIZE = 2;
void applyFilterToInput(int* pNormalizedX, int* pNormalizedY)
{
    static unsigned char index = 0;
    static int xBuffer[FILTER_BUFFER_SIZE] = {0};
    static int yBuffer[FILTER_BUFFER_SIZE] = {0};
    static int xRollingFilterVal = 0;
    static int yRollingFilterVal = 0;
    
    // Update our index to point to the oldest data.
    index++;
    if (index >= FILTER_BUFFER_SIZE) index =0;
    
    // remove this data from our rolling average.
    xRollingFilterVal -= xBuffer[index] / FILTER_BUFFER_SIZE;
    yRollingFilterVal -= yBuffer[index] / FILTER_BUFFER_SIZE;
    
    // Overwrite the old data with the latest
    xBuffer[index] = *pNormalizedX;
    yBuffer[index] = *pNormalizedY;
    
    // Add the new data to our rolling average.
    xRollingFilterVal +=  xBuffer[index] / FILTER_BUFFER_SIZE;
    yRollingFilterVal +=  yBuffer[index] / FILTER_BUFFER_SIZE;
    
    // Return the data via the pointers we were passed.
    *pNormalizedX = xRollingFilterVal;
    *pNormalizedY = yRollingFilterVal;
}

/*------
    Function: applyDeadZone
    Description: Apply a deadzone in the middle of the input range.
*/
void applyDeadZone(int* pNormalizedX, int* pNormalizedY)
{
    if(
        (*pNormalizedX < NORMALIZED_DEAD_ZONE) &&
        (*pNormalizedX > -NORMALIZED_DEAD_ZONE)
    )
    {
        *pNormalizedX = 0;
    }
    else
    {
        // Adjust for the missing deadzone area.
        int polarity = *pNormalizedX > 0 ? 1 : -1;
       *pNormalizedX = map(
           *pNormalizedX,
           (NORMALIZED_DEAD_ZONE * polarity),
           (NORMALIZED_RANGE_MAX * polarity),
           1,
           (NORMALIZED_RANGE_MAX * polarity)
       );
    }

    if(
        (*pNormalizedY < NORMALIZED_DEAD_ZONE) &&
        (*pNormalizedY > -NORMALIZED_DEAD_ZONE)
    )
    {
        *pNormalizedY = 0;
    }
    else
    {
        // Adjust for the missing deadzone area.
        int polarity = *pNormalizedY > 0 ? 1 : -1;
       *pNormalizedY = map(
           *pNormalizedY,
           (NORMALIZED_DEAD_ZONE * polarity),
           (NORMALIZED_RANGE_MAX * polarity),
           1,
           (NORMALIZED_RANGE_MAX * polarity)
       );
    }
}

/*------
    Function: convertInputToMotor
    Description: Convert normalized x and y values and process left and right motor values.
*/
void  convertInputToMotor(int normalizedX, int normalizedY,int* pMotorLeft,int* pMotorRight)
{
    // Use the Y direction to set the forward and backward motion.
    *pMotorRight = normalizedY;
    *pMotorLeft = normalizedY;
    
    // Apply the X as a "twist" effect.
    *pMotorRight -= normalizedX / 2 ;
    *pMotorLeft += normalizedX / 2 ;
    
    *pMotorLeft = constrain(*pMotorLeft,NORMALIZED_RANGE_MIN,NORMALIZED_RANGE_MAX);
    *pMotorRight = constrain(*pMotorRight,NORMALIZED_RANGE_MIN,NORMALIZED_RANGE_MAX);
}

/*------
    Function: SendNewMotorValues
    Description: Sends a new Left and Right motor value to the Receive code. In this
        case we use the XBee for this task.
*/
void SendNewMotorValues(int left, int right)
{
    // Send the new Motor Values.
    Serial.print (SERIAL_COMMAND_SET_LEFT_MOTOR, BYTE);
    Serial.print (left, BYTE);
            
    Serial.print (SERIAL_COMMAND_SET_RIGHT_MOTOR, BYTE);
    Serial.print (right, BYTE);
}

//------------------------------------------------------------------------------------------
/*
    Nunchuck functions
    
    The static keyword is used to create variables that are visible to only one function. 
    However unlike local variables that get created and destroyed every time a function is called, 
    static variables persist beyond the function call, preserving their data between function calls. 

    From : http://wiibrew.org/wiki/Wiimote/Extension_Controllers
  	Bit
Byte 	|7 	6 	5 	4 	3 	2 	1 	0
0 	|SX<7:0>
1 	|SY<7:0>
2 	|AX<9:2>
3 	|AY<9:2>
4 	|AZ<9:2>
5 	|AZ<1:0> 	AY<1:0> 	AX<1:0> 	BC 	BZ

SX,SY are the Analog Stick X and Y positions, while AX, AY, and AZ are the 10-bit accelerometer data
*/
const unsigned char WII_NUNCHUCK_nX_MASK  = 0x03;
const unsigned char WII_NUNCHUCK_nX_NUM_BITS = 2;
const unsigned char WII_NUNCHUCK_AX_SHIFT = 2;
const unsigned char WII_NUNCHUCK_AY_SHIFT = 4;
const unsigned char WII_NUNCHUCK_AZ_SHIFT = 6;

//------------------- Constants / Defines -------------------

// 3 + 14 == Analog Pin 3, Analog Pin 3 is the same as pin 17 on the arduino
const unsigned char PWRPIN  = 17;

// 2 + 14 == Analog Pin 2 , Analog Pin 2 is the same as pin 16 on the arduino
const unsigned char GNDPIN =  16;

const unsigned char WII_NUNCHUK_I2C_ADDRESS =  0x52;

const unsigned char WII_NUMBER_OF_BYTES_TO_READ = 6;

//------------------- Global Variables -------------------

// array to store nunchuck data
byte nunchuk_buf[WII_NUMBER_OF_BYTES_TO_READ];

//------------------- Functions -------------------

/*------
    Function: nunchuk_setpowerpins
    Description: Subroutine to set the Analog pins on the board to power and ground, clock and data.
*/
static void nunchuk_setpowerpins()
{
    pinMode(PWRPIN, OUTPUT);
    pinMode(GNDPIN, OUTPUT);
    
    /*
        Analog pin 3 is set high to power the nunchuk
        Analog pin 2 is set to ground to provide ground to the nunchuk
    */
    digitalWrite(PWRPIN, HIGH);
    digitalWrite(GNDPIN, LOW);
    
    // 100 ms delay to allow settling of the lines.
    delay(100);
}

/*------
    Function: nunchuk_init
    Description: initialize the I2C system, join the I2C bus, and tell the nunchuck we're talking to it
*/
void nunchuk_init()
{
    // Make sure the hardware is properly configured.
    nunchuk_setpowerpins();
    
    // join i2c bus as master
    Wire.begin();
    
    // transmit to device
    Wire.beginTransmission(WII_NUNCHUK_I2C_ADDRESS);
    
    // sends value of 0x00 to memory address 0x40
    Wire.send(0x40); 
    Wire.send(0x00);
    
    // stop transmitting via i2c stop.
    Wire.endTransmission(); 
}

/*------
    Function: nunchuk_send_request
    Description: Send a request for data to the nunchuck was "send_zero()"
*/
void nunchuk_send_request()
{
    // transmit to device
    Wire.beginTransmission(WII_NUNCHUK_I2C_ADDRESS); 

    // sending 0x00 sets the pointer back to the lowest address in order to read multiple bytes
    Wire.send(0x00);
    
    // stop transmitting via i2c stop.
    Wire.endTransmission(); 
}

/*------
    Function: nunchuk_get_data
    Description: Receive data back from the nunchuck, returns 1 on successful read. returns 0 on failure.
                 Subroutine to read the data sent back from the nunchuk. It comes back in in 6 byte chunks.
*/
int nunchuk_get_data()
{ 
    int bytesReadBackCount=0;
    
    // request data from nunchuck
    Wire.requestFrom (
        WII_NUNCHUK_I2C_ADDRESS, 
        WII_NUMBER_OF_BYTES_TO_READ
    ); 
    
    // If there is data in the buffer then send to the arduino. 
    while (Wire.available ()) 
    {  
        /* 
            receive byte as an integer.
            
            Wire.receive() - Retrieve a byte that was transmitted from a slave device to
                a master after a call to requestFrom or was transmitted from a master to a slave 
        */
        nunchuk_buf[bytesReadBackCount] = nunchuk_decode_byte(Wire.receive());
        bytesReadBackCount++;
    }
    
    // send request for next data payload.
    nunchuk_send_request(); 

    // If we got enought bytes, let the caller know.
    return (bytesReadBackCount >= (WII_NUMBER_OF_BYTES_TO_READ - 1)) ? GET_DATA_OK  : GET_DATA_FAIL ; 
}

/*------
    Function: nunchuk_decode_byte
    Description: helper function to decode the data coming from the nunchuk.
*/
char nunchuk_decode_byte (char x)
{
    x = (x ^ 0x17) + 0x17;
    return x;
}

/*------
    Function:  process_nunchuck_accel
    Description: helper function for processing accelromtere data for the wii nunchuck.
*/
int process_nunchuck_accel(unsigned char data_byte,unsigned char shift_size)
{
    int correctValue = nunchuk_buf[data_byte];
    correctValue <<= WII_NUNCHUCK_nX_NUM_BITS;
    correctValue |= ((nunchuk_buf[5] >> shift_size) & WII_NUNCHUCK_nX_MASK);
    return correctValue;
}

/*------
    Function: get_nunchuk_zbutton
    Description: returns zbutton state: 1=pressed, 0=notpressed
*/
int get_nunchuk_zbutton()
{
    // Shift byte by 0, AND with BIT0. If the bit is set, return 0, else 1.
    return (nunchuk_buf[5] & 0x01) ? 0 : 1;
}

/*------
    Function: nunchuk_cbutton
    Description: returns zbutton state: 1=pressed, 0=notpressed
*/
int get_nunchuk_cbutton()
{
    // Shift byte by 1, AND with BIT0. If the bit is set, return 0, else 1.
    return (nunchuk_buf[5] & 0x02) ? 0 : 1;
}

/*------
    Function: nunchuk_joyx
    Description: returns value of x-axis joystick
*/
int nunchuk_joyx() { return nunchuk_buf[0]; }

/*------
    Function: nunchuk_joyy
    Description: returns value of y-axis joystick
*/
int nunchuk_joyy() { return nunchuk_buf[1]; }

/*------
    Function: nunchuk_accelx
    Description: returns value of x-axis accelerometer
*/
int nunchuk_accelx() { return process_nunchuck_accel(2,WII_NUNCHUCK_AX_SHIFT);}

/*------
    Function:  nunchuk_accely
    Description: returns value of y-axis accelerometer
*/
int nunchuk_accely() { return process_nunchuck_accel(3,WII_NUNCHUCK_AY_SHIFT); }

/*------
    Function:  nunchuk_accelz
    Description: returns value of z-axis accelerometer
*/
int nunchuk_accelz() { return process_nunchuck_accel(4,WII_NUNCHUCK_AZ_SHIFT); }

