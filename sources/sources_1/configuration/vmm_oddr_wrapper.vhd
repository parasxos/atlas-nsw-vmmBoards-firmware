----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch) 
-- 
-- Create Date: 21.06.2017 14:18:44
-- Design Name: VMM ODDR Wrapper
-- Module Name: vmm_oddr_wrapper - RTL
-- Project Name: NTUA-BNL VMM3 Readout Firmware
-- Target Devices: Xilinx xc7a200t-2fbg484 and xc7a100t
-- Tool Versions: Vivado 2017.2
-- Description: Wrapper that contains the ODDR instantiations necessary for VMM
-- clock forwarding.
-- 
-- Dependencies: 
-- 
-- Changelog: 
-- 
----------------------------------------------------------------------------------
library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use UNISIM.VComponents.all;

entity vmm_oddr_wrapper is
    Port(
        -------------------------------------------------------
        ckdt_bufg       : in  std_logic;
        ckdt_enable_vec : in  std_logic_vector(8 downto 1);
        ckdt_toBuf_vec  : out std_logic_vector(8 downto 1);
        -------------------------------------------------------
        ckbc_bufg       : in  std_logic;
        ckbc_enable     : in  std_logic;
        ckbc_toBuf_vec  : out std_logic_vector(8 downto 1);
        -------------------------------------------------------
        cktp_bufg       : in  std_logic;
        cktp_toBuf_vec  : out std_logic_vector(8 downto 1);
        -------------------------------------------------------
        ckart_bufg      : in  std_logic;
        ckart_toBuf_vec : out std_logic_vector(9 downto 1)
        -------------------------------------------------------
    );
end vmm_oddr_wrapper;

architecture RTL of vmm_oddr_wrapper is

    signal ckdt_inhibit    : std_logic_vector(8 downto 1) := (others => '0'); 
    signal ckbc_inhibit    : std_logic := '0';

begin

----------------------------
--------- CKDT/ODDR --------
----------------------------

ODDR_CKDT_1: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckdt_toBuf_vec(1),
        C   => ckdt_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKDT_2: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckdt_toBuf_vec(2),
        C   => ckdt_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKDT_3: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckdt_toBuf_vec(3),
        C   => ckdt_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKDT_4: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckdt_toBuf_vec(4),
        C   => ckdt_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKDT_5: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckdt_toBuf_vec(5),
        C   => ckdt_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKDT_6: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckdt_toBuf_vec(6),
        C   => ckdt_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKDT_7: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckdt_toBuf_vec(7),
        C   => ckdt_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKDT_8: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckdt_toBuf_vec(8),
        C   => ckdt_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );


----------------------------
--------- CKBC/ODDR --------
----------------------------

ODDR_CKBC_1: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckbc_toBuf_vec(1),
        C   => ckbc_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKBC_2: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckbc_toBuf_vec(2),
        C   => ckbc_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKBC_3: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckbc_toBuf_vec(3),
        C   => ckbc_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKBC_4: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckbc_toBuf_vec(4),
        C   => ckbc_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKBC_5: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckbc_toBuf_vec(5),
        C   => ckbc_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKBC_6: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckbc_toBuf_vec(6),
        C   => ckbc_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKBC_7: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckbc_toBuf_vec(7),
        C   => ckbc_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKBC_8: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckbc_toBuf_vec(8),
        C   => ckbc_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );


----------------------------
--------- CKTP/ODDR --------
----------------------------

ODDR_CKTP_1: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => cktp_toBuf_vec(1),
        C   => cktp_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKTP_2: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => cktp_toBuf_vec(2),
        C   => cktp_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKTP_3: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => cktp_toBuf_vec(3),
        C   => cktp_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKTP_4: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => cktp_toBuf_vec(4),
        C   => cktp_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKTP_5: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => cktp_toBuf_vec(5),
        C   => cktp_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKTP_6: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => cktp_toBuf_vec(6),
        C   => cktp_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKTP_7: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => cktp_toBuf_vec(7),
        C   => cktp_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKTP_8: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => cktp_toBuf_vec(8),
        C   => cktp_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

----------------------------
--------- CKART/ODDR -------
----------------------------

ODDR_CKART_1: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckart_toBuf_vec(1),
        C   => ckart_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKART_2: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckart_toBuf_vec(2),
        C   => ckart_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKART_3: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckart_toBuf_vec(3),
        C   => ckart_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKART_4: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckart_toBuf_vec(4),
        C   => ckart_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKART_5: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckart_toBuf_vec(5),
        C   => ckart_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKART_6: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckart_toBuf_vec(6),
        C   => ckart_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKART_7: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckart_toBuf_vec(7),
        C   => ckart_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKART_8: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckart_toBuf_vec(8),
        C   => ckart_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

ODDR_CKART_9: ODDR
    generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        INIT         => '0',
        SRTYPE       => "SYNC")
    port map(
        Q   => ckart_toBuf_vec(9),
        C   => ckart_bufg,
        CE  => '1',
        D1  => '1',
        D2  => '0',
        R   => '0',
        S   => '0' 
    );

    ckdt_inhibit(1) <= not ckdt_enable_vec(1);
    ckdt_inhibit(2) <= not ckdt_enable_vec(2);
    ckdt_inhibit(3) <= not ckdt_enable_vec(3);
    ckdt_inhibit(4) <= not ckdt_enable_vec(4);
    ckdt_inhibit(5) <= not ckdt_enable_vec(5);
    ckdt_inhibit(6) <= not ckdt_enable_vec(6);
    ckdt_inhibit(7) <= not ckdt_enable_vec(7);
    ckdt_inhibit(8) <= not ckdt_enable_vec(8);

    ckbc_inhibit    <= not ckbc_enable;

end RTL;