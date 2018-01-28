--! @file xfec_pkg.vhd
--! @brief package for the fec code
--! @author C.Prados <cprados@mailfence.com>
--!
--! package for the fec project
--!
--! See the file "LICENSE" for the full license governing this code.
--!-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.genram_pkg.all;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;
use work.fec_pkg.all;

package xfec_pkg is

  component xwb_fec is
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
        wb_slave_we     : in std_logic;
        wb_slave_dat    : in t_wishbone_data);
  end component;

  component xwb_fec_mux is
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
  end component;

end package fec_pkg;
