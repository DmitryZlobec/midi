`define INTEL_VERSION
`define CLK_FREQUENCY (12 * 1000 * 1000)

`include "yrv_mcu.v"

module top
(
  input              clk,
  input              reset_n,

  input        [3:0] key_sw,
  output       [3:0] led,

  output logic [7:0] abcdefgh,
  output logic [3:0] digit,

  output             buzzer,

  output             hsync,
  output             vsync,
  output       [2:0] rgb,

  output [16:0] sram_a,
  output        sram_n_cs1,
  output        sram_cs2,
  output        sram_n_oe,
  output        sram_n_we,
  inout  [7:0]  sram_io,
  input         ps2k_clk,
  input         ps2k_data,
  output        tx
`ifdef BOOT_FROM_AUX_UART
  ,
  input              rx
  `endif
);

  //--------------------------------------------------------------------------
  // Unused pins

  assign buzzer = 1'b1;


  //--------------------------------------------------------------------------
  // Slow clock button / switch

  wire slow_clk_mode = ~ key_sw [0];

  //--------------------------------------------------------------------------
  // MCU clock

  logic [22:0] clk_cnt;
  reg  [15:0] random;
  wire [15:0] w_random;  
  reg sec_clock;

  always @ (posedge clk or negedge reset_n)
    if (~ reset_n)
      clk_cnt <= '0;
    else
      clk_cnt <= clk_cnt + 1'd1;

  wire muxed_clk_raw
    = slow_clk_mode ? clk_cnt [22] : clk_cnt[1];

  wire sec_edge;

  assign sec_edge  = clk_cnt [22];
  
  always @(posedge sec_edge or negedge reset_n) begin 
    if(~reset_n) begin
      //  random <= 0;
       sec_clock  <= 0;
    end else begin
      sec_clock <=sec_clock +1;
      // random <= random +1;
    end
  end

  timer i_timer
  (
    .clk(clk        ), 
    .rst( ~ reset_n ), 
    .out_time(w_random)
 );
 
 
  always @ (posedge clk or negedge reset_n)
    if (~ reset_n)
      random <= 0;
    else
      random <= w_random;

 
//assign random = 16'hAA55;
  
  wire muxed_clk;
  wire video_clk;
  assign video_clk = clk_cnt[0];

  `ifdef SIMULATION
    assign muxed_clk = muxed_clk_raw;
  `else
    global i_global (.in (muxed_clk_raw), .out (muxed_clk));
  `endif

  //--------------------------------------------------------------------------
  // MCU inputs

  wire         ei_req;               // external int request
  wire         nmi_req   = 1'b0;     // non-maskable interrupt
  wire         resetb    = reset_n;  // master reset
  wire         ser_rxd;     // receive data input
  wire  [15:0] port4_in  = '0;
  wire  [15:0] port5_in  = '0;

  //--------------------------------------------------------------------------
  // MCU outputs

  wire         debug_mode;  // in debug mode
  wire         ser_clk;     // serial clk output (cks mode)
  wire         ser_txd;     // transmit data output
  wire         wfi_state;   // waiting for interrupt
  wire  [15:0] port0_reg;   // port 0
  wire  [15:0] port1_reg;   // port 1
  wire  [15:0] port2_reg;   // port 2
  wire  [15:0] port3_reg;   // port 3

  // Auxiliary UART receive pin

  `ifdef BOOT_FROM_AUX_UART
  wire         aux_uart_rx ;
  `endif

  // Exposed memory bus for debug purposes

  wire         mem_ready;   // memory ready
  wire  [31:0] mem_rdata;   // memory read data
  wire         mem_lock;    // memory lock (rmw)
  wire         mem_write;   // memory write enable
  wire   [1:0] mem_trans;   // memory transfer type
  wire   [3:0] mem_ble;     // memory byte lane enables
  wire  [31:0] mem_addr;    // memory address
  wire  [31:0] mem_wdata;   // memory write data

  wire  [31:0] extra_debug_data;


  //Memory bus interface
  reg    [15:0] mem_addr_reg;                              /* reg'd memory address         */
  reg     [3:0] mem_ble_reg;                               /* reg'd memory byte lane en    */



  //--------------------------------------------------------------------------
  // MCU instantiation

  yrv_mcu i_yrv_mcu (.clk (muxed_clk), .port4_in(key_code),.port5_in(random),.real_clk(clk),.*);

  //--------------------------------------------------------------------------
  // Pin assignments

  // The original board had port3_reg [13:8], debug_mode, wfi_state
  // assign led = port3_reg [11:8];
    assign led = 4'b1111;


  //--------------------------------------------------------------------------

  wire [7:0] abcdefgh_from_mcu =
  {
    port0_reg[6],
    port0_reg[5],
    port0_reg[4],
    port0_reg[3],
    port0_reg[2],
    port0_reg[1],
    port0_reg[0],
    port0_reg[7] 
  };

  wire [3:0] digit_from_mcu =
  {
    port1_reg [3],
    port1_reg [2],
    port1_reg [1],
    port1_reg [0]
  };

  //--------------------------------------------------------------------------

  wire [7:0] abcdefgh_from_show_mode;
  wire [3:0] digit_from_show_mode;

  logic [15:0] display_number;

  assign  aux_uart_rx = key_sw[3] ? rx : 1'b0;
  assign  ser_rxd = rx;
  assign  tx = ser_txd;



  always_comb
    casez (key_sw)
    default : display_number = mem_addr  [15: 0];
    4'b?01? : display_number = mem_rdata [15: 0];
    4'b?10? : display_number = mem_wdata [15: 0];

    // 4'b101? : display_number = extra_debug_data [15: 0];
    // 4'b001? : display_number = extra_debug_data [31:16];
    endcase

  display_dynamic # (.n_dig (4)) i_display
  (
    .clk       (   clk                     ),
    .reset     ( ~ reset_n                 ),
    .number    (   display_number          ),
    .abcdefgh  (   abcdefgh_from_show_mode ),
    .digit     (   digit_from_show_mode    )
  );

  //--------------------------------------------------------------------------

  always_comb
    if (slow_clk_mode)
    begin
      abcdefgh = abcdefgh_from_show_mode;
      digit    = digit_from_show_mode;
    end
    else
    begin
      abcdefgh = abcdefgh_from_mcu;
      digit    = digit_from_mcu;
    end

  //--------------------------------------------------------------------------

  `ifdef OLD_INTERRUPT_CODE

  //--------------------------------------------------------------------------
  // 125Hz interrupt
  // 50,000,000 Hz / 125 Hz = 40,000 cycles

  logic [15:0] hz125_reg;
  logic        hz125_lat;

  assign ei_req    = hz125_lat;
  wire   hz125_lim = hz125_reg == 16'd39999;

  always_ff @ (posedge clk or negedge resetb)
    if (~ resetb)
    begin
      hz125_reg <= 16'd0;
      hz125_lat <= 1'b0;
    end
    else
    begin
      hz125_reg <= hz125_lim ? 16'd0 : hz125_reg + 1'b1;
      hz125_lat <= ~ port3_reg [15] & (hz125_lim | hz125_lat);
    end

  `endif

  //--------------------------------------------------------------------------
  // 8 KHz interrupt
  // 50,000,000 Hz / 8 KHz = 6250 cycles

  logic [12:0] khz8_reg;
  logic        khz8_lat;

  assign ei_req    = khz8_lat;
  wire   khz8_lim = khz8_reg == 13'd6249;

  always_ff @ (posedge clk or negedge resetb)
    if (~ resetb)
    begin
      khz8_reg <= 13'd0;
      khz8_lat <= 1'b0;
    end
    else
    begin
      khz8_reg <= khz8_lim ? 13'd0 : khz8_reg + 1'b1;
      khz8_lat <= ~ port3_reg [15] & (khz8_lim | khz8_lat);
    end

   //Keyboard section

  // signal declaration
  wire [7:0] scan_code, ascii_code;
  wire scan_code_ready;
  wire letter_case;
  reg  [7:0] r_reg;                       // baud rate generator register
  wire [7:0] r_next;                      // baud rate generator next state logic
  wire tick;                              // baud tick for uart_rx & uart_tx

  reg [7:0] key_code;
  always_ff @ (posedge clk or negedge resetb)
    if (~ resetb)
        begin  
          key_code<='0;
        end
    else
      begin
          key_code<=ascii_code;
      end
ps2scan ps2scan(.clk(clk), .rst_n(reset_n), .ps2k_clk(ps2k_clk), .ps2k_data(ps2k_data), .ps2_byte(ascii_code), .ps2_state(scan_code_ready)); 

endmodule
