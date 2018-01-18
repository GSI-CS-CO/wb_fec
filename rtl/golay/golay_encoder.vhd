--! @file golay_encoder.vhd
--! @brief  A Golay Encoder (24,12,7)
--! @author C.Prados <cprados@mailfence.com>
--!
--! This core is a golay encoder (24,12,7). It impkentes the parity check matrix
--! from a clasical GF poly generator (see doc). The core yields the paruty bits in 1 
--! clock cycle. For more info about Golay decoder check the doc folder.
--! 
--!    |1 1 1 1 1 1 1 1 1 1 1 0|   11  = 0 1 2 3 4  5  6 7 8 9 10
--!    |0 1 0 0 0 1 1 1 0 1 1 1|   10  = 1 5 6 7 9 10 11 
--!    |1 0 1 0 0 0 1 1 1 0 1 1|   9   = 0 2 6 7 8 10 11 
--!    |1 1 0 1 0 0 0 1 1 1 0 1|   8   = 0 1 3 7 8  9 11 
--!    |0 1 1 0 1 0 0 0 1 1 1 1|   7   = 1 2 4 8 9 10 11 
--!    |1 0 1 1 0 1 0 0 0 1 1 1|   6   = 0 2 3 5 9 10 11 
--! B= |1 1 0 1 1 0 1 0 0 0 1 1|   5   = 0 1 3 4 6 10 11 
--!    |1 1 1 0 1 1 0 1 0 0 0 1|   4   = 0 1 2 4 5  7 11 
--!    |0 1 1 1 0 1 1 0 1 0 0 1|   3   = 1 2 3 5 6  8 11 
--!    |0 0 1 1 1 0 1 1 0 1 0 1|   2   = 2 3 4 6 7  9 11 
--!    |0 0 0 1 1 1 0 1 1 0 1 1|   1   = 3 4 5 7 8 10 11 
--!    |1 0 0 0 1 1 1 0 1 1 0 1|   0   = 0 4 5 6 8  9 11 
--!
--! See the file "LICENSE" for the full license governing this code.
--!-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.golay_pkg.all;

entity golay_encoder is
  port (
    clk_i       : in  std_logic;
    rst_n_i     : in  std_logic;
    stb_i       : in  std_logic;
    payload_i   : in  std_logic_vector (golay_len - 1 downto 0);
    code_word_o : out std_logic_vector (golay_len - 1 downto 0));
end golay_encoder;

architecture rtl of golay_encoder is
begin 

          code_word_o(0)  <= payload_i(0) xor payload_i(4) xor payload_i(5) xor payload_i(6) xor payload_i(8) xor payload_i(9)  xor payload_i(11);
          code_word_o(1)  <= payload_i(3) xor payload_i(4) xor payload_i(5) xor payload_i(7) xor payload_i(8) xor payload_i(10) xor payload_i(11);
          code_word_o(2)  <= payload_i(2) xor payload_i(3) xor payload_i(4) xor payload_i(6) xor payload_i(7) xor payload_i(9)  xor payload_i(11);
          code_word_o(3)  <= payload_i(1) xor payload_i(2) xor payload_i(3) xor payload_i(5) xor payload_i(6) xor payload_i(8)  xor payload_i(11);
          code_word_o(4)  <= payload_i(0) xor payload_i(1) xor payload_i(2) xor payload_i(4) xor payload_i(5) xor payload_i(7)  xor payload_i(11);
          code_word_o(5)  <= payload_i(0) xor payload_i(1) xor payload_i(3) xor payload_i(4) xor payload_i(6) xor payload_i(10) xor payload_i(11);
          code_word_o(6)  <= payload_i(0) xor payload_i(2) xor payload_i(3) xor payload_i(5) xor payload_i(9) xor payload_i(10) xor payload_i(11);
          code_word_o(7)  <= payload_i(1) xor payload_i(2) xor payload_i(4) xor payload_i(8) xor payload_i(9) xor payload_i(10) xor payload_i(11);
          code_word_o(8)  <= payload_i(0) xor payload_i(1) xor payload_i(3) xor payload_i(7) xor payload_i(8) xor payload_i(9)  xor payload_i(11);
          code_word_o(9)  <= payload_i(0) xor payload_i(2) xor payload_i(6) xor payload_i(7) xor payload_i(8) xor payload_i(10) xor payload_i(11);
          code_word_o(10) <= payload_i(1) xor payload_i(5) xor payload_i(6) xor payload_i(7) xor payload_i(9) xor payload_i(10) xor payload_i(11);
          code_word_o(11) <= payload_i(0) xor payload_i(1) xor payload_i(2) xor payload_i(3) xor payload_i(4) xor payload_i(5)  xor payload_i(6) xor 
                             payload_i(7) xor payload_i(8) xor payload_i(9) xor payload_i(10);
end rtl;
