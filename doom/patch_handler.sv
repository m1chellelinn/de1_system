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
  output logic [31:0] mem_address,        // mem_master.address           // seq
  output logic        mem_read,           //           .read              // comb
  input  logic        mem_waitrequest,    //           .waitrequest       // 
  input  logic [7:0]  mem_readdata,       //           .readdata          // 
  output logic        mem_write,          //           .write             // comb
  output logic [7:0]  mem_writedata,      //           .writedata         // seq
                                          //                              // 
  output logic [31:0] w_mem_address,      // wide_mem_master.address      // seq
  output logic        w_mem_read,         //                .read         // comb
  input  logic        w_mem_waitrequest,  //                .waitrequest  // 
  input  logic [31:0] w_mem_readdata,     //                .readdata     // 
  output logic        w_mem_write,        //                .write        // comb
  output logic [31:0] w_mem_writedata,    //                .writedata    // seq

  output logic [6:0]  debug_seg_export,   //  a conduit                   // 
  
  input logic [31:0]  hps_params [7:0],
  input  logic        start,              //  top-level module            //
  output logic        processing          //  top-level module            // comb
);

/* Signals for local use */
enum { WAITING, DONE,
       PROCESSING_INIT0, PROCESSING_INIT1, PROCESS_INIT2,
       GET_POST, DRAW_POST, READ_COL, DRAW_COL,
       LOOP_ITER,
       WAIT_MEM_WRITE, WAIT_MEM_READ,
       WAIT_W_MEM_WRITE, WAIT_W_MEM_READ}
              state, next_state;          // seq
logic         hps_rst;                    // comb
logic [15:0]  x, y, scrn_num;             // seq -- function params
logic [31:0]  screens, patch;             // seq -- function params
logic [31:0]  patch_addr,                 // seq -- local pointers
              col_addr,                   // seq
              desttop,                    // seq
              dest,                       // seq
              source;                     // seq
logic [15:0]  count, col,                 // seq -- local numbers
logic [7:0]   post_topdelta, post_length; // seq -- cached memory
logic [15:0]  patch_width,                // seq -- cached memory
              patch_leftoffset,           // seq
              patch_topoffset;          // seq
logic [7:0]   local_mem_readdata;         // seq -- captured readdata
logic [31:0]  local_w_mem_readdata;       // seq -- captured readdata


/*
* // posts are runs of non masked source pixels
* typedef struct
* {
*     byte		topdelta;	// -1 is the last post in a column
*     byte		length; 	// length data bytes follows
* } post_t;
* 
* // column_t is a list of 0 or more post_t, (byte)-1 terminated
* typedef post_t	column_t;
*
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
****PROCESSING_INIT0
*     short		count;
*     short 	col; 
*     column_t*	column; 
*     byte*	desttop;
*     byte*	dest;
*     byte*	source; 
*
****PROCESSING_INIT1
*     short width = patch->width; // read -- also read patch->height (useless lol)
****PROCESSING_INIT2
*     y -= patch->topoffset; // read -- also read patch->leftoffset
*     x -= patch->leftoffset; // read -- aggregated away
* 
*     desttop = screens[scrn]+y*SCREENWIDTH+x;
*
****GET_POST
*     for (col = 0; col < width; x++, col++, desttop++)
*     { 
*         column = (column_t *)((byte *)patch + LONG(patch->columnofs[col])); // read
*
****DRAW_POST
*         // step through the posts in a column 
*         while (column->topdelta != 0xff ) // read -- also read column->length
*         { 
*           source = (byte *)column + 3; 
*           dest = desttop + column->topdelta*SCREENWIDTH; // read -- aggregated away
*           count = column->length; // read -- aggregated away
*
****DRAW_COL
*           while (count--) 
*           { 
*             *dest = *source++; // read & write
*             dest += SCREENWIDTH; 
*           } 
*           column = (column_t *)( (byte *)column + column->length + 4 );  // read -- aggregated away
*         } 
*     }
* } 
*/


always_ff @( posedge clk ) begin
  if (reset) begin
    state <= WAITING;
    next_state <= WAITING;

    x = 0; y = 0; scrn = 0; screens = 0; patch = 0;
    patch_addr = 0; col_addr = 0; desttop = 0; dest = 0; source = 0; 
    count = 0; col = 0;
    post_topdelta = 0; post_length = 0;
    patch_width = 0; patch_leftoffset = 0; patch_topoffset = 0;
    local_mem_readdata = 0; local_w_mem_readdata = 0;
    mem_address = 0; mem_writedata = 0; w_mem_address = 0; w_mem_writedata = 0;
  end

  else begin
    case (state)

      WAITING: begin
        if (start) begin
          w_mem_address <= hps_params[4]; // addr of "patch"
          state <= WAIT_W_MEM_READ;
          next_state <= PROCESSING_INIT1;

          x <= hps_params[1];
          y <= hps_params[2];
          scrn <= hps_params[3];
          screens <= hps_params[4]
          patch <= hps_params[5];

          // Reset all locals. Why is my code so CHUNKY
          patch_addr = 0; col_addr = 0; desttop = 0; dest = 0; source = 0; 
          count = 0; col = 0;
          post_topdelta = 0; post_length = 0;
          patch_width = 0; patch_leftoffset = 0; patch_topoffset = 0;
          local_mem_readdata = 0; local_w_mem_readdata = 0;
          mem_address = 0; mem_writedata = 0; w_mem_address = 0; w_mem_writedata = 0;
        end
        else begin
          state <= WAITING;
          next_state <= WAITING;
        end
      end

      PROCESSING_INIT1: begin
        patch_width <= local_w_mem_readdata[15:0];

        w_mem_address <= patch + 4; // {patch->topoffset, patch->leftoffset}
        state <= WAIT_W_MEM_READ;
        next_state <= PROCESS_INIT2;
      end

      PROCESSING_INIT2: begin
        patch_topoffset = local_w_mem_readdata[31:16];
        patch_leftoffset = local_w_mem_readdata[15:0];
        y = y - patch_topoffset;
        x = x - patch_leftoffset;
        desttop <= screens + 
                   (y << 8) + (y << 6) + // y * SCREENWIDTH
                   x +
                   (scrn ? 16'd64000 : 0); // assume DOOM only ever writes to scrn 0 or 1

        w_mem_address <= patch + 8 + col;
        state <= WAIT_W_MEM_READ;
        next_state <= GET_POST;
      end

      GET_POST: begin
          column = patch + local_w_mem_readdata;

          w_mem_address <= column;
          state <= WAIT_W_MEM_READ;
          next_state <= GET_POST;
      end

      DRAW_POST: begin
        post_length = local_w_mem_readdata[15:8];
        post_topdelta = local_w_mem_readdata[7:0];

        if (post_topdelta == 8'hFF) begin
          state <= LOOP_ITER;
        end
        else begin
          source <= column + 3;
          dest <= desttop + (post_topdelta << 8) + (post_topdelta << 6); // == desttop + post_topdelta * SCREENWIDTH
          count <= post_length; // FIXME: can get rid of "count" and just decrement post_length going forward
          state <= READ_COL;
        end
      end

      READ_COL: begin
        if (count > 0) begin
          mem_address <= source;
          state <= WAIT_MEM_READ;
          next_state <= WRITE_COL;

          source <= source + 1;
        end
        else begin
          state <= LOOP_ITER;
        end
      end

      WRITE_COL: begin
        mem_address <= dest;
        state <= WAIT_MEM_WRITE;
        next_state <= READ_COL;

        cout <= cout - 1;
        dest <= dest + SCREENWIDTH;
      end

      LOOP_ITER: begin
        if (col < patch_width) begin
          x <= x + 1;
          col <= col + 1;
          desttop <= desttop + 1;
        end
        else begin
          state <= DONE;
        end

      end

      WAIT_MEM_WRITE: begin
        if (!mem_waitrequest) begin
          state <= next_state;
          local_mem_readdata <= mem_readdata;
        end
      end

      WAIT_MEM_READ: begin
        if (!mem_waitrequest) begin
          state <= next_state;
          local_mem_readdata <= mem_readdata;
        end
      end

      WAIT_W_MEM_WRITE: begin
        if (!w_mem_waitrequest) begin
          state <= next_state;
          local_w_mem_readdata <= w_mem_readdata;
        end
      end

      WAIT_W_MEM_READ: begin
        if (!w_mem_waitrequest) begin
          state <= next_state;
          local_w_mem_readdata <= w_mem_readdata;
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
  processing = 1;

  vga_address = 0;
  vga_read = 0;
  vga_write = 0;
  vga_writedata = 0;

  mem_read = 0;
  mem_write = 0;

  w_mem_read = 0;
  w_mem_write = 0;

  case (state) 
    WAITING: begin
      processing = start;
    end

    PROCESSING_INIT1: begin
    end

    PROCESSING_INIT2: begin
    end
    
    GET_POST: begin
    end
    
    DRAW_POST: begin
    end

    READ_COL: begin
    end

    WRITE_COL: begin
    end

    LOOP_ITER: begin
    end

    WAIT_MEM_WRITE: begin
      mem_write = 1;
    end
    
    WAIT_MEM_READ: begin
      mem_read = 1;
    end
    
    WAIT_W_MEM_WRITE: begin
      w_mem_write = 1;
    end
    
    WAIT_W_MEM_READ: begin
      w_mem_read = 1;
    end

    DONE: begin
      processing = 0;
    end
  endcase
end
endmodule