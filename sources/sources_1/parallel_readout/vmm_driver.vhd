----------------------------------------------------------------------------------
-- Company:  NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Create Date: 09/30/2016 10:34:15 AM
-- Design Name: 
-- Module Name: vmm_driver - Behavioral
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
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vmm_driver is
  Port (
    ---------------------------------------
    ----------- general interface ---------
    clk_200             : in    std_logic;
    rst_drv             : in    std_logic;
    ---------------------------------------
    --------- vmm_ro interface ------------
    vmm_got_data        : in    std_logic_vector(7 downto 0);
    vmm_event_done      : in    std_logic_vector(7 downto 0); 
    trig_vmm_ack        : in    std_logic_vector(7 downto 0);   
    trig_vmm_ro         : out   std_logic;
    ---------------------------------------
    ----------- pf interface --------------
    write_packet        : out   std_logic;
    write_trailer       : out   std_logic;
    write_zeroes        : out   std_logic;
    udp_init            : out   std_logic;
    vmmId_pf            : in    std_logic_vector(2 downto 0); 
    done_and_cycle      : in    std_logic;
    new_read            : in    std_logic;
    pf_ready            : in    std_logic;
    trg_drv             : in    std_logic;
    --------------------------------------
    ------------ ila interface -----------
    drv_state_ila       : out   std_logic_vector(3 downto 0)
    );
end vmm_driver;

architecture Behavioral of vmm_driver is

--COMPONENT ila_driver
--    PORT (
--    clk    : IN STD_LOGIC;
--    probe0 : IN STD_LOGIC_VECTOR(60 DOWNTO 0)
--);
--END COMPONENT;

    type stateType is (IDLE, TRIG_VMM, CHECK_OVERALL_STATUS, IS_PF_READY, EVENT_DONE, ENABLE_PF, HOLD_HIGH, WAIT_FOR_PF_0, WAIT_FOR_PF_1);
    signal state         : stateType := IDLE;

    signal done_checking        : std_logic_vector(7 downto 0) := (others => '0');
    signal trailer_sent         : std_logic_vector(7 downto 0) := (others => '0');
    signal vmm_got_data_sync    : std_logic_vector(7 downto 0) := (others => '0');
    signal vmm_event_done_sync  : std_logic_vector(7 downto 0) := (others => '0');
    signal vmmId_pf_i           : std_logic_vector(2 downto 0) := (others => '0');
    signal debug_state          : std_logic_vector(3 downto 0) := (others => '0');
    signal trig_vmm_ack_sync    : std_logic_vector(7 downto 0) := (others => '0');

    signal write_packet_i       : std_logic := '0';
    signal write_trailer_i      : std_logic := '0';
    signal udp_init_i           : std_logic := '0';
    signal write_zeroes_i       : std_logic := '0';
    signal done_and_cycle_i     : std_logic := '0';
    signal new_read_i           : std_logic := '0';
    signal trg_drv_i            : std_logic := '0'; 
    signal wait_Cnt             : integer := 0; 
    signal vmmId_int            : integer := 0;
    signal triggerVmmReadout_i  : std_logic := '0';
    signal pf_ready_i           : std_logic := '0';
    


    ----------------- debugging declarations ------------------------------------
    --signal debug_probe       : std_logic_vector(60 downto 0) := (others => '0');
    
    --attribute mark_debug    : string;

    --attribute mark_debug of done_checking           :    signal    is    "true";
    --attribute mark_debug of trailer_sent            :    signal    is    "true";
    --attribute mark_debug of vmm_got_data_sync       :    signal    is    "true";
    --attribute mark_debug of vmm_event_done_sync     :    signal    is    "true";
    --attribute mark_debug of vmmId_pf_i              :    signal    is    "true";
    --attribute mark_debug of write_packet_i          :    signal    is    "true";
    --attribute mark_debug of write_trailer_i         :    signal    is    "true";
    --attribute mark_debug of udp_init_i              :    signal    is    "true";
    --attribute mark_debug of write_zeroes_i          :    signal    is    "true";
    --attribute mark_debug of new_read_i              :    signal    is    "true";
    --attribute mark_debug of trg_drv_i               :    signal    is    "true";
    --attribute mark_debug of triggerVmmReadout_i     :    signal    is    "true";
    --attribute mark_debug of fifo_rd_ena_i           :    signal    is    "true";
    --attribute mark_debug of debug_state             :    signal    is    "true";
    --attribute mark_debug of pf_ready_i              :    signal    is    "true";
    -----------------------------------------------------------------------------         

begin

DrvFSMproc: process(clk_200, rst_drv, state, trg_drv_i, wait_Cnt, done_checking, trailer_sent, 
                    vmmId_pf_i, vmmId_int, done_and_cycle_i, new_read_i, pf_ready_i, trig_vmm_ack_sync)
begin
    if(rising_edge(clk_200))then
        if(rst_drv = '1')then
            write_packet_i          <= '0';
            write_trailer_i         <= '0';
            write_zeroes_i          <= '0';
            triggerVmmReadout_i     <= '0';
            udp_init_i              <= '0';
            wait_Cnt                <= 0;
            debug_state             <= (others => '0');
            trailer_sent            <= (others => '0');
            state                   <= IDLE;
        else
            case state is

            when IDLE =>
                debug_state         <= "0000";
                udp_init_i          <= '0';

                if(trg_drv_i = '1')then
                    state <= TRIG_VMM;
                else
                    state <= IDLE;
                end if;

            when TRIG_VMM =>
                debug_state         <= "0001";
                if(trig_vmm_ack_sync /= "11111111")then
                    triggerVmmReadout_i     <= '1'; -- pulse until all have been triggered
                    state                   <= TRIG_VMM;
                elsif(trig_vmm_ack_sync = "11111111")then
                    triggerVmmReadout_i     <= '0'; -- done and proceed to checking
                    state                   <= CHECK_OVERALL_STATUS;
                else
                    triggerVmmReadout_i     <= '1'; -- pulse until all have been triggered
                    state                   <= TRIG_VMM;
                end if;
    

            when CHECK_OVERALL_STATUS =>
                debug_state     <= "0010";
                if(trailer_sent = "11111111")then     -- first check if all trailers have been sent i.e. event is done
                    state       <= EVENT_DONE; 
                elsif(done_checking = "11111111")then -- all vmms have either a word ready or they are empty
                    state       <= IS_PF_READY;
                else
                    state       <= CHECK_OVERALL_STATUS;
                end if;

            when IS_PF_READY =>
                debug_state         <= "0011";
                if(pf_ready_i = '1')then
                    state <= ENABLE_PF;
                else
                    state <= IS_PF_READY;
                end if;

            when ENABLE_PF =>
                debug_state         <= "0100";
                case vmmId_int is
                when 0 to 7 =>
                    if(vmm_event_done_sync(vmmId_int) = '0' and vmm_got_data_sync(vmmId_int) = '1')then
                        write_packet_i              <= '1';
                        state                       <= WAIT_FOR_PF_0;
                    elsif(vmm_event_done_sync(vmmId_int) = '1' and trailer_sent(vmmId_int) = '0')then
                        write_trailer_i             <= '1';
                        trailer_sent(vmmId_int)     <= '1';
                        state                       <= WAIT_FOR_PF_0;
                    elsif(vmm_event_done_sync(vmmId_int) = '1' and trailer_sent(vmmId_int) = '1')then
                        write_zeroes_i              <= '1';
                        trailer_sent(vmmId_int)     <= '1';
                        state                       <= WAIT_FOR_PF_0;
                    else
                        write_packet_i              <= '0';     
                        write_trailer_i             <= '0';
                        write_zeroes_i              <= '0';
                        state                       <= ENABLE_PF;
                   end if;
                when others => 
                    state <= ENABLE_PF;
                end case;
                
            when WAIT_FOR_PF_0 =>
                debug_state         <= "0101";
                if(pf_ready_i = '0')then    -- pf has got the message
                    write_packet_i  <= '0';     
                    write_trailer_i <= '0';
                    write_zeroes_i  <= '0';
                    state           <= WAIT_FOR_PF_1;
                else
                    state           <= WAIT_FOR_PF_0;
                end if;

            when WAIT_FOR_PF_1 =>
                debug_state         <= "0110";
                if(done_and_cycle_i = '1')then -- asserted by pf when it has finished incrementing vmmID
                    state       <= IS_PF_READY;
                elsif(new_read_i = '1')then   -- asserted by pf when it wishes to switch from 7 to 0. new read init.
                    state       <= CHECK_OVERALL_STATUS;            
                else
                    state       <= WAIT_FOR_PF_1;
                end if;

            when EVENT_DONE =>
                debug_state         <= "0111";
                udp_init_i          <= '1';
                trailer_sent        <= (others => '0');
                if(trg_drv_i = '0')then
                    state <= IDLE;
                else
                    state <= EVENT_DONE;
                end if;

            when others => 
                state <= IDLE;
            end case;

        end if;
    end if;
end process;

    trg_drv_i           <= trg_drv;
    done_and_cycle_i    <= done_and_cycle;
    new_read_i          <= new_read;
    vmmId_pf_i          <= vmmId_pf;
    write_packet        <= write_packet_i;
    write_trailer       <= write_trailer_i;
    write_zeroes        <= write_zeroes_i;
    trig_vmm_ro         <= triggerVmmReadout_i;
    udp_init            <= udp_init_i;
    pf_ready_i          <= pf_ready;
    vmmId_int           <= to_integer(unsigned(vmmId_pf_i));
      
    done_checking(0) <= vmm_got_data_sync(0) or vmm_event_done_sync(0);
    done_checking(1) <= vmm_got_data_sync(1) or vmm_event_done_sync(1);
    done_checking(2) <= vmm_got_data_sync(2) or vmm_event_done_sync(2);
    done_checking(3) <= vmm_got_data_sync(3) or vmm_event_done_sync(3);
    done_checking(4) <= vmm_got_data_sync(4) or vmm_event_done_sync(4);
    done_checking(5) <= vmm_got_data_sync(5) or vmm_event_done_sync(5);
    done_checking(6) <= vmm_got_data_sync(6) or vmm_event_done_sync(6);
    done_checking(7) <= vmm_got_data_sync(7) or vmm_event_done_sync(7);

    drv_state_ila   <= debug_state;
    
------------------- SYNC BLOCK --------------------------
-- sync signals that belong to different clock domains --
--------------------------------------------------------- 
got_data_sync: process(clk_200, vmm_got_data)  
begin
    if(rising_edge(clk_200))then
        vmm_got_data_sync <= vmm_got_data;
    end if;
end process;
    
event_done_sync: process(clk_200, vmm_event_done)
begin
     if(rising_edge(clk_200))then
         vmm_event_done_sync <= vmm_event_done;
     end if;
end process;

trigger_ack_sync: process(clk_200, trig_vmm_ack)
begin
    if(rising_edge(clk_200))then
        trig_vmm_ack_sync <= trig_vmm_ack;
    end if;
end process;
---------------------------------------------------------

    --driver_debugger: ila_driver
--PORT MAP (
--    clk    => clk_200,
--    probe0 => debug_probe
--);

--debug_probe(0)              <= write_packet_i;
--debug_probe(1)              <= write_trailer_i;
--debug_probe(2)              <= udp_init_i;
--debug_probe(3)              <= write_zeroes_i;
--debug_probe(4)              <= done_and_cycle_i;
--debug_probe(5)              <= new_read_i;
--debug_probe(6)              <= trg_drv_i;
--debug_probe(7)              <= pf_ready_i;
--debug_probe(8)              <= '0';
--debug_probe(9)              <= triggerVmmReadout_i;
--debug_probe(17 downto 10)   <= done_checking;
--debug_probe(25 downto 18)   <= trailer_sent;
--debug_probe(33 downto 26)   <= vmm_got_data_sync;
--debug_probe(41 downto 34)   <= vmm_event_done_sync;
--debug_probe(44 downto 42)   <= vmmId_pf_i;
--debug_probe(52 downto 45)   <= fifo_rd_ena_i;
--debug_probe(56 downto 53)   <= debug_state;
--debug_probe(60 downto 57)   <= (others => '0');   

end Behavioral;