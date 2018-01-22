--! @file hamming_wgt.vhd
--! @brief calculates the hamming weight of a give vector
--! @author C.Prados <cprados@mailfence.com>
--!
--! This core calculates the hamming weigth of given vector using 
--! a simple full adder and bit adders.
--! 
--! See the file "LICENSE" for the full license governing this code.
--!-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.golay_pkg.all;

entity hamming_wgt is
  port (
      vector_i  : in  std_logic_vector(golay_len - 1 downto 0);
      hmm_wgt_o : out std_logic_vector(hmm_wgt - 1 downto 0));
end hamming_wgt;

architecture rtl of hamming_wgt is
  type t_out_full is array (0 to 3) of std_logic_vector(1 downto 0);
  signal out_full : t_out_full;
  type t_out_two_adder is array (0 to 1) of std_logic_vector(2 downto 0);
  signal out_two_adder : t_out_two_adder;
begin

  FIRS_STEP : for i in 0 to 3 generate
    FULLADDER : full_adder
      port map (
        bit_0 => vector_i((3 * i)),
        bit_1 => vector_i((3 * i) + 1),
        bit_2 => vector_i((3 * i) + 2),
        add   => out_full(i));
  end generate;

  SECOND_STEP : for i in 0 to 1 generate
    TWOBITADDER : two_bit_adder
      port map(
        a   => out_full((2 * i) + 0),
        b   => out_full((2 * i) + 1),
        add => out_two_adder(i));
  end generate;

  THREEBITADDER : three_bit_adder
    port map(
      a   => out_two_adder(0),
      b   => out_two_adder(1),
      add => hmm_wgt_o);
end rtl;

