library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.golay_pkg.all;

entity golay_top is
  port(
    clk_20m_vcxo_i  : in  std_logic;  -- 20MHz VCXO clock
    payload_dec_o   : out std_logic_vector(golay_len - 1 downto 0)
    --clk_125m_local_i  	: in std_logic;  -- local clk from 125Mhz oscillator
    );
end golay_top;

architecture rtl of golay_top is
  
  -- Sys PLL from clk_125m_local_i
  signal sys_clk      : std_logic;
  signal locked       : std_logic;
  signal failed       : std_logic;
  signal decoded      : std_logic;
  signal rst_n        : std_logic := '0';
  signal stb          : std_logic := '0';
  signal stb_dec      : std_logic := '0';
  signal payload      : std_logic_vector(golay_len - 1 downto 0);      
  signal payload_dec  : std_logic_vector(golay_len - 1 downto 0);      
  signal codeword     : std_logic_vector(golay_len - 1 downto 0);      
  signal paycode      : std_logic_vector((2 * golay_len) - 1 downto 0);      


  component clock_pll is  -- arria2
    port(
      areset : in  std_logic;  
      inclk0 : in  std_logic; -- 20   MHz
      c0     : out std_logic;        -- 62.5 MHz
      locked : out std_logic);
  end component;

begin

 -- PLLs

  clk_proc : clock_pll port map(
    areset => '1',
    inclk0 => clk_20m_vcxo_i,    --  20  Mhz 
    c0     => sys_clk,         --  62.5MHz
    locked => locked);

  enc : golay_encoder
    port map (
      clk_i       => sys_clk,
      rst_n_i     => rst_n,
      stb_i       => stb,
      payload_i   => payload,
      code_word_o => codeword);

    paycode <= payload & codeword;
  
  dec : golay_decoder
    port map (
      clk_i     => sys_clk,
      rst_n_i   => rst_n,
      stb_i     => stb_dec,
      paycode_i => paycode,
      decoded_o => decoded,
      failed_o  => failed,
      payload_o => payload_dec);

  payload_dec_o <= payload_dec;

  cable : process(sys_clk)
  begin
    if rising_edge(sys_clk) then
      if (rst_n = '0') then
        rst_n <= '1'; 
        stb   <= '0';
        payload <= (others => '0');
      else
        stb     <= '1';
        stb_dec <= stb;
        payload <= (others => '1');
      end if;
    end if;
  end process;
end rtl;
