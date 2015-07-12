module l2_cache_control
(
   input logic clk,
	
	/* Arbiter <--> l2_cache_control */
	input logic l2_read,
	input logic l2_write,
	output logic l2_resp,
	
	/* L2_cache_control <--> physical memory */
	input logic p_resp,
	output logic p_read,
	output logic p_write,
	
	/* l2_cache_control <--> l2_cache_datapath*/
	output logic[2:0] lru_in,   
	output logic ld_lru, 
	input logic[2:0] lru_out, 
	output logic write_mux_sel,
	
	output logic v0_in,
   output logic v1_in,
   output logic v2_in,
   output logic v3_in,
	
	output logic ld_v0,	
	output logic ld_v1,
	output logic ld_v2,
	output logic ld_v3,
	
	input logic v0_out,
	input logic v1_out,	
	input logic v2_out,		
	input logic v3_out,
	
	output logic d0_in,	
	output logic d1_in,   	
	output logic d2_in,   
   output logic d3_in,   	
	
	input logic d0_out,
	input logic d1_out, 
	input logic d2_out, 
	input logic d3_out, 	
   
	output logic ld_d0, 
	output logic ld_d1,
	output logic ld_d2, 	
	output logic ld_d3, 
	
	output logic ld_tag0,  
	output logic ld_tag1, 
   output logic ld_tag2,  
	output logic ld_tag3, 
	
	output logic ld_data0,
	output logic ld_data1,
	output logic ld_data2,
	output logic ld_data3,
   
	output logic[2:0] pmem_mux_sel,
	
	input logic hit,
	input logic[3:0] hit_set
);
   
   logic[2:0]    replacement_set;
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
      
		if(v0_out == 0) 
					replacement_set <= {1'b0,1'b0, lru_out[0]};
		else if(v1_out == 0) 
					replacement_set <= {1'b0,1'b1, lru_out[0]};
		else if(v2_out == 0) 
				   replacement_set <= {1'b1,lru_out[1],1'b0};
		else if(v3_out == 0)
					replacement_set <= {1'b1,lru_out[1],1'b1};
		else 
			case(lru_out)
				3'b000: replacement_set <= 3'b101;
				3'b001: replacement_set <= 3'b100;
				3'b010: replacement_set <= 3'b111;
				3'b011: replacement_set <= 3'b110;
				3'b100: replacement_set <= 3'b010;
				3'b101: replacement_set <= 3'b011;
				3'b110: replacement_set <= 3'b000;
				3'b111: replacement_set <= 3'b001;			
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
      
      /* begin default signal values */
      ld_v0 <= 1'b0;     //valid bit loads
		ld_v1 <= 1'b0;
		ld_v2 <= 1'b0;
		ld_v3 <= 1'b0;
		v0_in <= 1'b0;     //valid bit inputs
      v1_in <= 1'b0;
      v2_in <= 1'b0;
      v3_in <= 1'b0;
	   d0_in <= 1'b0;     // dirty bit inputs
	   d1_in <= 1'b0;   	
	   d2_in <= 1'b0;   
      d3_in <= 1'b0;   	
	   ld_d0 <= 1'b0;     // dirty bit loads
	   ld_d1 <= 1'b0;
	   ld_d2 <= 1'b0;
	   ld_d3 <= 1'b0;
 
      ld_lru <= 1'b0;     // lru loads
      lru_in <= 3'b000;  // lru input
      
      pmem_mux_sel <= 3'b100;      // selects which tag   to send to physical  memory
      write_mux_sel <= 1'b0;    // picks wether to lload the data from memeory or from the cache
		
	   ld_data0 <= 1'b0;  // load the  the data arrays in the cache
	   ld_data1 <= 1'b0;
	   ld_data2 <= 1'b0;
	   ld_data3 <= 1'b0;
		ld_tag0 <= 1'b0;    // load the tag arrays in the cache
	   ld_tag1 <= 1'b0; 
      ld_tag2 <= 1'b0;  
	   ld_tag3 <= 1'b0; 
      
      p_write <= 1'b0;
      p_read <= 1'b0;
		
		l2_resp <= 1'b0;
		
	/* state definitions */
      case (state)
      
      st_idle:
      begin
         
         l2_resp <= hit;
         
         if (hit && l2_read)
         begin
			    ld_lru <= 1;
				case(hit_set) 
					4'b0001: lru_in <= {1'b0,1'b0,lru_out[0]};                  // way 0 hit
				   4'b0010: lru_in <= {1'b0,1'b1,lru_out[0]};						// way 1 hit
					4'b0100: lru_in <= {1'b1,lru_out[1],1'b0};						// way 2 hit 
					4'b1000: lru_in <= {1'b1,lru_out[1],1'b1};						// way 3 hit
					default:	lru_in <= {1'b0,1'b0,1'b0};
				endcase
         end
         
         if (l2_write && hit)
         begin
			  ld_lru <= 1;
           write_mux_sel <= 1;
			  case(hit_set)
            4'b0001: begin  	 						  //way 0 write hit
					ld_tag0 <= 1; 
					ld_data0 <= 1; 
					ld_d0 <= 1'b1; 
					d0_in <= 1'b1; 
					lru_in <= {1'b0,1'b0,lru_out[0]};  	
				end
     	      4'b0010:	begin     						  //way 1 write hit
					ld_tag1 <= 1; 
					ld_data1 <= 1; 
					ld_d1 <= 1'b1; 
					d1_in <= 1'b1; 
					lru_in <= {1'b0,1'b1,lru_out[0]};
				end
				4'b0100:	begin    						  //way 2 write hit
					ld_tag2 <= 1; 
					ld_data2 <= 1; 
					ld_d2 <= 1'b1; 
					d2_in <= 1'b1; 
					lru_in <= {1'b1,lru_out[1],1'b0}; 	
				end
				4'b1000: begin     						  // way 3 write hit
					ld_tag3 <= 1; 
					ld_data3 <= 1; 
					ld_d3 <= 1'b1; 
					d3_in <= 1'b1; 
					lru_in <= {1'b1,lru_out[1],1'b1};   
				end
				default: begin end //nothing 
			  endcase	
         end
         
      end
         
      st_evict:
      begin
		
         p_write <= 1'b1;   							//  write cycle
         			 
			 /* this block selects the tag or address to send to physical memory, the mux is in the l2_cache_datapath */
			 if (replacement_set[2])
          begin
					if(replacement_set[0])
							pmem_mux_sel <= 3'b011;  	// way 3
				   else    
                     pmem_mux_sel <= 3'b010;  	// way 2	
			 end else begin
				   
					if(replacement_set[1])
                    pmem_mux_sel <= 3'b001;     // way 1
					else 
                    pmem_mux_sel <= 3'b000;     // way 0		 
          end
      end
      
      st_fetch:
      begin
         
         p_read <= 1'b1;
         pmem_mux_sel <= 3'b100; 					// select the memory_address given by arbiter in the l2_cache_datapath

         
         // do not write until the data has been stabelized.  Only an issue for L really.
         if (p_resp)
         begin
            
				
            if (replacement_set[2])	begin
               if(replacement_set[0]) begin			       //way 3
						v3_in <= 1;
						ld_v3 <= 1;
						d3_in <= 0;
						ld_d3 <= 1;
						ld_tag3 <= 1;
						ld_data3 <= 1;
					end else begin                             // way 2 
						v2_in <= 1;
						ld_v2 <= 1;
						d2_in <= 0;
						ld_d2 <= 1;
						ld_tag2 <= 1;
						ld_data2 <= 1;
					end
				end 
				else begin
					if(replacement_set[1]) begin	            // way 1
						v1_in <= 1;
						ld_v1 <= 1;
						d1_in <= 0;
						ld_d1 <= 1;
						ld_tag1 <= 1;
						ld_data1 <= 1;
					end else begin                            // way 0
						v0_in <= 1;
						ld_v0 <= 1;
						d0_in <= 0;
						ld_d0 <= 1;
						ld_tag0 <= 1;
						ld_data0 <= 1;
					end
            end
            
            lru_in <= replacement_set;
            ld_lru <= 1;
            
         end
      end
      
		endcase
   end
   
   /* calculate the next state of the cache controller */
   always_comb
   begin
      case (state)
      st_idle:
         
			if (hit)
            // if the line is already in the cache, just gate it to the output
            next_state <= st_idle;
         else if(l2_read || l2_write) begin
					// We only need to write the evicted line back to memory if it is valid and dirty.
					if (v0_out && v1_out && v2_out && v3_out)		
						if (replacement_set[2])
							if(replacement_set[0])
								if(d3_out)								//way3
									next_state <= st_evict;
								else
									next_state <= st_fetch;
							else 										   //way2
								if(d2_out)
									next_state <= st_evict;
								else
									next_state <= st_fetch;
					else 
							if(replacement_set[1])					 //way1
								if(d1_out)
									next_state <= st_evict;
								else
									next_state <= st_fetch;
							else 
								if(d0_out)								//way0
									next_state <= st_evict;
								else
									next_state <= st_fetch;
					
					else
							next_state <= st_fetch;
			end	
			else
				next_state <= st_idle;
		
			

      st_evict:
         // only transition to the fetch state when the evicted cache line has been written
         if (p_resp)
            next_state <= st_fetch;
         else
            next_state <= st_evict;
      
		st_fetch:
         // only transition back to the idle state when the cache line has been successfully read
         if (p_resp)
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
   
endmodule : l2_cache_control