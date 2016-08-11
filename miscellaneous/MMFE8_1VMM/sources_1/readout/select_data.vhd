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
    clk_in                      : in  std_logic;
    configuring                 : in  std_logic;
    data_acq                    : in  std_logic;
    we_data                     : in  std_logic;
    we_conf                     : in  std_logic;
    daq_data_in                 : in  std_logic_vector(63 downto 0);
    conf_data_in                : in  std_logic_vector(63 downto 0);
    data_packet_length          : in  integer;
    conf_packet_length          : in  integer;
    end_packet_conf             : in  std_logic;
    end_packet_daq              : in  std_logic;
    data_out                    : out std_logic_vector(63 downto 0);
    packet_length               : out integer;
    we                          : out std_logic;
    end_packet                  : out std_logic
);
end select_data;

architecture Behavioral of select_data is
begin

data_selection : process(clk_in, configuring, data_acq)
begin
    if rising_edge(clk_in) then
        if configuring = '1' then
            we              <= we_conf;
            data_out        <= conf_data_in;
            packet_length   <= 2;--conf_packet_length;
            end_packet      <= end_packet_conf;
        elsif data_acq = '1' then
            we              <= we_data;
            data_out        <= daq_data_in;
            packet_length   <= data_packet_length;
            end_packet      <= end_packet_daq;
        else
            we              <= '0';
            data_out        <= (others => '0');
            packet_length   <= 0;
            end_packet      <= '0';
        end if; 
    end if;
end process;

end Behavioral;
