
-- VHDL Test Bench Created from source file encrypt.vhd -- 02:44:54 01/24/2003
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends 
-- that these types always be used for the top-level I/O of a design in order 
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY testbench IS
END testbench; 

ARCHITECTURE behavior OF testbench IS 

	COMPONENT des56
    Port ( indata : in std_logic_vector(0 to 63);
           inkey : in std_logic_vector(0 to 63);
           outdata : out std_logic_vector(0 to 63);
	   decipher: in std_logic_vector(0 to 63);
           ds : in std_logic;
           clk : in std_logic;
			  rst : in std_logic;
           rdy : out std_logic);
	END COMPONENT;

	SIGNAL ikey :  std_logic_vector(0 to 63);
	SIGNAL imsg0 :  std_logic_vector(0 to 63);
	SIGNAL odata :  std_logic_vector(0 to 63);
	signal dec: std_logic_vector(0 to 63);
	signal ds, clk, reset, ready: std_logic;

BEGIN

	uut: des56 PORT MAP(
		indata => imsg0,
      inkey => ikey,
      outdata => odata,
		decipher => dec,
      ds => ds,
      clk => clk,
		rst => reset,
      rdy => ready);



-- *** Test Bench - User Defined Section ***
   tb : PROCESS
   BEGIN
		wait for 100ns;
		reset <= '1';
		dec <= x"133457799BBCDFF0"; -- Since the first bit is '1', the operation is decryption. If you change it to '0', the op changes to encryption.
		ds <= '0';
		wait until clk = '0';
		reset <= '0';
		wait for 5ns;
--		wait until ready = '1';
--		wait until clk = '1';
		ikey <= x"133457799BBCDFF1"; -- Some random key to test. You need same key for encry/decry
		imsg0 <= x"c1a816541e1ef454"; -- Some random data to test
		wait for 7ns;
		ds <= '1';
--		wait until clk = '1';
		wait until ready = '0';
		ds <= '0';
--		wait until ready = '0';
--		wait until clk = '0';
--		wait for 5ns;
-- ----------------------------------
		ikey <= x"0E329232EA6D0D73";
		imsg0 <= x"8787878787878787";
		wait until ready = '1';
		ds <= '1';
		wait until ready = '0';
		ds <= '0';
--		wait until clk = '0';
--		wait for 4ns;
-- ----------------------------------
		imsg0 <= x"596F7572206C6970";
		wait until ready = '1';
		ds <= '1';
		wait until ready = '0';
		ds <= '0';
--		wait until ready = '1';
--		wait until clk = '0';
--		wait for 3ns;
-- ----------------------------------
		imsg0 <= x"732061726520736D";
		wait until ready = '1';
		ds <= '1';
		wait until ready = '0';
		ds <= '0';
--		wait until ready = '1';
--		wait until clk = '0';
--		wait for 2ns;
-- ----------------------------------
		imsg0 <= x"6F6F746865722074";
		wait until ready = '1';
		ds <= '1';
		wait until ready = '0';
		ds <= '0';
--		wait until ready = '1';
--		wait until clk = '0';
--		wait for 1ns;
-- ----------------------------------
		wait until ready = '1';
		imsg0 <= x"68616E2076617365";
		ds <= '1';
		wait until ready = '0';
		ds <= '0';
--		wait until ready = '1';
--		wait until clk = '0';
		wait for 25ns;
-- ----------------------------------
		imsg0 <= x"6C696E650D0A0000";
		wait until ready = '1';
		ds <= '1';
		wait until ready = '0';
		ds <= '0';
--		wait until ready = '1';
--		wait until clk = '0';
--		wait for 25ns;
-- ----------------------------------
		imsg0 <= x"8787878787878787";
		wait until ready = '1';
		ds <= '1';
		wait until ready = '0';
		ds <= '0';
--		wait until ready = '1';
--		wait until clk = '0';
		wait;
-- ----------------------------------

   END PROCESS;

	clkgen: process
	begin
		wait for 3550ps;
		if clk = '1' then
			clk <= '0';
		else
			clk <= '1';
		end if;
	end process;
-- *** End Test Bench - User Defined Section ***

END;
