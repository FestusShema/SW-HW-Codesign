----------------------------------------------------------------------------------
-- Module Name: i2c
-- Version: 0.99
----------------------------------------------------------------------------------
-- TODO:
--	- ...?
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity i2c is
	generic(
		system_clk	: integer := 100000000;	-- 100 MHz
		i2c_clk		: integer := 100000		-- 100 kHz
	);

	port(
		Clock			: in		std_logic;
		Reset			: in		std_logic;

		RW_Sel		: in		std_logic;

		Valid_In		: in		std_logic;
		Reg_Addr		: in		std_logic_vector(7 downto 0);
		Data_In		: in		std_logic_vector(15 downto 0);

		Valid_Out	: out		std_logic;
		Data_Out		: out		std_logic_vector(15 downto 0);

		Busy			: out		std_logic;
		Error			: out		std_logic;

		SDA_I			: in		std_logic;
		SDA_O			: out		std_logic;
		SDA_T			: out		std_logic;
		
		SCL			: out		std_logic
	);
end i2c;

architecture Behavioral of i2c is

	component SerialTopARallel
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
	end component;

	component i2c_scl
		port(
			Clock		: in	std_logic;
			Reset		: in	std_logic;
			SCL_EN	: in	std_logic;
			SCL		: out	std_logic
		);
	end component;

	type SDA_States is (
		wait_valid,

		init_write_start,
		send_write_start,

		send_cam_write_addr,
		recv_cam_write_addr_ack,

		send_reg_addr,
		recv_reg_addr_ack,

		send_hi_data,
		recv_hi_data_ack,

		send_lo_data,
		recv_lo_data_ack,

		stop,

		i2c_error,
--------------------------------------------------------------------------------
		init_read_start,
		send_read_start,

		send_cam_read_addr,
		recv_cam_read_addr_ack,

		recv_hi_data,
		send_hi_data_ack,

		recv_lo_data,
		send_lo_data_nack
	);

	constant Camera_Read_Addr  : std_logic_vector(7 downto 0) := X"BB";
	constant Camera_Write_Addr : std_logic_vector(7 downto 0) := X"BA";

	constant sys_clk_divider	: integer := system_clk / (2 * i2c_clk);

	signal c_state			: SDA_States;
	signal n_state			: SDA_States;

	signal double_clk		: std_logic;	-- 2 * i2c_clk

	signal sclk_en			: std_logic;
	signal sclk				: std_logic;

	signal sdata			: std_logic;

	signal star_en			: std_logic;

	signal counter_reset	: std_logic;
	signal counter			: integer range 0 to 7;

	signal i2c_valid_in	: std_logic;
	signal i2c_valid_out	: std_logic;
	signal i2c_failed		: std_logic;

	signal busy0			: std_logic;
	signal busy1			: std_logic;

begin

	SYS_I2C_SYNC : process(Clock, Reset, Valid_In, i2c_valid_in)
		variable tick	: integer range 1 to sys_clk_divider;
		variable tock	: integer range 1 to sys_clk_divider;
		variable valid	: std_logic_vector(1 downto 0);
		variable memo	: std_logic;
	begin
		if Reset = '1' then
			tick := 1;
			tock := 1;
			memo := '0';
			double_clk <= '1';
			Valid_Out <= '0';
			i2c_valid_in <= '0';
		else
			if rising_edge(Clock) then
				if tick = sys_clk_divider then
					tick := 1;
					double_clk <= not double_clk;
				elsif tick = (sys_clk_divider / 2) then
					tick := tick + 1;
					double_clk <= not double_clk;
				else
					tick := tick + 1;
					double_clk <= double_clk;
				end if;

				valid := Valid_In & i2c_valid_in;

				case valid is
					when "00"	=>	i2c_valid_in <= '0';
					when "01"	=>	if tick = tock then i2c_valid_in <= '0'; else i2c_valid_in <= '1'; end if;
					when "10"	=>	i2c_valid_in <= '1'; tock := tick;
					when others	=>	i2c_valid_in <= i2c_valid_in;
				end case;				

				if i2c_valid_out = '1' then
					if memo = '0' then
						Valid_Out <= '1';
					else
						Valid_Out <= '0';
					end if;

					memo := '1';
				else
					Valid_Out <= '0';
					memo := '0';
				end if;
			end if;
		end if;
	end process SYS_I2C_SYNC;


	SCL <= sclk;

	SDA_O <= sdata;

	SDA_T <= '0' when sdata = '0' else '1';

	SCL_GEN : i2c_scl port map(double_clk, Reset, sclk_en, sclk);

	DATA_REG : SerialTopARallel port map(double_clk, Reset, star_en, SDA_I, i2c_valid_out, Data_Out);

	star_en <= '1' when ((c_state = recv_hi_data or c_state = recv_lo_data) and sclk = '1') else '0';

	Error <= i2c_failed;

	Busy <= busy0 or busy1;



	SDA_REG: process(Reset, double_clk, c_state)
	begin

		if Reset = '1' then
			c_state <= wait_valid;
			counter <= 7;
			i2c_failed <= '0';
		else
			if double_clk'event and double_clk = '0' then
				c_state <= n_state;

				if counter_reset = '1' then
					counter <= 7;
				else
					if c_state = n_state and sclk = '0' then
						if counter = 0 then
							counter <= 7;
						else
							counter <= counter - 1;
						end if;
					end if;
				end if;

				case c_state is
					when wait_valid	=> i2c_failed <= i2c_failed;
					when i2c_error		=> i2c_failed <= '1';
					when others			=> i2c_failed <= '0';
				end case;
			end if;
		end if;

	end process SDA_REG;



	SDA_COMB: process(double_clk, counter, sclk, c_state, SDA_I, i2c_valid_in, RW_Sel)
	begin

		if double_clk = '0' then
			case c_state is
				when wait_valid					=>	if i2c_valid_in = '1' then
																n_state <= init_write_start;
															else
																n_state <= wait_valid;
															end if;


				when init_write_start			=>	n_state <= send_write_start;

				when send_write_start			=>	n_state <= send_cam_write_addr;

-- Send Camera Write Address --
				when send_cam_write_addr		=>	if sclk = '1' then
																if counter = 0 then
																	n_state <= recv_cam_write_addr_ack;
																else
																	n_state <= send_cam_write_addr;
																end if;
															else
																n_state <= send_cam_write_addr;
															end if;

				when recv_cam_write_addr_ack	=>	if sclk = '1' then
																if SDA_I = '0' then
																	n_state <= send_reg_addr;
																else
																	n_state <= i2c_error;
																end if;
															else
																n_state <= recv_cam_write_addr_ack;
															end if;

-- Send Register Address --
				when send_reg_addr				=>	if sclk = '1' then
																if counter = 0 then
																	n_state <= recv_reg_addr_ack;
																else
																	n_state <= send_reg_addr;
																end if;
															else
																n_state <= send_reg_addr;
															end if;

				when recv_reg_addr_ack			=>	if sclk = '1' then
																if SDA_I = '0' then
																	if RW_Sel = '0' then
																		n_state <= init_read_start;
																	else
																		n_state <= send_hi_data;
																	end if;
																else
																	n_state <= i2c_error;
																end if;
															else
																n_state <= recv_reg_addr_ack;
															end if;

-- Send High Data (write) --
				when send_hi_data					=>	if sclk = '1' then
																if counter = 0 then
																	n_state <= recv_hi_data_ack;
																else
																	n_state <= send_hi_data;
																end if;
															else
																n_state <= send_hi_data;
															end if;

				when recv_hi_data_ack			=>	if sclk = '1' then
																if SDA_I = '0' then
																	n_state <= send_lo_data;
																else
																	n_state <= i2c_error;
																end if;
															else
																n_state <= recv_hi_data_ack;
															end if;

-- Send Low Data (write) --
				when send_lo_data					=>	if sclk = '1' then
																if counter = 0 then
																	n_state <= recv_lo_data_ack;
																else
																	n_state <= send_lo_data;
																end if;
															else
																n_state <= send_lo_data;
															end if;

				when recv_lo_data_ack			=>	if sclk = '1' then
																if SDA_I = '0' then
																	n_state <= stop;
																else
																	n_state <= i2c_error;
																end if;
															else
																n_state <= recv_lo_data_ack;
															end if;

---- READ ---- READ ---- READ ----
				when init_read_start				=>	n_state <= send_read_start;

				when send_read_start				=>	n_state <= send_cam_read_addr;

-- Send Camera Read Address --
				when send_cam_read_addr			=>	if sclk = '1' then
																if counter = 0 then
																	n_state <= recv_cam_read_addr_ack;
																else
																	n_state <= send_cam_read_addr;
																end if;
															else
																n_state <= send_cam_read_addr;
															end if;

				when recv_cam_read_addr_ack	=>	if sclk = '1' then
																if SDA_I = '0' then
																	n_state <= recv_hi_data;
																else
																	n_state <= i2c_error;
																end if;
															else
																n_state <= recv_cam_read_addr_ack;
															end if;

-- Receive High Data --
				when recv_hi_data					=>	if sclk = '1' then
																if counter = 0 then
																	n_state <= send_hi_data_ack;
																else
																	n_state <= recv_hi_data;
																end if;
															else
																n_state <= recv_hi_data;
															end if;

				when send_hi_data_ack			=>	if sclk = '1' then
																n_state <= recv_lo_data;
															else
																n_state <= send_hi_data_ack;
															end if;

-- Receive Low Data --
				when recv_lo_data					=>	if sclk = '1' then
																if counter = 0 then
																	n_state <= send_lo_data_nack;
																else
																	n_state <= recv_lo_data;
																end if;
															else
																n_state <= recv_lo_data;
															end if;

				when send_lo_data_nack			=>	if sclk = '1' then
																n_state <= stop;
															else
																n_state <= send_lo_data_nack;
															end if;

				when stop							=>	n_state <= wait_valid;

				when i2c_error						=>	n_state <= wait_valid;
			end case;
		end if;
	end process SDA_COMB;



	BUSY_SIG : process(Reset, Clock, Valid_In, c_state)
	begin
		if Reset = '1' then
			busy1 <= '0';
		else
			if rising_edge(Clock) then
				if c_state = wait_valid then
					if Valid_In = '1' then
						busy1 <= '1';
					else
						busy1 <= busy1;
					end if;
				else
					busy1 <= '0';
				end if;
			end if;
		end if;
	end process BUSY_SIG;



	SDA_OUTPUT : process(c_state, counter)
	begin
		busy0 <= '1';

		case c_state is
			when wait_valid					=> counter_reset <= '1'; sclk_en <= '0'; sdata <= '1'; busy0 <= '0';

			when init_write_start			=> counter_reset <= '1'; sclk_en <= '1'; sdata <= '1';
			when send_write_start			=> counter_reset <= '1'; sclk_en <= '1'; sdata <= '0';

			when send_cam_write_addr		=> counter_reset <= '0'; sclk_en <= '1'; sdata <= Camera_Write_Addr(counter);
			when recv_cam_write_addr_ack	=> counter_reset <= '1'; sclk_en <= '1'; sdata <= '1';

			when send_reg_addr				=> counter_reset <= '0'; sclk_en <= '1'; sdata <= Reg_Addr(counter);
			when recv_reg_addr_ack			=> counter_reset <= '1'; sclk_en <= '1'; sdata <= '1';

			when send_hi_data					=> counter_reset <= '0'; sclk_en <= '1'; sdata <= Data_In(counter + 8);
			when recv_hi_data_ack			=> counter_reset <= '1'; sclk_en <= '1'; sdata <= '1';

			when send_lo_data					=> counter_reset <= '0'; sclk_en <= '1'; sdata <= Data_In(counter);
			when recv_lo_data_ack			=> counter_reset <= '1'; sclk_en <= '1'; sdata <= '1';

			when init_read_start				=> counter_reset <= '1'; sclk_en <= '1'; sdata <= '1';
			when send_read_start				=> counter_reset <= '1'; sclk_en <= '1'; sdata <= '0';

			when send_cam_read_addr			=> counter_reset <= '0'; sclk_en <= '1'; sdata <= Camera_Read_Addr(counter);
			when recv_cam_read_addr_ack	=> counter_reset <= '1'; sclk_en <= '1'; sdata <= '1';

			when recv_hi_data					=>	counter_reset <= '0'; sclk_en <= '1'; sdata <= '1';
			when send_hi_data_ack			=>	counter_reset <= '1'; sclk_en <= '1'; sdata <= '0';

			when recv_lo_data					=>	counter_reset <= '0'; sclk_en <= '1'; sdata <= '1';
			when send_lo_data_nack			=>	counter_reset <= '1'; sclk_en <= '1'; sdata <= '1';

			when stop							=> counter_reset <= '1'; sclk_en <= '0'; sdata <= '0';

			when i2c_error						=> counter_reset <= '1'; sclk_en <= '0'; sdata <= '0';
		end case;
	end process SDA_OUTPUT;

end Behavioral;
