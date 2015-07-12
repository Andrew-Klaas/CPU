module cache_control
(
   input    logic    clk,
   
   // Cache Control <--> CPU
   input    logic          mem_write,
   input    logic          mem_read,
   output   logic          mem_resp,
   
   // Cache Control <--> Cache Datapath
   input    logic          hit,
   input    logic          hit_set,
   input    logic          V0_out,
   input    logic          V1_out,
   input    logic          D0_out,
   input    logic          D1_out,
   input    logic          L_out,
   output   logic          L_in,
   output   logic          WE0,
   output   logic          WE1,
   output   logic          WEL,
   output   logic          D0_in,
   output   logic          D1_in,
   output   logic          feedback_sel,
   output   logic          output_mode,
   output   logic          output_set,
   
   // Cache Control <--> Physical Memory
   input    logic          pmem_resp,
   output   logic          pmem_write,
   output   logic          pmem_read,
   
   // added to support prefetching
   input    logic          lockout
);
   
   logic    replacement_set;
   /* The signal 'replacement_set' calculates which cache line at the current index
    * should be overwritten in the event of a cache miss (wheather or not an eviction
    * occurs).  If this signal is 0, then way0 will be evicted/overwritten and if
    * it is 1 then way1 will be evicted/overwritten.
    *
    * The replacement policy is:
    *   - If both of the cache lines are uninitialized (V == 0) then way 0 is written
    *   - If exactly one of the cache lines is uninitialzed (V == 0) then the way which
    *     is uninitialized will be overwritten
    *   - If both of the cache lines contain data (V == 1), then the one which was read or
    *     written the least recently (~L) will be replaced. */
   
   always_comb
   begin
      case ({V0_out, V1_out, L_out})
         3'b000:  replacement_set <= 1'b0;
         3'b001:  replacement_set <= 1'b0;
         3'b010:  replacement_set <= 1'b0;
         3'b011:  replacement_set <= 1'b0;
         3'b100:  replacement_set <= 1'b1;
         3'b101:  replacement_set <= 1'b1;
         3'b110:  replacement_set <= 1'b1;
         3'b111:  replacement_set <= 1'b0;
      endcase
   end
   
   /* list of states for the cache */
   enum int unsigned
   {
      st_idle,          // The requested data is already in the cache (cache hit)
      st_evict,         // The cache is writing a 128-bit line from a cache line to physical memory
      st_fetch          // The cache is reading a l28-bit line from physical memory
   } state, next_state;
   
   initial
   begin
      state <= st_idle;
   end
   
   /* generate control outputs based on the current state */
   always_comb
   begin
      
      // default signal values
      WE0 <= 1'b0;
      WE1 <= 1'b0;
      WEL <= 1'b0;
      D0_in <= 1'bx;
      D1_in <= 1'bx;
      L_in <= 1'bx;
      feedback_sel <= 1'bx;
      output_mode <= 1'bx;
      output_set <= 1'bx;
      mem_resp <= 1'b0;
      pmem_write <= 1'b0;
      pmem_read <= 1'b0;
      
      case (state)
      
      st_idle:
      begin
         
         mem_resp <= hit;
         output_set <= hit_set;
         
         if (hit)
         begin
            WEL <= 1'b1;
            L_in <= hit_set;
         end
         
         if (mem_write && hit)
         begin
            
            // on a hit, feedback the current cache line
            feedback_sel <= 1'b1;
            
            if (hit_set)
            begin
               WE1 <= 1'b1;
               D1_in <= 1'b1;
            end else begin
               WE0 <= 1'b1;
               D0_in <= 1'b1;
            end
         end
         
      end
         
      st_evict:
      begin
         output_set <= replacement_set;
         output_mode <= 1'b1;  // use the tag of the evicted line to generate an address
         pmem_write <= 1'b1;   // initiate and make progress on a write cycle
         
         // do NOT change L yet, or the fetch stage will write to the wrong way
         
      end
      
      st_fetch:
      begin
         
         pmem_read <= 1'b1;
         output_mode <= 1'b0;
         feedback_sel <= 1'b0;
         
         // do not write until the data has been stabelized.  Only an issue for L really.
         if (pmem_resp)
         begin
            
            if (replacement_set)
            begin
               // If way1 is being replaced...
               WE1 <= 1'b1;
               D1_in <= mem_write;
            end else begin
               // If way0 is being replaced...
               WE0 <= 1'b1;
               D0_in <= mem_write;
            end
            
            L_in <= replacement_set;
            WEL <= 1'b1;
            
         end
         
      end
      endcase
   end
   
   /* calculate the next state of the cache controller */
   always_comb
   begin
      case (state)
      st_idle:
         if (hit || lockout || (!mem_read && !mem_write))
            // if the line is already in the cache, just gate it to the output
            next_state <= st_idle;
         else
            // We only need to write the evicted line back to memory if it is valid and dirty.
            // A valid line is only evicted when both are valid
            if (V0_out && V1_out && (L_out ? D0_out : D1_out))
               next_state <= st_evict;
            else
               next_state <= st_fetch;
      st_evict:
         // only transition to the fetch state when the evicted cache line has been written
         if (pmem_resp)
            next_state <= st_fetch;
         else
            next_state <= st_evict;
      st_fetch:
         // only transition back to the idle state when the cache line has been successfully read
         if (pmem_resp)
            next_state <= st_idle;
         else
            next_state <= st_fetch;
      endcase
   end
   
   /* switch to the next state on each rising clock edge */
   always_ff @(posedge clk)
   begin
      state <= next_state;
   end
   
endmodule : cache_control
