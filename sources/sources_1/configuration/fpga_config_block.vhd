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
    cnt_bytes           : in  unsigned(4 downto 0);
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
    -------- FPGA Config Interface -----
    fpga_conf           : in  std_logic;
    fpgaPacket_rdy      : out std_logic;
    latency             : out std_logic_vector(15 downto 0);
    fpga_rst_conf       : out std_logic;
    daq_off             : out std_logic;
    daq_on              : out std_logic;
    ext_trigger         : out std_logic
    );
end fpga_config_block;

architecture RTL of fpga_config_block is
    
    signal fpga_conf_1of2   : std_logic_vector(31 downto 0) := (others => '0');
    signal fpga_conf_2of2   : std_logic_vector(31 downto 0) := (others => '0');

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
                when "00011" => --3
                    vmm_id_xadc(15 downto 8)      <= user_din_udp;    
                when "00100" => --4
                    vmm_id_xadc(7 downto 0)       <= user_din_udp;
                when "00111" => --7
                    xadc_sample_size(10 downto 8) <= user_din_udp(2 downto 0);
                when "01000" => --8
                    xadc_sample_size(7 downto 0)  <= user_din_udp;
                when "01010" => --10
                    xadc_delay(17 downto 16)      <= user_din_udp(1 downto 0);
                when "01011" => --11
                    xadc_delay(15 downto 8)       <= user_din_udp;
                when "01100" => --12
                    xadc_delay(7 downto 0)        <= user_din_udp;
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
                    myIP_set(31 downto 24)      <= user_din_udp;
                when "01010" => --10
                    myIP_set(23 downto 16)      <= user_din_udp;
                when "01011" => --11
                    myIP_set(15 downto 8)       <= user_din_udp;
                when "01100" => --12
                    myIP_set(7 downto 0)        <= user_din_udp;
                when "01111" => --15
                    myMAC_set(47 downto 40)     <= user_din_udp;
                when "10000" => --16
                    myMAC_set(39 downto 32)     <= user_din_udp;
                when "10001" => --17
                    myMAC_set(31 downto 24)     <= user_din_udp;
                when "10010" => --18
                    myMAC_set(23 downto 16)     <= user_din_udp;
                when "10011" => --19
                    myMAC_set(15 downto 8)      <= user_din_udp;
                when "10100" => --20
                    myMAC_set(7 downto 0)       <= user_din_udp;
                when "10101" => --21
                    destIP_set(31 downto 24)    <= user_din_udp;
                when "10110" => --22
                    destIP_set(23 downto 16)    <= user_din_udp;
                when "10111" => --23
                    destIP_set(15 downto 8)     <= user_din_udp;
                when "11000" => --24
                    destIP_set(7 downto 0)      <= user_din_udp;
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
                    fpga_conf_1of2(31 downto 24)    <= user_din_udp;
                when "10010" => --18
                    fpga_conf_1of2(23 downto 16)    <= user_din_udp;
                when "10011" => --19
                    fpga_conf_1of2(15 downto 8)     <= user_din_udp;
                when "10100" => --20
                    fpga_conf_1of2(7 downto 0)      <= user_din_udp;
                when "10101" => --21
                    fpga_conf_2of2(31 downto 24)    <= user_din_udp;
                when "10110" => --22
                    fpga_conf_2of2(23 downto 16)    <= user_din_udp;
                when "10111" => --23
                    fpga_conf_2of2(15 downto 8)     <= user_din_udp;
                when "11000" => --24
                    fpga_conf_2of2(7 downto 0)      <= user_din_udp;
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

end RTL;