`timescale 1ns / 1ps

//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 10-May-22  DWW  1000  Initial creation
//====================================================================================


module controller0#
(
    parameter integer AXI_DATA_WIDTH = 32,
    parameter integer AXI_ADDR_WIDTH = 32,
    parameter integer CLOCK_FREQ     = 100000000
)
(
    input CLK, RESETN, BUTTON,

    //================= The AMCI (AXI Master Control Interface) ================
    output wire[97:0] AMCI_MOSI,    // AMCI Master Out, Slave In
    input  wire[37:0] AMCI_MISO     // AMCI Master In, Slave Out
    //==========================================================================
);

    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    //      From here to the next marker is standard AMCI template code
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>


    //==========================================================================
    // Registers for performing AXI4-Lite write transactions
    //==========================================================================
    reg[AXI_ADDR_WIDTH-1:0] amci_waddr;
    reg[AXI_DATA_WIDTH-1:0] amci_wdata;
    reg[1:0]                amci_wresp;
    reg                     amci_write;
    reg                     amci_widle;
    //==========================================================================

    //==========================================================================
    // Registers for performing AXI4-Lite read transactions
    //==========================================================================
    reg[AXI_ADDR_WIDTH-1:0] amci_raddr;
    reg[AXI_DATA_WIDTH-1:0] amci_rdata;
    reg[1:0]                amci_rresp;
    reg                     amci_read;
    reg                     amci_ridle;
    //==========================================================================



    //==========================================================================
    // Break out the AMCI_MISO and AMCI_MISO interfaces into discrete ports
    //==========================================================================
    localparam AMCI_WADDR_OFFSET = 0;   localparam pa1 = AMCI_WADDR_OFFSET + AXI_ADDR_WIDTH;
    localparam AMCI_WDATA_OFFSET = pa1; localparam pa2 = AMCI_WDATA_OFFSET + AXI_DATA_WIDTH;
    localparam AMCI_RADDR_OFFSET = pa2; localparam pa3 = AMCI_RADDR_OFFSET + AXI_ADDR_WIDTH;
    localparam AMCI_WRITE_OFFSET = pa3; localparam pa4 = AMCI_WRITE_OFFSET + 1;
    localparam AMCI_READ_OFFSET  = pa4; localparam pa5 = AMCI_READ_OFFSET  + 1;

    localparam AMCI_RDATA_OFFSET = 0;   localparam pb1 = AMCI_RDATA_OFFSET + AXI_DATA_WIDTH;
    localparam AMCI_WIDLE_OFFSET = pb1; localparam pb2 = AMCI_WIDLE_OFFSET + 1;
    localparam AMCI_RIDLE_OFFSET = pb2; localparam pb3 = AMCI_RIDLE_OFFSET + 1;
    localparam AMCI_WRESP_OFFSET = pb3; localparam pb4 = AMCI_WRESP_OFFSET + 2;
    localparam AMCI_RRESP_OFFSET = pb4; localparam pb5 = AMCI_RRESP_OFFSET + 2;
    //==========================================================================


    //==========================================================================
    // Wire the "write-to-slave" FSM inputs and outputs to the module ports
    //==========================================================================
    always @(*) begin
        amci_widle <= AMCI_MISO[AMCI_WIDLE_OFFSET +: 1];
        amci_wresp <= AMCI_MISO[AMCI_WRESP_OFFSET +: 2];
    end

    assign AMCI_MOSI[AMCI_WADDR_OFFSET +: AXI_ADDR_WIDTH] = amci_waddr;
    assign AMCI_MOSI[AMCI_WDATA_OFFSET +: AXI_DATA_WIDTH] = amci_wdata;
    assign AMCI_MOSI[AMCI_WRITE_OFFSET +: 1             ] = amci_write;
    //==========================================================================

    //==========================================================================
    // Wire the "read-from-slave" FSM inputs and outputs to the module ports
    //==========================================================================
    always @(*) begin
        amci_ridle <= AMCI_MISO[AMCI_RIDLE_OFFSET +: 1             ];
        amci_rresp <= AMCI_MISO[AMCI_RRESP_OFFSET +: 2             ];
        amci_rdata <= AMCI_MISO[AMCI_RDATA_OFFSET +: AXI_DATA_WIDTH];
    end

    assign AMCI_MOSI[AMCI_RADDR_OFFSET +: AXI_ADDR_WIDTH] = amci_raddr;
    assign AMCI_MOSI[AMCI_READ_OFFSET  +: 1             ] = amci_read;
    //==========================================================================


    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    //                 End of standard AMCI template code
    //
    //                Module specific code below this point
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

    genvar x;

    localparam AXI_ADDR_GPIO_LED  = 32'h4000_0000;
    localparam AXI_ADDR_GPIO_SW   = 32'h4001_0000;
    localparam AXI_ADDR_UART      = 32'h4060_0000;
    localparam UART_TX_FIFO       = AXI_ADDR_UART + 4;

    localparam LED_BITS           = 3;
    localparam MSG_LEN            = 128;
    
    reg[ 2:0] state;
    reg[ 4:0] blink_count;
    reg[31:0] counter;
    reg[ 7:0] msg_index;

    // This is message buffer we're going to print to the UART
    reg[MSG_LEN*8-1:0] msg;
    
    // This is a byte array, with one byte for each 8-bits in the 'msg' buffer
    wire[7:0] msg_chr[0:MSG_LEN-1];
    
    // Map the 'msg_chr' byte array onto the message buffer
    for (x=0; x<MSG_LEN; x=x+1) assign msg_chr[x] = msg[8*(MSG_LEN-1-x) +: 8];

    always @(posedge CLK) begin
        amci_read  <= 0;
        amci_write <= 0;

        // The counter always counts down to zero
        if (counter) counter <= counter - 1;

        if (RESETN == 0) begin
            state <= 0;
        end else case(state)

        // If the user pushes the button, set up to print a message to the UART
        0:  if (BUTTON) begin
                msg_index <= 0;
                msg       <= "Hello from push-button #1\r\n";
                state     <= state + 1;
            end

        1:  begin
                if (msg_chr[msg_index]) begin           // If this character isn't nul...
                    amci_waddr <= UART_TX_FIFO;         //   We're going to send it to the UART
                    amci_wdata <= msg_chr[msg_index];   //   Fetch the character we want to send
                    amci_write <= 1;                    //   Begin the AXI-write transaction
                    state      <= state + 1;            //   And go wait for the transaction to complete
                end
                msg_index <= msg_index + 1;             // In any case, point to the next character
            end

        2:  if (amci_widle) begin                       // If the write to the UART has completed...
                if (amci_wresp[1])                      //   If a SLVERR occured (i.e, UART FIFO is full)...
                    amci_write <= 1;                    //     retransmit the character
                else if (msg_index == MSG_LEN) begin    //   Otherwise, if we're done sending the msg...
                    amci_raddr <= AXI_ADDR_GPIO_SW;     //     we're going to read the GPIO switches
                    amci_read  <= 1;                    //     start that AXI-read transaction
                    state      <= state + 1;            //     and go wait for the read to complete
                end else                                //   Otherwise, we're still in mid-message...
                    state <= state -1;                  //     so go send the next byte of the message
            end
        
        3:  if (amci_ridle) begin                       // If the read-transaction is complete...
                blink_count <= amci_rdata + 1;          //   blink_count is derived from the switches
                counter     <= 0;                       //   We don't want to wait for the next state
                state       <= state + 1;               //   And go turn on the LEDs
            end
        
        4:  if (counter == 0) begin                     // If the timer has expired...
                amci_waddr <= AXI_ADDR_GPIO_LED;        //   We're going to write to the LED GPIO 
                amci_wdata <= LED_BITS;                 //   These are the LEDs we're going to turn on
                amci_write <= 1;                        //   Start the AXI-write transaction
                counter    <= CLOCK_FREQ / 5;           //   Start a 1/5th of a second timer
                state      <= state + 1;                //   And go wait for the timer to expire
            end

        5:  if (counter == 0) begin                     // If the timer has expired...
                amci_waddr  <= AXI_ADDR_GPIO_LED;       //   We're going to write to the LED GPIO
                amci_wdata  <= 0;                       //   We're going to turn off all LEDs
                amci_write  <= 1;                       //   Start the AXI-write transaction
                counter     <= CLOCK_FREQ / 5;          //   Start a 1/5th of a second timer
                state       <= (blink_count == 1) ? 0 : state-1; // Should we go turn the LEDs back on?
                blink_count <= blink_count - 1;         //   We now have one less blink to perform
            end

        endcase
    end


endmodule