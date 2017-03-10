----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Create Date: 02.04.2017
-- Design Name: ICMP UDP MUX
-- Module Name: icmp_udp_mux - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: Vivado 2016.2
-- Description: This module instantiates a multiplexer that selects between data
-- input from UDP_TX or ICMP_TX and forwards the data to the IP layer.
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.axi.all;
use work.ipv4_types.all;

entity icmp_udp_mux is
  Port(
       sel_icmp         : in  std_logic; 
       ip_tx_start_icmp : in  std_logic;
       ip_tx_icmp       : in  ipv4_tx_type;
       ip_tx_start_udp  : in  std_logic;
       ip_tx_udp        : in  ipv4_tx_type;
       ip_tx_start_IP   : out std_logic;
       ip_tx_IP         : out ipv4_tx_type
    );
end icmp_udp_mux;

architecture Behavioral of icmp_udp_mux is

begin

ICMPudpMUX_proc: process(sel_icmp, ip_tx_start_icmp, ip_tx_icmp, ip_tx_start_udp, ip_tx_udp)
begin
    case sel_icmp is
    when '0' =>
        ip_tx_start_IP  <= ip_tx_start_udp;
        ip_tx_IP        <= ip_tx_udp;
    when '1' =>
        ip_tx_start_IP  <= ip_tx_start_icmp;
        ip_tx_IP        <= ip_tx_icmp;
    when others =>
        ip_tx_start_IP                  <= '0';
        ip_tx_IP.hdr.protocol           <= (others => '0');
        ip_tx_IP.hdr.data_length        <= (others => '0');
        ip_tx_IP.hdr.dst_ip_addr        <= (others => '0');
        ip_tx_IP.data.data_out          <= (others => '0');
        ip_tx_IP.data.data_out_valid    <= '0';
        ip_tx_IP.data.data_out_last     <= '0';
    end case;
end process;

end Behavioral;