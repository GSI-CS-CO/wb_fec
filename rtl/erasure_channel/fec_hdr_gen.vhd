--! @file fec_hdr_gen_stat.vhd
--! @brief Generates and streams the FEC header
--! @author C.Prados <c.prados@gsi.de> <bradomyn@gmail.com>
--!
--! For the encoder stores the original eth frame header and creates the fec one
--! For the decoder recovers the FEC header and uses for the FEC decoding and
--! recreates the eth hdr after decoding.
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
      g_subid_width : integer := 3;
      g_fec_type    : string  := "decoder"); -- decoder or encoder
    port (
      clk_i           : in  std_logic;
      rst_n_i         : in  std_logic;
      hdr_i           : in  t_wrf_bus;
      hdr_stb_i       : in  std_logic;
      fec_stb_i       : in  std_logic;
      fec_hdr_stb_i   : in  std_logic;
      fec_hdr_stall_i : in  std_logic;
      fec_hdr_done_o  : out std_logic;
      fec_hdr_o       : out t_wrf_bus;
      pkt_len_i       : in  t_eth_type;
      padding_i       : in  t_padding;
      enc_cnt_o       : out std_logic_vector(c_fec_cnt_width - 1 downto 0);
      ctrl_reg_i      : in  t_fec_ctrl_reg);
end fec_hdr_gen;

architecture rtl of fec_hdr_gen is
  signal id_cnt         : unsigned(c_fec_cnt_width - 1 downto 0);
  signal subid_cnt      : unsigned(g_subid_width - 1 downto 0);
  signal fec_hdr_stb_d  : std_logic;
  signal fec_stb_d      : std_logic;
  signal fec_hdr        : t_fec_header;
  signal fec_hdr_len    : unsigned(c_eth_hdr_len_width - 1 downto 0);
  signal eth_hdr_len    : unsigned(c_eth_hdr_len_width - 1 downto 0);
  signal eth_hdr_reg    : t_eth_hdr;
  signal eth_hdr_shift  : t_eth_hdr;
  signal eth_hdr        : t_eth_frame_header;
  signal pkt_len        : t_eth_type;
  constant c_is_decoder : boolean := g_fec_type = "decoder";
  constant c_is_encoder : boolean := g_fec_type = "encoder";
begin

  -- parsing ans saving ethernet header
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

  DECODER_HDR : if c_is_decoder generate
  stream_hdr  : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        fec_hdr_o   <= (others => '0');
        eth_hdr_len <= (others => '0');
        fec_hdr_done_o  <= '0';
      else
        if (fec_hdr_stall_i = '0') then
          if (fec_hdr_stb_i = '1') then
            if (eth_hdr_len <= c_eth_hdr_len - 1) then
              eth_hdr_len <= eth_hdr_len + 1;
            end if;
          else
            eth_hdr_len <= (others => '0');
          end if;

          if (eth_hdr_len <=  c_eth_hdr_len - 4) then
            fec_hdr_o <= f_extract_eth(eth_hdr_len, eth_hdr_reg);
          elsif (eth_hdr_len <=  c_eth_hdr_len - 3) then
            fec_hdr_done_o <= '1';
            fec_hdr_o <= ctrl_reg_i.eb_ethtype;
          else
            fec_hdr_done_o <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;
  end generate;

  ENCODER_HDR : if c_is_encoder generate
  stream_hdr  : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        fec_hdr_o   <= (others => '0');
        fec_hdr_len <= (others => '0');
      else
        if (fec_hdr_stb_i = '1') then
          if (fec_hdr_len <= c_fec_hdr_len - 1) then
            fec_hdr_len <= fec_hdr_len + 1;
          else
          end if;
        else
          fec_hdr_len <= (others => '0');
        end if;

        if (fec_hdr_len <=  c_fec_hdr_len - 5) then
          fec_hdr_o <= f_extract_eth(fec_hdr_len, eth_hdr_reg);
        elsif (fec_hdr_len <=  c_fec_hdr_len - 4) then
          fec_hdr_o <= ctrl_reg_i.fec_ethtype;
        elsif (fec_hdr_len <=  c_fec_hdr_len - 3) then
          fec_hdr_o <= fec_hdr.eth_pkt_len &
                       fec_hdr.fec_padding_crc;
        elsif (fec_hdr_len <=  c_fec_hdr_len - 2) then
          fec_hdr_o <= fec_hdr.fec_code &
                       fec_hdr.enc_frame_id &
                       fec_hdr.enc_frame_subid &
                       fec_hdr.reserved;
        end if;
      end if;
    end if;
  end process;


  fec_hdr_pack  : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        fec_hdr <=  c_fec_header;
      else
        fec_hdr.fec_code        <= ctrl_reg_i.fec_code;
        fec_hdr.enc_frame_id    <= std_logic_vector(id_cnt(g_id_width - 1 downto 0));
        fec_hdr.enc_frame_subid <= std_logic_vector(subid_cnt);
        fec_hdr.reserved        <= (others => '0');
        fec_hdr.eth_pkt_len     <= pkt_len(c_fec_hdr_pkt_len - 1 downto 0);
        fec_hdr.fec_padding_crc <= std_logic_vector(padding_i.pad_block xor
                                   padding_i.pad_pkt);
      end if;
    end if;
  end process;
  pkt_len <= std_logic_vector(unsigned(pkt_len_i) srl 1);

  id_fec_hdr  : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        id_cnt        <= (others =>'0');
        subid_cnt     <= (others =>'0');
        fec_hdr_stb_d <= '0';
        fec_stb_d     <= '0';
      else
        fec_stb_d     <= fec_stb_i;
        fec_hdr_stb_d <= fec_hdr_stb_i;

        if (fec_stb_d = '1' and fec_stb_i = '0') then
          id_cnt    <= id_cnt + 1;
          subid_cnt <= (others => '0');
        end if;

        if (fec_hdr_stb_d = '1' and fec_hdr_stb_i = '0') then
          subid_cnt    <= subid_cnt + 1;
        end if;
      end if;
    end if;
  end process;
  enc_cnt_o <= std_logic_vector(id_cnt);
  end generate;

end rtl;

