`timescale 1 ps / 1 ps
`include "snake_consts.svh"

module score_handler (
  input  logic        clk,                //      clock.clk               // 
  input  logic        reset_n,            //      reset.reset_n           // 
  input  logic        dbg_rst_n,          //      a conduit               // 
  input  logic [31:0] score,              //      internal                // 

  output logic [31:0] vga_ch_address,     // vga_master.address           // comb
  output logic        vga_ch_read,        //           .read              // comb
  input  logic        vga_ch_waitrequest, //           .waitrequest       // 
  input  logic [15:0] vga_ch_readdata,    //           .readdata          // 
  output logic        vga_ch_write,       //           .write             // comb
  output logic [15:0] vga_ch_writedata,   //           .writedata         // comb
  
  output logic [6:0]  cmd_export          //  a conduit                   // comb
);

enum { POLLING, UPDATING1, UPDATING2 } state;
logic [7:0] local_score;    // seq
logic [7:0] digit1, digit2; // hexadecimals, comb


always_ff @( posedge clk ) begin
  if ((~reset_n) | (~dbg_rst_n)) begin
    state <= UPDATING1;
    local_score <= 0;
  end

  else begin
    case (state) 
      POLLING: begin
        if (score[7:0] != local_score) begin
          state <= UPDATING1;
          local_score <= score;
        end
      end
      
      UPDATING1: begin
        if (~vga_ch_waitrequest) begin
          state <= UPDATING2;
        end
      end
      
      UPDATING2: begin
        if (~vga_ch_waitrequest) begin
          state <= POLLING;
        end
      end
    endcase
  end
end

always_comb begin
  cmd_export = state;
  
  digit2 = score[7:4] >= 10 ?
           score[7:4] + `ALPHA_ASCII_OFFSET :
           score[7:4] + `NUMERIC_ASCII_OFFSET;
  digit1 = score[3:0] >= 10 ?
           score[3:0] + `ALPHA_ASCII_OFFSET :
           score[3:0] + `NUMERIC_ASCII_OFFSET;

  vga_ch_write = 0;
  vga_ch_writedata = 0;
  vga_ch_address = `VGA_PX_BASE;

  vga_ch_read = 0;

  unique case (state)
      POLLING: begin
      end
      
      UPDATING1: begin
        vga_ch_write = 1;
        vga_ch_writedata = digit1;
        vga_ch_address = `VGA_PX_BASE | (2 << 7) | (4);
      end
      
      UPDATING2: begin
        vga_ch_write = 1;
        vga_ch_writedata = digit2;
        vga_ch_address = `VGA_PX_BASE | (2 << 7) | (3);
      end
  endcase
end

endmodule