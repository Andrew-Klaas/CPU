/* This level contains the 5 pipeline stages (fetch, decode, execute, mem, and writeback) */

import lc3b_types::*;

module cpu
(
   input    logic    clk,
   
   /* CPU <--> ICache memory signals */
   input    logic[15:0]    i_rdata,       // The ICache places the 16-bit instruction being fetched here
   input    logic          i_mem_resp,    // The ICache drives this 1 only when a hit occurrs (when 'i_rdata' is valid)
   output   logic[15:0]    i_address,     // The CPU places the address of the current instruction being fetched here
   
   /* CPU <--> DCache memory signals */
   input    logic[15:0]    d_rdata,       // During a data read cycle, the DCache places a 16-bit value here
   input    logic          d_mem_resp,    // The DCache drives this 1 only when a hit occurrs for both reads and writes
   output   logic[15:0]    d_wdata,       // During a write cycle, the CPU places the value to be written here and holds it until d_mem_resp == 1
   output   logic          d_read,        // The CPU drives this line 1 to request a memory read from the DCache
   output   logic          d_write,       // The CPU drives this line 1 to request a memory write to the DCache
   output   logic[1:0]     d_byte_enable, /* Used for data byte writes. (STB but not LDB)  See description below:
    ^    d_byte_enable           action
    ^         00                 don't write anything to memory
    ^         01                 write only d_wdata[7:0] to the data cache, the upper byte in memory doesn't change
    ^         10                 write only d_wdata[15:8] to the data cache, the lower byte in memory doesn't change
    ^         11                 normal STR/STI operation.  write the full 16-bit word to memory */
   output   logic[15:0]    d_address
   
);

   pipeline_ctrl     ctrl_ab;
   pipeline_ctrl     ctrl_bc;
   pipeline_ctrl     ctrl_cd;
   pipeline_ctrl     ctrl_de;
	
	pipeline_ctrl		ctrl_e_out;
   
   logic    stall_all;
   logic    stall_fetch;
   
   logic[2:0]     gencc_out_d;
   logic[15:0]    writeback_data_to_b;
   
   /* Execute <--> Forwarding Unit */
   logic[15:0]    alu_fwd;
   logic          alu_sr1_hit;
   logic          alu_sr2_hit;
   logic[15:0]    alu_sr1_data;
   logic[15:0]    alu_sr2_data;
	
   /* Mem <--> Forwarding Unit */
   logic[15:0]    mem_out;
   logic          mdr_hit;
   logic[15:0]    mdr_data;
   logic          mar_hit;
   logic[15:0]    mar_data;
   
	logic mem_instr;
	/* for setting CC with the load signals */
	logic ld_cc_from_d;
	
	/* Branch specific signals */
	logic wipe_mispredict;
	logic[15:0] calc_address_out;
   
   cpu_stage_1_fetch fetch_inst
   (
      .clk,
      
      /* Fetch <-- ICache */
      .i_rdata,       // The ICache places the 16-bit instruction being fetched here
      .i_mem_resp,    // The ICache drives this 1 only when a hit occurrs (when 'i_rdata' is valid)
      .i_address,     // The CPU places the address of the current instruction being fetched here
		
		/* Branch specific signals */
	   .wipe_mispredict,
	   .branch_nopredict_target(calc_address_out), // This is the calcuated address from the execute stage
      
      /* Pipeline Control */
      .stall_all,
      .stall_fetch,
      .ctrl_a_out(ctrl_ab),
      .ctrl_d_out(ctrl_de)
   );
   
   cpu_stage_2_decode decode_inst
   (
      .clk,
      
      /* Pipeline Control */
      .stall_all,
      .stall_fetch,
      .ctrl_b_in(ctrl_ab),
      .ctrl_b_out(ctrl_bc),
      
      /* Feedback from writeback stage */
      .ld_regfile_e(ctrl_de.ld_regfile),
      .write_back_data_e(writeback_data_to_b),
      .pc_writeback(ctrl_de.pc_mux_out),
      .dest_e(ctrl_de.dest_reg),
		
		/* input to clear the pipe stage*/
	   .wipe_mispredict
      
   );
   
   cpu_stage_3_execute execute_inst
   (
      .clk,
      
      /* Pipeline Control */
      .stall_all,
      .ctrl_c_in(ctrl_bc),
      .ctrl_c_out(ctrl_cd),
      
      /* Execute <-- Forwarding unit */
      .alu_fwd,
      .alu_sr1_hit,
      .alu_sr2_hit,
      .alu_sr1_data,
      .alu_sr2_data,
      
      /* Execute <-- Memory Stage */
      .gencc_from_d(gencc_out_d),
		.ld_cc_from_d,
		
		 /* Feedback to Fetch Stage */
       //.branch_enable,
       .wipe_mispredict,
		 .calc_address_out
   );
   
   cpu_stage_4_mem mem_inst
   (
      .clk,
      
      /* Pipeline Control */
      .stall_all,
      .ctrl_d_in(ctrl_cd),
      .ctrl_d_out(ctrl_de),
      
      /* Memory Stage <--> DCache */
      .d_rdata,
      .d_mem_resp,
      .d_wdata,
      .d_address,
      .d_read,
      .d_write,
      .d_byte_enable,
      
      /* Memory Stage --> Execute */
      .gencc_out_d,
		
      /* Memory Stage <--> Forwarding Unit */
      .mem_out,
      .mdr_hit,
      .mdr_data,
      .mar_hit,
      .mar_data,
      
		.mem_instr,
		.ld_cc_from_d
      
   );
   
   cpu_stage_5_writeback wb_inst
   (
      .clk,
      .ctrl_e_in(ctrl_de),
      .writeback_data_to_b
   );
   
   forwarding_unit forwarding_unit_inst
   (
      .clk,
      .stall_all,
      // TODO stall_req --> stall unit
      
      /* Forwarding <--> Execute */
      .alu_fwd,
      .ctrl_c_in(ctrl_bc),
      .alu_sr1_hit,
      .alu_sr2_hit,
      .alu_sr1_data,
      .alu_sr2_data,
      
      /* Forwarding <-- Memory Unit */
      .mem_out,
      .ctrl_d_in(ctrl_cd),
      .mdr_hit,
      .mdr_data,
      .mar_hit,
      .mar_data
   );
   
   cpu_check_stall stall_unit
   (
      .i_mem_resp,
      .d_mem_resp,
      .mem_instr,
		.d_read,
      .stall_all
   );
   
endmodule : cpu
