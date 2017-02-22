----------------------------------------------------------------------------------
-- Company: Westfälische Hochschule
-- Engineer: Pia Piekarek (piapiekarek@googlemail.com)
-- 
-- Create Date: 13.01.2017 11:56:04
-- Design Name: 
-- Module Name: ckbc_gen - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: CKBC Generator
-- 
-- Dependencies: 
-- 
-- Changelog:
-- 20.02.2017 Changed the FSM to create a multicycle path. Changed the input clock
-- frequency to 160 Mhz. (Christos Bakalis)
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ckbc_gen is
    port(  
        clk_160       : in std_logic;
        duty_cycle    : in std_logic_vector(7 downto 0);
        freq          : in std_logic_vector(7 downto 0);
        ready         : in std_logic;
        ckbc_out      : out std_logic
    );
end ckbc_gen;


architecture Behavioral of ckbc_gen is
    
    signal t_high        : unsigned(16 downto 0) := to_unsigned(0,17);
    signal t_low         : unsigned(16 downto 0) := to_unsigned(0,17);
    signal ckbc_start    : std_logic := '0';
    
    signal count         : unsigned(7 downto 0) := to_unsigned(0,8);
    signal p_high        : unsigned(16 downto 0) := to_unsigned(0,17);        --number of clock cycles while high
    signal p_low         : unsigned(16 downto 0) := to_unsigned(0,17);        --number of clock cycles while low
    
    type   state_type is (IDLE, WAIT_ONE, RDY);
    signal state: state_type := IDLE;

begin

-- small FSM that waits before starting the clocking process
ckbc_proc: process(clk_160)
begin
    if(rising_edge(clk_160)) then
        case state is
        when IDLE =>
            if(ready = '1') then
                ckbc_start  <= '0';
                state       <= WAIT_ONE;
            else
                ckbc_start  <= '0';
                state       <= IDLE;
            end if;
               
        when WAIT_ONE =>
            if(ready = '1') then
                ckbc_start  <= '0';
                state       <= RDY;
            else
                ckbc_start  <= '0';
                state       <= IDLE;
            end if;
            
        when RDY =>
            if(ready = '1')then
                ckbc_start  <= '1';
                state       <= RDY;
            else
                ckbc_start  <= '0';
                state       <= IDLE;
            end if;
        when others =>
            state <= IDLE;
        end case;
    end if;
end process;

clocking_proc: process(clk_160)
  begin
    if (rising_edge(clk_160)) then
        if(ckbc_start = '0') then
            ckbc_out <= '0';
            count    <= to_unsigned(0,8);
        else
            if(count < (p_high+p_low)) then
                if(count < p_high)then
                    ckbc_out <= '1';
                elsif (count < (p_high+p_low)) then
                    ckbc_out <= '0';
                end if;
                count <= count + 1;
            elsif (p_high >= 1 and p_low >= 1) then
                count <= to_unsigned(1,8);
                ckbc_out <= '1';
            end if;
        end if;
    end if;
end process;

t_high_proc: process(freq)
begin
    case freq is
    when "00101000" => -- 40
        t_high <= to_unsigned(6250,17);
        t_low  <= to_unsigned(18750,17);
    when "00010100" => -- 20
        t_high <= to_unsigned(12500,17);
        t_low  <= to_unsigned(37500,17);
    when "00001010" => -- 10
        t_high <= to_unsigned(18750,17);
        t_low  <= to_unsigned(81250,17);
    when others =>
        t_high <= to_unsigned(6250,17);
        t_low  <= to_unsigned(18750,17);
    end case;
end process;
      
      p_high        <= (t_high / to_unsigned(6250, 16)); -- input clock period: 160 Mhz = 6.250 ns
      p_low         <= (t_low  / to_unsigned(6250, 16));

end Behavioral;
