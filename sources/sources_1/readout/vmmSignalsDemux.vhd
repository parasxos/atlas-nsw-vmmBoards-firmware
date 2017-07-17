-- Company: NTU ATHENS - BNL
-- Engineer: Paris Moschovakos
--
-- Copyright Notice/Copying Permission:
--    Copyright 2017 Paris Moschovakos
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
-- Create Date: 21.07.2016
-- Design Name: 
-- Module Name: vmmSignalsDemux.vhd - Behavioral
-- Project Name: MMFE8 
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
--
-- Changelog:
-- 
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity vmmSignalsDemux is
    Port ( selVMM : in STD_LOGIC_VECTOR (2 downto 0);
           vmm_data0_vec : in STD_LOGIC_VECTOR (8 downto 1);
           vmm_data1_vec : in STD_LOGIC_VECTOR (8 downto 1);
           vmm_data0 : out STD_LOGIC;
           vmm_data1 : out STD_LOGIC;
           vmm_ckdt : in STD_LOGIC;
           vmm_cktk : in STD_LOGIC;
           vmm_ckdt_vec : out STD_LOGIC_VECTOR (8 downto 1);
           vmm_cktk_vec : out STD_LOGIC_VECTOR (8 downto 1)
           );
end vmmSignalsDemux;

architecture Behavioral of vmmSignalsDemux is

begin
    vmm_data0   <=  vmm_data0_vec(1) when (selVMM = b"000") else
                    vmm_data0_vec(2) when (selVMM = b"001") else
                    vmm_data0_vec(3) when (selVMM = b"010") else
                    vmm_data0_vec(4) when (selVMM = b"011") else
                    vmm_data0_vec(5) when (selVMM = b"100") else
                    vmm_data0_vec(6) when (selVMM = b"101") else
                    vmm_data0_vec(7) when (selVMM = b"110") else
                    vmm_data0_vec(8) when (selVMM = b"111");
                    
    vmm_data1   <=  vmm_data1_vec(1) when (selVMM = b"000") else
                    vmm_data1_vec(2) when (selVMM = b"001") else
                    vmm_data1_vec(3) when (selVMM = b"010") else
                    vmm_data1_vec(4) when (selVMM = b"011") else
                    vmm_data1_vec(5) when (selVMM = b"100") else
                    vmm_data1_vec(6) when (selVMM = b"101") else
                    vmm_data1_vec(7) when (selVMM = b"110") else
                    vmm_data1_vec(8) when (selVMM = b"111");
                    
    vmm_ckdt_vec(1)     <= vmm_ckdt when (selVMM = b"000") else '0';
    vmm_ckdt_vec(2)     <= vmm_ckdt when (selVMM = b"001") else '0';
    vmm_ckdt_vec(3)     <= vmm_ckdt when (selVMM = b"010") else '0';
    vmm_ckdt_vec(4)     <= vmm_ckdt when (selVMM = b"011") else '0';
    vmm_ckdt_vec(5)     <= vmm_ckdt when (selVMM = b"100") else '0';
    vmm_ckdt_vec(6)     <= vmm_ckdt when (selVMM = b"101") else '0';
    vmm_ckdt_vec(7)     <= vmm_ckdt when (selVMM = b"110") else '0';
    vmm_ckdt_vec(8)     <= vmm_ckdt when (selVMM = b"111") else '0';
    
    vmm_cktk_vec(1)     <= vmm_cktk when (selVMM = b"000") else '0';
    vmm_cktk_vec(2)     <= vmm_cktk when (selVMM = b"001") else '0';
    vmm_cktk_vec(3)     <= vmm_cktk when (selVMM = b"010") else '0';
    vmm_cktk_vec(4)     <= vmm_cktk when (selVMM = b"011") else '0';
    vmm_cktk_vec(5)     <= vmm_cktk when (selVMM = b"100") else '0';
    vmm_cktk_vec(6)     <= vmm_cktk when (selVMM = b"101") else '0';
    vmm_cktk_vec(7)     <= vmm_cktk when (selVMM = b"110") else '0';
    vmm_cktk_vec(8)     <= vmm_cktk when (selVMM = b"111") else '0';
    
end Behavioral;