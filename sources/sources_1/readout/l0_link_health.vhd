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
-- Create Date: 19.06.2017 12:38:23
-- Design Name: Level-0 Link Health Monitor
-- Module Name: l0_link_health - RTL
-- Project Name: NTUA-BNL VMM3 Readout Firmware
-- Target Devices: Xilinx xc7a200t-2fbg484
-- Tool Versions: Vivado 2017.1
-- Description: Module that checks if there is proper aligmnent with the comma
-- characters on each VMM's link.
-- 
-- Dependencies: 
-- 
-- Changelog: 
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity l0_link_health is
    Generic(is_mmfe8 : std_logic);
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk                 : in  std_logic;
        vmm_conf            : in  std_logic;
        daqOn_inhibit       : out std_logic;
        ------------------------------------
        --- Deserializer Interface ---------
        commas_true         : in  std_logic_vector(8 downto 1);
        ------------------------------------
        ---- Packet Formation Interface ----
        EventDone_dummy     : out std_logic_vector(8 downto 1);
        linkHealth_bitmask  : out std_logic_vector(8 downto 1)
    );
end l0_link_health;

architecture RTL of l0_link_health is

    signal commas_true_i        : std_logic_vector(7 downto 0) := (others => '0');
    signal linkHealth_bitmask_i : std_logic_vector(7 downto 0) := (others => '0');
    signal vmm_id               : integer range 0 to 7 := 0;
    signal cnt                  : integer range 0 to 1023 := 0;
    constant timeout_conf       : integer := 1023;
    constant timeout_vmm        : integer := 512;

    type StateType is (ST_IDLE, ST_CHECK, ST_INCR_ID, ST_DONE);
    signal state : StateType := ST_IDLE;
    
    attribute FSM_ENCODING              : string;
    attribute FSM_ENCODING of state     : signal is "ONE_HOT";

begin

-- FSM that labels a VMM link as healthy or not
link_health_FSM: process(clk)
begin
    if(rising_edge(clk))then
        if(vmm_conf = '1')then
            daqOn_inhibit           <= '1';
            cnt                     <= 0;
            vmm_id                  <= 0;
            linkHealth_bitmask_i    <= (others => '0');
            state                   <= ST_IDLE;
        else
            case state is

            -- wait before checking the lines
            when ST_IDLE =>
                daqOn_inhibit <= '1';

                if(cnt < timeout_conf)then
                    cnt     <= cnt + 1;
                    state   <= ST_IDLE;
                else
                    cnt     <= 0;
                    state   <= ST_CHECK;
                end if;

            -- check the VMM lines
            when ST_CHECK =>
                if(commas_true_i(vmm_id) = '0')then -- misalignment detected, bad link
                    cnt                             <= 0;
                    linkHealth_bitmask_i(vmm_id)    <= '0';
                    state                           <= ST_INCR_ID;
                elsif(cnt = timeout_vmm)then        -- link is healthy, proceed
                    cnt                             <= 0;
                    linkHealth_bitmask_i(vmm_id)    <= '1';
                    state                           <= ST_INCR_ID;
                else                                -- keep counting
                    cnt                             <= cnt + 1;
                    state                           <= ST_CHECK;
                end if;

            -- switch to the next VMM, or go to last state
            when ST_INCR_ID =>
                if(vmm_id = 7 and is_mmfe8 = '1')then -- cycled through all
                    state                   <= ST_DONE;
                elsif(vmm_id = 0 and is_mmfe8 = '0')then -- only one to check anyway
                    linkHealth_bitmask_i(1) <= '0';
                    linkHealth_bitmask_i(2) <= '0';
                    linkHealth_bitmask_i(3) <= '0';
                    linkHealth_bitmask_i(4) <= '0';
                    linkHealth_bitmask_i(5) <= '0';
                    linkHealth_bitmask_i(6) <= '0';
                    linkHealth_bitmask_i(7) <= '0';
                    state                   <= ST_DONE;
                else
                    vmm_id                  <= vmm_id + 1;
                    state                   <= ST_CHECK;
                end if;

            -- stay here until a new VMM configuration is sent, let flow_fsm read out the chips
            when ST_DONE =>
                daqOn_inhibit <= '0';

            when others =>
                daqOn_inhibit           <= '1';
                cnt                     <= 0;
                vmm_id                  <= 0;
                linkHealth_bitmask_i    <= (others => '0');
                state                   <= ST_IDLE;
            end case;
        end if;
    end if;
end process;

    commas_true_i(0)        <= commas_true(1);
    commas_true_i(1)        <= commas_true(2);
    commas_true_i(2)        <= commas_true(3);
    commas_true_i(3)        <= commas_true(4);
    commas_true_i(4)        <= commas_true(5);
    commas_true_i(5)        <= commas_true(6);
    commas_true_i(6)        <= commas_true(7);
    commas_true_i(7)        <= commas_true(8);

    linkHealth_bitmask(1)   <= linkHealth_bitmask_i(0);
    linkHealth_bitmask(2)   <= linkHealth_bitmask_i(1);
    linkHealth_bitmask(3)   <= linkHealth_bitmask_i(2);
    linkHealth_bitmask(4)   <= linkHealth_bitmask_i(3);
    linkHealth_bitmask(5)   <= linkHealth_bitmask_i(4);
    linkHealth_bitmask(6)   <= linkHealth_bitmask_i(5);
    linkHealth_bitmask(7)   <= linkHealth_bitmask_i(6);
    linkHealth_bitmask(8)   <= linkHealth_bitmask_i(7);

    EventDone_dummy(1)      <= not linkHealth_bitmask_i(0);
    EventDone_dummy(2)      <= not linkHealth_bitmask_i(1);
    EventDone_dummy(3)      <= not linkHealth_bitmask_i(2);
    EventDone_dummy(4)      <= not linkHealth_bitmask_i(3);
    EventDone_dummy(5)      <= not linkHealth_bitmask_i(4);
    EventDone_dummy(6)      <= not linkHealth_bitmask_i(5);
    EventDone_dummy(7)      <= not linkHealth_bitmask_i(6);
    EventDone_dummy(8)      <= not linkHealth_bitmask_i(7);

end RTL;