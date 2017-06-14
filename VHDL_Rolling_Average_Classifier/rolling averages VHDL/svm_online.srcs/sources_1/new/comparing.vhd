----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/22/2016 04:09:23 PM
-- Design Name: 
-- Module Name: comparing - Behavioral
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
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values

    entity compare is
    generic(
    constant N : integer := 16
    ); 
    Port (clock : in std_logic;
    
       -- Signals from the accelerometers and the other part
          D_i0: in std_logic_vector (N-1 downto 0);
          reset: in std_logic;
          --D_i5: in std_logic_vector (N-1 downto 0)
          
       -- Decision signal 
          Q0: out std_logic_vector(0 downto 0);
          Q1: out std_logic_vector(0 downto 0);
          out_valid: out std_logic
          
           );
          end compare;
             
    architecture Behavioral of compare is
        
     -- Weights
          signal w0: std_logic_vector (15 downto 0);
         
     -- Mean Normal
          signal n0: std_logic_vector (15 downto 0);
                   
     -- Mean Abnormal    
          signal m0: std_logic_vector (15 downto 0);
               
     -- Temporal signals
          signal tmp: std_logic_vector (4 downto 0); -- counting to 32 signal
          signal tmp0: std_logic_vector(5 downto 0); -- temp to evaluate output 1
          signal tmp1: std_logic_vector(5 downto 0); -- temp to evaluate output 2
          signal count: std_logic_vector(4 downto 0);
         
          
    begin
    
    
 counting32: process (clock,reset)
             begin
             if (reset = '1') then 
                 tmp <= (others => '0');
             elsif (rising_edge (clock)) then 
                 tmp <= tmp + 1;
             end if;
             end process;
             count <= tmp;
            
    
 comparin:process (clock, reset)
          begin
          if (reset = '1') then 
              tmp0 <= (others => '0');
              tmp1 <= (others => '0');
              
              
          elsif(rising_edge (clock)) then      -- increase the counter if the input is normal
            if (count/=0) then
               if (D_i0 >= w0 AND n0 >= w0) then 
                   tmp0 <= tmp0 + 1;
               elsif (D_i0 <= w0 AND m0 <= w0) then 
                      tmp1 <= tmp1 + 1;
               end if;
            else -- restart the counter to 32
               if (D_i0 >= w0 AND n0 >= w0) then 
                  tmp0 <= "000001";
                  tmp1 <= "000000";
               elsif (D_i0 <= w0 AND m0 <= w0) then 
                   tmp1 <= "000001";
                    tmp0 <= "000000";
               else 
                   tmp0 <= "000000"; -- Do nothing when neither condition is realized
                   tmp1 <= "000000";
               end if;               
               end if;
              end if;                      
              end process; 
                                         
          Q0(0) <= tmp0(4);  --Q0 is 1 when the total number of ones is greater than 16 (normal inputs)
          Q1(0) <= tmp1(4);  --Q1 is 1 when the total is number of ones is greater than 16 (abnormal inputs)
          out_valid <= '1' when (count = 0) else '0'; 
                          
    end Behavioral;
