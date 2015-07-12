import lc3b_types::*;

module cpu_stage_5_writeback
(
   input   logic clk,
   
   /* Pipeline control */
   input   pipeline_ctrl  ctrl_e_in,

   /* Feedback to the register file (decode stage) */
   output  logic[15:0]    writeback_data_to_b
   
);
   
   mux4 write_back_data_mux
   (
      .a(ctrl_e_in.mem_out),
      .b(ctrl_e_in.alu_out),
      .c(ctrl_e_in.pc_mux_out),
      .d(ctrl_e_in.calc_adrs_out),
      .f(writeback_data_to_b),
      .sel(ctrl_e_in.write_back_data_sel)
   );
   
endmodule : cpu_stage_5_writeback
