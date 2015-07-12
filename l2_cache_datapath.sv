import lc3b_types::*;

module l2_cache_datapath
(

   input logic clk,
	
	/* Arbiter <--> l2_cache_datapath */
	input logic[15:0] l2_address,
	input logic[127:0] l2_wdata,
	output logic[127:0] l2_rdata,
	
	/* L2_cache_datapath <--> physical memeory */
   input logic [127:0] p_rdata,
	output logic [127:0] p_wdata,
	output logic[15:0] p_address,
	
	/* L2_cache_datapath <--> l2_cache_controller */
	input logic[2:0] lru_in,   
	input logic ld_lru, 
	input logic write_mux_sel,
	output logic[2:0] lru_out, 
	
	input logic ld_v0,
	input logic ld_v1,
	input logic ld_v2,
	input logic ld_v3,
	
	input logic v0_in,
	input logic v1_in,
	input logic v2_in,
	input logic v3_in,
	
	output logic v0_out,	
	output logic v1_out,	
	output logic v2_out,		
	output logic v3_out,	
	
	input logic d0_in,   
	input logic d1_in,
	input logic d2_in,
	input logic d3_in,
	
	input logic ld_d0, 
	input logic ld_d1,
	input logic ld_d2,
	input logic ld_d3,
	
	output logic d0_out, 	
	output logic d1_out, 	
	output logic d2_out, 
   output logic d3_out, 	
   
	input logic ld_tag0,  
	input logic ld_tag1, 
   input logic ld_tag2,  
	input logic ld_tag3, 
	
	input logic ld_data0,
	input logic ld_data1,
	input logic ld_data2,
	input logic ld_data3,
	 
	input logic [2:0] pmem_mux_sel,
	
	output logic hit,
	output logic[3:0] hit_set
);

logic [6:0] Tag0_out;
logic [6:0] Tag1_out;
logic [6:0] Tag2_out;
logic [6:0] Tag3_out;

logic [127:0] Data0_out;
logic [127:0] Data1_out;
logic [127:0] Data2_out;
logic [127:0] Data3_out;

logic comp0_out;
logic comp1_out;
logic comp2_out;
logic comp3_out;

logic [3:0] pmem_mux_out;

logic [1:0] waymux_sel;

logic  [127:0] write_mux_out;

logic [2:0] replacement_set;



/* Breakdown of memory address */
/*************************************
15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0
|TAG   | INDEX  | OFFSET6 |
************************************/


assign write_mux_out = write_mux_sel ? l2_wdata : p_rdata;





/********************************************
               Cache Arrays
 *******************************************/

array_32 #(.width(3)) LRU_array
(
	.clk,
   .write(ld_lru),
   .index(l2_address[8:4]),   
   .datain(lru_in),

   .dataout(lru_out)
);





/*************************************
				WAY 0
*************************************/
array_32 #(.width(1)) Valid0_array_32 
(
	.clk,
   .write(ld_v0),
   .index(l2_address[8:4]),   
   .datain(v0_in),

   .dataout(v0_out)
);
array_32 #(.width(1)) Dirty0_array_32 
(
	.clk,
   .write(ld_d0),
   .index(l2_address[8:4]),    
   .datain(d0_in),

   .dataout(d0_out)
);
array_32 #(.width(7)) Tag0_array_32 
(
	.clk,
   .write(ld_tag0),
   .index(l2_address[8:4]),  
   .datain(l2_address[15:9]),        

   .dataout(Tag0_out)
);
array_32 #(.width(128)) Data0_array_32 
(
	.clk,
   .write(ld_data0),
   .index(l2_address[8:4]),   
   .datain(write_mux_out),

   .dataout(Data0_out)
);





/*************************************
			WAY 1
*************************************/
array_32 #(.width(1)) Valid1_array_32 
(
	.clk,
   .write(ld_v1),
   .index(l2_address[8:4]),   
   .datain(v1_in),

   .dataout(v1_out)
);
array_32 #(.width(1)) Dirty1_array_32 
(
	.clk,
   .write(ld_d1),
   .index(l2_address[8:4]),    
   .datain(d1_in),

   .dataout(d1_out)
);
array_32 #(.width(7)) Tag1_array_32 
(
	.clk,
   .write(ld_tag1),
   .index(l2_address[8:4]),  
   .datain(l2_address[15:9]),        

   .dataout(Tag1_out)
);
array_32 #(.width(128)) Data1_array_32 
(
	.clk,
   .write(ld_data1),
   .index(l2_address[8:4]),    
   .datain(write_mux_out),

   .dataout(Data1_out)
);




/*************************************
					WAY 2
*************************************/
array_32 #(.width(1)) Valid2_array_32 
(
	.clk,
   .write(ld_v2),
   .index(l2_address[8:4]),   
   .datain(v2_in),

   .dataout(v2_out)
);
array_32 #(.width(1)) Dirty2_array_32 
(
	.clk,
   .write(ld_d2),
   .index(l2_address[8:4]),    
   .datain(d2_in),

   .dataout(d2_out)
);
array_32 #(.width(7)) Tag2_array_32 
(
	.clk,
   .write(ld_tag2),
   .index(l2_address[8:4]),  
   .datain(l2_address[15:9]),        

   .dataout(Tag2_out)
);
array_32 #(.width(128)) Data2_array_32 
(
	.clk,
   .write(ld_data2),
   .index(l2_address[8:4]),    
   .datain(write_mux_out),

   .dataout(Data2_out)
);



/*************************************
					WAY 3
************************************/
array_32 #(.width(1)) Valid3_array_32 
(
	.clk,
   .write(ld_v3),
   .index(l2_address[8:4]),   
   .datain(v3_in),

   .dataout(v3_out)
);
array_32 #(.width(1)) Dirty3_array_32 
(
	.clk,
   .write(ld_d3),
   .index(l2_address[8:4]),    
   .datain(d3_in),

   .dataout(d3_out)
);
array_32 #(.width(7)) Tag3_array_32 
(
	.clk,
   .write(ld_tag3),
   .index(l2_address[8:4]),  
   .datain(l2_address[15:9]),      

   .dataout(Tag3_out)
);
array_32 #(.width(128)) Data3_array_32 
(
	.clk,
   .write(ld_data3),
   .index(l2_address[8:4]),    
   .datain(write_mux_out),

   .dataout(Data3_out)
);





/********************************************
         array_32 output Combinational
 *******************************************/
always_comb
begin
    /* comparator 0 */
	if( l2_address[15:9] == Tag0_out)
		comp0_out = 1;
	else 
		comp0_out = 0;

	/* comparator 1 */
	if( l2_address[15:9] == Tag1_out)
		comp1_out = 1;
	else 
		comp1_out = 0;

	/* comparator 2 */
	if( l2_address[15:9] == Tag2_out)
		comp2_out = 1;
	else 
		comp2_out = 0;

	/* comparator 3 */
	if( l2_address[15:9] == Tag3_out)
		comp3_out = 1;
	else 
		comp3_out = 0;
end


/* hit detection */
assign hit = (v0_out && comp0_out) || ( v1_out && comp1_out) || (v2_out && comp2_out) || (v3_out && comp3_out);

always_comb
begin


		case(lru_out)
				3'b000: replacement_set = 3'b101;
				3'b001: replacement_set = 3'b100;
				3'b010: replacement_set = 3'b111;
				3'b011: replacement_set = 3'b110;
				3'b100: replacement_set = 3'b010;
				3'b101: replacement_set = 3'b011;
				3'b110: replacement_set = 3'b000;
				3'b111: replacement_set = 3'b001;			
       endcase
	
	if( v0_out && comp0_out ) begin
	   waymux_sel = 2'b00;
	end
	else if(  v1_out && comp1_out ) begin
		waymux_sel = 2'b01;
	end
	else if ( v2_out && comp2_out ) begin
		waymux_sel = 2'b10;
	end
	else if ( v3_out && comp3_out ) begin
		waymux_sel = 2'b11;
	end
	else begin
		if(replacement_set[2]) begin
			if(replacement_set[0] == 1'b1) begin
				waymux_sel = 2'b11; 

			end
			else begin
				waymux_sel = 2'b10;

			end
		end
		else begin
			if(replacement_set[1])
				waymux_sel = 2'b01;
			else
				waymux_sel = 2'b00;
		end
	end
		
	hit_set[0] = v0_out && comp0_out;
	hit_set[1] = v1_out && comp1_out;
	hit_set[2] = v2_out && comp2_out;
	hit_set[3] = v3_out && comp3_out;
end
 
mux4 #(.width(128)) waymux
(
	.sel(waymux_sel),
	.a(Data0_out),
	.b(Data1_out),
	.c(Data2_out),
	.d(Data3_out),
	.f(p_wdata)
);

/****************************************
    Sending Address to physical memory
****************************************/

mux8 #(.width(16)) pmem_mux
(
    .sel(pmem_mux_sel),  
    
	 .a({Tag0_out, l2_address[8:0]}),
    .b({Tag1_out, l2_address[8:0]}),
	 .c({Tag2_out, l2_address[8:0]}),
	 .d({Tag3_out, l2_address[8:0]}),
	 .e(l2_address),
    .f(16'hxxxx),
	 .g(16'hxxxx),
	 .h(16'hxxxx),
	 
	 .out(p_address)
); 

//assign p_address = pmem_mux_out;

assign l2_rdata = p_wdata; 
 
endmodule : l2_cache_datapath