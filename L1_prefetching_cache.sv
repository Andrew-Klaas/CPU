module L1_prefetching_cache
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
   output   logic          pmem_write
);

typedef enum
{
   st_normal,
   st_prefetch_pending,
   st_prefetching,
   st_pre_writeback,
   st_writeback
} state_t;

/* LOCAL WIRES */
logic          peek_hit;
logic          lockout;

logic[15:0]    core_mem_address;
logic          core_mem_read;
logic          core_mem_write;
logic          core_mem_resp;

logic[127:0]   core_pmem_rdata;
logic          core_pmem_resp;
logic[15:0]    core_pmem_address;
logic          core_pmem_read;
logic          core_pmem_write;

/* LOCAL REGISTERS */
logic[15:0]    prefetch_address;
logic[127:0]   prefetch_data;
state_t        state;

initial begin
   prefetch_address     <= 16'h0000;
   prefetch_data        <= 128'h00000000000000000000000000000000;
   state                <= st_normal;
end

L1_cache    L1_core
(
   .clk,
   
   // Cache <--> CPU
   .mem_address(core_mem_address),
   .mem_wdata,
   .mem_read(core_mem_read),
   .mem_write(core_mem_write),
   .mem_byte_enable,
   .mem_rdata,
   .mem_resp(core_mem_resp),
   
   // Cache <--> Physical Memory 
   .pmem_rdata(core_pmem_rdata),
   .pmem_resp(core_pmem_resp),
   .pmem_address(core_pmem_address),
   .pmem_wdata,
   .pmem_read(core_pmem_read),
   .pmem_write(core_pmem_write),
   
   .lockout,
   .peek_address(prefetch_address),
   .peek_hit
);

/* PREFETCH ADDRESS REGISTER */
always_ff @(posedge clk) begin
   /* We are only ready to prefetch another address if:
    *    1) We are not currently prefetching something (state == st_normal)
    *    2) We do not need to prefetch the current prefetch address (peek_hit == 1)
    *    3) The last normal address was valid (mem_read == 1)
    */
   if (state == st_normal && peek_hit && mem_read)
      prefetch_address  <= mem_address + 16'h0010; // next cache line
end

/* PREFETCH DATA REGISTER */
always_ff @(posedge clk) begin
   if (state == st_prefetching && pmem_resp)
      prefetch_data <= pmem_rdata;
end

/* STATE TRANSITIONS */
always_ff @(posedge clk) begin
   case (state)
      st_normal:
         if (!peek_hit)
            state <= st_prefetch_pending;
      st_prefetch_pending:
         if (mem_resp)
            state <= st_prefetching;
      st_prefetching:
         if (pmem_resp)
            state <= st_pre_writeback;
      st_pre_writeback:
         state <= st_writeback;
      st_writeback:
         if (core_mem_resp)
            state <= st_normal;
   endcase
   
end

/* STATE ACTIONS */
always_comb begin
   
   case (state)
      st_normal: begin
         
         /* prefetching circuitry is completly transparent as if the L1 core 
          * cache was directly attached to the CPU and physical memory */
         
         lockout              =  1'b0;

         core_mem_address     =  mem_address;
         core_mem_read        =  mem_read;
         core_mem_write       =  mem_write;
         mem_resp             =  core_mem_resp;

         core_pmem_rdata      =  pmem_rdata;
         core_pmem_resp       =  pmem_resp;
         pmem_read            =  core_pmem_read;
         pmem_write           =  core_pmem_write;
         pmem_address         =  core_pmem_address;
         
      end
      
      st_prefetch_pending: begin
         
         /* the prefetching circuitry is still completly transparent, but once
          * the physical memory becomes free, control will move to st_prefetching
          * and the prefetching circuitry will take partial control */
         
         lockout              =  1'b0;

         core_mem_address     =  mem_address;
         core_mem_read        =  mem_read;
         core_mem_write       =  mem_write;
         mem_resp             =  core_mem_resp;

         core_pmem_rdata      =  pmem_rdata;
         core_pmem_resp       =  pmem_resp;
         pmem_read            =  core_pmem_read;
         pmem_write           =  core_pmem_write;
         pmem_address         =  core_pmem_address;
         
      end
      
      st_prefetching: begin
         
         /* The prefetching circuity is in complete control of the physical memory.
          * The prefetcher allows the core cache to respond to CPU hits while it is
          * using the physical memory.  If the core cache misses, then it is not
          * allowed to initiate an eviction or fetch until the prefetch data is writen */
         
         lockout              =  1'b1;

         core_mem_address     =  mem_address;
         core_mem_read        =  mem_read;
         core_mem_write       =  mem_write;
         mem_resp             =  core_mem_resp;

         core_pmem_rdata      =  128'hxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
         core_pmem_resp       =  1'b0;
         pmem_read            =  1'b1;
         pmem_write           =  1'b0;
         pmem_address         =  prefetch_address;
         
      end
      
      st_pre_writeback: begin
         
         /* Initite a fake read request to force the L1 core to read in the prefetched data.
          * This state is necesary to give the L1 core time to initiate an eviction if
          * necessary */
         
         lockout              =  1'b0;

         core_mem_address     =  prefetch_address;
         core_mem_read        =  1'b1;
         core_mem_write       =  1'b0;
         mem_resp             =  1'b0;

         core_pmem_rdata      =  prefetch_data;
         core_pmem_resp       =  1'b0;
         pmem_read            =  1'b0;
         pmem_write           =  1'b0;
         pmem_address         =  16'hxxxx;
         
      end
      
      st_writeback: begin
         
         /* Simulate a read request to the core cache at the prefetch address.  Since the
          * data has already been fetched, there will be no delay.  Feed the data in
          * through the core's pmem_rdata port when it requests a read (allow evictions
          * to pass to pmem first).  */
         
         lockout              =  1'b0;

         core_mem_address     =  prefetch_address;
         core_mem_read        =  1'b1;
         core_mem_write       =  1'b0;
         mem_resp             =  1'b0;

         core_pmem_rdata      =  prefetch_data;
         core_pmem_resp       =  core_pmem_write ? pmem_resp : 1'b1;  // wait on eviction, respond instantly for fetch
         pmem_read            =  1'b0;
         pmem_write           =  core_pmem_write;
         pmem_address         =  core_pmem_address;
         
      end
      
   endcase
   
end

endmodule

