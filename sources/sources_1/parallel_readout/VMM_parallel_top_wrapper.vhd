----------------------------------------------------------------------------------
-- Company:  NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Create Date: 09/30/2016 10:29:32 AM
-- Design Name: 
-- Module Name: VMM_parallel_top - rtl
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
use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;

entity VMM_parallel_top_wrapper is
    port(
        ------------- general interface ---------------------
        -----------------------------------------------------
        clk_200             : in    std_logic; -- 200 Mhz clk
        clk_125             : in    std_logic; -- 125 Mhz clk
        clk_50              : in    std_logic; -- 50 Mhz clk
        clk_10              : in    std_logic; -- 10 Mhz clk
        clk_10_phase45      : in    std_logic; -- shifted 10 Mhz clk
        reset               : in    std_logic;
        daq_enable          : in    std_logic;
        ----------- packet formation interface --------------
        ----------------------------------------------------- 
        newCycle            : in    std_logic;
        pfBusy              : out   std_logic;                        -- Control signal to ETR
        glBCID              : in    std_logic_vector(11 downto 0);    -- glBCID counter from ETR
        eventCnt            : in    std_logic_vector(31 downto 0);    -- event_counter from trigger module        
        resetting           : in    std_logic;
        rst_vmm             : out   std_logic;
        tr_hold             : out   std_logic;
        latency             : in    std_logic_vector(15 downto 0);
        ---------------- vmm readout interface ----------------
        -------------------------------------------------------       
        vmm_data0_vec       : in    std_logic_vector(8 downto 1);     -- Single-ended data0 from VMM
        vmm_data1_vec       : in    std_logic_vector(8 downto 1);     -- Single-ended data1 from VMM
        vmm_ckdt_vec        : out   std_logic_vector(8 downto 1);     -- Strobe to VMM CKDT
        vmm_cktk_vec        : out   std_logic_vector(8 downto 1);     -- Strobe to VMM CKTK
        vmm_ckbc_vec        : out   std_logic_vector(8 downto 1);     -- Strobe to VMM CKBC  
        ---------- mux2udp block interface --------------------
        -------------------------------------------------------
        udp_tx_start        : out   std_logic;
        data_length_ro      : out   std_logic_vector(15 downto 0);
        data_out_last_ro    : out   std_logic;
        data_out_valid_ro   : out   std_logic;
        data_out_ro         : out   std_logic_vector(7 downto 0);
        udp_tx_ready        : in    std_logic
        );
 
end VMM_parallel_top_wrapper;

architecture rtl of VMM_parallel_top_wrapper is

component vmm_readout_0
    Port (
        ------------------------------------------------------------
        ------------------- general interface ----------------------       
        clk_10              : in    std_logic;     -- Used in cktk process
        clk_10_phase45      : in    std_logic;     -- Used to sample the token pulse
        clk_50              : in    std_logic;     -- Used to clock word readout process
        clk_200             : in    std_logic;     -- Used for fast switching between processes
        daq_enable          : in    std_logic;     -- From flow_fsm
        rst_vmm_ro          : in    std_logic;     -- Reset buffer 
        ------------------------------------------------------------
        ------------------- VMM2 ASIC interface --------------------        
        vmm_data0           : in    std_logic;     -- Single-ended data0 from VMM
        vmm_data1           : in    std_logic;     -- Single-ended data1 from VMM
        vmm_ckdt            : out   std_logic;     -- Strobe to VMM CKDT
        vmm_cktk            : out   std_logic;     -- Strobe to VMM CKTK
        vmm_ckbc            : out   std_logic;     -- Strobe to VMM CKBC
        ------------------------------------------------------------
        -------------------- vmm driver interface -----------------        
        trigger_pulse       : in    std_logic;     -- Trigger in
        trigger_ack         : out   std_logic;     -- Trigger acknowledge
        vmm_got_data        : out   std_logic;     -- Buffer not empty
        vmm_event_done      : out   std_logic;     -- Buffer is empty and vmm fifo empty
        ------------------------------------------------------------
        ------------------ packet formation interface --------------                                             
        rd_ena              : in    std_logic;     -- Read word from buffer
        vmmWord             : out   std_logic_vector(31 downto 0); -- Word
        ------------------------------------------------------------
        ----------------------- ila interface ----------------------
        ro_tk_state_ila     : out   std_logic_vector(3 downto 0);
        ro_dt_state_ila     : out   std_logic_vector(3 downto 0)
        );
end component;

component vmm_readout_1
    Port (
        ------------------------------------------------------------
        ------------------- general interface ----------------------       
        clk_10              : in    std_logic;     -- Used in cktk process
        clk_10_phase45      : in    std_logic;     -- Used to sample the token pulse
        clk_50              : in    std_logic;     -- Used to clock word readout process
        clk_200             : in    std_logic;     -- Used for fast switching between processes
        daq_enable          : in    std_logic;     -- From flow_fsm
        rst_vmm_ro          : in    std_logic;     -- Reset buffer 
        ------------------------------------------------------------
        ------------------- VMM2 ASIC interface --------------------        
        vmm_data0           : in    std_logic;     -- Single-ended data0 from VMM
        vmm_data1           : in    std_logic;     -- Single-ended data1 from VMM
        vmm_ckdt            : out   std_logic;     -- Strobe to VMM CKDT
        vmm_cktk            : out   std_logic;     -- Strobe to VMM CKTK
        vmm_ckbc            : out   std_logic;     -- Strobe to VMM CKBC
        ------------------------------------------------------------
        -------------------- vmm driver interface -----------------        
        trigger_pulse       : in    std_logic;     -- Trigger in
        trigger_ack         : out   std_logic;     -- Trigger acknowledge
        vmm_got_data        : out   std_logic;     -- Buffer not empty
        vmm_event_done      : out   std_logic;     -- Buffer is empty and vmm fifo empty
        ------------------------------------------------------------
        ------------------ packet formation interface --------------                                             
        rd_ena              : in    std_logic;     -- Read word from buffer
        vmmWord             : out   std_logic_vector(31 downto 0); -- Word
        ------------------------------------------------------------
        ----------------------- ila interface ----------------------
        ro_tk_state_ila     : out   std_logic_vector(3 downto 0);
        ro_dt_state_ila     : out   std_logic_vector(3 downto 0)
        );
end component;

component vmm_readout_2
    Port (
        ------------------------------------------------------------
        ------------------- general interface ----------------------       
        clk_10              : in    std_logic;     -- Used in cktk process
        clk_10_phase45      : in    std_logic;     -- Used to sample the token pulse
        clk_50              : in    std_logic;     -- Used to clock word readout process
        clk_200             : in    std_logic;     -- Used for fast switching between processes
        daq_enable          : in    std_logic;     -- From flow_fsm
        rst_vmm_ro          : in    std_logic;     -- Reset buffer 
        ------------------------------------------------------------
        ------------------- VMM2 ASIC interface --------------------        
        vmm_data0           : in    std_logic;     -- Single-ended data0 from VMM
        vmm_data1           : in    std_logic;     -- Single-ended data1 from VMM
        vmm_ckdt            : out   std_logic;     -- Strobe to VMM CKDT
        vmm_cktk            : out   std_logic;     -- Strobe to VMM CKTK
        vmm_ckbc            : out   std_logic;     -- Strobe to VMM CKBC
        ------------------------------------------------------------
        -------------------- vmm driver interface -----------------        
        trigger_pulse       : in    std_logic;     -- Trigger in
        trigger_ack         : out   std_logic;     -- Trigger acknowledge
        vmm_got_data        : out   std_logic;     -- Buffer not empty
        vmm_event_done      : out   std_logic;     -- Buffer is empty and vmm fifo empty
        ------------------------------------------------------------
        ------------------ packet formation interface --------------                                             
        rd_ena              : in    std_logic;     -- Read word from buffer
        vmmWord             : out   std_logic_vector(31 downto 0); -- Word
        ------------------------------------------------------------
        ----------------------- ila interface ----------------------
        ro_tk_state_ila     : out   std_logic_vector(3 downto 0);
        ro_dt_state_ila     : out   std_logic_vector(3 downto 0)
        );
end component;

component vmm_readout_3
    Port (
        ------------------------------------------------------------
        ------------------- general interface ----------------------       
        clk_10              : in    std_logic;     -- Used in cktk process
        clk_10_phase45      : in    std_logic;     -- Used to sample the token pulse
        clk_50              : in    std_logic;     -- Used to clock word readout process
        clk_200             : in    std_logic;     -- Used for fast switching between processes
        daq_enable          : in    std_logic;     -- From flow_fsm
        rst_vmm_ro          : in    std_logic;     -- Reset buffer 
        ------------------------------------------------------------
        ------------------- VMM2 ASIC interface --------------------        
        vmm_data0           : in    std_logic;     -- Single-ended data0 from VMM
        vmm_data1           : in    std_logic;     -- Single-ended data1 from VMM
        vmm_ckdt            : out   std_logic;     -- Strobe to VMM CKDT
        vmm_cktk            : out   std_logic;     -- Strobe to VMM CKTK
        vmm_ckbc            : out   std_logic;     -- Strobe to VMM CKBC
        ------------------------------------------------------------
        -------------------- vmm driver interface -----------------        
        trigger_pulse       : in    std_logic;     -- Trigger in
        trigger_ack         : out   std_logic;     -- Trigger acknowledge
        vmm_got_data        : out   std_logic;     -- Buffer not empty
        vmm_event_done      : out   std_logic;     -- Buffer is empty and vmm fifo empty
        ------------------------------------------------------------
        ------------------ packet formation interface --------------                                             
        rd_ena              : in    std_logic;     -- Read word from buffer
        vmmWord             : out   std_logic_vector(31 downto 0); -- Word
        ------------------------------------------------------------
        ----------------------- ila interface ----------------------
        ro_tk_state_ila     : out   std_logic_vector(3 downto 0);
        ro_dt_state_ila     : out   std_logic_vector(3 downto 0)
        );
end component;

component vmm_readout_4
    Port (
        ------------------------------------------------------------
        ------------------- general interface ----------------------       
        clk_10              : in    std_logic;     -- Used in cktk process
        clk_10_phase45      : in    std_logic;     -- Used to sample the token pulse
        clk_50              : in    std_logic;     -- Used to clock word readout process
        clk_200             : in    std_logic;     -- Used for fast switching between processes
        daq_enable          : in    std_logic;     -- From flow_fsm
        rst_vmm_ro          : in    std_logic;     -- Reset buffer 
        ------------------------------------------------------------
        ------------------- VMM2 ASIC interface --------------------        
        vmm_data0           : in    std_logic;     -- Single-ended data0 from VMM
        vmm_data1           : in    std_logic;     -- Single-ended data1 from VMM
        vmm_ckdt            : out   std_logic;     -- Strobe to VMM CKDT
        vmm_cktk            : out   std_logic;     -- Strobe to VMM CKTK
        vmm_ckbc            : out   std_logic;     -- Strobe to VMM CKBC
        ------------------------------------------------------------
        -------------------- vmm driver interface -----------------        
        trigger_pulse       : in    std_logic;     -- Trigger in
        trigger_ack         : out   std_logic;     -- Trigger acknowledge
        vmm_got_data        : out   std_logic;     -- Buffer not empty
        vmm_event_done      : out   std_logic;     -- Buffer is empty and vmm fifo empty
        ------------------------------------------------------------
        ------------------ packet formation interface --------------                                             
        rd_ena              : in    std_logic;     -- Read word from buffer
        vmmWord             : out   std_logic_vector(31 downto 0); -- Word
        ------------------------------------------------------------
        ----------------------- ila interface ----------------------
        ro_tk_state_ila     : out   std_logic_vector(3 downto 0);
        ro_dt_state_ila     : out   std_logic_vector(3 downto 0)
        );
end component;

component vmm_readout_5
    Port (
        ------------------------------------------------------------
        ------------------- general interface ----------------------       
        clk_10              : in    std_logic;     -- Used in cktk process
        clk_10_phase45      : in    std_logic;     -- Used to sample the token pulse
        clk_50              : in    std_logic;     -- Used to clock word readout process
        clk_200             : in    std_logic;     -- Used for fast switching between processes
        daq_enable          : in    std_logic;     -- From flow_fsm
        rst_vmm_ro          : in    std_logic;     -- Reset buffer 
        ------------------------------------------------------------
        ------------------- VMM2 ASIC interface --------------------        
        vmm_data0           : in    std_logic;     -- Single-ended data0 from VMM
        vmm_data1           : in    std_logic;     -- Single-ended data1 from VMM
        vmm_ckdt            : out   std_logic;     -- Strobe to VMM CKDT
        vmm_cktk            : out   std_logic;     -- Strobe to VMM CKTK
        vmm_ckbc            : out   std_logic;     -- Strobe to VMM CKBC
        ------------------------------------------------------------
        -------------------- vmm driver interface -----------------        
        trigger_pulse       : in    std_logic;     -- Trigger in
        trigger_ack         : out   std_logic;     -- Trigger acknowledge
        vmm_got_data        : out   std_logic;     -- Buffer not empty
        vmm_event_done      : out   std_logic;     -- Buffer is empty and vmm fifo empty
        ------------------------------------------------------------
        ------------------ packet formation interface --------------                                             
        rd_ena              : in    std_logic;     -- Read word from buffer
        vmmWord             : out   std_logic_vector(31 downto 0); -- Word
        ------------------------------------------------------------
        ----------------------- ila interface ----------------------
        ro_tk_state_ila     : out   std_logic_vector(3 downto 0);
        ro_dt_state_ila     : out   std_logic_vector(3 downto 0)
        );
end component;

component vmm_readout_6
    Port (
        ------------------------------------------------------------
        ------------------- general interface ----------------------       
        clk_10              : in    std_logic;     -- Used in cktk process
        clk_10_phase45      : in    std_logic;     -- Used to sample the token pulse
        clk_50              : in    std_logic;     -- Used to clock word readout process
        clk_200             : in    std_logic;     -- Used for fast switching between processes
        daq_enable          : in    std_logic;     -- From flow_fsm
        rst_vmm_ro          : in    std_logic;     -- Reset buffer 
        ------------------------------------------------------------
        ------------------- VMM2 ASIC interface --------------------        
        vmm_data0           : in    std_logic;     -- Single-ended data0 from VMM
        vmm_data1           : in    std_logic;     -- Single-ended data1 from VMM
        vmm_ckdt            : out   std_logic;     -- Strobe to VMM CKDT
        vmm_cktk            : out   std_logic;     -- Strobe to VMM CKTK
        vmm_ckbc            : out   std_logic;     -- Strobe to VMM CKBC
        ------------------------------------------------------------
        -------------------- vmm driver interface -----------------        
        trigger_pulse       : in    std_logic;     -- Trigger in
        trigger_ack         : out   std_logic;     -- Trigger acknowledge
        vmm_got_data        : out   std_logic;     -- Buffer not empty
        vmm_event_done      : out   std_logic;     -- Buffer is empty and vmm fifo empty
        ------------------------------------------------------------
        ------------------ packet formation interface --------------                                             
        rd_ena              : in    std_logic;     -- Read word from buffer
        vmmWord             : out   std_logic_vector(31 downto 0); -- Word
        ------------------------------------------------------------
        ----------------------- ila interface ----------------------
        ro_tk_state_ila     : out   std_logic_vector(3 downto 0);
        ro_dt_state_ila     : out   std_logic_vector(3 downto 0)
        );
end component;

component vmm_readout_7
    Port (
        ------------------------------------------------------------
        ------------------- general interface ----------------------       
        clk_10              : in    std_logic;     -- Used in cktk process
        clk_10_phase45      : in    std_logic;     -- Used to sample the token pulse
        clk_50              : in    std_logic;     -- Used to clock word readout process
        clk_200             : in    std_logic;     -- Used for fast switching between processes
        daq_enable          : in    std_logic;     -- From flow_fsm
        rst_vmm_ro          : in    std_logic;     -- Reset buffer 
        ------------------------------------------------------------
        ------------------- VMM2 ASIC interface --------------------        
        vmm_data0           : in    std_logic;     -- Single-ended data0 from VMM
        vmm_data1           : in    std_logic;     -- Single-ended data1 from VMM
        vmm_ckdt            : out   std_logic;     -- Strobe to VMM CKDT
        vmm_cktk            : out   std_logic;     -- Strobe to VMM CKTK
        vmm_ckbc            : out   std_logic;     -- Strobe to VMM CKBC
        ------------------------------------------------------------
        -------------------- vmm driver interface -----------------        
        trigger_pulse       : in    std_logic;     -- Trigger in
        trigger_ack         : out   std_logic;     -- Trigger acknowledge
        vmm_got_data        : out   std_logic;     -- Buffer not empty
        vmm_event_done      : out   std_logic;     -- Buffer is empty and vmm fifo empty
        ------------------------------------------------------------
        ------------------ packet formation interface --------------                                             
        rd_ena              : in    std_logic;     -- Read word from buffer
        vmmWord             : out   std_logic_vector(31 downto 0); -- Word
        ------------------------------------------------------------
        ----------------------- ila interface ----------------------
        ro_tk_state_ila     : out   std_logic_vector(3 downto 0);
        ro_dt_state_ila     : out   std_logic_vector(3 downto 0)
        );
end component;



component vmm_driver is
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
end component;

component packet_formation_ram is
Port(
    -----------------------------------------------
    ---------- general interface ------------------
    clk_200             : in    std_logic;
    newCycle            : in    std_logic;
    vmmId               : out   std_logic_vector(2 downto 0);        
    pfBusy              : out   std_logic;                        -- Control signal to ETR
    glBCID              : in    std_logic_vector(11 downto 0);    -- glBCID counter from ETR
    eventCnt            : in    std_logic_vector(31 downto 0);    -- event_counter from trigger module
    reset               : in    std_logic;
    resetting           : in    std_logic;
    rst_vmm             : out   std_logic;
    tr_hold             : out   std_logic;
    latency             : in    std_logic_vector(15 downto 0);        
    -----------------------------------------------
    ----------- vmm driver interface -------------
    write_packet        : in    std_logic;
    write_trailer       : in    std_logic;
    write_zeroes        : in    std_logic;
    udp_init            : in    std_logic;         
    done_and_cycle      : out   std_logic;
    new_read            : out   std_logic;
    trg_drv             : out   std_logic;
    pf_ready            : out   std_logic;                      -- also driven into RAM2UDP
    -----------------------------------------------
    ------------- RAM2UDP interface ---------------
    RAMdone             : in    std_logic;
    dataout             : out   std_logic_vector(31 downto 0);
    addrRAM_wr          : out   std_logic_vector(11 downto 0);
    packLen             : out   std_logic_vector(11 downto 0);
    end_packet          : out   std_logic;
    wrenable            : out   std_logic;
    init_read           : out   std_logic;
    got_len             : in    std_logic;
    -------------------------------------------------
    ------------ vmm interface ----------------------
    vmm_rd_ena          : out   std_logic_vector(7 downto 0);
    fifo_bus_vmm0       : in    std_logic_vector(31 downto 0);
    fifo_bus_vmm1       : in    std_logic_vector(31 downto 0);
    fifo_bus_vmm2       : in    std_logic_vector(31 downto 0);
    fifo_bus_vmm3       : in    std_logic_vector(31 downto 0);
    fifo_bus_vmm4       : in    std_logic_vector(31 downto 0);
    fifo_bus_vmm5       : in    std_logic_vector(31 downto 0);
    fifo_bus_vmm6       : in    std_logic_vector(31 downto 0);
    fifo_bus_vmm7       : in    std_logic_vector(31 downto 0);
    --------------------------------------------------
    -------- ila interface ---------------------------
    pf_state_ila        : out   std_logic_vector(5 downto 0);
    start_cnt           : out   std_logic;
    start_cnt_ram       : out   std_logic;
    trigger_ila         : out   std_logic
    );
end component;

component RAM2UDP is
  Port (
    --------- general interface -------------------
    -----------------------------------------------
    clk_200                 : in std_logic;
    clk_125                 : in std_logic;
    rst_ram2udp             : in std_logic;
    ---------- pf interface -----------------------
    -----------------------------------------------
    RAMdone                 : out  std_logic;
    VmmId                   : in   std_logic_vector(2 downto 0);  
    dataIn                  : in   std_logic_vector(31 downto 0); 
    addrRAM_wr              : in   std_logic_vector(11 downto 0);
    packLen                 : in   std_logic_vector(11 downto 0); 
    end_packet              : in   std_logic;
    wrenable                : in   std_logic;
    pf_ready                : in   std_logic;
    init_read               : in   std_logic;
    got_len                 : out  std_logic;
    ----------- mux2udp interface ----------------
    ----------------------------------------------
    udp_tx_start            : out std_logic;
    data_length_o           : out std_logic_vector(15 downto 0);
    data_out_last_o         : out std_logic;
    data_out_valid_o        : out std_logic;
    data_out_o              : out std_logic_vector(7 downto 0);
    udp_tx_data_out_ready   : in  std_logic;
    ------------ ila interface -------------------
    ----------------------------------------------
    ram_state_ila           : out std_logic_vector(3 downto 0)
    );
end component;

--COMPONENT ila_para_readout_wrapper
--    PORT (
--    clk    : IN STD_LOGIC;
--    probe0 : IN STD_LOGIC_VECTOR(550 DOWNTO 0)
--);
--END COMPONENT;

    signal vmmWord_0_i      : std_logic_vector(31 downto 0);
    signal vmmWord_1_i      : std_logic_vector(31 downto 0);
    signal vmmWord_2_i      : std_logic_vector(31 downto 0);
    signal vmmWord_3_i      : std_logic_vector(31 downto 0);
    signal vmmWord_4_i      : std_logic_vector(31 downto 0);
    signal vmmWord_5_i      : std_logic_vector(31 downto 0);
    signal vmmWord_6_i      : std_logic_vector(31 downto 0);
    signal vmmWord_7_i      : std_logic_vector(31 downto 0);
    signal vmmID_i          : std_logic_vector(2  downto 0) := (others => '0');
    signal got_data_i       : std_logic_vector(7 downto 0)  := (others => '0');
    signal event_done_i     : std_logic_vector(7 downto 0)  := (others => '0');
    signal vmm_rd_ena_i     : std_logic_vector(7 downto 0)  := (others => '0');
    signal done_and_cycle_i : std_logic := '0';
    signal trigger_vmm_ro_i : std_logic := '0';
    signal trigger_ack_i    : std_logic_vector(7 downto 0) := (others => '0');
    signal trg_drv_i        : std_logic := '0';
    signal write_packet_i   : std_logic := '0';
    signal write_trl_i      : std_logic := '0';
    signal write_zero_i     : std_logic := '0';
    signal pf_ready_i       : std_logic := '0';
    signal new_read_i       : std_logic := '0';
    signal drv_done_i       : std_logic := '0';
    signal udp_init_i       : std_logic := '0';
    signal RAMdone_i        : std_logic := '0';
    signal glBCID_i         : std_logic_vector(11 downto 0) := x"faf";
    signal addrRAM_wr_i     : std_logic_vector(11 downto 0) := (others => '0');
    signal packLen_i        : std_logic_vector(11 downto 0) := (others => '0');
    signal wr_en_i          : std_logic := '0';
    signal end_packet_i     : std_logic := '0';
    signal init_read_i      : std_logic := '0';
    signal dout_pf          : std_logic_vector(31 downto 0) := (others => '0');
    signal got_len_i        : std_logic := '0';

    signal vmm_data0_vec_i  : std_logic_vector(8 downto 1) := (others => '0');
    signal vmm_data1_vec_i  : std_logic_vector(8 downto 1) := (others => '0');
    signal vmm_ckdt_vec_i   : std_logic_vector(8 downto 1) := (others => '0');
    signal vmm_cktk_vec_i   : std_logic_vector(8 downto 1) := (others => '0');
    signal vmm_ckbc_vec_i   : std_logic_vector(8 downto 1) := (others => '0');

    signal start_cnt_i      : std_logic := '0';
    signal start_cnt_ram_i  : std_logic := '0';
    signal trigger_ila_i    : std_logic := '0';
    signal dead_cnt         : unsigned(31 downto 0)         := (others => '0');
    signal dead_cnt_sig     : std_logic_vector(31 downto 0) := (others => '0');
    signal ram_cnt          : unsigned(31 downto 0)         := (others => '0');
    signal ram_cnt_sig      : std_logic_vector(31 downto 0) := (others => '0');  

    ------------------ debugging signals/declarations ------------------------
    signal pf_state_ila         : std_logic_vector(5 downto 0) := (others => '0');
    signal drv_state_ila        : std_logic_vector(3 downto 0) := (others => '0');
    signal ram_state_ila        : std_logic_vector(3 downto 0) := (others => '0');
    signal ro_tk_state_0_ila    : std_logic_vector(3 downto 0) := (others => '0');
    signal rd_dt_state_0_ila    : std_logic_vector(3 downto 0) := (others => '0'); 
    signal ro_tk_state_1_ila    : std_logic_vector(3 downto 0) := (others => '0');
    signal rd_dt_state_1_ila    : std_logic_vector(3 downto 0) := (others => '0');  
    signal ro_tk_state_2_ila    : std_logic_vector(3 downto 0) := (others => '0');
    signal rd_dt_state_2_ila    : std_logic_vector(3 downto 0) := (others => '0');
    signal ro_tk_state_3_ila    : std_logic_vector(3 downto 0) := (others => '0');
    signal rd_dt_state_3_ila    : std_logic_vector(3 downto 0) := (others => '0');
    signal ro_tk_state_4_ila    : std_logic_vector(3 downto 0) := (others => '0');
    signal rd_dt_state_4_ila    : std_logic_vector(3 downto 0) := (others => '0');
    signal ro_tk_state_5_ila    : std_logic_vector(3 downto 0) := (others => '0');
    signal rd_dt_state_5_ila    : std_logic_vector(3 downto 0) := (others => '0');
    signal ro_tk_state_6_ila    : std_logic_vector(3 downto 0) := (others => '0');
    signal rd_dt_state_6_ila    : std_logic_vector(3 downto 0) := (others => '0');
    signal ro_tk_state_7_ila    : std_logic_vector(3 downto 0) := (others => '0');
    signal rd_dt_state_7_ila    : std_logic_vector(3 downto 0) := (others => '0');
    
    ------------------------------------------------------------------------------
    ------------------------------ mark_debug ------------------------------------

--    signal debug_probe          : std_logic_vector(550 downto 0) := (others => '0');

--    attribute mark_debug : string;
    
--    attribute mark_debug of vmmWord_0_i                 :    signal    is    "true";
--    attribute mark_debug of vmmWord_1_i                 :    signal    is    "true";
--    attribute mark_debug of vmmWord_2_i                 :    signal    is    "true";
--    attribute mark_debug of vmmWord_3_i                 :    signal    is    "true";
--    attribute mark_debug of vmmWord_4_i                 :    signal    is    "true";
--    attribute mark_debug of vmmWord_5_i                 :    signal    is    "true";
--    attribute mark_debug of vmmWord_6_i                 :    signal    is    "true";
--    attribute mark_debug of vmmWord_7_i                 :    signal    is    "true";
--    attribute mark_debug of vmmID_i                     :    signal    is    "true";
--    attribute mark_debug of got_data_i                  :    signal    is    "true";
--    attribute mark_debug of event_done_i                :    signal    is    "true";
--    attribute mark_debug of vmm_rd_ena_i                :    signal    is    "true";
--    attribute mark_debug of done_and_cycle_i            :    signal    is    "true";
--    attribute mark_debug of trigger_vmm_ro_i            :    signal    is    "true";
--    attribute mark_debug of trigger_ack_i               :    signal    is    "true";
--    attribute mark_debug of trg_drv_i                   :    signal    is    "true";
--    attribute mark_debug of write_packet_i              :    signal    is    "true";
--    attribute mark_debug of write_trl_i                 :    signal    is    "true";
--    attribute mark_debug of write_zero_i                :    signal    is    "true";
--    attribute mark_debug of pf_ready_i                  :    signal    is    "true";
--    attribute mark_debug of new_read_i                  :    signal    is    "true";
--    attribute mark_debug of drv_done_i                  :    signal    is    "true";
--    attribute mark_debug of udp_init_i                  :    signal    is    "true";
--    attribute mark_debug of RAMdone_i                   :    signal    is    "true";
--    attribute mark_debug of wr_en_i                     :    signal    is    "true";
--    attribute mark_debug of init_read_i                 :    signal    is    "true";
--    attribute mark_debug of got_len_i                   :    signal    is    "true";
--    attribute mark_debug of addrRAM_wr_i                :    signal    is    "true";
--    attribute mark_debug of packLen_i                   :    signal    is    "true";
--    attribute mark_debug of dout_pf                     :    signal    is    "true";
--    attribute mark_debug of vmm_data0_vec_i             :    signal    is    "true";
--    attribute mark_debug of vmm_data1_vec_i             :    signal    is    "true";
--    attribute mark_debug of vmm_ckdt_vec_i              :    signal    is    "true";
--    attribute mark_debug of vmm_cktk_vec_i              :    signal    is    "true";
--    attribute mark_debug of pf_state_ila                :    signal    is    "true";
--    attribute mark_debug of drv_state_ila               :    signal    is    "true";
--    attribute mark_debug of ram_state_ila               :    signal    is    "true";
--    attribute mark_debug of ro_tk_state_0_ila           :    signal    is    "true";
--    attribute mark_debug of rd_dt_state_0_ila           :    signal    is    "true";
--    attribute mark_debug of ro_tk_state_1_ila           :    signal    is    "true";
--    attribute mark_debug of rd_dt_state_1_ila           :    signal    is    "true";
--    attribute mark_debug of ro_tk_state_2_ila           :    signal    is    "true";
--    attribute mark_debug of rd_dt_state_2_ila           :    signal    is    "true";
--    attribute mark_debug of ro_tk_state_3_ila           :    signal    is    "true";
--    attribute mark_debug of rd_dt_state_3_ila           :    signal    is    "true";
--    attribute mark_debug of ro_tk_state_4_ila           :    signal    is    "true";
--    attribute mark_debug of rd_dt_state_4_ila           :    signal    is    "true";
--    attribute mark_debug of ro_tk_state_5_ila           :    signal    is    "true";
--    attribute mark_debug of rd_dt_state_5_ila           :    signal    is    "true";
--    attribute mark_debug of ro_tk_state_6_ila           :    signal    is    "true";
--    attribute mark_debug of rd_dt_state_6_ila           :    signal    is    "true";
--    attribute mark_debug of ro_tk_state_7_ila           :    signal    is    "true";
--    attribute mark_debug of rd_dt_state_7_ila           :    signal    is    "true";
--    attribute mark_debug of ram_cnt_sig                 :    signal    is    "true";
--    attribute mark_debug of dead_cnt_sig                :    signal    is    "true";
--    attribute mark_debug of trigger_ila_i               :    signal    is    "true";

begin

vmm_0_readout: vmm_readout_0
    port map(
    ----------------------- general interface ------------------------
    clk_10          => clk_10,             -- Used in cktk process 
    clk_10_phase45  => clk_10_phase45,     -- Used to clock checking for data process
    clk_50          => clk_50,             -- Used to clock word readout process
    clk_200         => clk_200,            -- Used for fast switching between processes
    daq_enable      => daq_enable,         -- daq enable from top fsm
    rst_vmm_ro      => reset,              -- reset the vmm buffer
    ------------------------------------------------------------------
    ---------------------- VMM2 ASIC interface -----------------------
    vmm_data0       => vmm_data0_vec_i(1),     -- Single-ended data0 from VMM0
    vmm_data1       => vmm_data1_vec_i(1),     -- Single-ended data1 from VMM0
    vmm_ckdt        => vmm_ckdt_vec_i(1),     -- Strobe to VMM0 CKDT
    vmm_cktk        => vmm_cktk_vec_i(1),     -- Strobe to VMM0 CKTK
    vmm_ckbc        => vmm_ckbc_vec_i(1),     -- Strobe to VMM0 CKBC
    ------------------------------------------------------------
    -------------------- vmm driver interface -----------------        
    trigger_pulse   => trigger_vmm_ro_i,     -- Trigger
    trigger_ack     => trigger_ack_i(0),
    vmm_got_data    => got_data_i(0),
    vmm_event_done  => event_done_i(0),
    ------------------------------------------------------------
    ------------------ packet formation interface --------------                                             
    rd_ena          => vmm_rd_ena_i(0),
    vmmWord         => vmmWord_0_i,
    ------------------------------------------------------------
    ----------------------- ila interface ----------------------
    ro_tk_state_ila => ro_tk_state_0_ila,
    ro_dt_state_ila => rd_dt_state_0_ila
    );

vmm_1_readout: vmm_readout_1
    port map(
    ----------------------- general interface ------------------------
    clk_10          => clk_10,             -- Used in cktk process 
    clk_10_phase45  => clk_10_phase45,     -- Used to sample the token pulse
    clk_50          => clk_50,             -- Used to clock word readout process
    clk_200         => clk_200,            -- Used for fast switching between processes
    daq_enable      => daq_enable,         -- daq enable from top fsm
    rst_vmm_ro      => reset,              -- reset the vmm buffer
    ------------------------------------------------------------------
    ---------------------- VMM2 ASIC interface -----------------------
    vmm_data0       => vmm_data0_vec_i(2),     -- Single-ended data0 from VMM1
    vmm_data1       => vmm_data1_vec_i(2),     -- Single-ended data1 from VMM1
    vmm_ckdt        => vmm_ckdt_vec_i(2),     -- Strobe to VMM1 CKDT
    vmm_cktk        => vmm_cktk_vec_i(2),     -- Strobe to VMM1 CKTK
    vmm_ckbc        => vmm_ckbc_vec_i(2),     -- Strobe to VMM1 CKBC
    ------------------------------------------------------------
    -------------------- vmm driver interface -----------------        
    trigger_pulse   => trigger_vmm_ro_i,     -- Trigger
    trigger_ack     => trigger_ack_i(1),
    vmm_got_data    => got_data_i(1),
    vmm_event_done  => event_done_i(1),
    ------------------------------------------------------------
    ------------------ packet formation interface --------------                                             
    rd_ena          => vmm_rd_ena_i(1),
    vmmWord         => vmmWord_1_i,
    ------------------------------------------------------------
    ----------------------- ila interface ----------------------
    ro_tk_state_ila => ro_tk_state_1_ila,
    ro_dt_state_ila => rd_dt_state_1_ila
    );

vmm_2_readout: vmm_readout_2
    port map(
    ----------------------- general interface ------------------------
    clk_10          => clk_10,             -- Used in cktk process 
    clk_10_phase45  => clk_10_phase45,     -- Used to sample the token pulse
    clk_50          => clk_50,             -- Used to clock word readout process
    clk_200         => clk_200,            -- Used for fast switching between processes
    daq_enable      => daq_enable,         -- daq enable from top fsm
    rst_vmm_ro      => reset,              -- reset the vmm buffer
    ------------------------------------------------------------------
    ---------------------- VMM2 ASIC interface -----------------------
    vmm_data0       => vmm_data0_vec_i(3),     -- Single-ended data0 from VMM2
    vmm_data1       => vmm_data1_vec_i(3),     -- Single-ended data1 from VMM2
    vmm_ckdt        => vmm_ckdt_vec_i(3),     -- Strobe to VMM2 CKDT
    vmm_cktk        => vmm_cktk_vec_i(3),     -- Strobe to VMM2 CKTK
    vmm_ckbc        => vmm_ckbc_vec_i(3),     -- Strobe to VMM2 CKBC
    ------------------------------------------------------------
    -------------------- vmm driver interface -----------------        
    trigger_pulse   => trigger_vmm_ro_i,     -- Trigger
    trigger_ack     => trigger_ack_i(2),
    vmm_got_data    => got_data_i(2),
    vmm_event_done  => event_done_i(2),
    ------------------------------------------------------------
    ------------------ packet formation interface --------------                                             
    rd_ena          => vmm_rd_ena_i(2),
    vmmWord         => vmmWord_2_i,
    ------------------------------------------------------------
    ----------------------- ila interface ----------------------
    ro_tk_state_ila => ro_tk_state_2_ila,
    ro_dt_state_ila => rd_dt_state_2_ila
    );

vmm_3_readout: vmm_readout_3
    port map(
    ----------------------- general interface ------------------------
    clk_10          => clk_10,             -- Used in cktk process 
    clk_10_phase45  => clk_10_phase45,     -- Used to sample the token pulse
    clk_50          => clk_50,             -- Used to clock word readout process
    clk_200         => clk_200,            -- Used for fast switching between processes
    daq_enable      => daq_enable,         -- daq enable from top fsm
    rst_vmm_ro      => reset,              -- reset the vmm buffer
    ------------------------------------------------------------------
    ---------------------- VMM2 ASIC interface -----------------------
    vmm_data0       => vmm_data0_vec_i(4),     -- Single-ended data0 from VMM3
    vmm_data1       => vmm_data1_vec_i(4),     -- Single-ended data1 from VMM3
    vmm_ckdt        => vmm_ckdt_vec_i(4),     -- Strobe to VMM3 CKDT
    vmm_cktk        => vmm_cktk_vec_i(4),     -- Strobe to VMM3 CKTK
    vmm_ckbc        => vmm_ckbc_vec_i(4),     -- Strobe to VMM3 CKBC
    ------------------------------------------------------------
    -------------------- vmm driver interface -----------------        
    trigger_pulse   => trigger_vmm_ro_i,     -- Trigger
    trigger_ack     => trigger_ack_i(3),
    vmm_got_data    => got_data_i(3),
    vmm_event_done  => event_done_i(3),
    ------------------------------------------------------------
    ------------------ packet formation interface --------------                                             
    rd_ena          => vmm_rd_ena_i(3),
    vmmWord         => vmmWord_3_i,
    ------------------------------------------------------------
    ----------------------- ila interface ----------------------
    ro_tk_state_ila => ro_tk_state_3_ila,
    ro_dt_state_ila => rd_dt_state_3_ila
    );

vmm_4_readout: vmm_readout_4
    port map(
    ----------------------- general interface ------------------------
    clk_10          => clk_10,             -- Used in cktk process 
    clk_10_phase45  => clk_10_phase45,     -- Used to sample the token pulse
    clk_50          => clk_50,             -- Used to clock word readout process
    clk_200         => clk_200,            -- Used for fast switching between processes
    daq_enable      => daq_enable,         -- daq enable from top fsm
    rst_vmm_ro      => reset,              -- reset the vmm buffer
    ------------------------------------------------------------------
    ---------------------- VMM2 ASIC interface -----------------------
    vmm_data0       => vmm_data0_vec_i(5),     -- Single-ended data0 from VMM4
    vmm_data1       => vmm_data1_vec_i(5),     -- Single-ended data1 from VMM4
    vmm_ckdt        => vmm_ckdt_vec_i(5),     -- Strobe to VMM4 CKDT
    vmm_cktk        => vmm_cktk_vec_i(5),     -- Strobe to VMM4 CKTK
    vmm_ckbc        => vmm_ckbc_vec_i(5),     -- Strobe to VMM4 CKBC
    ------------------------------------------------------------
    -------------------- vmm driver interface -----------------        
    trigger_pulse   => trigger_vmm_ro_i,     -- Trigger
    trigger_ack     => trigger_ack_i(4),
    vmm_got_data    => got_data_i(4),
    vmm_event_done  => event_done_i(4),
    ------------------------------------------------------------
    ------------------ packet formation interface --------------                                             
    rd_ena          => vmm_rd_ena_i(4),
    vmmWord         => vmmWord_4_i,
    ------------------------------------------------------------
    ----------------------- ila interface ----------------------
    ro_tk_state_ila => ro_tk_state_4_ila,
    ro_dt_state_ila => rd_dt_state_4_ila
    );

vmm_5_readout: vmm_readout_5
    port map(
    ----------------------- general interface ------------------------
    clk_10          => clk_10,             -- Used in cktk process 
    clk_10_phase45  => clk_10_phase45,     -- Used to sample the token pulse
    clk_50          => clk_50,             -- Used to clock word readout process
    clk_200         => clk_200,            -- Used for fast switching between processes
    daq_enable      => daq_enable,         -- daq enable from top fsm
    rst_vmm_ro      => reset,              -- reset the vmm buffer
    ------------------------------------------------------------------
    ---------------------- VMM2 ASIC interface -----------------------
    vmm_data0       => vmm_data0_vec_i(6),     -- Single-ended data0 from VMM5
    vmm_data1       => vmm_data1_vec_i(6),     -- Single-ended data1 from VMM5
    vmm_ckdt        => vmm_ckdt_vec_i(6),     -- Strobe to VMM5 CKDT
    vmm_cktk        => vmm_cktk_vec_i(6),     -- Strobe to VMM5 CKTK
    vmm_ckbc        => vmm_ckbc_vec_i(6),     -- Strobe to VMM5 CKBC
    ------------------------------------------------------------
    -------------------- vmm driver interface -----------------        
    trigger_pulse   => trigger_vmm_ro_i,     -- Trigger
    trigger_ack     => trigger_ack_i(5),
    vmm_got_data    => got_data_i(5),
    vmm_event_done  => event_done_i(5),
    ------------------------------------------------------------
    ------------------ packet formation interface --------------                                             
    rd_ena          => vmm_rd_ena_i(5),
    vmmWord         => vmmWord_5_i,
    ------------------------------------------------------------
    ----------------------- ila interface ----------------------
    ro_tk_state_ila => ro_tk_state_5_ila,
    ro_dt_state_ila => rd_dt_state_5_ila
    );

vmm_6_readout: vmm_readout_6
    port map(
    ----------------------- general interface ------------------------
    clk_10          => clk_10,             -- Used in cktk process 
    clk_10_phase45  => clk_10_phase45,     -- Used to sample the token pulse
    clk_50          => clk_50,             -- Used to clock word readout process
    clk_200         => clk_200,            -- Used for fast switching between processes
    daq_enable      => daq_enable,         -- daq enable from top fsm
    rst_vmm_ro      => reset,              -- reset the vmm buffer
    ------------------------------------------------------------------
    ---------------------- VMM2 ASIC interface -----------------------
    vmm_data0       => vmm_data0_vec_i(7),     -- Single-ended data0 from VMM6
    vmm_data1       => vmm_data1_vec_i(7),     -- Single-ended data1 from VMM6
    vmm_ckdt        => vmm_ckdt_vec_i(7),     -- Strobe to VMM6 CKDT
    vmm_cktk        => vmm_cktk_vec_i(7),     -- Strobe to VMM6 CKTK
    vmm_ckbc        => vmm_ckbc_vec_i(7),     -- Strobe to VMM6 CKBC
    ------------------------------------------------------------
    -------------------- vmm driver interface -----------------        
    trigger_pulse   => trigger_vmm_ro_i,     -- Trigger
    trigger_ack     => trigger_ack_i(6),
    vmm_got_data    => got_data_i(6),
    vmm_event_done  => event_done_i(6),
    ------------------------------------------------------------
    ------------------ packet formation interface --------------                                             
    rd_ena          => vmm_rd_ena_i(6),
    vmmWord         => vmmWord_6_i,
    ------------------------------------------------------------
    ----------------------- ila interface ----------------------
    ro_tk_state_ila => ro_tk_state_6_ila,
    ro_dt_state_ila => rd_dt_state_6_ila
    );

vmm_7_readout: vmm_readout_7
    port map(
    ----------------------- general interface ------------------------
    clk_10          => clk_10,             -- Used in cktk process 
    clk_10_phase45  => clk_10_phase45,     -- Used to sample the token pulse
    clk_50          => clk_50,             -- Used to clock word readout process
    clk_200         => clk_200,            -- Used for fast switching between processes
    daq_enable      => daq_enable,         -- daq enable from top fsm
    rst_vmm_ro      => reset,              -- reset the vmm buffer
    ------------------------------------------------------------------
    ---------------------- VMM2 ASIC interface -----------------------
    vmm_data0       => vmm_data0_vec_i(8),     -- Single-ended data0 from VMM7
    vmm_data1       => vmm_data1_vec_i(8),     -- Single-ended data1 from VMM7
    vmm_ckdt        => vmm_ckdt_vec_i(8),     -- Strobe to VMM7 CKDT
    vmm_cktk        => vmm_cktk_vec_i(8),     -- Strobe to VMM7 CKTK
    vmm_ckbc        => vmm_ckbc_vec_i(8),     -- Strobe to VMM7 CKBC
    ------------------------------------------------------------
    -------------------- vmm driver interface -----------------        
    trigger_pulse   => trigger_vmm_ro_i,     -- Trigger
    trigger_ack     => trigger_ack_i(7),
    vmm_got_data    => got_data_i(7),
    vmm_event_done  => event_done_i(7),
    ------------------------------------------------------------
    ------------------ packet formation interface --------------                                             
    rd_ena          => vmm_rd_ena_i(7),
    vmmWord         => vmmWord_7_i,
    ------------------------------------------------------------
    ----------------------- ila interface ----------------------
    ro_tk_state_ila => ro_tk_state_7_ila,
    ro_dt_state_ila => rd_dt_state_7_ila
    );

vmm_driver_instance: vmm_driver
    port map(
    ---------------------------------------
    ----------- general interface ---------
    clk_200              => clk_200,
    rst_drv              => reset,
    ---------------------------------------
    --------- vmm interface ---------------
    vmm_got_data         => got_data_i,
    vmm_event_done       => event_done_i,
    trig_vmm_ack         => trigger_ack_i,       
    trig_vmm_ro          => trigger_vmm_ro_i,
    ---------------------------------------
    ----------- pf interface --------------
    write_packet         => write_packet_i,
    write_trailer        => write_trl_i,
    write_zeroes         => write_zero_i,
    udp_init             => udp_init_i,
    vmmId_pf             => vmmID_i,
    done_and_cycle       => done_and_cycle_i,
    new_read             => new_read_i,
    pf_ready             => pf_ready_i,
    trg_drv              => trg_drv_i,
    --------------------------------------
    ------------ ila interface -----------
    drv_state_ila        => drv_state_ila
    );

packet_formatting_instance: packet_formation_ram
    Port map(
    -----------------------------------------------
    ---------- general interface ------------------
    clk_200             => clk_200,
    newCycle            => newCycle,
    vmmId               => vmmID_i,      
    pfBusy              => pfBusy,
    glBCID              => glBCID_i,
    eventCnt            => eventCnt,
    reset               => reset,
    resetting           => resetting,
    rst_vmm             => rst_vmm,
    tr_hold             => tr_hold,
    latency             => latency,        
    -----------------------------------------------
    ----------- vmm_driver interface -------------
    write_packet        => write_packet_i,
    write_trailer       => write_trl_i,
    write_zeroes        => write_zero_i,
    udp_init            => udp_init_i,
    done_and_cycle      => done_and_cycle_i,
    new_read            => new_read_i,
    trg_drv             => trg_drv_i,
    pf_ready            => pf_ready_i,
    -----------------------------------------------
    ------------- RAM2UDP interface ---------------
    RAMdone             => RAMdone_i,
    dataout             => dout_pf,
    addrRAM_wr          => addrRAM_wr_i,
    packLen             => packLen_i,
    end_packet          => end_packet_i,
    wrenable            => wr_en_i,
    init_read           => init_read_i,
    got_len             => got_len_i,
    ----------------------------------------------
    ------------ data buses ----------------------
    vmm_rd_ena           => vmm_rd_ena_i,
    fifo_bus_vmm0        => vmmWord_0_i,
    fifo_bus_vmm1        => vmmWord_1_i,
    fifo_bus_vmm2        => vmmWord_2_i,
    fifo_bus_vmm3        => vmmWord_3_i,
    fifo_bus_vmm4        => vmmWord_4_i,
    fifo_bus_vmm5        => vmmWord_5_i,
    fifo_bus_vmm6        => vmmWord_6_i,
    fifo_bus_vmm7        => vmmWord_7_i,
    --------------------------------------------------
    -------- ila interface ---------------------------
    pf_state_ila        => pf_state_ila,
    start_cnt           => start_cnt_i,
    start_cnt_ram       => start_cnt_ram_i,
    trigger_ila         => trigger_ila_i
    );

RAM_instance: RAM2UDP
  Port map(
    --------- general interface -------------------
    -----------------------------------------------
    clk_200                 => clk_200,
    clk_125                 => clk_125,
    rst_ram2udp             => reset,
    ---------- pf interface -----------------------
    -----------------------------------------------
    RAMdone                 => RAMdone_i,
    VmmId                   => vmmID_i,
    dataIn                  => dout_pf,
    addrRAM_wr              => addrRAM_wr_i,
    packLen                 => packLen_i,
    end_packet              => end_packet_i,
    wrenable                => wr_en_i,
    pf_ready                => pf_ready_i,
    init_read               => init_read_i,
    got_len                 => got_len_i,
    ----------- mux2udp interface ----------------
    ----------------------------------------------
    udp_tx_start            => udp_tx_start,
    data_length_o           => data_length_ro,
    data_out_last_o         => data_out_last_ro,
    data_out_valid_o        => data_out_valid_ro,
    data_out_o              => data_out_ro,
    udp_tx_data_out_ready   => udp_tx_ready,
    ------------ ila interface -------------------
    ----------------------------------------------
    ram_state_ila           => ram_state_ila
    );
    
    vmm_data0_vec_i     <=      vmm_data0_vec;
    vmm_data1_vec_i     <=      vmm_data1_vec;
    vmm_ckdt_vec        <=      vmm_ckdt_vec_i;
    vmm_cktk_vec        <=      vmm_cktk_vec_i;
    vmm_ckbc_vec        <=      vmm_ckbc_vec_i;

--parallel_debug: ila_para_readout_wrapper
--PORT MAP (
--    clk    => clk_200,
--    probe0 => debug_probe
--);

--    debug_probe(31 downto 0)        <= vmmWord_0_i;
--    debug_probe(63 downto 32)       <= vmmWord_1_i;
--    debug_probe(95 downto 64)       <= vmmWord_2_i;
--    debug_probe(96)                 <= '0';
--    debug_probe(128 downto 97)      <= vmmWord_3_i;
--    debug_probe(160 downto 129)     <= vmmWord_4_i;
--    debug_probe(192 downto 161)     <= vmmWord_5_i;
--    debug_probe(224 downto 193)     <= vmmWord_6_i;
--    debug_probe(256 downto 225)     <= vmmWord_7_i;
--    debug_probe(259 downto 257)     <= vmmID_i;
--    debug_probe(267 downto 260)     <= got_data_i;
--    debug_probe(275 downto 268)     <= event_done_i;
--    debug_probe(279 downto 276)     <= ram_state_ila;
--    debug_probe(283 downto 280)     <= (others => '0');
--    debug_probe(291 downto 284)     <= vmm_rd_ena_i;
--    debug_probe(292)                <= done_and_cycle_i;
--    debug_probe(293)                <= trigger_vmm_ro_i;
--    debug_probe(294)                <= trg_drv_i;
--    debug_probe(295)                <= write_packet_i;
--    debug_probe(296)                <= write_trl_i;
--    debug_probe(297)                <= write_zero_i;
--    debug_probe(298)                <= pf_ready_i;
--    debug_probe(299)                <= new_read_i;
--    debug_probe(300)                <= drv_done_i;
--    debug_probe(301)                <= udp_init_i;
--    debug_probe(302)                <= '0';
--    debug_probe(303)                <= RAMdone_i;
--    debug_probe(304)                <= wr_en_i;
--    debug_probe(305)                <= end_packet_i;
--    debug_probe(306)                <= init_read_i;
--    debug_probe(307)                <= got_len_i;
--    debug_probe(319 downto 308)     <= addrRAM_wr_i;
--    debug_probe(331 downto 320)     <= packLen_i;
--    debug_probe(363 downto 332)     <= dout_pf;
--    debug_probe(371 downto 364)     <= vmm_data0_vec_i;
--    debug_probe(379 downto 372)     <= vmm_data1_vec_i;
--    debug_probe(387 downto 380)     <= vmm_ckdt_vec_i;
--    debug_probe(395 downto 388)     <= vmm_cktk_vec_i;
--    debug_probe(401 downto 396)     <= pf_state_ila;
--    debug_probe(405 downto 402)     <= drv_state_ila;
--    debug_probe(413 downto 406)     <= (others => '0');

--    debug_probe(417 downto 414)     <= ro_tk_state_0_ila;
--    debug_probe(421 downto 418)     <= rd_dt_state_0_ila;

--    debug_probe(425 downto 422)     <= ro_tk_state_1_ila;
--    debug_probe(429 downto 426)     <= rd_dt_state_1_ila;

--    debug_probe(433 downto 430)     <= ro_tk_state_2_ila;
--    debug_probe(437 downto 434)     <= rd_dt_state_2_ila;

--    debug_probe(441 downto 438)     <= ro_tk_state_3_ila;
--    debug_probe(445 downto 442)     <= rd_dt_state_3_ila;

--    debug_probe(449 downto 446)     <= ro_tk_state_4_ila;
--    debug_probe(453 downto 450)     <= rd_dt_state_4_ila;

--    debug_probe(457 downto 454)     <= ro_tk_state_5_ila;
--    debug_probe(461 downto 458)     <= rd_dt_state_5_ila;

--    debug_probe(465 downto 462)     <= ro_tk_state_6_ila;
--    debug_probe(469 downto 466)     <= rd_dt_state_6_ila;

--    debug_probe(473 downto 470)     <= ro_tk_state_7_ila;
--    debug_probe(477 downto 474)     <= rd_dt_state_7_ila;
--    debug_probe(478)                <= trigger_ila_i;
--    debug_probe(486 downto 479)     <= trigger_ack_i;
--    debug_probe(518 downto 487)     <= dead_cnt_sig;
--    debug_probe(550 downto 519)     <= ram_cnt_sig;
    
    

--deadTmProc: process(clk_200, start_cnt_i)
--begin
--    if(rising_edge(clk_200))then
--        if(start_cnt_i = '1')then
--            dead_cnt <= dead_cnt + 1;
--        else
--            dead_cnt <= (others => '0');
--        end if;
--    end if;
--end process;

--ramCntProc: process(clk_200, start_cnt_ram_i)
--begin
--    if(rising_edge(clk_200))then
--        if(start_cnt_ram_i = '1')then
--            ram_cnt <= ram_cnt + 1;
--        else
--            ram_cnt <= (others => '0');
--        end if;
--    end if;
--end process;
    
--    ram_cnt_sig     <= std_logic_vector(ram_cnt);
--    dead_cnt_sig    <= std_logic_vector(dead_cnt);
   
end rtl;
