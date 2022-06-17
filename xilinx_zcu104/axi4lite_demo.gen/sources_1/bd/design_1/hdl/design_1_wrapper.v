//Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2021.1 (lin64) Build 3247384 Thu Jun 10 19:36:07 MDT 2021
//Date        : Mon Jun 13 11:29:00 2022
//Host        : simtool5-2 running 64-bit Ubuntu 20.04.4 LTS
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (CLK_125_N,
    CLK_125_P,
    CPU_RESET,
    GPIO_BTND,
    GPIO_BTNU,
    GPIO_LED,
    GPIO_SW,
    UART2_TXD);
  input CLK_125_N;
  input CLK_125_P;
  input CPU_RESET;
  input GPIO_BTND;
  input GPIO_BTNU;
  output [3:0]GPIO_LED;
  input [3:0]GPIO_SW;
  output UART2_TXD;

  wire CLK_125_N;
  wire CLK_125_P;
  wire CPU_RESET;
  wire GPIO_BTND;
  wire GPIO_BTNU;
  wire [3:0]GPIO_LED;
  wire [3:0]GPIO_SW;
  wire UART2_TXD;

  design_1 design_1_i
       (.CLK_125_N(CLK_125_N),
        .CLK_125_P(CLK_125_P),
        .CPU_RESET(CPU_RESET),
        .GPIO_BTND(GPIO_BTND),
        .GPIO_BTNU(GPIO_BTNU),
        .GPIO_LED(GPIO_LED),
        .GPIO_SW(GPIO_SW),
        .UART2_TXD(UART2_TXD));
endmodule
