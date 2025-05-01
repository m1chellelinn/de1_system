// snake_fpga.v

`include "snake_fpga.svh"
`timescale 1 ps / 1 ps

module tb_snake();
logic        clk;
logic        reset_n;
logic [31:0]  vga_ch_address;
logic        vga_ch_read;
logic        vga_ch_waitrequest;
logic [15:0] vga_ch_readdata;
logic        vga_ch_write;
logic [15:0] vga_ch_writedata;
logic [31:0]  vga_px_address;
logic        vga_px_read;
logic        vga_px_waitrequest;
logic [15:0] vga_px_readdata;
logic        vga_px_write;
logic [15:0] vga_px_writedata;
logic [31:0]  hps_address;
logic        hps_read;
logic [31:0] hps_readdata;
logic        hps_write;
logic [31:0] hps_writedata;
logic        hps_waitrequest;

snake_fpga DUT (.*);


endmodule
