----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch) 
-- 
-- Create Date: 20.04.2017 11:46:44
-- Design Name: Level-0 Deserializer/Decoder
-- Module Name: l0_deserializer_decoder - RTL
-- Project Name: NTUA-BNL VMM3 Readout Firmware
-- Target Devices: Xilinx xc7a200t-2fbg484
-- Tool Versions: Vivado 2016.4
-- Description: Implementation of data0/data1 sampling and deserialization, comma
-- character recognition, and 8b/10b decoding.
-- 
-- Dependencies: 
-- 
-- Changelog: 
-- 30.04.2017: Changed the way wr_en is asserted to comply with the halved wr_clk
-- of the vmm level-0 data buffer. (Christos Bakalis)
-- 20.06.2017: Removed pipeline. (Christos Bakalis)
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use work.StdRtlPkg.all;
use work.Code8b10bPkg.all;

entity l0_deserializer_decoder is
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk_ckdt    : in  std_logic; -- will be forwarded to the VMM
        clk_des     : in  std_logic; -- must be twice the frequency of CKDT
        level_0     : in  std_logic; -- level-0 signal
        ------------------------------------
        -------- Buffer Interface ----------
        inhib_wr    : in  std_logic;
        dout_dec    : out std_logic_vector(7 downto 0);
        commas_true : out std_logic;
        wr_en       : out std_logic;
        ------------------------------------
        ---------- VMM Interface -----------
        vmm_ckdt    : out std_logic;
        vmm_data0   : in  std_logic;
        vmm_data1   : in  std_logic
    );
end l0_deserializer_decoder;

architecture RTL of l0_deserializer_decoder is
    
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
    signal L0_8B_data_i : std_logic_vector(7 downto 0) := (others => '0');
    signal L0_8B_data_s : std_logic_vector(7 downto 0) := (others => '0');
    signal L0_8B_K      : std_logic_vector(0 downto 0) := (others => '0');
    signal din_dec      : std_logic_vector(9 downto 0) := (others => '0');

    signal comma_valid  : std_logic := '0';
    signal word10b_rdy  : std_logic := '0';
    signal dec_en       : std_logic := '0';

    signal rdy_str      : std_logic := '0';
    signal rdt_str_s    : std_logic := '0';
    signal flag_0       : std_logic := '0';
    signal flag_1       : std_logic := '0';
    signal wr_en_i      : std_logic := '0';

    signal cnt_commas       : unsigned(4 downto 0) := (others => '0');
    constant cnt_thr        : unsigned(4 downto 0) := "11111"; -- 6 consecutive commas       
    
    type stateType is (ST_IDLE, ST_COUNT, ST_HOLD, ST_CHECK_CKTP);
    signal state : stateType := ST_IDLE;

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of L0_8B_data_s : signal is "TRUE";
    attribute ASYNC_REG of dout_dec     : signal is "TRUE";
    attribute ASYNC_REG of rdt_str_s    : signal is "TRUE";

begin

-- raw, encoded data shift register
sreg_proc: process(clk_des)
begin
    if(rising_edge(clk_des))then
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
align_sreg_proc: process(clk_des)
begin
    if(rising_edge(clk_des))then
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

-- process that counts commas
cnt_commas_proc: process(clk_des)
begin
    if(rising_edge(clk_des))then
        if(L0_8B_data_i /= x"BC")then
            cnt_commas  <= (others => '0');
            commas_true <= '0';
        else
            if(cnt_commas = cnt_thr)then
                commas_true <= '1';
            else
                commas_true <= '0';
                cnt_commas  <= cnt_commas + 1;
            end if;
        end if;
    end if;
end process;

-- process that stretches the ready signal, to be latched by the slower clock domain
-- if VMM data have been decoded
rdy_stretcher: process(clk_des)
begin
    if(rising_edge(clk_des))then
        if(flag_1 = '1')then -- last step
            flag_1 <= '0';
        elsif(flag_0 = '1')then -- second step
            flag_0 <= '0';
            flag_1 <= '1';
        elsif(word10b_rdy = '1' and L0_8B_data /= X"BC")then -- first step
            rdy_str <= '1';
            flag_0  <= '1';
        else
            rdy_str <= '0';
            flag_0  <= '0';
            flag_1  <= '0';
        end if;
        -- data pipeline
        L0_8B_data_i <= L0_8B_data;
    end if;
end process;

-- process that detects the stretched ready signal to assert the FIFO wr_en
wr_ena_proc: process(clk_ckdt)
begin
    if(rising_edge(clk_ckdt))then
        if(wr_en_i = '1')then
            wr_en_i <= '0';
        elsif(rdt_str_s = '1' and inhib_wr = '0')then -- resync rdy_str @ 160?
            wr_en_i <= '1';
        else
            wr_en_i <= '0';
        end if;
        -- stretched pulse synchronizer and data pipeline    
        L0_8B_data_s    <= L0_8B_data_i;
        dout_dec        <= L0_8B_data_s;
        rdt_str_s       <= rdy_str;
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
      rst           => '0',
      dataIn        => din_dec,
      dataOut       => L0_8B_data,
      dataKOut      => L0_8B_K,
      codeErr       => open,
      dispErr       => open
    );  
  
  vmm_ckdt      <= clk_ckdt;
  word10b_rdy   <= align_sreg(4);
  din_buff      <= vmm_data0 & vmm_data1;
  wr_en         <= wr_en_i;
  
end RTL;
