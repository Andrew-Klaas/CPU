import lc3b_types::*;

module arbiter
(

   input    logic    		clk,								// tick tock
   
   /* L1 instruction cache <--> Arbiter */
	input		logic				l1_i_read,						// when = 1, i cache wants to do a read
	input		logic[15:0]		l1_i_address,					// choose address from L1 to send through to L2
   output   logic[127:0]   l1_i_rdata,
	output 	logic				l1_i_resp,						// when = 1, i cache data is valid
   
   /* L1 data cache <--> Arbiter */
	input		logic				l1_d_write,						// when = 1, d cache wants to do a write
	input		logic 			l1_d_read,						// when = 1, d cache wants to do a read
	input		logic[15:0]		l1_d_address,
	input		logic[127:0]	l1_d_wdata,
   output   logic[127:0]   l1_d_rdata,
	output	logic				l1_d_resp,						// when = 1, d cache data is valid
   
   /* Arbiter <--> L2 cache */
	input		logic[127:0]	l2_rdata,						// this is rdata that the L2 cache is sending to us to pass onto L1
	input		logic 			l2_resp,							//	when = 1, data is valid from L2
	output	logic				l2_write,						// when = 1, we want to write to L2
	output	logic 			l2_read,							// when = 1, we want to read from L2
	output	logic[15:0]		l2_address,						// send the appropriate address to the L2 cache
	output	logic[127:0]	l2_wdata 						// send the appropriate wdata to the L2 cache
);

enum int unsigned
{
                                 st_ready,                            // the arbiter is idle and receptive to memory requests
//                           /     |     \
//                        /        |       \                            // a memory request comes in, the addresses & data values form both L1 and L2 are latched
//                    |/          \|/        \|
                st_L2_to_I,    st_L2_to_D,     st_D_to_L2,            // the arbiter presents the proper address and data (for writes) to the L2 cache. waits for mem_resp
//                  |              |             |
//                  |              |             |                     // the L2 cache response signal goes high
//                 \|/            \|/           \|/
           st_L2_to_I_done,   st_L2_to_D_done,   st_D_to_L2_done     // data from the L2 is presented to the L1 after 1 cycle later.  Mem_resp goes high on the L1.
           
} state;

/* Calculate the next state based on any outstandin
 * memory read/write requests, memory responses, and current state 
 * Also latch inputs from L1 and L2 caches when transitioning to st_L2_to_I, st_L2_to_D, or st_D_to_L2 */
always_ff @(posedge clk)
begin : state_logic

   // initiate a new memory operation when idle
   case (state)
      
      // you can only initiate a read/write cycle from the ready state
      st_ready:
      begin
         // if either of the L1 caches are requesting read or write access to L2,initiate a read/write cycle
         if (l1_i_read)
         begin
            // L1_I has priority over L1_data
            state <= st_L2_to_I;
            l2_address <= l1_i_address;
         end else begin
            // if the ICache isn't reading, then check for a request from the DCache
            case ({l1_d_read, l1_d_write})
               2'b10:
               begin
                  // Upstream (L2 --> L1) data
                  state <= st_L2_to_D;
                  l2_address <= l1_d_address;
               end
               2'b01:
               begin
                  // downstream (L1 --> L2) data
                  state <= st_D_to_L2;
                  l2_address <= l1_d_address;
                  l2_wdata <= l1_d_wdata;
               end
               default:
                  // should never happen
                  state <= st_ready;
            endcase
         end
      end
      
      st_L2_to_I:
         if (l2_resp)
         begin
            state <= st_L2_to_I_done;
            l1_i_rdata <= l2_rdata;
         end
      st_L2_to_D:
         if (l2_resp)
         begin
            state <= st_L2_to_D_done;
            l1_d_rdata <= l2_rdata;
         end
      st_D_to_L2:
         if (l2_resp)
            state <= st_D_to_L2_done;
      default:
         state <= st_ready;
      
   endcase
   
end

/* Drive L2 read/write signals during a pending operation */
assign   l2_read   = (state == st_L2_to_I) || (state == st_L2_to_D);
assign   l2_write  = (state == st_D_to_L2);
/* Drive L1 resp signals for exactly one clk cycle when an operation has finished */
assign   l1_i_resp = (state == st_L2_to_I_done);
assign   l1_d_resp = (state == st_L2_to_D_done) || (state == st_D_to_L2_done);

endmodule : arbiter
