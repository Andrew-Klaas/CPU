import lc3b_types::*;

module cpu_stage_3_execute
(
    input   logic clk,
    
    /* Pipeline Control */
    input   logic stall_all,
    input   pipeline_ctrl  ctrl_c_in,
    output  pipeline_ctrl  ctrl_c_out,
    
    /* Forwarding */
    input   logic       alu_sr1_hit,
    input   logic       alu_sr2_hit,
    input   logic[15:0] alu_sr1_data,
    input   logic[15:0] alu_sr2_data,
    output  logic[15:0] alu_fwd,
    
    /* Feedback from Memory Stage (D) */
    input   logic [2:0] gencc_from_d,
	 input   logic ld_cc_from_d,
    
    /* Feedback to Fetch Stage */
    output  logic wipe_mispredict,
	 output  logic [15:0] calc_address_out
);

logic branch_enable;
logic [15:0] mem_adder_mux_out;
logic [15:0] baser_mux_out;

logic [2:0] gencc_out;
logic [2:0] cc_out;
logic [2:0] gencc_out_final;

logic [15:0] alu_out;
logic gencc_mux_sel_internal;

logic [15:0] fwd_sr1_mux_out;
logic [15:0] fwd_sr2_mux_out;

logic [15:0] quotient;

initial
begin
   ctrl_c_out        <= nop;
   cc_out            <= 3'b000;
end

////////////////
// Forwarding //
////////////////

/* If the forwarding unit suggests that it has a more recent value for a 
 * register value, then use it. */
assign fwd_sr1_mux_out = alu_sr1_hit ? alu_sr1_data : ctrl_c_in.sr1_data;
assign fwd_sr2_mux_out = alu_sr2_hit ? alu_sr2_data : ctrl_c_in.sr2_data;

always_comb
begin
   if (ctrl_c_in.lea_instr)
      // for LEA, the value written to a register is calculated using the adress adder
      alu_fwd <= calc_address_out;
   else if (ctrl_c_in.instruction[15:12] == op_trap || ctrl_c_in.instruction[15:12] == op_jsr)
      // for JSR, JSRR, and TRAP instructions, a return address is stored in R7
      alu_fwd <= ctrl_c_in.pc_mux_out;
   else
      // most common case.  Arithmetic instructions use the ALU to generate a value to write to the registers
      alu_fwd <= alu_out;
end

//////////////////////
//    ALU Unit  	   //
//////////////////////

alu alu_inst
(
	 .aluop(ctrl_c_in.alu_sel),
    .a(fwd_sr1_mux_out),
	 .b(ctrl_c_in.imm_instr ?        // If the instruction uses an immediate operand
         ctrl_c_in.imm :            // Then use it as sr1
         fwd_sr2_mux_out),          // otherwise use a register
    .f(alu_out)
);


/*
divider divider
(
	.clk,
	.N(fwd_sr1_mux_out),
	.D(fwd_sr2_mux_out),
	.should_divide((ctrl_c_in.alu_sel == alu_div)),
	.quotient,
	.stall(stall_pipe)
);
*/


////////////////////////////////////////////////////////////////////////
// MEM_ADDR units aka: the adder used for calculating memory locations
////////////////////////////////////////////////////////////////////////

/* NOTE: This is the Mem_adder adder */
// Mem_adder
always_comb
begin
   if ((ctrl_c_in.instruction[15:12] == op_br) && ctrl_c_in.predict_branch && !branch_enable)
      // if a branch is predicted to be taken but is not, then load the original PC + 2
      calc_address_out <= ctrl_c_in.pc_mux_out;
   else
      // otherwise, perform normal address calculation
      calc_address_out  <= ctrl_c_in.imm + mem_adder_mux_out;	
end
   
mux4 #(.width(16)) mem_adder_mux 
(
	.sel(ctrl_c_in.mem_adder_mux_sel),
	.a(fwd_sr1_mux_out),
	.b(fwd_sr2_mux_out),
	.c(ctrl_c_in.pc_mux_out),
	.d(16'h0000),
	.f(mem_adder_mux_out)
);	
	
///////////////////////
// CC LOGIC	        //
//////////////////////

/* GENCC*/
always_comb
begin
    if (alu_out[15] == 1'b1)
        gencc_out = 3'b100;
    else if (|alu_out) 
        gencc_out = 3'b001;
    else
        gencc_out = 3'b010;
end


// you can write this as: assign gencc_mux_sel_internal = ~ctrl_c_in.ld_cc;
always_comb
begin
	if (ctrl_c_in.ld_cc == 1'b1)
		gencc_mux_sel_internal = 1'b0;
	else
		gencc_mux_sel_internal = 1'b1;
end



/*gencc_mux*/
assign gencc_out_final = gencc_mux_sel_internal ? gencc_from_d : gencc_out;
/*ctrl_c_in.gencc_mux_sel*/

/* CC */
always_ff @(posedge clk) // gencc and cc
begin
   if (ctrl_c_in.ld_cc || ld_cc_from_d )
		cc_out <= gencc_out_final;
end

// used for branch enable
cccomp cccomp_inst
(
  .in(cc_out),
  .nzp(ctrl_c_in.instruction[11:9]), 
  .branch_enable
);

////////////////////
//  STALL LOGIC  //
////////////////////
assign wipe_mispredict =
      ((ctrl_c_in.predict_branch ^ branch_enable) && ctrl_c_in.br_instr)      // mispredicted BR
   || (ctrl_c_in.instruction[15:12] == 4'b1100 && !ctrl_c_in.predict_branch)  // mispredicted JMP or RET
   || (ctrl_c_in.instruction[15:12] == 4'b0100 && !ctrl_c_in.predict_branch); // mispredicted JSR or JSRR

///////////////////////
//  PIPE flip-flops  //
///////////////////////
always_ff @(posedge clk)
begin
	if(~stall_all)
	begin
      /* Default pass-through behavior */
      ctrl_c_out <= ctrl_c_in;
      /* Contributions from execute override pass-through */
      ctrl_c_out.alu_out <= alu_out;
		ctrl_c_out.calc_adrs_out <= calc_address_out;
      ctrl_c_out.resolved_direction  <= branch_enable && ctrl_c_in.br_instr;
	end

end	

endmodule : cpu_stage_3_execute
