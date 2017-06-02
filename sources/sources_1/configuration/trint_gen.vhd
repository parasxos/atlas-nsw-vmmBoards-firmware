----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Create Date: 12.04.2017 20:51:01
-- Design Name: 
-- Module Name: trint_gen - RTL
-- Project Name:
-- Target Devices: 
-- Tool Versions: 
-- Description: State machine that detects a CKTP pulse and issues an internal
-- trigger signal that starts the readout process.
-- 
-- Dependencies:
-- 
-- Changelog: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity trint_gen is
Generic(vmmReadoutMode : std_logic);
Port(
    clk_160     : in  std_logic;
    clk_125     : in  std_logic;
    cktp_start  : in  std_logic;
    cktp_pulse  : in  std_logic;
    cktp_width  : in  std_logic_vector(11 downto 0);
    trint       : out std_logic
   );
end trint_gen;

architecture RTL of trint_gen is

    signal trint_cnt        : unsigned(11 downto 0) := (others => '0');
    signal cktp_start_i     : std_logic := '0';
    signal cktp_start_s_0   : std_logic := '0';
    signal cktp_start_s     : std_logic := '0';
    signal cktp_start_final : std_logic := '0';
    signal cnt_delay        : unsigned(3 downto 0) := (others => '0');
    
    signal trint_i          : std_logic := '0'; -- synced @ 160
--    signal trint_s_0        : std_logic := '0';
--    signal trint_s          : std_logic := '0'; -- synced @ 125

    type trint_state_type is (ST_INIT, ST_IDLE, ST_WAIT, ST_TRINT);
    signal state : trint_state_type := ST_INIT;

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of cktp_start_s_0  : signal is "TRUE";
    attribute ASYNC_REG of cktp_start_s    : signal is "TRUE";
--    attribute ASYNC_REG of trint_s_0       : signal is "TRUE";
--    attribute ASYNC_REG of trint_s         : signal is "TRUE";

begin

-- check if the width is zero, and inhibit the fsm if so
width_check_proc: process(cktp_width, cktp_start)
begin
    case cktp_width is
    when x"000" =>
        cktp_start_i <= '0';
    when others =>
        if(cktp_start = '1')then
            cktp_start_i <= '1';
        else
            cktp_start_i <= '0';
        end if;
    end case;
end process;

-- sync the start signal
sync_start_proc: process(clk_160)
begin
    if(rising_edge(clk_160))then
         cktp_start_s_0 <= cktp_start_i;
         cktp_start_s   <= cktp_start_s_0;  
    end if;
end process;

-- delay assertion of cktp start
cktp_enable_delayer_trint: process(clk_160)
begin
    if(rising_edge(clk_160))then
        if(cktp_start_s = '1')then
            if(cnt_delay < "1110")then
                cnt_delay           <= cnt_delay + 1;
                cktp_start_final    <= '0';
            else
                cktp_start_final    <= '1';
            end if;
        else
            cnt_delay           <= (others => '0');
            cktp_start_final    <= '0';
        end if;
    end if;
end process;

-- internal trigger FSM
trint_fsm: process(clk_160)
begin
    if(rising_edge(clk_160))then
        if(cktp_start_final = '1')then
            case state is
            
             -- only proceed if cktp is low
            when ST_INIT =>
                if(cktp_pulse = '0')then
                    state <= ST_IDLE;
                else
                    state <= ST_INIT;
                end if;

            -- wait for CKTP pulse
            when ST_IDLE =>
                trint_i     <= '0';
                trint_cnt   <= (others => '0');

                if(cktp_pulse = '1' and vmmReadoutMode = '0')then
                    state <= ST_WAIT;
                elsif(cktp_pulse = '1' and vmmReadoutMode = '1')then
                    state <= ST_TRINT;
                else
                    state <= ST_IDLE;
                end if;

            -- wait before asserting the internal trigger
            when ST_WAIT =>
                if(cktp_pulse = '1')then
                    trint_cnt   <= trint_cnt + 1;

                    if(trint_cnt < unsigned(cktp_width) - "1000110")then
                        state <= ST_WAIT;
                    else
                        state <= ST_TRINT;
                    end if;        
                else
                    state <= ST_IDLE;
                end if;

            -- assert the internal trigger pulse (expected width ~ 400ns if continuous mode)
            when ST_TRINT =>
                trint_i <= '1';

                if(cktp_pulse = '1')then
                    state <= ST_TRINT;
                else
                    state <= ST_IDLE;
                end if;

            when others => state <= ST_INIT;
            end case;
        else
           trint_i      <= '0';
           trint_cnt    <= (others => '0');
           state        <= ST_INIT;
        end if;
    end if;
end process;

-- sync the trint signal (Obsolete as the signal is synced one level-up)
--sync_trint_proc: process(clk_125)
--begin
--    if(rising_edge(clk_125))then
--         trint_s_0 <= trint_i;
--         trint_s   <= trint_s_0;  
--    end if;
--end process;

    trint <= trint_i; -- synced to 160 Mhz

end RTL;