library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
library work;
use work.golay_pkg.all;

entity hamming_weight_tb is
end hamming_weight_tb;
 
architecture behavior of hamming_weight_tb is

  constant clk_period : time := 8 ns;

  signal clk    : std_logic;
  signal rst_n  : std_logic;
  signal stb    : std_logic;
  signal vector : std_logic_vector(golay_len - 1 downto 0);
  signal dist   : std_logic_vector(hmm_dist - 1 downto 0);
 
begin
 
  H : golay_hamming_distance
    port map (
      clk_i       => clk,
      rst_n_i     => rst_n,
      hmm_stb_i   => stb,
      vector_i    => vector,
      hmm_dist_o  => dist);

   clk_process : process
   begin
        clk <= '0';
        wait for clk_period/2;  --for 0.5 ns signal is '0'.
        clk <= '1';
        wait for clk_period/2;  --for next 0.5 ns signal is '1'.
   end process;    

 -- stimulus process
 stim_proc: process
 begin
 -- hold reset state for 100 ns.
 wait for 8 ns;
 rst_n  <= '0';
 
 wait for 16 ns;
 rst_n  <= '1';
 wait for 8 ns;
 vector <= x"0FF";
 stb  <= '1';
 wait for 8 ns;
 vector <= x"003";
 stb  <= '1';
 wait for 8 ns;
 vector <= x"005";
 stb  <= '1';
 wait for 8 ns;
 vector <= x"007";
 stb  <= '1';
 wait for 8 ns;
 vector <= x"0FA";
 stb  <= '1';
 wait for 8 ns; 
 vector <= x"FFF";
 stb  <= '1';
 wait for 8 ns;

 end process;
end;
