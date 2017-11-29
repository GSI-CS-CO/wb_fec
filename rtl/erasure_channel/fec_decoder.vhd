--! @file fec_decoder.vhd
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
    fec_payload_stb_i : in  std_logic;
    fec_stb_o         : out std_logic;
    pkt_payload_o     : out t_wrf_bus;
    pkt_payload_stb_o : out std_logic;
    halt_streaming_i  : in  std_logic;
    pkt_dec_err_o     : out t_dec_err);
end fec_decoder;

architecture rtl of fec_decoder is

  signal fec_decoded    : std_logic;
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
  signal block_stream   : integer range 0 to g_num_block - 1;
  signal fec_pkt_rx     : std_logic_vector (g_num_block - 1 downto 0);
  signal pkt_dec_err    : t_dec_err;
  signal payload_cnt    : unsigned (c_block_len_width - 1 downto 0);
  signal read_block     : std_logic_vector (g_num_block - 1 downto 0);
  signal we_loop_back   : std_logic_vector (g_num_block - 1 downto 0);
  signal we_src_sel     : unsigned (g_num_block - 1 downto 0);
  signal we_mask        : unsigned (g_num_block - 1 downto 0);
  signal we_loop_bacg   : std_logic_vector (g_num_block - 1 downto 0);
  signal pkt_block      : t_wrf_bus_array (0 to g_num_block - 1);
  signal payload_block  : t_wrf_bus_array (0 to g_num_block - 1);
  signal cnt            : t_fifo_cnt_array (0 to g_num_block - 1);
  signal empty          : std_logic_vector (g_num_block - 1 downto 0);
  signal full           : std_logic_vector (g_num_block - 1 downto 0);
  signal stream_out     : std_logic;
  signal block_len      : t_block_len;
  signal s_fec_hdr      : t_fec_header;
  signal fec_payload_stb_d  : std_logic;
  signal fec_payload_cnt    : unsigned(c_eth_pl_width - 1 downto 0);

  begin

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
        pkt_dec_err   <= c_dec_err;
        fec_pkt_rx    <= (others => '0');
        decoding_id   <= (others => '0');
        fec_decoded   := '0';
        new_pkt       := '0';
        fec_stb_o     <= '0';
        block_stream  <= 0;
        payload_cnt   <= (others => '0');
        pkt_payload_o <= (others => '0');
        fec_hdr       := (others => '0');
        block_len     <= (others => '0');
        s_fec_hdr     <= c_fec_header;
        fec_payload_stb_d <= '0';
      else
        fec_payload_stb_d <= fec_payload_stb_i;
        new_pkt   := (not fec_payload_stb_d) and fec_payload_stb_i;

        if (new_pkt = '1') then
          fec_hdr   := fec_payload_i;
          s_fec_hdr <= f_parse_fec_hdr(fec_payload_i);
          --fec_id      := fec_payload_i
          --fec_subid   := fec_hdr.enc_frame_subid;
          --block_len   <= fec_hdr.block_len;

          if (fec_id /= decoding_id) then
            -- new fec id
            new_fec_id  := '1';
            fec_decoded := '0';
            decoding_id <= fec_id;
          else
            new_fec_id  := '0';
            -- check if with the incoming pkt we can decode already
            fec_decoded := f_is_decoded(fec_pkt_rx, fec_subid);
          end if;
          fec_pkt_rx  <= f_update_pkt_rx(fec_pkt_rx, fec_subid, new_fec_id);
        end if;

        case s_DEC is
          when IDLE =>
            if (new_fec_id = '1')  then
            -- new fec_id, start decoding
              s_DEC     <= DECODING;
              s_NEXT_OP <= f_next_op(fec_pkt_rx, fec_subid);
              fec_stb_o <= '1';
            elsif (new_fec_id = '0')  then
            -- this fec_id has been already decoded, do nothing
              s_DEC     <= IDLE;
            end if;
          when DECODING =>
            if (new_pkt = '1') then
              if (new_fec_id = '0' and fec_decoded = '1') then
                s_DEC       <= DECODED;
              elsif(new_fec_id = '1') then
              -- new fec_id and the pkt was not decoded yet --> error and start dec
                pkt_dec_err.dec_err <= '1';
                fec_stb_o   <= '1';
                s_DEC       <= DECODING;
                s_NEXT_OP   <= f_next_op(fec_pkt_rx, fec_subid);
              else
              -- keep decoding
                pkt_dec_err.dec_err <= '0';
                s_NEXT_OP <= f_next_op(fec_pkt_rx, fec_subid);
              end if;
            end if;
          when DECODED =>
            if (stream_out = '1') then
              pkt_payload_stb_o <= '1';
              s_DEC <= STREAMING;
            else
              s_DEC <= DECODED;
            end if;
          when STREAMING =>
            if (halt_streaming_i = '0') then
              if (payload_cnt <= block_len - 1) then
                payload_cnt   <= payload_cnt + 1;
                read_block(block_stream) <= '1';
              elsif (block_stream <= g_num_block - 1) then
                payload_cnt   <= (others => '0');
                block_stream  <= block_stream + 1;
                read_block(block_stream)    <= '0';
                read_block(block_stream + 1)<= '1';
              else
                pkt_payload_stb_o <= '0';
                read_block        <= (others => '0');
                s_DEC             <= IDLE;
                fec_stb_o         <= '0';
              end if;
            end if;
            pkt_payload_o <=  payload_block(block_stream);
          when others =>
        end case;
      end if;
    end if;
  end process;

  -- Decoding
  CTRL_DEC :  process(clk_i) is
    variable subid    : t_enc_frame_sub_id;
    begin
    if rising_edge(clk_i) then
      if (rst_n_i =  '0') then
        stream_out      <= '0';
        payload_cnt     <= (others => '0');
        xor_we          <= '0';
        we_src_sel      <= (others => '0');
        read_block      <= (others => '0');
        fec_payload_cnt <= (others => '0');
        subid           := (others => '0');
      else
        subid := s_fec_hdr.enc_frame_subid;

        if (fec_payload_stb_i = '1') then
          fec_payload_cnt <= fec_payload_cnt + 1;
        else
          fec_payload_cnt <= (others => '0');
        end if;
        case s_NEXT_OP is
          when IDLE =>
            stream_out  <= '0';
          when STORE =>
            if (fec_payload_cnt <= block_len - 1) then
              xor_we <= c_FIFO_ON;  -- [0 xor 1] / [1 xor 2] / [2 xor 3] / [3 xor 0]
            elsif (payload_cnt <= (2 * block_len) - 1) then
              xor_we <= c_FIFO_OFF;
              --fifo_id := f_fifo_id(subid);
              --we_src_sel <= fifo_id; -- [0] / [1] / [2] / [3]
              we_src_sel <= f_fifo_id(subid); -- [0] / [1] / [2] / [3]
            else
              we_src_sel <= (others => '0');
            end if;
          when XOR_0_1 =>
            if (fec_payload_cnt <= block_len - 1) then
              read_block(2) <= c_FIFO_ON;
              pkt_block(1)  <= pkt_block(2) xor fec_payload_i; -- [2] xor [1 xor 2] = [1]
              we_src_sel(1) <= c_FIFO_ON;
            elsif (fec_payload_cnt <= (2 * block_len) - 1) then
              we_src_sel(1) <= c_FIFO_OFF;
              read_block(1) <= c_FIFO_ON;
              xor_rd        <= c_FIFO_ON;
              pkt_block(0)  <= pkt_block(1) xor xor_payload; -- [1] xor [0 xor 1] = [0]
              --we can start the streaming
              stream_out    <= '1';
              -- Store
              --fifo_id     := f_fifo_id(subid);
              --we_src_sel  <= fifo_id;  -- [3]
              we_src_sel <= f_fifo_id(subid); -- [3]
            else
              stream_out  <= '0';
            end if;
          when XOR_0_2 =>
          when XOR_0_3 =>
          when XOR_1_2 =>
          when XOR_1_3 =>
          when XOR_2_3 =>
          when others =>
        end case;
      end if;
    end if;
  end process;

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
        rst_n_i => rst_n_i,
        d_i     => fec_payload_i,
        we_i    => xor_we,
        empty_o => xor_empty,
        full_o  => xor_full,
        q_o     => xor_payload,
        rd_i    => xor_rd,
        count_o => xor_cnt);

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
        rst_n_i => rst_n_i,
        d_i     => payload_block(i),
        we_i    => we_mask(i),
        empty_o => empty(i),
        full_o  => full(i),
        q_o     => pkt_block(i),
        rd_i    => read_block(i),
        count_o => cnt(i));

    we_mask(i) <= (fec_payload_stb_i and we_src_sel(i)) or we_loop_back(i);

    -- the fifo gets the data from the pkt or fifo lopping back the output
    payload_block(i)  <=  fec_payload_i when we_src_sel(i) = '1' else
                          pkt_block(i)  when we_src_sel(i) = '0';
  end generate;
  we_loop_back  <= read_block;
end rtl;
