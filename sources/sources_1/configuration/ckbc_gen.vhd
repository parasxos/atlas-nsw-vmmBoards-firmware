----------------------------------------------------------------------------------
-- Company: Westfälische Hochschule
-- Engineer: Pia Piekarek (piapiekarek@googlemail.com)
--
-- Copyright Notice/Copying Permission:
--    Copyright 2017 Pia Piekarek
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
-- Create Date: 13.01.2017 11:56:04
-- Design Name: 
-- Module Name: ckbc_gen - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: CKBC Generator
-- 
-- Dependencies: 
-- 
-- Changelog:
-- 20.02.2017 Changed the FSM to create a multicycle path. Changed the input clock
-- frequency to 160 Mhz. (Christos Bakalis)
-- 12.03.2017 Removed FSM. (Christos Bakalis)
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ckbc_gen is
    port(  
        clk_160       : in std_logic;
        duty_cycle    : in std_logic_vector(7 downto 0);
        freq          : in std_logic_vector(5 downto 0);
        ready         : in std_logic;
        ckbc_out      : out std_logic
    );
end ckbc_gen;


architecture Behavioral of ckbc_gen is
    
    signal t_high        : unsigned(16 downto 0) := to_unsigned(0,17);
    signal t_low         : unsigned(16 downto 0) := to_unsigned(0,17);
    
    signal count         : unsigned(7 downto 0) := to_unsigned(0,8);
    signal p_high        : unsigned(16 downto 0) := to_unsigned(0,17);        --number of clock cycles while high
    signal p_low         : unsigned(16 downto 0) := to_unsigned(0,17);        --number of clock cycles while low
    
    signal ready_i       : std_logic := '0';
    signal ready_sync    : std_logic := '0';
    
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of ready_i         : signal is "TRUE";
    attribute ASYNC_REG of ready_sync      : signal is "TRUE";

begin

-- 2 FF synchronizer
sync_ready: process(clk_160)
begin
    if(rising_edge(clk_160))then
        ready_i     <= ready;
        ready_sync  <= ready_i;
    end if;
end process;

clocking_proc: process(clk_160)
  begin
    if (rising_edge(clk_160)) then
        if(ready_sync = '0') then
            ckbc_out <= '0';
            count    <= to_unsigned(0,8);
        else
            if(count < (p_high+p_low)) then
                if(count < p_high)then
                    ckbc_out <= '1';
                elsif (count < (p_high+p_low)) then
                    ckbc_out <= '0';
                end if;
                count <= count + 1;
            elsif (p_high >= 1 and p_low >= 1) then
                count <= to_unsigned(1,8);
                ckbc_out <= '1';
            end if;
        end if;
    end if;
end process;

t_high_proc: process(freq)
begin
    case freq is
    when "101000" => -- 40
        t_high <= to_unsigned(6250,17);
        t_low  <= to_unsigned(18750,17);
    when "010100" => -- 20
        t_high <= to_unsigned(12500,17);
        t_low  <= to_unsigned(37500,17);
    when "001010" => -- 10
        t_high <= to_unsigned(18750,17);
        t_low  <= to_unsigned(81250,17);
    when others =>
        t_high <= to_unsigned(6250,17);
        t_low  <= to_unsigned(18750,17);
    end case;
end process;
      
      p_high        <= (t_high / to_unsigned(6250, 16)); -- input clock period: 160 Mhz = 6.250 ns
      p_low         <= (t_low  / to_unsigned(6250, 16));

end Behavioral;
