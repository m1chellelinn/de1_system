`timescale 1 ps / 1 ps
`include "snake_consts.svh"

module snake_fpga (
  input  logic        clk,                //      clock.clk               // 
  input  logic        reset_n,            //      reset.reset_n           // 
  input  logic        dbg_rst_n,          //      a conduit               // 
                                          //                              // 
  output logic [31:0] vga_ch_address,     // vga_master.address           // text_handler
  output logic        vga_ch_read,        //           .read              // text_handler
  input  logic        vga_ch_waitrequest, //           .waitrequest       // 
  input  logic [15:0] vga_ch_readdata,    //           .readdata          // 
  output logic        vga_ch_write,       //           .write             // text_handler
  output logic [15:0] vga_ch_writedata,   //           .writedata         // text_handler
                                          //                              // 
  output logic [31:0] vga_px_address,     // vga_master.address           // comb
  output logic        vga_px_read,        //           .read              // comb
  input  logic        vga_px_waitrequest, //           .waitrequest       // 
  input  logic [15:0] vga_px_readdata,    //           .readdata          // 
  output logic        vga_px_write,       //           .write             // seq
  output logic [15:0] vga_px_writedata,   //           .writedata         // seq
                                          //                              // 
  input  logic [3:0]  hps_address,        //  hps_slave.address           // 
  input  logic        hps_read,           //           .read              // 
  output logic        hps_waitrequest,    //           .waitrequest       // comb
  output logic [31:0] hps_readdata,       //           .readdata          // comb
  input  logic        hps_write,          //           .write             // 
  input  logic [31:0] hps_writedata,      //           .writedata         // 
                                          //                              //
  output logic [6:0]  state_export,       //  a conduit                   // comb
  output logic [6:0]  cmd_export          //  a conduit                   // seq
);

enum { WAITING, PLAYING, REQUESTING_PX,
       CLEAR_SCREEN_INIT, CLEAR_SCREEN} state, next_state;    // seq
logic [31:0] score;                                           // seq
logic [13:0] hps_cmd;                                         // comb
logic [8:0] hps_x;                                            // comb
logic [7:0] hps_y;                                            // comb
logic [15:0] hps_score;                                       // comb
logic [8:0] cls_x; // "clear screen, x"                       // seq
logic [7:0] cls_y; // "clear screen, y"                       // seq
logic hps_rst;                                                // comb
logic is_waiting;                                             // comb, used by text_handler

text_handler handler (.*);


always_ff @( posedge clk ) begin
  if ((~reset_n) | (~dbg_rst_n) | (hps_rst)) begin
    state <= WAITING;
    next_state <= WAITING;
    score <= 0;
    cls_x <= 0;
    cls_y <= 0;
    vga_px_write <= 0;
    vga_px_writedata <= 0;

    // cmd_export <= 0;
  end

  else begin
    case (state)

      WAITING: begin
        score <= 0;
        cls_x <= 0;
        cls_y <= 0;
        vga_px_write <= 0;
        vga_px_writedata <= 0;

        if (hps_write) begin
          case (hps_cmd)

            `CMD_START_GAME: begin
              state <= CLEAR_SCREEN_INIT;
              next_state <= PLAYING;
            end
          endcase
        end
        else begin
        end   
      end

      PLAYING: begin
        if (hps_write) begin
          case (hps_cmd)
            `CMD_END_GAME: begin
              state <= WAITING;
              // state <= CLEAR_SCREEN_INIT;
              // next_state <= WAITING;
            end

            `CMD_SNAKE_ADD: begin
              vga_px_write <= 1;
              vga_px_writedata <= `SNAKE_COLOUR;
              state <= REQUESTING_PX;
              next_state <= PLAYING;
            end

            `CMD_SNAKE_DEL: begin
              vga_px_write <= 1;
              vga_px_writedata <= (hps_x[0] ^ hps_y[0]) ? `GRAY : `BLACK;
              state <= REQUESTING_PX;
              next_state <= PLAYING;
            end

            `CMD_NEW_SCORE: begin
              score <= hps_score;
            end

            `CMD_APPLE_ADD: begin
              vga_px_write <= 1;
              vga_px_writedata <= `APPLE_COLOUR;
              state <= REQUESTING_PX;
              next_state <= PLAYING;
            end

            `CMD_APPLE_DEL: begin
              vga_px_write <= 1;
              vga_px_writedata <= (hps_x[0] ^ hps_y[0]) ? `GRAY : `BLACK;
              state <= REQUESTING_PX;
              next_state <= PLAYING;
            end

            `CMD_GOLDEN_APPLE_ADD: begin
              vga_px_write <= 1;
              vga_px_writedata <= `GAPPLE_COLOUR;
              state <= REQUESTING_PX;
              next_state <= PLAYING;
            end

            `CMD_GOLDEN_APPLE_DEL: begin
              vga_px_write <= 1;
              vga_px_writedata <= (hps_x[0] ^ hps_y[0]) ? `GRAY : `BLACK;
              state <= REQUESTING_PX;
              next_state <= PLAYING;
            end

            `CMD_SPEED_UP_ADD: begin
              vga_px_write <= 1;
              vga_px_writedata <= `SPEED_UP_COLOUR;
              state <= REQUESTING_PX;
              next_state <= PLAYING;
            end

            `CMD_SPEED_UP_DEL: begin
              vga_px_write <= 1;
              vga_px_writedata <= (hps_x[0] ^ hps_y[0]) ? `GRAY : `BLACK;
              state <= REQUESTING_PX;
              next_state <= PLAYING;
            end
          endcase
        end
        else begin
        end  
      end

      REQUESTING_PX: begin
        if (~vga_px_waitrequest) begin
          state <= next_state;
          vga_px_write <= 0;

          // cmd_export <= cmd_export + 1;
        end
      end

      CLEAR_SCREEN_INIT: begin
        cls_x <= 0;
        cls_y <= 0;
        vga_px_write <= 1'b1;
        vga_px_writedata <= (cls_x[0] ^ cls_y[0]) ? `BLACK : `GRAY;
        state <= CLEAR_SCREEN;

        // cmd_export <= cmd_export + 1;
      end

      CLEAR_SCREEN: begin
        vga_px_writedata <= (cls_x[0] ^ cls_y[0]) ? `BLACK : `GRAY;

        if (vga_px_waitrequest) ;// do nothing
        else if ( cls_x == `NUM_X_PIXELS && cls_y == `NUM_Y_PIXELS) begin
          state <= next_state;
          vga_px_write <= 1'b0;
        end
        else if ( cls_x == `NUM_X_PIXELS) begin
          cls_x = 0;
          cls_y += 8'd1;
        end
        else begin
          cls_x += 9'd1;
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
  hps_rst =   (hps_writedata == `RESET_GAME) & hps_write;
  hps_cmd =   hps_writedata[31:`MSG_CMD_OFFSET];
  hps_y =     hps_writedata[`MSG_CMD_OFFSET-1:`MSG_Y_OFFSET];
  hps_x =     hps_writedata[`MSG_Y_OFFSET-1:`MSG_X_OFFSET];
  hps_score = hps_writedata[15:0];
  vga_px_address = `VGA_PX_BASE | (hps_y << `MSG_Y_OFFSET) | (hps_x << `MSG_X_OFFSET);
  hps_waitrequest = 0;
  hps_readdata = 0;

  is_waiting = 0;
  state_export = state;

  case (state) 
    WAITING: begin
      is_waiting = 1;
    end

    PLAYING: begin
    end

    REQUESTING_PX: begin
      hps_waitrequest = 1;
    end

    CLEAR_SCREEN_INIT: begin
      hps_waitrequest = 1;
      vga_px_address = `VGA_PX_BASE | (cls_y << `MSG_Y_OFFSET) | (cls_x << `MSG_X_OFFSET);
    end

    CLEAR_SCREEN: begin
      hps_waitrequest = 1;
      vga_px_address = `VGA_PX_BASE | (cls_y << `MSG_Y_OFFSET) | (cls_x << `MSG_X_OFFSET);
    end

  endcase
end
endmodule
