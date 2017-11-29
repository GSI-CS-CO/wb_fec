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

entity xwb_fec is
    generic (
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

        fec_dec_sink_ack   : out std_logic;
        fec_dec_sink_stall : out std_logic;
        fec_dec_sink_adr   : in  std_logic_vector(1 downto 0);
        fec_dec_sink_dat   : in  std_logic_vector(15 downto 0);
        fec_dec_sink_cyc   : in  std_logic;
        fec_dec_sink_stb   : in  std_logic;
        fec_dec_sink_we    : in  std_logic;
        fec_dec_sink_sel   : in  std_logic_vector(1 downto 0);

        fec_dec_src_ack   : in  std_logic;
        fec_dec_src_stall : in  std_logic;
        fec_dec_src_adr   : out std_logic_vector(1 downto 0);
        fec_dec_src_dat   : out std_logic_vector(15 downto 0);
        fec_dec_src_cyc   : out std_logic;
        fec_dec_src_stb   : out std_logic;
        fec_dec_src_we    : out std_logic;
        fec_dec_src_sel   : out std_logic_vector(1 downto 0);

        fec_enc_sink_ack   : out std_logic;
        fec_enc_sink_stall : out std_logic;
        fec_enc_sink_adr   : in  std_logic_vector(1 downto 0);
        fec_enc_sink_dat   : in  std_logic_vector(15 downto 0);
        fec_enc_sink_cyc   : in  std_logic;
        fec_enc_sink_stb   : in  std_logic;
        fec_enc_sink_we    : in  std_logic;
        fec_enc_sink_sel   : in  std_logic_vector(1 downto 0);

        fec_enc_src_ack   : in  std_logic;
        fec_enc_src_stall : in  std_logic;
        fec_enc_src_adr   : out std_logic_vector(1 downto 0);
        fec_enc_src_dat   : out std_logic_vector(15 downto 0);
        fec_enc_src_cyc   : out std_logic;
        fec_enc_src_stb   : out std_logic;
        fec_enc_src_we    : out std_logic;
        fec_enc_src_sel   : out std_logic_vector(1 downto 0);

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

end xwb_fec;

architecture rtl of xwb_fec is

  signal fec_ctrl_reg : t_fec_ctrl_reg;
  signal fec_stat_reg : t_fec_stat_reg;

  signal fec_dec_sink_i  :  t_wrf_sink_in;
  signal fec_dec_sink_o  :  t_wrf_sink_out;
  signal fec_dec_src_i   :  t_wrf_source_in;
  signal fec_dec_src_o   :  t_wrf_source_out;

  signal fec_enc_sink_i  :  t_wrf_sink_in;
  signal fec_enc_sink_o  :  t_wrf_sink_out;
  signal fec_enc_src_i   :  t_wrf_source_in;
  signal fec_enc_src_o   :  t_wrf_source_out;
  signal wb_slave_o      :  t_wishbone_slave_out;
  signal wb_slave_i      :  t_wishbone_slave_in;

begin

  -- bypass

   fec_dec_sink_ack    <= fec_dec_src_ack;
   fec_dec_sink_stall  <= fec_dec_src_stall;

   fec_dec_src_adr   <=  fec_dec_sink_adr;
   fec_dec_src_dat   <=  fec_dec_sink_dat;
   fec_dec_src_cyc   <=  fec_dec_sink_cyc;
   fec_dec_src_stb   <=  fec_dec_sink_stb;
   fec_dec_src_we    <=  fec_dec_sink_we ;
   fec_dec_src_sel   <=  fec_dec_sink_sel;

    -- Decoder

   fec_dec_sink_ack    <= fec_dec_sink_o.ack;
   fec_dec_sink_stall  <= fec_dec_sink_o.stall;

   fec_dec_sink_i.adr  <= fec_dec_sink_adr;
   fec_dec_sink_i.dat  <= fec_dec_sink_dat;
   fec_dec_sink_i.cyc  <= fec_dec_sink_cyc;
   fec_dec_sink_i.stb  <= fec_dec_sink_stb;
   fec_dec_sink_i.we   <= fec_dec_sink_we ;
   fec_dec_sink_i.sel  <= fec_dec_sink_sel;

   fec_dec_src_i.ack   <= fec_dec_src_ack;
   fec_dec_src_i.stall <= fec_dec_src_stall;

   fec_dec_src_adr   <=  fec_dec_src_o.adr;
   fec_dec_src_dat   <=  fec_dec_src_o.dat;
   fec_dec_src_cyc   <=  fec_dec_src_o.cyc;
   fec_dec_src_stb   <=  fec_dec_src_o.stb;
   fec_dec_src_we    <=  fec_dec_src_o.we;
   fec_dec_src_sel   <=  fec_dec_src_o.sel;

   --fec_dec_sink_o   <= c_dummy_src_in;
   --fec_dec_src_o    <= c_dummy_snk_in;

  -- Encoder

   fec_enc_sink_ack    <= fec_enc_sink_o.ack;
   fec_enc_sink_stall  <= fec_enc_sink_o.stall;

   fec_enc_sink_i.adr  <= fec_enc_sink_adr;
   fec_enc_sink_i.dat  <= fec_enc_sink_dat;
   fec_enc_sink_i.cyc  <= fec_enc_sink_cyc;
   fec_enc_sink_i.stb  <= fec_enc_sink_stb;
   fec_enc_sink_i.we   <= fec_enc_sink_we ;
   fec_enc_sink_i.sel  <= fec_enc_sink_sel;


   fec_enc_src_i.ack   <= fec_enc_src_ack;
   fec_enc_src_i.stall <= fec_enc_src_stall;

   fec_enc_src_adr   <=  fec_enc_src_o.adr;
   fec_enc_src_dat   <=  fec_enc_src_o.dat;
   fec_enc_src_cyc   <=  fec_enc_src_o.cyc;
   fec_enc_src_stb   <=  fec_enc_src_o.stb;
   fec_enc_src_we    <=  fec_enc_src_o.we;
   fec_enc_src_sel   <=  fec_enc_src_o.sel;

  FEC_ENC: wb_fec_encoder
    generic map (
      g_en_golay => FALSE
      )
    port map (
      clk_i       => clk_i,
      rst_n_i     => rst_n_i,
      snk_i       => fec_enc_sink_i,
      snk_o       => fec_enc_sink_o,
      src_i       => fec_enc_src_i,
      src_o       => fec_enc_src_o,
      ctrl_reg_i  => fec_ctrl_reg,
      stat_reg_o  => fec_stat_reg);

  FEC_DEC : wb_fec_decoder
    generic map (
    g_num_block   => 4,
    g_en_golay    => FALSE)
    port map (
      clk_i       => clk_i,
      rst_n_i     => rst_n_i,
      snk_i       => fec_dec_sink_i,
      snk_o       => fec_dec_sink_o,
      src_i       => fec_dec_src_i,
      src_o       => fec_dec_src_o,
      ctrl_reg_i  => fec_ctrl_reg,
      stat_reg_o  => fec_stat_reg);
  
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
