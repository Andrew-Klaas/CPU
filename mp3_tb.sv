import lc3b_types::*;

module mp3_tb;

timeunit 1ns;
timeprecision 1ns;

logic clk;

/* Clock generator */
initial clk = 0;
always #5 clk = ~clk;

/* MP3 <--> Physical Memory */
logic          pmem_resp;
logic[127:0]   pmem_rdata;
logic[127:0]   pmem_wdata;
logic          pmem_read;
logic          pmem_write;
logic[15:0]    pmem_address;

mp3 dut
(
   .clk,
   
   .pmem_resp,
   .pmem_rdata,
   .pmem_wdata,
   .pmem_read,
   .pmem_write,
   .pmem_address
	
);

physical_memory I_phys_inst
(
   .clk,
   
   .read(pmem_read),
   .write(pmem_write),
   .address(pmem_address),
   .wdata(pmem_wdata),
   .resp(pmem_resp),
   .rdata(pmem_rdata)
);

endmodule : mp3_tb
