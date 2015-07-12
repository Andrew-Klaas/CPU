import lc3b_types::*;

module cpu_stage_1_fetch
(
   input    logic       clk,
   
   /* Fetch <--> Backend stall request signals */
   input    logic       stall_fetch,  // either of these two signals will...
   input    logic       stall_all,    // ...stall fetching in the same way
	
	/* Branch specific signals */
	input logic       wipe_mispredict,
	input logic[15:0] branch_nopredict_target, // This is the calcuated address from the execute stage
	
   
   /* Fetch <--> ICache signals */
   input    logic[15:0]    i_rdata,
   input    logic          i_mem_resp,
   output   logic[15:0]    i_address,
   
   /* Fetch --> Decode registered pipelined signals */
   output   pipeline_ctrl  ctrl_a_out,
   
   /* Writeback --> Fetch signals for TRAP */
   input    pipeline_ctrl  ctrl_d_out
   
);
   
   logic[1:0]     pc_mux_sel;
	logic[15:0]    pc_mux_out;
	logic[15:0]    branch_predict_target; // this is the targeta address output from the branch predictor
	logic 			predicted_direction; // this will hook up to the struct for branch_precit -> yes or no
   logic          br_instr;
   logic          br_instr_ctrl;
   logic          prediction_valid;
   
   logic[15:0]    pc;
   logic[15:0]    pc_ctrl; // just a copy of the PC passed down with the control word
   logic          predicted_direction_ctrl;
   logic[15:0]    ir;
   logic[15:0]    pc_inc;
   logic[15:0]    pc_inc_ctrl;
   
   /* Register Starting values honored by the simulator only */
   initial
   begin
      pc <= 16'h0000;
      ir <= 16'h0000;
      pc_ctrl <= 16'h0000;
      pc_inc_ctrl <= 16'h0000;
      br_instr_ctrl <= 1'b0;
      predicted_direction_ctrl  <= 1'b0;
   end
	
   assign pc_inc = pc + 16'h0002;
	
	// PC_MUX SELECT
   always_comb
   begin
      if (ctrl_d_out.trap_instr)
         pc_mux_sel <= 2'b11;
      else if (wipe_mispredict)
         pc_mux_sel <= 2'b10;
      else if (prediction_valid && predicted_direction)
         pc_mux_sel <= 2'b01;
      else
         pc_mux_sel <= 2'b00;
   end
   
	/* PC MUX */
	mux4 #(.width(16)) pc_mux
	(
      .sel(pc_mux_sel),
      .a(pc_inc),
      .b(branch_predict_target),    // this signal is from the branch predictor
      .c(branch_nopredict_target),  // this signal is from the execute stage
      .d(ctrl_d_out.mem_out),       // this signal is from the writeback stage 
      .f(pc_mux_out)
	 );	
	
	/* Instantiate the PC and IR */
   always_ff @(posedge clk)
   begin
      if (!stall_all && !stall_fetch)
         ir <= wipe_mispredict ? 16'h0000 : i_rdata;
      if ((!stall_all && !stall_fetch) || ctrl_d_out.trap_instr)
      begin
         pc <= pc_mux_out;
         pc_ctrl <= pc;
         br_instr_ctrl <= wipe_mispredict ? 1'b0 : br_instr;
         predicted_direction_ctrl <= predicted_direction;
         pc_inc_ctrl <= pc_inc;
      end
   end
   
	/* instantiate the Branch Predictor */
	branch_predictor branch_predictor_inst
	(
      
      .clk,
      
		.pc_in(pc),
      .fetch_in(i_rdata),
      .ctrl_d_out,
      
      .br_instr,
		.prediction_valid,
		.predicted_direction,
		.predicted_target(branch_predict_target)
	);	
	
   /* These signals are calculated in the decode stage */
   always_comb begin
      ctrl_a_out                    = nop;
      ctrl_a_out.pc_mux_out         = pc_inc_ctrl; // changed this away from pc_mux_out to match up with pc_ctrl
      ctrl_a_out.br_instr           = br_instr_ctrl;
      ctrl_a_out.instruction        = ir;
      ctrl_a_out.pc_out             = pc_ctrl;
      ctrl_a_out.predict_branch     = predicted_direction_ctrl;
   end
   
   /* the PC always drives the address input to the ICache */
   assign i_address = pc;
   
endmodule : cpu_stage_1_fetch
