/* To Meet timing requirements, a layer of flip flops must be added between each 
 * cache layer.  The arbiter serves as the flip flops between the L1s and L2.  
 * This entity serves as a barrier between the L2 <--> Victim and the 
 * Victim <--> Physical Memory.  */

module bridge
(
   
   input    logic          clk,
   
   /* Victim Cache <--> Bridge */
   input    logic[15:0]    upstream_address,
   output   logic[127:0]   upstream_rdata,
   input    logic[127:0]   upstream_wdata,
   input    logic          upstream_read,
   input    logic          upstream_write,
   output   logic          upstream_resp,
   
   /* Bridge <--> Physical memory */
   output   logic[15:0]    downstream_address,
   input    logic[127:0]   downstream_rdata,
   output   logic[127:0]   downstream_wdata,
   output   logic          downstream_read,
   output   logic          downstream_write,
   input    logic          downstream_resp
);

typedef enum
{
   st_ready,
   st_read,
   st_write,
   st_resp
} state_t;

/* LOCAL REGISTERS */
state_t state;

initial begin
   state <= st_ready;
end

/* STATE TRANSITIONS */
always_ff @(posedge clk) begin
   
   case (state)
      st_ready:
         if (upstream_read)
            state <= st_read;
         else if (upstream_write)
            state <= st_write;
      st_read:
         if (downstream_resp)
            state <= st_resp;
      st_write:
         if (downstream_resp)
            state <= st_resp;
      st_resp:
         state <= st_ready;
   endcase
   
end

/* STATE ACTIONS */
assign   downstream_read   =  (state == st_read);
assign   downstream_write  =  (state == st_write);
assign   upstream_resp     =  (state == st_resp);

/* DATA MOVEMENT FLIP FLOPS */
always_ff @(posedge clk) begin
   
   if (state == st_ready && (upstream_read || upstream_write))
      downstream_address   <= upstream_address;
   
   if (state == st_ready && upstream_write)
      downstream_wdata     <= upstream_wdata;
   
   if (state == st_read && downstream_resp)
      upstream_rdata       <= downstream_rdata;
   
end

endmodule
