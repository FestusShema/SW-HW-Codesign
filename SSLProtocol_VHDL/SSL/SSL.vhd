----------------------------------------------------------------------------------
-- Create Date:    21:08:25 04/30/2015 
-- Design Name: 
-- Module Name:    SSL - Behavioral  
-- Description: 

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

entity SSL is
    Port ( des_key : in  std_logic_vector(0 to 63);
           clk : in  STD_LOGIC;
			  des_data : in  std_logic_vector(0 to 63);
           outdata : out  std_logic_vector(0 to 63);
			  outready : out  STD_LOGIC;
           reset : in  STD_LOGIC; 
           ds : in  STD_LOGIC);
end SSL;

architecture Behavioral of SSL is
------------------------------------------------------
--1. DECLARE TEMPORAL SIGNALS
signal rsa_encrypt_out: std_logic_vector(63 downto 0);
signal rsa_decrypt_out: std_logic_vector(63 downto 0);
signal des56_encrypt_out : std_logic_vector(0 to 63);
signal des56_decrypt_out:  std_logic_vector(0 to 63);
signal des_key_temp: std_logic_vector(63 downto 0);
signal rsa_decrypt_out_temp : std_logic_vector(0 to 63); 

 
------------------------------------------------------
--2. CALL CRYPTOFUNCTIONS RSA-64bit and DES-64bit
------------------------------------------------------

COMPONENT RSACypher_encrypt
	PORT(
		indata : IN std_logic_vector(63 downto 0);
		clk : IN std_logic;
		ds : IN std_logic;
		reset : IN std_logic;          
		cypher : OUT std_logic_vector(63 downto 0 );
		ready : OUT std_logic
		);
	END COMPONENT;
	
COMPONENT rsacypher_decrypt
	PORT(
		indata : IN std_logic_vector(63 downto 0);
		clk : IN std_logic;
		ds : IN std_logic;
		reset : IN std_logic;          
		cypher : OUT std_logic_vector(63 downto 0);
		ready : OUT std_logic
		);
	END COMPONENT;
		
COMPONENT des56_decrypt
	PORT(
		indata         : IN     std_logic_vector (0 TO 63);
		inkey          : IN     std_logic_vector (0 TO 63);
      outdata        : OUT    std_logic_vector (0 TO 63);
      ds             : IN     std_logic;
      clk            : IN     std_logic;
      rst            : IN     std_logic;
      rdy_next_next_cycle : OUT    std_logic;	-- output will be ready in two clock cycles - optional signal
      rdy_next_cycle : OUT    std_logic;      -- output will be ready in one clock cycle - optional signal
      rdy            : OUT    std_logic  -- output is ready NOW
		);
	END COMPONENT;
		
COMPONENT des56_encrypt
	PORT(
		indata         : IN     std_logic_vector (0 TO 63);
		inkey          : IN     std_logic_vector (0 TO 63);
      outdata        : OUT    std_logic_vector (0 TO 63);
      ds             : IN     std_logic;
      clk            : IN     std_logic;
      rst            : IN     std_logic;
      rdy_next_next_cycle : OUT    std_logic;	-- output will be ready in two clock cycles - optional signal
      rdy_next_cycle : OUT    std_logic;      -- output will be ready in one clock cycle - optional signal
      rdy            : OUT    std_logic  -- output is ready NOW
		);
	END COMPONENT;


COMPONENT inputcon 
    Port ( clk,reset: in std_logic;
				array_in : in  STD_LOGIC_VECTOR(0 to 63);
           array_out : out  STD_LOGIC_VECTOR (63 downto 0)
			  );
END COMPONENT;


COMPONENT outputcon 
    Port ( clk,reset: in std_logic;
			  array_in : in  STD_LOGIC_VECTOR (63 downto 0);
           array_out : out  STD_LOGIC_VECTOR (0 to 63)
			  );
END COMPONENT;
	
--------------------------------------------------------	
--------------------------------------------------------
--3. MAP FUNCTIONS PORTS TO CORRESPONDING INPUT
--------------------------------------------------------
begin

U0: inputcon PORT MAP(
	   clk => clk,
		reset => reset,
		array_in => des_key,
		array_out => des_key_temp);

U1: RSACypher_encrypt PORT MAP(
		
		indata => des_key_temp,
		cypher => rsa_encrypt_out,
		clk => clk,
		ds => ds,
		ready => open,
		reset => reset);

U2: rsacypher_decrypt PORT MAP(
		
		indata => rsa_encrypt_out,
		cypher => rsa_decrypt_out,
		clk => clk,
		ds => ds,
		ready => open,
		reset => reset); 
		
U3: outputcon PORT MAP(
	   clk => clk,
		reset => reset,
		array_in => rsa_decrypt_out,				
		array_out => rsa_decrypt_out_temp);
		
U4: des56_encrypt PORT MAP( 
		
		indata => des_data,
		inkey => des_key,
		outdata => des56_encrypt_out,
		clk => clk,
		rdy_next_cycle => open,
		rdy_next_next_cycle => open,
		ds => ds, 
		rst => reset);
		
U5: des56_decrypt PORT MAP(
		
		indata => des56_encrypt_out,
		inkey => rsa_decrypt_out_temp,
		outdata => des56_decrypt_out,
		clk => clk,
		ds => ds,
		rdy => outready,
		rdy_next_cycle => open,
		rdy_next_next_cycle => open,
		rst => reset);
		
outdata <= des56_decrypt_out;
end Behavioral;

