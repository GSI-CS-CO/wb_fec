--! @file wb_fec.vhd
--! @brief  FEC 
--! @author C.Prados <cprados@mailfence.com>
--!
--! See the file "LICENSE" for the full license governing this code.
--!-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fec_pkg.all;
--use work.golay_pk.all;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;

entity wb_fec is
    generic (
        g_en_fec_enc    : boolean;
        g_en_fec_dec    : boolean;
        g_en_golay      : boolean;
        g_en_dec_time   : boolean);
    port ( 
        clk_i           : in  std_logic;
        rst_n_i         : in  std_logic;    
        fec_timestamps_i: in  t_txtsu_timestamp;
        fec_tm_tai_i    : in  std_logic_vector(39 downto 0);
        fec_tm_cycle_i  : in  std_logic_vector(27 downto 0);        
        fec_dec_sink_i  : in  t_wrf_sink_in;
        fec_dec_sink_o  : in  t_wrf_sink_out;
        fec_dec_src_i   : in  t_wrf_source_in;
        fec_dec_src_o   : out t_wrf_source_out;

        fec_enc_sink_i  : in  t_wrf_sink_in;
        fec_enc_sink_o  : out t_wrf_sink_out;
        fec_enc_src_i   : in  t_wrf_source_in;
        fec_enc_src_o   : out t_wrf_source_out;
        wb_slave_o      : out t_wishbone_slave_out;
        wb_slave_i      : in  t_wishbone_slave_in);
end wb_fec;

architecture rtl of wb_fec is
  signal fec_ctrl_reg : t_enc_ctrl_reg;
  signal fec_stat_reg : t_enc_stat_reg;

begin 

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

  ----FEC_DEC : wb_fec_decoder is

  --end wb_fec_decoder;

  WB_SLAVE: wb_slave_fec
    port (
      clk_i           => clk_i,
      rst_n_i         => rst_n_i,
      wb_slave_i      => wb_slave_i,
      wb_slave_o      => wb_slave_o,
      fec_stat_reg_i  => fec_stat_reg,
      fec_ctrl_reg_o  => fec_ctrl_reg,
      time_code_i     => (others => '0'));
