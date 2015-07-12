package lc3b_types;

typedef enum bit [3:0] {
    op_add  = 4'b0001,
    op_and  = 4'b0101,
    op_br   = 4'b0000,
    op_jmp  = 4'b1100,   /* also RET */
    op_jsr  = 4'b0100,   /* also JSRR */
    op_ldb  = 4'b0010,
    op_ldi  = 4'b1010,
    op_ldr  = 4'b0110,
    op_lea  = 4'b1110,
    op_not  = 4'b1001,
    op_ext  = 4'b1000,   /* ext = extended opcode */
    op_shf  = 4'b1101,
    op_stb  = 4'b0011,
    op_sti  = 4'b1011,
    op_str  = 4'b0111,
    op_trap = 4'b1111
} lc3b_opcode;

typedef enum bit [4:0] {
    alu_add,
    alu_and,
    alu_not,
    alu_pass,
    alu_sll,
    alu_srl,
    alu_sra,
	 
	 alu_sub,
	 alu_mult,
	 alu_div,
	 alu_xor,
	 alu_or,
	 alu_nor,
	 alu_xnor,
	 alu_nand
} lc3b_aluop;

typedef struct {
	lc3b_aluop  alu_sel;
	logic       ldi_sti_instr;
	logic       trap_instr;
	logic       shf_instr;
	logic       br_instr;
   logic       lea_instr;
	logic	      imm_instr;
	logic       dest_mux_sel;
	logic			sr1_mux_sel;
	logic			sr2_mux_sel;
	logic       ld_regfile;
	logic       ld_cc;
	logic[1:0]  write_back_data_sel;
	logic       mar_mux_sel;
	logic[1:0]  mem_adder_mux_sel;
	logic       gencc_mux_sel;
	logic       byte_write;
	logic       byte_read;
	logic       word_write;
	logic       word_read;
} ctrl_rom_entry;

typedef struct {
   
   /* Signals from the control ROM */
	lc3b_aluop  alu_sel;
	logic       ldi_sti_instr;
	logic       trap_instr;
	logic       shf_instr;
	logic       br_instr;
   logic       lea_instr;
	logic	      imm_instr;
//	logic       dest_mux_sel;
	logic       ld_regfile;
	logic       ld_cc;
	logic[1:0]  write_back_data_sel;
	logic       mar_mux_sel;
	logic[1:0]  mem_adder_mux_sel;
	logic       gencc_mux_sel;
	logic       byte_write;
	logic       byte_read;
	logic       word_write;
	logic       word_read;
   
   /* Non control ROM signals */
   logic[15:0] instruction;
   logic       predict_branch;
   logic       resolved_direction;
   logic[15:0] resolved_target;
   logic[2:0]  sr1_reg;
   logic[2:0]  sr2_reg;
   logic[2:0]  dest_reg;
   logic[15:0] sr1_data;
   logic[15:0] sr2_data;
   logic[15:0] imm;
   logic[15:0] alu_out;
   logic[15:0] mem_out;
   logic[15:0] calc_adrs_out;
   logic[15:0] pc_out;
   logic[15:0] pc_mux_out;
   
} pipeline_ctrl;

function pipeline_ctrl nop();
   nop = '{alu_add, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
endfunction

endpackage : lc3b_types
