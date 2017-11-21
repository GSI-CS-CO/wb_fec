--! @file fec_dncoder.vhd
--! @brief  A FEC Decoder
--! @author C.Prados <cprados@mailfence.com>
--!
--! See the file "LICENSE" for the full license governing this code.
--!-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fec_pkg.all;
use work.genram_pkg.all;
use work.wishbone_pkg.all;

entity fec_decoder is
  generic (
    g_num_block : integer := 4); -- power of 2 e.g. 8, 16...
  port (
    clk_i             : in  std_logic;
    rst_n_i           : in  std_logic;
    fec_payload_i     : in  t_wrf_bus;
    fec_stb_i         : in  std_logic;
    pkt_payload_o     : out t_wrf_bus;
    pkt_payload_stb_o : out std_logic;
    fec_id_i          : in  t_fec_id;
    pkt_dec_err_o     : out t_dec_err);
end fec_decoder;

architecture rtl of fec_decoder is

  signal decoded        : std_logic;
  signal decoding       : std_logic;
  signal decoding_id    : t_enc_frame_id;a

  signal decoding_subid : t_enc_frame_sub_id;

begin


  -- Ctrl deFEC sequences
  CTRL_deFEC:  process(clk_i) is
    if rising(clk_i) then
      if (rst_n_i =  '0') then
        s_DEC       <= IDLE;
        decoding    <= '0';           
        decoded     <= '0';
        fec_pkts    <= (others => '0');
        pkt_dec_err <= (others => '0');
        decoding_id <= (others => '0');
        fec_stb_d   <= '0';
      else
        fec_stb_d <= fec_stb;
        new_pkt   := (not fec_stb_d) and fec_stb;

        case s_DEC is
          when IDLE =>
            if (new_pkt = '1') then
              s_DEC       <= DECODING;
              decoding    <= '1';
              decoding_id <= fec_id_i.id;
            else
              s_DEC       <= IDLE;
              fec_pkt_rx  <= (others => '0');
              pkt_dec_err <= (others => '0');
              decoding_id <= (others => '0');
            end if;
          when DECODING =>

            function(fec_pkt_rx(fec_id_i.subid) = '1';)

            if (new_pkt = '1' and fec_id_i.id /= decoding_id) then
            -- new fec_id and the pkt was not decoded yet
              decoding_id <= fec_id_i.id;
              pkt_dec_err <= '1';
              s_DEC       <= DECODING; --keep decoding the new fec pktsa
            else
            -- keep decoding 
              pkt_dec_err <= '0';
            end if;
          when DECODED =>
            decoding  <= '0';
            decoded   <= '1';
          when others =>
        end case;
      end if;
    end if;
  end process;


  -- Blocks FIFO
  g_PKT_BLOCK_FIFO : for i in 0 to g_num_block - 1 generate
    PKT_BLOCK_FIFO : generic_sync_fifo
      generic map (
        g_data_width  => c_wrf_width,
        g_size        => c_fec_fifo_size,
        g_with_full   => true,
        g_with_empty  => true,
        g_with_count  => true,
        g_show_ahead  => true)
      port  map (
        clk_i   => clk_i,
        rst_n_i => rst_n,
        d_i     => pl_block(i),
        we_i    => we_mask(i),
        empty_o => empty(i),
        full_o  => full(i),
        q_o     => block2enc(i),
        rd_i    => read_block(i),
        count_o => cnt(i));

end rtl;
