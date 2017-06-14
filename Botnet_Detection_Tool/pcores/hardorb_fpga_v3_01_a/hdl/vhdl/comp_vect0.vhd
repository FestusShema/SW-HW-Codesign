----------------------------------------------------------------------------------
-- Company: University of Arkansas, CSCE department
-- Engineer: Adil Tbatou
-- 
-- Create Date:    May 2013 
-- Design Name: 
-- Module Name:    comp_vect0 - Behavioral 
-- Project Name: 	 
-- Target Devices: 
-- Tool versions: 
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
use IEEE.std_logic_1164.all;
entity comp_vect0 is 
	 port(car : in   std_logic_vector(7 downto 0); 
	      pos : out  std_logic_vector(49 downto 0));
end comp_vect0; 

architecture STRUCTURAL of comp_vect0 is 
begin 
	  pos(0) <= '1' when car = "00111111" else '0'; 
	  pos(1) <= '1' when car = "00100001" else '0'; 
	  pos(2) <= '1' when car = "00100101" else '0'; 
	  pos(3) <= '1' when car = "01000000" else '0'; 
	  pos(4) <= '1' when car = "00101101" else '0'; 
	  pos(5) <= '1' when car = "00111010" else '0'; 
	  pos(6) <= '1' when car = "01010101" else '0'; 
	  pos(7) <= '1' when car = "01010000" else '0'; 
	  pos(8) <= '1' when car = "01111110" else '0'; 
	  pos(9) <= '1' when car = "01110011" else '0'; 
	  pos(10) <= '1' when car = "00101110" else '0'; 
	  pos(11) <= '1' when car = "01000111" else '0'; 
	  pos(12) <= '1' when car = "01011101" else '0'; 
	  pos(13) <= '1' when car = "00110101" else '0'; 
	  pos(14) <= '1' when car = "00111101" else '0'; 
	  pos(15) <= '1' when car = "01110100" else '0'; 
	  pos(16) <= '1' when car = "00101100" else '0'; 
	  pos(17) <= '1' when car = "01111101" else '0'; 
	  pos(18) <= '1' when car = "01110000" else '0'; 
	  pos(19) <= '1' when car = "00110010" else '0'; 
	  pos(20) <= '1' when car = "01110001" else '0'; 
	  pos(21) <= '1' when car = "01001011" else '0'; 
	  pos(22) <= '1' when car = "00110011" else '0'; 
	  pos(23) <= '1' when car = "00111110" else '0'; 
	  pos(24) <= '1' when car = "01011110" else '0'; 
	  pos(25) <= '1' when car = "01001000" else '0'; 
	  pos(26) <= '1' when car = "01011000" else '0'; 
	  pos(27) <= '1' when car = "01001111" else '0'; 
	  pos(28) <= '1' when car = "01000001" else '0'; 
	  pos(29) <= '1' when car = "01011011" else '0'; 
	  pos(30) <= '1' when car = "00110100" else '0'; 
	  pos(31) <= '1' when car = "01011100" else '0'; 
	  pos(32) <= '1' when car = "01011010" else '0'; 
	  pos(33) <= '1' when car = "00101000" else '0'; 
	  pos(34) <= '1' when car = "00101001" else '0'; 
	  pos(35) <= '1' when car = "00110111" else '0'; 
	  pos(36) <= '1' when car = "01000011" else '0'; 
	  pos(37) <= '1' when car = "00100100" else '0'; 
	  pos(38) <= '1' when car = "01000101" else '0'; 
	  pos(39) <= '1' when car = "01001001" else '0'; 
	  pos(40) <= '1' when car = "01010010" else '0'; 
	  pos(41) <= '1' when car = "01010011" else '0'; 
	  pos(42) <= '1' when car = "01010100" else '0'; 
	  pos(43) <= '1' when car = "01001110" else '0'; 
	  pos(44) <= '1' when car = "01000100" else '0'; 
	  pos(45) <= '1' when car = "01010110" else '0'; 
	  pos(46) <= '1' when car = "01000110" else '0'; 
	  pos(47) <= '1' when car = "01001100" else '0'; 
	  pos(48) <= '1' when car = "00101011" else '0'; 
	  pos(49) <= '1' when car = "00101010" else '0'; 
end STRUCTURAL; 
