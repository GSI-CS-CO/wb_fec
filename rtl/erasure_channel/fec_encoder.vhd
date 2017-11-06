--! @file fec_encoder.vhd
--! @brief  A FEC Encoder
--! @author C.Prados <cprados@mailfence.com>
--!
--! See the file "LICENSE" for the full license governing this code.
--!-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.fec_pkg.all;

entity fec_encoder is
  port (
    clk_i       : in  std_logic;
    rst_n_i     : in  std_logic;
end fec_encoder;

architecture rtl of fec is
begin 


end rtl;

