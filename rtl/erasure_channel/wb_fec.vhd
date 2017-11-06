--! @file fec_encoder.vhd
--! @brief  A FEC Encoder
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

entity wb_fec is
    generic (
        g_en_fec_enc    : boolean;
        g_en_fec_dec    : boolean;
        g_en_golay      : boolean;
        g_en_dec_time   : boolean);
    port ( 
        clk_i           : in  std_logic;
        rst_n_i         : in  std_logic;    
        ctrl_reg_i      : in  t_fec_ctrl_reg;
        stat_reg_o      : out t_fec_stat_reg;
        fec_timestamps_i: in  t_txtsu_timestamp;
        fec_tm_tai_i    : in  std_logic_vector(39 downto 0);
        fec_tm_cycle_i  : in  std_logic_vector(27 downto 0);
        fec_sink_i      : in  t_wrd_sink_in;
        fec_sink_o      : in  t_wrd_sink_out;
        fec_src_i       : in  t_wrf_source_in;
        fec_src_o       : out t_wrf_source_out);
end wb_fec;

architecture rtl of wb_fec is
begin 


end rtl;
