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
-- Create Date: 25.04.2017 17:45:32
-- Design Name: VMM Driver
-- Module Name: vmm_driver - RTL
-- Project Name: NTUA-BNL VMM3 Readout Firmware
-- Target Devices: Xilinx xc7a200t-2fbg484
-- Tool Versions: Vivado 2016.4
-- Description: This module drives the data from the vmm_readout component
-- to the FIFO2UDP component.
-- 
-- Dependencies: packet_formation.vhd 
-- 
-- Changelog: 
-- 06.06.2017 Simplified the module as the continuous readout mode now uses a buffer
-- as well. (Christos Bakalis)
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity vmm_driver is
    port(
        ------------------------------------
        ------ General/PF Interface --------
        clk             : in  std_logic;
        drv_enable      : in  std_logic;
        drv_done        : out std_logic;
        pack_len_drv    : out std_logic_vector(11 downto 0);
        ------------------------------------
        ----- VMM_RO/FIFO2UDP Interface ----
        wr_en_fifo2udp  : out std_logic;
        rd_en_buff      : out std_logic;
        vmmWordReady    : in  std_logic
    );
end vmm_driver;

architecture RTL of vmm_driver is

    signal wait_cnt         : integer range 0 to 15 := 0;
    signal packLen_i        : unsigned(11 downto 0) := (others => '0');
    constant timeout        : integer := 15;

    type stateType_l0 is (ST_IDLE, ST_WAIT, ST_CHECK_FIFO, ST_RD_LOW, ST_WR_LOW, ST_DONE);
    signal state_l0 : stateType_l0 := ST_IDLE;

begin

l0_FSM_drv: process(clk)
begin
    if(rising_edge(clk))then
        if(drv_enable = '0')then
            drv_done        <= '0';
            wait_cnt        <=  0;
            rd_en_buff      <= '0';
            wr_en_fifo2udp  <= '0';
            packLen_i       <= (others => '0');
            state_l0        <= ST_IDLE;
        else
            case state_l0 is

            -- reset the counter and begin the process
            when ST_IDLE =>
                packLen_i   <= (others => '0');
                state_l0    <= ST_WAIT;
            
            -- stay here for "timeout" cycles for data bus stabilization   
            when ST_WAIT =>
                if(wait_cnt < timeout)then
                    wait_cnt    <= wait_cnt + 1;
                    state_l0    <= ST_WAIT;
                else
                    wait_cnt    <= 0;
                    state_l0    <= ST_CHECK_FIFO;
                end if;
               
            -- read the vmm buffer if there is still data
            when ST_CHECK_FIFO =>
                if(vmmWordReady = '1')then
                    rd_en_buff      <= '1';
                    state_l0        <= ST_RD_LOW;    
                else
                    rd_en_buff      <= '0';
                    state_l0        <= ST_DONE;           
                end if;

            -- stay here for "timeout" cycles for data bus stabilization
            when ST_RD_LOW =>
                rd_en_buff <= '0';

                if(wait_cnt < timeout)then
                    wait_cnt     <= wait_cnt + 1;
                    wr_en_fifo2udp  <= '0';
                    state_l0        <= ST_RD_LOW;
                else
                    wait_cnt        <= 0;
                    wr_en_fifo2udp  <= '1';
                    state_l0        <= ST_WR_LOW;
                end if;

            -- increment the packLen counter
            when ST_WR_LOW =>
                wr_en_fifo2udp <= '0';
                packLen_i      <= packLen_i + 1;
                state_l0       <= ST_WAIT;

            -- stay here until reset by pf
            when ST_DONE =>
                drv_done <= '1';

            when others => 
                drv_done        <= '0';
                wait_cnt        <=  0;
                rd_en_buff      <= '0';
                wr_en_fifo2udp  <= '0';
                packLen_i       <= (others => '0');
                state_l0        <= ST_IDLE;
            end case;
        end if;
    end if;
end process;

    pack_len_drv <= std_logic_vector(packLen_i);

end RTL;