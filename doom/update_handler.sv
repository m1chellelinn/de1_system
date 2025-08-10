`timescale 1 ps / 1 ps
`include "doom_consts.svh"

module update_handler (
  input  logic        clk,                //      clock.clk               // 
  input  logic        reset,              //      main_rst                // 
                                          //                              // 
  output logic [31:0] vga_address,        // vga_master.address           // comb
  output logic        vga_read,           //           .read              // comb
  input  logic        vga_waitrequest,    //           .waitrequest       // 
  input  logic [15:0] vga_readdata,       //           .readdata          // 
  output logic        vga_write,          //           .write             // comb
  output logic [15:0] vga_writedata,      //           .writedata         // comb
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
  input  logic [7:0]  local_palette [255:0][2:0],                         //
  input  logic        start,              //  top-level module            //
  output logic        processing          //  top-level module            // comb
);

/* Signals for local use */
enum { WAITING,
       ADVANCE_LOOP,
       WAIT_MEM, WAIT_VGA,
       DONE } 
              state;                          // seq
logic [31:0]  screen_addr;                    // seq
logic [15:0]  idx;                            // seq
logic [8:0]   x;                              // seq
logic [7:0]   y;                              // seq
logic [7:0]   colour_idx;                     // seq
logic [4:0]   r, b; logic [5:0]   g;          // comb


/* 
* int x, y;
* for (y = 0; y < SCREENHEIGHT; y++) {
*     for (x = 0; x < SCREENWIDTH; x++) {               // ADVANCE_LOOP
*         byte index = screens[0][y * SCREENWIDTH + x]; // WAIT_MEM
*         byte r = local_palette[index][0] >> 3;
*         byte g = local_palette[index][1] >> 2;
*         byte b = local_palette[index][2] >> 3;
*         WriteVgaPixel(x, y, r, g, b);                 // WAIT_VGA
*     }
* }
*/

always_ff @( posedge clk ) begin
  if (reset) begin
    state <= WAITING;

    screen_addr <= 0;
    idx <= 0;
    x <= 0;
    y <= 0;
    colour_idx <= 0;
  end

  else begin
    case (state)

      WAITING: begin
        if (start) begin
          state <= WAIT_MEM;

          screen_addr <= hps_params[1];
          idx <= 0;
          x <= 0;
          y <= 0;
          colour_idx <= 0;
        end
      end

      ADVANCE_LOOP: begin
        if (idx == `SCREENSIZE) begin
          state <= DONE;
        end
        else if (x == `SCREENWIDTH - 1) begin
          x <= 0;
          y <= y + 1;
          idx <= idx + 1;
        end
        else begin
          x <= x + 1;
          idx <= idx + 1;
          state <= WAIT_MEM;
        end
      end

      WAIT_MEM: begin
        if (!mem_waitrequest) begin
          state <= WAIT_VGA;
          colour_idx <= mem_readdata;
        end
      end

      WAIT_VGA: begin
        if (!vga_waitrequest) begin
          state <= ADVANCE_LOOP;
        end
      end

      DONE: begin
        state <= WAITING;
      end
    endcase
  end
end


always_comb begin
  debug_seg_export = state;
  processing = 0;

  r = local_palette[colour_idx][0] >> 3;
  g = local_palette[colour_idx][1] >> 2;
  b = local_palette[colour_idx][2] >> 3;

  mem_address = screen_addr + idx;
  mem_read = 0;
  mem_write = 0;
  mem_writedata = 0;

  vga_address = `VGA_PX_BASE | (y << `VGA_MSG_Y_OFFSET) | (x << `VGA_MSG_X_OFFSET);
  vga_read = 0;
  vga_write = 0;
  vga_writedata = {r, g, b};


  case (state) 
    WAITING: begin
      processing = start;
    end

    ADVANCE_LOOP: begin
      processing = 1;
    end

    WAIT_MEM: begin
      processing = 1;
      mem_read = 1;
    end

    WAIT_VGA: begin
      processing = 1;
      vga_write = 1;
    end

    DONE: begin
      
    end

  endcase
end
endmodule
