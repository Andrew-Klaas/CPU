import lc3b_types::*;

module calc_immed

(

    input logic [15:0] instruction,

    output logic [15:0] immediates

);

always_comb

begin

	// AND & ADD immed, immed5
    if ((instruction[15:12] == 4'b0001 || instruction[15:12] == 4'b0101) && instruction[5] == 1)
			immediates = $signed(instruction[4:0]);
	 
	 // BR & LEA immed, offset9
	 else if (instruction[15:12] == 4'b0000 || instruction[15:12] == 4'b1110)
		immediates = $signed( {instruction[8:0],1'b0} );
	 
	 // JSR, offset11
	 else if (instruction[15:12] == 4'b0100 && instruction[11] == 1)
		immediates = $signed({instruction[10:0], 1'b0});
	 
	 //  STI, STR, LDI, LDR, offset6 shifted left
	 else if ( instruction[15:12] == 4'b1011 || instruction[15:12] == 4'b0111 || instruction[15:12] == 4'b1010 || instruction[15:12] == 4'b0110)
		immediates = $signed({instruction[5:0],1'b0});
		
	 // LDB, STB offset 6
	 else if (instruction[15:12] == 4'b0010 || instruction[15:12] == 4'b0011)
	   immediates = $signed(instruction[5:0]);
	 
	 // TRAP, trapvect8
	 else if (instruction[15:12] == 4'b1111)
		immediates = $unsigned({instruction[7:0], 1'b0});
	 
	 // SHF, immed4
	 else if (instruction[15:12] == 4'b1101)
			immediates = $unsigned(instruction[3:0]);
	 
	 else
			immediates[15:0] = 16'b0000000000000000;

end

endmodule : calc_immed