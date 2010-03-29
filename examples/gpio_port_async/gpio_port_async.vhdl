-------------------------------------------------------------------------------
-- Title      : A sample GPIO port with asynchronous clock (wbgen2 example)
-- Project    : 
-------------------------------------------------------------------------------
-- File       : gpio_port_async.vhdl
-- Author     : T.W.
-- Company    : 
-- Created    : 2010-02-22
-- Last update: 2010-03-16
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2010 T.W.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2010-02-22  1.0      slayer  Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;

entity gpio_port_async is

  port (
    rst_n_i   : in  std_logic;
    wb_clk_i  : in  std_logic;
    wb_addr_i : in  std_logic_vector(2 downto 0);
    wb_data_i : in  std_logic_vector(31 downto 0);
    wb_data_o : out std_logic_vector(31 downto 0);
    wb_cyc_i  : in  std_logic;
    wb_sel_i  : in  std_logic_vector(3 downto 0);
    wb_stb_i  : in  std_logic;
    wb_we_i   : in  std_logic;
    wb_ack_o  : out std_logic;

-- our port :)
    gpio_clk_i: in std_logic;           -- asynchronous clock for the GPIO port
    gpio_pins_b : inout std_logic_vector(31 downto 0)
    );
end gpio_port_async;

architecture syn of gpio_port_async is

  component wb_slave_gpio_port_async
    port (
      rst_n_i          : in  std_logic;
      wb_clk_i         : in  std_logic;
      wb_addr_i        : in  std_logic_vector(2 downto 0);
      wb_data_i        : in  std_logic_vector(31 downto 0);
      wb_data_o        : out std_logic_vector(31 downto 0);
      wb_cyc_i         : in  std_logic;
      wb_sel_i         : in  std_logic_vector(3 downto 0);
      wb_stb_i         : in  std_logic;
      wb_we_i          : in  std_logic;
      wb_ack_o         : out std_logic;
      gpio_async_clk_i : in  std_logic;
      gpio_ddr_o       : out std_logic_vector(31 downto 0);
      gpio_psr_i       : in  std_logic_vector(31 downto 0);
      gpio_pdr_o       : out std_logic_vector(31 downto 0);
      gpio_pdr_wr_o    : out std_logic;
      gpio_sopr_o      : out std_logic_vector(31 downto 0);
      gpio_sopr_wr_o   : out std_logic;
      gpio_copr_o      : out std_logic_vector(31 downto 0);
      gpio_copr_wr_o   : out std_logic);
  end component;

  signal gpio_ddr     : std_logic_vector(31 downto 0);
  signal gpio_psr     : std_logic_vector(31 downto 0);
  signal gpio_pdr     : std_logic_vector(31 downto 0);
  signal gpio_pdr_wr  : std_logic;
  signal gpio_sopr    : std_logic_vector(31 downto 0);
  signal gpio_sopr_wr : std_logic;
  signal gpio_copr    : std_logic_vector(31 downto 0);
  signal gpio_copr_wr : std_logic;

-- regsiter containing current output state
  signal gpio_reg : std_logic_vector(31 downto 0);

-- registers for synchronization of input pins
  signal gpio_pins_sync1 : std_logic_vector(31 downto 0);
  signal gpio_pins_sync0 : std_logic_vector(31 downto 0);
  
begin  -- syn

  wb_slave : wb_slave_gpio_port_async
    port map (
      rst_n_i        => rst_n_i,
      wb_clk_i       => wb_clk_i,
      wb_addr_i      => wb_addr_i,
      wb_data_i      => wb_data_i,
      wb_data_o      => wb_data_o,
      wb_cyc_i       => wb_cyc_i,
      wb_sel_i       => wb_sel_i,
      wb_stb_i       => wb_stb_i,
      wb_we_i        => wb_we_i,
      wb_ack_o       => wb_ack_o,
      gpio_async_clk_i => gpio_clk_i,
      gpio_ddr_o     => gpio_ddr,
      gpio_psr_i     => gpio_pins_sync1,
      gpio_pdr_o     => gpio_pdr,
      gpio_pdr_wr_o  => gpio_pdr_wr,
      gpio_sopr_o    => gpio_sopr,
      gpio_sopr_wr_o => gpio_sopr_wr,
      gpio_copr_o    => gpio_copr,
      gpio_copr_wr_o => gpio_copr_wr);


  process (gpio_clk_i, rst_n_i)
  begin  -- process
    if(rst_n_i = '0') then
      gpio_reg <= (others => '0');
    elsif rising_edge(gpio_clk_i) then

      if(gpio_pdr_wr = '1') then        -- write operation to "PDR" register -
                                        -- set the new values of GPIO outputs
        gpio_reg <= gpio_pdr;
      end if;

      if(gpio_sopr_wr = '1') then       -- write to "SOPR" reg - set ones
        for i in 0 to 31 loop
          if(gpio_sopr(i) = '1') then
            gpio_reg(i) <= '1';
          end if;
        end loop;
      end if;

      if(gpio_copr_wr = '1') then       -- write to "COPR" reg - set zeros
        for i in 0 to 31 loop
          if(gpio_copr(i) = '1') then
            gpio_reg(i) <= '0';
          end if;
        end loop;
      end if;
    end if;
  end process;


-- synchronizing process for input pins
  synchronize_input_pins : process (gpio_clk_i, rst_n_i)
  begin  -- process
    if(rst_n_i = '0') then
      gpio_pins_sync0 <= (others => '0');
      gpio_pins_sync1 <= (others => '0');
    elsif rising_edge(gpio_clk_i) then
      gpio_pins_sync0 <= gpio_pins_b;
      gpio_pins_sync1 <= gpio_pins_sync0;
    end if;
  end process;

-- generate the tristate buffers for I/O pins
  gen_tristates : for i in 0 to 31 generate
      gpio_pins_b(i) <= gpio_reg(i) when gpio_ddr(i) = '1' else 'Z';
  end generate gen_tristates;
  
  
  

end syn;


