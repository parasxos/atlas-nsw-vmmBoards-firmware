----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Create Date: 20.02.2017 18:41:18
-- Design Name: 
-- Module Name: skew_gen - RTL
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Skewing module. Receives a CKTP aligned with the CKBC, and shifts
-- CKTP with a 500 Mhz clock in progressive stages (2 ns step size). Measurements
-- show that the first 2-3 delay stages may give unstable results. The rest stages
-- are all close to the theoretical values.
-- 
-- Dependencies: "Configurable CKBC/CKTP Constraints" .xdc snippet must be added to 
-- the main .xdc file of the design. Can be found at the project repository.
-- 
-- Changelog: 
-- 23.02.2017 Slowed down the skewing process to 500 Mhz. (Christos Bakalis)
-- 04.07.2017 Added delay levels to introduce skewing step-size of 1ns.
-- (Christos Bakalis)
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity skew_gen is
    Port(
        clk_500         : in std_logic;
        CKTP_preSkew    : in std_logic;
        skew            : in std_logic_vector(4 downto 0);
        CKTP_skewed     : out std_logic
    );
end skew_gen;

architecture RTL of skew_gen is
    
    signal cktp_02 : std_logic := '0';
    signal cktp_04 : std_logic := '0';
    signal cktp_06 : std_logic := '0';
    signal cktp_08 : std_logic := '0';
    signal cktp_10 : std_logic := '0';
    signal cktp_12 : std_logic := '0';
    signal cktp_14 : std_logic := '0';
    signal cktp_16 : std_logic := '0';
    signal cktp_18 : std_logic := '0';
    signal cktp_20 : std_logic := '0';
    signal cktp_22 : std_logic := '0';
    signal cktp_24 : std_logic := '0';
    signal cktp_26 : std_logic := '0';
    signal cktp_28 : std_logic := '0';
    signal cktp_30 : std_logic := '0';
    signal cktp_32 : std_logic := '0';
    signal cktp_34 : std_logic := '0';
    signal cktp_36 : std_logic := '0';
    signal cktp_38 : std_logic := '0';
    signal cktp_40 : std_logic := '0';
    signal cktp_42 : std_logic := '0';
    signal cktp_44 : std_logic := '0';
    signal cktp_46 : std_logic := '0';

    signal skew_i  : std_logic_vector(4 downto 0) := (others => '0');
    
    signal CKTP_internal : std_logic := '0';

begin

-- skew conversion
conv_skew_proc: process(skew)
begin
    case skew is
    when "00001" => skew_i <= "01101"; --  1 ns
    when "00010" => skew_i <= "00001"; --  2 ns
    when "00011" => skew_i <= "01110"; --  3 ns
    when "00100" => skew_i <= "00010"; --  4 ns
    when "00101" => skew_i <= "01111"; --  5 ns
    when "00110" => skew_i <= "00011"; --  6 ns
    when "00111" => skew_i <= "10000"; --  7 ns
    when "01000" => skew_i <= "00100"; --  8 ns
    when "01001" => skew_i <= "10001"; --  9 ns
    when "01010" => skew_i <= "00101"; -- 10 ns
    when "01011" => skew_i <= "10010"; -- 11 ns
    when "01100" => skew_i <= "00110"; -- 12 ns
    when "01101" => skew_i <= "10011"; -- 13 ns
    when "01110" => skew_i <= "00111"; -- 14 ns
    when "01111" => skew_i <= "10100"; -- 15 ns
    when "10000" => skew_i <= "01000"; -- 16 ns
    when "10001" => skew_i <= "10101"; -- 17 ns
    when "10010" => skew_i <= "01001"; -- 18 ns
    when "10011" => skew_i <= "10110"; -- 19 ns
    when "10100" => skew_i <= "01010"; -- 20 ns
    when "10101" => skew_i <= "10111"; -- 21 ns
    when "10110" => skew_i <= "01011"; -- 22 ns
    when "10111" => skew_i <= "11000"; -- 23 ns
    when "11000" => skew_i <= "01100"; -- 24 ns
    when others  => skew_i <= "00001"; --  2 ns
    end case;
end process;

-- select CKTP skewing
sel_skew_proc: process(skew_i, CKTP_preSkew, cktp_02, cktp_04, cktp_06, cktp_08, 
               cktp_10, cktp_12, cktp_14, cktp_16, cktp_18, cktp_20, cktp_22,
               cktp_24, cktp_26, cktp_28, cktp_30, cktp_32, cktp_34, cktp_36,
               cktp_38, cktp_40, cktp_42, cktp_44, cktp_46)
begin
    case skew_i is
    when "00001" => CKTP_internal <= CKTP_preSkew;  -- 02 ns (1)  (one extra reg at the end)
    when "00010" => CKTP_internal <= cktp_02;       -- 04 ns (2)
    when "00011" => CKTP_internal <= cktp_04;       -- 06 ns (3)
    when "00100" => CKTP_internal <= cktp_06;       -- 08 ns (4)
    when "00101" => CKTP_internal <= cktp_08;       -- 10 ns (5)
    when "00110" => CKTP_internal <= cktp_10;       -- 12 ns (6)
    when "00111" => CKTP_internal <= cktp_12;       -- 14 ns (7)
    when "01000" => CKTP_internal <= cktp_14;       -- 16 ns (8)
    when "01001" => CKTP_internal <= cktp_16;       -- 18 ns (9)
    when "01010" => CKTP_internal <= cktp_18;       -- 20 ns (10)
    when "01011" => CKTP_internal <= cktp_20;       -- 22 ns (11)
    when "01100" => CKTP_internal <= cktp_22;       -- 24 ns (12)
    when "01101" => CKTP_internal <= cktp_24;       -- 26 ns (13) 1 ns (rolled over)
    when "01110" => CKTP_internal <= cktp_26;       -- 28 ns (14) 3 ns
    when "01111" => CKTP_internal <= cktp_28;       -- 30 ns (15) 5 ns
    when "10000" => CKTP_internal <= cktp_30;       -- 32 ns (16) 7 ns
    when "10001" => CKTP_internal <= cktp_32;       -- 34 ns (17) 9 ns
    when "10010" => CKTP_internal <= cktp_34;       -- 36 ns (18) 11 ns
    when "10011" => CKTP_internal <= cktp_36;       -- 38 ns (19) 13 ns
    when "10100" => CKTP_internal <= cktp_38;       -- 40 ns (20) 15 ns
    when "10101" => CKTP_internal <= cktp_40;       -- 42 ns (21) 17 ns
    when "10110" => CKTP_internal <= cktp_42;       -- 44 ns (22) 19 ns
    when "10111" => CKTP_internal <= cktp_44;       -- 46 ns (23) 21 ns
    when "11000" => CKTP_internal <= cktp_46;       -- 48 ns (24) 23 ns
    when others  => CKTP_internal <= CKTP_preSkew;  -- 02 ns
    end case;
end process;

-- delay/skewing line
reg_cktp_proc: process(clk_500)
begin
    if(rising_edge(clk_500))then
        cktp_02 <= CKTP_preSkew;
        cktp_04 <= cktp_02;
        cktp_06 <= cktp_04;
        cktp_08 <= cktp_06;
        cktp_10 <= cktp_08;
        cktp_12 <= cktp_10;
        cktp_14 <= cktp_12;
        cktp_16 <= cktp_14;
        cktp_18 <= cktp_16;
        cktp_20 <= cktp_18;
        cktp_22 <= cktp_20;
        cktp_24 <= cktp_22;
        cktp_26 <= cktp_24;
        cktp_28 <= cktp_26;
        cktp_30 <= cktp_28;
        cktp_32 <= cktp_30;
        cktp_34 <= cktp_32;
        cktp_36 <= cktp_34;
        cktp_38 <= cktp_36;
        cktp_40 <= cktp_38;
        cktp_42 <= cktp_40;
        cktp_44 <= cktp_42;
        cktp_46 <= cktp_44;
    end if;
end process;

-- CKTP is registered one final time to optimize timing
regCKTP: process(clk_500)
begin
    if(rising_edge(clk_500))then
        CKTP_skewed <= CKTP_internal;
    end if;
end process;

end RTL;
