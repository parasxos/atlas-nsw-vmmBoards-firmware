----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Create Date: 14.10.2016
-- Design Name: 
-- Module Name: conf_xadc_mux.vhd - Behavioral
-- Project Name: MMFE8 
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
--
-- Changelog:
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity conf_xadc_mux is
    Port(
        --------------------------------------------------
        --------- general interface ----------------------
        sel_conf_xadc   : in std_logic;
        --------------------------------------------------
        ---------- xadc interface ------------------------
        data_xadc       : in std_logic_vector(31 downto 0);
        packet_len_xadc : in std_logic_vector(11 downto 0);
        wr_en_xadc      : in std_logic;
        end_packet_xadc : in std_logic;
        --------------------------------------------------
        ----------- config interface ---------------------
        data_conf       : in std_logic_vector(31 downto 0);
        packet_len_conf : in std_logic_vector(11 downto 0);
        wr_en_conf      : in std_logic;
        end_packet_conf : in std_logic;
        --------------------------------------------------
        ----------- FIFO2UDP interface -------------------
        data_mux        : out std_logic_vector(31 downto 0);
        packet_len_mux  : out std_logic_vector(11 downto 0);
        wr_en_mux       : out std_logic;
        end_packet_mux  : out std_logic
        );
end conf_xadc_mux;

architecture Behavioral of conf_xadc_mux is

begin

confXADCproc: process(sel_conf_xadc)
begin
    case sel_conf_xadc is
    when '0' => -- select XADC data
        data_mux        <= data_xadc;
        packet_len_mux  <= packet_len_xadc;
        wr_en_mux       <= wr_en_xadc;
        end_packet_mux  <= end_packet_xadc;

    when '1' => -- select config reply data
        data_mux        <= data_conf;
        packet_len_mux  <= packet_len_conf;
        wr_en_mux       <= wr_en_conf;
        end_packet_mux  <= end_packet_conf;
    when others => null;
    end case;
end process;

end Behavioral;