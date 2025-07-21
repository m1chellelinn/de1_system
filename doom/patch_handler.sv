`timescale 1 ps / 1 ps
`include "doom_consts.svh"

module patch_handler (
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

  output logic [6:0] debug_seg_export,    //  a conduit                   // 
  
  input logic [31:0] hps_params [7:0],
  input  logic        start,              //  top-level module            //
  output logic        processing          //  top-level module            // comb
);



/* Signals for Patch Handler */



/* Signals for local use */
enum { WAITING, PROCESSING, WAIT_MEM, DONE} 
    state, next_state;         // seq
logic hps_rst;                 // comb
logic [7:0] i;                 // seq
logic [31:0] ram_start_addr;

/*
* typedef struct 
* { 
*     short		width;		// bounding box size 
*     short		height; 
*     short		leftoffset;	// pixels to the left of origin 
*     short		topoffset;	// pixels below the origin 
*     int			columnofs[8];	// only [width] used
*     // the [0] is &columnofs[width] 
* } patch_t;
* 
* void V_DrawPatch ( int x, int y, int scrn, patch_t* patch ) { 
*     int		count;
*     int		col; 
*     column_t*	column; 
*     byte*	desttop;
*     byte*	dest;
*     byte*	source; 
*     int		w; 
* 	 
*     y -= patch->topoffset; 
*     x -= patch->leftoffset; 
* 
*     col = 0; 
*     desttop = screens[scrn]+y*SCREENWIDTH+x; 
* 	 
*     w = SHORT(patch->width); 
* 
*     for ( ; col<w; x++, col++, desttop++)
*     { 
*         column = (column_t *)((byte *)patch + LONG(patch->columnofs[col])); 
*     
*         // step through the posts in a column 
*         while (column->topdelta != 0xff ) 
*         { 
*           source = (byte *)column + 3; 
*           dest = desttop + column->topdelta*SCREENWIDTH; 
*           count = column->length; 
*               
*           while (count--) 
*           { 
*             *dest = *source++; 
*             dest += SCREENWIDTH; 
*           } 
*           column = (column_t *)( (byte *)column + column->length + 4 ); 
*         } 
*     }			 
* } 
*/


always_ff @( posedge clk ) begin
  if (reset) begin
    state <= WAITING;
    next_state <= WAITING;
    i <= 0;
    ram_start_addr <= 0;
  end

  else begin
    case (state)

      WAITING: begin
        if (start) begin
          state <= WAIT_MEM;
          next_state <= PROCESSING;
          i <= 0;
        end
        else begin
          state <= WAITING;
          next_state <= WAITING;
          i <= 0;
        end
      end

      PROCESSING: begin
        if (i >= 8'd20) begin
          state <= DONE;
          i <= 0;
        end
        else begin
          state <= WAIT_MEM;
          next_state <= PROCESSING;
          i <= i + 1;
        end
      end

      WAIT_MEM: begin
        if (!mem_waitrequest) begin
          state <= next_state;
        end
      end

      DONE: begin
        state <= DONE;
      end

      default: state <= WAITING;

    endcase
  end
end


always_comb begin
  debug_seg_export = state;
  processing = 0;

  vga_address = 0;
  vga_read = 0;
  vga_write = 0;
  vga_writedata = 0;

  mem_address = ram_start_addr + i;
  mem_read = 0;
  mem_write = 0;
  mem_writedata = i;

  case (state) 
    WAITING: begin
      processing = start;
    end

    PROCESSING: begin
      processing = 1;
    end

    WAIT_MEM: begin
      processing = 1;
      mem_write = 1;
    end

    DONE: begin
      
    end
  endcase
end
endmodule