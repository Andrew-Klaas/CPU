import lc3b_types::*;

module Victim_cache
(

    input logic clk,

	 /* L2_cache_datapath <--> Victim */
	 input logic [15:0] v_address,	// to tags
	 input logic [127:0] v_wdata,		// to data arrays
	 output logic [127:0] v_rdata,   // headed back to L2
	 
	 /*physical memory <--> Victim cache */
	 input logic [127:0] p_rdata, 		/// input from physical
	 output logic [127:0] p_wdata,    // headed to physical
    output logic [15:0] p_address, 	 // headed to physical
					 
	 /* l2_cache <-- Victim cache control */
	 input logic v_read, 				// input from L2
	 input logic v_write,				// input from L2
	 output logic v_resp,   			// output to L2
	 
	 /* Phsical memeory <--> Victim cache control  */   
	 input logic p_resp,  				// input from physical mememory
    output logic p_read,           	// output to physical memory
    output logic p_write				// output to ph ysical memeory
		
);

logic victim_write;
logic read_hit;
logic load_plru;
logic load_plru_sel;
logic valid;
logic address_sel;

victim_cache_datapath victim_cache_datapath_inst
(	
	.clk,
	
	.v_address,			 // input from l2
	.v_wdata, 			// input from L2
	.p_rdata,			 //input from physical memory
	
	.v_read,
	.v_write, 
	.victim_write,				//input from control
 	.load_plru,      				// should be high on a read hit
	.load_plru_sel,
	.address_sel,
	
	.v_rdata, 			// output to l2
	.p_wdata,				 // output to physical
	.read_hit,			// output to control
	.valid,               // current active index valid?
	.p_address

);

victim_cache_control victim_cache_control_inst
(
	.clk,
	
	.v_read, // input from l2
	.v_write, // input from L2
	.p_resp, //input from physical
	.read_hit,
	.valid,
	
	.v_resp, // output to l2
	.p_read, // output to physical
	.p_write, // output to physical
	.victim_write, // output to datapath
	.load_plru,
	.load_plru_sel,
	
	.address_sel
	
);



endmodule : Victim_cache