# axi4lite_demo

Demonstrates the use of axi4_lite_master.v, both as a standalone module and as an integrated controller.  

The top level directory contains two versions of the project, one implemented on a Nexys A7-100T, the other on a Xilinx ZCU-104.  

When the user presses either the "up" or the "down" push-button on the dev board:
 - An ASCII string is transmitted on the serial port
 - A 4-bit count-value is read from 4 GPIO switches
 - Two LEDs are flashed <count value +1> times.




