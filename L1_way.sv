/* This is just a memory.  When the 'we' signal is high,
 * the data at 'in' is constantly fed into the word at
 * address 'ix'.  When 'we' goes low, the most recent value
 * at 'in' is latched in memory.
 *
 * 'out' always displays the content at memory location 'ix' */

module cache_way
(
   
   input    logic                clk,
   
   input    logic                WE,
   input    logic[2:0]           ix,
   
   input    logic                D_in,
   input    logic[8:0]           tag_in,
   input    logic[127:0]         data_in,
   
   output   logic                V_out,
   output   logic                D_out,
   output   logic[8:0]           tag_out,
   output   logic[127:0]         data_out,
   
   input    logic[15:0]          peek_address,
   output   logic                peek_hit
);
   
   // declare storage
   logic[7:0]           V; // valid
   logic[7:0]           D; // dirty
   logic[7:0][8:0]      tag;
   logic[7:0][127:0]    data;
   
   initial
   begin
      for (int i = 0; i < 8; i++)
      begin
         V[i] <= 1'b0;
         D[i] <= 1'b0;
         tag[i] <= 9'b000000000;
         data[i] <= 128'h00000000;
      end
   end
   
   // write logic - writes only occur on the rising edge
   always_ff @ (posedge clk)
   begin
      
      if (WE)
      begin
         V[ix] <= 1'b1;
         D[ix] <= D_in;
         tag[ix] <= tag_in;
         data[ix] <= data_in;
      end
      
   end
   
   always_comb
   begin
      
      V_out <= V[ix];
      D_out <= D[ix];
      tag_out <= tag[ix];
      data_out <= data[ix];
      
      peek_hit <= tag[peek_address[6:4]] == peek_address[15:7] && V[peek_address[6:4]];
      
   end
   
endmodule : cache_way
