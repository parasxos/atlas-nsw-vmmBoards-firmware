----------------------------------------------------------------------------------
-- Company: NTU ATHNENS - BNL
-- Engineer: Panagiotis Gkountoumis
-- 
-- Create Date: 18.04.2016 13:00:21
-- Design Name: 
-- Module Name: config_logic - Behavioral
-- Project Name: MMFE8 
-- Target Devices: Arix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- Changelog:
-- 02.08.2016 Added ONLY_CONF_ONCE as a state to prevent multiple configuratoins
--      of the VMM. (Reid Pinkham)
-- 16.09.2016 Added additional elsif in state = CHECK for dynamic IP configuration
-- (Lev Kurilenko)
--
----------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;

entity config_logic is
    Port ( 
        clk125              : in  std_logic;
        clk200              : in  std_logic;
        clk_in              : in  std_logic;
        
        reset               : in  std_logic;

        user_data_in        : in  std_logic_vector (7 downto 0);
        user_data_out       : out std_logic_vector (63 downto 0);

        udp_rx              : in udp_rx_type;
        resp_data           : out udp_response;

        send_error          : out std_logic;
        user_conf           : out std_logic;
        user_wr_en          : in  std_logic;
        user_last           : in  std_logic;
        configuring         : in  std_logic;
        
--        we_conf             : out std_logic;
        
        vmm_id              : out std_logic_vector(15 downto 0);
        cfg_bit_out         : out std_logic;
        VMM_SCK             : out std_logic;
        VMM_SDO             : in  std_logic;
        status              : out std_logic_vector(3 downto 0);
        
        start_vmm_conf      : in  std_logic;
        conf_done           : out std_logic;
        ext_trigger         : out std_logic;
        
        ACQ_sync            : out std_logic_vector(15 downto 0);
        
        udp_header          : in std_logic;
        packet_length       : in std_logic_vector (15 downto 0);
        VMM_CS              : out std_logic;
        ena_conf            : out std_logic;

        xadc_busy           : in std_logic;
        xadc_start          : out std_logic;
        vmm_id_xadc         : out std_logic_vector(15 downto 0);
        xadc_sample_size    : out std_logic_vector(10 downto 0);
        xadc_delay          : out std_logic_vector(17 downto 0);
        
        myIP_set            : out std_logic_vector(31 downto 0);        --Lev
        myMAC_set           : out std_logic_vector(47 downto 0);        --Lev
        destIP_set          : out std_logic_vector(31 downto 0);        --Lev
        newip_start         : out std_logic                             --Lev        
    );
end config_logic;


architecture rtl of config_logic is

    signal packet_length_int    : integer := 0;
    signal reading_packet       : std_logic := '0';
    signal user_last_int        : std_logic := '0';
    signal count, timeout       : integer := 0;
    signal last_synced200       : std_logic := '0';
    signal i,w,del_cnt          : integer := 0;
    signal del_cnt2             : integer := 0;
    signal counter, k, j        : integer := 0;
    signal sig_out              : std_logic_vector(292 downto 0);
    signal sn                   : std_logic_vector(31 downto 0);
    signal vmm_id_int           : std_logic_vector(15 downto 0);
    signal cmd                  : std_logic_vector(15 downto 0);
    signal user_data_in_int     : std_logic_vector(7 downto 0);
    signal status_int           : std_logic_vector(3 downto 0);
    signal user_wr_en_int       : std_logic := '0';
    signal cfg_bit_out_i        : std_logic := '0';
    signal VMM_SCK_i           : std_logic := '0';
    signal start_conf_process   : std_logic := '0';
    signal conf_done_i          : std_logic := '0';
    signal cnt_array, cnt_pause : integer := 0;    
    signal MainFSMstate         : std_logic_vector(3 downto 0); 
    signal ConfFSMstate         : std_logic_vector(3 downto 0); 
    signal test_data_int        : std_logic_vector(31 downto 0);    
    signal delay_data           : std_logic_vector(7 downto 0);    
    signal udp_header_int       : std_logic := '0';
    signal cs_int               : std_logic := '1';
    signal VMM_SDO_i            : std_logic := '0';
    
    
    type data_buffer is array(0 to 60) of std_logic_vector(31 downto 0);
    signal conf_data            : data_buffer;
    
    signal reply_package        : std_logic_vector(63 downto 0);  
    signal udp_response_int     : udp_response;
    signal start_vmm_conf_int   : std_logic := '0';
    signal start_vmm_conf_synced   : std_logic := '0';
--    signal we_conf_int          : std_logic := '0';
    signal vmm_we_int          : std_logic := '0';
    signal cnt_cktk            : integer := 0;
    signal DAQ_START_STOP      : std_logic_vector(31 downto 0);
    signal dest_port           : std_logic_vector(15 downto 0);
    signal data_length         : integer := 0;
    signal cnt_reply           : integer := 0;
    signal cnt_conf_18         : integer := 0;
    signal cnt_conf_96         : integer := 0;
    signal delay_user_last     : std_logic := '0';
    signal ena_conf_i          : std_logic := '1';
    signal ERROR               : std_logic_vector(15 downto 0);

    signal vmm_id_xadc_i        : std_logic_vector(15 downto 0);
    signal xadc_sample_size_i   : std_logic_vector(10 downto 0);
    signal xadc_delay_i         : std_logic_vector(17 downto 0);
    
    -----------------------------------------------------------
    --                  IP Signal LEV
    signal newip_counter        : integer := 0;         --Lev
    -----------------------------------------------------------
    
    type tx_state is (IDLE, SerialNo, VMMID, COMMAND, DATA, CHECK, VMM_CONF, DELAY, FPGA_CONF, XADC_Init, XADC, SEND_REPLY, TEST, REPLY);
    signal state     : tx_state;  
    
    type state_t is (START, SEND1,SEND0, PAUSE_ONE, FINISHED, ONLY_CONF_ONCE);
    signal conf_state  : state_t; 

    attribute keep : string;
    attribute dont_touch : string;
    attribute keep of sn                          : signal is "true";
    attribute keep of vmm_id_int                  : signal is "true";
    attribute keep of user_last_int               : signal is "true";    
    attribute keep of cmd                         : signal is "true";
    attribute keep of count                       : signal is "true";
    attribute keep of last_synced200              : signal is "true";
    attribute keep of reading_packet              : signal is "true";
    attribute keep of user_data_in_int            : signal is "true";
    attribute keep of user_wr_en_int              : signal is "true";   
    attribute keep of packet_length_int           : signal is "true";
    attribute keep of cfg_bit_out_i               : signal is "true";  
    attribute keep of status_int                  : signal is "true";
    attribute keep of start_conf_process          : signal is "true";
    attribute keep of conf_done_i                 : signal is "true";
    attribute keep of cnt_array                   : signal is "true";
    
    attribute keep of DAQ_START_STOP                  : signal is "true";
    attribute dont_touch of DAQ_START_STOP            : signal is "true";    
    
    attribute keep of user_wr_en                  : signal is "true";
    attribute dont_touch of user_wr_en            : signal is "true";      
     
    attribute keep of MainFSMstate                : signal is "true";
    attribute keep of ConfFSMstate                : signal is "true";
    attribute keep of test_data_int               : signal is "true";   
    attribute keep of delay_data                  : signal is "true"; 
    attribute keep of i                           : signal is "true";
    attribute keep of VMM_SCK_i                  : signal is "true";
    attribute keep of udp_header_int              : signal is "true"; 
    attribute keep of j                           : signal is "true";     
    attribute keep of start_vmm_conf_int          : signal is "true";   
    attribute keep of start_vmm_conf_synced       : signal is "true";
    attribute keep of dest_port                   : signal is "true";
    attribute keep of cnt_conf_18                 : signal is "true";
    attribute keep of cnt_conf_96                 : signal is "true";
    
    
--    attribute keep of vmm_id_xadc_i               : signal is "true";
--    attribute keep of xadc_sample_size_i          : signal is "true";
--    attribute keep of xadc_delay_i                : signal is "true";
    
--    attribute keep of vmm_we_int                      : signal is "true";
--    attribute dont_touch of vmm_we_int                : signal is "true";  
    
    attribute keep of cnt_cktk                      : signal is "true";
    attribute dont_touch of cnt_cktk                : signal is "true";      

    attribute keep of k                         : signal is "true";
    attribute dont_touch of k                   : signal is "true"; 
    
    attribute keep of cs_int                      : signal is "true";
    attribute dont_touch of cs_int                : signal is "true";     
    
    attribute keep of counter                      : signal is "true";
    attribute dont_touch of counter                : signal is "true";       
    
    attribute keep of del_cnt                      : signal is "true";
    attribute dont_touch of del_cnt                : signal is "true"; 
    
    attribute keep of VMM_SDO_i                      : signal is "true";
    attribute dont_touch of VMM_SDO_i                : signal is "true";
    
    attribute keep of ena_conf_i                      : signal is "true";
    attribute dont_touch of ena_conf_i                : signal is "true";
    
   
  
    component ila_user_FIFO IS
        PORT (
            clk         : IN std_logic;
            probe0      : IN std_logic_vector(292 DOWNTO 0)
        );
    end component;    

     -----------------------------------------------------------
    --                  NEW IP Signals LEV
    -----------------------------------------------------------  
    --attribute keep of conf_data                       : signal is "true";   --Lev
    attribute keep of newip_counter                   : signal is "true";   --Lev
    attribute keep of myIP_set                        : signal is "true";   --Lev
    attribute keep of myMAC_set                       : signal is "true";   --Lev
    attribute keep of destIP_set                      : signal is "true";   --Lev


begin

 process (clk125)
    begin
    if clk125'event and clk125 = '1' then
        user_wr_en_int      <= user_wr_en;
        delay_data          <= user_data_in;
        delay_user_last    <= user_last;
    end if;
 end process;

    user_last_int    <= user_last;

    user_data_in_int <= user_data_in;
    
--synced_to_125: process(clk125) 
--        begin
--        if rising_edge(clk125) then
--            start_vmm_conf_synced       <= start_vmm_conf_int;
--        end if;
--    end process;    
    
------------------------  IDLE          0000
------------------------  VMM_CONF      0001
------------------------  XADC          0010    
------------------------  RESET FPGA    0011                                        
------------------------  DAQ OFF       1000
------------------------  FPGA_CONF     1001        
------------------------  REPLY         1011
------------------------  DAQ ON        1111


    process (clk125, state, configuring, cmd, reading_packet, count, packet_length_int, user_wr_en_int, last_synced200, user_wr_en, dest_port)
--    variable i : natural range 0 to 10 := 0; --1ms
    begin
        if clk125'event and clk125 = '1' then	
          if reset = '1' then 
            state   <= IDLE;
          else
            case state is
                when IDLE =>            
                    MainFSMstate    <= "0000";
                    status_int      <= "0000";  
                    count           <= 0;
                    j               <= 3;
                    cnt_array       <= 0;
                    sn              <= (others=> '0');
                    vmm_id_int      <= x"0000";
                    cmd             <= x"0000";
--                    cs_int              <= '1';
                    
                    if user_wr_en = '1' then
                        state   <= DATA;
                    end if;
                    
                when DATA =>
                    MainFSMstate        <= "0001";
                    if j = 0 then 
                        cnt_array       <= cnt_array + 1;  
                        conf_data(cnt_array)(8*j+ 7 downto 8*j) <= delay_data; 
                        j <= 3;
                    else                        
                        conf_data(cnt_array)(8*j+ 7 downto 8*j) <= delay_data; 
                        j   <= j - 1;
                    end if;
                     
                    if delay_user_last = '1' then               
--                        cnt_array   <= 0;
--                        count       <= 4;
                        j           <= 0;
                        state       <= SerialNo;
                    end if;          
                    
                when SerialNo =>
                    MainFSMstate        <= "0010";
--                    count   <= count - 1;
                    sn <= conf_data(0);
                    reply_package(63 downto 32)     <= sn;
                    state <= VMMID;
                    
                when VMMID =>  
                    MainFSMstate    <= "0011";
                    vmm_id_int <= conf_data(1)(31 downto 16);  
                    packet_length_int <= to_integer(unsigned(packet_length)); 
                    data_length         <= packet_length_int - 8;
                    reply_package(31 downto 16)     <= vmm_id_int;
                    state <= COMMAND;
                when COMMAND =>
                    MainFSMstate        <= "0100";       
                    cmd <= conf_data(1)(15 downto 0);                    
                    reply_package(15 downto 0)     <= cmd;
                    state <= CHECK;
                    
                when CHECK =>
                    MainFSMstate        <= "0101";
                    
                    if dest_port = x"1778"  then              -- 6008 VMM CONFIGURATION
                         state <= VMM_CONF;
--                         if vmm_id_int /= x"ffff" then
                            status_int  <= "0001";
--                         else
--                            status_int  <= "0010";
--                         end if;
                    elsif dest_port = x"19C8" or dest_port = x"1777" then           -- 6600 FPGA CONFIGURATION
                        cmd         <= conf_data(1)(31 downto 16);
                        vmm_id_int  <= conf_data(1)(15 downto 0); 
                        state <= FPGA_CONF;
                        status_int  <= "1001";   
                        count   <= 0;
                    elsif dest_port = x"19CC" then          -- 6604 Flash Configuration     --Lev
                        -- wait a few clock cycles to initatiate New IP Set                 --Lev
                        -- wait around 10 clock cycles                                      --Lev
                        newip_start   <= '1';                                               --Lev
                        newip_counter <= newip_counter + 1;                                 --Lev
                        myIP_set                    <= conf_data(2)(31 downto 0);           --Lev
                        myMAC_set(47 downto 32)    <= conf_data(3)(15 downto 0);            --Lev
                        myMAC_set(31 downto 0)     <= conf_data(4)(31 downto 0);            --Lev
                        destIP_set                  <= conf_data(5)(31 downto 0);           --Lev
                        
                        if (newip_counter = 10) then
                            newip_counter       <= 0;
                            newip_start         <= '0';
                            state               <= IDLE;
                        end if;
                    elsif dest_port = x"19D0"  then           -- 6608 XADC
                        state               <= XADC_Init;
                        status_int          <= "0100";
                        xadc_start          <= '1';
                        
                        if cnt_array > 0 then -- If it is not an empty packet
                            vmm_id_xadc_i       <= conf_data(0)(15 downto 0);
                            xadc_sample_size_i  <= conf_data(1)(10 downto 0);
                            xadc_delay_i        <= conf_data(2)(17 downto 0);
                        else -- is an empty packet
                            vmm_id_xadc_i       <= "0000000000000000";
                            xadc_sample_size_i  <= "01111111111"; -- 1023 packets
                            xadc_delay_i        <= "011111111111111111"; -- 1023 samples over ~0.7 seconds
                        end if;
                    else
                        count <= 0; 
                        state <= IDLE;
                    end if;
                    
                when VMM_CONF =>             
                    MainFSMstate        <= "0110";   
                    
                    if timeout = 5000000 then
                        state   <= IDLE;
                        timeout <= 0;
                        ERROR   <= x"ffff";
                    else
                        timeout <= timeout + 1;
                    end if;        
                                
                    if conf_done_i = '1' then 
--                        user_data_out   <= reply_package;
                        state           <= DELAY;-- SEND_REPLY;   
--                        reading_packet  <= '0';
                        ERROR   <= x"0000";
                        status_int      <= "1011";
                    end if;    
                    
                when DELAY  =>
                   if del_cnt2 = 10 then
                        state         <= REPLY;
                        del_cnt2   <= 0;
                   else
                        del_cnt2   <= del_cnt2 + 1;
                   end if;    
                
                when XADC_Init => -- Initialize the XADC
                    MainFSMstate        <= "0111";
                    state               <= XADC;
                    xadc_start          <= '0';

                when XADC => --Main XADC State
                    if (xadc_busy = '0') then -- if xadc is done
                        state           <= IDLE;
                    else
                        state           <= XADC;
                    end if;
                
                when FPGA_CONF =>
                    MainFSMstate        <= "1011";
--                    DAQ_START_STOP  <= conf_data(count+2);
                    
-------------------------------------set this for the real configuration                    
--                    if count*8 <= data_length then
                                             
--                        if conf_data(count + 2) = x"00000000" and conf_data(count + 3) = x"00000004" then           -- EXTERNAL
--                             ext_trigger    <= '1';
--                        elsif conf_data(count + 2) = x"00000000" and conf_data(count + 3) = x"00000007" then        -- PULSER
--                             ext_trigger    <= '0';
--                        elsif conf_data(count + 2) = x"00001111" and conf_data(count + 3) = x"00000001" then        -- DAQ ON
--                             status_int  <= "1111";
--                        elsif conf_data(count + 2) = x"00001111" and conf_data(count + 3) = x"00000000" then        -- DAQ OFF
--                            status_int  <= "1000";
--                        elsif conf_data(count + 2) = x"ffffffff" and conf_data(count + 3) = x"ffff8000" then        -- RESET FPGA
--                            status_int  <= "0011";
--                        else
--                            state   <= IDLE;
--                        end if;

--                  else
--                    count   <= 0;
--                    state   <= IDLE;

--                  end if;
-------------------------------------set this for the real configuration                    
                DAQ_START_STOP  <= conf_data(4);                    
                   
                    if conf_data(5) = x"00000004" and conf_data(4) = x"00000000" then           -- EXTERNAL
                         ext_trigger    <= '1';
                         state   <= TEST;
                    elsif conf_data(5) = x"00000007" and conf_data(4) = x"00000000" then        -- PULSER
                         ext_trigger    <= '0';
                         state   <= TEST;
                    elsif conf_data(5) = x"00000001" and conf_data(4) = x"0000000f" then        -- DAQ ON
                         status_int  <= "1111";
                         state   <= TEST;
                    elsif conf_data(5) = x"00000000" and conf_data(4) = x"0000000f" then        -- DAQ OFF
                        status_int  <= "1000";
                        state   <= TEST;
                    elsif conf_data(4) = x"ffffffff" and conf_data(5) = x"ffff8000" then        -- RESET FPGA
                        status_int  <= "0011";
                        state   <= IDLE;
                    elsif conf_data(4) = x"00000005" then
                        ACQ_sync    <= conf_data(5)(15 downto 0);
                        state       <= IDLE;
                else
                    state   <= TEST;
                end if;
                
                when TEST =>
                    if count < 10 then
                        DAQ_START_STOP  <= conf_data(count);
                        count <= count + 1; 
                    else
                        count <= 0;
                        state   <= IDLE;
                    end if;
               when REPLY => 
                    state   <= IDLE;
                    

--                    if cnt_reply = 0 then
----                        user_data_out_i <= conf_data_out_i;
--                        user_data_out   <= reply_package;
--                        cnt_reply   <= cnt_reply + 1;
--                    elsif cnt_reply = 1 then
--                        user_data_out_i <= (others => '0');
--                        cnt_reply   <= cnt_reply + 1;
--                        end_packet_conf_int <= '1';
--                        we_conf_int     <= '0';
--                    elsif cnt_reply > 1 and cnt_reply < 100 then
--                        cnt_reply   <= cnt_reply + 1;
--                    else
--                        cnt_reply           <= 0;
--                        state               <= IDLE;
----                        state               <= DAQ_INIT;
--                        end_packet_conf_int <= '1';
--                    end if;


                    
               when others =>    
            end case;
	    end if;
	  end if;
    end process;
           
        
--synced_to_clkin: process(clk_in) 
--            begin
--            if rising_edge(clk_in) then
--                start_vmm_conf_synced       <= start_vmm_conf;
--            end if;
--        end process;    
        
sync_start_vmm_conf: process(clk200) 
        begin
        if rising_edge(clk200) then
            if start_vmm_conf = '1' then
                start_vmm_conf_synced   <= '1';
            end if;
             
            if w = 40 then
                start_vmm_conf_synced       <= '0';
                w   <= 0;
            else
                w   <= w + 1;
            end if;
        end if;
    end process;            
        
   config_vmm_fsm : process( clk_in, conf_state, k, i, counter, del_cnt)
       begin
       
       if rising_edge( clk_in) then
        if reset = '1' or status_int = "0011" then
            conf_state   <= START;
        else
               case conf_state is
                   when START =>
                   
                        ConfFSMstate    <= "0001";
                        cnt_conf_96     <= 0;
                        cnt_conf_18     <= 0;
                        cs_int          <= '1';
                        counter         <= 1728;
                        i               <= 31; 
                        k               <= 2;
                        cfg_bit_out_i   <= '0'; 
                        VMM_SCK_i       <= '0';
                        test_data_int   <= conf_data(k);
                        conf_done_i     <= '0';
                        
                        if start_vmm_conf = '1' then
                            conf_state  <= SEND0; 
                            cs_int      <= '0';
                            ena_conf_i    <= '0';
                        end if;
                        
                   when SEND0 =>
                   
                      ConfFSMstate        <= "0010";
                       VMM_SCK_i         <= '1';
                       cnt_cktk           <= cnt_cktk + 1;

                       if cnt_conf_96 < 96 then
                            cnt_conf_96  <= cnt_conf_96 + 1;
                            conf_state          <= SEND1;  
                       else
                          cnt_conf_96  <= 0;
                          conf_state   <= PAUSE_ONE;
                          VMM_SCK_i    <= '0';
                          cnt_conf_18  <= cnt_conf_18 + 1;
                          cs_int       <= '1';
                       end if;     
                 
                       if cnt_conf_18  = 18 then
                            conf_state           <= FINISHED;
                       end if;
                  

                       if k <= packet_length_int - 1 then 
                            test_data_int       <= conf_data(k);
                            
                            if i /= 0 then
                                cfg_bit_out_i          <= conf_data(k)(i);--(0);
                                i  <= i - 1;
                            else
                                cfg_bit_out_i          <= conf_data(k)(0);
                                k   <= k + 1;
                                i   <= 31;
                            end if;                                           
                        end if;                                  
                                          
                    when SEND1 =>     
                    
                        if cnt_conf_96 = 0 then
                            cs_int        <= '0';
                        end if;
         
                        ConfFSMstate        <= "0011";
                        VMM_SCK_i <= '0';
                        
                        if (counter - 2) >= 0 then
                            if cnt_conf_96 /= 96 then
                                counter              <= counter - 1;
                            end if;
                            
                           conf_state           <= SEND0;
                        else
                           conf_state           <= FINISHED;
                        end if;     
                                  
                    when PAUSE_ONE =>
                        ConfFSMstate    <= "1111";
                        VMM_SCK_i       <= '0';
                        cfg_bit_out_i   <= '0';
                        i               <= 31;
                        
                        if cnt_pause = 10 then
                            conf_state  <= SEND1; 
                            cnt_pause   <= 0; 
                        else
                            cnt_pause   <= cnt_pause + 1;
                        end if; 
                                                 
                    when FINISHED =>           
                        cnt_conf_96     <= 0;
                        cnt_conf_18     <= 0;
                        cs_int          <= '0';
                        ena_conf_i      <= '1';
                        ConfFSMstate    <= "0100";            
                        cfg_bit_out_i   <= '0';
                        
                        if del_cnt = 5 then
                            conf_done_i <= '1';
                            del_cnt     <= del_cnt + 1;
                        elsif  del_cnt = 100 then
                            conf_state  <= ONLY_CONF_ONCE;
                            del_cnt     <= 0;
                        else
                            del_cnt     <= del_cnt + 1;
                        end if;

                       VMM_SCK_i        <= '0';
                       counter          <= 0;
                       cs_int           <= '1';
                       cnt_cktk         <= 0;
                       
                   when ONLY_CONF_ONCE =>
                        ConfFSMstate        <= "0101";
                        if (start_vmm_conf = '0') then
                            conf_state <= START;
                        else
                            conf_state <= ONLY_CONF_ONCE;
                        end if;
               end case;
           end if;
        end if;
       end process config_vmm_fsm ;             
     

  start_vmm_conf_int    <= start_vmm_conf;  
  vmm_id                <= vmm_id_int;
  dest_port             <= udp_rx.hdr.dst_port;
  vmm_id_xadc           <=vmm_id_xadc_i;
  xadc_sample_size      <= xadc_sample_size_i;
  xadc_delay            <= xadc_delay_i;

       

    status          <= status_int;   
    conf_done       <= conf_done_i; 
    cfg_bit_out     <= cfg_bit_out_i;
    VMM_SCK         <= VMM_SCK_i;     
    
--    ila_conf_logic :  ila_user_FIFO
--        port map(
--              clk         => clk125,
--              probe0      => sig_out 
--        );              
                     

--we_conf     <= we_conf_int;

--vmm_we_int  <= vmm_we;
    VMM_CS      <= cs_int;
    VMM_SDO_i   <= VMM_SDO;
    ena_conf    <= ena_conf_i;
                         
sig_out(7 downto 0)         <= delay_data;     
sig_out(8)                  <= start_vmm_conf_int;--user_fifo_empty;
sig_out(9)                  <= start_vmm_conf_synced;--user_fifo_en_main;--'0'; --user_fifo_en;
sig_out(10)                 <= udp_header_int;--send_error_int;
sig_out(11)                 <= user_wr_en;
sig_out(43 downto 12)       <= sn;
sig_out(59 downto 44)       <= vmm_id_int;
sig_out(75 downto 60)       <= cmd;
sig_out(83 downto 76)       <= std_logic_vector(to_unsigned(count, sig_out(83 downto 76)'length));
sig_out(91 downto 84)      <= std_logic_vector(to_unsigned(cnt_array, 8));   
sig_out(92)                <= user_last_int;
sig_out(93)                <= last_synced200;
--sig_out(110)                <= reading_packet;
sig_out(101 downto 94)     <= user_data_in_int;
sig_out(102)                <= user_wr_en_int;
sig_out(103)                <= VMM_SCK_i;--user_conf_int;
sig_out(104)                <= cfg_bit_out_i;--reset_fifo_int;
sig_out(112 downto 105)     <= std_logic_vector(to_unsigned(packet_length_int, sig_out(112 downto 105)'length));
sig_out(113)                <= conf_done_i;--configuring_int;
sig_out(117 downto 114)     <= status_int;
sig_out(118)                <= start_conf_process;
sig_out(122 downto 119)     <= MainFSMstate;
sig_out(126 downto 123)     <= ConfFSMstate;
sig_out(134 downto 127)     <= std_logic_vector(to_unsigned(i, sig_out(135 downto 128)'length));

sig_out(166 downto 135)     <= test_data_int;
sig_out(174 downto 167)     <= std_logic_vector(to_unsigned(j, sig_out(175 downto 168)'length));
sig_out(190 downto 175)     <= std_logic_vector(to_unsigned(counter, sig_out(190 downto 175)'length));

sig_out(198 downto 191)     <= std_logic_vector(to_unsigned(k, sig_out(198 downto 191)'length));
sig_out(214 downto 199)     <= dest_port;

sig_out(246 downto 215)     <= DAQ_START_STOP;
sig_out(247)                <= cs_int;
sig_out(255 downto 248)     <= std_logic_vector(to_unsigned(cnt_conf_18, sig_out(255 downto 248)'length));
sig_out(263 downto 256)     <= std_logic_vector(to_unsigned(cnt_conf_96, sig_out(255 downto 248)'length));
sig_out(264)                <= VMM_SDO_i;
sig_out(265)                <= ena_conf_i;

--sig_out(262 downto 247)     <= vmm_id_xadc_i;
--sig_out(273 downto 263)     <= xadc_sample_size_i;
--sig_out(291 downto 274)     <= xadc_delay_i;



sig_out(292 downto 266)     <= (others => '0');                 

end rtl;
