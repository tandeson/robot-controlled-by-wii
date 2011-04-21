 /*Program to gather the nunchuk data and place in a small packet to send it wirelessly to the
    receiver.
    The nunchuk code was borrowed from http://www.windmeadow.com/node/42  */
    // This program is like sender program 5 except the accleration values are not adjusted to the left 2 places
    // after the reading. This keeps the reading in a smaller range.
    #include <Wire.h>;        // Using the Wire library because of the two wire communication to the nunchuk.
    
    
    int UDintensity = 0;      // Variables to store the joystick/accelerometer readings
    int LRintensity = 0;
    int rightMotorVal;           // Variable to store the right Motors speed value.
    int leftMotorVal;            // Variable to store the left Motor speed value.
    int x;                    // Variables
    int y;
    int joy_x_axis; 
    int joy_y_axis; 
    int accel_x_axis; 
    int accel_y_axis; 
    int accel_z_axis; 
    int z_button; 
    int c_button; 
    
    void setup(){
      Serial.begin(38400);
      int button1 = 0;
      nunchuk_setpowerpins();    // Call the subroutine to set up the power pins on the nunchuk connection.
      nunchuk_init();            // Call the subroutine to begin communicating with the nunchuk.
      Serial.print("Nunchuck ready\n");
    }
    
    void loop(){
      nunchuk_get_data();              // Call the subroutine to read the data from the nunchuk.
      nunchuk_print_data();            // This subroutine also reads the data and puts the read data
                                     // into the correct variables.
      if (nunchuk_zbutton() == 1){    // If the Z button is pushed then use the data from the accelerometer
        y = nunchuk_accely();          // to control the motors.
        x = nunchuk_accelx();
        if (y < 80) y = 80;
        if (y > 180) y = 180;
        if (x < 80) x = 80;
        if (x > 180) x = 180;
      
      // map the incoming values to a symmetric scale of -100 to 100
          y = map(y,80,180,-100,100);
          x = map(x,80,180,-100,100);
      }
        else{
          y = nunchuk_joyy();            // If the Z button is not pushed then use the data from the joystick
          x = nunchuk_joyx();            // to control the motors.
      
     // map the incoming values to a symmetric scale of -100 to 100
          y = map(y,28,225,-100,100);
          x = map(x,28,225,-100,100);
        }
        
           if(y >-10 && y < 10 && x <  10 && x > - 10) {      // This is the deadspot
             Serial.print (254, BYTE);                          // Send the Stop command to the other xbee
             Serial.print (90, BYTE);
             Serial.print (255, BYTE);                                            
             Serial.print (90, BYTE);                                           
             delay(150);                                        // Give time to send
           }
        else {
         
          mix( y, x);            // If not in the dead band then call the subroutine
      
          LRintensity = map ( rightMotorVal, -100, 100, 50, 140);  // "mix" to calculate the values needed to move the 
          UDintensity = map ( leftMotorVal, -100, 100, 50, 140);   // motors with the correct speed and direction.
        
          
           Serial.print (254, BYTE);                                 // Send the Stop command to the other xbee
           Serial.print (UDintensity, BYTE);
           Serial.print (255, BYTE);                                            
           Serial.print (LRintensity, BYTE);                                           
           delay(150);  
        }     
    }
    //======================================================================================================================================================================================================//
    //Do not modify!!!!!!!!
    //======================================================================================================================================================================================================//
    
    //
    // Nunchuck functions
    //The static keyword is used to create variables that are visible to only one function. 
    //However unlike local variables that get created and destroyed every time a function is called, 
    //static variables persist beyond the function call, preserving their data between function calls. 
    //
    //static uint8_t
    byte nunchuk_buf[6]; // array to store nunchuck data,
    
    static void nunchuk_setpowerpins()                // Subroutine to set the Analog pins on the board
    {                                                   // to power and ground, clock and data.
      #define PWRPIN 17 // 3 + 14 == Analog Pin 3        // Analog Pin 3 is the same as pin 17 on the arduino
      #define GNDPIN 16 // 2 + 14 == Analog Pin 2        // Analog Pin 2 is the same as pin 16 
      pinMode(PWRPIN, OUTPUT);
      pinMode(GNDPIN, OUTPUT);
      digitalWrite(PWRPIN, HIGH);                        // Analog pin 3 is set high to power the nunchuk
      digitalWrite(GNDPIN, LOW);                         // Analog pin 2 is set to ground to provide ground to the nunchuk
      delay(100);                                        // 100 ms delay to allow settling of the lines.
    }
    
    // initialize the I2C system, join the I2C bus,
    // and tell the nunchuck we're talking to it
    void nunchuk_init()
    {
        Wire.begin(); // join i2c bus as master
        Wire.beginTransmission(0x52); // transmit to device 0x52
        Wire.send(0x40); // sends memory address
        Wire.send(0x00); // sends sent a zero.
        Wire.endTransmission(); // stop transmitting
    }
    
    // Send a request for data to the nunchuck
    // was "send_zero()"
    void nunchuk_send_request()
    {
        Wire.beginTransmission(0x52); // transmit to device 0x52. All nunchuks are assigned this address.
        Wire.send(0x00); // sending 0x00 sets the pointer back to the lowest address in order to read multiple bytes
        Wire.endTransmission(); // stop transmitting
    }
    
    // Receive data back from the nunchuck,
    // returns 1 on successful read. returns 0 on failure
    int nunchuk_get_data()        // Subroutine to read the data sent back from the nunchuk. It comes back in 
    {                             // in 6 byte chunks.
        int cnt=0;
        Wire.requestFrom (0x52, 6); // request data from nunchuck
        while (Wire.available ()) {  // If there is data in the buffer then send to the arduino. 
        // receive byte as an integer
            nunchuk_buf[cnt] = nunchuk_decode_byte(Wire.receive());//Wire.receive() - Retrieve a byte that 
                                                           // was transmitted from a slave device to 
                                                           //a master after a call to requestFrom or 
                                                           //was transmitted from a master to a slave
            cnt++;
        }
        nunchuk_send_request(); // send request for next data payload
                           // If we received the 6 bytes, then go print them
        if (cnt >= 5) {
            return 1; // success      // The success or failure values are not usedfor anything in this program
        }
            return 0; //failure
    }
    // Print the input data we have recieved
    // accel data is 10 bits long
    // so we read 8 bits, then we have to add
    // on the last 2 bits. 
    void nunchuk_print_data()  // This subroutine will read the buffered data and put in to variables.
    {
        static int i=0;
        int joy_x_axis = nunchuk_buf[0];
        int joy_y_axis = nunchuk_buf[1];
        int accel_x_axis = nunchuk_buf[2];
        int accel_y_axis = nunchuk_buf[3];
        int accel_z_axis = nunchuk_buf[4];
        int z_button = 0;
        int c_button = 0;
        // byte nunchuck_buf[5] contains bits for z and c buttons
        // it also contains the least significant bits for the accelerometer data
        // so we have to check each bit of byte outbuf[5]
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
    // Encode data to format that most wiimote drivers except
    // only needed if you use one of the regular wiimote drivers
    char nunchuk_decode_byte (char x)   // This subroutine decodes the data coming from the nunchuk.
    {
        x = (x ^ 0x17) + 0x17;
        return x;
    }
    
    // returns zbutton state: 1=pressed, 0=notpressed
    int nunchuk_zbutton()
    {
        return ((nunchuk_buf[5] >> 0) & 1) ? 0 : 1; // voodoo
    }
    // returns zbutton state: 1=pressed, 0=notpressed
    int nunchuk_cbutton()
    {
        return ((nunchuk_buf[5] >> 1) & 1) ? 0 : 1; // voodoo
    }
    // returns value of x-axis joystick
    int nunchuk_joyx()
    {
        return nunchuk_buf[0];
    }
    // returns value of y-axis joystick
    int nunchuk_joyy()
    {
        return nunchuk_buf[1];
    }
    // returns value of x-axis accelerometer
    int nunchuk_accelx()
    {
        return nunchuk_buf[2]; // FIXME: this leaves out 2-bits of the data
    }
    // returns value of y-axis accelerometer
    int nunchuk_accely()
    {
        return nunchuk_buf[3]; // FIXME: this leaves out 2-bits of the data
    }
    // returns value of z-axis accelerometer
    int nunchuk_accelz()
    {
        return nunchuk_buf[4]; // FIXME: this leaves out 2-bits of the data
    }
    
    
    // The subroutine "mix" takes the values from the joystick/accelerometer and checks to see what quadrant the
    // values are in, then calculates the corresponding motor values needed to move the motors in the correct way.
     void mix(int yAxis, int xAxis){
      if (yAxis >= 0 && xAxis >= 0){                                     
         rightMotorVal = ((yAxis * yAxis) - (xAxis * xAxis))/100;           // Quadrant I calculations
         leftMotorVal = (max((yAxis * yAxis),(xAxis * xAxis))/100);
        }
        else if (yAxis >= 0 && xAxis < 0 ){                             //  Quadrant II calculations
         rightMotorVal = (max((yAxis * yAxis),(xAxis * xAxis))/100);           // Quadrant I calculations
         leftMotorVal = ((yAxis * yAxis) - (xAxis * xAxis))/100;
        }
        else if (yAxis < 0 && xAxis >= 0 ){
          rightMotorVal = ((xAxis * xAxis) - (yAxis * yAxis))/100;               // Quadrant IV calculations
          leftMotorVal =  - (max((yAxis * yAxis),(xAxis * xAxis))/100);                   
        
        }
        else if (yAxis < 0 && xAxis < 0){                            // Quadrant III calculations
        leftMotorVal = (- (yAxis * yAxis) + (xAxis * xAxis))/100;
        rightMotorVal = - (max((yAxis * yAxis),(xAxis * xAxis))/100 );
        }
      }
     


