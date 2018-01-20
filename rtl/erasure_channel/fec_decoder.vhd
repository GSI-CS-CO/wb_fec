--! @file fec_decoder.vhd
--! @brief  A FEC Decoder
--! @author C.Prados <c.prados@gsi.de> <bradomyn@gmail.com>
--!
--! Fixed Rate Decoder - for more information about this code check my thesis
--!
--! See the file "LICENSE" for the full license governing this code.
--!-----------------------------------------------------------------
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
    fec_payload_stb_i : in  std_logic;
    fec_pad_stb_i     : in  std_logic;
    fec_stb_o         : out std_logic;
    pkt_payload_o     : out t_wrf_bus;
    pkt_payload_stb_o : out std_logic;
    eth_stream_o      : out std_logic;
    dat_stream_i      : in  std_logic;
    halt_streaming_i  : in  std_logic;
    pkt_dec_err_o     : out std_logic);
end fec_decoder;

architecture rtl of fec_decoder is

  signal decoding_id    : t_enc_frame_id;
  type t_dec  is (IDLE, DECODING, DECODED, STREAMING);
  signal s_DEC          : t_dec;
  signal s_NEXT_OP      : t_next_op;
  signal xor_we         : std_logic;
  signal xor_empty      : std_logic;
  signal xor_full       : std_logic;
  signal xor_rd         : std_logic;
  signal xor_payload    : t_wrf_bus;
  signal xor_cnt        : t_fec_fifo_cnt_width;
  signal fec_pkt_rx     : std_logic_vector (g_num_block - 1 downto 0);
  signal pkt_dec_err    : std_logic;
  signal payload_cnt    : unsigned (c_block_len_width - 1 downto 0);
  signal read_block     : std_logic_vector (g_num_block downto 0);
  signal read_payload   : std_logic_vector (g_num_block downto 0);
  signal read_fec_block : std_logic_vector (g_num_block downto 0);
  signal we_src_sel     : t_we_src_sel(g_num_block downto 0);
  signal we_xor_sel     : t_we_src_sel(g_num_block downto 0);
  signal we_store_sel   : t_we_src_sel(g_num_block downto 0);
  signal we_mask        : unsigned (g_num_block downto 0);
  signal pkt_block_fifo : t_wrf_bus_array (0 to g_num_block);
  signal pkt_block_xor  : t_wrf_bus_array (0 to g_num_block);
  signal payload_block  : t_wrf_bus_array (0 to g_num_block);
  signal cnt            : t_fifo_cnt_array (0 to g_num_block);
  signal empty          : std_logic_vector (g_num_block downto 0);
  signal full           : std_logic_vector (g_num_block downto 0);
  signal stream_out     : std_logic;
  signal block_len      : t_block_len;
  signal s_fec_hdr      : t_fec_header;
  signal fec_pad_err    : std_logic;
  signal padding_crc    : t_fec_padding;
  signal pkt_len        : t_fec_hdr_pkt_len;
  signal padding        : t_padding;
  signal fec_payload    : t_wrf_bus;
  signal fec_stb        : std_logic;
  signal rst_n_dec      : std_logic;
  signal rst_n_fifo     : std_logic;
  signal cnt_stb        : std_logic;
  signal block_stream   : integer range 0 to g_num_block;
  signal fec_payload_stb_d  : std_logic;
  signal pkt_payload_stb    : std_logic;
  signal fec_payload_cnt    : unsigned(c_eth_pl_width - 1 downto 0);
  begin

  PADDING_MOD: fec_len_rx_pad
    port map (
      clk_i           => clk_i,
      rst_n_i         => rst_n_i,
      fec_pad_stb_i   => fec_pad_stb_i,
      padding_crc_i   => padding_crc,
      pkt_len_i       => pkt_len,
      fec_block_len_o => block_len,
      padding_o       => padding,
      pad_crc_err_o   => fec_pad_err);

  pkt_len     <= fec_payload_i(15 downto 6);
  padding_crc <= fec_payload_i(5 downto 0);

  fec_stb_o   <= fec_stb;

  -- Ctrl deFEC sequences
  CTRL_deFEC :  process(clk_i) is
    variable new_pkt      : std_logic;
    variable new_fec_id   : std_logic;
    variable fec_decoded  : std_logic;
    variable fec_hdr      : t_wrf_bus;
    alias fec_id          : t_enc_frame_id is fec_hdr(fec_id_range);
    alias fec_subid       : t_enc_frame_sub_id is fec_hdr(fec_subid_range);

  begin
    if rising_edge(clk_i) then
      if (rst_n_i =  '0') then
        s_DEC         <= IDLE;
        s_NEXT_OP     <= IDLE;
        pkt_dec_err   <= '0';
        fec_pkt_rx    <= (others => '0');
        decoding_id   <= (others => '1');
        fec_decoded   := '0';
        new_pkt       := '0';
        fec_stb       <= '0';
        block_stream  <= 0;
        payload_cnt   <= (others => '0');
        fec_hdr       := (others => '0');
        s_fec_hdr     <= c_fec_header;
        new_fec_id    := '0';
        rst_n_dec     <= '1';
        cnt_stb       <= '0';
        fec_payload_stb_d <= '0';
        pkt_payload_stb <= '0';
      else
        fec_payload_stb_d <= fec_payload_stb_i;
        new_pkt   := (not fec_payload_stb_d) and fec_payload_stb_i;

        if (new_pkt = '1') then
          fec_hdr   := fec_payload_i;
          s_fec_hdr <= f_parse_fec_hdr(fec_payload_i);

          if (fec_id /= decoding_id) then
            -- new fec id
            new_fec_id  := '1';
            fec_decoded := '0';
            decoding_id <= fec_id;
          else
            new_fec_id  := '0';
            -- check if with the incoming pkt we can already decode
            fec_decoded := f_is_decoded(fec_pkt_rx, fec_subid);
          end if;
          fec_pkt_rx  <= f_update_pkt_rx(fec_pkt_rx, fec_subid, new_fec_id);
        end if;

        case s_DEC is
          when IDLE =>
            if (new_fec_id = '1')  then
            -- new fec_id, start decoding
              s_DEC     <= DECODING;
              s_NEXT_OP <= f_next_op("0000", fec_subid);
              fec_stb   <= '1';
              rst_n_dec <= '1';
              pkt_dec_err <= '0';
            elsif (new_fec_id = '0')  then
            -- this fec_id has been already decoded, do nothing
              s_DEC     <= IDLE;
              rst_n_dec <= '0';
            end if;
          when DECODING =>
            if (new_pkt = '1') then
              if (new_fec_id = '0' and fec_decoded = '1') then
                s_DEC       <= DECODED;
              elsif(new_fec_id = '1') then
              -- new fec_id and the pkt was not decoded yet --> error and start dec
                pkt_dec_err <= '1';
                rst_n_dec   <= '0';
                fec_stb     <= '1';
                s_DEC       <= IDLE;
              else
              -- keep decoding
                pkt_dec_err <= '0';
              end if;
              s_NEXT_OP <= f_next_op(fec_pkt_rx, fec_subid);
            end if;
          when DECODED =>
            if (dat_stream_i = '1') then
              pkt_payload_stb <= '1';
              s_DEC <= STREAMING;
            else
              s_DEC <= DECODED;
            end if;
          when STREAMING =>
            if (halt_streaming_i = '0') then
              if ((payload_cnt < block_len - 1) and pkt_payload_stb = '1') then
                payload_cnt       <= payload_cnt + 1;
              else
                payload_cnt   <= (others => '0');
              end if;

              if (payload_cnt < block_len - 1) then
                cnt_stb         <= '1';
                pkt_payload_stb <= '1';
              elsif (block_stream < g_num_block - 1) then
                block_stream  <= block_stream + 1;
              else
                cnt_stb           <= '0';
                pkt_payload_stb   <= '0';
                s_DEC             <= IDLE;
                s_NEXT_OP         <= IDLE;
                block_stream      <= 0;
                fec_stb           <= '0';
              end if;
            end if;
          when others =>
        end case;
      end if;
    end if;
  end process;

  pkt_dec_err_o <= pkt_dec_err;

  read_payload  <= f_hotbit(block_stream) when s_DEC = STREAMING and halt_streaming_i = '0' else
                   (others => '0');

  pkt_payload_o <=  pkt_block_fifo(block_stream) when  halt_streaming_i = '0' else
                    (others => '0');

  pkt_payload_stb_o <= pkt_payload_stb;

  -- Decoding
  CTRL_DEC :  process(clk_i) is
    variable subid    : t_enc_frame_sub_id;
    variable new_pkt  : std_logic;
    begin
    if rising_edge(clk_i) then
      if (rst_n_i =  '0') then
        stream_out      <= '0';
        xor_we          <= '0';
        --xor_rd          <= '0';
        we_store_sel    <= (others => (others => '0'));
        we_xor_sel    <= (others => (others => '0'));
        fec_payload_cnt <= (others => '0');
        fec_payload     <= (others => '0');
        subid           := (others => '0');
        new_pkt         := '0';
      else

        new_pkt   := (not fec_payload_stb_d) and fec_payload_stb_i;
        if (fec_payload_stb_d = '1' and new_pkt = '0') then
          fec_payload_cnt <= fec_payload_cnt + 1;
        elsif (new_pkt = '1' and stream_out = '0') then
          fec_payload_cnt <= (others => '0');
        end if;

        case s_NEXT_OP is
          when IDLE =>
            stream_out  <= '0';
            xor_we      <= c_FIFO_OFF;
          when STORE =>
            if (fec_payload_cnt <= block_len - 1) then
              xor_we        <= c_FIFO_ON;  -- [0 xor 1] / [1 xor 2] / [2 xor 3] / [3 xor 0]
            elsif (fec_payload_cnt <= (2 * block_len) - 1) then
              xor_we        <= c_FIFO_OFF;
              we_store_sel  <= f_fifo_id(subid);
            else
              we_store_sel  <= (others => (others => '0'));
            end if;
          when XOR_0_1 =>
            if (fec_payload_cnt <= block_len - 1) then
              pkt_block_xor(1)  <= pkt_block_fifo(2) xor fec_payload_i; -- [2] xor [1 xor 2] = [1]
              pkt_block_xor(4)  <= pkt_block_fifo(2) xor fec_payload_i; -- tmp fifo for next op
            elsif (fec_payload_cnt <= (2 * block_len) - 1) then
              stream_out        <= '1';
              pkt_block_xor(0)  <= pkt_block_fifo(4) xor xor_payload;   -- [1] xor [0 xor 1] = [0]
            end if;
          when XOR_0_2 =>
            if (fec_payload_cnt <= block_len - 1) then
              pkt_block_xor(3)  <= pkt_block_fifo(2) xor fec_payload_i; -- [2] xor [2 xor 3] = [3]
            elsif (fec_payload_cnt <= (2 * block_len) - 1) then
              pkt_block_xor(1)  <= fec_payload_i xor xor_payload;       -- [0] xor [0 xor 1] = [1]
              stream_out        <= '1';
            end if;
          when XOR_0_3 =>
          if (fec_payload_cnt <= block_len - 1) then
              pkt_block_xor(4)  <= fec_payload_i;                       -- [3 xor 0]
            elsif (fec_payload_cnt <= (2 * block_len) - 1) then
              stream_out        <= '1';
              pkt_block_xor(3)  <= pkt_block_fifo(4) xor xor_payload xor
                                   fec_payload_i;                       -- [0 xor 1] xor [3 xor 0] xor [1] = [3]
              pkt_block_xor(0)  <= xor_payload xor fec_payload_i;       -- [0 xor 1] xor [1] = [0]
            end if;
          when XOR_1_2 =>
            if (fec_payload_cnt <= block_len - 1) then
              pkt_block_xor(2)  <= pkt_block_fifo(3) xor fec_payload_i; -- [3] xor [2 xor 3] = [2]
              pkt_block_xor(4)  <= pkt_block_fifo(3) xor fec_payload_i; -- tmp fifo for next op
            elsif (fec_payload_cnt <= (2 * block_len) - 1) then
              stream_out        <= '1';
              pkt_block_xor(1)  <= pkt_block_fifo(4) xor xor_payload;   -- [2] xor [1 xor 2] = [1]
            end if;
          when XOR_1_3 =>
            if (fec_payload_cnt <= block_len - 1) then
              pkt_block_xor(0)  <= pkt_block_fifo(3) xor fec_payload_i; -- [3] xor [3 xor 0] = [0]
            elsif (fec_payload_cnt <= (2 * block_len) - 1) then
              stream_out        <= '1';
              pkt_block_xor(2)  <= fec_payload_i xor xor_payload;   -- [1] xor [1 xor 2] = [2]
            end if;
          when XOR_2_3 =>
            if (fec_payload_cnt <= block_len - 1) then
              pkt_block_xor(3)  <= pkt_block_fifo(0) xor fec_payload_i; -- [0] xor [3 xor 0] = [3]
              pkt_block_xor(4)  <= pkt_block_fifo(0) xor fec_payload_i; -- tmp fifo for next op
            elsif (fec_payload_cnt <= (2 * block_len) - 1) then
              stream_out        <= '1';
              pkt_block_xor(2)  <= pkt_block_fifo(4) xor xor_payload;   -- [3] xor [2 xor 3] = [2]
            end if;
          when others =>
        end case;

        fec_payload <= fec_payload_i;
        subid       := s_fec_hdr.enc_frame_subid;
        we_xor_sel  <= f_we_src_sel(s_NEXT_OP, subid, fec_payload_cnt, block_len);
      end if;
    end if;
  end process;

  we_src_sel  <= we_store_sel               when s_NEXT_OP = STORE else
                 (others => (others => '0'))when s_NEXT_OP = IDLE  else
                 we_xor_sel;

  xor_rd  <= c_FIFO_ON when (s_NEXT_OP = XOR_0_1 and fec_payload_cnt > block_len - 1) else
             c_FIFO_ON when (s_NEXT_OP = XOR_0_2 and fec_payload_cnt > block_len - 1) else
             c_FIFO_ON when (s_NEXT_OP = XOR_1_2 and fec_payload_cnt > block_len - 1) else
             c_FIFO_ON when (s_NEXT_OP = XOR_1_3 and fec_payload_cnt > block_len - 1) else
             c_FIFO_ON when (s_NEXT_OP = XOR_2_3 and fec_payload_cnt > block_len - 1) else
             c_FIFO_ON when (s_NEXT_OP = XOR_0_3 and fec_payload_cnt > block_len - 1) else
             c_FIFO_OFF;

  read_block  <= f_read_block(s_NEXT_OP, fec_payload_cnt, block_len);
  eth_stream_o <= stream_out;

  -- XOR FIFO
    XOR_BLOCK_FIFO : generic_sync_fifo
      generic map (
        g_data_width  => c_wrf_width,
        g_size        => c_fec_fifo_size,
        g_with_full   => true,
        g_with_empty  => true,
        g_with_count  => true,
        g_show_ahead  => true)
      port  map (
        clk_i   => clk_i,
        rst_n_i => rst_n_fifo,
        d_i     => fec_payload,
        we_i    => xor_we,
        empty_o => xor_empty,
        full_o  => xor_full,
        q_o     => xor_payload,
        rd_i    => xor_rd,
        count_o => xor_cnt);

  rst_n_fifo <= rst_n_i and rst_n_dec;

  -- Blocks FIFO
  g_PKT_BLOCK_FIFO : for i in 0 to g_num_block generate
    PKT_BLOCKS_FIFO : generic_sync_fifo
      generic map (
        g_data_width  => c_wrf_width,
        g_size        => c_fec_fifo_size,
        g_with_full   => true,
        g_with_empty  => true,
        g_with_count  => true,
        g_show_ahead  => true)
      port  map (
        clk_i   => clk_i,
        rst_n_i => rst_n_fifo,
        d_i     => payload_block(i),
        we_i    => we_mask(i),
        empty_o => empty(i),
        full_o  => full(i),
        q_o     => pkt_block_fifo(i),
        rd_i    => read_fec_block(i),
        count_o => cnt(i));

    payload_block(i)  <=  fec_payload       when we_src_sel(i) = c_PAYLOAD  else
                          pkt_block_xor(i)  when we_src_sel(i) = c_XOR_OP   else
                          pkt_block_fifo(i) when read_fec_block(i) = '1'    else
                          (others => '0')   when we_src_sel(i) = c_DEC_IDLE;

    we_mask(i)  <=  '1' and fec_payload_stb_i when (read_fec_block(i) = '1' or we_src_sel(i) /= c_DEC_IDLE) else
                    '0';

    read_fec_block(i) <= read_block(i) or read_payload(i);
  end generate;
end rtl;
