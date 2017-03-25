----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    09/11/2014  
--! Module Name:    CRresetManager
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library work, ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.all;

--! 
entity CRresetManager is
port ( 
    clk40           : in  std_logic;
    rst_soft        : in  std_logic;
    cr_rst          : out std_logic;
    cr_fifo_flush   : out std_logic
    );
end CRresetManager;

architecture Behavioral of CRresetManager is

--
constant fifoFLUSHcount_max : std_logic_vector (7 downto 0) := "10000000";
constant commonRSTcount_max : std_logic_vector (7 downto 0) := (others=>'1');
signal cr_rst_r,cr_rst_rr,fifoFLUSH : std_logic := '1';
signal rstTimerCount : std_logic_vector (7 downto 0) := (others=>'0');
--

begin
------------------------------------------------------------
-- clock domain crossing appreg_clk to clk40
------------------------------------------------------------
rst_cdc: process(clk40)
begin
    if rising_edge(clk40) then
        cr_rst_r <= rst_soft;
	end if;
end process;
--

------------------------------------------------------------
-- 
------------------------------------------------------------
--
rstTimerCounter: process(clk40)
begin
    if rising_edge(clk40) then
        if cr_rst_r = '1' then
            rstTimerCount <= (others=>'0');
        else -- after cr_rst_r is deasserted:  
            if rstTimerCount = commonRSTcount_max then -- stop counting
                rstTimerCount <= rstTimerCount; -- freese counter
            else
                rstTimerCount <= rstTimerCount + 1;
            end if;
        end if;
	end if;
end process;
--
cr_rst_out: process(clk40)
begin
    if rising_edge(clk40) then
        if cr_rst_r = '1' then
            cr_rst_rr <= '1';
        else
            if rstTimerCount = commonRSTcount_max then
                cr_rst_rr <= '0';
            else
                cr_rst_rr <= cr_rst_rr;
            end if;
        end if;
	end if;
end process;
--
crFifoFlush: process(clk40)
begin
    if rising_edge(clk40) then
        if cr_rst_r = '1' then
            fifoFLUSH <= '1';
        else
            if rstTimerCount = fifoFLUSHcount_max then
                fifoFLUSH <= '0';
            else
                fifoFLUSH <= fifoFLUSH;
            end if;
        end if;
	end if;
end process;
--
cr_rst          <= cr_rst_rr;
cr_fifo_flush   <= fifoFLUSH;
--
    
end Behavioral;

