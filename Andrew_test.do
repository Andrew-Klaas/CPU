restart -f

delete wave *

add wave -label CLK sim:/mp3_tb/dut/clk

add wave -divider physical_memory
add wave -label PMEM_RESP sim:/mp3_tb/pmem_resp
add wave -label PMEM_RDATA sim:/mp3_tb/pmem_rdata
add wave -label PMEM_WDATA sim:/mp3_tb/pmem_wdata
add wave -label PMEM_READ sim:/mp3_tb/pmem_read
add wave -label PMEM_WRITE sim:/mp3_tb/pmem_write
add wave -label PMEM_ADDRESS sim:/mp3_tb/pmem_address

#add wave -divider ICACHE
#add wave -label I_RESP sim:/mp3_tb/dut/cpu_inst/i_mem_resp 
#add wave -label I_ADRS sim:/mp3_tb/dut/cpu_inst/i_address 
#add wave -label I_RDATA sim:/mp3_tb/dut/cpu_inst/i_rdata 

#add wave -divider DCACHE
#add wave -label D_READ sim:/mp3_tb/dut/cpu_inst/d_read 
#add wave -label D_WRITE sim:/mp3_tb/dut/cpu_inst/d_write
#add wave -label D_RESP sim:/mp3_tb/dut/cpu_inst/d_mem_resp 
#add wave -label D_ADRS sim:/mp3_tb/dut/cpu_inst/d_address 
#add wave -label D_RDATA sim:/mp3_tb/dut/cpu_inst/d_rdata 
#add wave -label D_WDATA sim:/mp3_tb/dut/cpu_inst/d_wdata 

#add wave -divider FETCH
add wave -label PC sim:/mp3_tb/dut/cpu_inst/fetch_inst/pc 
add wave -label IR sim:/mp3_tb/dut/cpu_inst/fetch_inst/ctrl_a_out.instruction 
#add wave -label STALL_ALL sim:/mp3_tb/dut/cpu_inst/fetch_inst/stall_all 
#add wave -label Stall_fetch sim:/mp3_tb/dut/cpu_inst/fetch_inst/stall_fetch

#add wave -divider CONTROL
#add wave -label FETCH_out sim:/mp3_tb/dut/cpu_inst/fetch_inst/ctrl_a_out
#add wave -label DECODE_out sim:/mp3_tb/dut/cpu_inst/decode_inst/ctrl_b_out 
#add wave -label DECODE_state sim:/mp3_tb/dut/cpu_inst/decode_inst/ 
#add wave -label EXECUTE_in sim:/mp3_tb/dut/cpu_inst/execute_inst/ctrl_c_in 
#add wave -label MEMORY_in sim:/mp3_tb/dut/cpu_inst/mem_inst/ctrl_d_in 
#add wave -label WRITEBACK_in sim:/mp3_tb/dut/cpu_inst/wb_inst/ctrl_e_in 

add wave -divider REGISTERS   
add wave -label Registers sim:/mp3_tb/dut/cpu_inst/decode_inst/regfile_inst/data 

add wave -label L2STATE sim:/mp3_tb/dut/l2_cache_inst/l2_cache_control_inst/state

add wave -divider L1
add wave -label way0 sim:/mp3_tb/dut/dcache_inst/L1_core/CACHE_DATAPATH_INST/WAY0_INST/data
add wave -label way1 sim:/mp3_tb/dut/dcache_inst/L1_core/CACHE_DATAPATH_INST/WAY1_INST/data 

add wave -divider L2
add wave -label way0 sim:/mp3_tb/dut/l2_cache_inst/l2_cache_datapath_inst/Data0_array_32/data 
add wave -label way1 sim:/mp3_tb/dut/l2_cache_inst/l2_cache_datapath_inst/Data1_array_32/data 
add wave -label way2 sim:/mp3_tb/dut/l2_cache_inst/l2_cache_datapath_inst/Data2_array_32/data 
add wave -label way3 sim:/mp3_tb/dut/l2_cache_inst/l2_cache_datapath_inst/Data3_array_32/data 
add wave -divider LRUL2
#add wave -label LRU_IN sim:/mp3_tb/dut/l2_cache_inst/l2_cache_control_inst/lru_in
add wave -label LRU_OUT sim:/mp3_tb/dut/l2_cache_inst/l2_cache_control_inst/lru_out
#add wave -label LRU_LD sim:/mp3_tb/dut/l2_cache_inst/l2_cache_control_inst/ld_lru
#add wave -label LRU_INDEX sim:/mp3_tb/dut/l2_cache_inst/l2_cache_datapath_inst/LRU_array/index 

add wave -label REPLACEMENTSET sim:/mp3_tb/dut/l2_cache_inst/l2_cache_control_inst/replacement_set
#add wave -label REPLACEMENTSETDATAPATH sim:/mp3_tb/dut/l2_cache_inst/l2_cache_datapath_inst/replacement_set
#add wave -divider L2_incoming
add wave -label L2_WRITE sim:/mp3_tb/dut/l2_cache_inst/l2_cache_control_inst/l2_write
add wave -label L2_READ sim:/mp3_tb/dut/l2_cache_inst/l2_cache_control_inst/l2_read
add wave -label L2_ADDRESS sim:/mp3_tb/dut/l2_cache_inst/l2_cache_datapath_inst/l2_address
add wave -label L2_WDATA sim:/mp3_tb/dut/l2_cache_inst/l2_cache_datapath_inst/l2_wdata
add wave -label L2_RDATA sim:/mp3_tb/dut/l2_cache_inst/l2_cache_datapath_inst/l2_rdata
#add wave -label WAYMUX_SEL sim:/mp3_tb/dut/l2_cache_inst/l2_cache_datapath_inst/waymux_sel
#add wave -label flag1 sim:/mp3_tb/dut/l2_cache_inst/l2_cache_datapath_inst/flag1
#add wave -label flag2 sim:/mp3_tb/dut/l2_cache_inst/l2_cache_datapath_inst/flag2
#add wave -label DataOut sim:/mp3_tb/dut/l2_cache_inst/l2_cache_datapath_inst/p_wdata
#add wave -divider HIT_L2
add wave -label HIT sim:/mp3_tb/dut/l2_cache_inst/l2_cache_control_inst/hit
#add wave -label HIT_SET sim:/mp3_tb/dut/l2_cache_inst/l2_cache_control_inst/hit_set
#add wave -label HITDATAPATH sim:/mp3_tb/dut/l2_cache_inst/l2_cache_datapath_inst/hit
#add wave -label HIT_SETDATAPATH sim:/mp3_tb/dut/l2_cache_inst/l2_cache_datapath_inst/hit_set

add wave -divider VICTIM_CACHE
add wave -label Victim_write sim:/mp3_tb/dut/Victim_cache_inst/victim_write
add wave -label valid sim:/mp3_tb/dut/Victim_cache_inst/valid
add wave -label v_write sim:/mp3_tb/dut/Victim_cache_inst/v_write
add wave -label v_wdata sim:/mp3_tb/dut/Victim_cache_inst/v_wdata
add wave -label v_resp sim:/mp3_tb/dut/Victim_cache_inst/v_resp
add wave -label v_read sim:/mp3_tb/dut/Victim_cache_inst/v_read
add wave -label v_rdata sim:/mp3_tb/dut/Victim_cache_inst/v_rdata
#add wave -label v_address sim:/mp3_tb/dut/Victim_cache_inst/v_address
add wave -label read_hit sim:/mp3_tb/dut/Victim_cache_inst/read_hit
#add wave -label p_write sim:/mp3_tb/dut/Victim_cache_inst/p_write
#add wave -label p_wdata sim:/mp3_tb/dut/Victim_cache_inst/p_wdata
#add wave -label p_resp sim:/mp3_tb/dut/Victim_cache_inst/p_resp
#add wave -label p_read sim:/mp3_tb/dut/Victim_cache_inst/p_read
#add wave -label p_rdata sim:/mp3_tb/dut/Victim_cache_inst/p_rdata
#add wave -label p_address sim:/mp3_tb/dut/Victim_cache_inst/p_address
#add wave -label load_plru_sel sim:/mp3_tb/dut/Victim_cache_inst/load_plru_sel
#add wave -label load_plru sim:/mp3_tb/dut/Victim_cache_inst/load_plru

add wave -divider VICTIM_INTERNAL
#add wave -label state sim:/mp3_tb/dut/Victim_cache_inst/victim_cache_control_inst/state 
add wave -label victim_table sim:/mp3_tb/dut/Victim_cache_inst/victim_cache_datapath_inst/victim_table
#add wave -label victim_data_out sim:/mp3_tb/dut/Victim_cache_inst/victim_cache_datapath_inst/victim_data
#add wave -label write_ix sim:/mp3_tb/dut/Victim_cache_inst/victim_cache_datapath_inst/write_ix
#add wave -label write_hit sim:/mp3_tb/dut/Victim_cache_inst/victim_cache_datapath_inst/write_hit
#add wave -label flag sim:/mp3_tb/dut/Victim_cache_inst/victim_cache_datapath_inst/flag
#add wave -label flag2 sim:/mp3_tb/dut/Victim_cache_inst/victim_cache_datapath_inst/flag2
#add wave -label read_ix sim:/mp3_tb/dut/Victim_cache_inst/victim_cache_datapath_inst/read_ix
add wave -label plru sim:/mp3_tb/dut/Victim_cache_inst/victim_cache_datapath_inst/plru



radix hex

run 37000ns

