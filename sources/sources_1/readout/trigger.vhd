----------------------------------------------------------------------------------
-- Company: NTU ATHENS - BNL
-- Engineer: Paris Moschovakos
-- 
-- Create Date: 18.05.2016
-- Design Name: 
-- Module Name: trigger.vhd - Behavioral
-- Project Name: MMFE8 
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
--
-- Changelog:
-- 18.08.2016 Added tr_hold signal to hold trigger when reading out (Reid Pinkham)
-- 26.02.2017 Moved to a global clock domain @125MHz (Paris)
-- 27.02.2017 Synced trout (Paris)
-- 31.03.2017 Added 2 ckbc mode, requests 2 CKBC upon ext trigger (Paris)
-- 06.04.2017 Configurable latency was added for the 2 CKBC mode (Paris)
-- 
----------------------------------------------------------------------------------

library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;

entity trigger is
    Port (
            clk             : in STD_LOGIC;
            ckbc            : in STD_LOGIC;
            clk_art         : in STD_LOGIC;
            
            ckbcMode        : in STD_LOGIC;
            request2ckbc    : out STD_LOGIC;
            
            tren            : in STD_LOGIC;
            tr_hold         : in STD_LOGIC;
            trmode          : in STD_LOGIC;
            trext           : in STD_LOGIC;
            trint           : in STD_LOGIC;

            reset           : in STD_LOGIC;

            event_counter   : out STD_LOGIC_VECTOR(31 DOWNTO 0);
            tr_out          : out STD_LOGIC;
            latency         : in STD_LOGIC_VECTOR(15 DOWNTO 0)
            );
end trigger;

architecture Behavioral of trigger is

-- Signals

    signal event_counter_i   : std_logic_vector(31 downto 0)    := ( others => '0' );
    signal tr_out_i          : std_logic                        := '0';
    signal mode              : std_logic;
    signal trint_pre         : std_logic                        := '0';
    signal trext_pre         : std_logic                        := '0';
    signal trext_stage1      : std_logic                        := '0';
    signal trext_ff_synced   : std_logic                        := '0';    
    signal tren_buff         : std_logic                        := '0'; -- buffered enable signal
    -- Special Readout Mode
    signal trext_RoMode_stage1      : std_logic := '0';
    signal trext_RoMode_ff_synced   : std_logic := '0';
    signal request2ckbc_i           : std_logic := '0';
    signal trigLatencyCnt           : integer := 0;
    signal trigLatency              : integer := 140;
    
    type stateType is (waiting, latencyCounting);
    signal state            : stateType;
    
---------------------------------------------------------------------------------------------- Uncomment for hold window Start
--    signal hold_state       : std_logic_vector(3 downto 0);
--    signal hold_cnt         : std_logic_vector(31 downto 0);
--    signal start            : std_logic;
--    signal hold             : std_logic;
--    signal state            : std_logic_vector(2 downto 0)      := ( others => '0' );
---------------------------------------------------------------------------------------------- Uncomment for hold window End
    
    -- Debugging
    signal probe0_out         : std_logic_vector(39 DOWNTO 0);
    
-- Attributes
---------------------------------------------------------------------------------------------- Uncomment for hold window Start
--    constant delay : std_logic_vector(31 downto 0) := x"00000002"; -- Number of 200 MHz clock cycles to hold trigger in hex
---------------------------------------------------------------------------------------------- Uncomment for hold window End

-------------------------------------------------------------------
-- Keep signals for ILA
-------------------------------------------------------------------    
--    attribute keep : string;

--    attribute keep of event_counter_i       :    signal    is    "true";
--    attribute keep of tr_out_i              :    signal    is    "true";
--    attribute keep of tren                  :    signal    is    "true";
--    attribute keep of trmode                :    signal    is    "true";
--    attribute keep of trint                 :    signal    is    "true";
--    attribute keep of mode                  :    signal    is    "true";
--    attribute keep of trint_pre             :    signal    is    "true";
--    attribute keep of trext_pre             :    signal    is    "true";
    
-- Components if any

    component ila_trigger
    port(
        clk     : IN STD_LOGIC;
        probe0  : IN STD_LOGIC_VECTOR(39 DOWNTO 0)
    );
    end component;

begin

-- Processes
---------------------------------------------------------------------------------------------- Uncomment for hold window Start
--holdDelay: process (clk, reset, start, tr_out_i, trext, trint) -- state machine to manage delay
--begin
--    if (reset = '1') then
--        hold <= '0';
--        state <= ( others => '0' );
--    elsif rising_edge(clk) then
--        case state is 
--            when "000" => -- Idle
--                if (start = '1') then -- wait for start signal
--                    state <= "001";
--                else
--                    state <= "000";
--                end if;

--            when "001" => -- st1
--                if (tr_out_i = '0') then -- trigger returned to zero, start the count
--                    hold <= '1';
--                    hold_cnt <= ( others => '0' ); -- reset the counter
--                    state <= "010";
--                else
--                    state <= "001";
--                end if;

--            when "010" => -- st2
--                if (hold_cnt = delay) then -- reached end of deadtime
--                    if ((trext = '0' and mode = '1') or (trint = '0' and mode = '0')) then -- No current trigger
--                        hold <= '0';
--                        state <= "000";
--                    else
--                        state <= "011";
--                    end if;

--                    hold_cnt <= ( others => '0');
                    
--                else
--                    hold_cnt <= hold_cnt + '1';
--                end if;

--            when "011" => -- st3
--                if ((trext = '0' and mode = '1') or (trint = '0' and mode = '0')) then -- wait until missed trigger ends
--                    state <= "000";
--                    hold <= '0';
--                else
--                    state <= "011";
--                end if;

--            when others =>
--                state <= "000";
--        end case ;
            
--    end if;
--end process;


--triggerLatch: process (tr_out_i, hold)
--begin
--    if (tr_out_i = '1' and hold = '0') then -- start of trigger
--        start <= '1';
--    else -- Release the start command
--        start <= '0';
--    end if;
--end process;
---------------------------------------------------------------------------------------------- Uncomment for hold window End

trReadoutMode2Ckbc: process(clk_art)
begin
    if rising_edge(clk_art) then  
        if trigLatencyCnt < trigLatency and trext_RoMode_ff_synced = '1' and ckbcMode = '1' then 
            trigLatencyCnt      <= trigLatencyCnt + 1;
            request2ckbc_i      <= '0';
        elsif trigLatencyCnt = trigLatency then
            trigLatencyCnt      <= trigLatencyCnt + 1;
            request2ckbc_i      <= '1';
        else
            trigLatencyCnt      <= 0;
            request2ckbc_i      <= '0';
        end if;
    end if;
end process;

trenAnd: process(tren, tr_hold)
begin
    if (tren = '1' and tr_hold = '0') then -- No hold command, trigger enabled
        tren_buff <= '1';
    else
        tren_buff <= '0';
    end if;
end process;

changeModeCommandProc: process (clk, reset, tren_buff, trmode)
    begin
        if rising_edge(clk) and reset = '0' then
            if tren_buff = '1' then
                if trmode = '0' then                                -- Internal trigger
                    mode <= '0';
                else                                                -- External trigger
                    mode <= '1';
                end if;
            end if;
        end if;
    end process;

triggerDistrSignalProc: process (reset, mode, trext_ff_synced, trint)
    begin
        if reset = '1' then
            tr_out_i            <= '0';
        else
            if mode = '0' then
                if (tren_buff = '1' and trmode = '0' and trint = '1') then
                    tr_out_i            <= '1';
                elsif (trmode = '0' and trint = '0') then
                    tr_out_i            <= '0';
                else
                    tr_out_i            <= '0';
                end if;
            else
                if (tren_buff = '1' and trmode = '1' and trext_ff_synced = '1') then
                    tr_out_i            <= '1';
                elsif (trmode = '1' and trext_ff_synced = '0') then
                    tr_out_i            <= '0';
                else
                    tr_out_i            <= '0';
                end if;
            end if;
        end if;
    end process;

externalTriggerSynchronizerSpecialReadoutMode: process(clk_art)
begin
    if rising_edge(clk_art) then 
        trext_RoMode_stage1    <= trext;
        trext_RoMode_ff_synced <= trext_RoMode_stage1;
    end if;
end process;

externalTriggerSynchronizer: process(clk)
begin
    if rising_edge(clk) then 
        trext_stage1    <= trext;
        trext_ff_synced <= trext_stage1;
    end if;
end process;

eventCounterProc: process (clk, reset, mode, trext, trint)
    begin
        if reset = '1' then
            event_counter_i     <= x"00000000";
        else
            if rising_edge(clk) then
                if mode = '0' then
                    if (tren_buff = '1' and trmode = '0' and trint = '1' and trint_pre = '0') then
                        event_counter_i     <= event_counter_i + 1;
                        trint_pre           <= '1';
                    elsif (trmode = '0' and trint = '0') then
                        event_counter_i     <= event_counter_i;
                        trint_pre           <= '0';
                    else
                        event_counter_i     <= event_counter_i;
                    end if;
                else
                    if (tren_buff = '1' and trmode = '1' and trext = '1' and trext_pre = '0') then
                        event_counter_i     <= event_counter_i + 1;
                        trext_pre           <= '1';
                    elsif (trmode = '1' and trext = '0') then
                        event_counter_i     <= event_counter_i;
                        trext_pre           <= '0';
                    else
                        event_counter_i     <= event_counter_i;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
-- Signal assignments
event_counter       <= event_counter_i;
tr_out              <= tr_out_i;
request2ckbc        <= request2ckbc_i;
trigLatency         <= to_integer(unsigned(latency));

-- Instantiations if any

--ilaTRIG: ila_trigger
--port map(
--    clk                     =>  clk,
--    probe0                  =>  probe0_out
--    );
    
--    probe0_out(0)               <=  tr_out_i;
--    probe0_out(1)               <=  tren;
--    probe0_out(2)               <=  trmode;
--    probe0_out(3)               <=  trint;
--    probe0_out(4)               <=  mode;
--    probe0_out(36 downto 5)     <=  event_counter_i;
--    probe0_out(37)              <=  trint_pre;
--    probe0_out(38)              <=  trext_pre;
--    probe0_out(39)              <=  '0';
    

end Behavioral;