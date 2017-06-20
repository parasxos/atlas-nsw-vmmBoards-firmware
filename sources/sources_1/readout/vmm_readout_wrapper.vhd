----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch) 
-- 
-- Create Date: 28.04.2017 12:39:23
-- Design Name: VMM Readout Wrapper
-- Module Name: vmm_readout_wrapper - RTL
-- Project Name: NTUA-BNL VMM3 Readout Firmware
-- Target Devices: Xilinx xc7a200t-2fbg484
-- Tool Versions: Vivado 2016.4
-- Description: Wrapper that contains the two main components that implement the
-- VMM3 readout, namely vmm_readout (old continouous mode) and L0_wrapper (level-0)
-- mode.
-- 
-- Dependencies: 
-- 
-- Changelog: 
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity vmm_readout_wrapper is
    generic(is_mmfe8        : std_logic;
            vmmReadoutMode  : std_logic);
    Port(
    ------------------------------------
    --- Continuous Readout Interface ---
    clkTkProc       : in  std_logic;                    -- Used to clock checking for data process
    clkDtProc       : in  std_logic;                    -- Used to clock word readout process
    clk             : in  std_logic;                    -- Main clock
    --
    daq_enable      : in  std_logic;
    trigger_pulse   : in  std_logic;                     -- Trigger
    cktk_max        : in  std_logic_vector(7 downto 0);  -- Max number of CKTKs
    --
    dt_state_o      : out std_logic_vector(3 downto 0); -- for debugging
    dt_cntr_st_o    : out std_logic_vector(3 downto 0); -- for debugging
    ------------------------------------
    ---- Level-0 Readout Interface -----
    clk_ckdt        : in  std_logic;                    -- will be forwarded to the VMM
    clk_des         : in  std_logic;                    -- must be twice the frequency of CKDT
    rst_buff        : in  std_logic;                    -- reset the level-0 buffer
    rst_intf_proc   : in  std_logic;                    -- reset the pf interface
    --
    level_0         : in  std_logic;                    -- level-0 signal
    wr_accept       : in  std_logic;                    -- buffer acceptance window
    --
    vmm_conf        : in  std_logic;                    -- high during VMM configuration
    daq_on_inhib    : out std_logic;                    -- prevent daq_on state before checking link health
    ------------------------------------
    ---- Packet Formation Interface ----
    vmmWordReady    : out std_logic;
    vmmWord         : out std_logic_vector(15 downto 0);
    vmmEventDone    : out std_logic;
    rd_ena_buff     : in  std_logic;                     -- read the readout buffer (level0 or continuous)
    vmmId           : in  std_logic_vector(2 downto 0);  -- VMM to be readout
    linkHealth_bmsk : out std_logic_vector(8 downto 1);  -- status of comma alignment links
    ------------------------------------
    ---------- VMM3 Interface ----------
    vmm_data0_vec   : in  std_logic_vector(8 downto 1);  -- Single-ended data0 from VMM
    vmm_data1_vec   : in  std_logic_vector(8 downto 1);  -- Single-ended data1 from VMM
    vmm_ckdt_vec    : out std_logic_vector(8 downto 1);  -- Strobe to VMM CKDT
    vmm_cktk_vec    : out std_logic_vector(8 downto 1)   -- Strobe to VMM CKTK
    );
end vmm_readout_wrapper;

architecture RTL of vmm_readout_wrapper is

    component vmm_readout is
    Port( 
        clkTkProc               : in std_logic;     -- Used to clock checking for data process
        clkDtProc               : in std_logic;     -- Used to clock word readout process
        clk                     : in std_logic;     -- Used for fast switching between processes

        vmm_data0_vec           : in std_logic_vector(8 downto 1);      -- Single-ended data0 from VMM
        vmm_data1_vec           : in std_logic_vector(8 downto 1);      -- Single-ended data1 from VMM
        vmm_ckdt_vec            : out std_logic_vector(8 downto 1);     -- Strobe to VMM CKDT
        vmm_cktk_vec            : out std_logic_vector(8 downto 1);     -- Strobe to VMM CKTK

        daq_enable              : in std_logic;
        trigger_pulse           : in std_logic;                     -- Trigger
        cktk_max                : in std_logic_vector(7 downto 0);
        vmmId                   : in std_logic_vector(2 downto 0);  -- VMM to be readout
        ethernet_fifo_wr_en     : out std_logic;                    -- To be used for reading out seperate FIFOs in VMMx8 parallel readout
        vmm_data_buf            : buffer std_logic_vector(37 downto 0);
        
        vmmWordReady            : out std_logic;
        vmmWord                 : out std_logic_vector(15 downto 0);
        vmmEventDone            : out std_logic;
        
        rd_en                   : in  std_logic;
        
        dt_state_o              : out std_logic_vector(3 downto 0);
        dt_cntr_st_o            : out std_logic_vector(3 downto 0)
    );
    end component;

    component level0_wrapper is
    Generic(is_mmfe8        : std_logic;
            vmmReadoutMode  : std_logic);
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk_ckdt        : in  std_logic; -- will be forwarded to the VMM
        clk_des         : in  std_logic; -- must be twice the frequency of CKDT
        clk             : in  std_logic; -- buffer read domain
        rst_buff        : in  std_logic; -- reset buffer
        level_0         : in  std_logic; -- level-0 signal
        wr_accept       : in  std_logic; -- buffer acceptance window
        vmm_conf        : in  std_logic; -- high during VMM configuration
        daq_on_inhib    : out std_logic; -- prevent daq_on state before checking link health
        ------------------------------------
        ---- Packet Formation Interface ----
        rd_ena_buff     : in  std_logic;
        rst_intf_proc   : in  std_logic;                    -- reset the pf interface
        vmmId           : in std_logic_vector(2 downto 0);  -- VMM to be readout
        vmmWordReady    : out std_logic;
        vmmWord         : out std_logic_vector(15 downto 0);
        vmmEventDone    : out std_logic;
        linkHealth_bmsk : out std_logic_vector(8 downto 1);
        ------------------------------------
        ---------- VMM3 Interface ----------
        vmm_data0_vec   : in  std_logic_vector(8 downto 1);  -- Single-ended data0 from VMM
        vmm_data1_vec   : in  std_logic_vector(8 downto 1);  -- Single-ended data1 from VMM
        vmm_ckdt_vec    : out std_logic_vector(8 downto 1);  -- Strobe to VMM CKDT
        vmm_cktk_vec    : out std_logic_vector(8 downto 1)   -- Strobe to VMM CKTK
    );
    end component;

    signal data0_in_vec_cont    : std_logic_vector(8 downto 1)  := (others => '0');
    signal data1_in_vec_cont    : std_logic_vector(8 downto 1)  := (others => '0');
    signal ckdt_out_vec_cont    : std_logic_vector(8 downto 1)  := (others => '0');
    signal cktk_out_vec_cont    : std_logic_vector(8 downto 1)  := (others => '0');
    signal vmmWord_cont         : std_logic_vector(15 downto 0) := (others => '0');
    signal rd_en_cont           : std_logic := '0';
    signal vmmWordReady_cont    : std_logic := '0';
    signal vmmEventDone_cont    : std_logic := '0';

    signal data0_in_vec_l0      : std_logic_vector(8 downto 1)  := (others => '0');
    signal data1_in_vec_l0      : std_logic_vector(8 downto 1)  := (others => '0');
    signal ckdt_out_vec_l0      : std_logic_vector(8 downto 1)  := (others => '0');
    signal cktk_out_vec_l0      : std_logic_vector(8 downto 1)  := (others => '0');
    signal vmmWord_l0           : std_logic_vector(15 downto 0) := (others => '0');
    signal rd_en_l0             : std_logic := '0';
    signal vmmWordReady_l0      : std_logic := '0';
    signal vmmEventDone_l0      : std_logic := '0';

begin

-- continuous mode module instantiation
continuousReadoutMode: if vmmReadoutMode = '0' generate
readout_vmm_cont: vmm_readout
    port map(
        clkTkProc               => clkTkProc,
        clkDtProc               => clkDtProc,
        clk                     => clk,
        
        vmm_data0_vec           => data0_in_vec_cont,
        vmm_data1_vec           => data1_in_vec_cont,
        vmm_ckdt_vec            => ckdt_out_vec_cont,
        vmm_cktk_vec            => cktk_out_vec_cont,

        daq_enable              => daq_enable,
        trigger_pulse           => trigger_pulse,
        cktk_max                => cktk_max,
        vmmId                   => vmmId,
        ethernet_fifo_wr_en     => open,
        vmm_data_buf            => open,
        
        rd_en                   => rd_en_cont,
        
        vmmWordReady            => vmmWordReady_cont,
        vmmWord                 => vmmWord_cont,
        vmmEventDone            => vmmEventDone_cont,
        
        dt_state_o              => dt_state_o,
        dt_cntr_st_o            => dt_cntr_st_o
    );
end generate continuousReadoutMode;

level0_readout_case : if vmmReadoutMode = '1' generate
readout_vmm_l0: level0_wrapper
    generic map(is_mmfe8 => is_mmfe8, vmmReadoutMode => vmmReadoutMode)
    port map(
        ------------------------------------
        ------- General Interface ----------
        clk_ckdt        => clk_ckdt,
        clk_des         => clk_des,
        clk             => clk,
        rst_buff        => rst_buff,
        level_0         => level_0,
        wr_accept       => wr_accept,
        vmm_conf        => vmm_conf,
        daq_on_inhib    => daq_on_inhib,
        ------------------------------------
        ---- Packet Formation Interface ----
        rd_ena_buff     => rd_ena_buff,
        rst_intf_proc   => rst_intf_proc,
        vmmId           => vmmId,
        vmmWordReady    => vmmWordReady_l0,
        vmmWord         => vmmWord_l0,
        vmmEventDone    => vmmEventDone_l0,
        linkHealth_bmsk => linkHealth_bmsk,
        ------------------------------------
        ---------- VMM3 Interface ----------
        vmm_data0_vec   => data0_in_vec_l0,
        vmm_data1_vec   => data1_in_vec_l0,
        vmm_ckdt_vec    => ckdt_out_vec_l0,
        vmm_cktk_vec    => cktk_out_vec_l0
    );
end generate level0_readout_case;

-- multiplexer/demultiplexer for different mode cases
vmm_io_muxDemux: process(vmmWordReady_cont, vmmEventDone_cont, vmmWord_cont, ckdt_out_vec_cont, cktk_out_vec_cont, rd_ena_buff,
                         vmmWordReady_l0, vmmEventDone_l0, vmmWord_l0, ckdt_out_vec_l0, cktk_out_vec_l0, vmm_data0_vec, vmm_data1_vec)
begin
    case vmmReadoutMode is
    when '0' =>
        -- outputs
        vmmWordReady        <= vmmWordReady_cont;
        vmmEventDone        <= vmmEventDone_cont;
        vmmWord             <= vmmWord_cont;
        vmm_ckdt_vec        <= ckdt_out_vec_cont;
        vmm_cktk_vec        <= cktk_out_vec_cont;
        -- inputs
        rd_en_cont          <= rd_ena_buff;
        rd_en_l0            <= '0';
        data0_in_vec_cont   <= vmm_data0_vec;
        data1_in_vec_cont   <= vmm_data1_vec;
        data0_in_vec_l0     <= (others => '0');
        data1_in_vec_l0     <= (others => '0');
    when '1' =>
        -- outputs
        vmmWordReady        <= vmmWordReady_l0;
        vmmEventDone        <= vmmEventDone_l0;
        vmmWord             <= vmmWord_l0;
        vmm_ckdt_vec        <= ckdt_out_vec_l0;
        vmm_cktk_vec        <= cktk_out_vec_l0;
        -- inputs
        rd_en_cont          <= '0';
        rd_en_l0            <= rd_ena_buff;
        data0_in_vec_cont   <= (others => '0');
        data1_in_vec_cont   <= (others => '0');
        data0_in_vec_l0     <= vmm_data0_vec;
        data1_in_vec_l0     <= vmm_data1_vec;
    when others =>
        vmmWordReady        <= '0';
        vmmEventDone        <= '0';
        vmmWord             <= (others => '0');
        vmm_ckdt_vec        <= (others => '0');
        vmm_cktk_vec        <= (others => '0');
        -- inputs
        data0_in_vec_cont   <= (others => '0');
        data1_in_vec_cont   <= (others => '0');
        data0_in_vec_l0     <= (others => '0');
        data1_in_vec_l0     <= (others => '0');
    end case;
end process;

end RTL;

