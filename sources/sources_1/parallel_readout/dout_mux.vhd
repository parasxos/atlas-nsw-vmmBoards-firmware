----------------------------------------------------------------------------------
-- Company:  NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Create Date: 09/30/2016 10:34:15 AM
-- Design Name: 
-- Module Name: vmm_arbiter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
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
use IEEE.NUMERIC_STD.ALL;

entity dout_mux is
  Port (
    header_0_mux        : in std_logic_vector(31 downto 0);
    header_1_mux        : in std_logic_vector(31 downto 0);
    vmmWord_0_mux       : in std_logic_vector(31 downto 0);
    vmmWord_1_mux       : in std_logic_vector(31 downto 0);
    vmmWord_2_mux       : in std_logic_vector(31 downto 0);
    vmmWord_3_mux       : in std_logic_vector(31 downto 0);
    vmmWord_4_mux       : in std_logic_vector(31 downto 0);
    vmmWord_5_mux       : in std_logic_vector(31 downto 0);
    vmmWord_6_mux       : in std_logic_vector(31 downto 0);
    vmmWord_7_mux       : in std_logic_vector(31 downto 0);
    trailer_mux         : in std_logic_vector(31 downto 0);
    vmmId_cnt_mux       : in std_logic_vector(2 downto 0);
    master_sel_mux      : in std_logic_vector(1 downto 0);
    data_out_mux        : out std_logic_vector(31 downto 0)
    );
end dout_mux;

architecture Behavioral of dout_mux is

    signal vmmWord_i : std_logic_vector(31 downto 0);

begin

    process(master_sel_mux, header_0_mux, header_1_mux, vmmWord_i, trailer_mux)
    begin
        case master_sel_mux is 
        when "00" => data_out_mux <= vmmWord_i;    -- write words
        when "01" => data_out_mux <= header_0_mux; -- header 0
        when "10" => data_out_mux <= header_1_mux; -- header 1
        when "11" => data_out_mux <= trailer_mux;  -- trailer
        when others => null;
        end case;
    end process;

    process(vmmId_cnt_mux, vmmWord_i, vmmWord_0_mux, vmmWord_1_mux, vmmWord_2_mux, vmmWord_3_mux, vmmWord_4_mux, vmmWord_5_mux,
            vmmWord_6_mux, vmmWord_7_mux)
    begin
        case vmmId_cnt_mux is
        when "000" => vmmWord_i <= vmmWord_0_mux;
        when "001" => vmmWord_i <= vmmWord_1_mux;
        when "010" => vmmWord_i <= vmmWord_2_mux;
        when "011" => vmmWord_i <= vmmWord_3_mux; 
        when "100" => vmmWord_i <= vmmWord_4_mux;
        when "101" => vmmWord_i <= vmmWord_5_mux;
        when "110" => vmmWord_i <= vmmWord_6_mux;
        when "111" => vmmWord_i <= vmmWord_7_mux;
        when others => null;
        end case;
    end process;
   
end Behavioral;