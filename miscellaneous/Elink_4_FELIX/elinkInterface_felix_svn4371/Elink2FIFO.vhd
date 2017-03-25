----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    17/08/2015 
--! Module Name:    Elink2FIFO
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.all;
use work.all;

--! consists of 1 E-path
entity Elink2FIFO is
generic (
    InputDataRate   : integer := 80; -- 80 or 160 MHz
    elinkEncoding   : std_logic_vector (1 downto 0)
    );
port ( 
    clk40       : in  std_logic;
    clk80       : in  std_logic;
    clk160      : in  std_logic;    
    rst         : in  std_logic;
    fifo_flush  : in  std_logic;
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

EPROC_IN2bit: entity work.EPROC_IN2 
port map (
	bitCLK     => clk40,
	bitCLKx2   => clk80,
	bitCLKx4   => clk160,
	rst        => rst,
	ENA        => '1', -- always enabled here
	swap_inputbits => '0', -- when '1', the input bits will be swapped
	ENCODING   => elinkEncoding,  -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding 
	EDATA_IN   => DATA2bitIN, -- @ 40MHz
	DATA_OUT   => DATA_OUT,  -- 10-bit data out
	DATA_RDY   => DATA_RDY,
	busyOut    => open -- not in use here
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

EPROC_IN4bit: entity work.EPROC_IN4 
port map (
	bitCLK     => clk40,
	bitCLKx2   => clk80,
	bitCLKx4   => clk160,
	rst        => rst,
	ENA        => '1', -- always enabled here
	ENCODING   => elinkEncoding,  -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding 
	EDATA_IN   => DATA4bitIN, -- @ 40MHz
	DATA_OUT   => DATA_OUT,  -- 10-bit data out
	DATA_RDY   => DATA_RDY,
	busyOut    => open -- not in use here
);

end generate InputDataRate160; 



------------------------------------------------------------
-- EPATH FIFO DRIVER
------------------------------------------------------------
efd: entity work.EPROC_FIFO_DRIVER 
generic map(
    GBTid       => 0, -- no use
    egroupID    => 0, -- no use
    epathID     => 0  -- no use
    )
port map (
    clk40           => clk40,
    clk160          => clk160,
    rst             => rst,
    encoding        => "10", -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding 
    maxCLEN         => "000", -- 000-not limit on packet length
    DIN             => DATA_OUT,  -- 10-bit data in
    DIN_RDY         => DATA_RDY,
    xoff            => almost_full,
    timeCntIn       => x"00", -- not in use
    TimeoutEnaIn    => '0',  -- not in use
    wordOUT         => BWORD, -- 16-bit block word
    wordOUT_RDY     => BWORD_RDY
    );


------------------------------------------------------------
-- EPATH FIFOs
------------------------------------------------------------
efw: entity work.EPATH_FIFO_WRAP
port map (
    rst         => rst,
    fifoFlush   => fifo_flush,
    wr_clk 	    => clk160,
    rd_clk 	    => efifoRclk,
    din         => BWORD,
    wr_en       => BWORD_RDY,
    rd_en       => efifoRe,
    dout        => efifoDout,
    almost_full => almost_full,
    prog_full   => efifoHF -- Half-Full - output: 1Kbyte block is ready
    );


end Behavioral;

