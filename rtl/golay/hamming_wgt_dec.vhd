--! @file hamming_wgt_dec.vhd
--! @brief It is a priorirty decoder for hamming weights > 2 
--! @author C.Prados <cprados@mailfence.com>
--!
--! This core is a priorirty decoder for hamming weights > 2 
--! 
--! See the file "LICENSE" for the full license governing this code.
--!-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.golay_pkg.all;

entity hamming_wgt_dec is
  port (
    hmm_wgt_i : in  t_matrix_wgt;
    wgt_dec_o : out std_logic_vector(hmm_wgt - 1 downto 0));
end hamming_wgt_dec;

architecture rtl of hamming_wgt_dec is
  signal hmm_wgt_m  : std_logic_vector(golay_len - 1 downto 0);
begin

  WEIGHT_SMALLER_THAN_TWO: for i in 0 to golay_len - 1 generate 
    hmm_wgt_m(i)  <= (hmm_wgt_i(i)(0) nand hmm_wgt_i(i)(1)) and (hmm_wgt_i(i)(2) nor hmm_wgt_i(i)(3));
  end generate;

  wgt_dec_o <=   "0000" when hmm_wgt_m(0)  = '1' else
                 "0001" when hmm_wgt_m(1)  = '1' else 
                 "0010" when hmm_wgt_m(2)  = '1' else
                 "0011" when hmm_wgt_m(3)  = '1' else
                 "0100" when hmm_wgt_m(4)  = '1' else
                 "0101" when hmm_wgt_m(5)  = '1' else 
                 "0110" when hmm_wgt_m(6)  = '1' else
                 "0111" when hmm_wgt_m(7)  = '1' else 
                 "1000" when hmm_wgt_m(8)  = '1' else
                 "1001" when hmm_wgt_m(9)  = '1' else
                 "1010" when hmm_wgt_m(10) = '1' else
                 "1011" when hmm_wgt_m(11) = '1' else
                 "1111";
end rtl;
