// snake_fpga.v

`include "snake_fpga.svh"
`timescale 1 ps / 1 ps

module tb_snake();
  logic        clk=0;
  logic        reset_n=1;
  logic        dbg_rst_n;
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
  logic [31:0] test_num = 0;
  logic [31:0] score;

// enum { 
`define WAITING 0
`define PLAYING 1
`define REQUESTING_PX 2
`define REQUESTING_CH 3
`define CLEAR_SCREEN_INIT 4
`define CLEAR_SCREEN 5
// } state
  
  initial begin
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    $display("Testing: idling"); test_num += 1;

    x = 1; y = 1; test_num += 1;
    hps_writedata = (`CMD_SNAKE_ADD << `MSG_CMD_OFFSET) | (x << `MSG_X_OFFSET) | (y << `MSG_Y_OFFSET);
    hps_address = 0;
    hps_write = 1;
    assert (DUT.state == `WAITING)
    else   $display("DUT.state was actually %d", DUT.state);
    #10;

    hps_write = 1;
    hps_writedata = (`CMD_END_GAME << `MSG_CMD_OFFSET) | (x << `MSG_X_OFFSET) | (y << `MSG_Y_OFFSET);
    assert (DUT.state == `WAITING)
    else   $display("DUT.state was actually %d", DUT.state);
    #10;

    hps_write = 0;
    reset_n = 0;
    assert (DUT.state == `WAITING)
    else   $display("DUT.state was actually %d", DUT.state);
    #10;

    reset_n = 1;
    #10;


    ///////////////////////////////////////////////////////////////////////////////////////////////////
    $display("Testing: start game"); test_num += 1;

    hps_write = 1;
    hps_writedata = (`CMD_START_GAME << `MSG_CMD_OFFSET) | (x << `MSG_X_OFFSET) | (y << `MSG_Y_OFFSET);
    #10;

    hps_write = 0;
    assert (DUT.state == `CLEAR_SCREEN_INIT)
    else   $display("DUT.state was actually %d", DUT.state);
    #10;

    assert (DUT.state == `CLEAR_SCREEN)
    else   $display("DUT.state was actually %d", DUT.state);
    #10;

    wait (DUT.state == `PLAYING);
    #5;

    $stop;


    ///////////////////////////////////////////////////////////////////////////////////////////////////
    $display("Testing: setting pixels and score"); test_num += 1;

    hps_writedata = (`CMD_SNAKE_ADD << `MSG_CMD_OFFSET) | (x << `MSG_X_OFFSET) | (y << `MSG_Y_OFFSET);
    hps_write = 1;
    vga_px_waitrequest = 0;
    #10;

    hps_write = 0;
    assert (DUT.state == `REQUESTING_PX)
    else   $display("1, DUT.state was actually %d", DUT.state);  
    assert (DUT.hps_waitrequest == 1)
    else   $display("DUT.hps_waitrequest not high");
    #10;

    assert (DUT.state == `PLAYING)
    else   $display("2, DUT.state was actually %d", DUT.state);  
    hps_write = 1;
    hps_writedata = (`CMD_APPLE_DEL << `MSG_CMD_OFFSET) | (x << `MSG_X_OFFSET) | (y << `MSG_Y_OFFSET);
    vga_px_waitrequest = 1;
    #10;

    #10;
    #10;
    #10;
    assert (DUT.state == `REQUESTING_PX)
    else   $display("3, DUT.state was actually %d", DUT.state);  
    vga_px_waitrequest = 0;
    #10;
    
    assert (DUT.state == `PLAYING)
    else   $display("4, DUT.state was actually %d", DUT.state);  
    score = 100;
    hps_write = 1;
    hps_writedata = (`CMD_NEW_SCORE << `MSG_CMD_OFFSET) | (score);
    vga_px_waitrequest = 1;
    #10;

    assert (DUT.state == `PLAYING)
    else   $display("5, DUT.state was actually %d", DUT.state);  
    assert (DUT.score == score)
    else   $display("6, DUT.score was actually %d", DUT.state);  
    hps_write = 0;
    vga_px_waitrequest = 0;
    #10;

    $stop;


    ///////////////////////////////////////////////////////////////////////////////////////////////////
    $display("Testing: end game"); test_num += 1;

    hps_write = 1;
    hps_writedata = (`CMD_END_GAME << `MSG_CMD_OFFSET) | (x << `MSG_X_OFFSET) | (y << `MSG_Y_OFFSET);
    #10;

    hps_write = 0;
    assert (DUT.state == `CLEAR_SCREEN_INIT)
    else   $display("DUT.state was actually %d", DUT.state);
    #10;

    assert (DUT.state == `CLEAR_SCREEN)
    else   $display("DUT.state was actually %d", DUT.state);
    #10;

    wait (DUT.state == `WAITING);
    #5;


    $stop;
    

  end
endmodule
