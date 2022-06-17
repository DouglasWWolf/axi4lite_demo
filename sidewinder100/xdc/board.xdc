##################################################################################
# Sidewinder XDC file for "axi4lite_demo"
##################################################################################


# Clock signal
set_property -dict {PACKAGE_PIN C4  IOSTANDARD LVDS_25} [get_ports CLK_100_P]
set_property -dict {PACKAGE_PIN C3  IOSTANDARD LVDS_25} [get_ports CLK_100_N]

# Create the clock
create_clock -period 10.000 -name sysclk100 [get_ports CLK_100_P]

# CPU Reset 
set_property -dict {PACKAGE_PIN A3 IOSTANDARD LVCMOS33} [get_ports {CPU_RESET}] ;# PB_SW[1]

# General purpose LEDs
set_property  -dict {PACKAGE_PIN B5 IOSTANDARD LVCMOS33} [get_ports { GPIO_LED[0] }]
set_property  -dict {PACKAGE_PIN A5 IOSTANDARD LVCMOS33} [get_ports { GPIO_LED[1] }]
set_property  -dict {PACKAGE_PIN A4 IOSTANDARD LVCMOS33} [get_ports { GPIO_LED[2] }]
set_property  -dict {PACKAGE_PIN C5 IOSTANDARD LVCMOS33} [get_ports { GPIO_LED[3] }]


# General purpose push-buttons
set_property -dict {PACKAGE_PIN B6  IOSTANDARD LVCMOS33}  [get_ports {GPIO_BTNU}] ;# PB_SW[0]
set_property -dict {PACKAGE_PIN B3  IOSTANDARD LVCMOS33}  [get_ports {GPIO_BTND}] ;# PB_SW[2] 


# UART2, the UART that is connected to the FPGA fabric
set_property -dict {PACKAGE_PIN D1  IOSTANDARD LVCMOS33}  [get_ports {SIM_UART_TXD}] ;# GPIO_LED[9] 

