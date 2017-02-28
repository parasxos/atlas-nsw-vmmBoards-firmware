----------------------------------------------------------------------------------------
-- Company:  University of Washington
-- Engineer: Lev Kurilenko
-- 
-- Create Date: 25.10.2016 15:47:35
-- Design Name: 
-- Module Name: cktp_gen - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: CKTP Generator
-- 
-- Dependencies: 
-- 
-- Changelog: 
-- 20.02.2017 Added dynamic CKBC input frequency and reset circuitry. Changed the input
-- clock frequency to 160 Mhz. (Christos Bakalis)
-- 27.02.2017 Added cktp_primary signal from flow_fsm. (Christos Bakalis)
--
----------------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity cktp_gen is
    port(
        clk_160         : in  std_logic;
        cktp_start      : in  std_logic;
        cktp_primary    : in  std_logic;
        vmm_ckbc        : in  std_logic; -- CKBC clock currently dynamic
        ckbc_freq       : in  std_logic_vector(7 downto 0);
        skew            : in  std_logic_vector(15 downto 0);
        pulse_width     : in  std_logic_vector(31 downto 0);
        period          : in  std_logic_vector(31 downto 0);
        CKTP            : out std_logic
    );
end cktp_gen;

architecture Behavioral of cktp_gen is

    --is_state            <= "0101";

    signal cktp_state                   : std_logic_vector(3 downto 0) := (others => '0');
    signal cktp_cnt                     : integer   := 0;
    signal vmm_cktp                     : std_logic := '0';
    signal cktp_start_i                 : std_logic := '0';            -- Internal connection to 2-Flip-Flop Synchronizer
    signal cktp_start_sync              : std_logic := '0';            -- Synchronized output from Synchronizer
    signal cktp_primary_i               : std_logic := '0';
    signal cktp_primary_sync            : std_logic := '0';
    signal cktp_start_aligned           : std_logic := '0';            -- CKTP_start signal aligned to CKBC clock
    signal align_cnt                    : unsigned(7 downto 0) := (others => '0');         -- Used for aligning with the CKBC
    signal align_cnt_thresh             : unsigned(7 downto 0) := (others => '0');
    signal start_align_cnt              : std_logic := '0';     -- 
    
begin

--period <= x"43200"; -- Hardcode 320,000 cycles at 320 MHz to give a period of 1ms

    CKTP <= vmm_cktp;
    
--testPulse_proc: process(clk_10_phase45) -- 10MHz/#states.
--    begin
--        if rising_edge(clk_10_phase45) then            
--            if state = DAQ and trig_mode_int = '0' then
--                case cktp_state is
--                    when 0 to 9979 =>
--                        cktp_state <= cktp_state + 1;
--                        vmm_cktp      <= '0';
--                    when 9980 to 10000 =>
--                        cktp_state <= cktp_state + 1;
--                        vmm_cktp   <= '1';
--                    when others =>
--                        cktp_state <= 0;
--                end case;
--            else
--                vmm_cktp      <= '0';
--            end if;
--        end if;
--end process;

synchronizer_proc: process(vmm_ckbc, cktp_start)
    begin
        if(cktp_start = '0')then
            start_align_cnt <= '0';        
        elsif rising_edge(vmm_ckbc) then
            start_align_cnt <= '1';
            
            --if (cktp_start_sync = '1') then
            --    cktp_start_aligned <= '1';
            --    --if (to_integer(unsigned(skew)) = 0) then    -- Set CKTP signal as soon as rising edge of CKBC arrives if skew = 0
            --    --    vmm_cktp <= '1';
            --    --end if;
            --else
            --    cktp_start_aligned <= '0';
            --end if;
        end if;
end process;

testPulse_proc: process(clk_160) -- 160 MHz
    begin
        if rising_edge(clk_160) then
            if(cktp_start = '0')then
                cktp_cnt            <= 0;
                cktp_start_i        <= '0';
                cktp_start_sync     <= '0';
                vmm_cktp            <= '0';
                cktp_start_aligned  <= '0';
                align_cnt           <= (others => '0');
                cktp_state          <= (others => '0');
            else
                -- 2 Flip Flop Synchronizer
                cktp_start_i <= cktp_start;
                cktp_start_sync <= cktp_start_i;
                
                cktp_primary_i      <= cktp_primary;
                cktp_primary_sync   <= cktp_primary_i;
                
                if start_align_cnt = '1' then       -- Start alignment counter on rising edge of CKBC    
                    if align_cnt < align_cnt_thresh then
                        align_cnt <= align_cnt + 1;
                    else
                        align_cnt <= (others => '0');
                    end if;
                    
                    if cktp_start_sync = '0' then       -- Align CKTP generation to rising edge of CKBC
                        cktp_start_aligned <= '0';
                    elsif ((align_cnt = align_cnt_thresh) and (cktp_start_sync = '1')) then
                        cktp_start_aligned <= '1';
                        if (to_integer(unsigned(skew)) = 0 and cktp_primary_sync = '0') then    -- Set CKTP signal as soon as rising edge of CKBC arrives if skew = 0
                            vmm_cktp <= '1';
                        end if;
                    end if;
                    
                end if;
                
                if cktp_start_aligned = '1' and cktp_primary_sync = '0' then
                    if (cktp_cnt < (to_integer(unsigned(skew)) - 1 ) and (cktp_cnt /= to_integer(unsigned(skew)))) then
                            cktp_state  <= "0000";
                            vmm_cktp    <= '0';
                            cktp_cnt    <= cktp_cnt + 1;
                    elsif ( (cktp_cnt >= (to_integer(unsigned(skew))) - 1) and (cktp_cnt <= ( to_integer(unsigned(skew)) + to_integer(unsigned(pulse_width)) - 2) ) ) then 
                            cktp_state  <= "0001";
                            vmm_cktp    <= '1';
                            cktp_cnt    <= cktp_cnt + 1;
                    -- Uncomment if period does needs to be hardcoded
                    --elsif ( (cktp_cnt > ( to_integer(unsigned(skew)) + to_integer(unsigned(pulse_width)) - 2) ) and (cktp_cnt <= 320000 - 2) ) then
                    elsif ( (cktp_cnt > ( to_integer(unsigned(skew)) + to_integer(unsigned(pulse_width)) - 2) ) and (cktp_cnt <= to_integer(unsigned(period)) - 2) ) then
                            cktp_state  <= "0010";
                            vmm_cktp    <= '0';
                            cktp_cnt    <= cktp_cnt + 1;
                    else
                            cktp_state  <= "0011";
                            cktp_cnt    <= 0;
                    end if;
                elsif cktp_primary_sync = '1' then -- from flow_fsm. keep cktp high for readout initialization
                    vmm_cktp <= '1';
                else
                    cktp_state    <= "1111";
                    cktp_cnt <= 0;
                end if;
            end if;
        end if;
end process;

ckbc_freq_proc: process(ckbc_freq)
begin
    case ckbc_freq is
    when "00001010" => -- 10 Mhz
        align_cnt_thresh <= "00001111"; -- (16 - 1) 
    when "00010100" => -- 20 Mhz
        align_cnt_thresh <= "00000111"; -- (8 - 1)
    when "00101000" => -- 40 Mhz
        align_cnt_thresh <= "00000011"; -- (4 - 1)
    when others => 
        align_cnt_thresh <= "11111111"; 
    end case;
end process;

end Behavioral;