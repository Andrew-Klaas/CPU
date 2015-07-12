module write_merge
(
   // selects which bytes from mem_wdata will overwrite what bytes from cache_line_in
   input    logic          mem_write,
   input    logic[1:0]     mem_byte_enable,
   input    logic[2:0]     word_sel,
   
   // data to merge
   input    logic[15:0]    mem_wdata,
   input    logic[127:0]   cache_line_in,
   
   // output
   output   logic[127:0]   cache_line_out
);
   
   // I tried using a for() loop to do this, but I couldn't figure out the syntax...   :(
   
   // [7:0]
   assign cache_line_out[7:0] =
      (mem_write && mem_byte_enable[0] && (word_sel == 3'b000)) ? 
      mem_wdata[7:0] :
      cache_line_in[7:0];
   
   // [15:0]
   assign cache_line_out[15:8] =
      (mem_write && mem_byte_enable[1] && (word_sel == 3'b000)) ? 
      mem_wdata[15:8] :
      cache_line_in[15:8];
   
   // [23:16]
   assign cache_line_out[23:16] =
      (mem_write && mem_byte_enable[0] && (word_sel == 3'b001)) ? 
      mem_wdata[7:0] :
      cache_line_in[23:16];
   
   // [31:24]
   assign cache_line_out[31:24] =
      (mem_write && mem_byte_enable[1] && (word_sel == 3'b001)) ? 
      mem_wdata[15:8] :
      cache_line_in[31:24];
   
   // [39:32]
   assign cache_line_out[39:32] =
      (mem_write && mem_byte_enable[0] && (word_sel == 3'b010)) ? 
      mem_wdata[7:0] :
      cache_line_in[39:32];
   
   // [47:40]
   assign cache_line_out[47:40] =
      (mem_write && mem_byte_enable[1] && (word_sel == 3'b010)) ? 
      mem_wdata[15:8] :
      cache_line_in[47:40];
   
   // [55:48]
   assign cache_line_out[55:48] =
      (mem_write && mem_byte_enable[0] && (word_sel == 3'b011)) ? 
      mem_wdata[7:0] :
      cache_line_in[55:48];
   
   // [63:56]
   assign cache_line_out[63:56] =
      (mem_write && mem_byte_enable[1] && (word_sel == 3'b011)) ? 
      mem_wdata[15:8] :
      cache_line_in[63:56];
   
   // [71:64]
   assign cache_line_out[71:64] =
      (mem_write && mem_byte_enable[0] && (word_sel == 3'b100)) ? 
      mem_wdata[7:0] :
      cache_line_in[71:64];
   
   // [79:72]
   assign cache_line_out[79:72] =
      (mem_write && mem_byte_enable[1] && (word_sel == 3'b100)) ? 
      mem_wdata[15:8] :
      cache_line_in[79:72];
   
   // [87:80]
   assign cache_line_out[87:80] =
      (mem_write && mem_byte_enable[0] && (word_sel == 3'b101)) ? 
      mem_wdata[7:0] :
      cache_line_in[87:80];
   
   // [95:88]
   assign cache_line_out[95:88] =
      (mem_write && mem_byte_enable[1] && (word_sel == 3'b101)) ? 
      mem_wdata[15:8] :
      cache_line_in[95:88];
   
   // [103:96]
   assign cache_line_out[103:96] =
      (mem_write && mem_byte_enable[0] && (word_sel == 3'b110)) ? 
      mem_wdata[7:0] :
      cache_line_in[103:96];
   
   // [111:104]
   assign cache_line_out[111:104] =
      (mem_write && mem_byte_enable[1] && (word_sel == 3'b110)) ? 
      mem_wdata[15:8] :
      cache_line_in[111:104];
   
   // [119:112]
   assign cache_line_out[119:112] =
      (mem_write && mem_byte_enable[0] && (word_sel == 3'b111)) ? 
      mem_wdata[7:0] :
      cache_line_in[119:112];
   
   // [127:120]
   assign cache_line_out[127:120] =
      (mem_write && mem_byte_enable[1] && (word_sel == 3'b111)) ? 
      mem_wdata[15:8] :
      cache_line_in[127:120];
   
endmodule : write_merge
