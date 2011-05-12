/*
    Program to gather the nunchuk data and place in a small packet to send it wirelessly to the
    receiver.

    The nunchuk code was borrowed from http://www.windmeadow.com/node/42

    This program is like sender program 5 except the accleration values are not adjusted to the left 2 places
    after the reading. This keeps the reading in a smaller range.
*/

// Using the Wire library because of the two wire communication to the nunchuk.
#include <Wire.h>;

//------------------- Constants / Defines -------------------

// ---- Wii Constants ----
// Wii Nunchuk allowable value range. (Accelerometer)
const int WII_NUNCHUK_MIN = 80;
const int WII_NUNCHUK_MAX = 180;

// Wii Joystick allowable value range.
const int WII_JOYSTICK_MIN = 28;
const int WII_JOYSTICK_MAX = 225;

const int WII_BUTTON_PRESSED = 1;

// ---- Program Constants ----
// Normalized value range.
const int NORMALIZED_RANGE_MIN = -100;
const int NORMALIZED_RANGE_MAX = 100;

const int NORMALIZED_DEAD_ZONE_MIN = -10;
const int NORMALIZED_DEAD_ZONE_MAX = 10;

/*
    Commands / data rates / etc
    
    This section MUST match between send and
    receive code!
    
    ** Section Start **
*/
#define SERIAL_DATA_SPEED_38400_BPS  (38400)

const int SERIAL_COMMAND_SET_RIGHT_MOTOR = 255;
const int SERIAL_COMMAND_SET_LEFT_MOTOR =   254;

const int MOTOR_VALUE_MIN = 50;
const int MOTOR_VALUE_MAX = 140;
const int MOTOR_VALUE_SPECIAL_CODE_STOP = 90;

// ** Section end **

//------------------- Global Variables -------------------

//------------------- Functions -------------------

/*------
    Function: setup
    Description: Arduino setup hook, called once before the calls to loop() start.
*/
void setup()
{
  Serial.begin(SERIAL_DATA_SPEED_38400_BPS);
 
  // Setup the Wii nunchuk power, and start communicating.
  nunchuk_setpowerpins();
  nunchuk_init();
}

/*------
    Function: loop
    Description: Arduino main loop, called over and over again... forever...
*/
void loop()
{
    // Call the subroutine to read the data from the nunchuk, if we get new data.. do stuff.
    if (nunchuk_get_data() )
    {
        // normalized input Variables
        int normalized_x = (NORMALIZED_RANGE_MIN + NORMALIZED_RANGE_MAX) / 2;                    
        int normalized_y = (NORMALIZED_RANGE_MIN + NORMALIZED_RANGE_MAX) / 2;
  
        // Determine which data source to use.
        if (WII_BUTTON_PRESSED == get_nunchuk_zbutton())
        {
            // If the Z button is pushed then use the data from the accelerometer to control the motors.
            
            // map the incoming values to a symmetric scale of NORMALIZED_RANGE_MIN to NORMALIZED_RANGE_MAX
            normalized_y = map(
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
            
            normalized_x = map(
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
        }
        else 
        {
            // map the incoming values to a symmetric scale of NORMALIZED_RANGE_MIN to NORMALIZED_RANGE_MAX
            normalized_y = map(
                nunchuk_joyy(),
                WII_JOYSTICK_MIN,
                WII_JOYSTICK_MAX,
                NORMALIZED_RANGE_MIN,
                NORMALIZED_RANGE_MAX
            );
            
            normalized_x = map(
                nunchuk_joyx(),
                WII_JOYSTICK_MIN,
                WII_JOYSTICK_MAX,
                NORMALIZED_RANGE_MIN,
                NORMALIZED_RANGE_MAX
            );
        }
        
        if(
            (normalized_y < NORMALIZED_DEAD_ZONE_MAX) && (normalized_y > NORMALIZED_DEAD_ZONE_MIN) && 
            (normalized_x < NORMALIZED_DEAD_ZONE_MAX) && (normalized_x > NORMALIZED_DEAD_ZONE_MIN)
        )
        {
            // This is the deadspot
            
            // Send the Stop command to the other xbee
            SendNewMotorValues(MOTOR_VALUE_SPECIAL_CODE_STOP,MOTOR_VALUE_SPECIAL_CODE_STOP);
        }
        else 
        {
            // If not in the dead band then call the subroutine
         
            /*
                "calculate_motor_values_from_normalized" to calculate the values needed to move the motors with the correct
                speed and direction. 
            */
            int LeftMotor = MOTOR_VALUE_SPECIAL_CODE_STOP;
            int RightMotor = MOTOR_VALUE_SPECIAL_CODE_STOP;
            
            calculate_motor_values_from_normalized( normalized_y, normalized_x, &LeftMotor, &RightMotor);
            
            LeftMotor = map(
                LeftMotor, 
                NORMALIZED_RANGE_MIN, 
                NORMALIZED_RANGE_MAX, 
                MOTOR_VALUE_MIN, 
                MOTOR_VALUE_MAX
            );
            
            RightMotor = map( 
                RightMotor, 
                NORMALIZED_RANGE_MIN, 
                NORMALIZED_RANGE_MAX, 
                MOTOR_VALUE_MIN, 
                MOTOR_VALUE_MAX
            );
            
            SendNewMotorValues(LeftMotor,RightMotor);
        }
    }
    else
    {
        // Bad Wii Data - Send a stop?
    }
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
    
    // Give time to send
    delay(150);
}

//======================================================================================================================================================================================================//
//Do not modify!!!!!!!!
//======================================================================================================================================================================================================//

/*
    Nunchuck functions
    
    The static keyword is used to create variables that are visible to only one function. 
    However unlike local variables that get created and destroyed every time a function is called, 
    static variables persist beyond the function call, preserving their data between function calls. 
*/

//------------------- Constants / Defines -------------------

// 3 + 14 == Analog Pin 3, Analog Pin 3 is the same as pin 17 on the arduino
#define PWRPIN (17) 
// 2 + 14 == Analog Pin 2 , Analog Pin 2 is the same as pin 16 on the arduino
#define GNDPIN (16)

#define WII_NUNCHUK_I2C_ADDRESS   (0x52)

#define WII_NUMBER_OF_BYTES_TO_READ  (6)

//------------------- Global Variables -------------------

// Wii accelerometer data
int accel_x_axis = (WII_NUNCHUK_MIN + WII_NUNCHUK_MAX) /2 ;
int accel_y_axis = (WII_NUNCHUK_MIN + WII_NUNCHUK_MAX) /2 ;
int accel_z_axis = (WII_NUNCHUK_MIN + WII_NUNCHUK_MAX) /2 ;

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

// Return values for this funciton
const int GET_DATA_OK = 1;
const int GET_DATA_FAIL = 0;

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
    
    // send request for next data payload If we received the 6 bytes, then go print them
    nunchuk_send_request(); 

    // If we got enought bytes, let the caller know.
    return (bytesReadBackCount >= (WII_NUMBER_OF_BYTES_TO_READ - 1)) ? GET_DATA_OK  : GET_DATA_FAIL ; 
}

#if 0
/*------
    Function: nunchuk_print_data
    Description: This subroutine will read the buffered data and put in to variables.
      Print the input data we have recieved :
      accel data is 10 bits long so we read 8 bits, then we have to add on the last 2 bits.
*/
 void nunchuk_print_data()
{
    static int i=0;
    
    int joy_x_axis = nunchuk_buf[0];
    int joy_y_axis = nunchuk_buf[1];
    
    int accel_x_axis = nunchuk_buf[2];
    int accel_y_axis = nunchuk_buf[3];
    int accel_z_axis = nunchuk_buf[4];
    
    int z_button = 0;
    int c_button = 0;
    
    /*
       byte nunchuck_buf[5] contains bits for z and c buttons
       it also contains the least significant bits for the accelerometer data
       so we have to check each bit of byte outbuf[5]
    */
    if ((nunchuk_buf[5] >> 0) & 1)
      z_button = 1;
    if ((nunchuk_buf[5] >> 1) & 1)
      c_button = 1;
    
    if ((nunchuk_buf[5] >> 2) & 1)
      accel_x_axis += 2;
    if ((nunchuk_buf[5] >> 3) & 1)
      accel_x_axis += 1;
    
    if ((nunchuk_buf[5] >> 4) & 1)
      accel_y_axis += 2;
    if ((nunchuk_buf[5] >> 5) & 1)
      accel_y_axis += 1;
    
    if ((nunchuk_buf[5] >> 6) & 1)
      accel_z_axis += 2;
    if ((nunchuk_buf[5] >> 7) & 1)
      accel_z_axis += 1;
}
#endif // 0 - Code block commented out, unused.

/*------
    Function: nunchuk_decode_byte
    Description: This subroutine decodes the data coming from the nunchuk.
*/
char nunchuk_decode_byte (char x)
{
    x = (x ^ 0x17) + 0x17;
    return x;
}

/*------
    Function: get_nunchuk_zbutton
    Description: returns zbutton state: 1=pressed, 0=notpressed
*/
int get_nunchuk_zbutton()
{
    // Shift byte by 0, AND with BIT0. If the bit is set, return 0, else 1.
    return ((nunchuk_buf[5] >> 0) & 1) ? 0 : 1;
}

/*------
    Function: nunchuk_cbutton
    Description: returns zbutton state: 1=pressed, 0=notpressed
*/
int nunchuk_cbutton()
{
    // Shift byte by 1, AND with BIT0. If the bit is set, return 0, else 1.
    return ((nunchuk_buf[5] >> 1) & 1) ? 0 : 1;
}

/*------
    Function: nunchuk_joyx
    Description: returns value of x-axis joystick
*/
int nunchuk_joyx()
{
    return nunchuk_buf[0];
}

/*------
    Function: nunchuk_joyy
    Description: returns value of y-axis joystick
*/
int nunchuk_joyy()
{
    return nunchuk_buf[1];
}

/*------
    Function: nunchuk_accelx
    Description: returns value of x-axis accelerometer
*/
int nunchuk_accelx()
{
    // FIXME: this leaves out 2-bits of the data
    return nunchuk_buf[2]; 
}

/*------
    Function:  nunchuk_accely
    Description: returns value of y-axis accelerometer
*/
int nunchuk_accely()
{
    // FIXME: this leaves out 2-bits of the data
    return nunchuk_buf[3]; 
}

/*------
    Function:  nunchuk_accelz
    Description: returns value of z-axis accelerometer
*/
int nunchuk_accelz()
{
    // FIXME: this leaves out 2-bits of the data
    return nunchuk_buf[4]; 
}

/*------
    Function:  calculate_motor_values_from_normalized
    Description: The subroutine "calculate_motor_values_from_normalized" takes the values from the joystick/accelerometer 
        and checks to see what quadrant the values are in, then calculates the 
        corresponding motor values needed to move the motors in the correct way.
*/
void calculate_motor_values_from_normalized(int yAxis, int xAxis,int* pMotorLeft,int* pMotorRight)
{
    
    
    if (yAxis >= 0 && xAxis >= 0)
    {                                     
        // Quadrant I calculations
        *pMotorRight = ((yAxis * yAxis) - (xAxis * xAxis))/100;           
        *pMotorLeft = (max((yAxis * yAxis),(xAxis * xAxis))/100);
    }
    else if (yAxis >= 0 && xAxis < 0 )
    {
        //  Quadrant II calculations      
        *pMotorRight = (max((yAxis * yAxis),(xAxis * xAxis))/100);
        *pMotorLeft = ((yAxis * yAxis) - (xAxis * xAxis))/100;
    }
    else if (yAxis < 0 && xAxis >= 0 )
    {
        // Quadrant IV calculations
        *pMotorRight = ((xAxis * xAxis) - (yAxis * yAxis))/100;               
        *pMotorLeft =  - (max((yAxis * yAxis),(xAxis * xAxis))/100);                   
    }
    else if (yAxis < 0 && xAxis < 0)
    {
        // Quadrant III calculations
        *pMotorRight = - (max((yAxis * yAxis),(xAxis * xAxis))/100 );
        *pMotorLeft = (- (yAxis * yAxis) + (xAxis * xAxis))/100;
    }
}
