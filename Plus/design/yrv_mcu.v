/*******************************************************************************************/
/**                                                                                       **/
/** Copyright 2021 Monte J. Dalrymple                                                     **/
/**                                                                                       **/
/** SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1                                      **/
/**                                                                                       **/
/** Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may not use  **/
/** this file except in compliance with the License, or, at your option, the Apache       **/
/** License version 2.0. You may obtain a copy of the License at                          **/
/**                                                                                       **/
/** https://solderpad.org/licenses/SHL-2.1/                                               **/
/**                                                                                       **/
/** Unless required by applicable law or agreed to in writing, any work distributed under **/
/** the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF   **/
/** ANY KIND, either express or implied. See the License for the specific language        **/
/** governing permissions and limitations under the License.                              **/
/**                                                                                       **/
/** YRV simple mcu system                                             Rev 0.0  03/29/2021 **/
/**                                                                                       **/
/*******************************************************************************************/
`define IO_BASE   16'hffff                                 /* msword of i/o address        */
`define IO_PORT10 14'h0000                                 /* lsword of port 1/0 address   */
`define IO_PORT32 14'h0001                                 /* lsword of port 3/2 address   */
`define IO_PORT54 14'h0002                                 /* lsword of port 5/4 address   */
`define IO_PORT76 14'h0003                                 /* lsword of port 7/6 address   */

`define MEM_BASE  16'h0000                                 /* msword of mem address        */
`define VGA_BASE_0  16'hA000                                 /* msword of mem address        */
`define VGA_BASE_1  16'hA001                                 /* msword of mem address        */


`define IO_PORT0 15'h0000                                 /* lsword of port 0 address   */
`define IO_PORT1 15'h0001                                 /* lsword of port 1 address   */
`define IO_PORT2 15'h0002                                 /* lsword of port 2 address   */
`define IO_PORT3 15'h0003                                 /* lsword of port 3 address   */
`define IO_PORT4 15'h0004                                 /* lsword of port 4 address   */
`define IO_PORT5 15'h0005                                 /* lsword of port 5 address   */
`define IO_PORT6 15'h0006                                 /* lsword of port 6 address   */
`define IO_PORT7 15'h0007                                 /* lsword of port 7 address   */
`define IO_PORT8 15'h0008                                 /* lsword of port 8 address   */
`define IO_PORT9 15'h0009                                 /* lsword of port 9 address   */
`define IO_PORT_MIDI 15'h000A                                /* lsword of port 9 address midi  */





/* processor                                                                               */
`include "yrv_top.v"

`ifdef INSTANCE_MEM
/* instantiated memory                                                                     */
`include "inst_mem.v"
`endif

`ifdef BOOT_FROM_AUX_UART
`include "boot_hex_parser.sv"
`include "boot_uart_receiver.sv"
`endif

module yrv_mcu  (debug_mode, port0_reg, port1_reg, port2_reg, port3_reg, ser_txd,midi_ser_txd,
                 wfi_state, clk, ei_req, nmi_req, port4_in, port5_in, resetb, ser_rxd
                `ifdef BOOT_FROM_AUX_UART
                 , aux_uart_rx
                 `endif
                 `ifdef EXPOSE_MEM_BUS
                 , mem_ready, mem_rdata, mem_lock, mem_write, mem_trans, mem_ble,
                 mem_addr, mem_wdata, extra_debug_data
                 `endif
                 , port8_in, port9_in, real_clk
  );

  input         clk;                                       /* cpu clock                    */
  input         ei_req;                                    /* external int request         */
  input         nmi_req;                                   /* non-maskable interrupt       */
  input         resetb;                                    /* master reset                 */
  input         ser_rxd;                                   /* receive data input           */
  input  [15:0] port4_in;                                  /* port 4                       */
  input  [15:0] port5_in;                                  /* port 5                       */
  input  [15:0] port8_in;
  input  [15:0] port9_in;                                  /* port 5                       */

  output        debug_mode;                                /* in debug mode                */
  output        ser_txd;                                   /* transmit data output         */
  output        wfi_state;                                 /* waiting for interrupt        */
  output [15:0] port0_reg;                                 /* port 0                       */
  output [15:0] port1_reg;                                 /* port 1                       */
  output [15:0] port2_reg;                                 /* port 2                       */
  output [15:0] port3_reg;                                 /* port 3                       */

`ifdef BOOT_FROM_AUX_UART
  input         aux_uart_rx;                               /* auxiliary UART receive pin   */
`endif

`ifdef EXPOSE_MEM_BUS
  output        mem_ready;                                 /* memory ready                 */
  output  [31:0] mem_rdata;                                 /* memory read data             */
  output        mem_lock;                                  /* memory lock (rmw)            */
  output        mem_write;                                 /* memory write enable          */
  output  [1:0] mem_trans;                                 /* memory transfer type         */
  output  [3:0] mem_ble;                                   /* memory byte lane enables     */
  output [31:0] mem_addr;                                  /* memory address               */
  output [31:0] mem_wdata;                                 /* memory write data            */

  output [31:0] extra_debug_data;                          /* extra debug data unconnected */
`endif
  input         real_clk;
  output        midi_ser_txd;
  /*****************************************************************************************/
  /* signal declarations                                                                   */
  /*****************************************************************************************/
  wire          bufr_done;                                 /* serial tx done sending       */
  wire          bufr_empty;                                /* serial tx buffer empty       */
  wire          bufr_full;                                 /* serial rx buffer full        */
  wire          bufr_ovr;                                  /* serial rx buffer overrun     */

  wire          midi_bufr_done;                                 /* serial tx done sending       */
  wire          midi_bufr_empty;                                /* serial tx buffer empty       */
  wire          midi_bufr_full;                                 /* serial rx buffer full        */
  wire          midi_bufr_ovr;                                  /* serial rx buffer overrun     */
  wire          midi_ld_wdata;                                  /* serial port write            */
  wire          midi_ser_txd;                                   /* transmit data output         */
 


  wire          bus_32;                                    /* 32-bit bus select            */
  wire          debug_mode;                                /* in debug mode                */
  wire          ld_wdata;                                  /* serial port write            */
  wire          mem_ready;                                 /* memory ready                 */
  wire          mem_write;                                 /* memory write enable          */
  wire          port10_dec, port32_dec;                    /* i/o port decodes             */
  wire          port54_dec, port76_dec;
  
  wire          port0_dec, port1_dec;                    /* i/o port decodes             */
  wire          port2_dec, port3_dec;
  wire          port4_dec, port5_dec;                    /* i/o port decodes             */
  wire          port6_dec, port7_dec;
  wire          port8_dec, port9_dec;
  wire          portMIDI_dec;
  
  wire          rd_rdata;                                  /* serial port read             */
  wire          ser_clk;                                   /* serial clk output (cks mode) */
  wire          ser_txd;                                   /* transmit data output         */
  wire          wfi_state;                                 /* waiting for interrupt        */
  wire    [1:0] mem_trans;                                 /* memory transfer type         */
  wire    [3:0] mem_ble;                                   /* memory byte lane enables     */
  wire    [7:0] rx_rdata;                                  /* receive data buffer          */
  wire   [15:0] li_req;                                    /* local int requests           */
  wire   [15:0] port7_dat;                                 /* i/o port                     */
  wire   [15:0] portMIDI_dat;                                 /* i/o port                     */
  wire   [31:0] mcu_rdata;                                 /* system memory read data      */
  wire   [31:0] mem_addr;                                  /* memory address               */
  wire   [31:0] mem_wdata;                                 /* memory write data            */

  reg           io_rd_reg;                                 /* i/o read                     */
  reg           io_wr_reg;                                 /* i/o write                    */
  reg           mem_rd_reg;                                /* mem read                     */
  reg           mem_wr_reg;                                /* mem write                    */
  reg     [3:0] mem_ble_reg;                               /* reg'd memory byte lane en    */
  reg    [15:0] port0_reg,  port1_reg;                     /* i/o ports                    */
  reg    [15:0] port2_reg,  port3_reg;
  reg    [15:0] port4_reg,  port5_reg;
  reg    [15:0] port6_reg,  port7_reg;
  reg    [15:0] port8_reg,  port9_reg;
  reg    [15:0] portMIDI_reg;
  reg    [15:0] mem_addr_reg;                              /* reg'd memory address         */

// `ifdef INSTANCE_MEM
//   wire   [31:0] mem_rdata;                                 /* raw read data                */
// `else
  wire    [3:0] mem_wr_byte;                               /* system ram byte enables      */
	// reg     [7:0] mcu_mem [0:1024*16];                          /* system ram                   */
  reg     [7:0] mcu_mem0 [0:1024*32];                          /* system ram                   */
	reg     [7:0] mcu_mem1 [0:1024*32];                          /* system ram                   */
  reg    [31:0] mem_rdata;                                 /* raw read data                */
// `endif

  // wire   [31:0] mem_rdata;                                 /* raw read data                */

  

  /*****************************************************************************************/
  /* 32-bit bus, no wait states, internal local interrupts                                 */
  /*****************************************************************************************/
  assign bus_32    = 1'b0;
  assign mem_ready = 1'b1;
  assign li_req    = {12'h0, bufr_empty, bufr_done, bufr_full, bufr_ovr};

  /*****************************************************************************************/
  /* processor                                                                             */
  /*****************************************************************************************/

  wire [31:0] top_mem_addr;
  wire [ 3:0] top_mem_ble;
  wire [ 1:0] top_mem_trans;
  wire [31:0] top_mem_wdata;
  wire        top_mem_write;
  wire        top_resetb;

  yrv_top YRV     ( .csr_achk(), .csr_addr(), .csr_read(), .csr_wdata(), .csr_write(),
                    .debug_mode(debug_mode), .ebrk_inst(), .mem_addr(top_mem_addr),
                    .mem_ble(top_mem_ble), .mem_lock(), .mem_trans(top_mem_trans),
                    .mem_wdata(top_mem_wdata), .mem_write(top_mem_write), .timer_en(),
                    .wfi_state(wfi_state), .brk_req(1'b0), .bus_32(bus_32), .clk(clk),
                    .csr_ok_ext(1'b0), .csr_rdata(32'h0), .dbg_req(1'b0),
                    .dresetb(resetb), .ei_req(ei_req), .halt_reg(1'b0), .hw_id(10'h0),
                    .li_req(li_req), .mem_rdata(mcu_rdata), .mem_ready(mem_ready),
                    .nmi_req(nmi_req), .resetb(top_resetb), .sw_req(1'b0),
                    .timer_match(1'b0), .timer_rdata(64'h0) );

  /*****************************************************************************************/
  /* external boot                                                                         */
  /*****************************************************************************************/

`ifdef BOOT_FROM_AUX_UART

  wire [7:0] aux_uart_byte_data;
  wire       aux_uart_byte_valid;

  boot_uart_receiver
  # (
    .clk_frequency ( `CLK_FREQUENCY )
  )
  BOOT_UART_RECEIVER
  (
    .clk        ( clk                 ),
    .reset      ( ~ resetb            ),
    .rx         ( aux_uart_rx         ),
    .byte_valid ( aux_uart_byte_valid ),
    .byte_data  ( aux_uart_byte_data  )
  );

  wire        boot_valid;
  wire [31:0] boot_address;
  wire [31:0] boot_data;   
  wire        boot_busy;
  wire        boot_error;

 //localparam boot_address_width = $clog2 (4095*4);
  localparam boot_address_width = $clog2 (32768);
  wire [boot_address_width - 1:0] boot_address_narrow;
  assign boot_address = 32' (boot_address_narrow);

  boot_hex_parser
  # (
    .address_width      ( boot_address_width ),
    .data_width         ( 16                 ),
    .clk_frequency      ( `CLK_FREQUENCY     ),
    .timeout_in_seconds ( 2                  )
  )
  BOOT_HEX_PARSER
  (
    .clk          ( clk                 ),
    .reset        ( ~ resetb            ),

    .in_valid     ( aux_uart_byte_valid ),
    .in_char      ( aux_uart_byte_data  ),

    .out_valid    ( boot_valid          ),
    .out_address  ( boot_address_narrow ),
    .out_data     ( boot_data           ),

    .busy         ( boot_busy           ),
    .error        ( boot_error          )
  );

  reg boot_valid_reg;

  always @ (posedge clk)
    if (~ resetb)
      boot_valid_reg <= 1'b0;
    else
      boot_valid_reg <= boot_valid;

  reg [31:0] boot_data_reg;

  always @ (posedge clk)
    boot_data_reg <= boot_data;

  assign mem_addr   = boot_busy ?       boot_address      : top_mem_addr;
  assign mem_ble    = boot_busy ? { 1'b0, 1'b0, boot_valid, boot_valid } : top_mem_ble;
  assign mem_trans  = boot_busy ? { 2 { boot_valid    } } : top_mem_trans;
  assign mem_wdata  = boot_busy ?       boot_data_reg     : top_mem_wdata;
  assign mem_write  = boot_busy ?       boot_valid        : top_mem_write;

  assign top_resetb = ~ (~ resetb | boot_busy);

`else

  assign mem_addr   = top_mem_addr;
  assign mem_ble    = top_mem_ble;
  assign mem_trans  = top_mem_trans;
  assign mem_wdata  = top_mem_wdata;
  assign mem_write  = top_mem_write;
  assign top_resetb = resetb;

`endif

  assign mem_wr_byte = {4{mem_wr_reg}} & mem_ble_reg & {4{mem_ready}};


  always @ (posedge clk) begin
    if (mem_trans[0]) begin
      mem_rdata[15:8]  <= mcu_mem0[mem_addr[15:1]];
      mem_rdata[7:0]   <= mcu_mem1[mem_addr[15:1]];
      end
    if (mem_wr_byte[1]) mcu_mem0[mem_addr_reg[15:1]] <= mem_wdata[15:8];
    if (mem_wr_byte[0]) mcu_mem1[mem_addr_reg[15:1]] <= mem_wdata[7:0];
    end

  /*****************************************************************************************/
  /* bus interface                                                                         */
  /*****************************************************************************************/
  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      mem_addr_reg <= 16'h0;
      mem_ble_reg  <=  4'h0;
      io_rd_reg    <=  1'b0;
      io_wr_reg    <=  1'b0;
      mem_rd_reg   <=  1'b0;
      mem_wr_reg   <=  1'b0;
      end
    else if (mem_ready) begin
      mem_addr_reg <= mem_addr[15:0];
      mem_ble_reg  <= mem_ble;
      io_rd_reg    <= !mem_write &&  mem_trans[0] && (mem_addr[31:16] == `IO_BASE);
      io_wr_reg    <=  mem_write && &mem_trans    && (mem_addr[31:16] == `IO_BASE);
      mem_rd_reg   <= !mem_write &&  mem_trans[0] && (mem_addr[31:16] == `MEM_BASE);
      mem_wr_reg   <=  mem_write && &mem_trans    && (mem_addr[31:16] == `MEM_BASE);
      end
    end

  assign port0_dec = (mem_addr_reg[15:1] == `IO_PORT0);
  assign port1_dec = (mem_addr_reg[15:1] == `IO_PORT1);
  assign port2_dec = (mem_addr_reg[15:1] == `IO_PORT2);
  assign port3_dec = (mem_addr_reg[15:1] == `IO_PORT3);
  assign port4_dec = (mem_addr_reg[15:1] == `IO_PORT4);
  assign port5_dec = (mem_addr_reg[15:1] == `IO_PORT5);
  assign port6_dec = (mem_addr_reg[15:1] == `IO_PORT6);
  assign port7_dec = (mem_addr_reg[15:1] == `IO_PORT7);
  assign port8_dec = (mem_addr_reg[15:1] == `IO_PORT8);
  assign port9_dec = (mem_addr_reg[15:1] == `IO_PORT9);
  assign portMIDI_dec = (mem_addr_reg[15:1] == `IO_PORT_MIDI);

  assign mcu_rdata  = (mem_rd_reg) ? mem_rdata :
                      (port0_dec)  ? port0_reg :
                      (port1_dec)  ? port1_reg :
                      (port2_dec)  ? port2_reg :
                      (port3_dec)  ? port3_reg :
                      (port4_dec)  ? port4_reg :
                      (port5_dec)  ? port5_reg :
                      (port6_dec)  ? port6_reg :
                      (port7_dec)  ? port7_dat :
                      (port8_dec)  ? port8_reg :
                      (port9_dec)  ? port9_reg :
                      (portMIDI_dec) ? portMIDI_dat : 32'h0;


  /*****************************************************************************************/
  /* parallel ports                                                                        */
  /*****************************************************************************************/
  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      port0_reg <= 16'h0;
      port1_reg <= 16'h0;
      port2_reg <= 16'h0;
      port3_reg <= 16'h0;
      port4_reg <= 16'h0;
      port5_reg <= 16'h0;
      port6_reg <= 16'h0;
      port7_reg <= 16'h0;
      port8_reg <= 16'h0;
      port9_reg <= 16'h0;
      portMIDI_reg <= 16'h0;
      end
    else begin
      if (io_wr_reg && port0_dec && mem_ready) begin
        if (mem_ble_reg[1]) port0_reg[15:8] <= mem_wdata[15:8];
        if (mem_ble_reg[0]) port0_reg[7:0]  <= mem_wdata[7:0];
        end
      if (io_wr_reg && port1_dec && mem_ready) begin
        if (mem_ble_reg[1]) port1_reg[15:8] <= mem_wdata[15:8];
        if (mem_ble_reg[0]) port1_reg[7:0]  <= mem_wdata[7:0];
        end
      if (io_wr_reg && port2_dec && mem_ready) begin
        if (mem_ble_reg[1]) port2_reg[15:8] <= mem_wdata[15:8];
        if (mem_ble_reg[0]) port2_reg[7:0]  <= mem_wdata[7:0];
        end
      if (io_wr_reg && port3_dec && mem_ready) begin
        if (mem_ble_reg[1]) port3_reg[15:8] <= mem_wdata[15:8];
        if (mem_ble_reg[0]) port3_reg[7:0]  <= mem_wdata[7:0];
        end  
      port4_reg <= port4_in;
      port5_reg <= port5_in;
      port8_reg <= port8_in;
      port9_reg <= port9_in;
      
      if (io_wr_reg && port6_dec && mem_ready) begin
        if (mem_ble_reg[1]) port6_reg[15:8] <= mem_wdata[15:8];
        if (mem_ble_reg[0]) port6_reg[7:0]  <= mem_wdata[7:0];
        end

      if (io_wr_reg && port7_dec && mem_ready) begin
        if (mem_ble_reg[0]) port7_reg[7:0] <= mem_wdata[7:0];
        end
   
      if (io_wr_reg && portMIDI_dec && mem_ready) begin
        if (mem_ble_reg[0]) portMIDI_reg[7:0] <= mem_wdata[7:0];
        end
      end
    end

  // /*****************************************************************************************/
  // /* serial port                                                                           */
  // /*****************************************************************************************/
  //  uart SERIAL (.clk(real_clk), .reset(~resetb), .rd_uart(rd_rdata),
  //      .wr_uart(ld_wdata), .rx(ser_rxd), .w_data(mem_wdata[7:0]),
  //      .tx_full(bufr_full), .rx_empty(bufr_empty),
  //      .r_data(rx_rdata), .tx(ser_txd));

// Clock frequency in hertz.
//parameter CLK_HZ = 50000000;
parameter CLK_HZ = 12500000;

parameter BIT_RATE =   9600;
parameter PAYLOAD_BITS = 8;


//
// UART RX
uart_rx #(
.BIT_RATE(BIT_RATE),
.PAYLOAD_BITS(PAYLOAD_BITS),
.CLK_HZ  (CLK_HZ  )
) i_uart_rx(
.clk          (clk     ), // Top level system clock input.
.resetn       (resetb        ), // Asynchronous active low reset.
.uart_rxd     (ser_rxd     ), // UART Recieve pin.
.uart_rx_en   (1'b1         ), // Recieve enable
.uart_rx_break(bufr_ovr), // Did we get a BREAK message?
.uart_rx_valid(bufr_empty), // Valid data recieved and available.
.uart_rx_data (rx_rdata )  // The recieved data.
);

//
// UART Transmitter module.
//
uart_tx #(
.BIT_RATE(BIT_RATE),
.PAYLOAD_BITS(PAYLOAD_BITS),
.CLK_HZ  (CLK_HZ  )
) i_uart_tx(
.clk          (clk     ),
.resetn       (resetb       ),
.uart_txd     (ser_txd      ),
.uart_tx_en   (ld_wdata     ),     // Send the data on uart_tx_data
.uart_tx_busy (bufr_full    ),   // Module busy sending previous item.
.uart_tx_data (mem_wdata[7:0])   // The data to be sent
);

  assign ld_wdata  = io_wr_reg && port7_dec && mem_ble_reg[0] && mem_ready;
  assign rd_rdata  = io_rd_reg && port7_dec && mem_ble_reg[0] && mem_ready;
  assign port7_dat = {5'h0, bufr_ovr, bufr_full, bufr_empty, rx_rdata};



// Clock frequency in hertz.
//parameter CLK_HZ = 50000000;

parameter MIDI_BIT_RATE = 19200;

//
// MIDI UART Transmitter module.
//
uart_tx #(
.BIT_RATE(MIDI_BIT_RATE),
.PAYLOAD_BITS(PAYLOAD_BITS),
.CLK_HZ  (CLK_HZ  )
) midi_uart_tx(
.clk          (clk     ),
.resetn       (resetb       ),
.uart_txd     (midi_ser_txd      ),
.uart_tx_en   (midi_ld_wdata     ),     // Send the data on uart_tx_data
.uart_tx_busy (midi_bufr_full    ),   // Module busy sending previous item.
.uart_tx_data (mem_wdata[7:0])   // The data to be sent
);

assign midi_ld_wdata  = io_wr_reg && portMIDI_dec && mem_ble_reg[0] && mem_ready;
assign portMIDI_dat = {7'h0, midi_bufr_full, 8'b0};

  endmodule
