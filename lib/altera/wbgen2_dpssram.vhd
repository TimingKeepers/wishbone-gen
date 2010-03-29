library ieee;
use ieee.std_logic_1164.all;

library altera_mf;
use altera_mf.all;

library wbgen2;
use wbgen2.all;


entity wbgen2_dpssram  is

  generic (
    g_data_width : natural;
    g_size       : natural;
    g_addr_width : natural;
    g_dual_clock : boolean := false;
    g_use_bwsel  : boolean := false);

  port (
    clk_a_i : in std_logic;
    clk_b_i : in std_logic;

    addr_a_i : in std_logic_vector(g_addr_width-1 downto 0);
    addr_b_i : in std_logic_vector(g_addr_width-1 downto 0);

    data_a_i : in std_logic_vector(g_data_width-1 downto 0);
    data_b_i : in std_logic_vector(g_data_width-1 downto 0);

    data_a_o : out std_logic_vector(g_data_width-1 downto 0);
    data_b_o : out std_logic_vector(g_data_width-1 downto 0);

    bwsel_a_i : in std_logic_vector((g_data_width+7)/8-1 downto 0);
    bwsel_b_i : in std_logic_vector((g_data_width+7)/8-1 downto 0);

    rd_a_i : in std_logic;
    rd_b_i : in std_logic;

    wr_a_i : in std_logic;
    wr_b_i : in std_logic
    );

end wbgen2_dpssram;


architecture syn of wbgen2_dpssram is

  component altsyncram
    generic (
      address_reg_b                 : string;
      byteena_reg_b                 : string;
      byte_size                     : natural;
      clock_enable_input_a          : string;
      clock_enable_input_b          : string;
      clock_enable_output_a         : string;
      clock_enable_output_b         : string;
      indata_reg_b                  : string;
--      intended_device_family        : string;
      lpm_type                      : string;
      numwords_a                    : natural;
      numwords_b                    : natural;
      operation_mode                : string;
      outdata_aclr_a                : string;
      outdata_aclr_b                : string;
      outdata_reg_a                 : string;
      outdata_reg_b                 : string;
      power_up_uninitialized        : string;
      read_during_write_mode_port_a : string;
      read_during_write_mode_port_b : string;
      widthad_a                     : natural;
      widthad_b                     : natural;
      width_a                       : natural;
      width_b                       : natural;
      width_byteena_a               : natural;
      width_byteena_b               : natural;
      wrcontrol_wraddress_reg_b     : string);
    port (
      wren_a    : in  std_logic;
      clock0    : in  std_logic;
      wren_b    : in  std_logic;
      clock1    : in  std_logic;
      byteena_a : in  std_logic_vector ((g_data_width+7)/8-1 downto 0);
      byteena_b : in  std_logic_vector ((g_data_width+7)/8-1 downto 0);
      address_a : in  std_logic_vector ((g_addr_width-1) downto 0);
      address_b : in  std_logic_vector ((g_addr_width-1) downto 0);
      rden_a    : in  std_logic;
      q_a       : out std_logic_vector ((g_data_width-1) downto 0);
      rden_b    : in  std_logic;
      q_b       : out std_logic_vector ((g_data_width-1) downto 0);
      data_a    : in  std_logic_vector ((g_data_width-1) downto 0);
      data_b    : in  std_logic_vector ((g_data_width-1) downto 0));
  end component;

  signal clksel      : string(1 to 6);
  signal bwsel_int_a : std_logic_vector((g_data_width+7)/8-1 downto 0);
  signal bwsel_int_b : std_logic_vector((g_data_width+7)/8-1 downto 0);

  
begin  -- syn

  genram1: if(g_dual_clock = true) generate

      altsyncram_component : altsyncram
    generic map (
      address_reg_b                 => "CLOCK1",
      byteena_reg_b                 => "CLOCK1",
      byte_size                     => 8,
      clock_enable_input_a          => "BYPASS",
      clock_enable_input_b          => "BYPASS",
      clock_enable_output_a         => "BYPASS",
      clock_enable_output_b         => "BYPASS",
      indata_reg_b                  => "CLOCK1",
--      intended_device_family        => "Cyclone III",
      lpm_type                      => "altsyncram",
      numwords_a                    => g_size,
      numwords_b                    => g_size,
      operation_mode                => "BIDIR_DUAL_PORT",
      outdata_aclr_a                => "NONE",
      outdata_aclr_b                => "NONE",
      outdata_reg_a                 => "UNREGISTERED",
      outdata_reg_b                 => "UNREGISTERED",
      power_up_uninitialized        => "FALSE",
      read_during_write_mode_port_a => "OLD_DATA",
      read_during_write_mode_port_b => "OLD_DATA",
      widthad_a                     => g_addr_width,
      widthad_b                     => g_addr_width,
      width_a                       => g_data_width,
      width_b                       => g_data_width,
      width_byteena_a               => (g_data_width+7)/8,
      width_byteena_b               => (g_data_width+7)/8,
      wrcontrol_wraddress_reg_b     => "CLOCK1"
      )
    port map (
      wren_a    => wr_a_i,
      wren_b    => wr_b_i,
      clock0    => clk_a_i,
      clock1    => clk_b_i,
      byteena_a => bwsel_int_a,
      byteena_b => bwsel_int_b,
      address_a => addr_a_i,
      address_b => addr_b_i,
      rden_a    => rd_a_i,
      rden_b    => rd_b_i,
      data_a    => data_a_i,
      data_b    => data_b_i,
      q_a       => data_a_o,
      q_b       => data_b_o
      );

  end generate genram1;
  
  genram2: if(g_dual_clock = false) generate

      altsyncram_component : altsyncram
    generic map (
      address_reg_b                 => "CLOCK0",
      byteena_reg_b                 => "CLOCK0",
      byte_size                     => 8,
      clock_enable_input_a          => "BYPASS",
      clock_enable_input_b          => "BYPASS",
      clock_enable_output_a         => "BYPASS",
      clock_enable_output_b         => "BYPASS",
      indata_reg_b                  => "CLOCK0",
    --  intended_device_family        => "Cyclone III",
      lpm_type                      => "altsyncram",
      numwords_a                    => g_size,
      numwords_b                    => g_size,
      operation_mode                => "BIDIR_DUAL_PORT",
      outdata_aclr_a                => "NONE",
      outdata_aclr_b                => "NONE",
      outdata_reg_a                 => "UNREGISTERED",
      outdata_reg_b                 => "UNREGISTERED",
      power_up_uninitialized        => "FALSE",
      read_during_write_mode_port_a => "OLD_DATA",
      read_during_write_mode_port_b => "OLD_DATA",
      widthad_a                     => g_addr_width,
      widthad_b                     => g_addr_width,
      width_a                       => g_data_width,
      width_b                       => g_data_width,
      width_byteena_a               => (g_data_width+7)/8,
      width_byteena_b               => (g_data_width+7)/8,
      wrcontrol_wraddress_reg_b     => "CLOCK0"
      )
    port map (
      wren_a    => wr_a_i,
      wren_b    => wr_b_i,
      clock0    => clk_a_i,
  --    clock1    => clk_b_i,
      byteena_a => bwsel_int_a,
      byteena_b => bwsel_int_b,
      address_a => addr_a_i,
      address_b => addr_b_i,
      rden_a    => rd_a_i,
      rden_b    => rd_b_i,
      data_a    => data_a_i,
      data_b    => data_b_i,
      q_a       => data_a_o,
      q_b       => data_b_o
      );

  end generate genram2;

--  clksel <= ;
  
  genbwsel1: if(g_use_bwsel = true) generate
    bwsel_int_a <= bwsel_a_i;
    bwsel_int_b <= bwsel_b_i;
  end generate genbwsel1;

  genbwsel2: if(g_use_bwsel = false) generate
    bwsel_int_a <= (others => '1');
    bwsel_int_b <= (others => '1');
  end generate genbwsel2;







end syn;
