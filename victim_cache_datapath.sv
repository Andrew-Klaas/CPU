import lc3b_types::*;

module victim_cache_datapath
(
	input logic clk,
	
	input logic[15:0] v_address,			 // input from l2
	input logic[127:0] v_wdata, 			// input from L2
	input logic[127:0] p_rdata,			 //input from physical memory
	
	input logic v_read,
	input logic v_write, 
	input logic victim_write,
	input logic load_plru,      				// should be high on a read hit
	input logic load_plru_sel,
	input logic address_sel,
	
	output logic [127:0] v_rdata, 			// output to l2
	output logic [127:0] p_wdata,				 // output to physical

	
	output logic read_hit,				// hit registered on victim cache read
	output logic valid,               // current active index valid?
	output logic[15:0] p_address
);

typedef struct
{
   logic       		valid;
   logic[15:0] 		tag;            
   logic[127:0] 		data;
 
} victim_entry;


   /* 
    * plru shows which entry was touched LAST.
    * EXAMPLE 1: if we read from predictor_table[2] then the following bits in plru will be updated
    *    plru[6] <-- 0
    *    plru[5] <-- 1
    *    plru[2] <-- 0
    *    The other bits in plru are not touched, they stay the same
    *
    * EXAMPLE 2: if we need to evict an entry in predictor_table and plru == 7'b1001011
    *    plru[6] == 1, so we should an entry somewhere in [0 to 3]
    *    plru[5] == 0, so we should evict an entry somewhere in [2 to 3]
    *    plru[2] == 0, so we should evict [3]
    *    predictor_table[3] will be evicted and since it has been touched...
    *    plru will be changed to 7'b0101111 (only bits 6, 5, and 2 are modified)
    *
    *  |                       plru[6] == 0                        |                       plru[6] == 1                        |
    *  
    *  |        plru[5] == 0         |        plru[5] == 1         |        plru[4] == 0         |        plru[4] == 1         |
    *
    *  | plru[3] == 0 | plru[3] == 1 | plru[2] == 0 | plru[2] == 1 | plru[1] == 0 | plru[1] == 1 | plru[0] == 0 | plru[0] == 1 |
    *  |              |              |              |              |              |              |              |              |
    *  |______________|______________|______________|______________|______________|______________|______________|______________|
    *         [0]            [1]            [2]            [3]            [4]            [5]            [6]            [7]      
    */


logic[6:0]           plru;
victim_entry         victim_table[7:0];

logic write_hit;
//logic flag;
//logic flag2;

 
// signals controlling the read and write ports of the predictor_table

logic[2:0]  read_ix;
logic[2:0]  write_ix;
logic[127:0] victim_data;

initial
begin
      
      plru <= 7'b0000000;
      for (int ix = 0; ix < 8; ix = ix + 1)
      begin
         victim_table[ix].valid           <= 1'b0;
         victim_table[ix].tag             <= 16'h0000;
         victim_table[ix].data            <= 128'h00000000000000000000000000000000;
      end
      
end

// reading
// IF tag match then we need to write data back to l2 cache, victim_data is routed to mux
/* Read port to the victim table. Looks for a tag match  */
   always_comb
   begin
      
      read_hit             <= 1'b0;
      read_ix              <= 3'bxxx;   
		victim_data 			<= 128'h00000000000000000000000000000000;
      for (int ix = 0; ix < 8; ix = ix + 1)
      begin
         if ( (victim_table[ix].tag == v_address) && victim_table[ix].valid && v_read)
         begin
            read_hit             <= 1'b1;
            read_ix              <= ix[2:0];
            victim_data     <= victim_table[ix].data;
         end
							
      end
      
   end   
		
		
// writing				else if (!read_hit)
/* The index of the victim table to write to is chosen as follows:
    *    if there is already an entry for that branch, write to that index
    *    if there is no entry yet, use the plru bits to overwrite an entry */
   always_comb
   begin
      write_ix <= 3'bxxx;
		write_hit <= 1'b0;
		//flag <= 1'b0;
		//flag2<= 1'b0;
      
      // if no entry exists in the table, then use the plru bits to overwrite an entry

		/*
		for (int ix = 0; ix < 8; ix = ix + 1)
		begin
				if ( (victim_table[ix].tag == v_address) && victim_table[ix].valid && v_write)
				begin	
							write_ix              <= ix[2:0];
							write_hit				 <= 1;
				end
						
		end
		*/
		
		
		// TODO: ask about this messy if crap, I had trouble using the for loop
		
		
		if ( (victim_table[0].tag == v_address) && victim_table[0].valid && v_write)
		begin	
							write_ix              <= 3'b000;
							write_hit				 <= 1;
		end
		else if ( (victim_table[1].tag == v_address) && victim_table[1].valid && v_write)
		begin	
							write_ix              <= 3'b001;
							write_hit				 <= 1;
		end
		else if ( (victim_table[2].tag == v_address) && victim_table[2].valid && v_write)
		begin	
							write_ix              <= 3'b010;
							write_hit				 <= 1;
							//flag                  <= 1;
		end
		else if ( (victim_table[3].tag == v_address) && victim_table[3].valid && v_write)
		begin	
							write_ix              <= 3'b011;
							write_hit				 <= 1;
		end
		else if ( (victim_table[4].tag == v_address) && victim_table[4].valid && v_write)
		begin	
							write_ix              <= 3'b100;
							write_hit				 <= 1;
		end
		else if ( (victim_table[5].tag == v_address) && victim_table[5].valid && v_write)
		begin	
							write_ix              <= 3'b101;
							write_hit				 <= 1;
		end
		else if ( (victim_table[6].tag == v_address) && victim_table[6].valid && v_write)
		begin	
							write_ix              <= 3'b110;
							write_hit				 <= 1;
							//flag2 					 <= 1;
		end
		else if ( (victim_table[7].tag == v_address) && victim_table[7].valid && v_write)
		begin	
							write_ix              <= 3'b111;
							write_hit				 <= 1;
		end
		else if(write_hit == 0)
      begin
         if (plru[6])
            if (plru[5])
               if (plru[3])
                  write_ix <= 3'b000;
               else
                  write_ix <= 3'b001;
            else
               if (plru[2])
                  write_ix <= 3'b010;
               else
                  write_ix <= 3'b011;
         else
            if (plru[4])
               if (plru[1])
                  write_ix <= 3'b100;
               else
                  write_ix <= 3'b101;
            else
               if (plru[0])
                  write_ix <= 3'b110; 
               else
                  write_ix <= 3'b111;
      end
	
	end
	
	
	/* Write port to the victim table.
    * Writes occur when a control flow instruction exits the pipeline  */
   always_ff @(posedge clk)
   begin
      
      if (victim_write) // the l2 is trying to write
      begin
         
         // now actually perform the write
         victim_table[write_ix].valid = 1'b1;
         victim_table[write_ix].tag = v_address;
			victim_table[write_ix].data = v_wdata;
               
      end
   end
	
	
	
   /* Update the plru bits.
    * If a write occurs, touch the bits for the index which was written.  
    * If a read occurs but not a write, touch the bits at the index that was read */
   always_ff @(posedge clk)
   begin
      
      logic[2:0] active_ix;
      
      active_ix =  load_plru_sel ? read_ix : write_ix;     // use the read_ix if we have a victim cache hit, else use write
      
      if (load_plru)
      begin
         case (active_ix)
            3'b000:
            begin
               plru[6] = 1'b0;
               plru[5] = 1'b0;
               plru[3] = 1'b0;
            end
            3'b001:
            begin
               plru[6] = 1'b0;
               plru[5] = 1'b0;
               plru[3] = 1'b1;
            end
            3'b010:
            begin
               plru[6] = 1'b0;
               plru[5] = 1'b1;
               plru[2] = 1'b0;
            end
            3'b011:
            begin
               plru[6] = 1'b0;
               plru[5] = 1'b1;
               plru[2] = 1'b1;
            end
            3'b100:
            begin
               plru[6] = 1'b1;
               plru[4] = 1'b0;
               plru[1] = 1'b0;
            end
            3'b101:
            begin
               plru[6] = 1'b1;
               plru[4] = 1'b0;
               plru[1] = 1'b1;
            end
            3'b110:
            begin
               plru[6] = 1'b1;
               plru[4] = 1'b1;
               plru[0] = 1'b0;
            end
            3'b111:
            begin
               plru[6] = 1'b1;
               plru[4] = 1'b1;
               plru[0] = 1'b1;
            end
         endcase
      end
      
   end
	
	/* read data mux */
	assign v_rdata = read_hit ? victim_data : p_rdata; // headed back to l2 cache
	assign p_wdata = victim_table[write_ix].data; // may be problems here, trying to evict data basically
	assign	valid = victim_table[write_ix].valid;
	assign p_address = address_sel ? victim_table[write_ix].tag : v_address;
	



endmodule : victim_cache_datapath