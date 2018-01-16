library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.wrf_pkt_dropper_pkg.all;

package xwrf_pkt_dropper_pkg is
  component xwrf_pkt_dropper is
      port (
        clk_i     : in  std_logic;
        rst_n_i   : in  std_logic;

        snk_ack   : out std_logic;
        snk_stall : out std_logic;
        snk_adr   : in  std_logic_vector(1 downto 0);
        snk_dat   : in  std_logic_vector(15 downto 0);
        snk_cyc   : in  std_logic;
        snk_stb   : in  std_logic;
        snk_we    : in  std_logic;
        snk_sel   : in  std_logic_vector(1 downto 0);

        src_ack   : in  std_logic;
        src_stall : in  std_logic;
        src_adr   : out std_logic_vector(1 downto 0);
        src_dat   : out std_logic_vector(15 downto 0);
        src_cyc   : out std_logic;
        src_stb   : out std_logic;
        src_we    : out std_logic;
        src_sel   : out std_logic_vector(1 downto 0);

        wb_ack    : out std_logic;
        wb_stall  : out std_logic;
        wb_cyc    : in std_logic;
        wb_stb    : in std_logic;
        wb_adr    : in t_wishbone_address;
        wb_sel    : in t_wishbone_byte_select;
        wb_we     : in std_logic;
        wb_dat_o  : out t_wishbone_data;
        wb_dat_i  : in t_wishbone_data);
  end component;
end package xwrf_pkt_dropper_pkg;
