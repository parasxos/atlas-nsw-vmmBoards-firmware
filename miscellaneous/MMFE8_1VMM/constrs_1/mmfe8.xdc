#create_clock -period 5.000 -name independent_clock [get_pins independent_clock]
create_clock -period 5.000 -name X_2V5_DIFF_CLK_P -waveform {0.000 2.500} [get_ports independent_clock_p]
#create_clock -period 8.000 -name gtrefclk [get_pins gtrefclk]
create_clock -period 8.000 -name gtrefclk_p -waveform {0.000 4.000} [get_ports gtrefclk_p]

#create_clock -period 16.000 -name txoutclk [get_pins core_wrapper/transceiver_inst/gtwizard_inst/gt0_txoutclk_i_bufg/O]
create_clock -period 25.000 -name clk_in [get_ports clk_in]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets gtx_clk]

set_property PACKAGE_PIN F6 [get_ports gtrefclk_p]
set_property PACKAGE_PIN E6 [get_ports gtrefclk_n]

#set_property PACKAGE_PIN F10 [get_ports independent_clock_p]
#set_property PACKAGE_PIN E10 [get_ports independent_clock_n]

set_property IOSTANDARD LVDS_25 [get_ports X_2V5_DIFF_CLK_P]
set_property PACKAGE_PIN W19 [get_ports X_2V5_DIFF_CLK_P]
set_property PACKAGE_PIN W20 [get_ports X_2V5_DIFF_CLK_N]
set_property IOSTANDARD LVDS_25 [get_ports X_2V5_DIFF_CLK_N]

#-----------------------------------------------------------
# Top level I/O placement:                               -
#-----------------------------------------------------------

########################L1DDC##################################
#set_property PACKAGE_PIN C5 [get_ports txn]
#set_property PACKAGE_PIN D5 [get_ports txp]

#set_property PACKAGE_PIN C11 [get_ports rxn]
#set_property PACKAGE_PIN D11 [get_ports rxp]

#set_property PACKAGE_PIN V14 [get_ports phy_int]
#set_property IOSTANDARD LVCMOS25 [get_ports phy_int]

#set_property PACKAGE_PIN T14 [get_ports SDA_inout]
#set_property IOSTANDARD LVCMOS25 [get_ports SDA_inout]

#set_property PACKAGE_PIN V13 [get_ports SCL_out]
#set_property IOSTANDARD LVCMOS25 [get_ports SCL_out]

#set_property PACKAGE_PIN Y11 [get_ports phy_rstn_out]
#set_property IOSTANDARD LVCMOS25 [get_ports phy_rstn_out]

#set_property PACKAGE_PIN D2 [get_ports glbl_rst]
#set_property IOSTANDARD LVCMOS15 [get_ports glbl_rst]

########################MMFE8##################################

set_property PACKAGE_PIN A8 [get_ports rxn]
set_property PACKAGE_PIN B8 [get_ports rxp]
set_property PACKAGE_PIN A4 [get_ports txn]
set_property PACKAGE_PIN B4 [get_ports txp]

set_property PACKAGE_PIN N13 [get_ports SDA_inout]
set_property IOSTANDARD LVCMOS25 [get_ports SDA_inout]

set_property PACKAGE_PIN N14 [get_ports SCL_out]
set_property IOSTANDARD LVCMOS25 [get_ports SCL_out]

set_property PACKAGE_PIN P16 [get_ports phy_int]
set_property IOSTANDARD LVCMOS25 [get_ports phy_int]

set_property PACKAGE_PIN R17 [get_ports phy_rstn_out]
set_property IOSTANDARD LVCMOS25 [get_ports phy_rstn_out]

#set_property PACKAGE_PIN W19 [get_ports glbl_rst]
#set_property IOSTANDARD LVCMOS25 [get_ports glbl_rst]

########################MMFE8##################################
#set_property PACKAGE_PIN B1 [get_ports userclk2_out]
#set_property IOSTANDARD LVCMOS15 [get_ports userclk2_out]

#set_property PACKAGE_PIN A1 [get_ports half_full]
#set_property IOSTANDARD LVCMOS15 [get_ports half_full]

#set_property PACKAGE_PIN B2 [get_ports fifoempty]
#set_property IOSTANDARD LVCMOS15 [get_ports fifoempty]

#set_property PACKAGE_PIN F3 [get_ports clk_out0]
#set_property IOSTANDARD LVCMOS15 [get_ports clk_out0]

#set_property PACKAGE_PIN E3 [get_ports tx_outclk]
#set_property IOSTANDARD LVCMOS15 [get_ports tx_outclk]


#set_property PACKAGE_PIN G2 [get_ports oddr_out]
#set_property IOSTANDARD LVCMOS15 [get_ports oddr_out]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets oddr_out]

#set_property PACKAGE_PIN W19 [get_ports clk_in]
#set_property IOSTANDARD LVCMOS33 [get_ports clk_in]


#########################TRIGGER#############################
# CTF 1.0 External Trigger
set_property PACKAGE_PIN Y22 [get_ports EXT_TRIGGER_N]
set_property IOSTANDARD LVDS_25 [get_ports EXT_TRIGGER_N]
set_property PACKAGE_PIN Y21 [get_ports EXT_TRIGGER_P]
set_property IOSTANDARD LVDS_25 [get_ports EXT_TRIGGER_P]

# Arizona Board for External Trigger
#set_property PACKAGE_PIN Y21 [get_ports EXT_TRIG_IN]
#set_property IOSTANDARD LVCMOS25 [get_ports EXT_TRIG_IN]

#########################DATA0#############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_1_P]
set_property PACKAGE_PIN J17 [get_ports DATA0_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_2_P]
set_property PACKAGE_PIN G18 [get_ports DATA0_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_3_P]
set_property PACKAGE_PIN B18 [get_ports DATA0_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_4_P]
set_property PACKAGE_PIN C19 [get_ports DATA0_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_5_P]
set_property PACKAGE_PIN D1 [get_ports DATA0_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_6_P]
set_property PACKAGE_PIN L1 [get_ports DATA0_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_7_P]
set_property PACKAGE_PIN AA4 [get_ports DATA0_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_8_P]
set_property PACKAGE_PIN AA6 [get_ports DATA0_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_8_N]

#########################DATA1#############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_1_P]
set_property PACKAGE_PIN K14 [get_ports DATA1_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_2_P]
set_property PACKAGE_PIN H18 [get_ports DATA1_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_3_P]
set_property PACKAGE_PIN B16 [get_ports DATA1_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_4_P]
set_property PACKAGE_PIN C20 [get_ports DATA1_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_5_P]
set_property PACKAGE_PIN D2 [get_ports DATA1_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_6_P]
set_property PACKAGE_PIN K3 [get_ports DATA1_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_7_P]
set_property PACKAGE_PIN Y2 [get_ports DATA1_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_8_P]
set_property PACKAGE_PIN Y7 [get_ports DATA1_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_8_N]

##########################DI##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_1_P]
set_property PACKAGE_PIN L13 [get_ports DI_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_2_P]
set_property PACKAGE_PIN L20 [get_ports DI_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_3_P]
set_property PACKAGE_PIN B13 [get_ports DI_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_4_P]
set_property PACKAGE_PIN E18 [get_ports DI_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_5_P]
set_property PACKAGE_PIN G3 [get_ports DI_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_6_P]
set_property PACKAGE_PIN L4 [get_ports DI_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_7_P]
set_property PACKAGE_PIN Y9 [get_ports DI_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_8_P]
set_property PACKAGE_PIN V8 [get_ports DI_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_8_N]

##########################DO##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_1_P]
set_property PACKAGE_PIN M20 [get_ports DO_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_2_P]
set_property PACKAGE_PIN E17 [get_ports DO_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_3_P]
set_property PACKAGE_PIN D15 [get_ports DO_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_4_P]
set_property PACKAGE_PIN A19 [get_ports DO_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_5_P]
set_property PACKAGE_PIN J2 [get_ports DO_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_6_P]
set_property PACKAGE_PIN N3 [get_ports DO_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_7_P]
set_property PACKAGE_PIN Y1 [get_ports DO_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_8_P]
set_property PACKAGE_PIN T6 [get_ports DO_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_8_N]

##########################CKBC##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_1_P]
set_property PACKAGE_PIN N19 [get_ports CKBC_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_2_P]
set_property PACKAGE_PIN M22 [get_ports CKBC_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_3_P]
set_property PACKAGE_PIN E14 [get_ports CKBC_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_4_P]
set_property PACKAGE_PIN F20 [get_ports CKBC_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_5_P]
set_property PACKAGE_PIN J1 [get_ports CKBC_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_6_P]
set_property PACKAGE_PIN J6 [get_ports CKBC_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_7_P]
set_property PACKAGE_PIN R2 [get_ports CKBC_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_8_P]
set_property PACKAGE_PIN U5 [get_ports CKBC_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_8_N]

##########################CKTP##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_1_P]
set_property PACKAGE_PIN K16 [get_ports CKTP_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_2_P]
set_property PACKAGE_PIN F14 [get_ports CKTP_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_3_P]
set_property PACKAGE_PIN B22 [get_ports CKTP_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_4_P]
set_property PACKAGE_PIN N2 [get_ports CKTP_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_5_P]
set_property PACKAGE_PIN G2 [get_ports CKTP_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_6_P]
set_property PACKAGE_PIN M2 [get_ports CKTP_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_7_P]
set_property PACKAGE_PIN V3 [get_ports CKTP_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_8_P]
set_property PACKAGE_PIN T4 [get_ports CKTP_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_8_N]

##########################CKTK##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_1_P]
set_property PACKAGE_PIN H19 [get_ports CKTK_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_2_P]
set_property PACKAGE_PIN G22 [get_ports CKTK_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_3_P]
set_property PACKAGE_PIN A16 [get_ports CKTK_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_4_P]
set_property PACKAGE_PIN A20 [get_ports CKTK_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_5_P]
set_property PACKAGE_PIN B2 [get_ports CKTK_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_6_P]
set_property PACKAGE_PIN P4 [get_ports CKTK_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_7_P]
set_property PACKAGE_PIN AB2 [get_ports CKTK_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_8_P]
set_property PACKAGE_PIN AB8 [get_ports CKTK_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_8_N]

##########################WEN##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_1_P]
set_property PACKAGE_PIN M16 [get_ports WEN_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_2_P]
set_property PACKAGE_PIN D22 [get_ports WEN_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_3_P]
set_property PACKAGE_PIN D16 [get_ports WEN_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_4_P]
set_property PACKAGE_PIN N5 [get_ports WEN_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_5_P]
set_property PACKAGE_PIN H5 [get_ports WEN_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_6_P]
set_property PACKAGE_PIN P1 [get_ports WEN_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_7_P]
set_property PACKAGE_PIN AA3 [get_ports WEN_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_8_P]
set_property PACKAGE_PIN V5 [get_ports WEN_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_8_N]
##########################ENA##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_1_P]
set_property PACKAGE_PIN L18 [get_ports ENA_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_2_P]
set_property PACKAGE_PIN K19 [get_ports ENA_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_3_P]
set_property PACKAGE_PIN A14 [get_ports ENA_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_4_P]
set_property PACKAGE_PIN D19 [get_ports ENA_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_5_P]
set_property PACKAGE_PIN F1 [get_ports ENA_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_6_P]
set_property PACKAGE_PIN J4 [get_ports ENA_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_7_P]
set_property PACKAGE_PIN AB5 [get_ports ENA_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_8_P]
set_property PACKAGE_PIN W7 [get_ports ENA_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_8_N]

##########################CKDT##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_1_P]
set_property PACKAGE_PIN J21 [get_ports CKDT_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_2_P]
set_property PACKAGE_PIN C15 [get_ports CKDT_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_3_P]
set_property PACKAGE_PIN A21 [get_ports CKDT_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_4_P]
set_property PACKAGE_PIN A1 [get_ports CKDT_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_5_P]
set_property PACKAGE_PIN E3 [get_ports CKDT_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_6_P]
set_property PACKAGE_PIN V2 [get_ports CKDT_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_7_P]
set_property PACKAGE_PIN W4 [get_ports CKDT_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_8_P]
set_property PACKAGE_PIN AB6 [get_ports CKDT_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_8_N]



#set_false_path -from [get_cells */*/*/gt0_txresetfsm_i/*time_out_wait_bypass] -to [get_cells */*/*/gt0_txresetfsm_i/time_out_wait_bypass_*]
#set_false_path -from [get_cells */*/*/gt0_txresetfsm_i/*run_phase_alignment_int] -to [get_cells */*/*/gt0_txresetfsm_i/*run_phase_alignment_int_*]
#set_false_path -from [get_cells */*/*/gt0_txresetfsm_i/*tx_fsm_reset_done_int] -to [get_cells */*/*/gt0_txresetfsm_i/*tx_fsm_reset_done_int_*]
#set_false_path -from [get_cells */*/*/gt0_txresetfsm_i/*TXRESETDONE] -to [get_cells */*/*/gt0_txresetfsm_i/*txresetdone_*]
#set_false_path -from [get_cells */*/*/gt0_rxresetfsm_i/*time_out_wait_bypass] -to [get_cells */*/*/gt0_rxresetfsm_i/time_out_wait_bypass_*]
#set_false_path -from [get_cells */*/*/gt0_rxresetfsm_i/*run_phase_alignment_int] -to [get_cells */*/*/gt0_rxresetfsm_i/*run_phase_alignment_int_*]
#set_false_path -from [get_cells */*/*/gt0_rxresetfsm_i/*rx_fsm_reset_done_int] -to [get_cells */*/*/gt0_rxresetfsm_i/*rx_fsm_reset_done_int_*]
#set_false_path -from [get_cells */*/*/gt0_rxresetfsm_i/*RXRESETDONE] -to [get_cells */*/*/gt0_rxresetfsm_i/*rxresetdone_*]




set_max_delay 10.000 -from [get_cells *user_side_FIFO/tx_fifo_i/*rd_addr_txfer*] -to [get_cells *user_side_FIFO/tx_fifo_i/wr_rd_addr*]

connect_debug_port dbg_hub/clk [get_nets clk]


set_property IOSTANDARD LVCMOS25 [get_ports EXT_TRIG_IN]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_200]
