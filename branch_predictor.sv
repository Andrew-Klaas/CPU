import lc3b_types::*;

module	branch_predictor 
(
      
      input logic clk,
      
		input logic[15:0] pc_in,
      input logic[15:0] fetch_in, // this is the INPUT to IR from the memory BEFORE it is latched
		
      input pipeline_ctrl  ctrl_d_out,
      
      output logic         br_instr,
      output logic         prediction_valid,
		output logic         predicted_direction,
		output logic[15:0]   predicted_target
);	

typedef struct
{
   logic       valid;
   logic[15:0] tag;             // the PC at which there is a BR, JMP, JSR, or TRAP (note JSRR is included with JSR & RET is not included)
   logic[15:0] target;
   logic[1:0]  bimodal_counter; // high bit specifies S/W' low bit specifies T/N'.  Convinently, these are in grey code order.
   /*     Value      Meaning
    *      10           Strongly Not Taken
    *      00           Weakly Not Taken
    *      01           Weakly Taken
    *      11           Strongly Taken */
} predictor_entry;

   /* Up to 8 branches in the program can have their targets and histories
    * "cached" in the predictor.  When no more space is available, a psudo-LRU
    * policy is used to evict on of the 8 entries 
    *
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
   
   // registers 
   logic[6:0]              plru;
   predictor_entry         predictor_table[7:0];
   
   // signals controlling the read and write ports of the predictor_table
   logic       read_hit;
   logic[2:0]  read_ix;
   logic       write_hit;
   logic[2:0]  write_ix;
   
   /* Altera registers are all zero at power up.  Mimic this in simulator */
   initial
   begin
      
      plru <= 7'b0000000;
      
      for (int ix = 0; ix < 8; ix = ix + 1)
      begin
         predictor_table[ix].valid           <= 1'b0;
         predictor_table[ix].tag             <= 16'h0000;
         predictor_table[ix].target          <= 16'h0000;
         predictor_table[ix].bimodal_counter <= 2'b00;
      end
      
   end
   
   /* Read port to the predictor table. Looks for a tag match (tag ~ pc_out) */
   always_comb
   begin
      
      read_hit             <= 1'b0;
      read_ix              <= 3'bxxx;
      predicted_target     <= 16'hxxxx;
      predicted_direction  <= 1'b0;
      
      for (int ix = 0; ix < 8; ix = ix + 1)
      begin
         if (predictor_table[ix].tag == pc_in && predictor_table[ix].valid)
         begin
            read_hit             <= 1'b1;
            read_ix              <= ix[2:0];
            predicted_target     <= predictor_table[ix].target;
            predicted_direction  <= predictor_table[ix].bimodal_counter[0]; // ignore weak/strong
         end
      end
      
   end
   
   /* The index of the predictor table to write to is chosen as follows:
    *    if there is already an entry for that branch, write to that index
    *    if there is no entry yet, use the plru bits to overwrite an entry */
   always_comb
   begin
      
      write_hit = 1'b0;
      write_ix = 3'bxxx;
      
      // look for a pre-existing entry in the table
      for (int ix = 0; ix < 8; ix = ix + 1)
      begin
         if ((predictor_table[ix].tag == ctrl_d_out.pc_out) && predictor_table[ix].valid)
         begin
            write_hit = 1'b1;
            write_ix = ix[2:0];
         end
      end
      
      // if no entry exists in the table, then use the plru bits to overwrite an entry
      if (!write_hit)
      begin
         if (plru[6])
            if (plru[5])
               if (plru[3])
                  write_ix = 3'b000;
               else
                  write_ix = 3'b001;
            else
               if (plru[2])
                  write_ix = 3'b010;
               else
                  write_ix <= 3'b011;
         else
            if (plru[4])
               if (plru[1])
                  write_ix = 3'b100;
               else
                  write_ix = 3'b101;
            else
               if (plru[0])
                  write_ix = 3'b110;
               else
                  write_ix = 3'b111;
      end
      
   end
   
   /* Write port to the predictor table.
    * Writes occur when a control flow instruction exits the pipeline  */
   always_ff @(posedge clk)
   begin
      
      if (ctrl_d_out.br_instr) // write enable is active only for BR, TRAP, JMP, JSR, and JSRR
      begin
         
         // now actually perform the write
         predictor_table[write_ix].valid = 1'b1;
         predictor_table[write_ix].tag = ctrl_d_out.pc_out;
         if (!write_hit)
            predictor_table[write_ix].target = ctrl_d_out.resolved_target;
         
         case (predictor_table[write_ix].bimodal_counter)
            2'b 10: /* Strongly Not Taken */    predictor_table[write_ix].bimodal_counter    =   ctrl_d_out.resolved_direction ? 2'b00 : 2'b10;
            2'b 00: /* Weakly Not Taken */      predictor_table[write_ix].bimodal_counter    =   ctrl_d_out.resolved_direction ? 2'b01 : 2'b10;
            2'b 01: /* Weakly taken */          predictor_table[write_ix].bimodal_counter    =   ctrl_d_out.resolved_direction ? 2'b11 : 2'b00;
            2'b 11: /* Strongly Taken */        predictor_table[write_ix].bimodal_counter    =   ctrl_d_out.resolved_direction ? 2'b11 : 2'b01;
         endcase
         
      end
   end
   
   assign br_instr = 
       (fetch_in[15:12] == op_br)
   ||  (fetch_in[15:12] == op_jmp)
   ||  (fetch_in[15:12] == op_jsr)
   ||  (fetch_in[15:12] == op_trap);
   
   assign prediction_valid  = read_hit && br_instr;
   
   /* Update the plru bits.
    * If a write occurs, touch the bits for the index which was written.  
    * If a read occurs but not a write, touch the bits at the index that was read */
   always_ff @(posedge clk)
   begin
      
      logic[2:0] active_ix;
      
      active_ix = ctrl_d_out.br_instr ? write_ix : read_ix;
      
      if (ctrl_d_out.br_instr || prediction_valid)
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
    
    
endmodule : branch_predictor
