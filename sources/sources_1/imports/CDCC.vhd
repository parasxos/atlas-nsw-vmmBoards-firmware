----------------------------------------------------------------------------------
-- Company: NTU ATHENS - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Create Date: 19.12.2016 13:35:28
-- Design Name: Clock Domain Crossing Circuit
-- Module Name: CDCC - RTL
-- Project Name: CDCC
-- Target Devices: All Xilinx devices
-- Tool Versions: Vivado 2016.2
-- Description: This design instantiates a number of cascaded DFFs, which are used
-- to synchronize data that are crossing clock domains. The user must provide the
-- source clock and the destination clock, as well as the number of bits that are
-- to be synchronized.
-- 
-- Changelog:
-- 12.01.2017 Added ASYNC_REG attribute to the internal interconnecting signals.
-- Added an extra stage of registers for the input signals (Christos Bakalis).
--
----------------------------------------------------------------------------------

library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use UNISIM.VComponents.all;

entity CDCC is
generic(
    NUMBER_OF_BITS : integer := 8); -- number of signals to be synced
port(
    clk_src     : in  std_logic;                                        -- input clk (source clock)
    clk_dst     : in  std_logic;                                        -- input clk (dest clock)
    data_in     : in  std_logic_vector(NUMBER_OF_BITS - 1 downto 0);    -- data to be synced
    data_out_s  : out std_logic_vector(NUMBER_OF_BITS - 1 downto 0)     -- synced data to clk_dst
    );
end CDCC;

architecture RTL of CDCC is
    
    signal data_in_int          : std_logic_vector(NUMBER_OF_BITS - 1 downto 0) := (others => '0');
    signal data_in_reg          : std_logic_vector(NUMBER_OF_BITS - 1 downto 0) := (others => '0');
    signal data_sync_stage_0    : std_logic_vector(NUMBER_OF_BITS - 1 downto 0) := (others => '0');
    signal data_out_s_int       : std_logic_vector(NUMBER_OF_BITS - 1 downto 0) := (others => '0');

    attribute ASYNC_REG                         : string;
    attribute ASYNC_REG of data_in_int          : signal is "true";
    attribute ASYNC_REG of data_in_reg          : signal is "true";
    attribute ASYNC_REG of data_sync_stage_0    : signal is "true";
    attribute ASYNC_REG of data_out_s_int       : signal is "true";

begin

-------------------------------------------------------
-- Register the input signals
-------------------------------------------------------
reg_input_CDCC: for I in 0 to (NUMBER_OF_BITS - 1) generate
FDRE_reg_input_CDCC: FDRE
    generic map (INIT => '0')
    port map(
        Q   => data_in_reg(I),
        C   => clk_src,
        CE  => '1',
        R   => '0',
        D   => data_in_int(I)
        );
end generate reg_input_CDCC;

-------------------------------------------------------
-- Synchronization stage 0
-------------------------------------------------------
sync_block_CDCC_0: for I in 0 to (NUMBER_OF_BITS - 1) generate
FDRE_sync_CDCC_0: FDRE
    generic map (INIT => '0')
    port map(
        Q   => data_sync_stage_0(I),
        C   => clk_dst,
        CE  => '1',
        R   => '0',
        D   => data_in_reg(I)
        );
end generate sync_block_CDCC_0;

-------------------------------------------------------
-- Synchronization stage 1
-------------------------------------------------------
sync_block_CDCC_1: for I in 0 to (NUMBER_OF_BITS - 1) generate
FDRE_sync_CDCC_1: FDRE
    generic map (INIT => '0')
    port map(
        Q   => data_out_s_int(I),
        C   => clk_dst,
        CE  => '1',
        R   => '0',
        D   => data_sync_stage_0(I)
        );
end generate sync_block_CDCC_1;

    data_in_int <= data_in;
    data_out_s  <= data_out_s_int;

end RTL;