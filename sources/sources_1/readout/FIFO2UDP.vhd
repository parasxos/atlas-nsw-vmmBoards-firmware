----------------------------------------------------------------------------------
-- Company: NTU ATHNENS - BNL - Michigan
-- Engineer: Panagiotis Gkountoumis
-- 
-- Create Date: 18.04.2016 13:00:21
-- Design Name: 
-- Module Name: config_logic - Behavioral
-- Project Name: MMFE8 
-- Target Devices: Arix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-- Changelog:
-- 23.07.2016 Output signal "sending" to hold packet_formation from issuing new 
-- packets (P.M.)
-- 26.07.2016 Increased the size of the FIFO to 2048 in order to be able to handle
-- jumbo UDP frames. (P.M.)
-- 22.08.2016 Re-wrote the main logic into a single state machine to fix the freezing
-- bug. (Reid Pinkham)
-- 17.10.2016 Changed the data bus width to 32-bit wide and changed the FIFO depth
-- to adapt it to the new parallel readout standards. (Christos Bakalis)
--
----------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;

entity FIFO2UDP is
    Port ( 
        clk_200                     : in std_logic;
        clk_125                     : in std_logic;
        conf_xadc_data_in           : in  std_logic_vector(31 downto 0);	
        re_out					    : out std_logic;
        control					    : out std_logic;
        fifo_empty                  : out std_logic;
        wr_en                       : in  std_logic;
        end_packet                  : in  std_logic;
        global_reset                : in  std_logic;
        packet_length_in            : in  std_logic_vector(11 downto 0);
        reset_FIFO                  : in  std_logic;
        sending_o                   : out std_logic;
        
        udp_tx_data_out_ready       : in  std_logic;
        udp_tx_start_fifo           : out std_logic;
        data_length_fifo            : out std_logic_vector(15 downto 0);
        data_out_last_fifo          : out std_logic;
        data_out_valid_fifo         : out std_logic;
        data_out_fifo               : out std_logic_vector(7 downto 0)
    );
end FIFO2UDP;

architecture Behavioral of FIFO2UDP is

    signal count                       : unsigned(3 downto 0) := x"0";
    signal i                           : integer := 0;
    signal count_length                : unsigned(15 downto 0) := x"0000";
    signal daq_fifo_re                 : std_logic := '0';
    signal fifo_empty_UDP              : std_logic := '0';
    signal fifo_full_UDP               : std_logic := '0';
    signal prog_fifo_empty             : std_logic := '0';
    signal daq_out                     : std_logic_vector(255 downto 0);
    signal data_out                    : std_logic_vector(7 downto 0) := x"00";
    signal data_out_valid              : std_logic := '0';
    signal packet_length               : unsigned(15 downto 0) := x"0000";
    signal data_out_last               : std_logic := '0';
    signal sending                     : std_logic := '0';
    signal end_packet_synced           : std_logic := '0';
    signal udp_tx_start_int            : std_logic := '0';
    signal wr_en_int                   : std_logic := '0';
    signal fifo_len_wr_en              : std_logic := '0';
    signal fifo_len_rd_en              : std_logic := '0';
    signal packet_len_r                : std_logic_vector(11 downto 0);
    signal fifo_empty_len              : std_logic;
    signal state                       : std_logic_vector(3 downto 0) := "0000";
    
    signal is_trailer                  : integer := 0;
    
    signal daq_data_out                : std_logic_vector(7 downto 0) := x"00";
    
    signal vmmID_i                     : std_logic_vector(2 downto 0);
    
    signal trigger                     : std_logic;

    signal len_cnt                     : unsigned(7 downto 0) := "00000000";
  
--    attribute mark_debug : string;
 
--    attribute mark_debug of prog_fifo_empty         : signal is "true";
--    attribute mark_debug of fifo_empty_UDP          : signal is "true";     
--    attribute mark_debug of daq_fifo_re             : signal is "true";     
--    attribute mark_debug of data_out_last           : signal is "true";           
--    attribute mark_debug of data_out                : signal is "true";
--    attribute mark_debug of data_out_valid          : signal is "true";
--    attribute mark_debug of sending                 : signal is "true";
--    attribute mark_debug of udp_tx_data_out_ready   : signal is "true";
--    attribute mark_debug of udp_tx_data_out_ready   : signal is "true";
--    attribute mark_debug of daq_data_out            : signal is "true";
--    attribute mark_debug of udp_tx_start            : signal is "true";
--    attribute mark_debug of end_packet_synced       : signal is "true";     
--    attribute mark_debug of i                       : signal is "true";     
--    attribute mark_debug of packet_length           : signal is "true";            
--    attribute mark_debug of count                   : signal is "true";
--    attribute mark_debug of count_length            : signal is "true";
--    attribute mark_debug of daq_data_in_int         : signal is "true";
--    attribute mark_debug of wr_en_int               : signal is "true";
--    attribute mark_debug of fifo_full_UDP           : signal is "true";
--    attribute mark_debug of fifo_empty_len          : signal is "true";
--    attribute mark_debug of wr_en                   : signal is "true";
--    attribute mark_debug of wr_en                   : signal is "true";
    
--    attribute mark_debug of packet_length_in        : signal is "true";
--    attribute mark_debug of packet_length_in        : signal is "true";
--    attribute mark_debug of vmmID_i                 : signal is "true";
--    attribute mark_debug of trigger                 : signal is "true";

--    attribute mark_debug of len_cnt                 : signal is "true";
--    attribute mark_debug of fifo_len_wr_en          : signal is "true";
--    attribute mark_debug of fifo_len_rd_en          : signal is "true";
--    attribute mark_debug of packet_len_r            : signal is "true";
  
  
component conf_xadc_fifo is

port(
    rst         : in std_logic;
    wr_clk      : in std_logic;
    rd_clk      : in std_logic;
    din         : in std_logic_vector(31 downto 0);
    wr_en       : in std_logic;
    rd_en       : in std_logic;
    dout        : out std_logic_vector(7 downto 0);
    full        : out std_logic;
    empty       : out std_logic
);
end component;

component packet_len_fifo
port (
    clk : in std_logic;
    srst : in std_logic;
    din : in std_logic_vector(11 downto 0);
    wr_en : in std_logic;
    rd_en : in std_logic;
    dout : out std_logic_vector(11 downto 0);
    full : out std_logic;
    empty : out std_logic
);
end component;
  

begin


conf_xadc_fifo_instance: conf_xadc_fifo
    port map(
        rst         => reset_FIFO,
        wr_clk      => clk_200,
        rd_clk      => clk_125,
        din         => conf_xadc_data_in,
        wr_en       => wr_en,
        rd_en       => daq_fifo_re,
        dout        => daq_data_out,
        full        => fifo_full_UDP,
        empty       => fifo_empty_UDP
    );

packet_len_fifo_instance: packet_len_fifo
    port map (
        clk => clk_125,
        srst => reset_FIFO,
        din => packet_length_in,
        wr_en => fifo_len_wr_en,
        rd_en => fifo_len_rd_en,
        dout => packet_len_r,
        full => open,
        empty => fifo_empty_len
    );

synced_end_packet: process (clk_125)
begin
    if clk_125'event and clk_125 = '1' then
        end_packet_synced   <= end_packet;
    end if;
end process;

fill_packet_len: process (clk_125, state) -- small state machine to write packet_len to fifo
begin
    if rising_edge(clk_125) then
        case state is
            when "0000" => -- idle
                if (end_packet_synced = '1') then -- latch the packet_len into the fifo
                    fifo_len_wr_en <= '1';
                    state <= "0001";
                else
                    state <= "0000";
                end if;

            when "0001" => -- st1
                if (end_packet_synced = '0') then-- prevent a double latch
                    state <= "0000";
                else
                    state <= "0001";
                end if;
                fifo_len_wr_en <= '0';

            when others =>
                state <= "0000";
        end case;
    end if;
end process;

process (clk_125, fifo_len_rd_en)
begin
    if rising_edge(clk_125) then
        if fifo_len_rd_en = '1' then
            len_cnt <= len_cnt + 1;
        end if;
    end if;
end process;

--UDPDone_proc: process (clk_200, fifo_empty_UDP, sending)
--begin
--    if fifo_empty_UDP = '1' and sending = '0' then -- IF Statement to inidcate when packets have been sent
--        UDPDone <= '1';
--    else
--        UDPDone <= '0';
--    end if;
--end process;

process (clk_125, count, udp_tx_data_out_ready, fifo_empty_UDP, prog_fifo_empty, data_out_valid, end_packet_synced)
begin
    if rising_edge(clk_125) then
        if global_reset = '1' then -- IF statement to read from length fifo and initiate a packet send
            sending             <= '0';
            data_out_last       <= '0';    
            data_out_valid      <= '0';     
            udp_tx_start_int    <= '0';
            count               <= x"0";
        else
            case count is
                when x"0" =>
                    if fifo_empty_len = '0' then -- Send packets until FIFO is empty
                        fifo_len_rd_en <= '1';
                        count <= x"1";
                    end if;

                when x"1" => -- state to allow fifo time to respond
                    count <= x"2";
                    fifo_len_rd_en  <= '0';

                when x"2" =>
                    packet_length   <= resize(unsigned("0000" & packet_len_r) * 4, 16);
                    count_length    <= resize(unsigned("0000" & packet_len_r) * 4, 16);
                    fifo_len_rd_en  <= '0';
                    count <= x"3";

                when x"3" =>
                      data_out_last   <= '0';    
                      data_out_valid  <= '0';
                      data_out        <= (others => '0');
                      udp_tx_start_int                 <= '0';
                      count <= x"4";

                when x"4" =>
                      udp_tx_start_int  <= '1';
                      daq_fifo_re       <= '0';                              
                      count             <= x"5";

                when x"5" =>
                    if udp_tx_data_out_ready = '1' then     
                      udp_tx_start_int          <= '0'; 
                      daq_fifo_re               <= '1';
                      count                     <= x"6";
                    end if;

                when x"6" =>
                    if udp_tx_data_out_ready = '1' then   
                        count_length              <= count_length - 1;      
                        udp_tx_start_int          <= '0'; 
                        data_out                  <= daq_data_out;
                        count                     <= x"7";
                    end if;
                    
                when x"7" =>
                    if udp_tx_data_out_ready = '1' then
                        if count_length = 1 then
                            daq_fifo_re                 <= '0';
                            data_out_last               <= '0';
                        elsif count_length = 0 then
                            count                       <= x"8"; 
                            daq_fifo_re                 <= '0';
                            data_out_last               <= '1';
                        else
                            daq_fifo_re                 <= '1';
                        end if;
                         
                            count_length     <= count_length - 1;    
                            udp_tx_start_int                             <= '0';                
                            data_out_valid                               <= '1';   
                            control                                      <= '0';                                       
                            data_out                    <= daq_data_out;
                        else
                            daq_fifo_re               <= '0';
                        end if;
                    
                when x"8" =>
                    data_out_last   <= '0';    
                    data_out_valid  <= '0';
                    data_out        <= (others => '0');
                    udp_tx_start_int                 <= '0';
                    count <= x"9";
                    
                when x"9" =>
                    count                         <= x"0";
                    count_length                  <= x"0000";
                    data_out_last                 <= '0';    
                    data_out_valid                <= '0';                  
                    udp_tx_start_int              <= '0';
                    
                when others =>
                    count <= x"0";                      
            end case;
        end if;
    end if;
end process;




    -- to mux ---------
    udp_tx_start_fifo           <= udp_tx_start_int;
    data_length_fifo            <= std_logic_vector(packet_length);
    data_out_last_fifo          <= data_out_last;
    data_out_valid_fifo         <= data_out_valid;
    data_out_fifo               <= data_out;
    -------------------
    
    fifo_empty                  <= fifo_empty_UDP;
    wr_en_int                   <= wr_en;
    sending_o                   <= sending;
   
--ila_daq_send : ila_0
--    port map
--    (
--        clk           => clk_125, 
--        probe0        => daq_out,
--        probe1        => udp_tx_data_out_ready
--    );   

--daq_out(0)              <= end_packet_synced;
--daq_out(1)              <= fifo_empty_UDP;
--daq_out(2)              <= daq_fifo_re;
--daq_out(3)              <= data_out_valid;
--daq_out(4)              <= data_out_last;   
--daq_out(12 downto 5)    <= data_out;
--daq_out(16 downto 13)   <= std_logic_vector(count);
--daq_out(38 downto 17)   <= (others => '0');
--daq_out(39)             <= udp_tx_start_int;
--daq_out(40)             <= '0'; --udp_tx_data_out_ready;
--daq_out(48 downto 41)   <= daq_data_out;
--daq_out(112 downto 49)  <= daq_data_in;
--daq_out(113)            <= sending;
--daq_out(129 downto 114) <= std_logic_vector(packet_length);
--daq_out(145 downto 130) <= std_logic_vector(count_length);     
--daq_out(157 downto 146) <= packet_len_r;
--daq_out(221 downto 158) <= daq_data_in_int;
--daq_out(222)            <= wr_en_int;
--daq_out(223)            <= wr_en;
--daq_out(235 downto 224) <= packet_length_in;
--daq_out(236)            <= udp_tx_data_out_ready;
--daq_out(237)            <= fifo_len_wr_en;
--daq_out(238)            <= fifo_len_rd_en;
--daq_out(239)            <= fifo_empty_len;
--daq_out(240)            <= fifo_full_UDP;
--daq_out(243 downto 241) <= vmmID_i;
--daq_out(244)            <= trigger;
--daq_out(252 downto 245) <= std_logic_vector(len_cnt);
--daq_out(255 downto 253) <= (others => '0');


end Behavioral;