`timescale 1 ps / 1 ps
`include "../doom_consts.svh"

module tb_patch ();
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

logic [31:0] data_start_addr = 32'hBEEF0000;
logic [31:0] screen_start_addr = 32'hABCD0000;
logic [8:0] x, y;

logic [7:0] data_array [0:119] = '{
    8'd2, 8'h0, // patch: width
    8'd255, 8'd255, // height
    8'd10, 8'h0, // leftoffset
    8'd10, 8'h0, // topoffset
    8'd88, 8'h0, 8'h0, 8'h0, // columnoffs[0]
    8'd97, 8'h0, 8'h0, 8'h0, // columnoffs[1] 

    8'h0, 8'h0, 8'h0, 8'h0,
    8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, //20-29
    8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, // 30-39
    8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, // 40-49
    8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0,
    8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0,
    8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0,
    8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 

    8'd8, // offset 88: column 1: topdelta
    8'd4, // length
    8'h0, // pad
    8'h47, 8'h48, 8'h49, 8'h8d, // data
    8'h0, // pad
    8'hFF, // end column

    8'd6, // offset 97: column 2: topdelta
    8'd11, // length
    8'h0, //pad
    8'h46, 8'h49, 8'h48, 8'h45, 8'h47, 8'h4c, 8'h4d, 8'h97, 8'h8f, 8'h8f, 8'h8d, // data
    8'h0, // pad
    8'hFF, // end column

    8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0
};

logic [7:0] screens[`SCREENHEIGHT:0][`SCREENWIDTH:0];

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

always_comb begin
    mem_readdata = data_array[mem_address - data_start_addr];
    w_mem_readdata = {
        data_array[w_mem_address - data_start_addr + 3],
        data_array[w_mem_address - data_start_addr + 2],
        data_array[w_mem_address - data_start_addr + 1],
        data_array[w_mem_address - data_start_addr + 0]
    };

    if (mem_write) begin
        x = (mem_address-screen_start_addr) / `SCREENWIDTH;
        y = (mem_address-screen_start_addr) % `SCREENWIDTH;
        screens[x][y] = mem_writedata;
    end
end

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
    $display("Testing: patch handler"); test_num += 1;
    #10;

    assert (DUT.state == `WAITING)
    else begin
        $display("DUT.state was actually %d", DUT.state);
        errs += 1;
    end
    hps_params[1] = 50;
    hps_params[2] = 30;
    hps_params[3] = 0;
    hps_params[4] = screen_start_addr;
    hps_params[5] = data_start_addr;
    start = 1;
    #10;

    assert (DUT.state == `WAIT_W_MEM_READ)
    else begin
        $display("DUT.state was actually %d", DUT.state);
        errs += 1;
    end
    #10;

    #1000;

    // for (int y = 0; y <= `SCREENHEIGHT; y++) begin
    //     for (int x = 0; x <= `SCREENWIDTH; x++) begin
    //         $write("%02h", screens[y][x]);
    //         if (x != `SCREENWIDTH) $write(",");
    //     end
    //     $write("\n");
    // end


    $stop;
end

endmodule