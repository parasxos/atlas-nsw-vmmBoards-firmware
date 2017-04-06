----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch) 
-- 
-- Create Date: 04.04.2017 18:05:10
-- Design Name: VMM Reset Generator
-- Module Name: rst_gen - RTL
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Asserts a periodic soft reset to the VMMs, either on CKTP mode
-- or in external trigger mode. Reset is inhibited if packet_formation is busy
--
-- 
-- Dependencies: 
-- 
-- Changelog:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity rst_gen is
Port(
    clk_160         : in  std_logic;
    rst_enable      : in  std_logic;
    cktp_enable     : in  std_logic;
    pf_busy         : in  std_logic;
    cktp            : in  std_logic;
    cktp_period     : in  std_logic_vector(21 downto 0);
    rst_period      : in  std_logic_vector(21 downto 0);
    rst_before_cktp : in  std_logic_vector(7 downto 0);
    rst_vmm         : out std_logic
);
end rst_gen;

architecture RTL of rst_gen is
    
    -- for internal use, counters and reset signals
    signal rst_ext_cnt      : unsigned (22 downto 0) := (others => '0');
    signal rst_cktp_cnt     : unsigned (22 downto 0) := (others => '0');

    signal rst_ext_mode     : std_logic := '0';
    signal rst_cktp_mode    : std_logic := '0';

    -- state machine signals
    type state_type is (ST_IDLE, ST_COUNT, ST_RST, ST_ERROR);
    signal state : state_type := ST_IDLE;
    
    -- synchronization signals and ASYNC_REG attributes
    signal rst_enable_i     : std_logic := '0';
    signal rst_enable_s     : std_logic := '0';
    signal cktp_enable_i    : std_logic := '0';
    signal cktp_enable_s    : std_logic := '0';
    
    attribute ASYNC_REG : string;
    
    attribute ASYNC_REG of rst_enable_i     : signal is "TRUE";
    attribute ASYNC_REG of rst_enable_s     : signal is "TRUE";
    attribute ASYNC_REG of cktp_enable_i    : signal is "TRUE";
    attribute ASYNC_REG of cktp_enable_s    : signal is "TRUE";
    
begin

-- process that asserts a periodic soft reset to the VMMs when on external trigger mode
rst_periodic_ext_mode: process(clk_160)
begin
    if(rising_edge(clk_160))then
        if(cktp_enable_s = '0' and rst_enable_s = '1')then
            
            if(rst_ext_cnt < unsigned(rst_period))then
                rst_ext_cnt     <= rst_ext_cnt + 1;
                rst_ext_mode    <= '0';
            elsif(rst_ext_cnt >= unsigned(rst_period))then

                rst_ext_mode <= '1';

                if(rst_ext_cnt >= unsigned(rst_period) + 10)then
                    rst_ext_cnt <= (others => '0');
                else
                    rst_ext_cnt <= rst_ext_cnt + 1;
                end if;
            else
                rst_ext_cnt     <= (others => '0');
                rst_ext_mode    <= '0';
            end if;
                    
        else
            rst_ext_cnt     <= (others => '0');
            rst_ext_mode    <= '0';
        end if;
    end if;
end process;

-- FSM that asserts a periodic soft reset to the VMMs when on CKTP mode
rst_periodic_cktp_mode: process(clk_160)
begin
    if(rising_edge(clk_160))then
        if(cktp_enable_s = '1' and rst_enable_s = '1')then
            case state is

            -- wait for CKTP
            when ST_IDLE =>
                rst_cktp_mode   <= '0';
                if(cktp = '1')then
                    state           <= ST_COUNT;
                    rst_cktp_cnt    <= rst_cktp_cnt + 1;
                else
                    state           <= ST_IDLE;
                    rst_cktp_cnt    <= (others => '0');
                end if;

            -- wait here until a configurable amount of time
            when ST_COUNT =>
                rst_cktp_cnt    <= rst_cktp_cnt + 1;
                if(rst_cktp_cnt >= unsigned(cktp_period) - unsigned(rst_before_cktp))then
                    state <= ST_RST;
                else
                    state <= ST_COUNT;
                end if;

            -- abort if cktp is high, otherwise keep reset high for 10 cycles
            when ST_RST =>
                if(cktp = '1')then
                    state <= ST_ERROR;
                elsif(rst_cktp_cnt >= unsigned(cktp_period) - unsigned(rst_before_cktp))then
                    rst_cktp_mode <= '1';
                    if(rst_cktp_cnt >= (unsigned(cktp_period) - unsigned(rst_before_cktp)) + 10)then
                        rst_cktp_cnt    <= (others => '0');
                        state           <= ST_IDLE;
                    else
                        rst_cktp_cnt    <= rst_cktp_cnt + 1;
                        state           <= ST_RST;
                    end if;
                end if;

            -- wait for CKTP to go low...shouldn't go to this state
            when ST_ERROR =>
                rst_cktp_mode   <= '0';
                rst_cktp_cnt    <= (others => '0');

                if(cktp = '0')then
                    state <= ST_IDLE;
                else
                    state <= ST_ERROR;
                end if;

            when others => state <= ST_IDLE;
            end case;
        else
            rst_cktp_cnt    <= (others => '0');
            rst_cktp_mode   <= '0';
            state           <= ST_IDLE;
        end if;
    end if;
end process;

-- mux that selects/inhibits the reset
rst_mux_proc: process(rst_cktp_mode, rst_ext_mode, cktp_enable, rst_enable, pf_busy)
begin
    if(rst_enable = '1' and pf_busy = '0')then
        case cktp_enable is
        when '1'    => rst_vmm <= rst_cktp_mode;
        when '0'    => rst_vmm <= rst_ext_mode;
        when others => rst_vmm <= '0';
        end case;
    else rst_vmm <= '0';
    end if;
end process;

-- synchronize the control signals
sync_proc: process(clk_160)
begin
    if(rising_edge(clk_160))then
        cktp_enable_i   <= cktp_enable;
        cktp_enable_s   <= cktp_enable_i;
        rst_enable_i    <= rst_enable;
        rst_enable_s    <= rst_enable_i;
    end if;
end process;

end RTL;