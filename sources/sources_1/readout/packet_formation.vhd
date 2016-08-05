----------------------------------------------------------------------------------
-- Company: NTU ATHENS - BNL
-- Engineer: Paris Moschovakos
-- 
-- Create Date: 25.06.2016
-- Design Name: 
-- Module Name: packet_formation.vhd - Behavioral
-- Project Name: MMFE8 
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
--
-- Changelog:
-- 25.07.2016 Added DAQ FIFO reset every vmm packet sent
-- 
----------------------------------------------------------------------------------

library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;

entity packet_formation is
    Port(
        clk_200     : in std_logic;

        newCycle    : in std_logic;
        
        trigVmmRo   : out std_logic;
        vmmId       : out std_logic_vector(2 downto 0);
        vmmWord     : in std_logic_vector(63 downto 0);
        vmmWordReady: in std_logic;
        vmmEventDone: in std_logic;

        UDPDone     : in std_logic;

        packLen     : out std_logic_vector(11 downto 0);
        dataout     : out std_logic_vector(63 downto 0);
        wrenable    : out std_logic;
        end_packet  : out std_logic;
        udp_busy    : in std_logic;
        
        tr_hold     : out std_logic;
        reset       : in std_logic;
        rst_vmm     : out std_logic;
        resetting   : in std_logic;
        rst_FIFO    : out std_logic;
        
        latency     : in std_logic_vector(15 downto 0)
    );
end packet_formation;

architecture Behavioral of packet_formation is

    signal header           : std_logic_vector(63 downto 0) := ( others => '0' );
    signal vmmId_i          : std_logic_vector(2 downto 0)  := b"000";
    signal globBcid         : std_logic_vector(15 downto 0) := x"FFFF"; --( others => '0' );
    signal precCnt          : std_logic_vector(7 downto 0)  := x"00"; --( others => '0' );
    signal globBcid_i       : std_logic_vector(15 downto 0);
    signal eventCounter_i   : std_logic_vector(31 downto 0) := ( others => '0' );
    signal wait_Cnt         : integer := 0;
--    signal packetCounter    : integer := 0;
    signal vmmId_cnt        : integer := 0;
    signal trigLatencyCnt   : integer := 0;
    signal trigLatency      : integer := 140; -- 700ns (140x5ns)

    signal daqFIFO_wr_en        : std_logic                     := '0';
    signal daqFIFO_wr_en_i      : std_logic                     := '0';
    signal daqFIFO_din          : std_logic_vector(63 downto 0) := ( others => '0' );
    signal daqFIFO_din_i        : std_logic_vector(63 downto 0) := ( others => '0' );
    signal triggerVmmReadout_i  : std_logic := '0';

    signal vmmWord_i        : std_logic_vector(63 downto 0) := ( others => '0' );
    signal packLen_i        : std_logic_vector(11 downto 0) := x"000";
    signal packLen_cnt      : unsigned(11 downto 0) := x"000";
    signal end_packet_int   : std_logic                     := '0';

    type stateType is (waitingForNewCycle, S2, waitForLatency, captureEventID, setEventID, sendHeaderStep1, sendHeaderStep2, triggerVmmReadout, waitForData, 
                       sendVmmDataStep1, sendVmmDataStep2, formTrailer, sendTrailer, packetDone, eventDone, resetVMMs, resetDone, isUDPDone, isTriggerOff);
    signal state            : stateType;

--------------------  Debugging ------------------------------
    signal probe0_out           : std_logic_vector(129 DOWNTO 0);
    signal probe1_out           : std_logic_vector(142 downto 0);
-----------------------------------------------------------------

----------------------  Debugging ------------------------------
    attribute mark_debug : string;

    attribute mark_debug of header                :    signal    is    "true";
    attribute mark_debug of globBcid              :    signal    is    "true";
    attribute mark_debug of globBcid_i            :    signal    is    "true";
    attribute mark_debug of precCnt               :    signal    is    "true";
    attribute mark_debug of vmmId_i               :    signal    is    "true";
    attribute mark_debug of daqFIFO_din           :    signal    is    "true";
    attribute mark_debug of vmmWord_i             :    signal    is    "true";
    attribute mark_debug of packLen_i             :    signal    is    "true";
    attribute mark_debug of packLen_cnt           :    signal    is    "true";
    attribute mark_debug of end_packet_int        :    signal    is    "true";
    attribute mark_debug of triggerVmmReadout_i   :    signal    is    "true";
    
    attribute dont_touch : string;

    attribute dont_touch of header                :    signal    is    "true";
    attribute dont_touch of globBcid              :    signal    is    "true";
    attribute dont_touch of globBcid_i            :    signal    is    "true";
    attribute dont_touch of precCnt               :    signal    is    "true";
    attribute dont_touch of vmmId_i               :    signal    is    "true";
    attribute dont_touch of daqFIFO_din           :    signal    is    "true";
    attribute dont_touch of vmmWord_i             :    signal    is    "true";
    attribute dont_touch of packLen_i             :    signal    is    "true";
    attribute dont_touch of packLen_cnt           :    signal    is    "true";
    attribute dont_touch of end_packet_int        :    signal    is    "true";
    attribute dont_touch of triggerVmmReadout_i   :    signal    is    "true";
    
    attribute keep : string;

    attribute keep of header                :	signal	is	"true";
    attribute keep of globBcid              :	signal	is	"true";
    attribute keep of globBcid_i            :	signal	is	"true";
    attribute keep of precCnt               :	signal	is	"true";
    attribute keep of vmmId_i               :	signal	is	"true";
    attribute keep of daqFIFO_din           :   signal  is  "true";
    attribute keep of vmmWord_i             :   signal  is  "true";
    attribute keep of packLen_i             :   signal  is  "true";
    attribute keep of packLen_cnt           :   signal  is  "true";
    attribute keep of end_packet_int        :   signal  is  "true";
    attribute keep of triggerVmmReadout_i   :   signal  is  "true";


    component ila_pf
    port(
        clk     : IN STD_LOGIC;
        probe0  : IN STD_LOGIC_VECTOR(129 DOWNTO 0);
        probe1  : IN STD_LOGIC_VECTOR(142 downto 0)
    );
    end component;

-----------------------------------------------------------------

begin

packetCaptureProc: process(clk_200, newCycle, vmmEventDone)
begin
-- Upon a signal from trigger capture the current global BCID
    if rising_edge(clk_200) then
        if reset = '1' then
            eventCounter_i <= x"00000000";
        else
        case state is
            when waitingForNewCycle =>
                triggerVmmReadout_i     <= '0';
                trigLatencyCnt          <= 0;
                rst_FIFO                <= '0';
                if newCycle = '1' then
                    eventCounter_i  <= eventCounter_i + 1;
                    daqFIFO_wr_en   <= '0';
                    state           <= S2;
                else
                    tr_hold         <= '0';
                end if;
                
            when waitForLatency =>
                tr_hold         <= '1';                 -- Prevent new triggers
                if trigLatencyCnt > trigLatency then 
                    state           <= S2;
                else
                    trigLatencyCnt  <= trigLatencyCnt + 1;
                end if;

            when S2 =>          -- wait for the header elements to be formed
                tr_hold         <= '1';                 -- Prevent new triggers
                packLen_cnt     <= x"000";
                vmmId_i         <= std_logic_vector(to_unsigned(vmmId_cnt, 3));
                state           <= captureEventID;

            when captureEventID =>      -- Form Header
                rst_FIFO                <= '0';
                header(63 downto 0)     <=    eventCounter_i & precCnt & globBcid & b"00000" & vmmId_i;
                                        --          32       &    8    &    16    &     5    &   3
                state                   <= setEventID;
                
            when setEventID =>
                rst_FIFO                <= '0';
                daqFIFO_wr_en           <= '0';
                daqFIFO_din             <= header;
                state                   <= sendHeaderStep1;

            when sendHeaderStep1 =>
                daqFIFO_wr_en   <= '1';
                packLen_cnt     <= packLen_cnt + 1;
                state           <= sendHeaderStep2;

            when sendHeaderStep2 =>
                daqFIFO_wr_en   <= '0';
                state           <= triggerVmmReadout;

            when triggerVmmReadout =>   -- Creates an 125ns pulse to trigger the readout
                if wait_Cnt < 25 then
                    wait_Cnt                <= wait_Cnt + 1;
                    triggerVmmReadout_i     <= '1';
                else
                    triggerVmmReadout_i     <= '0';
                    wait_Cnt    <= 0;
                    state       <= waitForData;
                end if;

            when waitForData =>
                if vmmWordReady = '1' then
                    daqFIFO_din     <= vmmWord_i;
                    daqFIFO_wr_en   <= '0';
                    state           <= sendVmmDataStep1;
                elsif vmmEventDone = '1' then
                    daqFIFO_wr_en   <= '0';
                    state           <= sendTrailer; 
                end if;

            when sendVmmDataStep1 =>
                daqFIFO_wr_en   <= '1';
                packLen_cnt     <= packLen_cnt + 1;
                state           <= sendVmmDataStep2;

            when sendVmmDataStep2 =>
                daqFIFO_wr_en   <= '0';
                state           <= formTrailer;

            when formTrailer =>
                if (vmmEventDone = '1') then
                    daqFIFO_wr_en   <= '0';
                    state           <= sendTrailer;
                elsif (vmmEventDone = '0' and vmmWordReady = '0') then  
                    state       <= waitForData;
                else -- (vmmWordReady = '1') then
                    state       <= formTrailer;
                end if;

            when sendTrailer =>
                packLen_i       <= std_logic_vector(packLen_cnt);
                daqFIFO_wr_en   <= '0';
                wait_Cnt        <= 0;
                state           <= packetDone;

            when packetDone =>                  -- Wait for FIFO2UDP to get synced
                if wait_Cnt < 2 then
                    wait_Cnt        <= wait_Cnt + 1;
                    end_packet_int  <= '1';
                    daqFIFO_wr_en   <= '0';
                else
                    wait_Cnt        <= 0;
                    end_packet_int  <= '0';
                    state           <= eventDone;
                end if;

            when eventDone =>
                if vmmId_cnt >= 7 then
                    vmmId_cnt   <= 0;
                    state       <= resetVMMs;
                else
                    vmmId_cnt   <= vmmId_cnt + 1;
                    state       <= S2;
                end if;
                
            when resetVMMs =>
                rst_vmm     <= '1';
                state       <= resetDone;
                
            when resetDone =>
                if resetting = '0' then
                    state       <= isUDPDone;
                end if;

            when isUDPDone =>
                if (UDPDone = '1') then -- Wait for all 8 UDP packets to be sent
                    state       <= isTriggerOff;
                else
                    state       <= isUDPDone;
                end if;
                
            when isTriggerOff =>            -- Wait for whatever ongoing trigger pulse to go to 0
                end_packet_int  <= '0';
                tr_hold         <= '0';     -- Allow new triggers
                rst_vmm         <= '0';
                if newCycle /= '1' then
                    state           <= waitingForNewCycle;
                end if;

            when others =>
                state           <= waitingForNewCycle;
        end case;
    end if;
end if;
end process;

    globBcid_i      <= globBcid;
    daqFIFO_wr_en_i <= daqFIFO_wr_en;
    vmmWord_i       <= vmmWord;
    dataout         <= daqFIFO_din;
    wrenable        <= daqFIFO_wr_en_i;
    packLen         <= packLen_i;
    end_packet      <= end_packet_int;
    trigVmmRo       <= triggerVmmReadout_i;
    vmmId           <= vmmId_i;
    trigLatency     <= to_integer(unsigned(latency));

ilaPacketFormation: ila_pf
port map(
    clk                     =>  clk_200,
    probe0                  =>  probe0_out,
    probe1                  =>  probe1_out
);

    probe0_out(63 downto 0)             <=  header;             -- OK
    probe0_out(127 downto 64)           <=  vmmWord_i;          -- OK
    probe0_out(129 downto 128)          <= (others => '0');

    probe1_out(63 downto 0)             <=  daqFIFO_din;        -- OK
    probe1_out(64)                      <=  vmmWordReady;       -- OK
    probe1_out(65)                      <=  vmmEventDone;       -- OK
    probe1_out(66)                      <=  daqFIFO_wr_en_i;    -- OK
    probe1_out(67)                      <=  newCycle;           -- OK
    probe1_out(79 downto 68)            <=  packLen_i;
    probe1_out(91 downto 80)            <=  std_logic_vector(packLen_cnt);
    probe1_out(92)                      <=  end_packet_int;        -- Not tested
    probe1_out(93)                      <=  triggerVmmReadout_i;    --Not tested
    probe1_out(109 downto 94)           <=  latency;
    probe1_out(110)                     <=  udp_busy;
    probe1_out(142 downto 111)                <= eventCounter_i;
--    probe1_out(129 downto 111)          <=  (others => '0');

end Behavioral;