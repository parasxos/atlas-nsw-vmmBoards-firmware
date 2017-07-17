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
-- Create Date: 26.03.2017 18:22:01
-- Design Name: 
-- Module Name: cktp_counter - RTL
-- Project Name:
-- Target Devices: 
-- Tool Versions: 
-- Description: State machine that counts CKTP pulses sent and stops the CKTP
-- generation depending on a maximum number of pulses that must be sent.
-- 
-- Dependencies:
-- 
-- Changelog: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity cktp_counter is
Port(
    clk_160         : in  std_logic;
    cktp_start      : in  std_logic;
    cktp_pulse      : in  std_logic;
    cktp_max        : in  std_logic_vector(15 downto 0);
    cktp_inhibit    : out std_logic
    );
end cktp_counter;

architecture RTL of cktp_counter is

    -- state machine signals    
    type cktp_cnt_state_type   is (ST_IDLE, ST_WAIT_FOR_LOW, ST_CNT_CHECK);
    signal cktp_cnt_state       : cktp_cnt_state_type := ST_IDLE;
    signal fsm_enable           : std_logic := '0';
    signal fsm_enable_i         : std_logic := '0';
    signal fsm_enable_s         : std_logic := '0';
    signal cktp_inhibit_fsm     : std_logic := '0';
    signal inhibit_async_i      : std_logic := '0';
    signal inhibit_async_s      : std_logic := '0';
    signal inhibit_async        : std_logic := '0';
    signal cktp_cnt             : unsigned(15 downto 0) := (others => '0');

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of fsm_enable_i     : signal is "TRUE";
    attribute ASYNC_REG of fsm_enable_s     : signal is "TRUE";
    attribute ASYNC_REG of inhibit_async_i  : signal is "TRUE";
    attribute ASYNC_REG of inhibit_async_s  : signal is "TRUE";

begin

-- transmit CKTPs indefinitely if cktp_max is FFFF, inhibit CKTPs if 0000
FSM_enble_proc: process(cktp_max, cktp_start)
begin
    if(cktp_start = '1')then
        case cktp_max is
        when x"FFFF" => fsm_enable  <= '0'; inhibit_async <= '0';
        when x"0000" => fsm_enable  <= '0'; inhibit_async <= '1';
        when others  => fsm_enable  <= '1'; inhibit_async <= '0';
        end case;
    else
        fsm_enable      <= '0';
        inhibit_async   <= '1';
    end if;
end process;

-- sync the enable signal
SynProc: process(clk_160)
begin
    if(rising_edge(clk_160))then
        fsm_enable_i    <= fsm_enable;
        fsm_enable_s    <= fsm_enable_i;
        inhibit_async_i <= inhibit_async;
        inhibit_async_s <= inhibit_async_i; 
    end if;
end process;

-- state machine that counts CKTP pulses and asserts the inhibit flag if needed
FSM_CKTP_cnt_proc: process(clk_160)
begin
    if(rising_edge(clk_160))then
        if(fsm_enable_s = '1')then
            case cktp_cnt_state is

            -- wait for pulse
            when ST_IDLE =>
                if(cktp_pulse = '1')then
                    cktp_cnt_state  <= ST_WAIT_FOR_LOW;
                else
                    cktp_cnt_state  <= ST_IDLE;
                end if;

            -- wait for pulse to go low, increment counter and check
            when ST_WAIT_FOR_LOW =>
                if(cktp_pulse = '0')then
                    cktp_cnt_state  <= ST_CNT_CHECK;
                    cktp_cnt        <= cktp_cnt + 1;
                else
                    cktp_cnt_state  <= ST_WAIT_FOR_LOW;
                end if;

            -- check the counter and assert flag+stay here if limit is reached, and
            -- wait to be rest by configuration
            when ST_CNT_CHECK =>
                if(cktp_cnt <= unsigned(cktp_max))then
                    cktp_cnt_state      <= ST_IDLE;
                else
                    cktp_cnt_state      <= ST_CNT_CHECK;
                    cktp_inhibit_fsm    <= '1';
                end if;

            when others =>
                cktp_cnt_state      <= ST_IDLE;
                cktp_cnt            <= (others => '0');
                cktp_inhibit_fsm    <= '0';
            end case;
        else
            cktp_cnt_state      <= ST_IDLE;
            cktp_cnt            <= (others => '0');
            cktp_inhibit_fsm    <= '0';
        end if;
    end if;
end process;

    cktp_inhibit <= cktp_inhibit_fsm or inhibit_async_s;

end RTL;
