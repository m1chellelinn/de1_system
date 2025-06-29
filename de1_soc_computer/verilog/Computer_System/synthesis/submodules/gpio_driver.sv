module gpio_driver (
  input  logic        clk,                //      clock.clk               // 
  input  logic        reset_n,            //      reset.reset_n           // 
  input  logic        dbg_rst_n,          //      a conduit               // 

  inout  wire [35:0]  gpio_0,             //      conduits
  inout  wire [35:0]  gpio_1,             //      conduits

  input  logic [3:0]  hps_address,        //  hps_slave.address           // 
  input  logic        hps_read,           //           .read              // 
  output logic        hps_waitrequest,    //           .waitrequest       // comb
  output logic [31:0] hps_readdata,       //           .readdata          // comb
  input  logic        hps_write,          //           .write             // 
  input  logic [31:0] hps_writedata       //           .writedata         // 
);

logic [35:0] gpio_out_0, gpio_out_1;
logic [35:0] gpio_in_0, gpio_in_1;
logic [35:0] drive_enable_0, drive_enable_1; 

assign gpio_0 = drive_enable_0 ? gpio_out_0 : 1'bz;
assign gpio_in_0 = gpio_0;  

assign gpio_1 = drive_enable_1 ? gpio_out_1 : 1'bz;
assign gpio_in_1 = gpio_1;  

always_ff @(posedge clk) begin
  if ((~reset_n) | (~dbg_rst_n)) begin
    drive_enable_0 <= 1;
    gpio_out_0[0] <= ~gpio_out_0[0];
    gpio_out_0[30] <= ~gpio_out_0[30];
  end
  else begin
    drive_enable_0 <= 1;
    gpio_out_0[0] <= 1;
    gpio_out_0[30] <= 1;
  end
end

always_comb begin
  hps_waitrequest = 0;
  hps_readdata = 0;
end

endmodule