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
--use work.golay_pk.all;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;

entity wb_fec_mux is
  generic (
    g_num_block     : integer := 4;
    g_mux_class     : t_mux_class := c_default_classes;
    g_oust_ethtype  : boolean := true;
    g_en_fec_enc    : boolean := true;
    g_en_fec_dec    : boolean := false;
    g_en_golay      : boolean := false;
    g_en_dec_time   : boolean := false);
  port (
    clk_i           : in  std_logic;
    rst_n_i         : in  std_logic;
    fec_timestamps_i: in  t_txtsu_timestamp;
    fec_tm_tai_i    : in  std_logic_vector(39 downto 0);
    fec_tm_cycle_i  : in  std_logic_vector(27 downto 0);
    eb2fec_snk_i    : in  t_wrf_sink_in;
    eb2fec_snk_o    : out t_wrf_sink_out;
    fec2eb_src_i    : in  t_wrf_source_in;
    fec2eb_src_o    : out t_wrf_source_out;

    wr2fec_snk_i    : in  t_wrf_sink_in;
    wr2fec_snk_o    : out t_wrf_sink_out;
    fec2wr_src_i    : in  t_wrf_source_in;
    fec2wr_src_o    : out t_wrf_source_out;
    wb_slave_o      : out t_wishbone_slave_out;
    wb_slave_i      : in  t_wishbone_slave_in);
end wb_fec_mux;

architecture rtl of wb_fec_mux is
  signal fec_ctrl_reg : t_fec_ctrl_reg;
  signal fec_dec_reg  : t_dec_err;
  signal fec_enc_reg  : t_enc_err;
  signal fec_stat_reg : t_fec_stat_reg;

  signal enc_bypass_in  : t_wrf_sink_in;
  signal enc_bypass_out : t_wrf_sink_out;
  signal dec_bypass_in  : t_wrf_source_in;
  signal dec_bypass_out : t_wrf_source_out;

  signal dec_snk_in  : t_wrf_sink_in;
  signal dec_snk_out : t_wrf_sink_out;
  signal dec_src_in  : t_wrf_source_in;
  signal dec_src_out : t_wrf_source_out;

  signal enc_snk_in  : t_wrf_sink_in;
  signal enc_snk_out : t_wrf_sink_out;
  signal enc_src_in  : t_wrf_source_in;
  signal enc_src_out : t_wrf_source_out;

  signal mux_class    : t_wrf_mux_class(1 downto 0);

begin

  y_WB_FEC_ENC : if g_en_fec_enc generate
  FEC_ENC : wb_fec_encoder
    generic map (
      g_num_block  => 4,
      g_en_golay   => FALSE)
    port map (
      clk_i       => clk_i,
      rst_n_i     => rst_n_i,
      snk_i       => enc_snk_in,
      snk_o       => enc_snk_out,
      src_i       => enc_src_in,
      src_o       => enc_src_out,
      ctrl_reg_i  => fec_ctrl_reg,
      stat_enc_o  => fec_enc_reg);

    fec_stat_reg.enc_err  <= fec_enc_reg;
  end generate;

  n_WB_FEC_ENC : if not g_en_fec_enc generate
    enc_snk_out <= enc_src_in;
    enc_src_out <= enc_snk_in;
    fec_stat_reg.enc_err  <= c_enc_err;
  end generate;

  y_WB_FEC_DEC : if g_en_fec_dec generate
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

    fec_stat_reg.dec_err  <= fec_dec_reg;
  end generate;

  n_WB_FEC_DEC : if not g_en_fec_dec generate
    dec_src_out <= dec_snk_in;
    dec_snk_out <= dec_src_in;
    fec_stat_reg.dec_err  <= c_dec_err;
  end generate;

  mux_class(0)  <= g_mux_class(0); -- x"40" Etherbone
  mux_class(1)  <= g_mux_class(1); -- x"80" FEC

  WRF_Mux2WR : xwrf_mux
      generic map(
        g_muxed_ports => 2)
      port map (
        clk_sys_i     => clk_i,
        rst_n_i       => rst_n_i,
        ep_src_o      => fec2wr_src_o,
        ep_src_i      => fec2wr_src_i,
        ep_snk_o      => wr2fec_snk_o,
        ep_snk_i      => wr2fec_snk_i,
        mux_src_o(0)  => dec_bypass_out,
        mux_src_o(1)  => dec_snk_in,
        mux_src_i(0)  => dec_bypass_in,
        mux_src_i(1)  => dec_snk_out,
        mux_snk_o(0)  => enc_bypass_out,
        mux_snk_o(1)  => enc_src_in,
        mux_snk_i(0)  => enc_bypass_in,
        mux_snk_i(1)  => enc_src_out,
        mux_class_i   => mux_class);

  WRF_Mux2EB : xwrf_mux
      generic map(
        g_muxed_ports => 2)
      port map (
        clk_sys_i     => clk_i,
        rst_n_i       => rst_n_i,
        ep_src_o      => fec2eb_src_o,
        ep_src_i      => fec2eb_src_i,
        ep_snk_o      => eb2fec_snk_o,
        ep_snk_i      => eb2fec_snk_i,
        mux_src_o(0)  => enc_bypass_in,
        mux_src_o(1)  => enc_snk_in,
        mux_src_i(0)  => enc_bypass_out,
        mux_src_i(1)  => enc_snk_out,
        mux_snk_o(0)  => dec_bypass_in,
        mux_snk_o(1)  => dec_src_in,
        mux_snk_i(0)  => dec_bypass_out,
        mux_snk_i(1)  => dec_src_out,
        mux_class_i   => mux_class);

  WB_SLAVE: wb_slave_fec
    port map (
      clk_i           => clk_i,
      rst_n_i         => rst_n_i,
      wb_slave_i      => wb_slave_i,
      wb_slave_o      => wb_slave_o,
      fec_stat_reg_i  => fec_stat_reg,
      fec_ctrl_reg_o  => fec_ctrl_reg,
      time_code_i     => c_time_code);
end rtl;
