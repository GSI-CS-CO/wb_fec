--! @file wb_fec_encoder.vhd
--! @brief  A FEC Encoder
--! @author C.Prados <cprados@mailfence.com>
--!
--! it receives frames eth from the WR fabric and passes it to
--! the Fixed Rate Encoder.The encoder generates up to 4 FEC pkts
--! and this module steers the transmission of the FEC frames over
--! the WR Frabirc.
--!
--! See the file "LICENSE" for the full license governing this code.
--!--------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fec_pkg.all;
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
      stat_enc_o    : out t_enc_err);
end wb_fec_encoder;

architecture rtl of wb_fec_encoder is
  signal src_cyc          : std_logic;
  signal src_stb          : std_logic;
  signal snk_ack          : std_logic;
  signal fec_stb_d        : std_logic;
  signal enc_err          : std_logic;
  signal pkt_err          : std_logic;
  signal pkt_stb          : std_logic;
  signal hdr_ethertype    : t_eth_type;
  signal pkt_len          : integer range 0 to c_eth_pkt;
  signal ctrl_reg         : t_fec_ctrl_reg;
  signal snk_stall        : std_logic;
  signal enc_payload      : t_wrf_bus;
  signal fec_hdr          : t_wrf_bus;
  signal fec_stb          : std_logic;
  signal fec_hdr_stb      : std_logic;
  signal pkt_id           : std_logic_vector(c_fec_cnt_width - 1 downto 0);
  signal OOB_frame_id     : t_wrf_bus;
  signal data_fifo_i      : t_wrf_fifo_out;
  alias  fec_pkt_i        : t_wrf_bus is data_fifo_i(15 downto 0);
  alias  wrf_adr_i        : t_wrf_adr is data_fifo_i(17 downto 16);
  signal data_fifo_o      : t_wrf_fifo_out;
  alias  fec_pkt_o        : t_wrf_bus is data_fifo_o(15 downto 0);
  alias  wrf_adr_o        : t_wrf_adr is data_fifo_o(17 downto 16);
  signal fec_enc_rd       : std_logic;
  signal wr_fifo_o        : std_logic;
  signal rd_fifo_o        : std_logic;
  signal fifo_empty       : std_logic;
  signal fifo_full        : std_logic;
  signal fifo_cnt         : t_wrf_fifo_cnt_width;
  signal fec_block_len    : t_block_len;
  signal hdr_stb          : std_logic;
  type t_enc_refresh is (IDLE, WAIT_TO_APPLY);
  type t_fec_strm is (IDLE, SEND_STATUS, SEND_OOB0, SEND_OOB1, SEND_FEC_HDR, SEND_FEC_PKT, SEND_FEC_PAYLOAD, SEND_FEC_PADDING, IDLE_FEC);
  signal s_enc_refresh    : t_enc_refresh;
  signal s_fec_strm       : t_fec_strm;
  signal eth_cnt          : integer range 0 to c_eth_hdr_len + c_eth_payload + 1;
  signal pad_cnt          : integer range 0 to c_pad_cnt;
  signal fec_pkt_cnt      : integer range 0 to g_num_block;
  signal fec_word_cnt     : integer range 0 to c_fec_hdr_len + c_eth_payload;
  signal pad_word_cnt     : integer range 0 to c_pad_cnt;
  signal fec_bytes        : integer;
  signal start_streaming  : std_logic;
  signal padding          : t_padding;
  signal data_stb         : std_logic;
  signal pad_stb          : std_logic;
  signal padded           : std_logic;
  signal pkt_data         : t_wrf_bus;

  constant c_div_num_block : integer := f_log2_size(g_num_block) + 1; -- in 16bit words
begin

  PKT_ERASURE_ENC : fec_encoder
    generic map(
    g_num_block     => g_num_block)
    port map(
      clk_i         => clk_i,
      rst_n_i       => rst_n_i,
      payload_i     => pkt_data,
      payload_stb_i => data_stb,
      fec_stb_i     => fec_stb,
      fec_enc_rd_i  => fec_enc_rd,
      block_len_i   => fec_block_len,
      streaming_o   => start_streaming,
      enc_err_o     => enc_err,
      enc_payload_o => enc_payload);

  data_stb    <= pkt_stb or pad_stb;

  pkt_data    <= snk_i.dat        when pkt_stb = '1' else
                 (others => '1')  when pad_stb = '1' else
                 (others => '0');

  fec_enc_rd  <=  '1' when s_fec_strm  = SEND_FEC_PAYLOAD else
                  '0';

  FEC_CALC_LEN_PAD : fec_len_tx_pad
    generic map(
      g_num_block     => g_num_block)
    port map(
      clk_i           => clk_i,
      rst_n_i         => rst_n_i,
      pkt_len_i       => hdr_ethertype,
      fec_block_len_o => fec_block_len,
      padding_o       => padding);

  FEC_HDR_PROC : fec_hdr_gen
    generic map(
      g_id_width    => c_id_width,
      g_subid_width => c_subid_width,
      g_fec_type    => "encoder")
    port map(
      clk_i           => clk_i,
      rst_n_i         => rst_n_i,
      hdr_i           => snk_i.dat,
      hdr_stb_i       => hdr_stb,
      pkt_len_i       => hdr_ethertype,
      padding_i       => padding,
      fec_stb_i       => fec_stb,
      fec_hdr_done_o  => open,
      fec_hdr_stall_i => '0',
      fec_hdr_stb_i   => fec_hdr_stb,
      fec_hdr_o       => fec_hdr,
      enc_cnt_o       => pkt_id,
      ctrl_reg_i      => ctrl_reg);

  hdr_stb <= '1' when (snk_i.cyc = '1' and snk_i.stb = '1' and pkt_stb = '0' and
                       snk_stall = '0' and snk_i.adr = c_WRF_DATA) else
             '0';
  fec_hdr_stb <= '1' when s_fec_strm  = SEND_FEC_HDR else
                 '0';

  -- Refresh the ctrl setting after pkt encoded
  ctrl_config_refresh : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
          s_enc_refresh <= IDLE;
          fec_stb_d     <= '0';
      else
        fec_stb_d <= fec_stb;
        case s_enc_refresh is
          when IDLE =>
            if (ctrl_reg_i.fec_ctrl_refresh = '1' and fec_stb = '0') then
              ctrl_reg  <= ctrl_reg_i;
              s_enc_refresh <= IDLE;
            elsif (ctrl_reg_i.fec_ctrl_refresh = '1' and fec_stb = '1') then
              s_enc_refresh <= WAIT_TO_APPLY;
            end if;
          when WAIT_TO_APPLY => -- wait till the last enc pkt has been sent
            if ((fec_stb = '0') and (fec_stb_d = '1')) then
              ctrl_reg  <= ctrl_reg_i;
              s_enc_refresh <= IDLE;
            else
              s_enc_refresh <= WAIT_TO_APPLY;
            end if;
        end case;
      end if;
    end if;
  end process;
  stat_enc_o.fec_enc_err  <= enc_err & pkt_err;
  stat_enc_o.fec_enc_cnt  <= pkt_id;

  -- Ctrl the streaming of FEC pkts
  fec_streaming : process(clk_i) is
    variable fec_hdr_payload_len  : integer range 0 to c_eth_pkt;
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        fec_pkt_cnt     <= 0;
        fec_word_cnt    <= 0;
        fec_hdr_payload_len := 0;
        fec_stb         <= '0';
        s_fec_strm      <= IDLE;
      else
        fec_hdr_payload_len := c_fec_hdr_len + (2 * to_integer(fec_block_len - 1));
        case s_fec_strm is
          when IDLE =>
            if (start_streaming = '1') then
              s_fec_strm  <= SEND_STATUS;
              fec_stb     <= '1';
            else
              s_fec_strm  <= IDLE;
              fec_stb         <= '0';
              fec_word_cnt    <= 0;
              pad_word_cnt    <= 0;
              fec_pkt_cnt     <= 0;
            end if;
          when SEND_STATUS  =>
            s_fec_strm  <= SEND_FEC_HDR;
          when SEND_FEC_HDR =>
            if (fec_word_cnt < c_fec_hdr_len - 1) then
              s_fec_strm  <= SEND_FEC_HDR;
            else
              s_fec_strm  <= SEND_FEC_PAYLOAD;
            end if;
            fec_word_cnt <= fec_word_cnt + 1;
          when SEND_FEC_PAYLOAD =>
            if (fec_word_cnt <= fec_hdr_payload_len) then
              s_fec_strm  <= SEND_FEC_PAYLOAD;
            elsif (fec_word_cnt = fec_hdr_payload_len + 1 and
                  (padding.pad_block /= (padding.pad_block'range => '0'))) then
                s_fec_strm  <= SEND_FEC_PADDING;
            elsif(fec_pkt_cnt <= g_num_block - 1) then
              s_fec_strm      <= IDLE_FEC;
              fec_pkt_cnt <= fec_pkt_cnt + 1;
            else
              fec_stb     <= '0';
              s_fec_strm  <= IDLE_FEC;
            end if;
            fec_word_cnt <= fec_word_cnt + 1;
          when SEND_FEC_PADDING =>
            if (pad_word_cnt < unsigned(padding.pad_block) - 1) then
              s_fec_strm  <= SEND_FEC_PADDING;
            elsif(fec_pkt_cnt <= g_num_block - 1) then
              s_fec_strm  <= IDLE_FEC;
              fec_pkt_cnt <= fec_pkt_cnt + 1;
            else
              fec_stb     <= '0';
              s_fec_strm  <= IDLE_FEC;
            end if;
            pad_word_cnt <= pad_word_cnt + 1;
          when SEND_OOB0 =>
              s_fec_strm  <= SEND_OOB1; -- not used in tx
          when SEND_OOB1=>
              s_fec_strm  <= IDLE_FEC;  -- not used in tx
          when IDLE_FEC =>
            if (fifo_empty = '1') then
              if (fec_pkt_cnt <= g_num_block - 1) then
                s_fec_strm  <= SEND_STATUS;
              else
                fec_stb     <= '0';
                s_fec_strm  <= IDLE;
              end if;
              fec_word_cnt  <= 0;
              pad_word_cnt  <= 0;
            else
              s_fec_strm  <= IDLE_FEC;
            end if;
          when others =>
        end case;
      end if;
    end if;
  end process;

  -- Rx from WR Fabric
  rx_fabric : process(clk_i) is
    variable pad : integer range 0 to c_pad_cnt;
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        hdr_ethertype   <= (others => '0');
        eth_cnt         <= 0;
        pad_cnt         <= 0;
        pkt_len         <= 0;
        pkt_stb         <= '0';
        pad_stb         <= '0';
        pkt_err         <= '0';
        padded          <= '1';
      else
        pad := to_integer(unsigned(padding.pad_pkt));

        if (ctrl_reg_i.fec_enc_en =  c_ENABLE) then
          snk_ack <= snk_i.cyc and snk_i.stb;
          if snk_i.cyc = '1' and snk_i.stb = '1' and snk_stall = '0' then
            if snk_i.adr = c_WRF_DATA then
              -- getting the pkt header
              if (eth_cnt < c_eth_hdr_len - 1) then
                pkt_stb <= '0';
              elsif (eth_cnt = c_eth_hdr_len - 1) then
                hdr_ethertype <= snk_i.dat;
                pkt_len       <= to_integer(unsigned(snk_i.dat) srl 1);
                pkt_stb   <= '1';
              elsif (eth_cnt = c_eth_hdr_len + pkt_len - 1) then
              -- getting the payload
                pkt_stb   <= '0';
                if (pad_cnt < pad and padded = '0') then
                  pad_stb <= '1';
                  pad_cnt <= pad_cnt + 1;
                end if;
              elsif (eth_cnt >= c_eth_pkt - 1) then
                -- jumbo pkt error
                pkt_stb   <= '0';
                pkt_err   <= '1';
              end if;
            eth_cnt <= eth_cnt + 1;
            end if;
            padded  <= '0';
          elsif (pad_cnt < pad and padded = '0') then
            pad_stb <= '1';
            pkt_stb <= '0';
            pad_cnt <= pad_cnt + 1;
          else
            padded        <= '1';
            pad_cnt       <= 0;
            eth_cnt       <= 0;
            pad_stb       <= '0';
            pkt_stb       <= '0';
            pkt_err       <= '0';
          end if;
        else -- c_DISABLE
          padded        <= '0';
          pad_cnt       <= 0;
          eth_cnt       <= 0;
          pad_stb       <= '0';
          pkt_stb       <= '0';
          pkt_err       <= '0';
        end if;
      end if;
    end if;
  end process;

  snk_stall   <=  src_i.stall when ctrl_reg_i.fec_enc_en = c_DISABLE else
                  '1'         when snk_i.cyc = '0' and fec_stb = '1'  else

                  '0';
  snk_o.stall <= snk_stall;

  snk_o.ack    <=  src_i.ack   when ctrl_reg_i.fec_enc_en = c_DISABLE else
                   snk_ack     when ctrl_reg_i.fec_enc_en = c_ENABLE  else
                  '0';

  snk_o.err    <=  src_i.err   when ctrl_reg_i.fec_enc_en = c_DISABLE else
                   '0'         when ctrl_reg_i.fec_enc_en = c_ENABLE; --FIXME Error Handling

  snk_o.rty    <=  src_i.rty   when ctrl_reg_i.fec_enc_en = c_DISABLE else
                   '0'         when ctrl_reg_i.fec_enc_en = c_ENABLE;

  -- Tx to WR Farbric
  src_stb <=  '1'  when (s_fec_strm = SEND_FEC_HDR or
                        s_fec_strm = SEND_FEC_PAYLOAD or
                        s_fec_strm = SEND_FEC_PADDING or
                        s_fec_strm = SEND_STATUS or
                        (fifo_empty = '0' and  s_fec_strm = IDLE_FEC)) and
                        fifo_empty = '0' else
              '0';

  src_o.stb <=  snk_i.stb when ctrl_reg_i.fec_enc_en = c_DISABLE else
                src_stb   when ctrl_reg_i.fec_enc_en = c_ENABLE else
                '0';

  --src_cyc   <=  src_stb or src_i.ack;
  src_cyc   <=  src_stb;

  src_o.cyc <=  snk_i.cyc when ctrl_reg_i.fec_enc_en = c_DISABLE  else
                src_cyc   when ctrl_reg_i.fec_enc_en = c_ENABLE   else
                '0';

  src_o.sel <=  snk_i.sel when  ctrl_reg_i.fec_enc_en = c_DISABLE else
                "11";

  src_o.we  <=  snk_i.we when  ctrl_reg_i.fec_enc_en = c_DISABLE else
                '1';

  wrf_adr_i <= c_WRF_STATUS     when s_fec_strm = SEND_STATUS       else
               c_WRF_DATA       when s_fec_strm = SEND_FEC_HDR      or
                                     s_fec_strm = SEND_FEC_PAYLOAD  or
                                     s_fec_strm = SEND_FEC_PADDING  else
               c_WRF_OOB        when s_fec_strm = SEND_OOB0         or
                                     s_fec_strm = SEND_OOB1         else
               (others => '0');

  src_o.adr <=  snk_i.adr   when ctrl_reg_i.fec_enc_en = c_DISABLE else
                wrf_adr_o   when ctrl_reg_i.fec_enc_en = c_ENABLE;

  fec_pkt_i <= c_WRF_STATUS_FEC when s_fec_strm = SEND_STATUS       else
               fec_hdr          when s_fec_strm = SEND_FEC_HDR      else
               enc_payload      when s_fec_strm = SEND_FEC_PAYLOAD  else
               (others => '1')  when s_fec_strm = SEND_FEC_PADDING  else
               c_WRF_OOB_FEC    when s_fec_strm = SEND_OOB0         else
               OOB_frame_id     when s_fec_strm = SEND_OOB1         else
               (others => '0');

  src_o.dat <= snk_i.dat        when ctrl_reg_i.fec_enc_en = c_DISABLE  else
               fec_pkt_o        when ctrl_reg_i.fec_enc_en = c_ENABLE   else
               (others => '0');

  wr_fifo_o <=  '1'  when s_fec_strm = SEND_STATUS      or
                          s_fec_strm = SEND_FEC_HDR     or
                          s_fec_strm = SEND_FEC_PAYLOAD or
                          s_fec_strm = SEND_FEC_PADDING or
                          s_fec_strm = SEND_OOB0        or
                          s_fec_strm = SEND_OOB1   else
                '0';

  rd_fifo_o <=  '1'  when  (s_fec_strm = SEND_STATUS or
                            s_fec_strm = SEND_FEC_PAYLOAD  or
                            s_fec_strm = SEND_FEC_PADDING  or
                            s_fec_strm = SEND_FEC_HDR or
                            s_fec_strm = IDLE_FEC or
                            s_fec_strm = SEND_OOB0 or
                            s_fec_strm = SEND_OOB1) and
                            src_i.stall = '0' and
                            fifo_empty = '0'else
                '0';


  ENC_HDR_PKT_FIFO : generic_sync_fifo
    generic map (
      g_data_width  => c_wrf_fifo_width,
      g_size        => c_wrf_fifo_size,
      g_with_full   => true,
      g_with_empty  => true,
      g_with_count  => true,
      g_show_ahead  => true)
    port  map (
      clk_i   => clk_i,
      rst_n_i => rst_n_i,
      d_i     => data_fifo_i,
      we_i    => wr_fifo_o,
      empty_o => fifo_empty,
      full_o  => fifo_full,
      count_o => fifo_cnt,
      q_o     => data_fifo_o,
      rd_i    => rd_fifo_o);

    cnt_fec_pkt_bytes : process(clk_i) is
    begin
      if rising_edge(clk_i) then
        if (rst_n_i = '0') then
          fec_bytes <= 0;
        else
          if (src_stb = '1' and src_i.stall = '0') then
            fec_bytes <= fec_bytes + 1;
          elsif (src_stb = '1' and src_i.stall = '1') then
            fec_bytes <= fec_bytes;
          elsif (src_stb = '0') then
            fec_bytes <= 0;
          end if;
        end if;
      end if;
    end process;
end rtl;
