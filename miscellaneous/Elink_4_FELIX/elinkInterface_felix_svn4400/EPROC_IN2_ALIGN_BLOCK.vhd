----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    05/19/2014 
--! Module Name:    EPROC_IN2_ALIGN_BLOCK
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.all;
use work.centralRouter_package.all;

--! 
entity EPROC_IN2_ALIGN_BLOCK is
port ( 
    bitCLKx2    : in  std_logic;
    bitCLKx4    : in  std_logic;
    rst         : in  std_logic;
    bytes       : in  std_logic_vector(9 downto 0);
    bytes_rdy   : in  std_logic;
    ------------
    dataOUT     : out std_logic_vector(9 downto 0);
    dataOUTrdy  : out std_logic;
    ------------
    busyOut     : out std_logic
    );
end EPROC_IN2_ALIGN_BLOCK;

architecture Behavioral of EPROC_IN2_ALIGN_BLOCK is

begin


-------------------------------------------------------------------------------------------
-- 
-------------------------------------------------------------------------------------------
dec_8b10: entity work.dec_8b10_wrap -- 
port map(
	RESET         => rst,
	RBYTECLK      => bitCLKx4,
	ABCDEIFGHJ_IN => bytes,
	HGFEDCBA      => dataOUT(7 downto 0),
	ISK           => dataOUT(9 downto 8),
	BUSY          => busyOut
);
--
rdy_pipe: entity work.pulse_pdxx_pwxx generic map(pd=>1,pw=>1) port map(bitCLKx4,bytes_rdy,dataOUTrdy);
--

end Behavioral;

