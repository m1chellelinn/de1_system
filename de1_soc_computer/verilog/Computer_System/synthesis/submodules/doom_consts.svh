`define VGA_PX_BASE 32'h08000000
`define VGA_CH_BASE 32'h09000000

`define VGA_MSG_X_OFFSET 1
`define VGA_MSG_Y_OFFSET 10

`define CMD_RESET 32'h80000000
`define CMD_AM_clearFB 0 // int color, int f_w, int f_h
`define CMD_AM_drawCrosshair 1 //
`define CMD_AM_drawFline 2 //
`define CMD_I_FinishUpdate 3 // byte *screens
`define CMD_I_SetPalette 4 // byte* palette
`define CMD_R_FillBackScreen 5 //
`define CMD_V_CopyRect 6 //
`define CMD_V_DrawBlock 7 //
`define CMD_V_DrawPatch 8 // int x, int y, int scrn, addr patch
`define CMD_V_Init 9 //
`define CMD_Wi_slamBackground 10 //

`define SCREENWIDTH  320
`define SCREENHEIGHT 200
`define SCREENSIZE   16'd64000
