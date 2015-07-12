import lc3b_types::*;

module alu
(
    input lc3b_aluop aluop,
    input logic [15:0] a, b,
    output logic [15:0] f
);

always_comb
begin
    case (aluop)
        alu_add: f = a + b;
        alu_and: f = a & b;
        alu_not: f = ~a;
        alu_pass: f = a;
        alu_sll: f = a << b;
        alu_srl: f = a >> b;
        alu_sra: f = $signed(a) >>> b;
		  
		  alu_sub: f = a - b;
		  alu_mult: f = a*b;
		  alu_div: f <= 16'hxxxx; //a+b;//a/b;
		  alu_xor: f = a ^ b;
		  alu_or: f = a | b;
		  alu_nor: f = ~(a | b);
		  alu_xnor: f = ~(a ^ b);
		  alu_nand: f = ~(a & b);
        default: $display("Unknown aluop");
    endcase
end

endmodule : alu