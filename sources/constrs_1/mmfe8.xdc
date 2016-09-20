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

###########################XADC#############################
# Dedicated Analog Inputs
set_property IOSTANDARD LVCMOS25 [get_ports VP_0]
set_property PACKAGE_PIN L10 [get_ports VP_0]
set_property IOSTANDARD LVCMOS25 [get_ports VN_0]
set_property PACKAGE_PIN M9 [get_ports VN_0]

# Analog Multiplexer Pins
set_property PACKAGE_PIN T20 [get_ports MuxAddr0]
set_property IOSTANDARD LVCMOS25 [get_ports MuxAddr0]
set_property PACKAGE_PIN P14 [get_ports MuxAddr1]
set_property IOSTANDARD LVCMOS25 [get_ports MuxAddr1]
set_property PACKAGE_PIN R14 [get_ports MuxAddr2]
set_property IOSTANDARD LVCMOS25 [get_ports MuxAddr2]
set_property PACKAGE_PIN R18 [get_ports MuxAddr3_p]
set_property IOSTANDARD LVCMOS25 [get_ports MuxAddr3_p]
set_property PACKAGE_PIN T18 [get_ports MuxAddr3_n]
set_property IOSTANDARD LVCMOS25 [get_ports MuxAddr3_n]

# PDO Inputs
set_property PACKAGE_PIN G13 [get_ports Vaux0_v_n]
set_property PACKAGE_PIN H13 [get_ports Vaux0_v_p]
set_property PACKAGE_PIN H14 [get_ports Vaux1_v_n]
set_property PACKAGE_PIN J14 [get_ports Vaux1_v_p]
set_property PACKAGE_PIN J22 [get_ports Vaux2_v_p]
set_property PACKAGE_PIN H22 [get_ports Vaux2_v_n]
set_property PACKAGE_PIN K22 [get_ports Vaux3_v_n]
set_property PACKAGE_PIN K21 [get_ports Vaux3_v_p]
set_property PACKAGE_PIN G16 [get_ports Vaux8_v_n]
set_property PACKAGE_PIN G15 [get_ports Vaux8_v_p]
set_property PACKAGE_PIN H15 [get_ports Vaux9_v_n]
set_property PACKAGE_PIN J15 [get_ports Vaux9_v_p]
set_property PACKAGE_PIN G20 [get_ports Vaux10_v_n]
set_property PACKAGE_PIN H20 [get_ports Vaux10_v_p]
set_property PACKAGE_PIN L21 [get_ports Vaux11_v_n]
set_property PACKAGE_PIN M21 [get_ports Vaux11_v_p]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux0_v_p]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux0_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux1_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux1_v_p]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux2_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux2_v_p]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux3_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux3_v_p]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux8_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux8_v_p]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux9_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux9_v_p]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux10_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux10_v_p]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux11_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux11_v_p]



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

#======================= SPI Flash Constraints =======================
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

# this is to ensure min routing delay from SCK generation to STARTUP input
# User should change this value based on the results
# having more delay on this net reduces the Fmax
set_max_delay -datapath_only -from [get_pins -hier *SCK_O_reg_reg/C] -to [get_pins -hier *USRCCLKO] 1.500
set_min_delay -from [get_pins -hier *SCK_O_reg_reg/C] -to [get_pins -hier *USRCCLKO] 0.100
# Following command creates a divide by 2 clock
# It also takes into account the delay added by STARTUP block to route the CCLK
# create_generated_clock -name clk_sck -source [get_pins -hierarchical *axi_quad_spi_0/ext_spi_clk] [get_pins -hierarchical *USRCCLKO] -edges {3 5 7} -edge_shift [list $cclk_delay $cclk_delay $cclk_delay]
create_generated_clock -name clk_sck -source [get_pins -hierarchical *axi_SPI/ext_spi_clk] [get_pins -hierarchical *USRCCLKO] -edges {3 5 7} -edge_shift {6.700 6.700 6.700}
# Data is captured into FPGA on the second rising edge of ext_spi_clk after the SCK falling edge
# Data is driven by the FPGA on every alternate rising_edge of ext_spi_clk
set_input_delay -clock clk_sck -clock_fall -max 7.450 [get_ports IO*_IO]
set_input_delay -clock clk_sck -clock_fall -min 1.450 [get_ports IO*_IO]
set_multicycle_path -setup -from clk_sck -to [get_clocks -of_objects [get_pins -hierarchical *ext_spi_clk]] 2
set_multicycle_path -hold -end -from clk_sck -to [get_clocks -of_objects [get_pins -hierarchical *ext_spi_clk]] 1
# Data is captured into SPI on the following rising edge of SCK
# Data is driven by the IP on alternate rising_edge of the ext_spi_clk
set_output_delay -clock clk_sck -max 2.050 [get_ports IO*_IO]
set_output_delay -clock clk_sck -min -2.950 [get_ports IO*_IO]
set_multicycle_path -setup -start -from [get_clocks -of_objects [get_pins -hierarchical *ext_spi_clk]] -to clk_sck 2
set_multicycle_path -hold -from [get_clocks -of_objects [get_pins -hierarchical *ext_spi_clk]] -to clk_sck 1
#======================= SPI Flash Constraints =======================


set_max_delay 10.000 -from [get_cells *user_side_FIFO/tx_fifo_i/*rd_addr_txfer*] -to [get_cells *user_side_FIFO/tx_fifo_i/wr_rd_addr*]
connect_debug_port dbg_hub/clk [get_nets clk]
set_property IOSTANDARD LVCMOS25 [get_ports EXT_TRIG_IN]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_200]
