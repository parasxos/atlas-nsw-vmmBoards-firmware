----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch) 
-- 
-- Create Date: 30.01.2017
-- Design Name: FPGA Configuration Block
-- Module Name: fpga_config_block - RTL
-- Project Name: MMFE8 - NTUA
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484
-- Tool Versions: Vivado 2016.2
-- Description: Module that samples the data coming from the UDP/Ethernet
-- to produce various control signals for the FPGA user logic. It controls
-- the configuration of the XADC/AXI4SPI_FLASH modules and more general
-- FPGA commands.

-- Dependencies: MMFE8 NTUA Project
-- 
-- Changelog:
-- 07.03.2017 Changed FPGA_conf_proc to accomodate CKBC/CKTP configuration
-- and future register address configuration scheme. (Christos Bakalis)
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity fpga_config_block is
    port(
    ------------------------------------
    ------- General Interface ----------
    clk_125             : in  std_logic;
    rst                 : in  std_logic;
    cnt_bytes           : in  unsigned(7 downto 0);
    user_din_udp        : in  std_logic_vector(7 downto 0); --prv
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
    -------- CKTP/CKBC Interface -------
    ckbc_freq           : out std_logic_vector(7 downto 0);
    cktk_max_num        : out std_logic_vector(7 downto 0);
    cktp_max_num        : out std_logic_vector(15 downto 0);
    cktp_skew           : out std_logic_vector(7 downto 0);
    cktp_period         : out std_logic_vector(15 downto 0);
    cktp_width          : out std_logic_vector(7 downto 0);
    ------------------------------------
    -------- FPGA Config Interface -----
    fpga_conf           : in  std_logic;
    fpgaPacket_rdy      : out std_logic;
    latency             : out std_logic_vector(15 downto 0);
    daq_off             : out std_logic;
    daq_on              : out std_logic;
    ext_trigger         : out std_logic
    );
end fpga_config_block;

architecture RTL of fpga_config_block is
    
    -- register value and address from UDP packet
    signal reg_address      : std_logic_vector(7 downto 0)  := (others => '0');
    signal reg_value        : std_logic_vector(31 downto 0) := (others => '0');

    -- internal registers
    signal daq_state_reg    : std_logic_vector(7 downto 0)  := (others => '0');
    signal trig_state_reg   : std_logic_vector(7 downto 0)  := (others => '0');

    -- internal signal declarations (to assert default values)
    --signal daq_off_i        : std_logic := '1';
    --signal daq_on_i         : std_logic := '0';
    --signal ext_trigger_i    : std_logic := '0';
    --signal latency_i        : std_logic_vector(15 downto 0) := (others => '0'); -- ??????
    --signal ckbc_freq_i      : std_logic_vector(7 downto 0)  := x"28";           -- 40 Mhz
    --signal cktk_numb_i      : std_logic_vector(7 downto 0)  := x"07";           -- 7 CKTKs
    --signal cktp_Pnum_i      : std_logic_vector(15 downto 0) := x"ffff";         -- infinite
    --signal cktp_skew_i      : std_logic_vector(7 downto 0)  := (others => '0'); -- aligned
    --signal cktp_peri_i      : std_logic_vector(15 downto 0) := (others => '0'); -- ?????? 1 ms
    --signal cktp_widt_i      : std_logic_vector(7 downto 0)  := (others => '0'); -- ?????? 2 us

begin

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
                when "00000011" => --3
                    vmm_id_xadc(15 downto 8)      <= user_din_udp;    
                when "00000100" => --4
                    vmm_id_xadc(7 downto 0)       <= user_din_udp;
                when "00000111" => --7
                    xadc_sample_size(10 downto 8) <= user_din_udp(2 downto 0);
                when "00001000" => --8
                    xadc_sample_size(7 downto 0)  <= user_din_udp;
                when "00001010" => --10
                    xadc_delay(17 downto 16)      <= user_din_udp(1 downto 0);
                when "00001011" => --11
                    xadc_delay(15 downto 8)       <= user_din_udp;
                when "00001100" => --12
                    xadc_delay(7 downto 0)        <= user_din_udp;
                when "00001110" => --14
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
                when "00001001" => --9
                    myIP_set(31 downto 24)      <= user_din_udp;
                when "00001010" => --10
                    myIP_set(23 downto 16)      <= user_din_udp;
                when "00001011" => --11
                    myIP_set(15 downto 8)       <= user_din_udp;
                when "00001100" => --12
                    myIP_set(7 downto 0)        <= user_din_udp;
                when "00001111" => --15
                    myMAC_set(47 downto 40)     <= user_din_udp;
                when "00010000" => --16
                    myMAC_set(39 downto 32)     <= user_din_udp;
                when "00010001" => --17
                    myMAC_set(31 downto 24)     <= user_din_udp;
                when "00010010" => --18
                    myMAC_set(23 downto 16)     <= user_din_udp;
                when "00010011" => --19
                    myMAC_set(15 downto 8)      <= user_din_udp;
                when "00010100" => --20
                    myMAC_set(7 downto 0)       <= user_din_udp;
                when "00010101" => --21
                    destIP_set(31 downto 24)    <= user_din_udp;
                when "00010110" => --22
                    destIP_set(23 downto 16)    <= user_din_udp;
                when "00010111" => --23
                    destIP_set(15 downto 8)     <= user_din_udp;
                when "00011000" => --24
                    destIP_set(7 downto 0)      <= user_din_udp;
                when "00011010" => --26
                    flashPacket_rdy  <= '1';
                when others => null;
                end case;
            else
                flashPacket_rdy <= '0';
            end if;
        end if;
    end if;
end process;

-- sub-process that samples register addresses and values for FPGA configuration
FPGA_conf_proc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        if(rst = '1')then
            fpgaPacket_rdy  <= '0';
            reg_address     <= (others => '0');
            reg_value       <= (others => '0');
        else
            if(fpga_conf = '1')then
                case cnt_bytes is
                --- register addresses -----
                when "00001100" => -- 12
                    reg_address <= user_din_udp;
                when "00010100" => -- 20
                    reg_address <= user_din_udp;
                when "00011100" => -- 28
                    reg_address <= user_din_udp;
                when "00100100" => -- 36
                    reg_address <= user_din_udp;
                when "00101100" => -- 44
                    reg_address <= user_din_udp;
                when "00110100" => -- 52
                    reg_address <= user_din_udp;
                when "00111100" => -- 60
                    reg_address <= user_din_udp;
                ----------------------------
                --- register values --------
                when "00001101" => -- 13
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00001110" => -- 14
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00001111" => -- 15
                    reg_value(15 downto 8)     <= user_din_udp;
                when "00010000" => -- 16
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "00010101" => -- 21
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00010110" => -- 22
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00010111" => -- 23
                    reg_value(15 downto 8)     <= user_din_udp;
                when "00011000" => -- 24
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "00011101" => -- 29
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00011110" => -- 30
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00011111" => -- 31
                    reg_value(15 downto 8)     <= user_din_udp;
                when "00100000" => -- 32
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "00100101" => -- 37
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00100110" => -- 38
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00100111" => -- 39
                    reg_value(15 downto 8)     <= user_din_udp;
                when "00101000" => -- 40
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "00101101" => -- 45
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00101110" => -- 46
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00101111" => -- 47
                    reg_value(15 downto 8)     <= user_din_udp;
                when "00110000" => -- 48
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "00110101" => -- 53
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00110110" => -- 54
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00110111" => -- 55
                    reg_value(15 downto 8)     <= user_din_udp;
                when "00111000" => -- 56
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "00111101" => -- 61
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00111110" => -- 62
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00111111" => -- 63
                    reg_value(15 downto 8)     <= user_din_udp;
                when "01000000" => -- 64
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "01000001" => -- 65
                     fpgaPacket_rdy  <= '1';
                when others => null;
                end case;
            else
                fpgaPacket_rdy  <= '0';
                reg_address     <= (others => '0');
                reg_value       <= (others => '0');
            end if;
        end if;
    end if;
end process;

-- demux that assigns values to signals depending on the address
regMap_demux_proc: process(reg_address, reg_value)
begin
    case reg_address is
    when x"00"  => trig_state_reg   <= reg_value(7 downto 0);
    when x"0f"  => daq_state_reg    <= reg_value(7 downto 0);
    when x"05"  => latency          <= reg_value(15 downto 0);
    when x"c1"  => cktk_max_num     <= reg_value(7 downto 0);
    when x"c2"  => ckbc_freq        <= reg_value(7 downto 0);
    when x"c3"  => cktp_max_num     <= reg_value(15 downto 0);
    when x"c4"  => cktp_skew        <= reg_value(7 downto 0);
    when x"c5"  => cktp_period      <= reg_value(15 downto 0);
    when x"c6"  => cktp_width       <= reg_value(7 downto 0);
    when others => null;
    end case;
end process;

-- process to handle daq state and trigger state 
daqOnOff_proc: process(daq_state_reg)
begin
    case daq_state_reg is
    when x"01"  => daq_on <= '1'; daq_off <= '0';
    when x"00"  => daq_on <= '0'; daq_off <= '1';
    when others => null;
    end case;
end process;

-- process to handle trigger state
triggerState_proc: process(trig_state_reg)
begin
    case trig_state_reg is
    when x"04"  => ext_trigger <= '1';
    when x"07"  => ext_trigger <= '0';
    when others => null;
    end case;
end process;

    --ckbc_freq       <= ckbc_freq_i;
    --cktk_max_num    <= cktk_numb_i;
    --cktp_max_num    <= cktp_Pnum_i;
    --cktp_skew       <= cktp_skew_i;
    --cktp_period     <= cktp_peri_i;
    --cktp_width      <= cktp_widt_i;
    --latency         <= latency_i;
    --daq_off         <= daq_off_i;
    --daq_on          <= daq_on_i;
    --ext_trigger     <= ext_trigger_i;

end RTL;