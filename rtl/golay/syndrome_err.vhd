--! @file syndrome_err.vhd
--! @brief it calculate the error of the syndrome error
--! @author C.Prados <cprados@mailfence.com>
--!
--! This core calculates the error of syndrome of a golay codeword. 
--! S_err = codeword ^ [H]
--!
--! See the file "LICENSE" for the full license governing this code.
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.golay_pkg.all;

entity syndrome_err is
  port (  
    codeword_i      : in  std_logic_vector(golay_len - 1 downto 0);
    syndrome_err_o  : out std_logic_vector(golay_len - 1 downto 0));
end syndrome_err;

architecture rtl of syndrome_err is
begin

  syndrome_err_o(0)  <= codeword_i(0) xor codeword_i(4) xor codeword_i(5) xor codeword_i(6) xor codeword_i(8) xor codeword_i(9)  xor codeword_i(11);
  syndrome_err_o(1)  <= codeword_i(3) xor codeword_i(4) xor codeword_i(5) xor codeword_i(7) xor codeword_i(8) xor codeword_i(10) xor codeword_i(11);
  syndrome_err_o(2)  <= codeword_i(2) xor codeword_i(3) xor codeword_i(4) xor codeword_i(6) xor codeword_i(7) xor codeword_i(9)  xor codeword_i(11);
  syndrome_err_o(3)  <= codeword_i(1) xor codeword_i(2) xor codeword_i(3) xor codeword_i(5) xor codeword_i(6) xor codeword_i(8)  xor codeword_i(11);
  syndrome_err_o(4)  <= codeword_i(0) xor codeword_i(1) xor codeword_i(2) xor codeword_i(4) xor codeword_i(5) xor codeword_i(7)  xor codeword_i(11);
  syndrome_err_o(5)  <= codeword_i(0) xor codeword_i(1) xor codeword_i(3) xor codeword_i(4) xor codeword_i(6) xor codeword_i(10) xor codeword_i(11);
  syndrome_err_o(6)  <= codeword_i(0) xor codeword_i(2) xor codeword_i(3) xor codeword_i(5) xor codeword_i(9) xor codeword_i(10) xor codeword_i(11);
  syndrome_err_o(7)  <= codeword_i(1) xor codeword_i(2) xor codeword_i(4) xor codeword_i(8) xor codeword_i(9) xor codeword_i(10) xor codeword_i(11);
  syndrome_err_o(8)  <= codeword_i(0) xor codeword_i(1) xor codeword_i(3) xor codeword_i(7) xor codeword_i(8) xor codeword_i(9)  xor codeword_i(11);
  syndrome_err_o(9)  <= codeword_i(0) xor codeword_i(2) xor codeword_i(6) xor codeword_i(7) xor codeword_i(8) xor codeword_i(10) xor codeword_i(11);
  syndrome_err_o(10) <= codeword_i(1) xor codeword_i(5) xor codeword_i(6) xor codeword_i(7) xor codeword_i(9) xor codeword_i(10) xor codeword_i(11);
  syndrome_err_o(11) <= codeword_i(0) xor codeword_i(1) xor codeword_i(2) xor codeword_i(3) xor codeword_i(4) xor codeword_i(5)  xor codeword_i(6) xor 
                        codeword_i(7) xor codeword_i(8) xor codeword_i(9) xor codeword_i(10);

end rtl;
