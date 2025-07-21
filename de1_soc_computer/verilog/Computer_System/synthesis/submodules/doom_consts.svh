`define VGA_PX_BASE 32'h08000000
`define VGA_CH_BASE 32'h09000000

// Character display uses Code Page 437 format:
// https://en.wikipedia.org/wiki/Code_page_437
`define NUMERIC_ASCII_OFFSET 8'h30
`define ALPHA_ASCII_OFFSET   8'h37

`define RESET 32'h80000000

`define CMD_AM_clearFB 0 // int color, int f_w, int f_h
`define CMD_AM_drawCrosshair 1 //
`define CMD_AM_drawFline 2 //
`define CMD_I_FinishUpdate 3 //
`define CMD_I_SetPalette 4 // byte* palette
`define CMD_R_FillBackScreen 5 //
`define CMD_V_CopyRect 6 //
`define CMD_V_DrawBlock 7 //
`define CMD_V_DrawPatch 8 // int x, int y, int scrn, addr patch
`define CMD_V_Init 9 //
`define CMD_Wi_slamBackground 10 //

`define MSG_X_OFFSET 1
`define MSG_Y_OFFSET 10
`define MSG_CMD_OFFSET 24

`define NUM_X_PIXELS 320
`define NUM_Y_PIXELS 200

`define SNAKE_COLOUR        16'b1111111111111111
`define APPLE_COLOUR        16'b1111100000000000
`define GAPPLE_COLOUR       16'b1111110111100111
`define SPEED_UP_COLOUR     16'b0000000000011111
`define BLACK               16'b0000000000000000
`define GRAY                16'b0011100011100111
