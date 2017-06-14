----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/25/2016 03:41:32 PM
-- Design Name: 
-- Module Name: classify - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity classify is
    generic(
    constant N : integer := 16
    ); 
    Port (clock : in std_logic;
    
       -- Signals from the accelerometers and the other part
          D0: in std_logic_vector (N-1 downto 0);
          D1: in std_logic_vector (N-1 downto 0);
          D2: in std_logic_vector (N-1 downto 0);
          D3: in std_logic_vector (N-1 downto 0);
          D4: in std_logic_vector (N-1 downto 0);
          D5: in std_logic_vector (N-1 downto 0);         
          reset: in std_logic;
                 
       -- Decision signal       
          Q: out std_logic     
            
           );
          end classify;

architecture Behavioral of classify is 

--------------------------------------------------
  --Temp signals for input1
    signal tmp0: std_logic_vector(0 downto 0);
    signal tmp1: std_logic_vector(0 downto 0);
    signal tmp2: std_logic_vector(0 downto 0);
  --Temp signals for input1
    signal tmp3: std_logic_vector(0 downto 0);
    signal tmp4: std_logic_vector(0 downto 0);
    signal tmp5: std_logic_vector(0 downto 0);
  --Temp signals for input1
    signal tmp6: std_logic_vector(0 downto 0);
    signal tmp7: std_logic_vector(0 downto 0);
    signal tmp8: std_logic_vector(0 downto 0);
  --Temp signals for input1
    signal tmp9: std_logic_vector(0 downto 0);
    signal tmp10: std_logic_vector(0 downto 0);
    signal tmp11: std_logic_vector(0 downto 0);
    
  --Temp signal for readiness of the data
    signal tmp12: std_logic;  
  
  --Temp decision signals
    signal tmp13: std_logic_vector(2 downto 0);
    signal tmp14: std_logic_vector(2 downto 0);
----------------------------------------------------
 
    component compare generic(
        constant N: integer := 16
        );
        port (clock: in std_logic;
              reset: in std_logic;
              D_i0: std_logic_vector (N-1 downto 0);
              Q0: out std_logic_vector(0 downto 0);
              Q1: out std_logic_vector(0 downto 0);
              out_valid: out std_logic
              );
    end component;             
------------------------------------------------------
              
    begin
   
    u1: compare 
        generic map ( N => N )
        port map (clock => clock, 
         reset => reset,
         D_i0 => D0, 
         Q0 => tmp0,
         Q1 => tmp1,
         out_valid => tmp12); 
                         
     u2: compare 
         generic map ( N => N )
         port map (clock => clock, 
         reset => reset,
         D_i0 => D1, 
         Q0 => tmp2,
         Q1 => tmp3,
         out_valid => open);
         
    u3: compare 
         generic map ( N => N )
         port map (clock => clock, 
         reset => reset,
         D_i0 => D2, 
         Q0 => tmp4,
         Q1 => tmp5,
         out_valid => open);

    u4: compare 
         generic map ( N => N )
         port map (clock => clock, 
         reset => reset,
         D_i0 => D3, 
         Q0 => tmp6,
         Q1 => tmp7,
         out_valid => open);

    u5: compare 
         generic map ( N => N )
         port map (clock => clock, 
         reset => reset,
         D_i0 => D4, 
         Q0 => tmp8,
         Q1 => tmp9,
         out_valid => open);
    
    u6: compare 
         generic map ( N => N )
         port map (clock => clock, 
         reset => reset,
         D_i0 => D5, 
         Q0 => tmp10,
         Q1 => tmp11,
         out_valid => open);
         
         
         
         
 classify: process (clock,reset)
           
           begin
           if (reset='1') then 
           tmp13 <= "000";
           tmp14 <= "000";
          
           elsif (rising_edge (clock)) then  
            if (tmp12 = '1')then
                tmp13 <= ("00"&tmp11) + ("00"&tmp9)+ ("00"&tmp9) + ("00"&tmp7) +("00"&tmp5) + ("00"&tmp3) ; -- scores for abnormal inputs
                tmp14 <= ("00"&tmp10) + ("00"&tmp8) + ("00"&tmp6) + ("00"&tmp4) + ("00"&tmp2) + ("00"&tmp0) ; -- scores for normal inputs
            else
                tmp13 <= "000";
                tmp14 <= "000";
            end if;
            
            if(tmp13 >= 4) then 
                Q <= '1'; -- Trigger PR if 4 out of 6 inputs have been abnormal for 32 clock cycles.
            else
                Q <= '0';
            end if;   
           end if; 
           end process;
    
end Behavioral;
