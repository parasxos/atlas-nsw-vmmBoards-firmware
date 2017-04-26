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
-- 22.08.2016 Changed state_dt (integer) to state_dt (4 bit vector) (Reid Pinkham)
-- 26.02.2016 Moved to a global clock domain @125MHz (Paris)
-- 25.04.2016 Added vmm_driver interfacing. (Christos Bakalis)
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
            clkTkProc               : in std_logic;     -- Used to clock checking for data process
            clkDtProc               : in std_logic;     -- Used to clock word readout process
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
            vmmWord                 : out std_logic_vector(15 downto 0);
            vmmEventDone            : out std_logic;

            sel_data                : in  std_logic_vector(1 downto 0);
            driverBusy              : in  std_logic;
            
            dt_state_o              : out std_logic_vector(3 downto 0);
            dt_cntr_st_o            : out std_logic_vector(3 downto 0)
           );
end vmm_readout;

architecture Behavioral of vmm_readout is

    -- Interconnected signals
    signal reading_out_word         : std_logic := '0';
    signal reading_out_word_stage1  : std_logic := '0';
    signal reading_out_word_ff_sync : std_logic := '0';
    signal cktkSent                 : std_logic := '0';
    signal cktkSent_stage1          : std_logic := '0';
    signal cktkSent_ff_sync         : std_logic := '0';
    signal timeoutCnt               : unsigned(2 downto 0) := b"000";
    signal timeout                  : unsigned(2 downto 0) := b"111";
    signal daq_enable_stage1_Dt     : std_logic := '0';
    signal daq_enable_ff_sync_Dt    : std_logic := '0';

    -- tokenProc
    signal state_tk             : std_logic_vector( 3 downto 0 )    := x"1";
    signal daq_enable_stage1    : std_logic := '0';
    signal daq_enable_ff_sync   : std_logic := '0';
    signal vmm_wen_i            : std_logic := '0';
    signal vmm_ena_i            : std_logic := '0';
    signal vmm_cktk_i           : std_logic := '0';
    signal NoFlg_counter        : unsigned(7 downto 0) := (others => '0');   -- Counter of CKTKs
    signal cktk_max_i           : std_logic_vector(7 downto 0) := x"07";
    signal cktk_max_sync        : std_logic_vector(7 downto 0) := x"07";
    signal vmmEventDone_i       : std_logic := '0';
    signal vmmEventDone_stage1  : std_logic := '0';
    signal vmmEventDone_ff_sync : std_logic := '0';
    signal trigger_pulse_i      : std_logic := '0';
    signal trigger_pulse_stage1 : std_logic := '0';
    signal trigger_pulse_ff_sync: std_logic := '0';
    signal hitsLen_cnt          : integer := 0;
    signal hitsLenMax           : integer := 150;   --Real maximum is 1119 for a jumbo UDP frame and 184 for a normal UDP frame

    -- readoutProc
    signal vmm_data_buf_i       : std_logic_vector( 37 downto 0 )   := ( others => '0' );
    signal state_dt             : std_logic_vector(3 downto 0) := "0000";
    signal dt_cntr_intg0        : integer := 0;
    signal dt_cntr_intg1        : integer := 0;
    signal dataBitRead          : integer := 0;

    signal vmmWordReady_i       : std_logic := '0';
    signal vmmWordReady_stage1  : std_logic := '0';
    signal vmmWordReady_ff_sync : std_logic := '0';
    signal vmmWord_i            : std_logic_vector(63 downto 0);    
    signal vmm_data0            : std_logic := '0';
    signal vmm_data0_stage1     : std_logic := '0';
    signal vmm_data0_ff_sync    : std_logic := '0';
    signal vmm_data1            : std_logic := '0';
    signal vmm_data1_stage1     : std_logic := '0';
    signal vmm_data1_ff_sync    : std_logic := '0';
    signal driverBusy_stage1    : std_logic := '0';
    signal driverBusy_ff_sync   : std_logic := '0';
    signal vmm_ckdt             : std_logic := '0';     -- Strobe to VMM CKDT
    signal vmm_cktk             : std_logic := '0';     -- Strobe to VMM CKTK
    signal vmm_ckdt_i           : std_logic := '0';

    -- Debugging
    signal probe0_out           : std_logic_vector(127 downto 0);

    -------------------------------------------------------------------
    -- Keep signals for ILA
    -----------------------------------------------------------------
    attribute mark_debug : string;

--    attribute mark_debug of NoFlg                       : signal  is  "true";
--    attribute mark_debug of state_tk                    : signal  is  "true";
--    attribute mark_debug of NoFlg_counter               : signal  is  "true";
--    attribute mark_debug of reading_out_word            : signal  is  "true";
--    attribute mark_debug of cktkSent_ff_sync            : signal  is  "true";
--    attribute mark_debug of vmm_ckdt_i                  : signal  is  "true";
--    attribute mark_debug of vmm_cktk_i                  : signal  is  "true";
--    attribute mark_debug of vmm_data0_ff_sync           : signal  is  "true";
--    attribute mark_debug of vmm_data1_ff_sync           : signal  is  "true";
--    attribute mark_debug of dataBitRead                 : signal  is  "true";
--    attribute mark_debug of state_dt                    : signal  is  "true";
--    attribute mark_debug of vmmEventDone_i              : signal  is  "true";
--    attribute mark_debug of hitsLen_cnt                 : signal  is  "true";
--    attribute mark_debug of vmmWordReady_i              : signal  is  "true";
--    attribute mark_debug of vmmWord_i                   : signal  is  "true";
--    attribute mark_debug of trigger_pulse               : signal  is  "true";
--    attribute mark_debug of trigger_pulse_i             : signal  is  "true";
--    attribute mark_debug of reading_out_word_ff_sync    : signal  is  "true";
--    attribute mark_debug of timeoutCnt                  : signal  is  "true";

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

-- by using this clock the CKTK strobe has f=20MHz (T=50ns, D=50%)
tokenProc: process(clkTkProc)
begin
    if (rising_edge(clkTkProc)) then
        if (daq_enable_ff_sync = '1') then
                case state_tk is
                    when x"1" =>
                        vmmEventDone_i          <= '0';
                        if (trigger_pulse_ff_sync = '1') then
                            state_tk                <= x"2";
                        end if;
                        
                    when x"2" =>
                        if (reading_out_word_ff_sync = '0') then -- If we are not reading issue a CKTK
                            vmm_cktk_i      <= '1';
                            cktkSent        <= '1';
                            hitsLen_cnt     <= hitsLen_cnt + 1;
                            state_tk        <= x"3";
                        else
                            NoFlg_counter   <= ( others => '0' );
                            state_tk        <= x"5";
                        end if;
                    when x"3" =>
                        vmm_cktk_i          <= '0';
                        timeoutCnt          <= b"000";
                        state_tk            <= x"4";

                    when x"4" =>
                        if (NoFlg_counter = unsigned(cktk_max_sync)) then
                            cktkSent        <= '0';                 -- cktkSent intentionally stays high for x1.5 of ckdt proc clock + VMM delay + datapath delay
                            state_tk        <= x"6";                -- If NoFlg_counter = 7 : time to transmit data
                        elsif (timeoutCnt = timeout) then           -- No data (wait for reading_out_word signal to pass through the synchronizer)
                            cktkSent        <= '0';                 -- cktkSent intentionally stays high for x1.5 of ckdt proc clock + VMM delay + datapath delay
                            NoFlg_counter   <= NoFlg_counter  + 1;
                            state_tk        <= x"2";
                        elsif (reading_out_word_ff_sync = '1') then -- Data proc started clocking out VMM data. Wait...
                            cktkSent        <= '0';                 -- cktkSent intentionally stays high for x1.5 of ckdt proc clock + VMM delay + datapath delay
                            NoFlg_counter   <= ( others => '0' );
                            state_tk        <= x"5";
                        else
                            timeoutCnt      <= timeoutCnt + 1;
                        end if;

                    when x"5" =>                                    -- Wait until word readout is done
                        if (reading_out_word_ff_sync = '0') then
                            if hitsLen_cnt >= hitsLenMax then       -- Maximum UDP packet length reached 
                                state_tk            <= x"6";
                            else
                                state_tk            <= x"2";        -- Issue new CKTK strobe
                            end if;
                        end if;
                        
                    when x"6" =>                                    -- Start the soft reset sequence, there is still a chance
                        if (reading_out_word_ff_sync = '0') then    -- of getting data at this point so check that before soft reset
                            NoFlg_counter           <= ( others => '0' );
                            state_tk                <= x"7";
                        else
                            NoFlg_counter   <= ( others => '0' );
                            state_tk        <= x"5";
                        end if;

                    when x"7" =>
                        hitsLen_cnt             <= 0;
                        vmmEventDone_i          <= '1';
                        state_tk                <= x"1";
                        
                    when others =>
                        hitsLen_cnt             <= 0;
                        NoFlg_counter           <= ( others => '0' );
                        state_tk                <= x"1";
                end case;
        else
            state_tk        <= x"1";
            vmm_ena_i       <= '0';
            vmm_cktk_i      <= '0';
            timeoutCnt      <= b"000";
            hitsLen_cnt     <= 0;
            NoFlg_counter   <= ( others => '0' );
            cktkSent        <= '0';
            vmm_wen_i       <= '0';
        end if;
    end if;
end process;

-- by using this clock the CKDT strobe has f=25MHz (T=40ns, D=50%, phase=0deg) to clock in data0 and data1
readoutProc: process(clkDtProc)
begin
    if rising_edge(clkDtProc) then
        if (daq_enable_ff_sync_Dt = '1') then
            case state_dt is
                when x"0" =>
                    reading_out_word    <= '0';
                    vmm_data_buf        <= (others => '0');
                    dt_cntr_intg0       <= 0;
                    dt_cntr_intg1       <= 1;
                    vmm_ckdt_i          <= '0';
                    if (cktkSent_ff_sync = '1' and vmm_data0_ff_sync = '1') then
                        state_dt        <= x"1";
                    end if;

                when x"1" =>
                    reading_out_word<= '1';
                    vmm_ckdt_i      <= '1';
                    state_dt        <= x"a";
                    
                when x"a" =>
                    vmm_ckdt_i      <= '0';
                    state_dt        <= x"b";
                    
                when x"b" =>
                    if (dataBitRead < 19) then
                        vmm_ckdt_i      <= '1';
                    end if;
                    state_dt            <= x"2";

                when x"2" =>                               --  19 ckdt and collect data
                    vmm_ckdt_i      <= '0';
                    if (dataBitRead /= 19) then
                        vmm_data_buf(dt_cntr_intg0) <= vmm_data0_ff_sync;
                        vmm_data_buf(dt_cntr_intg1) <= vmm_data1_ff_sync;
                        vmm_data_buf_i              <= vmm_data_buf;
                        state_dt                    <= x"b";
                        dataBitRead                 <= dataBitRead + 1;
                    else
                        vmm_data_buf(dt_cntr_intg0) <= vmm_data0_ff_sync;
                        vmm_data_buf(dt_cntr_intg1) <= vmm_data1_ff_sync;
                        vmm_data_buf_i              <= vmm_data_buf;
                        dataBitRead                 <= 1;
                        state_dt                    <= x"3";
                    end if;
                    dt_cntr_intg0               <= dt_cntr_intg0 + 2;
                    dt_cntr_intg1               <= dt_cntr_intg1 + 2;

                when x"3" =>
                    vmmWord_i       <= b"00" & vmm_data_buf(25 downto 18) & vmm_data_buf(37 downto 26) & vmm_data_buf(17 downto 8) & b"000000000000000000000000" & vmm_data_buf(7 downto 2) & vmm_data_buf(1) & vmm_data_buf(0);
                                                 --         TDO             &           Gray             &           PDO             &                             &          Address         &    Threshold    &       Flag;
                    state_dt        <= x"d";

                when x"d" =>
                    vmmWordReady_i  <= '0';
                    vmmWord_i       <= b"00" & vmm_data_buf(25 downto 18) & vmm_data_buf(37 downto 26) & vmm_data_buf(17 downto 8) & b"000000000000000000000000" & vmm_data_buf(7 downto 2) & vmm_data_buf(1) & vmm_data_buf(0);
                                                 --         TDO             &           Gray             &           PDO             &                             &          Address         &    Threshold    &       Flag;
                    state_dt        <= x"4";
                    
                when x"4" =>
                    vmmWordReady_i  <= '1';
                    state_dt        <= x"c";
                    
                when x"c" =>                    -- Extended length of high. (Fast CD to slow CD)
                    state_dt        <= x"5";

                when x"5" =>                    -- Word read
                    dt_cntr_intg0   <= 0;
                    dt_cntr_intg1   <= 1;
                    vmmWordReady_i  <= '0';

                    if(driverBusy_ff_sync = '1')then
                        state_dt        <= x"6"; -- go to state that waits for driver
                    else
                        state_dt        <= x"5";
                    end if;

                when x"6" =>
                    if(driverBusy_ff_sync = '0')then
                        state_dt        <= x"0"; -- driver is done, go to idle
                    else
                        state_dt        <= x"6";
                    end if;

                when others =>
                    dt_cntr_intg0   <= 0;
                    dt_cntr_intg1   <= 1;
                    state_dt        <= x"0";
                    vmmWordReady_i  <= '0';
            end case;
        else
            dt_cntr_intg0       <= 0;
            dt_cntr_intg1       <= 1;
            vmmWordReady_i      <= '0';
            reading_out_word    <= '0';
            vmm_ckdt_i          <= '0';
            state_dt            <= x"0";
        end if;
    end if;
end process;

packetFormationSynchronizer: process(clk) --125
begin
    if rising_edge(clk) then 
        vmmEventDone_stage1     <= vmmEventDone_i;
        vmmEventDone_ff_sync    <= vmmEventDone_stage1;
        vmmWordReady_stage1     <= vmmWordReady_i;
        vmmWordReady_ff_sync    <= vmmWordReady_stage1;
    end if;
end process;

tokenProcSynchronizer: process(clkTkProc) --40
begin
    if rising_edge (clkTkProc) then
        daq_enable_stage1           <= daq_enable;
        daq_enable_ff_sync          <= daq_enable_stage1;
        trigger_pulse_stage1        <= trigger_pulse_i;
        trigger_pulse_ff_sync       <= trigger_pulse_stage1;
        reading_out_word_stage1     <= reading_out_word;
        reading_out_word_ff_sync    <= reading_out_word_stage1;
        cktk_max_i                  <= cktk_max;
        cktk_max_sync               <= cktk_max_i;
    end if;
end process;

readoutProcSynchronizer: process(clkDtProc) --50
begin
    if rising_edge(clkDtProc) then
        daq_enable_stage1_Dt        <= daq_enable;
        daq_enable_ff_sync_Dt       <= daq_enable_stage1_Dt;
        vmm_data0_stage1            <= vmm_data0;
        vmm_data0_ff_sync           <= vmm_data0_stage1;
        vmm_data1_stage1            <= vmm_data1;
        vmm_data1_ff_sync           <= vmm_data1_stage1;
        cktkSent_stage1             <= cktkSent;
        cktkSent_ff_sync            <= cktkSent_stage1;
        driverBusy_stage1           <= driverBusy;
        driverBusy_ff_sync          <= driverBusy_stage1;
    end if;
end process;

-- mux that selects vmm data depending on the sel_data from vmm_driver
dout_mux: process(sel_data, vmmWord_i)
begin
    case sel_data is
    when "00"   => vmmWord <= vmmWord_i(63 downto 48);
    when "01"   => vmmWord <= vmmWord_i(47 downto 32);
    when "10"   => vmmWord <= vmmWord_i(31 downto 16);
    when "11"   => vmmWord <= vmmWord_i(15 downto 0);
    when others => vmmWord <= (others => '0');
    end case;
end process;

    vmm_cktk            <= vmm_cktk_i;
    vmm_ckdt            <= vmm_ckdt_i;
    vmmEventDone        <= vmmEventDone_ff_sync;
    vmmWordReady        <= vmmWordReady_ff_sync;
    trigger_pulse_i     <= trigger_pulse;
    
    dt_state_o          <= state_tk;
    dt_cntr_st_o        <= state_dt;

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
    probe0_out(4 downto 1)      <=  state_tk;                                                                       -- OK
    probe0_out(7 downto 5)      <=  (others => '0');
    probe0_out(10 downto 8)     <=  (others => '0');                                                                -- OK
    probe0_out(14 downto 11)    <=  state_dt;                                                                       -- OK
    probe0_out(15)              <=  daq_enable_ff_sync;                                                             -- OK
    probe0_out(16)              <=  reading_out_word;                                                               -- OK
    probe0_out(17)              <=  cktkSent_ff_sync;                                                               -- OK
    probe0_out(18)              <=  vmm_ckdt_i;                                                                     -- OK
    probe0_out(19)              <=  vmm_data0_ff_sync;                                                              -- OK
    probe0_out(20)              <=  vmm_data1_ff_sync;                                                              -- OK
    probe0_out(25 downto 21)    <=  std_logic_vector(to_unsigned(dataBitRead, probe0_out(28 downto 24)'length));    -- OK
    probe0_out(26)              <=  vmmWordReady_i;                                                                 -- OK
    probe0_out(90 downto 27)    <=  vmmWord_i;                                                                      -- OK
    probe0_out(91)              <=  trigger_pulse_i;                                                                -- OK 
    probe0_out(92)              <=  reading_out_word_ff_sync;
    probe0_out(95 downto 93)    <=  std_logic_vector(timeoutCnt);
    probe0_out(127 downto 96)   <=  (others => '0');

end behavioral;