library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fec_pkg.all;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.wrf_pkt_dropper_pkg.all;
use work.xwrf_pkt_dropper_pkg.all;

entity xwrf_pkt_dropper is
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
end xwrf_pkt_dropper;

architecture rtl of xwrf_pkt_dropper is

  signal snk_i  :  t_wrf_sink_in;
  signal snk_o  :  t_wrf_sink_out;
  signal src_i  :  t_wrf_source_in;
  signal src_o  :  t_wrf_source_out;
  signal wb_o   :  t_wishbone_slave_out;
  signal wb_i   :  t_wishbone_slave_in;

begin

 DROPPER : component wrf_pkt_dropper
   generic map (
    g_ena_sim   => true,
    g_num_block => 4)
   port map (
     clk_i     => clk_i,
     rst_n_i   => rst_n_i,
     snk_i     => snk_i,
     snk_o     => snk_o,
     src_i     => src_i,
     src_o     => src_o,
     wb_o      => wb_o,
     wb_i      => wb_i);

  src_cyc    <= src_o.cyc;
  src_stb    <= src_o.stb;
  src_dat    <= src_o.dat;
  src_adr    <= src_o.adr;
  src_we     <= src_o.we;
  src_sel    <= src_o.sel;

  src_i.ack   <= src_ack;
  src_i.stall <= src_stall;

  snk_i.cyc     <= snk_cyc;
  snk_i.stb     <= snk_stb;
  snk_i.dat     <= snk_dat;
  snk_i.adr     <= snk_adr;
  snk_i.we      <= snk_we;
  snk_i.sel     <= snk_sel;

  snk_ack   <= snk_o.ack;
  snk_stall <= snk_o.stall;

  wb_ack    <= wb_o.ack;
  --wb_err    <= wb_o.err;
  --wb_rty    <= wb_o.rty;
  wb_stall  <= wb_o.stall;
  --wb_int    <= wb_o.int;
  wb_dat_o  <= wb_o.dat;

  wb_i.cyc  <= wb_cyc;
  wb_i.stb  <= wb_stb;
  wb_i.adr  <= wb_adr;
  wb_i.sel  <= wb_sel;
  wb_i.we   <= wb_we;
  wb_i.dat  <= wb_dat_i;

end rtl;

