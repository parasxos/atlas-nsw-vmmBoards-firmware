----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch) 
-- 
-- Create Date: 30.01.2017
-- Design Name: configuration block
-- Module Name: configuration_block - RTL
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
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;

entity configuration_block is
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
    user_data           : in  std_logic_vector(7 downto 0);
    user_valid          : in  std_logic;
    user_last           : in  std_logic;
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
end configuration_block;

architecture RTL of configuration_block is

    COMPONENT vmm_conf_buffer
    PORT (
        rst     : IN STD_LOGIC;
        wr_clk  : IN STD_LOGIC;
        rd_clk  : IN STD_LOGIC;
        din     : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        wr_en   : IN STD_LOGIC;
        rd_en   : IN STD_LOGIC;
        dout    : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        full    : OUT STD_LOGIC;
        empty   : OUT STD_LOGIC
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
    signal user_valid_fifo  : std_logic := '0';
    signal user_last_prv    : std_logic := '0';
    signal cnt_bytes        : unsigned(4 downto 0) := (others => '0');
    signal wait_cnt         : unsigned(1 downto 0) := (others => '0');
    signal vmm_conf         : std_logic := '0';
    signal vmm_ser_done     : std_logic := '0';
    signal vmmSer_done_s125 : std_logic := '0';
    signal vmm_conf_rdy     : std_logic := '0';
    signal fpga_conf        : std_logic := '0';
    signal flash_conf       : std_logic := '0';
    signal sel_vmm_data     : std_logic := '0';
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
    signal fpga_conf_1of2   : std_logic_vector(31 downto 0) := (others => '0');
    signal fpga_conf_2of2   : std_logic_vector(31 downto 0) := (others => '0');
    signal dest_port        : std_logic_vector(15 downto 0) := (others => '0');
    signal rd_ena           : std_logic := '0';
    signal fifo_full        : std_logic := '0';
    signal fifo_empty       : std_logic := '0';
    
    type masterFSM is (ST_IDLE, ST_CHK_PORT, ST_COUNT, ST_WAIT_FOR_BUSY, ST_WAIT_FOR_IDLE, ST_RESET_FIFO, ST_WAIT_FOR_CKTK_FSM);
    signal st_master : masterFSM := ST_IDLE;
    
    type confFSM is (ST_IDLE, ST_RD_HIGH, ST_RD_LOW, ST_CKTK_LOW, ST_DONE);
    signal st_conf : confFSM := ST_IDLE;
    
    ---- Uncomment the following to add signals to ILA debugging core
    -----------------------------------------------------------------
    --attribute mark_debug : string;

    --attribute mark_debug of latency           : signal is "true";
    --attribute mark_debug of fpga_rst_conf     : signal is "true";
    --attribute mark_debug of daq_off           : signal is "true";
    --attribute mark_debug of daq_on            : signal is "true";
    --attribute mark_debug of ext_trigger       : signal is "true";
    --attribute mark_debug of user_data         : signal is "true";
    --attribute mark_debug of user_valid        : signal is "true";
    --attribute mark_debug of user_last         : signal is "true";
    --attribute mark_debug of dest_port         : signal is "true";
    --attribute mark_debug of flash_busy        : signal is "true";
    --attribute mark_debug of newIP_rdy         : signal is "true";
    --attribute mark_debug of myIP_set          : signal is "true";
    --attribute mark_debug of myMAC_set         : signal is "true";
    --attribute mark_debug of destIP_set        : signal is "true";
    --attribute mark_debug of vmm_id            : signal is "true";
    --attribute mark_debug of vmmConf_rdy       : signal is "true";
    --attribute mark_debug of vmmConf_done      : signal is "true";
    --attribute mark_debug of vmm_cktk          : signal is "true";
    --attribute mark_debug of vmm_cfg_bit       : signal is "true";
    --attribute mark_debug of top_rdy           : signal is "true";
    --attribute mark_debug of xadc_busy         : signal is "true";
    --attribute mark_debug of xadc_rdy          : signal is "true";
    --attribute mark_debug of vmm_id_xadc       : signal is "true";
    --attribute mark_debug of xadc_sample_size  : signal is "true";
    --attribute mark_debug of xadc_delay        : signal is "true";

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
        user_data_prv   <= user_data;
        user_valid_prv  <= user_valid;
        user_last_prv   <= user_last;
    end if;
end process;

-- Central configuarion FSM that checks for the first valid pulse
-- and for the UDP port, in order to initialize the byte counter 
-- that the sub-processes will use to sample the configuration data
master_conf_FSM: process(clk_125)
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
                rst_fifo    <= '1';

                if(user_valid = '1')then
                    cnt_bytes   <= cnt_bytes + 1;
                    st_master   <= ST_CHK_PORT;
                else
                    cnt_bytes   <= (others => '0');
                    st_master   <= ST_IDLE;
                end if;

            -- check the port     
            when ST_CHK_PORT =>
                cnt_bytes   <= cnt_bytes + 1;
                
                case dest_port is
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
                elsif(fpgaPacket_rdy = '1' and user_valid = '0')then -- no need to wait, jump to idle state
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
                if(xadc_busy_s125 = '0' and user_valid = '0')then
                    st_master <= ST_IDLE;
                elsif(flash_busy_s125 = '0' and user_valid = '0')then
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
                if(vmmSer_done_s125 = '0' and user_valid = '0')then
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

-- sub-process that samples data for XADC configuration
XADC_conf_proc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        if(rst = '1')then
            xadcPacket_rdy      <= '0';
            vmm_id_xadc         <= "0000000000000000";
            xadc_sample_size    <= "01111111111"; -- 1023 packets
            xadc_delay          <= "011111111111111111"; -- 1023 samples over ~0.7 seconds
        else    
            if(xadc_conf = '1')then
                case cnt_bytes is
                when "00011" => --3
                    vmm_id_xadc(15 downto 8)      <= user_data_prv;    
                when "00100" => --4
                    vmm_id_xadc(7 downto 0)       <= user_data_prv;
                when "00111" => --7
                    xadc_sample_size(10 downto 8) <= user_data_prv(2 downto 0);
                when "01000" => --8
                    xadc_sample_size(7 downto 0)  <= user_data_prv;
                when "01010" => --10
                    xadc_delay(17 downto 16)      <= user_data_prv(1 downto 0);
                when "01011" => --11
                    xadc_delay(15 downto 8)       <= user_data_prv;
                when "01100" => --12
                    xadc_delay(7 downto 0)        <= user_data_prv;
                when "01110" => --14
                    xadcPacket_rdy   <= '1';
                when others => null;
                end case;
            else
                xadcPacket_rdy      <= '0';
            end if;
        end if;
    end if;
end process;

-- sub-process that samples data for flash memory configuration
FLASH_conf_proc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        if(rst = '1')then
            flashPacket_rdy <= '0';
            myIP_set        <= (others => '0');
            myMAC_set       <= (others => '0');
            destIP_set      <= (others => '0');
        else
            if(flash_conf = '1')then
                case cnt_bytes is
                when "01001" => --9
                    myIP_set(31 downto 24)      <= user_data_prv;
                when "01010" => --10
                    myIP_set(23 downto 16)      <= user_data_prv;
                when "01011" => --11
                    myIP_set(15 downto 8)       <= user_data_prv;
                when "01100" => --12
                    myIP_set(7 downto 0)        <= user_data_prv;
                when "01111" => --15
                    myMAC_set(47 downto 40)     <= user_data_prv;
                when "10000" => --16
                    myMAC_set(39 downto 32)     <= user_data_prv;
                when "10001" => --17
                    myMAC_set(31 downto 24)     <= user_data_prv;
                when "10010" => --18
                    myMAC_set(23 downto 16)     <= user_data_prv;
                when "10011" => --19
                    myMAC_set(15 downto 8)      <= user_data_prv;
                when "10100" => --20
                    myMAC_set(7 downto 0)       <= user_data_prv;
                when "10101" => --21
                    destIP_set(31 downto 24)    <= user_data_prv;
                when "10110" => --22
                    destIP_set(23 downto 16)    <= user_data_prv;
                when "10111" => --23
                    destIP_set(15 downto 8)     <= user_data_prv;
                when "11000" => --24
                    destIP_set(7 downto 0)      <= user_data_prv;
                when "11010" => --26
                    flashPacket_rdy  <= '1';
                when others => null;
                end case;
            else
                flashPacket_rdy <= '0';
            end if;
        end if;
    end if;
end process;

-- sub-process that samples data for FPGA configuration
FPGA_conf_proc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        if(rst = '1')then
            fpgaPacket_rdy  <= '0';
            fpga_rst_conf   <= '0';
            daq_off         <= '0';
            daq_on          <= '0';
            ext_trigger     <= '0';
            fpga_conf_1of2  <= (others => '0');
            fpga_conf_2of2  <= (others => '0');
            latency         <= (others => '0');
        else
            if(fpga_conf = '1')then
                case cnt_bytes is
                when "10001" => --17
                    fpga_conf_1of2(31 downto 24)    <= user_data_prv;
                when "10010" => --18
                    fpga_conf_1of2(23 downto 16)    <= user_data_prv;
                when "10011" => --19
                    fpga_conf_1of2(15 downto 8)     <= user_data_prv;
                when "10100" => --20
                    fpga_conf_1of2(7 downto 0)      <= user_data_prv;
                when "10101" => --21
                    fpga_conf_2of2(31 downto 24)    <= user_data_prv;
                when "10110" => --22
                    fpga_conf_2of2(23 downto 16)    <= user_data_prv;
                when "10111" => --23
                    fpga_conf_2of2(15 downto 8)     <= user_data_prv;
                when "11000" => --24
                    fpga_conf_2of2(7 downto 0)      <= user_data_prv;
                when "11010" => --26
                    if(fpga_conf_1of2 = x"00000000" and fpga_conf_2of2 = x"00000004")then
                        ext_trigger     <= '1';
                    elsif(fpga_conf_1of2 = x"00000000" and fpga_conf_2of2 = x"00000007")then
                        ext_trigger     <= '0';
                    elsif(fpga_conf_1of2 = x"0000000f" and fpga_conf_2of2 = x"00000001")then
                        daq_on          <= '1';
                        daq_off         <= '0';
                    elsif(fpga_conf_1of2 = x"0000000f" and fpga_conf_2of2 = x"00000000")then
                        daq_on          <= '0';
                        daq_off         <= '1';
                    elsif(fpga_conf_1of2 = x"ffffffff" and fpga_conf_2of2 = x"ffff8000")then
                        fpga_rst_conf   <= '1';
                    elsif(fpga_conf_1of2 = x"00000005")then
                        latency         <= fpga_conf_2of2(15 downto 0);
                    else
                        null;
                    end if;
                when "11100" => --28
                     fpgaPacket_rdy  <= '1';
                when others => null;
                end case;
            else
                fpgaPacket_rdy  <= '0';
                fpga_conf_1of2  <= (others => '0');
                fpga_conf_2of2  <= (others => '0');
            end if;
        end if;
    end if;
end process;

-- sub-process that first samples the vmm_id and then drives the data into
-- the FIFO used for VMM configuration. it also detects the 'last' pulse 
-- sent from the UDP block to initialize the VMM config data serialization
VMM_conf_proc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        if(rst = '1')then
            vmm_id          <= (others => '0');
            sel_vmm_data    <= '0';
            vmm_conf_rdy    <= '0';
        else
            if(vmm_conf = '1' and user_last_prv = '0')then
                case cnt_bytes is 
                when "00101" => --5
                    vmm_id(15 downto 8) <= user_data_prv;
                when "00110" => --6
                    vmm_id(7 downto 0)  <= user_data_prv;
                when "01000" => --8
                    sel_vmm_data        <= '1'; -- select the correct data at the MUX
                when others => null;
                end case;
            elsif(vmm_conf = '1' and user_last_prv = '1')then -- 'last' pulse detected, signal master FSM
                vmm_conf_rdy    <= '1';
            else
                vmm_conf_rdy    <= '0';
                sel_vmm_data    <= '0';
            end if;
        end if;

    end if;
end process;

-- FSM that reads the data from the serializing FIFO  and asserts the CKTK pulse 
-- after the bit has passed safely into the vmm configuration bus. serialization 
-- starts only after the assertion of the 'last' signal from the UDP block (see VMM_conf_proc)
VMM_conf_CKTK_FSM: process(clk_40)
begin
    if(rising_edge(clk_40))then
        if(rst = '1' or rst_fifo_s40 = '1')then
            st_conf         <= ST_IDLE;
            vmm_ser_done    <= '0';
            rd_ena          <= '0';
            wait_cnt        <= (others => '0');
            vmm_cktk        <= '0';
        else
            case st_conf is

            -- wait for flow_fsm and master_conf_FSM
            when ST_IDLE =>
                vmm_ser_done <= '0';

                if(top_rdy_s40 = '1' and init_ser_s40 = '1')then
                    st_conf <= ST_RD_HIGH;
                else
                    st_conf <= ST_IDLE;
                end if;

            -- assert the rd_ena signal if there is still data in the buffer
            when ST_RD_HIGH =>
                if(fifo_empty = '0')then
                    rd_ena  <= '1';
                    st_conf <= ST_RD_LOW;
                else
                    rd_ena  <= '0';
                    st_conf <= ST_DONE;
                end if;

            -- wait for the FIFO to pass the bit as there is
            -- some latency (see 'embedded registers' at FIFO generator)
            when ST_RD_LOW =>
                rd_ena  <= '0';
                if(wait_cnt = "11")then
                    wait_cnt    <= (others => '0');
                    vmm_cktk    <= '1';
                    st_conf     <= ST_CKTK_LOW;
                else
                    wait_cnt    <= wait_cnt + 1;
                    vmm_cktk    <= '0';
                    st_conf     <= ST_RD_LOW;
                end if;

            -- ground CKTK and then check if there is more data left
            when ST_CKTK_LOW =>
                vmm_cktk    <= '0';
                st_conf     <= ST_RD_HIGH;

            -- stay here until reset by master config FSM
            when ST_DONE =>
                vmm_ser_done  <= '1';
                st_conf       <= ST_DONE;   

            when others =>
                st_conf <= ST_IDLE;
            end case;
        end if;
    end if;
end process;

-- MUX that drives the VMM configuration data into the FIFO
FIFO_valid_MUX: process(sel_vmm_data, user_valid_prv)
begin
    case sel_vmm_data is
    when '0'    =>  user_valid_fifo <= '0';
    when '1'    =>  user_valid_fifo <= user_valid_prv;
    when others =>  user_valid_fifo <= '0';
    end case;
end process;

-- FIFO that serializes the VMM data
FIFO_serializer: vmm_conf_buffer
    PORT MAP(
        rst     => rst_fifo,
        wr_clk  => clk_125,
        rd_clk  => clk_40,
        din     => user_data_prv,
        wr_en   => user_valid_fifo,
        rd_en   => rd_ena,
        dout(0) => vmm_cfg_bit,
        full    => fifo_full,
        empty   => fifo_empty
      );

    xadc_rdy        <= xadcPacket_rdy;
    newIP_rdy       <= flashPacket_rdy;
    vmmConf_rdy     <= init_ser;
    vmmConf_done    <= vmm_ser_done;
    dest_port       <= udp_rx.hdr.dst_port;

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