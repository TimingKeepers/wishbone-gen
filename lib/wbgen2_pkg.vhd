library ieee;
use ieee.std_logic_1164.all;

library wbgen2;

package wbgen2_pkg is

  
  component wbgen2_dpssram
    generic (
      g_data_width : natural;
      g_size       : natural;
      g_addr_width : natural;
      g_dual_clock : boolean;
      g_use_bwsel  : boolean);
    port (
      clk_a_i   : in  std_logic;
      clk_b_i   : in  std_logic;
      addr_a_i  : in  std_logic_vector(g_addr_width-1 downto 0);
      addr_b_i  : in  std_logic_vector(g_addr_width-1 downto 0);
      data_a_i  : in  std_logic_vector(g_data_width-1 downto 0);
      data_b_i  : in  std_logic_vector(g_data_width-1 downto 0);
      data_a_o  : out std_logic_vector(g_data_width-1 downto 0);
      data_b_o  : out std_logic_vector(g_data_width-1 downto 0);
      bwsel_a_i : in  std_logic_vector((g_data_width+7)/8-1 downto 0);
      bwsel_b_i : in  std_logic_vector((g_data_width+7)/8-1 downto 0);
      rd_a_i    : in  std_logic;
      rd_b_i    : in  std_logic;
      wr_a_i    : in  std_logic;
      wr_b_i    : in  std_logic);
  end component;
  component wbgen2_eic
    generic (
      g_num_interrupts : natural;
      g_irq00_mode     : integer;
      g_irq01_mode     : integer;
      g_irq02_mode     : integer;
      g_irq03_mode     : integer;
      g_irq04_mode     : integer;
      g_irq05_mode     : integer;
      g_irq06_mode     : integer;
      g_irq07_mode     : integer;
      g_irq08_mode     : integer;
      g_irq09_mode     : integer;
      g_irq0a_mode     : integer;
      g_irq0b_mode     : integer;
      g_irq0c_mode     : integer;
      g_irq0d_mode     : integer;
      g_irq0e_mode     : integer;
      g_irq0f_mode     : integer;
      g_irq10_mode     : integer;
      g_irq11_mode     : integer;
      g_irq12_mode     : integer;
      g_irq13_mode     : integer;
      g_irq14_mode     : integer;
      g_irq15_mode     : integer;
      g_irq16_mode     : integer;
      g_irq17_mode     : integer;
      g_irq18_mode     : integer;
      g_irq19_mode     : integer;
      g_irq1a_mode     : integer;
      g_irq1b_mode     : integer;
      g_irq1c_mode     : integer;
      g_irq1d_mode     : integer;
      g_irq1e_mode     : integer;
      g_irq1f_mode     : integer);
    port (
      rst_n_i          : in  std_logic;
      clk_i            : in  std_logic;
      irq_i            : in  std_logic_vector(g_num_interrupts-1 downto 0);
      reg_imr_o        : out std_logic_vector(g_num_interrupts-1 downto 0);
      reg_ier_i        : in  std_logic_vector(g_num_interrupts-1 downto 0);
      reg_ier_wr_stb_i : in  std_logic;
      reg_idr_i        : in  std_logic_vector(g_num_interrupts-1 downto 0);
      reg_idr_wr_stb_i : in  std_logic;
      reg_isr_o        : out std_logic_vector(g_num_interrupts-1 downto 0);
      reg_isr_i        : in  std_logic_vector(g_num_interrupts-1 downto 0);
      reg_isr_wr_stb_i : in  std_logic;
      wb_irq_o         : out std_logic);
  end component;
  
end wbgen2_pkg;
