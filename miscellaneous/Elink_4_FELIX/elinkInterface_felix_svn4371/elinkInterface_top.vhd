----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    17/08/2015 
--! Module Name:    FIFO2Elink
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
--! Use standard library
library work, ieee, std;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.all;
use work.centralRouter_package.all;
use work.elinkInterface_package.all; 
use ieee.std_logic_textio.all;
use std.textio.all;

--! consists of 1 E-path
entity elinkInterface_top is
port (  
    clk_200_in_n    : in  std_logic;
    clk_200_in_p    : in  std_logic;
    sys_reset_n     : in  std_logic;
    rst_sw          : in  std_logic;
    locked          : out std_logic;
    clk40_out       : out std_logic;
    rst_state       : out std_logic;
    ------
    emu_ena         : in  std_logic; 
    --
    edata_clk       : out std_logic;
    edata           : out std_logic_vector (15 downto 0); 
    edata_rdy       : out std_logic 
    ------
    );
end elinkInterface_top;

architecture Behavioral of elinkInterface_top is

----------------------------------
----------------------------------
component CR_CLKs
port
 (-- Clock in ports
  clk200_in_p   : in std_logic;
  clk200_in_n   : in std_logic;
  -- Clock out ports
  clk40         : out std_logic;
  clk80         : out std_logic;
  clk160        : out std_logic;
  clk320        : out std_logic;
  clk240        : out std_logic;
  -- Status and control signals
  resetn        : in  std_logic;
  locked        : out std_logic
 );
end component;

ATTRIBUTE SYN_BLACK_BOX : BOOLEAN;
ATTRIBUTE SYN_BLACK_BOX OF CR_CLKs : COMPONENT IS TRUE;

ATTRIBUTE BLACK_BOX_PAD_PIN : STRING;
ATTRIBUTE BLACK_BOX_PAD_PIN OF CR_CLKs : COMPONENT IS "clk200_in_p,clk200_in_n,clk40,clk80,clk160,clk320,resetn,locked";
----------------------------------
----------------------------------

constant block_size     : std_logic_vector(8 downto 0) := (others=>'1'); -- block is 1Kbyte
signal block_word_count : std_logic_vector(8 downto 0) := (others=>'0');
signal packet_counter   : std_logic_vector(7 downto 0) := (others=>'0');
signal count : std_logic_vector(7 downto 0) := (others=>'0');
signal packet_data : std_logic_vector(15 downto 0);
signal clk40, clk80, clk160, clk320, clk240 : std_logic;
signal startup_case : std_logic := '1';
signal efifoRe,send_sop,edata_rdy_r : std_logic := '0';
signal rst,fifo_flush,data_on_elink,efifoWe,efifoPfull,efifoHF,send_eop,emu_ena_s,block_done : std_logic;

signal efifoDin     : std_logic_vector(17 downto 0) := (others=>'0');
signal efifoDout    : std_logic_vector(15 downto 0);

begin


--------------------------------------------------------------------
-- clocks
--------------------------------------------------------------------
clk0: CR_CLKs
   port map ( 
   -- Clock in ports
   clk200_in_p => clk_200_in_p,
   clk200_in_n => clk_200_in_n,
  -- Clock out ports  
   clk40  => clk40,
   clk80  => clk80,
   clk160 => clk160,
   clk320 => clk320,
   clk240 => clk240,
  -- Status and control signals                
   resetn => sys_reset_n,
   locked => locked           
 );
--
clk40_out <= clk40;
--

--------------------------------------------------------------------
-- reset and fifo flush sequence
--------------------------------------------------------------------
rst0: entity work.CRresetManager 
port map ( 
    clk40           => clk40,
    rst_soft        => rst_sw,
    cr_rst          => rst,
    cr_fifo_flush   => fifo_flush
    );
--
rst_state <= rst;
--

--------------------------------------------------------------------
-- user data source: counter @ clk160
--------------------------------------------------------------------
send_eop <= '1' when (count = packet_size) else '0';
--
process(clk160)
begin
    if rising_edge(clk160) then
        send_sop <= send_eop; -- nex clock after eop is sent
        if emu_ena = '1' then
            startup_case <= '0';
        end if;
        if send_eop = '1' then
            packet_counter <= packet_counter + 1;
        end if;
	end if;
end process;
--
emu_ena_s <= emu_ena and not (send_eop or send_sop or startup_case);
--
process(clk160)
begin
    if rising_edge(clk160) then
        if efifoPfull = '0' then -- only when not full
            if emu_ena_s = '1' then -- when data emulator is enabled in simulation module 
                count <= count + 1;
            else
                count <= (others=>'0');
            end if;
        end if;
	end if;
end process;
--
process(clk160)
begin
    if rising_edge(clk160) then
        if efifoPfull = '1' or emu_ena = '0' then 
            efifoWe     <= '0';
            efifoDin    <= "11" & x"0000";
        else
            efifoWe     <= '1';          
            if send_sop = '1' or startup_case = '1' then 
                efifoDin    <= "10" & x"0000";
            elsif send_eop = '1' then               
                efifoDin    <= "01" & x"0000";
            else
                efifoDin    <= "00" & packet_data;
            end if;
        end if;
	end if;
end process;
--
--packet_data <= packet_counter & count;
--packet_data <= "11111111" & count;
--packet_data <= (others=>'1');
--packet_data <= x"fc" & x"fd";
--packet_data <= x"7e" & x"f" & count(3 downto 0);
packet_data <= x"fe" & x"f" & count(3 downto 0);

--


--------------------------------------------------------------------
-- elink transmitter
--------------------------------------------------------------------
elink_tx: entity work.FIFO2Elink 
generic map (
    OutputDataRate  => elinkRate,
    elinkEncoding   => elinkEncoding
    )
port map ( 
    clk40       => clk40,
    clk80       => clk80,
    clk160      => clk160,
    rst         => rst,
    fifo_flush  => fifo_flush,
    ------   
    efifoDin    => efifoDin,   -- [data_code,2bit][data,16bit]
    efifoWe     => efifoWe,
    efifoPfull  => efifoPfull, 
    efifoWclk   => clk160, 
    ------
    DATA1bitOUT => data_on_elink
    ------
    );



--------------------------------------------------------------------
-- elink receiver
--------------------------------------------------------------------
elink_rx: entity work.Elink2FIFO
generic map (
    InputDataRate   => elinkRate,
    elinkEncoding   => elinkEncoding
    )
port map ( 
    clk40       => clk40,
    clk80       => clk80,
    clk160      => clk160,    
    rst         => rst,
    fifo_flush  => fifo_flush,
    ------
    DATA1bitIN  => data_on_elink,
    ------
    efifoRclk   => clk160,
    efifoRe     => efifoRe, 
    efifoHF     => efifoHF, -- half-full flag: 1 KByte block is ready to be read
    efifoDout   => efifoDout
    ------
    );


--------------------------------------------------------------------
-- user data acquisition
--------------------------------------------------------------------
block_re_latch: process(clk160)
begin
    if rising_edge(clk160) then       
        if block_done = '1' or rst = '1' then
            efifoRe <= '0';
        elsif efifoHF = '1' then  -- one 1Kbyte block is ready
            efifoRe <= '1';
        end if;
	end if;
end process;
--
block_done <= '1' when (block_word_count = block_size) else '0';
--
block_word_counter: process(clk160)
begin
    if rising_edge(clk160) then       
        if efifoRe = '1' and block_done = '0' then
            block_word_count <= block_word_count + 1;
        else
            block_word_count <= (others=>'0');
        end if;
	end if;
end process;
--
edata_rdy0: process(clk160)
begin
    if rising_edge(clk160) then       
        edata_rdy_r <= efifoRe;
	end if;
end process;
--
edata_clk   <= clk160;
edata_rdy   <= edata_rdy_r;
edata       <= efifoDout;
--



end Behavioral;

