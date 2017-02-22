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
-- CKTP with a 800 Mhz clock in progressive stages. The indicated phase shift at
-- the comments of sel_skew_proc are not absolute and they may differ from design
-- to design. However, the mean value of the step size is always ~ 1.25 ns
-- 
-- Dependencies: "Configurable CKBC/CKTP Constraints" .xdc snippet must be added to 
-- the main .xdc file of the design. Can be found at the project repository.
-- 
-- Changelog:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity skew_gen is
    Port(
        clk_800         : in std_logic;
        CKTP_preSkew    : in std_logic;
        skew            : in std_logic_vector(4 downto 0);
        CKTP_skew       : out std_logic
    );
end skew_gen;

architecture RTL of skew_gen is
    
    signal cktp_01p25 : std_logic := '0';
    signal cktp_02p50 : std_logic := '0';
    signal cktp_03p75 : std_logic := '0';
    signal cktp_05p00 : std_logic := '0';
    signal cktp_06p25 : std_logic := '0';
    signal cktp_07p50 : std_logic := '0';
    signal cktp_08p75 : std_logic := '0';
    signal cktp_10p00 : std_logic := '0';
    signal cktp_11p25 : std_logic := '0';
    signal cktp_12p50 : std_logic := '0';
    signal cktp_13p75 : std_logic := '0';
    signal cktp_15p00 : std_logic := '0';
    signal cktp_16p25 : std_logic := '0';
    signal cktp_17p50 : std_logic := '0';
    signal cktp_18p75 : std_logic := '0';
    signal cktp_20p00 : std_logic := '0';
    signal cktp_21p25 : std_logic := '0';
    
    signal CKTP_internal : std_logic := '0';

begin

-- select CKTP skewing
sel_skew_proc: process(skew, CKTP_preSkew, cktp_01p25, cktp_02p50, cktp_03p75, cktp_05p00, 
               cktp_06p25, cktp_07p50, cktp_08p75, cktp_10p00, cktp_11p25, cktp_12p50, 
               cktp_13p75, cktp_15p00, cktp_16p25, cktp_17p50, cktp_18p75, cktp_20p00, cktp_21p25)
begin
    case skew is
    when "00001" => CKTP_internal <= CKTP_preSkew;  -- 1.25  ns (1)   (one extra reg at the end)
    when "00010" => CKTP_internal <= cktp_01p25;    -- 2.50  ns (2)
    when "00011" => CKTP_internal <= cktp_02p50;    -- 3.75  ns (3)
    when "00100" => CKTP_internal <= cktp_03p75;    -- 5.00  ns (4)
    when "00101" => CKTP_internal <= cktp_05p00;    -- 6.25  ns (5)
    when "00110" => CKTP_internal <= cktp_06p25;    -- 7.50  ns (6)
    when "00111" => CKTP_internal <= cktp_07p50;    -- 8.75  ns (7)
    when "01000" => CKTP_internal <= cktp_08p75;    -- 10.00 ns (8)
    when "01001" => CKTP_internal <= cktp_10p00;    -- 11.25 ns (9)
    when "01010" => CKTP_internal <= cktp_11p25;    -- 12.50 ns (10)
    when "01011" => CKTP_internal <= cktp_12p50;    -- 13.75 ns (11)
    when "01100" => CKTP_internal <= cktp_13p75;    -- 15.00 ns (12)
    when "01101" => CKTP_internal <= cktp_15p00;    -- 16.25 ns (13)
    when "01110" => CKTP_internal <= cktp_16p25;    -- 17.50 ns (14)
    when "01111" => CKTP_internal <= cktp_17p50;    -- 18.75 ns (15)
    when "10000" => CKTP_internal <= cktp_18p75;    -- 20.00 ns (16)
    when "10001" => CKTP_internal <= cktp_20p00;    -- 21.25 ns (17)
    when "10010" => CKTP_internal <= cktp_21p25;    -- 22.50 ns (18)
    when others  => CKTP_internal <= CKTP_preSkew;  -- 1.25 ns
    end case;
end process;

-- delay/skewing line
reg_cktp_proc: process(clk_800)
begin
    if(rising_edge(clk_800))then
        cktp_01p25 <= CKTP_preSkew;
        cktp_02p50 <= cktp_01p25;
        cktp_03p75 <= cktp_02p50;
        cktp_05p00 <= cktp_03p75;
        cktp_06p25 <= cktp_05p00;
        cktp_07p50 <= cktp_06p25;
        cktp_08p75 <= cktp_07p50;
        cktp_10p00 <= cktp_08p75;
        cktp_11p25 <= cktp_10p00;
        cktp_12p50 <= cktp_11p25;
        cktp_13p75 <= cktp_12p50;
        cktp_15p00 <= cktp_13p75;
        cktp_16p25 <= cktp_15p00;
        cktp_17p50 <= cktp_16p25;
        cktp_18p75 <= cktp_17p50;
        cktp_20p00 <= cktp_18p75;
        cktp_21p25 <= cktp_20p00;
    end if;
end process;

-- CKTP is registered one final time to ease timing closure
regCKTP: process(clk_800)
begin
    if(rising_edge(clk_800))then
        CKTP_skew <= CKTP_internal;
    end if;
end process;

end RTL;
