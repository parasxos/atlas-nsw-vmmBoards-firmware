----------------------------------------------------------------------------------
-- Company: NTU ATHNENS - BNL
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
        daq_data_in                 : in  std_logic_vector(63 downto 0);
        fifo_data_out               : out std_logic_vector (7 downto 0);
        udp_txi		                : out udp_tx_type;	
        udp_tx_start                : out std_logic;
        re_out					    : out std_logic;
        control					    : out std_logic;        
        udp_tx_data_out_ready       : in  std_logic;
        wr_en                       : in  std_logic;
        end_packet                  : in  std_logic;
        global_reset                : in  std_logic;
        packet_length_in            : in  integer;
        reset_DAQ_FIFO              : in std_logic;
        sending_o                   : out std_logic
    );
end FIFO2UDP;

architecture Behavioral of FIFO2UDP is

  signal count                       : integer := 0;
  signal i                           : integer := 0;
  signal count_length                : integer := 0;
  signal packet_length_int           : integer := 0;
  signal daq_fifo_re                 : std_logic := '0';
  signal fifo_empty                  : std_logic := '0';
  signal prog_fifo_empty             : std_logic := '0';
  signal daq_out                     : std_logic_vector(255 downto 0);
  signal data_out                    : std_logic_vector(7 downto 0) := x"00";
  signal data_out_valid              : std_logic := '0';
  signal packet_length               : integer := 0;
  signal daq_data_in_int             : std_logic_vector(63 downto 0);
  signal data_out_last               : std_logic := '0';
  signal sending                     : std_logic := '0';
  signal end_packet_synced           : std_logic := '0';
  signal udp_tx_start_int            : std_logic := '0';
  signal wr_en_int                   : std_logic := '0';
  
  signal is_trailer                  : integer := 0;
  signal temp_buffer                 : std_logic_vector(63 downto 0) := (others=> '0');
  
  signal daq_data_out                : std_logic_vector(7 downto 0) := x"00";
  
  type tx_state is (HEADER, EN_RE, WAIT_ONE, DATA, TRAILER, LAST, IDLE);
  signal state     : tx_state;  
  
    component readout_fifo is
    port(
       rst         : in std_logic;
       wr_clk      : in std_logic;
       rd_clk      : in std_logic;
       din         : in std_logic_vector(63 downto 0);
       wr_en       : in std_logic;
       rd_en       : in std_logic;
       dout        : out std_logic_vector(7 downto 0);
       full        : out std_logic;
       empty       : out std_logic;
       prog_empty  : out std_logic
    );
    end component;

begin

daq_FIFO_instance: readout_fifo
    port map(
             rst         => reset_DAQ_FIFO,
             wr_clk      => clk_200,
             rd_clk      => clk_125,
             din         => daq_data_in,
             wr_en       => wr_en,
             rd_en       => daq_fifo_re,
             dout        => daq_data_out,
             full        => open,
             empty       => fifo_empty,
             prog_empty  => prog_fifo_empty
    );

    synced_end_packet: process (clk_125)
        begin
        if clk_125'event and clk_125 = '1' then
            end_packet_synced   <= end_packet;
         end if;
         end process;

          process (clk_125, count, state, udp_tx_data_out_ready, fifo_empty, prog_fifo_empty, data_out_valid, end_packet_synced)
        begin
        if clk_125'event and clk_125 = '1' then
            if global_reset = '1' then
                sending             <= '0';
                data_out_last       <= '0';    
                data_out_valid      <= '0';     
                udp_tx_start_int    <= '0';
                       
            elsif end_packet_synced = '1' and sending = '0' then 
                packet_length   <= (packet_length_in * 8) + 4;
                count_length    <= packet_length_in * 8;
                state           <= HEADER;
                sending         <= '1';
            else
            end if;    
            
            
            if sending = '1' then
                if count = 0 then
                      count <= count + 1;
                      data_out_last   <= '0';    
                      data_out_valid  <= '0';
                      data_out        <= (others => '0');
                      udp_tx_start_int                 <= '0';
                elsif count = 1 then      
                      udp_tx_start_int             <= '1';
                      udp_txi.hdr.dst_ip_addr  <= x"c0a80010";         -- set a generic ip adrress (192.168.0.255)
                      udp_txi.hdr.src_port     <= x"19CB";                -- set src and dst ports
                      udp_txi.hdr.dst_port     <= x"1778";                     -- x"6af0"; 
                      udp_txi.hdr.data_length  <= std_logic_vector(to_unsigned(packet_length, udp_txi.hdr.data_length'length));                       
                      daq_fifo_re              <= '0';                           
                      udp_txi.hdr.checksum     <= x"0000";     
                      count <= count + 1;
                elsif count = 2 then
                    if udp_tx_data_out_ready = '1' then     
                      udp_tx_start_int          <= '0'; 
                      daq_fifo_re               <= '1';
                      count                     <= count + 1;
                    else
                    end if;       
                elsif count = 3 then
                    if udp_tx_data_out_ready = '1' then   
                      count_length  <= count_length - 1;      
                      udp_tx_start_int          <= '0'; 
                      count                     <= count + 1;
                      data_out                    <= daq_data_out;
                    end if;                               
                elsif count = 4 then 
                    if udp_tx_data_out_ready = '1' then
                        if count_length = 1 then
                            daq_fifo_re                 <= '0';
                        elsif count_length = 0 then
                            count <= count + 1; 
                            daq_fifo_re                 <= '0';
                        end if; 
                        count_length  <= count_length - 1;    
                        udp_tx_start_int                             <= '0';                
                        data_out_valid                               <= '1';   
                        control                                      <= '0';         
                        data_out_last                                <= '0';       
                        data_out                    <= daq_data_out;
                    else
                        daq_fifo_re               <= '0';
                    end if;
                elsif count >= 5  and count <= 7 then
                      if udp_tx_data_out_ready = '1' then    
                          daq_fifo_re                 <= '0';
                          udp_tx_start_int            <= '0';
                          data_out_last               <= '0';
                         data_out <= x"ff";
                          count <= count + 1;
                      end if;
                elsif count = 8 then
                    if udp_tx_data_out_ready = '1' then
                        daq_fifo_re                 <= '0';    
                        udp_tx_start_int            <= '0';
                        data_out_last               <= '1';
                        data_out <= x"ff";
                        count <= count + 1;
                    end if;
                elsif count = 9 then           
                      count <= count + 1;
                      data_out_last   <= '0';    
                      data_out_valid  <= '0';
                      data_out        <= (others => '0');
                      udp_tx_start_int                 <= '0';
                else
                      count                         <= 0;
                      count_length                  <= 0;
                      data_out_last    <= '0';    
                      data_out_valid   <= '0';                  
                      udp_tx_start_int              <= '0';
                      sending                       <= '0';
                end if;
            end if;
        end if;
        end process;
       
        udp_tx_start                <= udp_tx_start_int;
        udp_txi.data.data_out_last  <= data_out_last;
        udp_txi.data.data_out_valid <= data_out_valid ;
        udp_txi.data.data_out       <= data_out;
        packet_length_int           <= packet_length_in;
        
        daq_data_in_int             <= daq_data_in;
        wr_en_int                   <= wr_en;
        sending_o                   <= sending;
    
    end Behavioral;