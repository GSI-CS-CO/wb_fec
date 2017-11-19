--! @file fec_encoder.vhd
--! @brief  A FEC Encoder
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
  signal halt_cnt     : std_logic;
  signal fifo_empty   : std_logic;
  signal fifo_full    : std_logic;
  signal fifo_cnt     : t_out_fifo_cnt_width;
  signal code_src_sel : std_logic;
  signal read_block   : std_logic_vector (g_num_block - 1 downto 0);
  signal block_cnt    : unsigned (c_eth_pl_width - 1 downto 0);
  signal payload_cnt  : unsigned (c_eth_pl_width - 1 downto 0);
  signal enc_cnt      : integer range 0 to 10000;
  signal fec_enc_stb  : std_logic;
  signal fec_pl_len   : integer;
  signal we_src_sel   : unsigned (g_num_block - 1 downto 0);
  signal we_mask      : unsigned (g_num_block - 1 downto 0);
  signal we_loop_back : std_logic_vector (g_num_block - 1 downto 0);
  type t_dec is (IDLE, ENC_PKT_0, ENC_PKT_1, ENC_PKT_2, ENC_PKT_3);
  signal s_ENC        : t_dec;
  signal s_next_ENC   : t_dec;
  type t_dec_cnt is (IDLE, ENCODING);
  signal S_ENC_CNT    : t_dec_cnt;
  signal enc_payload  : t_wrf_bus;
  signal cnt          : t_fifo_cnt_array (0 to g_num_block - 1);
  constant c_div_num_block : integer := f_log2_size(g_num_block) + 1; -- 16 bit word

begin
  -- FEC payload length 
  fec_pl_len  <= to_integer(2 * block_len_i);
  
  enc_payload   <= payload_i  when  code_src_sel = c_FROM_STR else
                   xor_code   when  code_src_sel = c_FROM_XOR;

  coding_streaming_fsm : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        s_enc         <= IDLE;
        enc_cnt       <= 0;
        xor_code      <= (others => '0');
        read_block    <= (others => '0');
        code_src_sel  <= c_FROM_XOR;
        fifo_wr       <= '0';
        halt_cnt      <= '0';
      else
        -- FSM counter for the encoder
        case s_ENC_CNT is
          when IDLE =>
            -- the first block[0] received, we can start encoding
            if (payload_stb_i = '1' and block_cnt > block_len_i - 3) then
              s_ENC_CNT <= ENCODING;
              s_ENC     <= s_next_ENC;
            else
             s_ENC     <= IDLE;
              s_ENC_CNT <= IDLE;
            end if;
          when ENCODING =>
            if (fec_stb_i = '1') then
              if (enc_cnt < fec_pl_len - 1 and halt_cnt = '0')  then
                enc_cnt <= enc_cnt + 1;
              elsif (halt_cnt = '1') then
                enc_cnt <= enc_cnt;
              else
                s_ENC <= s_next_ENC;
                enc_cnt <= 0;
              end if;
            else
             s_ENC_CNT <= IDLE;
            end if;
          when others =>
        end case;
 
        case s_ENC  is
          when IDLE =>
            s_next_ENC  <= ENC_PKT_0;
            read_block  <= (others => '0');
            xor_code    <= (others => '0');
            code_src_sel<= c_FROM_XOR;
            enc_cnt     <= 0;
            fifo_wr     <= '0';
          when ENC_PKT_0 =>        
            if (enc_cnt =  1) then
              fifo_wr     <= '1';
            end if;
            if (enc_cnt <= block_len_i - 1) then
            -- block(0)[fifo] xor block(1)[payload]            
              read_block(0) <= c_FIFO_ON; --[0]
              code_src_sel  <= c_FROM_XOR;
              xor_code      <= block2enc(0) xor payload_i;            
            else
            -- block(2)[payload]
              read_block(0) <= c_FIFO_OFF; --[0]
              code_src_sel  <= c_FROM_STR; --[2]
              xor_code      <= (others => '0');
            end if;
            s_next_ENC  <= ENC_PKT_1;
          when ENC_PKT_1 =>
            if (enc_cnt <= block_len_i - 1) then
            -- block(1)[fifo] xor block(2)[fifo]
              read_block(1) <= c_FIFO_ON; --[1]
              read_block(2) <= c_FIFO_ON; --[2]
              code_src_sel  <= c_FROM_XOR;
              xor_code      <= block2enc(1) xor block2enc(2);
            else
            -- block(3)[payload]
              fifo_wr       <= '1';
              halt_cnt      <= '0';
              xor_code      <= block2enc(3);
            end if;

            -- resynchronize all the streams halting 1 clock the cnt
            -- and enabling all the fifos to stream a waterfall
            if (enc_cnt = block_len_i) then
              fifo_wr       <= '0';
              halt_cnt      <= '1';
              read_block(0) <= c_FIFO_ON; --[0]
              read_block(3) <= c_FIFO_ON; --[3]
            end if;

            s_next_ENC <= ENC_PKT_2;
          when ENC_PKT_2 =>
            if (enc_cnt <= block_len_i - 1) then
            -- block(2)[fifo] xor block(3)[fifo]
              xor_code <= block2enc(2) xor block2enc(3);
            else
            -- block(0)[fifo]
              xor_code <= block2enc(0);
            end if;
            s_next_ENC <= ENC_PKT_3;
          when ENC_PKT_3 =>        
            if (enc_cnt <= block_len_i - 1) then          
            -- block(3)[fifo] xor block(0)[fifo]
              xor_code  <= block2enc(3) xor block2enc(0);
            else
            -- block(1)[fifo]
              xor_code  <= block2enc(1);
            end if;
            s_next_ENC <= IDLE;
          when others =>
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
  
  -- steers to the block FIFO the incoming payload data
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
            --error frame bigger than provide
            --enc_err_o <= '1';
        end if;
      end if;
    end if;
  end process;
end rtl;
