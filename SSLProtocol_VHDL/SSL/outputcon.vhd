----------------------------------------------------------------------------------
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

entity outputcon is
    Port ( clk,reset: in std_logic;
			  array_in : in  STD_LOGIC_VECTOR (63 downto 0);
           array_out : out  STD_LOGIC_VECTOR (0 to 63)
			  );
end outputcon;

architecture Behavioral of outputcon is

begin

LE_2_BE_PROC: process(clk,reset)
begin
	 if(reset ='1') then
		 array_out <= (others => '0');
    elsif(rising_edge(clk)) then		
		 for i in 63 downto 0 loop
			  array_out(63-i) <= array_in(i);
		 end loop;
	end if;
end process;



end Behavioral;

