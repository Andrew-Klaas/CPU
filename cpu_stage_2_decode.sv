import lc3b_types::*;

module cpu_stage_2_decode
(
   input    logic 			clk,
   
   /* Pipeline signals */
   input    logic          stall_all,
   output   logic          stall_fetch,
	input    pipeline_ctrl  ctrl_b_in,
   output   pipeline_ctrl  ctrl_b_out,
   
   /* Feedback from the writeback stage into the register file */
   input    logic          ld_regfile_e,
   input    logic[15:0]    write_back_data_e,
   input    logic[15:0]    pc_writeback,
   input    logic[2:0]     dest_e,
	
	/* input to clear the pipe stage*/
	input 	logic 			wipe_mispredict   
);

typedef enum
{
                                         st_TRAP_2, /*  ----->  */ st_TRAP_3,  /* -----> */ st_TRAP_4,  /* -----> */ st_TRAP_5,
//                           opcode == TRAP /|\
//                               and         |
//                     predict_branch == 0   |        opcode == STI
                                          st_normal, /* --------->  */ st_STI_2,
//                      opcode == LDR   /        \                        
//                           or        /          \  opcode == LDI        
//                    opcode == LDB  |/            \|                     
                          st_LD_cooldown,/*  <---  */ st_LDI_2
} state_t;

/* EXPLINATION OF STATES 
 * 
 * st_normal         During this state, the current opcode is decoded and sent downstream. 
 *                   each instruction takes one cycle to decode.
 *
 * st_LD_cooldown    The decode unit enters this state the cycle immediatly after an LDR, LDB, or LDI
 *                   finishes (aka for LDI, after the st_LDI_2).   If the instruction currently being
 *                   decoded is executed in the EXECUTE stage of the pipeline (as opposed to the
 *                   MEMORY stage) AND consumes the register which was written to by the preceeding
 *                   LDR, LDB, or LDI, then a single NOP is inserted in the pipeline to ensure that
 *                   the dependent instruction is executed AFTER the load instruction completes.  If
 *                   there is no dependency, then the next instruction is fetched normally without a NOP.
 *
 * st_LDI_2          An LDI is broken down into two micro-instructions: one to fetch the pointer and the
 *                   next to dereference the pointer.  The decode unit enters the st_LDI_2 state the
 *                   cycle after the first micro-instruction of an LDI is decoded and sent down the pipeline.
 *                   If the decode unit is in st_LDI_2, then it stalls the fetch unit and emits the second
 *                   micro-instruction.
 *
 * st_STI_2          An STI is broken down into two micro-instructions: one to fetch the pointer and the
 *                   next to dereference the pointer.  The decode unit enters the st_STI_2 state the
 *                   cycle after the first micri-instruction of an STI is decoded and sent down the pipeline.
 *                   If the decode unit is in st_STI_2, then it stalls the fetch unit and emitts the second
 *                   micro-instruction.
 *
 * st_TRAP_2..4      If the target address of a branch instruction is not in the branch target buffer, then 
 *                   we insert 4 NOPs into the pipeline: the target address will not be available until the
 *                   final WRITEBACK stage.  If the target is in the BTB, then the branch predictor will 
 *                   raise the predict_branch line high.  The branch predictor is 100% successfull at predicting
 *                   TRAP targets unless self-modifying code is used, so it is safe to assume that: if a TRAP
 *                   is predicted taken (predict_branch == 1) then the target is correctly predicted and the fetch
 *                   unit will fetch from the correct address. */

/* LOCAL REGISTERS */
state_t           state;
logic[2:0]        mem_dest; // the last register which was written by an LDR, LDB, or LDI

/* LOCAL WIRES */
logic[15:0]       imm;

logic [2:0]       sr1_ix;
logic [2:0]       sr2_ix;
logic [2:0]       dest_ix;

logic[15:0]       sr1_data;
logic[15:0]       sr2_data;

pipeline_ctrl     decoded;

initial begin
   state <= st_normal;
   ctrl_b_out <= nop;
end

/* STATE TRANSITION CONTROL */
always_ff @(posedge clk) begin
   
      if (!stall_all) begin
      case (state)
         st_normal:
            case (ctrl_b_in.instruction[15:12]) // opcode
               op_ldi:
                  state <= st_LDI_2;
               op_sti:
                  state <= st_STI_2;
               op_ldr:
                  state <= st_LD_cooldown;
               op_ldb:
                  state <= st_LD_cooldown;
               op_trap:
                  if (ctrl_b_in.predict_branch)
                     state <= st_normal;
                  else
                     state <= st_TRAP_2;
               default:
                  if (state == st_LDI_2)
                     state <= st_LD_cooldown;
                  else
                     state <= st_normal;
            endcase
         st_LD_cooldown: begin
            if (ctrl_b_in.instruction[15:12] == op_ldr ||  ctrl_b_in.instruction[15:12] == op_ldb)
               state <= st_LD_cooldown;
            else
               state <= st_normal;
         end
         st_LDI_2:
            state <= st_LD_cooldown;
         st_STI_2:
            state <= st_normal;
         st_TRAP_2:
            state <= st_TRAP_3;
         st_TRAP_3:
            state <= st_TRAP_4;
         st_TRAP_4:
            state <= st_TRAP_5;
         st_TRAP_5:
            state <= st_normal;
      endcase
   end
   
end

/* EXTEND IMMEDIATE VALUES TO 16-BITS */
calc_immed calc_immed_inst
(
   .instruction(ctrl_b_in.instruction),
   .immediates(imm)
);


/* INSTRUCTION DECODING */
always_comb begin
      
      decoded = ctrl_b_in;
      stall_fetch = 1'b0;
      
      if (wipe_mispredict) begin
         decoded = nop;
      end else begin
         
         // default control signals 
         decoded           = ctrl_b_in;
         
         stall_fetch       = 1'b0;
         
         decoded.sr1_reg   = sr1_ix;
         decoded.sr2_reg   = sr2_ix;
         decoded.dest_reg  = dest_ix;
         decoded.sr1_data  = sr1_data;
         decoded.sr2_data  = sr2_data;
         decoded.imm       = imm;
         
         case (state)
            
            st_LDI_2: begin
               decoded.word_read       = 1'b1;
               decoded.mar_mux_sel     = 1'b1;
               decoded.ld_regfile      = 1'b1;
               decoded.ld_cc           = 1'b1;
            end
            
            st_STI_2: begin
               decoded.word_write      = 1'b1;
               decoded.mar_mux_sel     = 1'b1;
               decoded.alu_sel         = alu_pass;
            end
            
            st_TRAP_2: begin
               decoded                 = nop;
               stall_fetch             = 1'b1;
            end
               
            st_TRAP_3: begin
               decoded                 = nop;
               stall_fetch             = 1'b1;
            end
            
            st_TRAP_4: begin
               decoded                 = nop;
               stall_fetch             = 1'b1;
            end
            
            st_TRAP_5: begin
               decoded                 = nop;
            end
            
            default: begin // st_fetch and st_LD_cooldown
               case (ctrl_b_in.instruction[15:12])
                  
                  // BR
                  op_br: begin
                     if (state == st_LD_cooldown) begin
                        decoded                          = nop;
                        stall_fetch                      = 1'b1;
                     end else begin
                        decoded.mem_adder_mux_sel	      = 2'b10;
                        decoded.write_back_data_sel      = 2'b10;
                        decoded.br_instr				      = 1'b1;
                     end
                  end
               
                  op_add: begin
                     if (state == st_LD_cooldown && (mem_dest == sr1_ix || mem_dest == sr2_ix)) begin
                        decoded                          = nop;
                        stall_fetch                      = 1'b1;
                     end else begin
                        if (ctrl_b_in.instruction[5]) begin
                           // imm5 ADD
                           decoded.write_back_data_sel   = 2'b01;
                           decoded.imm_instr             = 1'b1;
                           decoded.ld_cc                 = 1'b1;
                           decoded.ld_regfile            = 1'b1;
                           decoded.alu_sel               = alu_add;
                        end else begin
                           // 2-register ADD
                           decoded.write_back_data_sel   = 2'b01;
                           decoded.ld_cc                 = 1'b1;
                           decoded.ld_regfile            = 1'b1;
                           decoded.alu_sel               = alu_add;
                        end
                     end
                  end
               
                  op_and: begin
                     if (state == st_LD_cooldown && (mem_dest == sr1_ix || mem_dest == sr2_ix)) begin
                        decoded                          = nop;
                        stall_fetch                      = 1'b1;
                     end else begin
                        if (ctrl_b_in.instruction[5]) begin
                           // imm5 AND
                           decoded.write_back_data_sel   = 2'b01;
                           decoded.imm_instr             = 1'b1;
                           decoded.ld_cc                 = 1'b1;
                           decoded.ld_regfile            = 1'b1;
                           decoded.alu_sel               = alu_and;
                        end else begin
                           // 2-register AND
                           decoded.write_back_data_sel   = 2'b01;
                           decoded.ld_cc                 = 1'b1;
                           decoded.ld_regfile            = 1'b1;
                           decoded.alu_sel               = alu_and;
                        end
                     end
                  end
               
                  op_ext:
						begin
							// TODO
							case (ctrl_b_in.instruction[5:3])
								/* SUB */ 3'b000:
								begin
									decoded.write_back_data_sel  <= 2'b01;
									decoded.ld_cc                <= 1'b1;
									decoded.ld_regfile           <= 1'b1;
									decoded.alu_sel              <= alu_sub;
								end
								
								/* MULT */ 3'b001:
								begin
									decoded.write_back_data_sel  <= 2'b01;
									decoded.ld_cc                <= 1'b1;
									decoded.ld_regfile           <= 1'b1;
									decoded.alu_sel              <= alu_mult;
									//	ADD STALL LOGIC!!
								
								end			
								
								/* DIV */	3'b010:
								begin
									decoded.write_back_data_sel  <= 2'b01;
									decoded.ld_cc                <= 1'b1;
									decoded.ld_regfile           <= 1'b1;
									decoded.alu_sel              <= alu_div;
									//ADD STALL LOGIC!!!
								end
								
								/* XOR */	3'b011:
								begin
									decoded.write_back_data_sel  <= 2'b01;
									decoded.ld_cc                <= 1'b1;
									decoded.ld_regfile           <= 1'b1;
									decoded.alu_sel              <= alu_xor;
								end
								
								/* OR	*/		3'b100:
								begin
									decoded.write_back_data_sel  <= 2'b01;
									decoded.ld_cc                <= 1'b1;
									decoded.ld_regfile           <= 1'b1;
									decoded.alu_sel              <= alu_or;
								end
								
								/* NOR	*/		3'b101:
								begin
									decoded.write_back_data_sel  <= 2'b01;
									decoded.ld_cc                <= 1'b1;
									decoded.ld_regfile           <= 1'b1;
									decoded.alu_sel              <= alu_nor;
								end
								
								/* XNOR	*/		3'b110:
								begin
									decoded.write_back_data_sel  <= 2'b01;
									decoded.ld_cc                <= 1'b1;
									decoded.ld_regfile           <= 1'b1;
									decoded.alu_sel              <= alu_xnor;
								end
								
								/* NAND	*/		3'b111:
								begin
									decoded.write_back_data_sel  <= 2'b01;
									decoded.ld_cc                <= 1'b1;
									decoded.ld_regfile           <= 1'b1;
									decoded.alu_sel              <= alu_nand;
								end
												
							endcase
						end			
						
						
						// JMP 
                  op_jmp: begin
                     if (state == st_LD_cooldown && mem_dest == sr1_ix) begin
                        decoded                          = nop;
                     end else begin
                        decoded.mem_adder_mux_sel        = 2'b00;
                        decoded.write_back_data_sel      = 2'b11;
                        decoded.br_instr                 = 1'b1;
                     end
                  end
                  
                  op_jsr: begin
                     if (ctrl_b_in.instruction[11]) begin
                        // JSR
                        decoded.mem_adder_mux_sel        = 2'b10;
                        decoded.ld_regfile               = 1'b1;
                        decoded.write_back_data_sel      = 2'b10;
                        decoded.br_instr                 = 1'b1;
                     end else begin
                        if (state == st_LD_cooldown && mem_dest == sr1_ix) begin
                           decoded                       = nop;
                           stall_fetch                   = 1'b1;
                        end else begin
                           // JSRR
                           decoded.mem_adder_mux_sel     = 2'b00;
                           decoded.ld_regfile            = 1'b1;
                           decoded.write_back_data_sel   = 2'b10;
                        decoded.br_instr                 = 1'b1;
                        end
                     end
                  end
                  
                  // LDB
                  op_ldb: begin
                     if (state == st_LD_cooldown && mem_dest == sr1_ix) begin
                        decoded                          = nop;
                        stall_fetch                      = 1'b1;
                     end else begin
                        decoded.byte_read                = 1'b1;
                        decoded.ld_cc                    = 1'b1;
                        decoded.ld_regfile               = 1'b1;
                     end
                  end
                  
                  // LDI (stage 1)
                  op_ldi: begin
                     stall_fetch                         = 1'b1;
                     if (state == st_LD_cooldown && mem_dest == sr1_ix) begin
                        decoded                          = nop;
                     end else begin
                        decoded.word_read                = 1'b1;
                     end
                  end
                  
                  // LDR
                  op_ldr: begin
                     if (state == st_LD_cooldown && mem_dest == sr1_ix) begin
                        decoded                          = nop;
                        stall_fetch                      = 1'b1;
                     end else begin
                        decoded.word_read				      = 1'b1;
                        decoded.ld_cc                    = 1'b1;
                        decoded.ld_regfile               = 1'b1;
                     end
                  end
                  
                  // LEA
                  op_lea: begin
                     decoded.mem_adder_mux_sel           = 2'b10;
                     decoded.write_back_data_sel         = 2'b11;
                     decoded.lea_instr                   = 1'b1;
                     decoded.ld_cc                       = 1'b1;
                     decoded.ld_regfile                  = 1'b1;
                  end
                  
                  // NOT
                  op_not: begin
                     if (state == st_LD_cooldown && mem_dest == sr1_ix) begin
                        decoded                          = nop;
                        stall_fetch                      = 1'b1;
                     end else begin
                        decoded.write_back_data_sel      = 2'b01;
                        decoded.ld_cc  				      = 1'b1;
                        decoded.ld_regfile               = 1'b1;
                        decoded.alu_sel                  = alu_not;
                     end
                  end
                  
                  op_shf:
                  begin
                     if (state == st_LD_cooldown && mem_dest == sr1_ix) begin
                        decoded                             = nop;
                        stall_fetch                         = 1'b1;
                     end else begin
                        case (ctrl_b_in.instruction[5:4])
                           /* RSHFA */ 2'b11: begin
                              decoded.imm_instr             = 1'b1;
                              decoded.write_back_data_sel   = 2'b01;
                              decoded.ld_cc                 = 1'b1;
                              decoded.ld_regfile            = 1'b1;
                              decoded.alu_sel				   = alu_sra;
                           end
                           /* RSHFL */ 2'b01: begin
                              decoded.imm_instr             = 1'b1;
                              decoded.write_back_data_sel   = 2'b01;
                              decoded.ld_cc                 = 1'b1;
                              decoded.ld_regfile            = 1'b1;
                              decoded.alu_sel				   = alu_srl;
                           end
                           /* LSHFL */ default: begin
                              decoded.imm_instr             = 1'b1;
                              decoded.write_back_data_sel   = 2'b01;
                              decoded.ld_cc                 = 1'b1;
                              decoded.ld_regfile            = 1'b1;
                              decoded.alu_sel				   = alu_sll;
                           end
                        endcase
                     end
                  end
                  
                  // STB
                  op_stb: begin
                     if (state == st_LD_cooldown && mem_dest == sr1_ix) begin
                        decoded                          = nop;
                        stall_fetch                      = 1'b1;
                     end else begin
                        decoded.byte_write			      = 1'b1;
                        decoded.alu_sel				      = alu_pass;
                        decoded.mem_adder_mux_sel        = 2'b01;
                     end
                  end
                  
                  // STI (stage 1)
                  op_sti: begin
                     stall_fetch                         = 1'b1;
                     if (state == st_LD_cooldown && mem_dest == sr1_ix) begin
                        decoded                          = nop;
                     end else begin
                        decoded.word_read                = 1'b1;
                        decoded.mem_adder_mux_sel        = 2'b01;
                     end
                  end
                  
                  // STR
                  op_str: begin
                     if (state == st_LD_cooldown && mem_dest == sr1_ix) begin
                        decoded                          = nop;
                        stall_fetch                      = 1'b1;
                     end else begin
                        decoded.word_write			      = 1'b1;
                        decoded.alu_sel				      = alu_pass;
                        decoded.mem_adder_mux_sel        = 2'b01;
                     end
                  end
                  
                  // TRAP
                  op_trap: begin
                     if (state == st_LD_cooldown && mem_dest == sr1_ix) begin
                        decoded                          = nop;
                        stall_fetch                      = 1'b1;
                     end else begin
                        decoded.write_back_data_sel		= 2'b10;
                        decoded.mem_adder_mux_sel			= 2'b11;
                        decoded.word_read						= 1'b1;
                        decoded.trap_instr					= 1'b1;
                        decoded.ld_regfile               = 1'b1;
                        stall_fetch                      = !ctrl_b_in.predict_branch;
                     end
                  end
                  
                  default: begin
                     decoded                             = nop;
                  end
                  
               endcase
            end
         endcase
      end
      
end

always_ff @(posedge clk) begin
   if (!stall_all)
      ctrl_b_out <= decoded;
end

/* REGISTER FILE */
regfile regfile_inst
(
   .clk,
   .load(ld_regfile_e),
   .in(write_back_data_e),
   .src_a(sr1_ix),
   .src_b(sr2_ix),
   .destt(dest_e),
   .reg_a(sr1_data),
   .reg_b(sr2_data)
);

/* SR/DR MULTIPLEXERS */
always_comb begin
   
   // sr1 mux
   if (ctrl_b_in.instruction[15:12] == op_str
   ||  ctrl_b_in.instruction[15:12] == op_stb
   ||  ctrl_b_in.instruction[15:12] == op_sti
   ||  state == st_STI_2)
   begin
      sr1_ix <= ctrl_b_in.instruction[11:9];
   end else
      sr1_ix <= ctrl_b_in.instruction[8:6];
   
   // sr2 mux
   if (ctrl_b_in.instruction[15:12] == op_str
   ||  ctrl_b_in.instruction[15:12] == op_stb
   ||  ctrl_b_in.instruction[15:12] == op_sti
   ||  state == st_STI_2)
   begin
      sr2_ix <= ctrl_b_in.instruction[8:6];
   end else
      sr2_ix <= ctrl_b_in.instruction[2:0];
   
   // dest mux
   if (ctrl_b_in.instruction[15:12] == op_jsr
   ||  ctrl_b_in.instruction[15:12] == op_trap)
   begin
      dest_ix <= 3'b111;
   end else begin
      dest_ix <= ctrl_b_in.instruction[11:9];
   end
end

/* MEM_DEST register */
always_ff @(posedge clk) begin
   if (state == st_LDI_2
   ||  ctrl_b_in.instruction[15:12] == op_ldb
   ||  ctrl_b_in.instruction[15:12] == op_ldr)
   begin
      mem_dest <= dest_ix;
   end
end

endmodule : cpu_stage_2_decode
