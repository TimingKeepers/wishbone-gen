
library ieee;
use ieee.std_logic_1164.all;

library altera_mf;
use altera_mf.all;

library wbgen2;

entity wbgen2_fifo_sync is
  generic (
    g_width      : integer;
    g_size       : integer;
    g_usedw_size : integer);

  
  port
    (
      clk_i     : in std_logic;
      wr_data_i : in std_logic_vector(g_width-1 downto 0);
      wr_req_i  : in std_logic;

      rd_data_o : out std_logic_vector(g_width-1 downto 0);
      rd_req_i  : in  std_logic;

      wr_empty_o : out std_logic;
      wr_full_o  : out std_logic;
      wr_usedw_o : out std_logic_vector(g_usedw_size -1 downto 0);

      rd_empty_o : out std_logic;
      rd_full_o  : out std_logic;
      rd_usedw_o : out std_logic_vector(g_usedw_size -1 downto 0)

      );
end wbgen2_fifo_sync;


architecture rtl of wbgen2_fifo_sync is

  component scfifo
    generic (
      add_ram_output_register : string;
--      intended_device_family  : string;
      lpm_numwords            : natural;
      lpm_showahead           : string;
      lpm_type                : string;
      lpm_width               : natural;
      lpm_widthu              : natural;
      overflow_checking       : string;
      underflow_checking      : string;
      use_eab                 : string
      );
    port (
      usedw : out std_logic_vector (g_usedw_size-1 downto 0);
      rdreq : in  std_logic;
      empty : out std_logic;
      clock : in  std_logic;
      q     : out std_logic_vector (12 downto 0);
      wrreq : in  std_logic;
      data  : in  std_logic_vector (12 downto 0);
      full  : out std_logic
      );
  end component;

  signal empty_int, full_int : std_logic;
  signal usedw_int           : std_logic_vector(g_usedw_size -1 downto 0);
  
  
begin
  
  scfifo_component : scfifo
    generic map (
      add_ram_output_register => "ON",
--      intended_device_family  => "Cyclone III",
      lpm_numwords            => g_size,
      lpm_showahead           => "OFF",
      lpm_type                => "scfifo",
      lpm_width               => g_width,
      lpm_widthu              => g_usedw_size,
      overflow_checking       => "ON",
      underflow_checking      => "ON",
      use_eab                 => "ON"
      )
    port map (
      rdreq => rd_req_i,
      clock => clk_i,
      wrreq => wr_req_i,
      data  => wr_data_i,
      usedw => usedw_int,
      empty => empty_int,
      q     => rd_data_o,
      full  => full_int
      );

  rd_empty_o <= empty_int;
  rd_full_o <= full_int;
  rd_usedw_o <= usedw_int;

  wr_empty_o <= empty_int;
  wr_full_o <= full_int;
  wr_usedw_o <= usedw_int;
  
  
end rtl;
