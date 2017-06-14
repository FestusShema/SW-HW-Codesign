--------------------------------------------------------------------------------

-- Create Date:   10:27:47 05/01/2015
-- Design Name:   
-- Module Name:   /home/festus/Documents/SSL/SSL/ssl_test.vhd
-- Project Name:  SSL
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY ssl_test IS
END ssl_test;
 
ARCHITECTURE behavior OF ssl_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT SSL
    PORT(
         des_key : IN  std_logic_vector(0 to 63);
         clk : IN  std_logic;
         des_data : IN  std_logic_vector(0 to 63);
         outdata : OUT  std_logic_vector(0 to 63);
         outready : OUT  std_logic;
         reset : IN  std_logic;
         ds : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal des_key : std_logic_vector(0 to 63) := (others => '0');
   signal clk : std_logic := '0';
   signal des_data : std_logic_vector(0 to 63) := (others => '0');
   signal reset : std_logic := '0';
   signal ds : std_logic := '0';

 	--Outputs
   signal outdata : std_logic_vector(0 to 63);
   signal outready : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: SSL PORT MAP (
          des_key => des_key,
          clk => clk,
          des_data => des_data,
          outdata => outdata,
          outready => outready,
          reset => reset,
          ds => ds
        );

   -- Clock process definitions
   
	clkgen: process
	begin
		wait for 3550ps;
		if clk = '1' then
			clk <= '0';
		else
			clk <= '1';
		end if;
	end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      wait for 120ns;
		reset <= '1';
		ds <= '0';
		wait for 20ns;
		wait until clk = '0';
		reset <= '0';
		wait until clk = '1';
		wait until clk = '0';
		des_key <= x"133457799BBCDFF1";
		des_data <= x"c1a816541e1ef454";
		wait until clk = '1';
		wait for 2ns;
		ds <= '1';
		wait until outready = '0';
		ds <= '0';
		wait until outready = '1';
		wait;
   end process;

END;
