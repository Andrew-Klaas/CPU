import lc3b_types::*;

module mp3
(

   input    logic          clk,
   
   input    logic          pmem_resp,
   input    logic[127:0]   pmem_rdata,
   output   logic[127:0]   pmem_wdata,
   output   logic          pmem_read,
   output   logic          pmem_write,
   output   logic[15:0]    pmem_address
   
);
   
   /*          ---------------------------------------------------------
    *          -                                                       -
    *          -                          CPU                          -
    *          -     I                                           D     -
    *          ---------------------------------------------------------
    *               /|\                                         /|\
    *                |                                           |
    *                |                                           |
    */      logic       cpu_i_resp;                   logic       cpu_d_read;
            logic[15:0] cpu_i_address;                logic       cpu_d_write;
            logic[15:0] cpu_i_rdata;                  logic       cpu_d_resp;
   /*                |                   */           logic[1:0]  cpu_d_byte_enable;
   /*                |                   */           logic[15:0] cpu_d_address;
   /*                |                   */           logic[15:0] cpu_d_rdata;
   /*                |                   */           logic[15:0] cpu_d_wdata;
   /*                |                                           |
    *                |                                           |
    *               \|/                                         \|/
    *          ---------------                           ---------------
    *          -      L1     -                           -      L1     -
    *          - instruction -                           - instruction -
    *          -    cache    -                           -    cache    -
    *          ---------------                           ---------------
    *               /|\                                         /|\
    *                |                                           |
    *                |                                           |
    */      logic          i_arb_read;                logic          d_arb_read;
            logic          i_arb_resp;                logic          d_arb_write;
            logic[15:0]    i_arb_address;             logic          d_arb_resp;
            logic[127:0]   i_arb_rdata;               logic[15:0]    d_arb_address;
   /*                |                    */          logic[127:0]   d_arb_rdata;
   /*                |                    */          logic[127:0]   d_arb_wdata;
   /*                |                                           |
    *                |                                           |
    *               \|/                                         \|/
    *          ---------------------------------------------------------
    *          -                                                       -
    *          -                       Arbiter                         -
    *          -                                                       -
    *          ---------------------------------------------------------
    *                                    /|\
    *                                     |
    *                                     |
    */                        logic          arb_L2_read;
                              logic          arb_L2_write;
                              logic          arb_L2_resp;
                              logic[15:0]    arb_L2_address;
                              logic[127:0]   arb_L2_rdata;
                              logic[127:0]   arb_L2_wdata;
   /*                                     |
    *                                     |
    *                                    \|/
    *                              ---------------
    *                              -             -
    *                              -     L2      -
    *                              -             -
    *                              ---------------
    *                                    /|\
    *                                     |
    *                                     |
	 */	   						logic          L2_bridge_read;
                              logic          L2_bridge_write;
                              logic          L2_bridge_resp;
                              logic[15:0]    L2_bridge_address;
                              logic[127:0]   L2_bridge_rdata;
                              logic[127:0]   L2_bridge_wdata;
   /*                                     |
    *                                     |
    *                                    \|/
    *                              ---------------
    *                              -             -
    *                              -   BRIDGE    -
    *                              -             -
    *                              ---------------
    *                                    /|\
    *                                     |
    *                                     |
    */                        logic          bridge_victim_read;
                              logic          bridge_victim_write;
                              logic          bridge_victim_resp;
                              logic[15:0]    bridge_victim_address;
                              logic[127:0]   bridge_victim_rdata;
                              logic[127:0]   bridge_victim_wdata;
    /*												 |
	 *													 |		
	 * 												\|/
	 *											----------------	
	 *											-	  victim		-		
	 *											-	  cache		-	
	 *											----------------	
    * 												/|\
	 *													 |		
	 * 												 | 
	 *													\|/
	 *										physical memory outputs
	 */
	 
	 

										
										

	 
   /* This level contains the CPU and Caches */
   
   /* CPU (contains the Fetch, Decode, Execute, Mem, and Writeback stages)*/
   cpu cpu_inst
   (
      .clk,
      
      /* CPU <--> ICache */
      .i_rdata(cpu_i_rdata),
      .i_mem_resp(cpu_i_resp),
      .i_address(cpu_i_address),
      
      /* CPU <--> DCache */
      .d_read(cpu_d_read),
      .d_write(cpu_d_write),
      .d_mem_resp(cpu_d_resp),
      .d_byte_enable(cpu_d_byte_enable),
		.d_address(cpu_d_address),
      .d_rdata(cpu_d_rdata),
      .d_wdata(cpu_d_wdata)
   );
	
   /* L1 instruction cache */
   //L1_prefetching_cache icache_inst
	L1_prefetching_cache icache_inst
   (
      .clk,
      
      // ICache <--> CPU
      .mem_address(cpu_i_address),
      .mem_wdata(16'hxxxx),
      .mem_read(1'b1),
      .mem_write(1'b0),
      .mem_byte_enable(2'b11),
      .mem_rdata(cpu_i_rdata),
      .mem_resp(cpu_i_resp),
      
      // ICache <--> L2
      .pmem_rdata(i_arb_rdata),
      .pmem_resp(i_arb_resp),
      .pmem_address(i_arb_address),
      .pmem_read(i_arb_read),
      .pmem_write(),
      .pmem_wdata()
   );
   
   //L1_prefetching_cache dcache_inst
	L1_prefetching_cache dcache_inst
   (
      .clk,
      
      /* DCache <--> CPU */
      .mem_address(cpu_d_address),
      .mem_wdata(cpu_d_wdata),
      .mem_read(cpu_d_read),
      .mem_write(cpu_d_write),
      .mem_byte_enable(cpu_d_byte_enable),
      .mem_rdata(cpu_d_rdata),
      .mem_resp(cpu_d_resp),
      
      /* DCache <--> Arbiter */
      .pmem_rdata(d_arb_rdata),
      .pmem_resp(d_arb_resp),
      .pmem_address(d_arb_address),
      .pmem_wdata(d_arb_wdata),
      .pmem_read(d_arb_read),
      .pmem_write(d_arb_write)
   );
   
   arbiter arbiter_inst
   (
      .clk,
   
      /* L1 instruction cache <--> Arbiter */
      .l1_i_read(i_arb_read),						// when = 1, i cache wants to do a read
      .l1_i_address(i_arb_address),				// choose address from L1 to send through to L2
      .l1_i_rdata(i_arb_rdata),
      .l1_i_resp(i_arb_resp),						// when = 1, i cache data is valid
   
      /* L1 data cache <--> Arbiter */
      .l1_d_write(d_arb_write),					// when = 1, d cache wants to do a write
      .l1_d_read(d_arb_read),						// when = 1, d cache wants to do a read
      .l1_d_address(d_arb_address),
      .l1_d_wdata(d_arb_wdata),
      .l1_d_rdata(d_arb_rdata),
      .l1_d_resp(d_arb_resp),						// when = 1, d cache data is valid
   
      /* Arbiter <--> L2 cache */
      .l2_read(arb_L2_read),						// when = 1, we want to read from L2
      .l2_write(arb_L2_write),					// when = 1, we want to write to L2
      .l2_resp(arb_L2_resp),						//	when = 1, data is valid from L2
      .l2_address(arb_L2_address),				// send the appropriate address to the L2 cache
      .l2_rdata(arb_L2_rdata),					// this is rdata that the L2 cache is sending to us to pass onto L1
      .l2_wdata(arb_L2_wdata) 					// send the appropriate wdata to the L2 cache   );
   );

	l2_cache l2_cache_inst
	(
	 .clk,
	 // Arbiter <--> L2_cache_datapath 
	 .l2_address(arb_L2_address),
	 .l2_wdata(arb_L2_wdata),
	 .l2_rdata(arb_L2_rdata),
	 //victim cache <--> l2_cache_datapath 
	 .p_rdata(L2_bridge_rdata), 
	 .p_wdata(L2_bridge_wdata), 
    .p_address(L2_bridge_address),
	 // Arbiter <-- L2_cache_control 
	 .l2_read(arb_L2_read), 
	 .l2_write(arb_L2_write),
	 .l2_resp(arb_L2_resp),  
	 //victim <--> l2_cache_control
	 .p_resp(L2_bridge_resp),
    .p_read(L2_bridge_read),
    .p_write(L2_bridge_write)
   );
   
   bridge  bridge_inst
   (
      .clk,
   
      /* Victim Cache <--> bridge */
      .upstream_address(L2_bridge_address),
      .upstream_rdata(L2_bridge_rdata),
      .upstream_wdata(L2_bridge_wdata),
      .upstream_read(L2_bridge_read),
      .upstream_write(L2_bridge_write),
      .upstream_resp(L2_bridge_resp),
   
      /* bridge <--> Physical memory */
      .downstream_address(bridge_victim_address),
      .downstream_rdata(bridge_victim_rdata),
      .downstream_wdata(bridge_victim_wdata),
      .downstream_read(bridge_victim_read),
      .downstream_write(bridge_victim_write),
      .downstream_resp(bridge_victim_resp)
   );
   
   Victim_cache Victim_cache_inst
   (

    .clk,

	 .v_address(bridge_victim_address), // to tags
	 .v_wdata(bridge_victim_wdata),     // to data arrays
	 .v_rdata(bridge_victim_rdata),     // headed back to L2
	 
	 .p_rdata(pmem_rdata), 		         // input from physical
	 .p_wdata(pmem_wdata),              // headed to physical
    .p_address(pmem_address), 	      // headed to physical
					 
	 .v_read(bridge_victim_read),       // input from L2
	 .v_write(bridge_victim_write),     // input from L2
	 .v_resp(bridge_victim_resp),       // output to L2
	 
	 .p_resp(pmem_resp),  				   // input from physical mememory
    .p_read(pmem_read),           	   // output to physical memory
    .p_write(pmem_write)				   // output to ph ysical memeory
		
  );
   
endmodule : mp3
