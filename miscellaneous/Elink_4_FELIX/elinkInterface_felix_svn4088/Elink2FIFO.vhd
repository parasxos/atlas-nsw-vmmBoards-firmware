----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    17/08/2015 
--! Module Name:    Elink2FIFO
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.all;

--! consists of 1 E-path
entity Elink2FIFO is
generic (
    InputDataRate  : integer := 80 -- 80 or 160 MHz
    );
port ( 
    clk40       : in  std_logic;
    clk80       : in  std_logic;
    clk160      : in  std_logic;    
    RSTclk40    : in  std_logic;
    ------
    DATA1bitIN  : in  std_logic;
    ------
    efifoRclk  : in  std_logic;
    efifoRe     : in  std_logic; 
    efifoHF     : out std_logic; -- half-full flag: 1 KByte block is ready to be read
    efifoDout   : out std_logic_vector (15 downto 0)
    ------
    );
end Elink2FIFO;

architecture Behavioral of Elink2FIFO is

----------------------------------
----------------------------------
component EPROC_IN2
port ( 
    bitCLK      : in  std_logic;
    bitCLKx2    : in  std_logic;
    bitCLKx4    : in  std_logic;
    rst         : in  std_logic;
    ENA         : in  std_logic;
    ENCODING    : in  std_logic_vector (1 downto 0);
    EDATA_IN    : in  std_logic_vector (1 downto 0);
    DATA_OUT    : out std_logic_vector (9 downto 0);
    DATA_RDY    : out std_logic
    );
end component;
----------------------------------
----------------------------------
component EPROC_IN4
port ( 
    bitCLK      : in  std_logic;
    bitCLKx2    : in  std_logic;
    bitCLKx4    : in  std_logic;
    rst         : in  std_logic;
    ENA         : in  std_logic;
    ENCODING    : in  std_logic_vector (1 downto 0);
    EDATA_IN    : in  std_logic_vector (3 downto 0);
    DATA_OUT    : out std_logic_vector (9 downto 0);
    DATA_RDY    : out std_logic
    );
end component;
----------------------------------
----------------------------------
component EPROC_FIFO_DRIVER
generic (
    GBTid       : integer := 0;
    egroupID    : integer := 0;
    epathID     : integer := 0
    );
port ( 
    bitCLKx4        : in std_logic;
    rst             : in std_logic;
    FIFOrst_state   : in std_logic;
    maxCLEN     : in std_logic_vector (2 downto 0); 
    DIN         : in std_logic_vector (9 downto 0);
    DIN_RDY     : in std_logic;
    xoff        : in std_logic;
    wordOUT     : out std_logic_vector (15 downto 0);
    wordOUT_RDY : out std_logic
    );
end component;
----------------------------------
----------------------------------
component EPATH_FIFO_WRAP
port (
    rst                 : in  std_logic;
    FIFO_RESET_STATE    : out std_logic;
    wr_clk              : in  std_logic;
    rd_clk              : in  std_logic;
    din                 : in  std_logic_vector(15 downto 0);
    wr_en               : in  std_logic;
    rd_en               : in  std_logic;
    dout                : out std_logic_vector(15 downto 0);
    full                : out std_logic;
    almost_full         : out std_logic;
    empty               : out std_logic;
    rd_data_count       : out std_logic_vector(9 downto 0);
    prog_full           : out std_logic
    );
end component;
----------------------------------
----------------------------------

--
constant maxClen    : std_logic_vector (11 downto 0) := (others => '0'); -- no limit on packet size here
signal DATA2bitIN, shreg2bit : std_logic_vector (1 downto 0) := (others => '0');
signal DATA4bitIN, shreg4bit : std_logic_vector (3 downto 0) := (others => '0');
signal DATA_OUT     : std_logic_vector(9 downto 0); 
signal DATA_RDY, FIFO_RESET_STATE, almost_full, BWORD_RDY  : std_logic;
signal BWORD        : std_logic_vector(15 downto 0); 
----

begin


------------------------------------------------------------
-- E-PATH case 80 MHz
------------------------------------------------------------
InputDataRate80: if InputDataRate = 80 generate

--
process(clk80)
begin
    if clk80'event and clk80 = '1' then
        shreg2bit <= DATA1bitIN & shreg2bit(1);
	end if;
end process;
--
process(clk40)
begin
    if clk40'event and clk40 = '1' then
        DATA2bitIN <= shreg2bit;
	end if;
end process;
---

EPROC_IN2bit: EPROC_IN2 
port map (
	bitCLK     => clk40,
	bitCLKx2   => clk80,
	bitCLKx4   => clk160,
	rst        => RSTclk40,
	ENA        => '1',
	ENCODING   => "10", -- 8b10b
	EDATA_IN   => DATA2bitIN,
	DATA_OUT   => DATA_OUT, 
	DATA_RDY   => DATA_RDY
);

end generate InputDataRate80; 



------------------------------------------------------------
-- E-PATH case 160 MHz
------------------------------------------------------------
InputDataRate160: if InputDataRate = 160 generate

--
process(clk160)
begin
    if clk160'event and clk160 = '1' then
        shreg4bit <= DATA1bitIN & shreg4bit(3 downto 1);
	end if;
end process;
--
process(clk40)
begin
    if clk40'event and clk40 = '1' then
        DATA4bitIN <= shreg4bit;
	end if;
end process;
---

EPROC_IN4bit: EPROC_IN4 
port map (
	bitCLK     => clk40,
	bitCLKx2   => clk80,
	bitCLKx4   => clk160,
	rst        => RSTclk40,
	ENA        => '1',
	ENCODING   => "10", -- 8b10b
	EDATA_IN   => DATA4bitIN,
	DATA_OUT   => DATA_OUT,
	DATA_RDY   => DATA_RDY
);

end generate InputDataRate160; 



------------------------------------------------------------
-- EPATH FIFO DRIVER
------------------------------------------------------------
efd: EPROC_FIFO_DRIVER 
generic map(
    GBTid       => 0, -- no use
    egroupID    => 0, -- no use
    epathID     => 0  -- no use
    )
port map (
    bitCLKx4        => clk160,
    rst             => RSTclk40,
    FIFOrst_state   => FIFO_RESET_STATE,
    maxCLEN         => maxClen,
    DIN             => DATA_OUT,
    DIN_RDY         => DATA_RDY,
    xoff            => almost_full,
    wordOUT         => BWORD, -- block word
    wordOUT_RDY     => BWORD_RDY
    );


------------------------------------------------------------
-- EPATH FIFOs
------------------------------------------------------------
efw: EPATH_FIFO_WRAP
port map (
    rst 	=> RSTclk40,
    FIFO_RESET_STATE => FIFO_RESET_STATE,
    wr_clk 	=> clk160,
    rd_clk 	=> efifoRclk,
    din     => BWORD,
    wr_en 	=> BWORD_RDY,
    rd_en 	=> efifoRe,
    dout 	=> efifoDout,
    full 	=> open,
    almost_full 	=> almost_full,
    empty           => open,
    rd_data_count   => open,
    prog_full       => efifoHF -- Half-Full - output: 1K block is ready
    );


end Behavioral;

