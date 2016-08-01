----------------------------------------------------------------------------------
-- Company: NTU ATHNENS - BNL
-- Engineer: Panagiotis Gkountoumis
-- 
-- Create Date: 18.04.2016 13:00:21
-- Design Name: 
-- Module Name: config_logic - Behavioral
-- Project Name: MMFE8 
-- Target Devices: Arix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;

entity i2c_top is
	
		generic(cnt_1ms : natural := 50_000;  -- 20ns*50_000 = 1ms
				 cnt_10ms : natural := 500_000); --20ns*500_000 = 10ms 
	
	port(
		clk_in       : in  std_logic; -- clk40, W19, LVCMOS33			
		phy_rstn_out : out std_logic
		);
	
end i2c_top;

architecture rtl of i2c_top is

	
	signal phy_resetn       : std_logic := '0';

	

begin


	phy_rstn_out     <= phy_resetn;

				
	phy_resetn_process : process(clk_in, phy_resetn) is
		
			variable cnt : natural range 0 to cnt_1ms := 0; --1ms
			
				begin
					if (rising_edge(clk_in)) then
						if phy_resetn = '0' then --resetn
							if(cnt < cnt_1ms)then --cnt
								cnt := cnt + 1;
							elsif(cnt = cnt_1ms)then
								cnt := 0;
								phy_resetn <= '1';
							else null;
							end if; --cnt
						else null;
						end if; --resetn check
					end if; --clk				
				end process;

	
end rtl;

