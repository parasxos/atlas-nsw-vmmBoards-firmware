#======================= TIMING ASSERTIONS SECTION ====================
#============================= Primary Clocks =========================
create_clock -period 5.000 -name X_2V5_DIFF_CLK_P -waveform {0.000 2.500} [get_ports X_2V5_DIFF_CLK_P]
create_clock -period 8.000 -name gtrefclk_p       -waveform {0.000 4.000} [get_ports gtrefclk_p]
#============================= Virtual Clocks =========================
#============================= Generated Clocks =======================
## SPI FLASH BEGIN ##
# Following command creates a divide by 2 clock
# It also takes into account the delay added by STARTUP block to route the CCLK
# create_generated_clock -name clk_sck -source [get_pins -hierarchical *axi_quad_spi_0/ext_spi_clk] [get_pins -hierarchical *USRCCLKO] -edges {3 5 7} -edge_shift [list $cclk_delay $cclk_delay $cclk_delay]
create_generated_clock -name clk_sck -source [get_pins -hierarchical *axi_SPI/ext_spi_clk] -edges {3 5 7} -edge_shift {6.700 6.700 6.700} [get_pins -hierarchical *USRCCLKO]
## SPI FLASH END ##
#============================= Clock Groups ===========================
#============================= I/O Delays =============================
## SPI FLASH BEGIN ##
# Data is captured into FPGA on the second rising edge of ext_spi_clk after the SCK falling edge
# Data is driven by the FPGA on every alternate rising_edge of ext_spi_clk
set_input_delay -clock clk_sck -clock_fall -max 7.450 [get_ports IO*_IO]
set_input_delay -clock clk_sck -clock_fall -min 1.450 [get_ports IO*_IO]

# Data is captured into SPI on the following rising edge of SCK
# Data is driven by the IP on alternate rising_edge of the ext_spi_clk
set_output_delay -clock clk_sck -max 2.050 [get_ports IO*_IO]
set_output_delay -clock clk_sck -min -2.950 [get_ports IO*_IO]
## SPI FLASH END ##

set_input_delay 1.0 -clock [get_clocks -of_objects [get_pins clk_user_inst/inst/mmcm_adv_inst/CLKOUT0]] [get_ports CH_TRIGGER]
#============================= Primary Clocks =========================
#======================================================================


#======================= TIMING EXCEPTIONS SECTION ====================
#=============================== False Paths ==========================
set_false_path -from [get_ports CH_TRIGGER]

# CKTP/CKBC enabling false path
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells ckbc_cktp_generator/cktp_generator/cktp_start_i_reg]
set_false_path -from [get_cells rstFIFO_top_reg]      -to [get_cells ckbc_cktp_generator/cktp_generator/cktp_primary_i_reg]
set_false_path -from [get_cells ckbc_enable_reg]      -to [get_cells ckbc_cktp_generator/ckbc_generator/ready_i_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells ckbc_cktp_generator/cktp_max_module/inhibit_async_i_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells ckbc_cktp_generator/cktp_max_module/fsm_enable_i_reg]
set_false_path -from [get_cells FSM_onehot_state_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_max_module/inhibit_async_i_reg]
set_false_path -from [get_cells FSM_onehot_state_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_generator/cktp_start_i_reg]
set_false_path -from [get_cells FSM_onehot_state_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_max_module/fsm_enable_i_reg]
set_false_path -from [get_cells FSM_onehot_state_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_trint_module/cktp_start_s_0_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells ckbc_cktp_generator/cktp_trint_module/cktp_start_s_0_reg]
set_false_path -from [get_cells ckbc_cktp_generator/cktp_trint_module/trint_i_reg] -to [get_cells ckbc_cktp_generator/cktp_trint_module/trint_s_0_reg]

# Trigger related false paths
set_false_path -from [get_cells trigger_instance/tr_out_i_reg] -to [get_cells trigger_instance/tr_out_i_stage1_reg]
set_false_path -from [get_cells trigger_instance/tren_buff_reg] -to [get_cells trigger_instance/tren_buff_stage1_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells trigger_instance/trext_stage1_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells trigger_instance/trmode_stage1_reg]
set_false_path -from [get_cells trigger_instance/mode_reg] -to [get_cells trigger_instance/mode_stage1_reg]
set_false_path -from [get_cells trigger_instance/trext_ff_synced_reg] -to [get_cells trigger_instance/trext_stage_resynced_reg]
set_false_path -from [get_cells ckbc_cktp_generator/cktp_trint_module/trint_s_reg] -to [get_cells trigger_instance/trint_stage1_reg]

# AXI SPI related false paths
set_false_path -from [get_cells axi4_spi_instance/CDCC_50to125/data_in_reg_reg[*]] -to [get_cells axi4_spi_instance/CDCC_50to125/data_sync_stage_0_reg[*]]
set_false_path -from [get_cells axi4_spi_instance/CDCC_125to50/data_in_reg_reg[*]] -to [get_cells axi4_spi_instance/CDCC_125to50/data_sync_stage_0_reg[*]]

# UDP configuration related false paths
set_false_path -from [get_cells udp_din_conf_block/CDCC_40to125/data_in_reg_reg[*]] -to [get_cells udp_din_conf_block/CDCC_40to125/data_sync_stage_0_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/CDCC_125to40/data_in_reg_reg[*]] -to [get_cells udp_din_conf_block/CDCC_125to40/data_sync_stage_0_reg[*]]

# MMCM related false paths
set_false_path -from [get_cells clk_400_low_jitter_inst/inst/seq_reg1_reg[*]] -to [get_cells clk_400_low_jitter_inst/inst/clkout1_buf]

# Readout related false paths
set_false_path -from [get_cells packet_formation_instance/triggerVmmReadout_i_reg] -to [get_cells readout_vmm/trigger_pulse_stage1_reg]
set_false_path -from [get_cells readout_vmm/daq_enable_stage1_Dt_reg] -to [get_cells readout_vmm/daq_enable_ff_sync_Dt_reg]
set_false_path -from [get_cells daq_enable_i_reg] -to [get_cells readout_vmm/daq_enable_stage1_reg]
set_false_path -from [get_cells readout_vmm/vmmEventDone_i_reg] -to [get_cells readout_vmm/vmmEventDone_stage1_reg]
set_false_path -from [get_cells readout_vmm/vmmWord_i_reg[*]] -to [get_cells readout_vmm/vmmWord_stage1_reg[*]]
set_false_path -from [get_cells readout_vmm/vmmWordReady_i_reg] -to [get_cells readout_vmm/vmmWordReady_stage1_reg]
#============================== Min/Max Delay =========================
## SPI FLASH BEGIN ##
# this is to ensure min routing delay from SCK generation to STARTUP input
# User should change this value based on the results
# having more delay on this net reduces the Fmax
set_max_delay -datapath_only -from [get_pins -hier *SCK_O_reg_reg/C] -to [get_pins -hier *USRCCLKO] 1.500
set_min_delay -from [get_pins -hier *SCK_O_reg_reg/C] -to [get_pins -hier *USRCCLKO] 0.100
## SPI FLASH END ##
#set_max_delay 10.000 -from [get_cells *user_side_FIFO/tx_fifo_i/*rd_addr_txfer*] -to [get_cells *user_side_FIFO/tx_fifo_i/wr_rd_addr*]
#============================= Multicycle Paths =======================
## SPI FLASH BEGIN ##
set_multicycle_path -setup -from clk_sck -to     [get_clocks -of_objects [get_pins -hierarchical *ext_spi_clk]] 2
set_multicycle_path -hold -end -from clk_sck -to [get_clocks -of_objects [get_pins -hierarchical *ext_spi_clk]] 1
set_multicycle_path -setup -start -from          [get_clocks -of_objects [get_pins -hierarchical *ext_spi_clk]] -to clk_sck 2
set_multicycle_path -hold -from                  [get_clocks -of_objects [get_pins -hierarchical *ext_spi_clk]] -to clk_sck 1
## SPI FLASH END ##
#============================= Case Analysis  =========================
## SPI FLASH BEGIN ##
# You must provide all the delay numbers
# CCLK delay is 0.5, 6.7 ns min/max for K7-2; refer Data sheet
# Consider the max delay for worst case analysis
set cclk_delay 6.7
# Following are the SPI device parameters
# Max Tco
set tco_max 7
# Min Tco
set tco_min 1
# Setup time requirement
set tsu 2
# Hold time requirement
set th 3
# Following are the board/trace delay numbers
# Assumption is that all Data lines are matched
set tdata_trace_delay_max 0.25
set tdata_trace_delay_min 0.25
set tclk_trace_delay_max 0.2
set tclk_trace_delay_min 0.2
### End of user provided delay numbers
## SPI FLASH END ##
#============================= Disable Timing =========================
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets gtx_clk]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_pins FDCE_inst/C] 
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets ART_P]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets ART_N]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {CLK_40_IBUF}]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets art_in_i]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets ART_P]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets ART_N]
#======================================================================

#====================== PHYSICAL CONSTRAINTS SECTION ==================
#====================== ASYNC_REG for synchronizers ===================
set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_50to125/data_sync_stage_0_reg[*]]
set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_50to125/data_out_s_int_reg[*]]

set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_125to50/data_sync_stage_0_reg[*]]
set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_125to50/data_out_s_int_reg[*]]

set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_125to40/data_sync_stage_0_reg[*]]
set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_125to40/data_out_s_int_reg[*]]

set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_40to125/data_sync_stage_0_reg[*]]
set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_40to125/data_out_s_int_reg[*]]

set_property ASYNC_REG true [get_cells readout_vmm/vmmEventDone_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmmEventDone_ff_sync_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmmWordReady_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmmWordReady_ff_sync_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmmWord_stage1_reg[*]]
set_property ASYNC_REG true [get_cells readout_vmm/vmmWord_ff_sync_reg[*]]

set_property ASYNC_REG true [get_cells readout_vmm/daq_enable_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/daq_enable_ff_sync_reg]
set_property ASYNC_REG true [get_cells readout_vmm/daq_enable_stage1_Dt_reg]
set_property ASYNC_REG true [get_cells readout_vmm/daq_enable_ff_sync_Dt_reg]

set_property ASYNC_REG true [get_cells readout_vmm/trigger_pulse_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/trigger_pulse_ff_sync_reg]
set_property ASYNC_REG true [get_cells packet_formation_instance/triggerVmmReadout_i_reg]
        
set_property ASYNC_REG true [get_cells readout_vmm/cktk_max_i_reg[*]]
set_property ASYNC_REG true [get_cells readout_vmm/cktk_max_sync_reg[*]]
set_property ASYNC_REG true [get_cells readout_vmm/reading_out_word_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/reading_out_word_ff_sync_reg]

set_property ASYNC_REG true [get_cells readout_vmm/vmm_data0_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmm_data0_ff_sync_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmm_data1_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmm_data1_ff_sync_reg]
set_property ASYNC_REG true [get_cells readout_vmm/cktkSent_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/cktkSent_ff_sync_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmmEventDone_i_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmmEventDone_stage1_reg]
set_property ASYNC_REG true [get_cells daq_enable_i_reg]
set_property ASYNC_REG true [get_cells readout_vmm/daq_enable_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/driverBusy_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/driverBusy_ff_sync_reg]


set_property ASYNC_REG true [get_cells trigger_instance/tr_out_i_stage1_reg]
set_property ASYNC_REG true [get_cells trigger_instance/tr_out_i_ff_synced_reg]
set_property ASYNC_REG true [get_cells trigger_instance/trext_stage_resynced_reg]
set_property ASYNC_REG true [get_cells trigger_instance/trext_ff_resynced_reg]
set_property ASYNC_REG true [get_cells trigger_instance/trext_stage1_reg]
set_property ASYNC_REG true [get_cells trigger_instance/trext_ff_synced_reg]
set_property ASYNC_REG true [get_cells trigger_instance/tren_buff_stage1_reg]
set_property ASYNC_REG true [get_cells trigger_instance/tren_buff_ff_synced_reg]
set_property ASYNC_REG true [get_cells trigger_instance/mode_stage1_reg]
set_property ASYNC_REG true [get_cells trigger_instance/mode_ff_synced_reg]
set_property ASYNC_REG true [get_cells trigger_instance/trmode_stage1_reg]
set_property ASYNC_REG true [get_cells trigger_instance/trmode_ff_synced_reg]
set_property ASYNC_REG true [get_cells trigger_instance/trint_stage1_reg]
set_property ASYNC_REG true [get_cells trigger_instance/trint_ff_synced_reg]

set_property ASYNC_REG true [get_cells udp_din_conf_block/fpga_config_logic/daq_on_i_reg]
set_property ASYNC_REG true [get_cells udp_din_conf_block/fpga_config_logic/daq_on_sync_reg]
set_property ASYNC_REG true [get_cells udp_din_conf_block/fpga_config_logic/ext_trg_i_reg]
set_property ASYNC_REG true [get_cells udp_din_conf_block/fpga_config_logic/ext_trg_sync_reg]
#=====================================================================

#======================= Configurable CKBC/CKTP Constraints ==========
# 160 MHz global clock buffer placement constraint
set_property LOC BUFGCTRL_X0Y1 [get_cells mmcm_ckbc_cktp/inst/clkout1_buf]
# 500 Mhz global clock buffer placement constraint
set_property LOC BUFGCTRL_X0Y2 [get_cells mmcm_ckbc_cktp/inst/clkout2_buf]

# CKBC global buffer placement constraint
set_property LOC BUFGCTRL_X0Y0 [get_cells ckbc_cktp_generator/CKBC_BUFGMUX]
# register-to-CKBC buffer placement constraint
set_property LOC SLICE_X83Y145 [get_cells ckbc_cktp_generator/ckbc_generator/ckbc_out_reg]

# CKTP global buffer placement constraint
set_property LOC BUFGCTRL_X0Y3 [get_cells ckbc_cktp_generator/CKTP_BUFGMUX]
# register-to-CKTP buffer placement constraint
set_property LOC SLICE_X83Y146 [get_cells ckbc_cktp_generator/cktp_generator/vmm_cktp_reg]
set_property LOC SLICE_X83Y147 [get_cells ckbc_cktp_generator/skewing_module/CKTP_skewed_reg]

# critical register of cktp generator placement constraint
set_property LOC SLICE_X82Y146 [get_cells ckbc_cktp_generator/cktp_generator/start_align_cnt_reg]

#ASYNC_REG to skewing pipeline
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/cktp_generator/vmm_cktp_reg]
set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/CKTP_skewed_reg]
set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_02_reg]
set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_04_reg]
set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_06_reg]
set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_08_reg]
set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_10_reg]
set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_12_reg]
set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_14_reg]
set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_16_reg]
set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_18_reg]
set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_20_reg]
set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_22_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_24_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_26_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_28_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_30_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_32_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_34_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_36_reg]

#False paths for skewing pipeline (Caution!! Those lines might not be needed. It should be validated with an oscilloscope) 
set_false_path -from [get_cells ckbc_cktp_generator/cktp_generator/vmm_cktp_reg] -to [get_cells ckbc_cktp_generator/skewing_module/CKTP_skewed_reg]
set_false_path -from [get_cells ckbc_cktp_generator/cktp_generator/vmm_cktp_reg] -to [get_cells ckbc_cktp_generator/skewing_module/cktp_02_reg]
set_false_path -from [get_cells ckbc_cktp_generator/skewing_module/cktp_02_reg] -to [get_cells ckbc_cktp_generator/skewing_module/CKTP_skewed_reg]

# PBLOCKS (obsolete)
#create_pblock pblock_skewing_module
#add_cells_to_pblock [get_pblocks pblock_skewing_module] [get_cells -quiet [list ckbc_cktp_generator/skewing_module]]
#resize_pblock [get_pblocks pblock_skewing_module] -add {SLICE_X82Y146:SLICE_X83Y148}
#create_pblock pblock_ckbc_generator_block
#add_cells_to_pblock [get_pblocks pblock_ckbc_generator_block] [get_cells -quiet [list ckbc_cktp_generator/ckbc_generator]]
#resize_pblock [get_pblocks pblock_ckbc_generator_block] -add {SLICE_X76Y138:SLICE_X83Y146}
#resize_pblock [get_pblocks pblock_ckbc_generator_block] -add {RAMB18_X4Y56:RAMB18_X4Y57}
#resize_pblock [get_pblocks pblock_ckbc_generator_block] -add {RAMB36_X4Y28:RAMB36_X4Y28}
#create_pblock pblock_cktp_generator_block
#add_cells_to_pblock [get_pblocks pblock_cktp_generator_block] [get_cells -quiet [list ckbc_cktp_generator/cktp_generator]]
#resize_pblock [get_pblocks pblock_cktp_generator_block] -add {SLICE_X74Y147:SLICE_X83Y160}
#resize_pblock [get_pblocks pblock_cktp_generator_block] -add {RAMB18_X4Y60:RAMB18_X4Y63}
#resize_pblock [get_pblocks pblock_cktp_generator_block] -add {RAMB36_X4Y30:RAMB36_X4Y31}
#============================================================================================