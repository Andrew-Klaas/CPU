import lc3b_types::*;

module victim_cache_control
(
	
	input logic clk,
	input logic v_read, // input from l2
	input logic v_write, // input from L2
	input logic p_resp, //input from physical
	input logic read_hit, //input from datapath
	input logic valid,
	

	output logic v_resp, // output to l2
	output logic p_read, // output to physical
	output logic p_write, // output to physical
	output logic victim_write, // output to datapath
	output logic load_plru,
	output logic load_plru_sel,
	output logic address_sel
		
);

	logic manual_resp;
	logic resp_enable;
	logic enable_valve;
   
	/* list of states for the cache */
   enum int unsigned
   {
      st_idle,          // The requested data is already in the cache (cache hit)
      st_evict,         // The cache is writing a 128-bit line from a cache line to physical memory
      st_write,          // The cache is reading a l28-bit line from physical memory
		st_fetch			// had a victim cache miss, just need to ask physical for correct value now

   } state, next_state;
   
   initial
   begin
      state <= st_idle;
   end
   
   always_comb
   begin
      
   manual_resp <= 0; 				// output to l2
	p_read <= 0; 				// output to physical
	p_write <= 0; 				// output to physical
	victim_write <= 0; 		// output to datapath
	load_plru <= 0;
	load_plru_sel <= 0;
	address_sel <= 0;
	enable_valve <= 1;
		
	/* state definitions */
      case (state)
      
      st_idle:
      begin   
         if (read_hit && v_read )    		// update plru with read hit
         begin
				load_plru_sel <= 1;
				load_plru 		<= 1;
				//victim_write 	<= 1;
				manual_resp <= 1;
         end
      end
		
		st_fetch:
		begin
			p_read <= 1; 						// address is already connected to physical 
		end
		
		
      st_evict:
      begin
		   p_write <= 1'b1;   					//  write cycle
			address_sel <= 1;
			enable_valve <= 0;
      end
      
      st_write:
      begin
         // do not write until the data has been stabelized.  Only an issue for L really.

				victim_write <= 1;
				load_plru <= 1;
				manual_resp <= 1;          

      end
      
		endcase
   end
   
   /* calculate the next state of the cache controller */
   always_comb
   begin
      case (state)
      st_idle:
		   // should a l2_read signal automatically be sent to physical
			if (read_hit)
            // if the line is already in the cache, just gate it to the output
            next_state <= st_idle;
			else if( v_read && !read_hit )
				next_state <= st_fetch;
         else if(v_write && valid) 
				next_state <= st_evict;
			else if(v_write && !valid)
				next_state <= st_write;
			else
				next_state <= st_idle;
				
		st_fetch:
			if(p_resp)
				next_state <= st_idle;
			else
				next_state <= st_fetch;	
		
		
      st_evict:
         // only transition to the fetch state when the evicted cache line has been written
         if (p_resp)
            next_state <= st_write;
         else
            next_state <= st_evict;
      
		st_write:
         // only transition back to the idle state when the cache line has been successfully read
         next_state <= st_idle;

      endcase
   end
   
   /* switch to the next state on each rising clock edge */
   always_ff @(posedge clk)
   begin
      state <= next_state;
   end
	
	
	assign resp_enable = p_resp || manual_resp;
   assign v_resp = resp_enable && enable_valve;
endmodule : victim_cache_control