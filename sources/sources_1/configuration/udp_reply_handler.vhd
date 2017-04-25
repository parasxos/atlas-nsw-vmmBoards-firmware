----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch) 
-- 
-- Create Date: 25.04.2017 11:05:21
-- Design Name: UDP Reply Handler
-- Module Name: udp_reply_handler - RTL
-- Project Name: NTUA-BNL VMM3 Readout Firmware
-- Target Devices: Xilinx xc7a200t-2fbg484
-- Tool Versions: Vivado 2016.4
-- Description: Module that sends UDP replies to the configuration software 
-- via UDP.
-- 
-- Dependencies: 
-- 
-- Changelog: 
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity udp_reply_handler is
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk             : in  std_logic;
        enable          : in  std_logic;
        serial_number   : in  std_logic_vector(31 downto 0);
        reply_done      : out std_logic;
        ------------------------------------
        ---- FIFO Data Select Interface ----
        wr_en_conf      : out std_logic;
        dout_conf       : out std_logic_vector(15 downto 0);
        packet_len_conf : out std_logic_vector(11 downto 0);
        end_conf        : out std_logic       
    );
end udp_reply_handler;

architecture RTL of udp_reply_handler is

    signal sn_i         : std_logic_vector(31 downto 0) := (others => '0');
    signal sel_dout     : std_logic_vector(1 downto 0)  := (others => '0');
    signal cnt_packet   : integer range 0 to 7 := 0;

    type stateType is (ST_IDLE, ST_WR_HIGH, ST_WR_LOW, ST_COUNT_AND_DRIVE, ST_DONE);
    signal state : stateType := ST_IDLE;

begin

-- FSM that samples the S/N and sends it back to the configuration software
-- as a UDP reply
UDP_reply_FSM: process(clk)
begin
    if(rising_edge(clk))then
        if(enable = '0')then
            sn_i        <= (others => '0');
            wr_en_conf  <= '0';
            cnt_packet  <=  0;
            end_conf    <= '0';
            reply_done  <= '0';
            state       <= ST_IDLE;
        else
            case state is

            -- sample the serial number and start writing data
            when ST_IDLE =>
                sn_i     <= serial_number;
                state    <= ST_WR_HIGH;

            -- wr_en FIFO high
            when ST_WR_HIGH =>
                wr_en_conf <= '1';
                state      <= ST_WR_LOW;

            -- wr_en FIFO low
            when ST_WR_LOW =>
                wr_en_conf <= '0';
                state      <= ST_COUNT_AND_DRIVE;

            -- increment the counter to select a different dout
            when ST_COUNT_AND_DRIVE =>
                if(cnt_packet < 3)then
                    cnt_packet  <= cnt_packet + 1;
                    state       <= ST_WR_HIGH;
                else
                    end_conf    <= '1';
                    state       <= ST_DONE;
                end if;

            -- stay here until reset by flow_fsm
            when ST_DONE =>
                reply_done  <= '1';
                end_conf    <= '0';

            when others =>
                sn_i        <= (others => '0');
                wr_en_conf  <= '0';
                cnt_packet  <=  0;
                end_conf    <= '0';
                reply_done  <= '0';
                state       <= ST_IDLE;
            end case;
        end if;
    end if;
end process;

-- MUX that drives the apporpiate data to the UDP FIFO
dout_conf_MUX: process(sel_dout, sn_i)
begin
    case sel_dout is
    when "00"   => dout_conf <= sn_i(31 downto 16);
    when "01"   => dout_conf <= sn_i(15 downto 0);
    when "10"   => dout_conf <= x"FFFF";
    when "11"   => dout_conf <= x"FFFF";
    when others => dout_conf <= (others => '0');
    end case;
end process;

    packet_len_conf <= std_logic_vector(to_unsigned(cnt_packet, 12));
    sel_dout        <= std_logic_vector(to_unsigned(cnt_packet, 2));

end RTL;