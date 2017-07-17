----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Copyright Notice/Copying Permission:
--    Copyright 2017 Christos Bakalis
--
--    This file is part of NTUA-BNL_VMM_firmware.
--
--    NTUA-BNL_VMM_firmware is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    NTUA-BNL_VMM_firmware is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with NTUA-BNL_VMM_firmware.  If not, see <http://www.gnu.org/licenses/>.
--
-- Create Date: 03.02.2017
-- Design Name: ICMP Transmitter
-- Module Name: ICMP_TX - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions: Vivado 2016.2
-- Description: Handles simple ICMP TX
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

entity ICMP_TX is
    Port(
        -- ICMP layer signals
        icmp_tx_start           : in  std_logic;                       -- indicates req to tx ICMP
        icmp_txi                : in  icmp_tx_type;                    -- icmp tx cxns
        icmp_tx_data_out_ready  : out std_logic;                       -- indicates icmp_tx is ready to take data
        -- system signals
        clk                     : in  STD_LOGIC;                       -- same clock used to clock mac data and ip data
        reset                   : in  STD_LOGIC;
        icmp_tx_is_idle         : out STD_LOGIC; 
        -- IP layer TX signals
        ip_tx_start             : out std_logic;
        ip_tx                   : out ipv4_tx_type;                    -- IP tx cxns
        ip_tx_result            : in  std_logic_vector (1 downto 0);   -- tx status (changes during transmission)
        ip_tx_data_out_ready    : in  std_logic                        -- indicates IP TX is ready to take data
        );
end ICMP_TX;

architecture Behavioral of ICMP_TX is
    type tx_state_type is (IDLE, PAUSE, SEND_ICMP_HDR, SEND_PAYLOAD);

    type count_mode_type is (RST, INCR, HOLD);
    type settable_cnt_type is (RST, SET, INCR, HOLD);
    type set_clr_type is (SET, CLR, HOLD);

    -- TX state variables
    signal icmp_tx_state        : tx_state_type;
    signal tx_count             : unsigned (15 downto 0);
    signal ip_tx_start_reg      : std_logic;
    signal data_out_ready_reg   : std_logic;
    signal icmp_tx_is_idle_reg  : std_logic;

    -- tx control signals
    signal next_tx_state        : tx_state_type;
    signal set_tx_state         : std_logic;
    signal tx_count_val         : unsigned (15 downto 0);
    signal tx_count_mode        : settable_cnt_type;
    signal tx_is_idle_state     : set_clr_type;
    signal tx_data              : std_logic_vector (7 downto 0);
    signal set_last             : std_logic;
    signal set_ip_tx_start      : set_clr_type;
    signal tx_data_valid        : std_logic;            -- indicates whether data is valid to tx or not

    -- tx temp signals
    signal total_length     : std_logic_vector (15 downto 0);   -- computed combinatorially from header size

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

    tx_combinatorial : process(
        -- input signals
        icmp_tx_start, icmp_txi, clk, ip_tx_result, ip_tx_data_out_ready,
        -- state variables
        icmp_tx_state, tx_count, ip_tx_start_reg, data_out_ready_reg,
        icmp_tx_is_idle_reg,
        -- control signals
        next_tx_state, set_tx_state, tx_count_mode, tx_count_val,
        tx_data, set_last, total_length, set_ip_tx_start, tx_data_valid
        )

    begin
        icmp_tx_is_idle         <= icmp_tx_is_idle_reg;
        -- set output followers
        ip_tx_start             <= ip_tx_start_reg;
        ip_tx.hdr.protocol      <= x"01";    -- ICMP protocol
        ip_tx.hdr.data_length   <= total_length;
        ip_tx.hdr.dst_ip_addr   <= icmp_txi.hdr.dst_ip_addr;

        case icmp_tx_state is
            when SEND_PAYLOAD =>
                ip_tx.data.data_out         <= icmp_txi.payload.data_out;
                tx_data_valid               <= icmp_txi.payload.data_out_valid;
                ip_tx.data.data_out_last    <= icmp_txi.payload.data_out_last;

            when SEND_ICMP_HDR =>
                ip_tx.data.data_out         <= tx_data;
                tx_data_valid               <= ip_tx_data_out_ready;
                ip_tx.data.data_out_last    <= set_last;

            when others =>
                ip_tx.data.data_out         <= (others => '0');
                tx_data_valid               <= '0';
                ip_tx.data.data_out_last    <= set_last;
        end case;

        ip_tx.data.data_out_valid <= tx_data_valid and ip_tx_data_out_ready;

        -- set signal defaults
        next_tx_state           <= IDLE;
        set_tx_state            <= '0';
        tx_count_mode           <= HOLD;
        tx_data                 <= x"00";
        set_last                <= '0';
        set_ip_tx_start         <= HOLD;
        tx_is_idle_state        <= SET;
        tx_count_val            <= (others => '0');
        icmp_tx_data_out_ready  <= '0';

        -- set temp signals
        total_length <= std_logic_vector(unsigned(icmp_txi.hdr.icmp_pay_len) + 8);        -- total length = user data length + header length (bytes)

        -- TX FSM
        case icmp_tx_state is
            when IDLE =>
                icmp_tx_data_out_ready  <= '0';       -- in this state, we are unable to accept user data for tx
                tx_count_mode           <= RST;
                tx_is_idle_state        <= SET;

                if icmp_tx_start = '1' then
                    tx_count_mode   <= RST;
                    set_ip_tx_start <= SET;
                    next_tx_state   <= PAUSE;
                    set_tx_state    <= '1';
                end if;

            when PAUSE =>
                -- delay one clock for IP layer to respond to ip_tx_start and remove any tx error result
                next_tx_state       <= SEND_ICMP_HDR;
                tx_is_idle_state    <= CLR;
                set_tx_state        <= '1';

            when SEND_ICMP_HDR =>
                icmp_tx_data_out_ready  <= '0';       -- in this state, we are unable to accept user data for tx
                tx_is_idle_state        <= HOLD;
                if ip_tx_result = IPTX_RESULT_ERR then          -- 10
                    set_ip_tx_start <= CLR;
                    next_tx_state   <= IDLE;
                    set_tx_state    <= '1';
                elsif ip_tx_data_out_ready = '1' then
                    if tx_count = x"0007" then
                        tx_count_val <= x"0001";
                        tx_count_mode <= SET;
                        next_tx_state <= SEND_PAYLOAD;
                        set_tx_state <= '1';
                    else
                        tx_count_mode <= INCR;
                    end if;
                    case tx_count is
                        when x"0000"  => tx_data <= icmp_txi.hdr.icmp_type (7 downto 0);    -- type
                        when x"0001"  => tx_data <= icmp_txi.hdr.icmp_code (7 downto 0);    -- code
                        when x"0002"  => tx_data <= icmp_txi.hdr.icmp_chksum (15 downto 8); -- checksum 1/2
                        when x"0003"  => tx_data <= icmp_txi.hdr.icmp_chksum (7 downto 0);  -- checksum 2/2
                        when x"0004"  => tx_data <= icmp_txi.hdr.icmp_ident (15 downto 8);  -- identifier 1/2
                        when x"0005"  => tx_data <= icmp_txi.hdr.icmp_ident (7 downto 0);   -- identifier 2/2 
                        when x"0006"  => tx_data <= icmp_txi.hdr.icmp_seqNum (15 downto 8); -- sequence number 1/2
                        when x"0007"  => tx_data <= icmp_txi.hdr.icmp_seqNum (7 downto 0);  -- sequence number 2/2
                        when others =>
                    end case;
                end if;

            when SEND_PAYLOAD =>
                icmp_tx_data_out_ready <= ip_tx_data_out_ready;  -- in this state, we can accept user data if IP TX rdy

                if ip_tx_data_out_ready = '1' then
                    if icmp_txi.payload.data_out_valid = '1' or tx_count = x"000" then
                        -- only increment if ready and valid has been subsequently established, otherwise data count moves on too fast
                        if unsigned(tx_count) = unsigned(icmp_txi.hdr.icmp_pay_len) then
                            -- TX terminated due to count - end normally
                            set_last            <= '1';
                            tx_data             <= icmp_txi.payload.data_out;
                            set_ip_tx_start     <= CLR;
                            next_tx_state       <= IDLE;
                            set_tx_state        <= '1';
                        elsif icmp_txi.payload.data_out_last = '1' then
                            -- terminate tx with error as got last from upstream before exhausting count
                            set_last            <= '1';
                            tx_data             <= icmp_txi.payload.data_out;
                            set_ip_tx_start     <= CLR;
                            next_tx_state       <= IDLE;
                            set_tx_state        <= '1';
                        else
                            -- TX continues
                            tx_count_mode       <= INCR;
                            tx_data             <= icmp_txi.payload.data_out;
                        end if;
                    end if;
                end if;

        end case;
    end process;

    -----------------------------------------------------------------------------
    -- sequential process to action control signals and change states and outputs
    -----------------------------------------------------------------------------

    tx_sequential : process (clk,reset,data_out_ready_reg)
    begin
        if rising_edge(clk) then
            data_out_ready_reg <= ip_tx_data_out_ready;
        else
            data_out_ready_reg <= data_out_ready_reg;
        end if;

        if rising_edge(clk) then
            if reset = '1' then
                -- reset state variables
                icmp_tx_state       <= IDLE;
                tx_count            <= x"0000";
                icmp_tx_is_idle_reg <= '0';
                ip_tx_start_reg     <= '0';
            else
                -- Next icmp_tx_state processing
                if set_tx_state = '1' then
                    icmp_tx_state <= next_tx_state;
                else
                    icmp_tx_state <= icmp_tx_state;
                end if;

                -- ip_tx_start_reg processing
                case set_ip_tx_start is
                    when SET  => ip_tx_start_reg <= '1';
                    when CLR  => ip_tx_start_reg <= '0';
                    when HOLD => ip_tx_start_reg <= ip_tx_start_reg;
                end case;
                
                -- state signal to be used by reply processor
                case tx_is_idle_state is
                    when SET  => icmp_tx_is_idle_reg <= '1';
                    when CLR  => icmp_tx_is_idle_reg <= '0';
                    when HOLD => icmp_tx_is_idle_reg <= icmp_tx_is_idle_reg;
                end case;

                -- tx_count processing
                case tx_count_mode is
                    when RST  =>    tx_count <= x"0000";
                    when SET  =>    tx_count <= tx_count_val;
                    when INCR =>    tx_count <= tx_count + 1;
                    when HOLD =>    tx_count <= tx_count;
                end case;

            end if;
        end if;
    end process;


end Behavioral;

