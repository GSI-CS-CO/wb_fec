--! @file full_adder.vhd
--! @brief just a full adder 
--! @author C.Prados <cprados@mailfence.com>
--!
--! This core is just a full adder, the carrier bit is the add(1) bit.
--!
--! See the file "LICENSE" for the full license governing this code.
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
 
entity full_adder is
  port (
    bit_0 : in  std_logic;
    bit_1 : in  std_logic;
    bit_2 : in  std_logic;
    add   : out std_logic_vector(1 downto 0));
end full_adder;
 
architecture gate of full_adder is
begin
  add(0)  <=  bit_0  xor bit_1 xor bit_2;
  add(1)  <= (bit_0 and bit_1) or (bit_2 and bit_0) or (bit_2 and bit_1);
end gate;
