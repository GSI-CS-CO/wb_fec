library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
library work;
use work.golay_pkg.all;

entity golay_tb is
end golay_tb;
 
architecture behavior of golay_tb is

  constant clk_period : time := 8 ns;

  signal clk          : std_logic;
  signal rst_n        : std_logic;
  signal stb          : std_logic;
  signal stb_dec      : std_logic;
  signal payload      : std_logic_vector(golay_len - 1 downto 0);
  signal payload_dec  : std_logic_vector(golay_len - 1 downto 0);
  signal codeword     : std_logic_vector(golay_len - 1 downto 0);
  signal paycode      : std_logic_vector((2 * golay_len) - 1 downto 0);
 
begin

  uut_enc : golay_encoder
    port map (
      clk_i       => clk,
      rst_n_i     => rst_n,
      stb_i       => stb,
      payload_i   => payload,
      code_word_o => codeword);

  cable : process(clk)
  begin
    if rising_edge(clk) then
      if (rst_n = '0') then
        stb_dec <= '0';
        paycode <= (others => '0');
      else
        stb_dec <= stb;
        paycode <= payload & codeword;
      end if;
    end if;
  end process;

  uut_dec : golay_decoder
  port map (
    clk_i     => clk,
    rst_n_i   => rst_n,
    stb_i     => stb_dec,
    paycode_i => paycode,
    payload_o => payload_dec);

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
 rst_n  <= '0';
 stb    <= '0';
 payload <= (others => '0');
 wait for 16 ns;
 rst_n  <= '1';
 wait for 8 ns;
 payload <= x"0FC";
 stb  <= '1';
 wait for 8 ns; 
 stb  <= '0';
 wait for 16 ns;
 payload <= x"A27";
 stb  <= '1';
 wait for 8 ns; 
 stb  <= '0';
 wait for 16 ns;
 payload <= x"005";
 stb  <= '1';
 wait for 8 ns;
 stb  <= '0';
 wait for 16 ns;
 payload <= x"007";
 stb  <= '1';
 wait for 8 ns; 
 stb  <= '0';
 wait for 16 ns;
 payload <= x"0FA";
 stb  <= '1';
 wait for 8 ns;  
 stb  <= '0';
 wait for 16 ns;
 payload <= x"FFF";
 stb  <= '1';
 wait for 8 ns;
 stb  <= '0';
 wait for 16 ns;
 end process;
end;
