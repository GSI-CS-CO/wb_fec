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
    stb_i         : in  std_logic;
    block_len_i   : in  t_block_len;
    enc_err_o     : out std_logic;
    stb_o         : out std_logic;
    enc_payload_o : out t_wrf_bus);
end fec_encoder;

architecture rtl of fec_encoder is
  signal rst_n        : std_logic;
  signal empty        : std_logic_vector (g_num_block - 1 downto 0);
  signal blocl_full   : std_logic_vector (g_num_block - 1 downto 0);
  signal full         : std_logic_vector (g_num_block - 1 downto 0);
  signal code_empty   : std_logic;
  signal code_full    : std_logic;
  signal code_src_sel : std_logic;
  signal we_code      : std_logic;
  signal code         : t_wrf_bus;
  signal xor_code     : t_wrf_bus;
  signal block2enc    : t_wrf_bus_array (0 to g_num_block - 1);
  signal pl_block     : t_wrf_bus_array (0 to g_num_block - 1);
  signal read_block   : std_logic_vector (g_num_block - 1 downto 0);
  signal block_cnt    : unsigned (c_eth_pl_width - 1 downto 0);
  signal enc_cnt      : unsigned (c_eth_pl_width - 1 downto 0);
  signal we_src_sel   : unsigned (g_num_block - 1 downto 0);
  signal we_mask      : unsigned (g_num_block - 1 downto 0);
  signal we_loop_back : unsigned (g_num_block - 1 downto 0);
  signal fec_block_len_i: unsigned (c_eth_pl_width - 1 downto 0);
  type t_dec is (IDLE, STEP_0, STEP_1, STEP_2, STEP_3, STEP_4);
  signal s_dec        : t_dec;
  signal fifo_cnt     : t_fifo_cnt_array (0 to g_num_block - 1);
  constant c_div_num_block : integer := f_log2_size(g_num_block) + 1; -- 16 bit word
begin 
 
  coding_fsm : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        s_dec         <= IDLE;
        enc_cnt       <= (others => '0');
        xor_code      <= (others => '0');
        we_code       <= c_FIFO_OFF;
        code_src_sel  <= c_FROM_FIFO;
      else
        -- counter of enc blocks
        if ((enc_cnt <= block_len_i - 1) and s_dec /= IDLE) then
          enc_cnt <= enc_cnt + 1;
        else
          enc_cnt <= (others => '0');
        end if;

        case s_dec is
          when IDLE =>
            -- First block of packet received, start encoding
            if ((block_cnt = block_len_i  - 1) and we_src_sel(0) = '1') then
              s_dec         <= STEP_0;
            else
              we_code       <= c_FIFO_OFF;
              code_src_sel  <= c_FROM_FIFO;
              s_dec         <= IDLE;
            end if;
          when STEP_0 => 
            if (enc_cnt = block_len_i - 1) then
              s_dec <= STEP_1;
            end if;
            -- block(0)[fifo] xor block(1)[payload] => stream
            read_block(0) <= c_FROM_FIFO;
            xor_code      <= block2enc(0) xor payload_i;
            we_code       <= c_FIFO_ON;
            code_src_sel  <= c_FROM_FIFO;
          when STEP_1 =>
            --block(2)[payload] => stream
            -- block(1)[fifo] xor block(2)[payload] => store
            read_block(1) <= c_FROM_FIFO;
            xor_code      <= block2enc(1) xor payload_i;
            we_code       <= c_FIFO_ON;
            -- block(2) => stream
            code_src_sel  <= c_FROM_PKT;
          when STEP_2 =>            
            if (enc_cnt = block_len_i - 1) then
              s_dec <= STEP_3;
            end if;
            -- block(1)[fifo] xor block(2)[payload] => store
            read_block(1) <= c_FROM_FIFO;
            xor_code      <= block2enc(1) xor payload_i;
            we_code       <= c_FIFO_ON;
            -- block(3) => stream
            code_src_sel  <= c_FROM_PKT;
          when STEP_3 =>
          when STEP_4 =>
          when others => 
            we_code       <= c_FIFO_ON; -- test
        end case;
      end if;
    end if;
  end process;
  
  ENC_PKT_FIFO : generic_sync_fifo
    generic map (
      g_data_width => c_wrf_width,
      g_size       => c_block_max_len,
      g_show_ahead => true)
    port  map (
      clk_i   => clk_i,
      rst_n_i => rst_n,
      d_i     => xor_code,
      --we_i    => we_code,
      we_i    => '0',
      empty_o => code_empty,
      full_o  => code_full,
      q_o     => code,
      rd_i    => code_src_sel);

  enc_payload_o <= payload_i  when  code_src_sel = c_FROM_PKT else
                   code       when  code_src_sel = c_FROM_FIFO;

  -- Block Fifos
  g_PKT_BLOCK_FIFO : for i in 0 to g_num_block - 1 generate
    PKT_BLOCK_FIFO : generic_sync_fifo
      generic map (
        g_data_width => c_wrf_width,
        g_size       => c_block_max_len,
        g_with_count => true,
        g_show_ahead => true)
      port  map (
        clk_i   => clk_i,
        rst_n_i => rst_n,
        d_i     => pl_block(i),
        --we_i    => we_mask(i),
        we_i    => '0',
        empty_o => empty(i),
        full_o  => full(i),
        q_o     => block2enc(i),
        rd_i    => read_block(i),
        count_o => fifo_cnt(i));

      we_mask(i) <= (stb_i and we_src_sel(i)) or we_loop_back(i);
      
      -- the fifo gets the data from the pkt or fifo lopping back the output
      pl_block(i) <=  payload_i    when we_src_sel(i) = '1' else
                      block2enc(i) when we_src_sel(i) = '0';
  end generate g_PKT_BLOCK_FIFO; 
  
  we_loop_back  <= (others => '0');

  --rst_n <= end_packet or rst_n_i;
  rst_n <= rst_n_i; -- or end_packet

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
        if (stb_i = '0') then
          block_cnt     <= (others => '0');
          we_src_sel    <= (others => '0');
          we_src_sel(0) <= '1';
        elsif (stb_i = '1') then
          if (block_cnt < block_len_i - 1) then
            block_cnt <= block_cnt + 1;
          elsif ((block_cnt = block_len_i  - 1) and (we_src_sel /= (we_src_sel'range => '0'))) then
            block_cnt   <= (others => '0');
            we_src_sel  <= we_src_sel sll 1;
          elsif (block_cnt > block_len_i - 1) then
            --error frame bigger than provide
            enc_err_o <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;
end rtl;
