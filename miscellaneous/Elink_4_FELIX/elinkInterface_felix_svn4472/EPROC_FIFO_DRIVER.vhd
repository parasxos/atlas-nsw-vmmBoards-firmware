----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    07/13/2014  
--! Module Name:    EPROC_FIFO_DRIVER
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.all;
use work.centralRouter_package.all;

--! a driver for EPROC FIFO, manages block header and sub-chunk trailer
entity EPROC_FIFO_DRIVER is
generic (
    GBTid               : integer := 0;
    egroupID            : integer := 0;
    epathID             : integer := 0;
    toHostTimeoutBitn   : integer := 8
    );
port ( 
    clk40       : in  std_logic;
    clk160      : in  std_logic;
    rst         : in  std_logic;
    ----------
    encoding    : in  std_logic_vector (1 downto 0);
    maxCLEN     : in  std_logic_vector (2 downto 0); 
    ---------
    DIN         : in  std_logic_vector (9 downto 0);
    DIN_RDY     : in  std_logic;
    ----------
    xoff        : in  std_logic;
    timeCntIn   : in std_logic_vector ((toHostTimeoutBitn-1) downto 0);
    TimeoutEnaIn: in std_logic;
    ----------
    wordOUT     : out  std_logic_vector (15 downto 0);
    wordOUT_RDY : out  std_logic
    );
end EPROC_FIFO_DRIVER;

architecture Behavioral of EPROC_FIFO_DRIVER is

--
signal DIN_r : std_logic_vector (7 downto 0) := (others => '0');
signal DIN_CODE_r : std_logic_vector (1 downto 0) := (others => '0');

signal DIN_s : std_logic_vector (9 downto 0);
signal DIN_RDY_r : std_logic := '0';
---
signal  receiving_state, data_shift_trig, trailer_shift_trig, trailer_shift_trig_s, 
        EOC_error, SOC_error, rst_clen_counter, data16bit_rdy, 
        data16bit_rdy_shifted, truncating_state, truncation_trailer_sent : std_logic := '0';

signal send_trailer_trig,data_shift_trig_s : std_logic;

signal DIN_prev_is_zeroByte, DIN_is_zeroByte : std_logic := '0';
signal direct_data_mode, direct_data_boundary_detected : std_logic;
      
signal trailer_trunc_bit, trailer_cerr_bit, first_subchunk, first_subchunk_on : std_logic := '0';
signal trailer_mod_bits  : std_logic_vector (1 downto 0);
signal trailer_type_bits : std_logic_vector (2 downto 0) := (others => '0');

signal EOB_MARK, truncateDataFlag, flushed, flush_trig, data_rdy : std_logic;
signal trailer_shift_trigs, trailer_shift_trig0, header_shift_trigs : std_logic;
signal trailer_shift_trig1 : std_logic := '0';

signal data16bit_rdy_code : std_logic_vector (2 downto 0);
signal trailer, trailer0, trailer1, header, data : std_logic_vector (15 downto 0);
signal wordOUT_s : std_logic_vector (15 downto 0) := (others => '0');

signal pathENA, DIN_RDY_s : std_logic := '0';
signal pathENAtrig, blockCountRdy,timeout_trailer_send,xoff_s : std_logic;
--
signal timeCnt_lastClk : std_logic_vector ((toHostTimeoutBitn-1) downto 0);
signal do_transmit_timeout_trailers,timout_ena,truncation_from_timeout,truncating_state_clk40 : std_logic := '0';
signal zero_trailer_send_pulse_count : std_logic_vector (2 downto 0) := (others=>'0');
signal zero_trailer_send_pulse,truncation_from_timeout_trig,timeout_event_clk0,timeout_event_clk1,data_on_input,data_on_input_clk40 : std_logic;
--
constant zero_data_trailer  : std_logic_vector(15 downto 0) := "0000000000000000"; -- "000"=null chunk, "00"=no truncation & no cerr, '0', 10 bit length is zero;
constant timeout_trailer    : std_logic_vector(15 downto 0) := "1010000000000000"; -- "101"=timeout, "00"=no truncation & no cerr, '0', 10 bit length is zero;
signal work_state,sop_in : std_logic := '0';
--

begin


------------------------------------------------------------
-- time out counter for triggering the send-out of an 
-- incomplete block
------------------------------------------------------------
--data_on_input <= '1' when (DIN_RDY = '1' and DIN(9 downto 8) /= "11" and truncating_state_clk40 = '0') else '0';
--
process(clk160,rst) 
begin
    if rst = '1' then
        data_on_input <= '0';
    elsif rising_edge (clk160) then
        if DIN_RDY = '1' then           
            if DIN(9 downto 8) /= "11" then -- data
                data_on_input   <= not truncating_state_clk40; 
                if DIN(9 downto 8) = "10" then -- sop
                    sop_in          <= '1';
                else
                    sop_in          <= '0'; 
                end if;
            else
                data_on_input   <= '0';
                sop_in          <= '0';
            end if;
        else
            data_on_input <= '0';
        end if;
    end if;
end process;
--
tcdc: entity work.pulse_pdxx_pwxx generic map(pd=>0,pw=>5) port map(clk160, data_on_input, data_on_input_clk40);
--
process(clk40,rst) 
begin
    if rst = '1' then
        timeCnt_lastClk         <= (others=>'1');
        truncating_state_clk40  <= '0';
        work_state              <= '0';
    elsif rising_edge (clk40) then
        if TimeoutEnaIn = '0' then
            timeCnt_lastClk         <= (others=>'1');
            truncating_state_clk40  <= '0';
            work_state              <= '0';
        else     
            truncating_state_clk40 <= truncating_state;  -- cdc
            --
            if timeCntIn(0) = '1' then
                work_state <= TimeoutEnaIn;
            end if;
            --
            if (data_on_input_clk40 = '1' or timout_ena = '0') and work_state = '1' then 
                timeCnt_lastClk <= timeCntIn;   -- [valid data] or [disabled timeout] re-set counter cycle start point            
            end if;
        end if;
    end if;
end process;
--
--
process(clk40,rst) 
begin
    if rst = '1' then
        timeout_event_clk0  <= '0';
    elsif rising_edge (clk40) then        --
        if timeCnt_lastClk = timeCntIn then 
            timeout_event_clk0 <= TimeoutEnaIn;
        else
            timeout_event_clk0 <= '0';
        end if;
        --
        timeout_event_clk1 <= timeout_event_clk0 and (not sop_in);
        --
    end if;
end process;
--
--t0: entity work.pulse_pdxx_pwxx generic map(pd=>1,pw=>1) port map(clk40, timeout_event_clk0, timeout_event_clk1);
--
truncation_from_timeout <= timeout_event_clk0 and (not sop_in);
p0: entity work.pulse_pdxx_pwxx generic map(pd=>0,pw=>1) port map(clk160, truncation_from_timeout, truncation_from_timeout_trig); 
--
--
process(clk160,rst) 
begin
    if rst = '1' then
        do_transmit_timeout_trailers <= '0';
    elsif rising_edge (clk160) then
        if timeout_event_clk1 = '1' then --timeCnt_lastClk = timeCntIn and timout_ena = '1' and TimeoutEnaIn = '1' then
            do_transmit_timeout_trailers <= TimeoutEnaIn; 
        elsif (data_on_input = '1' or EOB_MARK = '1') then
            do_transmit_timeout_trailers <= '0';
        end if;
    end if;
end process;
--
--
p1: entity work.pulse_pdxx_pwxx generic map(pd=>0,pw=>1) port map(clk160, do_transmit_timeout_trailers, timeout_trailer_send); 
xoff_s <= xoff or truncation_from_timeout;
--
process(clk160,rst) 
begin
    if rst = '1' then
        timout_ena <= '0';
    elsif rising_edge (clk160) then
        if do_transmit_timeout_trailers = '1' then
            timout_ena <= '0';
        elsif receiving_state = '1' then
            timout_ena <= '1';
        end if;
    end if;
end process;
--


---------------------------------------------
-- CLK1: register the input
---------------------------------------------
process(clk160)
begin
    if rising_edge (clk160) then
        if DIN_RDY = '1' then
            DIN_s       <= DIN;
            DIN_RDY_s   <= '1';
        else
            DIN_RDY_s   <= '0';
        end if;
	end if;
end process;
-- for the direct data case:
-- register the input byte comparator result 
-- for the direct data case to detect zeros as data delimeter
direct_data_mode <= not(encoding(1) or encoding(0));
--
process(clk160)
begin
    if rising_edge (clk160) then
        if DIN_RDY = '1' then
            if DIN(7 downto 0) = "00000000" then
                DIN_is_zeroByte <= '1';
            else
                DIN_is_zeroByte <= '0';
            end if;
        end if;
    end if;
end process;
-- pipeline the input byte comparator result 
process(clk160)
begin
    if rising_edge (clk160) then
        if DIN_RDY = '1' then
            DIN_prev_is_zeroByte <= DIN_is_zeroByte;
        end if;
    end if;
end process;
--
direct_data_boundary_detected <= '1' when (DIN_is_zeroByte = '1' and DIN_prev_is_zeroByte = '1') else '0';
--

---------------------------------------------
-- initial enabling of the path: 
-- enabled after reset on the first 
-- valid input symbol (must be comma!)
-- the first symbol is then lost! as we are sending
-- a bloack header when it is detected
---------------------------------------------
process(clk160)
begin
    if rising_edge (clk160) then
        if rst = '1' then
            pathENA <= '0';
        elsif DIN_RDY_s = '1' then -- 
            pathENA <= '1';
        end if;
    end if;
end process;
-- trigger to restart the block counter
pathENA1clk: entity work.pulse_pdxx_pwxx GENERIC MAP(pd=>0,pw=>1) PORT MAP(clk160, pathENA, pathENAtrig); 


---------------------------------------------
-- CLK2: 
---------------------------------------------
--
DIN_RDY_r   <= (DIN_RDY_s and (not truncateDataFlag)) or truncation_from_timeout_trig; --and pathENA; --blockCountRdy;
DIN_r       <= DIN_s(7 downto 0);
--
process(direct_data_mode, direct_data_boundary_detected, DIN_s(9 downto 8), truncateDataFlag)
begin
    if direct_data_mode = '1' then
        DIN_CODE_r  <= direct_data_boundary_detected & '0'; -- "10"=soc, "00"=data
    else
        if truncateDataFlag = '0' then
            DIN_CODE_r <= DIN_s(9 downto 8);
        else
            DIN_CODE_r <= "00";
        end if;
    end if;       
end process;
--


-----------------------------------------------------------
-- clock 3
--        case of the input word code:
-- "00" => data, "01" => EOC, "10" => SOC, "11" => COMMA
-----------------------------------------------------------
process(clk160, rst)
begin
    if rst = '1' then
        --
        receiving_state     <= '0';
        trailer_trunc_bit   <= '1';
        trailer_cerr_bit    <= '1';
        trailer_type_bits   <= "000"; -- not a legal code
        data_shift_trig     <= '0';
        trailer_shift_trig  <= '0';
        EOC_error           <= '0';
        SOC_error           <= '0';
        rst_clen_counter    <= '0';
        first_subchunk_on   <= '0';
        truncating_state    <= '0';
        --
    elsif rising_edge (clk160) then
        if DIN_RDY_r = '1' then
            case (DIN_CODE_r) is 
                when "00" =>  -- data
                    --
                    data_shift_trig     <= (receiving_state) and (not truncateDataFlag); -- shift-in data if in the receiving state
                    -- if block filled up after that, chunk trailer and block header will be shifted-in as well
                    trailer_trunc_bit   <= truncateDataFlag;  -- truncation mark in case of CLEN_error
                    trailer_cerr_bit    <= truncateDataFlag;  -- CLEN_error is '1' in case of receiving data after CLEN is reached
                    trailer_type_bits   <= (not (truncateDataFlag or first_subchunk)) & truncateDataFlag & first_subchunk;  -- 001_first, 011_whole, 100_middle, 010_last
                    trailer_shift_trig  <= truncateDataFlag and receiving_state; -- send a trailer once when CLEN value is reached (SOC will rst the chunk-len-counter)
                    receiving_state     <= receiving_state and (not truncateDataFlag); -- switching off receiving in case of truncateDataFlag, waiting for SOC now
                    EOC_error           <= '0';
                    SOC_error           <= not receiving_state; -- if current state is not 'receiving', flag an error, do nothing
                    rst_clen_counter    <= '0';
                    first_subchunk_on   <= '0';
                    truncating_state    <= truncateDataFlag and receiving_state; -- truncation trailer is sent in this 'case' (once)
                    --
                when "01" =>  -- EOC
                    --
                    trailer_shift_trig  <= receiving_state or do_transmit_timeout_trailers; -- if '1' => correct state, shift-in a trailer, if not, do nothing
                    -- sending a trailer is including padding with zeros ('flush') in case of even word count (should be flagged somewhere...)
                    trailer_trunc_bit   <= '0';  -- no truncation, proper ending
                    trailer_cerr_bit    <= '0';
                    trailer_type_bits   <= do_transmit_timeout_trailers & '1' & first_subchunk; -- 'last sub-chunk' or 'whole sub-chunk' mark
                    EOC_error           <= not receiving_state; -- if current state was not 'receiving', flag an error, do nothing
                    receiving_state     <= '0';                  
                    --
                    truncating_state    <= truncating_state;
                    rst_clen_counter    <= '0';
                    first_subchunk_on   <= '0';
                    data_shift_trig     <= '0';
                    SOC_error           <= '0';
                    --
                when "10" =>  -- SOC
                    --
                    trailer_shift_trig  <= (receiving_state and (not direct_data_mode)) or (truncateDataFlag and (not truncation_trailer_sent)); -- if '1' => incorrect state, shift-in a trailer to finish the unfinished chunk
                     -- sending a trailer is including padding with zeros ('flush') in case of even word count (should be flagged somewhere...)
                    trailer_trunc_bit   <= '1';  -- truncation mark in case of sending a trailer (this is when EOC was not received)
                    trailer_cerr_bit    <= '1';
                    trailer_type_bits   <= "01" & (first_subchunk or truncateDataFlag); -- 'last sub-chunk' or 'whole sub-chunk' mark
                    SOC_error           <= receiving_state; -- if current state was already 'receiving', flag an error
                    receiving_state     <= not truncateDataFlag; --'1';
                    rst_clen_counter    <= '1';
                    first_subchunk_on   <= '1';
                    truncating_state    <= truncateDataFlag and (not truncation_trailer_sent); -- truncation trailer is sent in this 'case' (once)
                    --
                    data_shift_trig     <= '0';
                    EOC_error           <= '0';
                    --
                when "11" =>  -- COMMA
                    --
                    -- do nothing
                    receiving_state     <= receiving_state;
                    truncating_state    <= truncating_state;
                    trailer_trunc_bit   <= '0'; 
                    trailer_cerr_bit    <= '0';
                    trailer_type_bits   <= "000"; 
                    data_shift_trig     <= '0';
                    trailer_shift_trig  <= '0';
                    EOC_error           <= '0';
                    SOC_error           <= '0';
                    rst_clen_counter    <= '0';
                    first_subchunk_on   <= '0';
                    --
                when others =>
            end case;
        else
            receiving_state     <= receiving_state;
            trailer_trunc_bit   <= trailer_trunc_bit;
            trailer_cerr_bit    <= trailer_cerr_bit;
            trailer_type_bits   <= trailer_type_bits; --"000";
            truncating_state    <= truncating_state;
            data_shift_trig     <= '0';
            trailer_shift_trig  <= '0';
            EOC_error           <= '0';
            SOC_error           <= '0';
            rst_clen_counter    <= '0';
            first_subchunk_on   <= '0';
        end if;
    end if;
end process;

-----------------------------------------------------------
-- truncation trailer should be only sent once (the first one)
-----------------------------------------------------------
process(clk160)
begin
    if rising_edge (clk160) then 
        if truncateDataFlag = '0' then
            truncation_trailer_sent <= '0';
        else -- truncateDataFlag = '1':
            if trailer_shift_trig = '1' then
                truncation_trailer_sent <= '1'; -- latch, send only one truncation trailer
            end if;
        end if;
    end if;
end process;
--
-----------------------------------------------------------
-- clock3, writing to the shift register
--        data8bit ready pulse
-----------------------------------------------------------
process(clk160)
begin
    if rising_edge (clk160) then -- first, try to flush the shift register        
        trailer_shift_trig_s <= trailer_shift_trig and (not EOB_MARK); -- this trailer is a result of {eoc} or {soc without eoc} or {max clen violation}
    end if;
end process;
--
send_trailer_trig   <= trailer_shift_trig_s or EOB_MARK; -- or truncation_from_timeout_trig;
data_shift_trig_s   <= data_shift_trig;
flush_trig          <= trailer_shift_trig;-- and (not truncateDataFlag); -- no need for flush in truncation case
--
DATA_shift_r: entity work.reg8to16bit -- only for data or 'flush' padding
PORT MAP(
    rst         => rst,
    clk         => clk160,
    flush       => flush_trig, --trailer_shift_trig,
    din         => DIN_r,
    din_rdy     => data_shift_trig_s,
    -----
    flushed     => flushed,
    dout        => data,
    dout_rdy    => data_rdy
    );

----------------------------------------------------------- 
-- clock  
--  BLOCK_WORD_COUNTER
-----------------------------------------------------------
BLOCK_WORD_COUNTER_inst: entity work.BLOCK_WORD_COUNTER 
generic map (GBTid=>GBTid, egroupID=>egroupID, epathID=>epathID)
port map (
	CLK                    => clk160,
	RESET                  => rst, 
	RESTART                => pathENAtrig,
	BW_RDY                 => data16bit_rdy, -- counts everything that is written to EPROC FIFO
	EOB_MARK               => EOB_MARK, -- End-Of-Block: 'send the chunk trailer' trigger
	BLOCK_HEADER_OUT       => header,
	BLOCK_HEADER_OUT_RDY   => header_shift_trigs,
	BLOCK_COUNT_RDY        => blockCountRdy
    );
--
process(clk160)
begin
    if rising_edge (clk160) then 
        if first_subchunk_on = '1' or rst = '1' then
            first_subchunk <= '1';
        elsif EOB_MARK = '1' then 
            first_subchunk <= '0';
        end if;
    end if;
end process;

-----------------------------------------------------------
-- Sub-Chunk Data manager
-- sends a trailer in 2 clocks (current clock and the next)
-----------------------------------------------------------
--
trailer_mod_bits <= trailer_trunc_bit & trailer_cerr_bit;
--
SCDataMANAGER_inst: entity work.SCDataMANAGER 
PORT MAP(
    CLK             => clk160,
    rst             => rst,
    xoff            => xoff_s,
    maxCLEN         => maxCLEN,
    rstCLENcount    => rst_clen_counter,
    truncateCdata   => truncateDataFlag,    -- out, next data will be truncated, a trailer will be sent instead
    trailerMOD      => trailer_mod_bits,    -- in, keeps its value till the next DIN_RDY_s
    trailerTYPE     => trailer_type_bits,   -- in, keeps its value till the next DIN_RDY_s 
    trailerRSRVbit  => xoff_s,
    -------
    trailerSENDtrig => send_trailer_trig,
    dataCNTena      => data_shift_trig_s, -- counts data Bytes (not 16-bit words)data_rdy, -- counts only data (or 'flush' padding), no header, no trailer
    -------
    trailerOUT      => trailer0,
    trailerOUTrdy   => trailer_shift_trig0
);
--

--
process(clk160)
begin
    if rising_edge (clk160) then 
        trailer_shift_trig1 <= flushed;
        trailer1            <= trailer0;
    end if;
end process;
--
trailer_shift_trigs <= (trailer_shift_trig0 and (not flushed)) or trailer_shift_trig1;
--
process(trailer_shift_trig1, trailer1, trailer0)
begin
    if trailer_shift_trig1 = '1' then 
        trailer <= trailer1;
    else
        trailer <= trailer0;
    end if;
end process;

-----------------------------------------------------------
-- 16 bit output MUX, goes to a EPROC FIFO
-----------------------------------------------------------
--process(clk160)
--begin
--    if clk160'event and clk160 = '0' then 
--        data16bit_rdy_shifted <= data16bit_rdy;
--    end if;
--end process;
--
data16bit_rdy         <= data_rdy or trailer_shift_trigs or header_shift_trigs or timeout_trailer_send or zero_trailer_send_pulse;
data16bit_rdy_code(0) <= (not trailer_shift_trigs) and (data_rdy xor header_shift_trigs);
data16bit_rdy_code(1) <= (not header_shift_trigs) and (data_rdy xor trailer_shift_trigs);
data16bit_rdy_code(2) <= do_transmit_timeout_trailers;
--
--process(data16bit_rdy_code, data, header, trailer)
process(clk160)
begin
    if rising_edge (clk160) then 

    case (data16bit_rdy_code) is 
        when "001" =>  -- header
            wordOUT_s <= header;
        when "010" =>  -- trailer
            wordOUT_s <= trailer;
        when "011" =>  -- data
            wordOUT_s <= data;           
        when "100" => -- time-out trailer
            if timeout_trailer_send = '1' then
                wordOUT_s <= timeout_trailer;
            else 
                wordOUT_s <= zero_data_trailer;
            end if;
        when "101" => -- time-out trailer
            if timeout_trailer_send = '1' then
                wordOUT_s <= timeout_trailer;
            else 
                wordOUT_s <= zero_data_trailer;
            end if;
        when "110" => -- time-out trailer
            if timeout_trailer_send = '1' then
                wordOUT_s <= timeout_trailer;
            else 
                wordOUT_s <= zero_data_trailer;
            end if;
        when "111" => -- time-out trailer
            if timeout_trailer_send = '1' then
                wordOUT_s <= timeout_trailer;
            else 
                wordOUT_s <= zero_data_trailer;
            end if;
        when others =>
            --wordOUT_s <= (others => '0');
    end case;
    
    end if;
end process;
--

--
process(clk160)
begin
    if rising_edge (clk160) then 
        if do_transmit_timeout_trailers = '0' then
            zero_trailer_send_pulse_count   <= (others=>'0');
        else
            zero_trailer_send_pulse_count   <= zero_trailer_send_pulse_count + 1;
        end if;
    end if;
end process;
--
zero_trailer_send_pulse <= '1' when (zero_trailer_send_pulse_count = "111") else '0';
--

--
process(clk160)
begin
    if rising_edge (clk160) then 
        if rst = '1' then
            wordOUT_RDY <= '0';
        else
            wordOUT_RDY <= data16bit_rdy;-- or data16bit_rdy_shifted;
        end if;
    end if;
end process;
--


wordOUT     <= wordOUT_s;




end Behavioral;

