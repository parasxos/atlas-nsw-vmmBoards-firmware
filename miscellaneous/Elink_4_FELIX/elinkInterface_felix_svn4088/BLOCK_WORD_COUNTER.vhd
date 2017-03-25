----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    07/13/2014 
--! Module Name:    BLOCK_WORD_COUNTER
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.centralRouter_package.all;

--! counts block words, inserts block header
entity BLOCK_WORD_COUNTER is
	 Port ( 
        CLK    : in  STD_LOGIC;
        RESET  : in  STD_LOGIC;
        RESTART : IN std_logic;
        BW_RDY : in  STD_LOGIC; -- Block Word Ready Enable
        -------------
        BLOCK_HEADER : in  STD_LOGIC_VECTOR(31 downto 0); 
        -------------
        EOB_MARK : out  STD_LOGIC; -- End Of Block flag to send the trailer
        BLOCK_HEADER_OUT     : out  STD_LOGIC_VECTOR(15 downto 0); --> sending block header
        BLOCK_HEADER_OUT_RDY : out  STD_LOGIC;                      --> sending block header
        -------------
        BLOCK_COUNT_RDY : out  STD_LOGIC
        );
end BLOCK_WORD_COUNTER;

architecture Behavioral of BLOCK_WORD_COUNTER is

----------------------------------
----------------------------------
component pulse_pdxx_pwxx
generic( 
	pd : integer := 0;
	pw : integer := 1);
port(
    clk         : in   std_logic;
    trigger     : in   std_logic;
    pulseout    : out  std_logic
	);
end component pulse_pdxx_pwxx;
----------------------------------
----------------------------------

signal count_sig    : STD_LOGIC_VECTOR (9 downto 0) := (others => '0');
signal seq_num      : STD_LOGIC_VECTOR (4 downto 0) := (others => '0');
signal SOB_MARK0, SOB_MARK1, seqCNTcase, seqCNTtrig : STD_LOGIC;
signal SOB_MARK, EOB_MARK_sig, EOB_MARK_sig_clk1, blockCountRdy : STD_LOGIC := '0';
-- two first words are always sent in the beginning of a block transmittion
constant count_offset : STD_LOGIC_VECTOR (9 downto 0) := "0000000001"; --(others => '0'); 

begin

ce: process(CLK)
begin
	if CLK'event and CLK = '1' then
		if RESET = '1' or RESTART = '1' then
            blockCountRdy <= '0';
		elsif SOB_MARK1 = '1' then
            blockCountRdy <= '1';
		end if;
	end if;
end process;
--
BLOCK_COUNT_RDY <= blockCountRdy;

--------------------------------------------------------------
-- counting block words, data partition
--------------------------------------------------------------
counter: process(CLK)
begin
	if CLK'event and CLK = '1' then
		if RESET = '1' then
		  count_sig <= (others => '0');
		else
            if EOB_MARK_sig = '1' or RESTART = '1' then
                count_sig <= count_offset;
            elsif BW_RDY = '1' then
                count_sig <= count_sig + 1;
            end if;
		end if;
	end if;
end process;

--------------------------------------------------------------
-- End Of Block trigger out for the 
-- sub-chunk data manager to insert a trailer
--------------------------------------------------------------
EOB_MARK_sig <= '1' when (count_sig = BLOCK_WORDn) else '0'; -- there is one more space left, for the trailer
EOB_MARK <= EOB_MARK_sig;

--------------------------------------------------------------
-- Block Sequence counter, 5 bit
--------------------------------------------------------------
seqCNTcase <= EOB_MARK_sig or RESTART;
seqCNTtrig_pulse: pulse_pdxx_pwxx generic map(pd=>2,pw=>1) PORT MAP(CLK, seqCNTcase, seqCNTtrig); 
--process(CLK)
--begin
--	if CLK'event and CLK = '1' then
--		EOB_MARK_sig_clk1 <= EOB_MARK_sig;
--	end if;
--end process;
--
scounter: process(CLK)
begin
	if CLK'event and CLK = '1' then
		if RESET = '1' then
		  seq_num <= (others => '0');
		else
            if seqCNTtrig = '1' then
               seq_num <= seq_num + 1;
            end if;
		end if;
	end if;
end process;

--------------------------------------------------------------
-- Start Of Block Mark to insert block header
--------------------------------------------------------------
SOB_MARK <= '1' when (count_sig = count_offset) else '0';

--------------------------------------------------------------
-- Start Of Block produces 2 triggers 
-- to send 2 words, as header is 32bit
--------------------------------------------------------------
SOB_MARK0_PULSE: pulse_pdxx_pwxx PORT MAP(CLK, SOB_MARK, SOB_MARK0); -- FIFO WE to send word0
SOB_MARK1_PULSE: pulse_pdxx_pwxx GENERIC MAP(pd=>1,pw=>1) PORT MAP(CLK, SOB_MARK0, SOB_MARK1); -- FIFO WE to send word1
--
BLOCK_HEADER_OUT <= 	(seq_num & BLOCK_HEADER(10 downto 0))  when (SOB_MARK0 = '1') else
                        BLOCK_HEADER(31 downto 16) when (SOB_MARK1 = '1') else
                        (others => '0');

BLOCK_HEADER_OUT_RDY <= SOB_MARK0 or SOB_MARK1;

end Behavioral;