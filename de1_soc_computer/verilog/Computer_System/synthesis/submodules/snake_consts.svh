`define VGA_PX_BASE 32'hC8000000
`define RAM_BASE    32'h00000000
`define RAM_SPAN    32'h3FFFFFFF

// Character display uses Code Page 437 format:
// https://en.wikipedia.org/wiki/Code_page_437
`define NUMERIC_ASCII_OFFSET 8'h30
`define ALPHA_ASCII_OFFSET   8'h37
`define CHAR_E 8'h45
`define CHAR_N 8'h4E
`define CHAR_T 8'h54
`define CHAR_R 8'h52
`define CHAR_t 8'h74
`define CHAR_o 8'h6F
`define CHAR_s 8'h73
`define CHAR_a 8'h61
`define CHAR_r 8'h72
`define CHAR_  8'h00

`define RESET_GAME 32'h80000000

`define CMD_START_GAME 0
`define CMD_END_GAME 1
`define CMD_SNAKE_ADD 2
`define CMD_SNAKE_DEL 3
`define CMD_NEW_SCORE 4
`define CMD_APPLE_ADD 5
`define CMD_APPLE_DEL 6
`define CMD_GOLDEN_APPLE_ADD 7
`define CMD_GOLDEN_APPLE_DEL 8
`define CMD_SPEED_UP_ADD 9
`define CMD_SPEED_UP_DEL 10

`define MSG_X_OFFSET 1
`define MSG_Y_OFFSET 10
`define MSG_CMD_OFFSET 24

`define NUM_X_PIXELS 320
`define NUM_Y_PIXELS 240

`define SNAKE_COLOUR        16'b1111111111111111
`define APPLE_COLOUR        16'b1111100000000000
`define GAPPLE_COLOUR       16'b1111110111100111
`define SPEED_UP_COLOUR     16'b0000000000011111
`define BLACK               16'b0000000000000000
`define GRAY                16'b0011100011100111
