`timescale 1 ps / 1 ps
`include "../doom_consts.svh"

module tb_doom_fpga ();
logic        clk=0;
logic        reset_n=1;
logic        dbg_rst_n=1;
logic [31:0] vga_address;
logic        vga_read;
logic        vga_waitrequest=0;
logic [15:0] vga_readdata=0;
logic        vga_write;
logic [15:0] vga_writedata;
logic [31:0] mem_address;
logic        mem_read;
logic        mem_waitrequest=0;
logic [7:0]  mem_readdata=0;
logic        mem_write;
logic [7:0]  mem_writedata;
logic [31:0] w_mem_address;
logic        w_mem_read;
logic        w_mem_waitrequest=0;
logic [31:0] w_mem_readdata=0;
logic        w_mem_write;
logic [31:0] w_mem_writedata;
logic [7:0]  hps_address=0;
logic        hps_read=0;
logic        hps_waitrequest;
logic [31:0] hps_readdata;
logic        hps_write=0;
logic [31:0] hps_writedata=0;
logic [41:0] debug_seg_export;
logic [9:0]  debug_light_export;


doom_fpga DUT( .* );

logic [31:0] test_num = 0;
logic [31:0] errs = 0;

// enum {
`define WAITING 0
`define PATCH 1
`define PALETTE 2
`define UPDATE 3
`define SELFCHECK 4
`define RESET 5
// } state

always #5 clk = ~clk;  // Create clock with period=10

initial begin
    #5;
    forever begin
        mem_waitrequest = 0;
        vga_waitrequest = 0;
        #90;
        mem_waitrequest = 1;
        vga_waitrequest = 1;
        #10;
    end
end

initial begin
    $display("Test 1: self check"); test_num += 1;
    hps_write = 1;
    hps_address = 1;
    hps_writedata = 32'h3000_0000;
    #10; 

    hps_write = 0;
    #10;
    
    assert (DUT.state == `WAITING)
    else begin
        $display("DUT.state was actually %d", DUT.state);
        errs += 1;
    end
    hps_write = 1;
    hps_address = 0;
    hps_writedata = `CMD_V_Init;
    #10;

    assert (DUT.state == `SELFCHECK)
    else begin
        $display("DUT.state was actually %d", DUT.state);
        errs += 1;
    end
    hps_write = 0;
    #10;

    #10;

    wait(hps_waitrequest == 0);
    #5;

    $display("Test 2: update"); test_num += 1;
    #10;

    assert (DUT.state == `WAITING)
    else begin
        $display("DUT.state was actually %d", DUT.state);
        errs += 1;
    end
    hps_write = 1;
    hps_address = 0;
    hps_writedata = `CMD_I_FinishUpdate;
    #10;

    assert (DUT.state == `UPDATE)
    else begin
        $display("DUT.state was actually %d", DUT.state);
        errs += 1;
    end
    hps_write = 0;
    #10; 
    mem_readdata = 10;
    #10; 
    mem_readdata = 20;
    #10; 
    mem_readdata = 30;
    #10; 
    mem_readdata = 40;
    #10; 
    mem_readdata = 50;
    #10; 
    mem_readdata = 60;
    #10; 
    mem_readdata = 70;
    #10; 
    mem_readdata = 80;
    #10; 
    mem_readdata = 90;
    assert (DUT.state == `UPDATE)
    else begin
        $display("DUT.state was actually %d", DUT.state);
        errs += 1;
    end
    hps_write = 1;
    hps_address = 0;
    hps_writedata = `CMD_RESET;
    #10;

    assert (DUT.state == `RESET)
    else begin
        $display("DUT.state was actually %d", DUT.state);
        errs += 1;
    end
    hps_write = 0;
    #10;



    $stop;
end

endmodule