# activate waveform simulation

view wave

# format signal names in waveform

configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform

add wave -divider -height 20 {Top-level signals}
add wave -bin UUT/CLOCK_50_I
add wave -bin UUT/resetn
add wave UUT/top_state
add wave -uns UUT/UART_timer

add wave -divider -height 10 {SRAM signals}
add wave -uns UUT/SRAM_address
add wave -hex UUT/SRAM_write_data
add wave -bin UUT/SRAM_we_n
add wave -hex UUT/SRAM_read_data
#add wave -hex UUT/M1/state
add wave -hex UUT/M2/state
add wave -hex UUT/M2/FS_state
add wave -hex UUT/M2/CT_state
add wave -hex UUT/M2/CS_state
add wave -hex UUT/M2/WS_state
add wave -hex UUT/M2/Resetn
#add wave -dec UUT/M2/FS_stop
#add wave -bin UUT/M2/WS_stop
#add wave -bin UUT/M2/CT_stop
#add wave -dec UUT/M2/CT_stopper
#add wave -dec UUT/M2/CTCS_stopper
#add wave -dec UUT/M2/CS_stopper
#add wave -dec UUT/M2/CSWS_stopper
#add wave -bin UUT/M2/CS_stop
#add wave -dec UUT/M2/FS_stopper
#add wave -dec UUT/M2/FSCT_stopper
#add wave -bin UUT/M2/FS_start
#add wave -bin UUT/M2/FSFS_stop
#add wave -bin UUT/M2/FSCS_stop
#add wave -bin UUT/M2/FSCT_stop
#add wave -bin UUT/M2/CS_stop
#add wave -bin UUT/M2/CS_start

add wave -divider -height 10 {DPRAM}
add wave -dec UUT/M2/address_0
add wave -dec UUT/M2/address_1
add wave -dec UUT/M2/address_2
#add wave -dec UUT/M2/address_3
add wave -dec UUT/M2/address_4
add wave -dec UUT/M2/address_5
add wave -bin UUT/M2/write_en_0
add wave -bin UUT/M2/write_en_1
add wave -bin UUT/M2/write_en_2
add wave -dec UUT/M2/coef_offset
add wave -bin UUT/M2/write_en_4
add wave -bin UUT/M2/write_en_5

#add wave -divider -height 10 {FS}
add wave -dec UUT/M2/col_block
#add wave -dec UUT/M2/col_index
add wave -dec UUT/M2/row_block
#add wave -dec UUT/M2/YUV_fetch
#add wave -dec UUT/M2/row_index
#add wave -dec UUT/M2/row_address
#add wave -dec UUT/M2/col_address
#add wave -dec UUT/M2/FS_address_0
#add wave -hex UUT/M2/y_buf
#add wave -hex UUT/M2/write_data_a

add wave -divider -height 10 {CT}
#add wave -dec UUT/M2/CT_counter
#add wave -dec UUT/M2/CT_address_0
#add wave -dec UUT/M2/counter
#add wave -dec UUT/M2/address_0_offset
#add wave -hex UUT/M2/T_sum
#add wave -hex UUT/M2/Mult_result1
#add wave -hex UUT/M2/Mult_result2
#add wave -hex UUT/M2/Mult_result3
#add wave -hex UUT/M2/CT_mult1
#add wave -hex UUT/M2/CT_mult2
#add wave -hex UUT/M2/CT_mult3
#add wave -dec UUT/M2/CT_c_0
#add wave -dec UUT/M2/CT_c_1
#add wave -dec UUT/M2/CT_c_2
#add wave -dec UUT/M2/C0
#add wave -dec UUT/M2/C1
#add wave -dec UUT/M2/C2
#add wave -hex UUT/M2/C0
#add wave -hex UUT/M2/C1
#add wave -hex UUT/M2/C2
#add wave -hex UUT/M2/write_data_b
#add wave -hex {UUT/M2/write_data_a[0]}
#add wave -hex {UUT/M2/write_data_a[1]}
#add wave -hex {UUT/M2/read_data_a[0]}
#add wave -hex {UUT/M2/read_data_a[1]}

add wave -divider -height 10 {CS}
#add wave -dec UUT/M2/CS_counter
#add wave -dec UUT/M2/column
#add wave -hex UUT/M2/s_sum1
#add wave -hex UUT/M2/s_sum2
#add wave -hex UUT/M2/s_sum3
#add wave -hex UUT/M2/S_sum1
#add wave -hex UUT/M2/S_sum2
#add wave -hex UUT/M2/S_sum3
#add wave -hex UUT/M2/write_register
#add wave -dec UUT/M2/CS_c_0
#add wave -dec UUT/M2/CS_c_1
#add wave -dec UUT/M2/CS_c_2
#add wave -hex UUT/M2/CS_mult1
#add wave -hex UUT/M2/CS_mult2
#add wave -hex UUT/M2/CS_mult3
#add wave -hex UUT/M2/Mult_result1
#add wave -hex UUT/M2/Mult_result2
#add wave -hex UUT/M2/Mult_result3
add wave -hex {UUT/M2/write_data_c[0]}
add wave -hex {UUT/M2/write_data_c[1]}
#add wave -hex {UUT/M2/read_data_b[0]}
add wave -hex UUT/M2/s_sum1
add wave -hex UUT/M2/s_sum2

add wave -divider -height 10 {WS}
add wave -dec UUT/M2/tracker
add wave -dec UUT/M2/counter
add wave -dec UUT/M2/WS_counter
add wave -dec UUT/M2/WS_offset
add wave -dec UUT/M2/ws_col_index
add wave -dec UUT/M2/ws_col_block
add wave -dec UUT/M2/ws_row_index
add wave -dec UUT/M2/ws_row_block
add wave -dec UUT/M2/WS_row_address
add wave -dec UUT/M2/WS_col_address
add wave -hex {UUT/M2/read_data_c[0]}
add wave -hex {UUT/M2/read_data_c[1]}


#add wave -divider -height 10 {VGA signals}
#add wave -bin UUT/VGA_unit/VGA_HSYNC_O
#add wave -bin UUT/VGA_unit/VGA_VSYNC_O
#add wave -uns UUT/VGA_unit/pixel_X_pos
#add wave -uns UUT/VGA_unit/pixel_Y_pos
#add wave -hex UUT/VGA_unit/VGA_red
#add wave -hex UUT/VGA_unit/VGA_green
#add wave -hex UUT/VGA_unit/VGA_blue






