`timescale 1ns / 1ps

//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 10-May-22  DWW  1000  Initial creation
//====================================================================================


module controller1#
(
    parameter integer AXI_DATA_WIDTH = 32,
    parameter integer AXI_ADDR_WIDTH = 32,
    parameter integer CLOCK_FREQ     = 100000000
)
(
    input BUTTON,   

    //================ From here down is the AXI4-Lite interface ===============
    input wire  M_AXI_ACLK,
    input wire  M_AXI_ARESETN,
        
    // "Specify write address"              -- Master --    -- Slave --
    output wire [AXI_ADDR_WIDTH-1 : 0]      M_AXI_AWADDR,   
    output wire                             M_AXI_AWVALID,  
    input  wire                                             M_AXI_AWREADY,
    output wire  [2 : 0]                    M_AXI_AWPROT,

    // "Write Data"                         -- Master --    -- Slave --
    output wire [AXI_DATA_WIDTH-1 : 0]      M_AXI_WDATA,      
    output wire                             M_AXI_WVALID,
    output wire [(AXI_DATA_WIDTH/8)-1:0]    M_AXI_WSTRB,
    input  wire                                             M_AXI_WREADY,

    // "Send Write Response"                -- Master --    -- Slave --
    input  wire [1 : 0]                                     M_AXI_BRESP,
    input  wire                                             M_AXI_BVALID,
    output wire                             M_AXI_BREADY,

    // "Specify read address"               -- Master --    -- Slave --
    output wire [AXI_ADDR_WIDTH-1 : 0]      M_AXI_ARADDR,     
    output wire                             M_AXI_ARVALID,
    output wire [2 : 0]                     M_AXI_ARPROT,     
    input  wire                                             M_AXI_ARREADY,

    // "Read data back to master"           -- Master --    -- Slave --
    input  wire [AXI_DATA_WIDTH-1 : 0]                      M_AXI_RDATA,
    input  wire                                             M_AXI_RVALID,
    input  wire [1 : 0]                                     M_AXI_RRESP,
    output wire                             M_AXI_RREADY
    //==========================================================================

);

    localparam AXI_DATA_BYTES = (AXI_DATA_WIDTH/8);

    // Define the handshakes for all 5 AXI channels
    wire B_HANDSHAKE  = M_AXI_BVALID  & M_AXI_BREADY;
    wire R_HANDSHAKE  = M_AXI_RVALID  & M_AXI_RREADY;
    wire W_HANDSHAKE  = M_AXI_WVALID  & M_AXI_WREADY;
    wire AR_HANDSHAKE = M_AXI_ARVALID & M_AXI_ARREADY;
    wire AW_HANDSHAKE = M_AXI_AWVALID & M_AXI_AWREADY;

    //=========================================================================================================
    // FSM logic used for writing to the slave device.
    //
    //  To start:   amci_waddr = Address to write to
    //              amci_wdata = Data to write at that address
    //              amci_write = Pulsed high for one cycle
    //
    //  At end:     Write is complete when "amci_widle" goes high
    //              amci_wresp = AXI_BRESP "write response" signal from slave
    //=========================================================================================================
    reg[1:0]                    write_state = 0;

    // FSM user interface inputs
    reg[AXI_ADDR_WIDTH-1:0]     amci_waddr;
    reg[AXI_DATA_WIDTH-1:0]     amci_wdata;
    reg                         amci_write;

    // FSM user interface outputs
    wire                        amci_widle = (write_state == 0 && amci_write == 0);     
    reg[1:0]                    amci_wresp;

    // AXI registers and outputs
    reg[AXI_ADDR_WIDTH-1:0]     m_axi_awaddr;
    reg[AXI_DATA_WIDTH-1:0]     m_axi_wdata;
    reg                         m_axi_awvalid = 0;
    reg                         m_axi_wvalid = 0;
    reg                         m_axi_bready = 0;

    // Wire up the AXI interface outputs
    assign M_AXI_AWADDR  = m_axi_awaddr;
    assign M_AXI_WDATA   = m_axi_wdata;
    assign M_AXI_AWVALID = m_axi_awvalid;
    assign M_AXI_WVALID  = m_axi_wvalid;
    assign M_AXI_AWPROT  = 3'b000;
    assign M_AXI_WSTRB   = (1 << AXI_DATA_BYTES) - 1; // usually 4'b1111
    assign M_AXI_BREADY  = m_axi_bready;
    //=========================================================================================================
     
    always @(posedge M_AXI_ACLK) begin

        // If we're in RESET mode...
        if (M_AXI_ARESETN == 0) begin
            write_state   <= 0;
            m_axi_awvalid <= 0;
            m_axi_wvalid  <= 0;
            m_axi_bready  <= 0;
        end        
        
        // Otherwise, we're not in RESET and our state machine is running
        else case (write_state)
            
            // Here we're idle, waiting for someone to raise the 'amci_write' flag.  Once that happens,
            // we'll place the user specified address and data onto the AXI bus, along with the flags that
            // indicate that the address and data values are valid
            0:  if (amci_write) begin
                    m_axi_awaddr    <= amci_waddr;  // Place our address onto the bus
                    m_axi_wdata     <= amci_wdata;  // Place our data onto the bus
                    m_axi_awvalid   <= 1;           // Indicate that the address is valid
                    m_axi_wvalid    <= 1;           // Indicate that the data is valid
                    m_axi_bready    <= 1;           // Indicate that we're ready for the slave to respond
                    write_state     <= 1;           // On the next clock cycle, we'll be in the next state
                end
                
           // Here, we're waiting around for the slave to acknowledge our request by asserting M_AXI_AWREADY
           // and M_AXI_WREADY.  Once that happens, we'll de-assert the "valid" lines.  Keep in mind that we
           // don't know what order AWREADY and WREADY will come in, and they could both come at the same
           // time.      
           1:   begin   
                    // Keep track of whether we have seen the slave raise AWREADY or WREADY
                    if (AW_HANDSHAKE) m_axi_awvalid <= 0;
                    if (W_HANDSHAKE ) m_axi_wvalid  <= 0;

                    // If we've seen AWREADY (or if its raised now) and if we've seen WREADY (or if it's raised now)...
                    if ((~m_axi_awvalid || AW_HANDSHAKE) && (~m_axi_wvalid || W_HANDSHAKE)) begin
                        write_state <= 2;
                    end
                end
                
           // Wait around for the slave to assert "M_AXI_BVALID".  When it does, we'll save the 
           // write-response, lower M_AXI_BREADY, and go back to waiting for a start signal
           2:   if (B_HANDSHAKE) begin
                    amci_wresp   <= M_AXI_BRESP;
                    m_axi_bready <= 0;
                    write_state  <= 0;
                end

        endcase
    end
    //=========================================================================================================





    //=========================================================================================================
    // FSM logic used for reading from a slave device.
    //
    //  To start:   amci_raddr = Address to read from
    //              amci_read  = Pulsed high for one cycle
    //
    //  At end:   Read is complete when "amci_ridle" goes high.
    //            amci_rdata = The data that was read
    //            amci_rresp = The AXI "read response" that is used to indicate success or failure
    //=========================================================================================================
    reg                         read_state = 0;

    // FSM user interface inputs
    reg[AXI_ADDR_WIDTH-1:0]     amci_raddr;
    reg                         amci_read;

    // FSM user interface outputs
    reg[AXI_DATA_WIDTH-1:0]     amci_rdata;
    reg[1:0]                    amci_rresp;
    wire                        amci_ridle = (read_state == 0 && amci_read == 0);     

    // AXI registers and outputs
    reg[AXI_ADDR_WIDTH-1:0]     m_axi_araddr;
    reg                         m_axi_arvalid = 0;
    reg                         m_axi_rready;

    // Wire up the AXI interface outputs
    assign M_AXI_ARADDR  = m_axi_araddr;
    assign M_AXI_ARVALID = m_axi_arvalid;
    assign M_AXI_ARPROT  = 3'b001;
    assign M_AXI_RREADY  = m_axi_rready;
    //=========================================================================================================
    always @(posedge M_AXI_ACLK) begin
         
        if (M_AXI_ARESETN == 0) begin
            read_state    <= 0;
            m_axi_arvalid <= 0;
            m_axi_rready  <= 0;
        end else case (read_state)

            // Here we are waiting around for someone to raise "amci_read", which signals us to begin
            // a AXI read at the address specified in "amci_raddr"
            0:  if (amci_read) begin
                    m_axi_araddr  <= amci_raddr;
                    m_axi_arvalid <= 1;
                    m_axi_rready  <= 1;
                    read_state    <= 1;
                end else begin
                    m_axi_arvalid <= 0;
                    m_axi_rready  <= 0;
                    read_state    <= 0;
                end
            
            // Wait around for the slave to raise M_AXI_RVALID, which tells us that M_AXI_RDATA
            // contains the data we requested
            1:  begin
                    if (AR_HANDSHAKE) begin
                        m_axi_arvalid <= 0;
                    end

                    if (R_HANDSHAKE) begin
                        amci_rdata    <= M_AXI_RDATA;
                        amci_rresp    <= M_AXI_RRESP;
                        m_axi_rready  <= 0;
                        read_state    <= 0;
                    end
                end

        endcase
    end
    //=========================================================================================================


    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    //                 End of standard AXI4-Lite master code
    //
    //                Module specific code below this point
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

    wire CLK    = M_AXI_ACLK;
    wire RESETN = M_AXI_ARESETN;

    genvar x;

    localparam AXI_ADDR_GPIO_LED  = 32'h4000_0000;
    localparam AXI_ADDR_GPIO_SW   = 32'h4001_0000;
    localparam AXI_ADDR_UART      = 32'h4060_0000;
    localparam UART_TX_FIFO       = AXI_ADDR_UART + 4;

    localparam LED_BITS           = 12;
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
                msg       <= "Hello from push-button #2\r\n";
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