-----------------------------------------------------------------------------------------------------------------------
-- FILE         : imagesensor.vhd
-- TITLE        : 
-- PROJECT      : PICSY
-- AUTHOR       : Felix & akzare (University of Potsdam, Computer Sceince Department)
-- DESCRIPTION	: image sensor interface with the SDI Controller 
--                for producing video stream data and writing to the Writer FIFO.
-----------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------
-- Libraries
-----------------------------------------------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.std_logic_arith.all;

-----------------------------------------------------------------------------------------------------------------------
-- Ports
-----------------------------------------------------------------------------------------------------------------------
entity picsyi2c_imagesensor_light is
	generic
	(
		C_IMAGE_WIDTH     : integer := 2048;
		C_IMAGE_HIGHT     : integer := 1536;
		C_DWIDTH          : integer := 80;
		C_REGWIDTH 		   : integer := 32;
		C_NUM_CONFIG_REGS : integer := 4;
		C_NUM_STATUS_REGS : integer := 1
  );
  port
  (
    rst               : in std_logic;
    clk               : in std_logic;
	 I2C_SDA_I  	   : in std_logic;    
    I2C_SDA_O  	   : out std_logic;    
    I2C_SDA_T  	   : out std_logic;    
    I2C_SCL    	   : out std_logic;    
	 I2C_SEL0         : out std_logic;
	 I2C_SEL1         : out std_logic;
	 config_reg       : in std_logic_vector(C_NUM_CONFIG_REGS*C_REGWIDTH-1 downto 0);
	 status_reg       : out std_logic_vector(C_NUM_STATUS_REGS*C_REGWIDTH-1 downto 0);
--ports for 2 image sensors
	-- image sensor 1 signals
    ISI1_D             : in std_logic_vector(9 downto 0);
    ISI1_LNE_VLD       : in std_logic;
    ISI1_FRM_VLD       : in std_logic;
    ISI1_TRIGGER       : out std_logic;
    ISI1_RESET_N       : out std_logic;
    ISI1_XMCLK         : out std_logic;
    ISI1_GSHT_CTL      : out std_logic;
    ISI1_PXCLK         : in std_logic;
    ISI1_STB           : in std_logic;
    ISI1_OE_N          : out std_logic;
    ISI1_STDBY	        : out std_logic;
    ISI1_RES0_I	      : in std_logic;
    ISI1_RES0_O	      : out std_logic;
    ISI1_RES0_T	      : out std_logic;
    ISI1_RES1_I	      : in std_logic;   
    ISI1_RES1_O	      : out std_logic;   
    ISI1_RES1_T	      : out std_logic;   		
	-- image sensor 3 signals
    ISI3_D             : in std_logic_vector(9 downto 0);
    ISI3_LNE_VLD       : in std_logic;
    ISI3_FRM_VLD       : in std_logic;
    ISI3_TRIGGER       : out std_logic;
    ISI3_RESET_N       : out std_logic;
    ISI3_XMCLK         : out std_logic;
    ISI3_GSHT_CTL      : out std_logic;
    ISI3_PXCLK         : in std_logic;
    ISI3_STB           : in std_logic;
    ISI3_OE_N          : out std_logic;
    ISI3_STDBY	        : out std_logic;
    ISI3_RES0_I	      : in std_logic;
    ISI3_RES0_O	      : out std_logic;
    ISI3_RES0_T	      : out std_logic;
    ISI3_RES1_I	      : in std_logic;   
    ISI3_RES1_O	      : out std_logic;   
    ISI3_RES1_T	      : out std_logic;   		
	-- stream out 8 pixels
    stream_out_stop   : in std_logic;
    stream_out_valid  : out std_logic;
    stream_out_valid_wide : out std_logic;
    stream_out_data   : out std_logic_vector(C_DWIDTH-1 downto 0);
	 sof : out std_logic;
	 eof : out std_logic
  );
end picsyi2c_imagesensor_light;

-----------------------------------------------------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------------------------------------------------
architecture behavior of picsyi2c_imagesensor_light is

component I2C
  generic
  (
    system_clk	: integer := 100000000;	-- 100 MHz
    i2c_clk	: integer := 100000	-- 100 kHz
  );
	port(	
	Clock		: in		std_logic;
	Reset		: in		std_logic;
	RW_Sel		: in		std_logic;
	Valid_In	: in		std_logic;
	Reg_Addr	: in		std_logic_vector(7 downto 0);
	Data_In		: in		std_logic_vector(15 downto 0);
	Valid_Out	: out		std_logic;
	Data_Out	: out		std_logic_vector(15 downto 0);
	Busy		: out		std_logic;
	Error		: out		std_logic;
	SDA_I		: in		std_logic;
	SDA_O		: out		std_logic;
	SDA_T		: out		std_logic;
	SCL		: out		std_logic
	);
end component;

component imagesensor generic
  (
    C_IMAGE_WIDTH           : integer := 2048;
    C_IMAGE_HIGHT           : integer := 1536;
    C_DWIDTH                : integer := 80;
    C_NUM_CONFIG_REGS       : integer := 2
  );
  port
  (
	-- Streaming I/O
    rst               : in std_logic;
    clk               : in std_logic;
   -- configuration
    config_regs       : in std_logic_vector(C_NUM_CONFIG_REGS*32 - 1 downto 0);
	-- image sensor signals
    ISI_D             : in std_logic_vector(9 downto 0);
    ISI_LNE_VLD       : in std_logic;
    ISI_FRM_VLD       : in std_logic;
    ISI_TRIGGER       : out std_logic;
    ISI_RESET_N       : out std_logic;
    ISI_XMCLK         : out std_logic;
    ISI_GSHT_CTL      : out std_logic;
    ISI_PXCLK         : in std_logic;
    ISI_STB           : in std_logic;
    ISI_OE_N          : out std_logic;
    ISI_STDBY	        : out std_logic;
    ISI_RES0_I	      : in std_logic;
    ISI_RES0_O	      : out std_logic;
    ISI_RES0_T	      : out std_logic;
    ISI_RES1_I	      : in std_logic;   
    ISI_RES1_O	      : out std_logic;   
    ISI_RES1_T	      : out std_logic;   		
	-- stream out 8 pixels
    stream_out_stop   : in std_logic;
    stream_out_valid  : out std_logic;
    stream_out_valid_wide : out std_logic;
    stream_out_data   : out std_logic_vector(C_DWIDTH-1 downto 0);
	--debug
	-- ISI_MASK : in std_logic_vector(7 downto 0);
	sof : out std_logic;
	eof : out std_logic
  );
end component;

--signal reg0,reg1 : std_logic_vector(0 to C_DWIDTH-1);
--register 0 (in MHS first from right, in C struct the first) is 31..0
--register 1 (in MHS second from right, in C struct the second) is 63..32
--register 2,3 is for image sensor

type START_STATES is (IDLE_0, WAIT_FOR_ZERO_1);
signal start_state : START_STATES;
signal start : std_logic;

signal stream1_valid_s : std_logic;
signal stream1_valid_wide_s : std_logic;
signal stream1_data : std_logic_vector(C_DWIDTH-1 downto 0);
signal stream3_valid_s : std_logic;
signal stream3_valid_wide_s : std_logic;
signal stream3_data : std_logic_vector(C_DWIDTH-1 downto 0);
signal sof1_s : std_logic;
signal sof3_s : std_logic;
signal eof1_s : std_logic;
signal eof3_s : std_logic;

  
begin

	--reg0 <= config_reg(C_DWIDTH to 2*C_DWIDTH-1);
	--reg1 <= config_reg(0 to C_DWIDTH-1);
	
	U1:I2C port map(
	Clock => clk,		 
	Reset => rst,
	RW_Sel => config_reg(31), --reg0(0), 		
	Valid_In => start, --valid_in, --slv_reg_write_sel(0)
	Reg_Addr => config_reg(23 downto 16), --reg0(8 to 15),	
	Data_In =>  config_reg(15 downto 0), --reg0(16 to 31),	
	Valid_Out => status_reg(29),	
	Data_Out => status_reg(15 downto 0),	
	Busy => status_reg(31),		
	Error => status_reg(30),	
	SDA_I => I2C_SDA_I,	
	SDA_O => I2C_SDA_O,	
	SDA_T => I2C_SDA_T,	
	SCL => I2C_SCL		
);
  I2C_SEL0 <= config_reg(63); --reg1(0);
  I2C_SEL1 <= config_reg(62); --reg1(1);
  
  status_reg(22 downto 16) <= config_reg(22 downto 16);--reg0(9 to 15);
  status_reg(28) <= config_reg(63); --reg1(0)
  status_reg(27) <= config_reg(62); --reg1(1)

ISI1 : imagesensor generic map(
  C_IMAGE_WIDTH=>C_IMAGE_WIDTH,
    C_IMAGE_HIGHT=>C_IMAGE_HIGHT,
    C_DWIDTH=>C_DWIDTH,
    C_NUM_CONFIG_REGS=>2)--C_NUM_CONFIG_REGS)
	 port map(
    rst => rst, --sensor_reset,
    clk => clk,
    config_regs => config_reg(4*32-1 downto 2*32),
	 ISI_D => ISI1_D,
    ISI_LNE_VLD => ISI1_LNE_VLD,
    ISI_FRM_VLD => ISI1_FRM_VLD,
    ISI_TRIGGER => ISI1_TRIGGER,
    ISI_RESET_N => ISI1_RESET_N,
    ISI_XMCLK => ISI1_XMCLK,
    ISI_GSHT_CTL => ISI1_GSHT_CTL,
    ISI_PXCLK => ISI1_PXCLK,
    ISI_STB => ISI1_STB,
    ISI_OE_N => ISI1_OE_N,
    ISI_STDBY => ISI1_STDBY,
    ISI_RES0_I => ISI1_RES0_I,
    ISI_RES0_O => ISI1_RES0_O,
    ISI_RES0_T => ISI1_RES0_T,
    ISI_RES1_I => ISI1_RES1_I,
    ISI_RES1_O => ISI1_RES1_O,
    ISI_RES1_T => ISI1_RES1_T,		
	-- stream out
    stream_out_stop => stream_out_stop,
    stream_out_valid => stream1_valid_s,
    stream_out_valid_wide => stream1_valid_wide_s,
    stream_out_data => stream1_data,
	--debug
	-- ISI_MASK : in std_logic_vector(7 downto 0);
	sof => sof1_s,
	eof => eof1_s
  );
  
  ISI3 : imagesensor generic map(
  C_IMAGE_WIDTH=>C_IMAGE_WIDTH,
    C_IMAGE_HIGHT=>C_IMAGE_HIGHT,
    C_DWIDTH=>C_DWIDTH,
    C_NUM_CONFIG_REGS=>2)--C_NUM_CONFIG_REGS)
	 port map(
    rst => rst, --sensor_reset
    clk => clk,
    config_regs => config_reg(4*32-1 downto 2*32),
	 ISI_D => ISI3_D,
    ISI_LNE_VLD => ISI3_LNE_VLD,
    ISI_FRM_VLD => ISI3_FRM_VLD,
    ISI_TRIGGER => ISI3_TRIGGER,
    ISI_RESET_N => ISI3_RESET_N,
    ISI_XMCLK => ISI3_XMCLK,
    ISI_GSHT_CTL => ISI3_GSHT_CTL,
    ISI_PXCLK => ISI3_PXCLK,
    ISI_STB => ISI3_STB,
    ISI_OE_N => ISI3_OE_N,
    ISI_STDBY => ISI3_STDBY,
    ISI_RES0_I => ISI3_RES0_I,
    ISI_RES0_O => ISI3_RES0_O,
    ISI_RES0_T => ISI3_RES0_T,
    ISI_RES1_I => ISI3_RES1_I,
    ISI_RES1_O => ISI3_RES1_O,
    ISI_RES1_T => ISI3_RES1_T,		
	-- stream out
    stream_out_stop => stream_out_stop,
    stream_out_valid => stream3_valid_s,
    stream_out_valid_wide => stream3_valid_wide_s,
    stream_out_data => stream3_data,
	--debug
	-- ISI_MASK : in std_logic_vector(7 downto 0);
	sof => sof3_s,
	eof => eof3_s
  );
  
	 --sensor_reset <= Bus2IP_Reset or slv_reg_write(3); 
	 stream_out_valid      <= stream1_valid_s      when config_reg(63 downto 62)="11" else stream3_valid_s;
	 stream_out_valid_wide <= stream1_valid_wide_s when config_reg(63 downto 62)="11" else stream3_valid_wide_s;
	 stream_out_data       <= stream1_data         when config_reg(63 downto 62)="11" else stream3_data;
	 sof                   <= sof1_s               when config_reg(63 downto 62)="11" else sof3_s;
	 eof                   <= eof1_s               when config_reg(63 downto 62)="11" else eof3_s;
  
PROC : process (clk, rst, start)
begin
  if clk'event and clk = '1' then
      if rst = '1' then
        --reg0 <= (others => '0');
        --reg1 <= (others => '0');
		  start_state <= IDLE_0;
		  start <= '0';
      else
			start <= '0';
			case start_state IS
				when IDLE_0 =>
					if config_reg(47) = '1' then
						start <= '1';
						start_state <= WAIT_FOR_ZERO_1;
					end if;
				when WAIT_FOR_ZERO_1 =>
					if( config_reg(47) = '0' ) then
						start_state <= IDLE_0;
					end if;
			end case;
		end if;
  end if;
end process PROC;

end behavior;
