//Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2021.1 (lin64) Build 3247384 Thu Jun 10 19:36:07 MDT 2021
//Date        : Sat Jun 11 18:44:38 2022
//Host        : simtool5-2 running 64-bit Ubuntu 20.04.4 LTS
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (CLK100MHZ,
    CPU_RESETN,
    GPIO_BTNU,
    GPIO_LED,
    GPIO_SW,
    UART_TXD);
  input CLK100MHZ;
  input CPU_RESETN;
  input GPIO_BTNU;
  output [3:0]GPIO_LED;
  input [3:0]GPIO_SW;
  output UART_TXD;

  wire CLK100MHZ;
  wire CPU_RESETN;
  wire GPIO_BTNU;
  wire [3:0]GPIO_LED;
  wire [3:0]GPIO_SW;
  wire UART_TXD;

  design_1 design_1_i
       (.CLK100MHZ(CLK100MHZ),
        .CPU_RESETN(CPU_RESETN),
        .GPIO_BTNU(GPIO_BTNU),
        .GPIO_LED(GPIO_LED),
        .GPIO_SW(GPIO_SW),
        .UART_TXD(UART_TXD));
endmodule
