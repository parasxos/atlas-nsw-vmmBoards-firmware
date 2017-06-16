----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch) 
-- 
-- Create Date: 28.04.2017 14:18:44
-- Design Name: Level-0 Reset Sequence Asserter
-- Module Name: l0_rst - RTL
-- Project Name: NTUA-BNL VMM3 Readout Firmware
-- Target Devices: Xilinx xc7a200t-2fbg484
-- Tool Versions: Vivado 2016.4
-- Description: This module asserts a proper reset sequence to all level_0 readout
-- subcomponents (logic and buffers)
-- 
-- Dependencies: 
-- 
-- Changelog: 
-- 
----------------------------------------------------------------------------------
library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use UNISIM.VComponents.all;

entity l0_rst is
    Port(
        clk         : in  std_logic;
        rst         : in  std_logic;
        rst_buff    : in  std_logic;
        rst_l0      : out std_logic;
        rst_l0_buff : out std_logic
    );
end l0_rst;

architecture RTL of l0_rst is

    signal cnt_rst          : integer range 0 to 31 := 0;
    signal cnt_rst_buff     : integer range 0 to 15 := 0;
    signal rst_l0_buff_i0   : std_logic := '0';
    signal rst_l0_buff_i1   : std_logic := '0';
    signal rst_l0_i         : std_logic := '0';
    signal rst_l0_buff_i    : std_logic := '0';

begin

-- complete logic and buffer reset asserter (TEMPORARILY UNUSED)
--rst_l0_proc: process(clk)
--begin
--    if(rising_edge(clk))then
--        if(rst = '1')then
--            rst_l0_i        <= '0';
--            rst_l0_buff_i0  <= '0';
--            cnt_rst         <= 0;
--        else
--            case cnt_rst is
--            when 0 to 10 =>
--                rst_l0_i        <= '1';
--                rst_l0_buff_i0  <= '1';
--                cnt_rst         <= cnt_rst + 1;
--            when 11 to 20 =>
--                rst_l0_i        <= '0';
--                rst_l0_buff_i0  <= '1';
--                cnt_rst         <= cnt_rst + 1;
--            when 21 to 30 =>
--                rst_l0_i        <= '0';
--                rst_l0_buff_i0  <= '0';
--                cnt_rst         <= cnt_rst + 1;
--            when 31 =>
--                rst_l0_i        <= '0';
--                rst_l0_buff_i0  <= '0';
--                cnt_rst         <= 31;
--            when others =>
--                rst_l0_i        <= '0';
--                rst_l0_buff_i0  <= '0';
--            end case;
--        end if;
--    end if;
--end process;

-- buffer reset asserter
rst_buff_proc: process(clk)
begin
    if(rising_edge(clk))then
        if(rst_buff = '1')then
            rst_l0_buff_i1  <= '0';
            cnt_rst_buff    <= 0;
        else
            case cnt_rst_buff is
            when 0 to 10 =>
                rst_l0_buff_i1  <= '1';
                cnt_rst_buff    <= cnt_rst_buff + 1;
            when 11 =>
                rst_l0_buff_i1  <= '0';
                cnt_rst_buff    <= 11;
            when others =>
                rst_l0_buff_i1  <= '0';
            end case;
        end if;
    end if;
end process;

--    rst_l0_buff_i <= rst_l0_buff_i0 or rst_l0_buff_i1;
    rst_l0_buff <= rst_l0_buff_i1;

--RST_L0_BUFG:        BUFG port map(O => rst_l0,      I => rst_l0_i);
--RST_L0_BUFF_BUFG:   BUFG port map(O => rst_l0_buff, I => rst_l0_buff_i);

end RTL;