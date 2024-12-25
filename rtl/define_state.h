`ifndef DEFINE_STATE

// for top state - we have more states than needed
typedef enum logic [1:0] {
	S_IDLE,
	S_UART_RX,
	S_M2,
	S_M1
} top_state_type;

typedef enum logic [1:0] {
	S_RXC_IDLE,
	S_RXC_SYNC,
	S_RXC_ASSEMBLE_DATA,
	S_RXC_STOP_BIT
} RX_Controller_state_type;

typedef enum logic [2:0] {
	S_US_IDLE,
	S_US_STRIP_FILE_HEADER_1,
	S_US_STRIP_FILE_HEADER_2,
	S_US_START_FIRST_BYTE_RECEIVE,
	S_US_WRITE_FIRST_BYTE,
	S_US_START_SECOND_BYTE_RECEIVE,
	S_US_WRITE_SECOND_BYTE
} UART_SRAM_state_type;

typedef enum logic [3:0] {
	S_VS_WAIT_NEW_PIXEL_ROW,
	S_VS_NEW_PIXEL_ROW_DELAY_1,
	S_VS_NEW_PIXEL_ROW_DELAY_2,
	S_VS_NEW_PIXEL_ROW_DELAY_3,
	S_VS_NEW_PIXEL_ROW_DELAY_4,
	S_VS_NEW_PIXEL_ROW_DELAY_5,
	S_VS_FETCH_PIXEL_DATA_0,
	S_VS_FETCH_PIXEL_DATA_1,
	S_VS_FETCH_PIXEL_DATA_2,
	S_VS_FETCH_PIXEL_DATA_3
} VGA_SRAM_state_type;

typedef enum logic [7:0] {
    M1_IDLE,
    LI0,
    LI1,
    LI2,
    LI3,
    LI4,
    LI5,
    LI6,
    LI7,
    LI8,
    LI9,
    LI10,
    LI11,
    LI12,
    LI13,
    LI14,
    LI15,
	 LI16,
	 LI17,
	 LI18,
	 LI19,
	 LI20,
    CC1,
    CC2,
    CC3,
    CC4,
    CC5,
    CC6,
    CC7,
    LO1,
    LO2,
    LO3,
    LO4,
    LO5,
    LO6,
    LO7
} M1_state_type;

typedef enum logic [7:0] {
	M2_IDLE,
	FS,
	CS,
	CT,
	MS1,
	MS2,
	WS
} M2_state_type;

typedef enum logic [7:0] {
	FS_IDLE,
	FSLI0,
	FSLI1,
	FSLI2,
	FSCC1,
	FSCC2,
	FSCC3,
	FSCC4,
	FSCC5,
	FSCC6,
	FSCC7,
	FSCC8,
	FSCC9,
	FSLO
} FSM2_state_type;

typedef enum logic [7:0] {
	CT_IDLE,
	CTLI0,
	CTLI1,
	CTLI2,
	CTCC0,
	CTCC1,
	CTCC2,
	CTLO
} CTM2_state_type;

typedef enum logic [7:0] {
	CS_IDLE,
	CSLI0,
	CSLI1,
	CSCC0,
	CSCC1,
	CSCC2,
	CSCC3,
	CSCC4,
	CSCC5,
	CSCC6,
	CSCC7,
	CSCC8,
	CSLO
} CSM2_state_type;

typedef enum logic [7:0] {
	WS_IDLE,
	WSLI0,
	WSLI1,
	WSLI2,
	WSCC0,
	WSCC1,
	WSCC2,
	WSCC3,
	WSLO
} WSM2_state_type;

parameter 
	Y_BASE_ADDRESS = 18'd0,
	U_BASE_ADDRESS = 18'd38400,
	V_BASE_ADDRESS = 18'd57600,
	RGB_BASE_ADDRESS = 18'd146944;
	
parameter 
	RY_BASE_ADDRESS = 18'd76800,
	RU_BASE_ADDRESS = 18'd153600,
	RV_BASE_ADDRESS = 18'd192000;

parameter
	coef1 = 8'sd21,
	coef2 = 8'sd52,
	coef3 = 32'sd159;

parameter
	a = 32'sd76284,
	c = 32'sd104595,
	e = -32'sd25624,
	f = -32'sd53281,
	h = 32'sd132251;

parameter 
   VIEW_AREA_LEFT = 160,
   VIEW_AREA_RIGHT = 480,
   VIEW_AREA_TOP = 120,
   VIEW_AREA_BOTTOM = 360;

`define DEFINE_STATE 1
`endif
