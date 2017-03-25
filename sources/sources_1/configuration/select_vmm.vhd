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
-- Changelog:
-- 30.01.2016 Changed the process to make it asynchronous (Christos Bakalis)
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity select_vmm is
    Port (
        clk_in              : in  std_logic;
        vmm_id              : in  std_logic_vector(15 downto 0);
        
        conf_di             : in  std_logic;
        conf_di_vec         : out  std_logic_vector(8 downto 1);
                
        conf_do             : out  std_logic;                
        conf_do_vec         : in std_logic_vector(8 downto 1);
        
        cktk_out            : in  std_logic;
        cktk_out_vec        : out std_logic_vector(8 downto 1);
        
        conf_wen            : in  std_logic;
        conf_wen_vec        : out std_logic_vector(8 downto 1);
        
        conf_ena            : in  std_logic;
        conf_ena_vec        : out std_logic_vector(8 downto 1)
    );
end select_vmm;

architecture Behavioral of select_vmm is

begin
    fill_fifo : process(vmm_id, conf_wen, cktk_out, conf_ena, conf_do_vec, conf_di)
    begin
    case vmm_id is
    when x"0001" =>
        conf_wen_vec(1)     <= conf_wen;
        cktk_out_vec(1)     <= cktk_out;
        conf_ena_vec(1)     <= conf_ena;
        conf_do             <= conf_do_vec(1);
        conf_di_vec(1)      <= conf_di;
    when x"0002" =>
        conf_wen_vec(2)     <= conf_wen;
        cktk_out_vec(2)     <= cktk_out;
        conf_ena_vec(2)     <= conf_ena;
        conf_do             <= conf_do_vec(2);
        conf_di_vec(2)      <= conf_di;
    when x"0003" =>                            
        conf_wen_vec(3)     <= conf_wen;
        cktk_out_vec(3)     <= cktk_out;
        conf_ena_vec(3)     <= conf_ena;
        conf_do             <= conf_do_vec(3);
        conf_di_vec(3)      <= conf_di;
    when x"0004" =>         
        conf_wen_vec(4)     <= conf_wen;
        cktk_out_vec(4)     <= cktk_out;
        conf_ena_vec(4)     <= conf_ena;
        conf_do             <= conf_do_vec(4);
        conf_di_vec(4)      <= conf_di;
    when x"0005" =>                            
        conf_wen_vec(5)     <= conf_wen;
        cktk_out_vec(5)     <= cktk_out;
        conf_ena_vec(5)     <= conf_ena;
        conf_do             <= conf_do_vec(5);
        conf_di_vec(5)      <= conf_di;
    when x"0006" =>                      
        conf_wen_vec(6)     <= conf_wen;
        cktk_out_vec(6)     <= cktk_out;
        conf_ena_vec(6)     <= conf_ena;
        conf_do             <= conf_do_vec(6);
        conf_di_vec(6)      <= conf_di;
    when x"0007" =>                            
        conf_wen_vec(7)     <= conf_wen;
        cktk_out_vec(7)     <= cktk_out;
        conf_ena_vec(7)     <= conf_ena;
        conf_do             <= conf_do_vec(7);
        conf_di_vec(7)      <= conf_di;
    when x"0008" =>         
        conf_wen_vec(8)     <= conf_wen;
        cktk_out_vec(8)     <= cktk_out;
        conf_ena_vec(8)     <= conf_ena;
        conf_do             <= conf_do_vec(8);
        conf_di_vec(8)      <= conf_di;
    when others =>                            
        conf_wen_vec        <= (others => '0');
        cktk_out_vec        <= (others => '0');
        conf_ena_vec        <= (others => '0');
        conf_di_vec         <= (others => '0');
    end case;    
    end process;
end Behavioral;
