----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Create Date: 14.10.2016
-- Design Name: 
-- Module Name: udp_mux.vhd - Behavioral
-- Project Name: MMFE8 
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
--
-- Changelog:
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;

entity udp_mux is
    Port(
        --------------------------------------------------
        --------- general interface ----------------------
        sel_udp_mux         : in std_logic;
        destinationIP       : in std_logic_vector(31 downto 0);
        --------------------------------------------------
        --------- readout interface ----------------------
        data_length_ro      : in std_logic_vector(15 downto 0);
        data_out_last_ro    : in std_logic;
        data_out_valid_ro   : in std_logic;
        data_out_ro         : in std_logic_vector(7 downto 0);
        udp_tx_start_ro     : in std_logic;
        --------------------------------------------------
        --------- fifo2udp interface ---------------------
        data_length_fifo    : in std_logic_vector(15 downto 0);
        data_out_last_fifo  : in std_logic;
        data_out_valid_fifo : in std_logic;
        data_out_fifo       : in std_logic_vector(7 downto 0);
        udp_tx_start_fifo   : in std_logic;
        --------------------------------------------------
        --------- udp interface --------------------------
        udp_txi             : out udp_tx_type;
        udp_tx_start_mux    : out std_logic
        );
end udp_mux;

architecture Behavioral of udp_mux is

begin

udpMuxProc: process(sel_udp_mux)
begin
    case sel_udp_mux is
    
    when '0' => -- select readout data
        udp_txi.data.data_out_last  <= data_out_last_ro;
        udp_txi.data.data_out_valid <= data_out_valid_ro;
        udp_txi.data.data_out       <= data_out_ro;
        udp_txi.hdr.data_length     <= data_length_ro;
        udp_tx_start_mux            <= udp_tx_start_ro;
        
    when '1' => -- select fifo data
        udp_txi.data.data_out_last  <= data_out_last_fifo;
        udp_txi.data.data_out_valid <= data_out_valid_fifo;
        udp_txi.data.data_out       <= data_out_fifo;
        udp_txi.hdr.data_length     <= data_length_fifo;
        udp_tx_start_mux            <= udp_tx_start_fifo;
    when others => null;
    end case;
end process;

    -- static UDP signals

    udp_txi.hdr.dst_ip_addr  <= destinationIP;         -- set a generic ip adrress (192.168.0.255)
    udp_txi.hdr.src_port     <= x"19CB";                -- set src and dst ports
    udp_txi.hdr.dst_port     <= x"1778";                     -- x"6af0";                            
    udp_txi.hdr.checksum     <= x"0000";

end Behavioral;