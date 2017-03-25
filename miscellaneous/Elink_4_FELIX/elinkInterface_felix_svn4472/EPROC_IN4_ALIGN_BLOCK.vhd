----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    06/22/2014 
--! Module Name:    EPROC_IN4_ALIGN_BLOCK
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.all;
use work.centralRouter_package.all;

--! continuously aligns 4bit bit-stream to two commas
entity EPROC_IN4_ALIGN_BLOCK is
port ( 
    bitCLK      : in  std_logic;
    bitCLKx2    : in  std_logic;
    bitCLKx4    : in  std_logic;
    rst         : in  std_logic;
    bytes       : in  word10b_2array_type; -- 8b10b encoded
    bytes_rdy   : in  std_logic;
    ------------
    dataOUT     : out std_logic_vector(9 downto 0);
    dataOUTrdy  : out std_logic;
    ------------
    busyOut     : out std_logic
    );
end EPROC_IN4_ALIGN_BLOCK;

architecture Behavioral of EPROC_IN4_ALIGN_BLOCK is

signal bytes_r : word10b_2array_type := ((others=>'0'),(others=>'0')); 
signal byte1_in_rdy,byte0_in_rdy,send_state : std_logic := '0';
signal byte1_out_rdy_s,byte0_out_rdy_s : std_logic;
signal byte_in,byte_1,dataOUT_s : std_logic_vector(9 downto 0) := (others => '0');
signal byte1_out_rdy,byte0_out_rdy,byte_in_rdy,byte_1_rdy,dataOUTrdy_s, bytes_rdy_r : std_logic := '0';
signal byte_count : std_logic_vector(0 downto 0) := "0";

begin

process(bitCLK)
begin
    if rising_edge(bitCLK) then
        if bytes_rdy = '1' then
            byte_1       <= bytes(1);
            byte_1_rdy   <= '1';
        else
            byte_1_rdy   <= '0';
        end if;
    end if;
end process;
--
process(bitCLK)
begin
    if rising_edge(bitCLK) then
        if bytes_rdy = '1' then
            byte_in       <= bytes(0);
            byte_in_rdy   <= '1';
        elsif byte_1_rdy = '1' then 
            byte_in       <= byte_1;
            byte_in_rdy   <= '1';
        else
            byte_in_rdy   <= '0';
        end if;
    end if;
end process;
--
process(bitCLK)
begin
    if rising_edge(bitCLK) then
        byte0_in_rdy    <= bytes_rdy;
        byte1_in_rdy    <= byte0_in_rdy;
        byte0_out_rdy   <= byte0_in_rdy;
        byte1_out_rdy   <= byte1_in_rdy;
    end if;
end process;
--
rdy_pipe0: entity work.pulse_pdxx_pwxx generic map(pd=>1,pw=>1) port map(bitCLKx4,byte0_out_rdy,byte0_out_rdy_s);
rdy_pipe1: entity work.pulse_pdxx_pwxx generic map(pd=>1,pw=>1) port map(bitCLKx4,byte1_out_rdy,byte1_out_rdy_s);
--














---------------------------------------------------------------------------------------------
---- clock1
---- input register
---------------------------------------------------------------------------------------------
--process(bitCLKx2, rst)
--begin
--    if rst = '1' then
--        bytes_rdy_r <= '0';
--    elsif rising_edge(bitCLKx2) then
--        if bytes_rdy = '1' then
--            bytes_rdy_r <= not bytes_rdy_r;
--        else
--            bytes_rdy_r <= '0';
--        end if;
--    end if;
--end process;
----
--input_latch: process(bitCLKx2)
--begin
--    if rising_edge(bitCLKx2) then
--        if bytes_rdy = '1' then
--            bytes_r <= bytes;
--        end if;
--    end if;
--end process;
----
----
--process(bitCLKx2, rst) 
--begin
--    if rst = '1' then
--        send_state <= '0';
--    elsif rising_edge(bitCLKx2) then
--        if bytes_rdy = '1' then
--            send_state <= '1';
--        else
--            if byte_count = "1" then 
--                send_state <= '0';
--            end if;
--        end if;
--    end if;
--end process;
----
--process(bitCLKx2) 
--begin
--    if rising_edge(bitCLKx2) then
--        if send_state = '1' then 
--            byte_count <= byte_count + 1;
--        else
--            byte_count <= "0";
--        end if;
--    end if;
--end process;
----


---------------------------------------------------------------------------------------------
---- clock2
---- 
---------------------------------------------------------------------------------------------
--process(bitCLKx4)
--begin
--    if rising_edge(bitCLKx4) then
--        if send_state = '1' then
--            dataOUTrdy_s <= not dataOUTrdy_s;
--        else
--            dataOUTrdy_s <= '0';
--        end if;
--    end if;
--end process;
----

---------------------------------------------------------------------------------------------
---- 
---------------------------------------------------------------------------------------------
--out_select_proc: process(byte_count, bytes_r) 
--begin
--    case (byte_count) is 
--        when "0" => dataOUT_s <= bytes_r(0); 
--        when "1" => dataOUT_s <= bytes_r(1); 
--        when others =>
--    end case;
--end process;
----

-------------------------------------------------------------------------------------------
-- dataOUT_s (@bitCLKx4) & dataOUTrdy_s (@bitCLKx4, 2nd clock) can be used when 
-- decoder is moved up
-------------------------------------------------------------------------------------------
dec_8b10: entity work.dec_8b10_wrap 
port map(
	RESET         => rst,
	RBYTECLK      => bitCLK, --bitCLKx4,
	ABCDEIFGHJ_IN => byte_in, --dataOUT_s,
	HGFEDCBA      => dataOUT(7 downto 0),
	ISK           => dataOUT(9 downto 8),
	BUSY          => busyOut
);
--
dataOUTrdy  <= byte0_out_rdy_s or byte1_out_rdy_s; --dataOUTrdy_s; 
----
end Behavioral;

