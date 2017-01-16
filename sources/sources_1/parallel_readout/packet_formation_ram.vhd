----------------------------------------------------------------------------------
-- Company:  NTU Athens - BNL
-- Engineer: Paris Moschovakos (paris.moschovakos@cern.ch)
--           Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Create Date: 09/30/2016 10:35:05 AM
-- Design Name: 
-- Module Name: packet_formation_ram - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: Based on the original component by Paris Moschovakos
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity packet_formation_ram is
    Port(
        -----------------------------------------------
        ---------- general interface ------------------
        clk_200             : in    std_logic;
        newCycle            : in    std_logic;
        vmmId               : out   std_logic_vector(2 downto 0);        
        pfBusy              : out   std_logic;                        -- Control signal to ETR
        glBCID              : in    std_logic_vector(11 downto 0);    -- glBCID counter from ETR
        eventCnt            : in    std_logic_vector(31 downto 0);    -- event_counter from trigger module
        reset               : in    std_logic;
        resetting           : in    std_logic;
        rst_vmm             : out   std_logic;
        tr_hold             : out   std_logic;
        latency             : in    std_logic_vector(15 downto 0);        
        -----------------------------------------------
        ----------- vmm driver interface -------------
        write_packet        : in    std_logic;
        write_trailer       : in    std_logic;
        write_zeroes        : in    std_logic;
        udp_init            : in    std_logic;         
        done_and_cycle      : out   std_logic;
        new_read            : out   std_logic;
        trg_drv             : out   std_logic;
        pf_ready            : out   std_logic;                      -- also driven into RAM2UDP
        -----------------------------------------------
        ------------- RAM2UDP interface ---------------
        RAMdone             : in    std_logic;
        dataout             : out   std_logic_vector(31 downto 0);
        addrRAM_wr          : out   std_logic_vector(11 downto 0);
        packLen             : out   std_logic_vector(11 downto 0);
        end_packet          : out   std_logic;
        wrenable            : out   std_logic;
        init_read           : out   std_logic;
        got_len             : in    std_logic;
        -------------------------------------------------
        ------------ vmm interface ----------------------
        vmm_rd_ena          : out   std_logic_vector(7 downto 0);
        fifo_bus_vmm0       : in    std_logic_vector(31 downto 0);
        fifo_bus_vmm1       : in    std_logic_vector(31 downto 0);
        fifo_bus_vmm2       : in    std_logic_vector(31 downto 0);
        fifo_bus_vmm3       : in    std_logic_vector(31 downto 0);
        fifo_bus_vmm4       : in    std_logic_vector(31 downto 0);
        fifo_bus_vmm5       : in    std_logic_vector(31 downto 0);
        fifo_bus_vmm6       : in    std_logic_vector(31 downto 0);
        fifo_bus_vmm7       : in    std_logic_vector(31 downto 0);
        --------------------------------------------------
        -------- ila interface ---------------------------
        pf_state_ila        : out   std_logic_vector(5 downto 0);
        start_cnt           : out   std_logic;
        start_cnt_ram       : out   std_logic;
        trigger_ila         : out   std_logic
    );
end packet_formation_ram;

architecture Behavioral of packet_formation_ram is


component dout_mux
  Port (
    header_0_mux        : in std_logic_vector(31 downto 0);
    header_1_mux        : in std_logic_vector(31 downto 0);
    vmmWord_0_mux       : in std_logic_vector(31 downto 0);
    vmmWord_1_mux       : in std_logic_vector(31 downto 0);
    vmmWord_2_mux       : in std_logic_vector(31 downto 0);
    vmmWord_3_mux       : in std_logic_vector(31 downto 0);
    vmmWord_4_mux       : in std_logic_vector(31 downto 0);
    vmmWord_5_mux       : in std_logic_vector(31 downto 0);
    vmmWord_6_mux       : in std_logic_vector(31 downto 0);
    vmmWord_7_mux       : in std_logic_vector(31 downto 0);
    trailer_mux         : in std_logic_vector(31 downto 0);
    vmmId_cnt_mux       : in std_logic_vector(2 downto 0);
    master_sel_mux      : in std_logic_vector(1 downto 0);
    data_out_mux        : out std_logic_vector(31 downto 0)
    );
end component;

--COMPONENT ila_pf
--    PORT (
--    clk    : IN STD_LOGIC;
--    probe0 : IN STD_LOGIC_VECTOR(223 DOWNTO 0)
--);
--END COMPONENT;

    signal header_0         : std_logic_vector(31 downto 0) := ( others => '0' );
    signal header_1         : std_logic_vector(31 downto 0) := ( others => '0' );
    signal vmmId_i          : std_logic_vector(2 downto 0)  := ( others => '0' );
    signal globBcid         : std_logic_vector(15 downto 0) := x"ffff";
    signal precCnt          : std_logic_vector(7 downto 0)  := x"00";
    signal globBCID_etr     : std_logic_vector(11 downto 0) := (others => '0'); -- globBCID counter as it is coming from ETR
    signal eventCounter_i   : std_logic_vector(31 downto 0) := ( others => '0' );
    signal master_sel       : std_logic_vector(1 downto 0) := (others => '0');
    signal wait_Cnt         : integer := 0;
    signal vmmId_cnt        : integer := 0;
    signal trigLatencyCnt   : integer := 0;
    signal trigLatency      : integer := 200; -- (200 i.e. 1 us)
    signal pfBusy_i         : std_logic := '0';               -- control signal to be sent to ETR
    signal daqRAM_wr_en_i   : std_logic                     := '0';
    signal packLen_i        : std_logic_vector(11 downto 0) := ( others => '0' );
    signal end_packet_i     : std_logic                     := '0';
    constant trailer        : std_logic_vector(31 downto 0) := X"ffffffff";
    signal trg_drv_i        : std_logic := '0';
    signal addrRAM          : unsigned(11 downto 0) := (others => '0');
    signal addRAM_wr_i      : std_logic_vector(11 downto 0) := (others => '0');
    signal vmm_rd_ena_i     : std_logic_vector(7 downto 0)  := (others => '0');
    signal pf_ready_i       : std_logic := '0';
    signal write_packet_i   : std_logic := '0';
    signal write_trailer_i  : std_logic := '0';
    signal write_zeroes_i   : std_logic := '0';
    signal udp_init_i       : std_logic := '0';
    signal done_and_cycle_i : std_logic := '0';
    signal new_read_i       : std_logic := '0';
    signal init_read_i      : std_logic := '0';
    signal RAMdone_sync     : std_logic := '0';
    signal got_len_sync     : std_logic := '0';
    signal newCycle_sync    : std_logic := '0';
    signal tr_hold_i        : std_logic := '0';
    signal rst_vmm_i        : std_logic := '0';
    signal resetting_i      : std_logic := '0';

    signal start_cnt_i      : std_logic := '0';
    signal start_cnt_ram_i  : std_logic := '0';
    signal trigger_ila_i    : std_logic := '0';

    type unsigned_array is array (integer range 0 to 7) of unsigned(11 downto 0);
    signal packLenArrayCnt : unsigned_array;

    type stateType is (waitingForNewCycle, S2, waitForLatency, captureEventID, setEventID, sendHeaderStep1, sendHeaderStep2, sendHeaderStep3, sendHeaderStep4, 
                       cycleVMM_header, waitForDriver, readSendDataStep1, readSendDataStep2, readSendDataStep3, readSendDataStep4, readSendDataStep5,
                       sendTrailerStep1, sendTrailerStep2, sendTrailerStep3, sendTrailerStep4, sendTrailerStep5, packetDone, doneSending, assertDoneCycle, 
                       assertNewRead, resetAndStartRead, resetDone, assertInitRead, waitToLatch, isUDPDone, isTriggerOff, delayWrite0, delayWrite1, assertWord, 
                       readEnable0, readEnable1, readEnable2, readEnable3);
    signal state      : stateType := waitingForNewCycle;

--------------------  Debugging ------------------------------
  --  signal debug_probe          : std_logic_vector(223 DOWNTO 0);
    signal debug_state          : std_logic_vector(5 downto 0);
-----------------------------------------------------------------

----------------------  Debugging ------------------------------
--    attribute mark_debug : string;

--    attribute mark_debug of header_0                :    signal    is    "true"; --32
--    attribute mark_debug of header_1                :    signal    is    "true"; --32
--    attribute mark_debug of vmmId_i                 :    signal    is    "true"; --3
--    attribute mark_debug of eventCounter_i          :    signal    is    "true"; --32  
--    attribute mark_debug of vmmWord_i               :    signal    is    "true"; --32
--    attribute mark_debug of packLen_i               :    signal    is    "true"; --12    
--    attribute mark_debug of vmm_rd_ena_i           :    signal    is    "true"; --8
--    attribute mark_debug of debug_state             :    signal    is    "true"; --6
--    attribute mark_debug of addRAM_wr_i             :    signal    is    "true"; --12
--    attribute mark_debug of daqRAM_wr_en_i          :    signal    is    "true";
--    attribute mark_debug of pfBusy_i                :    signal    is    "true";
--    attribute mark_debug of end_packet_i            :    signal    is    "true";
--    attribute mark_debug of trg_drv_i               :    signal    is    "true";
--    attribute mark_debug of pf_ready_i              :    signal    is    "true";
--    attribute mark_debug of write_packet_i          :    signal    is    "true";
--    attribute mark_debug of write_trailer_i         :    signal    is    "true";
--    attribute mark_debug of write_zeroes_i          :    signal    is    "true";
--    attribute mark_debug of udp_init_i              :    signal    is    "true";
--    attribute mark_debug of done_and_cycle_i        :    signal    is    "true";
--    attribute mark_debug of new_read_i              :    signal    is    "true";
--    attribute mark_debug of init_read_i             :    signal    is    "true";
--    attribute mark_debug of RAMdone_sync            :    signal    is    "true";
--    attribute mark_debug of got_len_sync            :    signal    is    "true";
--    attribute mark_debug of newCycle_sync           :    signal    is    "true";
--    attribute mark_debug of tr_hold_i               :    signal    is    "true";
--    attribute mark_debug of rst_vmm_i               :    signal    is    "true";
--    attribute mark_debug of resetting_i             :    signal    is    "true";    
    
-----------------------------------------------------------------

begin

packetCaptureProc: process(clk_200, state, reset, newCycle_sync, trigLatencyCnt, vmmId_cnt, write_packet_i, write_trailer_i, 
                           write_zeroes_i, udp_init_i, got_len_sync, wait_Cnt, resetting_i, RAMdone_sync)
begin
-- Upon a signal from trigger capture the current global BCID
    if rising_edge(clk_200) then
        if reset = '1' then
            pfBusy_i            <= '0';
            vmmId_cnt           <= 0;
            tr_hold_i           <= '0';
            done_and_cycle_i    <= '0';
            new_read_i          <= '0';
            trg_drv_i           <= '0';
            pf_ready_i          <= '0';
            addrRAM             <= (others => '0');
            end_packet_i        <= '0';
            daqRAM_wr_en_i      <= '0';
            init_read_i         <= '0';
            vmm_rd_ena_i        <= (others => '0');
            debug_state         <= (others => '0');
            start_cnt_i         <= '0';
            trigger_ila_i       <= '0';
            start_cnt_ram_i     <= '0';
            master_sel          <= (others => '0');
            wait_Cnt            <= 0;
            state               <= waitingForNewCycle;
        else
        case state is
            when waitingForNewCycle =>
                debug_state                 <= "000000";
                trigger_ila_i               <= '0';
                if newCycle_sync = '1' then          -- trigger just arrived
                    pfBusy_i                <= '1';
                    eventCounter_i          <= eventCnt;  -- buffer for eventCnt coming from trigger module
                    daqRAM_wr_en_i          <= '0';
                    start_cnt_i             <= '1';
                    state                   <= waitForLatency;
                else
                    tr_hold_i               <= '0';
                end if;
                
            when waitForLatency =>                          -- wait for 1us
                debug_state                 <= "000001";
                tr_hold_i                   <= '1';                 -- Prevent new triggers
                if trigLatencyCnt > trigLatency then
                    trigLatencyCnt          <= 0; 
                    state                   <= S2;
                else
                    trigLatencyCnt          <= trigLatencyCnt + 1;
                    state                   <= waitForLatency;
                end if;

            when S2 =>          -- trigger driver and wait for the header elements to be formed
                debug_state                 <= "000010";
                trg_drv_i                   <= '1'; 
                tr_hold_i                   <= '1';                          -- Prevent new triggers
                packLenArrayCnt(vmmId_cnt)  <= (others => '0');              -- clear packLen counter of vmm
                state                       <= captureEventID;

            when captureEventID =>          -- Form Header
                debug_state                 <= "000011";
                state                       <= setEventID;
                
            when setEventID =>
                debug_state                 <= "000100";
                daqRAM_wr_en_i              <= '0';
                master_sel                  <= "01"; -- select first part of header
                state                       <= sendHeaderStep1;

                if(vmmId_cnt = 0)then
                    addrRAM <= (others => '0');
                else
                    addrRAM <= addrRAM + 1;
                end if;
                
            when sendHeaderStep1 =>
                debug_state                 <= "000101";
                daqRAM_wr_en_i              <= '1';
                packLenArrayCnt(vmmId_cnt)  <= packLenArrayCnt(vmmId_cnt) + 1; -- header_0 just written in the RAM
                state                       <= sendHeaderStep2;
            
            when sendHeaderStep2 =>
                debug_state                 <= "000110";     
                daqRAM_wr_en_i              <= '0';
                master_sel                  <= "10"; -- select second part of header
                addrRAM                     <= addrRAM + 1;
                state                       <= sendHeaderStep3;
                
            when sendHeaderStep3 =>
                debug_state                 <= "000111";
                daqRAM_wr_en_i              <= '1';
                packLenArrayCnt(vmmId_cnt)  <= packLenArrayCnt(vmmId_cnt) + 1; -- header_1 just written in the RAM
                state                       <= sendHeaderStep4;
             
            when sendHeaderStep4 =>
                debug_state                 <= "001000";
                daqRAM_wr_en_i              <= '0';
                state                       <= cycleVMM_header;

            when cycleVMM_header =>    -- send one of each headers and if finished, start reading VMMs
                debug_state <= "001001";
                if vmmId_cnt >= 7 then
                    vmmId_cnt   <= 0;
                    state       <= waitForDriver;
                else
                    vmmId_cnt   <= vmmId_cnt + 1;
                    state       <= S2;
                end if;

    --------------------------------------------------------------------- 

            when waitForDriver =>
                debug_state             <= "001010";
                pf_ready_i              <= '1';     -- deassert this in each state the conditions below switch to

                if(write_packet_i = '1')then                   
                    daqRAM_wr_en_i      <= '0';
                    master_sel          <= "00"; -- select data
                    addrRAM             <= addrRAM + 1;
                    state               <= assertWord;
                elsif(write_trailer_i = '1')then           
                    daqRAM_wr_en_i      <= '0';
                    master_sel          <= "11";    -- select trailer
                    addrRAM             <= addrRAM + 1;
                    state               <= sendTrailerStep1;
                elsif(write_zeroes_i = '1')then
                    daqRAM_wr_en_i      <= '0';
                    master_sel          <= "00"; -- keep at select data
                    addrRAM             <= addrRAM + 2;     -- jump two addresses to keep ram readout scheme intact
                    state               <= doneSending;
                elsif(udp_init_i   = '1')then
                    state               <= resetAndStartRead;
                else
                    state               <= waitForDriver;
                end if;

    ---------------------------------------------------------------------
            when assertWord =>          
                debug_state                 <= "001011";
                pf_ready_i                  <= '0';
                done_and_cycle_i            <= '0';
                new_read_i                  <= '0';

                if wait_Cnt < 4 then       -- wait for the buses to be switched
                    wait_Cnt    <= wait_Cnt + 1;
                    state       <= assertWord;
                else
                    wait_Cnt    <= 0;
                    state       <= readEnable0;
                end if;
           
            when readEnable0 =>
                debug_state                 <= "001100";
                vmm_rd_ena_i(vmmId_cnt)     <= '1';       -- pass the first 32-bit chunk into the bus
                state                       <= readEnable1;
                
            when readEnable1 =>
                debug_state                 <= "001101";
                vmm_rd_ena_i(vmmId_cnt)     <= '0';
                state                       <= delayWrite0;
                                                                                       
            when delayWrite0 =>                          
                debug_state                 <= "001110";

                if wait_Cnt < 4 then       -- wait for the word to be asserted
                    wait_Cnt    <= wait_Cnt + 1;
                    state       <= delayWrite0;
                else
                    wait_Cnt    <= 0;
                    state       <= readSendDataStep1;
                end if;
                
            when readSendDataStep1 =>
                debug_state                 <= "001111";                
                daqRAM_wr_en_i              <= '1';
                packLenArrayCnt(vmmId_cnt)  <= packLenArrayCnt(vmmId_cnt) + 1; -- word_0 just written in the RAM
                state                       <= readSendDataStep2;

            when readSendDataStep2 =>
                debug_state                 <= "010000";               
                daqRAM_wr_en_i              <= '0';
                state                       <= readSendDataStep3;

            when readSendDataStep3 =>
                debug_state                 <= "010001";
                addrRAM                     <= addrRAM + 1;
                state                       <= readEnable2;
           
            when readEnable2 =>
                debug_state                 <= "001100";           
                vmm_rd_ena_i(vmmId_cnt)     <= '1';       -- pass the second 32-bit chunk into the bus
                state                       <= readEnable3;

            when readEnable3 =>
                debug_state                 <= "010010";
                vmm_rd_ena_i(vmmId_cnt)     <= '0';      
                state                       <= delayWrite1;
          
            when delayWrite1 =>                 -- wait for the word to be asserted
                debug_state                 <= "010100";

                if wait_Cnt < 4 then
                   wait_Cnt     <= wait_Cnt + 1;
                   state        <= delayWrite1;
                else
                   wait_Cnt     <= 0;
                   state        <= readSendDataStep4;
                end if;    
           
            when readSendDataStep4 =>
                debug_state                 <= "010101";
                daqRAM_wr_en_i              <= '1';
                packLenArrayCnt(vmmId_cnt)  <= packLenArrayCnt(vmmId_cnt) + 1; -- word_1 just written in the RAM
                state                       <= readSendDataStep5;

            when readSendDataStep5 =>
                debug_state                 <= "010110";
                daqRAM_wr_en_i              <= '0';
                state                       <= doneSending;

    ---------------------------------------------------------------------

             when sendTrailerStep1 =>
                debug_state                     <= "010111";
                pf_ready_i                      <= '0';
                done_and_cycle_i                <= '0';
                new_read_i                      <= '0';
                daqRAM_wr_en_i                  <= '1';
                packLenArrayCnt(vmmId_cnt)      <= packLenArrayCnt(vmmId_cnt) + 1; -- trailer just written in the RAM
                state                           <= sendTrailerStep2;
                
            when sendTrailerStep2 =>
                debug_state                     <= "011000";
                daqRAM_wr_en_i                  <= '0';                               
                state                           <= sendTrailerStep3;

            when sendTrailerStep3 =>
                debug_state                     <= "011001";
                addrRAM                         <= addrRAM + 1; -- jump one address to keep ram readout scheme intact
                state                           <= sendTrailerStep4;

            when sendTrailerStep4 =>
                debug_state                     <= "011010";
                packLen_i                       <= std_logic_vector(packLenArrayCnt(vmmId_cnt));
                state                           <= packetDone;

            when packetDone =>                  -- Wait for RAM2UDP to get synced
                debug_state         <= "011011";
                
                if(got_len_sync = '1')then                    
                    end_packet_i    <= '0';
                    state           <= doneSending;
                else
                    end_packet_i    <= '1';
                    state           <= packetDone;
                end if;

    ---------------------------------------------------------------------

            when doneSending =>
                debug_state             <= "011100";
                pf_ready_i              <= '0';
                done_and_cycle_i        <= '0';
                new_read_i              <= '0';
                wait_Cnt                <= 0;

                if vmmId_cnt >= 7 then
                    vmmId_cnt       <= 0;
                    state           <= assertNewRead; -- assert the new_cycle sig
                else
                    vmmId_cnt       <= vmmId_cnt + 1;
                    state           <= assertDoneCycle; -- assert the done_and_cycle sig
                end if;
                
            when assertDoneCycle =>
                debug_state             <= "011101";
                done_and_cycle_i        <= '1';
                state                   <= waitForDriver;
                
            when assertNewRead =>
                debug_state             <= "011110";
                new_read_i              <= '1';
                state                   <= waitForDriver;     

    ---------------------------------------------------------------------

            when resetAndStartRead =>
                debug_state         <= "011111";
                trg_drv_i           <= '0';
                end_packet_i        <= '0';
                start_cnt_ram_i     <= '1';
                rst_vmm_i           <= '1';
                state               <= resetDone;
                
            when resetDone =>
                debug_state         <= "100000";
                if resetting_i = '0' then
                    rst_vmm_i       <= '0';      -- Prevent from continuously resetting while waiting for UDP Packet
                    state           <= assertInitRead;
                end if;

            when assertInitRead =>
                debug_state             <= "100001";
                if(RAMdone_sync = '1')then -- ram2udp is on idle, assert init_read
                    init_read_i         <= '1';
                    state               <= waitToLatch;
                else
                    init_read_i         <= '0';
                    state               <= assertInitRead;
                end if;

            when waitToLatch =>
                debug_state             <= "100010";
                if(RAMDone_sync = '0')then   -- ram2udp got the message, move on and wait
                    init_read_i         <= '0';
                    state               <= isUDPDone;
                else
                    init_read_i         <= '1';
                    state               <= waitToLatch;
                end if;

            when isUDPDone =>
                debug_state         <= "100011";
                pfBusy_i            <= '0';                
                if(RAMdone_sync = '1')then -- Wait for all 8 UDP packets to be sent
                    state       <= isTriggerOff;
                else
                    state       <= isUDPDone;
                end if;
                
            when isTriggerOff =>            -- Wait for whatever ongoing trigger pulse to go to 0
                debug_state         <= "100100";
                trigger_ila_i       <= '1';
                start_cnt_i         <= '0';
                start_cnt_ram_i     <= '0';
                tr_hold_i           <= '0';     -- Allow new triggers
                if newCycle_sync /= '1' then
                    state           <= waitingForNewCycle;
                end if;

           when others =>
                state           <= waitingForNewCycle;
        end case;
    end if;
end if;
end process;

    trigLatency     <= to_integer(unsigned(latency));
    globBCID_etr    <= glBCID;
    vmmId_i         <= std_logic_vector(to_unsigned(vmmId_cnt, 3)); -- update vmmId for driver
    vmmId           <= vmmId_i;
    pfBusy          <= pfBusy_i;
    resetting_i     <= resetting;
    rst_vmm         <= rst_vmm_i;
    tr_hold         <= tr_hold_i;

    write_packet_i  <= write_packet;
    write_trailer_i <= write_trailer;
    write_zeroes_i  <= write_zeroes;
    udp_init_i      <= udp_init;
    
    done_and_cycle  <= done_and_cycle_i;
    new_read        <= new_read_i;
    trg_drv         <= trg_drv_i;
    pf_ready        <= pf_ready_i;

    addRAM_wr_i     <= std_logic_vector(addrRAM);
    addrRAM_wr      <= addRAM_wr_i;
    packLen         <= packLen_i;
    end_packet      <= end_packet_i;
    wrenable        <= daqRAM_wr_en_i;
    init_read       <= init_read_i;

    vmm_rd_ena      <= vmm_rd_ena_i;
    pf_state_ila    <= debug_state;

    start_cnt       <= start_cnt_i;
    trigger_ila     <= trigger_ila_i;
    start_cnt_ram   <= start_cnt_ram_i;

master_mux: dout_mux
  Port map(
    header_0_mux        => header_0,
    header_1_mux        => header_1,
    vmmWord_0_mux       => fifo_bus_vmm0,
    vmmWord_1_mux       => fifo_bus_vmm1,
    vmmWord_2_mux       => fifo_bus_vmm2,
    vmmWord_3_mux       => fifo_bus_vmm3,
    vmmWord_4_mux       => fifo_bus_vmm4,
    vmmWord_5_mux       => fifo_bus_vmm5,
    vmmWord_6_mux       => fifo_bus_vmm6,
    vmmWord_7_mux       => fifo_bus_vmm7,
    trailer_mux         => trailer,
    vmmId_cnt_mux       => vmmId_i,
    master_sel_mux      => master_sel,
    data_out_mux        => dataout
    );
    
   header_0(31 downto 0)       <= eventCounter_i;
   header_1(31 downto 0)       <= precCnt & globBcid & "00000" & vmmId_i;
   
------------------- SYNC BLOCK --------------------------
-- sync signals that belong to different clock domains --
---------------------------------------------------------
RAMdoneSync: process(clk_200, RAMdone)
begin
    if(rising_edge(clk_200))then
        RAMdone_sync <= RAMdone;
    end if;
end process;
 
gotLenSync: process(clk_200, got_len)
begin
    if(rising_edge(clk_200))then
        got_len_sync <= got_len;
    end if;
end process;
   
newCycleSync: process(clk_200, newCycle)
begin
    if(rising_edge(clk_200))then
        newCycle_sync <= newCycle;
    end if;
end process;
---------------------------------------------------------

    --pf_debugger: ila_pf
--PORT MAP (
--    clk    => clk_200,
--    probe0 => debug_probe
--);

    --debug_probe(31 downto 0)        <= header_0;
    --debug_probe(63 downto 32)       <= header_1; 
    --debug_probe(66 downto 64)       <= vmmId_i;
    --debug_probe(98 downto 67)       <= eventCounter_i;
    --debug_probe(130 downto 99)      <= (others => '0');
    --debug_probe(162 downto 131)     <= vmmWord_i;
    --debug_probe(174 downto 163)     <= packLen_i;
    --debug_probe(182 downto 175)     <= vmm_rd_ena_i;
    --debug_probe(188 downto 183)     <= debug_state;
    --debug_probe(200 downto 189)     <= addRAM_wr_i;
    --debug_probe(201)                <= daqRAM_wr_en_i;
    --debug_probe(202)                <= '0';
    --debug_probe(203)                <= pfBusy_i;
    --debug_probe(204)                <= end_packet_i;
    --debug_probe(205)                <= trg_drv_i;
    --debug_probe(206)                <= pf_ready_i;
    --debug_probe(207)                <= write_packet_i;
    --debug_probe(208)                <= write_trailer_i;
    --debug_probe(209)                <= write_zeroes_i;
    --debug_probe(210)                <= udp_init_i;
    --debug_probe(211)                <= done_and_cycle_i;
    --debug_probe(212)                <= new_read_i;
    --debug_probe(213)                <= init_read_i;
    --debug_probe(214)                <= RAMdone_sync;
    --debug_probe(215)                <= got_len_sync;
    --debug_probe(216)                <= newCycle_sync;
    --debug_probe(217)                <= tr_hold_i;
    --debug_probe(218)                <= rst_vmm_i;
    --debug_probe(219)                <= resetting_i;
    --debug_probe(223 downto 220)     <= (others => '0');

end Behavioral;
