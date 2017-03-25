----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    09/14/2014 
--! Module Name:    EPATH_FIFO_WRAP
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

--! EPATH FIFO 16 bit wide, 1K deep
entity EPATH_FIFO_WRAP is
port (   
    rst         : in std_logic;
    fifoFlush   : in std_logic;
    wr_clk      : in std_logic;
    rd_clk      : in std_logic;
    din         : in std_logic_vector(15 downto 0);
    wr_en       : in std_logic;
    rd_en       : in std_logic;
    dout        : out std_logic_vector(15 downto 0);
    full        : out std_logic;
    almost_full : out std_logic;
    empty       : out std_logic;
    rd_data_count : out std_logic_vector(9 downto 0);
    prog_full   : out std_logic
    );
end EPATH_FIFO_WRAP;

architecture Behavioral of EPATH_FIFO_WRAP is

----------------------------------
----------------------------------
component EPATH_FIFO -- IP
port (
    wr_clk      : in std_logic;
    wr_rst      : in std_logic;
    rd_clk      : in std_logic;
    rd_rst      : in std_logic;
    din         : in std_logic_vector(15 downto 0);
    wr_en       : in std_logic;
    rd_en       : in std_logic;
    dout        : out std_logic_vector(15 downto 0);
    full        : out std_logic;
    almost_full : out std_logic;
    empty       : out std_logic;
    rd_data_count : out std_logic_vector(9 downto 0);
    prog_full   : out std_logic;
    prog_empty  : out std_logic;
    prog_empty_thresh : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    prog_full_thresh : IN STD_LOGIC_VECTOR(9 DOWNTO 0)
  );
end component;
----------------------------------
----------------------------------

signal rd_en_s, wr_en_s : std_logic;
signal prog_full_s, full_s, empty_s, prog_empty_s : std_logic;
signal rst_state : std_logic;

begin

--
rd_en_s <= rd_en and (not rst_state);
wr_en_s <= wr_en and (not rst_state);
--
EPATH_FIFO_INST: EPATH_FIFO 
PORT MAP (
	wr_clk     => wr_clk, 
	wr_rst     => fifoFlush,
	rd_clk     => rd_clk, 
	rd_rst     => fifoFlush,
	din        => din,
	wr_en      => wr_en_s,
	rd_en      => rd_en_s,
	dout       => dout,
	full       => full_s,
	almost_full => open, --almost_full,
	empty      => empty_s,
	rd_data_count => rd_data_count, -- behavioral simulation only, optimized out
	prog_full  => prog_full_s,
	prog_empty => prog_empty_s,
	prog_full_thresh  => std_logic_vector(to_unsigned(512, 10)),
    prog_empty_thresh => std_logic_vector(to_unsigned(1010, 10))
);
--
rst_state <= rst or (full_s and empty_s);
--
full  <= full_s; -- wr_clk domain
empty <= empty_s;-- rd_clk domain
--
process(rd_clk)
begin
	if rd_clk'event and rd_clk = '1' then
        prog_full <= prog_full_s and (not rst_state);
	end if;
end process;
--
process(wr_clk)
begin
	if wr_clk'event and wr_clk = '1' then
        almost_full <= not prog_empty_s;
	end if;
end process;
--

end Behavioral;

