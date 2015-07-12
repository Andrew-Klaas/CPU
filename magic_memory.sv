import lc3b_types::*;

module magic_memory #(parameter file = "memory.lst")
(
    input clk,
    input read,
    input write,
    input [1:0] byte_enable,
    input [15:0] address,
    input [15:0] wdata,
    output logic resp,
    output logic [15:0] rdata
);
   
   timeunit 1ns;
   timeprecision 1ns;
   
   logic [7:0] mem [0:2**$bits(address)-1];
   
   enum int unsigned
   {
      st_idle,
      st_wait0,
      st_wait1,
      st_ready
   } state;
   
   /* Initialize memory contents from memory.lst file */
   initial
   begin
      $readmemh(file, mem);
      state <= st_idle;
   end
   
   always_ff @(posedge clk)
   begin
      case (state)
         st_idle  :
            if (read | write)
               state <= st_wait0;
            else
               state <= st_idle;
         st_wait0 : state <= st_wait1;
         st_wait1 : state <= st_ready;
         st_ready : state <= st_idle;
      endcase
   end
   
   always_latch
   begin
      if (state == st_wait1 && write)
      begin
         if (byte_enable[0])
            mem[{address[15:1], 1'b0}] <= wdata[7:0];
         if (byte_enable[1])
            mem[{address[15:1], 1'b1}] <= wdata[15:8];
      end
   end
   
   always_comb
   begin
      case (state)
         
         st_ready:
         begin
            resp <= 1'b1;
            rdata <=
            {
               mem[{address[15:1], 1'b1}],
               mem[{address[15:1], 1'b0}]
            };
         end
         
         default:
         begin
            resp <= 1'b0;
            rdata <= 16'hxxxx;
         end
         
      endcase
   end
endmodule : magic_memory
