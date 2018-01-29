--! @file xwb_fec.vhd
--! @brief  FEC wrapper for simulation
--! @author C.Prados <cprados@mailfence.com>
--!
--! See the file "LICENSE" for the full license governing this code.
--!-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fec_pkg.all;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;

entity xwb_fec_mux is
    generic (
        g_mux_class     : t_mux_class := c_default_classes;
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

        wr2fec_snk_ack   : out std_logic;
        wr2fec_snk_stall : out std_logic;
        wr2fec_snk_adr   : in  std_logic_vector(1 downto 0);
        wr2fec_snk_dat   : in  std_logic_vector(15 downto 0);
        wr2fec_snk_cyc   : in  std_logic;
        wr2fec_snk_stb   : in  std_logic;
        wr2fec_snk_we    : in  std_logic;
        wr2fec_snk_sel   : in  std_logic_vector(1 downto 0);

        fec2wr_src_ack   : in  std_logic;
        fec2wr_src_stall : in  std_logic;
        fec2wr_src_adr   : out std_logic_vector(1 downto 0);
        fec2wr_src_dat   : out std_logic_vector(15 downto 0);
        fec2wr_src_cyc   : out std_logic;
        fec2wr_src_stb   : out std_logic;
        fec2wr_src_we    : out std_logic;
        fec2wr_src_sel   : out std_logic_vector(1 downto 0);

        eb2fec_snk_ack   : out std_logic;
        eb2fec_snk_stall : out std_logic;
        eb2fec_snk_adr   : in  std_logic_vector(1 downto 0);
        eb2fec_snk_dat   : in  std_logic_vector(15 downto 0);
        eb2fec_snk_cyc   : in  std_logic;
        eb2fec_snk_stb   : in  std_logic;
        eb2fec_snk_we    : in  std_logic;
        eb2fec_snk_sel   : in  std_logic_vector(1 downto 0);

        fec2eb_src_ack   : in  std_logic;
        fec2eb_src_stall : in  std_logic;
        fec2eb_src_adr   : out std_logic_vector(1 downto 0);
        fec2eb_src_dat   : out std_logic_vector(15 downto 0);
        fec2eb_src_cyc   : out std_logic;
        fec2eb_src_stb   : out std_logic;
        fec2eb_src_we    : out std_logic;
        fec2eb_src_sel   : out std_logic_vector(1 downto 0);

        wb_slave_ack    : out std_logic;
        wb_slave_err    : out std_logic;
        wb_slave_rty    : out std_logic;
        wb_slave_stall  : out std_logic;
        wb_slave_int    : out std_logic;
        wb_slave_dat_o  : out t_wishbone_data;

        wb_slave_dat_i  : in t_wishbone_data;
        wb_slave_cyc    : in std_logic;
        wb_slave_stb    : in std_logic;
        wb_slave_adr    : in t_wishbone_address;
        wb_slave_sel    : in t_wishbone_byte_select;
        wb_slave_we     : in std_logic);

end xwb_fec_mux;

architecture rtl of xwb_fec_mux is

  signal fec_ctrl_reg : t_fec_ctrl_reg;
  signal fec_stat_reg : t_fec_stat_reg;
  signal fec_dec_reg  : t_dec_err;
  signal fec_enc_reg  : t_enc_err;

  signal enc_bypass_in  : t_wrf_sink_in;
  signal enc_bypass_out : t_wrf_sink_out;
  signal dec_bypass_in  : t_wrf_source_in;
  signal dec_bypass_out : t_wrf_source_out;

  signal enc_snk_in   : t_wrf_sink_in;
  signal enc_snk_out  : t_wrf_sink_out;
  signal enc_src_in   : t_wrf_source_in;
  signal enc_src_out  : t_wrf_source_out;

  signal dec_snk_in   :  t_wrf_sink_in;
  signal dec_snk_out  :  t_wrf_sink_out;
  signal dec_src_in   :  t_wrf_source_in;
  signal dec_src_out  :  t_wrf_source_out;

  signal wr2fec_snk_i  :  t_wrf_sink_in;
  signal wr2fec_snk_o  :  t_wrf_sink_out;
  signal fec2wr_src_i  :  t_wrf_source_in;
  signal fec2wr_src_o  :  t_wrf_source_out;

  signal eb2fec_snk_i  :  t_wrf_sink_in;
  signal eb2fec_snk_o  :  t_wrf_sink_out;
  signal fec2eb_src_i  :  t_wrf_source_in;
  signal fec2eb_src_o  :  t_wrf_source_out;

  signal wb_slave_o      :  t_wishbone_slave_out;
  signal wb_slave_i      :  t_wishbone_slave_in;

  signal mux_class    : t_wrf_mux_class(1 downto 0);

begin

  y_WB_FEC_DEC : if g_en_fec_dec generate
  FEC_DEC : wb_fec_decoder
    generic map (
    g_num_block     => 4,
    g_oust_ethtype  => true,
    g_en_golay      => false)
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

  -- Encoder
  y_WB_FEC_ENC : if g_en_fec_enc generate
  FEC_ENC: wb_fec_encoder
    generic map (
      g_en_golay      => false,
      g_num_block     => 4,
      g_oust_ethtype  => true)
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

  mux_class(0)  <= g_mux_class(0); -- x"40" Etherbone
  mux_class(1)  <= g_mux_class(1); -- x"80" FEC

  -- WRF_MUX2WR
  wr2fec_snk_ack    <= wr2fec_snk_o.ack;
  wr2fec_snk_stall  <= wr2fec_snk_o.stall;

  wr2fec_snk_i.adr  <= wr2fec_snk_adr;
  wr2fec_snk_i.dat  <= wr2fec_snk_dat;
  wr2fec_snk_i.cyc  <= wr2fec_snk_cyc;
  wr2fec_snk_i.stb  <= wr2fec_snk_stb;
  wr2fec_snk_i.we   <= wr2fec_snk_we ;
  wr2fec_snk_i.sel  <= wr2fec_snk_sel;

  fec2wr_src_i.ack  <= fec2wr_src_ack;
  fec2wr_src_i.stall<= fec2wr_src_stall;

  fec2wr_src_adr   <=  fec2wr_src_o.adr;
  fec2wr_src_dat   <=  fec2wr_src_o.dat;
  fec2wr_src_cyc   <=  fec2wr_src_o.cyc;
  fec2wr_src_stb   <=  fec2wr_src_o.stb;
  fec2wr_src_we    <=  fec2wr_src_o.we;
  fec2wr_src_sel   <=  fec2wr_src_o.sel;


  -- WRF_MUX2EB
  fec2eb_src_i.ack   <= fec2eb_src_ack;
  fec2eb_src_i.stall <= fec2eb_src_stall;

  fec2eb_src_adr   <=  fec2eb_src_o.adr;
  fec2eb_src_dat   <=  fec2eb_src_o.dat;
  fec2eb_src_cyc   <=  fec2eb_src_o.cyc;
  fec2eb_src_stb   <=  fec2eb_src_o.stb;
  fec2eb_src_we    <=  fec2eb_src_o.we;
  fec2eb_src_sel   <=  fec2eb_src_o.sel;

  eb2fec_snk_ack    <= eb2fec_snk_o.ack;
  eb2fec_snk_stall  <= eb2fec_snk_o.stall;

  eb2fec_snk_i.adr  <= eb2fec_snk_adr;
  eb2fec_snk_i.dat  <= eb2fec_snk_dat;
  eb2fec_snk_i.cyc  <= eb2fec_snk_cyc;
  eb2fec_snk_i.stb  <= eb2fec_snk_stb;
  eb2fec_snk_i.we   <= eb2fec_snk_we ;
  eb2fec_snk_i.sel  <= eb2fec_snk_sel;



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

  XWB_SLAVE: xwb_slave_fec
    port map (
      clk_i           => clk_i,
      rst_n_i         => rst_n_i,
      wb_slave_i      => wb_slave_i,
      wb_slave_o      => wb_slave_o,
      fec_stat_reg_i  => fec_stat_reg,
      fec_ctrl_reg_o  => fec_ctrl_reg,
      time_code_i     => c_time_code);

  --end wb_fec_decoder;
  wb_slave_ack    <= wb_slave_o.ack;
  wb_slave_err    <= wb_slave_o.err;
  wb_slave_rty    <= wb_slave_o.rty;
  wb_slave_stall  <= wb_slave_o.stall;
  wb_slave_int    <= wb_slave_o.int;
  wb_slave_dat_o  <= wb_slave_o.dat;

  wb_slave_i.cyc  <= wb_slave_cyc;
  wb_slave_i.stb  <= wb_slave_stb;
  wb_slave_i.adr  <= wb_slave_adr;
  wb_slave_i.sel  <= wb_slave_sel;
  wb_slave_i.we   <= wb_slave_we;
  wb_slave_i.dat  <= wb_slave_dat_i;

end rtl;
