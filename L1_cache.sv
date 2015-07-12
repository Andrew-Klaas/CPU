module L1_cache
(
   input    logic    clk,
   
   // Cache <--> CPU
   input    logic[15:0]    mem_address,
   input    logic[15:0]    mem_wdata,
   input    logic          mem_read,
   input    logic          mem_write,
   input    logic[1:0]     mem_byte_enable,
   output   logic[15:0]    mem_rdata,
   output   logic          mem_resp,
   
   // Cache <--> Physical Memory 
   input    logic[127:0]   pmem_rdata,
   input    logic          pmem_resp,
   output   logic[15:0]    pmem_address,
   output   logic[127:0]   pmem_wdata,
   output   logic          pmem_read,
   output   logic          pmem_write,
   
   // peeking circuitry added to support prefetching
   input    logic          lockout,          // prevent the L1 from transitioning out of st_idle during a miss
   input    logic[15:0]    peek_address,
   output   logic          peek_hit
);
   
   /* Declare intermediate signals */
   logic       hit;
   logic       hit_set;
   logic       V0_out;
   logic       V1_out;
   logic       D0_out;
   logic       D1_out;
   logic       D0_in;
   logic       D1_in;
   logic       L_out;
   logic       L_in;
   logic       WE0;
   logic       WE1;
   logic       WEL;
   logic       feedback_sel;
   logic       output_mode;
   logic       output_set;
   
   /* Instantiate the control unit */
   cache_control CACHE_CONTROL_INST
   (
      .clk,
      
      // Cache Control <--> CPU
      .mem_write,
      .mem_read,
      .mem_resp,
      
      // Cache Control <--> Cache Datapath
      .hit,
      .hit_set,
      .V0_out,
      .V1_out,
      .D0_out,
      .D1_out,
      .D0_in,
      .D1_in,
      .L_out,
      .L_in,
      .WE0,
      .WE1,
      .WEL,
      .feedback_sel,
      .output_mode,
      .output_set,
      
      // Cache Control <--> Physical Memory
      .pmem_resp,
      .pmem_write,
      .pmem_read,
      
      .lockout
   );
   
   /* Instantiate the datapath */
   cache_datapath CACHE_DATAPATH_INST
   (
      .clk,
      
      // Cache Datapath <--> CPU
      .mem_byte_enable,
      .mem_address,
      .mem_wdata,
      .mem_write,
      .mem_rdata,
   
      // Cache Datapath <--> Cache Control
      .L_in,
      .WE0,
      .WE1,
      .WEL,
      .feedback_sel,
      .output_mode,
      .output_set,
      .hit,
      .hit_set,
      .V0_out,
      .V1_out,
      .D0_out,
      .D1_out,
      .D0_in,
      .D1_in,
      .L_out,
      
      // Cache Datapath <--> Physical Memory
      .pmem_rdata,
      .pmem_wdata,
      .pmem_address,
      
      // peeking
      .peek_address,
      .peek_hit
   );
   
endmodule : L1_cache
