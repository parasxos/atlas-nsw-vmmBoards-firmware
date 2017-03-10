----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    05/19/2014
--! Module Name:    EPROC_IN2
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.ALL;
use work.all;

--! 80 Mbps E-link processor, 2bit input @ clk40
entity EPROC_IN2 is
generic (do_generate : boolean := true);
port ( 
    bitCLK      : in  std_logic;
    bitCLKx2    : in  std_logic;
    bitCLKx4    : in  std_logic;
    rst         : in  std_logic;
    ENA         : in  std_logic;
    swap_inputbits : in  std_logic;
    ENCODING    : in  std_logic_vector (1 downto 0);
    EDATA_IN    : in  std_logic_vector (1 downto 0);
    DATA_OUT    : out std_logic_vector (9 downto 0);
    DATA_RDY    : out std_logic;
    busyOut     : out std_logic
    );
end EPROC_IN2;

architecture Behavioral of EPROC_IN2 is

constant zeros10array  : std_logic_vector (9 downto 0) := (others=>'0');
signal edata_in_s : std_logic_vector (1 downto 0);
signal DATA_OUT_direct,DATA_OUT_8b10b_case,DATA_OUT_HDLC_case,DATA_OUT_s : std_logic_vector (9 downto 0);
signal DATA_RDY_direct,DATA_RDY_8b10b_case,DATA_RDY_HDLC_case,DATA_RDY_sig : std_logic;
signal RESTART_sig, rst_case00, rst_case01, rst_case10 : std_logic;
---

begin

gen_enabled: if do_generate = true generate

--
in_sel: process(swap_inputbits,EDATA_IN)
begin   
    if swap_inputbits = '1' then
        edata_in_s <= EDATA_IN(0) & EDATA_IN(1);
    else
        edata_in_s <= EDATA_IN;
    end if;	   
end process;
--
RESTART_sig <= rst or (not ENA); -- comes from clk40 domain 
--

-------------------------------------------------------------------------------------------
-- ENCODING case "00": direct data, no delimeter...
-------------------------------------------------------------------------------------------
rst_case00 <= '0' when ((RESTART_sig = '0') and (ENCODING = "00")) else '1';
--
direct_data_case: entity work.EPROC_IN2_direct 
port map(
    bitCLK      => bitCLK,
    bitCLKx4    => bitCLKx4,
    rst         => rst_case00,
    edataIN     => edata_in_s,
    dataOUT     => DATA_OUT_direct,
    dataOUTrdy  => DATA_RDY_direct
	);

-------------------------------------------------------------------------------------------
-- ENCODING case "01": DEC8b10b
-------------------------------------------------------------------------------------------
rst_case01 <= '0' when ((RESTART_sig = '0') and (ENCODING = "01")) else '1';
--
dec8b10b_case: entity work.EPROC_IN2_DEC8b10b 
port map(
    bitCLK      => bitCLK,
    bitCLKx2    => bitCLKx2,
    bitCLKx4    => bitCLKx4,
    rst         => rst_case01,
    edataIN     => edata_in_s,
    dataOUT     => DATA_OUT_8b10b_case,
    dataOUTrdy  => DATA_RDY_8b10b_case,
    busyOut     => busyOut
	);

-------------------------------------------------------------------------------------------
-- ENCODING case "10": HDLC
-------------------------------------------------------------------------------------------
rst_case10 <= '0' when ((RESTART_sig = '0') and (ENCODING = "10")) else '1';
--
decHDLC_case: entity work.EPROC_IN2_HDLC 
port map(  
    bitCLK      => bitCLK,
    bitCLKx2    => bitCLKx2,
    bitCLKx4    => bitCLKx4,
    rst         => rst_case10,
    edataIN     => edata_in_s,
    dataOUT     => DATA_OUT_HDLC_case,
    dataOUTrdy  => DATA_RDY_HDLC_case
    );

	
-------------------------------------------------------------------------------------------
-- output data/rdy according to the encoding settings
-------------------------------------------------------------------------------------------
DATA_OUT_MUX4_10bit: entity work.MUX4_Nbit 
generic map(N=>10)
port map(
    data0 => DATA_OUT_direct,
    data1 => DATA_OUT_8b10b_case,
    data2 => DATA_OUT_HDLC_case,
    data3 => zeros10array, 
    sel   => ENCODING,
    data_out => DATA_OUT_s
	);

DATA_RDY_MUX4: entity work.MUX4 
port map(
    data0 => DATA_RDY_direct,
    data1 => DATA_RDY_8b10b_case,
    data2 => DATA_RDY_HDLC_case,
    data3 => '0', 
    sel   => ENCODING,
    data_out => DATA_RDY_sig
	);


DATA_RDY <= DATA_RDY_sig;
DATA_OUT <= DATA_OUT_s;
--------------------
end generate gen_enabled;
--
--
gen_disabled: if do_generate = false generate
    DATA_OUT <= (others=>'0');
    DATA_RDY <= '0';
    busyOut  <= '0';
end generate gen_disabled;

end Behavioral;

