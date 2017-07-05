----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Create Date: 11/16/2016 03:11:54 PM
-- Design Name: ELINK_TX
-- Module Name: elink_daq_driver - Behavioral
-- Project Name: 
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Changelog:
-- 29.11.2016 Changed the appending of the SOP, MOP, EOP flag with respect to the
-- data, to comply with the updated FIFO2Elink module. The data appended with the
-- SOP/EOP flags are omitted in the rx-side of the E-LINK. (Christos Bakalis)
-- 03.12.2016 Removed the ILA of the component and increased the write limit
-- to 400 bytes. Altered the FIFO to operate in two clock domains. Minor changes 
-- in state order and naming. (Christos Bakalis)
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity elink_daq_driver is
    Port(
        ---------------------------
        ---- general interface ---- 
        clk_in      : in std_logic;
        wr_clk      : in std_logic;
        fifo_flush  : in std_logic;
        rst         : in std_logic;
        driver_ena  : in std_logic;
        ---------------------------
        ------- pf interface ------
        din_daq     : in std_logic_vector(63 downto 0);
        wr_en_daq   : in std_logic;
        ---------------------------
        ------ elink inteface -----
        empty_elink : in std_logic;
        wr_en_elink : out std_logic;
        dout_elink  : out std_logic_vector(17 downto 0)
        );
end elink_daq_driver;

architecture Behavioral of elink_daq_driver is

COMPONENT ila_daq_elink_drv
PORT(
	clk    : IN STD_LOGIC;
    probe0 : IN STD_LOGIC_VECTOR(139 DOWNTO 0)
    );
END COMPONENT;

COMPONENT DAQelinkFIFO
    PORT(
        rst                 : IN STD_LOGIC;
        wr_clk              : IN STD_LOGIC;
        rd_clk              : IN STD_LOGIC;
        din                 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
        wr_en               : IN STD_LOGIC;
        rd_en               : IN STD_LOGIC;
        dout                : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        prog_empty_thresh   : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        full                : OUT STD_LOGIC;
        empty               : OUT STD_LOGIC;
        prog_empty          : OUT STD_LOGIC
    );
END COMPONENT;

    signal rd_en_daq        : std_logic := '0';
    signal dout_daq         : std_logic_vector(15 downto 0) := (others => '0');
    signal full_daq         : std_logic := '0';
    signal empty_daq        : std_logic := '0';
    signal flag             : std_logic_vector(1 downto 0) := (others => '0');
    signal check_state      : std_logic_vector(3 downto 0) := (others => '0');
    signal cnt_word         : integer := 0;
    signal cnt_sig          : std_logic_vector(7 downto 0) := (others => '0');
    signal prog_empty_sig   : std_logic_vector(11 downto 0) := (others => '0');
    signal limit_64bitWords : integer := 50; -- write 50x64-bit words first, then start reading the FIFO
    signal write_limit      : integer := 0;
    signal wait_Cnt         : integer := 0;
    signal wr_en_elink_i    : std_logic := '0';
    signal dout_elink_i     : std_logic_vector(17 downto 0) := (others => '0'); 

    constant SOP        : std_logic_vector(1 downto 0) := "10";
    constant MOP        : std_logic_vector(1 downto 0) := "00";
    constant EOP        : std_logic_vector(1 downto 0) := "01";

    type stateType is (IDLE, DELAY_CHECK_DRV_FIFO, CHECK_DRV_FIFO, WRITE_SOP, READ_HIGH, READ_LOW, CHECK_CNT, DELAY_WRITE, WRITE_HIGH, WRITE_LOW); 
    signal state : stateType := IDLE;

    attribute FSM_ENCODING          : string;
    attribute FSM_ENCODING of state : signal is "ONE_HOT";
    
    signal din_daq_ila      : std_logic_vector(63 downto 0) := (others => '0');
    signal wr_en_daq_ila    : std_logic := '0';
    signal empty_elink_ila  : std_logic := '0';  
    signal driver_ena_ila   : std_logic := '0'; 
    
--    signal probe_ila : std_logic_vector(139 downto 0) := (others => '0');
    
    attribute mark_debug    : string;
        
--    attribute mark_debug of rd_en_daq       : signal is "true";
--    attribute mark_debug of dout_daq        : signal is "true";
--    attribute mark_debug of full_daq        : signal is "true";
--    attribute mark_debug of empty_daq       : signal is "true";
--    attribute mark_debug of flag            : signal is "true";
--    attribute mark_debug of check_state     : signal is "true";
--    attribute mark_debug of cnt_sig         : signal is "true";
--    attribute mark_debug of prog_empty_sig  : signal is "true";
--    attribute mark_debug of wr_en_elink_i   : signal is "true";
--    attribute mark_debug of dout_elink_i    : signal is "true";
--    attribute mark_debug of din_daq_ila     : signal is "true";
--    attribute mark_debug of wr_en_daq_ila   : signal is "true";
--    attribute mark_debug of empty_elink_ila : signal is "true";
--    attribute mark_debug of driver_ena_ila  : signal is "true";

begin

driverFSM: process(clk_in)
begin
    if(rising_edge(clk_in))then
        if(rst = '1')then
            rd_en_daq       <= '0';
            wr_en_elink_i   <= '0';
            cnt_word        <= 0;
            wait_Cnt        <= 0;
            flag            <= "00";
            check_state     <= (others => '0');
            state           <= IDLE;
        else
            case state is

            when IDLE => -- wait for elink fifo to be emptied
                check_state <= "0001";
                flag        <= SOP;

                if(empty_elink = '1' and driver_ena = '1')then
                    state <= DELAY_CHECK_DRV_FIFO;
                else
                    state <= IDLE;
                end if;
                
            when DELAY_CHECK_DRV_FIFO => -- hold delay to allow FIFO2Elink to send comma characters
                check_state <= "0010";
                
                if(wait_Cnt < 1_000)then
                    wait_Cnt    <= wait_Cnt + 1;
                    state       <= DELAY_CHECK_DRV_FIFO;
                else
                    wait_Cnt    <= 0;
                    state       <= CHECK_DRV_FIFO;
                end if;

            when CHECK_DRV_FIFO =>
                check_state <= "0011";

                if(empty_daq = '0')then -- if driverFIFO has data, proceed to transmission
                    state   <= WRITE_SOP;
                else
                    state   <= CHECK_DRV_FIFO; -- driverFIFO has no data, wait for data
                end if;
                
            when WRITE_SOP =>   -- write the SOP packet
                check_state     <= "0100";
                wr_en_elink_i   <= '1';
                state           <= READ_HIGH;

            when READ_HIGH =>  -- pass one 16-bit word to the bus
                check_state     <= "0101";
                wr_en_elink_i   <= '0';
                rd_en_daq       <= '1';
                cnt_word        <= cnt_word + 1;
                state           <= READ_LOW;

            when READ_LOW =>
                check_state <= "0110";
                rd_en_daq   <= '0';
                state       <= CHECK_CNT;

            when CHECK_CNT => -- append the correct elink flag to the 16-bit word
                check_state <= "0111";
                
                if(cnt_word <= write_limit)then
                    flag    <= MOP;
                    state   <= DELAY_WRITE;
                elsif(cnt_word > write_limit)then
                    flag    <= EOP;
                    state   <= DELAY_WRITE;
                else
                    flag    <= "00";
                    state   <= CHECK_CNT;
                end if;

            when DELAY_WRITE => -- delay to ensure correct passing of data
                check_state <= "1000";
                if(wait_Cnt < 3)then
                    wait_Cnt    <= wait_Cnt + 1;
                    state       <= DELAY_WRITE;
                else
                    wait_Cnt    <= 0;
                    state       <= WRITE_HIGH;
                end if;

            when WRITE_HIGH => -- write the 18-bit word to the elinkFIFO (flag & daqDATA)
                check_state     <= "1001";
                wr_en_elink_i   <= '1';
                state           <= WRITE_LOW;

            when WRITE_LOW => -- if the maximum amount of words have been read/written, 
                              -- the DAQelinkFIFO is probably now empty. Go to IDLE and wait for
                              -- more data. Otherwise keep passing new 16-bit words to the ELINK
                check_state     <= "1010";
                wr_en_elink_i   <= '0';

                if(cnt_word <= write_limit)then
                    state       <= READ_HIGH; -- keep reading the fifo
                else
                    cnt_word    <= 0;         -- go to IDLE and wait for more DAQ data to come
                    state       <= IDLE;
                end if;

            when others => state <= IDLE;
            end case;
        end if;
    end if;
end process;

driverFIFO: DAQelinkFIFO
  PORT MAP (
    rst                 => fifo_flush,
    wr_clk              => wr_clk,
    rd_clk              => clk_in,
    din                 => din_daq,
    wr_en               => wr_en_daq,
    rd_en               => rd_en_daq,
    dout                => dout_daq,
    prog_empty_thresh   => prog_empty_sig,
    full                => full_daq,
    prog_empty          => empty_daq,
    empty               => open    
  );

  write_limit       <= limit_64bitWords*4;
  dout_elink_i      <= flag & dout_daq;
  cnt_sig           <= std_logic_vector(to_unsigned(cnt_word, 8));
  prog_empty_sig    <= std_logic_vector(to_unsigned(write_limit-4, 12));
  wr_en_daq_ila     <= wr_en_daq;
  empty_elink_ila   <= empty_elink;
  driver_ena_ila    <= driver_ena;
  din_daq_ila       <= din_daq;
  
  dout_elink        <= dout_elink_i;
  wr_en_elink       <= wr_en_elink_i;
    
end Behavioral;
