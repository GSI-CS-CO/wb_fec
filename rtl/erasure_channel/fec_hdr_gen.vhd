--! @file fec_hdr_gen_stat.vhd
--! @brief Generates and streams the FEC header
--! @author C.Prados <cprados@mailfence.com>
--!
--! See the file "LICENSE" for the full license governing this code.
--!-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fec_pkg.all;

entity fec_hdr_gen is
    generic (
      g_id_width    : integer := 6;
      g_subid_width : integer := 3);
    port (
      clk_i       : in  std_logic;
      rst_n_i     : in  std_logic;
      hdr_i       : in  t_wrf_bus;
      hdr_stb_i   : in  std_logic;
      block_len_i : in  unsigned (c_eth_pl_width - 1 downto 0);
      stb_i       : in  std_logic;
      fec_stb_i   : in  std_logic;
      fec_hdr_o   : out t_wrf_bus;
      enc_cnt_o   : out std_logic_vector(c_fec_cnt_width - 1 downto 0);
      ctrl_reg_i  : in  t_fec_ctrl_reg);
end fec_hdr_gen;

architecture rtl of fec_hdr_gen is
  signal id_cnt       : unsigned(c_fec_cnt_width - 1 downto 0);
  signal subid_cnt    : unsigned(g_subid_width - 1 downto 0);
  signal stb_d        : std_logic;
  signal fec_stb_d    : std_logic;
  --signal fec_hdr      : t_wrf_bus_array (0 to 1);
  signal fec_hdr      : t_wrf_bus;
  signal hdr_len_word : integer range 0 to 1; 
  signal eth_hdr_reg      : t_eth_hdr;
  signal eth_hdr_shift    : t_eth_hdr;
  signal eth_hdr          : t_eth_frame_header;
  constant hdr_reserved : std_logic_vector(2 downto 0) := "000";
begin

  stream_hdr  : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        fec_hdr_o     <= (others => '0');
        hdr_len_word  <= 0;
      else
        if (stb_i = '1') then
          hdr_len_word <= hdr_len_word + 1;  
        else
          hdr_len_word <= 0;
        end if;
        fec_hdr_o <= fec_hdr;
      end if;
    end if;
  end process;

  -- parsing ethernet header
  eth_hdr_reg <= eth_hdr_shift(eth_hdr_shift'left - hdr_i'length downto 0) & hdr_i;
  eth_hdr_pack  : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then       
        eth_hdr_shift   <= (others => '0');
        eth_hdr         <= c_eth_frame_header_default;
      else
        if (hdr_stb_i = '1') then
          eth_hdr       <= f_parse_eth(eth_hdr_reg);
          eth_hdr_shift <= eth_hdr_reg;
        end if;
      end if;
    end if;
  end process;
  

  fec_hdr_pack  : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        fec_hdr <=  (others => '0');
      else
        fec_hdr <=  ctrl_reg_i.fec_pkt_er_code &
                    ctrl_reg_i.fec_bit_er_code &
                    std_logic_vector(id_cnt(g_id_width -1 downto 0)) &
                    std_logic_vector(subid_cnt) & 
                    hdr_reserved;
      end if;
    end if;
  end process;

  id_fec_hdr  : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        id_cnt    <= (others =>'0');
        subid_cnt <= (others =>'0');
        stb_d     <= '0';
        fec_stb_d <= '0';
      else
        stb_d     <= stb_i;
        fec_stb_d <= fec_stb_i;

        if (stb_d = '0' and stb_i = '1') then
          id_cnt    <= id_cnt + 1;
          subid_cnt <= (others => '0');
        end if;

        if (fec_stb_d = '0' and fec_stb_i = '1') then
          subid_cnt    <= subid_cnt + 1;
        end if;
      end if;
    end if;
  end process;
  enc_cnt_o <= std_logic_vector(id_cnt);

end rtl;

