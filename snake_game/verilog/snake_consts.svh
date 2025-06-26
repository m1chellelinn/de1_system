`define VGA_PX_BASE 32'hC8000000
`define VGA_CH_BASE 32'h09000000

// Character display uses Code Page 437 format:
// https://en.wikipedia.org/wiki/Code_page_437
`define NUMERIC_ASCII_OFFSET 8'h30
`define ALPHA_ASCII_OFFSET   8'h37

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

`define MSG_X_OFFSET 1
`define MSG_Y_OFFSET 10
`define MSG_CMD_OFFSET 24

`define NUM_X_PIXELS 320
`define NUM_Y_PIXELS 240

`define SNAKE_COLOUR        16'b1111111111111111
`define APPLE_COLOUR        16'b1111100000000000
`define GAPPLE_COLOUR       16'b1111110111100111
`define BLACK               16'b0000000000000000
`define GRAY                16'b0001100001100011
