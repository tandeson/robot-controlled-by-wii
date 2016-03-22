#Proposed new software requirements

# Introduction #
This page holds notes on requirements of the software to drive the two wheeled robot via a Wii Nunchuck.

## Sending Device ##
  * Hardware:
    * 1x - Arduino w/ ATMEGA168
    * 1x ProtoShield v2
    * 1x Xbee transceiver.
    * 1x Wiimote Nunchuck.
  * Software
    * Goals:
      * Filter the Input Source (avoid quick jumps)
      * Allow for calibrated "zero" position of the joystick.
      * Damp the speed up of the robot, but allow for quick stops.
      * ? Allow for Joystick or Accelerometer as a input.
      * Go to a "safe" shutdown state if we can't communicate with the Wiimote. (maybe after 300 - 500 mSec?)
      * Send out a new motor state of the Receiver ever 100 mSec or so.

## Receiving Device ##
  * Hardware:
    * 1x - Arduino w/ ATMEGA168
    * 1x Xbee transceiver.
    * 2x <Motor Controller Names>
    * TODO - add the rest of the hardware here.
  * Software
    * Set the motor controllers based on commands from the Sender.
    * If we loose communication with the sender, stop the Robot.
      * How long a timeout? also about 300 - 500 mSec?
    * Control the LEDs
      * ? Set LED based on motor state? (e.g. front LED on for front movement?)
      * ? Set LED based on action (Moving vs. Stopped)
      * ? Set LED based on Joystick vs. Accelermeters?
      * ? Set LED on Wiimote communication error?
      * ? Set LED on Send / Receive device comm error?
    * Convert from the send format to a format the motor controllers use.