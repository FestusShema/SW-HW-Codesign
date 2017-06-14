----------------------------------------------------------------------------------
-- Module Name: SerialTopARallel
-- Version: 1.0
----------------------------------------------------------------------------------
-- TODO:
--	- ...?
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;



entity SerialTopARallel is
	generic(
		width : integer := 16
	);

	port(
		Clock		: in	std_logic;
		Reset		: in	std_logic;

		Enable	: in	std_logic;
		Serial	: in 	std_logic;

		Valid		: out	std_logic;
		Parallel	: out	std_logic_vector(width - 1 downto 0)
	);
end SerialTopARallel;



architecture Behavioral of SerialTopARallel is

	signal memory	: std_logic_vector(width - 1 downto 0);

	signal tick		: integer range 0 to (width - 1);

begin

	Parallel <= memory;

	process(Reset, Clock, Serial, Enable)
	begin
		if Reset = '1' then
			memory <= (others => '0');

			tick <= 0;

			Valid <= '0';
		else
			if Clock'event and Clock = '0' then
				if Enable = '1' then
					for i in (width - 2) downto 0 loop
						memory(i + 1) <= memory(i);
					end loop;

					memory(0) <= Serial;

					if tick = (width - 1) then
						tick <= 0;

						Valid <= '1';
					else
						tick <= tick + 1;

						Valid <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;

end Behavioral;

