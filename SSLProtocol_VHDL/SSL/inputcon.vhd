----------------------------------------------------------------------------------
-- Create Date:    12:54:01 05/01/2015 
-- Design Name: 
-- Module Name:    inputcon - Behavioral 
-- Project Name: 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity inputcon is
    Port ( clk,reset: in std_logic;
			  array_in : in  STD_LOGIC_VECTOR(0 to 63);
           array_out : out  STD_LOGIC_VECTOR (63 downto 0)
			  );
end inputcon;

architecture Behavioral of inputcon is

begin

conv: process(clk,reset)
begin
	 if(reset ='1') then
		array_out <= (others => '0');
    elsif(rising_edge(clk)) then		
      for i in 0 to 63 loop
       array_out(i) <= array_in(63-i);
      end loop;
	end if;
end process;


end Behavioral;

