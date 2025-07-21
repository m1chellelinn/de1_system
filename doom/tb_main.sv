`timescale 1 ps / 1 ps
`include "doom_consts.svh"

module tb_doom_fpga ();
logic        clk=0;
logic        reset_n=1;
logic        dbg_rst_n;
logic [31:0] vga_address;
logic        vga_read;
logic        vga_waitrequest;
logic [15:0] vga_readdata;
logic        vga_write;
logic [15:0] vga_writedata;
logic [31:0] mem_address;
logic        mem_read;
logic        mem_waitrequest;
logic [7:0]  mem_readdata;
logic        mem_write;
logic [7:0]  mem_writedata;
logic [7:0]  hps_address;
logic        hps_read;
logic        hps_waitrequest;
logic [31:0] hps_readdata;
logic        hps_write;
logic [31:0] hps_writedata;
logic [41:0] debug_seg_export;
logic [9:0]  debug_light_export;

doom_fpga DUT( .* );
logic [31:0] test_num = 0;

// enum {
`define WAITING 0
`define PATCH 1
`define PALETTE 2
// } state

always #5 clk = ~clk;  // Create clock with period=10

initial begin
    $display("Testing: shared memory access"); test_num += 1;
    hps_write = 1;
    hps_address = 1;
    hps_writedata = 32'h3000_0000;
    #10; 

    hps_write = 0;
    #10;
    
    assert (DUT.state == `WAITING)
    else   $display("DUT.state was actually %d", DUT.state);
    hps_write = 1;
    hps_address = 0;
    hps_writedata = `CMD_V_Init;
    #10;

    assert (DUT.state == `PATCH)
    else   $display("DUT.state was actually %d", DUT.state);
    hps_write = 0;
    #10;

    #10;
    
    mem_waitrequest = 1;
    #10;
    
    mem_waitrequest = 0;
    #10;

    wait(hps_waitrequest == 0);
    #5;

    $stop;
end

endmodule