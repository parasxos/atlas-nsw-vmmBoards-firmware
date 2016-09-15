--------------------------------------------------------------------------------------------
-- Company: NTU ATHENS - BNL
-- Engineer: Paris Moschovakos
-- 
-- Create Date: 21.07.2016
-- Design Name: 
-- Module Name: event_timing_reset.vhd
-- Project Name: MMFE8 
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
--
-- Changelog:
-- 09.09.2016 Added a glBCID counter for periodic soft reset of VMMs which takes place
-- every 102us if DAQ is on and if not in the middle of read-out. (Christos Bakalis)
-- 10.09.2016 Added a new process to assert the periodic soft reset signal. (Christos Bakalis)
--
---------------------------------------------------------------------------------------------

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
		clk_200         : in std_logic;
		clk_10_phase45  : in std_logic;     -- Drives the reset
		bc_clk          : in std_logic;     -- 40MHz

		daqEnable       : in std_logic;     -- From flow FSM
		pfBusy          : in std_logic;     -- From packet formation
		reset           : in std_logic;     -- Reset

		glBCID          : out std_logic_vector(11 downto 0);
		prec_cnt        : out std_logic_vector(4 downto 0);        -- 5 bits are more than enough (32) while 1-25 used

		state_rst_out   : out std_logic_vector(2 downto 0);        -- For debugging purposes
		rst_o           : out std_logic;                           -- For debugging purposes
		rst_done_o      : out std_logic;                           -- For debugging purposes 

		vmm_ena_vec     : out std_logic_vector(8 downto 1);
		vmm_wen_vec     : out std_logic_vector(8 downto 1);
		reset_latched   : out std_logic
		);
end event_timing_reset;

architecture Behavioral of event_timing_reset is

-- Signals

    signal glBCID_i                 : std_logic_vector(11 downto 0) := b"000000000000";
    signal prec_cnt_i               : std_logic_vector(4 downto 0)  := b"00000";
	signal state_nxt                : std_logic_vector(2 downto 0);
	signal vmm_wen_int, vmm_ena_int : std_logic;
	signal acq_rst_int, acq_rst_d   : std_logic;

    signal state_rst                : std_logic_vector(2 downto 0) := "000";
    signal reset_latched_i          : std_logic;
    signal rst_done                 : std_logic;
    signal rst_done_pre             : std_logic:='0';
    signal vmm_ena_vec_i            : std_logic_vector(8 downto 1)	:= ( others => '0' );
    signal vmm_wen_vec_i            : std_logic_vector(8 downto 1)	:= ( others => '0' );
    signal rst_i                    : std_logic := '0';                                     -- Internal reset related to glBCID counter
    constant glBCID_limit           : std_logic_vector(11 downto 0) := b"010000000000";     -- 1024*T(10MHz~100ns) = 102 us
    signal limit_reached_i			: std_logic := '0';
-- Components if any

begin

-- Processes

synchronousSoftReset: process (clk_10_phase45, reset, reset_latched_i, state_rst)
begin
    if rising_edge (clk_10_phase45) then
        if reset_latched_i = '1' then
            case state_rst is
                when "000" => -- reset step 1
                    vmm_ena_vec_i   <= x"00";
                    vmm_wen_vec_i   <= x"00";
                    state_rst       <= "001";
                    rst_done        <= '0';
                when "001" => -- reset step 2
                    vmm_ena_vec_i   <= x"00";
                    vmm_wen_vec_i   <= x"00";
                    state_rst       <= "010";
                    rst_done        <= '0';
                when "010" => -- reset step 3
                    vmm_ena_vec_i   <= x"00";
                    vmm_wen_vec_i   <= x"FF";
                    state_rst       <= "011";
                when "011" => -- reset step 4
                    vmm_ena_vec_i   <= x"00";
                    vmm_wen_vec_i   <= x"00";
                    rst_done        <= '1';
                    state_rst       <= "000";
                when others =>
                    state_rst       <= "000";
            end case;
        elsif daqEnable = '1' then
            vmm_ena_vec_i   <= x"FF";
            vmm_wen_vec_i   <= x"00";
        else
            vmm_ena_vec_i   <= x"00";
            vmm_wen_vec_i   <= x"00";
        end if;
    end if;
end process;

latchResetProc: process (clk_200, rst_done, rst_done_pre, reset, rst_i)
begin
    if rising_edge(clk_200) then
        if rst_done = '0' and rst_done_pre = '1' then
            reset_latched_i <= '0';
        elsif reset = '1' then
            reset_latched_i <= '1';
        elsif rst_i = '1' then      -- internal reset. globBCID has reached limit
            reset_latched_i <= '1';
        end if;
    end if;
end process;

latchResetProcAuxiliary: process (clk_200, rst_done)
begin
    if rising_edge(clk_200) then
        rst_done_pre    <= rst_done;
    end if;
end process;

globalBCIDproc: process (bc_clk, rst_done, glBCID_i)
begin
    if(rst_done = '1')then
        glBCID_i    	<= b"000000000000";
        limit_reached_i <= '0';
    elsif(rising_edge(bc_clk))then 
    
        glBCID_i    <= glBCID_i + 1;
        
        if(glBCID_i >= glBCID_limit)then
        
        	limit_reached_i <= '1';
        else
            limit_reached_i <= '0';
        end if;
    end if;
end process;

rstAsserterProc: process(clk_200, limit_reached_i, rst_done, daqEnable, pfBusy)
begin
	if(rst_done = '1')then
		rst_i	<= '0';
	elsif(rising_edge(clk_200))then
		if(limit_reached_i = '1')then
			if(daqEnable = '1' and pfBusy /= '1')then
                rst_i   <= '1';
            else
                rst_i   <= '0';
            end if;
        else
            rst_i <= '0';
        end if;
    end if;
end process;

--process (bc_clk)
--    begin
--        if (bc_clk'event and bc_clk = '1') then
--    end if;
--end process;

--process (bc_clk)
--     --  this process is an edge detect for acq_rst
--         begin
--         if rising_edge (bc_clk) then
--         end if;

--end process;

-- Signal assignment
    
--    prec_cnt        <=  prec_cnt_i;
    glBCID          <= glBCID_i;
    reset_latched   <= reset_latched_i;
    vmm_ena_vec     <= vmm_ena_vec_i;
    vmm_wen_vec     <= vmm_wen_vec_i;

    ------- Debugging signals assertion ---------
    state_rst_out   <= state_rst;
    rst_o           <= rst_i;
    rst_done_o      <= rst_done;

-- Instantiations if any

end Behavioral;