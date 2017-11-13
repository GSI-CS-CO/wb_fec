--! @file wb_fec_encoder.vhd
--! @brief  A FEC Encoder
--! @author C.Prados <cprados@mailfence.com>
--!
--! See the file "LICENSE" for the full license governing this code.
--! TODO bypass if the encoder is not enable
--!-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fec_pkg.all;
--use work.golay_pk.all;
use work.wishbone_pkg.all;
use work.genram_pkg.all;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;

entity wb_fec_encoder is
  generic ( 
    g_num_block   : integer := 4;
    g_en_golay    : boolean := FALSE);
    port (
      clk_i         : in  std_logic;
      rst_n_i       : in  std_logic;     
      snk_i         : in  t_wrf_sink_in;
      snk_o         : out t_wrf_sink_out;
      src_i         : in  t_wrf_source_in;
      src_o         : out t_wrf_source_out;
      ctrl_reg_i    : in  t_fec_ctrl_reg;
      stat_reg_o    : out t_fec_stat_reg);
end wb_fec_encoder;

architecture rtl of wb_fec_encoder is
  signal src_cyc          : std_logic;
  signal fec_stb_d        : std_logic;
  signal enc_err          : std_logic;
  signal pkt_err          : std_logic;
  signal pkt_stb          : std_logic;
  signal pkt_enc_stb      : std_logic;
  signal hdr_etherType    : t_eth_type;
  signal ctrl_reg         : t_fec_ctrl_reg;
  signal snk_stall        : std_logic;
  signal enc_payload      : t_wrf_bus;
  signal fec_hdr          : t_wrf_bus;
  signal fec_pkt          : t_wrf_bus;
  signal fec_stb          : std_logic;
  signal fec_hdr_stb      : std_logic;
  signal fec_payload_stb  : std_logic;
  signal fec_oob_stb      : std_logic;
  signal dat_fifo_out     : t_wrf_bus;
  signal wr_fifo_out      : std_logic;
  signal rd_fifo_out      : std_logic;
  signal code_empty       : std_logic;
  signal code_full        : std_logic;
  signal fec_block_len    : t_block_len;
  signal hdr_stb          : std_logic;
  type t_enc_refresh is (REFRESH, WAIT_REFRESH);
  type t_fec_strm is (IDLE, SEND_OOB, SEND_FEC_HDR, SEND_FEC_PAYLOAD, IDLE_FEC);
  signal s_enc_refresh    : t_enc_refresh;
  signal s_fec_strm       : t_fec_strm;
  signal eth_cnt          : integer range 0 to c_eth_hdr_len + c_eth_payload;
  signal fec_pkt_cnt      : integer range 0 to g_num_block;
  signal fec_word_cnt     : integer range 0 to c_fec_hdr_len + c_eth_payload;

  constant c_div_num_block : integer := f_log2_size(g_num_block) + 1; -- 16 bit word
begin 

  PKT_ERASURE_ENC : fec_encoder
    port  map(
      clk_i         => clk_i,
      rst_n_i       => rst_n_i,
      payload_i     => snk_i.dat,
      block_len_i   => fec_block_len, -- payload in 16 bit words
      stb_i         => pkt_stb,
      enc_err_o     => enc_err,
      stb_o         => pkt_enc_stb,
      --enc_payload_o => enc_payload);
      enc_payload_o => open);

  stat_reg_o.fec_enc_err  <= enc_err & pkt_err;
 
  --g_GOLAY_ENC : if g_en_golay generate
  --  GOLAY_ENC : golay_encoder
  --    port map (
  --      clk_i       => clk_i,
  --      rst_n_i     => rst_n_i,
  --      stb_i       => 
  --      payload_i   =>
  --      code_word_o => );
  --end generate;

  FEC_HDR_PROC : fec_hdr_gen
    generic map(
      g_id_width    => c_id_width,
      g_subid_width => c_subid_width)
    port map(
      clk_i         => clk_i,
      rst_n_i       => rst_n_i,
      hdr_i         => snk_i.dat,
      hdr_stb_i     => hdr_stb,
      block_len_i   => fec_block_len,
      fec_stb_i     => fec_stb,
      fec_hdr_stb_i => fec_hdr_stb,
      fec_hdr_o     => fec_hdr,
      enc_cnt_o     => stat_reg_o.fec_enc_cnt,
      ctrl_reg_i    => ctrl_reg);
  
  hdr_stb <= '1' when (snk_i.cyc = '1' and snk_i.stb = '1' and pkt_stb = '0' and
                       snk_stall = '0' and snk_i.adr = c_WRF_DATA) else 
             '0';

  -- Encoded pkt payload length
  fec_block_len <= f_calc_len_block(hdr_etherType, c_div_num_block, g_num_block);

  -- Refresh the ctrl setting after pkt encoded
  ctrl_config_refresh : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
          s_enc_refresh <= REFRESH;
          fec_stb_d     <= '0';
      else
        fec_stb_d <= fec_stb;
        case s_enc_refresh is
          when REFRESH =>
            if (ctrl_reg_i.fec_ctrl_refresh = '1' and fec_stb = '0') then
              ctrl_reg  <= ctrl_reg_i;
              s_enc_refresh <= REFRESH;
            elsif (ctrl_reg_i.fec_ctrl_refresh = '1' and fec_stb = '1') then
              s_enc_refresh <= WAIT_REFRESH;
            end if;
          when WAIT_REFRESH => -- wait till the last enc pkt has been sent
            if ((fec_stb = '0') and (fec_stb_d = '1')) then
              ctrl_reg  <= ctrl_reg_i;
            end if;
            s_enc_refresh <= REFRESH;
        end case;
      end if;
    end if;
  end process;
  
  -- Ctrl the streaming of FEC pkts
  fec_streaming : process(clk_i) is
    variable fec_hdr_payload_len  : integer range 0 to c_eth_payload;
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        fec_pkt_cnt     <= 0;
        fec_word_cnt    <= 0;
        fec_hdr_payload_len := 0;
        fec_stb         <= '0';
        fec_oob_stb     <= '0';
        fec_hdr_stb     <= '0';
        fec_payload_stb <= '0';
        s_fec_strm      <= IDLE;
      else
        fec_hdr_payload_len := c_fec_hdr_len + (2 * to_integer(fec_block_len));
        case s_fec_strm is
          when IDLE =>
            if (eth_cnt >= fec_block_len - 2) then
              s_fec_strm  <= SEND_OOB;
              fec_oob_stb <= '1'; 
              fec_stb     <= '1';
            else
              s_fec_strm  <= IDLE;            
              fec_stb         <= '0';
              fec_oob_stb     <= '0';
              fec_hdr_stb     <= '0';
              fec_payload_stb <= '0';
              fec_word_cnt    <= 0;
              fec_pkt_cnt     <= 0;
            end if;
          when SEND_OOB => 
              fec_hdr_stb <= '1'; 
              fec_oob_stb <= '0'; 
              s_fec_strm  <= SEND_FEC_HDR;
          when SEND_FEC_HDR =>
            if (fec_word_cnt <= fec_block_len - 1) then
              s_fec_strm  <= SEND_FEC_HDR;
            else
              fec_hdr_stb     <= '0';
              fec_payload_stb <= '1';
              s_fec_strm  <= SEND_FEC_PAYLOAD;
            end if;
            fec_word_cnt <= fec_word_cnt + 1;          
          when SEND_FEC_PAYLOAD =>
            if (fec_word_cnt <= fec_hdr_payload_len - 1) then
              s_fec_strm      <= SEND_FEC_PAYLOAD;
            elsif(fec_pkt_cnt < g_num_block - 1) then
              fec_payload_stb <= '0';
              s_fec_strm      <= IDLE_FEC;
              fec_pkt_cnt <= fec_pkt_cnt + 1;
            else
              fec_stb         <= '0';
              s_fec_strm      <= IDLE;
            end if;
            fec_word_cnt <= fec_word_cnt + 1;

          when IDLE_FEC =>
            s_fec_strm  <= SEND_OOB;
            fec_oob_stb   <= '1'; 
            fec_word_cnt  <= 0;
        end case;
      end if;
    end if;
  end process;

  -- Rx from WR Fabric
  rx_fabric : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        hdr_etherType   <= (others => '0');
        eth_cnt         <= 0;
        pkt_stb         <= '0';
        pkt_err         <= '0';
      else
        if (ctrl_reg_i.fec_enc_en =  c_ENABLE) then
          snk_o.ack   <= snk_i.cyc and snk_i.stb;
          --if snk_i.cyc = '1' and snk_i.stb = '1' and snk_stall = '0' then
          if snk_i.cyc = '1' and snk_i.stb = '1' then
            if snk_i.adr = c_WRF_DATA then
              -- getting the pkt header
              if (eth_cnt < c_eth_hdr_len - 1) then
                pkt_stb   <= '0';
                eth_cnt   <= eth_cnt + 1;
              elsif (eth_cnt <= c_eth_hdr_len - 1) then
              -- getting the payload
                hdr_etherType <= snk_i.dat;
                pkt_stb   <= '1';
                eth_cnt   <= eth_cnt + 1;
              elsif (eth_cnt < c_eth_payload - 1) then
                pkt_stb   <= '1';
                eth_cnt   <= eth_cnt + 1;
              elsif (eth_cnt >= c_eth_payload - 1) then
                -- jumbo pkt error
                pkt_stb   <= '0';
                pkt_err   <= '1';
              end if;          
            end if;          
          else
            eth_cnt       <= 0;
            pkt_stb       <= '0';
            pkt_err       <= '0';
          end if;
        else -- c_DISABLE            
          eth_cnt       <= 0;
          pkt_stb       <= '0';
          pkt_err       <= '0';
          --src_o         <= snk_i;
          snk_o         <= src_i;
        end if;
      end if;
    end if;
  end process;

  snk_stall   <=  '1' when snk_i.cyc = '0' and fec_stb = '1' else
                  '0';
  snk_o.stall <= snk_stall;

  --Tx to WR Fabric
  src_o.sel <= "11";
  src_o.we  <= '1';
  
  src_cyc   <=  snk_i.cyc when ctrl_reg_i.fec_enc_en = c_DISABLE            else
                '1'       when fec_stb = '1' and (fec_hdr_stb = '1' or
                               FEC_PAYLoad_stb = '1' or fec_oob_stb = '1')  else
                '0';

  src_o.cyc <= src_cyc;

  src_o.stb <= snk_i.stb  when ctrl_reg_i.fec_enc_en = c_DISABLE            else
               '1'        when fec_stb = '1' and (fec_hdr_stb = '1' or
                               FEC_PAYLoad_stb = '1' or fec_oob_stb = '1')  else
               '0';

  enc_payload <= (others => '1');

  fec_pkt   <= c_WRF_OOB_TYPE_TX & x"aaa" when s_fec_strm = SEND_OOB else
               fec_hdr                    when s_fec_strm = SEND_FEC_HDR      else
               enc_payload                when s_fec_strm = SEND_FEC_PAYLOAD  else
               (others => '0');

  src_o.dat <= snk_i.dat        when ctrl_reg_i.fec_enc_en = c_DISABLE  else
               dat_fifo_out     when ctrl_reg_i.fec_enc_en = c_ENABLE   else
               (others => '0');
               
  src_o.adr <= snk_i.adr        when ctrl_reg_i.fec_enc_en = c_DISABLE  else
               c_WRF_OOB        when s_fec_strm = SEND_OOB              else
               c_WRF_DATA       when s_fec_strm = SEND_FEC_HDR or s_fec_strm = SEND_FEC_PAYLOAD else
               (others => '0');

  wr_fifo_out <= fec_hdr_stb or fec_payload_stb; 
  rd_fifo_out <= (not src_i.stall) and src_cyc;

  ENC_HDR_PKT_FIFO : generic_sync_fifo
    generic map (
      g_data_width => c_wrf_width,
      g_size       => c_block_max_len,
      g_show_ahead => true)
    port  map (
      clk_i   => clk_i,
      rst_n_i => rst_n_i,
      d_i     => fec_pkt,
      we_i    => wr_fifo_out,
      empty_o => code_empty,
      full_o  => code_full,
      q_o     => dat_fifo_out,
      --q_o     => open,
      rd_i    => rd_fifo_out);

    -- IF HALT TOO LONG AND FIFO FULL, ERROR and RESET EVERYTHING

end rtl;
