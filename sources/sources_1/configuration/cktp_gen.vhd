----------------------------------------------------------------------------------------
-- Company:  University of Washington
-- Engineer: Lev Kurilenko
-- 
-- Copyright Notice/Copying Permission:
--    Copyright 2017 Lev Kurilenko
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
-- Create Date: 25.10.2016 15:47:35
-- Design Name: 
-- Module Name: cktp_gen - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: CKTP Generator
-- 
-- Dependencies: 
-- 
-- Changelog: 
-- 20.02.2017 Added dynamic CKBC input frequency and reset circuitry. Changed the input
-- clock frequency to 160 Mhz. (Christos Bakalis)
-- 27.02.2017 Added cktp_primary signal from flow_fsm. (Christos Bakalis)
-- 09.03.2017 Changed input bus widths and introduced integer range for logic and routing
-- optimization. (Christos Bakalis)
-- 14.03.2017 Added a cktp_start delay process. (Christos Bakalis)
--
----------------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity cktp_gen is
    port(
        clk_160         : in  std_logic;
        cktp_start      : in  std_logic;
        cktp_primary    : in  std_logic;
        vmm_ckbc        : in  std_logic; -- CKBC clock currently dynamic
        ckbc_mode       : in  std_logic;
        ckbc_freq       : in  std_logic_vector(5 downto 0);
        skew            : in  std_logic_vector(4 downto 0);
        pulse_width     : in  std_logic_vector(11 downto 0);
        period          : in  std_logic_vector(21 downto 0);
        CKTP            : out std_logic
    );
end cktp_gen;

architecture Behavioral of cktp_gen is

    --is_state            <= "0101";

    signal cktp_state                   : std_logic_vector(3 downto 0)  := (others => '0');
    signal cktp_cnt                     : integer range -2 to 2_100_000:= 0;
    signal vmm_cktp                     : std_logic := '0';
    signal cktp_start_i                 : std_logic := '0';            -- Internal connection to 2-Flip-Flop Synchronizer
    signal cktp_start_sync              : std_logic := '0';            -- Synchronized output from Synchronizer
    signal cktp_start_final             : std_logic := '0';
    signal cktp_primary_i               : std_logic := '0';
    signal cktp_primary_sync            : std_logic := '0';
    signal cktp_start_aligned           : std_logic := '0';            -- CKTP_start signal aligned to CKBC clock
    signal align_cnt                    : unsigned(7 downto 0) := (others => '0');         -- Used for aligning with the CKBC
    signal align_cnt_thresh             : unsigned(7 downto 0) := (others => '0');
    signal start_align_cnt              : std_logic := '0';     --
    signal cnt_delay                    : unsigned(3 downto 0) := (others => '0');
    signal ckbc_mode_i                  : std_logic := '0';
    signal ckbc_mode_sync               : std_logic := '0';
    
    attribute ASYNC_REG : string;
    
    attribute ASYNC_REG of cktp_start_i         : signal is "TRUE";
    attribute ASYNC_REG of cktp_start_sync      : signal is "TRUE";
    attribute ASYNC_REG of cktp_primary_i       : signal is "TRUE";
    attribute ASYNC_REG of cktp_primary_sync    : signal is "TRUE";
    attribute ASYNC_REG of ckbc_mode_i          : signal is "TRUE";
    attribute ASYNC_REG of ckbc_mode_sync       : signal is "TRUE";
    
begin

--period <= x"43200"; -- Hardcode 320,000 cycles at 320 MHz to give a period of 1ms

    CKTP <= vmm_cktp;
    
--testPulse_proc: process(clk_10_phase45) -- 10MHz/#states.
--    begin
--        if rising_edge(clk_10_phase45) then            
--            if state = DAQ and trig_mode_int = '0' then
--                case cktp_state is
--                    when 0 to 9979 =>
--                        cktp_state <= cktp_state + 1;
--                        vmm_cktp      <= '0';
--                    when 9980 to 10000 =>
--                        cktp_state <= cktp_state + 1;
--                        vmm_cktp   <= '1';
--                    when others =>
--                        cktp_state <= 0;
--                end case;
--            else
--                vmm_cktp      <= '0';
--            end if;
--        end if;
--end process;

synchronizer_proc: process(vmm_ckbc, cktp_start_final)
    begin
        if(cktp_start_final = '0')then
            start_align_cnt <= '0';        
        elsif rising_edge(vmm_ckbc) then
            start_align_cnt <= '1';
            
            --if (cktp_start_sync = '1') then
            --    cktp_start_aligned <= '1';
            --    --if (unsigned(skew) = "00000") then    -- Set CKTP signal as soon as rising edge of CKBC arrives if skew = 0
            --    --    vmm_cktp <= '1';
            --    --end if;
            --else
            --    cktp_start_aligned <= '0';
            --end if;
        end if;
end process;

sync160_proc: process(clk_160)
begin
    if(rising_edge(clk_160))then
        cktp_start_i        <= cktp_start;
        cktp_start_sync     <= cktp_start_i;
        
        cktp_primary_i      <= cktp_primary;
        cktp_primary_sync   <= cktp_primary_i;

        ckbc_mode_i         <= ckbc_mode;
        ckbc_mode_sync      <= ckbc_mode_i;
    end if;
end process;

-- delay assertion of cktp start
cktpEnableDelayer: process(clk_160)
begin
    if(rising_edge(clk_160))then
        if(cktp_start_sync = '1')then
            if(cnt_delay < "1110")then
                cnt_delay           <= cnt_delay + 1;
                cktp_start_final    <= '0';
            else
                cktp_start_final    <= '1';
            end if;
        else
            cnt_delay           <= (others => '0');
            cktp_start_final    <= '0';
        end if;
    end if;
end process;

testPulse_proc: process(clk_160) -- 160 MHz
    begin
        if rising_edge(clk_160) then
            if(cktp_start_final = '0' and cktp_primary_sync = '0')then
                cktp_cnt            <= 0;
                vmm_cktp            <= '0';
                cktp_start_aligned  <= '0';
                align_cnt           <= (others => '0');
                cktp_state          <= (others => '0');
            elsif(cktp_primary_sync = '1')then  -- from flow_fsm. keep cktp high for readout initialization
                vmm_cktp            <= '1';
            else
                if start_align_cnt = '1' or ckbc_mode_sync = '1' then -- Start alignment counter on rising edge of CKBC    
                    if align_cnt < align_cnt_thresh then
                        align_cnt <= align_cnt + 1;
                    else
                        align_cnt <= (others => '0');
                    end if;
                
                    if ckbc_mode_sync = '1' then            -- Just send periodic CKTPs if @ ckbc mode
                        cktp_start_aligned <= '1';
                    elsif cktp_start_final = '0' then       -- Align CKTP generation to rising edge of CKBC if CKTPs are enabled @ top
                        cktp_start_aligned <= '0';
                    elsif (align_cnt = align_cnt_thresh) then
                        cktp_start_aligned <= '1';
                        if unsigned(skew) = "00000" then    -- Set CKTP signal as soon as rising edge of CKBC arrives if skew = 0
                            vmm_cktp <= '1';
                        end if;
                    end if;
                
                end if;
                
                if cktp_start_aligned = '1' then
                    if (cktp_cnt < (to_integer(unsigned(skew)) - 1 ) and (cktp_cnt /= to_integer(unsigned(skew)))) then
                            cktp_state  <= "0000";
                            vmm_cktp    <= '0';
                            cktp_cnt    <= cktp_cnt + 1;
                    elsif ( (cktp_cnt >= to_integer((unsigned(skew))) - 1) and (cktp_cnt <= (to_integer(unsigned(skew)) + to_integer(unsigned(pulse_width)) - 2) ) ) then 
                            cktp_state  <= "0001";
                            vmm_cktp    <= '1';
                            cktp_cnt    <= cktp_cnt + 1;
                    -- Uncomment if period needs to be hardcoded
                    --elsif ( (cktp_cnt > ( unsigned(skew) + unsigned(pulse_width) - 2) ) and (cktp_cnt <= 320000 - 2) ) then
                    elsif ( (cktp_cnt > ( to_integer(unsigned(skew)) + to_integer(unsigned(pulse_width)) - 2) ) and (cktp_cnt <= to_integer(unsigned(period)) - 2) ) then
                            cktp_state  <= "0010";
                            vmm_cktp    <= '0';
                            cktp_cnt    <= cktp_cnt + 1;
                    else
                            cktp_state  <= "0011";
                            cktp_cnt    <= 0;
                    end if;
                else
                    cktp_state      <= "1111";
                    cktp_cnt        <= 0;
                end if;
            end if;
        end if;
end process;

ckbc_freq_proc: process(ckbc_freq)
begin
    case ckbc_freq is
    when "001010" => -- 10 Mhz
        align_cnt_thresh <= "00001111"; -- (16 - 1) 
    when "010100" => -- 20 Mhz
        align_cnt_thresh <= "00000111"; -- (8 - 1)
    when "101000" => -- 40 Mhz
        align_cnt_thresh <= "00000011"; -- (4 - 1)
    when others => 
        align_cnt_thresh <= "11111111"; 
    end case;
end process;

end Behavioral;