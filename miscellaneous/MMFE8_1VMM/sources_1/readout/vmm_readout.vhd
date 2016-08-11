----------------------------------------------------------------------------------
-- Company: NTU ATHNENS - BNL
-- Engineer: Paris Moschovakos
-- 
-- Create Date: 18.04.2016 13:00:21
-- Design Name: 
-- Module Name: vmm_readout.vhd - Behavioral
-- Project Name: MMFE8 
-- Target Devices: Arix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 1.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.all;
library UNISIM;
use UNISIM.vcomponents.all;

entity vmm_readout is
    Port (
    	   vmm_data0 				: in std_logic;      -- Single-ended data0 from VMM
           vmm_data1 				: in std_logic;      -- Single-ended data1 from VMM
           clk_10_phase45			: in std_logic;      -- Used to clock checking for data process
           clk_50                   : in std_logic;      -- Used to clock word readout process
           clk_200                  : in std_logic;      -- Used for fast ILA signal sampling

           daq_enable               : in std_logic;

           trigger_pulse     		: in std_logic;      -- To be used trigger
           ethernet_fifo_wr_en		: out std_logic;     -- To be used to for ethernet to software readout
           latency                  : in std_logic_vector(15 downto 0);

           vmm_ckdt 				: out std_logic;     -- Strobe to VMM CKDT
           vmm_cktk             	: out std_logic;     -- Strobe to VMM CKTK

           acq_rst_from_data0		: out std_logic;     -- Send a soft reset when done

           vmm_data_buf				: buffer std_logic_vector(37 downto 0);

           vmm_wen                  : out std_logic;
           vmm_ena                  : out std_logic;

           vmmWordReady             : out std_logic;
           vmmWord                  : out std_logic_vector(63 downto 0);
           vmmEventDone             : out std_logic
           );
end vmm_readout;

architecture Behavioral of vmm_readout is

    -- readoutControlProc
	signal reading_out_word		: std_logic := '0';

    -- tokenProc
	signal dt_state				: std_logic_vector( 3 DOWNTO 0 )	:= ( others => '0' );
    signal vmm_wen_1_i          : std_logic := '0';
    signal vmm_ena_1_i          : std_logic := '0';
    signal vmm_cktk_1_i         : std_logic := '0';
    signal ethernet_fifo_wr_en_i: std_logic := '0';                                         -- Not used
--	signal trig_latency_counter	: std_logic_vector( 15 DOWNTO 0 )	:= ( others => '0' );
--  signal trig_latency         : std_logic_vector( 15 DOWNTO 0 )   := x"008C";             -- x"008C";  700ns @200MHz (User defined)
    signal latency_i            : integer := 7;
    signal latencyCnt           : integer := 0;
    signal NoFlg_counter		: integer	:= 0;                                           -- Counter of CKTKs
    signal NoFlg                : integer   := 2;                                           -- How many (#+1) CKTKs before soft reset (User defined)
    signal vmmEventDone_i       : std_logic := '0';
    signal trigger_pulse_i      : std_logic := '0';
    signal hitsLen_cnt          : integer := 0;
    signal hitsLenMax           : integer := 150;       

    -- readoutProc
    signal dt_done              : std_logic := '1';
	signal vmm_data_buf_i 		: std_logic_vector( 37 DOWNTO 0 ) 	:= ( others => '0' );
	signal dt_cntr_intg 		: integer := 0;
    signal dt_cntr_intg0        : integer := 0;
    signal dt_cntr_intg1        : integer := 0;
    signal vmm_ckdt_1_i         : std_logic;
    signal dataBitRead          : integer := 0;

    signal vmmWordReady_i       : std_logic := '0';
    signal vmmWord_i            : std_logic_vector(63 DOWNTO 0);

    -- Internal signal direct assign from ports
	signal vmm_data0_i          : std_logic := '0';
    signal vmm_data1_i          : std_logic := '0';
    signal daq_enable_i         : std_logic := '0';

begin

readoutControlProc: process(clk_200, daq_enable_i, dt_done, vmm_data0_i)
begin
    if (dt_done = '1') then
        reading_out_word    <= '0';     -- readoutProc done, stop it
    end if;
    if (vmm_data0_i = '1') then
        reading_out_word    <= '1';     -- new data, trigger readoutProc
    end if;
end process;

-- by using this clock the CKTK strobe has f=5MHz (T=200ns, D=50%, phase=45deg)
tokenProc: process(clk_10_phase45, daq_enable_i, dt_done, vmm_data0_i, trigger_pulse)
begin
    if (rising_edge(clk_10_phase45)) then
        if (daq_enable_i = '1') then

                case dt_state is

				    when x"0" =>
				        vmmEventDone_i          <= '0';
				        vmm_wen_1_i             <= '0';
                        vmm_ena_1_i             <= '1';
                        latencyCnt              <= 0;

                        if (trigger_pulse_i = '1') then
                            vmm_cktk_1_i            <= '0';
                            ethernet_fifo_wr_en_i   <= '0';
                            dt_state                <= x"1";
                        end if;

				    when x"1" =>
                        if (latencyCnt = latency_i) then
                            dt_state                <= x"2";
                        else
                            latencyCnt    <= latencyCnt + 1;
                        end if;

                    when x"2" =>
                        vmm_cktk_1_i    <= '0';
                        dt_state        <= x"3";

				    when x"3" =>
				        if (reading_out_word /= '1') then
				            vmm_cktk_1_i    <= '1';
				            hitsLen_cnt     <= hitsLen_cnt + 1;
				            dt_state        <= x"4";
				        else
				            NoFlg_counter   <= 0;
				            dt_state        <= x"6";
				        end if;

                    when x"4" =>
                        vmm_cktk_1_i    <= '0';
                        dt_state        <= x"5";

    				when x"5" =>
                        if (vmm_data0_i = '1') then             -- Data presence: wait to read out
                            NoFlg_counter   <= 0;
                            dt_state        <= x"6";
                        else
						    if (NoFlg_counter = NoFlg) then
							    dt_state    <= x"7";	        -- If NoFlg = 4 : time to soft reset and transmit data
						    else
                                dt_state    <= x"3";			-- Send new CKTK strobe
						    end if;
						    NoFlg_counter <= NoFlg_counter  + 1;
					    end if;

                	when x"6" =>                                -- Wait until word readout is done
                		if (dt_done = '1') then
                		  if hitsLen_cnt >= hitsLenMax then       -- Maximum UDP packet length reached 
                            dt_state             <= x"7";
                          else
                            dt_state            <= x"3";        -- Issue new CKTK strobe
                          end if;
                		end if;

                    when x"7" =>                                -- Start the soft reset sequence, there is still a chance
                        if (reading_out_word /= '1') then       -- of getting data at this point so check that before soft reset
                            vmm_wen_1_i             <= '0';
                            vmm_ena_1_i             <= '0';
                            dt_state                <= x"8";
                        else
				            NoFlg_counter   <= 0;
                            dt_state        <= x"6";
                        end if;

				    when x"8" =>
					    vmm_wen_1_i             <= '1';
					    vmm_ena_1_i             <= '0';
					    hitsLen_cnt             <= 0;
					    dt_state                <= x"9";

				    when others =>
				        vmmEventDone_i          <= '1';
                        vmm_wen_1_i             <= '0';
                        vmm_ena_1_i             <= '0';
                        NoFlg_counter           <= 0;
                        ethernet_fifo_wr_en_i   <= '1';
				        dt_state                <= x"0";
                end case;
        else
            vmm_ena_1_i   <= '0';
		    vmm_wen_1_i   <= '0';
        end if;
    end if;
end process;

-- by using this clock the CKDT strobe has f=25MHz (T=40ns, D=50%, phase=0deg) to click in data0 and data1
readoutProc: process(clk_50, reading_out_word)
begin
    if rising_edge(clk_50) then
        if (reading_out_word = '1') then

            case dt_cntr_intg is

                when 0 =>                               -- Initiate values
                    dt_done       <= '0';
                	vmm_data_buf  <= (others => '0');
                    dt_cntr_intg  <= dt_cntr_intg + 1;
                    dt_cntr_intg0 <= 0;
                    dt_cntr_intg1 <= 1;
                	vmm_ckdt_1_i  <= '0';               -- Go for the first ckdt

                when 1 =>
                    vmm_ckdt_1_i   <= '1';
                    dt_cntr_intg   <= dt_cntr_intg + 1;

                when 2 =>                               --  19 ckdt and collect data
                    vmm_ckdt_1_i   <= '0';
                    if (dataBitRead /= 19) then
                        vmm_data_buf(dt_cntr_intg0) <= vmm_data0;
                        vmm_data_buf(dt_cntr_intg1) <= vmm_data1;
                        vmm_data_buf_i              <= vmm_data_buf;
                        dt_cntr_intg                <= 1;
                        dataBitRead                 <= dataBitRead + 1;
                    else
                        vmm_data_buf(dt_cntr_intg0) <= vmm_data0;
                        vmm_data_buf(dt_cntr_intg1) <= vmm_data1;
                        vmm_data_buf_i              <= vmm_data_buf;
                        dataBitRead                 <= 1;
                        dt_cntr_intg                <= 3;
                    end if;
                    dt_cntr_intg0               <= dt_cntr_intg0 + 2;
                    dt_cntr_intg1               <= dt_cntr_intg1 + 2;

                when 3 =>
                    vmmWordReady_i    <= '0';
                    -- daqFIFO_din_i     <= b"000" & b"111" & vmm_data_buf(25 downto 0) & b"0000" & b"1010101010101010" & vmm_data_buf(37 downto 26);
                    vmmWord_i         <= b"00" & vmm_data_buf(25 downto 18) & vmm_data_buf(37 downto 26) & vmm_data_buf(17 downto 8) & b"000000000000000000000000" & vmm_data_buf(7 downto 2) & vmm_data_buf(1) & vmm_data_buf(0);
                                                 --         TDO             &           Gray             &           PDO             &                             &          Address         &    Threshold    &       Flag;
                    dt_cntr_intg      <= dt_cntr_intg + 1;

                when 4 =>
                    vmmWordReady_i    <= '1';
                    dt_cntr_intg      <= dt_cntr_intg + 1;

                when others =>                  -- Word read
                    dt_cntr_intg0   <= 0;
                    dt_cntr_intg1   <= 1;
                    dt_cntr_intg    <= 0;
                    vmmWordReady_i  <= '0';
                    dt_done         <= '1';
            end case;
        else
            dt_cntr_intg0 <= 0;
            dt_cntr_intg1 <= 1;
            dt_cntr_intg  <= 0;
        end if;
    end if;
end process;

    vmm_cktk            <= vmm_cktk_1_i;            -- Used
    vmm_ckdt            <= vmm_ckdt_1_i;            -- Used
    vmm_wen             <= vmm_wen_1_i;             -- Used
    vmm_ena             <= vmm_ena_1_i;             -- Used
    daq_enable_i        <= daq_enable;              -- Used
    vmm_data0_i         <= vmm_data0;               -- Used
    vmm_data1_i         <= vmm_data1;               -- Used
    vmmWordReady        <= vmmWordReady_i;          -- Used
    vmmWord             <= vmmWord_i;               -- Used
    vmmEventDone        <= vmmEventDone_i;          -- Used
    trigger_pulse_i     <= trigger_pulse;           -- Used
    latency_i           <= to_integer(unsigned(latency));

end behavioral;