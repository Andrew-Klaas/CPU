module L_array
(
   input       logic       clk,
   input       logic       WE,
   input       logic[2:0]  ix,
   input       logic       L_in,
   output      logic       L_out
);
   
   /* Decalre storeage */
   logic[7:0]    L;
   
   /* Output Logic.  Independent of the clk signal */
   assign   L_out = L[ix];
   
   initial
   begin
      for (int i = 0; i < 8; i++)
         L[i] <= 1'b0;
   end
   
   /* Input logic.  L_in transferred to L[ix] when WE is high on the rising edge of clk */
   always_ff @(posedge clk)
   begin
      if (WE)
         L[ix] <= L_in;
   end
   
endmodule : L_array
