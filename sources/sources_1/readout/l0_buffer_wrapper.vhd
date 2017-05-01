----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch) 
-- 
-- Create Date: 28.04.2017 14:18:44
-- Design Name: Level-0 Buffer Wrapper
-- Module Name: l0_buffer_wrapper - RTL
-- Project Name: NTUA-BNL VMM3 Readout Firmware
-- Target Devices: Xilinx xc7a200t-2fbg484
-- Tool Versions: Vivado 2016.4
-- Description: Wrapper that contains the FIFO that buffers level-0 data, and the
-- necessary acomppanying logic (packet_formation interface)
-- 
-- Dependencies: 
-- 
-- Changelog: 
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity l0_buffer_wrapper is
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk_des         : in  std_logic;
        clk_ckdt        : in  std_logic;
        clk             : in  std_logic;
        rst_buff        : in  std_logic;
        ------------------------------------
        --- Deserializer Interface ---------
        inhib_wr        : out std_logic;
        commas_true     : in  std_logic;
        dout_dec        : in  std_logic_vector(7 downto 0);
        wr_en           : in  std_logic;
        ------------------------------------
        ---- Packet Formation Interface ----
        rd_ena_buff     : in  std_logic;
        rst_intf_proc   : in  std_logic;
        vmmWordReady    : out std_logic;
        vmmWord         : out std_logic_vector(15 downto 0);
        vmmEventDone    : out std_logic
    );
end l0_buffer_wrapper;

architecture RTL of l0_buffer_wrapper is

component level0_buffer
  port (
    wr_clk      : in  std_logic;
    rd_clk      : in  std_logic;
    rst         : in  std_logic;
    din         : in  std_logic_vector(7 downto 0);
    wr_en       : in  std_logic;
    rd_en       : in  std_logic;
    dout        : out std_logic_vector(15 downto 0);
    full        : out std_logic;
    empty       : out std_logic;
    wr_rst_busy : out std_logic;
    rd_rst_busy : out std_logic
  );
end component;

    signal fifo_full        : std_logic := '0';
    signal fifo_empty       : std_logic := '0';
    signal commas_true_i    : std_logic := '0';
    signal commas_true_s125 : std_logic := '0';
    signal inhibit_write    : std_logic := '0';
    signal inhib_wr_i       : std_logic := '0';
    signal inhib_wr_s       : std_logic := '0';
    
    type stateType is (ST_IDLE, ST_READING, ST_DONE);
    signal state : stateType := ST_IDLE;

    attribute ASYNC_REG                       : string;
    attribute ASYNC_REG of commas_true_i      : signal is "TRUE";
    attribute ASYNC_REG of commas_true_s125   : signal is "TRUE";
    attribute ASYNC_REG of inhib_wr_i         : signal is "TRUE";
    attribute ASYNC_REG of inhib_wr_s         : signal is "TRUE";

begin

-- sync 'commas_true'
limit_sync: process(clk)
begin
    if(rising_edge(clk))then
        commas_true_i     <= commas_true;
        commas_true_s125  <= commas_true_i;    
    end if;
end process;

-- FSM that interfaces with packet_formation and vmm_driver
pf_interface_FSM: process(clk)
begin
    if(rising_edge(clk))then
        case state is

        -- if there are data in the buffer and commas are being detected => ready to be read
        when ST_IDLE =>
            if(fifo_empty = '0' and commas_true_s125 = '1')then
                vmmWordReady    <= '1';
                state           <= ST_READING;
            else
                vmmWordReady    <= '0';
                state           <= ST_IDLE;
            end if;

        -- wait for pf to empty the buffer and prevent any further writes
        when ST_READING =>     
            inhibit_write <= '1';
                       
            if(fifo_empty = '0')then
                state           <= ST_READING;
            else
                vmmWordReady    <= '0';
                vmmEventDone    <= '1';
                state           <= ST_DONE;
            end if;

        -- stay here until reset by pf
        when ST_DONE =>
            vmmWordReady    <= '0';
            vmmEventDone    <= '1';
            if(rst_intf_proc = '1')then
                state   <= ST_IDLE;
            else
                state   <= ST_DONE;
            end if;

        when others =>
            vmmWordReady    <= '0';
            vmmEventDone    <= '0';
            inhibit_write   <= '0';
            state           <= ST_IDLE;
        end case;
    end if;
end process;

-- sync inhibit_write to clk_ckdt
inhib_wr_sync_proc: process(clk_ckdt)
begin
    if(rising_edge(clk_ckdt))then
        inhib_wr_i <= inhibit_write;
        inhib_wr_s <= inhib_wr_i;
    end if;
end process;

l0_buffering_fifo: level0_buffer
    port map(
        rst         => rst_buff,
        wr_clk      => clk_ckdt,
        rd_clk      => clk,
        din         => dout_dec,
        wr_en       => wr_en,
        rd_en       => rd_ena_buff,
        dout        => vmmWord,
        full        => fifo_full,
        empty       => fifo_empty,
        wr_rst_busy => open,
        rd_rst_busy => open
    );
    
    inhib_wr <= inhib_wr_s;

end RTL;