// snake_fpga.v

`include "snake_fpga.svh"
`timescale 1 ps / 1 ps

module tb_snake();
  logic        clk=0;
  logic        reset_n;
  logic [31:0] vga_ch_address;
  logic        vga_ch_read;
  logic        vga_ch_waitrequest;
  logic [15:0] vga_ch_readdata;
  logic        vga_ch_write;
  logic [15:0] vga_ch_writedata;

  logic [31:0] vga_px_address;
  logic        vga_px_read;
  logic        vga_px_waitrequest;
  logic [15:0] vga_px_readdata;
  logic        vga_px_write;
  logic [15:0] vga_px_writedata;

  logic [3:0]  hps_address;
  logic        hps_read;
  logic [31:0] hps_readdata;
  logic        hps_write;
  logic [31:0] hps_writedata;
  logic        hps_waitrequest;

  snake_fpga DUT (.*);

  always #5 clk = ~clk;  // Create clock with period=10

  logic [8:0] x;
  logic [7:0] y;
  
  initial begin
    x = 1; y = 1;
    hps_writedata = (`CMD_SNAKE_ADD << `MSG_CMD_OFFSET) | (x << `MSG_X_OFFSET) | (y << `MSG_Y_OFFSET);
    hps_address = 0;
    hps_write = 1;

    #10;
    #10;
    hps_write = 0;
    #10;
    #10;

    x = 10; y = 10;
    hps_writedata = (`CMD_SNAKE_DEL << `MSG_CMD_OFFSET) | (x << `MSG_X_OFFSET) | (y << `MSG_Y_OFFSET);
    hps_address = 0;
    hps_write = 1;

    #10;
    #10;
    #10;
    #10;

    $stop;
    

  end
endmodule
