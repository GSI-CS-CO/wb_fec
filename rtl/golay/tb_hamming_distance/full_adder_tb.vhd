LIBrary ieee;
use ieee.std_logic_1164.all;
 
entity full_adder_tb is
end full_adder_tb;
 
architecture behavior of full_adder_tb is
 
 -- component declaration for the unit under test (uut)
component full_adder  
  port (
    bit_0 : in std_logic;
    bit_1 : in std_logic;
    bit_2 : in std_logic;
    out_0 : out std_logic;
    out_1 : out std_logic);
end component;
 
  --inputs
  signal bit_0  : std_logic := '0';
  signal bit_1  : std_logic := '0';
  signal bit_2  : std_logic := '0';
 
  --outputs
  signal out_0 : std_logic;
  signal out_1 : std_logic;
 
begin
 
 -- instantiate the unit under test (uut)
uut: full_adder 
  port map (
  bit_0 => bit_0,
  bit_1 => bit_1,
  bit_2 => bit_2,
  out_0 => out_0,
  out_1 => out_1);
 
 -- stimulus process
 stim_proc: process
 begin
 -- hold reset state for 100 ns.
 wait for 100 ns; 
 
 -- insert stimulus here
 bit_0 <= '1';
 bit_1 <= '0';
 bit_2 <= '0';
 wait for 10 ns;
 
 bit_0 <= '0';
 bit_1 <= '1';
 bit_2 <= '0';
 wait for 10 ns;
 
 bit_0 <= '1';
 bit_1 <= '1';
 bit_2 <= '0';
 wait for 10 ns;
 
 bit_0 <= '0';
 bit_1 <= '0';
 bit_2 <= '1';
 wait for 10 ns;
 
 bit_0 <= '1';
 bit_1 <= '0';
 bit_2 <= '1';
 wait for 10 ns;
 
 bit_0 <= '0';
 bit_1 <= '1';
 bit_2 <= '1';
 wait for 10 ns;
 
 bit_0 <= '1';
 bit_1 <= '1';
 bit_2 <= '1';
 wait for 10 ns;
 
 end process;
 
end;
