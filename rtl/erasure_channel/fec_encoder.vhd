--! @file fec_encoder.vhd
--! @brief  A FEC Encoder
--! @author C.Prados <c.prados@gsi.de> <bradomyn@gmail.com>
--!
--! Fixed Rate Encoder -- for more information about this code check my thesis
--!
--! See the file "LICENSE" for the full license governing this code.
--!----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fec_pkg.all;
use work.genram_pkg.all;
use work.wishbone_pkg.all;

entity fec_encoder is
  generic (
    g_num_block : integer := 4); -- power of 2 e.g. 8, 16...
  port (
    clk_i         : in  std_logic;
    rst_n_i       : in  std_logic;
    payload_i     : in  t_wrf_bus;
    payload_stb_i : in  std_logic;
    fec_stb_i     : in  std_logic;
    fec_enc_rd_i  : in  std_logic;
    block_len_i   : in  t_block_len;
    streaming_o   : out std_logic;
    enc_err_o     : out std_logic;
    enc_payload_o : out t_wrf_bus);
end fec_encoder;

architecture rtl of fec_encoder is
  signal rst_n        : std_logic;
  signal empty        : std_logic_vector (g_num_block - 1 downto 0);
  signal full         : std_logic_vector (g_num_block - 1 downto 0);
  signal block2enc    : t_wrf_bus_array (0 to g_num_block - 1);
  signal pl_block     : t_wrf_bus_array (0 to g_num_block - 1);
  signal xor_code     : t_wrf_bus;
  signal fifo_wr      : std_logic;
  signal fifo_empty   : std_logic;
  signal fifo_full    : std_logic;
  signal fifo_cnt     : t_out_fifo_cnt_width;
  signal read_block   : t_read_block;
  signal block_cnt    : unsigned (c_eth_pl_width - 1 downto 0);
  signal enc_cnt      : t_block_len;
  signal fec_pkt_cnt  : t_fec_pkt_cnt;
  signal we_src_sel   : unsigned (g_num_block - 1 downto 0);
  signal we_mask      : unsigned (g_num_block - 1 downto 0);
  signal we_loop_back : std_logic_vector (g_num_block - 1 downto 0);
  type t_dec_cnt is (IDLE, ENCODING);
  signal s_ENC_CNT    : t_dec_cnt;
  signal enc_payload  : t_wrf_bus;
  signal cnt          : t_fifo_cnt_array (0 to g_num_block - 1);
  constant c_fec_blocks   : integer := 2 * g_num_block;
begin

  -- FIFO block read ctrl
  read_block  <=  c_FIFO_0_1 when fec_pkt_cnt = c_PKT_0_1 else
                  c_FIFO_Z   when fec_pkt_cnt = c_PKT_0_2 else
                  c_FIFO_1_2 when fec_pkt_cnt = c_PKT_1_1 else
                  c_FIFO_ALL when fec_pkt_cnt = c_PKT_1_2 or
                                  fec_pkt_cnt = c_PKT_2_1 or
                                  fec_pkt_cnt = c_PKT_3_1 or
                                  fec_pkt_cnt = c_PKT_3_2 else
                  c_FIFO_Z   when fec_pkt_cnt = c_IDLE;

  -- The simple encoding
  enc_payload   <= xor_code;
  xor_code <= block2enc(0) xor payload_i    when fec_pkt_cnt = c_PKT_0_1 else
              payload_i                     when fec_pkt_cnt = c_PKT_0_2 else
              block2enc(1) xor block2enc(2) when fec_pkt_cnt = c_PKT_1_1 else
              block2enc(3)                  when fec_pkt_cnt = c_PKT_1_2 else
              block2enc(2) xor block2enc(3) when fec_pkt_cnt = c_PKT_2_1 else
              block2enc(0)                  when fec_pkt_cnt = c_PKT_2_2 else
              block2enc(3) xor block2enc(0) when fec_pkt_cnt = c_PKT_3_1 else
              block2enc(1)                  when fec_pkt_cnt = c_PKT_3_2 else
              (others => '0')               when fec_pkt_cnt = c_IDLE;

  -- Counters to control de enconding and streaming
  coding_streaming_fsm : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        enc_cnt       <= (others => '0');
        fec_pkt_cnt   <= c_IDLE;
        fifo_wr       <= '0';
        streaming_o   <= '0';
      else
        case s_ENC_CNT is
          when IDLE =>
            -- start enconding, storing in output FIFO and streaming as soon as enough data is received
            if (we_src_sel = 1 and block_cnt > block_len_i - 2) then
              s_ENC_CNT   <= ENCODING;
              fifo_wr     <= '1';
              streaming_o <= '1';
              fec_pkt_cnt <= fec_pkt_cnt + 1;
            end if;
          when ENCODING =>
            if (enc_cnt < block_len_i - 1) then
              enc_cnt <= enc_cnt + 1;
            elsif (fec_pkt_cnt < c_fec_blocks) then
              enc_cnt     <= (others => '0');
              fec_pkt_cnt <= fec_pkt_cnt + 1;
            else
              s_ENC_CNT   <= IDLE;
              enc_cnt     <= (others => '0');
              fec_pkt_cnt <= c_IDLE;
              fifo_wr     <= '0';
              streaming_o <= '0';
            end if;
        end case;
      end if;
    end if;
  end process;

  -- Encoded output FIFO
  ENC_PKT_FIFO : generic_sync_fifo
    generic map (
      g_data_width  => c_wrf_width,
      g_size        => c_out_fifo_size,
      g_with_full   => true,
      g_with_empty  => true,
      g_with_count  => true,
      g_show_ahead  => true)
    port  map (
      clk_i   => clk_i,
      rst_n_i => rst_n,
      d_i     => enc_payload,
      we_i    => fifo_wr,
      empty_o => fifo_empty,
      full_o  => fifo_full,
      count_o => fifo_cnt,
      q_o     => enc_payload_o,
      rd_i    => fec_enc_rd_i);

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

  we_mask(i) <= (payload_stb_i and we_src_sel(i)) or we_loop_back(i);

  -- the fifo gets the data from the pkt or fifo lopping back the output
  pl_block(i) <=  payload_i     when we_src_sel(i) = '1' else
                  block2enc(i)  when we_src_sel(i) = '0';
  end generate g_PKT_BLOCK_FIFO;

  we_loop_back  <= read_block;
  rst_n <= rst_n_i and (payload_stb_i or fec_stb_i);

  -- steers incoming data to the FIFO blocks
  fifo_wr_mux : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        block_cnt     <= (others => '0');
        we_src_sel    <= (others => '0');
        we_src_sel(0) <= '1';
        enc_err_o     <= '0';
      else
        -- Pkt word (16 bit) cnt source data for info source (pkt, loopback)
        if (payload_stb_i = '0' and fec_stb_i = '0') then
          block_cnt     <= (others => '0');
          we_src_sel    <= (others => '0');
          we_src_sel(0) <= '1';
        elsif (payload_stb_i = '0' and fec_stb_i = '1') then
          block_cnt     <= (others => '0');
          we_src_sel    <= (others => '0');
        elsif (payload_stb_i = '1') then
          if (block_cnt < block_len_i - 1) then
            block_cnt <= block_cnt + 1;
          elsif ((block_cnt = block_len_i  - 1) and (we_src_sel /= (we_src_sel'range => '0'))) then
            block_cnt   <= (others => '0');
            we_src_sel  <= we_src_sel sll 1;
          end if;
        end if;
      end if;
    end if;
  end process;
end rtl;
