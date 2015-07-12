import lc3b_types::*;

module l2_cache
(

    input logic clk,

	 /* Arbiter <--> L2_cache_datapath */
	 input logic [15:0] l2_address,
	 input logic [127:0] l2_wdata,
	 output logic [127:0] l2_rdata,
	 
	 /*physical memory <--> l2_cache_datapath */
	 input logic [127:0] p_rdata, 
	 output logic [127:0] p_wdata, 
    output logic [15:0] p_address, 	 
					 
	 /* Arbiter <-- L2_cache_control */
	 input logic l2_read, 
	 input logic l2_write,
	 output logic l2_resp,   
	 
	 /* Phsical memeory <--> l2_cache_control*/   
	 input logic p_resp,   
    output logic p_read,            
    output logic p_write
		
);

logic ld_v0;
logic ld_v1;
logic ld_v2;
logic ld_v3;
	
logic v0_in;
logic v1_in;
logic v2_in;
logic v3_in;
	
logic v0_out;	
logic v1_out;	
logic v2_out;		
logic v3_out;	
	
logic d0_in;   
logic d1_in;
logic d2_in;
logic d3_in;
	
logic ld_d0; 
logic ld_d1;
logic ld_d2;
logic ld_d3;
	
logic d0_out; 	
logic d1_out; 	
logic d2_out; 
logic d3_out; 	
   
logic ld_tag0;  
logic ld_tag1; 
logic ld_tag2;  
logic ld_tag3; 
	
logic ld_data0;
logic ld_data1;
logic ld_data2;
logic ld_data3;

logic [2:0] lru_in;
logic ld_lru;
logic [2:0] lru_out;

logic hit;
logic[3:0] hit_set;

logic [2:0] pmem_mux_sel;
logic write_mux_sel;


l2_cache_datapath l2_cache_datapath_inst
(
	.clk,
	
	/* Arbiter <--> l2_cache_datapath */
	.l2_address,
	.l2_wdata,
	.l2_rdata,
	
	/* L2_cache_datapath <--> physical memeory */
   .p_rdata,
	.p_wdata,
	.p_address,
	
	/* L2_cache_datapath <--> l2_cache_controller */
	.lru_in,   
	.ld_lru, 
	.lru_out, 
	.write_mux_sel,
	
	.ld_v0,
	.ld_v1,
	.ld_v2,
	.ld_v3,	
	.v0_in,
	.v1_in,
	.v2_in,
	.v3_in,	
	.v0_out,	
	.v1_out,	
	.v2_out,		
	.v3_out,		
	.d0_in,   
	.d1_in,
	.d2_in,
	.d3_in,	
	.ld_d0, 
	.ld_d1,
	.ld_d2,
	.ld_d3,	
	.d0_out, 	
	.d1_out, 	
	.d2_out, 
   .d3_out, 	  
	.ld_tag0,  
	.ld_tag1, 
   .ld_tag2,  
	.ld_tag3,	
	.ld_data0,
	.ld_data1,
	.ld_data2,
	.ld_data3,
	.pmem_mux_sel,
	
	.hit,
	.hit_set
);

l2_cache_control l2_cache_control_inst
(
    .clk,
	
	/* Arbiter <--> l2_cache_control */
	.l2_read,
	.l2_write,
	.l2_resp,
	
	/* L2_cache_control <--> physical memory */
	.p_resp,
	.p_read,
	.p_write,
	
	/* l2_cache_control <--> l2_cache_datapath*/
	.lru_in,   
	.ld_lru, 
	.lru_out, 
	.write_mux_sel,
	
	.ld_v0,
	.ld_v1,
	.ld_v2,
	.ld_v3,	
	.v0_in,
	.v1_in,
	.v2_in,
	.v3_in,	
	.v0_out,	
	.v1_out,	
	.v2_out,		
	.v3_out,		
	.d0_in,   
	.d1_in,
	.d2_in,
	.d3_in,	
	.ld_d0, 
	.ld_d1,
	.ld_d2,
	.ld_d3,	
	.d0_out, 	
	.d1_out, 	
	.d2_out, 
   .d3_out, 	  
	.ld_tag0,  
	.ld_tag1, 
   .ld_tag2,  
	.ld_tag3,	
	.ld_data0,
	.ld_data1,
	.ld_data2,
	.ld_data3,
	  
	.pmem_mux_sel,
	
	.hit,
	.hit_set
);

endmodule : l2_cache