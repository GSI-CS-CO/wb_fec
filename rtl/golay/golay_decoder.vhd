--! @file golay_decoder.vhd
--! @brief 
--! @author C.Prados <cprados@mailfence.com>
--!
--! This core is a golay decoder (24,12,7). It uses the IMLD Algorithm 
--! for decoding expresed in max 3 states. It detects and fixes codewords 
--! with 3 errors and a set of codewords with 4 erros. Codewords > 5 errors 
--! are not fixed nor detected, for that reason please check the BER of your 
--! system. For more info about Golay decoder check the doc folder.
--! 
--! See the file "LICENSE" for the full license governing this code.
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.golay_pkg.all;

entity golay_decoder is
  port (
    clk_i       : in  std_logic;
    rst_n_i     : in  std_logic;
    stb_i       : in  std_logic;
    paycode_i   : in  std_logic_vector ((2 * golay_len) - 1 downto 0);
    decoded_o   : out std_logic;
    failed_o    : out std_logic;
    payload_o   : out std_logic_vector (golay_len - 1 downto 0));
end golay_decoder;

architecture rtl of golay_decoder is
  type t_dec is (IDLE, DECODING_0, DECODING_1, DECODING_2);
  signal s_dec        : t_dec;
  signal synd         : std_logic_vector (golay_len - 1 downto 0);
  signal synd_err     : std_logic_vector (golay_len - 1 downto 0);
  signal synd_d       : std_logic_vector (golay_len - 1 downto 0);
  signal codeword     : std_logic_vector (golay_len - 1 downto 0);
  signal parity       : std_logic_vector (golay_len - 1 downto 0);
  signal wgt_dec      : std_logic_vector (hmm_wgt - 1 downto 0);
  signal hmm_wgt      : std_logic_vector (hmm_wgt - 1 downto 0);
  signal paycode      : std_logic_vector ((2 * golay_len) - 1 downto 0);
  signal codeword_m   : t_matrix;
  signal hmm_wgt_m    : t_matrix_wgt;
  constant parity_gen : unsigned (golay_len - 1 downto 0) := x"001";
begin

  SYNDROME_CALC : syndrome
    port map (
      codeword_i  => paycode_i, 
      syndrome_o  => synd);
  
  SYNDROME_ERR_CALC : syndrome_err
    port map (
      codeword_i      => synd_d, 
      syndrome_err_o  => synd_err);

  HAMMWGT : hamming_wgt
    port map (
      vector_i    => codeword,
      hmm_wgt_o   => hmm_wgt);
  
  HAMMWGT_MATRIX : for i in 0 to golay_len - 1 generate
    HAMMWGT_M : hamming_wgt
      port map (
        vector_i    => codeword_m(i),
        hmm_wgt_o   => hmm_wgt_m(i));
  end generate;

  HAMMWGT_DEC : hamming_wgt_dec
    port map (
      hmm_wgt_i => hmm_wgt_m,
      wgt_dec_o => wgt_dec);

  process(clk_i)
    variable parity_vec : std_logic_vector (golay_len - 1 downto 0);
  begin
    if (rising_edge(clk_i)) then
      if(rst_n_i = '0') then
        paycode     <= (others => '0');
        codeword    <= (others => '0');
        synd_d      <= (others => '0');
        codeword_m  <= (others => (others => '0'));
        decoded_o   <= '0';
        failed_o    <= '0';
        payload_o   <= (others => '0');
        parity      <= (others => '0');
        parity_vec  := (others => '0');
        s_dec       <= IDLE;
      else
        case s_dec is
          when IDLE =>
            if (stb_i = '1') then
              paycode   <=  paycode_i;
              codeword  <=  synd;   -- calc weight
              s_dec     <= DECODING_0;
            end if;
            decoded_o <= '0';
            failed_o  <= '0';
            synd_d    <= synd;  -- calc beforehand the syndrome_err
          when DECODING_0   =>
            if (unsigned(hmm_wgt) <= 3) then
              -- decoded
              payload_o <= synd xor paycode((2 * golay_len) - 1 downto golay_len);
              parity    <= (others => '0');              
              decoded_o <= '1';
              s_dec     <= IDLE;
            else
              for i in 0 to golay_len - 1 loop
                codeword_m(i) <= parity_matrix(i) xor synd;  --calc matrix, weight and decode
              end loop;
              decoded_o <= '0';
              s_dec     <= DECODING_1;
            end if;
            codeword  <= synd_err; -- calc weight syndrome_err
          when DECODING_1   =>
            if(wgt_dec /= (wgt_dec'range => '1')) then
              -- decoded
              payload_o <= codeword_m(to_integer(unsigned(wgt_dec))) xor paycode((2 * golay_len) - 1 downto golay_len);
              parity    <= parity_matrix(to_integer(unsigned(wgt_dec))) xor paycode(golay_len - 1 downto 0);
              decoded_o <= '1';
              s_dec     <= IDLE;
            else
              if (unsigned(hmm_wgt) <= 3) then
                -- decoded
                payload_o <= paycode((2 * golay_len) - 1 downto golay_len);           
                parity    <= synd_err xor paycode(golay_len - 1 downto 0);              
                decoded_o <= '1';
                s_dec     <= IDLE;
              else
                for i in 0 to golay_len - 1 loop
                  codeword_m(i) <= parity_matrix(i) xor synd_err;  --calc matrix, weight and decode
                end loop;
                decoded_o <= '0';
                s_dec     <= DECODING_2;
              end if;
            end if;
          when DECODING_2   =>          
            if(wgt_dec /= (wgt_dec'range => '1')) then
              -- decoded
              parity_vec:= std_logic_vector(parity_gen sll (11 - to_integer(unsigned(wgt_dec))));
              payload_o <= parity_vec xor paycode((2 * golay_len) - 1 downto golay_len);
              parity    <= parity_matrix(to_integer(unsigned(wgt_dec))) xor paycode(golay_len - 1 downto 0);
              decoded_o <= '1';
              s_dec     <= IDLE;
            else
              failed_o  <= '1';
              decoded_o <= '0';
              s_dec     <= IDLE;
            end if;
        end case;
      end if;
    end if;
  end process;
end rtl;
