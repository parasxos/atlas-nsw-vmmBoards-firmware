----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
--
-- Create Date: 03.02.2017
-- Design Name: ICMP Receiver
-- Module Name: ICMP_RX - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions: Vivado 2016.2
-- Description: Handles simple ICMP RX
--              
-- Dependencies:
--
-- Changelog:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.axi.all;
use work.ipv4_types.all;

entity ICMP_RX is
  port (
    -- ICMP Layer signals
    icmp_rx_start : out std_logic;       -- indicates receipt of icmp header
    icmp_rxo      : out icmp_rx_type;
    -- system signals
    clk           : in  std_logic;
    reset         : in  std_logic;
    -- IP layer RX signals
    ip_rx_start   : in  std_logic;       -- indicates receipt of ip header
    ip_rx         : in  ipv4_rx_type
    );
end ICMP_RX;

architecture Behavioral of ICMP_RX is

  type rx_state_type is (IDLE, ICMP_HDR, ICMP_PAYLOAD, WAIT_END, ERR);

  type rx_event_type is (NO_EVENT, DATA);
  type count_mode_type is (RST, INCR, HOLD);
  type settable_count_mode_type is (RST, INCR, SET_VAL, HOLD);
  type set_clr_type is (SET, CLR, HOLD);


  -- state variables
  signal rx_state           : rx_state_type;
  signal rx_count           : unsigned (15 downto 0);
  signal icmp_type          : std_logic_vector (7 downto 0);
  signal icmp_code          : std_logic_vector (7 downto 0);
  signal icmp_chksum        : std_logic_vector (15 downto 0);
  signal icmp_ident         : std_logic_vector (15 downto 0);
  signal icmp_seqNum        : std_logic_vector (15 downto 0);
  signal icmp_rx_start_reg  : std_logic;  -- indicates start of user data
  signal src_ip_addr        : std_logic_vector (31 downto 0);  -- captured from IP hdr

  -- rx control signals
  signal next_rx_state      : rx_state_type;
  signal set_rx_state       : std_logic;
  signal rx_event           : rx_event_type;
  signal rx_count_mode      : settable_count_mode_type;
  signal rx_count_val       : unsigned (15 downto 0);
  signal set_type           : std_logic;
  signal set_code           : std_logic;
  signal set_chksum_h       : std_logic;
  signal set_chksum_l       : std_logic;
  signal set_ident_h        : std_logic;
  signal set_ident_l        : std_logic;
  signal set_seq_h          : std_logic;
  signal set_seq_l          : std_logic;
  signal set_icmp_rx_start  : set_clr_type;
  signal dataval            : std_logic_vector (7 downto 0);
  signal set_src_ip         : std_logic;
  signal set_data_last      : std_logic;

-- ICMP datagram header format
--
--      0                     8                      16                                           31
--      --------------------------------------------------------------------------------------------
--      |          Type       |        Code          |                 Checksum                    |
--      |                     |                      |                                             |
--      --------------------------------------------------------------------------------------------
--      |                 Identifier                 |              Sequence Number                |
--      |                                            |                                             |
--      --------------------------------------------------------------------------------------------
--      |                                         Payload                                          |
--      |                                                                                          |
--      --------------------------------------------------------------------------------------------
--      |                                          ....                                            |
--      |                                                                                          |
--      --------------------------------------------------------------------------------------------
--
--      Type = 8 and Code = 0 (echo request)
--      Type = 0 and Code = 0 (echo reply)

begin

  -----------------------------------------------------------------------
  -- combinatorial process to implement FSM and determine control signals
  -----------------------------------------------------------------------

  rx_combinatorial : process (
    -- input signals
    ip_rx, ip_rx_start,
    -- state variables
    rx_state, rx_count, icmp_type, icmp_code, icmp_chksum, icmp_ident, icmp_seqNum, icmp_rx_start_reg, src_ip_addr,
    -- control signals
    next_rx_state, set_rx_state, rx_event, rx_count_mode, rx_count_val,
    set_type, set_code, set_chksum_h, set_chksum_l, set_ident_h, set_ident_l, set_seq_h, set_seq_l, set_data_last,
    set_icmp_rx_start, dataval, set_src_ip
    )
  begin
    -- set output followers
    icmp_rx_start               <= icmp_rx_start_reg;
    icmp_rxo.hdr.src_ip_addr    <= src_ip_addr;
    icmp_rxo.hdr.icmp_type      <= icmp_type;
    icmp_rxo.hdr.icmp_code      <= icmp_code;
    icmp_rxo.hdr.icmp_chksum    <= icmp_chksum;
    icmp_rxo.hdr.icmp_ident     <= icmp_ident;
    icmp_rxo.hdr.icmp_seqNum    <= icmp_seqNum;

    
    -- transfer data upstream if in user data phase
    if rx_state = ICMP_PAYLOAD then
      icmp_rxo.payload.data_in       <= ip_rx.data.data_in;
      icmp_rxo.payload.data_in_valid <= ip_rx.data.data_in_valid;
      icmp_rxo.payload.data_in_last  <= set_data_last;
    else
      icmp_rxo.payload.data_in       <= (others => '0');
      icmp_rxo.payload.data_in_valid <= '0';
      icmp_rxo.payload.data_in_last  <= '0';
    end if;

    -- set signal defaults
    next_rx_state       <= IDLE;
    set_rx_state        <= '0';
    rx_event            <= NO_EVENT;
    rx_count_mode       <= RST;
    set_type            <= '0';
    set_code            <= '0';
    set_chksum_h        <= '0';
    set_chksum_l        <= '0';
    set_ident_h         <= '0';
    set_ident_l         <= '0';
    set_seq_h           <= '0';
    set_seq_l           <= '0';
    set_icmp_rx_start   <= CLR;
    dataval             <= (others => '0');
    set_src_ip          <= '0';
    rx_count_val        <= (others => '0');
    set_data_last       <= '0';

    -- determine event (if any)
    if ip_rx.data.data_in_valid = '1' then
      rx_event <= DATA;
      dataval  <= ip_rx.data.data_in;
    end if;

    -- RX FSM
    case rx_state is
      when IDLE =>
        rx_count_mode <= RST;
        case rx_event is
          when NO_EVENT =>              -- (nothing to do)
          when DATA =>

            if ip_rx.hdr.protocol = x"01" then -- ICMP protocol
              rx_count_mode <= INCR;
              set_src_ip    <= '1';
              set_type      <= '1';
              next_rx_state <= ICMP_HDR;
              set_rx_state  <= '1';
            else                             -- non-ICMP protocol - ignore this pkt
              next_rx_state <= WAIT_END;
              set_rx_state  <= '1'; 
            end if;
            
        end case;

      when ICMP_HDR =>
        case rx_event is
          when NO_EVENT =>              -- (nothing to do)
          when DATA =>
            if rx_count = x"0007" then
              rx_count_mode <= SET_VAL;
              rx_count_val  <= x"0001";
              next_rx_state <= ICMP_PAYLOAD;
              set_rx_state  <= '1';
            else
              rx_count_mode <= INCR;
            end if;
                                        -- handle early frame termination
            if ip_rx.data.data_in_last = '1' then
              next_rx_state <= IDLE;
              set_rx_state  <= '1';
            else
              case rx_count is
                when x"0000" => set_type        <= '1';  -- set ICMP type
                when x"0001" => set_code        <= '1';  -- set ICMP code
                when x"0002" => set_chksum_h    <= '1';  -- set checksum (1st byte)
                when x"0003" => set_chksum_l    <= '1';  -- set checksum (2nd byte)

                when x"0004" => set_ident_h     <= '1';  -- set identifier (1st byte)
                when x"0005" => set_ident_l     <= '1';  -- set identifier (2nd byte)
                                                    
                when x"0006" => set_seq_h       <= '1';  -- set sequence number (1st byte)
                when x"0007" => set_seq_l       <= '1';  -- set sequence number (2nd byte)   
                                set_icmp_rx_start   <= SET;  -- indicate frame received

                when others =>  -- ignore other bytes in icmp header
              end case;
            end if;
        end case;

      when ICMP_PAYLOAD =>
        case rx_event is
          when NO_EVENT =>              -- (nothing to do)
          when DATA =>
                                        -- note: data/payload gets transfered upstream as part of "output followers" processing
              if ip_rx.data.data_in_last = '1' then -- no early frame termination check
                next_rx_state       <= IDLE;
                set_icmp_rx_start   <= CLR;
                rx_count_mode       <= RST;
                set_rx_state        <= '1';
                set_data_last       <= '1';
              else
                rx_count_mode       <= INCR;
                set_rx_state        <= '0';
              end if;

        end case;

      when ERR =>
        if ip_rx.data.data_in_last = '0' then
          next_rx_state <= WAIT_END;
          set_rx_state  <= '1';
        else
          next_rx_state <= IDLE;
          set_rx_state  <= '1';
        end if;


      when WAIT_END =>
        case rx_event is
          when NO_EVENT =>              -- (nothing to do)
          when DATA =>
            if ip_rx.data.data_in_last = '1' then
              next_rx_state <= IDLE;
              set_rx_state  <= '1';
            end if;
        end case;

    end case;

  end process;


  -----------------------------------------------------------------------------
  -- sequential process to action control signals and change states and outputs
  -----------------------------------------------------------------------------

  rx_sequential : process (clk, reset)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        -- reset state variables
        rx_state            <= IDLE;
        rx_count            <= x"0000";
        icmp_type           <= (others => '0');
        icmp_code           <= (others => '0');
        icmp_chksum         <= (others => '0');
        icmp_ident          <= (others => '0');
        icmp_seqNum         <= (others => '0');
        icmp_rx_start_reg   <= '0';
        src_ip_addr         <= (others => '0');
      else
        -- Next rx_state processing
        if set_rx_state = '1' then
          rx_state <= next_rx_state;
        else
          rx_state <= rx_state;
        end if;

        -- rx_count processing
        case rx_count_mode is
          when RST     => rx_count <= x"0000";
          when INCR    => rx_count <= rx_count + 1;
          when SET_VAL => rx_count <= rx_count_val;
          when HOLD    => rx_count <= rx_count;
        end case;

        -- ICMP datafields capture
        if (set_type     = '1') then icmp_type(7 downto 0)       <= dataval; end if;
        if (set_code     = '1') then icmp_code(7 downto 0)       <= dataval; end if;
        if (set_chksum_h = '1') then icmp_chksum(15 downto 8)    <= dataval; end if; 
        if (set_chksum_l = '1') then icmp_chksum(7 downto 0)     <= dataval; end if;
        if (set_ident_h  = '1') then icmp_ident(15 downto 8)     <= dataval; end if;
        if (set_ident_l  = '1') then icmp_ident(7 downto 0)      <= dataval; end if;
        if (set_seq_h    = '1') then icmp_seqNum(15 downto 8)    <= dataval; end if;
        if (set_seq_l    = '1') then icmp_seqNum(7 downto 0)     <= dataval; end if;

        case set_icmp_rx_start is
          when SET  => icmp_rx_start_reg <= '1';
          when CLR  => icmp_rx_start_reg <= '0';
          when HOLD => icmp_rx_start_reg <= icmp_rx_start_reg;
        end case;

        -- capture src IP address
        if set_src_ip = '1' then
          src_ip_addr <= ip_rx.hdr.src_ip_addr;
        else
          src_ip_addr <= src_ip_addr;
        end if;

      end if;
    end if;
  end process;

end Behavioral;