`timescale 1ns / 1ps

module main (
    input wire clk,
    
    output wire Hsynq,
    output wire Vsynq,
    output wire [3:0] Red,
    output wire [3:0] Green,
    output wire [3:0] Blue,
    
    output wire left,          // Left audio (headphone tip)
    output wire right,
    
    input wire sw,             // Switch input for display 1
    input wire sw_2,           // Switch input for display 2
    output wire led,
    output wire led_2,
    output wire [6:0] seg,     // 7-segment segments (shared)
    output wire [7:0] an      // anodes (display 1)
);
    
    vga_display display( // line 51 -> 388
            .clk(clk),
            .Hsynq(Hsynq),
            .Vsynq(Vsynq),
            .Red(Red),
            .Green(Green),
            .Blue(Blue),
            .sw(sw)
        );
    twinkle_top speaker(  // line 390 -> 522
        .clk(clk),
        .sw_2(sw_2),
        .left(left),
        .right(right)
    );

    seg_on_off control(  // Line 526 -> 588
        .clk(clk),
        .sw(sw),
        .sw_2(sw_2),
        .led(led),
        .led_2(led_2),
        .seg(seg),
        .an(an)
        );
        
endmodule

module vga_display (
    input clk,
    input sw,
    output Hsynq,
    output Vsynq,
    output [3:0] Red,
    output [3:0] Green,
    output [3:0] Blue
    );

    wire clk_25M;
    wire enable_V_Counter;
    wire [15:0] H_Count_Value;
    wire [15:0] V_Count_Value;
    wire pixel_on;
    wire [6:0] scroll_offset;

    clock_divider clkdiv(clk, clk_25M);
    horizontal_counter hcount(clk_25M, enable_V_Counter, H_Count_Value);
    vertical_counter vcount(clk_25M, enable_V_Counter, V_Count_Value);

    assign Hsynq = (H_Count_Value < 96) ? 1'b1 : 1'b0;
    assign Vsynq = (V_Count_Value < 2)  ? 1'b1 : 1'b0;

    wire active = (H_Count_Value >= 144 && H_Count_Value < 784 &&
                   V_Count_Value >= 35 && V_Count_Value < 515);

    scroll_counter sc(clk_25M, scroll_offset);

    text_renderer tr(
        clk_25M,
        H_Count_Value - 144,
        V_Count_Value - 35,
        scroll_offset,
        pixel_on
    );
    
    assign {Red, Green, Blue} = (sw == 0 && active &&
        (pixel_on || (V_Count_Value >= 298 && V_Count_Value < 300) || (V_Count_Value >= 270 && V_Count_Value < 272))) 
        ? 12'hF00 : 12'h000;

    
endmodule

// Clock divider from 100 MHz to 25 MHz
module clock_divider(input clk, output reg clk_25M = 0);
    reg [1:0] counter = 0;
    always @(posedge clk) begin
        counter <= counter + 1;
        clk_25M <= counter[1];
    end
endmodule

// Horizontal counter
module horizontal_counter(input clk, output reg enable_V_Counter, output reg [15:0] H_Count_Value = 0);
    always @(posedge clk) begin
        if (H_Count_Value == 799) begin
            H_Count_Value <= 0;
            enable_V_Counter <= 1;
        end else begin
            H_Count_Value <= H_Count_Value + 1;
            enable_V_Counter <= 0;
        end
    end
endmodule

// Vertical counter
module vertical_counter(input clk, input enable, output reg [15:0] V_Count_Value = 0);
    always @(posedge clk) begin
        if (enable) begin
            if (V_Count_Value == 524)
                V_Count_Value <= 0;
            else
                V_Count_Value <= V_Count_Value + 1;
        end
    end
endmodule

// Scroll counter
module scroll_counter(input clk, output reg [6:0] scroll_offset = 0);
    reg [23:0] counter = 0;
    always @(posedge clk) begin
        counter <= counter + 1;
        if (counter == 5_000_000) begin
            counter <= 0;
            scroll_offset <= scroll_offset + 1;
        end
    end
endmodule

// Main text renderer for 16x16 characters
module text_renderer(
    input clk,
    input [9:0] x,
    input [9:0] y,
    input [6:0] scroll_offset,
    output reg pixel_on
);
    wire [6:0] char_x = (x >> 4) - scroll_offset;
    wire [4:0] char_y = y >> 4;
    wire [3:0] col = x[3:0];
    wire [3:0] row = y[3:0];

    wire [7:0] char_code;
    char_rom cr(char_x, char_y, char_code);

    wire [15:0] font_line;
    font_rom_16x16 fr(char_code, row, font_line);

    always @(*) begin
        pixel_on = font_line[15 - col];
    end
endmodule

// Character ROM for "HELLO WORLD"
module char_rom(input [6:0] x, input [4:0] y, output reg [7:0] char);
    always @(*) begin
        if (y == 15) begin
            case (x % 12)
                0: char =  " ";
                1: char =  "O";
                2: char =  "P";
                3: char =  "E";
                4: char =  "N";
                5: char =  "";
                6: char =  "N";
                7: char =  "O";
                8: char =  "W";
                9: char =  " ";
                10: char = "@";
                11: char = " ";
                default: char = 8'h20;
            endcase
        end else begin
            char = 8'h20;
        end
    end
endmodule

// 16x16 font ROM for selected characters
module font_rom_16x16(input [7:0] char_code, input [3:0] row, output reg [15:0] line);
    always @(*) begin
        case (char_code)
            "H": case(row)
                0: line = 16'b1000000000001000;
                1: line = 16'b1000000000001000;
                2: line = 16'b1000000000001000;
                3: line = 16'b1000000000001000;
                4: line = 16'b1111111111111000;
                5: line = 16'b1000000000001000;
                6: line = 16'b1000000000001000;
                7: line = 16'b1000000000001000;
                8: line = 16'b1000000000001000;
                9: line = 16'b1000000000001000;
                10:line = 16'b1000000000001000; // too thin
                11:line = 16'b1000000000001000;
                12:line = 16'b1000000000001000;
                13:line = 16'b1000000000001000;
                14:line = 16'b1000000000001000;
                15:line = 16'b0000000000000000;
            endcase

            "E": case(row)
                0: line = 16'b1111111111111000;
                1: line = 16'b1000000000000000;
                2: line = 16'b1000000000000000;
                3: line = 16'b1000000000000000;
                4: line = 16'b1111111111110000;
                5: line = 16'b1000000000000000;
                6: line = 16'b1000000000000000; // short a bit
                7: line = 16'b1000000000000000;
                8: line = 16'b1000000000000000;
                9: line = 16'b1000000000000000;
                10:line = 16'b1000000000000000;
                11:line = 16'b1111111111111000;
                12:line = 16'b0000000000000000;
                13:line = 16'b0000000000000000;
                14:line = 16'b0000000000000000;
                15:line = 16'b0000000000000000;
            endcase

            "L": case(row)
                0: line = 16'b1000000000000000;
                1: line = 16'b1000000000000000;
                2: line = 16'b1000000000000000;
                3: line = 16'b1000000000000000;
                4: line = 16'b1000000000000000;
                5: line = 16'b1000000000000000;
                6: line = 16'b1000000000000000;
                7: line = 16'b1000000000000000;
                8: line = 16'b1000000000000000;
                9: line = 16'b1000000000000000; // Short
                10:line = 16'b1000000000000000;
                11:line = 16'b1111111111110000;
                12:line = 16'b0000000000000000;
                13:line = 16'b0000000000000000;
                14:line = 16'b0000000000000000;
                15:line = 16'b0000000000000000;
            endcase

            "O": case(row)
                0: line = 16'b0011111111111000;
                1: line = 16'b0100000000000100;
                2: line = 16'b1000000000000100;
                3: line = 16'b1000000000000100;
                4: line = 16'b1000000000000100;
                5: line = 16'b1000000000000100;
                6: line = 16'b1000000000000100;
                7: line = 16'b1000000000000100;
                8: line = 16'b1000000000000100; // too short
                9: line = 16'b1000000000000100;
                10:line = 16'b1000000000000100;
                11:line = 16'b0100000000001000;
                12:line = 16'b0011111111111000;
                13:line = 16'b0000000000000000;
                14:line = 16'b0000000000000000;
                15:line = 16'b0000000000000000;
            endcase

            "W": case(row)
                0: line = 16'b1000000000000010;
                1: line = 16'b1000000100000010;
                2: line = 16'b1000000100000010;
                3: line = 16'b1000000100000010;
                4: line = 16'b1000000100000010;
                5: line = 16'b1000000100000010;
                6: line = 16'b1000000100000010;
                7: line = 16'b1000000100000010;
                8: line = 16'b1000000100000010; // NO middle line
                9: line = 16'b1000000100000010;
                10:line = 16'b1000000100000010;
                11:line = 16'b0100000100000100;
                12:line = 16'b0010001110001000;
                13:line = 16'b0001110001110000;
                14:line = 16'b0000000000000000;
                15:line = 16'b0000000000000000;
            endcase

            "R": case(row)
                0: line = 16'b1111111111110000;
                1: line = 16'b1000000000001000;
                2: line = 16'b1000000000001000;
                3: line = 16'b1000000000001000;
                4: line = 16'b1111111111110000;
                5: line = 16'b1000000010000000;
                6: line = 16'b1000000001000000;
                7: line = 16'b1000000000100000;
                8: line = 16'b1000000000010000;
                9: line = 16'b1000000000001000;
                10:line = 16'b1000000000000100;
                11:line = 16'b1000000000000010;
                12:line = 16'b0000000000000000;
                13:line = 16'b0000000000000000;
                14:line = 16'b0000000000000000;
                15:line = 16'b0000000000000000;
            endcase

            "D": case(row)
                0: line = 16'b1111111111110000;
                1: line = 16'b1000000000001000;
                2: line = 16'b1000000000000100;
                3: line = 16'b1000000000000100;
                4: line = 16'b1000000000000100;
                5: line = 16'b1000000000000100;
                6: line = 16'b1000000000000100;
                7: line = 16'b1000000000000100;
                8: line = 16'b1000000000000100;
                9: line = 16'b1000000000000100;
                10:line = 16'b1000000000001000;
                11:line = 16'b1000000000010000;
                12:line = 16'b1111111111100000;
                13:line = 16'b0000000000000000;
                14:line = 16'b0000000000000000;
                15:line = 16'b0000000000000000;
            endcase
            
            "@": case(row)
                0:  line = 16'b0000011000000000;  // wrist
                1:  line = 16'b0000011000000000;
                2:  line = 16'b0000011000000000;
                3:  line = 16'b0000011000110000;  // pinky
                4:  line = 16'b0000011001110000;  // ring
                5:  line = 16'b0000011011110000;  // middle
                6:  line = 16'b0000011111110000;  // index
                7:  line = 16'b0000011111110000;
                8:  line = 16'b0000111111110000;
                9:  line = 16'b0001111111110000;
                10: line = 16'b0011111111100000;  // base palm
                11: line = 16'b0011111111000000;
                12: line = 16'b0011111110000000;
                13: line = 16'b0001111100000000;
                14: line = 16'b0000111000000000;
                15: line = 16'b0000000000000000;
            endcase 
            
            "P": case(row)
                0: line = 16'b1111111111100000;
                1: line = 16'b1000000000010000;
                2: line = 16'b1000000000001000;
                3: line = 16'b1000000000001000;
                4: line = 16'b1000000000001000;
                5: line = 16'b1000000000010000;
                6: line = 16'b1111111111100000;
                7: line = 16'b1000000000000000;
                8: line = 16'b1000000000000000;
                9: line = 16'b1000000000000000;
                10:line = 16'b1000000000000000;
                11:line = 16'b1000000000000000;
                12:line = 16'b0000000000000000;
                13:line = 16'b0000000000000000;
                14:line = 16'b0000000000000000;
                15:line = 16'b0000000000000000;
            endcase 

            "N": case(row)
                0: line = 16'b1000000000000010;
                1: line = 16'b1100000000000010;
                2: line = 16'b1010000000000010;
                3: line = 16'b1001000000000010;
                4: line = 16'b1000100000000010;
                5: line = 16'b1000010000000010;
                6: line = 16'b1000001000000010;
                7: line = 16'b1000000100000010;
                8: line = 16'b1000000010000010;
                9: line = 16'b1000000001000010;
                10:line = 16'b1000000000100010;
                11:line = 16'b1000000000010010;
                12:line = 16'b1000000000001010;
                13:line = 16'b1000000000000110;
                14:line = 16'b1000000000000010;
                15:line = 16'b0000000000000000;
            endcase 

            " ": line = 16'b0000000000000000;
            default: line = 16'b0000000000000000;
        endcase
    end
endmodule

module twinkle_top(
    input clk,             // 100 MHz clock
    input sw_2,            // Switch to enable/disable audio
    output left,           // Left audio (headphone tip)
    output right
);
    // Note tone wires
    wire c, d, e, f, g, a;

    // Instantiate tone generators
    c_261Hz tone_c (.clk(clk), .o_261Hz(c));
    d_293Hz tone_d (.clk(clk), .o_293Hz(d));
    e_329Hz tone_e (.clk(clk), .o_329Hz(e));
    f_349Hz tone_f (.clk(clk), .o_349Hz(f));
    g_392Hz tone_g (.clk(clk), .o_392Hz(g));
    a_440Hz tone_a (.clk(clk), .o_440Hz(a));

    parameter CLK_FREQ = 100_000_000;
    parameter integer D_500ms = 0.5 * CLK_FREQ;
    parameter integer D_break = 0.1 * CLK_FREQ;

    reg [25:0] count = 0;
    reg counter_clear = 0;
    reg flag_500ms = 0;
    reg flag_break = 0;
    reg [7:0] state = 0;

    always @(posedge clk) begin
        if (counter_clear) begin
            count <= 0;
            counter_clear <= 0;
            flag_500ms <= 0;
            flag_break <= 0;
        end else begin
            count <= count + 1;
            if (count == D_500ms) flag_500ms <= 1;
            if (count == D_break)  flag_break <= 1;
        end

        // Loop the melody
        case (state)
            0: if (flag_500ms) begin counter_clear <= 1; state <= 1; end
            1: if (flag_break)  begin counter_clear <= 1; state <= 2; end
            2: if (flag_500ms) begin counter_clear <= 1; state <= 3; end
            3: if (flag_break)  begin counter_clear <= 1; state <= 4; end
            4: if (flag_500ms) begin counter_clear <= 1; state <= 5; end
            5: if (flag_break)  begin counter_clear <= 1; state <= 6; end
            6: if (flag_500ms) begin counter_clear <= 1; state <= 7; end
            7: if (flag_break)  begin counter_clear <= 1; state <= 8; end
            8: if (flag_500ms) begin counter_clear <= 1; state <= 9; end
            9: if (flag_break)  begin counter_clear <= 1; state <= 10; end
           10: if (flag_500ms) begin counter_clear <= 1; state <= 11; end
           11: if (flag_break)  begin counter_clear <= 1; state <= 12; end
           12: if (flag_500ms) begin counter_clear <= 1; state <= 13; end
           13: if (flag_break)  begin counter_clear <= 1; state <= 14; end
           14: if (flag_500ms) begin counter_clear <= 1; state <= 15; end
           15: if (flag_break)  begin counter_clear <= 1; state <= 16; end
           16: if (flag_500ms) begin counter_clear <= 1; state <= 17; end
           17: if (flag_break)  begin counter_clear <= 1; state <= 18; end
           18: if (flag_500ms) begin counter_clear <= 1; state <= 19; end
           19: if (flag_break)  begin counter_clear <= 1; state <= 20; end
           20: if (flag_500ms) begin counter_clear <= 1; state <= 21; end
           21: if (flag_break)  begin counter_clear <= 1; state <= 22; end
           22: if (flag_500ms) begin counter_clear <= 1; state <= 23; end
           23: if (flag_break)  begin counter_clear <= 1; state <= 24; end
           24: if (flag_500ms) begin counter_clear <= 1; state <= 25; end
           25: if (flag_break)  begin counter_clear <= 1; state <= 26; end
           26: if (flag_500ms) begin counter_clear <= 1; state <= 27; end
           27: if (flag_break)  begin counter_clear <= 1; state <= 28; end
           28: if (flag_500ms) begin counter_clear <= 1; state <= 29; end
           29: if (flag_break)  begin counter_clear <= 1; state <= 0; end // Loop
        endcase
    end

    // Select which tone to play based on state
    wire tone = (state == 0 || state == 2 || state == 24 || state == 26) ? c :
                (state == 4 || state == 6 || state == 18 || state == 20) ? g :
                (state == 8 || state == 10 || state == 12 || state == 14 || state == 22) ? a :
                (state == 16 || state == 28) ? c :
                (state == 9 || state == 19 || state == 21 || state == 23) ? f :
                (state == 11 || state == 13 || state == 15 || state == 17) ? e :
                (state == 25 || state == 27) ? d : 0;

    // Mute output if sw_2 is off
    assign left  = sw_2 ? tone : 1'b0;
    assign right = sw_2 ? tone : 1'b0;
endmodule



// --- Tone generator modules ---

module c_261Hz(input clk, output o_261Hz);
    reg r; reg [18:0] c = 0;
    always @(posedge clk)
        if (c == 19'd191572) begin c <= 0; r <= ~r; end else c <= c + 1;
    assign o_261Hz = r;
endmodule

module d_293Hz(input clk, output o_293Hz);
    reg r; reg [18:0] c = 0;
    always @(posedge clk)
        if (c == 19'd170068) begin c <= 0; r <= ~r; end else c <= c + 1;
    assign o_293Hz = r;
endmodule

module e_329Hz(input clk, output o_329Hz);
    reg r; reg [18:0] c = 0;
    always @(posedge clk)
        if (c == 19'd151515) begin c <= 0; r <= ~r; end else c <= c + 1;
    assign o_329Hz = r;
endmodule

module f_349Hz(input clk, output o_349Hz);
    reg r; reg [18:0] c = 0;
    always @(posedge clk)
        if (c == 19'd143266) begin c <= 0; r <= ~r; end else c <= c + 1;
    assign o_349Hz = r;
endmodule

module g_392Hz(input clk, output o_392Hz);
    reg r; reg [17:0] c = 0;
    always @(posedge clk)
        if (c == 18'd127551) begin c <= 0; r <= ~r; end else c <= c + 1;
    assign o_392Hz = r;
endmodule

module a_440Hz(input clk, output o_440Hz);
    reg r; reg [17:0] c = 0;
    always @(posedge clk)
        if (c == 18'd113636) begin c <= 0; r <= ~r; end else c <= c + 1;
    assign o_440Hz = r;
endmodule

//    seg_on_off  control(clk, se, sw2, led, led2, seg, an, an_2);

module seg_on_off (
    input wire clk,           // 100 MHz clock
    input wire sw,            // Switch for display 1
    input wire sw_2,          // Switch for display 2
    output reg led,           // LED for display 1
    output reg led_2,         // LED for display 2
    output reg [6:0] seg,     // Shared segment lines (active low)
    output reg [7:0] an       // Anode control (shared)
);

    function [6:0] char_seg(input [7:0] c);
        case (c)
            "O": char_seg = 7'b1000000;
            "F": char_seg = 7'b0001110;
            "U": char_seg = 7'b1000001;
            "L": char_seg = 7'b1110001;
            " ": char_seg = 7'b1111111;
            default: char_seg = 7'b1111111;
        endcase
    endfunction

    reg [2:0] digit = 0;
    reg [19:0] clkdiv = 0;

    reg [7:0] chars1 [3:0];
    reg [7:0] chars2 [3:0];

    always @(*) begin
        if (sw) begin
            chars1[3] = " "; chars1[2] = " "; chars1[1] = " "; chars1[0] = " ";
        end else begin
            chars1[3] = "O"; chars1[2] = "F"; chars1[1] = "F"; chars1[0] = " ";
        end

        if (sw_2) begin
            chars2[3] = " "; chars2[2] = " "; chars2[1] = " "; chars2[0] = " ";
        end else begin
            chars2[3] = "O"; chars2[2] = "F"; chars2[1] = "F"; chars2[0] = " ";
        end
    end

    always @(posedge clk) begin
        clkdiv <= clkdiv + 1;
        if (clkdiv[15:0] == 0)
            digit <= digit + 1;

        led <= sw;
        led_2 <= sw_2;
    end

    always @(*) begin
        an = 8'b1111_1111;

        // Show display 1 on digits 0-3, display 2 on digits 4-7
        if (digit < 4) begin
            an[digit] = 1'b0;
            seg = char_seg(chars1[digit]);
        end else begin
            an[digit] = 1'b0;
            seg = char_seg(chars2[digit - 4]);
        end
    end
endmodule
