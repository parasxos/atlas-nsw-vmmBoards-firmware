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

# CKTP registering false paths
set_false_path -from [get_cells ckbc_cktp_generator/skewing_module/CKTP_skewed_reg] -to [get_cells CKTP_i_reg]
set_false_path -from [get_cells ckbc_cktp_generator/cktp_generator/vmm_cktp_reg]    -to [get_cells CKTP_i_reg]

# CKTP/CKBC enabling false path
set_false_path -from [get_cells state_reg[*]]         -to [get_cells ckbc_cktp_generator/cktp_generator/cktp_start_i_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells ckbc_cktp_generator/cktp_generator/cktp_start_i_reg]
set_false_path -from [get_cells rstFIFO_top_reg]      -to [get_cells ckbc_cktp_generator/cktp_generator/cktp_primary_i_reg]
set_false_path -from [get_cells ckbc_enable_reg]      -to [get_cells ckbc_cktp_generator/ckbc_generator/ready_i_reg]
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
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets art_P]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets art_N]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {CLK_40_IBUF}]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets art_in_i]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets art_P]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets art_N]
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
set_property ASYNC_REG true [get_cells readout_vmm/trigger_pulse_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/trigger_pulse_ff_sync_reg]
set_property ASYNC_REG true [get_cells readout_vmm/cktk_max_i_reg[*]]
set_property ASYNC_REG true [get_cells readout_vmm/cktk_max_sync_reg[*]]

set_property ASYNC_REG true [get_cells trigger_instance/trext_stage1_reg]
set_property ASYNC_REG true [get_cells trigger_instance/trext_ff_synced_reg]

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
set_property LOC BUFGCTRL_X0Y0 [get_cells ckbc_cktp_generator/CKBC_BUFGCE]
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

#====================== I/O Placement - IOSTANDARDS ===================
############################# MDT #############################
set_property PACKAGE_PIN W19     [get_ports X_2V5_DIFF_CLK_P]
set_property PACKAGE_PIN W20     [get_ports X_2V5_DIFF_CLK_N]
set_property IOSTANDARD LVDS_25  [get_ports X_2V5_DIFF_CLK_P]
set_property IOSTANDARD LVDS_25  [get_ports X_2V5_DIFF_CLK_N]
#set_property PACKAGE_PIN V20     [get_ports CLK_40]
#set_property IOSTANDARD LVCMOS33 [get_ports CLK_40]
############################# Ethernet #############################
set_property PACKAGE_PIN F6      [get_ports gtrefclk_p]
set_property PACKAGE_PIN E6      [get_ports gtrefclk_n]
set_property PACKAGE_PIN A8      [get_ports rxn]
set_property PACKAGE_PIN B8      [get_ports rxp]
set_property PACKAGE_PIN A4      [get_ports txn]
set_property PACKAGE_PIN B4      [get_ports txp]
set_property PACKAGE_PIN P16     [get_ports phy_int]
set_property IOSTANDARD LVCMOS25 [get_ports phy_int]
set_property PACKAGE_PIN R17     [get_ports phy_rstn_out]
set_property IOSTANDARD LVCMOS25 [get_ports phy_rstn_out]

#########################DATA0 VMM3#############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_1_P]
set_property PACKAGE_PIN B17         [get_ports DATA0_1_P]
set_property PACKAGE_PIN B18         [get_ports DATA0_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_2_P]
set_property PACKAGE_PIN B17         [get_ports DATA0_2_P]
set_property PACKAGE_PIN B18         [get_ports DATA0_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_3_P]
set_property PACKAGE_PIN B17         [get_ports DATA0_3_P]
set_property PACKAGE_PIN B18         [get_ports DATA0_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_4_P]
set_property PACKAGE_PIN B17         [get_ports DATA0_4_P]
set_property PACKAGE_PIN B18         [get_ports DATA0_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_5_P]
set_property PACKAGE_PIN B17         [get_ports DATA0_5_P]
set_property PACKAGE_PIN B18         [get_ports DATA0_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_6_P]
set_property PACKAGE_PIN B17         [get_ports DATA0_6_P]
set_property PACKAGE_PIN B18         [get_ports DATA0_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_7_P]
set_property PACKAGE_PIN B17         [get_ports DATA0_7_P]
set_property PACKAGE_PIN B18         [get_ports DATA0_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_8_P]
set_property PACKAGE_PIN B17         [get_ports DATA0_8_P]
set_property PACKAGE_PIN B18         [get_ports DATA0_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_8_N]

#########################DATA1 VMM3#############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_1_P]
set_property PACKAGE_PIN B17         [get_ports DATA1_1_P]
set_property PACKAGE_PIN B18         [get_ports DATA1_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_2_P]
set_property PACKAGE_PIN B17         [get_ports DATA1_2_P]
set_property PACKAGE_PIN B18         [get_ports DATA1_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_3_P]
set_property PACKAGE_PIN B17         [get_ports DATA1_3_P]
set_property PACKAGE_PIN B18         [get_ports DATA1_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_4_P]
set_property PACKAGE_PIN B17         [get_ports DATA1_4_P]
set_property PACKAGE_PIN B18         [get_ports DATA1_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_5_P]
set_property PACKAGE_PIN B17         [get_ports DATA1_5_P]
set_property PACKAGE_PIN B18         [get_ports DATA1_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_6_P]
set_property PACKAGE_PIN B17         [get_ports DATA1_6_P]
set_property PACKAGE_PIN B18         [get_ports DATA1_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_7_P]
set_property PACKAGE_PIN B17         [get_ports DATA1_7_P]
set_property PACKAGE_PIN B18         [get_ports DATA1_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_8_P]
set_property PACKAGE_PIN B17         [get_ports DATA1_8_P]
set_property PACKAGE_PIN B18         [get_ports DATA1_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_8_N]

##########################CKDT VMM3##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_1_P]
set_property PACKAGE_PIN B21         [get_ports CKDT_1_P]
set_property PACKAGE_PIN A21         [get_ports CKDT_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_2_P]
set_property PACKAGE_PIN B21         [get_ports CKDT_2_P]
set_property PACKAGE_PIN A21         [get_ports CKDT_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_3_P]
set_property PACKAGE_PIN B21         [get_ports CKDT_3_P]
set_property PACKAGE_PIN A21         [get_ports CKDT_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_4_P]
set_property PACKAGE_PIN B21         [get_ports CKDT_4_P]
set_property PACKAGE_PIN A21         [get_ports CKDT_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_5_P]
set_property PACKAGE_PIN B21         [get_ports CKDT_5_P]
set_property PACKAGE_PIN A21         [get_ports CKDT_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_6_P]
set_property PACKAGE_PIN B21         [get_ports CKDT_6_P]
set_property PACKAGE_PIN A21         [get_ports CKDT_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_7_P]
set_property PACKAGE_PIN B21         [get_ports CKDT_7_P]
set_property PACKAGE_PIN A21         [get_ports CKDT_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_8_P]
set_property PACKAGE_PIN B21         [get_ports CKDT_8_P]
set_property PACKAGE_PIN A21         [get_ports CKDT_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_8_N]

##########################CKBC VMM3##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_1_P]
set_property PACKAGE_PIN E13         [get_ports CKBC_1_P]
set_property PACKAGE_PIN E14         [get_ports CKBC_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_2_P]
set_property PACKAGE_PIN E13         [get_ports CKBC_2_P]
set_property PACKAGE_PIN E14         [get_ports CKBC_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_3_P]
set_property PACKAGE_PIN E13         [get_ports CKBC_3_P]
set_property PACKAGE_PIN E14         [get_ports CKBC_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_4_P]
set_property PACKAGE_PIN E13         [get_ports CKBC_4_P]
set_property PACKAGE_PIN E14         [get_ports CKBC_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_5_P]
set_property PACKAGE_PIN E13         [get_ports CKBC_5_P]
set_property PACKAGE_PIN E14         [get_ports CKBC_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_6_P]
set_property PACKAGE_PIN E13         [get_ports CKBC_6_P]
set_property PACKAGE_PIN E14         [get_ports CKBC_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_7_P]
set_property PACKAGE_PIN E13         [get_ports CKBC_7_P]
set_property PACKAGE_PIN E14         [get_ports CKBC_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_8_P]
set_property PACKAGE_PIN E13         [get_ports CKBC_8_P]
set_property PACKAGE_PIN E14         [get_ports CKBC_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_8_N]


##########################CKTP VMM3##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_1_P]
set_property PACKAGE_PIN C22         [get_ports CKTP_1_P]
set_property PACKAGE_PIN B22         [get_ports CKTP_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_2_P]
set_property PACKAGE_PIN C22         [get_ports CKTP_2_P]
set_property PACKAGE_PIN B22         [get_ports CKTP_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_3_P]
set_property PACKAGE_PIN C22         [get_ports CKTP_3_P]
set_property PACKAGE_PIN B22         [get_ports CKTP_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_4_P]
set_property PACKAGE_PIN C22         [get_ports CKTP_4_P]
set_property PACKAGE_PIN B22         [get_ports CKTP_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_5_P]
set_property PACKAGE_PIN C22         [get_ports CKTP_5_P]
set_property PACKAGE_PIN B22         [get_ports CKTP_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_6_P]
set_property PACKAGE_PIN C22         [get_ports CKTP_6_P]
set_property PACKAGE_PIN B22         [get_ports CKTP_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_7_P]
set_property PACKAGE_PIN C22         [get_ports CKTP_7_P]
set_property PACKAGE_PIN B22         [get_ports CKTP_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_8_P]
set_property PACKAGE_PIN C22         [get_ports CKTP_8_P]
set_property PACKAGE_PIN B22         [get_ports CKTP_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_8_N]

##########################CKTK VMM3##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_1_P]
set_property PACKAGE_PIN A15         [get_ports CKTK_1_P]
set_property PACKAGE_PIN A16         [get_ports CKTK_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_2_P]
set_property PACKAGE_PIN A15         [get_ports CKTK_2_P]
set_property PACKAGE_PIN A16         [get_ports CKTK_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_3_P]
set_property PACKAGE_PIN A15         [get_ports CKTK_3_P]
set_property PACKAGE_PIN A16         [get_ports CKTK_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_4_P]
set_property PACKAGE_PIN A15         [get_ports CKTK_4_P]
set_property PACKAGE_PIN A16         [get_ports CKTK_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_5_P]
set_property PACKAGE_PIN A15         [get_ports CKTK_5_P]
set_property PACKAGE_PIN A16         [get_ports CKTK_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_6_P]
set_property PACKAGE_PIN A15         [get_ports CKTK_6_P]
set_property PACKAGE_PIN A16         [get_ports CKTK_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_7_P]
set_property PACKAGE_PIN A15         [get_ports CKTK_7_P]
set_property PACKAGE_PIN A16         [get_ports CKTK_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_8_P]
set_property PACKAGE_PIN A15         [get_ports CKTK_8_P]
set_property PACKAGE_PIN A16         [get_ports CKTK_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_8_N]

#############################SDI VMM3###########################

set_property PACKAGE_PIN C13         [get_ports SDI_1]
set_property IOSTANDARD LVCMOS12     [get_ports SDI_1]

set_property PACKAGE_PIN C13         [get_ports SDI_2]
set_property IOSTANDARD LVCMOS12     [get_ports SDI_2]

set_property PACKAGE_PIN C13         [get_ports SDI_3]
set_property IOSTANDARD LVCMOS12     [get_ports SDI_3]

set_property PACKAGE_PIN C13         [get_ports SDI_4]
set_property IOSTANDARD LVCMOS12     [get_ports SDI_4]

set_property PACKAGE_PIN C13         [get_ports SDI_5]
set_property IOSTANDARD LVCMOS12     [get_ports SDI_5]

set_property PACKAGE_PIN C13         [get_ports SDI_6]
set_property IOSTANDARD LVCMOS12     [get_ports SDI_6]

set_property PACKAGE_PIN C13         [get_ports SDI_7]
set_property IOSTANDARD LVCMOS12     [get_ports SDI_7]

set_property PACKAGE_PIN C13         [get_ports SDI_8]
set_property IOSTANDARD LVCMOS12     [get_ports SDI_8]

#############################SDO VMM3###########################

set_property PACKAGE_PIN B13         [get_ports SDO_1]
set_property IOSTANDARD LVCMOS12     [get_ports SDO_1]

set_property PACKAGE_PIN B13         [get_ports SDO_2]
set_property IOSTANDARD LVCMOS12     [get_ports SDO_2]

set_property PACKAGE_PIN B13         [get_ports SDO_3]
set_property IOSTANDARD LVCMOS12     [get_ports SDO_3]

set_property PACKAGE_PIN B13         [get_ports SDO_4]
set_property IOSTANDARD LVCMOS12     [get_ports SDO_4]

set_property PACKAGE_PIN B13         [get_ports SDO_5]
set_property IOSTANDARD LVCMOS12     [get_ports SDO_5]

set_property PACKAGE_PIN B13         [get_ports SDO_6]
set_property IOSTANDARD LVCMOS12     [get_ports SDO_6]

set_property PACKAGE_PIN B13         [get_ports SDO_7]
set_property IOSTANDARD LVCMOS12     [get_ports SDO_7]

set_property PACKAGE_PIN B13         [get_ports SDO_8]
set_property IOSTANDARD LVCMOS12     [get_ports SDO_8]

#############################TKI/TKO###########################

set_property PACKAGE_PIN AA13         [get_ports TKI_P]
set_property PACKAGE_PIN AB13         [get_ports TKI_N]

set_property IOSTANDARD DIFF_HSUL_12  [get_ports TKI_P]
set_property IOSTANDARD DIFF_HSUL_12  [get_ports TKI_N]

set_property PACKAGE_PIN Y16          [get_ports TKO_P]
set_property PACKAGE_PIN AA16         [get_ports TKO_N]

set_property IOSTANDARD DIFF_HSUL_12  [get_ports TKO_P]
set_property IOSTANDARD DIFF_HSUL_12  [get_ports TKO_N]

##########################ENA VMM3##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_1_P]
set_property PACKAGE_PIN A13         [get_ports ENA_1_P]
set_property PACKAGE_PIN A14         [get_ports ENA_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_2_P]
set_property PACKAGE_PIN A13         [get_ports ENA_2_P]
set_property PACKAGE_PIN A14         [get_ports ENA_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_3_P]
set_property PACKAGE_PIN A13         [get_ports ENA_3_P]
set_property PACKAGE_PIN A14         [get_ports ENA_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_4_P]
set_property PACKAGE_PIN A13         [get_ports ENA_4_P]
set_property PACKAGE_PIN A14         [get_ports ENA_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_5_P]
set_property PACKAGE_PIN A13         [get_ports ENA_5_P]
set_property PACKAGE_PIN A14         [get_ports ENA_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_6_P]
set_property PACKAGE_PIN A13         [get_ports ENA_6_P]
set_property PACKAGE_PIN A14         [get_ports ENA_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_7_P]
set_property PACKAGE_PIN A13         [get_ports ENA_7_P]
set_property PACKAGE_PIN A14         [get_ports ENA_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_8_P]
set_property PACKAGE_PIN A13         [get_ports ENA_8_P]
set_property PACKAGE_PIN A14         [get_ports ENA_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_8_N]

##########################CS VMM3##############################

set_property PACKAGE_PIN E19         [get_ports CS_1]
set_property IOSTANDARD LVCMOS12     [get_ports CS_1]

set_property PACKAGE_PIN E19         [get_ports CS_2]
set_property IOSTANDARD LVCMOS12     [get_ports CS_2]

set_property PACKAGE_PIN E19         [get_ports CS_3]
set_property IOSTANDARD LVCMOS12     [get_ports CS_3]

set_property PACKAGE_PIN E19         [get_ports CS_4]
set_property IOSTANDARD LVCMOS12     [get_ports CS_4]

set_property PACKAGE_PIN E19         [get_ports CS_5]
set_property IOSTANDARD LVCMOS12     [get_ports CS_5]

set_property PACKAGE_PIN E19         [get_ports CS_6]
set_property IOSTANDARD LVCMOS12     [get_ports CS_6]

set_property PACKAGE_PIN E19         [get_ports CS_7]
set_property IOSTANDARD LVCMOS12     [get_ports CS_7]

set_property PACKAGE_PIN E19         [get_ports CS_8]
set_property IOSTANDARD LVCMOS12     [get_ports CS_8]

##########################SCK VMM3##############################

set_property PACKAGE_PIN E19         [get_ports SCK_1]
set_property IOSTANDARD LVCMOS12     [get_ports SCK_1]

set_property PACKAGE_PIN E19         [get_ports SCK_2]
set_property IOSTANDARD LVCMOS12     [get_ports SCK_2]

set_property PACKAGE_PIN E19         [get_ports SCK_3]
set_property IOSTANDARD LVCMOS12     [get_ports SCK_3]

set_property PACKAGE_PIN E19         [get_ports SCK_4]
set_property IOSTANDARD LVCMOS12     [get_ports SCK_4]

set_property PACKAGE_PIN E19         [get_ports SCK_5]
set_property IOSTANDARD LVCMOS12     [get_ports SCK_5]

set_property PACKAGE_PIN E19         [get_ports SCK_6]
set_property IOSTANDARD LVCMOS12     [get_ports SCK_6]

set_property PACKAGE_PIN E19         [get_ports SCK_7]
set_property IOSTANDARD LVCMOS12     [get_ports SCK_7]

set_property PACKAGE_PIN E19         [get_ports SCK_8]
set_property IOSTANDARD LVCMOS12     [get_ports SCK_8]

##########################CKART VMM3##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_1_P]
set_property PACKAGE_PIN A13         [get_ports CKART_1_P]
set_property PACKAGE_PIN A14         [get_ports CKART_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_2_P]
set_property PACKAGE_PIN A13         [get_ports CKART_2_P]
set_property PACKAGE_PIN A14         [get_ports CKART_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_3_P]
set_property PACKAGE_PIN A13         [get_ports CKART_3_P]
set_property PACKAGE_PIN A14         [get_ports CKART_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_4_P]
set_property PACKAGE_PIN A13         [get_ports CKART_4_P]
set_property PACKAGE_PIN A14         [get_ports CKART_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_5_P]
set_property PACKAGE_PIN A13         [get_ports CKART_5_P]
set_property PACKAGE_PIN A14         [get_ports CKART_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_6_P]
set_property PACKAGE_PIN A13         [get_ports CKART_6_P]
set_property PACKAGE_PIN A14         [get_ports CKART_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_7_P]
set_property PACKAGE_PIN A13         [get_ports CKART_7_P]
set_property PACKAGE_PIN A14         [get_ports CKART_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_8_P]
set_property PACKAGE_PIN A13         [get_ports CKART_8_P]
set_property PACKAGE_PIN A14         [get_ports CKART_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_8_N]

##########################CKART ADDC##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_ADDC_P]
set_property PACKAGE_PIN A13         [get_ports CKART_ADDC_P]
set_property PACKAGE_PIN A14         [get_ports CKART_ADDC_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_ADDC_N]

###########################XADC MDT#############################
# Dedicated Analog Inputs
set_property IOSTANDARD LVCMOS25 [get_ports VP_0]
set_property PACKAGE_PIN L10 [get_ports VP_0]
set_property IOSTANDARD LVCMOS25 [get_ports VN_0]
set_property PACKAGE_PIN M9 [get_ports VN_0]

## Analog Multiplexer Pins
#set_property PACKAGE_PIN T20 [get_ports MuxAddr0]
#set_property IOSTANDARD LVCMOS33 [get_ports MuxAddr0]
#set_property PACKAGE_PIN P14 [get_ports MuxAddr1]
#set_property IOSTANDARD LVCMOS33 [get_ports MuxAddr1]
#set_property PACKAGE_PIN R14 [get_ports MuxAddr2]
#set_property IOSTANDARD LVCMOS33 [get_ports MuxAddr2]
#set_property PACKAGE_PIN R18 [get_ports MuxAddr3_p]
#set_property IOSTANDARD LVCMOS33 [get_ports MuxAddr3_p]
#set_property PACKAGE_PIN T18 [get_ports MuxAddr3_n]
#set_property IOSTANDARD LVCMOS33 [get_ports MuxAddr3_n]

#PDO
set_property PACKAGE_PIN G16 [get_ports Vaux8_v_n]
set_property PACKAGE_PIN G15 [get_ports Vaux8_v_p]

#TDO
set_property PACKAGE_PIN H14 [get_ports Vaux1_v_n]
set_property PACKAGE_PIN J14 [get_ports Vaux1_v_p]

#set_property PACKAGE_PIN J22 [get_ports Vaux2_v_p]
#set_property PACKAGE_PIN H22 [get_ports Vaux2_v_n]
#set_property PACKAGE_PIN K22 [get_ports Vaux3_v_n]
#set_property PACKAGE_PIN K21 [get_ports Vaux3_v_p]

#set_property PACKAGE_PIN H15 [get_ports Vaux9_v_n]
#set_property PACKAGE_PIN J15 [get_ports Vaux9_v_p]

#set_property PACKAGE_PIN G20 [get_ports Vaux10_v_n]
#set_property PACKAGE_PIN H20 [get_ports Vaux10_v_p]

#set_property PACKAGE_PIN N22 [get_ports Vaux10_v_n]
#set_property PACKAGE_PIN M22 [get_ports Vaux10_v_p]

#set_property PACKAGE_PIN L21 [get_ports Vaux11_v_n]
#set_property PACKAGE_PIN M21 [get_ports Vaux11_v_p]

#set_property PACKAGE_PIN L19 [get_ports Vaux11_v_n]
#set_property PACKAGE_PIN L20 [get_ports Vaux11_v_p]

#set_property IOSTANDARD LVCMOS12 [get_ports Vaux0_v_p]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux0_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux1_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux1_v_p]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux2_v_n]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux2_v_p]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux3_v_n]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux3_v_p]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux8_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux8_v_p]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux9_v_n]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux9_v_p]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux10_v_n]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux10_v_p]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux11_v_n]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux11_v_p]

######################### SPI FLASH ##########################

set_property CONFIG_MODE SPIx1 [current_design]
#set_property IOSTANDARD LVCMOS25 [get_ports SPI_CLK]
set_property IOSTANDARD LVCMOS25 [get_ports IO0_IO]
set_property IOSTANDARD LVCMOS25 [get_ports IO1_IO]
set_property IOSTANDARD LVCMOS25 [get_ports SS_IO]
#set_property PACKAGE_PIN V22 [get_ports SPI_CLK]
set_property PACKAGE_PIN P22 [get_ports IO0_IO]
set_property PACKAGE_PIN R22 [get_ports IO1_IO]
set_property PACKAGE_PIN T19 [get_ports SS_IO]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]
#set_property OFFCHIP_TERM NONE [get_ports SPI_CLK]
set_property OFFCHIP_TERM NONE [get_ports IO0_IO]
set_property OFFCHIP_TERM NONE [get_ports IO1_IO]
set_property OFFCHIP_TERM NONE [get_ports SS_IO]

##############################################################
