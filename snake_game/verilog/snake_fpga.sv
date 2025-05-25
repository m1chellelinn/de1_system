// snake_fpga.v
`timescale 1 ps / 1 ps


`define VGA_PX_BASE 32'h08000000
`define VGA_CH_BASE 32'h09000000

// `include "snake_fpga.svh"
`define CMD_START_GAME 0
`define CMD_END_GAME 1
`define CMD_SNAKE_ADD 2
`define CMD_SNAKE_DEL 3
`define CMD_NEW_SCORE 4

`define MSG_X_OFFSET 1
`define MSG_Y_OFFSET 10
`define MSG_CMD_OFFSET 18


module snake_fpga (
  input  logic        clk,       //      clock.clk
  input  logic        reset_n,         //      reset.reset_n

  output logic [31:0]  vga_ch_address,     // vga_master.address
  output logic        vga_ch_read,        //           .read
  input  logic        vga_ch_waitrequest, //           .waitrequest
  input  logic [15:0] vga_ch_readdata,    //           .readdata
  output logic        vga_ch_write,       //           .write
  output logic [15:0] vga_ch_writedata,   //           .writedata

  output logic [31:0]  vga_px_address,     // vga_master.address
  output logic        vga_px_read,        //           .read
  input  logic        vga_px_waitrequest, //           .waitrequest
  input  logic [15:0] vga_px_readdata,    //           .readdata
  output logic        vga_px_write,       //           .write
  output logic [15:0] vga_px_writedata,   //           .writedata

  input  logic [3:0]  hps_address,     //  hps_slave.address
  input  logic        hps_read,        //           .read
  output logic [31:0] hps_readdata,    //           .readdata
  input  logic        hps_write,       //           .write
  input  logic [31:0] hps_writedata,   //           .writedata
  output logic        hps_waitrequest  //           .waitrequest
);

enum { WAITING, PLAYING } state;
logic [31:0] score;
logic [13:0] hps_cmd;
logic [8:0] hps_x;
logic [7:0] hps_y;
logic [15:0] hps_score;


always_ff @( posedge clk ) begin
  if (~reset_n) begin
    state <= WAITING;

    vga_px_read = 1'b0;
    vga_px_write = 1'b0;
  end

  else begin
    case (state)

      WAITING: begin
        if (hps_write) begin
          case (hps_cmd)

            `CMD_START_GAME: begin
              state <= PLAYING;
            end

            `CMD_SNAKE_ADD: begin
              state <= PLAYING;

              vga_px_write = 1'b1;
              vga_px_writedata = 16'hFF00;
            end

            `CMD_NEW_SCORE: begin
              score <= hps_writedata & 32'h0000FFFF;
            end
          endcase
        end
        else begin
          vga_px_write = 1'b0;
        end   
      end

      PLAYING: begin
        state <= WAITING;

        vga_px_write = 1'b0;
        
        if (hps_write) begin
          case (hps_cmd)
            `CMD_END_GAME: begin
            end

            `CMD_SNAKE_ADD: begin
              
            end

            `CMD_SNAKE_DEL: begin
              
            end

            `CMD_NEW_SCORE: begin
              
            end

          endcase
        end
        else begin
          vga_px_read = 1'b0;
          vga_px_write = 1'b0;
        end   
      end

      default: begin
        state <= WAITING;

        vga_px_read = 1'b0;
        vga_px_write = 1'b0;
      end
      
    endcase
  end
end


always_comb begin
  hps_cmd =   hps_writedata[31:`MSG_CMD_OFFSET];
  hps_y =     hps_writedata[`MSG_CMD_OFFSET-1:`MSG_Y_OFFSET];
  hps_x =     hps_writedata[`MSG_Y_OFFSET-1:`MSG_X_OFFSET];
  hps_score = hps_writedata[15:0];
  vga_px_address = `VGA_PX_BASE | {hps_y, hps_x, 1'b0};



  // vga_writedata = 32'b00000000000000000000000000000000;
  hps_readdata = 32'b00000000000000000000000000000000;
  hps_waitrequest = 1'b0;
end


endmodule
