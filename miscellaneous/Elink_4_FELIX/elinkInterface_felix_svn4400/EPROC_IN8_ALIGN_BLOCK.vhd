----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    06/25/2014 
--! Module Name:    EPROC_IN8_ALIGN_BLOCK
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.all;
use work.centralRouter_package.all;

--! continuously aligns 8bit bit-stream to two commas
entity EPROC_IN8_ALIGN_BLOCK is
port ( 
    bitCLKx2    : in  std_logic;
    bitCLKx4    : in  std_logic;
    rst         : in  std_logic;
    bytes       : in  word10b_4array_type;
    bytes_rdy   : in  std_logic; 
    ------------
    dataOUT     : out std_logic_vector(9 downto 0);
    dataOUTrdy  : out std_logic;
    ------------
    busyOut     : out std_logic
    );
end EPROC_IN8_ALIGN_BLOCK;

architecture Behavioral of EPROC_IN8_ALIGN_BLOCK is

signal bytes_r : word10b_4array_type := ((others=>'0'),(others=>'0'),(others=>'0'),(others=>'0')); 
signal send_state : std_logic := '0';
signal dataOUT_s : std_logic_vector(9 downto 0) := (others => '0');
signal dataOUTrdy_s, bytes_rdy_r : std_logic := '0';
signal byte_count : std_logic_vector(1 downto 0) := "00";

begin

-------------------------------------------------------------------------------------------
-- clock1
-- input register
-------------------------------------------------------------------------------------------
process(bitCLKx2, rst)
begin
    if rst = '1' then
        bytes_rdy_r <= '0';
    elsif rising_edge(bitCLKx2) then
        if bytes_rdy = '1' then
            bytes_rdy_r <= not bytes_rdy_r;
        else
            bytes_rdy_r <= '0';
        end if;
    end if;
end process;
--
input_latch: process(bitCLKx2)
begin
    if rising_edge(bitCLKx2) then
        if bytes_rdy = '1' then
            bytes_r <= bytes;
        end if;
    end if;
end process;
--
--
process(bitCLKx2, rst) 
begin
    if rst = '1' then
       send_state <= '0'; 
    elsif rising_edge(bitCLKx2) then
        if bytes_rdy = '1' then
            send_state <= '1';
        else
            if byte_count = "11" then 
                send_state <= '0';
            end if;
        end if;
    end if;
end process;
--
process(bitCLKx2) 
begin
    if rising_edge(bitCLKx2) then
        if send_state = '1' then 
            byte_count <= byte_count + 1;
        else
            byte_count <= "00";
        end if;
    end if;
end process;
--

-------------------------------------------------------------------------------------------
-- 
-------------------------------------------------------------------------------------------
process(bitCLKx4)
begin
    if rising_edge(bitCLKx4) then
        if send_state = '1' then
            dataOUTrdy_s <= not dataOUTrdy_s;
        else
            dataOUTrdy_s <= '0';
        end if;
    end if;
end process;
--

-------------------------------------------------------------------------------------------
-- 
-------------------------------------------------------------------------------------------
out_select_proc: process(byte_count, bytes_r)
begin
    case (byte_count) is 
        when "00" => dataOUT_s <= bytes_r(0);
        when "01" => dataOUT_s <= bytes_r(1);
        when "10" => dataOUT_s <= bytes_r(2);
        when "11" => dataOUT_s <= bytes_r(3);
        when others =>
    end case;
end process;
--

-------------------------------------------------------------------------------------------
-- dataOUT_s (@bitCLKx4) & dataOUTrdy_s (@bitCLKx4, 2nd clock) can be used when 
-- decoder is moved up
-------------------------------------------------------------------------------------------
dec_8b10: entity work.dec_8b10_wrap 
port map(
	RESET         => rst,
	RBYTECLK      => bitCLKx4,
	ABCDEIFGHJ_IN => dataOUT_s,
	HGFEDCBA      => dataOUT(7 downto 0),
	ISK           => dataOUT(9 downto 8),
	BUSY          => busyOut
);
--
dataOUTrdy  <= dataOUTrdy_s;
--
end Behavioral;



