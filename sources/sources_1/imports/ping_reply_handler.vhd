----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Create Date: 02.04.2017
-- Design Name: Ping Reply Handler
-- Module Name: ping_reply_handler - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: Vivado 2016.2
-- Description: This module receives a ping/echo request packet from ICMP_RX and 
-- forwards an appropriate echo reply to ICMP_TX.
-- 
-- Dependencies: Xilinx FIFO IP
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

entity ping_reply_handler is
    Port(
        -- ICMP RX interface
        icmp_rx_start           : in std_logic;
        icmp_rxi                : in icmp_rx_type;
        -- system signals
        tx_clk                  : in std_logic;
        rx_clk                  : in std_logic;
        reset                   : in std_logic;
        -- ICMP/UDP mux interface
        sel_icmp                : out std_logic;
        -- ICMP TX interface
        icmp_tx_start           : out std_logic;
        icmp_tx_ready           : in  std_logic;
        icmp_txo                : out icmp_tx_type;
        icmp_tx_is_idle         : in  std_logic
    );
end ping_reply_handler;

architecture Behavioral of ping_reply_handler is

    COMPONENT icmp_payload_buffer
        PORT(
        rst     : IN STD_LOGIC;
        wr_clk  : IN STD_LOGIC;
        rd_clk  : IN STD_LOGIC;
        din     : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        wr_en   : IN STD_LOGIC;
        rd_en   : IN STD_LOGIC;
        dout    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        full    : OUT STD_LOGIC;
        empty   : OUT STD_LOGIC
        );
    END COMPONENT;

    type rx_state_type   is (IDLE, CNT_LEN, CHK_TYPE_CODE, WAIT_FOR_TX);
    type tx_state_type   is (IDLE, SET_HDR, START, WAIT_FOR_EMPTY, DELAY);
    type count_mode_type is (RST, INCR, HOLD);
    type sel_mode_type   is (SELECT_UDP, SELECT_ICMP, HOLD);
    type st_chksum_type  is (SET, RST, PLUS_2048, HOLD);
    type simple_reg_type is (SET, RST, HOLD);
    type dout_last_type  is (SET, RST);


    signal ping_rx_state  : rx_state_type    := IDLE;
    signal ping_tx_state  : tx_state_type    := IDLE;
    signal next_rx_state  : rx_state_type    := IDLE;
    signal next_tx_state  : tx_state_type    := IDLE;
    signal cntLen_state   : count_mode_type  := RST;
    signal mux_state      : sel_mode_type    := SELECT_UDP;
    signal chksum_state   : st_chksum_type   := RST;
    signal tx_ena_state   : simple_reg_type  := RST;
    signal start_tx_state : simple_reg_type  := RST;
    signal valid_state    : simple_reg_type  := RST;
    signal read_state     : simple_reg_type  := RST;
    signal last_state     : dout_last_type   := RST;
    signal rst_fifo_state : simple_reg_type  := RST;
    
    signal payLen_count_ug      : unsigned (15 downto 0) := (others => '0');
    signal chksum_out_ug        : unsigned (15 downto 0) := (others => '0');
    signal set_tx_state         : std_logic := '0';
    signal set_rx_state         : std_logic := '0';
    signal sel_icmp_int         : std_logic := '0';
    signal tx_ena               : std_logic := '0';
    signal icmp_tx_start_int    : std_logic := '0';

    signal rd_ena               : std_logic := '0';
    signal rst_fifo             : std_logic := '0';
    signal fifo_empty           : std_logic := '0';
    signal fifo_full            : std_logic := '0';
    signal data_last            : std_logic := '0';
    signal data_valid           : std_logic := '0';
    signal data_valid_reg       : std_logic := '0';

begin

    --------------------------------------------------------------------------
    -- combinatorial process to implement FSM RX and determine control signals
    --------------------------------------------------------------------------

ping_FSM_RX: process(ping_rx_state, icmp_rx_start, icmp_rxi, fifo_empty)
begin
    case ping_rx_state is

    when IDLE =>
        if(icmp_rx_start = '1')then
            if(icmp_rxi.payload.data_in_valid = '1' and icmp_rxi.payload.data_in_last = '0')then
                set_rx_state    <= '1';
                cntLen_state    <= INCR;
                next_rx_state   <= CNT_LEN;
            elsif(icmp_rxi.payload.data_in_valid = '1' and icmp_rxi.payload.data_in_last = '1')then -- payload is only one-byte long
                set_rx_state    <= '1';
                cntLen_state    <= INCR;
                next_rx_state   <= CHK_TYPE_CODE;
            else 
                set_rx_state    <= '0';
            end if;
        else
            set_rx_state    <= '0';
            cntLen_state    <= RST;
            chksum_state    <= RST;
            tx_ena_state    <= RST;
        end if;

    when CNT_LEN =>
        cntLen_state    <= INCR;
        if(icmp_rxi.payload.data_in_last = '1')then
            set_rx_state    <= '1';
            chksum_state    <= SET;
            next_rx_state   <= CHK_TYPE_CODE;
        else
            set_rx_state    <= '0';
        end if;

    when CHK_TYPE_CODE =>
        cntLen_state    <= HOLD;
        if(icmp_rxi.hdr.icmp_type = x"08" and icmp_rxi.hdr.icmp_code = x"00")then -- echo request           
            chksum_state    <= PLUS_2048;
            tx_ena_state    <= SET;
            set_rx_state    <= '1';
            next_rx_state   <= WAIT_FOR_TX;
        else
            set_rx_state    <= '1';
            next_rx_state   <= IDLE;
        end if;

    when WAIT_FOR_TX =>
        chksum_state    <= HOLD;
        if(fifo_empty = '1')then
            set_rx_state  <= '1';
            next_rx_state <= IDLE;
        else
            set_rx_state  <= '0';
            tx_ena_state  <= HOLD;
        end if;

    when others =>
        set_rx_state    <= '1';
        next_rx_state   <= IDLE;
    end case;
end process;

    --------------------------------------------------------------------
    -- sequential process to clock FSM RX and related counters/registers
    --------------------------------------------------------------------

FSM_RX_seq: process(rx_clk)
begin
    if(rising_edge(rx_clk))then
        if(reset = '1')then
            payLen_count_ug <= (others => '0');
            chksum_out_ug   <= (others => '0');
            ping_rx_state   <= IDLE;
            tx_ena          <= '0';
        else
            if(set_rx_state = '1')then
                ping_rx_state <= next_rx_state;
            else
                ping_rx_state <= ping_rx_state;
            end if;

            case cntLen_state is
            when RST  =>  payLen_count_ug <= (others => '0');
            when INCR =>  payLen_count_ug <= payLen_count_ug + 1;
            when HOLD =>  payLen_count_ug <= payLen_count_ug;
            end case;

            case tx_ena_state is
            when RST  => tx_ena <= '0';
            when SET  => tx_ena <= '1';
            when HOLD => tx_ena <= tx_ena;
            end case;

            case chksum_state is
            when RST        => chksum_out_ug <= (others => '0');
            when SET        => chksum_out_ug <= unsigned(icmp_rxi.hdr.icmp_chksum);
            when PLUS_2048  => chksum_out_ug <= chksum_out_ug + "0000100000000000";
            when HOLD       => chksum_out_ug <= chksum_out_ug;
            end case;
        end if;
    end if;
end process;

    --------------------------------------------------------------------------
    -- combinatorial process to implement FSM TX and determine control signals
    --------------------------------------------------------------------------

ping_FSM_TX: process(ping_tx_state, tx_ena, icmp_tx_ready, fifo_empty, icmp_tx_is_idle)
begin
    case ping_tx_state is

    when IDLE =>
        rst_fifo_state  <= RST;

        if(tx_ena = '1')then
            set_tx_state    <= '1';
            mux_state       <= SELECT_ICMP;
            next_tx_state   <= SET_HDR;
        else
            set_tx_state    <= '0';
            mux_state       <= SELECT_UDP;
        end if;

    when SET_HDR =>

        icmp_txo.hdr.dst_ip_addr    <= icmp_rxi.hdr.src_ip_addr;          -- reply back to source
        icmp_txo.hdr.icmp_pay_len   <= std_logic_vector(payLen_count_ug); -- payload length in bytes
        ------------------------
        icmp_txo.hdr.icmp_type      <= x"00";                             -- reply
        icmp_txo.hdr.icmp_code      <= x"00";                             -- reply
        icmp_txo.hdr.icmp_chksum    <= std_logic_vector(chksum_out_ug);   -- old checksum + 2048(in dec)
        icmp_txo.hdr.icmp_ident     <= icmp_rxi.hdr.icmp_ident;           -- CC
        icmp_txo.hdr.icmp_seqNum    <= icmp_rxi.hdr.icmp_seqNum;          -- CC
        -------------------------
        
        start_tx_state              <= SET;
        set_tx_state                <= '1';
        next_tx_state               <= START;

    when START =>
        if(icmp_tx_ready = '1')then
            read_state      <= SET;
            valid_state     <= SET;
            start_tx_state  <= RST;
            set_tx_state    <= '1';
            next_tx_state   <= WAIT_FOR_EMPTY;
        else
            start_tx_state  <= HOLD;
            valid_state     <= RST;
            read_state      <= RST;
            set_tx_state    <= '0';
        end if;

    when WAIT_FOR_EMPTY =>
        if(fifo_empty = '1')then
            read_state      <= RST;
            valid_state     <= RST;
            last_state      <= SET;
            rst_fifo_state  <= SET;
            set_tx_state    <= '1';
            next_tx_state   <= DELAY;
        else
            read_state      <= HOLD;
            valid_state     <= HOLD;
            last_state      <= RST;
            set_tx_state    <= '0';
        end if;

    when DELAY =>
        last_state      <= RST;
        rst_fifo_state  <= HOLD;

        if(icmp_tx_is_idle = '1')then
            set_tx_state    <= '1';
            next_tx_state   <= IDLE;
        else
            set_tx_state    <= '0';
        end if;

    when others =>
        set_tx_state    <= '1';
        next_tx_state   <= IDLE;
    end case;
end process;

    --------------------------------------------------------------------
    -- sequential process to clock FSM TX and related counters/registers
    --------------------------------------------------------------------
FSM_TX_seq: process(tx_clk)
begin
    if(rising_edge(tx_clk))then
        if(reset = '1')then
            rd_ena              <= '0';
            rst_fifo            <= '0';
            data_last           <= '0';
            data_valid          <= '0';
            icmp_tx_start_int   <= '0';
            sel_icmp_int        <= '0';
            ping_tx_state       <= IDLE;
        else
            if(set_tx_state = '1')then
                ping_tx_state <= next_tx_state;
            else
                ping_tx_state <= ping_tx_state;
            end if;

            case read_state is
            when RST  =>  rd_ena <= '0';
            when SET  =>  rd_ena <= '1';
            when HOLD =>  rd_ena <= rd_ena;
            end case;

            case last_state is
            when RST => data_last <= '0';
            when SET => data_last <= '1';
            end case;

            case valid_state is
            when RST  => data_valid <= '0';
            when SET  => data_valid <= '1';
            when HOLD => data_valid <= data_valid;
            end case;

            case start_tx_state is
            when RST  => icmp_tx_start_int <= '0';
            when SET  => icmp_tx_start_int <= '1';
            when HOLD => icmp_tx_start_int <= icmp_tx_start_int;
            end case;

            case rst_fifo_state is
            when RST  => rst_fifo <= '0';
            when SET  => rst_fifo <= '1';
            when HOLD => rst_fifo <= rst_fifo;
            end case;

            case mux_state is
            when SELECT_UDP  => sel_icmp_int <= '0';
            when SELECT_ICMP => sel_icmp_int <= '1';
            when HOLD        => sel_icmp_int <= sel_icmp_int;
            end case;

        end if;
    end if;
end process;

fdre_valid_0 : process(tx_clk)
begin
    if(rising_edge(tx_clk))then
        if(reset = '1')then
            data_valid_reg <= '0';
        else
            data_valid_reg <= data_valid;
        end if;
    end if;
end process;

fdre_valid_1 : process(tx_clk)
begin
    if(rising_edge(tx_clk))then
        if(reset = '1')then
            icmp_txo.payload.data_out_valid <= '0';
        else
            icmp_txo.payload.data_out_valid <= data_valid_reg;
        end if;
    end if;
end process;

fifo_payload_buffer: icmp_payload_buffer
    PORT MAP (
        rst     => rst_fifo,
        wr_clk  => rx_clk,
        rd_clk  => tx_clk,
        din     => icmp_rxi.payload.data_in,
        wr_en   => icmp_rxi.payload.data_in_valid,
        rd_en   => rd_ena,
        dout    => icmp_txo.payload.data_out,
        full    => fifo_full,
        empty   => fifo_empty
    );
 
    sel_icmp                        <= sel_icmp_int;
    icmp_tx_start                   <= icmp_tx_start_int;
    icmp_txo.payload.data_out_last  <= data_last;

end Behavioral;

