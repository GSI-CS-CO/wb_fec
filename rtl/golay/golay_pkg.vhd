--! @file golay_pkg.vhd
--! @brief package for the golay project
--! @author C.Prados <cprados@mailfence.com>
--!
--! package for the golay project
--! 
--! See the file "LICENSE" for the full license governing this code.
--!-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package golay_pkg is

  constant golay_len : integer := 12;
  constant hmm_wgt   : integer := 4;
  
  subtype  t_arrow_matrix_wgt is std_logic_vector (hmm_wgt - 1 downto 0);
  type     t_matrix_wgt is array (0 to golay_len - 1) of t_arrow_matrix_wgt;
 
  subtype  t_arrow_matrix is std_logic_vector (golay_len - 1 downto 0);
  type     t_matrix is array (0 to golay_len - 1) of t_arrow_matrix;

  constant parity_matrix    : t_matrix := (x"7ff", 
                                           x"ee2", 
                                           x"dc5", 
                                           x"b8b", 
                                           x"f16",
                                           x"e2d",
                                           x"c5b", 
                                           x"8b7", 
                                           x"96e", 
                                           x"adc",
                                           x"db8", 
                                           x"b71");

component golay_decoder is
  port (
    clk_i       : in  std_logic;
    rst_n_i     : in  std_logic;
    stb_i       : in  std_logic;
    paycode_i   : in  std_logic_vector ((2 * golay_len) - 1 downto 0);
    decoded_o   : out std_logic;
    failed_o    : out std_logic;
    payload_o   : out std_logic_vector (golay_len - 1 downto 0));
end component;

component golay_encoder is
  port (
    clk_i       : in  std_logic;
    rst_n_i     : in  std_logic;
    stb_i       : in  std_logic;
    payload_i   : in  std_logic_vector (golay_len - 1 downto 0);
    code_word_o : out std_logic_vector (golay_len - 1 downto 0));
end component;

component syndrome is
  port (  
    codeword_i  : in  std_logic_vector((2 * golay_len) - 1 downto 0);
    syndrome_o  : out std_logic_vector(golay_len - 1 downto 0));
end component;

component syndrome_err is
  port (  
    codeword_i      : in  std_logic_vector(golay_len - 1 downto 0);
    syndrome_err_o  : out std_logic_vector(golay_len - 1 downto 0));
end component;

component hamming_wgt
  port (
    vector_i    : in  std_logic_vector(golay_len - 1 downto 0);
    hmm_wgt_o   : out std_logic_vector(hmm_wgt - 1 downto 0));
end component;

component hamming_wgt_dec is
  port ( 
    hmm_wgt_i : in  t_matrix_wgt;
    wgt_dec_o : out std_logic_vector(hmm_wgt - 1 downto 0));
end component;

component full_adder is
  port (
    bit_0 : in  std_logic;
    bit_1 : in  std_logic;
    bit_2 : in  std_logic;
    add   : out std_logic_vector(1 downto 0));
end component;

component two_bit_adder is
  port (
    a   : in  std_logic_vector(1 downto 0);
    b   : in  std_logic_vector(1 downto 0);
    add : out std_logic_vector(2 downto 0));
end component;

component three_bit_adder is
  port (
    a   : in  std_logic_vector(2 downto 0);
    b   : in  std_logic_vector(2 downto 0);
    add : out std_logic_vector(3 downto 0));
end component;
end golay_pkg;
