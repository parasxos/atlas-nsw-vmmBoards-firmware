----------------------------------------------------------------------------------
-- Company: NTU ATHNENS - BNL
-- Engineer: Panagiotis Gkountoumis
-- 
-- Create Date: 18.04.2016 13:00:21
-- Design Name: 
-- Module Name: config_logic - Behavioral
-- Project Name: MMFE8 
-- Target Devices: Arix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Chandelog:
-- 19.07.2016 Reverted component to work asynchronously (Reid Pinkham)
-- 20.07.2016 Changed packet length from integer to std_logic_vector (Reid Pinkham)
-- 04.08.2016 Added XADC support (Reid Pinkham)
----------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;


entity select_data is
port(
    configuring                 : in  std_logic;
    data_acq                    : in  std_logic;
    xadc                        : in  std_logic;
    we_data                     : in  std_logic;
    we_conf                     : in  std_logic;
    we_xadc                     : in  std_logic;
    daq_data_in                 : in  std_logic_vector(63 downto 0);
    conf_data_in                : in  std_logic_vector(63 downto 0);
    xadc_data_in                : in  std_logic_vector(63 downto 0);
    data_packet_length          : in  std_logic_vector(11 downto 0);
    xadc_packet_length          : in  std_logic_vector(11 downto 0);
    end_packet_conf             : in  std_logic;
    end_packet_daq              : in  std_logic;
    end_packet_xadc             : in  std_logic;
    fifo_rst_daq                : in  std_logic;
    fifo_rst_xadc               : in  std_logic;

    data_out                    : out std_logic_vector(63 downto 0);
    packet_length               : out std_logic_vector(11 downto 0);
    we                          : out std_logic;
    end_packet                  : out std_logic;
    fifo_rst                    : out std_logic
);
end select_data;

architecture Behavioral of select_data is

signal sel                      : std_logic_vector(2 downto 0);
begin

data_selection : process(configuring, data_acq)
begin
    sel <= configuring & data_acq & xadc;
        case sel is
            when "100" => -- Configuration
                we              <= we_conf;
                data_out        <= conf_data_in;
                packet_length   <= x"002"; -- constant length
                end_packet      <= end_packet_conf;
                fifo_rst        <= '0';
            when "010" => -- DAQ
                we              <= we_data;
                data_out        <= daq_data_in;
                packet_length   <= data_packet_length;
                end_packet      <= end_packet_daq;
                fifo_rst        <= fifo_rst_daq;
            when "001" => -- XADC
                we              <= we_xadc;
                data_out        <= xadc_data_in;
                packet_length   <= xadc_packet_length;
                end_packet      <= end_packet_xadc;
                fifo_rst        <= fifo_rst_xadc;
            when others =>
                we              <= '0';
                data_out        <= (others => '0');
                packet_length   <= x"000";
                end_packet      <= '0';
                fifo_rst        <= '0';
        end case; 
end process;

end Behavioral;
