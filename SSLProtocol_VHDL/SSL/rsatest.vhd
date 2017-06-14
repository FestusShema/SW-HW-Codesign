--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   12:00:23 05/01/2015
-- Design Name:   
-- Module Name:   /home/festus/Documents/SSL/SSL/rsatest.vhd
-- Project Name:  SSL
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: RSACypher_encrypt
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY rsatest IS
END rsatest;
 
ARCHITECTURE behavior OF rsatest IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT RSACypher_encrypt
    PORT(
         org_indata : IN  std_logic_vector(0 to 63);
         org_cypher : OUT  std_logic_vector(0 to 63);
         clk : IN  std_logic;
         ds : IN  std_logic;
         reset : IN  std_logic;
         ready : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal org_indata : std_logic_vector(0 to 63) := (others => '0');
   signal clk : std_logic := '0';
   signal ds : std_logic := '0';
   signal reset : std_logic := '0';

 	--Outputs
   signal org_cypher : std_logic_vector(0 to 63);
   signal ready : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: RSACypher_encrypt PORT MAP (
          org_indata => org_indata,
          org_cypher => org_cypher,
          clk => clk,
          ds => ds,
          reset => reset,
          ready => ready
        );

   -- Clock process definitions
   clk_process :process
   begin
		wait for 120ns;
		reset <= '1';
		ds <= '0';
		wait for 20ns;
		wait until clk = '0';
		reset <= '0';
		wait until clk = '1';
		wait until clk = '0';
		org_indata <= x"133457799BBCDFF1";
		wait until clk = '1';
		wait for 2ns;
		ds <= '1';
		wait until ready = '0';
		ds <= '0';
		wait until ready = '1';
		wait;
		end process;

   -- Stimulus process
  ClkGen : PROCESS
   BEGIN
      wait for 5300ps; -- will wait forever
		if clk = '1' then
			clk <= '0';
		else
			clk <= '1';
		end if;
   END PROCESS;

END;
