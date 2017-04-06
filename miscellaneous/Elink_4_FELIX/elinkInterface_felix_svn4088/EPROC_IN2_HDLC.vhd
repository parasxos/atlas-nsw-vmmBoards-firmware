----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    05/19/2015 
--! Module Name:    EPROC_IN2_HDLC
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.centralRouter_package.all;
use work.all;

--! HDLC decoder for EPROC_IN2 module
entity EPROC_IN2_HDLC is
port (  
    bitCLK      : in  std_logic;
    bitCLKx2    : in  std_logic;
    bitCLKx4    : in  std_logic;
    rst         : in  std_logic;
    edataIN     : in  std_logic_vector (1 downto 0);
    dataOUT     : out std_logic_vector(9 downto 0);
    dataOUTrdy  : out std_logic
    );
end EPROC_IN2_HDLC;

architecture Behavioral of EPROC_IN2_HDLC is

----------------------------------
----------------------------------

signal edataIN_r : std_logic_vector (1 downto 0) := (others=>'1'); 
signal bit_in_sr,out_sr : std_logic_vector (7 downto 0) := (others=>'1'); 
signal bit_cnt,error_bit_cnt : std_logic_vector (2 downto 0) := (others=>'0'); 
signal error_state,error_state_r,error_out : std_logic := '1';
signal edataIN_latch_trig,bit_in,isflag_r,isflag_rr,bit_in_r,bit_in_r_we,sop_marked,remove_zero_r : std_logic := '0';
signal isflag,iserror,remove_zero,out_sr_rdy,dataOUTrdy0,dataOUTrdy1,dataOUTrdy_s,error_out_rdy,error_out_rdy_s : std_logic;

begin

-------------------------------------------------------------------------------------------
--live bitstream
-- input serializer
-------------------------------------------------------------------------------------------
process(bitCLKx2, rst)
begin
    if rst = '1' then
        edataIN_latch_trig <= '0';
    elsif bitCLKx2'event and bitCLKx2 = '1' then
        edataIN_latch_trig <= not edataIN_latch_trig;
    end if;
end process;
--
process(bitCLKx2, rst)
begin
    if rst = '1' then
        edataIN_r <= (others=>'1');
    elsif bitCLKx2'event and bitCLKx2 = '1' then
        if edataIN_latch_trig = '1' then
            edataIN_r <= edataIN;
        end if;    
    end if;
end process;
--
process(bitCLKx2)
begin
    if bitCLKx2'event and bitCLKx2 = '1' then
        if edataIN_latch_trig = '0' then
            bit_in <= edataIN_r(0);
        else
            bit_in <= edataIN_r(1);
        end if;
    end if;
end process;
--

-------------------------------------------------------------------------------------------
--clock1
-- input shift register 
-------------------------------------------------------------------------------------------
process(bitCLKx2, rst)
begin
    if rst = '1' then
        bit_in_sr <= (others=>'1');
    elsif bitCLKx2'event and bitCLKx2 = '1' then
        bit_in_sr <= bit_in & bit_in_sr(7 downto 1);
    end if;
end process;
--
isflag  <=  '1' when (bit_in_sr = "01111110") else '0';
iserror <=  '1' when (bit_in_sr(7 downto 1) = "1111111") else '0';
remove_zero <=  '1' when (bit_in_sr(6 downto 1) = "011111" and isflag_r = '0') else '0';
--

-------------------------------------------------------------------------------------------
--clock2
-- latching the error state, forwarding clean bit sequence
-------------------------------------------------------------------------------------------
process(bitCLKx2, rst)
begin
    if rst = '1' then
        error_state <= '1';
    elsif bitCLKx2'event and bitCLKx2 = '1' then
        if iserror = '1' then
            error_state <= '1';
        elsif isflag = '1' then
            error_state <= '0';
        end if;
    end if;
end process;
--
process(bitCLKx2, rst)
begin
    if rst = '1' then       
        isflag_r        <= '0';
        isflag_rr       <= '0';
        bit_in_r_we     <= '0';
        remove_zero_r   <= '0';
		error_state_r 	<= '1';
    elsif bitCLKx2'event and bitCLKx2 = '1' then
        isflag_r        <= isflag;
        isflag_rr       <= isflag_r;
        bit_in_r_we     <= not(error_state or remove_zero);
        remove_zero_r   <= remove_zero;
		error_state_r 	<= error_state;
    end if;
end process;
--
bit_in_r <= bit_in_sr(6);
--

-------------------------------------------------------------------------------------------
--clock3
-- output shift register
-------------------------------------------------------------------------------------------
process(bitCLKx2)
begin
    if bitCLKx2'event and bitCLKx2 = '1' then 
        if remove_zero = '0' or isflag_r = '1' or error_state = '1' then --if bit_in_r_we = '1' or isflag_r = '1' then
            out_sr  <= bit_in_r & out_sr(7 downto 1);            
        end if;           
    end if;
end process;
--
process(bitCLKx2, rst)
begin
    if rst = '1' then
        bit_cnt <= (others=>'0');
    elsif bitCLKx2'event and bitCLKx2 = '1' then
        if error_state = '1' then
            bit_cnt <= (others=>'0');
        else
            if bit_in_r_we = '1' or isflag_r = '1' then
                bit_cnt <= bit_cnt + 1;
            end if;
        end if;
    end if;
end process;
--
out_sr_rdy <=  '1' when (bit_cnt = "111" and error_state = '0' and remove_zero_r = '0') else '0';
--

-------------------------------------------------------------------------------------------
--clock3+
-- output latch
-------------------------------------------------------------------------------------------
dataOUTrdy0_pulse: entity work.pulse_pdxx_pwxx (Behavioral) generic map(pd=>2,pw=>1) port map(bitCLKx4,isflag_r,dataOUTrdy0); 
dataOUTrdy1_pulse: entity work.pulse_pdxx_pwxx (Behavioral) generic map(pd=>4,pw=>1) port map(bitCLKx4,out_sr_rdy,dataOUTrdy1); 
--
dataOUTrdy_s <= dataOUTrdy0 or dataOUTrdy1;
dataOUTrdy  <= dataOUTrdy_s or error_out_rdy_s;
--
process(bitCLKx4)
begin
    if bitCLKx4'event and bitCLKx4 = '1' then 
        if edataIN /= "11" then
            error_out <= '0'; 
        elsif error_state = '1' then
            error_out <= '1'; 
        end if;        
    end if;
end process;
--
process(bitCLKx2, rst)
begin
    if rst = '1' then
        error_bit_cnt <= (others=>'0');
    elsif bitCLKx2'event and bitCLKx2 = '1' then
        if error_out = '0' then
            error_bit_cnt <= (others=>'0');
        else
            error_bit_cnt <= error_bit_cnt + 1;
        end if;
    end if;
end process;
--
error_out_rdy <= '1' when (error_bit_cnt = "001" and error_out = '1') else '0';
error_out_rdy_pulse: entity work.pulse_pdxx_pwxx (Behavioral) generic map(pd=>0,pw=>1) port map(bitCLKx4,error_out_rdy,error_out_rdy_s); 
--
process(bitCLKx4)
begin
    if bitCLKx4'event and bitCLKx4 = '1' then 
		if error_state_r = '1' and isflag_r = '1' then
			dataOUT(9 downto 8) <= "10"; -- sop
		elsif error_state_r = '0' and isflag_r = '1' then
			dataOUT(9 downto 8) <= "01"; -- eop
		else
			dataOUT(9 downto 8) <= error_out & error_out; -- data/error
		end if;
        --dataOUT(9 downto 8) <= isflag_r & (isflag_r and sop_marked);         
    end if;
end process;
--
dataOUT(7 downto 0) <= out_sr;
--
process(bitCLKx4)
begin
    if bitCLKx4'event and bitCLKx4 = '1' then 
        if dataOUTrdy_s = '1' then
            sop_marked <= isflag_rr; -- flag is sent
        end if;        
    end if;
end process;
--



end Behavioral;
