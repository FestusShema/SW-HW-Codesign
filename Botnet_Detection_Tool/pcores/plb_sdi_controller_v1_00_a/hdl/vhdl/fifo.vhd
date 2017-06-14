------------------------------------------------------------------------------
-- Filename:          fifo.vhd
-- Version:           1.00.a
-- Description:       fifo wrapper
-- Date:              Oct 16 2009
-- VHDL Standard:     VHDL'93
-- PROJECT      : PICSY
-- AUTHOR       : Felix & Ali (University of Potsdam, Computer Science Department)
------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY fifo IS
generic (
  DATA_WIDTH : integer := 32;
  FIFO_DEPTH_BITS : integer := 10 );
port (
	din: IN std_logic_VECTOR(DATA_WIDTH-1 downto 0);
	rd_clk: IN std_logic;
	rd_en: IN std_logic;
	rst: IN std_logic;
	wr_clk: IN std_logic;
	wr_en: IN std_logic;
	dout: OUT std_logic_VECTOR(DATA_WIDTH-1 downto 0);
	empty: OUT std_logic;
	full: OUT std_logic;
	rd_data_count: OUT std_logic_VECTOR(FIFO_DEPTH_BITS downto 0);
	wr_data_count: OUT std_logic_VECTOR(FIFO_DEPTH_BITS downto 0));
END fifo;

ARCHITECTURE fifo_a OF fifo IS

component fifo_generator_v4_4_32
	port (
	din: IN std_logic_VECTOR(31 downto 0);
	rd_clk: IN std_logic;
	rd_en: IN std_logic;
	rst: IN std_logic;
	wr_clk: IN std_logic;
	wr_en: IN std_logic;
	dout: OUT std_logic_VECTOR(31 downto 0);
	empty: OUT std_logic;
	full: OUT std_logic;
	rd_data_count: OUT std_logic_VECTOR(10 downto 0);
	wr_data_count: OUT std_logic_VECTOR(10 downto 0));
end component;

component fifo_generator_v4_4_64
	port (
	din: IN std_logic_VECTOR(63 downto 0);
	rd_clk: IN std_logic;
	rd_en: IN std_logic;
	rst: IN std_logic;
	wr_clk: IN std_logic;
	wr_en: IN std_logic;
	dout: OUT std_logic_VECTOR(63 downto 0);
	empty: OUT std_logic;
	full: OUT std_logic;
	rd_data_count: OUT std_logic_VECTOR(9 downto 0);
	wr_data_count: OUT std_logic_VECTOR(9 downto 0));
end component;

BEGIN

  fifo_32 : if DATA_WIDTH = 32 generate begin
        fifo_32_i : fifo_generator_v4_4_32
		port map (
			din => din,
			rd_clk => rd_clk,
			rd_en => rd_en,
			rst => rst,
			wr_clk => wr_clk,
			wr_en => wr_en,
			dout => dout,
			empty => empty,
			full => full,
			rd_data_count => rd_data_count,
			wr_data_count => wr_data_count);
  end generate;

  fifo_64 : if DATA_WIDTH = 64 generate begin
        fifo_64_i : fifo_generator_v4_4_64
		port map (
			din => din,
			rd_clk => rd_clk,
			rd_en => rd_en,
			rst => rst,
			wr_clk => wr_clk,
			wr_en => wr_en,
			dout => dout,
			empty => empty,
			full => full,
			rd_data_count => rd_data_count,
			wr_data_count => wr_data_count);
  end generate;

  assert DATA_WIDTH = 64
  report "unsupported parameter combination" 
  severity ERROR;

END fifo_a;

