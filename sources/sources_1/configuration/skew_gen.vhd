----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
--
-- Copyright Notice/Copying Permission:
--    Copyright 2017 Christos Bakalis
--
--    This file is part of NTUA-BNL_VMM_firmware.
--
--    NTUA-BNL_VMM_firmware is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    NTUA-BNL_VMM_firmware is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with NTUA-BNL_VMM_firmware.  If not, see <http://www.gnu.org/licenses/>.
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
    --signal cktp_24 : std_logic := '0';
    --signal cktp_26 : std_logic := '0';
    --signal cktp_28 : std_logic := '0';
    --signal cktp_30 : std_logic := '0';
    --signal cktp_32 : std_logic := '0';
    --signal cktp_34 : std_logic := '0';
    --signal cktp_36 : std_logic := '0';
    
    signal CKTP_internal : std_logic := '0';

begin

-- select CKTP skewing
sel_skew_proc: process(skew, CKTP_preSkew, cktp_02, cktp_04, cktp_06, cktp_08, 
               cktp_10, cktp_12, cktp_14, cktp_16, cktp_18, cktp_20, cktp_22)
begin
    case skew is
    when "00001" => CKTP_internal <= CKTP_preSkew;  -- 02  ns (1)   (one extra reg at the end)
    when "00010" => CKTP_internal <= cktp_02;       -- 04  ns (2)
    when "00011" => CKTP_internal <= cktp_04;       -- 06  ns (3)
    when "00100" => CKTP_internal <= cktp_06;       -- 08  ns (4)
    when "00101" => CKTP_internal <= cktp_08;       -- 10  ns (5)
    when "00110" => CKTP_internal <= cktp_10;       -- 12  ns (6)
    when "00111" => CKTP_internal <= cktp_12;       -- 14  ns (7)
    when "01000" => CKTP_internal <= cktp_14;       -- 16 ns  (8)
    when "01001" => CKTP_internal <= cktp_16;       -- 18 ns  (9)
    when "01010" => CKTP_internal <= cktp_18;       -- 20 ns (10)
    when "01011" => CKTP_internal <= cktp_20;       -- 22 ns (11)
    when "01100" => CKTP_internal <= cktp_22;       -- 24 ns (12)
    --when "01101" => CKTP_internal <= cktp_24;       -- 26 ns (13)
    --when "01110" => CKTP_internal <= cktp_26;       -- 28 ns (14)
    --when "01111" => CKTP_internal <= cktp_28;       -- 30 ns (15)
    --when "10000" => CKTP_internal <= cktp_30;       -- 32 ns (16)
    --when "10001" => CKTP_internal <= cktp_32;       -- 34 ns (17)
    --when "10010" => CKTP_internal <= cktp_34;       -- 36 ns (18)
    --when "10011" => CKTP_internal <= cktp_36;       -- 38 ns (19)
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
        --cktp_24 <= cktp_22;
        --cktp_26 <= cktp_24;
        --cktp_28 <= cktp_26;
        --cktp_30 <= cktp_28;
        --cktp_32 <= cktp_30;
        --cktp_34 <= cktp_32;
        --cktp_36 <= cktp_34;
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
