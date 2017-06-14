
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.std_logic_arith.all;
  
entity sdi_bayer2rgb is
generic(
	C_IMAGE_WIDTH           : integer := 1280;
   C_IMAGE_HEIGHT           : integer := 960;
	C_DWIDTH                : integer := 64
	);
port(
	-- Streaming I/O
    rst               : in std_logic;
    clk               : in std_logic;
	 pu_reset : in std_logic;
	 stream_in_stop   : out std_logic;
    stream_in_valid  : in std_logic;
    stream_in_data   : in std_logic_vector(C_DWIDTH-1 downto 0);
	 stream_out_stop   : in std_logic;
    stream_out_valid  : out std_logic;
    stream_out_data   : out std_logic_vector(C_DWIDTH-1 downto 0);
	 sof_in : in std_logic;
	 sof_out : out std_logic
);
end sdi_bayer2rgb;

architecture behavior of sdi_bayer2rgb is

type ROW_STATES is (GR, BG);
signal row_state : ROW_STATES;

type PIXELS is (IDLE, PIXEL0, PIXEL1, INC_ADDR, PIXELWAIT, PIXELWAIT2);
signal pixel : PIXELS;

signal addr : std_logic_vector(8 downto 0);
signal dout_g1, dout_g2, dout_b, dout_r : std_logic_vector(31 downto 0);
signal greens1, greens2, blues, reds : std_logic_vector(31 downto 0);
--signal b1,g1,r1,g2,b2,r2 : std_logic_vector(7 downto 0);
signal wea_g1, wea_g2, wea_b, wea_r : std_logic_vector(0 downto 0);
component ColorRAM
	port (
	clka: IN std_logic;
	dina: IN std_logic_VECTOR(31 downto 0);
	addra: IN std_logic_VECTOR(8 downto 0);
	wea: IN std_logic_VECTOR(0 downto 0);
	douta: OUT std_logic_VECTOR(31 downto 0));
end component;

begin

	--stream_in_data(63:0) is GRGRGRGR or BGBGBGBG
	greens1 <= stream_in_data(63 downto 56) & stream_in_data(47 downto 40) & stream_in_data(31 downto 24) & stream_in_data(15 downto 8);
	reds    <= stream_in_data(55 downto 48) & stream_in_data(39 downto 32) & stream_in_data(23 downto 16) & stream_in_data( 7 downto 0);
	blues   <= stream_in_data(63 downto 56) & stream_in_data(47 downto 40) & stream_in_data(31 downto 24) & stream_in_data(15 downto 8);
	greens2 <= stream_in_data(55 downto 48) & stream_in_data(39 downto 32) & stream_in_data(23 downto 16) & stream_in_data( 7 downto 0);
	
	RAM_G1 : ColorRAM
		port map (
			clka => clk,
			dina => greens1,
			addra => addr,
			wea => wea_g1,
			douta => dout_g1);
	RAM_R : ColorRAM
		port map (
			clka => clk,
			dina => reds,
			addra => addr,
			wea => wea_r,
			douta => dout_r);
	RAM_B : ColorRAM
		port map (
			clka => clk,
			dina => blues,
			addra => addr,
			wea => wea_b,
			douta => dout_b);
	RAM_G2 : ColorRAM
		port map (
			clka => clk,
			dina => greens2,
			addra => addr,
			wea => wea_g2,
			douta => dout_g2);
	
	sof_out <= sof_in;
	--stream_out_data <= x"00" & b1 & g1 & r1 & x"00" & b2 & g2 & r2;

	STD_PROC : process (clk,rst,pu_reset)
		--variable greenL, greenR : std_logic_vector(8 downto 0);
	begin
		if rst='1' or pu_reset='1' then
			addr <= ( others => '0' );
			stream_out_valid <= '0';
			wea_g1(0) <= '0';
			wea_g2(0) <= '0';
			wea_b(0) <= '0';
			wea_r(0) <= '0';
			pixel <= IDLE;
			stream_in_stop <= '0';
		elsif rising_edge(clk) and stream_out_stop = '0' then
			stream_out_valid <= '0';
			wea_g1(0) <= '0';
			wea_g2(0) <= '0';
			wea_b(0) <= '0';
			wea_r(0) <= '0';
			stream_in_stop <= '0';
			
			case pixel is
			when IDLE =>
				if sof_in = '1' then
					addr <= (others => '0');
					row_state <= GR;
				elsif stream_in_valid = '1' then
					--store current pixel
					stream_in_stop <= '1';
					case row_state is
					when GR =>
						wea_g1(0) <= '1';
						wea_r(0) <= '1';
						pixel <= INC_ADDR;
					when BG =>
						wea_b(0) <= '1';
						wea_g2(0) <= '1';
						pixel <= PIXEL0;
					end case;
					
				end if;
				
			when PIXEL0 => --select first two bytes of each color RAM
				stream_in_stop <= '1';
				stream_out_valid <= '1';
				--stream_out_data <= x"00" & b1 & g1 & r1 & x"00" & b2 & g2 & r2;
				--greenL := ('0'&dout_g1(23 downto 16)) + ('0'&dout_g2(23 downto 16));
				--greenR := ('0'&dout_g1(31 downto 24)) + ('0'&dout_g2(31 downto 24));
				stream_out_data <= x"00"
										& dout_b(23 downto 16)
										--& greenL(8 downto 1)
										& dout_g1(23 downto 16)
										& dout_r(23 downto 16)
										& x"00"
										& dout_b(31 downto 24)
										--& greenR(8 downto 1)
										& dout_g1(31 downto 24)
										& dout_r(31 downto 24);
				pixel <= PIXELWAIT;
				
			--wait for following PCores. ToDo: better use stream_stop instead
			when PIXELWAIT =>
				stream_in_stop <= '1';
				pixel <= PIXEL1;
			
			when PIXEL1 => --select second two bytes of each color RAM
				stream_in_stop <= '1';
				stream_out_valid <= '1';
				--stream_out_data <= x"00" & b1 & g1 & r1 & x"00" & b2 & g2 & r2;
				--greenL := ('0'&dout_g1(7 downto 0)) + ('0'&dout_g2(7 downto 0));
				--greenR := ('0'&dout_g1(15 downto 8)) + ('0'&dout_g2(15 downto 8));
				stream_out_data <= x"00"
										& dout_b(7 downto 0)
										--& greenL(8 downto 1)
										& dout_g1(7 downto 0)
										& dout_r(7 downto 0)
										& x"00"
										& dout_b(15 downto 8)
										--& greenR(8 downto 1)
										& dout_g1(15 downto 8)
										& dout_r(15 downto 8);
				pixel <= PIXELWAIT2;
				
			--wait for following PCores. ToDo: better use stream_stop instead
			when PIXELWAIT2 =>
				stream_in_stop <= '1';
				pixel <= INC_ADDR;
				
			when INC_ADDR =>
				--update addr
				if addr < C_IMAGE_WIDTH/8-1 then --8 pixel per 64 word
					addr <= addr + 1;
				else
					case row_state is
					when GR =>
						row_state <= BG;
					when BG =>
						row_state <= GR;
					end case;
					addr <= ( others => '0' );
				end if;
				pixel <= IDLE;
				
			end case;
 		end if; --clk
	end process STD_PROC;
	
end behavior;
