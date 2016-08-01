-- IEEE VHDL standard library:
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_bit.all;
use IEEE.std_logic_unsigned.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity vmm_global_reset is
	port(  clk             : in std_logic; -- 100MHz
	       rst             : in std_logic; -- reset
	       gbl_rst         : in std_logic ; -- from control register. a pulse
		   vmm_ena         : out std_logic ; -- these will be ored with same from other sm
		   vmm_wen         : out std_logic  -- these will be ored with same from other sm
		);
end vmm_global_reset ;

architecture beh of vmm_global_reset is

	signal state_switch_count : std_logic_vector(31 downto 0) := x"00010000"; --fast
	signal cfg_rst_ctr : std_logic_vector(31 downto 0) := x"00000000";


	signal state_nxt : std_logic_vector(2 downto 0) ;


	signal vmm_wen_int, vmm_ena_int : std_logic ;
	signal gbl_rst_int, done_int    : std_logic ;
	
	attribute keep: boolean;
	attribute keep of vmm_ena_int: signal is true;
	attribute keep of vmm_wen_int: signal is true;
	attribute keep of cfg_rst_ctr: signal is true;

begin

	process( clk, rst, done_int, gbl_rst, gbl_rst_int)
	begin
		if( rst = '1' or done_int = '1') then
				gbl_rst_int <= '0' ;
		else
			if( rising_edge( clk)) then  --100MHz
				if (gbl_rst = '1') then
					gbl_rst_int <= '1' ;
				end if ;
			end if ;
		end if ;
	end process ;

	process( clk, state_nxt, rst, gbl_rst_int, vmm_ena_int, vmm_wen_int)
	begin
		if ( rising_edge( clk)) then       --100MHz
			if (rst = '1') then
				state_nxt <= (others=>'0') ;
				done_int <= '0' ;
				vmm_ena_int <= '0' ;
				vmm_wen_int <= '0' ;
				cfg_rst_ctr  <= (others=>'0') ;
			else
					case state_nxt is 
						when "000" => 
										vmm_wen_int <= '0' ;
										vmm_ena_int <= '0' ;
										done_int <= '0' ;
										
										if (gbl_rst_int = '1') then
											state_nxt <= "001" ;									
                               				cfg_rst_ctr  <= (others=>'0') ;
										else	
											state_nxt <= "000" ;
										end if ;

						when "001" => 
								        vmm_ena_int <= '0' ;
									    vmm_wen_int <= '1' ;

										if (cfg_rst_ctr = state_switch_count) then
                                            state_nxt <= "010" ;                                    
                                            cfg_rst_ctr  <= (others=>'0') ;
                                        else    
                                            state_nxt <= "001" ;
                                            cfg_rst_ctr <= cfg_rst_ctr +  '1';
                                        end if ;

						when "010" =>     
									    vmm_ena_int <= '1' ;
									    vmm_wen_int <= '1' ;

										  if (cfg_rst_ctr = state_switch_count) then
                                                state_nxt <= "011" ;                                    
                                                cfg_rst_ctr  <= (others=>'0') ;
                                           else    
                                                state_nxt <= "010" ;
                                                cfg_rst_ctr <= cfg_rst_ctr +  '1';
                                           end if ;

						when "011" => 

									     vmm_ena_int <= '0' ;
									     vmm_wen_int <= '1' ;

										  if (cfg_rst_ctr = state_switch_count) then
                                                state_nxt <= "100" ;                                    
                                                cfg_rst_ctr  <= (others=>'0') ;
                                           else    
                                                state_nxt <= "011" ;
                                                cfg_rst_ctr <= cfg_rst_ctr +  '1';
                                           end if ;
                                           
						when "100" => 
						                  vmm_ena_int <= '0' ;
										  vmm_wen_int <= '0' ;
                                          state_nxt <= "000" ;                                    
    								      done_int <= '1' ;


						when others =>    vmm_ena_int <= '0' ;
										  vmm_wen_int <= '0' ;
										  done_int <= '1' ;
										  state_nxt <= (others=>'0') ;
					end case ;
			end if ;
	   end if;
	end process ;
	
	vmm_wen <= vmm_wen_int ;
	vmm_ena <= vmm_ena_int ;
	
end beh ;
