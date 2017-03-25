-------------------------------------------------------------------------------------------
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
-- 05.10.2016 Reworked the component in order to comply with the new standards of the
-- parallel readout scheme. (Christos Bakalis)
--
--------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity vmm_readout_6 is
    Port (
        ------------------------------------------------------------
        ------------------- general interface ----------------------       
        clk_10              : in    std_logic;     -- Used in cktk process
        clk_10_phase45      : in    std_logic;     -- Used to sample the token pulse
        clk_50              : in    std_logic;     -- Used to clock word readout process
        clk_200             : in    std_logic;     -- Used for fast switching between processes
        daq_enable          : in    std_logic;     -- From flow_fsm
        rst_vmm_ro          : in    std_logic;     -- Reset buffer 
        ------------------------------------------------------------
        ------------------- VMM2 ASIC interface --------------------        
        vmm_data0           : in    std_logic;     -- Single-ended data0 from VMM
        vmm_data1           : in    std_logic;     -- Single-ended data1 from VMM
        vmm_ckdt            : out   std_logic;     -- Strobe to VMM CKDT
        vmm_cktk            : out   std_logic;     -- Strobe to VMM CKTK
        vmm_ckbc            : out   std_logic;     -- Strobe to VMM CKBC
        ------------------------------------------------------------
        -------------------- vmm driver interface -----------------        
        trigger_pulse       : in    std_logic;     -- Trigger in
        trigger_ack         : out   std_logic;     -- Trigger acknowledge
        vmm_got_data        : out   std_logic;     -- Buffer not empty
        vmm_event_done      : out   std_logic;     -- Buffer is empty and vmm fifo empty
        ------------------------------------------------------------
        ------------------ packet formation interface --------------                                             
        rd_ena              : in    std_logic;     -- Read word from buffer
        vmmWord             : out   std_logic_vector(31 downto 0); -- Word
        ------------------------------------------------------------
        ----------------------- ila interface ----------------------
        ro_tk_state_ila     : out   std_logic_vector(3 downto 0);
        ro_dt_state_ila     : out   std_logic_vector(3 downto 0)
        );
end vmm_readout_6;

architecture Behavioral of vmm_readout_6 is

COMPONENT vmm_temp_buffer
  PORT (
    rst     : IN  STD_LOGIC;
    wr_clk  : IN  STD_LOGIC;
    rd_clk  : IN  STD_LOGIC;
    din     : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
    wr_en   : IN  STD_LOGIC;
    rd_en   : IN  STD_LOGIC;
    dout    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    full    : OUT STD_LOGIC;
    empty   : OUT STD_LOGIC
  );
END COMPONENT;

    -- interface signals 
    ---------------------------------
    signal clk_10_i             : std_logic := '0';
    signal daq_enable_i         : std_logic := '0';
    ---------------------------------
    signal vmm_data0_i          : std_logic := '0';
    signal vmm_data1_i          : std_logic := '0';
    signal vmm_cktk_i           : std_logic := '0';
    signal vmm_ckdt_i           : std_logic := '0';
    ---------------------------------
    signal trigger_pulse_i      : std_logic := '0';
    signal trigger_ack_i        : std_logic := '0';
    signal vmm_got_data_i       : std_logic := '0';
    signal vmm_event_done_i     : std_logic := '0';
    ---------------------------------
    signal vmmWord_out          : std_logic_vector(31 downto 0);
    signal rd_ena_i             : std_logic := '0';
    ---------------------------------    
    signal ro_tk_state_ila_i    : std_logic_vector(3 downto 0); -- for ila, don't constrain
    signal ro_dt_state_ila_i    : std_logic_vector(3 downto 0);
    ---------------------------------
    
    -- internal signals 
    ---------------------------------   
    -- readoutControlProc
    signal reading_out_word     : std_logic := '0';

    -- tokenProc
    signal dt_state             : std_logic_vector( 3 DOWNTO 0 )    := ( others => '0' );   
    signal trig_latency_counter : unsigned(31 DOWNTO 0)   := ( others => '0' );   -- Latency per VMM ()
    signal trig_latency         : unsigned(31 DOWNTO 0)   := x"00000000";         -- x"0000008C";  700ns @200MHz (User defined)
    signal NoFlg_counter        : unsigned(2 downto 0)  := (others => '0');       -- Counter of CKTKs
    signal NoFlg                : unsigned(2 downto 0)  := "010";                -- How many (#+1) CKTKs before soft reset (User defined)
    signal vmmEventDone_i       : std_logic := '0';
    signal vmm_cktk_45          : std_logic := '0';
    signal hitsLen_cnt          : unsigned(7 downto 0)  := (others => '0');
    signal hitsLenMax           : unsigned(7 downto 0)  := "10010110"; --150 in decimal => 1100 bytes; Real maximum is 1119 for a jumbo UDP frame and 184 for a normal UDP frame

    -- readoutProc
    signal dt_done              : std_logic := '1';
    signal dt_cntr_st           : std_logic_vector(3 downto 0) := "0000";
    signal dt_cntr_intg0        : integer := 0;
    signal dt_cntr_intg1        : integer := 0;
    signal vmm_data_buf         : std_logic_vector(37 downto 0) := (others => '0');
    signal vmmWord_i            : std_logic_vector(63 downto 0);
    signal dataBitRead          : integer := 0;

    -- fifo signals 
    signal wr_en_i              : std_logic := '0';
    signal fifo_full            : std_logic := '0';
    signal fifo_empty           : std_logic := '0';

begin

readoutControlProc: process(clk_200, dt_done, vmm_data0_i)
begin
    if (dt_done = '1') then
        reading_out_word    <= '0';     -- readoutProc done, stop it
    end if;
    if (vmm_data0_i = '1') then
        reading_out_word    <= '1';     -- new data, trigger readoutProc
    end if;
end process;

-- by using this clock the CKTK strobe has f=5MHz (T=200ns, D=50%, phase=45deg)
tokenProc: process(clk_10_i, daq_enable_i, dt_done, vmm_data0_i, rst_vmm_ro, trigger_pulse_i)
begin
    if (rising_edge(clk_10_i)) then
        if(rst_vmm_ro = '1')then
            dt_state        <= x"0";
            NoFlg_counter   <= (others => '0');
            vmmEventDone_i  <= '0';
            hitsLen_cnt     <= (others => '0');
            vmm_cktk_i      <= '0';
            trigger_ack_i   <= '0';
            
        elsif (daq_enable_i = '1') then

            case dt_state is

                    when x"0" =>
                        trigger_ack_i   <= '0';
                            
                        if (trigger_pulse_i = '1') then
                            vmm_cktk_i              <= '0';
                            vmmEventDone_i          <= '0';
                            dt_state                <= x"1";
                        end if;

                    when x"1" =>
                        trigger_ack_i   <= '1';
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
                            NoFlg_counter   <= (others => '0');
                            dt_state        <= x"6";
                        end if;

                    when x"4" =>
                        vmm_cktk_i      <= '0';
                        dt_state        <= x"5";

                    when x"5" =>
                        if (reading_out_word = '1') then        -- Data presence: wait for read out to finish
                            NoFlg_counter   <= (others => '0');
                            dt_state        <= x"6";
                        else
                            if (NoFlg_counter = NoFlg) then
                                dt_state    <= x"7";            -- If NoFlg = 3 : time to soft reset and transmit data
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
                            NoFlg_counter   <= (others => '0');
                            dt_state        <= x"6";
                        end if;

                    when x"8" =>
                         hitsLen_cnt             <= (others => '0');
                         dt_state                <= x"9";
                        
                    when x"9" =>
                         vmmEventDone_i          <= '1';
                         hitsLen_cnt             <= (others => '0');
                         dt_state                <= x"0";

                    when others =>
                        vmmEventDone_i          <= '1';
                        NoFlg_counter           <= (others => '0');
                        dt_state                <= x"0";
                end case;
        else null;
        end if;
    end if;
end process;

-- by using this clock the CKDT strobe has f=25MHz (T=40ns, D=50%, phase=0deg) to clock in data0 and data1
readoutProc: process(clk_50, reading_out_word, rd_ena_i, vmm_data0_i, vmm_data1_i, rst_vmm_ro)
begin
    if rising_edge(clk_50) then
        if(rst_vmm_ro = '1')then
                dt_done         <= '1';
                dt_cntr_st      <= x"0";
                dt_cntr_intg0   <= 0;
                dt_cntr_intg1   <= 1;
                vmm_ckdt_i      <= '0';
                vmmWord_i       <= (others => '0');
                dataBitRead     <= 0;  
                wr_en_i         <= '0';
        elsif (reading_out_word = '1') then

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
                        vmm_data_buf(dt_cntr_intg0) <= vmm_data0_i;
                        vmm_data_buf(dt_cntr_intg1) <= vmm_data1_i;
                        dt_cntr_st                  <= x"1";
                        dataBitRead                 <= dataBitRead + 1;
                    else
                        vmm_data_buf(dt_cntr_intg0) <= vmm_data0_i;
                        vmm_data_buf(dt_cntr_intg1) <= vmm_data1_i;
                        dataBitRead                 <= 1;
                        dt_cntr_st                  <= x"3";
                    end if;
                    dt_cntr_intg0               <= dt_cntr_intg0 + 2;
                    dt_cntr_intg1               <= dt_cntr_intg1 + 2;

                when x"3" =>
                    vmmWord_i         <= b"00" & vmm_data_buf(25 downto 18) & vmm_data_buf(37 downto 26) & vmm_data_buf(17 downto 8) & b"000000000000000000000000" & vmm_data_buf(7 downto 2) & vmm_data_buf(1) & vmm_data_buf(0);
                                                 --         TDO             &           Gray             &           PDO             &                             &          Address         &    Threshold    &       Flag;
                    
                    if(fifo_full = '0')then     -- halt if fifo is full
                        dt_cntr_st        <= x"4";
                    else
                        dt_cntr_st        <= x"3";
                    end if;

                when x"4" =>     
                    wr_en_i         <= '1';   -- write word into the buffer
                    dt_cntr_st      <= x"5";       

                when x"5" =>
                    wr_en_i         <= '0';
                    dt_cntr_intg0   <= 0;
                    dt_cntr_intg1   <= 1;                    
                    dt_cntr_st      <= x"0";
                    dt_done         <= '1';

                when others =>
                    dt_cntr_intg0   <= 0;
                    dt_cntr_intg1   <= 1;
                    dt_cntr_st      <= x"0";
                    dt_done         <= '1';
            end case;
        else null;
        end if;
    end if;
end process;

sampleTkProc: process(clk_10_phase45, vmm_cktk_i)
begin
    if(rising_edge(clk_10_phase45))then
        vmm_cktk_45 <= vmm_cktk_i;
    end if;
end process;

vmm_buffer_6: vmm_temp_buffer
  PORT MAP (
    rst     => rst_vmm_ro,
    wr_clk  => clk_50,
    rd_clk  => clk_200,
    din     => vmmWord_i,
    wr_en   => wr_en_i,
    rd_en   => rd_ena_i,
    dout    => vmmWord_out,
    full    => fifo_full,
    empty   => fifo_empty
  );

    ------- gen interface ------------
    daq_enable_i        <= daq_enable;
    clk_10_i            <= clk_10;
    ----------------------------------
    ----- vmm interface --------------
    vmm_cktk            <= vmm_cktk_45;              
    vmm_ckdt            <= vmm_ckdt_i;
    vmm_ckbc            <= clk_10_i;                           
    vmm_data0_i         <= vmm_data0;               
    vmm_data1_i         <= vmm_data1;
    ----------------------------------
    ------ drv interface -------------                   
    trigger_pulse_i     <= trigger_pulse;
    trigger_ack         <= trigger_ack_i;
    vmm_got_data        <= vmm_got_data_i;
    vmm_event_done      <= vmm_event_done_i;
    ----------------------------------
    --------- pf interface -----------
    vmmWord             <= vmmWord_out;
    rd_ena_i            <= rd_ena;
    ---------------------------------- 
    --------- ila interface ----------   
    ro_tk_state_ila     <= ro_tk_state_ila_i;
    ro_dt_state_ila     <= ro_dt_state_ila_i;           
      
    ---------------------------------
    ---------- other ----------------
    vmm_event_done_i    <= vmmEventDone_i and fifo_empty; -- protect against omitting last words    
    vmm_got_data_i      <= not fifo_empty;                -- if fifo has a word, signal driver
    ro_tk_state_ila_i   <= dt_state;
    ro_dt_state_ila_i   <= dt_cntr_st;
    

end Behavioral;