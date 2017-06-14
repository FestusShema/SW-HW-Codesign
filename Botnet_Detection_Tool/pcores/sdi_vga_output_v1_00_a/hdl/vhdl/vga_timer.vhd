-----------------------------------------------------------------------------------------------------------------------
-- FILE         : vga_timer.vhd
-- TITLE        : 
-- PROJECT      : PICSY
-- AUTHOR       : Felix & akzare (University of Potsdam, Computer Science Department)
-- DESCRIPTION	: vga output timer 
--                for generation of v_sync and h_sync signals.
-----------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity vga_timer is
generic (
  V_DT : integer := 480;   -- vertical display time
  V_FP : integer := 11;    -- vertical front porch
  V_SP : integer := 2;     -- vertical sync pulse
  V_BP : integer := 31;    -- vertical back porch
  H_DT : integer := 640;   -- horizontal display time
  H_FP : integer := 16;    -- horizontal front porch
  H_SP : integer := 96;    -- horizontal sync pulse
  H_BP : integer := 48 );  -- horizontal back porch
port (
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
end vga_timer;


architecture behavior of  vga_timer is

	constant V_PT			: integer	:= V_DT + V_FP + V_SP + V_BP; -- vertical pulse time
	constant H_PT			: integer	:= H_DT + H_FP + H_SP + H_BP; -- horizontal pulse time

	signal h_counter	: integer range 0 to H_PT - 1;		-- horizontal pixels counter
	signal v_counter	: integer range 0 to V_PT - 1;		-- vertical pixels counter

begin

  process( pixel_clk, reset )
    variable v_visible : std_logic;
    variable h_visible : std_logic;
  begin
    if reset = '1' then
      h_counter <= 0;
      v_counter <= 0;
      h_sync_d <=	'0';
      v_sync_d <=	'0';
      is_visible <=	'0';
      h_retrace <= '0';
      v_retrace <= '0';
    elsif rising_edge(pixel_clk) then

      h_visible := '0';
      h_sync_d <=	'1';
      if h_counter < H_DT - 1 then
        h_visible := '1';
      elsif (h_counter >= (H_DT+H_FP)) and (h_counter < (H_DT+H_FP+H_SP)) then  -- h_sync is delayed 1 clock cycle
        h_sync_d <= '0';
      end if;

      v_visible := '0';
      v_sync_d <=	'1';
      if v_counter < V_DT then
        v_visible := '1';
      elsif (v_counter >= (V_DT+V_FP)) and (v_counter < (V_DT+V_FP+V_SP)) then  -- v_sync is delayed 1 clock cycle
        v_sync_d <= '0';
      end if;

      if h_counter < H_PT - 1 then
        h_counter <= h_counter + 1;
      else
        h_counter <= 0;
        h_visible := '1';
        if v_counter < V_PT - 1 then
          v_counter <= v_counter + 1;
        else
          v_counter <= 0;
          v_visible := '1';
        end if;
      end if;

      is_visible <=	v_visible and h_visible;
      h_retrace <= not h_visible;
      v_retrace <= not v_visible;
    end if;
  end process;

  x_pos <= std_logic_vector(to_unsigned(h_counter, x_pos'length));
  y_pos <= std_logic_vector(to_unsigned(v_counter, y_pos'length));

end behavior;