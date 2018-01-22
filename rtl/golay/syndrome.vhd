--! @file syndrome.vhd
--! @brief it calculates the syndrome of a golay codeword
--! @author C.Prados <cprados@mailfence.com>
--!
--! This core calculates the syndrome of a golay codeword. 
--! S = [I|H] * codeword
--!
--!     | 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 1|   11 12 13 14 15 16 17 18 19 20 21 22
--!     | 0 1 0 0 0 1 1 1 0 1 1 1 0 0 0 0 0 0 0 0 0 0 1 0|   10 13 17 18 19 21 22 23
--!     | 1 0 1 0 0 0 1 1 1 0 1 1 0 0 0 0 0 0 0 0 0 1 0 0|    9 12 14 18 19 20 22 23
--!     | 1 1 0 1 0 0 0 1 1 1 0 1 0 0 0 0 0 0 0 0 1 0 0 0|    8 12 13 15 19 20 21 23
--!     | 0 1 1 0 1 0 0 0 1 1 1 1 0 0 0 0 0 0 0 1 0 0 0 0|    7 13 14 16 20 21 22 23
--!     | 1 0 1 1 0 1 0 0 0 1 1 1 0 0 0 0 0 0 1 0 0 0 0 0|    6 12 14 15 17 21 22 23
--! S = | 1 1 0 1 1 0 1 0 0 0 1 1 0 0 0 0 0 1 0 0 0 0 0 0|    5 12 13 15 16 18 22 23
--!     | 1 1 1 0 1 1 0 1 0 0 0 1 0 0 0 0 1 0 0 0 0 0 0 0|    4 12 13 14 16 17 19 23
--!     | 0 1 1 1 0 1 1 0 1 0 0 1 0 0 0 1 0 0 0 0 0 0 0 0|    3 13 14 15 17 18 20 23
--!     | 0 0 1 1 1 0 1 1 0 1 0 1 0 0 1 0 0 0 0 0 0 0 0 0|    2 14 15 16 18 19 21 23
--!     | 0 0 0 1 1 1 0 1 1 0 1 1 0 1 0 0 0 0 0 0 0 0 0 0|    1 15 16 17 19 20 22 23
--!     | 1 0 0 0 1 1 1 0 1 1 0 1 1 0 0 0 0 0 0 0 0 0 0 0|    0 12 16 17 18 20 21 23
--!
--! See the file "LICENSE" for the full license governing this code.
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.golay_pkg.all;

entity syndrome is
  port (  
    codeword_i  : in  std_logic_vector((2 * golay_len) - 1 downto 0);
    syndrome_o  : out std_logic_vector(golay_len - 1 downto 0));
end syndrome;

architecture rtl of syndrome is
begin

syndrome_o(11) <= codeword_i(0) xor codeword_i(1) xor codeword_i(2) xor codeword_i(3) xor codeword_i(4) xor codeword_i(5) xor 
                  codeword_i(6) xor codeword_i(7) xor codeword_i(8) xor codeword_i(9) xor codeword_i(10) xor codeword_i(23);
syndrome_o(10) <= codeword_i(1) xor codeword_i(5) xor codeword_i(6) xor codeword_i(7) xor codeword_i(9) xor codeword_i(10) xor codeword_i(11) xor codeword_i(22);
syndrome_o(9)  <= codeword_i(0) xor codeword_i(2) xor codeword_i(6) xor codeword_i(7) xor codeword_i(8) xor codeword_i(10) xor codeword_i(11) xor codeword_i(21);
syndrome_o(8)  <= codeword_i(0) xor codeword_i(1) xor codeword_i(3) xor codeword_i(7) xor codeword_i(8) xor codeword_i(9)  xor codeword_i(11) xor codeword_i(20);
syndrome_o(7)  <= codeword_i(1) xor codeword_i(2) xor codeword_i(4) xor codeword_i(8) xor codeword_i(9) xor codeword_i(10) xor codeword_i(11) xor codeword_i(19);
syndrome_o(6)  <= codeword_i(0) xor codeword_i(2) xor codeword_i(3) xor codeword_i(5) xor codeword_i(9) xor codeword_i(10) xor codeword_i(11) xor codeword_i(18);
syndrome_o(5)  <= codeword_i(0) xor codeword_i(1) xor codeword_i(3) xor codeword_i(4) xor codeword_i(6) xor codeword_i(10) xor codeword_i(11) xor codeword_i(17);
syndrome_o(4)  <= codeword_i(0) xor codeword_i(1) xor codeword_i(2) xor codeword_i(4) xor codeword_i(5) xor codeword_i(7)  xor codeword_i(11) xor codeword_i(16);
syndrome_o(3)  <= codeword_i(1) xor codeword_i(2) xor codeword_i(3) xor codeword_i(5) xor codeword_i(6) xor codeword_i(8)  xor codeword_i(11) xor codeword_i(15);
syndrome_o(2)  <= codeword_i(2) xor codeword_i(3) xor codeword_i(4) xor codeword_i(6) xor codeword_i(7) xor codeword_i(9)  xor codeword_i(11) xor codeword_i(14);
syndrome_o(1)  <= codeword_i(3) xor codeword_i(4) xor codeword_i(5) xor codeword_i(7) xor codeword_i(8) xor codeword_i(10) xor codeword_i(11) xor codeword_i(13);
syndrome_o(0)  <= codeword_i(0) xor codeword_i(4) xor codeword_i(5) xor codeword_i(6) xor codeword_i(8) xor codeword_i(9)  xor codeword_i(11) xor codeword_i(12);

end rtl;
