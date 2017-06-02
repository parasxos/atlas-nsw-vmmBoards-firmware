----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch) 
-- 
-- Create Date: 25.04.2017 17:45:32
-- Design Name: VMM Driver
-- Module Name: vmm_driver - RTL
-- Project Name: NTUA-BNL VMM3 Readout Firmware
-- Target Devices: Xilinx xc7a200t-2fbg484
-- Tool Versions: Vivado 2016.4
-- Description: This module drives the data from the vmm_readout component
-- to the FIFO2UDP component.
-- 
-- Dependencies: packet_formation.vhd 
-- 
-- Changelog: 
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity vmm_driver is
    generic(vmmReadoutMode : std_logic);
    port(
        ------------------------------------
        ------ General/PF Interface --------
        clk             : in  std_logic;
        drv_enable      : in  std_logic;
        drv_done        : out std_logic;
        pack_len_drv    : out std_logic_vector(11 downto 0);
        ------------------------------------
        ----- VMM_RO/FIFO2UDP Interface ----
        wr_en_fifo2udp  : out std_logic;
        rd_en_l0_buff   : out std_logic;
        vmmWordReady    : in  std_logic;
        sel_data        : out std_logic_vector(1 downto 0)
    );
end vmm_driver;

architecture RTL of vmm_driver is

    signal cnt_chunk        : unsigned(1 downto 0) := (others => '0');
    signal wait_cnt_l0      : integer range 0 to 15 := 0;
    signal wait_cnt_cont    : integer range 0 to 15 := 0;
    signal packLen_i        : unsigned(11 downto 0) := (others => '0');

    type stateType_l0 is (ST_IDLE, ST_WAIT, ST_CHECK_FIFO, ST_RD_LOW, ST_WR_LOW, ST_DONE);
    signal state_l0 : stateType_l0 := ST_IDLE;

    type stateType_cont is (ST_IDLE, ST_WAIT_0, ST_WR_HIGH, ST_WR_LOW, ST_WAIT_1, ST_COUNT_AND_DRIVE, ST_DONE);
    signal state_cont : stateType_cont := ST_IDLE;

begin

------------------------------------------------------------
-- Level-0 Enabled
------------------------------------------------------------
l0_case: if vmmReadoutMode = '1' generate

l0_FSM_drv: process(clk)
begin
    if(rising_edge(clk))then
        if(drv_enable = '0')then
            drv_done        <= '0';
            wait_cnt_l0     <=  0;
            rd_en_l0_buff   <= '0';
            wr_en_fifo2udp  <= '0';
            packLen_i       <= (others => '0');
            state_l0        <= ST_IDLE;
        else
            case state_l0 is

            -- reset the counter and begin the process
            when ST_IDLE =>
                packLen_i   <= (others => '0');
                state_l0    <= ST_WAIT;
            
            -- intermediate state for data bus stabilization    
            when ST_WAIT =>
                if(wait_cnt_l0 < 15)then
                    wait_cnt_l0 <= wait_cnt_l0 + 1;
                    state_l0    <= ST_WAIT;
                else
                    wait_cnt_l0 <= 0;
                    state_l0    <= ST_CHECK_FIFO;
                end if;
               
            -- read the vmm buffer if there is still data
            when ST_CHECK_FIFO =>
                if(vmmWordReady = '1')then
                    rd_en_l0_buff   <= '1';
                    state_l0        <= ST_RD_LOW;    
                else
                    rd_en_l0_buff   <= '0';
                    pack_len_drv    <= std_logic_vector(packLen_i);
                    state_l0        <= ST_DONE;           
                end if;

            -- stay here for 15 cycles for data bus stabilization
            when ST_RD_LOW =>
                rd_en_l0_buff <= '0';

                if(wait_cnt_l0 < 15)then
                    wait_cnt_l0     <= wait_cnt_l0 + 1;
                    wr_en_fifo2udp  <= '0';
                    state_l0        <= ST_RD_LOW;
                else
                    wait_cnt_l0     <= 0;
                    wr_en_fifo2udp  <= '1';
                    state_l0        <= ST_WR_LOW;
                end if;

            -- increment the packLen counter
            when ST_WR_LOW =>
                wr_en_fifo2udp <= '0';
                packLen_i      <= packLen_i + 1;
                state_l0       <= ST_WAIT;

            -- stay here until reset by pf
            when ST_DONE =>
                drv_done <= '1';

            when others => 
                drv_done        <= '0';
                wait_cnt_l0     <=  0;
                rd_en_l0_buff   <= '0';
                wr_en_fifo2udp  <= '0';
                packLen_i       <= (others => '0');
                state_l0        <= ST_IDLE;
            end case;
        end if;
    end if;
end process;

end generate l0_case;

------------------------------------------------------------
-- Level-0 Disabled
------------------------------------------------------------
continuous_case: if vmmReadoutMode = '0' generate

cont_FSM_drv: process(clk)
begin
    if(rising_edge(clk))then
        if(drv_enable = '0')then
            wait_cnt_cont   <= 0;
            wr_en_fifo2udp  <= '0';
            drv_done        <= '0';
            cnt_chunk       <= (others => '0');
            state_cont      <= ST_IDLE;
        else
            case state_cont is

            -- begin the process
            when ST_IDLE =>
                state_cont  <= ST_WAIT_0;
            
            -- intermediate state for data bus stabilization    
            when ST_WAIT_0 =>
                if(wait_cnt_cont < 10)then
                    wait_cnt_cont   <= wait_cnt_cont + 1;
                    state_cont      <= ST_WAIT_0;
                else
                    wait_cnt_cont   <= 0;
                    state_cont      <= ST_WR_HIGH;
                end if;

            -- wr_en FIFO2UDP high
            when ST_WR_HIGH =>
                wr_en_fifo2udp  <= '1';
                state_cont      <= ST_WR_LOW;

            -- wr_en FIFO2UDP low
            when ST_WR_LOW =>
                wr_en_fifo2udp  <= '0';
                state_cont      <= ST_WAIT_1;
            
            -- wait before changing the mux select signal @ vmm_ro    
            when ST_WAIT_1 =>
                if(wait_cnt_cont < 10)then
                    wait_cnt_cont   <= wait_cnt_cont + 1;
                    state_cont      <= ST_WAIT_1;
                else
                    wait_cnt_cont   <= 0;
                    state_cont      <= ST_COUNT_AND_DRIVE;
                end if;
                
            -- increment the counter to select a different chunk of the vmm word
            when ST_COUNT_AND_DRIVE =>
                if(cnt_chunk < 3)then
                    cnt_chunk       <= cnt_chunk + 1;
                    state_cont      <= ST_WAIT_0;
                else
                    state_cont      <= ST_DONE;
                end if;

            -- stay here until reset by packet_formation
            when ST_DONE =>
                drv_done <= '1';

            when others =>
                wait_cnt_cont   <= 0;
                wr_en_fifo2udp  <= '0';
                drv_done        <= '0';
                cnt_chunk       <= (others => '0');
                state_cont      <= ST_IDLE;
            end case;
        end if;
    end if;
end process;

    sel_data <= std_logic_vector(cnt_chunk);

end generate continuous_case;

end RTL;