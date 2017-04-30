----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch) 
-- 
-- Create Date: 28.04.2017 14:18:44
-- Design Name: Level-0 Wrapper
-- Module Name: level0_wrapper - RTL
-- Project Name: NTUA-BNL VMM3 Readout Firmware
-- Target Devices: Xilinx xc7a200t-2fbg484
-- Tool Versions: Vivado 2016.4
-- Description: Wrapper that contains all necessary modules for implementing
-- level0 readout of the VMMs
-- 
-- Dependencies: 
-- 
-- Changelog: 
-- 
----------------------------------------------------------------------------------
library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use UNISIM.VComponents.all;

entity level0_wrapper is
    Generic(is_mmfe8   : std_logic;
            l0_enabled : std_logic);
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk_ckdt        : in  std_logic; -- will be forwarded to the VMM
        clk_des         : in  std_logic; -- must be twice the frequency of CKDT
        clk             : in  std_logic; -- buffer read domain
        rst             : in  std_logic; -- logic reset
        rst_buff        : in  std_logic; -- reset buffer
        level_0         : in  std_logic; -- level-0 signal
        ------------------------------------
        ---- Packet Formation Interface ----
        rd_ena_buff     : in  std_logic;
        rst_intf_proc   : in  std_logic;
        vmmId           : in  std_logic_vector(2 downto 0);  -- VMM to be readout
        vmmWordReady    : out std_logic;
        vmmWord         : out std_logic_vector(15 downto 0);
        vmmEventDone    : out std_logic;
        ------------------------------------
        ---------- VMM3 Interface ----------
        vmm_data0_vec   : in  std_logic_vector(8 downto 1);  -- Single-ended data0 from VMM
        vmm_data1_vec   : in  std_logic_vector(8 downto 1);  -- Single-ended data1 from VMM
        vmm_ckdt_vec    : out std_logic_vector(8 downto 1);  -- Strobe to VMM CKDT
        vmm_cktk_vec    : out std_logic_vector(8 downto 1)   -- Strobe to VMM CKTK
    );
end level0_wrapper;

architecture RTL of level0_wrapper is

component l0_deserializer_decoder
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk_ckdt    : in  std_logic; -- will be forwarded to the VMM
        clk_des     : in  std_logic; -- must be twice the frequency of CKDT
        level_0     : in  std_logic; -- level-0 signal
        rst         : in  std_logic; -- logic reset
        ------------------------------------
        -------- Buffer Interface ----------
        dout_dec    : out std_logic_vector(7 downto 0);
        wr_en       : out std_logic;
        ------------------------------------
        ---------- VMM Interface -----------
        vmm_ckdt    : out std_logic;
        vmm_data0   : in  std_logic;
        vmm_data1   : in  std_logic
    );
end component;

component l0_buffer_wrapper is
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk_des         : in  std_logic;
        clk             : in  std_logic;
        rst             : in  std_logic;
        rst_buff        : in  std_logic;
        ------------------------------------
        --- Deserializer Interface ---------
        dout_dec        : in std_logic_vector(7 downto 0);
        wr_en           : in std_logic;
        ------------------------------------
        ---- Packet Formation Interface ----
        rd_ena_buff     : in  std_logic;
        rst_intf_proc   : in  std_logic;
        vmmWordReady    : out std_logic;
        vmmWord         : out std_logic_vector(15 downto 0);
        vmmEventDone    : out std_logic
    );
end component;

component l0_rst is
    Port(
        clk         : in  std_logic;
        rst         : in  std_logic;
        rst_buff    : in  std_logic;
        rst_l0      : out std_logic;
        rst_l0_buff : out std_logic
    );
end component;

    type dout_dec_array is array (8 downto 1) of std_logic_vector(7 downto 0);
    type vmmWord_array  is array (8 downto 1) of std_logic_vector(15 downto 0);
    
    signal wr_en            : std_logic_vector(8 downto 1)  := (others => '0');
    signal rd_ena_buff_i    : std_logic_vector(8 downto 1)  := (others => '0');
    signal vmmWordReady_i   : std_logic_vector(8 downto 1)  := (others => '0');
    signal vmmEventDone_i   : std_logic_vector(8 downto 1)  := (others => '0');
    signal vmmWord_i        : vmmWord_array;
    signal dout_dec         : dout_dec_array;

    signal rst_l0_logic     : std_logic := '0';
    signal rst_l0_buffers   : std_logic := '0';
    signal level_0_bufg     : std_logic := '0';

begin
  
---------------------------------------------
------------ One VMM Case -------------------
---------------------------------------------
one_vmm_case: if is_mmfe8 = '0' generate

 add_instances: for I in 1 to 1 generate 

des_dec_inst: l0_deserializer_decoder
    Port Map(
        ------------------------------------
        ------- General Interface ----------
        clk_ckdt    => clk_ckdt,
        clk_des     => clk_des,
        level_0     => level_0,
        rst         => rst_l0_logic,
        ------------------------------------
        -------- Buffer Interface ----------
        dout_dec    => dout_dec(I),
        wr_en       => wr_en(I),
        ------------------------------------
        ---------- VMM Interface -----------
        vmm_ckdt    => vmm_ckdt_vec(I),
        vmm_data0   => vmm_data0_vec(I),
        vmm_data1   => vmm_data1_vec(I)
    );
    
l0_buf_wr_inst: l0_buffer_wrapper
    Port Map(
        ------------------------------------
        ------- General Interface ----------
        clk_des         => clk_des,
        clk             => clk,
        rst             => rst_l0_logic,
        rst_buff        => rst_l0_buffers,
        ------------------------------------
        --- Deserializer Interface ---------
        dout_dec        => dout_dec(I),
        wr_en           => wr_en(I),
        ------------------------------------
        ---- Packet Formation Interface ----
        rd_ena_buff     => rd_ena_buff_i(I),
        rst_intf_proc   => rst_intf_proc,
        vmmWordReady    => vmmWordReady_i(I),
        vmmWord         => vmmWord_i(I),
        vmmEventDone    => vmmEventDone_i(I)
    );
    
 end generate add_instances;

end generate one_vmm_case;

---------------------------------------------
------------ Multiple VMMs Case -------------
---------------------------------------------

eight_vmm_case: if is_mmfe8 = '1' generate

 add_instances: for I in 1 to 8 generate 

l0_deserializer_decoder_inst: l0_deserializer_decoder
    Port Map(
        ------------------------------------
        ------- General Interface ----------
        clk_ckdt    => clk_ckdt,
        clk_des     => clk_des,
        level_0     => level_0,
        rst         => rst_l0_logic,
        ------------------------------------
        -------- Buffer Interface ----------
        dout_dec    => dout_dec(I),
        wr_en       => wr_en(I),
        ------------------------------------
        ---------- VMM Interface -----------
        vmm_ckdt    => vmm_ckdt_vec(I),
        vmm_data0   => vmm_data0_vec(I),
        vmm_data1   => vmm_data1_vec(I)
    );
    
l0_buffer_wrapper_inst: l0_buffer_wrapper
    Port Map(
        ------------------------------------
        ------- General Interface ----------
        clk_des         => clk_des,
        clk             => clk,
        rst             => rst_l0_logic,
        rst_buff        => rst_l0_buffers,
        ------------------------------------
        --- Deserializer Interface ---------
        dout_dec        => dout_dec(I),
        wr_en           => wr_en(I),
        ------------------------------------
        ---- Packet Formation Interface ----
        rd_ena_buff     => rd_ena_buff_i(I),
        rst_intf_proc   => rst_intf_proc,
        vmmWordReady    => vmmWordReady_i(I),
        vmmWord         => vmmWord_i(I),
        vmmEventDone    => vmmEventDone_i(I)
    );
    
 end generate add_instances;
 
end generate eight_vmm_case;

-- reset asserter 
l0_rst_inst: l0_rst
    Port Map(
        clk         => clk,
        rst         => rst,
        rst_buff    => rst_buff,
        rst_l0      => rst_l0_logic,
        rst_l0_buff => rst_l0_buffers
    );

-- multiplexer that drives the packet formation signals corresponding to the vmmID         
vmm_ID_MUX: process(vmmId, vmmWordReady_i, vmmWord_i, vmmEventDone_i, rd_ena_buff)
begin
    case vmmId is
    when "000"  =>
        vmmWordReady                <= vmmWordReady_i(1);
        vmmWord                     <= vmmWord_i(1);
        vmmEventDone                <= vmmEventDone_i(1);
        rd_ena_buff_i(1)            <= rd_ena_buff;
        rd_ena_buff_i(8 downto 2)   <= (others => '0');
    when "001"  =>
        vmmWordReady                <= vmmWordReady_i(2);
        vmmWord                     <= vmmWord_i(2);
        vmmEventDone                <= vmmEventDone_i(2);
        rd_ena_buff_i(2)            <= rd_ena_buff;
        rd_ena_buff_i(8 downto 3)   <= (others => '0');
        rd_ena_buff_i(1 downto 1)   <= (others => '0');
    when "010"  =>
        vmmWordReady                <= vmmWordReady_i(3);
        vmmWord                     <= vmmWord_i(3);
        vmmEventDone                <= vmmEventDone_i(3);
        rd_ena_buff_i(3)            <= rd_ena_buff;
        rd_ena_buff_i(8 downto 4)   <= (others => '0');
        rd_ena_buff_i(2 downto 1)   <= (others => '0');
    when "011"  =>
        vmmWordReady                <= vmmWordReady_i(4);
        vmmWord                     <= vmmWord_i(4);
        vmmEventDone                <= vmmEventDone_i(4);
        rd_ena_buff_i(4)            <= rd_ena_buff;
        rd_ena_buff_i(8 downto 5)   <= (others => '0');
        rd_ena_buff_i(3 downto 1)   <= (others => '0');
    when "100"  =>
        vmmWordReady                <= vmmWordReady_i(5);
        vmmWord                     <= vmmWord_i(5);
        vmmEventDone                <= vmmEventDone_i(5);
        rd_ena_buff_i(5)            <= rd_ena_buff;
        rd_ena_buff_i(8 downto 6)   <= (others => '0');
        rd_ena_buff_i(4 downto 1)   <= (others => '0');
    when "101"  =>
        vmmWordReady                <= vmmWordReady_i(6);
        vmmWord                     <= vmmWord_i(6);
        vmmEventDone                <= vmmEventDone_i(6);
        rd_ena_buff_i(6)            <= rd_ena_buff;
        rd_ena_buff_i(8 downto 7)   <= (others => '0');
        rd_ena_buff_i(5 downto 1)   <= (others => '0');
    when "110"  =>
        vmmWordReady                <= vmmWordReady_i(7);
        vmmWord                     <= vmmWord_i(7);
        vmmEventDone                <= vmmEventDone_i(7);
        rd_ena_buff_i(7)            <= rd_ena_buff;
        rd_ena_buff_i(8 downto 2)   <= (others => '0');
        rd_ena_buff_i(6 downto 1)   <= (others => '0');
    when "111"  =>
        vmmWordReady                <= vmmWordReady_i(8);
        vmmWord                     <= vmmWord_i(8);
        vmmEventDone                <= vmmEventDone_i(8);
        rd_ena_buff_i(8)            <= rd_ena_buff;
        rd_ena_buff_i(7 downto 1)   <= (others => '0');
    when others =>
        vmmWordReady                <= '0';
        vmmWord                     <= (others => '0');
        rd_ena_buff_i               <= (others => '0');
        vmmEventDone                <= '0';
    end case;
end process;

LEVEL0_BUFG: BUFG port map(O => level_0_bufg, I => level_0);

    vmm_cktk_vec(1) <= level_0_bufg;
    vmm_cktk_vec(2) <= level_0_bufg;
    vmm_cktk_vec(3) <= level_0_bufg;
    vmm_cktk_vec(4) <= level_0_bufg;
    vmm_cktk_vec(5) <= level_0_bufg;
    vmm_cktk_vec(6) <= level_0_bufg;
    vmm_cktk_vec(7) <= level_0_bufg;
    vmm_cktk_vec(8) <= level_0_bufg;
    
end RTL;