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
logic [31:0] w_mem_address_aligned;
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

logic [31:0] data_start_addr = 32'h201DEF58;
logic [31:0] screen_start_addr = 32'h1FF00000;
logic [8:0] x, y;

logic [7:0] data_array_1 [0:119] = '{
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

logic [7:0] data_array_2 [0:599] = '{
    8'h14, 8'h00, 8'h13, 8'h00, 8'h00, 8'h00, 8'hFF, 8'hFF, 8'h58, 8'h00, 
    8'h00, 8'h00, 8'h61, 8'h00, 8'h00, 8'h00, 8'h71, 8'h00, 8'h00, 8'h00, 
    8'h85, 8'h00, 8'h00, 8'h00, 8'h9A, 8'h00, 8'h00, 8'h00, 8'hB0, 8'h00, 
    8'h00, 8'h00, 8'hC7, 8'h00, 8'h00, 8'h00, 8'hDF, 8'h00, 8'h00, 8'h00, 
    8'hF7, 8'h00, 8'h00, 8'h00, 8'h0F, 8'h01, 8'h00, 8'h00, 8'h27, 8'h01, 
    8'h00, 8'h00, 8'h3F, 8'h01, 8'h00, 8'h00, 8'h57, 8'h01, 8'h00, 8'h00, 
    8'h6F, 8'h01, 8'h00, 8'h00, 8'h87, 8'h01, 8'h00, 8'h00, 8'h9E, 8'h01, 
    8'h00, 8'h00, 8'hB4, 8'h01, 8'h00, 8'h00, 8'hC9, 8'h01, 8'h00, 8'h00, 
    8'hDD, 8'h01, 8'h00, 8'h00, 8'hEE, 8'h01, 8'h00, 8'h00, 8'h08, 8'h04, 
    8'h47, 8'h47, 8'h48, 8'h49, 8'h8D, 8'h8D, 8'hFF, 8'h06, 8'h0B, 8'h46, 
    8'h46, 8'h49, 8'h48, 8'h45, 8'h47, 8'h4C, 8'h4D, 8'h97, 8'h8F, 8'h8F, 
    8'h8D, 8'h8D, 8'hFF, 8'h03, 8'h0F, 8'h44, 8'h44, 8'h44, 8'h46, 8'h43, 
    8'h42, 8'h42, 8'h44, 8'h45, 8'h4D, 8'h02, 8'h4D, 8'h4A, 8'h49, 8'h49, 
    8'h49, 8'h49, 8'hFF, 8'h02, 8'h10, 8'h43, 8'h43, 8'h42, 8'h43, 8'h42, 
    8'h46, 8'h4C, 8'h4A, 8'h43, 8'h47, 8'h4C, 8'h00, 8'h02, 8'h02, 8'h48, 
    8'h4A, 8'h4B, 8'h4B, 8'hFF, 8'h01, 8'h11, 8'h43, 8'h43, 8'h41, 8'h3F, 
    8'h41, 8'h46, 8'hBD, 8'hBD, 8'hBD, 8'h40, 8'h49, 8'h4C, 8'h02, 8'h02, 
    8'h4C, 8'h4A, 8'h4B, 8'h01, 8'h01, 8'hFF, 8'h01, 8'h12, 8'h3F, 8'h3F, 
    8'h3D, 8'h3D, 8'h41, 8'h4B, 8'hBE, 8'hBD, 8'hBC, 8'h3E, 8'h4B, 8'h4D, 
    8'h4E, 8'h4D, 8'h4B, 8'h4A, 8'h4E, 8'h02, 8'h02, 8'h02, 8'hFF, 8'h00, 
    8'h13, 8'h40, 8'h40, 8'h3D, 8'h3B, 8'h3C, 8'h43, 8'hBF, 8'hBE, 8'hBC, 
    8'hBB, 8'h45, 8'h4D, 8'h49, 8'h47, 8'h4A, 8'h49, 8'h48, 8'h02, 8'h02, 
    8'h02, 8'h02, 8'hFF, 8'h00, 8'h13, 8'h3D, 8'h3D, 8'h3B, 8'h3A, 8'h3C, 
    8'h43, 8'hBF, 8'hBE, 8'hBC, 8'hBC, 8'h48, 8'h48, 8'h45, 8'h41, 8'h4C, 
    8'h47, 8'h48, 8'h00, 8'h02, 8'h02, 8'h02, 8'hFF, 8'h00, 8'h13, 8'h3D, 
    8'h3D, 8'h3A, 8'h3A, 8'h3C, 8'h42, 8'hBF, 8'hBF, 8'hBD, 8'h48, 8'h4B, 
    8'h4D, 8'h49, 8'h41, 8'h4D, 8'h44, 8'h46, 8'h00, 8'h02, 8'h02, 8'h02, 
    8'hFF, 8'h00, 8'h13, 8'h3D, 8'h3D, 8'h3A, 8'h3A, 8'h3B, 8'h40, 8'h48, 
    8'h45, 8'h48, 8'h02, 8'h02, 8'h02, 8'h45, 8'h3F, 8'h4E, 8'h3E, 8'h46, 
    8'h00, 8'h02, 8'h02, 8'h02, 8'hFF, 8'h00, 8'h13, 8'h3D, 8'h3D, 8'h3A, 
    8'h3A, 8'h3B, 8'h41, 8'h48, 8'h45, 8'h48, 8'h02, 8'h02, 8'h02, 8'h45, 
    8'h3F, 8'h4E, 8'h3E, 8'h46, 8'h00, 8'h02, 8'h02, 8'h02, 8'hFF, 8'h00, 
    8'h13, 8'h3D, 8'h3D, 8'h3B, 8'h3A, 8'h3C, 8'h43, 8'hBF, 8'hBF, 8'hBD, 
    8'h48, 8'h4B, 8'h4D, 8'h49, 8'h41, 8'h4D, 8'h44, 8'h46, 8'h00, 8'h02, 
    8'h02, 8'h02, 8'hFF, 8'h00, 8'h13, 8'h3D, 8'h3D, 8'h3C, 8'h3B, 8'h3C, 
    8'h44, 8'hBF, 8'hBE, 8'hBC, 8'hBC, 8'h48, 8'h48, 8'h45, 8'h41, 8'h4C, 
    8'h47, 8'h48, 8'h00, 8'h02, 8'h02, 8'h02, 8'hFF, 8'h00, 8'h13, 8'h40, 
    8'h40, 8'h3D, 8'h3C, 8'h3C, 8'h43, 8'hBF, 8'hBE, 8'hBC, 8'hBC, 8'h45, 
    8'h4D, 8'h49, 8'h47, 8'h4A, 8'h49, 8'h48, 8'h00, 8'h02, 8'h02, 8'h02, 
    8'hFF, 8'h01, 8'h12, 8'h40, 8'h40, 8'h3E, 8'h3D, 8'h41, 8'h4B, 8'hBE, 
    8'hBD, 8'hBA, 8'h40, 8'h4B, 8'h4D, 8'h4E, 8'h4D, 8'h4B, 8'h4A, 8'h4E, 
    8'h02, 8'h02, 8'h02, 8'hFF, 8'h01, 8'h11, 8'h42, 8'h42, 8'h41, 8'h3F, 
    8'h42, 8'h46, 8'hBD, 8'hBD, 8'hBD, 8'h40, 8'h49, 8'h4D, 8'h02, 8'h02, 
    8'h4C, 8'h4A, 8'h4B, 8'h01, 8'h01, 8'hFF, 8'h02, 8'h10, 8'h42, 8'h42, 
    8'h43, 8'h44, 8'h42, 8'h46, 8'h4C, 8'h4A, 8'h43, 8'h47, 8'h4D, 8'h00, 
    8'h02, 8'h02, 8'h48, 8'h4A, 8'h4B, 8'h4B, 8'hFF, 8'h03, 8'h0F, 8'h44, 
    8'h44, 8'h46, 8'h46, 8'h43, 8'h42, 8'h42, 8'h44, 8'h45, 8'h4D, 8'h02, 
    8'h4D, 8'h4A, 8'h49, 8'h49, 8'h49, 8'h49, 8'hFF, 8'h05, 8'h0C, 8'h45, 
    8'h45, 8'h48, 8'h48, 8'h47, 8'h45, 8'h47, 8'h4C, 8'h4D, 8'h97, 8'h8F, 
    8'h8F, 8'h8D, 8'h8D, 8'hFF, 8'h08, 8'h04, 8'h45, 8'h45, 8'h48, 8'h49, 
    8'h8D, 8'h8D, 8'hFF, 8'h00, 8'hB0, 8'h0E, 8'h42, 8'h00, 8'h00, 8'h00, 
    8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
    8'h04, 8'hC0, 8'h7A, 8'hB6, 8'h40, 8'hAF, 8'h98, 8'hB6, 8'h05, 8'h6A, 
    8'h6A, 8'h03, 8'h03, 8'h03, 8'h00, 8'h00, 8'h00, 8'h80, 8'h48, 8'h00, 
    8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
    8'h06, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
    8'h00, 8'h6C, 8'h03, 8'h06, 8'h06, 8'h06, 8'h06, 8'h05, 8'h6C, 8'h67, 
    8'h67, 8'h03, 8'h03, 8'h05, 8'h06, 8'h05, 8'h05, 8'h03, 8'h03, 8'h03, 
    8'h05, 8'h08, 8'h08, 8'h08, 8'h08, 8'h08, 8'h08, 8'h08, 8'h08, 8'h08, 
    8'h08, 8'h06, 8'h08, 8'h00, 8'h00, 8'h08, 8'h08, 8'h08, 8'h08, 8'h08
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
    w_mem_address_aligned = w_mem_address & (~2'b11);

    if (test_num == 1) begin
        mem_readdata = data_array_1[mem_address - data_start_addr];
        w_mem_readdata = {
            data_array_1[w_mem_address_aligned - data_start_addr + 3],
            data_array_1[w_mem_address_aligned - data_start_addr + 2],
            data_array_1[w_mem_address_aligned - data_start_addr + 1],
            data_array_1[w_mem_address_aligned - data_start_addr + 0]
        };
    end

    else if (test_num == 2) begin
        if (mem_read) begin
            mem_readdata = data_array_2[mem_address - data_start_addr];
        end 
        else begin
            mem_readdata = 8'd0;
        end

        if (w_mem_read) begin
            w_mem_readdata = {
                data_array_2[w_mem_address_aligned - data_start_addr + 3],
                data_array_2[w_mem_address_aligned - data_start_addr + 2],
                data_array_2[w_mem_address_aligned - data_start_addr + 1],
                data_array_2[w_mem_address_aligned - data_start_addr + 0]
            };
        end
        else begin
            w_mem_readdata = 32'd0;
        end

        if (mem_write) begin
            x = (mem_address-screen_start_addr) / `SCREENWIDTH;
            y = (mem_address-screen_start_addr) % `SCREENWIDTH;
            screens[x][y] = mem_writedata;
        end
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
    $display("Testing: patch handler short"); test_num = 1;
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

    wait(processing == 0);
    start = 0;
    #10;

    $stop;


    $display("Testing: patch handler long"); test_num = 2;
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

    wait(processing == 0);
    start = 0;
    #300;

    for (int y = 0; y <= `SCREENHEIGHT; y++) begin
        for (int x = 0; x <= `SCREENWIDTH; x++) begin
            $write("%02h", screens[y][x]);
            if (x != `SCREENWIDTH) $write(",");
        end
        $write("\n");
    end

    $stop;
end

endmodule