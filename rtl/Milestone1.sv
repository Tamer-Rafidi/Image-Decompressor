/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

// This is the top module
// It connects the SRAM and VGA together
// It will first write RGB data of an image with 8x8 rectangles of size 40x30 pixels into the SRAM
// The VGA will then read the SRAM and display the image
module Milestone1 (
        /////// board clocks                      ////////////
        input logic CLOCK_50_I,                   // 50 MHz clock
        input logic Resetn,
        input logic start,
        input logic[15:0] SRAM_read_data,
        
        output logic stop,
        output logic SRAM_we_n,
        output logic[15:0] SRAM_write_data,
        output logic[17:0] SRAM_address 
);


// counter for keeping track of the address offset
logic [17:0] counter, row_counter, Y_BASE_ADDRESS_COUNTER, V_BASE_ADDRESS_COUNTER, U_BASE_ADDRESS_COUNTER, RGB_BASE_ADDRESS_COUNTER;

M1_state_type state;

logic [31:0] R_odd, R_even, G_odd, G_even, B_odd, B_even;
logic [7:0]  r_even, r_odd, g_even, g_odd, b_even, b_odd;
logic [15:0] Y_even, Y_odd, Y_even_buf, Y_odd_buf, Up_even, Up_odd, Vp_even, Vp_odd;
logic [15:0] U_even;
logic [15:0] V_even;
logic [15:0] U_buf, U_buf_2, U_buf_3, V_buf, V_buf_2, V_buf_3; 
logic [7:0] U_buf_4, V_buf_4;
logic [31:0] Mul_1, Mul_2, Mul_3;
logic [31:0] VU_mul1, VU_mul2, VU_mul3;
logic [31:0] RGB_odd1, RGB_odd2, RGB_odd3, RGB_even1, RGB_even2, RGB_even3;
logic [31:0] Mult_op_1, Mult_op_2, Mult_op_3;
logic [31:0] Mult_result1, Mult_result2, Mult_result3;
logic [63:0] Mult_result_long1, Mult_result_long2, Mult_result_long3;

// Mult_op_1 is coefficient, Mul_1 is sum of pixel pair (J-5/J+5)
assign Mult_result_long1 = Mult_op_1 * Mul_1;
// VU_mul1
assign Mult_result1 = Mult_result_long1[31:0];

// Mult_op_2 is a constant, Mul_2 is odd
assign Mult_result_long2 = Mult_op_2 * Mul_2;
// VU_mul2
assign Mult_result2 = Mult_result_long2[31:0];

// Mult_op_3 is a constant, Mul_3 is even
assign Mult_result_long3 = Mult_op_3 * Mul_3;
// VU_mul2
assign Mult_result3 = Mult_result_long3[31:0];



assign r_even = R_even[31] ? 8'd0 : |R_even[30:24] ? 8'd255 : R_even[23:16];
assign r_odd = R_odd[31] ? 8'd0 : |R_odd[30:24] ? 8'd255 : R_odd[23:16];
assign g_even = G_even[31] ? 8'd0 : |G_even[30:24] ? 8'd255 : G_even[23:16];
assign g_odd = G_odd[31] ? 8'd0 : |G_odd[30:24] ? 8'd255 : G_odd[23:16];
assign b_even = B_even[31] ? 8'd0 : |B_even[30:24] ? 8'd255 : B_even[23:16];
assign b_odd = B_odd[31] ? 8'd0 : |B_odd[30:24] ? 8'd255 : B_odd[23:16];

assign G_even = RGB_even1 + RGB_even2 + RGB_even3;
assign B_even = RGB_even1 + RGB_even2;
	
always_ff @ (posedge CLOCK_50_I or negedge Resetn) begin
	if (~Resetn) begin
		state <= M1_IDLE;			
		SRAM_we_n <= 1'b1;
		SRAM_write_data <= 16'd0;
		SRAM_address <= 18'd0;
		counter <= 18'd0;
		row_counter <= 18'd0;
		stop <= 1'b0;
		R_odd <= 16'd0;
	   R_even <= 16'd0;
	   G_odd <= 16'd0;
	   B_odd <= 16'd0;
	   Y_even <= 16'd0;
	   Y_odd <= 16'd0;
	   Y_even_buf <= 16'd0;
	   Y_odd_buf <= 16'd0;
	   Up_even <= 16'd0;
	   Up_odd <= 16'd0;
	   Vp_even <= 16'd0;
	   Vp_odd <= 16'd0;
	   U_even <= 16'd0;
	   U_buf <= 16'd0;
	   U_buf_2 <= 16'd0;
	   U_buf_3 <= 16'd0;
	   U_buf_4 <= 16'd0;
	   V_buf <= 16'd0;
	   V_buf_2 <= 16'd0;
	   V_buf_3 <= 16'd0;
	   V_buf_4 <= 16'd0;
	   Mul_1 <= 16'd0;
	   Mul_2 <= 16'd0;
	   Mul_3 <= 16'd0;
	   VU_mul1 <= 16'd0;
	   VU_mul2 <= 16'd0;
	   VU_mul3 <= 16'd0;
	   RGB_odd1 <= 16'd0;
	   RGB_odd2 <= 16'd0;
	   RGB_odd3 <= 16'd0;
	   RGB_even1 <= 16'd0;
	   RGB_even2 <= 16'd0;
	   RGB_even3 <= 16'd0;
		Y_BASE_ADDRESS_COUNTER <= 18'd0;
		U_BASE_ADDRESS_COUNTER <= 18'd0;
		V_BASE_ADDRESS_COUNTER <= 18'd0;
		RGB_BASE_ADDRESS_COUNTER <= 18'd0;
	end else begin
		case (state)
			M1_IDLE: begin
				if (start) begin
					// Start filling the SRAM
					state <= LI0;			
				end
			end
			LI0: begin
				SRAM_we_n <= 1'b1;
				counter <= 18'd0;
				SRAM_address <= V_BASE_ADDRESS + V_BASE_ADDRESS_COUNTER;
				V_BASE_ADDRESS_COUNTER <= V_BASE_ADDRESS_COUNTER + 16'd1;
				if (row_counter == 18'd240) begin
					stop <= 1'b1;
					state <= M1_IDLE;
				end else begin
					state <= LI1;
				end
			end
			
			LI1: begin
				SRAM_address <= U_BASE_ADDRESS + U_BASE_ADDRESS_COUNTER;
				U_BASE_ADDRESS_COUNTER <= U_BASE_ADDRESS_COUNTER + 16'd1;
				state <= LI2;
			end
			
			LI2: begin
				SRAM_address <= Y_BASE_ADDRESS + Y_BASE_ADDRESS_COUNTER;
				Y_BASE_ADDRESS_COUNTER <= Y_BASE_ADDRESS_COUNTER + 16'd1;
				state <= LI3;
			end
			
			LI3: begin
				SRAM_address <= V_BASE_ADDRESS + V_BASE_ADDRESS_COUNTER;
				V_BASE_ADDRESS_COUNTER <= V_BASE_ADDRESS_COUNTER + 16'd1;
				V_buf[15:0] <= SRAM_read_data[15:0];
				state <= LI4;
			end
			
			LI4: begin
				SRAM_address <= U_BASE_ADDRESS + U_BASE_ADDRESS_COUNTER;
				U_BASE_ADDRESS_COUNTER <= U_BASE_ADDRESS_COUNTER + 16'd1;
				U_buf[15:0] <= SRAM_read_data[15:0];
				state <= LI5;
			end
			
			LI5: begin
				Y_even <= SRAM_read_data[15:8];// - 32'sd16;
				Y_odd <= SRAM_read_data[7:0];// - 32'sd16;
				state <= LI6;
			end
			
			LI6: begin
				V_buf_2[15:0] <= SRAM_read_data[15:0];
				state <= LI7;
			end
			
			LI7: begin
				SRAM_address <= V_BASE_ADDRESS + V_BASE_ADDRESS_COUNTER;
				V_BASE_ADDRESS_COUNTER <= V_BASE_ADDRESS_COUNTER + 16'd1;
				// V_plus5 + V_minus5
				U_buf_2[15:0] <= SRAM_read_data[15:0];
				
				Mul_1 <= V_buf_2[7:0] + V_buf[15:8];
				Mult_op_1 <= coef1;
				
				state <= LI8;
			end
			
			LI8: begin
				SRAM_address <= U_BASE_ADDRESS + U_BASE_ADDRESS_COUNTER;
				U_BASE_ADDRESS_COUNTER <= U_BASE_ADDRESS_COUNTER + 16'd1;
				// V_plus3 + V_minus3
				
				Mul_1 <= V_buf_2[15:8] + V_buf[15:8];
				Mult_op_1 <= coef2;
				VU_mul1 <= Mult_result1;
				
				
				state <= LI9;
			end
			
			LI9: begin
				// V_plus1 + V_minus1
				Mul_1 <= V_buf[7:0] + V_buf[15:8];
				Mult_op_1 <= coef3;
				VU_mul2 <= Mult_result1;
				
				
				state <= LI10;
			end
			
			LI10: begin
				SRAM_address <= Y_BASE_ADDRESS + Y_BASE_ADDRESS_COUNTER;
				Y_BASE_ADDRESS_COUNTER <= Y_BASE_ADDRESS_COUNTER + 4'd1;
				V_buf_3[15:0] <= SRAM_read_data[15:0];
				// U_plus5 + U_minus5
				Mul_1 <= U_buf_2[7:0] + U_buf[15:8];
				Mult_op_1 <= coef1;
				VU_mul3 <= Mult_result1;
				
				
				state <= LI11;			
			end
			
			LI11: begin
				Vp_odd <= ((VU_mul1 - VU_mul2 + VU_mul3 + 16'd128) >> 8) - 32'sd128;// - 32'sd128;
				U_buf_3 <= SRAM_read_data[15:0];
				// U_plus3 + U_minus3
				Mul_1 <= U_buf_2[15:8] + U_buf[15:8];
				Mult_op_1 <= coef2;
				VU_mul1 <= Mult_result1;
				
				
				state <= LI12;
			end
			
			LI12: begin
				U_even <= U_buf[15:8];
				V_even <= V_buf[15:8];

				// U_plus1 + U_minus1
				Mul_1 <= U_buf[7:0] + U_buf[15:8];
				Mult_op_1 <= coef3;
				VU_mul2 <= Mult_result1;
				
				
				state <= LI13;
			end
			
			LI13: begin
				Y_even_buf <= SRAM_read_data[15:8];
				Y_odd_buf <= SRAM_read_data[7:0];
				Up_even <= U_even - 16'sd128;
				
				Vp_even <= V_even - 16'sd128;
				VU_mul3 <= Mult_result1;
				
				Mul_2 <= {16'd0,Y_odd} - 32'sd16;
				Mult_op_2 <= a;
				
				Mul_3 <= Y_even - 32'sd16;
				Mult_op_3 <= a;
				state <= LI14;
			end
			
			LI14: begin
				Up_odd <= ((VU_mul1 - VU_mul2 + VU_mul3 + 16'd128) >> 8) - 16'sd128;
				SRAM_address <= Y_BASE_ADDRESS + Y_BASE_ADDRESS_COUNTER;
				Y_BASE_ADDRESS_COUNTER <= Y_BASE_ADDRESS_COUNTER + 4'd1;

				// V_plus5 + V_minus5
				Mul_1 <= V_buf_3[15:8] + V_buf[15:8];
				Mult_op_1 <= coef1;
				
				
				//Mul_2 <= {{16{Vp_odd[15]}},Vp_odd[15:0]};
				Mul_2 <= $signed(Vp_odd);
				Mult_op_2 <= c;
				RGB_odd1 <= Mult_result2;
				
				
				Mul_3 <= $signed(Vp_even);
				Mult_op_3 <= c;
				RGB_even1 <= Mult_result3;
				state <= LI15;
			end
			
			LI15: begin
				// V_plus3 + V_minus3
				Mul_1 <= V_buf_2[7:0] + V_buf[15:8];
				Mult_op_1 <= coef2;
				VU_mul1 <= Mult_result1;
				
				Mul_2 <= $signed(Up_odd);
				Mult_op_2 <= e;
				RGB_odd2 <= Mult_result2;
				
				Mul_3 <= $signed(Up_even);
				Mult_op_3 <= e;
				RGB_even2 <= Mult_result3;
				state <= LI16;
			end
			
			LI16: begin
				Y_even <= Y_even_buf;
				Y_odd <= Y_odd_buf;

				// V_plus1 + V_minus1
				Mul_1 <= V_buf_2[15:8] + V_buf[7:0];
				Mult_op_1 <= coef3;
				VU_mul2 <= Mult_result1;
				
				Mul_2 <= $signed(Vp_odd);
				Mult_op_2 <= f;
				RGB_odd2 <= Mult_result2;
				
				R_odd <= RGB_odd1 + RGB_odd2;
				R_even <= (RGB_even1 + RGB_even2);
				
				Mul_3 <= $signed(Vp_even);
				Mult_op_3 <= f;
				RGB_even2 <= Mult_result3;
				state <= LI17;
			end
			
			LI17: begin
				Y_even_buf <= SRAM_read_data[15:8];
				Y_odd_buf <= SRAM_read_data[7:0];

				// U_plus5 + U_minus5
				Mul_1 <= U_buf_3[15:8] + U_buf[15:8];
				Mult_op_1 <= coef1;
				VU_mul3 <= Mult_result1;
				
				
				Mul_2 <= $signed(Up_odd);
				Mult_op_2 <= h;
				RGB_odd3 <= Mult_result2; 
				
				Mul_3 <= $signed(Up_even);
				Mult_op_3 <= h;
				RGB_even3 <= Mult_result3;
			
				state <= LI18;
			end
			
			LI18: begin
				SRAM_we_n <= 1'b0;	
				SRAM_address <= RGB_BASE_ADDRESS + RGB_BASE_ADDRESS_COUNTER;
				RGB_BASE_ADDRESS_COUNTER <= RGB_BASE_ADDRESS_COUNTER + 8'd1;
				Vp_odd <= ((VU_mul1 - VU_mul2 + VU_mul3 + 16'd128) >> 8) - 16'sd128;
				SRAM_write_data <= {r_even, g_even};
				G_odd <= RGB_odd1 + RGB_odd2 + RGB_odd3;

				// U_plus3 + U_minus3
				Mul_1 <= U_buf_2[7:0] + U_buf[15:8];
				Mult_op_1 <= coef2;
				VU_mul1 <= Mult_result1;
				
				RGB_odd2 <= Mult_result2; 
				RGB_even2 <= Mult_result3;
				
				state <= LI19;
			end
			
			LI19: begin
				SRAM_address <= RGB_BASE_ADDRESS + RGB_BASE_ADDRESS_COUNTER;
				RGB_BASE_ADDRESS_COUNTER <= RGB_BASE_ADDRESS_COUNTER + 8'd1;
				SRAM_write_data <= {b_even, r_odd};
				B_odd <= RGB_odd1 + RGB_odd2;

				U_even <= U_buf[7:0];
				
				V_even <= V_buf[7:0];
				// U_plus1 + U_minus1
				Mul_1 <= U_buf_2[15:8] + U_buf[7:0];
				Mult_op_1 <= coef3;
				VU_mul2 <= Mult_result1;
				
				state <= LI20;
			end
			
			LI20: begin
				SRAM_address <= RGB_BASE_ADDRESS + RGB_BASE_ADDRESS_COUNTER;
				RGB_BASE_ADDRESS_COUNTER <= RGB_BASE_ADDRESS_COUNTER + 8'd1;
				SRAM_write_data <= {g_odd, b_odd};
				
				Up_even <= U_even - 16'sd128;
				Vp_even <= V_even - 16'sd128;
				counter <= counter + 4'd2;
				VU_mul3 <= Mult_result1;
				
				Mul_2 <= {16'd0,Y_odd} - 32'sd16;
				Mult_op_2 <= a;
				
				Mul_3 <= {16'd0,Y_even} - 32'sd16;
				Mult_op_3 <= a;
				
				state <= CC1;
			end
			
			CC1: begin
				SRAM_we_n <= 1'b1;
				SRAM_address <= Y_BASE_ADDRESS + Y_BASE_ADDRESS_COUNTER;
				Y_BASE_ADDRESS_COUNTER <= Y_BASE_ADDRESS_COUNTER + 4'd1;
				Up_odd <= ((VU_mul1 - VU_mul2 + VU_mul3 + 16'd128) >> 8) - 16'sd128;			

				// V_plus5 + V_minus5
				Mul_1 <= V_buf_3[7:0] + V_buf[15:8];
				Mult_op_1 <= coef1;
				
				Mul_2 <= $signed(Vp_odd);
				Mult_op_2 <= c;
				RGB_odd1 <= Mult_result2;
				

				Mul_3 <= $signed(Vp_even);
				Mult_op_3 <= c;
				RGB_even1 <= Mult_result3;
				
				state <= CC2;
			end
			
			CC2: begin
				if (counter < 18'sd309) begin
					if (Y_BASE_ADDRESS_COUNTER[0] == 1'b0) begin
						SRAM_address <= V_BASE_ADDRESS + V_BASE_ADDRESS_COUNTER;
						V_BASE_ADDRESS_COUNTER <= V_BASE_ADDRESS_COUNTER + 4'd1;
					end
				end
				// V_plus3 + V_minus3
				Mul_1 <= V_buf_3[15:8] + V_buf[7:0];
				Mult_op_1 <= coef2;
				VU_mul1 <= Mult_result1;
				
				Mul_2 <= $signed(Up_odd);
				Mult_op_2 <= e;
				RGB_odd2 <= Mult_result2;
				
				Mul_3 <= $signed(Up_even);
				Mult_op_3 <= e;
				RGB_even2 <= Mult_result3;
	
				state <= CC3;
			end
			
			CC3: begin
				if (counter < 18'sd309) begin
					if (Y_BASE_ADDRESS_COUNTER[0] == 1'b0) begin
						SRAM_address <= U_BASE_ADDRESS + U_BASE_ADDRESS_COUNTER;
						U_BASE_ADDRESS_COUNTER <= U_BASE_ADDRESS_COUNTER + 4'd1;
					end
				end
				Y_even <= Y_even_buf;
				Y_odd <= Y_odd_buf;
				R_odd <= RGB_odd1 + RGB_odd2;
				R_even <= RGB_even1 + RGB_even2;

				V_even <= V_buf_2[15:8]; 
				// V_plus1 + V_minus1
				Mul_1 <= V_buf_2[7:0] + V_buf_2[15:8];
				Mult_op_1 <= coef3;
				VU_mul2 <= Mult_result1;
				
				
				
				Mul_2 <= $signed(Vp_odd);
				Mult_op_2 <= f;
				RGB_odd2 <= Mult_result2;
				
				Mul_3 <= $signed(Vp_even);
				Mult_op_3 <= f;
				RGB_even2 <= Mult_result3;
				
				state <= CC4;
			end
			
			CC4: begin
				Y_even_buf <= SRAM_read_data[15:8];
				Y_odd_buf <= SRAM_read_data[7:0];
				
				// U_plus5 + U_minus5
				Mul_1 <= U_buf_3[7:0] + U_buf[15:8];
				Mult_op_1 <= coef1;
				VU_mul3 <= Mult_result1;
				
				Mul_2 <= $signed(Up_odd);
				Mult_op_2 <= h;
				RGB_odd3 <= Mult_result2;
				
				Mul_3 <= $signed(Up_even);
				Mult_op_3 <= h;
				RGB_even3 <= Mult_result3;	
				
				state <= CC5;
			end
			
			CC5: begin
				SRAM_address <= RGB_BASE_ADDRESS + RGB_BASE_ADDRESS_COUNTER;
				RGB_BASE_ADDRESS_COUNTER <= RGB_BASE_ADDRESS_COUNTER + 8'd1;
				Vp_odd <= ((VU_mul1 - VU_mul2 + VU_mul3 + 16'd128) >> 8) - 16'sd128;
				SRAM_we_n <= 1'b0;
				SRAM_write_data <= {r_even, g_even};
				G_odd <= RGB_odd1 + RGB_odd2 + RGB_odd3;
	
				// U_plus3 + U_minus3
				Mul_1 <= U_buf_3[15:8] + U_buf[7:0];
				Mult_op_1 <= coef2;
				VU_mul1 <= Mult_result1;
				
				RGB_odd2 <= Mult_result2;
				
				RGB_even2 <= Mult_result3;	
				
				V_buf <= {V_buf[7:0], V_buf_2[15:8]};
				V_buf_2 <= {V_buf_2[7:0], V_buf_3[15:8]};
				if (counter != 18'sd310) begin
					if (Y_BASE_ADDRESS_COUNTER[0] == 1'b0) begin
						V_buf_3 <= {V_buf_3[7:0], SRAM_read_data[15:8]};
						V_buf_4 <= SRAM_read_data[7:0];
					end else begin
						V_buf_3 <= {V_buf_3[7:0], V_buf_4};
					end
				end else begin
					V_buf <= {V_buf[7:0], V_buf_2[15:8]};
					V_buf_2 <= {V_buf_2[7:0], V_buf_3[15:8]};
					V_buf_3 <= {V_buf_3[7:0], V_buf_4};
				end
				
				state <= CC6;
			end
			
			CC6: begin
				SRAM_address <= RGB_BASE_ADDRESS + RGB_BASE_ADDRESS_COUNTER;
				RGB_BASE_ADDRESS_COUNTER <= RGB_BASE_ADDRESS_COUNTER + 8'd1;
				SRAM_write_data <= {b_even, r_odd};
				B_odd <= RGB_odd1 + RGB_odd2;
				U_even <= U_buf_2[15:8]; 
				// U_plus1 + U_minus1
				Mul_1 <= U_buf_2[7:0] + U_buf_2[15:8];
				Mult_op_1 <= coef3;
				VU_mul2 <= Mult_result1;
				
				
				state <= CC7;
			end
			
			CC7: begin
				SRAM_address <= RGB_BASE_ADDRESS + RGB_BASE_ADDRESS_COUNTER;
				RGB_BASE_ADDRESS_COUNTER <= RGB_BASE_ADDRESS_COUNTER + 8'd1;
				SRAM_write_data <= {g_odd, b_odd};
				Up_even <= U_even - 16'sd128;
				Up_odd <= ((VU_mul1 - VU_mul2 + VU_mul3 + 16'd128) >> 8) - 16'sd128;
				Vp_even <= V_even - 16'sd128;
				VU_mul3 <= Mult_result1;
				
				Mul_2 <= {16'd0,Y_odd} - 32'sd16;
				Mult_op_2 <= a;
				
				Mul_3 <= {16'd0,Y_even} - 32'sd16;
				Mult_op_3 <= a;
				
				U_buf <= {U_buf[7:0], U_buf_2[15:8]};
				U_buf_2 <= {U_buf_2[7:0], U_buf_3[15:8]};
				if (counter != 18'sd310) begin
					if (Y_BASE_ADDRESS_COUNTER[0] == 1'b0) begin
						U_buf_3 <= {U_buf_3[7:0], SRAM_read_data[15:8]};				
						U_buf_4 <= SRAM_read_data[7:0];
					end else begin
						U_buf_3 <= {U_buf_3[7:0], U_buf_4};
					end
				end else begin
					U_buf <= {U_buf[7:0], U_buf_2[15:8]};
					U_buf_2 <= {U_buf_2[7:0], U_buf_3[15:8]};
					U_buf_3 <= {U_buf_3[7:0], U_buf_4};
				end
				
				counter <= counter + 4'd2;
				if (counter == 18'sd312) begin
					state <= LO1;
				end else begin
					state <= CC1;
				end
			end
			
			LO1: begin
				SRAM_we_n <= 1'b1;
				if (counter < 18'sd316) begin
					SRAM_address <= Y_BASE_ADDRESS + Y_BASE_ADDRESS_COUNTER;
					Y_BASE_ADDRESS_COUNTER <= Y_BASE_ADDRESS_COUNTER + 4'd1;
				end
				Up_odd <= ((VU_mul1 - VU_mul2 + VU_mul3 + 16'd128) >> 8) - 16'sd128;

				// V_plus5 + V_minus5
				Mul_1 <= V_buf_3[7:0] + V_buf[15:8];
				Mult_op_1 <= coef1;
				
				Mul_2 <= $signed(Vp_odd);
				Mult_op_2 <= c;
				RGB_odd1 <= Mult_result2;
				
				Mul_3 <= $signed(Vp_even);
				Mult_op_3 <= c;
				RGB_even1 <= Mult_result3;
				
				state <= LO2;
			end
			
			LO2: begin
				// V_plus3 + V_minus3
				Mul_1 <= V_buf_3[15:8] + V_buf[7:0];
				Mult_op_1 <= coef2;
				VU_mul1 <= Mult_result1;
				
				Mul_2 <= $signed(Up_odd);
				Mult_op_2 <= e;
				RGB_odd2 <= Mult_result2;
				
				Mul_3 <= $signed(Up_even);
				Mult_op_3 <= e;
				RGB_even2 <= Mult_result3;
	
				state <= LO3;
			end
			
			LO3: begin
				Y_even <= Y_even_buf;
				Y_odd <= Y_odd_buf;
				R_odd <= RGB_odd1 + RGB_odd2;
				R_even <= RGB_even1 + RGB_even2;

				V_even <= V_buf_2[15:8];
				// V_plus1 + V_minus1
				Mul_1 <= V_buf_2[7:0] + V_buf_2[15:8];
				Mult_op_1 <= coef3;
				VU_mul2 <= Mult_result1;
				
				Mul_2 <= $signed(Vp_odd);
				Mult_op_2 <= f;
				RGB_odd2 <= Mult_result2;
				
				Mul_3 <= $signed(Vp_even);
				Mult_op_3 <= f;
				RGB_even2 <= Mult_result3;
				state <= LO4;
			end
			
			LO4: begin
				Y_even_buf <= SRAM_read_data[15:8];
				Y_odd_buf <= SRAM_read_data[7:0];
				// U_plus5 + U_minus5
				Mul_1 <= U_buf_3[7:0] + U_buf[15:8];
				Mult_op_1 <= coef1;
				VU_mul3 <= Mult_result1;
				

				Mul_2 <= $signed(Up_odd);
				Mult_op_2 <= h;
				RGB_odd3 <= Mult_result2;
				
				Mul_3 <= $signed(Up_even);
				Mult_op_3 <= h;
				RGB_even3 <= Mult_result3;
				
				state <= LO5;
			end
			
			LO5: begin
				SRAM_address <= RGB_BASE_ADDRESS + RGB_BASE_ADDRESS_COUNTER;
				RGB_BASE_ADDRESS_COUNTER <= RGB_BASE_ADDRESS_COUNTER + 8'd1;
				Vp_odd <= ((VU_mul1 - VU_mul2 + VU_mul3 + 16'd128) >> 8) - 16'sd128;
				SRAM_we_n <= 1'b0;
				SRAM_write_data <= {r_even, g_even};
				G_odd <= RGB_odd1 + RGB_odd2 + RGB_odd3;
	
				// U_plus3 + U_minus3
				Mul_1 <= U_buf_3[15:8] + U_buf[7:0];
				Mult_op_1 <= coef2;
				VU_mul1 <= Mult_result1;
				
				RGB_odd2 <= Mult_result2;
				
				RGB_even2 <= Mult_result3;
				
				V_buf <= {V_buf[7:0], V_buf_2[15:8]};
				V_buf_2 <= {V_buf_2[7:0], V_buf_3[15:8]};
				V_buf_3 <= {V_buf_3[7:0], V_buf_4};
				
				state <= LO6;
			end
			
			LO6: begin
				SRAM_address <= RGB_BASE_ADDRESS + RGB_BASE_ADDRESS_COUNTER;
				RGB_BASE_ADDRESS_COUNTER <= RGB_BASE_ADDRESS_COUNTER + 8'd1;
				SRAM_write_data <= {b_even, r_odd};
				B_odd <= RGB_odd1 + RGB_odd2;

				U_even <= U_buf_2[15:8];
				// U_plus1 + U_minus1
				Mul_1 <= U_buf_2[7:0] + U_buf_2[15:8];
				Mult_op_1 <= coef3;
				VU_mul2 <= Mult_result1;
				
				state <= LO7;
			end
			
			LO7: begin
				SRAM_address <= RGB_BASE_ADDRESS + RGB_BASE_ADDRESS_COUNTER;
				RGB_BASE_ADDRESS_COUNTER <= RGB_BASE_ADDRESS_COUNTER + 8'd1;
				SRAM_write_data <= {g_odd, b_odd};
				Up_even <= U_even - 16'sd128;
				Up_odd <= ((VU_mul1 - VU_mul2 + VU_mul3 + 16'd128) >> 8) - 16'sd128;
				Vp_even <= V_even - 16'sd128;
				VU_mul3 <= Mult_result1;
				
				Mul_2 <= {16'd0,Y_odd} - 32'sd16;
				Mult_op_2 <= a;
				
				Mul_3 <= {16'd0,Y_even} - 32'sd16;
				Mult_op_3 <= a;
				
				U_buf <= {U_buf[7:0], U_buf_2[15:8]};
				U_buf_2 <= {U_buf_2[7:0], U_buf_3[15:8]};
				U_buf_3 <= {U_buf_3[7:0], U_buf_4};
				
				counter <= counter + 4'd2;
				if (counter < 18'sd318) begin
					state <= LO1;
				end else begin
					state <= LI0;
					row_counter <= row_counter + 4'd1;
				end
			end
		endcase
	end
end

endmodule
