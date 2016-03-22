#Notes on Wii Nunchuk

Note: This is based on debugging statements added to [r11](https://code.google.com/p/robot-controlled-by-wii/source/detail?r=11) code in the SVN repository.

# Notes on Wii Nunchuk #
  * When Joystick centered:
    * Raw: (x,y) = 121,125
    * Normalized (x,y) = -6,-2
    * Motor (Left,Right) = 90,90
  * When Joystick straight up (full forward):
    * Raw: (x,y) = 126,219
    * Normalized (x,y) = -2,93
    * Motor (Left,Right) = 133,133
  * When Joystick full down (full reverse):
    * Raw: (x,y) = 120,29
    * Normalized (x,y) = -7,-99
    * Motor (Left,Right) = 51,50
  * When Joystick full right (spin):
    * Raw: (x,y) = 221,130
    * Normalized (x,y) = 95,3
    * Motor (Left,Right) = 135,55
  * When Joystick full left (spin):
    * Raw: (x,y) = 29,126
    * Normalized (x,y) = -99,-1
    * Motor (Left,Right) = 139,50

This suggest that:
  * Raw values range from about 29 to 221 for the joystick, with a center value of 120.
  * Values appear to have 1 - 3 counts of noise.
  * Not sure that values are the same for all Wiimote Nunchucks.
  * Possible to get approximately a +/- 100 count value just by subtracting off the midpoint, maybe?
