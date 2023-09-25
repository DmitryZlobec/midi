`include "config.svh"

module top
# (
    parameter clk_mhz = 50,
              w_key   = 4,
              w_sw    = 8,
              w_led   = 8,
              w_digit = 8,
              w_gpio  = 20
)
(
    input                        clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // VGA

    output logic                 vsync,
    output logic                 hsync,
    output logic [          3:0] red,
    output logic [          3:0] green,
    output logic [          3:0] blue,

    input        [         23:0] mic,

    // General-purpose Input/Output

    inout  logic [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    // assign led      = '0;
    // assign abcdefgh = '0;
    // assign digit    = '0;
       assign vsync    = '0;
       assign hsync    = '0;
       assign red      = '0;
       assign green    = '0;
       assign blue     = '0;

    //------------------------------------------------------------------------

    wire [15:0] value = mic [23:8];

    //------------------------------------------------------------------------
    //
    //  Measuring frequency
    //
    //------------------------------------------------------------------------

    // It is enough for the counter to be 20 bit. Why?

    logic [15:0] prev_value;
    logic [19:0] counter;
    logic [19:0] distance;

    localparam [15:0] threshold = 16'h1100;

    // A way to investigate thresholds
    // wire [15:0] threshold = { ~ key_sw, 12'b0 };

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            prev_value <= 16'h0;
            counter    <= 20'h0;
            distance   <= 20'h0;
        end
        else
        begin
            prev_value <= value;

            if (  value      >= threshold
                & prev_value < threshold)
            begin
               distance <= counter;
               counter  <= 20'h0;
            end
            else if (counter != ~ 20'h0)  // To prevent overflow
            begin
               counter <= counter + 20'h1;
            end
        end

    //------------------------------------------------------------------------
    //
    //  Determining the note
    //
    //------------------------------------------------------------------------

    `ifdef USE_STANDARD_FREQUENCIES

    localparam freq_100_C  = 26163,
               freq_100_Cs = 27718,
               freq_100_D  = 29366,
               freq_100_Ds = 31113,
               freq_100_E  = 32963,
               freq_100_F  = 34923,
               freq_100_Fs = 36999,
               freq_100_G  = 39200,
               freq_100_Gs = 41530,
               freq_100_A  = 44000,
               freq_100_As = 46616,
               freq_100_B  = 49388;
    `else

    // Custom measured frequencies

    localparam freq_100_C  = 26163,
               freq_100_Cs = 27718,
               freq_100_D  = 29366,
               freq_100_Ds = 31113,
               freq_100_E  = 32963,
               freq_100_F  = 34923,
               freq_100_Fs = 36999,
               freq_100_G  = 39200,
               freq_100_Gs = 41530,
               freq_100_A  = 44000,
               freq_100_As = 46616,
               freq_100_B  = 49388;
    `endif

    //------------------------------------------------------------------------

    function [19:0] high_distance (input [18:0] freq_100);
       high_distance = clk_mhz * 1000 * 1000 / freq_100 * 104;
    endfunction

    //------------------------------------------------------------------------

    function [19:0] low_distance (input [18:0] freq_100);
       low_distance = clk_mhz * 1000 * 1000 / freq_100 * 96;
    endfunction

    //------------------------------------------------------------------------

    function [19:0] check_freq_single_range (input [18:0] freq_100);

       check_freq_single_range =    distance > low_distance  (freq_100)
                                  & distance < high_distance (freq_100);
    endfunction

    //------------------------------------------------------------------------

    function [19:0] check_freq (input [18:0] freq_100);

       check_freq =   check_freq_single_range (freq_100 * 4)
                    | check_freq_single_range (freq_100 * 2)
                    | check_freq_single_range (freq_100);

    endfunction

    //------------------------------------------------------------------------

    wire check_C  = check_freq (freq_100_C );
    wire check_Cs = check_freq (freq_100_Cs);
    wire check_D  = check_freq (freq_100_D );
    wire check_Ds = check_freq (freq_100_Ds);
    wire check_E  = check_freq (freq_100_E );
    wire check_F  = check_freq (freq_100_F );
    wire check_Fs = check_freq (freq_100_Fs);
    wire check_G  = check_freq (freq_100_G );
    wire check_Gs = check_freq (freq_100_Gs);
    wire check_A  = check_freq (freq_100_A );
    wire check_As = check_freq (freq_100_As);
    wire check_B  = check_freq (freq_100_B );

    //------------------------------------------------------------------------

    localparam w_note = 12;

    wire [w_note - 1:0] note = { check_C  , check_Cs , check_D  , check_Ds ,
                                 check_E  , check_F  , check_Fs , check_G  ,
                                 check_Gs , check_A  , check_As , check_B  };

    localparam [w_note - 1:0] no_note = 12'b0,

                              C  = 12'b1000_0000_0000,
                              Cs = 12'b0100_0000_0000,
                              D  = 12'b0010_0000_0000,
                              Ds = 12'b0001_0000_0000,
                              E  = 12'b0000_1000_0000,
                              F  = 12'b0000_0100_0000,
                              Fs = 12'b0000_0010_0000,
                              G  = 12'b0000_0001_0000,
                              Gs = 12'b0000_0000_1000,
                              A  = 12'b0000_0000_0100,
                              As = 12'b0000_0000_0010,
                              B  = 12'b0000_0000_0001;

    localparam [w_note - 1:0] Df = Cs, Ef = Ds, Gf = Fs, Af = Gs, Bf = As;

    //------------------------------------------------------------------------
    //
    //  Note filtering
    //
    //------------------------------------------------------------------------

    logic  [w_note - 1:0] d_note;  // Delayed note

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            d_note <= no_note;
        else
            d_note <= note;

    logic  [19:0] t_cnt;           // Threshold counter
    logic  [w_note - 1:0] t_note;  // Thresholded note

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            t_cnt <= 0;
        else
            if (note == d_note)
                t_cnt <= t_cnt + 1;
            else
                t_cnt <= 0;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            t_note <= no_note;
        else
            if (& t_cnt)
                t_note <= d_note;

    //------------------------------------------------------------------------
    //
    //  FSMs
    //
    //------------------------------------------------------------------------

    localparam w_state = 4;  // Let's keep to 16 states
    localparam n_fsms  = 3;

    localparam [3:0] recognized = 4'hf;

    logic [w_state - 1:0] states [0:n_fsms - 1];

    //------------------------------------------------------------------------
    //
    //  Exercise: Write an FSM for a new song
    //
    //------------------------------------------------------------------------

    `define SONGS_581
    //`define SONGS_423

    `ifdef SONGS_581

    // No 5. The story of love

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            states [0] <= 0;
        else
            case (states [0])
             0: if ( t_note == Bf ) states [0] <=  1;
             1: if ( t_note == D  ) states [0] <=  2;
             2: if ( t_note == Bf ) states [0] <=  3;
             3: if ( t_note == D  ) states [0] <=  4;
             4: if ( t_note == Ef ) states [0] <=  5;
             5: if ( t_note == D  ) states [0] <=  6;
             6: if ( t_note == C  ) states [0] <=  7;
             7: if ( t_note == A  ) states [0] <=  8;
             8: if ( t_note == C  ) states [0] <=  9;
             9: if ( t_note == A  ) states [0] <= 10;
            10: if ( t_note == C  ) states [0] <= 11;
            11: if ( t_note == D  ) states [0] <= 12;
            12: if ( t_note == C  ) states [0] <= 13;
            13: if ( t_note == Bf ) states [0] <= 14;
            14: if ( t_note == G  ) states [0] <= recognized;
            endcase

    // No 8. Godfather

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            states [1] <= 0;
        else
            case (states [1])
             0: if ( t_note == G  ) states [1] <=  1;
             1: if ( t_note == C  ) states [1] <=  2;
             2: if ( t_note == Ef ) states [1] <=  3;
             3: if ( t_note == D  ) states [1] <=  4;
             4: if ( t_note == C  ) states [1] <=  5;
             5: if ( t_note == Ef ) states [1] <=  6;
             6: if ( t_note == C  ) states [1] <=  7;
             7: if ( t_note == D  ) states [1] <=  8;
             8: if ( t_note == C  ) states [1] <=  9;
             9: if ( t_note == Af ) states [1] <= 10;
            10: if ( t_note == Bf ) states [1] <= 11;
            11: if ( t_note == G  ) states [1] <= 12;
            12: if ( t_note == C  ) states [1] <= 13;
            13: if ( t_note == Ef ) states [1] <= 14;
            14: if ( t_note == D  ) states [1] <= recognized;
            endcase

    // No 1. Gangsters Song

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            states [2] <= 0;
        else
            case (states [2])
             0: if ( t_note == E  ) states [2] <=  1;
             1: if ( t_note == F  ) states [2] <=  2;
             2: if ( t_note == E  ) states [2] <=  3;
             3: if ( t_note == A  ) states [2] <=  4;
             4: if ( t_note == B  ) states [2] <=  5;
             5: if ( t_note == C  ) states [2] <=  6;
             6: if ( t_note == D  ) states [2] <=  7;
             7: if ( t_note == C  ) states [2] <=  8;
             8: if ( t_note == B  ) states [2] <=  9;
             9: if ( t_note == C  ) states [2] <= 10;
            10: if ( t_note == G  ) states [2] <= 11;
            11: if ( t_note == C  ) states [2] <= 12;
            12: if ( t_note == A  ) states [2] <= 13;
            13: if ( t_note == C  ) states [2] <= 14;
            14: if ( t_note == A  ) states [2] <= recognized;
            endcase

    `elsif SONGS_423

    // No 4. Fly away on the wings of wind

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            states [0] <= 0;
        else
            case (states [0])
             0: if ( t_note == G  ) states [0] <=  1;
             1: if ( t_note == D  ) states [0] <=  2;
             2: if ( t_note == C  ) states [0] <=  3;
             3: if ( t_note == D  ) states [0] <=  4;
             4: if ( t_note == Bf ) states [0] <=  5;
             5: if ( t_note == A  ) states [0] <=  6;
             6: if ( t_note == G  ) states [0] <=  7;
             7: if ( t_note == A  ) states [0] <=  8;
             8: if ( t_note == Bf ) states [0] <=  9;
             9: if ( t_note == C  ) states [0] <= 10;
            10: if ( t_note == D  ) states [0] <= 11;
            11: if ( t_note == A  ) states [0] <= 12;
            12: if ( t_note == G  ) states [0] <= 13;
            13: if ( t_note == F  ) states [0] <= 14;
            14: if ( t_note == D  ) states [0] <= recognized;
            endcase

    // No 2. Winged Swing

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            states [1] <= 0;
        else
            case (states [1])
             0: if ( t_note == A  ) states [1] <=  1;
             1: if ( t_note == Fs ) states [1] <=  2;
             2: if ( t_note == G  ) states [1] <=  3;
             3: if ( t_note == Fs ) states [1] <=  4;
             4: if ( t_note == E  ) states [1] <=  5;
             5: if ( t_note == B  ) states [1] <=  6;
             6: if ( t_note == A  ) states [1] <=  7;
             7: if ( t_note == Gs ) states [1] <=  8;
             8: if ( t_note == A  ) states [1] <=  9;
             9: if ( t_note == D  ) states [1] <= 10;
            10: if ( t_note == C  ) states [1] <= 11;
            11: if ( t_note == Bf ) states [1] <= 12;
            12: if ( t_note == A  ) states [1] <= 13;
            13: if ( t_note == B  ) states [1] <= 14;
            14: if ( t_note == A  ) states [1] <= recognized;
            endcase

    // No 3. Yesterday by Beatles

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            states [2] <= 0;
        else
            case (states [2])
             0: if ( t_note == G  ) states [2] <=  1;
             1: if ( t_note == F  ) states [2] <=  2;
             2: if ( t_note == A  ) states [2] <=  3;
             3: if ( t_note == B  ) states [2] <=  4;
             4: if ( t_note == Cs ) states [2] <=  5;
             5: if ( t_note == D  ) states [2] <=  6;
             6: if ( t_note == E  ) states [2] <=  7;
             7: if ( t_note == F  ) states [2] <=  8;
             8: if ( t_note == E  ) states [2] <=  9;
             9: if ( t_note == D  ) states [2] <= 10;
            10: if ( t_note == C  ) states [2] <= 11;
            11: if ( t_note == Bf ) states [2] <= 12;
            12: if ( t_note == A  ) states [2] <= 13;
            13: if ( t_note == G  ) states [2] <= 14;
            14: if ( t_note == Bf ) states [2] <= recognized;
            endcase

    `endif

    //------------------------------------------------------------------------
    //
    //  The dynamic seven segment display logic
    //
    //------------------------------------------------------------------------

    logic [15:0] digit_enable_cnt;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            digit_enable_cnt <= 0;
        else
            digit_enable_cnt <= digit_enable_cnt + 1;

    wire digit_enable = & digit_enable_cnt;

    //------------------------------------------------------------------------

    logic  [1:0] i_digit_r;
    wire [1:0] i_digit = i_digit_r + 2'd1;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            i_digit_r <= 2'd0;
            digit     <= 4'b0;
        end
        else if (digit_enable)
        begin
            i_digit_r <= i_digit;
            digit     <= 4'b0001 << i_digit;
        end

    //------------------------------------------------------------------------
    //
    //  The output to seven segment display
    //
    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            abcdefgh <= 8'b00000000;
        end
        else if (digit_enable)
        begin
            if (i_digit == 3'd3)
                case (t_note)
                C  : abcdefgh <= 8'b10011100;  // C   // abcdefgh
                Cs : abcdefgh <= 8'b10011101;  // C#
                D  : abcdefgh <= 8'b01111010;  // D   //   --a--
                Ds : abcdefgh <= 8'b01111011;  // D#  //  |     |
                E  : abcdefgh <= 8'b10011110;  // E   //  f     b
                F  : abcdefgh <= 8'b10001110;  // F   //  |     |
                Fs : abcdefgh <= 8'b10001111;  // F#  //   --g--
                G  : abcdefgh <= 8'b10111100;  // G   //  |     |
                Gs : abcdefgh <= 8'b10111101;  // G#  //  e     c
                A  : abcdefgh <= 8'b11101110;  // A   //  |     |
                As : abcdefgh <= 8'b11101111;  // A#  //   --d--  h
                B  : abcdefgh <= 8'b00111110;  // B
                default : abcdefgh <= 8'b00000000;
                endcase
            else if (i_digit < n_fsms)
                case (states [n_fsms - 1 - i_digit])
                4'h0: abcdefgh <= 8'b11111100;
                4'h1: abcdefgh <= 8'b01100000;
                4'h2: abcdefgh <= 8'b11011010;
                4'h3: abcdefgh <= 8'b11110010;
                4'h4: abcdefgh <= 8'b01100110;
                4'h5: abcdefgh <= 8'b10110110;
                4'h6: abcdefgh <= 8'b10111110;
                4'h7: abcdefgh <= 8'b11100000;
                4'h8: abcdefgh <= 8'b11111110;
                4'h9: abcdefgh <= 8'b11100110;
                4'ha: abcdefgh <= 8'b11101110;
                4'hb: abcdefgh <= 8'b00111110;
                4'hc: abcdefgh <= 8'b10011100;
                4'hd: abcdefgh <= 8'b01111010;
                4'he: abcdefgh <= 8'b10011110;
                // 4'hf: abcdefgh <= 8'b10001110;  // F
                4'hf: abcdefgh <= 8'b11000110;  // Upper o - recognized
                endcase
            else
                abcdefgh <= 8'b00000000;
        end

    //------------------------------------------------------------------------
    //
    //  The auxiliary output to LED
    //
    //------------------------------------------------------------------------

    logic [3:0] new_led;

    always_comb
    begin
        new_led [3:1] = 3'b0;

        for (int i = 0; i < n_fsms; i = i + 1)
            new_led [3 - i] = (states [i] == recognized);

        new_led [0] = & new_led [3:1];  // All recognized
    end

    always_ff @ (posedge clk)
        led <= new_led;

endmodule
