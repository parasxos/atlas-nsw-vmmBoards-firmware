----------------------------------------------------------------------------------
-- Company: NTU ATHENS - BNL
-- Engineer: Paris Moschovakos & Panagiotis Gkountoumis
-- 
-- Create Date: 16.3.2016
-- Design Name: MMFE8
-- Module Name: mmfe8_top
-- Project Name: MMFE8 
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
--
-- Changelog:
-- 
----------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;

entity mmfe8_top is
    port(
        -- Trigger pins
        -- CTF 1.0 External Trigger
        EXT_TRIGGER_P       : in std_logic;
        EXT_TRIGGER_N       : in std_logic;
        -- Arizona Board for External Trigger
--        EXT_TRIG_IN         : in std_logic;

        TRIGGER_LOOP_P      : out std_logic;
        TRIGGER_LOOP_N      : out std_logic;

        -- LED's
        LED_BANK_13         : out std_logic;
        LED_BANK_14         : out std_logic;
        LED_BANK_15         : out std_logic;
        LED_BANK_16         : out std_logic;
        LED_BANK_34         : out std_logic;
        LED_BANK_35         : out std_logic;

        -- 200.0359MHz from bank 14
        X_2V5_DIFF_CLK_P    : in std_logic;
        X_2V5_DIFF_CLK_N    : in std_logic;        		
--        glbl_rst		    : in std_logic;

        -- Tranceiver Interface
        -----------------------
        gtrefclk_p            : in  std_logic;                     -- Differential +ve of reference clock for tranceiver: 125MHz, very high quality
        gtrefclk_n            : in  std_logic;                     -- Differential -ve of reference clock for tranceiver: 125MHz, very high quality
        txp                   : out std_logic;                     -- Differential +ve of serial transmission from PMA to PMD.
        txn                   : out std_logic;                     -- Differential -ve of serial transmission from PMA to PMD.
        rxp                   : in  std_logic;                     -- Differential +ve for serial reception from PMD to PMA.
        rxn                   : in  std_logic;                     -- Differential -ve for serial reception from PMD to PMA.
        phy_int               : out std_logic;
        phy_rstn_out 		  : out std_logic;
        
        DATA0_1_P, DATA0_1_N  : IN STD_LOGIC;
        DATA0_2_P, DATA0_2_N  : IN STD_LOGIC;
        DATA0_3_P, DATA0_3_N  : IN STD_LOGIC;
        DATA0_4_P, DATA0_4_N  : IN STD_LOGIC;
        DATA0_5_P, DATA0_5_N  : IN STD_LOGIC;
        DATA0_6_P, DATA0_6_N  : IN STD_LOGIC;
        DATA0_7_P, DATA0_7_N  : IN STD_LOGIC;
        DATA0_8_P, DATA0_8_N  : IN STD_LOGIC;

        DATA1_1_P, DATA1_1_N  : IN STD_LOGIC;
        DATA1_2_P, DATA1_2_N  : IN STD_LOGIC;
        DATA1_3_P, DATA1_3_N  : IN STD_LOGIC;
        DATA1_4_P, DATA1_4_N  : IN STD_LOGIC;
        DATA1_5_P, DATA1_5_N  : IN STD_LOGIC;
        DATA1_6_P, DATA1_6_N  : IN STD_LOGIC;
        DATA1_7_P, DATA1_7_N  : IN STD_LOGIC;
        DATA1_8_P, DATA1_8_N  : IN STD_LOGIC;

        DO_1_P, DO_1_N        : IN STD_LOGIC;
        DO_2_P, DO_2_N        : IN STD_LOGIC;
        DO_3_P, DO_3_N        : IN STD_LOGIC;
        DO_4_P, DO_4_N        : IN STD_LOGIC;
        DO_5_P, DO_5_N        : IN STD_LOGIC;
        DO_6_P, DO_6_N        : IN STD_LOGIC;
        DO_7_P, DO_7_N        : IN STD_LOGIC;
        DO_8_P, DO_8_N        : IN STD_LOGIC;

        DI_1_P, DI_1_N        : OUT STD_LOGIC;
        DI_2_P, DI_2_N        : OUT STD_LOGIC;
        DI_3_P, DI_3_N        : OUT STD_LOGIC;
        DI_4_P, DI_4_N        : OUT STD_LOGIC;
        DI_5_P, DI_5_N        : OUT STD_LOGIC;
        DI_6_P, DI_6_N        : OUT STD_LOGIC;
        DI_7_P, DI_7_N        : OUT STD_LOGIC;
        DI_8_P, DI_8_N        : OUT STD_LOGIC;

        WEN_1_P, WEN_1_N      : OUT STD_LOGIC;
        WEN_2_P, WEN_2_N      : OUT STD_LOGIC;
        WEN_3_P, WEN_3_N      : OUT STD_LOGIC;
        WEN_4_P, WEN_4_N      : OUT STD_LOGIC;
        WEN_5_P, WEN_5_N      : OUT STD_LOGIC;
        WEN_6_P, WEN_6_N      : OUT STD_LOGIC;
        WEN_7_P, WEN_7_N      : OUT STD_LOGIC;
        WEN_8_P, WEN_8_N      : OUT STD_LOGIC;

        ENA_1_P, ENA_1_N      : OUT STD_LOGIC;
        ENA_2_P, ENA_2_N      : OUT STD_LOGIC;
        ENA_3_P, ENA_3_N      : OUT STD_LOGIC;
        ENA_4_P, ENA_4_N      : OUT STD_LOGIC;
        ENA_5_P, ENA_5_N      : OUT STD_LOGIC;
        ENA_6_P, ENA_6_N      : OUT STD_LOGIC;
        ENA_7_P, ENA_7_N      : OUT STD_LOGIC;
        ENA_8_P, ENA_8_N      : OUT STD_LOGIC;

        CKTK_1_P, CKTK_1_N    : OUT STD_LOGIC;
        CKTK_2_P, CKTK_2_N    : OUT STD_LOGIC;
        CKTK_3_P, CKTK_3_N    : OUT STD_LOGIC;
        CKTK_4_P, CKTK_4_N    : OUT STD_LOGIC;
        CKTK_5_P, CKTK_5_N    : OUT STD_LOGIC;
        CKTK_6_P, CKTK_6_N    : OUT STD_LOGIC;
        CKTK_7_P, CKTK_7_N    : OUT STD_LOGIC;
        CKTK_8_P, CKTK_8_N    : OUT STD_LOGIC;
    
        CKTP_1_P, CKTP_1_N	  :	OUT	STD_LOGIC;
        CKTP_2_P, CKTP_2_N	  :	OUT	STD_LOGIC;
        CKTP_3_P, CKTP_3_N	  :	OUT	STD_LOGIC;
        CKTP_4_P, CKTP_4_N	  :	OUT	STD_LOGIC;
        CKTP_5_P, CKTP_5_N	  :	OUT	STD_LOGIC;
        CKTP_6_P, CKTP_6_N	  :	OUT	STD_LOGIC;
        CKTP_7_P, CKTP_7_N	  :	OUT	STD_LOGIC;
        CKTP_8_P, CKTP_8_N	  :	OUT	STD_LOGIC;
    
        CKBC_1_P, CKBC_1_N    : OUT STD_LOGIC;
        CKBC_2_P, CKBC_2_N    : OUT STD_LOGIC;
        CKBC_3_P, CKBC_3_N    : OUT STD_LOGIC;
        CKBC_4_P, CKBC_4_N    : OUT STD_LOGIC;
        CKBC_5_P, CKBC_5_N    : OUT STD_LOGIC;
        CKBC_6_P, CKBC_6_N    : OUT STD_LOGIC;
        CKBC_7_P, CKBC_7_N    : OUT STD_LOGIC;
        CKBC_8_P, CKBC_8_N    : OUT STD_LOGIC;
    
        CKDT_1_P, CKDT_1_N    : OUT STD_LOGIC;
        CKDT_2_P, CKDT_2_N    : OUT STD_LOGIC;
        CKDT_3_P, CKDT_3_N    : OUT STD_LOGIC;
        CKDT_4_P, CKDT_4_N    : OUT STD_LOGIC;
        CKDT_5_P, CKDT_5_N    : OUT STD_LOGIC;
        CKDT_6_P, CKDT_6_N    : OUT STD_LOGIC;
        CKDT_7_P, CKDT_7_N    : OUT STD_LOGIC;
        CKDT_8_P, CKDT_8_N    : OUT STD_LOGIC             
	  );
end mmfe8_top;

architecture Behavioral of mmfe8_top is

    -- IP and MAC address of the MMFE8
    constant myIP   : std_logic_vector(31 downto 0) := x"c0a80002";
    constant myMAC  : std_logic_vector(47 downto 0) := x"002320212223";
    constant destIP : std_logic_vector(31 downto 0) := x"c0a80010";

  -- clock generation signals for tranceiver
  signal gtrefclkp, gtrefclkn  : std_logic;                    -- Route gtrefclk through an IBUFG.
  signal txoutclk              : std_logic;                    -- txoutclk from GT transceiver
  signal resetdone             : std_logic;                    -- To indicate that the GT transceiver has completed its reset cycle
  signal mmcm_locked           : std_logic;                    -- MMCM locked signal.
  signal mmcm_reset            : std_logic;                    -- MMCM reset signal.
  signal clkfbout              : std_logic;                    -- MMCM feedback clock
  signal userclk               : std_logic;                    -- 62.5MHz clock for GT transceiver Tx/Rx user clocks
  signal userclk2              : std_logic;                    -- 125MHz clock for core reference clock.
  -- PMA reset generation signals for tranceiver
  signal pma_reset_pipe        : std_logic_vector(3 downto 0); -- flip-flop pipeline for reset duration stretch
  signal pma_reset             : std_logic;                    -- Synchronous transcevier PMA reset
  -- An independent clock source used as the reference clock for an
  -- IDELAYCTRL (if present) and for the main GT transceiver reset logic.
  signal independent_clock_bufg: std_logic;
  -- clock generation signals for SGMII clock
  signal sgmii_clk_r           : std_logic;                    -- Clock to client MAC (125MHz, 12.5MHz or 1.25MHz) (to rising edge DDR).
  signal sgmii_clk_f           : std_logic;                    -- Clock to client MAC (125MHz, 12.5MHz or 1.25MHz) (to falling edge DDR).
  -- GMII signals
  signal gmii_isolate          : std_logic;                    -- Internal gmii_isolate signal.
  signal gmii_txd_int          : std_logic_vector(7 downto 0); -- Internal gmii_txd signal (between core and SGMII adaptation module).
  signal gmii_tx_en_int        : std_logic;                    -- Internal gmii_tx_en signal (between core and SGMII adaptation module).
  signal gmii_tx_er_int        : std_logic;                    -- Internal gmii_tx_er signal (between core and SGMII adaptation module).
  signal gmii_rxd_int          : std_logic_vector(7 downto 0); -- Internal gmii_rxd signal (between core and SGMII adaptation module).
  signal gmii_rx_dv_int        : std_logic;                    -- Internal gmii_rx_dv signal (between core and SGMII adaptation module).
  signal gmii_rx_er_int        : std_logic;                    -- Internal gmii_rx_er signal (between core and SGMII adaptation module).

  -- Extra registers to ease IOB placement
  signal status_vector_int : std_logic_vector(15 downto 0);
  
  ----------------------------panos---------------------------------
  signal gmii_txd_emac 			     : std_logic_vector(7 downto 0);
  signal gmii_tx_en_emac		     : std_logic; 
  signal gmii_tx_er_emac		     : std_logic; 
  signal gmii_rxd_emac 			     : std_logic_vector(7 downto 0);
  signal gmii_rx_dv_emac		     : std_logic; 
  signal gmii_rx_er_emac		     : std_logic; 
  signal sgmii_clk_int			     : std_logic;
  signal speed_is_10_100		     : std_logic;
  signal speed_is_100			     : std_logic;
  signal tx_axis_mac_tready_int      : std_logic;
  signal rx_axis_mac_tuser_int       : std_logic;
  signal rx_axis_mac_tlast_int       : std_logic;
  signal rx_axis_mac_tdata_int       : std_logic_vector(7 downto 0);
  signal rx_axis_mac_tvalid_int      : std_logic;
  signal local_gtx_reset		     : std_logic;
  signal rx_reset		 			 : std_logic;
  signal tx_reset		 			 : std_logic;
  signal gtx_pre_resetn              : std_logic := '0';
  signal tx_axis_mac_tdata_int       : std_logic_vector(7 downto 0);	
  signal tx_axis_mac_tvalid_int      : std_logic;
  signal tx_axis_mac_tlast_int       : std_logic;  
  signal gtx_resetn				     : std_logic;
  signal glbl_rstn        	         : std_logic;
  signal glbl_rst_i        	         : std_logic;
  signal gtx_clk_reset_int		     : std_logic;
  signal an_restart_config_int       : std_logic;
  signal rx_axis_mac_tready_int      : std_logic;
  signal rx_configuration_vector_int : std_logic_vector(79 downto 0);
  signal tx_configuration_vector_int : std_logic_vector(79 downto 0);
  signal vector_resetn               : std_logic := '0';
  signal vector_pre_resetn           : std_logic := '0';
  signal vector_reset_int            : std_logic;
  signal independent_clock_int       : std_logic;
  signal rst_gtclk_int				 : std_logic;
  signal clk_enable_int				 : std_logic;
  signal sgmii_clk_int_oddr			 : std_logic;
  signal udp_txi_int				 : udp_tx_type;
  signal control                     : udp_control_type;
  signal udp_rx_int                  : udp_rx_type;
  signal ip_rx_hdr_int               : ipv4_rx_header_type;
  signal udp_tx_data_out_ready_int	 : std_logic;
  signal udp_tx_start_int			 : std_logic;
  signal rxp_int                     : std_logic;
  signal rxn_int		             : std_logic;
  signal clkfbout2, clkfbout1        : std_logic;
  signal tx_axis_mac_tuser_int       : std_logic := '1';
  signal test_data                   : std_logic_vector(7 downto 0); 
  signal test_valid, test_last       : std_logic;
  
  signal test_data_out                   : std_logic_vector(7 downto 0); 
  signal test_valid_out, test_last_out       : std_logic;  
  signal user_data_out_i             : std_logic_vector(63 downto 0);
  signal sig_out200                  : std_logic_vector(127 downto 0);
  signal user_conf_i                 : std_logic := '0'; 
  signal send_error_int              : std_logic := '0';
  signal send_error_done_int         : std_logic := '0';
  signal resp_data_int               : resp_data;
  signal user_wr_en_int              : std_logic := '0';
  signal reset                       : std_logic := '0';
  signal end_packet_i                : std_logic := '0';    
  signal conf_done_int_synced        : std_logic := '0';
  signal we_conf_int                 : std_logic := '0';    
  signal packet_length_int           : std_logic_vector(11 downto 0);
  signal daq_data_out_i              : std_logic_vector(63 downto 0);
  signal conf_data_out_i             : std_logic_vector(63 downto 0);
  
  signal daq_wr_en_i                 : std_logic := '0';    
  signal end_packet_daq              : std_logic := '0';
  
  signal start_conf_proc_int         : std_logic := '0';

  signal status_int_old               : std_logic_vector(3 downto 0);

  ------------------------------VMM configuration------------------------------
  signal vmm_do_vec_i                 : std_logic_vector(8 downto 1);
  signal conf_cktk_out_i              : std_logic := '0';

  ------------------------------ Select VMM ------------------------------
  signal conf_cktk_out_vec_i          : std_logic_vector(8 downto 1);
  signal conf_vmm_wen_vec             : std_logic_vector(8 downto 1);
  signal conf_vmm_ena_vec             : std_logic_vector(8 downto 1);

  -------------------------------------------------
  -- Configuration Signals
  -------------------------------------------------
  signal configuring_i      : std_logic;
  signal reading_i_200      : std_logic;
  signal conf_done_i_200    : std_logic;
  signal cntr, cntr2        : integer := 0;
  signal vmm_cnt, counter   : integer := 0;
  signal reset_done         : std_logic := '0';

  signal vmm_data0_1_syn    : std_logic;
  signal vmm_data1_1_syn    : std_logic;
  signal vmm_data0_ii_d     : std_logic;
  signal vmm_data0_ii       : std_logic;
  signal vmm_data0_i        : std_logic;
  signal vmm_do_fde_sync    : std_logic;
  signal vmm_do_fde         : std_logic;
  signal vmm_do_fde_i       : std_logic;
  signal delay_wen          : integer := 0;
  signal w                  : integer := 0;

  signal probe0_out         : std_logic_vector(127 DOWNTO 0);

  signal data_fifo_wr_en    : std_logic;
  signal data_fifo_wr_en_i  : std_logic;
  signal data_fifo_din_i    : std_logic_vector(7 DOWNTO 0);
  signal data_fifo_rd_en    : std_logic;
  signal data_fifo_rd_en_i  : std_logic;
  --  signal data_fifo_dout_i   : std_logic_vector(0 DOWNTO 0);
  signal data_fifo_empty    : std_logic;
  signal data_fifo_rd_count : std_logic_vector(14 DOWNTO 0);
  signal data_fifo_wr_count : std_logic_vector(14 DOWNTO 0);
  signal vmm_cfg_sel_i      : std_logic_vector(31 downto 0);
  signal turn_counter_i     : std_logic_vector(15 downto 0);
  signal conf_data_in_i     : std_logic_vector (7 downto 0); 
  signal udp_response_int   : udp_response; 
  
  signal clk_400_noclean  : std_logic;
  signal clk_400_clean    : std_logic;
  signal clk_200          : std_logic;
  signal clk_800          : std_logic;
  signal clk_10_phase45   : std_logic;
  signal clk_50           : std_logic;
  signal clk_40           : std_logic;
  signal clk_10           : std_logic;
  signal gbl_rst          : std_logic;    --coming from UDP
  signal acq_rst          : std_logic;    --coming from UDP

  signal vmm_ena_gbl_rst  : std_logic := '0';
  signal vmm_wen_gbl_rst  : std_logic := '0';
  signal vmm_ena_acq_rst  : std_logic := '0';
  signal vmm_wen_acq_rst  : std_logic := '0';
--  signal conf_data_out_i  : std_logic_vector(7 downto 0);
  signal vmm_data_buf_i   : std_logic_vector(37 downto 0);

  -- vmm signals
  signal conf_di_i        : std_logic;
  signal conf_do_i        : std_logic;
  signal conf_ena_i       : std_logic := '0';
  signal conf_wen_i       : std_logic;
  signal conf_cktk_i      : std_logic;

  signal vmm_do_1_i       : std_logic := '0';
  signal vmm_di_en        : std_logic;
  signal vmm_di_r         : std_logic;
  signal vmm_wen_en       : std_logic;
  signal vmm_wen_R        : std_logic;
  signal vmm_ena_en       : std_logic;
  signal vmm_ena_r        : std_logic;
  signal vmm_cktk_en      : std_logic;
  signal vmm_cktk_r       : std_logic;
  signal vmm_cktp         : std_logic;
  signal vmm_cktp_en      : std_logic;
  signal vmm_cktp_r       : std_logic;
  signal vmm_ckbc         : std_logic;
  signal vmm_ckbc_en      : std_logic;
  signal vmm_ckbc_R       : std_logic;  

  signal dt_cntr_intg0_i    : integer;
  signal ckdt_cntr, timeout : integer := 0;
  signal dt_cntr_intg1_i    : integer;
  signal conf_cnt           : integer := 0;
  signal cnt_vmm            : integer := 0;
--  signal timeout            : integer := 0;
  signal vmm_2cfg_i         : std_logic_vector( 2 DOWNTO 0);
  signal mmfeID_i           : std_logic_vector( 3 DOWNTO 0);
  signal clk_dt_out           : std_logic;
  signal vmm_ckart          : std_logic;
  signal vmm_ckart_en       : std_logic;
  signal vmm_ckart_r        : std_logic;
  signal clk_tk_out         : std_logic;
  signal clk_bc_out         : std_logic;
  signal testX, reading_i   : std_logic := '0';
  signal clk_tp_out         : std_logic ;
  signal write_done_i       : std_logic;
  signal fifo_writing_i     : std_logic;
  signal global_reset       : std_logic := '0';
  signal conf_done_i        : std_logic;
  signal cktp_send          : std_logic := '0';
  signal conf_wait          : std_logic := '0';  
  signal udp_tx_start_reply : std_logic := '0';
  signal udp_tx_start_daq   : std_logic := '0';
  signal re_out_int         : std_logic := '0';
  signal fifo_data_out_int  : std_logic_vector(7 downto 0) := x"00";
  signal fifo_data          : std_logic_vector(7 downto 0) := x"00";
  signal re_out             : std_logic := '0';
  signal status_int         : std_logic_vector(3 downto 0) := "0000";
  signal status_int_synced  : std_logic_vector(3 downto 0) := "0000";
    signal cnt_reset          : integer := 0;
  signal set_reset          : std_logic := '0';
  
  signal conf_done_int      : std_logic := '0';
  signal udp_header_int     : std_logic := '0';
  signal cnt_reply          : integer := 0;
  
  signal end_packet_conf_int     : std_logic := '0';
  signal end_packet_daq_int     : std_logic := '0';
  signal is_state         : std_logic_vector(3 downto 0) := "1010";
  signal ACQ_sync_int       : std_logic_vector := x"0000";
  signal udp_busy           : std_logic := '0';

    -------------------------------------------------
    -- VMM2 Signals                   
    -------------------------------------------------
    signal vmm_wen_vec      : std_logic_vector(8 downto 1);
    signal vmm_ena_vec      : std_logic_vector(8 downto 1);
    signal cktk_out_vec     : std_logic_vector(8 downto 1);
    signal ckdt_out_vec     : std_logic_vector(8 downto 1);
    signal data0_in_vec     : std_logic_vector(8 downto 1);
    signal data1_in_vec     : std_logic_vector(8 downto 1);
    signal vmm_do_vec       : std_logic_vector(8 downto 1);
    signal vmm_di_vec_i     : std_logic_vector(8 downto 1);

    signal cktk_out_i       : std_logic;
    signal vmm_id           : std_logic_vector(15 downto 0) := x"0000";
    signal vmm_id_int       : std_logic_vector(15 downto 0) := x"0000";
    signal vmm_id_synced    : std_logic_vector(15 downto 0) := x"0000";
    signal vmm_id_old       : std_logic_vector(15 downto 0) := x"0000";
    
    signal vmm_cktp_1       : std_logic;
    signal vmm_cktp_2       : std_logic;
    signal vmm_cktp_3       : std_logic;
    signal vmm_cktp_4       : std_logic;
    signal vmm_cktp_5       : std_logic;
    signal vmm_cktp_6       : std_logic;
    signal vmm_cktp_7       : std_logic;
    signal vmm_cktp_8       : std_logic;
    
    signal vmm_do_1         : std_logic;
    signal vmm_do_2         : std_logic;
    signal vmm_do_3         : std_logic;
    signal vmm_do_4         : std_logic;
    signal vmm_do_5         : std_logic;
    signal vmm_do_6         : std_logic;
    signal vmm_do_7         : std_logic;
    signal vmm_do_8         : std_logic;
  
    -------------------------------------------------
    -- Readout Signals
    -------------------------------------------------
    signal daq_enable_i             : std_logic;
    signal daq_done                 : std_logic;
    signal cktp_state               : integer := 0;
    signal ro_cktk_out_vec          : std_logic_vector(8 downto 1) := ( others => '0' );
    signal daqFIFO_wr_en_i          : std_logic := '0';
    signal daqFIFO_din_i            : std_logic_vector(63 downto 0);
    signal daqFIFO_dout_i           : std_logic_vector(7 downto 0); 
    signal vmmWordReady_i           : std_logic := '0';
    signal vmmWord_i                : std_logic_vector(63 downto 0);
    signal vmmEventDone_i           : std_logic := '0';
    signal daqFIFO_reset            : std_logic := '0';
    signal daq_vmm_ena_wen_enable   : std_logic_vector(8 downto 1) := (others => '0');
    signal daq_cktk_out_enable      : std_logic_vector(8 downto 1) := (others => '0');
    
    signal UDPDone                  : std_logic;
   
    -------------------------------------------------
    -- Trigger Signals
    -------------------------------------------------
    signal tren               : std_logic := '0';
    signal tr_hold            : std_logic := '0';
    signal trmode             : std_logic := '0';
    signal ext_trigger_in     : std_logic := '0';
    signal trint              : std_logic := '0';
    signal tr_reset           : std_logic := '0';
    signal event_counter_i    : std_logic_vector(31 downto 0);
    signal event_counter_ila  : std_logic_vector(31 downto 0);
    signal tr_out_i           : std_logic;
    signal trigger_loop       : std_logic;
    signal trig_mode_int      : std_logic := '0';
    
    signal trigger_loop_i     : std_logic;
    signal ext_trigger_i      : std_logic;
    
    signal internalTrigger_state : integer := 0;
  
    -------------------------------------------------
    -- Event Timing & Soft Reset
    -------------------------------------------------
    --    signal tr_out_i         : std_logic;
    signal etr_vmm_wen_vec  : std_logic_vector(8 downto 1) := ( others => '0' );
    signal etr_vmm_ena_vec  : std_logic_vector(8 downto 1) := ( others => '0' );
    signal etr_reset_latched: std_logic;

    -------------------------------------------------
    -- Packet Formation Signals
    -------------------------------------------------
    signal pf_datain_i  : std_logic_vector(63 downto 0);
    signal pf_newCycle  : std_logic;
    signal pf_dataout   : std_logic_vector(63 downto 0);
    signal pf_wren      : std_logic;
    signal pf_packLen   : std_logic_vector(11 downto 0);
    signal pf_trigVmmRo : std_logic := '0';
    signal pf_vmmIdRo   : std_logic_vector(2 downto 0) := b"000";
    signal pf_reset     : std_logic := '0';
    signal rst_vmm      : std_logic := '0';
    signal pf_rst_FIFO  : std_logic := '0';

    -------------------------------------------------
    -- Flow FSM signals
    -------------------------------------------------
    type state_t is (IDLE, CONFIGURE, CONF_DONE, SEND_CONF_REPLY, DAQ_INIT, TRIG, DAQ);
    signal state        : state_t;
    signal rstDAQFIFO   : std_logic := '0';

    -------------------------------------------------
    -- Debugging Signals
    -------------------------------------------------
    signal read_out           : std_logic_vector(255 downto 0);

    -------------------------------------------------------------------
    -- These attribute will stop timing errors being reported in back
    -- annotated SDF simulation.
    -------------------------------------------------------------------
    attribute ASYNC_REG                         : string;
    attribute ASYNC_REG of pma_reset_pipe       : signal is "TRUE";
  
    -------------------------------------------------------------------
    -- Keep signals for ILA
    -------------------------------------------------------------------
    attribute keep          : string;
    attribute dont_touch    : string;
  
    -------------------------------------------------------------------
    -- Readout Monitoring
    -------------------------------------------------------------------
    attribute keep of vmm_ena_vec           : signal is "true";
    attribute dont_touch of vmm_ena_vec     : signal is "true";
    attribute keep of vmm_wen_vec           : signal is "true";
    attribute dont_touch of vmm_wen_vec     : signal is "true";
    attribute keep of cktk_out_vec          : signal is "true";
    attribute dont_touch of cktk_out_vec    : signal is "true";
    attribute keep of vmm_cktp_8            : signal is "true";

    attribute keep of cktk_out_i            : signal is "true";
    attribute keep of ckdt_out_vec          : signal is "true";
    attribute keep of vmm_do_vec_i          : signal is "true";
    attribute keep of daq_vmm_ena_wen_enable: signal is "true";
    attribute keep of vmm_id_int            : signal is "true";
    
    attribute keep of data0_in_vec          : signal is "true";
    attribute dont_touch of data0_in_vec    : signal is "true";
    attribute keep of ro_cktk_out_vec       : signal is "true";
    attribute dont_touch of ro_cktk_out_vec : signal is "true";

    -------------------------------------------------------------------
    -- Trigger
    -------------------------------------------------------------------
--      attribute keep of event_counter_i       : signal is "true";
--      attribute keep of tr_out_i              : signal is "true";
--      attribute keep of ext_trigger           : signal is "true";
--      attribute keep of trigger_loop_i        : signal is "true";
--      attribute keep of ext_trigger_i         : signal is "true";
    attribute keep of trint               : signal is "true";
    attribute keep of tren                : signal is "true";
    attribute keep of ext_trigger_in      : signal is "true";
    attribute keep of trig_mode_int       : signal is "true";

    -------------------------------------------------------------------
    -- Event Timing & Soft Reset
    -------------------------------------------------------------------
  --   attribute keep of tr_out_i               :   signal  is  "true";
    attribute keep of etr_reset_latched      : signal is "true";
    attribute keep of rst_vmm                : signal is "true";
    attribute keep of etr_vmm_ena_vec        : signal is "true";
    attribute keep of daq_enable_i           : signal is "true";
    
    -------------------------------------------------------------------
    -- Packet Formation
    -------------------------------------------------------------------
--      attribute keep of pf_datain_i           :  signal  is  "true";
    attribute keep of pf_newCycle           :  signal  is  "true";
--      attribute keep of pf_dataout            :  signal  is  "true";
--      attribute keep of pf_wren               :  signal  is  "true";

    -------------------------------------------------------------------
    -- Other
    -------------------------------------------------------------------
    attribute keep of set_reset                 : signal is "TRUE";
    attribute dont_touch of set_reset           : signal is "TRUE";
    attribute keep of tx_axis_mac_tready_int    : signal is "TRUE";
    attribute keep of test_data                 : signal is "TRUE";
    attribute keep of status_int                : signal is "TRUE";
    attribute keep of status_int_synced         : signal is "TRUE";
    attribute keep of user_data_out_i           : signal is "TRUE";
    attribute dont_touch of user_data_out_i     : signal is "TRUE";
    attribute keep of we_conf_int               : signal is "TRUE";
    attribute keep of fifo_data_out_int         : signal is "TRUE";
    attribute keep of re_out_int                : signal is "TRUE";
    attribute keep of daqFIFO_wr_en_i           : signal is "TRUE";
    attribute keep of daqFIFO_din_i             : signal is "TRUE";
    attribute keep of user_conf_i               : signal is "TRUE";
    attribute keep of send_error_int            : signal is "TRUE";
    attribute keep of send_error_done_int       : signal is "TRUE";
    attribute keep of test_data_out             : signal is "TRUE";
    attribute keep of test_valid_out            : signal is "TRUE";
    attribute keep of test_last_out             : signal is "TRUE";
    attribute keep of udp_tx_start_int          : signal is "TRUE";
    attribute keep of udp_tx_data_out_ready_int : signal is "TRUE";
    attribute keep of vmm_id                    : signal is "TRUE";
    attribute keep of configuring_i             : signal is "TRUE";
    attribute keep of vmm_id_synced             : signal is "TRUE";
    attribute keep of vmm_id_old                : signal is "TRUE";
    attribute keep of cnt_vmm                   : signal is "TRUE";
    attribute keep of conf_done_int             : signal is "TRUE";
    attribute keep of conf_done_int_synced      : signal is "TRUE";
    attribute keep of conf_wen_i                : signal is "TRUE";
    attribute dont_touch of conf_wen_i          : signal is "TRUE";
    attribute keep of conf_ena_i                : signal is "TRUE";
    attribute dont_touch of conf_ena_i          : signal is "TRUE";
    attribute keep of conf_di_i                 : signal is "TRUE";
    attribute keep of vmm_di_vec_i              : signal is "TRUE";
    attribute dont_touch of vmm_di_vec_i        : signal is "TRUE";
    attribute keep of start_conf_proc_int       : signal is "TRUE";
    attribute keep of cnt_reply                 : signal is "TRUE";
    attribute keep of end_packet_conf_int       : signal is "TRUE";
    
    -------------------------------------------------------------------
    --                       COMPONENTS                              --
    -------------------------------------------------------------------
    -- 1.  clk_wiz_200_to_400
    -- 2.  clk_wiz_low_jitter
    -- 3.  clk_wiz_0
    -- 4.  vmm_global_reset
    -- 5.  event_timing_reset
    -- 6.  select_vmm
    -- 7.  configuration_block
    -- 8.  vmm_readout
    -- 9.  FIFO2UDP
    -- 10. trigger
    -- 11. packet_formation
    -- 12. gig_ethernet_pcs_pma_0
    -- 13. UDP_Complete_nomac
    -- 14. temac_10_100_1000_fifo_block
    -- 15. temac_10_100_1000_reset_sync
    -- 16. temac_10_100_1000_config_vector_sm
    -- 17. i2c_top
    -- 18. config_logic
    -- 19. select_data
    -- 20. ila_top_level
    -------------------------------------------------------------------
    -- 1
    component clk_wiz_200_to_400
      port(
          clk_in1_p       : in     std_logic;
          clk_in1_n       : in     std_logic;
          clk_out_400     : out    std_logic
      );
    end component;
    -- 2
    component clk_wiz_low_jitter
      port(
          clk_in1         : in     std_logic;
          clk_out1        : out    std_logic
      );
    end component;
    -- 3
    component clk_wiz_0
      port(
          clk_in1         : in     std_logic;
          reset           : in     std_logic;
          clk_200_o       : out    std_logic;
          clk_800_o       : out    std_logic;
          clk_10_phase45_o: out    std_logic;
          clk_50_o        : out    std_logic;
          clk_40_o        : out    std_logic;
          clk_10_o        : out    std_logic
      );
    end component;
    -- 4
    component vmm_global_reset
      port(
          clk             : in std_logic;
          rst             : in std_logic;     -- reset
          gbl_rst         : in std_logic;     -- from control register. a pulse
          vmm_ena         : out std_logic;    -- these will be ored with same from other sm
          vmm_wen         : out std_logic     -- these will be ored with same from other sm
      );
    end component;
    -- 5
    component event_timing_reset
      port(
          hp_clk          : in std_logic;
          clk_200         : in std_logic;
          clk_10_phase45  : in std_logic;
          bc_clk          : in std_logic;
          
          daqEnable       : in std_logic;
          readout_done    : in std_logic;
          reset           : in std_logic;

          bcid            : out std_logic_vector(12 downto 0);
          prec_cnt        : out std_logic_vector(4 downto 0);

		  vmm_ena_vec     : out std_logic_vector(8 downto 1);
          vmm_wen_vec     : out std_logic_vector(8 downto 1);
          reset_latched   : out std_logic
      );
    end component;    
    -- 6
    component select_vmm 
      port (
          clk_in              : in  std_logic;
          vmm_id              : in  std_logic_vector(15 downto 0);
          
          conf_di             : in  std_logic;
          conf_di_vec         : out  std_logic_vector(8 downto 1);
                  
          conf_do             : out std_logic;                
          conf_do_vec         : in  std_logic_vector(8 downto 1);
          
          cktk_out            : in  std_logic;
          cktk_out_vec        : out std_logic_vector(8 downto 1);
          
          conf_wen            : in  std_logic;
          conf_wen_vec        : out std_logic_vector(8 downto 1);
          
          conf_ena            : in  std_logic;
          conf_ena_vec        : out std_logic_vector(8 downto 1)
      );
    end component;
    -- 7
    component configuration_block
    port
    (
      clk_in                  : in   STD_LOGIC;
      reset                   : in   STD_LOGIC;
    
      cfg_bit_in              : in   std_logic ;
      cfg_bit_out             : out  std_logic ;
    
      vmm_cktk                : out   std_logic ;        
      configuring             : in  std_logic;
      conf_done               : out  std_logic;
        
      data_fifo_wr_en         : in   std_logic := '0'; -- signal cannot be driven from top module !!! 
      data_fifo_din           : in   std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
      data_fifo_empty         : out  std_logic := '0';
      data_fifo_rd_count      : out  std_logic_vector(14 DOWNTO 0) := (OTHERS => '0');
      data_fifo_wr_count      : out  std_logic_vector(14 DOWNTO 0) := (OTHERS => '0');
                
      conf_data_in            : in   STD_LOGIC_VECTOR(7 downto 0);  
      conf_data_out           : out  STD_LOGIC_VECTOR(7 downto 0);        
      vmm_cfg_sel             : in   STD_LOGIC_VECTOR(31 downto 0));
    end component;
    -- 8
    component vmm_readout is
        port ( 
            clk_10_phase45          : in std_logic;     -- Used to clock checking for data process
            clk_50                  : in std_logic;     -- Used to clock word readout process
            clk_200                 : in std_logic;     -- Used for fast switching between processes

            vmm_data0_vec           : in std_logic_vector(8 downto 1);      -- Single-ended data0 from VMM
            vmm_data1_vec           : in std_logic_vector(8 downto 1);      -- Single-ended data1 from VMM
            vmm_ckdt_vec            : out std_logic_vector(8 downto 1);     -- Strobe to VMM CKDT
            vmm_cktk_vec            : out std_logic_vector(8 downto 1);     -- Strobe to VMM CKTK

            daq_enable              : in std_logic;
            trigger_pulse           : in std_logic;                     -- Trigger
            vmmId                   : in std_logic_vector(2 downto 0);  -- VMM to be readout
            ethernet_fifo_wr_en     : out std_logic;                    -- To be used for reading out seperate FIFOs in VMMx8 parallel readout
            vmm_data_buf            : buffer std_logic_vector(37 downto 0);
            
            vmmWordReady            : out std_logic;
            vmmWord                 : out std_logic_vector(63 downto 0);
            vmmEventDone            : out std_logic
        );
    end component;
    -- 9
    component FIFO2UDP
        port ( 
            clk_200                     : in std_logic;
            clk_125                     : in std_logic;
            destinationIP               : in std_logic_vector(31 downto 0);
            daq_data_in                 : in  std_logic_vector(63 downto 0);
            fifo_data_out               : out std_logic_vector (7 downto 0);
            udp_txi                     : out udp_tx_type;    
            udp_tx_start                : out std_logic;
            control                     : out std_logic;
            UDPDone                     : out std_logic; 
            re_out                      : out std_logic;     
            udp_tx_data_out_ready       : in  std_logic;
            wr_en                       : in  std_logic;
            end_packet                  : in std_logic;
            global_reset                : in  std_logic;
            packet_length_in            : in std_logic_vector(11 downto 0);
            reset_DAQ_FIFO              : in std_logic;
            sending_o                   : out std_logic
        );
    end component;
    -- 10
    component trigger is
      port (
          clk_200         : in std_logic;
          
          tren            : in std_logic;
          tr_hold         : in std_logic;
          trmode          : in std_logic;
          trext           : in std_logic;
          trint           : in std_logic;
          reset           : in std_logic;
          
          event_counter   : out std_logic_vector(31 DOWNTO 0);
          tr_out          : out std_logic
      );
    end component;
    -- 11
    component packet_formation is
    port (
        clk_200         : in std_logic;
        
        newCycle        : in std_logic;
        trigVmmRo       : out std_logic;
        vmmId           : out std_logic_vector(2 downto 0);
        vmmWord         : in std_logic_vector(63 downto 0);
        vmmWordReady    : in std_logic;
        vmmEventDone    : in std_logic;
        
        UDPDone         : in std_logic;

        packLen         : out std_logic_vector(11 downto 0);
        dataout         : out std_logic_vector(63 downto 0);
        wrenable        : out std_logic;
        end_packet      : out std_logic;
        udp_busy        : in std_logic;

        tr_hold         : out std_logic;
        reset           : in std_logic;
        rst_vmm         : out std_logic;
        resetting       : in std_logic;
        rst_FIFO        : out std_logic;
        
        latency         : in std_logic_vector(15 downto 0)
    );
    end component;
    -- 12
    component gig_ethernet_pcs_pma_0
        port(
            -- Transceiver Interface
            ---------------------
            gtrefclk_p               : in  std_logic;                          
            gtrefclk_n               : in  std_logic;                         
            
            gtrefclk_out             : out std_logic;                           -- Very high quality clock for GT transceiver.
            gtrefclk_bufg_out        : out std_logic;                           
                
            txp                      : out std_logic;                    -- Differential +ve of serial transmission from PMA to PMD.
            txn                      : out std_logic;                    -- Differential -ve of serial transmission from PMA to PMD.
            rxp                      : in  std_logic;                     -- Differential +ve for serial reception from PMD to PMA.
            rxn                      : in  std_logic;                     -- Differential -ve for serial reception from PMD to PMA.
            resetdone                : out std_logic;                           -- The GT transceiver has completed its reset cycle
            userclk_out              : out std_logic;                           
            userclk2_out             : out std_logic;                           
            rxuserclk_out            : out std_logic;                         
            rxuserclk2_out           : out std_logic;                         
            pma_reset_out            : out std_logic;                           -- transceiver PMA reset signal
            mmcm_locked_out          : out std_logic;                           -- MMCM Locked
            independent_clock_bufg   : in  std_logic;                   
            
            -- GMII Interface
            -----------------
            sgmii_clk_r             : out std_logic;              
            sgmii_clk_f             : out std_logic;              
            sgmii_clk_en            : out std_logic;                    -- Clock enable for client MAC
            gmii_txd                : in std_logic_vector(7 downto 0);  -- Transmit data from client MAC.
            gmii_tx_en              : in std_logic;                     -- Transmit control signal from client MAC.
            gmii_tx_er              : in std_logic;                     -- Transmit control signal from client MAC.
            gmii_rxd                : out std_logic_vector(7 downto 0); -- Received Data to client MAC.
            gmii_rx_dv              : out std_logic;                    -- Received control signal to client MAC.
            gmii_rx_er              : out std_logic;                    -- Received control signal to client MAC.
            gmii_isolate            : out std_logic;                    -- Tristate control to electrically isolate GMII.
            
            -- Management: Alternative to MDIO Interface
            --------------------------------------------
            
            configuration_vector    : in std_logic_vector(4 downto 0);  -- Alternative to MDIO interface.
            
            an_interrupt            : out std_logic;                    -- Interrupt to processor to signal that Auto-Negotiation has completed
            an_adv_config_vector    : in std_logic_vector(15 downto 0); -- Alternate interface to program REG4 (AN ADV)
            an_restart_config       : in std_logic;                     -- Alternate signal to modify AN restart bit in REG0
            
            -- Speed Control
            ----------------
            speed_is_10_100         : in std_logic;                             -- Core should operate at either 10Mbps or 100Mbps speeds
            speed_is_100            : in std_logic;                             -- Core should operate at 100Mbps speed
            
            -- General IO's
            ---------------
            status_vector           : out std_logic_vector(15 downto 0);        -- Core status.
            reset                   : in std_logic;                             -- Asynchronous reset for entire core.
            
            signal_detect           : in std_logic;                             -- Input from PMD to indicate presence of optical input.
            gt0_pll0outclk_out      : out std_logic;
            gt0_pll0outrefclk_out   : out std_logic;
            gt0_pll1outclk_out      : out std_logic;
            gt0_pll1outrefclk_out   : out std_logic;
            gt0_pll0refclklost_out  : out std_logic;
            gt0_pll0lock_out        : out std_logic);
    end component;
	-- 13
	component UDP_Complete_nomac
	   Port (
			-- UDP TX signals
			udp_tx_start			: in std_logic;							    -- indicates req to tx UDP
			udp_txi					: in udp_tx_type;							-- UDP tx cxns
			udp_tx_result			: out std_logic_vector (1 downto 0);        -- tx status (changes during transmission)
			udp_tx_data_out_ready   : out std_logic;							-- indicates udp_tx is ready to take data
			-- UDP RX signals
			udp_rx_start			: out std_logic;							-- indicates receipt of udp header
			udp_rxo					: out udp_rx_type;
			-- IP RX signals
			ip_rx_hdr				: out ipv4_rx_header_type;
			-- system signals
			rx_clk					: in  STD_LOGIC;
			tx_clk					: in  STD_LOGIC;
			reset 					: in  STD_LOGIC;
			our_ip_address 		    : in STD_LOGIC_VECTOR (31 downto 0);
			our_mac_address 		: in std_logic_vector (47 downto 0);
			control					: in udp_control_type;
			-- status signals
			arp_pkt_count			: out STD_LOGIC_VECTOR(7 downto 0);			-- count of arp pkts received
			ip_pkt_count			: out STD_LOGIC_VECTOR(7 downto 0);			-- number of IP pkts received for us
			-- MAC Transmitter
			mac_tx_tdata            : out  std_logic_vector(7 downto 0);	    -- data byte to tx
			mac_tx_tvalid           : out  std_logic;							-- tdata is valid
			mac_tx_tready           : in std_logic;							    -- mac is ready to accept data
			mac_tx_tfirst           : out  std_logic;							-- indicates first byte of frame
			mac_tx_tlast            : out  std_logic;							-- indicates last byte of frame
			-- MAC Receiver
			mac_rx_tdata            : in std_logic_vector(7 downto 0);	        -- data byte received
			mac_rx_tvalid           : in std_logic;							    -- indicates tdata is valid
			mac_rx_tready           : out  std_logic;							-- tells mac that we are ready to take data
			mac_rx_tlast            : in std_logic);							-- indicates last byte of the trame
	end component;
    -- 14
    component temac_10_100_1000_fifo_block
    port(
            gtx_clk                    : in  std_logic;
            -- asynchronous reset
            glbl_rstn                  : in  std_logic;
            rx_axi_rstn                : in  std_logic;
            tx_axi_rstn                : in  std_logic;
            -- Receiver Statistics Interface
            -----------------------------------------
            rx_reset                   : out std_logic;
            rx_statistics_vector       : out std_logic_vector(27 downto 0);
            rx_statistics_valid        : out std_logic;
            -- Receiver (AXI-S) Interface
            ------------------------------------------
            rx_fifo_clock              : in  std_logic;
            rx_fifo_resetn             : in  std_logic;
            rx_axis_fifo_tdata         : out std_logic_vector(7 downto 0);
            rx_axis_fifo_tvalid        : out std_logic;
            rx_axis_fifo_tready        : in  std_logic;
            rx_axis_fifo_tlast         : out std_logic;
            -- Transmitter Statistics Interface
            --------------------------------------------
            tx_reset                   : out std_logic;
            tx_ifg_delay               : in  std_logic_vector(7 downto 0);
            tx_statistics_vector       : out std_logic_vector(31 downto 0);
            tx_statistics_valid        : out std_logic;
            -- Transmitter (AXI-S) Interface
            ---------------------------------------------
            tx_fifo_clock              : in  std_logic;
            tx_fifo_resetn             : in  std_logic;
            tx_axis_fifo_tdata         : in  std_logic_vector(7 downto 0);
            tx_axis_fifo_tvalid        : in  std_logic;
            tx_axis_fifo_tready        : out std_logic;
            tx_axis_fifo_tlast         : in  std_logic;
            -- MAC Control Interface
            --------------------------
            pause_req                  : in  std_logic;
            pause_val                  : in  std_logic_vector(15 downto 0);
            -- GMII Interface
            -------------------
            gmii_txd                  : out std_logic_vector(7 downto 0);
            gmii_tx_en                : out std_logic;
            gmii_tx_er                : out std_logic;
            gmii_rxd                  : in  std_logic_vector(7 downto 0);
            gmii_rx_dv                : in  std_logic;
            gmii_rx_er                : in  std_logic;
            clk_enable                : in  std_logic;
            speedis100                : out std_logic;
            speedis10100              : out std_logic;
            -- Configuration Vector
            -------------------------
            rx_configuration_vector   : in  std_logic_vector(79 downto 0);
            tx_configuration_vector   : in  std_logic_vector(79 downto 0));
    end component;
    -- 15
    component temac_10_100_1000_reset_sync
        port ( 
            reset_in           : in  std_logic;    -- Active high asynchronous reset
            enable             : in  std_logic;
            clk                : in  std_logic;    -- clock to be sync'ed to
            reset_out          : out std_logic);     -- "Synchronised" reset signal
    end component;
    -- 16
    component temac_10_100_1000_config_vector_sm is
    port(
      gtx_clk                 : in  std_logic;
      gtx_resetn              : in  std_logic;
      mac_speed               : in  std_logic_vector(1 downto 0);
      update_speed            : in  std_logic;
      rx_configuration_vector : out std_logic_vector(79 downto 0);
      tx_configuration_vector : out std_logic_vector(79 downto 0));
    end component;
    -- 17
	component i2c_top is
	port(  
	    clk_in       		  : in    std_logic;		
        phy_rstn_out 		  : out   std_logic
	);	
	end component;
	-- 18
    component config_logic is
        Port ( 
            clk125              : in  std_logic;
            clk200              : in  std_logic;
            clk_in              : in  std_logic;
            reset               : in  std_logic;
            user_data_in        : in  std_logic_vector (7 downto 0);
            user_data_out       : out std_logic_vector (63 downto 0);
            udp_rx              : in udp_rx_type;
            resp_data           : out udp_response;
            send_error          : out std_logic;
            user_conf           : out  std_logic;
            user_wr_en          : in  std_logic;
            user_last           : in std_logic;
            configuring         : in std_logic;
            we_conf             : out std_logic;
            vmm_id              : out std_logic_vector(15 downto 0);            
            cfg_bit_out         : out std_logic ;
            vmm_cktk            : out std_logic ;
            status              : out std_logic_vector(3 downto 0);
            start_vmm_conf      : in  std_logic;
            conf_done           : out std_logic;     
            ext_trigger         : out std_logic;
            ACQ_sync            : out std_logic_vector(15 downto 0);
            udp_header          : in std_logic;
            packet_length       : in std_logic_vector (15 downto 0));
    end component;
    -- 19
    component select_data
    port(
        configuring                 : in  std_logic;
        data_acq                    : in  std_logic;
        we_data                     : in  std_logic;
        we_conf                     : in  std_logic;
        daq_data_in                 : in  std_logic_vector(63 downto 0);
        conf_data_in                : in  std_logic_vector(63 downto 0);
        data_packet_length          : in  std_logic_vector(11 downto 0);
        end_packet_conf             : in  std_logic;
        end_packet_daq              : in  std_logic;
        data_out                    : out std_logic_vector(63 downto 0);
        packet_length               : out std_logic_vector(11 downto 0);
        we                          : out std_logic;
        end_packet                  : out std_logic
    );
    end component;
    -- 20
    component ila_top_level
        PORT (  clk     : IN std_logic;
                probe0  : IN std_logic_vector(255 DOWNTO 0)
                );
    end component;

begin

	glbl_rstn	     <= not glbl_rst_i;
	phy_int          <= '1';
	
gen_vector_reset: process (userclk2)
    begin
     if userclk2'event and userclk2 = '1' then
       if vector_reset_int = '1' then
         vector_pre_resetn  <= '0';
         vector_resetn      <= '0';
       else
         vector_pre_resetn  <= '1';
         vector_resetn      <= vector_pre_resetn;
       end if;
     end if;
    end process gen_vector_reset;

    mmcm_reset <= glbl_rst_i; -- reset;

   -----------------------------------------------------------------------------
   -- Transceiver PMA reset circuitry
   -----------------------------------------------------------------------------
   
   -- Create a reset pulse of a decent length
   process(glbl_rst_i, clk_200)
   begin
     if (glbl_rst_i = '1') then
       pma_reset_pipe <= "1111";
     elsif clk_200'event and clk_200 = '1' then
       pma_reset_pipe <= pma_reset_pipe(2 downto 0) & glbl_rst_i;
     end if;
   end process;

   pma_reset <= pma_reset_pipe(3);

core_wrapper: gig_ethernet_pcs_pma_0
--    generic map ( EXAMPLE_SIMULATION              =>    0)
    port map (
      gtrefclk_p           => gtrefclk_p,
      gtrefclk_n           => gtrefclk_n,
      txp                  => txp,
      txn                  => txn,
      rxp                  => rxp,
      rxn                  => rxn,
      gtrefclk_out         => open,
      gtrefclk_bufg_out    => txoutclk,
      rxuserclk_out        => open,
      rxuserclk2_out       => open,
      resetdone            => resetdone,
      mmcm_locked_out      => mmcm_locked,
      userclk_out          => userclk,
      userclk2_out         => userclk2,
      independent_clock_bufg => clk_200,
      pma_reset_out        => pma_reset,
      sgmii_clk_r          => sgmii_clk_r,
      sgmii_clk_f          => sgmii_clk_f,
      sgmii_clk_en         => clk_enable_int,
      gmii_txd             => gmii_txd_int,
      gmii_tx_en           => gmii_tx_en_int,
      gmii_tx_er           => gmii_tx_er_int,
      gmii_rxd             => gmii_rxd_int,
      gmii_rx_dv           => gmii_rx_dv_int,
      gmii_rx_er           => gmii_rx_er_int,
      gmii_isolate         => gmii_isolate,
      configuration_vector => "10000", -- configuration_vector,
      status_vector        => status_vector_int, -- status_vector_int,
      reset                => glbl_rst_i,
      signal_detect        => '1', -- signal_detect
      speed_is_10_100	   => speed_is_10_100,
	  speed_is_100		   => speed_is_100,
	  an_interrupt         => open,                    -- Interrupt to processor to signal that Auto-Negotiation has completed
      an_adv_config_vector =>  "1111111000000001",-- Alternate interface to program REG4 (AN ADV)
      an_restart_config    => an_restart_config_int,                     -- Alternate signal to modify AN restart bit in REG0

	  gt0_pll0outclk_out     => open,
      gt0_pll0outrefclk_out  => open,
      gt0_pll1outclk_out     => open,
      gt0_pll1outrefclk_out  => open,
      gt0_pll0refclklost_out => open,
      gt0_pll0lock_out       => open);

	process(userclk2)
        begin
			if (local_gtx_reset = '1') then 
				an_restart_config_int <= '1';
			else
				an_restart_config_int <= '0';
			end if;
    end process;

tri_fifo: temac_10_100_1000_fifo_block
    port map(
      gtx_clk                    => userclk2, --sgmii_clk_int, --userclk2,
      -- asynchronous reset
      glbl_rstn                  => glbl_rstn,
      rx_axi_rstn                => '1',
      tx_axi_rstn                => '1',
      -- Receiver Statistics Interface
      -----------------------------------------
      rx_reset                   => rx_reset,
      rx_statistics_vector       => open,
      rx_statistics_valid        => open,
      -- Receiver (AXI-S) Interface
      ------------------------------------------
      rx_fifo_clock              => userclk2,
      rx_fifo_resetn             => gtx_resetn,
      rx_axis_fifo_tdata         => rx_axis_mac_tdata_int,
      rx_axis_fifo_tvalid        => rx_axis_mac_tvalid_int,
      rx_axis_fifo_tready        => rx_axis_mac_tready_int,
      rx_axis_fifo_tlast         => rx_axis_mac_tlast_int,
      -- Transmitter Statistics Interface
      --------------------------------------------
      tx_reset                   => tx_reset,
      tx_ifg_delay               => x"00",
      tx_statistics_vector       => open,
      tx_statistics_valid        => open,
      -- Transmitter (AXI-S) Interface
      ---------------------------------------------
      tx_fifo_clock              => userclk2,
      tx_fifo_resetn             => gtx_resetn,
      tx_axis_fifo_tdata         => tx_axis_mac_tdata_int,
      tx_axis_fifo_tvalid        => tx_axis_mac_tvalid_int,
      tx_axis_fifo_tready        => tx_axis_mac_tready_int,
      tx_axis_fifo_tlast         => tx_axis_mac_tlast_int,
      -- MAC Control Interface
      --------------------------
      pause_req                  => '0',
      pause_val                  => x"0000",
      -- GMII Interface
      -------------------
      gmii_txd                  => gmii_txd_emac,
      gmii_tx_en                => gmii_tx_en_emac,
      gmii_tx_er                => gmii_tx_er_emac,
      gmii_rxd                  => gmii_rxd_emac,
      gmii_rx_dv                => gmii_rx_dv_emac,
      gmii_rx_er                => gmii_rx_er_emac,
	  clk_enable			    => clk_enable_int,
      speedis100                => speed_is_100,
      speedis10100              => speed_is_10_100,
      -- Configuration Vector
      -------------------------
      rx_configuration_vector   => rx_configuration_vector_int, -- x"0605_0403_02da_0000_2022",
      tx_configuration_vector   => tx_configuration_vector_int);  -- x"0605_0403_02da_0000_2022"
	
	-- Control vector reset
axi_lite_reset_gen: temac_10_100_1000_reset_sync
   port map (
       clk                      => userclk2,
       enable                   => '1',
       reset_in                 => glbl_rst_i,
       reset_out                => vector_reset_int);	
		
config_vector: temac_10_100_1000_config_vector_sm
    port map(
      gtx_clk                   => userclk2, --sgmii_clk_int, --userclk2,
      gtx_resetn                => vector_resetn,    
      mac_speed                 => status_vector_int(11 downto 10), -- "10",
      update_speed              => '1',    
      rx_configuration_vector   => rx_configuration_vector_int,
      tx_configuration_vector   => tx_configuration_vector_int);

   -----------------------------------------------------------------------------
   -- GMII transmitter data logic
   -----------------------------------------------------------------------------

   -- Drive input GMII signals through IOB input flip-flops (inferred).
    process (userclk2)
    begin
      if userclk2'event and userclk2 = '1' then
         gmii_txd_int    <= gmii_txd_emac;
         gmii_tx_en_int  <= gmii_tx_en_emac;
         gmii_tx_er_int  <= gmii_tx_er_emac;
      end if;
    end process;
		
	local_gtx_reset <= glbl_rst_i or rx_reset or tx_reset;
	
gtx_reset_gen: temac_10_100_1000_reset_sync
    port map (
       clk              => userclk2,
       enable           => '1',
       reset_in         => local_gtx_reset,
       reset_out        => gtx_clk_reset_int);

gen_gtx_reset: process (userclk2)
   begin
     if userclk2'event and userclk2 = '1' then
       if gtx_clk_reset_int = '1' then
         gtx_pre_resetn   <= '0';
         gtx_resetn       <= '0';
       else
         gtx_pre_resetn   <= '1';
         gtx_resetn       <= gtx_pre_resetn;
       end if;
     end if;
   end process gen_gtx_reset;

   -- Drive input GMII signals through IOB output flip-flops (inferred).
   process (userclk2)
   begin
      if userclk2'event and userclk2 = '1' then
         gmii_rxd_emac          <= gmii_rxd_int;
         gmii_rx_dv_emac        <= gmii_rx_dv_int;
         gmii_rx_er_emac        <= gmii_rx_er_int;
      end if;
   end process;

UDP_block: UDP_Complete_nomac
	Port map(
			udp_tx_start				=> udp_tx_start_int,
			udp_txi						=> udp_txi_int, 
			udp_tx_result				=> open,
			udp_tx_data_out_ready	    => udp_tx_data_out_ready_int, 
			udp_rx_start				=> udp_header_int,									-- indicates receipt of udp header
			udp_rxo						=> udp_rx_int,
			ip_rx_hdr					=> ip_rx_hdr_int,	
			rx_clk						=> userclk2,
			tx_clk						=> userclk2,
			reset 						=> glbl_rst_i,
			our_ip_address 			    => myIP,
			our_mac_address 			=> myMAC,
			control						=> control,
			arp_pkt_count				=> open,
			ip_pkt_count				=> open,
			mac_tx_tdata         	    => tx_axis_mac_tdata_int,
			mac_tx_tvalid        	    => tx_axis_mac_tvalid_int,
			mac_tx_tready        	    => tx_axis_mac_tready_int,
			mac_tx_tfirst        	    => open,
			mac_tx_tlast         	    => tx_axis_mac_tlast_int,
			mac_rx_tdata         	    => rx_axis_mac_tdata_int,
			mac_rx_tvalid        	    => rx_axis_mac_tvalid_int,
			mac_rx_tready        	    => rx_axis_mac_tready_int,
			mac_rx_tlast         	    => rx_axis_mac_tlast_int);

i2c_module: i2c_top
	   port map(  clk_in       			=> clk_200,
		          phy_rstn_out 			=> phy_rstn_out);

configuration_logic: config_logic
        Port map( 
            clk125              => userclk2,
            clk200              => clk_200,
            clk_in              => clk_40,
            reset               => reset,
            user_data_in        => udp_rx_int.data.data_in,
            user_data_out       => conf_data_out_i, 
            udp_rx              => udp_rx_int,
            resp_data           => udp_response_int,
            send_error          => send_error_int,
            user_conf           => user_conf_i,
            user_wr_en          => udp_rx_int.data.data_in_valid,
            user_last           => udp_rx_int.data.data_in_last,
            configuring         => '0', --configuring_i,
            we_conf             => open, --we_conf_int,
            vmm_id              => vmm_id,
            cfg_bit_out         => conf_di_i,
            status              => status_int,
            start_vmm_conf      => conf_wen_i, --start_conf_proc_int, --configuring_i,
            conf_done           => conf_done_int,
            ext_trigger         => trig_mode_int,
            ACQ_sync            => ACQ_sync_int,
            udp_header          => udp_header_int,
            vmm_cktk            => conf_cktk_out_i,
            packet_length       => udp_rx_int.hdr.data_length);

clk_200_to_400_inst: clk_wiz_200_to_400
    port map(
        clk_in1_p   => X_2V5_DIFF_CLK_P,
        clk_in1_n   => X_2V5_DIFF_CLK_N,
        clk_out_400 => clk_400_noclean
    );

clk_400_low_jitter_inst: clk_wiz_low_jitter
    port map(
        clk_in1     => clk_400_noclean,
        clk_out1    => clk_400_clean
    );

clk_user_inst: clk_wiz_0
    port map(
        clk_in1             => clk_400_clean,
        reset               => '0',
        clk_200_o           => clk_200,
        clk_800_o           => clk_800,
        clk_10_phase45_o    => clk_10_phase45,
        clk_50_o            => clk_50,
        clk_40_o            => clk_40,
        clk_10_o            => clk_10
   );

vmm_global_reset_inst: vmm_global_reset
    port map(
        clk            => clk_200,           -- main clock
        rst            => reset,             -- reset
        gbl_rst        => gbl_rst,           -- input
        vmm_ena        => vmm_ena_gbl_rst,   -- 
        vmm_wen        => vmm_wen_gbl_rst    -- 
    );

event_timing_reset_instance: event_timing_reset
    port map(
        hp_clk          => clk_800,
        clk_200         => clk_200,
        clk_10_phase45  => clk_10_phase45,
        bc_clk          => clk_10,
        daqEnable       => daq_enable_i,
        readout_done    => '0',
        reset           => rst_vmm,

        bcid            => open,
        prec_cnt        => open,

        vmm_ena_vec     => etr_vmm_ena_vec,
        vmm_wen_vec     => etr_vmm_wen_vec,
        reset_latched   => etr_reset_latched
    );

readout_vmm: vmm_readout
    port map(
        clk_10_phase45          => clk_10_phase45,
        clk_50                  => clk_50,
        clk_200                 => clk_200,
        
        vmm_data0_vec           => data0_in_vec,
        vmm_data1_vec           => data1_in_vec,
        vmm_ckdt_vec            => ckdt_out_vec,
        vmm_cktk_vec            => ro_cktk_out_vec,

        daq_enable              => daq_enable_i,
        trigger_pulse           => pf_trigVmmRo,
        vmmId                   => pf_vmmIdRo,
        ethernet_fifo_wr_en     => open,
        vmm_data_buf            => open,
        
        vmmWordReady            => vmmWordReady_i,
        vmmWord                 => vmmWord_i,
        vmmEventDone            => vmmEventDone_i
    );

trigger_instance: trigger
    port map(
        clk_200         => clk_200,

        tren            => tren,                -- Trigger module enabled
        tr_hold         => tr_hold,             -- Prevents trigger while high
        trmode          => trig_mode_int,       -- Mode 0: internal / Mode 1: external
        trext           => ext_trigger_in,      -- External trigger is to be driven to this port
        trint           => trint,               -- Internal trigger is to be driven to this port (CKTP)

        reset           => tr_reset,

        event_counter   => event_counter_i,
        tr_out          => tr_out_i
    );

pf_newCycle     <=      tr_out_i;
    
select_vmm_block: select_vmm
    Port map (
        clk_in              => clk_200,
        vmm_id              => vmm_id_int,

        conf_di             => conf_di_i,
        conf_di_vec         => vmm_di_vec_i,

        conf_do             => conf_do_i,
        conf_do_vec         => vmm_do_vec_i,

        cktk_out            => conf_cktk_out_i,
        cktk_out_vec        => conf_cktk_out_vec_i,

        conf_wen            => conf_wen_i,
        conf_wen_vec        => conf_vmm_wen_vec,

        conf_ena            => conf_ena_i,
        conf_ena_vec        => conf_vmm_ena_vec
    );

FIFO2UDP_instance: FIFO2UDP
    Port map( 
        clk_200                     => clk_200,
        clk_125                     => userclk2,
        destinationIP               => destIP,
        daq_data_in                 => daqFIFO_din_i,
        fifo_data_out               => fifo_data_out_int,
        udp_txi                     => udp_txi_int,    
        udp_tx_start                => udp_tx_start_int,
        control                     => control.ip_controls.arp_controls.clear_cache,
        UDPDone                     => UDPDone,   
        re_out                      => re_out_int,    
        udp_tx_data_out_ready       => udp_tx_data_out_ready_int,
        wr_en                       => daqFIFO_wr_en_i,
        end_packet                  => end_packet_i,
        global_reset                => glbl_rst_i,
        packet_length_in            => packet_length_int,
        reset_DAQ_FIFO              => daqFIFO_reset,
        sending_o                   => udp_busy
    );       

packet_formation_instance: packet_formation
    port map(
        clk_200         => clk_200,
        
        newCycle        => pf_newCycle,
        
        trigVmmRo       => pf_trigVmmRo,
        vmmId           => pf_vmmIdRo,
        vmmWord         => vmmWord_i,
        vmmWordReady    => vmmWordReady_i,
        vmmEventDone    => vmmEventDone_i,
        
        UDPDone         => UDPDone,
        
        packLen         => pf_packLen,
        dataout         => daq_data_out_i,
        wrenable        => daq_wr_en_i,
        end_packet      => end_packet_daq_int,
        udp_busy        => udp_busy,
        
        tr_hold         => tr_hold,
        reset           => pf_reset,
        rst_vmm         => rst_vmm,
        resetting       => etr_reset_latched,
        rst_FIFO        => pf_rst_FIFO,

        latency         => ACQ_sync_int
    );   
        
data_selection:  select_data
    port map(
        configuring                 => start_conf_proc_int,
        data_acq                    => daq_enable_i,
        we_data                     => daq_wr_en_i,
        we_conf                     => we_conf_int,
        daq_data_in                 => daq_data_out_i,
        conf_data_in                => user_data_out_i,
        data_packet_length          => pf_packLen,
        data_out                    => daqFIFO_din_i,
        packet_length               => packet_length_int,
        end_packet_conf             => end_packet_conf_int,
        end_packet_daq              => end_packet_daq_int,
        we                          => daqFIFO_wr_en_i,
        end_packet                  => end_packet_i
    );

--FIFO2Elink_instance: FIFO2Elink
--    generic map(OutputDataRate  => 80) -- 80 or 160 MHz
--    port map(
--            clk40           => clk_40,
--            clk80           => clk_80,
--            clk160          => clk_80,
--            RSTclk40        => '0',
--            ------
--            efifoDin        => open,     -- : in  std_logic_vector (17 downto 0);   -- [data_code,2bit][data,16bit]
--            efifoWe         => '1',
--            efifoPfull      => open,
--            efifoWclk       => clk_200,
--            ------
--            DATA1bitOUT     => open
--            ------
--    );
        
--Elink2FIFO: Elink2FIFO
--    generic map(InputDataRate   => 80 )-- 80 or 160 MHz
--    port map( 
--            clk40           => clk_40,
--            clk80           => clk_80,
--            clk160          => clk_80,
--            RSTclk40        => '0',
--            ------
--            DATA1bitIN      => open,
--            ------
--            efifoRclk       => clk_200,
--            efifoRe         => '1',
--            efifoHF         => '0',
--            efifoDout       => open      -- : out std_logic_vector (15 downto 0)
--            ------
--    );

----------------------------------------------------SET ENA--------------------------------------------------------------
    ena_diff_1 : OBUFDS port map ( O =>  ENA_1_P, OB => ENA_1_N, I =>  vmm_ena_vec(1));    
    ena_diff_2 : OBUFDS port map ( O =>  ENA_2_P, OB => ENA_2_N, I =>  vmm_ena_vec(2));
    ena_diff_3 : OBUFDS port map ( O =>  ENA_3_P, OB => ENA_3_N, I =>  vmm_ena_vec(3));
    ena_diff_4 : OBUFDS port map ( O =>  ENA_4_P, OB => ENA_4_N, I =>  vmm_ena_vec(4));
    ena_diff_5 : OBUFDS port map ( O =>  ENA_5_P, OB => ENA_5_N, I =>  vmm_ena_vec(5));
    ena_diff_6 : OBUFDS port map ( O =>  ENA_6_P, OB => ENA_6_N, I =>  vmm_ena_vec(6));
    ena_diff_7 : OBUFDS port map ( O =>  ENA_7_P, OB => ENA_7_N, I =>  vmm_ena_vec(7));
    ena_diff_8 : OBUFDS port map ( O =>  ENA_8_P, OB => ENA_8_N, I =>  vmm_ena_vec(8));

----------------------------------------------------SET WEN--------------------------------------------------------------
    wen_diff_1 : OBUFDS port map ( O =>  WEN_1_P, OB => WEN_1_N, I =>  vmm_wen_vec(1));
    wen_diff_2 : OBUFDS port map ( O =>  WEN_2_P, OB => WEN_2_N, I =>  vmm_wen_vec(2));
    wen_diff_3 : OBUFDS port map ( O =>  WEN_3_P, OB => WEN_3_N, I =>  vmm_wen_vec(3));
    wen_diff_4 : OBUFDS port map ( O =>  WEN_4_P, OB => WEN_4_N, I =>  vmm_wen_vec(4));
    wen_diff_5 : OBUFDS port map ( O =>  WEN_5_P, OB => WEN_5_N, I =>  vmm_wen_vec(5));
    wen_diff_6 : OBUFDS port map ( O =>  WEN_6_P, OB => WEN_6_N, I =>  vmm_wen_vec(6));
    wen_diff_7 : OBUFDS port map ( O =>  WEN_7_P, OB => WEN_7_N, I =>  vmm_wen_vec(7));
    wen_diff_8 : OBUFDS port map ( O =>  WEN_8_P, OB => WEN_8_N, I =>  vmm_wen_vec(8));

----------------------------------------------------SET DI--------------------------------------------------------------
    di_diff_1 : OBUFDS port map ( O => DI_1_P, OB => DI_1_N, I =>  vmm_di_vec_i(1));
    di_diff_2 : OBUFDS port map ( O => DI_2_P, OB => DI_2_N, I =>  vmm_di_vec_i(2));
    di_diff_3 : OBUFDS port map ( O => DI_3_P, OB => DI_3_N, I =>  vmm_di_vec_i(3));
    di_diff_4 : OBUFDS port map ( O => DI_4_P, OB => DI_4_N, I =>  vmm_di_vec_i(4));
    di_diff_5 : OBUFDS port map ( O => DI_5_P, OB => DI_5_N, I =>  vmm_di_vec_i(5));
    di_diff_6 : OBUFDS port map ( O => DI_6_P, OB => DI_6_N, I =>  vmm_di_vec_i(6));
    di_diff_7 : OBUFDS port map ( O => DI_7_P, OB => DI_7_N, I =>  vmm_di_vec_i(7));
    di_diff_8 : OBUFDS port map ( O => DI_8_P, OB => DI_8_N, I =>  vmm_di_vec_i(8));      

----------------------------------------------------SET CKBC--------------------------------------------------------------
    ckbc_diff_1 : OBUFDS port map ( O =>  CKBC_1_P, OB => CKBC_1_N, I =>  vmm_ckbc);
    ckbc_diff_2 : OBUFDS port map ( O =>  CKBC_2_P, OB => CKBC_2_N, I =>  vmm_ckbc);
    ckbc_diff_3 : OBUFDS port map ( O =>  CKBC_3_P, OB => CKBC_3_N, I =>  vmm_ckbc);
    ckbc_diff_4 : OBUFDS port map ( O =>  CKBC_4_P, OB => CKBC_4_N, I =>  vmm_ckbc);
    ckbc_diff_5 : OBUFDS port map ( O =>  CKBC_5_P, OB => CKBC_5_N, I =>  vmm_ckbc);
    ckbc_diff_6 : OBUFDS port map ( O =>  CKBC_6_P, OB => CKBC_6_N, I =>  vmm_ckbc);
    ckbc_diff_7 : OBUFDS port map ( O =>  CKBC_7_P, OB => CKBC_7_N, I =>  vmm_ckbc);
    ckbc_diff_8 : OBUFDS port map ( O =>  CKBC_8_P, OB => CKBC_8_N, I =>  vmm_ckbc);

----------------------------------------------------SET CKTK--------------------------------------------------------------
    cktk_diff_1 : OBUFDS port map ( O =>  CKTK_1_P, OB => CKTK_1_N, I =>  cktk_out_vec(1));
    cktk_diff_2 : OBUFDS port map ( O =>  CKTK_2_P, OB => CKTK_2_N, I =>  cktk_out_vec(2));
    cktk_diff_3 : OBUFDS port map ( O =>  CKTK_3_P, OB => CKTK_3_N, I =>  cktk_out_vec(3));
    cktk_diff_4 : OBUFDS port map ( O =>  CKTK_4_P, OB => CKTK_4_N, I =>  cktk_out_vec(4));
    cktk_diff_5 : OBUFDS port map ( O =>  CKTK_5_P, OB => CKTK_5_N, I =>  cktk_out_vec(5));
    cktk_diff_6 : OBUFDS port map ( O =>  CKTK_6_P, OB => CKTK_6_N, I =>  cktk_out_vec(6));
    cktk_diff_7 : OBUFDS port map ( O =>  CKTK_7_P, OB => CKTK_7_N, I =>  cktk_out_vec(7));
    cktk_diff_8 : OBUFDS port map ( O =>  CKTK_8_P, OB => CKTK_8_N, I =>  cktk_out_vec(8));

----------------------------------------------------SET CKTP--------------------------------------------------------------  
    cktp_diff_1 : OBUFDS port map ( O =>  CKTP_1_P, OB => CKTP_1_N, I => vmm_cktp);  
    cktp_diff_2 : OBUFDS port map ( O =>  CKTP_2_P, OB => CKTP_2_N, I => vmm_cktp);
    cktp_diff_3 : OBUFDS port map ( O =>  CKTP_3_P, OB => CKTP_3_N, I => vmm_cktp);
    cktp_diff_4 : OBUFDS port map ( O =>  CKTP_4_P, OB => CKTP_4_N, I => vmm_cktp);
    cktp_diff_5 : OBUFDS port map ( O =>  CKTP_5_P, OB => CKTP_5_N, I => vmm_cktp);
    cktp_diff_6 : OBUFDS port map ( O =>  CKTP_6_P, OB => CKTP_6_N, I => vmm_cktp);
    cktp_diff_7 : OBUFDS port map ( O =>  CKTP_7_P, OB => CKTP_7_N, I => vmm_cktp);
    cktp_diff_8 : OBUFDS port map ( O =>  CKTP_8_P, OB => CKTP_8_N, I => vmm_cktp);
    
----------------------------------------------------SET CKDT--------------------------------------------------------------
    ckdt_diff_1 : OBUFDS port map ( O => ckdt_1_P, OB => ckdt_1_N, I => ckdt_out_vec(1));
    ckdt_diff_2 : OBUFDS port map ( O => ckdt_2_P, OB => ckdt_2_N, I => ckdt_out_vec(2));
    ckdt_diff_3 : OBUFDS port map ( O => ckdt_3_P, OB => ckdt_3_N, I => ckdt_out_vec(3));
    ckdt_diff_4 : OBUFDS port map ( O => ckdt_4_P, OB => ckdt_4_N, I => ckdt_out_vec(4));
    ckdt_diff_5 : OBUFDS port map ( O => ckdt_5_P, OB => ckdt_5_N, I => ckdt_out_vec(5));
    ckdt_diff_6 : OBUFDS port map ( O => ckdt_6_P, OB => ckdt_6_N, I => ckdt_out_vec(6));
    ckdt_diff_7 : OBUFDS port map ( O => ckdt_7_P, OB => ckdt_7_N, I => ckdt_out_vec(7));
    ckdt_diff_8 : OBUFDS port map ( O => ckdt_8_P, OB => ckdt_8_N, I => ckdt_out_vec(8));                                               

----------------------------------------------------DO--------------------------------------------------------------
    do_diff_1       : IBUFDS port map ( O =>  vmm_do_1, I =>  DO_1_P, IB => DO_1_N);
    do_diff_2       : IBUFDS port map ( O =>  vmm_do_2, I =>  DO_2_P, IB => DO_2_N);
    do_diff_3       : IBUFDS port map ( O =>  vmm_do_3, I =>  DO_3_P, IB => DO_3_N);
    do_diff_4       : IBUFDS port map ( O =>  vmm_do_4, I =>  DO_4_P, IB => DO_4_N);
    do_diff_5       : IBUFDS port map ( O =>  vmm_do_5, I =>  DO_5_P, IB => DO_5_N);
    do_diff_6       : IBUFDS port map ( O =>  vmm_do_6, I =>  DO_6_P, IB => DO_6_N);
    do_diff_7       : IBUFDS port map ( O =>  vmm_do_7, I =>  DO_7_P, IB => DO_7_N);
    do_diff_8       : IBUFDS port map ( O =>  vmm_do_8, I =>  DO_8_P, IB => DO_8_N);      
    
----------------------------------------------------DATA 0--------------------------------------------------------------
    data0_diff_1    : IBUFDS port map ( O => data0_in_vec(1), I => DATA0_1_P, IB => DATA0_1_N);
    data0_diff_2    : IBUFDS port map ( O => data0_in_vec(2), I => DATA0_2_P, IB => DATA0_2_N);
    data0_diff_3    : IBUFDS port map ( O => data0_in_vec(3), I => DATA0_3_P, IB => DATA0_3_N);
    data0_diff_4    : IBUFDS port map ( O => data0_in_vec(4), I => DATA0_4_P, IB => DATA0_4_N);
    data0_diff_5    : IBUFDS port map ( O => data0_in_vec(5), I => DATA0_5_P, IB => DATA0_5_N);
    data0_diff_6    : IBUFDS port map ( O => data0_in_vec(6), I => DATA0_6_P, IB => DATA0_6_N);
    data0_diff_7    : IBUFDS port map ( O => data0_in_vec(7), I => DATA0_7_P, IB => DATA0_7_N);
    data0_diff_8    : IBUFDS port map ( O => data0_in_vec(8), I => DATA0_8_P, IB => DATA0_8_N);
    
----------------------------------------------------DATA 1--------------------------------------------------------------
    data1_diff_1    : IBUFDS port map ( O => data1_in_vec(1), I => DATA1_1_P, IB => DATA1_1_N);
    data1_diff_2    : IBUFDS port map ( O => data1_in_vec(2), I => DATA1_2_P, IB => DATA1_2_N);
    data1_diff_3    : IBUFDS port map ( O => data1_in_vec(3), I => DATA1_3_P, IB => DATA1_3_N);
    data1_diff_4    : IBUFDS port map ( O => data1_in_vec(4), I => DATA1_4_P, IB => DATA1_4_N);
    data1_diff_5    : IBUFDS port map ( O => data1_in_vec(5), I => DATA1_5_P, IB => DATA1_5_N);
    data1_diff_6    : IBUFDS port map ( O => data1_in_vec(6), I => DATA1_6_P, IB => DATA1_6_N);
    data1_diff_7    : IBUFDS port map ( O => data1_in_vec(7), I => DATA1_7_P, IB => DATA1_7_N);
    data1_diff_8    : IBUFDS port map ( O => data1_in_vec(8), I => DATA1_8_P, IB => DATA1_8_N);      
    
---------------------------------------------------TRIGGERS--------------------------------------------------------------
    ext_trigger     : IBUFDS port map ( O => ext_trigger_in, I => EXT_TRIGGER_P, IB => EXT_TRIGGER_N);

-------------------------------------------------------------------
--                        Processes                              --
-------------------------------------------------------------------
    -- 1. internalTrigger_proc
    -- 2. testPulse_proc
    -- 3. synced_to_200
    -- 4. FPGA_global_reset
    -- 5. flow_fsm
-------------------------------------------------------------------

internalTrigger_proc: process(clk_10_phase45) -- 10MHz/#states.
    begin
        if rising_edge(clk_10_phase45) then            
            if state = DAQ and trig_mode_int = '0' then
                case internalTrigger_state is
                    when 0 to 9979 =>
                        internalTrigger_state <= internalTrigger_state + 1;
                        trint           <= '0';
                    when 9980 to 10000 =>
                        internalTrigger_state <= internalTrigger_state + 1;
                        trint           <= '1';        
                    when others =>
                        internalTrigger_state <= 0;
                end case;
            else
                trint           <= '0';
            end if;
        end if;
end process;

testPulse_proc: process(clk_10_phase45) -- 10MHz/#states.
    begin
        if rising_edge(clk_10_phase45) then            
            if state = DAQ and trig_mode_int = '0' then
                case cktp_state is
                    when 0 to 9979 =>
                        cktp_state <= cktp_state + 1;
                        vmm_cktp      <= '0';
                    when 9980 to 10000 =>
                        cktp_state <= cktp_state + 1;
                        vmm_cktp      <= '1';                             
                    when others =>
                        cktp_state <= 0;
                end case;
            else
                vmm_cktp      <= '0';
            end if;
        end if;
end process;

synced_to_200: process(clk_200)
    begin
    if rising_edge(clk_200) then
        status_int_old       <= status_int;
        if status_int_old = status_int then
            status_int_synced   <= status_int_old;
        end if;
        
        vmm_id_old       <= vmm_id;
        if vmm_id_old = vmm_id then
            vmm_id_synced   <= vmm_id_old;
        end if;
        conf_done_int_synced    <= conf_done_int;
    end if;
end process;

FPGA_global_reset: process(clk_200, status_int_synced)
    begin
    if rising_edge(clk_200) then
        if status_int_synced = "0011" then
            glbl_rst_i <= '1';
        else
            glbl_rst_i <= '0';
        end if;
    end if;
end process;

flow_fsm: process(clk_200, counter, status_int, status_int_synced, state, vmm_id, write_done_i, conf_done_i, reading_i)
    begin
    if rising_edge(clk_200) then
        if glbl_rst_i = '1' then
            state                <=    IDLE;
        elsif is_state = "0000" then
            state   <= IDLE;
        else
        
            case state is
                when IDLE =>
                    is_state                <= "1111";
                    configuring_i           <= '0';
                    daq_vmm_ena_wen_enable  <= x"00";
                    daq_cktk_out_enable     <= x"00";
                    daq_enable_i            <= '0';
                    rstDAQFIFO              <= '0';
                    tren                    <= '0';
                    conf_wen_i              <= '0';
                    conf_ena_i              <= '0';     
                    we_conf_int             <= '0';
                    end_packet_conf_int     <= '0';
                    start_conf_proc_int     <= '0';

                    if status_int_synced = "0010" then      -- VMM conf x8: 0010
                        cnt_vmm       <= 8;
                        vmm_id_int    <= std_logic_vector(to_unsigned(cnt_vmm, vmm_id_int'length));
                        state         <= CONFIGURE;
                    elsif status_int_synced = "0001" then   -- VMM conf x1: 0001
                        cnt_vmm       <= 1;
                        vmm_id_int    <= vmm_id_synced;
                        state         <= CONFIGURE;
                    elsif status_int_synced = "1111" then   -- DAQ ON
                        state         <= DAQ_INIT;
                    end if;
            
               when    CONFIGURE    =>        
                    is_state        <= "0001";    
                    if status_int_synced = "1011" then 
                        state   <= CONF_DONE;
                    end if;

                    configuring_i       <= '1';
                    conf_wen_i          <= '1'; 
                    start_conf_proc_int <= '1';

                when    CONF_DONE    =>
                    is_state        <= "0010";
                    if w = 40 then
                        cnt_vmm     <= cnt_vmm - 1;
                        if cnt_vmm = 1 then --1 VMM conf done
                            state           <= SEND_CONF_REPLY;
                            we_conf_int     <= '1';
                        else
                            state       <= CONFIGURE after 100ns;  
                        end if;
                        w   <= 0;
                    else
                        w <= w + 1;
                    end if;
                    
                    conf_wen_i      <= '0';   
                    
                when    SEND_CONF_REPLY    =>
                    is_state            <= "1010"; 
                    if cnt_reply = 0 then
                        user_data_out_i <= conf_data_out_i;
                        cnt_reply   <= cnt_reply + 1;
                    elsif cnt_reply = 1 then
                        user_data_out_i <= (others => '0');
                        cnt_reply   <= cnt_reply + 1;
                        end_packet_conf_int <= '1';
                        we_conf_int     <= '0';
                    elsif cnt_reply > 1 and cnt_reply < 100 then
                        cnt_reply   <= cnt_reply + 1;
                    else
                        cnt_reply           <= 0;
                        state               <= IDLE;
                        end_packet_conf_int <= '1';
                    end if;

                when DAQ_INIT =>
                    is_state                <= "0011";
                    tren                    <= '0';
                    daq_vmm_ena_wen_enable  <= x"ff";
                    daq_cktk_out_enable     <= x"ff";
                    daq_enable_i            <= '1';
                    rstDAQFIFO              <= '1';
                    pf_reset                <= '1';
                    if status_int_synced = "0000" or status_int_synced = "1000" then    -- Reset came or idle
                        daq_vmm_ena_wen_enable  <= x"00";
                        daq_cktk_out_enable     <= x"00";
                        daq_enable_i            <= '0';
                        pf_reset                <= '0';
                        state   <= IDLE;
                    else
                        state   <= TRIG;
                    end if;
                when TRIG =>
                    is_state        <= "0100";
                    rstDAQFIFO      <= '0';
                    pf_reset        <= '0';
                    tren            <= '1';
                    state           <= DAQ;
                when DAQ =>
                    is_state            <= "0101";
                    if status_int_synced = "1000" then  -- Reset came
                        daq_enable_i    <= '0';
                        state           <= DAQ_INIT;
                    end if;

                when others =>
                    state       <= IDLE;
                    is_state    <= "0110";
            end case;
        end if;
    end if;
end process;

    vmm_ckbc        <=  clk_10;

    cktk_out_vec    <= conf_cktk_out_vec_i or (ro_cktk_out_vec and daq_cktk_out_enable);
    vmm_ena_vec     <= conf_vmm_ena_vec or (etr_vmm_ena_vec and daq_vmm_ena_wen_enable);
    vmm_wen_vec     <= conf_vmm_wen_vec or (etr_vmm_wen_vec and daq_vmm_ena_wen_enable);

    rstDAQFIFO      <= pf_rst_FIFO or daqFIFO_reset;
    
    test_data               <= udp_rx_int.data.data_in;
    test_valid              <= udp_rx_int.data.data_in_valid;
    test_last               <= udp_rx_int.data.data_in_last;

    test_data_out           <= udp_txi_int.data.data_out;
    test_valid_out          <= udp_txi_int.data.data_out_valid;
    test_last_out           <= udp_txi_int.data.data_out_last;

    fifo_data               <= fifo_data_out_int;
	re_out                  <= re_out_int;


ila_top: ila_top_level
    port map (
        clk     => clk_200,
        probe0  => read_out
    );

    read_out(7 downto 0)        <= vmm_ena_vec;
    read_out(15 downto 8)       <= vmm_wen_vec;
    read_out(23 downto 16)      <= cktk_out_vec;
    read_out(31 downto 24)      <= ckdt_out_vec;
    read_out(35 downto 32)      <= is_state;
    read_out(39 downto 36)      <= status_int;
    read_out(55 downto 40)      <= vmm_id_int;
    read_out(59 downto 56)      <= status_int_synced;
    read_out(67 downto 60)      <= daq_vmm_ena_wen_enable;
    read_out(75 downto 68)      <= data0_in_vec;
    read_out(76)                <= trint;
    read_out(77)                <= tren;
    read_out(78)                <= vmm_cktp;
    read_out(79)                <= pf_newCycle;
    read_out(80)                <= tx_axis_mac_tready_int;
    read_out(81)                <= glbl_rst_i;
    read_out(82)                <= start_conf_proc_int;
    read_out(83)                <= daqFIFO_wr_en_i;
    read_out(84)                <= daq_wr_en_i;
    read_out(85)                <= trig_mode_int;
    read_out(86)                <= ext_trigger_in;
    read_out(87)                <= conf_wen_i;
    read_out(88)                <= cktk_out_i;
    read_out(89)                <= conf_di_i;
    read_out(90)                <= etr_reset_latched;
    read_out(91)                <= rst_vmm;
    read_out(99 downto 92)      <= etr_vmm_ena_vec;
    read_out(102 downto 100)    <= pf_vmmIdRo;
    read_out(103)               <= daq_enable_i;

    read_out(255 downto 104)     <= (others => '0');

end Behavioral;