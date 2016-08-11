----------------------------------------------------------------------------------
-- Company: NTU ATHNENS - BNL
-- Engineer: Paris Moschovakos
-- 
-- Create Date: 18.04.2016 13:00:21
-- Design Name: 
-- Module Name: packet_formation.vhd - Behavioral
-- Project Name: MMFE8 
-- Target Devices: Arix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 1.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity packet_formation is
    Port(
        clk_200     : in std_logic;

        newCycle    : in std_logic;
        eventCounter: in std_logic_vector(31 downto 0);
        
        trigVmmRo   : out std_logic;
        vmmWord     : in std_logic_vector(63 downto 0);
        vmmWordReady: in std_logic;
        vmmEventDone: in std_logic;

        packLen     : out integer;
        dataout     : out std_logic_vector(63 downto 0);
        wrenable    : out std_logic;
        end_packet  : out std_logic;
        udp_busy    : in std_logic;
        
        tr_hold     : out std_logic
    );
end packet_formation;

architecture Behavioral of packet_formation is

    signal header           : std_logic_vector(63 downto 0) := ( others => '0' );
    signal vmmId            : std_logic_vector(7 downto 0)  := x"01"; --( others => '0' );
    signal globBcid         : std_logic_vector(15 downto 0) := x"FFFF"; --( others => '0' );
    signal globBcid_i       : std_logic_vector(15 downto 0);
    signal precCnt          : std_logic_vector(7 downto 0)  := x"00"; --( others => '0' );
    signal eventCounter_i   : std_logic_vector(31 downto 0) := ( others => '0' );
    signal wait_Cnt         : integer := 0;
    signal packetCounter    : integer := 0;

    signal daqFIFO_wr_en        : std_logic                     := '0';
    signal daqFIFO_wr_en_i      : std_logic                     := '0';
    signal daqFIFO_din          : std_logic_vector(63 downto 0) := ( others => '0' );
    signal daqFIFO_din_i        : std_logic_vector(63 downto 0) := ( others => '0' );
    signal triggerVmmReadout_i  : std_logic := '0';

    signal vmmWord_i        : std_logic_vector(63 downto 0) := ( others => '0' );
    signal packLen_i        : integer                       := 0;
    signal packLen_cnt      : integer                       := 0;
    signal end_packet_int   : std_logic                     := '0';

    type stateType is (waitingForNewCycle, S2, captureEventID, setEventID, sendHeaderStep1, sendHeaderStep2, triggerVmmReadout,
                       waitForData, sendVmmDataStep1, sendVmmDataStep2, formTrailer, sendTrailer, packetDone, isTriggerOff);
    signal state            : stateType;
    
-----------------------------------------------------------------

begin

packetCaptureProc: process(clk_200, newCycle, vmmEventDone)
begin
-- Upon a signal from trigger capture the current global BCID
    if rising_edge(clk_200) then
        case state is

            when waitingForNewCycle =>
                triggerVmmReadout_i     <= '0';
                if newCycle = '1' then
                    tr_hold         <= '1'; -- Prevent new triggers
                    daqFIFO_wr_en   <= '0';
                    packLen_cnt     <= 0;
                    packetCounter   <= packetCounter + 1;   -- Signal to count packets for debugging
                    state           <= S2;
                else
                    tr_hold         <= '0';
                end if;

            when S2 =>  -- wait for the header elements to be formed
                state           <= captureEventID;

            when captureEventID =>      -- Form Header
                header(63 downto 0)     <=    eventCounter & precCnt & globBcid & vmmId;
                                        --         32      &    8    &    16    &  8
                state                   <= setEventID;
                
            when setEventID =>
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
                if wait_Cnt /= 25 then
                    wait_Cnt                <= wait_cnt + 1;
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
                    daqFIFO_din     <= x"FFFFFFFF" & std_logic_vector(to_unsigned(packetCounter, 16)) & x"FF" & std_logic_vector(to_unsigned(packLen_cnt, 8)); -- 8 bit
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
                    daqFIFO_din     <= x"FFFFFFFF" & std_logic_vector(to_unsigned(packetCounter, 16)) & x"FF" & std_logic_vector(to_unsigned(packLen_cnt, 8)); -- 8 bit
                    state           <= sendTrailer;
                elsif (vmmEventDone = '0' and vmmWordReady = '0') then  
                    state       <= waitForData;
                else -- (vmmWordReady = '1') then
                    state       <= formTrailer;
                end if;

            when sendTrailer =>
                if udp_busy /= '1' then
                    daqFIFO_wr_en   <= '0';
                    packLen_i       <= packLen_cnt;
                    state           <= packetDone;
                end if;
                
            when packetDone =>                  -- Wait for FIFO2UDP
                if wait_Cnt /= 10 then
                    wait_Cnt        <= wait_cnt + 1;
                    end_packet_int  <= '1';
                    daqFIFO_wr_en   <= '0';
                else
                    wait_Cnt        <= 0;
                    state           <= isTriggerOff;
                end if;
                
            when isTriggerOff =>            -- Wait for whatever ongoing trigger pulse to go to 0
                end_packet_int  <= '0';
                tr_hold         <= '0';     -- Allow new triggers
                if newCycle /= '1' then
                    state           <= waitingForNewCycle;
                end if;

            when others =>
                state           <= waitingForNewCycle;
        end case;
    end if;

end process;

    eventCounter_i  <= eventCounter;
    globBcid_i      <= globBcid;
    daqFIFO_wr_en_i <= daqFIFO_wr_en;
    vmmWord_i       <= vmmWord;
    dataout         <= daqFIFO_din;
    wrenable        <= daqFIFO_wr_en_i;
    packLen         <= packLen_i;
    end_packet      <= end_packet_int;
    trigVmmRo       <= triggerVmmReadout_i;

end Behavioral;