`timescale 1 ps / 1 ps
`include "../doom_consts.svh"

module tb_update ();
logic        clk=0;
logic        reset=0;
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
logic [6:0]  debug_seg_export;
logic [31:0] hps_params [7:0];
logic [7:0]  local_palette [255:0][2:0];
logic        start;
logic        processing;

update_handler DUT( .* );
logic [31:0] test_num = 0;
logic [31:0] errs = 0;

// enum {
`define WAITING 0
`define ADVANCE_LOOP 1
`define WAIT_MEM 2
`define WAIT_VGA 3
`define DONE 4
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
    #5;
    local_palette[0][0] = 4'hA << 3;
    local_palette[0][1] = 4'hA << 2;
    local_palette[0][2] = 4'hA << 3;

    local_palette[1][0] = 4'hB << 3;
    local_palette[1][1] = 4'hB << 2;
    local_palette[1][2] = 4'hB << 3;

    local_palette[2][0] = 4'hC << 3;
    local_palette[2][1] = 4'hC << 2;
    local_palette[2][2] = 4'hC << 3;

    local_palette[3][0] = 4'hD << 3;
    local_palette[3][1] = 4'hD << 2;
    local_palette[3][2] = 4'hD << 3;

    local_palette[4][0] = 4'hE << 3;
    local_palette[4][1] = 4'hE << 2;
    local_palette[4][2] = 4'hE << 3;

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