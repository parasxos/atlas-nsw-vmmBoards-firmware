----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch) 
-- 
-- Create Date: 30.01.2017
-- Design Name: UDP Data Handler
-- Module Name: udp_data_handler - RTL
-- Project Name: MMFE8 - NTUA
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484
-- Tool Versions: Vivado 2016.2
-- Description: Module that samples the data coming from the UDP/Ethernet
-- and issues the corresponding FPGA commands depending on the payload and
-- the incoming port. It also serializes the data of the VMM configuration.

-- Dependencies: MMFE8 NTUA Project
-- 
-- Changelog:
-- 31.01.2017 The serialization now starts with a signal coming from the master FSM 
-- and the MUX select signal is being reset between packets. (Christos Bakalis)
-- 08.02.2017 Broke down the processes into two sub-components. (Christos Bakalis)
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;

entity udp_data_in_handler is
    port(
    ------------------------------------
    ------- General Interface ----------
    clk_200             : in  std_logic;
    clk_125             : in  std_logic;
    clk_50              : in  std_logic;
    clk_40              : in  std_logic;
    rst                 : in  std_logic;
    ------------------------------------
    -------- FPGA Config Interface -----
    latency             : out std_logic_vector(15 downto 0);
    fpga_rst_conf       : out std_logic;
    daq_off             : out std_logic;
    daq_on              : out std_logic;
    ext_trigger         : out std_logic;
    ------------------------------------
    -------- UDP Interface -------------
    udp_rx              : in  udp_rx_type;
    ------------------------------------
    ---------- AXI4SPI Interface -------
    flash_busy          : in  std_logic;
    newIP_rdy           : out std_logic;
    myIP_set            : out std_logic_vector(31 downto 0);
    myMAC_set           : out std_logic_vector(47 downto 0);
    destIP_set          : out std_logic_vector(31 downto 0);
    ------------------------------------
    ------ VMM Config Interface --------
    vmm_id              : out std_logic_vector(15 downto 0);
    vmmConf_rdy         : out std_logic;
    vmmConf_done        : out std_logic;
    vmm_cktk            : out std_logic;
    vmm_cfg_bit         : out std_logic;
    top_rdy             : in  std_logic;
    ------------------------------------
    ---------- XADC Interface ----------
    xadc_busy           : in  std_logic;
    xadc_rdy            : out std_logic;
    vmm_id_xadc         : out std_logic_vector(15 downto 0);
    xadc_sample_size    : out std_logic_vector(10 downto 0);
    xadc_delay          : out std_logic_vector(17 downto 0)
    );
end udp_data_in_handler;

architecture RTL of udp_data_in_handler is

    COMPONENT fpga_config_block
    PORT(
        -----------------------------------
        ------- General Interface ----------
        clk_125             : in  std_logic;
        rst                 : in  std_logic;
        cnt_bytes           : in  unsigned(4 downto 0);
        user_din_udp        : in  std_logic_vector(7 downto 0);
        ------------------------------------
        ---------- XADC Interface ----------
        xadc_conf           : in  std_logic;
        xadcPacket_rdy      : out std_logic;
        vmm_id_xadc         : out std_logic_vector(15 downto 0);
        xadc_sample_size    : out std_logic_vector(10 downto 0);
        xadc_delay          : out std_logic_vector(17 downto 0);
        ------------------------------------
        ---------- AXI4SPI Interface -------
        flash_conf          : in  std_logic;
        flashPacket_rdy     : out std_logic;
        myIP_set            : out std_logic_vector(31 downto 0);
        myMAC_set           : out std_logic_vector(47 downto 0);
        destIP_set          : out std_logic_vector(31 downto 0);
        ------------------------------------
        -------- FPGA Config Interface -----
        fpga_conf           : in  std_logic;
        fpgaPacket_rdy      : out std_logic;
        latency             : out std_logic_vector(15 downto 0);
        fpga_rst_conf       : out std_logic;
        daq_off             : out std_logic;
        daq_on              : out std_logic;
        ext_trigger         : out std_logic
    );
    END COMPONENT;

    COMPONENT vmm_config_block
    PORT(
        ------------------------------------
        ------- General Interface ----------
        clk_125             : in  std_logic;
        clk_40              : in  std_logic;
        rst                 : in  std_logic;
        rst_fifo            : in  std_logic;
        cnt_bytes           : in  unsigned(4 downto 0);
        ------------------------------------
        --------- FIFO/UDP Interface -------
        user_din_udp        : in  std_logic_vector(7 downto 0);
        user_valid_udp      : in  std_logic;
        user_last_udp       : in  std_logic;
        ------------------------------------
        ------ VMM Config Interface --------
        vmm_id              : out std_logic_vector(15 downto 0);
        vmmConf_rdy         : out std_logic;
        vmmConf_done        : out std_logic;
        vmm_cktk            : out std_logic;
        vmm_cfg_bit         : out std_logic;
        vmm_conf            : in  std_logic;
        top_rdy             : in  std_logic;
        init_ser            : in  std_logic
    );
    END COMPONENT;

    COMPONENT CDCC
    GENERIC(
        NUMBER_OF_BITS : integer := 8); -- number of signals to be synced
    PORT(
        clk_src     : in  std_logic;                                        -- input clk (source clock)
        clk_dst     : in  std_logic;                                        -- input clk (dest clock)
        data_in     : in  std_logic_vector(NUMBER_OF_BITS - 1 downto 0);    -- data to be synced
        data_out_s  : out std_logic_vector(NUMBER_OF_BITS - 1 downto 0)     -- synced data to clk_dst
    );
    END COMPONENT;

    signal user_data_prv    : std_logic_vector(7 downto 0) := (others => '0');
    signal user_valid_prv   : std_logic := '0';
    signal user_last_prv    : std_logic := '0';
    signal cnt_bytes        : unsigned(4 downto 0) := (others => '0');
    signal vmm_conf         : std_logic := '0';
    signal vmm_ser_done     : std_logic := '0';
    signal vmmSer_done_s125 : std_logic := '0';
    signal vmm_conf_rdy     : std_logic := '0';
    signal fpga_conf        : std_logic := '0';
    signal flash_conf       : std_logic := '0';
    signal xadc_conf        : std_logic := '0';
    signal rst_fifo         : std_logic := '0';
    signal rst_fifo_s40     : std_logic := '0';
    signal xadcPacket_rdy   : std_logic := '0';
    signal flashPacket_rdy  : std_logic := '0';
    signal fpgaPacket_rdy   : std_logic := '0';
    signal init_ser         : std_logic := '0';
    signal init_ser_s40     : std_logic := '0';
    signal top_rdy_s125     : std_logic := '0';
    signal top_rdy_s40      : std_logic := '0';
    signal flash_busy_s125  : std_logic := '0';
    signal xadc_busy_s125   : std_logic := '0';
    
    type masterFSM is (ST_IDLE, ST_CHK_PORT, ST_COUNT, ST_WAIT_FOR_BUSY, ST_WAIT_FOR_IDLE, ST_RESET_FIFO, ST_WAIT_FOR_CKTK_FSM);
    signal st_master : masterFSM := ST_IDLE;
    
    ---- Uncomment the following to add signals to ILA debugging core
    -----------------------------------------------------------------
    --attribute mark_debug : string;

    --attribute mark_debug of latency                   : signal is "true";
    --attribute mark_debug of fpga_rst_conf             : signal is "true";
    --attribute mark_debug of daq_off                   : signal is "true";
    --attribute mark_debug of daq_on                    : signal is "true";
    --attribute mark_debug of ext_trigger               : signal is "true";
    --attribute mark_debug of udp_rx.data.data_in       : signal is "true";
    --attribute mark_debug of udp_rx.data.data_in_valid : signal is "true";
    --attribute mark_debug of udp_rx.data.data_in_last  : signal is "true";
    --attribute mark_debug of udp_rx.hdr.dst_port       : signal is "true";
    --attribute mark_debug of flash_busy                : signal is "true";
    --attribute mark_debug of newIP_rdy                 : signal is "true";
    --attribute mark_debug of myIP_set                  : signal is "true";
    --attribute mark_debug of myMAC_set                 : signal is "true";
    --attribute mark_debug of destIP_set                : signal is "true";
    --attribute mark_debug of vmm_id                    : signal is "true";
    --attribute mark_debug of vmmConf_rdy               : signal is "true";
    --attribute mark_debug of vmmConf_done              : signal is "true";
    --attribute mark_debug of vmm_cktk                  : signal is "true";
    --attribute mark_debug of vmm_cfg_bit               : signal is "true";
    --attribute mark_debug of top_rdy                   : signal is "true";
    --attribute mark_debug of xadc_busy                 : signal is "true";
    --attribute mark_debug of xadc_rdy                  : signal is "true";
    --attribute mark_debug of vmm_id_xadc               : signal is "true";
    --attribute mark_debug of xadc_sample_size          : signal is "true";
    --attribute mark_debug of xadc_delay                : signal is "true";

    --attribute mark_debug of user_data_prv     : signal is "true";
    --attribute mark_debug of user_valid_prv    : signal is "true";
    --attribute mark_debug of user_valid_fifo   : signal is "true";
    --attribute mark_debug of user_last_prv     : signal is "true";
    --attribute mark_debug of cnt_bytes         : signal is "true";
    --attribute mark_debug of wait_cnt          : signal is "true";
    --attribute mark_debug of vmm_ser_done      : signal is "true";
    --attribute mark_debug of vmm_conf_rdy      : signal is "true";
    --attribute mark_debug of fpga_conf         : signal is "true";
    --attribute mark_debug of flash_conf        : signal is "true";
    --attribute mark_debug of sel_vmm_data      : signal is "true";
    --attribute mark_debug of xadc_conf         : signal is "true";
    --attribute mark_debug of rst_fifo          : signal is "true";
    --attribute mark_debug of xadcPacket_rdy    : signal is "true";
    --attribute mark_debug of flashPacket_rdy   : signal is "true";
    --attribute mark_debug of fpgaPacket_rdy    : signal is "true";
    --attribute mark_debug of fpga_conf_1of2    : signal is "true";
    --attribute mark_debug of fpga_conf_2of2    : signal is "true";
    --attribute mark_debug of rd_ena            : signal is "true";
    --attribute mark_debug of fifo_full         : signal is "true";
    --attribute mark_debug of fifo_empty        : signal is "true";

    --------------- List of Processes/FSMs ----------------
    -------------------------------------------------------
    --- 1. delay_din            (clk_125)
    --- 2. master_conf_FSM      (clk_125)
    --- 3. XADC_conf_proc       (clk_125)
    --- 4. FLASH_conf_proc      (clk_125)
    --- 5. FPGA_conf_proc       (clk_125)
    --- 6. VMM_conf_proc        (clk_125)
    --- 7. VMM_conf_CKTK_FSM    (clk_40)
    --- 8. FIFO_valid_MUX       (async)
    -------------------------------------------------------
    -------------------------------------------------------
begin

-- delay the input data for correct sampling by the sub-processes
delay_din: process(clk_125)
begin
    if(rising_edge(clk_125))then
        user_data_prv   <= udp_rx.data.data_in;
        user_valid_prv  <= udp_rx.data.data_in_valid;
        user_last_prv   <= udp_rx.data.data_in_last;
    end if;
end process;

-- Central configuarion FSM that checks for the first valid pulse
-- and for the UDP port, in order to initialize the byte counter 
-- that the sub-processes will use to sample the configuration data
master_handling_FSM: process(clk_125)
begin
    if(rising_edge(clk_125))then
        if(rst = '1')then
            cnt_bytes   <= (others => '0');
            vmm_conf    <= '0';
            fpga_conf   <= '0';
            flash_conf  <= '0';
            xadc_conf   <= '0';
            init_ser    <= '0';
            rst_fifo    <= '1';
            st_master   <= ST_IDLE;
        else
            case st_master is

            -- wait for valid signal to initialize counter
            when ST_IDLE => 
                vmm_conf    <= '0';
                fpga_conf   <= '0';
                flash_conf  <= '0';
                xadc_conf   <= '0';
                rst_fifo    <= '0';

                if(udp_rx.data.data_in_valid = '1')then
                    cnt_bytes   <= cnt_bytes + 1;
                    st_master   <= ST_CHK_PORT;
                else
                    cnt_bytes   <= (others => '0');
                    st_master   <= ST_IDLE;
                end if;

            -- check the port     
            when ST_CHK_PORT =>
                cnt_bytes   <= cnt_bytes + 1;
                
                case udp_rx.hdr.dst_port is
                when x"1778" => -- VMM CONF
                    vmm_conf    <= '1';
                    rst_fifo    <= '0'; -- release the reset of the FIFO
                    st_master   <= ST_COUNT;
                when x"19C8" => -- FPGA CONF
                    fpga_conf   <= '1';
                    st_master   <= ST_COUNT;
                when x"1777" => -- FPGA CONF
                    fpga_conf   <= '1';
                    st_master   <= ST_COUNT;
                when x"19CC" => -- FLASH CONF
                    flash_conf  <= '1';
                    st_master   <= ST_COUNT;
                when x"19D0" => -- XADC CONF
                    xadc_conf   <= '1';
                    st_master   <= ST_COUNT;
                when others => 
                    st_master   <= ST_CHK_PORT;
                end case;

            -- mark_debug counting and wait for configuration packets to be formed
            when ST_COUNT => 
                cnt_bytes <= cnt_bytes + 1;

                if(xadcPacket_rdy = '1' or flashPacket_rdy = '1' or fpgaPacket_rdy = '1' or vmm_conf_rdy = '1')then
                    st_master <= ST_WAIT_FOR_BUSY;
                else
                    st_master <= ST_COUNT;
                end if;

            -- stop counting and wait for corresponding sub-module to get the init signal
            -- or wait for sub-process to finish
            when ST_WAIT_FOR_BUSY =>
                if(xadcPacket_rdy = '1' and xadc_busy_s125 = '1')then
                    xadc_conf   <= '0';
                    st_master   <= ST_WAIT_FOR_IDLE;
                elsif(flashPacket_rdy = '1' and flash_busy_s125 = '1')then
                    flash_conf  <= '0';
                    st_master   <= ST_WAIT_FOR_IDLE;
                elsif(fpgaPacket_rdy = '1' and udp_rx.data.data_in_valid = '0')then -- no need to wait, jump to idle state
                    fpga_conf   <= '0';
                    st_master   <= ST_IDLE;
                elsif(vmm_conf_rdy = '1')then -- initialize serialization
                    init_ser    <= '1';
                    vmm_conf    <= '0';
                    st_master   <= ST_RESET_FIFO;
                else
                    st_master   <= ST_WAIT_FOR_BUSY;
                end if;
        
            -- wait for corresponding sub-module to finish processing    
            when ST_WAIT_FOR_IDLE =>
                if(xadc_busy_s125 = '0' and flash_busy_s125 = '0' and udp_rx.data.data_in_valid = '0')then
                    st_master <= ST_IDLE;
                else
                    st_master <= ST_WAIT_FOR_IDLE;
                end if;

            -- create a reset signal of adequate length. release the reset
            -- only when flow_fsm and cktk_fsm are in the appropriate states
            when ST_RESET_FIFO =>
                if(vmmSer_done_s125 = '1' and top_rdy_s125 = '0')then -- flow_fsm is back to IDLE + serialization has finished => reset
                    rst_fifo    <= '1';
                    init_ser    <= '0';
                    st_master   <= ST_WAIT_FOR_CKTK_FSM;
                else
                    rst_fifo    <= '0';     -- serialization not finished or flow_fsm is not in IDLE, wait
                    init_ser    <= '1';
                    st_master   <= ST_RESET_FIFO;
                end if;

            -- wait for CKTK FSM to latch the reset signal
            when ST_WAIT_FOR_CKTK_FSM =>
                if(vmmSer_done_s125 = '0' and udp_rx.data.data_in_valid = '0')then
                    rst_fifo    <= '0';
                    st_master   <= ST_IDLE;
                else
                    rst_fifo    <= '1';
                    st_master   <= ST_WAIT_FOR_CKTK_FSM;
                end if;

            when others => 
                st_master <= ST_IDLE;
            end case;
        end if;
    end if;
end process;

fpga_config_logic: fpga_config_block
    port map(
        -----------------------------------
        ------- General Interface ----------
        clk_125             => clk_125,
        rst                 => rst,
        cnt_bytes           => cnt_bytes,
        user_din_udp        => user_data_prv,
        ------------------------------------
        ---------- XADC Interface ----------
        xadc_conf           => xadc_conf,
        xadcPacket_rdy      => xadcPacket_rdy,
        vmm_id_xadc         => vmm_id_xadc,
        xadc_sample_size    => xadc_sample_size,
        xadc_delay          => xadc_delay,
        ------------------------------------
        ---------- AXI4SPI Interface -------
        flash_conf          => flash_conf,
        flashPacket_rdy     => flashPacket_rdy,
        myIP_set            => myIP_set,
        myMAC_set           => myMAC_set,
        destIP_set          => destIP_set,
        ------------------------------------
        -------- FPGA Config Interface -----
        fpga_conf           => fpga_conf,
        fpgaPacket_rdy      => fpgaPacket_rdy,
        latency             => latency,
        fpga_rst_conf       => fpga_rst_conf,
        daq_off             => daq_off,
        daq_on              => daq_on,
        ext_trigger         => ext_trigger
    );

vmm_config_logic: vmm_config_block
    port map(
        ------------------------------------
        ------- General Interface ----------
        clk_125             => clk_125,
        clk_40              => clk_40,
        rst                 => rst,
        rst_fifo            => rst_fifo_s40,
        cnt_bytes           => cnt_bytes,
        ------------------------------------
        --------- FIFO/UDP Interface -------
        user_din_udp        => user_data_prv,
        user_valid_udp      => user_valid_prv,
        user_last_udp       => user_last_prv,
        ------------------------------------
        ------ VMM Config Interface --------
        vmm_id              => vmm_id,
        vmmConf_rdy         => vmm_conf_rdy,
        vmmConf_done        => vmm_ser_done,
        vmm_cktk            => vmm_cktk,
        vmm_cfg_bit         => vmm_cfg_bit,
        vmm_conf            => vmm_conf,
        top_rdy             => top_rdy_s40,
        init_ser            => init_ser_s40
    );

    xadc_rdy        <= xadcPacket_rdy;
    newIP_rdy       <= flashPacket_rdy;
    vmmConf_rdy     <= init_ser;
    vmmConf_done    <= vmm_ser_done;

---------------------------------------------------------
--------- Clock Domain Crossing Sync Block --------------
---------------------------------------------------------
CDCC_200to125: CDCC
    generic map(NUMBER_OF_BITS => 2)
    port map(
        clk_src         => clk_200,
        clk_dst         => clk_125,

        data_in(0)      => top_rdy,
        data_in(1)      => xadc_busy,

        data_out_s(0)   => top_rdy_s125,
        data_out_s(1)   => xadc_busy_s125
    );

CDCC_50to125: CDCC
    generic map(NUMBER_OF_BITS => 1)
    port map(
        clk_src         => clk_50,
        clk_dst         => clk_125,

        data_in(0)      => flash_busy,
        data_out_s(0)   => flash_busy_s125
    );

CDCC_200to40: CDCC
    generic map(NUMBER_OF_BITS => 1)
    port map(
        clk_src         => clk_200,
        clk_dst         => clk_40,

        data_in(0)      => top_rdy,
        data_out_s(0)   => top_rdy_s40
    );

CDCC_125to40: CDCC
    generic map(NUMBER_OF_BITS => 2)
    port map(
        clk_src         => clk_125,
        clk_dst         => clk_40,
  
        data_in(0)      => init_ser,
        data_in(1)      => rst_fifo,
        data_out_s(0)   => init_ser_s40,
        data_out_s(1)   => rst_fifo_s40
    );

CDCC_40to125: CDCC
    generic map(NUMBER_OF_BITS => 1)
    port map(
        clk_src         => clk_40,
        clk_dst         => clk_125,
  
        data_in(0)      => vmm_ser_done,
        data_out_s(0)   => vmmSer_done_s125
    );
---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------

end RTL;