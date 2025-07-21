`timescale 1 ps / 1 ps
`include "doom_consts.svh"

module doom_fpga (
  input  logic        clk,                //      clock.clk               // 
  input  logic        reset_n,            //      reset.reset_n           // 
  input  logic        dbg_rst_n,          //      a conduit               // 
                                          //                              // 
  output logic [31:0] vga_address,        // vga_master.address           // comb
  output logic        vga_read,           //           .read              // comb
  input  logic        vga_waitrequest,    //           .waitrequest       // 
  input  logic [15:0] vga_readdata,       //           .readdata          // 
  output logic        vga_write,          //           .write             // seq
  output logic [15:0] vga_writedata,      //           .writedata         // seq
                                          //                              // 
  output logic [31:0] mem_address,        // mem_master.address           // comb
  output logic        mem_read,           //           .read              // comb
  input  logic        mem_waitrequest,    //           .waitrequest       // 
  input  logic [7:0]  mem_readdata,       //           .readdata          // 
  output logic        mem_write,          //           .write             // seq
  output logic [7:0]  mem_writedata,      //           .writedata         // seq
                                          //                              // 
  input  logic [7:0]  hps_address,        //  hps_slave.address           // 
  input  logic        hps_read,           //           .read              // 
  output logic        hps_waitrequest,    //           .waitrequest       // comb
  output logic [31:0] hps_readdata,       //           .readdata          // comb
  input  logic        hps_write,          //           .write             // 
  input  logic [31:0] hps_writedata,      //           .writedata         // 
                                          //                              //
  output logic [41:0] debug_seg_export,   //  a conduit                   // 
  output logic [9:0]  debug_light_export  //  a conduit                   // 
);

/* Top-level module signals */
enum { WAITING, PATCH, PALETTE } 
              state, next_state;              // seq
logic         main_rst;                       // assign
logic         hps_rst;                        // comb
logic [31:0]  hps_params      [7:0];          // comb
// logic [7:0]   local_palette   [255:0][2:0];   // comb TODO: re-enable

assign main_rst = (~reset_n) | (~dbg_rst_n) | (hps_rst);


/* Patch handler */
logic         pat_start;                      // comb
logic         pat_processing;                 // seq
logic [31:0]  pat_vga_address;                // comb
logic         pat_vga_read;                   // comb
logic         pat_vga_write;                  // comb
logic [15:0]  pat_vga_writedata;              // comb
logic [31:0]  pat_mem_address;                // comb
logic         pat_mem_read;                   // comb
logic         pat_mem_write;                  // comb
logic [7:0]   pat_mem_writedata;              // comb
patch_handler patch_handler (
  .clk(clk), .reset(main_rst),

  .vga_address(pat_vga_address), .vga_read(pat_vga_read),
  .vga_waitrequest(vga_waitrequest), .vga_readdata(vga_readdata),
  .vga_write(pat_vga_write), .vga_writedata(pat_vga_writedata),

  .mem_address(pat_mem_address), .mem_read(pat_mem_read),
  .mem_waitrequest(mem_waitrequest), .mem_readdata(mem_readdata),
  .mem_write(pat_mem_write), .mem_writedata(pat_mem_writedata),

  .debug_seg_export(debug_seg_export[34:28]), .hps_params(hps_params),
  .start(pat_start), .processing(pat_processing)
);


/* Palette handler */
logic         pal_start;                      // comb
logic         pal_processing;                 // seq
logic [31:0]  pal_mem_address;                // comb
logic         pal_mem_read;                   // comb
logic         pal_mem_write;                  // comb
logic [7:0]   pal_mem_writedata;              // comb
// palette_handler palette_handler ( // TODO: re-enable
//   .clk(clk), .reset(main_rst),

//   .mem_address(pal_mem_address), .mem_read(pal_mem_read),
//   .mem_waitrequest(mem_waitrequest), .mem_readdata(mem_readdata),
//   .mem_write(pal_mem_write), .mem_writedata(pal_mem_writedata),

//   .debug_seg_export(debug_seg_export[27:21]),
//   .hps_params(hps_params), .local_palette(local_palette),
//   .start(pal_start), .processing(pal_processing) 
// );




always_ff @( posedge clk ) begin
  if (main_rst) begin
    state <= WAITING;
    next_state <= WAITING;

    debug_light_export <= 10'd0;
  end

  else begin
    case (state)

      WAITING: begin
        if (hps_write) begin
          debug_light_export <= ~(hps_address);

          if (hps_address == 0) begin
            case (hps_writedata)
              `CMD_V_Init: begin
                state <= PATCH;
              end

              `CMD_I_SetPalette: begin
                state <= PALETTE;
              end
            endcase
          end

          else begin
            hps_params[hps_address-1] <= hps_writedata;
          end
        end

      end

      PATCH: begin
        if (!pat_processing) begin
          state <= WAITING;
        end
      end

      PALETTE: begin
        if (!pal_processing) begin
          state <= WAITING;
        end
      end

    endcase
  end
end


always_comb begin
  hps_rst =   (hps_writedata == `RESET) & hps_write;
  hps_waitrequest = 0;
  hps_readdata = 0;

  debug_seg_export[41:35] = state;

  pat_start = 0;
  pal_start = 0;

  vga_address = 0;
  vga_read = 0;
  vga_write = 0;
  vga_writedata = 0;

  mem_address = 0;
  mem_read = 0;
  mem_write = 0;
  mem_writedata = 0;

  hps_waitrequest = 0;
  hps_readdata = 0;

  case (state) 
    WAITING: begin

    end

    PATCH: begin
      hps_waitrequest = 1;
      pat_start = 1;

      vga_address = pat_vga_address;
      vga_read = pat_vga_read;
      vga_write = pat_vga_write;
      vga_writedata = pat_vga_writedata;

      mem_address = pat_mem_address;
      mem_read = pat_mem_read;
      mem_write = pat_mem_write;
      mem_writedata = pat_mem_writedata;
    end

    PALETTE: begin
      hps_waitrequest = 1;
      pal_start = 1;

      mem_address = pal_mem_address;
      mem_read = pal_mem_read;
      mem_write = pal_mem_write;
      mem_writedata = pal_mem_writedata;
    end

  endcase
end
endmodule
