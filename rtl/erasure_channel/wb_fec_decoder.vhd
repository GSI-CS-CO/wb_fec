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
use work.wishbone_pkg.all;
use work.genram_pkg.all;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;

entity wb_fec_decoder is
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
end wb_fec_decoder;

architecture rtl of wb_fec_decoder is
  signal oob_info         : t_wrf_oob;
  signal oob_toggle       : std_logic;
  signal fec_skip_pkt     : std_logic;
  signal eth_cnt          : unsigned (c_eth_pkt_width - 1 downto 0);
  signal wrf_oob_cnt      : unsigned (1 downto 0);
  signal pkt_stb          : std_logic;
  signal jumbo_frame      : std_logic;
  signal hdr_stb          : std_logic;
  signal hdr_stall        : std_logic;
  signal fec_stb          : std_logic;
  signal fec_stb_d        : std_logic;
  signal eth_payload_stb  : std_logic;
  signal fec_pad_stb      : std_logic;
  signal src_halt         : std_logic;
  signal dec_err          : t_dec_err;
  signal eth_payload      : t_wrf_bus;
  signal eth_hdr          : t_wrf_bus;
  signal eth_hdr_stb      : std_logic;
  signal start_stream     : std_logic;
  signal ctrl_reg         : t_fec_ctrl_reg;
  signal snk_stall        : std_logic;
  type t_enc_refresh is (IDLE, WAIT_TO_APPLY);
  signal s_enc_refresh    : t_enc_refresh;
  type t_eth_strm  is (IDLE, SEND_STATUS, SEND_HDR, SEND_PAYLOAD);
  signal s_eth_strm       : t_eth_strm;
  signal src_stb          : std_logic;
  signal src_cyc          : std_logic;
  signal wrf_adr          : t_wrf_adr;
  signal wrf_dat          : t_wrf_bus;
  signal stream_dat       : std_logic;
  signal eth_hdr_done     : std_logic;
  signal fec_dec_cnt      : unsigned (c_fec_cnt_width - 1 downto 0);

  constant c_div_num_block : integer := f_log2_size(g_num_block) + 1; -- in 16bit words
begin

  PKT_ERASURE_DEC: fec_decoder
  generic map (
    g_num_block => g_num_block)
  port map (
    clk_i             => clk_i,
    rst_n_i           => rst_n_i,
    fec_payload_i     => snk_i.dat,
    fec_payload_stb_i => pkt_stb,
    fec_pad_stb_i     => fec_pad_stb,
    fec_stb_o         => fec_stb,
    pkt_payload_o     => eth_payload,
    pkt_payload_stb_o => eth_payload_stb,
    eth_stream_o      => start_stream,
    dat_stream_i      => stream_dat,
    halt_streaming_i  => src_halt,
    pkt_dec_err_o     => dec_err);

  FEC_HDR_PROC : fec_hdr_gen
    generic map(
      g_id_width    => c_id_width,
      g_subid_width => c_subid_width,
      g_fec_type    => "decoder")
    port map(
      clk_i           => clk_i,
      rst_n_i         => rst_n_i,
      hdr_i           => snk_i.dat,
      hdr_stb_i       => hdr_stb,
      fec_hdr_stall_i => hdr_stall,
      fec_hdr_done_o  => eth_hdr_done,
      pkt_len_i       => (others => '0'),
      padding_i       => c_padding,
      fec_stb_i       => fec_stb,
      fec_hdr_stb_i   => eth_hdr_stb,
      fec_hdr_o       => eth_hdr,
      enc_cnt_o       => open,
      ctrl_reg_i      => ctrl_reg);

  hdr_stb <= '1' when (snk_i.cyc = '1' and snk_i.stb = '1' and pkt_stb = '0' and
                       snk_stall = '0' and snk_i.adr = c_WRF_DATA) else
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
  stat_reg_o.fec_dec_err  <= dec_err;
  dec_err.jumbo_frame     <= jumbo_frame;
  stat_reg_o.fec_dec_cnt  <= std_logic_vector(fec_dec_cnt);

  -- Tx from decoder
  tx_fabric : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        s_eth_strm    <= IDLE;
        eth_hdr_stb   <= '0';
        --stream_dat    <= '0';
      else
        case s_eth_strm is
          when IDLE =>
            if (start_stream = '1') then
              s_eth_strm <= SEND_STATUS;
            end if;
            eth_hdr_stb <= '0';
            --stream_dat  <= '0';
          when SEND_STATUS =>
              if (src_halt = '0') then
                s_eth_strm  <= SEND_HDR;
              end if;
          when SEND_HDR =>
            if (eth_hdr_done = '1' and hdr_stall = '0') then
              s_eth_strm  <= SEND_PAYLOAD;
              eth_hdr_stb <= '0';
            end if;

            if (eth_hdr_done = '0' and hdr_stall = '0') then
              eth_hdr_stb <= '1';
            end if;
          when SEND_PAYLOAD =>
            if (eth_payload_stb = '0') then
              s_eth_strm <= IDLE;
              fec_dec_cnt <= fec_dec_cnt + 1;
            else
            end if;
        end case;
      end if;
    end if;
  end process;

  stream_dat  <= eth_hdr_done and (not src_i.stall);
  src_halt    <= src_i.stall;
  hdr_stall   <= src_i.stall;

  src_stb <= '1' when (s_eth_strm = SEND_HDR      or
                       eth_payload_stb = '1'      or -- SEND_PAYLOAD
                       s_eth_strm = SEND_STATUS) else
             '0';

  src_o.stb <= snk_i.stb when ctrl_reg_i.fec_dec_en = c_DISABLE else
               src_stb   when ctrl_reg_i.fec_dec_en = c_ENABLE  else
               '0';

  src_cyc   <= src_stb or src_i.ack;

  src_o.cyc <= snk_i.cyc when ctrl_reg_i.fec_dec_en = c_DISABLE else
               src_cyc   when ctrl_reg_i.fec_dec_en = c_ENABLE  else
               '0';

  src_o.sel <= snk_i.sel when ctrl_reg_i.fec_dec_en = c_DISABLE else
               "11";

  src_o.we  <= snk_i.we when ctrl_reg_i.fec_dec_en = c_DISABLE else
               '1';

  wrf_adr   <=  c_WRF_STATUS  when s_eth_strm = SEND_STATUS   else
                c_WRF_DATA    when (s_eth_strm = SEND_HDR      or
                                    eth_payload_stb = '1')    else -- SEND_PAYLOAD
                (others => '0');

  src_o.adr <=  snk_i.adr when ctrl_reg_i.fec_dec_en = c_DISABLE else
                wrf_adr   when ctrl_reg_i.fec_dec_en = c_ENABLE  else
                (others => '0');

  wrf_dat   <=  c_WRF_STATUS_FEC  when s_eth_strm = SEND_STATUS  else
                eth_hdr           when s_eth_strm = SEND_HDR     else
                eth_payload       when eth_payload_stb = '1'     else -- SEND_PAYLOAD
                (others => '0');

  src_o.dat <= snk_i.dat  when ctrl_reg_i.fec_dec_en = c_DISABLE else
               wrf_dat    when ctrl_reg_i.fec_dec_en = c_ENABLE  else
               (others => '0');

  -- Rx from WR Fabric
  rx_fabric : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        oob_toggle    <= '0';
        fec_skip_pkt  <= '0';
        eth_cnt       <= (others => '0');
        pkt_stb       <= '0';
        jumbo_frame   <= '0';
        fec_pad_stb   <= '0';
      else
        if (ctrl_reg_i.fec_enc_en =  c_ENABLE) then
          snk_o.ack <= snk_i.cyc or snk_i.stb;
          if snk_i.cyc = '1' and snk_i.stb = '1' and snk_stall = '0' and
             fec_skip_pkt = '0' then
            eth_cnt <= eth_cnt + 1;
            if (snk_i.adr = c_WRF_STATUS) then
              if (snk_i.dat(1) = '1') then
                fec_skip_pkt  <= '1';
              end if;
            elsif (snk_i.adr = c_WRF_DATA) then
              if (eth_cnt < c_fec_hdr_len - 3) then
              -- getting the pkt header
                pkt_stb <= '0';
              elsif (eth_cnt = c_fec_hdr_len - 3) then
              -- check FEC ethertype
                if (ctrl_reg.fec_ethtype /= snk_i.dat) then
                  --TODO No FEC pkt and FEC enable -> error
                  fec_skip_pkt  <= '1';
                else
                  fec_pad_stb   <= '1';
                end if;
              elsif (eth_cnt = c_fec_hdr_len - 2) then
                -- 1st 16 bits FEC Header Eth Frame Length and Padding
               fec_pad_stb   <= '0';
                -- start getting FEC 2nd header and payload
                pkt_stb <= '1';
              elsif (eth_cnt < c_eth_pkt - 1) then
                pkt_stb <= '1';
              else
                jumbo_frame <= '1';
              end if;
              eth_cnt <= eth_cnt + 1;
            elsif (snk_i.adr = c_WRF_OOB) then
              if (wrf_oob_cnt = 0) then
                pkt_stb           <= '0';
                oob_info.oob_type <= snk_i.dat(15 downto 12);
                oob_info.valid    <= snk_i.dat(11);
                oob_info.port_id  <= snk_i.dat(5 downto 0);
              elsif (wrf_oob_cnt = 1) then
                oob_info.ts_f <= snk_i.dat(15 downto 12);
                oob_info.ts_r(27 downto 16) <= snk_i.dat(11 downto 0);
              elsif (wrf_oob_cnt = 2) then
                oob_info.ts_r(15 downto 0) <= snk_i.dat;
              end if;
            end if;
          else
            eth_cnt     <= (others => '0');
            wrf_oob_cnt <= (others => '0');
            jumbo_frame <= '0';
            fec_skip_pkt<= '0';
            pkt_stb     <= '0';
          end if;
        else -- c_DISABLE
          jumbo_frame   <= '0';
          fec_skip_pkt  <= '0';
          pkt_stb       <= '0';
        end if;
      end if;
    end if;
  end process;

  snk_stall   <= src_i.stall  when ctrl_reg_i.fec_enc_en = c_DISABLE else
                '1'           when snk_i.cyc = '0'                   else
                '0';

  snk_o.stall <= snk_stall;
end rtl;
