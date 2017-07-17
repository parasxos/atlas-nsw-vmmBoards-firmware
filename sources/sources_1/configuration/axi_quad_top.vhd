----------------------------------------------------------------------------------
-- Company:  University of Washington
-- Engineer: Lev Kurilenko
-- 
-- Copyright Notice/Copying Permission:
--    Copyright 2017 Lev Kurilenko
--
--    This file is part of NTUA-BNL_VMM_firmware.
--
--    NTUA-BNL_VMM_firmware is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    NTUA-BNL_VMM_firmware is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with NTUA-BNL_VMM_firmware.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- Create Date: 08/18/2016 11:27:16 AM
-- Design Name: 
-- Module Name: AXI4_SPI_top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-- Micron SPI Flash  Documentation (n25q256 1.8V):  https://www.micron.com/~/media/documents/products/data-sheet/nor-flash/serial-nor/n25q/n25q_256mb_1_8v.pdf
-- axi_quad_spi      Documentation:                 http://www.xilinx.com/support/documentation/ip_documentation/axi_quad_spi/v3_2/pg153-axi-quad-spi.pdf
----------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity AXI4_SPI is
    port(            
            clk_200                 : in  std_logic;
            clk_125                 : in  std_logic;
            clk_50                  : in  std_logic;
            
            myIP                    : out std_logic_vector(31 downto 0);    -- Signal going out to mmfe8_top and used as main IP
            myMAC                   : out std_logic_vector(47 downto 0);    -- Signal going out to mmfe8_top and used as main MAC
            destIP                  : out std_logic_vector(31 downto 0);    -- Signal going out to mmfe8_top and used as main destIP
            
            default_IP              : in std_logic_vector(31 downto 0);
            default_MAC             : in std_logic_vector(47 downto 0);
            default_destIP          : in std_logic_vector(31 downto 0);
            
            myIP_set                : in std_logic_vector(31 downto 0);     -- Signal coming from config_logic. Used to set myIP
            myMAC_set               : in std_logic_vector(47 downto 0);     -- Signal coming from config_logic. Used to set myMAC
            destIP_set              : in std_logic_vector(31 downto 0);     -- Signal coming from config_logic. Used to set destIP
            
            newip_start             : in std_logic;                         -- Flag that initiates the process for setting newIP
            flash_busy              : out std_logic;                        -- Flag that indicates the module is busy setting IP
            
            -- refer to Micron documentation for the signals below: https://www.micron.com/~/media/documents/products/data-sheet/nor-flash/serial-nor/n25q/n25q_256mb_1_8v.pdf
            io0_i                   : IN STD_LOGIC;                         -- Signals for DQ0 (MOSI)
            io0_o                   : OUT STD_LOGIC;
            io0_t                   : OUT STD_LOGIC;
            io1_i                   : IN STD_LOGIC;                         -- Signals for DQ1 (MISO)
            io1_o                   : OUT STD_LOGIC;
            io1_t                   : OUT STD_LOGIC;
            ss_i                    : IN STD_LOGIC_VECTOR(0 DOWNTO 0);      -- Slave Select
            ss_o                    : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
            ss_t                    : OUT STD_LOGIC
            --SPI_CLK                 : in    std_logic
    );
end AXI4_SPI;

architecture Behavioral of AXI4_SPI is

    -------------------------------------------------
    -- Flow FSM signals
    -------------------------------------------------
    type state_spi is (SETUP, IDLE, WAIT_WRITE, WRITE, FINISH_WRITE, WAIT_READ, READ, FINISH_READ);
    signal spi_state        : state_spi;                    -- State machine that handles the signals necessary to perform a single write to or read to and from a core register in the axi_quad_spi

    type state_spi_control is (CLEAR_FIFO, WRITE_CMD_ADDR_DATA, ASSERT_SS, DEASSERT_INHIB, CLEAR_SS, ASSERT_INHIB, READ_SPI_DATA, RESET);
    signal spi_state_control        : state_spi_control;    -- State machine that handles the higher level flow (above spi_state) in order to execute a proper transaction via the axi_quad_spi (Nested within spi_state = IDLE)

    type config_ip_state is (IDLE, CHECK_IP_SET, SET_IP, NEW_IP, RESET);
    signal ip_config_state : config_ip_state;               -- State machine that handles Dynamic IP Configuration. Can be though of as wrapper that allows proper function of Dynamic IP Configuration
    
    type spi_write_state is (WRITE_ENABLE, SUBSECTOR_ERASE, PAGE_PROGRAM, RESET);
    signal write_spi_state : spi_write_state;               -- State machine nested within ip_config_state = NEW_IP. Handles the necessary logic in order to execute a write to the SPI Flash. (Specific logic flow needed)
    
    -------------------------------------------------
    -- FSM Automation signals
    -------------------------------------------------
    signal araddr_set               : std_logic_vector(6 downto 0);     -- Sets read address for registers in axi_quad_spi
    signal awaddr_set               : std_logic_vector(6 downto 0);     -- Sets write address for registers in axi_quad_spi
    signal wdata_set                : std_logic_vector(31 downto 0);    -- Sets write data for registers in axi_quad_spi
    
    signal byte_transfer_counter    : integer := 0;                     -- Counts how many bytes are being transferred/read to or from Rx or Tx FIFO in axi_quad_spi 
    signal page_prog_counter        : integer := 0;                     -- Used to see what page program iteration (command to SPI Flash) FSM is at
    signal set_ip_counter           : integer := 0;                     -- Counter used to delay some signals within FSM for proper transactions
    signal check_ip_counter         : integer := 0;                     -- Counts how many times the check_ip_flag was checked 
    shared variable cmdaddrdata     : bit_vector(79 downto 0);          -- Stores command, address, and data needed for transactions with the SPI Flash
     
    signal start_transaction        : std_logic := '0';                 -- Flag that initiates a transaction with the SPI Flash
    signal transaction_finished     : std_logic := '1';                 -- Flag letting the FSM know that transaction is finished
    signal second_transaction       : std_logic := '0';                 -- Flag used when performing 2 transaction to read the proper data from SPI Flash
    signal page_prog                : std_logic := '0';                 -- Page program flag lets the spi_write_state = WRITE_ENABLE state know whether to perform a SUBESCTOR_ERASE or a PAGE_PROGRAM 
    
    signal system_start            : std_logic := '0';                  -- Flag used to check if the system has just started. Used to configure the proper IP, MAC, and destIP
    -------------------------------------------------
    -- Dynamic IP signals
    -------------------------------------------------
    signal cmdaddrdata_set    : std_logic_vector(79 downto 0);
    signal byte_count_set     : std_logic_vector(31 downto 0);
    signal ip_set_flag        : std_logic_vector(7 downto 0) := x"FF";
    signal new_ip_set         : std_logic := '0';
    signal set_default_ip     : std_logic := '0';
    
    -------------------------------------------------
    -- Debugging Signals
    -------------------------------------------------   
    signal read_out           : std_logic_vector(244 downto 0);
    
    -------------------------------------------------
    -- Quad SPI Signals 
    -- refer to quad_spi_documentation: http://www.xilinx.com/support/documentation/ip_documentation/axi_quad_spi/v3_2/pg153-axi-quad-spi.pdf
    -------------------------------------------------
    signal   ip2intc_irpt : std_logic:= '0';          
    signal   spi_rdata  : STD_LOGIC_VECTOR(31 DOWNTO 0):=(others => '0');
    signal   spi_arready : std_logic:= '0';
    signal   spi_rresp : STD_LOGIC_VECTOR(1 DOWNTO 0):=(others => '0');
    signal   spi_rvalid : std_logic:= '1';
    signal   spi_counter : integer := 0;
    signal   spi_slct_cmd : integer := 0;
    signal   spi_cnt : STD_LOGIC_VECTOR(31 DOWNTO 0):=(others => '0');
    signal   spi_awready : std_logic := '1';
    signal   spi_bresp : STD_LOGIC_vector(1 downto 0) := "00";
    signal   spi_bvalid : std_logic := '0';
    
    signal   spi_awaddr     : std_logic_vector(6 downto 0) := "0000000";
    signal   spi_wdata      : std_logic_vector(31 downto 0) := x"00000000";
    signal   spi_wstrb      : std_logic_vector(3 downto 0) := "0000";
    signal   spi_aresetn    : std_logic := '0';
    signal   spi_awvalid    : std_logic := '0';
    signal   spi_wvalid     : std_logic := '0';
    signal   spi_bready     : std_logic := '0';
    signal   spi_wready     : std_logic := '0';
    signal   spi_arvalid    : std_logic := '0';
    signal   spi_rready     : std_logic := '0';    
    signal   spi_araddr     : std_logic_vector(6 downto 0) := "0000000";
    signal   spi_state_is   : std_logic_vector(3 downto 0) := "0000";
    signal   spi_state_control_is   : std_logic_vector(3 downto 0) := "0000";
    signal   spi_ip_config_state_is   : std_logic_vector(3 downto 0) := "0000";
    signal   write_spi_state_is   : std_logic_vector(3 downto 0) := "0000";
    
    signal   startupe2_eos : std_logic;

    -------------------------------------------------------------------
    -- CDCC signals
    ------------------------------------------------------------------- 
    signal flash_busy_i     : std_logic := '0';
    signal myIP_i           : std_logic_vector(31 downto 0) := (others => '0');
    signal myMAC_i          : std_logic_vector(47 downto 0) := (others => '0');
    signal destIP_i         : std_logic_vector(31 downto 0) := (others => '0');

    signal newIP_start_s50  : std_logic := '0';
    signal myIP_set_s50     : std_logic_vector(31 downto 0) := (others => '0');
    signal myMAC_set_s50    : std_logic_vector(47 downto 0) := (others => '0');
    signal destIP_set_s50   : std_logic_vector(31 downto 0) := (others => '0');

    -------------------------------------------------------------------
    -- Keep signals for ILA
    -------------------------------------------------------------------
--    attribute keep          : string;
--    attribute dont_touch    : string;
        
    -------------------------------------------------------------------
    -- Other
    -------------------------------------------------------------------     
    
--    attribute keep of ip_set_flag                   : signal is "TRUE";
--    attribute dont_touch of ip_set_flag             : signal is "TRUE";
    
--    attribute keep of spi_arready                   : signal is "TRUE";
--    attribute dont_touch of spi_arready             : signal is "TRUE";    
    
--    attribute keep of spi_rresp                     : signal is "TRUE";
--    attribute dont_touch of spi_rresp               : signal is "TRUE";         
    
--    attribute keep of spi_rvalid                    : signal is "TRUE";
--    attribute dont_touch of spi_rvalid              : signal is "TRUE";   

--    attribute keep of spi_cnt                       : signal is "TRUE";
--    attribute dont_touch of spi_cnt                 : signal is "TRUE";   
    
--    attribute keep of spi_awready                   : signal is "TRUE";
--    attribute dont_touch of spi_awready             : signal is "TRUE";       
    
--    attribute keep of spi_bresp                     : signal is "TRUE";
--    attribute dont_touch of spi_bresp               : signal is "TRUE";   
    
--    attribute keep of spi_bvalid                    : signal is "TRUE";
--    attribute dont_touch of spi_bvalid              : signal is "TRUE";         
    
--    attribute keep of spi_awaddr                    : signal is "TRUE";
--    attribute dont_touch of spi_awaddr              : signal is "TRUE";         
    
--    attribute keep of spi_wdata                     : signal is "TRUE";
--    attribute dont_touch of spi_wdata               : signal is "TRUE";   
    
--    attribute keep of spi_wstrb                     : signal is "TRUE";
--    attribute dont_touch of spi_wstrb               : signal is "TRUE";   
    
--    attribute keep of spi_aresetn                   : signal is "TRUE";
--    attribute dont_touch of spi_aresetn             : signal is "TRUE";       
       
--    attribute keep of spi_awvalid                   : signal is "TRUE";
--    attribute dont_touch of spi_awvalid             : signal is "TRUE";   
    
--    attribute keep of spi_wvalid                    : signal is "TRUE";
--    attribute dont_touch of spi_wvalid              : signal is "TRUE";    

--    attribute keep of spi_bready                    : signal is "TRUE";
--    attribute dont_touch of spi_bready              : signal is "TRUE";      
    
--    attribute keep of spi_wready                    : signal is "TRUE";
--    attribute dont_touch of spi_wready              : signal is "TRUE";     
    
--    attribute keep of spi_arvalid                   : signal is "TRUE";
--    attribute dont_touch of spi_arvalid             : signal is "TRUE";  
    
--    attribute keep of spi_rready                    : signal is "TRUE";
--    attribute dont_touch of spi_rready              : signal is "TRUE";  

--    attribute keep of spi_araddr                    : signal is "TRUE";
--    attribute dont_touch of spi_araddr              : signal is "TRUE";
    
--    attribute keep of spi_rdata                     : signal is "TRUE";
--    attribute dont_touch of spi_rdata               : signal is "TRUE";
    
--    attribute keep of araddr_set                    : signal is "TRUE";
--    attribute dont_touch of araddr_set              : signal is "TRUE";
    
--    attribute keep of awaddr_set                    : signal is "TRUE";
--    attribute dont_touch of awaddr_set              : signal is "TRUE";
    
--    attribute keep of wdata_set                     : signal is "TRUE";
--    attribute dont_touch of wdata_set               : signal is "TRUE";
    
--    attribute keep of spi_state_control_is          : signal is "TRUE";
--    attribute dont_touch of spi_state_control_is    : signal is "TRUE";
         
--    attribute keep of io0_i                         : signal is "TRUE";
--    attribute dont_touch of io0_i                   : signal is "TRUE";
    
--    attribute keep of io0_o                         : signal is "TRUE";
--    attribute dont_touch of io0_o                   : signal is "TRUE";
    
--    attribute keep of io0_t                         : signal is "TRUE";
--    attribute dont_touch of io0_t                   : signal is "TRUE";   
 
--    attribute keep of io1_i                         : signal is "TRUE";
--    attribute dont_touch of io1_i                   : signal is "TRUE";
    
--    attribute keep of io1_o                         : signal is "TRUE";
--    attribute dont_touch of io1_o                   : signal is "TRUE";
    
--    attribute keep of io1_t                         : signal is "TRUE";
--    attribute dont_touch of io1_t                   : signal is "TRUE";   
    
--    attribute keep of ss_i                          : signal is "TRUE";
--    attribute dont_touch of ss_i                    : signal is "TRUE";
    
--    attribute keep of ss_o                          : signal is "TRUE";
--    attribute dont_touch of ss_o                    : signal is "TRUE";
    
--    attribute keep of ss_t                          : signal is "TRUE";
--    attribute dont_touch of ss_t                    : signal is "TRUE";
    
--    attribute keep of cmdaddrdata_set               : signal is "TRUE";
--    attribute dont_touch of cmdaddrdata_set         : signal is "TRUE";
        
--    attribute keep of cmdaddrdata                   : variable is "TRUE";
--    attribute dont_touch of cmdaddrdata             : variable is "TRUE";

--    attribute keep of start_transaction             : signal is "TRUE";
--    attribute dont_touch of start_transaction       : signal is "TRUE";

--    attribute keep of transaction_finished          : signal is "TRUE";
--    attribute dont_touch of transaction_finished    : signal is "TRUE";
    
--    attribute keep of spi_ip_config_state_is        : signal is "TRUE";
--    attribute dont_touch of spi_ip_config_state_is  : signal is "TRUE";
    
--    attribute keep of newip_start                   : signal is "TRUE";
--    attribute dont_touch of newip_start             : signal is "TRUE";
    
--    attribute keep of write_spi_state_is            : signal is "TRUE";
--    attribute dont_touch of write_spi_state_is      : signal is "TRUE";
      
--    attribute keep of byte_transfer_counter          : signal is "true";
--    attribute keep of set_ip_counter                 : signal is "true";
--    attribute keep of page_prog_counter              : signal is "true";
--    attribute keep of second_transaction             : signal is "true";
--    attribute keep of page_prog                      : signal is "true";
--    attribute keep of system_start                   : signal is "true";
--    attribute keep of check_ip_counter               : signal is "true";
--    attribute keep of set_default_ip                 : signal is "true";
    
--    attribute keep of myIP_set                       : signal is "true";
--    attribute keep of myMAC_set                      : signal is "true";
--    attribute keep of destIP_set                     : signal is "true";
--    attribute dont_touch of myIP_set                 : signal is "true";
--    attribute dont_touch of myMAC_set                : signal is "true";
--    attribute dont_touch of destIP_set               : signal is "true";
    
    
    component ila_spi_flash
        PORT (  clk     : IN std_logic;
                probe0  : IN std_logic_vector(244 DOWNTO 0)
                );
    end component;

    component CDCC
    generic(
        NUMBER_OF_BITS : integer := 8); -- number of signals to be synced
    port(
        clk_src     : in  std_logic;                                        -- input clk (source clock)
        clk_dst     : in  std_logic;                                        -- input clk (dest clock)
        data_in     : in  std_logic_vector(NUMBER_OF_BITS - 1 downto 0);    -- data to be synced
        data_out_s  : out std_logic_vector(NUMBER_OF_BITS - 1 downto 0)     -- synced data to clk_dst
    );
    end component;    
    
--    component vio_0
--        PORT (  clk     : IN std_logic;
--                probe_out0 : OUT std_logic;
--                probe_out1 : OUT std_logic;
--                probe_out2 : OUT std_logic_vector(79 DOWNTO 0);
--                probe_out3 : OUT std_logic_vector(31 DOWNTO 0);
--                probe_out4 : OUT std_logic;
--                probe_out5 : OUT std_logic
--                );
--    end component;
        
    component axi_quad_spi_0 is
        Port ( 
            ext_spi_clk : in std_logic;
            s_axi_aclk : in std_logic;
            s_axi_aresetn : in std_logic;
            s_axi_awaddr : in STD_LOGIC_VECTOR ( 6 downto 0 );
            s_axi_awvalid : in std_logic;
            s_axi_awready : out std_logic;
            s_axi_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
            s_axi_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
            s_axi_wvalid : in std_logic;
            s_axi_wready : out std_logic;
            s_axi_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
            s_axi_bvalid : out std_logic;
            s_axi_bready : in std_logic;
            s_axi_araddr : in STD_LOGIC_VECTOR ( 6 downto 0 );
            s_axi_arvalid : in std_logic;
            s_axi_arready : out std_logic;
            s_axi_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
            s_axi_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
            s_axi_rvalid : out std_logic;
            s_axi_rready : in std_logic;
            io0_i : in std_logic;
            io0_o : out std_logic;
            io0_t : out std_logic;
            io1_i : in std_logic;
            io1_o : out std_logic;
            io1_t : out std_logic;
            ss_i : in STD_LOGIC_VECTOR ( 0 to 0 );
            ss_o : out STD_LOGIC_VECTOR ( 0 to 0 );
            ss_t : out std_logic;
            ip2intc_irpt : out std_logic;
            cfgclk : out std_logic;
            cfgmclk : out std_logic;
            eos : out std_logic;
            preq : out std_logic
      );   
    end component;

begin


axi_SPI: axi_quad_spi_0
      Port map( 
        ext_spi_clk     => clk_50,      --V22
        --ext_spi_clk     => SPI_CLK,      --V22
        s_axi_aclk      => clk_50,
        s_axi_aresetn   => spi_aresetn,
        
        s_axi_awaddr    => spi_awaddr, 
        s_axi_awvalid   => spi_wvalid,
        s_axi_awready   => spi_awready,
        
        s_axi_wdata     => spi_wdata, 
        s_axi_wstrb     => spi_wstrb, 
        s_axi_wvalid    => spi_wvalid,
        s_axi_wready    => spi_wready,
        
        s_axi_bresp     => spi_bresp, 
        s_axi_bvalid    => spi_bvalid,
        s_axi_bready    => spi_bready,
        
        s_axi_araddr    => spi_araddr, 
        s_axi_arvalid   => spi_arvalid,
        s_axi_arready   => spi_arready,
        s_axi_rdata     => spi_rdata, 
        s_axi_rresp     => spi_rresp, 
        s_axi_rvalid    => spi_rvalid,
        s_axi_rready    => spi_rready,
        
        io0_i           => io0_i,
        io0_o           => io0_o,
        io0_t           => io0_t,
        io1_i           => io1_i,
        io1_o           => io1_o,
        io1_t           => io1_t,
        ss_i            => ss_i,
        ss_o            => ss_o,
        ss_t            => ss_t,
        
        ip2intc_irpt    => ip2intc_irpt,
        
        cfgclk          => open,
        cfgmclk         => open,
        eos             => startupe2_eos,
        preq            => open
      );


spi_ip_config: process(clk_50)  -- Process that handles Dynamic IP Configuration
    begin
    if rising_edge(clk_50) then
        case ip_config_state is     -- State machine that handles Dynamic IP Configuration. Can be though of as wrapper that allows proper function of Dynamic IP Configuration
            when IDLE =>
                spi_ip_config_state_is <= "0000";
                flash_busy_i             <= '0';
                if (system_start = '0') then                     -- Checked when system is started to set IP
                    ip_config_state <= CHECK_IP_SET; 
                elsif (newip_start_s50 = '1') then               -- This is set when UDP dest port 6604 receives data
                    ip_config_state <= NEW_IP;
                else
                    ip_config_state <= IDLE;
                end if;
            when CHECK_IP_SET =>
                spi_ip_config_state_is <= "0001";
                flash_busy_i             <= '1';
                cmdaddrdata_set     <= x"03F0_0000_0000_0000_0000";         -- Command to read ipset_flag in address x"F0_0000"
                byte_count_set      <= x"0000_0004";                        -- Byte count required for proper read: 4 bytes (starts at 0)
                set_ip_counter      <= 0;
                start_transaction   <= '0';
                
                if (transaction_finished = '1') then                        -- Checks if ipset_flag = x"01" and sets the flag accordingly
                    if (ip_set_flag = x"01") then
                        system_start        <= '1';
                        ip_config_state     <= SET_IP;
                        check_ip_counter    <= 0; 
                    elsif ((ip_set_flag /= x"01")  and (check_ip_counter > 5)) then     -- Must iterate 
                        ip_config_state     <= IDLE;
                        set_default_ip      <= '1';
                        system_start        <= '1';
                        check_ip_counter    <= 0;
                    else    
                        start_transaction   <= '1';
                        check_ip_counter    <= check_ip_counter + 1;
                    end if;
                end if;            
            when SET_IP =>      -- Performs necessary operations to read SPI Flash and set the current IP, MAC, and destIP
                spi_ip_config_state_is <= "0010";
                if ( set_ip_counter <= 50) then
                    set_ip_counter      <= set_ip_counter + 1;
                end if;          
                if ((transaction_finished = '1') and (set_ip_counter < 10)) then                    
                    second_transaction  <= '0';
                    cmdaddrdata_set     <= x"03F0_0001_0000_0000_0000";
                    byte_count_set      <= x"0000_000F";
                    start_transaction   <= '1';
                elsif ((transaction_finished = '1') and (set_ip_counter >= 40)) then
                    second_transaction  <= '1';
                    cmdaddrdata_set     <= x"03F0_000D_0000_0000_0000";
                    byte_count_set      <= x"0000_0005";
                    set_ip_counter      <= set_ip_counter + 1;
                    start_transaction   <= '1';
                    if( set_ip_counter = 70) then     
                        ip_config_state     <= RESET;
                        set_ip_counter      <= 0;
                    end if;
                else
                    start_transaction   <= '0';
                end if;
            when NEW_IP =>      -- Writes new IP, MAC, and destIP into SPI Flash and sets the new IP as the current active IP, MAC, and destIP
                spi_ip_config_state_is <= "0011";
                flash_busy_i             <= '1';
                    case write_spi_state is         -- State machine nested within ip_config_state = NEW_IP. Handles the necessary logic in order to execute a write to the SPI Flash. (Uses logic flow described in Micron Documentation)
                        when WRITE_ENABLE =>
                            write_spi_state_is  <= "0000";
                            start_transaction   <= '0';
                            if (set_ip_counter < 3) then    --Wait 3 Clock cycles before beginning next transaction
                                set_ip_counter          <= set_ip_counter + 1;  
                            elsif ((transaction_finished = '1') and (set_ip_counter = 3)) then                    
                                cmdaddrdata_set         <= x"0600_0000_0000_0000_0000";         --SPI WRITE ENABLE
                                byte_count_set          <= x"0000_0000";
                                start_transaction       <= '1';
                                set_ip_counter          <= 0;
                                if (page_prog = '0') then
                                    write_spi_state         <= SUBSECTOR_ERASE;
                                    page_prog               <= '1';     
                                elsif (page_prog = '1') then
                                    write_spi_state     <= PAGE_PROGRAM;
                                end if;
                            end if;
                        when SUBSECTOR_ERASE =>
                            write_spi_state_is  <= "0001";
                            start_transaction   <= '0';
                            
                            if (set_ip_counter < 3) then    --Wait 3 Clock cycles before beginning next transaction
                                set_ip_counter      <= set_ip_counter + 1;   
                            elsif ((transaction_finished = '1') and (set_ip_counter = 3)) then
                                cmdaddrdata_set     <= x"20F0_0000_0000_0000_0000";         --SPI SUBSECTOR ERASE 4kB
                                byte_count_set      <= x"0000_0003";
                                start_transaction   <= '1';
                                set_ip_counter      <= 0;
                                write_spi_state     <= WRITE_ENABLE;
                            end if;
                        when PAGE_PROGRAM =>
                            write_spi_state_is  <= "0010";
                            start_transaction   <= '0';
                            
                            if (set_ip_counter < 3) then    --Wait 3 Clock cycles before beginning next transaction
                                set_ip_counter      <= set_ip_counter + 1;
                                
                            elsif ((transaction_finished = '1') and (set_ip_counter = 3)) then                        
                                set_ip_counter      <= 0;
                                if (page_prog_counter = 0) then
                                    page_prog_counter   <= page_prog_counter + 1;                                    

                                    --myIP_set    -- 32 bits
                                    --myMAC_set   -- 48 bits
                                    --destIP_set  -- 32 bits

                                    cmdaddrdata_set(79 downto 40)    <= x"02F0_0000_01";         --SPI PAGE PROGRAM 256 BYTES
                                    cmdaddrdata_set(39 downto 8)     <= myIP_set_s50(31 downto 0);
                                    cmdaddrdata_set(7 downto 0)      <= myMAC_set_s50(47 downto 40);
                                    
                                    byte_count_set      <= x"0000_0009";
                                    write_spi_state     <= WRITE_ENABLE;        -- Write enable must be issued before every write operation
                                    start_transaction   <= '1';
                                    
                                elsif (page_prog_counter = 1) then
                                    page_prog_counter   <= page_prog_counter + 1;
                                
                                    cmdaddrdata_set(79 downto 48)     <= x"02F0_0006";         --SPI PAGE PROGRAM 256 BYTES
                                    cmdaddrdata_set(47 downto 8)     <= myMAC_set_s50(39 downto 0);
                                    cmdaddrdata_set(7 downto 0)      <= destIP_set_s50(31 downto 24);                                
                                
                                    byte_count_set      <= x"0000_0009";
                                    write_spi_state     <= WRITE_ENABLE;        -- Write enable must be issued before every write operation
                                    start_transaction   <= '1';
                                    
                                elsif (page_prog_counter = 2) then
                                    page_prog_counter   <= page_prog_counter + 1;
                                    
                                    cmdaddrdata_set(79 downto 48)    <= x"02F0_000C";         --SPI PAGE PROGRAM 256 BYTES
                                    cmdaddrdata_set(47 downto 24)    <= destIP_set_s50(23 downto 0);
                                    cmdaddrdata_set(23 downto 0)     <= x"0000_00";
                                    
                                    byte_count_set      <= x"0000_0006";
                                    start_transaction   <= '1';
                                    
                                elsif (page_prog_counter = 3) then
                                    page_prog_counter   <= 0;
                                    write_spi_state     <= RESET;
                                    page_prog           <= '0';
                                    set_default_ip      <= '0';
                                    system_start        <= '0';     -- This will 'reset' the system_start flag and the FSM will check for the IP in SPI Flash again
                                end if;
                            end if;
                        when RESET =>
                            write_spi_state_is  <= "0011";
                            start_transaction   <= '0';
                            set_ip_counter      <= set_ip_counter + 1;
                            if( set_ip_counter = 10) then     
                                ip_config_state     <= RESET;
                                set_ip_counter      <= 0;
                                write_spi_state     <= WRITE_ENABLE;
                            end if;
                    end case;
            when RESET =>
                page_prog_counter   <= 0;
                start_transaction   <= '0';
                spi_ip_config_state_is <= "0100";
                if (transaction_finished = '1') then
                    cmdaddrdata_set     <= x"0000_0000_0000_0000_0000";
                    byte_count_set      <= x"0000_0000";
                    ip_config_state <= IDLE;
                end if;
            when others =>
                spi_ip_config_state_is <= "0101";
                ip_config_state <= RESET;
        end case;
    end if;
end process;

spi_read_write_core_registers: process(clk_50)  -- State machine that handles the signals necessary to write to or read from a core register
    begin
    if rising_edge(clk_50) then
                if (set_default_ip = '1') then
                    myIP_i    <= default_IP;
                    myMAC_i   <= default_MAC;
                    destIP_i  <= default_destIP;

                end if;
            
                case spi_state is           -- State machine that handles the signals necessary to perform a single write to or read to and from a core register in the axi_quad_spi
                    when SETUP =>
                        spi_aresetn         <= '0';
                        if (start_transaction = '1') then
                            transaction_finished    <= '0';
                            spi_state       <= IDLE;
                            spi_counter     <= 0;
                            spi_aresetn     <= '1';
                        end if;
                    when IDLE =>
                        spi_awvalid         <= '0';
                        spi_wvalid          <= '0';
                        spi_bready          <= '0';
                        spi_counter         <= 0;
                        spi_rready          <= '0';
                        spi_state_is        <= "0000";
                        
                        case spi_state_control is       -- State machine that handles the higher level flow (above spi_state) in order to execute a proper transaction via the axi_quad_spi (Nested within spi_state = IDLE)
                            when CLEAR_FIFO =>          -- Clear Rx and Tx FIFO's in axi_quad_spi
                                spi_state_control_is    <= "0000";
                                araddr_set              <= "1100100";               --x"64";
                                awaddr_set              <= "1100000";               --x"60";
                                wdata_set               <= x"00000186";
                                spi_state               <= WAIT_WRITE;
                                spi_state_control       <= WRITE_CMD_ADDR_DATA;
                                byte_transfer_counter   <= to_integer(unsigned(byte_count_set));
                                cmdaddrdata             := to_bitvector(cmdaddrdata_set);
                            when WRITE_CMD_ADDR_DATA => -- Write the command, address, and data into the Tx FIFO in axi_quad_spi
                                spi_state_control_is    <= "0001";
                                araddr_set              <= "1110100";               --x"74";
                                awaddr_set              <= "1101000";               --x"68";                                
                                wdata_set               <= x"000000" & to_stdlogicvector(cmdaddrdata(79 downto 72));
                                byte_transfer_counter   <= byte_transfer_counter - 1;
                                cmdaddrdata             := cmdaddrdata sll 8; 
                                spi_state               <= WAIT_WRITE;
                                if (byte_transfer_counter = 0) then
                                    spi_state_control   <= ASSERT_SS;
                                end if;
                            when ASSERT_SS =>           -- Assert Slave Select by writing x"00" into the x"70" registers in axi_quad_spi
                                spi_state_control_is    <= "0010";
                                araddr_set              <= "1100100";               --x"64"
                                awaddr_set              <= "1110000";               --x"70";
                                wdata_set               <= x"00000000";
                                spi_state               <= WAIT_WRITE;
                                spi_state_control       <= DEASSERT_INHIB;
                            when DEASSERT_INHIB =>      -- Deassert inhibit bit in order to allow the Master (FPGA) to communicate with the Slave (SPI Flash)
                                spi_state_control_is    <= "0011";
                                araddr_set              <= "1100100";               --x"64"
                                awaddr_set              <= "1100000";               --x"60";
                                wdata_set               <= x"00000086";
                                spi_counter             <= 0;
                                spi_state               <= WAIT_WRITE;
                                spi_state_control       <= CLEAR_SS;
                            when CLEAR_SS =>            -- Clear Slave Select by pulling the SS line high after 400 clock cycles (default)
                                spi_state_control_is    <= "0100";
                                araddr_set              <= "1100100";               --x"64"
                                awaddr_set              <= "1110000";               --x"70";
                                spi_counter     <= spi_counter + 1;
                                if (spi_counter > 400) then
                                    wdata_set               <= x"00000001";
                                    spi_counter             <= 0;
                                    spi_state               <= WAIT_WRITE;
                                    spi_state_control       <= ASSERT_INHIB;                                    
                                end if;
                            when ASSERT_INHIB =>        -- Assert inhibit bit in order to inhibit the Master (FPGA) to communicate with the Slave (SPI Flash)
                                spi_state_control_is    <= "0101";
                                araddr_set              <= "1111000";               --x"78"
                                awaddr_set              <= "1100000";               --x"60";
                                wdata_set               <= x"00000186";
                                spi_counter     <= spi_counter + 1;
                                if((cmdaddrdata_set(79 downto 72) = x"20") and (spi_counter = 25_000_000)) then -- Need to wait 0.5 s for successful SUBSECTOR_ERASE operation after SS is pulled high
                                    spi_state               <= WAIT_WRITE;
                                    spi_state_control       <= READ_SPI_DATA;
                                    byte_transfer_counter   <= to_integer(unsigned(byte_count_set)) + 1;
                                    spi_counter             <= 0;
                                elsif ((cmdaddrdata_set(79 downto 72) = x"02") and (spi_counter = 7500))then      -- Need to wait 0.15 ms for successful PAGE_PROGRAM operation after SS is pulled high
                                    spi_state               <= WAIT_WRITE;
                                    spi_state_control       <= READ_SPI_DATA;
                                    byte_transfer_counter   <= to_integer(unsigned(byte_count_set)) + 1;
                                    spi_counter             <= 0;
                                elsif ((cmdaddrdata_set(79 downto 72) /= x"20") and (cmdaddrdata_set(79 downto 72) /= x"02")) then
                                    spi_state               <= WAIT_WRITE;
                                    spi_state_control       <= READ_SPI_DATA;
                                    byte_transfer_counter   <= to_integer(unsigned(byte_count_set)) + 1;
                                    spi_counter             <= 0;
                                end if;
                            when READ_SPI_DATA =>       -- Read SPI data in the Rx FIFO in axi_quad_spi
                                spi_state_control_is    <= "0110";
                                araddr_set              <= "1101100";                       --x"6C";
                                awaddr_set              <= "1111111";                       --x"7F";       --Address does not exist. Just there so core registers are not written too
                                wdata_set               <= x"00000000";                     --Dummy data
                                byte_transfer_counter   <= byte_transfer_counter - 1;       --Read occupancy register
                                spi_state               <= WAIT_READ;
                                if ((ip_config_state = CHECK_IP_SET) and (byte_transfer_counter = 0)) then
                                    ip_set_flag             <= spi_rdata(7 downto 0);
                                end if;
                                
                                if (ip_config_state = SET_IP) then
                                    if (second_transaction = '0') then
                                        if ((byte_transfer_counter >= 8) and (byte_transfer_counter <= 11)) then
                                            myIP_i((byte_transfer_counter-8)*8+7 downto (byte_transfer_counter-8)*8)        <=  spi_rdata(7 downto 0);
                                        elsif ((byte_transfer_counter >= 2) and (byte_transfer_counter <= 7)) then
                                            myMAC_i((byte_transfer_counter-2)*8+7 downto (byte_transfer_counter-2)*8)       <=  spi_rdata(7 downto 0);
                                        elsif ((byte_transfer_counter >= 0) and (byte_transfer_counter <= 1)) then
                                            destIP_i((byte_transfer_counter+2)*8+7 downto (byte_transfer_counter+2)*8)    <=  spi_rdata(7 downto 0);
                                        end if;
                                    elsif (second_transaction = '1') then
                                        if ((byte_transfer_counter >= 0) and (byte_transfer_counter <= 1)) then
                                            destIP_i((byte_transfer_counter)*8+7 downto (byte_transfer_counter)*8)        <=  spi_rdata(7 downto 0);
                                        end if;
                                    end if;
                                end if;
                                
                                if (byte_transfer_counter = 0) then
                                    spi_state_control   <= RESET;
                                end if;
                            when RESET =>
                                spi_state_control_is    <= "0111";
                                transaction_finished <= '1';
                                spi_state       <= SETUP;
                                spi_state_control       <= CLEAR_FIFO;
                                --end if;  
                            when others =>
                                araddr_set              <= "0000000";
                                awaddr_set              <= "0000000";
                                wdata_set               <= x"00000000";
                                transaction_finished    <= '1';
                                spi_state_control_is    <= "1111"; --Error State
                                spi_state <= SETUP;
                                spi_state_control       <= CLEAR_FIFO;
                        end case;
                    when WAIT_WRITE =>      -- State for writing to the axi_quad_spi register
                        spi_state_is    <= "0001";
                        spi_counter     <= spi_counter + 1;
                        spi_wstrb       <= "0000";
                        if spi_counter = 5 then
                            spi_state   <= WRITE;
                            spi_counter <= 0;
                        end if;
                     when WRITE =>          -- State for writing to the axi_quad_spi register
                        spi_state_is    <= "0010";
                        spi_awaddr      <= awaddr_set;
                        spi_wdata       <= wdata_set;
                        spi_awvalid     <= '1';
                        spi_wvalid      <= '1';
                        spi_wstrb       <= "1111";
                        spi_bready      <= '1';
                        if spi_awready  = '1' or spi_wready = '1' then
                            spi_state   <= FINISH_WRITE;
                            spi_wstrb   <= "0000";
                            spi_awaddr      <= "0000000";
                            spi_wdata       <= x"00000000";
                            spi_awvalid <= '0';
                            spi_wvalid  <= '0';
                        end if;
                    when  FINISH_WRITE =>   -- State for writing to the axi_quad_spi register
                        spi_state_is    <= "0011";
                        spi_awaddr      <= "0000000";
                        spi_wdata       <= x"00000000";                
                        spi_awvalid     <= '0';
                        spi_wvalid      <= '0';
                        if spi_bvalid  = '1' then
                            spi_bready  <= '0';
                            spi_state   <= IDLE;
                        end if;         
                    when WAIT_READ =>       -- State for reading from the axi_quad_spi register
                        spi_state_is    <= "0100";
                        spi_counter     <= spi_counter + 1;
                        if spi_counter = 10 then
                            spi_state   <= READ;
                            spi_counter <= 0;
                        end if;
                    when READ =>            -- State for reading from the axi_quad_spi register
                        spi_state_is    <= "0101";
                        spi_counter     <= spi_counter + 1;
                        spi_araddr  <= araddr_set;
                        spi_arvalid <= '1';
                        spi_rready  <= '1';
                        if spi_counter = 10 then
                            spi_state   <= FINISH_READ;
                            spi_counter <= 0;
                        end if; 
                    when FINISH_READ =>     -- State for reading from the axi_quad_spi register
                        spi_state_is    <= "0110";
                        if spi_arready = '1' then
                            spi_araddr  <= "0000000";
                            spi_arvalid <= '0';
                            spi_arvalid <= '0';
                            spi_counter <= 0;
                        end if;
                        spi_state   <= IDLE;
                end case;
    end if;
end process;   

--spi_cnt <=     std_logic_vector(to_unsigned(spi_counter, spi_cnt'length));
spi_cnt <=     std_logic_vector(to_unsigned(spi_counter, 32));

---------------------------------------------------------
--------- Clock Domain Crossing Sync Block --------------
---------------------------------------------------------

-- sync output signals to 125 Mhz clock
CDCC_50to125: CDCC
    generic map(NUMBER_OF_BITS => 113)
    port map(
        clk_src                 => clk_50,
        clk_dst                 => clk_125,

        data_in(112)            => flash_busy_i,
        data_in(111 downto 80)  => myIP_i,
        data_in(79 downto 32)   => myMAC_i,
        data_in(31 downto 0)    => destIP_i,

        data_out_s(112)            => flash_busy,
        data_out_s(111 downto 80)  => myIP,
        data_out_s(79 downto 32)   => myMAC,
        data_out_s(31 downto 0)    => destIP
    );
    
-- sync input signals to 50 Mhz clock  
CDCC_125to50: CDCC
    generic map(NUMBER_OF_BITS => 113)
    port map(
        clk_src                 => clk_125,
        clk_dst                 => clk_50,

        data_in(112)            => newIP_start,
        data_in(111 downto 80)  => myIP_set,
        data_in(79 downto 32)   => myMAC_set,
        data_in(31 downto 0)    => destIP_set,

        data_out_s(112)            => newIP_start_s50,
        data_out_s(111 downto 80)  => myIP_set_s50,
        data_out_s(79 downto 32)   => myMAC_set_s50,
        data_out_s(31 downto 0)    => destIP_set_s50
    );
---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------


--ila_top: ila_spi_flash
--    port map (
--        clk     => clk_50,
--        probe0  => read_out
--    );

--    read_out(31 downto 0)       <= spi_rdata;
--    read_out(38 downto 32)      <= (others => '0');
--    read_out(40 downto 39)      <= spi_rresp;
--    read_out(41)                <= spi_awready;
--    read_out(43 downto 42)      <= spi_bresp;
--    read_out(44)                <= spi_bvalid;    
--    read_out(45)                <= spi_awvalid; 
--    read_out(46)                <= spi_wvalid; 
--    read_out(47)                <= spi_aresetn;
--    read_out(51 downto 48)      <= spi_wstrb;
--    read_out(83 downto 52)      <= spi_wdata;
--    read_out(90 downto 84)      <= spi_awaddr;   
--    read_out(91)                <= spi_bready;
--    read_out(92)                <= spi_wready;
--    read_out(93)                <= spi_arvalid;
--    read_out(94)                <= spi_rready;
--    read_out(98 downto 95)      <= spi_state_is;   
--    read_out(99)                <= spi_rvalid;
--    read_out(100)               <= spi_arready;
--    read_out(107 downto 101)    <= spi_araddr;
--    read_out(108)               <= '0';
--    read_out(109)               <= '0';
--    read_out(110)               <= '0';
--    read_out(114 downto 111)    <= spi_state_control_is;
--    read_out(115)               <= transaction_finished;
--    read_out(119 downto 116)    <= spi_ip_config_state_is;
--    read_out(127 downto 120)    <= ip_set_flag;
--    read_out(128)               <= newip_start;
--    read_out(208 downto 129)    <= cmdaddrdata_set;
--    read_out(212 downto 209)    <= write_spi_state_is;
--    read_out(244 downto 213)     <= spi_cnt;
     
--vio_top: vio_0
--    port map (
--        clk     => clk_200,
--        probe_out0  => start_vio,
--        probe_out1  => system_start_vio,
--        probe_out2  => cmdaddrdata_vio,
--        probe_out3  => byte_count_vio,
--        probe_out4  => new_ip_vio,
--        probe_out5  => set_ip_vio
--    );

end Behavioral;
