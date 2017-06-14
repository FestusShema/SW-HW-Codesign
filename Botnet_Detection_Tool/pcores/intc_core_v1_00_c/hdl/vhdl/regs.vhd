-------------------------------------------------------------------------------
-- $Id: regs.vhd,v 1.8 2004/03/18 15:56:44 lesters Exp $
-------------------------------------------------------------------------------
-- regs - entity / architecture pair
-------------------------------------------------------------------------------
--
--  ***************************************************************************
--  **  Copyright(C) 2003 by Xilinx, Inc. All rights reserved.               **
--  **                                                                       **
--  **  This text contains proprietary, confidential                         **
--  **  information of Xilinx, Inc. , is distributed by                      **
--  **  under license from Xilinx, Inc., and may be used,                    **
--  **  copied and/or disclosed only pursuant to the terms                   **
--  **  of a valid license agreement with Xilinx, Inc.                       **
--  **                                                                       **
--  **  Unmodified source code is guaranteed to place and route,             **
--  **  function and run at speed according to the datasheet                 **
--  **  specification. Source code is provided "as-is", with no              **
--  **  obligation on the part of Xilinx to provide support.                 **
--  **                                                                       **
--  **  Xilinx Hotline support of source code IP shall only include          **
--  **  standard level Xilinx Hotline support, and will only address         **
--  **  issues and questions related to the standard released Netlist        **
--  **  version of the core (and thus indirectly, the original core source). **
--  **                                                                       **
--  **  The Xilinx Support Hotline does not have access to source            **
--  **  code and therefore cannot answer specific questions related          **
--  **  to source HDL. The Xilinx Support Hotline will only be able          **
--  **  to confirm the problem in the Netlist version of the core.           **
--  **                                                                       **
--  **  This copyright and support notice must be retained as part           **
--  **  of this text at all times.                                           **
--  ***************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        regs.vhd
-- Version:         v1.00c
-- Description:     registers for microblaze interrupt controller
--
-------------------------------------------------------------------------------
-- Structure:
--
--              intc.vhd
--                mb_intc_top.vhd
--                  regs.vhd
--
-------------------------------------------------------------------------------
-- Author:      jam
-- History:
--  jam      08/01/2001      -- First version
--  jam      08/06/2001  changed to unisim version of load_reg
--  jam      08/10/2001  changed to target_family_type in common
--  jam      08/21/2001  changed to little endian except for Wr_data and Rd_data
--                       changed registers width to equal number of int inputs
--  jam      11/05/2001  changed le_reg and le_load_reg component instantiations
--                       to generates with xilinx primitive registers
--  jam      12/04/2001  changed to C_FAMILY
--  jam      09/03/2002  added Xon generic
--  jam      11/04/2002      -- roll to rev c
--  lss      01/05/2004  Changed int_det to use int_ack rather than clr_int to 
--                       avoid int_status losing interrupts. Changed regs to
--                       use int_ack as reset to ISR.
--  
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x" 
--      reset signals:                          "rst", "rst_n" 
--      generics:                               "C_*" 
--      user defined types:                     "*_TYPE" 
--      state machine next state:               "*_ns" 
--      state machine current state:            "*_cs" 
--      combinatorial signals:                  "*_cmb" 
--      pipelined or register delay signals:    "*_d#" 
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce" 
--      internal version of output port         "*_i"
--      device pins:                            "*_pin" 
--      ports:                                  - Names begin with Uppercase 
--      processes:                              "*_PROCESS" 
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------

library ieee;
library intc_core_v1_00_c;
library unisim;
use ieee.std_logic_1164.all;
use intc_core_v1_00_c.intc_pkg.all;
use intc_core_v1_00_c.all;
use unisim.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------

entity regs is
  generic
  (
    C_FAMILY     : string   := "virtex2";
    C_Y          : integer  := 0;
    C_X          : integer  := 0;
    C_U_SET      : string   := "intc";
    C_DWIDTH     : positive := WORD_SIZE;
    C_HAS_IPR    : boolean  := false;
    C_HAS_SIE    : boolean  := false;
    C_HAS_CIE    : boolean  := false;
    C_HAS_IVR    : boolean  := false;
    C_RWIDTH     : positive range 2 to WORD_SIZE := 2
  );
  port
  (
    Clk           : in  std_logic;
    Rst           : in  std_logic;
    Int_status    : in  std_logic_vector(C_RWIDTH - 1 downto 0);
    Ints_pending  : in  std_logic_vector(C_RWIDTH - 1 downto 0);
    Reg_sel       : in  reg_sel_type;
    Valid_rd      : in  std_logic;
    Valid_wr      : in  std_logic;
    Wr_data       : in  std_logic_vector(C_DWIDTH - 1 downto 0);
    Global_enable : out std_logic;
    Hw_int_enable : out std_logic;
    Int_ack       : out std_logic_vector(C_RWIDTH - 1 downto 0);
    Int_enables   : out std_logic_vector(C_RWIDTH - 1 downto 0);
    Rd_data       : out std_logic_vector(C_DWIDTH - 1 downto 0);
    Sw_ints       : out std_logic_vector(C_RWIDTH - 1 downto 0)
  );

end regs;

------------------------------------------------------------------------------
-- Architecture
------------------------------------------------------------------------------

architecture imp of regs is
 
  constant REG_PLC_HLDR : std_logic_vector(C_RWIDTH - 1 downto 0) :=
                                                              (others  => '0');
  constant NUM_REGS      : positive := 8;
  constant IER_SEL_WIDTH : positive := 2;
  
  signal data_in    : std_logic_vector(C_RWIDTH - 1 downto 0);
  signal data_out   : std_logic_vector(C_RWIDTH - 1 downto 0);
  signal ier        : std_logic_vector(C_RWIDTH - 1 downto 0);
  signal ier_data   : std_logic_vector(C_RWIDTH - 1 downto 0);
  signal ier_sel    : ier_sel_type;
  signal int_ack_en : std_logic_vector(C_RWIDTH - 1 downto 0);
  signal ipr        : std_logic_vector(C_RWIDTH - 1 downto 0);
  signal isr        : std_logic_vector(C_RWIDTH - 1 downto 0);
  signal ivr        : std_logic_vector(C_RWIDTH - 1 downto 0);
  signal ivr_empty  : boolean;
  signal ld_ier     : std_logic;
  signal ld_mer     : std_logic;
  signal mer        : std_logic_vector(C_RWIDTH - 1 downto 0);
  signal rd         : reg_sel_type;
  signal rd_reg_sel : reg_sel_type;
  signal reg_data   : std_logic_vector(C_RWIDTH*NUM_REGS - 1 downto 0);
  signal sw_ints_en : std_logic_vector(C_RWIDTH - 1 downto 0);

-- LSS 1/05/04
  signal Int_ack_i : std_logic_vector(C_RWIDTH - 1 downto 0); 

  component fdr
    port
    (
      Q : out std_logic;
      D : in std_logic;
      C : in std_logic;
      R : in std_logic
    );
  end component;

  component fdre
    port
    (
      Q  : out std_logic;
      D  : in std_logic;
      C  : in std_logic;
      CE : in std_logic;
      R  : in std_logic
    );
  end component;

  component bus_mux_le is
    generic
    (
      C_W  : integer;
      C_SW : integer;
      C_N  : integer
    );
    port
    (
      Buses_in : in std_logic_vector(((C_W * C_N) - 1) downto 0);
      Sel      : in std_logic_vector(C_SW - 1 downto 0);
      Bus_out  : out std_logic_vector(C_W - 1 downto 0)
    );
  end component bus_mux_le;

  component wr_reg_decode is
    generic (C_WIDTH : positive := 1);
    port
    (
      Reg_addr   : in  reg_sel_type;
      Valid_wr   : in  std_logic;
      Sw_ints_en : out std_logic_vector(C_WIDTH - 1 downto 0);
      Ier_sel    : out ier_sel_type;
      Ld_ier     : out std_logic;
      Int_ack_en : out std_logic_vector(C_WIDTH - 1 downto 0);
      Ld_mer     : out std_logic
    );
  end component;

  component ier_logic is
    generic
    (
      C_WIDTH     : positive := 1;
      C_HAS_SIE   : boolean  := false;
      C_HAS_CIE   : boolean  := false;
      C_SEL_WIDTH : positive := 2
    );
    port
    (
      Data_in  : in  std_logic_vector(C_WIDTH - 1 downto 0);
      IER_in   : in  std_logic_vector(C_WIDTH - 1 downto 0);
      IER_sel  : in  ier_sel_type;
      IER_data : out std_logic_vector(C_WIDTH - 1 downto 0)
    );
  end component;

  component mer_reg is
    generic (C_WIDTH : positive := 1);
    port
    (
      Clk      : in  std_logic;
      Rst      : in  std_logic;
      Data_in  : in  std_logic_vector(1 downto 0);
      Ld       : in  std_logic;
      Data_out : out std_logic_vector(C_WIDTH - 1 downto 0)
    );
  end component;

  component opt_regs is
    generic
    (
      C_WIDTH   : positive := 1;
      C_HAS_IPR : boolean  := false;
      C_HAS_IVR : boolean  := false
    );
    port
    (
      Clk          : in  std_logic;
      Rst          : in  std_logic;
      Pending_ints : in  std_logic_vector(C_WIDTH - 1 downto 0);
      IPR_out      : out std_logic_vector(C_WIDTH - 1 downto 0);
      IVR_out      : out std_logic_vector(C_WIDTH - 1 downto 0);
      IVR_empty    : out boolean
    );
  end component;

-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------

begin

  data_in <= Wr_data(C_RWIDTH - 1 downto 0);

  RD_DATA_MAX_GEN:
  if C_RWIDTH = C_DWIDTH
  generate
    Rd_data(C_RWIDTH - 1 downto 0) <= data_out;
  end generate RD_DATA_MAX_GEN;

  RD_DATA_GEN:
  if C_RWIDTH < C_DWIDTH
  generate
    Rd_data(C_DWIDTH - 1 downto C_RWIDTH) <=
      (others => '1') when ivr_empty and Reg_sel = IVR_DATA_SEL
                      else (others => '0');
    Rd_data(C_RWIDTH - 1 downto 0) <= data_out;
  end generate RD_DATA_GEN;

  ISR_REG_GEN:
  for i in Int_status'range
  generate
    ISR_REG_BIT_I : fdr
    port map
    (
      Q => isr(i),
      D => Int_status(i),
      C => Clk,
--      R => Rst
      R => Int_ack_i(i)
    );
  end generate ISR_REG_GEN;
 
  IER_REG_GEN:
  for i in ier_data'range
  generate
    IER_REG_BIT_I : fdre
    port map
    (
      Q  => ier(i),
      D  => ier_data(i),
      C  => Clk,
      CE => ld_ier,
      R  => Rst
    );
  end generate IER_REG_GEN;
 
  RD_REG_MUX_I: bus_mux_le
    generic map
    (
      C_W  => C_RWIDTH,
      C_SW => REG_SEL_WIDTH,
      C_N  => NUM_REGS
    )
    port map
    (
      Buses_in => reg_data(C_RWIDTH*NUM_REGS - 1 downto 0),
      Sel      => rd_reg_sel(REG_SEL_WIDTH - 1 downto 0),
      Bus_out  => data_out
    );
 
  WR_REG_DECODE_I: wr_reg_decode
    generic map (C_WIDTH => C_RWIDTH)
    port map
    (
      Reg_addr   => Reg_sel,
      Valid_wr   => Valid_wr,
      Sw_ints_en => sw_ints_en,
      Ier_sel    => ier_sel,
      Ld_ier     => ld_ier,
      Int_ack_en => int_ack_en,
      Ld_mer     => ld_mer
    );
 
  IER_LOGIC_I: ier_logic
    generic map
    (
      C_WIDTH     => C_RWIDTH,
      C_HAS_SIE   => C_HAS_SIE,
      C_HAS_CIE   => C_HAS_CIE,
      C_SEL_WIDTH => IER_SEL_WIDTH
    )
    port map
    (
      Data_in  => data_in,
      IER_in   => ier,
      IER_sel  => ier_sel,
      IER_data => ier_data
    );
 
  MER_REG_I: mer_reg
    generic map (C_WIDTH => C_RWIDTH)
    port map
    (
      Clk      => Clk,
      Rst      => Rst,
      Data_in  => data_in(1 downto 0),
      Ld       => ld_mer,
      Data_out => mer
    );
 
  OPT_REGS_I: opt_regs
    generic map
    (
      C_WIDTH   => C_RWIDTH,
      C_HAS_IPR => C_HAS_IPR,
      C_HAS_IVR => C_HAS_IVR 
    )
    port map
    (
      Clk          => Clk,
      Rst          => Rst,
      Pending_ints => Ints_pending,
      IPR_out      => ipr,
      IVR_out      => ivr,
      IVR_empty    => ivr_empty
    );
 
  Int_enables <= ier;
 
  Sw_ints <= data_in and sw_ints_en;
 
  -- Int_ack <= data_in and int_ack_en;  LSS 1/05/04
  Int_ack_i <= data_in and int_ack_en;
  Int_ack <= Int_ack_i; 
 
  Global_enable <= mer(0);
 
  Hw_int_enable <= mer(1);
 
  reg_data <= mer &
              ivr &
              REG_PLC_HLDR &  -- cie - write only location
              REG_PLC_HLDR &  -- sie - write only location
              REG_PLC_HLDR &  -- iar - write only location
              ier &
              ipr &
              isr;
 
  rd_reg_sel <= Reg_sel and rd;
 
  rd <= (others => Valid_rd);

end imp;

