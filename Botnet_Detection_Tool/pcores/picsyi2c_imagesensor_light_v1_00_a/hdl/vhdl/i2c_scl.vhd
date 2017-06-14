----------------------------------------------------------------------------------
-- Module Name: I2C_SCL
-- Version: 1.0
----------------------------------------------------------------------------------
-- TODO:
--	- ...?
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;


entity i2c_scl is
	port(
		Clock		: in std_logic;
		Reset		: in std_logic;
		SCL_EN	: in std_logic;
		SCL		: out std_logic
	);
end i2c_scl;


architecture Behavioral of i2c_scl is
	type States is (high, low);

	signal c_state, n_state : States;

	signal enable : std_logic;

begin

	SCL_REG : process(Reset, Clock)
	begin
		if Reset = '1' then
			c_state <= high;
			enable <= '0';
		else
			if Clock'event and Clock = '1' then
				c_state <= n_state;
				enable <= SCL_En;
			end if;
		end if;
	end process SCL_REG;


	SCL_COMB : process(c_state, enable)
	begin
		case c_state is
			when high	=>	if enable = '1' then
										n_state <= low;
									else 
										n_state <= high;
									end if;

			when low		=>	n_state <= high;
		end case;
	end process SCL_COMB;


	SCL_OUT : process(c_state)
	begin
		case c_state is
			when high	=>	SCL <= '1';

			when low		=>	SCL <= '0';
		end case;
	end process SCL_OUT;

end Behavioral;
