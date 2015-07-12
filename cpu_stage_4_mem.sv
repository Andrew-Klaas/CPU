import lc3b_types::*;

module cpu_stage_4_mem
(
    input logic clk,
    
    /* Pipeline control */
    input   stall_all,
    input   pipeline_ctrl  ctrl_d_in,
    output  pipeline_ctrl  ctrl_d_out,
    
    /* Stage 4 <--> DCache */
    input   logic[15:0]    d_rdata,
    input   logic          d_mem_resp,
    output  logic[15:0]    d_wdata,
    output  logic[15:0]    d_address,
    output  logic          d_read,
    output  logic          d_write,
    output  logic[1:0]     d_byte_enable,
    
    /* Stage 4 <--> Forwarding Unit */
    output  logic[15:0]    mem_out,
    input   logic          mdr_hit,
    input   logic[15:0]    mdr_data,
    input   logic          mar_hit,
    input   logic[15:0]    mar_data,
    
    
    
    /* Backwards data forwarding Stage (mem) --> Stage 3 (exec) */
    output  logic[2:0]     gencc_out_d,
	 
	 output logic ld_cc_from_d,
    output logic mem_instr
);
   
logic data_in_reg_ld;	

   initial
   begin
      ctrl_d_out <= nop;
   end
   
/////////////////
//  WRITING    //
/////////////////	
	
/* MAR & MARMUX */
assign d_address = ctrl_d_in.mar_mux_sel ? ctrl_d_out.mem_out : ctrl_d_in.calc_adrs_out;

/* "MDR" NOTE: combinational, not a register->  byte_write_to*/
always_comb
begin
   
   // allow the forwarding unit to override the incoming data for a store-after-load
   logic[15:0] data_fwd;
   data_fwd = mdr_hit ? mdr_data : ctrl_d_in.alu_out;
   
	if(ctrl_d_in.word_write)
		d_wdata[15:0] = data_fwd[15:0];
	else if(ctrl_d_in.byte_write)
	begin 												// for STB, handled in cache
		d_wdata[15:8] = data_fwd[7:0];
		d_wdata[7:0] = data_fwd[7:0];
	end 
	else 													// TODO: can we get rid of first if statement?
		d_wdata[15:0] = data_fwd[15:0];
end

/* d_byte_enable generator*/
always_comb
begin
	if(ctrl_d_in.word_write)
		d_byte_enable = 2'b11;
	else if((ctrl_d_in.byte_write || ctrl_d_in.byte_read) && ctrl_d_in.calc_adrs_out[0])
		d_byte_enable = 2'b10;
	else if((ctrl_d_in.byte_write || ctrl_d_in.byte_read) && !ctrl_d_in.calc_adrs_out[0])	
		d_byte_enable = 2'b01;
	else 
		d_byte_enable = 2'b11; //2'b00;
end
	
////////////////////////////
// DATA INCOMING from CACHE
////////////////////////////
always_comb
begin
	if(ctrl_d_in.word_read || ctrl_d_in.word_write || ctrl_d_in.byte_read || ctrl_d_in.byte_write)
		mem_instr = 1'b1;
	else 
		mem_instr = 1'b0;
end
 
/* byte_write_from */
/* -> this unit formats output based on whether we are trying to read a word or a byte*/
always_comb
begin
	if( ctrl_d_in.word_read)
		mem_out[15:0] = d_rdata[15:0];
	else if( ctrl_d_in.byte_read && ctrl_d_in.calc_adrs_out[0])
		mem_out[15:0] = {8'h00, d_rdata[15:8]};
	else if( ctrl_d_in.byte_read && !ctrl_d_in.calc_adrs_out
	[0])
	   mem_out[15:0] = {8'h00, d_rdata[7:0]};
	else 
	   mem_out[15:0] = d_rdata[15:0];
end


////////////////////////
// GENCC
///////////////////////

/* TODO: make sure set cc is correct in execute stage */
always_comb
begin
    if (d_rdata[15] == 1'b1)
        gencc_out_d = 3'b100;
    else if (|d_rdata)
        gencc_out_d = 3'b001;
    else
        gencc_out_d = 3'b010;
end


///////////////////////
//  PIPE flip-flops  //
///////////////////////
always_ff @(posedge clk)
begin
	if(~stall_all)
	begin
	    /* Default pass-through behavior */
      ctrl_d_out <= ctrl_d_in;
      /* Contributions from this stage that override pass-through */
		ctrl_d_out.mem_out <= mem_out;
      ctrl_d_out.resolved_target <=    // resolved target address for branch if it is taken
         ctrl_d_in.trap_instr ?
         mem_out :
         ctrl_d_in.calc_adrs_out;
	end
end	

assign d_read = ctrl_d_in.byte_read || ctrl_d_in.word_read;
assign d_write = ctrl_d_in.byte_write || ctrl_d_in.word_write;

always_comb
begin
	if(ctrl_d_in.instruction[15:12] == 4'b0110 || ctrl_d_in.instruction[15:12] == 4'b0010 || ctrl_d_in.instruction[15:12] == 4'b1010 )
		ld_cc_from_d = 1'b1;
	else	
		ld_cc_from_d = 1'b0;
end
   
endmodule : cpu_stage_4_mem
