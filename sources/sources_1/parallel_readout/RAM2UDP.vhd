----------------------------------------------------------------------------------
-- Company:  NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Create Date: 09/30/2016 10:33:01 AM
-- Design Name: 
-- Module Name: RAM2UDP - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;

entity RAM2UDP is
  Port (
    --------- general interface -------------------
    -----------------------------------------------
    clk_200                 : in std_logic;
    clk_125                 : in std_logic;
    rst_ram2udp             : in std_logic;
    ---------- pf interface -----------------------
    -----------------------------------------------
    RAMdone                 : out  std_logic;
    VmmId                   : in   std_logic_vector(2 downto 0);  
    dataIn                  : in   std_logic_vector(31 downto 0); 
    addrRAM_wr              : in   std_logic_vector(11 downto 0);
    packLen                 : in   std_logic_vector(11 downto 0); 
    end_packet              : in   std_logic;
    wrenable                : in   std_logic;
    pf_ready                : in   std_logic;
    init_read               : in   std_logic;
    got_len                 : out  std_logic;
    ----------- mux2udp interface ----------------
    ----------------------------------------------
    udp_tx_start            : out std_logic;
    data_length_o           : out std_logic_vector(15 downto 0);
    data_out_last_o         : out std_logic;
    data_out_valid_o        : out std_logic;
    data_out_o              : out std_logic_vector(7 downto 0);
    udp_tx_data_out_ready   : in  std_logic;
    ------------ ila interface -------------------
    ----------------------------------------------
    ram_state_ila           : out std_logic_vector(3 downto 0)
    );
end RAM2UDP;

architecture Behavioral of RAM2UDP is

COMPONENT data_ram
  PORT (
    clka    : IN STD_LOGIC;
    wea     : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra   : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dina    : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

    clkb    : IN STD_LOGIC;
    rstb    : IN STD_LOGIC;
    enb     : IN STD_LOGIC;
    addrb   : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    doutb   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;

--COMPONENT ila_ram

--PORT (
--    clk    : IN STD_LOGIC;
--    probe0 : IN STD_LOGIC_VECTOR(101 DOWNTO 0)
--);
--END COMPONENT;

    signal wr_en            : std_logic_vector(0 downto 0)  := (others => '0');
    signal rd_en            : std_logic := '0';
    signal addra_sig        : std_logic_vector(11 downto 0) := (others => '0');
    signal addrb_cnt        : unsigned(13 downto 0) := (others => '0');
    signal addrb_sig        : std_logic_vector(13 downto 0) := (others => '0');
    signal ram_din          : std_logic_vector(31 downto 0) := (others => '0');
    signal din_rev          : std_logic_vector(31 downto 0) := (others => '0');
    signal tx_start         : std_logic := '0';
    signal pack_cnt         : unsigned(11 downto 0) := (others => '0');
    signal byte_cnt         : unsigned(3 downto 0) := (others => '0');
    signal vmmId_int        : integer   := 0;
    signal wait_Cnt         : integer   := 0;
    signal last             : std_logic := '0';
    signal RAMdone_i        : std_logic := '0';
    signal valid            : std_logic := '0';
    signal tx_ready         : std_logic := '0'; 
    signal vmmRo_cnt        : integer   := 0;
    signal got_len_i        : std_logic := '0';
    signal packLen_sync     : std_logic_vector(11 downto 0) := (others => '0');
    signal VmmId_sync       : std_logic_vector(2 downto 0)  := (others => '0');
    signal end_packet_sync  : std_logic := '0';
    signal init_read_sync   : std_logic := '0';
    signal pf_ready_sync    : std_logic := '0';
    signal doutb_i          : std_logic_vector(7 downto 0) := (others => '0');
    signal valid_delay0     : std_logic := '0';
    signal last_delay0      : std_logic := '0';
    
    
    
    signal packLen_sync_usg : unsigned(11 downto 0)        := (others => '0');
    signal packLen_usg_UDP  : unsigned(15 downto 0)        := (others => '0');
      
    -----------------------------

    type    stateType is (IDLE, STORE_PACKLEN, IS_PF_READY, SET_LEN, SET_ADDRB, START_TX, CHECK_READY, READ_DATA, PACKET_DONE, INCR_VMM, DELAY, DONE_READING);
    signal  state : stateType := IDLE;    
    ---------------------------------------------------------
    type    vector_matrix_12 is array (integer range 0 to 7) of unsigned(11 downto 0);
    type    vector_matrix_16 is array (integer range 0 to 7) of unsigned(15 downto 0); 
    signal  lenForUDP               : vector_matrix_16;
    signal  lenForPackCnt           : vector_matrix_12;
    ---------------------------------------------------------
    
    ---------------------------------------------------------
    
--    signal debug_probe          : std_logic_vector(101 downto 0) := (others => '0');
    signal debug_state          : std_logic_vector(3 downto 0)   := (others => '0');
    
    attribute mark_debug    : string;
    
--    attribute mark_debug of wr_en               :    signal    is    "true";
--    attribute mark_debug of rd_en               :    signal    is    "true";
--    attribute mark_debug of addra_sig           :    signal    is    "true"; --12
--  --  attribute mark_debug of addrb_sig           :    signal    is    "true"; --14 -- DONT DEBUG
--    attribute mark_debug of ram_din             :    signal    is    "true"; --32
--    attribute mark_debug of tx_start            :    signal    is    "true";
--    attribute mark_debug of last                :    signal    is    "true";
--    attribute mark_debug of RAMdone_i           :    signal    is    "true";
--    attribute mark_debug of valid               :    signal    is    "true";
--    attribute mark_debug of tx_ready            :    signal    is    "true";
--    attribute mark_debug of rst_i               :    signal    is    "true";
--    attribute mark_debug of doutb_i             :    signal    is    "true"; --8
--    attribute mark_debug of got_len_i           :    signal    is    "true";
--    attribute mark_debug of packLen_sync        :    signal    is    "true"; --12
--    attribute mark_debug of VmmId_sync          :    signal    is    "true"; --3
--    attribute mark_debug of end_packet_sync     :    signal    is    "true";
--    attribute mark_debug of init_read_sync      :    signal    is    "true";
--    attribute mark_debug of pf_ready_sync       :    signal    is    "true";
--    attribute mark_debug of debug_state         :    signal    is    "true"; --4

            
    ---------------------------------------------------------

begin

RAMaddrFSM: process(clk_125, rst_ram2udp, state, end_packet_sync, init_read_sync, pf_ready_sync, tx_ready, byte_cnt, pack_cnt, vmmRo_cnt)
begin
    if(rising_edge(clk_125))then
        if(rst_ram2udp = '1')then
           debug_state  <= "0000";
           rd_en        <= '0';
           addrb_cnt    <= (others => '0');
           tx_start     <= '0';
           byte_cnt     <= (others => '0');
           wait_Cnt     <= 0;
           last         <= '0';
           RAMdone_i    <= '0';
           valid        <= '0';
           vmmRo_cnt    <= 0;
           got_len_i    <= '0';
           state        <= IDLE;
        else
            case state is
            when IDLE =>
                debug_state     <= "0001";
                RAMdone_i       <= '1';

                if(end_packet_sync = '1')then
                    state           <= STORE_PACKLEN;
                elsif(init_read_sync = '1')then
                    state           <= SET_LEN;
                else
                    state           <= IDLE;
                end if;

            when STORE_PACKLEN =>
                debug_state                 <= "0010";
                RAMdone_i                   <= '0';
                lenForUDP(vmmId_int)        <= packLen_usg_UDP;      -- store std_logic_vector to send to udp block
                lenForPackCnt(vmmId_int)    <= packLen_sync_usg;     -- store integer to use for packet counter
                got_len_i                   <= '1';
                state                       <= IS_PF_READY;

            when IS_PF_READY =>
                debug_state     <= "0011";    
                if(pf_ready_sync = '1')then
                    got_len_i   <= '0';
                    state       <= IDLE;
                else
                    got_len_i   <= '1';
                    state       <= IS_PF_READY;
                end if;

            when SET_LEN =>
                debug_state         <= "0100";
                RAMdone_i           <= '0';
                pack_cnt            <= lenForPackCnt(vmmRo_cnt);
                addrb_cnt           <= (others => '0');
                state               <= SET_ADDRB;

            when SET_ADDRB =>
                debug_state  <= "0101";
                case vmmRo_cnt is
                when 0 =>   addrb_cnt <= (others => '0');   state <= START_TX;
                when 1 =>   addrb_cnt <= addrb_cnt + 8;     state <= START_TX;  
                when 2 =>   addrb_cnt <= addrb_cnt + 16;    state <= START_TX;  
                when 3 =>   addrb_cnt <= addrb_cnt + 24;    state <= START_TX;
                when 4 =>   addrb_cnt <= addrb_cnt + 32;    state <= START_TX;
                when 5 =>   addrb_cnt <= addrb_cnt + 40;    state <= START_TX;
                when 6 =>   addrb_cnt <= addrb_cnt + 48;    state <= START_TX;
                when 7 =>   addrb_cnt <= addrb_cnt + 56;    state <= START_TX;
                when others => state <= SET_ADDRB;
                end case;

            when START_TX =>
                debug_state              <= "0110";
                tx_start                 <= '1';
                state                    <= CHECK_READY;   
                
            when CHECK_READY =>
                debug_state  <= "0111";
                if(tx_ready = '1')then
                    tx_start    <= '0';                    
                    rd_en       <= '1';
                    valid       <= '0';                
                    state       <= READ_DATA;
                else
                    state       <= CHECK_READY;
                    tx_start    <= '1';
                end if;                

            when READ_DATA =>
                debug_state  <= "1000";
                if(byte_cnt < 7 and pack_cnt > 1 and tx_ready = '1')then -- normal data read
                    addrb_cnt   <= addrb_cnt + 1;                   
                    valid       <= '1';
                    rd_en       <= '1';
                    last        <= '0';
                    byte_cnt    <= byte_cnt + 1;
                    state       <= READ_DATA;
                elsif(byte_cnt = 7 and pack_cnt > 1 and tx_ready = '1')then                 
                    addrb_cnt   <= addrb_cnt + 57;       -- last byte reached, jump to next packet
                    valid       <= '1';
                    rd_en       <= '1';
                    last        <= '0';
                    byte_cnt    <=  (others => '0');
                    pack_cnt    <= pack_cnt - 2; -- one packet done being read
                    state       <= READ_DATA;
                elsif(byte_cnt < 3 and pack_cnt = 1 and tx_ready = '1')then 
                    addrb_cnt   <= addrb_cnt + 1;   -- trailer packet reached (ff... & 00...)
                    valid       <= '1';
                    rd_en       <= '1';
                    last        <= '0';
                    byte_cnt    <= byte_cnt + 1;
                    state       <= READ_DATA;
                elsif(byte_cnt = 3 and pack_cnt = 1 and tx_ready = '1')then -- read last trailer byte and skip the zeroes
                    valid       <= '1';
                    rd_en       <= '1';
                    last        <= '1';
                    state       <= PACKET_DONE;
                elsif(tx_ready = '0')then
                    state       <= CHECK_READY;
                else
                    valid       <= '0';
                    rd_en       <= '0';
                    last        <= '0';
                    byte_cnt    <= (others => '0');
                    state       <= READ_DATA; 
                end if;

            when PACKET_DONE =>
                debug_state <= "1001";
                addrb_cnt   <= (others => '0');
                valid       <= '0';
                rd_en       <= '0';
                last        <= '0';
                byte_cnt    <= (others => '0');
                state       <= INCR_VMM;

            when INCR_VMM =>
                debug_state  <= "1010";
                case vmmRo_cnt is
                when 0 to 6 =>
                   vmmRo_cnt    <= vmmRo_cnt + 1;
                   state        <= SET_LEN;         -- state <= SET_LEN if skip DELAY
                when 7 =>
                   vmmRo_cnt   <= 0;
                   state       <= DONE_READING;
                when others =>
                    vmmRo_cnt   <= 0;
                    state       <= DONE_READING;
                end case;
               
--            when DELAY =>             -- USE THIS STATE IF THE SOFTWARE CAN'T DECODE PACKETS FAST ENOUGH
--                debug_state  <= "1010";
--                if wait_Cnt < 250_000 then    -- 10 ms delay
--                    wait_Cnt    <= wait_Cnt + 1;
--                    state       <= DELAY;
--                else
--                    wait_Cnt    <= 0;
--                    state       <= SET_LEN;
--                end if;

            when DONE_READING =>
                debug_state     <= "1011";
                state           <= IDLE;
            when others => 
                state <= IDLE;
            end case;
        end if;
    end if;
end process;   

readout_ram: data_ram
  PORT MAP (
    clka    => clk_200,
    wea     => wr_en,
    addra   => addra_sig,
    dina    => din_rev,

    clkb    => clk_125,
    rstb    => rst_ram2udp,
    enb     => rd_en,
    addrb   => addrb_sig,
    doutb   => doutb_i
  );
  
    
        
    vmmId_int                   <= to_integer(unsigned(VmmId_sync));            
    packLen_sync_usg            <= unsigned(packLen_sync);        
    packLen_usg_UDP             <= resize("0000" & packLen_sync_usg*4, 16);
    
    addrb_sig                   <= std_logic_vector(addrb_cnt);

    ram_din                     <= dataIn;
    din_rev(7 downto 0)         <= ram_din(31 downto 24);
    din_rev(15 downto 8)        <= ram_din(23 downto 16);
    din_rev(23 downto 16)       <= ram_din(15 downto 8);
    din_rev(31 downto 24)       <= ram_din(7 downto 0);
    
    -- to mux ---
    udp_tx_start                <= tx_start;
    data_length_o               <= std_logic_vector(lenForUDP(vmmRo_cnt));
    data_out_last_o             <= last_delay0;
    data_out_valid_o            <= valid_delay0;
    data_out_o                  <= doutb_i;
    ----------------

    wr_en(0)                    <= wrenable;
    got_len                     <= got_len_i;
    addra_sig                   <= addrRAM_wr;
    RAMdone                     <= RAMdone_i;
    ram_state_ila               <= debug_state;

------------------- SYNC BLOCK --------------------------
-- sync signals that belong to different clock domains --
---------------------------------------------------------

syncReady: process(clk_125, udp_tx_data_out_ready)
begin
    if(rising_edge(clk_125))then
        tx_ready <= udp_tx_data_out_ready;
    end if;
end process;

syncPackLen: process(clk_125, packLen)
begin
    if(rising_edge(clk_125))then
        packLen_sync <= packLen;
    end if;
end process;

syncEndPacket: process(clk_125, end_packet)
begin
    if(rising_edge(clk_125))then
        end_packet_sync <= end_packet;
    end if;
end process;

syncInitRead: process(clk_125, init_read)
begin
    if(rising_edge(clk_125))then
        init_read_sync <= init_read;
    end if;
end process;

syncVmmID: process(clk_125, VmmId)
begin
    if(rising_edge(clk_125))then
        VmmId_sync <= VmmId;
    end if;
end process;

syncPfReady: process(clk_125, pf_ready)
begin
    if(rising_edge(clk_125))then
        pf_ready_sync <= pf_ready;
    end if;
end process;

delayValid0: process(clk_125, valid)    -- cascade more DFFs if using output regs in RAM
begin
    if(rising_edge(clk_125))then
        valid_delay0 <= valid;
    end if;
end process;

delaylast0: process(clk_125, last)     -- cascade more DFFs if using output regs in RAM
begin
    if(rising_edge(clk_125))then
        last_delay0 <= last;
    end if;
end process;

---------------------------------------------------------

--ram_debugger: ila_ram
--PORT MAP (
--    clk    => clk_125,
--    probe0 => debug_probe
--);

--    debug_probe(0)              <= wr_en(0);
--    debug_probe(1)              <= rd_en;
--    debug_probe(2)              <= tx_start;
--    debug_probe(3)              <= last;
--    debug_probe(4)              <= RAMdone_i;
--    debug_probe(5)              <= valid;
--    debug_probe(6)              <= tx_ready;
--    debug_probe(7)              <= rst_i;
--    debug_probe(8)              <= '0';
--    debug_probe(9)              <= got_len_i;
--    debug_probe(10)             <= end_packet_sync;
--    debug_probe(11)             <= init_read_sync;
--    debug_probe(12)             <= pf_ready_sync;
--    debug_probe(16 downto 13)   <= debug_state;
--    debug_probe(19 downto 17)   <= VmmId_sync;
--    debug_probe(27 downto 20)   <= doutb_i;
--    debug_probe(39 downto 28)   <= addra_sig;
--    debug_probe(53 downto 40)   <= addrb_sig;
--    debug_probe(85 downto 54)   <= ram_din;
--    debug_probe(101 downto 86)  <= packLen_sync;
    
end Behavioral;
