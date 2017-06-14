-----------------------------------------------------------------------------------------------------------------------
-- FILE         : sdi_vga_output.vhd
-- TITLE        : 
-- PROJECT      : PICSY
-- AUTHOR       : Felix & Ali (University of Potsdam, Computer Sceince Department)
-- DESCRIPTION	: vga output 
--                for consuming data from Redear FIFO of SDI Controller and producing video RGB color data on VGA output.
-----------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------
-- Libraries
-----------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity sdi_vga_output is
	generic
	(
    C_REG_WIDTH : integer :=  32;
		C_DWIDTH : integer	:=	32
	);
	port
	(
		-- Reset and Clocks --------------------------------------------------
		reset : in std_logic;
		vga_pixel_clk	: in	std_logic;
		-- Stream In ---------------------------------------------------------
    pu_reset : in std_logic;
    request_frame : out std_logic;
    request_frame_ack : in std_logic;
		stream_in_stop : out	std_logic;
		stream_in_valid : in	std_logic;
		stream_in_data : in	std_logic_vector(C_DWIDTH-1 downto 0);
		-- Config -----------------------------------------------------------
    config_reg : in std_logic_vector(C_REG_WIDTH-1 downto 0);
	 sof : in std_logic;
	 sof_ack : out std_logic;
		-- VGA ---------------------------------------------------------------
    pixel_clk : out	std_logic;
		red	: out	std_logic_vector(7 downto 0);
		green	: out	std_logic_vector(7 downto 0);
		blue : out	std_logic_vector(7 downto 0);
		h_sync : out	std_logic;
		v_sync : out	std_logic
	);

end sdi_vga_output;
------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture Behavioral of sdi_vga_output is

	-- -------------------------------
	-- Constants Declarations
	-- -------------------------------
	constant COLOR_24BIT	: std_logic_vector(1 downto 0) := "10";
	constant COLOR_16BIT	: std_logic_vector(1 downto 0) := "01";
	constant GRAY_8BIT		: std_logic_vector(1 downto 0) := "00";

  component vga_timer port ( 
    reset	: in std_logic;
    pixel_clk	: in std_logic;
    -- VGA output -----------------------------------------------------
    h_sync_d : out std_logic;     -- horizontal sync (delayed 1 clock cycle)
    v_sync_d : out std_logic;     -- vertical sync (delayed 1 clock cycle)
    is_visible : out std_logic;   -- indicates if the current pixel is visible or not
    h_retrace : out std_logic;    -- horizontal retrace
    v_retrace : out std_logic;    -- vertical retrace
    x_pos : out std_logic_vector(9 downto 0);
    y_pos : out std_logic_vector(9 downto 0) );
  end component;

	signal data_counter : natural range 0 to 7;
	signal data_counter_max : natural range 0 to 7;
  
	signal color_depth : std_logic_vector(1 downto 0);

	signal x_pos: std_logic_vector(9 downto 0);
	signal y_pos: std_logic_vector(9 downto 0);
  
	signal is_visible	: std_logic;
  
  signal v_retrace : std_logic;
  signal v_retrace_old : std_logic;
  
  signal type16bit : integer range 0 to 2;
  
  signal red_buffer, green_buffer : std_logic_vector(7 downto 0);
  
begin

	VGA_TIMER_INST : vga_timer
	port map (
    reset => reset,
    pixel_clk => vga_pixel_clk,
    h_sync_d => h_sync,
    v_sync_d => v_sync,
    is_visible => is_visible,
    v_retrace => v_retrace,
    x_pos => x_pos,
    y_pos => y_pos
	);

	sdi_64: if C_DWIDTH = 64 generate

  with color_depth select
    data_counter_max <= 1 when COLOR_24BIT,
                        3 when COLOR_16BIT,
                        7 when GRAY_8BIT,
                        0 when others;

  vga_signals : process( vga_pixel_clk, reset, pu_reset ) is
	  variable lsb_index : natural range 0 to 56;
	  variable index : natural range 0 to 7;
  begin
    if reset = '1' or pu_reset = '1' then
      data_counter <= 0;
      red <= (others => '0');
      green <= (others => '0');
      blue <= (others => '0');
		red_buffer <= (others => '0');
		green_buffer <= (others => '0');
      request_frame <= '0';
		sof_ack <= '0';
		type16bit <= 0;
    elsif rising_edge(vga_pixel_clk) then
	   sof_ack <= '0';
      if sof = '1' then
			sof_ack <= '1';
			data_counter <= 0;
			request_frame <= '0';
			type16bit <= 0;
		end if;
		
      if ( v_retrace_old = '0' and v_retrace = '1' ) then
        request_frame <= '1';
        data_counter <= data_counter_max;
      elsif request_frame_ack = '1' then
        request_frame <= '0';
      end if;
      v_retrace_old <= v_retrace;

      red <= (others => '0');
      green <= (others => '0');
      blue <= (others => '0');
      
      if is_visible = '1' and stream_in_valid = '1' then  -- FIXME: check valid??

        if ( data_counter = 0 ) then
          data_counter <= data_counter_max;
        else
          data_counter <= data_counter - 1;
        end if;

        case color_depth is
          when COLOR_24BIT =>
            -- for 64-bit
            -- data from FIFO: xxx(8) & Pxl_b_1(8) & Pxl_g_1(8) & Pxl_r_1(8) &    FIXME: update
            --                 xxx(8) & Pxl_b_0(8) & Pxl_g_0(8) & Pxl_r_0(8)
            index := (1-data_counter);
            lsb_index := index*2*2*8;
            red   <= stream_in_data((lsb_index+7) downto lsb_index);
            green <= stream_in_data((lsb_index+15) downto (lsb_index+8));
            blue  <= stream_in_data((lsb_index+23) downto (lsb_index+16));

          when COLOR_16BIT =>
            -- for 64-bit
            -- data from FIFO: Pxl_b_3(5) & Pxl_g_3(6) & Pxl_r_3(5) & 
            --                 Pxl_b_2(5) & Pxl_g_2(6) & Pxl_r_2(5) & 
            --                 Pxl_b_1(5) & Pxl_g_1(6) & Pxl_r_1(5) & 
            --                 Pxl_b_0(5) & Pxl_g_0(6) & Pxl_r_0(5)
				-- type16bit
				--	0:					              Pxl_g_3(8) & Pxl_r_3(8) & 
            --                 Pxl_b_2(8) & Pxl_g_2(8) & Pxl_r_2(8) & 
            --                 Pxl_b_1(8) & Pxl_g_1(8) & Pxl_r_1(8)
				
				--	1:					                           Pxl_r_4(8) & 
				--						 Pxl_b_3(8) & Pxl_g_3(8) & Pxl_r_3(8) & 
            --                 Pxl_b_2(8) & Pxl_g_2(8) & Pxl_r_2(8) & 
            --                 Pxl_b_1(8)
				
				--	2:					 Pxl_b_3(8) & Pxl_g_3(8) & Pxl_r_3(8) & 
            --                 Pxl_b_2(8) & Pxl_g_2(8) & Pxl_r_2(8) & 
            --                 Pxl_b_1(8) & Pxl_g_2(8)
				
            case type16bit is
				when 0 =>
					case data_counter is
					when 7 => --error
					when 6 => --error
					when 5 => --error
					when 4 => --error
					when 3 =>
						red   <= stream_in_data( 7 downto  0);
						green <= stream_in_data(15 downto  8);
						blue  <= stream_in_data(23 downto 16);
						data_counter <= 1;
					when 2 =>
					when 1 =>
						red   <= stream_in_data(31 downto 24);
						green <= stream_in_data(39 downto 32);
						blue  <= stream_in_data(47 downto 40);
					when 0 =>
						red_buffer   <= stream_in_data(55 downto 48);
						green_buffer <= stream_in_data(63 downto 56);
						type16bit <= 1;
					end case;
				when 1 =>
					case data_counter is
					when 7 => --error
					when 6 => --error
					when 5 => --error
					when 4 => --error
					when 3 =>
						red   <= red_buffer;
						green <= green_buffer;
						blue  <= stream_in_data(7 downto 0);
					when 2 =>
						red   <= stream_in_data(15 downto  8);
						green <= stream_in_data(23 downto 16);
						blue  <= stream_in_data(31 downto 24);
					when 1 =>
						red   <= stream_in_data(39 downto 32);
						green <= stream_in_data(47 downto 40);
						blue  <= stream_in_data(55 downto 48);
					when 0 =>
						red_buffer <= stream_in_data(63 downto 56);
						type16bit <= 2;
					end case;
				when 2 =>
					case data_counter is
					when 7 => --error
					when 6 => --error
					when 5 => --error
					when 4 => --error
					when 3 =>
						red   <= red_buffer;
						green <= stream_in_data( 7 downto  0);
						blue  <= stream_in_data(15 downto  8);
						data_counter <= 1;
					when 2 =>
					when 1 =>
						red   <= stream_in_data(23 downto 16);
						green <= stream_in_data(31 downto 24);
						blue  <= stream_in_data(39 downto 32);
					when 0 =>
						red   <= stream_in_data(47 downto 40);
						green <= stream_in_data(55 downto 48);
						blue  <= stream_in_data(63 downto 56);
						type16bit <= 0;
					end case;
				end case;
				

          when GRAY_8BIT =>
            -- for 64-bit
            -- data from FIFO: Pxl_7(8) & Pxl_6(8) & Pxl_5(8) & Pxl_4(8) & 
            --                 Pxl_3(8) & Pxl_2(8) & Pxl_1(8) & Pxl_0(8)
            lsb_index := data_counter*8;
            red   <= stream_in_data((lsb_index+7) downto lsb_index);
            green <= stream_in_data((lsb_index+7) downto lsb_index);
            blue  <= stream_in_data((lsb_index+7) downto lsb_index);
            
          when others =>
--            red   <= stream_in_data(7 downto 0);
--            green <= stream_in_data(15 downto 8);
--            blue  <= stream_in_data(23 downto 16);
            null;  -- red, green, blue is 0

        end case;
        
      end if;

     -- if is_visible = '1' and ((x_pos = y_pos) or (stream_in_valid = '0')) then  -- debugging
     --   red   <= (others => '1');
     --   green <= (others => '0');
     --   blue  <= (others => '0');
     -- end if;
      
    end if;
  end process;

	end generate;

------------------------------------------------------------------------------------------------
--	sdi_32: if C_DWIDTH = 32 generate
--
--  with color_depth select
--    data_counter_max <= 1 when COLOR_24BIT,
--                        3 when COLOR_16BIT,
--                        7 when GRAY_8BIT,
--                        0 when others;
--
--  vga_signals : process( vga_pixel_clk, reset, pu_reset ) is
--	  variable lsb_index : natural range 0 to 56;
--	  variable index : natural range 0 to 7;
--  begin
--    if reset = '1' or pu_reset = '1' then
--      data_counter <= 0;
--      red <= (others => '0');
--      green <= (others => '0');
--      blue <= (others => '0');
--      request_frame <= '0';
--    elsif rising_edge(vga_pixel_clk) then
--        
--      if ( v_retrace_old = '0' and v_retrace = '1' ) then
--        request_frame <= '1';
--        data_counter <= data_counter_max;
--      elsif request_frame_ack = '1' then
--        request_frame <= '0';
--      end if;
--      v_retrace_old <= v_retrace;
--
--      red <= (others => '0');
--      green <= (others => '0');
--      blue <= (others => '0');
--      
--      if is_visible = '1' and stream_in_valid = '1' then  -- FIXME: check valid??
--
--        if ( data_counter = 0 ) then
--          data_counter <= data_counter_max;
--        else
--          data_counter <= data_counter - 1;
--        end if;
--
--        case color_depth is
--          when COLOR_24BIT =>
--            -- for 32-bit
--            -- data from FIFO: xxx(8) & Pxl_b_1(8) & Pxl_g_1(8) & Pxl_r_1(8) &    FIXME: update
--            --                 xxx(8) & Pxl_b_0(8) & Pxl_g_0(8) & Pxl_r_0(8)
--            index := (1-data_counter);
--            lsb_index := index*2*2*8;
--            red   <= stream_in_data((lsb_index+7) downto lsb_index);
--            green <= stream_in_data((lsb_index+15) downto (lsb_index+8));
--            blue  <= stream_in_data((lsb_index+23) downto (lsb_index+16));
--
--          when COLOR_16BIT =>
--            -- for 32-bit
--            -- data from FIFO: Pxl_b_3(5) & Pxl_g_3(6) & Pxl_r_3(5) & 
--            --                 Pxl_b_2(5) & Pxl_g_2(6) & Pxl_r_2(5) & 
--            --                 Pxl_b_1(5) & Pxl_g_1(6) & Pxl_r_1(5) & 
--            --                 Pxl_b_0(5) & Pxl_g_0(6) & Pxl_r_0(5)
--            index := (3-data_counter);
--            lsb_index := index*2*8;
--            red   <= stream_in_data((lsb_index+4) downto lsb_index) 
--                   & stream_in_data(lsb_index)
--                   & stream_in_data(lsb_index)
--                   & stream_in_data(lsb_index);
--            green <= stream_in_data((lsb_index+10) downto lsb_index+5)
--                   & stream_in_data(lsb_index+5) 
--                   & stream_in_data(lsb_index+5);
--            blue  <= stream_in_data((lsb_index+15) downto lsb_index+11)
--                   & stream_in_data(lsb_index+11)
--                   & stream_in_data(lsb_index+11)
--                   & stream_in_data(lsb_index+11);
--
--          when GRAY_8BIT =>
--            -- for 32-bit
--            -- data from FIFO: Pxl_7(8) & Pxl_6(8) & Pxl_5(8) & Pxl_4(8) & 
--            --                 Pxl_3(8) & Pxl_2(8) & Pxl_1(8) & Pxl_0(8)
--            lsb_index := data_counter*8;
--            red   <= stream_in_data((lsb_index+7) downto lsb_index);
--            green <= stream_in_data((lsb_index+7) downto lsb_index);
--            blue  <= stream_in_data((lsb_index+7) downto lsb_index);
--            
--          when others =>
----            red   <= stream_in_data(7 downto 0);
----            green <= stream_in_data(15 downto 8);
----            blue  <= stream_in_data(23 downto 16);
--            null;  -- red, green, blue is 0
--
--        end case;
--        
--      end if;
--
--     -- if is_visible = '1' and ((x_pos = y_pos) or (stream_in_valid = '0')) then  -- debugging
--     --   red   <= (others => '1');
--     --   green <= (others => '0');
--     --   blue  <= (others => '0');
--     -- end if;
--      
--    end if;
--  end process;
--
--	end generate;

  stream_in_stop <= '0' when (is_visible = '1') and (data_counter = 0) else '1';
  color_depth <= config_reg(1 downto 0);
  pixel_clk <= vga_pixel_clk;

end Behavioral;
