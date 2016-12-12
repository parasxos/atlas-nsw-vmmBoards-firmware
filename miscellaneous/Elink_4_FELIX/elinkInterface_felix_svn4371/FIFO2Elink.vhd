----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    17/08/2015 
--! Module Name:    FIFO2Elink
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use work.all;

--! consists of 1 E-path
entity FIFO2Elink is
generic (
    OutputDataRate  : integer := 80; -- 80 or 160 MHz
    elinkEncoding   : std_logic_vector (1 downto 0)
    );
port ( 
    clk40       : in  std_logic;
    clk80       : in  std_logic;
    clk160      : in  std_logic;
    rst         : in  std_logic;
    fifo_flush  : in  std_logic;
    ------   
    efifoDin    : in  std_logic_vector (17 downto 0);   -- [data_code,2bit][data,16bit]
    efifoWe     : in  std_logic;
    efifoPfull  : out std_logic; 
    efifoWclk   : in  std_logic; 
    ------
    DATA1bitOUT : out  std_logic
    ------
    );
end FIFO2Elink;

architecture Behavioral of FIFO2Elink is

----
signal efifoRE, doutRdy : std_logic;
signal efifoDout : std_logic_vector(9 downto 0); 
signal dout2bit  : std_logic_vector(1 downto 0); 
signal bitCount1,dout2bit_r : std_logic := '0';
signal dout4bit, dout4bit_r : std_logic_vector(3 downto 0); 
signal bitCount2 : std_logic_vector(1 downto 0) := "00";
----

begin


------------------------------------------------------------
-- EPATH_FIFO
------------------------------------------------------------
UEF: entity work.upstreamEpathFifoWrap
port map(
    rst 	        => rst,
    fifoFLUSH       => fifo_flush,
    ---
    wr_clk 	=> efifoWclk,
    wr_en 	=> efifoWe,
    din     => efifoDin,
    ---
    rd_clk 	=> clk160,
    rd_en 	=> efifoRE, 
    dout 	=> efifoDout,
    doutRdy => doutRdy,
    ---
    full        => open,
    empty       => open,
    prog_full   => efifoPfull
    );
--

					

------------------------------------------------------------
-- E-PATH case 80 MHz
------------------------------------------------------------
OutputDataRate80: if OutputDataRate = 80 generate

EPROC_OUT2bit: entity work.EPROC_OUT2 
port map(
	bitCLK     => clk40,
	bitCLKx2   => clk80,
	bitCLKx4   => clk160,
	rst        => rst,
	ENA        => '1', -- always enabled here
	swap_outbits => '0', -- when '1', the output bits will be swapped
	getDataTrig => efifoRE,
	ENCODING   => ("00" & elinkEncoding), -- 0000-direct data / 0001-8b10b encoding / 0010-HDLC encoding / others are used for TTC formats
	EDATA_OUT  => dout2bit, -- @ 40MHz
	TTCin      => "00", -- not in use here
	DATA_IN    => efifoDout,  -- 10-bit data in
	DATA_RDY   => doutRdy
);
-------------------------------------------
-- serialization of the 2-bit data output:
-------------------------------------------
process(clk80)
begin
    if clk80'event and clk80 = '1' then
        bitCount1 <= not bitCount1;
	end if;
end process;
--
process(clk80)
begin
    if clk80'event and clk80 = '1' then
        if bitCount1 = '0' then
            dout2bit_r <= dout2bit(1);
        end if;
	end if;
end process;
---
process(clk80)
begin
    if clk80'event and clk80 = '1' then
        if bitCount1 = '0' then
            DATA1bitOUT <= dout2bit(0);
        else
            DATA1bitOUT <= dout2bit_r;
        end if;
	end if;
end process;
---

end generate OutputDataRate80; 





------------------------------------------------------------
-- E-PATH case 160 MHz
------------------------------------------------------------
OutputDataRate160: if OutputDataRate = 160 generate

EPROC_OUT4bit: entity work.EPROC_OUT4 
PORT MAP(
	bitCLK     => clk40,
	bitCLKx2   => clk80,
	bitCLKx4   => clk160,
	rst        => rst,
	ENA        => '1', -- always enabled here
	getDataTrig => efifoRE,
	ENCODING   => ("00" & elinkEncoding), -- 0000-direct data / 0001-8b10b encoding / 0010-HDLC encoding / others are used for TTC formats
	EDATA_OUT  => dout4bit, -- @ 40MHz
	TTCin      => "00000", -- not in use here
	DATA_IN    => efifoDout, -- 10-bit data in
	DATA_RDY   => doutRdy
);
-------------------------------------------
-- serialization of the 4-bit data output:
-------------------------------------------
process(clk160)
begin
    if clk160'event and clk160 = '1' then
        bitCount2 <= bitCount2 + 1;
	end if;
end process;
--
process(clk160)
begin
    if clk160'event and clk160 = '1' then
        if bitCount2 = "00" then
            dout4bit_r <= dout4bit;
        end if;
	end if;
end process;
---
process(clk80)
begin
    if clk160'event and clk160 = '1' then       
       case bitCount2 is 
          when "00" => DATA1bitOUT <= dout4bit(0);
          when "01" => DATA1bitOUT <= dout4bit_r(1);
          when "10" => DATA1bitOUT <= dout4bit_r(2);
          when "11" => DATA1bitOUT <= dout4bit_r(3);
          when others =>
       end case;
	end if;
end process;
---

end generate OutputDataRate160; 


end Behavioral;

