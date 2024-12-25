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
module Milestone2 (
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
logic [17:0] counter, CT_counter, read_counter, CS_counter, column, WS_counter, WS_offset, never_reset, tracker;
logic [17:0] FS_stopper, FSCT_stopper, FS_stop, CT_stopper, CTCS_stopper, CT_stop, CS_stopper, CSWS_stopper, WS_stop, CS_stop, WS_stopper, WSCS_stopper;
logic [6:0] address_0_offset;
logic [6:0] offset;
logic WS_SRAM_we_n, FS_SRAM_we_n;
logic [17:0] FS_SRAM_address, WS_SRAM_address;

M2_state_type state;
FSM2_state_type FS_state;
CTM2_state_type CT_state;
CSM2_state_type CS_state;
WSM2_state_type WS_state;


logic [6:0] address_0, address_1, address_2, address_3, address_4, address_5, FS_address_0, CT_address_0, CT_address_1, CT_address_2, CS_address_2, WS_address_4, CS_address_4, WS_address_5, CS_address_5;
logic [31:0] write_data_a [1:0];
logic signed [31:0] write_data_b [1:0];
logic [31:0] write_data_c [1:0];
logic signed [31:0] read_data_a [1:0];
logic [31:0] read_data_b [1:0];
logic [31:0] read_data_c [1:0];
logic write_en_0, write_en_1, write_en_2, write_en_3, write_en_4, write_en_5, FS_write_en_0, CT_write_en_0, CT_write_en_2, CS_write_en_2, CS_write_en_4, WS_write_en_4, CS_write_en_5, WS_write_en_5;

logic [6:0] row_block, col_block, ws_row_block, ws_col_block;
logic [3:0] col_index, row_index, ws_row_index;
logic [2:0] ws_col_index;
logic YUV_fetch = 1'b1;
logic [17:0] row_address, col_address, WS_row_address, WS_col_address;
logic [31:0] y_buf;
logic signed [31:0] C0, C1, C2; 
logic [31:0] T_sum;
logic [31:0] S_sum1, S_sum2, S_sum3, write_register, sum1, sum2;
logic [6:0] c_0, c_1, c_2, coef_offset, CT_c_0, CS_c_0, CT_c_1, CS_c_1, CT_c_2, CS_c_2;
logic FS_start, CT_start, CS_start, WS_start;
logic [7:0] s_sum1, s_sum2, s_sum3;

logic signed [31:0] mult1, mult2, mult3, CT_mult1, CT_mult2, CT_mult3, CS_mult1, CS_mult2, CS_mult3;
logic signed [31:0] Mult_result1, Mult_result2, Mult_result3;
logic signed [63:0] Mult_result_long1, Mult_result_long2, Mult_result_long3;


assign row_address = (YUV_fetch == 1'b1) ? ({row_block, row_index[2:0]} << 8) + ({row_block, row_index[2:0]} << 6) : ({row_block, row_index[2:0]} << 7) + ({row_block, row_index[2:0]} << 5);
assign col_address = (YUV_fetch == 1'b1) ? {col_block, col_index[2:0]} : {col_block, col_index[2:0]};

assign WS_row_address = ({ws_row_block, ws_row_index[2:0]} << 7) + ({ws_row_block, ws_row_index[2:0]} << 5);
assign WS_col_address = {ws_col_block, ws_col_index[1:0]};

assign FS_stop = FS_stopper + FSCT_stopper;
assign CT_stop = CT_stopper + CTCS_stopper;
assign CS_stop = CS_stopper + CSWS_stopper;
assign WS_stop = WS_stopper + WSCS_stopper + 1'd1;

// THese are the calculations for T
// C0 is coefficient, mult1 is our Y or T pixels
assign Mult_result_long1 = mult1 * C0;
assign Mult_result1 = Mult_result_long1[31:0];

// C1 is a coefficient, mult2 is our Y or T pixels
assign Mult_result_long2 = mult2 * C1;
assign Mult_result2 = Mult_result_long2[31:0];

// C2 is a coefficient, mult3 is our Y or T pixels
assign Mult_result_long3 = mult3 * C2;
assign Mult_result3 = Mult_result_long3[31:0];

assign s_sum1 = (sum1[31]) ? 8'd0 : (|sum1[30:24]) ? 8'd255 : sum1[23:16];
assign s_sum2 = (sum2[31]) ? 8'd0 : (|sum2[30:24]) ? 8'd255 : sum2[23:16];
assign s_sum3 = (S_sum3[31]) ? 8'd0 : (|S_sum3[30:24]) ? 8'd255 : S_sum3[23:16];


// instantiate RAM0
dual_port_RAM0 RAM_inst0 (
	.address_a ( address_0 ),
	.address_b ( address_1 ),
	.clock ( CLOCK_50_I ),
	.data_a ( write_data_a[0] ),
	.data_b ( write_data_a[1] ),
	.wren_a ( write_en_0 ),
	.wren_b ( write_en_1 ),
	.q_a ( read_data_a[0] ),
	.q_b ( read_data_a[1] )
	);

// instantiate RAM1
dual_port_RAM1 RAM_inst1 (
	.address_a ( address_2 ),
	.address_b ( address_3 ),
	.clock ( CLOCK_50_I ),
	.data_a ( write_data_b[0] ),
	.data_b ( write_data_b[1] ),
	.wren_a ( write_en_2 ),
	.wren_b ( write_en_3 ),
	.q_a ( read_data_b[0] ),
	.q_b ( read_data_b[1] )
	);
	
// instantiate RAM2
dual_port_RAM2 RAM_inst2 (
	.address_a ( address_4 ),
	.address_b ( address_5 ),
	.clock ( CLOCK_50_I ),
	.data_a ( write_data_c[0] ),
	.data_b ( write_data_c[1] ),
	.wren_a ( write_en_4 ),
	.wren_b ( write_en_5 ),
	.q_a ( read_data_c[0] ),
	.q_b ( read_data_c[1] )
	);

always_comb begin
	case(c_0)
	0:   C0 = 32'sd1448;
	1:   C0 = 32'sd1448;
	2:   C0 = 32'sd1448;
	3:   C0 = 32'sd1448;
	4:   C0 = 32'sd1448;
	5:   C0 = 32'sd1448;
	6:   C0 = 32'sd1448;
	7:   C0 = 32'sd1448;
	8:   C0 = 32'sd2008;
	9:   C0 = 32'sd1702;
	10:  C0 = 32'sd1137;
	11:  C0 = 32'sd399;
	12:  C0 = -32'sd399;
	13:  C0 = -32'sd1137;
	14:  C0 = -32'sd1702;
	15:  C0 = -32'sd2008;
	16:  C0 = 32'sd1892;
	17:  C0 = 32'sd783;
	18:  C0 = -32'sd783;
	19:  C0 = -32'sd1892;
	20:  C0 = -32'sd1892;
	21:  C0 = -32'sd783;
	22:  C0 = 32'sd783;
	23:  C0 = 32'sd1892;
	24:  C0 = 32'sd1702;
	25:  C0 = -32'sd399;
	26:  C0 = -32'sd2008;
	27:  C0 = -32'sd1137;
	28:  C0 = 32'sd1137;
	29:  C0 = 32'sd2008;
	30:  C0 = 32'sd399;
	31:  C0 = -32'sd1702;
	32:  C0 = 32'sd1448;
	33:  C0 = -32'sd1448;
	34:  C0 = -32'sd1448;
	35:  C0 = 32'sd1448;
	36:  C0 = 32'sd1448;
	37:  C0 = -32'sd1448;
	38:  C0 = -32'sd1448;
	39:  C0 = 32'sd1448;
	40:  C0 = 32'sd1137;
	41:  C0 = -32'sd2008;
	42:  C0 = 32'sd399;
	43:  C0 = 32'sd1702;
	44:  C0 = -32'sd1702;
	45:  C0 = -32'sd399;
	46:  C0 = 32'sd2008;
	47:  C0 = -32'sd1137;
	48:  C0 = 32'sd783;
	49:  C0 = -32'sd1892;
	50:  C0 = 32'sd1892;
	51:  C0 = -32'sd783;
	52:  C0 = -32'sd783;
	53:  C0 = 32'sd1892;
	54:  C0 = -32'sd1892;
	55:  C0 = 32'sd783;
	56:  C0 = 32'sd399;
   57:  C0 = -32'sd1137;
   58:  C0 = 32'sd1702;
   59:  C0 = -32'sd2008;
   60:  C0 = 32'sd2008;
   61:  C0 = -32'sd1702;
   62:  C0 = 32'sd1137;
   63:  C0 = -32'sd399;
	default: C0 = 32'd0;
	endcase	
end

always_comb begin
	case(c_1)
	0:   C1 = 32'sd1448;
	1:   C1 = 32'sd1448;
	2:   C1 = 32'sd1448;
	3:   C1 = 32'sd1448;
	4:   C1 = 32'sd1448;
	5:   C1 = 32'sd1448;
	6:   C1 = 32'sd1448;
	7:   C1 = 32'sd1448;
	8:   C1 = 32'sd2008;
	9:   C1 = 32'sd1702;
	10:  C1 = 32'sd1137;
	11:  C1 = 32'sd399;
	12:  C1 = -32'sd399;
	13:  C1 = -32'sd1137;
	14:  C1 = -32'sd1702;
	15:  C1 = -32'sd2008;
	16:  C1 = 32'sd1892;
	17:  C1 = 32'sd783;
	18:  C1 = -32'sd783;
	19:  C1 = -32'sd1892;
	20:  C1 = -32'sd1892;
	21:  C1 = -32'sd783;
	22:  C1 = 32'sd783;
	23:  C1 = 32'sd1892;
	24:  C1 = 32'sd1702;
	25:  C1 = -32'sd399;
	26:  C1 = -32'sd2008;
	27:  C1 = -32'sd1137;
	28:  C1 = 32'sd1137;
	29:  C1 = 32'sd2008;
	30:  C1 = 32'sd399;
	31:  C1 = -32'sd1702;
	32:  C1 = 32'sd1448;
	33:  C1 = -32'sd1448;
	34:  C1 = -32'sd1448;
	35:  C1 = 32'sd1448;
	36:  C1 = 32'sd1448;
	37:  C1 = -32'sd1448;
	38:  C1 = -32'sd1448;
	39:  C1 = 32'sd1448;
	40:  C1 = 32'sd1137;
	41:  C1 = -32'sd2008;
	42:  C1 = 32'sd399;
	43:  C1 = 32'sd1702;
	44:  C1 = -32'sd1702;
	45:  C1 = -32'sd399;
	46:  C1 = 32'sd2008;
	47:  C1 = -32'sd1137;
	48:  C1 = 32'sd783;
	49:  C1 = -32'sd1892;
	50:  C1 = 32'sd1892;
	51:  C1 = -32'sd783;
	52:  C1 = -32'sd783;
	53:  C1 = 32'sd1892;
	54:  C1 = -32'sd1892;
	55:  C1 = 32'sd783;
	56:  C1 = 32'sd399;
   57:  C1 = -32'sd1137;
   58:  C1 = 32'sd1702;
   59:  C1 = -32'sd2008;
   60:  C1 = 32'sd2008;
   61:  C1 = -32'sd1702;
   62:  C1 = 32'sd1137;
   63:  C1 = -32'sd399;
	default: C1 = 32'd0;
	endcase	
end

always_comb begin
	case(c_2)
	0:   C2 = 32'sd1448;
	1:   C2 = 32'sd1448;
	2:   C2 = 32'sd1448;
	3:   C2 = 32'sd1448;
	4:   C2 = 32'sd1448;
	5:   C2 = 32'sd1448;
	6:   C2 = 32'sd1448;
	7:   C2 = 32'sd1448;
	8:   C2 = 32'sd2008;
	9:   C2 = 32'sd1702;
	10:  C2 = 32'sd1137;
	11:  C2 = 32'sd399;
	12:  C2 = -32'sd399;
	13:  C2 = -32'sd1137;
	14:  C2 = -32'sd1702;
	15:  C2 = -32'sd2008;
	16:  C2 = 32'sd1892;
	17:  C2 = 32'sd783;
	18:  C2 = -32'sd783;
	19:  C2 = -32'sd1892;
	20:  C2 = -32'sd1892;
	21:  C2 = -32'sd783;
	22:  C2 = 32'sd783;
	23:  C2 = 32'sd1892;
	24:  C2 = 32'sd1702;
	25:  C2 = -32'sd399;
	26:  C2 = -32'sd2008;
	27:  C2 = -32'sd1137;
	28:  C2 = 32'sd1137;
	29:  C2 = 32'sd2008;
	30:  C2 = 32'sd399;
	31:  C2 = -32'sd1702;
	32:  C2 = 32'sd1448;
	33:  C2 = -32'sd1448;
	34:  C2 = -32'sd1448;
	35:  C2 = 32'sd1448;
	36:  C2 = 32'sd1448;
	37:  C2 = -32'sd1448;
	38:  C2 = -32'sd1448;
	39:  C2 = 32'sd1448;
	40:  C2 = 32'sd1137;
	41:  C2 = -32'sd2008;
	42:  C2 = 32'sd399;
	43:  C2 = 32'sd1702;
	44:  C2 = -32'sd1702;
	45:  C2 = -32'sd399;
	46:  C2 = 32'sd2008;
	47:  C2 = -32'sd1137;
	48:  C2 = 32'sd783;
	49:  C2 = -32'sd1892;
	50:  C2 = 32'sd1892;
	51:  C2 = -32'sd783;
	52:  C2 = -32'sd783;
	53:  C2 = 32'sd1892;
	54:  C2 = -32'sd1892;
	55:  C2 = 32'sd783;
	56:  C2 = 32'sd399;
   57:  C2 = -32'sd1137;
   58:  C2 = 32'sd1702;
   59:  C2 = -32'sd2008;
   60:  C2 = 32'sd2008;
   61:  C2 = -32'sd1702;
   62:  C2 = 32'sd1137;
   63:  C2 = -32'sd399;
	default: C2 = 32'd0;
	endcase	
end


always_ff @ (posedge CLOCK_50_I or negedge Resetn) begin
	if (~Resetn) begin
		FS_state <= FS_IDLE;				
		FS_SRAM_we_n <= 1'b1;
		FS_SRAM_address <= 18'd0;
		col_index <= 3'd0;
		row_index <= 3'd0;
		col_block <= 7'd0;
		row_block <= 7'd0;
		FS_address_0 <= 9'd0;
		FS_stopper <= 7'd0;
	end else begin
		case (FS_state)
			FS_IDLE: begin
				if (FS_start) begin
					// Start filling the SRAM
					FS_state <= FSLI0;
					row_index <= 3'd0;
					col_index <= 3'd0;
					FS_address_0 <= 9'd0;
				end
			end
			
			FSLI0: begin
				FS_write_en_0 <= 1'b1;
				if (YUV_fetch == 1'b1) begin
					FS_SRAM_address <= RY_BASE_ADDRESS + row_address + col_address;
				end else begin 
					FS_SRAM_address <= RU_BASE_ADDRESS + row_address + col_address;
				end

				col_index <= col_index + 2'd1;
				FS_state <= FSLI1;
			end
			
			FSLI1: begin
				if (YUV_fetch == 1'b1) begin
					FS_SRAM_address <= RY_BASE_ADDRESS + row_address + col_address;
				end else begin 
					FS_SRAM_address <= RU_BASE_ADDRESS + row_address + col_address;
				end
				col_index <= col_index + 2'd1;
				FS_state <= FSLI2;
			end
			
			FSLI2: begin
				if (YUV_fetch == 1'b1) begin
					FS_SRAM_address <= RY_BASE_ADDRESS + row_address + col_address;
				end else begin 
					FS_SRAM_address <= RU_BASE_ADDRESS + row_address + col_address;
				end
				col_index <= col_index + 2'd1;
				FS_state <= FSCC1;
			end
			
			FSCC1: begin
				if (YUV_fetch == 1'b1) begin
					FS_SRAM_address <= RY_BASE_ADDRESS + row_address + col_address;
				end else begin 
					FS_SRAM_address <= RU_BASE_ADDRESS + row_address + col_address;
				end
				y_buf[31:16] <= $signed(SRAM_read_data);
				col_index <= col_index + 2'd1;
				FS_state <= FSCC2;
			end
			
			FSCC2: begin
				if (YUV_fetch == 1'b1) begin
					FS_SRAM_address <= RY_BASE_ADDRESS + row_address + col_address;
				end else begin 
					FS_SRAM_address <= RU_BASE_ADDRESS + row_address + col_address;
				end
				y_buf[15:0] <= $signed(SRAM_read_data);
				col_index <= col_index + 2'd1;
				FS_state <= FSCC3;
			end 
			
			FSCC3: begin
				if (YUV_fetch == 1'b1) begin
					FS_SRAM_address <= RY_BASE_ADDRESS + row_address + col_address;
				end else begin 
					FS_SRAM_address <= RU_BASE_ADDRESS + row_address + col_address;
				end
				y_buf[31:16] <= $signed(SRAM_read_data);
				write_data_a[0] <= y_buf[31:0];
				if (FS_address_0 > 7'd0) begin
					FS_address_0 <= FS_address_0 + 7'd1;
				end
				col_index <= col_index + 2'd1;
				FS_state <= FSCC4;
			end
			
			FSCC4: begin
				if (YUV_fetch == 1'b1) begin
					FS_SRAM_address <= RY_BASE_ADDRESS + row_address + col_address;
				end else begin 
					FS_SRAM_address <= RU_BASE_ADDRESS + row_address + col_address;
				end
				y_buf[15:0] <= $signed(SRAM_read_data);
				col_index <= col_index + 2'd1;
				FS_state <= FSCC5;
			end
			
			FSCC5: begin
				if (YUV_fetch == 1'b1) begin
					FS_SRAM_address <= RY_BASE_ADDRESS + row_address + col_address;
				end else begin 
					FS_SRAM_address <= RU_BASE_ADDRESS + row_address + col_address;
				end
				y_buf[31:16] <= $signed(SRAM_read_data);
				write_data_a[0] <= y_buf[31:0];
				FS_address_0 <= FS_address_0 + 7'd1;
				col_index <= 2'd0;
				row_index <= row_index + 2'd1;
				FS_state <= FSCC6;
			end
			
			FSCC6: begin
				y_buf[15:0] <= $signed(SRAM_read_data);
				FS_state <= FSCC7;
			end
			
			FSCC7: begin
				if (row_index <= 3'd7) begin
					if (YUV_fetch == 1'b1) begin
						FS_SRAM_address <= RY_BASE_ADDRESS + row_address + col_address;
					end else begin 
						FS_SRAM_address <= RU_BASE_ADDRESS + row_address + col_address;
					end
				end
				y_buf[31:16] <= $signed(SRAM_read_data);
				write_data_a[0] <= y_buf[31:0];
				FS_address_0 <= FS_address_0 + 7'd1;
				col_index <= col_index + 2'd1;
				FS_state <= FSCC8;
			end
			
			FSCC8: begin
			
				if (row_index <= 3'd7) begin
					if (YUV_fetch == 1'b1) begin
						FS_SRAM_address <= RY_BASE_ADDRESS + row_address + col_address;
					end else begin 
						FS_SRAM_address <= RU_BASE_ADDRESS + row_address + col_address;
					end
					FS_state <= FSCC9;
				end else begin
					FS_address_0 <= FS_address_0 + 7'd1;
					FS_state <= FSLO;
					FS_stopper <= FS_stopper + 7'd1;
				end
				y_buf[15:0] <= $signed(SRAM_read_data);
				col_index <= col_index + 2'd1;
			end

			FSCC9: begin
				if (YUV_fetch == 1'b1) begin
					FS_SRAM_address <= RY_BASE_ADDRESS + row_address + col_address;
				end else begin 
					FS_SRAM_address <= RU_BASE_ADDRESS + row_address + col_address;
				end
				write_data_a[0] <= y_buf[31:0];
				FS_address_0 <= FS_address_0 + 7'd1;
				col_index <= col_index + 2'd1;
				FS_state <= FSCC1;
			end
			
			FSLO: begin
				write_data_a[0] <= y_buf[31:0];
				FS_address_0 <= FS_address_0 + 7'd1;
				if (col_block == 6'd39 && row_block == 6'd29) begin
					YUV_fetch <= 1'b0;
					col_block <= 6'd0;
					row_block <= 6'd0;
				end
				else if (YUV_fetch == 1'b1) begin
					if (col_block <= 6'd38) begin
						col_block <= col_block + 6'd1; 
					end else begin
						col_block <= 6'd0;
						row_block <= row_block + 6'd1;	
					end
				end else begin
					if (col_block <= 6'd18) begin
						col_block <= col_block + 6'd1; 
					end else begin
						col_block <= 6'd0;
						row_block <= row_block + 6'd1;	
					end
			end
			FS_state <= FS_IDLE;
		end
		endcase
	end
end


always_ff @ (posedge CLOCK_50_I or negedge Resetn) begin
	if (~Resetn) begin
		CT_state <= CT_IDLE;			
		counter <= 18'd0;
		CT_mult1 <= 16'd0;
		CT_mult2 <= 16'd0;
		CT_mult3 <= 16'd0;
		CT_address_0 <= 7'd0;
		address_1 <= 7'd0;
		CT_address_2 <= 7'd0;
		CT_counter <= 18'd0;
		T_sum <= 18'd0;
		CT_c_0 <= 6'd0;
		CT_c_1 <= 6'd0;
		CT_c_2 <= 6'd0;
		coef_offset <= 6'd0;
		address_0_offset <= 6'd0;
		FSCT_stopper <= 7'd0;
		CT_stopper <= 7'd0;

	end else begin
		case (CT_state)
			CT_IDLE: begin
				if (CT_start) begin
					// Start filling the SRAM
					CT_state <= CTLI0;			
				end
			end
			
			CTLI0: begin
				CT_write_en_0 <= 1'b0;
				write_en_1 <= 1'b0;
				CT_address_0 <= 7'd0;
				address_1 <= 7'd1;
				CT_state <= CTLI1;
			end
			
			CTLI1: begin
				CT_address_0 <= CT_address_0 + 7'd2;
				CT_address_2 <= 7'd0;
				CT_state <= CTLI2;
			end
			
			CTLI2: begin
				CT_address_0 <= CT_address_0 + 7'd1;
				CT_counter <= CT_counter + 18'd1;
				CT_mult1 <= $signed(read_data_a[0][31:16]);
				CT_mult2 <= $signed(read_data_a[0][15:0]);
				CT_mult3 <= $signed(read_data_a[1][31:16]);
				CT_c_0 <= 6'd0 + coef_offset;
				CT_c_1 <= 6'd8 + coef_offset;
				CT_c_2 <= 6'd16 + coef_offset;
				CT_state <= CTCC0;
			end
			
			CTCC0: begin
				if (CT_counter == 18'd8) begin
					CT_address_0 <= CT_address_0 + 7'd1;
					address_1 <= address_1 + 7'd4;
					CT_counter <= 18'd0;
					address_0_offset <= address_0_offset + 4'd4;
				end else begin
					CT_address_0 <= address_0_offset;
				end
				if (counter > 18'd0) begin
					CT_address_2 <= CT_address_2 + 4'd1;
				end
				CT_mult1 <= $signed(read_data_a[1][15:0]);
				CT_mult2 <= $signed(read_data_a[0][31:16]);
				CT_mult3 <= $signed(read_data_a[0][15:0]);
				CT_c_0 <= CT_c_0 + 6'd24;
				CT_c_1 <= CT_c_1 + 6'd24;
				CT_c_2 <= CT_c_2 + 6'd24;
				T_sum <= $signed(T_sum + Mult_result1 + Mult_result2 + Mult_result3);
				CT_state <= CTCC1;
			end
			
			CTCC1: begin
				CT_write_en_2 <= 1'b1;
				if (CT_counter == 18'd8) begin
					CT_address_0 <= CT_address_0 + 7'd1;
					address_1 <= address_1 + 7'd4;
					CT_counter <= 18'd0;
				end else begin
					CT_address_0 <= address_0_offset;
				end
				counter <= counter + 7'd1;
				CT_address_0 <= CT_address_0 + 7'd2;
				CT_mult1 <= $signed(read_data_a[0][31:16]);
				CT_mult2 <= $signed(read_data_a[0][15:0]);
				T_sum <= $signed(T_sum + Mult_result1 + Mult_result2 + Mult_result3);
				CT_c_0 <= CT_c_0 + 6'd24;
				CT_c_1 <= CT_c_1 + 6'd24;
				if (coef_offset == 6'd7)begin
					coef_offset <= 6'd0;
				end else begin
					coef_offset <= coef_offset + 6'd1;
				end
				if (counter == 7'd63) begin
					CT_state <= CTLO;
					CT_stopper <= CT_stopper + 7'd1;
					FSCT_stopper <= FSCT_stopper + 7'd1;
					counter <= 7'd0;
				end else begin
					CT_state <= CTCC2;
				end
			end
			
			CTCC2: begin
				CT_counter <= CT_counter + 18'd1;
				CT_address_0 <= CT_address_0 + 7'd1;
				CT_mult1 <= $signed(read_data_a[0][31:16]);
				CT_mult2 <= $signed(read_data_a[0][15:0]);
				CT_mult3 <= $signed(read_data_a[1][31:16]);
				CT_c_0 <= 6'd0 + coef_offset;
				CT_c_1 <= 6'd8 + coef_offset;
				CT_c_2 <= 6'd16 + coef_offset;
				write_data_b[0] <= $signed(T_sum + Mult_result1 + Mult_result2) >>> 8;
				T_sum <= 32'd0;
				CT_state <= CTCC0;
			end
			
			CTLO: begin
				write_data_b[0] <= $signed(T_sum + Mult_result1 + Mult_result2) >>> 8;
				CT_state <= CT_IDLE;
				CT_address_0 <= 32'd0;
				address_0_offset <= 7'd0;
			end
		endcase
	end
end

always_ff @ (posedge CLOCK_50_I or negedge Resetn) begin
	if (~Resetn) begin
		CS_state <= CS_IDLE;			
		CS_address_2 <= 7'd0;
		CS_address_4 <= 7'd0;
		CS_address_5 <= 7'd0;
		CS_c_0 <= 6'd0;
		CS_c_1 <= 6'd0;
		CS_c_2 <= 6'd0;
		CS_mult1 <= 6'd0;
		CS_mult2 <= 6'd0;
		CS_mult3 <= 6'd0;
		offset <= 6'd0;
		S_sum1 <= 32'd0;
		S_sum2 <= 32'd0;
		S_sum3 <= 32'd0;
		CS_counter <= 4'd0;
		column <= 4'd0;
		never_reset <= 4'd0;
		CS_write_en_4 <= 1'b0;
		CS_write_en_5 <= 1'b0;
		CTCS_stopper <= 7'd0;
		CS_stopper <= 7'd0;
		WSCS_stopper <= 7'd0;
	
	end else begin
		case (CS_state)
			CS_IDLE: begin
				if (CS_start) begin
					// Start filling the SRAM
					CS_state <= CSLI0;			
				end
			end
			
			CSLI0: begin
				CS_address_2 <= 7'd0;
				CS_state <= CSLI1;
				CS_write_en_2 <= 1'b0;
			end
			
			CSLI1: begin
				CS_address_2 <= CS_address_2 + 7'd8;
				CS_state <= CSCC0;
			end
			
			CSCC0: begin
				if (CS_counter < 4'd3 && CS_counter > 4'd0) begin
					CS_address_4 <= CS_address_4 + 7'd16;
				end
				if (CS_counter == 4'd0) begin
					CS_address_4 <= 4'd0 + column;
				end
				CS_address_2 <= CS_address_2 + 7'd8;
				if (CS_counter == 4'd0) begin
					CS_address_5 <= 7'd8 + column;
				end
				CS_write_en_4 <= 1'b1;
				CS_write_en_5 <= 1'b1;
				if (never_reset > 4'd0 && CS_counter != 4'd3) begin
					write_data_c[0] <= write_register;
				end
				S_sum1 <= 32'd0;
				S_sum2 <= 32'd0;
				S_sum3 <= 32'd0;
				CS_mult1 <= read_data_b[0]; 
				CS_mult2 <= read_data_b[0];
				CS_mult3 <= read_data_b[0];
				CS_c_0 <= 6'd0 + offset;
				CS_c_1 <= 6'd1 + offset;
				CS_c_2 <= 6'd2 + offset;
				if (offset == 7'd6) begin
					offset <= 4'd0;
				end else begin
					offset <= offset + 4'd3;
				end
				CS_state <= CSCC1;
			end
			
			CSCC1: begin
				CS_address_2 <= CS_address_2 + 7'd8;
				if (CS_counter > 4'd0) begin
					CS_address_5 <= CS_address_5 + 7'd24;
				end
				CS_mult1 <= read_data_b[0]; 
				CS_mult2 <= read_data_b[0];
				CS_mult3 <= read_data_b[0];
				CS_c_0 <= CS_c_0 + 4'd8;
				CS_c_1 <= CS_c_1 + 4'd8;
				CS_c_2 <= CS_c_2 + 4'd8;
				S_sum1 <= S_sum1 + Mult_result1;
				S_sum2 <= S_sum2 + Mult_result2;
				S_sum3 <= S_sum3 + Mult_result3;
				CS_counter <= CS_counter + 7'd1;
				CS_state <= CSCC2;
			end
			
			CSCC2: begin
				never_reset <= never_reset + 4'd1;
				CS_address_2 <= CS_address_2 + 7'd8;
				if (CS_counter >= 4'd2) begin
					CS_address_4 <= CS_address_4 + 7'd8;
				end
				if (CS_counter == 4'd3) begin
					column <= column + 4'd1;
					CS_counter <= 4'd0;
				end
				CS_mult1 <= read_data_b[0]; 
				CS_mult2 <= read_data_b[0];
				CS_mult3 <= read_data_b[0];
				CS_c_0 <= CS_c_0 + 4'd8;
				CS_c_1 <= CS_c_1 + 4'd8;
				CS_c_2 <= CS_c_2 + 4'd8;
				S_sum1 <= S_sum1 + Mult_result1;
				S_sum2 <= S_sum2 + Mult_result2;
				S_sum3 <= S_sum3 + Mult_result3;
				CS_state <= CSCC3;
			end
			
			CSCC3: begin
				CS_address_2 <= CS_address_2 + 7'd8;
				CS_mult1 <= read_data_b[0]; 
				CS_mult2 <= read_data_b[0];
				CS_mult3 <= read_data_b[0];
				CS_c_0 <= CS_c_0 + 4'd8;
				CS_c_1 <= CS_c_1 + 4'd8;
				CS_c_2 <= CS_c_2 + 4'd8;
				S_sum1 <= S_sum1 + Mult_result1;
				S_sum2 <= S_sum2 + Mult_result2;
				S_sum3 <= S_sum3 + Mult_result3;
				CS_state <= CSCC4;
			end				
				
			CSCC4: begin
				CS_address_2 <= CS_address_2 + 7'd8;
				CS_mult1 <= read_data_b[0]; 
				CS_mult2 <= read_data_b[0];
				CS_mult3 <= read_data_b[0];
				CS_c_0 <= CS_c_0 + 4'd8;
				CS_c_1 <= CS_c_1 + 4'd8;
				CS_c_2 <= CS_c_2 + 4'd8;
				S_sum1 <= S_sum1 + Mult_result1;
				S_sum2 <= S_sum2 + Mult_result2;
				S_sum3 <= S_sum3 + Mult_result3;
				CS_state <= CSCC5;
			end
			
			CSCC5: begin
				CS_address_2 <= CS_address_2 + 7'd8;
				CS_mult1 <= read_data_b[0]; 
				CS_mult2 <= read_data_b[0];
				CS_mult3 <= read_data_b[0];
				CS_c_0 <= CS_c_0 + 4'd8;
				CS_c_1 <= CS_c_1 + 4'd8;
				CS_c_2 <= CS_c_2 + 4'd8;
				S_sum1 <= S_sum1 + Mult_result1;
				S_sum2 <= S_sum2 + Mult_result2;
				S_sum3 <= S_sum3 + Mult_result3;
				CS_state <= CSCC6;
			end
		
			CSCC6: begin
				CS_mult1 <= read_data_b[0]; 
				CS_mult2 <= read_data_b[0];
				CS_mult3 <= read_data_b[0];
				CS_c_0 <= CS_c_0 + 4'd8;
				CS_c_1 <= CS_c_1 + 4'd8;
				CS_c_2 <= CS_c_2 + 4'd8;
				S_sum1 <= S_sum1 + Mult_result1;
				S_sum2 <= S_sum2 + Mult_result2;
				S_sum3 <= S_sum3 + Mult_result3;
				CS_state <= CSCC7;
			end	

			CSCC7: begin
				CS_address_2 <= column;
				CS_mult1 <= read_data_b[0]; 
				CS_mult2 <= read_data_b[0];
				CS_mult3 <= read_data_b[0];
				CS_c_0 <= CS_c_0 + 4'd8;
				CS_c_1 <= CS_c_1 + 4'd8;
				CS_c_2 <= CS_c_2 + 4'd8;
				S_sum1 <= S_sum1 + Mult_result1;
				S_sum2 <= S_sum2 + Mult_result2;
				S_sum3 <= S_sum3 + Mult_result3;
				CS_state <= CSCC8;
			end	
		
			CSCC8: begin
				CS_address_2 <= CS_address_2 + 7'd8;
				write_data_c[0] <= S_sum1 + Mult_result1;
				write_data_c[1] <= S_sum2 + Mult_result2;
				write_register <= S_sum3 + Mult_result3;
				if (column == 8'd8) begin
					CS_state <= CSLO;
					CS_stopper <= CS_stopper + 7'd1;
					CTCS_stopper <= CTCS_stopper + 7'd1;
					WSCS_stopper <= WSCS_stopper + 7'd1;
					column <= 8'd0;
				end else begin
					CS_state <= CSCC0;
				end
			end
			
			CSLO: begin
				write_data_c[0] <= S_sum1;
				write_data_c[1] <= S_sum2;
				CS_state <= CS_IDLE;
			end
		endcase
	end
end

always_ff @ (posedge CLOCK_50_I or negedge Resetn) begin
	if (~Resetn) begin
		WS_state <= WS_IDLE;			
		WS_SRAM_we_n <= 1'b1;
		WS_SRAM_address <= 18'd0;;
		WS_counter <= 18'd0;
		WS_address_4 <= 9'd0;
		WS_address_5 <= 9'd0;
		WS_offset <= 18'd0;
		ws_col_index <= 18'd0;
		ws_row_index <= 18'd0;
		ws_col_block <= 18'd0;
		ws_row_block <= 18'd0;
		CSWS_stopper <= 7'd0;
		WS_stopper <= 7'd0;
		sum1 <= 32'd0;
		sum2 <= 32'd0;


	end else begin
		case (WS_state)
			WS_IDLE: begin
				if (WS_start) begin
					// Start filling the SRAM
					WS_state <= WSLI0;			
				end
			end
			
			WSLI0: begin
				WS_offset <= WS_offset + 18'd1;
				WS_write_en_4 <= 1'b0;
				WS_write_en_5 <= 1'b0;
				WS_address_4 <= 9'd0;
				WS_address_5 <= 9'd1;
				WS_state <= WSLI1;
			end
			
			WSLI1: begin
				WS_counter <= WS_counter + 4'd1;
				WS_address_4 <= WS_address_4 + 4'd2;
				WS_address_5 <= WS_address_5 + 4'd2;
				WS_state <= WSLI2;
			end
			
			WSLI2: begin
				sum1 <= read_data_c[0];
				sum2 <= read_data_c[1];
				WS_address_4 <= WS_address_4 + 4'd2;
				WS_address_5 <= WS_address_5 + 4'd2;				
				WS_state <= WSCC0;
			end
			
			WSCC0: begin
				WS_SRAM_we_n <= 1'b0;
				WS_SRAM_address <= WS_col_address + WS_row_address;
				ws_col_index <= ws_col_index + 2'd1;
				SRAM_write_data <= {s_sum1, s_sum2};
				WS_counter <= WS_counter + 4'd1;
				WS_address_4 <= WS_address_4 + 4'd2;
				WS_address_5 <= WS_address_5 + 4'd2;
				sum1 <= read_data_c[0];
				sum2 <= read_data_c[1];
				WS_state <= WSCC1;
			end
			
			WSCC1: begin
				WS_SRAM_address <= WS_col_address + WS_row_address;
				ws_col_index <= ws_col_index + 2'd1;
				WS_offset <= WS_offset + 18'd1;
				SRAM_write_data <= {s_sum1, s_sum2};
				WS_counter <= WS_counter + 4'd1;
				WS_address_4 <= WS_address_4 + 4'd2;
				WS_address_5 <= WS_address_5 + 4'd2;
				sum1 <= read_data_c[0];
				sum2 <= read_data_c[1];
				WS_state <= WSCC2;
			end
			
			WSCC2: begin
				WS_SRAM_address <= WS_col_address + WS_row_address;
				ws_col_index <= ws_col_index + 2'd1;
				WS_offset <= WS_offset + 18'd1;
				SRAM_write_data <= {s_sum1, s_sum2};
				WS_counter <= WS_counter + 4'd1;
				WS_address_4 <= WS_address_4 + 4'd2;
				WS_address_5 <= WS_address_5 + 4'd2;
				sum1 <= read_data_c[0];
				sum2 <= read_data_c[1];
				WS_state <= WSCC3;
			end
			
			WSCC3: begin
				if (ws_col_index == 2'd3) begin
					WS_SRAM_address <= WS_col_address + WS_row_address;
					if (ws_row_index == 6'd7) begin
						ws_row_index <= 6'd0;
					end else begin
						ws_row_index <= ws_row_index + 6'd1;
					end
					ws_col_index <= 2'd0;
				end
				WS_offset <= WS_offset + 18'd1;
				SRAM_write_data <= {s_sum1, s_sum2};
				WS_counter <= WS_counter + 4'd1;
				WS_address_4 <= WS_address_4 + 4'd2;
				WS_address_5 <= WS_address_5 + 4'd2;
				sum1 <= read_data_c[0];
				sum2 <= read_data_c[1];
				if (WS_counter == 17'd32) begin
					WS_state <= WSLO;
					CSWS_stopper <= CSWS_stopper + 7'd1;
					WS_stopper <= WS_stopper + 7'd1;
				end else begin
					WS_state <= WSCC0;
				end
			end
			
			WSLO: begin
				if (ws_col_block <= 6'd38) begin
					ws_col_block <= ws_col_block + 6'd1; 
				end else begin
					ws_col_block <= 6'd0;
					ws_row_block <= ws_row_block + 6'd1;	
				end
				WS_SRAM_we_n <= 1'b1;
				WS_counter <= 4'd0;
				WS_state <= WS_IDLE;
			end

		endcase
	end
end

always_ff @ (posedge CLOCK_50_I or negedge Resetn) begin
	if (~Resetn) begin
		state <= M2_IDLE;
		tracker <= 17'd0;

	end else begin
		case (state)
			M2_IDLE: begin
				if (start) begin
					// Start filling the SRAM
					state <= FS;			
				end
			end
			
			FS: begin
				FS_start <= 1'b1;
				if (FS_stop[0]) begin
					state <= CT;
					FS_start <= 1'b0;
					
				end
			end
			
			CT: begin
				CT_start <= 1'b1;
				if (CT_stop[0]) begin
					state <= MS1;
					CT_start <= 1'b0;
					//$stop(1);
				end
			end
			
			MS1: begin
				CS_start <= 1'b1;
				FS_start <= 1'b1;
				if (FS_stop[0]) begin
					FS_start <= 1'b0;
				end
				if (CS_stop[0]) begin
					CS_start <= 1'b0;
				end
				if (CS_stop[0] && FS_stop[0]) begin
					state <= MS2;
					//$stop(1);
				end
			end
			
			MS2: begin
				WS_start <= 1'b1;
				CT_start <= 1'b1;
				if (WS_stop[0]) begin
					WS_start <= 1'b0;
				end
				if (CT_stop[0]) begin
					CT_start <= 1'b0;
				end
				if (WS_stop[0] && CT_stop[0]) begin
					state <= MS1;
					tracker <= tracker + 18'd1;
					// $stop(1);
				end
				// Placeholder tracker conditional to send to lead out once all pixels (but last) are written in SRAM
				if (tracker == 18'd1000) begin
					state <= CS;
					WS_start <= 1'b0;
					CT_start <= 1'b0;
				end
			end
			
			CS: begin
				CS_start <= 1'b1;
				if (CS_stop[0]) begin
					state <= WS;
					CS_start <= 1'b0;
				end
			end
			
			WS: begin
				WS_start <= 1'b1;
				if (WS_stop[0]) begin
					state <= M2_IDLE;
					stop <= 1'b1;
				end
			end
			default: state <= M2_IDLE;
		endcase
	end
end

always_comb begin
    case (state)
        FS, MS1: SRAM_address = FS_SRAM_address;
        WS, MS2: SRAM_address = WS_SRAM_address;
        default: SRAM_address = 18'd0;
    endcase
end

always_comb begin
    case (state)
        FS, MS1: SRAM_we_n = FS_SRAM_we_n;
        WS, MS2: SRAM_we_n = WS_SRAM_we_n;
        default: SRAM_we_n = 1'b1;
    endcase
end

always_comb begin
    case (state)
        FS, MS1: address_0 = FS_address_0;
        CT, MS2: address_0 = CT_address_0; 
        default: address_0 = 9'd0;
    endcase
end

always_comb begin
    case (state)
        CS, MS1: address_2 = CS_address_2; 
        CT, MS2: address_2 = CT_address_2; 
        default: address_2 = 9'd0;
    endcase
end

always_comb begin
    case (state)
        WS, MS2: address_4 = WS_address_4;  
		  CS, MS1: address_4 = CS_address_4;
        default: address_4 = 9'd0;  
    endcase
end

always_comb begin
    case (state)
        WS, MS2: address_5 = WS_address_5; 
		  CS, MS1: address_5 = CS_address_5;
        default: address_5 = 9'd0;  
    endcase
end

always_comb begin
    case (state)
        CT, MS2: c_0 = CT_c_0;  
		  CS, MS1: c_0 = CS_c_0;
        default: c_0 = 6'd0; 
    endcase
end

always_comb begin
    case (state)
        CT, MS2: c_1 = CT_c_1; 
		  CS, MS1: c_1 = CS_c_1;
        default: c_1 = 6'd0; 
    endcase
end

always_comb begin
    case (state)
        CT, MS2: c_2 = CT_c_2;  
		  CS, MS1: c_2 = CS_c_2;
        default: c_2 = 6'd0;  
    endcase
end

always_comb begin
    case (state)
        CT, MS2: mult1 = CT_mult1; 
		  CS, MS1: mult1 = CS_mult1;
        default: mult1 = 32'd0;  
    endcase
end

always_comb begin
    case (state)
        CT, MS2: mult2 = CT_mult2;  
		  CS, MS1: mult2 = CS_mult2;
        default: mult2 = 32'd0;  
    endcase
end

always_comb begin
    case (state)
        CT, MS2: mult3 = CT_mult3;  
		  CS, MS1: mult3 = CS_mult3;
        default: mult3 = 32'd0; 
    endcase
end

always_comb begin
    case (state)
        FS, MS1: write_en_0 = FS_write_en_0; 
		  CT, MS2: write_en_0 = CT_write_en_0;
        default: write_en_0 = 1'b0; 
    endcase
end

always_comb begin
    case (state)
		  CT, MS2: write_en_2 = CT_write_en_2;
        CS, MS1: write_en_2 = CS_write_en_2;  
        default: write_en_2 = 1'b0;  
    endcase
end

always_comb begin
    case (state)
		  CS, MS1: write_en_4 = CS_write_en_4;  
        WS, MS2: write_en_4 = WS_write_en_4;  
        default: write_en_4 = 1'b0; 
    endcase
end

always_comb begin
    case (state)
		  CS, MS1: write_en_5 = CS_write_en_5;
        WS, MS2: write_en_5 = WS_write_en_5;  
        default: write_en_5 = 1'b0;  
    endcase
end


endmodule