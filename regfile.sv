import lc3b_types::*;

module regfile
(
    input clk,
    input load,
    input logic [15:0] in,
    input logic [2:0] src_a, src_b, destt,
    output logic [15:0] reg_a, reg_b
);

logic [15:0] data [7:0];

/* Altera device registers are 0 at power on. Specify this
 * so that Modelsim works as expected.
 */
initial
begin
    for (int i = 0; i < $size(data); i++)
    begin
        data[i] = {i[3:0], 12'h000}; //16'b0;   UNDO this after testing
		  //data[i] = 16'b0000000000000000;
		  data[i] = 16'b0000000000000000;
    end
end

always_ff @(posedge clk)
begin
    if (load == 1)
    begin
        data[destt] = in;
    end
end

always_comb
begin
    // include pass-through logic
    reg_a = destt == src_a && load ? in : data[src_a];
    reg_b = destt == src_b && load ? in : data[src_b];
end

endmodule : regfile