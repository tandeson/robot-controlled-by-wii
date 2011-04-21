/*Program to control the two wheeled robot with the joystick or the accelerometer of the nunchuk.*/ 

#include <Servo.h>        // Using the servo library

Servo leftMotor;          //Since dc motors are controlled with a parallax motor controller
Servo rightMotor;         // they will be given servo signals

int rightMotorVal;           // Variable to store the right Motors speed value.
int leftMotorVal;            // Variable to store the left Motor speed value.
int x;                    // Variables
int y;
int incomingByte;
int frontLED = 8;
int backLED = 9;
int leftLED = 10;
int rightLED = 11;
int count = 0;

void setup(){
  pinMode (frontLED, OUTPUT);
  pinMode (backLED, OUTPUT);
  pinMode (leftLED, OUTPUT);
  pinMode (rightLED, OUTPUT);
  Serial.begin(38400);
  leftMotor.attach (5);      // Attach the left motor to  pin 5
  rightMotor.attach(4);        // and the right motor to pin 4
}

void loop(){
  if (Serial.available()){// are there any bytes available on the serial port??
    // assign bytes to the variable incomingByte
      incomingByte = Serial.read();
      if (incomingByte == 254){
        leftMotorVal = Serial.read();
      }
      if (incomingByte == 255){
        rightMotorVal = Serial.read();
      }
  }
  
  if (leftMotorVal == 90 && rightMotorVal == 90) blinkLED();
    leftMotor.write(leftMotorVal);                        // Write the values to the motors.                   
    rightMotor.write(rightMotorVal);                                               
     delay(15);
}

void blinkLED()
  {
  if ( count < 4 ){
    digitalWrite(frontLED + count,HIGH);
    delay (20);
    digitalWrite(frontLED + count,LOW);
    delay (20);
  }
  count = count + 1;
  if (count >= 4) count = 0;
  
}

