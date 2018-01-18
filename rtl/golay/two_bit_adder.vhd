--! @file two_bit_adder.vhd
--! @brief a simple two bit adder 
--! @author C.Prados <cprados@mailfence.com>
--!
--! a simple two bit adder 
--!
--! See the file "LICENSE" for the full license governing this code.
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity two_bit_adder is
  port (
    a   : in  std_logic_vector(1 downto 0);
    b   : in  std_logic_vector(1 downto 0);
    add : out std_logic_vector(2 downto 0));
end two_bit_adder;

architecture gate of two_bit_adder is
  signal bit_tmp_0  : std_logic; 
  signal bit_tmp_1  : std_logic; 
  signal bit_tmp_2  : std_logic; 
  signal bit_tmp_3  : std_logic; 
begin
  add(0)    <= a(0) xor b(0);
  bit_tmp_0 <= a(0) and b(0);

  bit_tmp_1 <= a(1) xor b(1);
  bit_tmp_2 <= a(1) and b(1);

  add(1)    <= bit_tmp_0 xor bit_tmp_1;
  bit_tmp_3 <= bit_tmp_0 and bit_tmp_1;
            
  add(2)    <= bit_tmp_3 or bit_tmp_2;
end gate;
