`timescale 1 ps / 1 ps
`include "../doom_consts.svh"

module tb_update ();
logic        clk=0;
logic        reset=0;
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
logic [6:0]  debug_seg_export;
logic [31:0] hps_params [7:0];
logic        start;
logic        processing;

patch_handler DUT( .* );
logic [31:0] test_num = 0;
logic [31:0] errs = 0;

// enum {
`define WAITING 0
`define DONE 1
`define PROCESSING_INIT0 2
`define PROCESSING_INIT1 3
`define PROCESS_INIT2 4
`define GET_POST 5
`define DRAW_POST 6
`define READ_COL 7
`define DRAW_COL 8
`define LOOP_ITER 9
`define WAIT_MEM_WRITE 10
`define WAIT_MEM_READ 11
`define WAIT_W_MEM_WRITE 12
`define WAIT_W_MEM_READ 13
// } state

always #5 clk = ~clk;  // Create clock with period=10

initial begin
    #5;
    forever begin
        mem_waitrequest = 0;
        w_mem_waitrequest = 0;
        #90;
        mem_waitrequest = 1;
        w_mem_waitrequest = 1;
        #10;
    end
end

initial begin
    #5;

    mem_readdata = 0;
    forever begin
        mem_readdata = (mem_readdata + 1) % 5;
        #10;
    end
end
initial begin
    $display("Testing: update handler"); test_num += 1;
    #10;

    assert (DUT.state == `WAITING)
    else begin
        $display("DUT.state was actually %d", DUT.state);
        errs += 1;
    end
    hps_params[1] = 32'hC0000000;
    start = 1;
    #10;

    assert (DUT.state == `WAIT_MEM)
    else begin
        $display("DUT.state was actually %d", DUT.state);
        errs += 1;
    end
    #10;

    wait(processing == 0);
    #5;

    $stop;
end

endmodule