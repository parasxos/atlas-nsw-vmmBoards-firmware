----------------------------------------------------------------------------------
-- Company: NTU ATHNENS - BNL
-- Engineer: Paris Moschovakos
-- 
-- Create Date:
-- Design Name: 
-- Module Name:
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

library UNISIM;
library ieee;
use ieee.numeric_std.all;
use IEEE.numeric_bit.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use UNISIM.vcomponents.all;

entity event_timing_reset is
	port(
        hp_clk          : in std_logic;     -- High precision clock 1 GHz
        bc_clk          : in std_logic;     -- 40MHz
        trigger         : in std_logic;
        readout_done    : in std_logic;
	    reset           : in std_logic;     -- reset

	    bcid            : out std_logic_vector(12 downto 0);       -- 13 bits 12 for counting to 0xFFF and the MSB as a signal to auto reset.
	    prec_cnt        : out std_logic_vector(4 downto 0);        -- 5 bits are more than enough (32) while 1-25 used

		vmm_ena         : out std_logic;    -- these will be ored with same from other sm. This should evolve to a vector.
        vmm_wen         : out std_logic     -- these will be ored with same from other sm. This should evolve to a vector.
		);
end event_timing_reset;

architecture Behavioral of event_timing_reset is

-- Signals

    signal bcid_i       : std_logic_vector(12 downto 0) := b"0000000000000";
    signal prec_cnt_i   : std_logic_vector(4 downto 0)  := b"00000";

	signal state_nxt : std_logic_vector(2 downto 0);

	signal vmm_wen_int, vmm_ena_int : std_logic;
	signal acq_rst_int, acq_rst_d   : std_logic;

-- Components if any

begin

-- Processes

    process (bc_clk)
    begin
        if (bc_clk'event and bc_clk = '1') then
        end if;
    end process;

     process (bc_clk)
     --  this process is an edge detect for acq_rst
         begin
         if rising_edge (bc_clk) then
         end if;

     end process;

--	process(clk, state_nxt, rst, acq_rst_int, vmm_ena_int, vmm_wen_int)
--	begin
--		if (rising_edge( clk)) then                   --100MHz
--			if (rst = '1') then
--				state_nxt           <= (others=>'0');
--				vmm_ena_int         <= '0';
--				vmm_wen_int         <= '0';
--			else
--                case state_nxt is
--						when "000" =>
							
--							vmm_wen_int <= '0';
--							vmm_ena_int <= '0';

--							if (acq_rst_int = '1') then
--								state_nxt <= "001";
--							else
--								state_nxt <= "000" ;
--							end if ;

--						when "001" =>
--                            vmm_ena_int <= '0';
--							vmm_wen_int <= '1';
--                            state_nxt <= "010";
--                            state_nxt <= "001";
                                
--						when "010" =>
--						    vmm_ena_int <= '0';
--							vmm_wen_int <= '0';
--                            state_nxt <= "000";

--						when others =>    
--                            vmm_ena_int <= '0';
--							vmm_wen_int <= '0';
--							state_nxt <= (others=>'0');
--				end case;
--			end if;
--	   end if;
--	end process;

-- Signal assignment

    vmm_wen     <= vmm_wen_int;
    vmm_ena     <= vmm_ena_int;
    
    prec_cnt    <=  prec_cnt_i;
    bcid        <=  bcid_i;

-- Instantiations if any

end Behavioral;