`timescale 1 ps / 1 ps
`include "doom_consts.svh"

module palette_handler (
  input  logic        clk,                //      clock.clk               // 
  input  logic        reset,              //      main_rst                // 
                                          //                              // 
  output logic [31:0] mem_address,        // mem_master.address           // comb
  output logic        mem_read,           //           .read              // comb
  input  logic        mem_waitrequest,    //           .waitrequest       // 
  input  logic [7:0]  mem_readdata,       //           .readdata          // 
  output logic        mem_write,          //           .write             // comb
  output logic [7:0]  mem_writedata,      //           .writedata         // comb
                                          //                              // 
  output logic [6:0]  debug_seg_export,   //  a conduit                   // comb
  
  input  logic [31:0] hps_params [7:0],   //  top-level module            // 
  output logic [7:0]  local_palette [255:0][2:0],                         //
  input  logic        start,              //  top-level module            //
  output logic        processing          //  top-level module            // comb
);



/* Signals for Patch Handler */



/* Signals for local use */
enum { WAITING, PROCESSING, WAIT_MEM, DONE } 
              state, next_state;              // seq
logic [31:0]  palette_addr;                   // seq
logic [7:0]  i;                               // seq
logic [9:0]  ix3;                             // seq
logic [1:0]  mod3;                            // seq
logic [7:0]  palette_val;                     // seq



/* 
* NOTE: gammatable[usegamma][i] == i

* byte local_palette[256*3];
* void I_SetPalette (byte* palette) {
*     byte c;
*     int i;
* 
*     usegamma = 3;
*     for (i = 0 ; i<256 ; i++) {
*         local_palette[i][0] = *palette++ // VGA R 
*         local_palette[i][1] = *palette++;
*         local_palette[i][2] = *palette++;
*     }
* }
*/

always_ff @( posedge clk ) begin
  if (reset) begin
    state <= WAITING;
    next_state <= WAITING;

    palette_addr <= 0;
    palette_val <= 0;
    i <= 0;
    ix3 <= 0;
    mod3 <= 0;
  end

  else begin
    case (state)

      WAITING: begin
        if (start) begin
          state <= WAIT_MEM;
          next_state <= PROCESSING;

          palette_addr <= hps_params[1];
          palette_val <= 0;
          i <= 0;
          ix3 <= 0;
          mod3 <= 0;
        end
        else begin
          next_state <= WAITING;
        end
      end

      PROCESSING: begin
        if (i == 8'd255) begin
          state <= DONE;
        end
        else begin
          local_palette[i][mod3] <= palette_val;

          if (mod3 == 2'd2) begin
            ix3 <= ix3 + 10'd3;
            i <= i + 8'd1;
          end
          mod3 <= {!mod3[1] & mod3[0], !mod3[1] & !mod3[0]}; // mod3 = (mod3 + 1)% 3;

          state <= WAIT_MEM;
          next_state <= PROCESSING;
        end
      end

      WAIT_MEM: begin
        if (!mem_waitrequest) begin
          state <= next_state;
          palette_val <= mem_readdata;
        end
      end

      DONE: begin
        state <= WAITING;
        next_state <= WAITING;
      end
    endcase
  end
end


always_comb begin
  debug_seg_export = state;
  processing = 0;

  mem_address = palette_addr + ix3 + mod3;
  mem_read = 0;
  mem_write = 0;
  mem_writedata = 0;

  case (state) 
    WAITING: begin
      processing = start;
    end

    PROCESSING: begin
      processing = 1;
    end

    WAIT_MEM: begin
      processing = 1;
      mem_read = 1;
    end

    DONE: begin
      
    end

  endcase
end
endmodule
