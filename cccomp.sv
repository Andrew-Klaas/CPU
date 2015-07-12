import lc3b_types::*;

module cccomp 
(
  input [2:0] in,
  input [2:0] nzp, 
  output logic branch_enable
);

always_comb

begin
	if ( in[2] && nzp[2])
		branch_enable <= in[2];
	else if ( in[1] && nzp[1])
		branch_enable <= in[1];	
	else if ( in[0] && nzp[0])
		branch_enable <= in[0];
	else	
		branch_enable <= 1'b0;
end

endmodule : cccomp
