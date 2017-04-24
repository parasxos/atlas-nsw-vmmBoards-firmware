----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch) 
-- 
-- Create Date: 20.04.2017 11:46:44
-- Design Name: Level-0 Wrapper
-- Module Name: L0_wrapper - RTL
-- Project Name: NTUA-BNL VMM3 Readout Firmware
-- Target Devices: Xilinx xc7a200t-2fbg484
-- Tool Versions: Vivado 2016.4
-- Description: Wrapper that contains the necessary modules for L0 readout, i.e.
-- data0/1 sampling, comma character recognition, and 8b/10b decoding.
-- 
-- Dependencies: 
-- 
-- Changelog: 
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use work.StdRtlPkg.all;
use work.Code8b10bPkg.all;

entity L0_wrapper is
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk_ckdt    : in  std_logic; -- will be forwarded to the VMM
        clk_des     : in  std_logic; -- must be twice the frequency of CKDT
        level_0     : in  std_logic; -- level-0 signal
        rst         : in  std_logic;
        ------------------------------------
        ---------- VMM Interface -----------
        VMM_CKDT    : out std_logic;
        VMM_CKTK    : out std_logic;
        VMM_DATA0   : in  std_logic;
        VMM_DATA1   : in  std_logic
    );
end L0_wrapper;

architecture RTL of L0_wrapper is
    
    component ila_l0
        port(
            clk    : IN STD_LOGIC;
            probe0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
        );
    end component;

    component Decoder8b10b 
        generic (
            TPD_G          : time     := 1 ns;
            NUM_BYTES_G    : positive := 2;
            RST_POLARITY_G : sl       := '1';
            RST_ASYNC_G    : boolean  := false);
        port(
            clk      : in  sl;
            clkEn    : in  sl := '1';
            rst      : in  sl;
            dataIn   : in  slv(NUM_BYTES_G*10-1 downto 0);
            dataOut  : out slv(NUM_BYTES_G*8-1 downto 0);
            dataKOut : out slv(NUM_BYTES_G-1 downto 0);
            codeErr  : out slv(NUM_BYTES_G-1 downto 0);
            dispErr  : out slv(NUM_BYTES_G-1 downto 0)
        );
    end component;

    signal L0_10B_sreg  : std_logic_vector(9 downto 0) := (others => '0');
    signal L0_10B_prev  : std_logic_vector(9 downto 0) := (others => '0');
    signal din_buff     : std_logic_vector(1 downto 0) := (others => '0');
    signal align_sreg   : std_logic_vector(4 downto 0) := (others => '0');
    signal L0_8B_data   : std_logic_vector(7 downto 0) := (others => '0');
    signal L0_8B_K      : std_logic_vector(0 downto 0) := (others => '0');
    signal din_dec      : std_logic_vector(9 downto 0) := (others => '0');


    signal VMM_DATA0_i  : std_logic := '0';
    signal VMM_DATA1_i  : std_logic := '0';
    signal data_0_i     : std_logic := '0';
    signal data_1_i     : std_logic := '0';
    signal data_0       : std_logic := '0';
    signal data_1       : std_logic := '0';

    signal comma_valid  : std_logic := '0';
    signal word10b_rdy  : std_logic := '0';
    signal dec_en       : std_logic := '0';
    
    type stateType is (ST_IDLE, ST_COUNT, ST_HOLD, ST_CHECK_CKTP);
    signal state : stateType := ST_IDLE;

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of data_0_i     : signal is "TRUE";
    attribute ASYNC_REG of data_1_i     : signal is "TRUE";
    attribute ASYNC_REG of data_0       : signal is "TRUE";
    attribute ASYNC_REG of data_1       : signal is "TRUE";

    attribute mark_debug : string;
    attribute mark_debug of level_0     : signal is "TRUE";
    attribute mark_debug of L0_8B_data  : signal is "TRUE";
    attribute mark_debug of data_0      : signal is "TRUE";
    attribute mark_debug of data_1      : signal is "TRUE";

begin

-- register/pipeline the data lines
data_pipe: process(clk_des)
begin
    if(rising_edge(clk_des))then
        data_0_i    <= VMM_DATA0;
        data_1_i    <= VMM_DATA1;
        data_0      <= data_0_i;
        data_1      <= data_1_i;
    end if;
end process;

-- raw, encoded data shift register
sreg_proc: process(clk_des, rst)
begin
    if(rst = '1')then
        L0_10B_sreg <= (others => '0');
    elsif(rising_edge(clk_des))then
        L0_10B_sreg <= din_buff & L0_10B_sreg(9 downto 2);
        L0_10B_prev <= L0_10B_sreg;
    end if;
end process;

-- check for comma characters
is_comma_proc: process(L0_10B_sreg)
begin    
    case L0_10B_sreg is
    when "0101111100" => comma_valid <= '1';
    when "1010000011" => comma_valid <= '1';
    when others       => comma_valid <= '0';
    end case;
end process;

-- alignment shift register
align_sreg_proc: process(rst, clk_des)
begin
    if(rst = '1')then
        align_sreg <= "00000";
    elsif(rising_edge(clk_des))then
        if comma_valid = '1' then
            align_sreg <= "10000"; 
        else
            align_sreg <= align_sreg(0) & align_sreg(4 downto 1); 
        end if;
    end if;
end process;

-- final register stage before the decoder
reg_final: process(clk_des)
begin
    if(rising_edge(clk_des))then
        dec_en  <= word10b_rdy;
        din_dec <= L0_10B_prev;
    end if;
end process;

Decoder8b10b_inst: Decoder8b10b
   generic map (
      TPD_G          => 1 ns,
      NUM_BYTES_G    => 1,
      RST_POLARITY_G => '1',
      RST_ASYNC_G    => false)
   port map(
      clk           => clk_des,
      clkEn         => dec_en,
      rst           => rst,
      dataIn        => din_dec,
      dataOut       => L0_8B_data,
      dataKOut      => L0_8B_K,
      codeErr       => open,
      dispErr       => open
    );  

ila_level0: ila_l0
  PORT MAP (
      clk                   => clk_des,
      probe0(0)             => level_0,
      probe0(8 downto 1)    => L0_8B_data,
      probe0(9)             => data_0,
      probe0(10)            => data_1,
      probe0(15 downto 11)  => (others => '0')
  );
  
  VMM_CKDT      <= clk_ckdt;
  word10b_rdy   <= align_sreg(4);
  din_buff      <= data_0 & data_1;
  VMM_CKTK      <= level_0;
  
end RTL;
