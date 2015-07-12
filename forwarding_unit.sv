import lc3b_types::*;

module forwarding_unit
(
   
   input  clk,
   input  stall_all,
   
   /* Forwarding unit <--> Execute Stage */
   input    pipeline_ctrl  ctrl_c_in,     // The forwarding unit sees the same control signals that execute sees
   input    logic[15:0]    alu_fwd,       // ALU output
   output   logic          alu_sr1_hit,   // Goes high when the valid value of the repspective register...
   output   logic          alu_sr2_hit,   // ...is in the forwarding unit, not the register file
   output   logic[15:0]    alu_sr1_data,  // the data value of sr1 if alu_sr1_hit == 1
   output   logic[15:0]    alu_sr2_data,  // the data value of sr1 if alu_sr2_hit == 1
   
   /* Forwarding Unit <--> Memory Stage */
   input    pipeline_ctrl  ctrl_d_in,
   input    logic[15:0]    mem_out,
   output   logic          mdr_hit,
   output   logic[15:0]    mdr_data,
   output   logic          mar_hit,
   output   logic[15:0]    mar_data
);
   logic[15:0]    exe_data_0;
   logic[2:0]     exe_dest_0;
   logic          exe_v_0;
   
   logic[15:0]    exe_data_1;
   logic[2:0]     exe_dest_1;
   logic          exe_v_1;

   logic[15:0]    mem_data;
   logic[2:0]     mem_dest;
   logic          mem_v;
   
   logic          hit_sr1_exe_0;
   logic          hit_sr1_exe_1;
   logic          hit_sr1_mem;
   
   logic          hit_sr2_exe_0;
   logic          hit_sr2_exe_1;
   logic          hit_sr2_mem;
   
   logic          hit_mdr_exe_0;
   logic          hit_mdr_exe_1;
   logic          hit_mdr_mem;
   
   logic          hit_mar_exe_0;
   logic          hit_mar_exe_1;
   logic          hit_mar_mem;
   
   initial
   begin
      exe_data_0 <= 16'h0000;
      exe_data_1 <= 16'h0000;
      mem_data   <= 16'h0000;
      exe_dest_0 <= 3'b000;
      exe_dest_1 <= 3'b000;
      mem_dest   <= 3'b000;
      exe_v_0    <= 1'b0;
      exe_v_1    <= 1'b0;
      mem_v      <= 1'b0;
   end
   
   /* register the results of arithmetic instructions */
   always_ff @(posedge clk)
   begin
      // only set the valid flip flops for ADD, AND, SHF, LEA, and the extended instructions
      if (!stall_all)
      begin
         exe_data_0 <= alu_fwd;
         exe_dest_0 <= ctrl_c_in.dest_reg;
         exe_v_0    <= ctrl_c_in.ld_regfile && !ctrl_c_in.byte_read && !ctrl_c_in.word_read && !ctrl_c_in.br_instr;
         
         exe_data_1 <= exe_data_0;
         exe_dest_1 <= exe_dest_0;
         exe_v_1    <= exe_v_0 && !(ctrl_c_in.dest_reg == exe_dest_0 && ctrl_c_in.ld_regfile);
         // ^ if the same register is written twice in a row, invalidate exe1 and have exe0 source the hit
         
         mem_data <= mem_out;
         mem_dest <= ctrl_d_in.dest_reg;
         mem_v    <= ctrl_d_in.ld_regfile && !ctrl_d_in.trap_instr &&(ctrl_d_in.byte_read || ctrl_d_in.word_read);
      end
   end
   
   /* raise a flag whenever a value from the register file is invalid and the forwarded value should be used */
   
   always_comb begin
      hit_sr1_exe_0 = ctrl_c_in.sr1_reg == exe_dest_0 && exe_v_0;
      hit_sr1_exe_1 = ctrl_c_in.sr1_reg == exe_dest_1 && exe_v_1;
      hit_sr1_mem   = ctrl_c_in.sr1_reg == mem_dest   && mem_v;
      alu_sr1_hit   = hit_sr1_exe_0 || hit_sr1_exe_1 || hit_sr1_mem;
      
      hit_sr2_exe_0 = ctrl_c_in.sr2_reg == exe_dest_0 && exe_v_0;
      hit_sr2_exe_1 = ctrl_c_in.sr2_reg == exe_dest_1 && exe_v_1;
      hit_sr2_mem   = ctrl_c_in.sr2_reg == mem_dest   && mem_v;
      alu_sr2_hit   = hit_sr2_exe_0 || hit_sr2_exe_1 || hit_sr2_mem;
      
      hit_mdr_exe_0 = ctrl_d_in.sr1_reg == exe_dest_0 && exe_v_0;
      hit_mdr_exe_1 = ctrl_d_in.sr1_reg == exe_dest_1 && exe_v_1;
      hit_mdr_mem   = ctrl_d_in.sr1_reg == mem_dest   && mem_v;
      mdr_hit       = (hit_mdr_exe_0 || hit_mdr_exe_1 || hit_mdr_mem)
                    && (ctrl_d_in.byte_write || ctrl_d_in.word_write);
      
      case (ctrl_c_in.mem_adder_mux_sel)
         2'b00: begin
            hit_mar_exe_0 = ctrl_d_in.sr1_reg == exe_dest_0 && exe_v_0;
            hit_mar_exe_1 = ctrl_d_in.sr1_reg == exe_dest_1 && exe_v_1;
            hit_mar_mem   = ctrl_d_in.sr1_reg == mem_dest   && mem_v;
         end
         2'b01: begin
            hit_mar_exe_0 = ctrl_d_in.sr2_reg == exe_dest_0 && exe_v_0;
            hit_mar_exe_1 = ctrl_d_in.sr2_reg == exe_dest_1 && exe_v_1;
            hit_mar_mem   = ctrl_d_in.sr2_reg == mem_dest   && mem_v;
         end
         default: begin
            hit_mar_exe_0 = 1'b0;
            hit_mar_exe_1 = 1'b0;
            hit_mar_mem   = 1'b0;
         end
      endcase
      mar_hit       = (hit_mar_exe_0 || hit_mar_exe_1 || hit_mar_mem)
                    && (ctrl_d_in.byte_read || ctrl_d_in.byte_write || ctrl_d_in.word_read || ctrl_d_in.word_write);
   end
   
   /* Route data to sr1, sr2, and mar for a hit */
   always_comb
   begin
      // SR1
      case ({hit_sr1_exe_0, hit_sr1_exe_1, hit_sr1_mem})
         3'b100:     alu_sr1_data <= exe_data_0;
         3'b010:     alu_sr1_data <= exe_data_1;
         3'b001:     alu_sr1_data <= mem_data;
         3'b101:     alu_sr1_data <= exe_data_0;
         3'b110:     alu_sr1_data <= exe_data_0;
         default:    alu_sr1_data <= 16'hxxxx;
      endcase
      // SR2
      case ({hit_sr2_exe_0, hit_sr2_exe_1, hit_sr2_mem})
         3'b100:     alu_sr2_data <= exe_data_0;
         3'b010:     alu_sr2_data <= exe_data_1;
         3'b001:     alu_sr2_data <= mem_data;
         3'b101:     alu_sr2_data <= exe_data_0;
         3'b110:     alu_sr2_data <= exe_data_0;
         default:    alu_sr2_data <= 16'hxxxx;
      endcase
      // MDR 
      case ({hit_mdr_exe_0, hit_mdr_exe_1, hit_mdr_mem})
         3'b100:     mdr_data <= exe_data_0;
         3'b010:     mdr_data <= exe_data_1;
         3'b001:     mdr_data <= mem_data;
         3'b101:     mdr_data <= exe_data_0;
         3'b110:     mdr_data <= exe_data_0;
         default:    mdr_data <= 16'hxxxx;
      endcase
      // MAR
      case ({hit_mar_exe_0, hit_mar_exe_1, hit_mar_mem})
         3'b100:     mar_data <= exe_data_0;
         3'b010:     mar_data <= exe_data_1;
         3'b001:     mar_data <= mem_data;
         3'b101:     mar_data <= exe_data_0;
         3'b110:     mar_data <= exe_data_0;
         default:    mar_data <= 16'hxxxx;
      endcase
   end
   
endmodule : forwarding_unit
