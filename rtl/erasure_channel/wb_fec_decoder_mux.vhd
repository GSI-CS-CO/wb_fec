--! @file wb_fec.vhd
--! @brief  FEC
--! @author C.Prados <c.prados@gsi.de> <bradomyn@gmail.com>
--!
--! See the file "LICENSE" for the full license governing this code.
--!----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fec_pkg.all;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;

entity wb_fec_decoder_mux is
  generic (
    g_num_block     : integer := 4;
    g_en_fec_enc    : boolean := true;
    g_en_fec_dec    : boolean := false;
    g_en_golay      : boolean := false;
    g_en_dec_time   : boolean := false);
  port (
    clk_i         : in  std_logic;
    rst_n_i       : in  std_logic;
    snk_i         : in  t_wrf_sink_in;
    snk_o         : out t_wrf_sink_out;
    src_i         : in  t_wrf_source_in;
    src_o         : out t_wrf_source_out;
    ctrl_reg_i    : in  t_fec_ctrl_reg;
    stat_dec_o    : out t_dec_err);
end wb_fec_decoder_mux;

architecture rtl of wb_fec_decoder_mux is
  signal fec_ctrl_reg : t_fec_ctrl_reg;
  signal fec_dec_reg  : t_dec_err;

  signal bypass_in  : t_wrf_sink_in;
  signal bypass_out : t_wrf_sink_out;

  signal dec_snk_in  : t_wrf_sink_in;
  signal dec_snk_out : t_wrf_sink_out;
  signal dec_src_in  : t_wrf_source_in;
  signal dec_src_out : t_wrf_source_out;

  signal mux_class   : t_wrf_mux_class(1 downto 0);

begin

  mux_class(0)  <= x"40"; --FEC
  mux_class(1)  <= x"80"; -- Etherbone

  IN_WBP_Mux : xwrf_mux
      generic map(
        g_muxed_ports => 2)
      port map (
        clk_sys_i     => clk_i,
        rst_n_i       => rst_n_i,
        ep_src_o      => open,
        ep_src_i      => c_dummy_src_in,
        ep_snk_o      => snk_o,
        ep_snk_i      => snk_i,
        mux_src_o(0)  => bypass_in,
        mux_src_o(1)  => dec_snk_in,
        mux_src_i(0)  => bypass_out,
        mux_src_i(1)  => dec_snk_out,
        mux_snk_o     => open,
        mux_snk_i(0)  => c_dummy_snk_in,
        mux_snk_i(1)  => c_dummy_snk_in,
        mux_class_i   => mux_class);

  FEC_DEC : wb_fec_decoder
    generic map (
    g_num_block   => 4,
    g_en_golay    => FALSE)
    port map (
      clk_i       => clk_i,
      rst_n_i     => rst_n_i,
      snk_i       => dec_snk_in,
      snk_o       => dec_snk_out,
      src_i       => dec_src_in,
      src_o       => dec_src_out,
      ctrl_reg_i  => fec_ctrl_reg,
      stat_dec_o  => fec_dec_reg);

  OUT_WBP_Mux : xwrf_mux
    generic map(
      g_muxed_ports => 2)
    port map (
      clk_sys_i     => clk_i,
      rst_n_i       => rst_n_i,
      ep_src_o      => src_o,
      ep_src_i      => src_i,
      ep_snk_o      => open,
      ep_snk_i      => c_dummy_snk_in,
      mux_src_o     => open,
      mux_src_i(0)  => c_dummy_src_in,
      mux_src_i(1)  => c_dummy_src_in,
      mux_snk_o(0)  => bypass_out,
      mux_snk_o(1)  => dec_src_in,
      mux_snk_i(0)  => bypass_in,
      mux_snk_i(1)  => dec_src_out,
      mux_class_i   => mux_class);

end rtl;
