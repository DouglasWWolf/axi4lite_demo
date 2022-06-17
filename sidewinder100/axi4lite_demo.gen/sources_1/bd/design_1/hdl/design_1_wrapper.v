//Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2021.1 (lin64) Build 3247384 Thu Jun 10 19:36:07 MDT 2021
//Date        : Fri Jun 17 11:45:09 2022
//Host        : simtool5-2 running 64-bit Ubuntu 20.04.4 LTS
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (CLK_100_N,
    CLK_100_P,
    CPU_RESET,
    GPIO_BTND,
    GPIO_BTNU,
    GPIO_LED,
    SIM_UART_TXD);
  input [0:0]CLK_100_N;
  input [0:0]CLK_100_P;
  input CPU_RESET;
  input GPIO_BTND;
  input GPIO_BTNU;
  output [3:0]GPIO_LED;
  output SIM_UART_TXD;

  wire [0:0]CLK_100_N;
  wire [0:0]CLK_100_P;
  wire CPU_RESET;
  wire GPIO_BTND;
  wire GPIO_BTNU;
  wire [3:0]GPIO_LED;
  wire SIM_UART_TXD;

  design_1 design_1_i
       (.CLK_100_N(CLK_100_N),
        .CLK_100_P(CLK_100_P),
        .CPU_RESET(CPU_RESET),
        .GPIO_BTND(GPIO_BTND),
        .GPIO_BTNU(GPIO_BTNU),
        .GPIO_LED(GPIO_LED),
        .SIM_UART_TXD(SIM_UART_TXD));
endmodule
