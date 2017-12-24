--! @file fec_len_pad.vhd
--! @brief Calculates the padding to the fec pkts
--! @author C.Prados <cprados@mailfence.com>
--! Calculates the len of the encoding fec blocks and pads the fec pkts up to 64 bits
--! or/and padding up to next multiple of 8
--!
--! See the file "LICENSE" for the full license governing this code.
--!-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fec_pkg.all;

entity fec_len_rx_pad is
    generic (
      g_num_block : integer := 4);
    port (
      clk_i           : in  std_logic;
      rst_n_i         : in  std_logic;
      fec_pad_stb_i   : in  std_logic;
      padding_crc_i   : in  t_fec_padding;
      pkt_len_i       : in  t_fec_hdr_pkt_len;
      fec_block_len_o : out t_block_len;
      padding_o       : out t_padding;
      pad_crc_err_o   : out std_logic);
end fec_len_rx_pad;

architecture rtl of fec_len_rx_pad is
  signal padding      : t_padding;
  signal fec_pad_stb_d: std_logic;
  signal pad_crc_rx   : t_fec_padding;
  signal fec_block_len: t_block_len;
  constant c_mult     : t_eth_pkt_len := x"007";
  constant c_not_mult : t_eth_pkt_len := not c_mult;
  constant c_min_pkt_len    : integer := 128;
  constant c_fec_min_block  : integer := 32; -- 16bit words = 64bytes
begin

  padding_o       <= padding;
  fec_block_len_o <= fec_block_len;

  calc_padding: process (clk_i) is
    variable pkt_len_mult   : t_eth_pkt_len;
    variable block_len      : t_eth_pkt_len;
    variable pad_pkt        : t_eth_pkt_len;
    variable pad_block      : t_eth_pkt_len;
    variable pkt_len        : t_eth_pkt_len;
    variable padding_crc    : t_fec_padding;
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        padding       <= c_padding;
        pad_crc_rx    <= (others => '0');
        fec_block_len <= (others => '0');
        pkt_len_mult  := (others => '0');
        pad_pkt       := (others => '0');
        pad_block     := (others => '0');
        pkt_len       := (others => '0');
        padding_crc   := (others => '0');
        block_len     := (others => '0');
      else
        fec_pad_stb_d <= fec_pad_stb_i;
        pad_crc_rx    <= padding_crc_i;
        if (fec_pad_stb_i = '1') then
          pkt_len := f_pkt_len_conv(pkt_len_i);
          -- next n multiple of x -- y = (x + (n-1)) & ~(n-1)
          pkt_len_mult  := (pkt_len + c_mult) and (not c_mult);
          -- length of single fec blocks
          block_len       := pkt_len_mult srl 3;
          fec_block_len   <= block_len(c_block_len_width - 1 downto 0);

          -- min lenght of pkt to enconde 128 bytes
          if (pkt_len < c_min_pkt_len) then
            pad_pkt   := (pkt_len_mult - pkt_len) srl 1; -- 16bit word
            pad_block := (c_min_pkt_len - pkt_len_mult) srl 2; -- 16bit word
          else
            pad_pkt   := (pkt_len_mult - pkt_len) srl 1;
            pad_block := (others => '0');
          end if;
          padding.pad_pkt   <= pad_pkt(c_fec_padding - 1 downto 0);
          padding.pad_block <= pad_block(c_fec_padding - 1 downto 0);
        elsif (fec_pad_stb_d = '1') then
          padding_crc := std_logic_vector(padding.pad_block xor padding.pad_pkt);
          if (pad_crc_rx /= padding_crc) then
            pad_crc_err_o <= '1';
          end if;
        else
          pad_crc_err_o <= '0';
        end if;
      end if;
    end if;
  end process;
end rtl;
