----------------------------------------------------------------------------------
-- Company: NTU ATHENS - BNL
-- Engineer: Paris Moschovakos
-- 
-- Create Date: 21.07.2016
-- Design Name: 
-- Module Name: vmm_readout.vhd - Behavioral
-- Project Name: MMFE8 
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
--
-- Changelog:
-- 22.08.2016 Changed vmm_data0_i to reading_out_word in dt_state x"5" to prevent soft reset
-- during VMM readout (Reid Pinkham)
-- 22.08.2016 Changed dt_cntr_intg (integer) to dt_cntr_st (4 bit vector) (Reid Pinkham)
-- 26.02.2016 Moved to a global clock domain @125MHz (Paris)
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.all;
library UNISIM;
use UNISIM.vcomponents.all;

entity vmm_readout is
    Port (
            clk_10_phase45          : in std_logic;     -- Used to clock checking for data process
            clk_50                  : in std_logic;     -- Used to clock word readout process
            clk                     : in std_logic;     -- Main clock

            vmm_data0_vec           : in std_logic_vector(8 downto 1);     -- Single-ended data0 from VMM
            vmm_data1_vec           : in std_logic_vector(8 downto 1);     -- Single-ended data1 from VMM
            vmm_ckdt_vec            : out std_logic_vector(8 downto 1);    -- Strobe to VMM CKDT
            vmm_cktk_vec            : out std_logic_vector(8 downto 1);    -- Strobe to VMM CKTK
            vmm_wen_vec             : out std_logic_vector(8 downto 1);    -- Strobe to VMM WEN
            vmm_ena_vec             : out std_logic_vector(8 downto 1);    -- Strobe to VMM ENA

            daq_enable              : in std_logic;
            trigger_pulse           : in std_logic;                     -- Trigger
            cktk_max                : in std_logic_vector(7 downto 0);  -- Max number of CKTKs
            vmmId                   : in std_logic_vector(2 downto 0);  -- VMM to be readout
            ethernet_fifo_wr_en     : out std_logic;                    -- To be used for reading out seperate FIFOs in VMMx8 parallel readout
            vmm_data_buf            : buffer std_logic_vector(37 downto 0);

            vmmWordReady            : out std_logic;
            vmmWord                 : out std_logic_vector(63 downto 0);
            vmmEventDone            : out std_logic
           );
end vmm_readout;

architecture Behavioral of vmm_readout is

    -- readoutControlProc
    signal reading_out_word        : std_logic := '0';

    -- tokenProc
    signal dt_state             : std_logic_vector( 3 DOWNTO 0 )    := ( others => '0' );
    signal daq_enable_i         : std_logic := '0';
    signal daq_enable_stage1    : std_logic := '0';
    signal daq_enable_ff_sync   : std_logic := '0';
    signal vmm_wen_i            : std_logic := '0';
    signal vmm_ena_i            : std_logic := '0';
    signal vmm_cktk_i           : std_logic := '0';
    signal trig_latency_counter : std_logic_vector( 31 DOWNTO 0 )   := ( others => '0' );   -- Latency per VMM ()
    signal trig_latency         : std_logic_vector( 31 DOWNTO 0 )   := x"0000008C";         -- x"0000008C";  700ns @200MHz (User defined)
    signal NoFlg_counter        : integer   := 0;                                           -- Counter of CKTKs
--    signal NoFlg                : integer   := 7; -- Obsolete. See cktk_max               -- How many (#+1) CKTKs before soft reset (User defined)
    signal cktk_max_i           : std_logic_vector(7 downto 0) := x"07";
    signal cktk_max_sync        : std_logic_vector(7 downto 0) := x"07";
    signal vmmEventDone_i       : std_logic := '0';
    signal vmmEventDone_stage1  : std_logic := '0';
    signal vmmEventDone_ff_sync : std_logic := '0';
    signal trigger_pulse_i      : std_logic := '0';
    signal trigger_pulse_stage1 : std_logic := '0';
    signal trigger_pulse_ff_sync : std_logic := '0';
    signal hitsLen_cnt          : integer := 0;
    signal hitsLenMax           : integer := 150;--1100;  --Real maximum is 1119 for a jumbo UDP frame and 184 for a normal UDP frame

    -- readoutProc
    signal dt_done              : std_logic := '1';
    signal vmm_data_buf_i       : std_logic_vector( 37 DOWNTO 0 )   := ( others => '0' );
    signal dt_cntr_st           : std_logic_vector(3 downto 0) := "0000";
    signal dt_cntr_intg0        : integer := 0;
    signal dt_cntr_intg1        : integer := 0;
    signal vmm_ckdt_i           : std_logic;
    signal dataBitRead          : integer := 0;

    signal vmmWordReady_i       : std_logic := '0';
    signal vmmWordReady_stage1  : std_logic := '0';
    signal vmmWordReady_ff_sync : std_logic := '0';
    signal vmmWord_i            : std_logic_vector(63 downto 0);
    signal vmmWord_ff_sync      : std_logic_vector(63 downto 0);
    signal vmmWord_stage1       : std_logic_vector(63 downto 0);
    
    signal vmm_data0            : std_logic := '0';     -- Single-ended data0 from VMM
    signal vmm_data1            : std_logic := '0';     -- Single-ended data1 from VMM
    signal vmm_ckdt             : std_logic := '0';     -- Strobe to VMM CKDT
    signal vmm_cktk             : std_logic := '0';     -- Strobe to VMM CKTK

    -- Internal signal direct assign from ports
    signal vmm_data0_i          : std_logic := '0';
    signal vmm_data1_i          : std_logic := '0';

    -- Debugging
    signal probe0_out           : std_logic_vector(127 DOWNTO 0);

    -------------------------------------------------------------------
    -- Keep signals for ILA
    -----------------------------------------------------------------
--    attribute mark_debug : string;

--    attribute mark_debug of NoFlg                 : signal  is  "true";
--    attribute mark_debug of dt_state              : signal  is  "true";
--    attribute mark_debug of NoFlg_counter         : signal  is  "true";
--    attribute mark_debug of reading_out_word      : signal  is  "true";
--    attribute mark_debug of dt_done               : signal  is  "true";
--    attribute mark_debug of vmm_ckdt_i            : signal  is  "true";
--    attribute mark_debug of vmm_cktk_i            : signal  is  "true";
--    attribute mark_debug of vmm_data0_i           : signal  is  "true";
--    attribute mark_debug of vmm_data1_i           : signal  is  "true";
--    attribute mark_debug of dataBitRead           : signal  is  "true";
--    attribute mark_debug of dt_cntr_st            : signal  is  "true";
--    attribute mark_debug of vmmEventDone_i        : signal  is  "true";
--    attribute mark_debug of hitsLen_cnt           : signal  is  "true";
--    attribute mark_debug of daq_enable_i          : signal  is  "true";
--    attribute mark_debug of vmmWordReady_i        : signal  is  "true";
--    attribute mark_debug of vmmWord_i             : signal  is  "true";
--    attribute mark_debug of trigger_pulse         : signal  is  "true";
--    attribute mark_debug of trigger_pulse_i       : signal  is  "true";
--    attribute mark_debug of trig_latency_counter  : signal  is  "true";


component vmmSignalsDemux
port(
    selVMM          : in std_logic_vector(2 downto 0);
    
    vmm_data0_vec   : in std_logic_vector(8 downto 1);
    vmm_data1_vec   : in std_logic_vector(8 downto 1);
    vmm_data0       : out std_logic;
    vmm_data1       : out std_logic;
    
    vmm_ckdt        : in std_logic;
    vmm_cktk        : in std_logic;
    vmm_ckdt_vec    : out std_logic_vector(8 downto 1);
    vmm_cktk_vec    : out std_logic_vector(8 downto 1)
    );
end component;
    

component ila_readout
port(
    clk     : in std_logic;
    probe0  : in std_logic_vector(127 downto 0)
);
end component;

begin

readoutControlProc: process(clk, dt_done, vmm_data0_i)
begin
    if (dt_done = '1') then
        reading_out_word    <= '0';     -- readoutProc done, stop it
    end if;
    if (vmm_data0_i = '1' and daq_enable_ff_sync = '1') then
        reading_out_word    <= '1';     -- new data, trigger readoutProc
    end if;
end process;

-- by using this clock the CKTK strobe has f=5MHz (T=200ns, D=50%, phase=45deg)
tokenProc: process(clk_10_phase45, daq_enable_ff_sync, dt_done, vmm_data0_i, trigger_pulse)
begin
    if (rising_edge(clk_10_phase45)) then
        if (daq_enable_ff_sync = '1') then
                case dt_state is

                    when x"0" =>
                        vmmEventDone_i          <= '0';
                        if (trigger_pulse_ff_sync = '1') then
                            vmm_cktk_i              <= '0';
                            dt_state                <= x"1";
                        end if;
                    when x"1" =>
                        if (trig_latency_counter = trig_latency) then
                            dt_state                <= x"2";
                        else
                            trig_latency_counter    <= trig_latency_counter + 1;
                        end if;
                    when x"2" =>
                        vmm_cktk_i      <= '0';
                        dt_state        <= x"3";
                    when x"3" =>
                        if (reading_out_word = '0') then
                            vmm_cktk_i      <= '1';
                            hitsLen_cnt     <= hitsLen_cnt + 1;
                            dt_state        <= x"4";
                        else
                            NoFlg_counter   <= 0;
                            dt_state        <= x"6";
                        end if;
                    when x"4" =>
                        vmm_cktk_i      <= '0';
                        dt_state        <= x"5";
                    when x"5" =>
                        if (reading_out_word = '1') then        -- Data presence: wait for read out to finish
                            NoFlg_counter   <= 0;
                            dt_state        <= x"6";
                        else
                            if (NoFlg_counter = to_integer(unsigned(cktk_max_sync))) then
                                dt_state    <= x"7";            -- If NoFlg = cktk max number : time to soft reset and transmit data
                            else
                                dt_state    <= x"3";            -- Send new CKTK strobe
                            end if;
                            NoFlg_counter <= NoFlg_counter  + 1;
                        end if;
                    when x"6" =>                                -- Wait until word readout is done
                        if (dt_done = '1') then
                            if hitsLen_cnt >= hitsLenMax then       -- Maximum UDP packet length reached 
                                dt_state            <= x"7";
                            else
                                dt_state            <= x"3";        -- Issue new CKTK strobe
                            end if;
                        else
                            dt_state                <= x"6";
                        end if;
                    when x"7" =>                                -- Start the soft reset sequence, there is still a chance
                        if (reading_out_word = '0') then        -- of getting data at this point so check that before soft reset
                            dt_state                <= x"8";
                        else
                            NoFlg_counter   <= 0;
                            dt_state        <= x"6";
                        end if;
                    when x"8" =>
                        hitsLen_cnt             <= 0;
                        dt_state                <= x"9";
                    when x"9" =>
                        vmmEventDone_i          <= '1';
                        NoFlg_counter           <= 0;
                        dt_state                <= x"0";
                    when others =>
                        vmmEventDone_i          <= '1';
                        NoFlg_counter           <= 0;
                        dt_state                <= x"0";
                end case;
        else
            vmm_ena_i     <= '0';
            vmm_wen_i     <= '0';
        end if;
    end if;
end process;

-- by using this clock the CKDT strobe has f=25MHz (T=40ns, D=50%, phase=0deg) to clock in data0 and data1
readoutProc: process(clk_10_phase45, reading_out_word)
begin
    if rising_edge(clk_10_phase45) then
        if (reading_out_word = '1') then

            case dt_cntr_st is
                when x"0" =>                               -- Initiate values
                    dt_done       <= '0';
                    vmm_data_buf  <= (others => '0');
                    dt_cntr_st    <= x"1";
                    dt_cntr_intg0 <= 0;
                    dt_cntr_intg1 <= 1;
                    vmm_ckdt_i    <= '0';               -- Go for the first ckdt

                when x"1" =>
                    vmm_ckdt_i     <= '1';
                    dt_cntr_st     <= x"2";

                when x"2" =>                               --  19 ckdt and collect data
                    vmm_ckdt_i     <= '0';
                    if (dataBitRead /= 19) then
                        vmm_data_buf(dt_cntr_intg0) <= vmm_data0;
                        vmm_data_buf(dt_cntr_intg1) <= vmm_data1;
                        vmm_data_buf_i              <= vmm_data_buf;
                        dt_cntr_st                  <= x"1";
                        dataBitRead                 <= dataBitRead + 1;
                    else
                        vmm_data_buf(dt_cntr_intg0) <= vmm_data0;
                        vmm_data_buf(dt_cntr_intg1) <= vmm_data1;
                        vmm_data_buf_i              <= vmm_data_buf;
                        dataBitRead                 <= 1;
                        dt_cntr_st                  <= x"3";
                    end if;
                    dt_cntr_intg0               <= dt_cntr_intg0 + 2;
                    dt_cntr_intg1               <= dt_cntr_intg1 + 2;

                when x"3" =>
                    vmmWordReady_i    <= '0';
                    vmmWord_i         <= b"00" & vmm_data_buf(25 downto 18) & vmm_data_buf(37 downto 26) & vmm_data_buf(17 downto 8) & b"000000000000000000000000" & vmm_data_buf(7 downto 2) & vmm_data_buf(1) & vmm_data_buf(0);
                                                 --         TDO             &           Gray             &           PDO             &                             &          Address         &    Threshold    &       Flag;
                    dt_cntr_st        <= x"4";

                when x"4" =>
                    vmmWordReady_i    <= '1';
                    dt_cntr_st        <= x"5";

                when x"5" =>                   -- Word read
                    dt_cntr_intg0   <= 0;
                    dt_cntr_intg1   <= 1;
                    dt_cntr_st      <= x"0";
                    vmmWordReady_i  <= '0';
                    dt_done         <= '1';

                when others =>
                    dt_cntr_intg0   <= 0;
                    dt_cntr_intg1   <= 1;
                    dt_cntr_st      <= x"0";
                    vmmWordReady_i  <= '0';
                    dt_done         <= '1';
            end case;
        else
            dt_cntr_intg0 <= 0;
            dt_cntr_intg1 <= 1;
            dt_cntr_st    <= x"0";
        end if;
    end if;
end process;

packetFormationSynchronizer: process(clk)
begin
    if rising_edge(clk) then 
        vmmEventDone_stage1     <= vmmEventDone_i;
        vmmEventDone_ff_sync    <= vmmEventDone_stage1;
        vmmWordReady_stage1     <= vmmWordReady_i;
        vmmWordReady_ff_sync    <= vmmWordReady_stage1;
--        daq_enable_stage1       <= daq_enable_i;
--        daq_enable_ff_sync      <= daq_enable_stage1;
    end if;
end process;

tokenProcSynchronizer: process(clk_10_phase45)
begin
    if rising_edge (clk_10_phase45) then
        daq_enable_stage1       <= daq_enable_i;
        daq_enable_ff_sync      <= daq_enable_stage1;
        trigger_pulse_stage1    <= trigger_pulse_i;
        trigger_pulse_ff_sync   <= trigger_pulse_stage1;
        cktk_max_i              <= cktk_max;
        cktk_max_sync           <= cktk_max_i;
    end if;
end process;

vmmWordSynchronizer: process(clk)
begin
    if rising_edge(clk) then
        vmmWord_stage1  <= vmmWord_i;
        vmmWord_ff_sync <= vmmWord_stage1;
    end if;
end process;

    daq_enable_i        <= daq_enable;
    vmmEventDone        <= vmmEventDone_ff_sync;
    vmmWordReady        <= vmmWordReady_ff_sync;
    vmm_cktk            <= vmm_cktk_i;              -- Used
    vmm_ckdt            <= vmm_ckdt_i;              -- Used
    vmm_data0_i         <= vmm_data0;               -- Used
    vmm_data1_i         <= vmm_data1;               -- Used
    vmmWord             <= vmmWord_ff_sync;         -- Used
    trigger_pulse_i     <= trigger_pulse;           -- Used

VMMdemux: vmmSignalsDemux
port map(
    selVMM          => vmmId,
    
    vmm_data0_vec   => vmm_data0_vec,
    vmm_data1_vec   => vmm_data1_vec,
    vmm_data0       => vmm_data0,
    vmm_data1       => vmm_data1,
    
    vmm_ckdt        => vmm_ckdt,
    vmm_cktk        => vmm_cktk,
    vmm_ckdt_vec    => vmm_ckdt_vec,
    vmm_cktk_vec    => vmm_cktk_vec
    );

--ilaDAQ: ila_readout
--port map
--    (
--        clk                     =>  clk,
--        probe0                  =>  probe0_out
--    );

    probe0_out(0)               <=  vmm_cktk_i;                                                                     -- OK
    probe0_out(4 downto 1)      <=  dt_state;                                                                       -- OK
    probe0_out(7 downto 5)      <=  (others => '0');
    probe0_out(10 downto 8)     <=  std_logic_vector(to_unsigned(NoFlg_counter, probe0_out(10 downto 8)'length));   -- OK
    probe0_out(14 downto 11)    <=  dt_cntr_st;                                                                     -- OK
    probe0_out(15)              <=  daq_enable_ff_sync;                                                             -- OK
    probe0_out(16)              <=  reading_out_word;                                                               -- OK
    probe0_out(17)              <=  dt_done;                                                                        -- OK
    probe0_out(18)              <=  vmm_ckdt_i;                                                                     -- OK
    probe0_out(19)              <=  vmm_data0_i;                                                                    -- OK
    probe0_out(20)              <=  vmm_data1_i;                                                                    -- OK
    probe0_out(25 downto 21)    <=  std_logic_vector(to_unsigned(dataBitRead, probe0_out(28 downto 24)'length));    -- OK
    probe0_out(26)              <=  vmmWordReady_i;                                                                 -- OK
    probe0_out(90 downto 27)    <=  vmmWord_i;                                                                      -- OK
    probe0_out(91)              <=  trigger_pulse_i;                                                                -- OK
    probe0_out(123 downto 92)   <=  trig_latency_counter;   

    probe0_out(127 downto 124)  <=  (others => '0');

end behavioral;