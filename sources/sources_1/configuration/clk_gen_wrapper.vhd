----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Create Date: 19.02.2017 12:07:30
-- Design Name: 
-- Module Name: clk_gen_wrapper - RTL
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Wrapper that contains the CKTP and CKBC generators. It also 
-- instantiates a skewing module with 1.25 ns resolution. See skew_gen for more
-- information.
-- 
-- Dependencies: "Configurable CKBC/CKTP Constraints" .xdc snippet must be added to 
-- the main .xdc file of the design. Can be found at the project repository.
-- 
-- Changelog: 
-- 
----------------------------------------------------------------------------------
library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use UNISIM.VComponents.all;


entity clk_gen_wrapper is
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk_800             : in  std_logic;
        clk_160             : in  std_logic;
        rst                 : in  std_logic;
        mmcm_locked         : in  std_logic;
        ------------------------------------
        ----- Configuration Interface ------
        ckbc_ready          : in  std_logic;
        cktp_enable         : in  std_logic;
        cktp_pulse_width    : in  std_logic_vector(31 downto 0);
        cktp_period         : in  std_logic_vector(31 downto 0);
        cktp_skew           : in  std_logic_vector(15 downto 0);        
        ckbc_freq           : in  std_logic_vector(7 downto 0);
        ------------------------------------
        ---------- VMM Interface -----------
        CKTP                : out std_logic;
        CKBC                : out std_logic
    );
end clk_gen_wrapper;

architecture RTL of clk_gen_wrapper is

    component cktp_gen
    port(
        clk_160     : in  std_logic;
        cktp_start  : in  std_logic;
        vmm_ckbc    : in  std_logic; -- CKBC clock currently dynamic
        ckbc_freq   : in  std_logic_vector(7 downto 0);
        skew        : in  std_logic_vector(15 downto 0);
        pulse_width : in  std_logic_vector(31 downto 0);
        period      : in  std_logic_vector(31 downto 0);
        CKTP        : out std_logic
    );
    end component;

    component ckbc_gen
    port(  
        clk_160       : in std_logic;
        duty_cycle    : in std_logic_vector(7 downto 0);
        freq          : in std_logic_vector(7 downto 0);
        ready         : in std_logic;
        ckbc_out      : out std_logic
    );
    end component;
    
    component skew_gen
    port(
        clk_800         : in std_logic;
        CKTP_preSkew    : in std_logic;
        skew            : in std_logic_vector(4 downto 0);
        CKTP_skew       : out std_logic
    );    
    end component;

    signal ckbc_start       : std_logic := '0';
    signal cktp_start       : std_logic := '0';

    signal CKBC_preBuf      : std_logic := '0';
    signal CKBC_glbl        : std_logic := '0';
    
    signal CKTP_preAlign    : std_logic := '0';
    signal CKTP_aligned     : std_logic := '0';
    signal CKTP_skewed      : std_logic := '0';
    signal CKTP_glbl        : std_logic := '0';
    
    signal sel_cktp         : std_logic := '0';

begin

ckbc_generator: ckbc_gen
    port map(  
        clk_160       => clk_160,
        duty_cycle    => (others => '0'), -- unused
        freq          => ckbc_freq,
        ready         => ckbc_start,
        ckbc_out      => CKBC_preBuf
    );
      
CKBC_BUFGCE: BUFGCE
    port map(O => CKBC_glbl,  CE => ckbc_start, I => CKBC_preBuf);

cktp_generator: cktp_gen
    port map(
        clk_160     => clk_160,
        cktp_start  => cktp_start,
        vmm_ckbc    => CKBC_glbl,
        ckbc_freq   => ckbc_freq,
        skew        => (others => '0'), -- unused, skewing in another module
        pulse_width => cktp_pulse_width,
        period      => cktp_period,
        CKTP        => CKTP_preAlign
    );

-- align CKTP with CKBC (use skew_gen for skewing)    
alignCKTP_CKBC: process(CKBC_glbl)
begin
    if(rising_edge(CKBC_glbl))then
        CKTP_aligned <= CKTP_preAlign;  
    end if;
end process; 
    
skewing_module: skew_gen
    port map(
        clk_800         => clk_800,
        CKTP_preSkew    => CKTP_aligned,
        skew            => cktp_skew(4 downto 0),
        CKTP_skew       => CKTP_skewed
    );

CKTP_BUFGMUX: BUFGMUX
    port map(O => CKTP_glbl, I0 => CKTP_aligned, I1 => CKTP_skewed, S => sel_cktp);

skew_sel_proc: process(cktp_enable, cktp_skew)
begin
    if(cktp_enable = '1')then
        case cktp_skew is
        when x"0000" => sel_cktp <= '0'; -- select CKTP_aligned
        when others  => sel_cktp <= '1'; -- select CKTP_skewed
        end case;
    end if;
end process;

    cktp_start      <= not rst and ckbc_ready and cktp_enable and mmcm_locked;
    ckbc_start      <= not rst and ckbc_ready and mmcm_locked;

    CKBC            <= ckbc_glbl;
    CKTP            <= CKTP_glbl;
    
end RTL;
