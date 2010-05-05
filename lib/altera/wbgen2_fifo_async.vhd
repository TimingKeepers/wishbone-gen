library ieee;
use ieee.std_logic_1164.all;

library altera_mf;
use altera_mf.all;

library wbgen2;

entity wbgen2_fifo_async is
  generic (
    g_size       : integer;
    g_width      : integer;
    g_usedw_size : integer
    );

  port
    (
      rd_clk_i  : in  std_logic;
      rd_req_i  : in  std_logic;
      rd_data_o : out std_logic_vector(g_width-1 downto 0);

      rd_empty_o : out std_logic;
      rd_full_o  : out std_logic;
      rd_usedw_o : out std_logic_vector(g_usedw_size -1 downto 0);


      wr_clk_i  : in std_logic;
      wr_req_i  : in std_logic;
      wr_data_i : in std_logic_vector(g_width-1 downto 0);

      wr_empty_o : out std_logic;
      wr_full_o  : out std_logic;
      wr_usedw_o : out std_logic_vector(g_usedw_size -1 downto 0)
    );
end wbgen2_fifo_async;

architecture rtl of wbgen2_fifo_async is

  component dcfifo
    generic (
      lpm_numwords       : natural;
      lpm_showahead      : string;
      lpm_type           : string;
      lpm_width          : natural;
      lpm_widthu         : natural;
      overflow_checking  : string;
      rdsync_delaypipe   : natural;
      underflow_checking : string;
      use_eab            : string;
      wrsync_delaypipe   : natural
      );
    port (
      rdfull  : out std_logic;
      wrclk   : in  std_logic;
      rdempty : out std_logic;
      rdreq   : in  std_logic;
      wrusedw : out std_logic_vector (g_usedw_size-1 downto 0);
      wrfull  : out std_logic;
      wrempty : out std_logic;
      rdclk   : in  std_logic;
      q       : out std_logic_vector (g_width-1 downto 0);
      wrreq   : in  std_logic;
      data    : in  std_logic_vector (g_width-1 downto 0);
      rdusedw : out std_logic_vector (g_usedw_size-1 downto 0)
      );
  end component;

begin

  dcfifo_component : dcfifo
    generic map (
--      intended_device_family => "Cyclone III",
      lpm_numwords       => g_size,
      lpm_showahead      => "OFF",
      lpm_type           => "dcfifo",
      lpm_width          => g_width,
      lpm_widthu         => g_usedw_size,
      overflow_checking  => "ON",
      rdsync_delaypipe   => 5,
      underflow_checking => "ON",
      use_eab            => "ON",
      wrsync_delaypipe   => 5
      )
    port map (
      wrclk   => wr_clk_i,
      rdreq   => rd_req_i,
      rdclk   => rd_clk_i,
      wrreq   => wr_req_i,
      data    => wr_data_i,
      rdfull  => rd_full_o,
      rdempty => rd_empty_o,
      wrusedw => wr_usedw_o,
      wrfull  => wr_full_o,
      wrempty => wr_empty_o,
      q       => rd_data_o,
      rdusedw => rd_usedw_o
      );


end rtl;
