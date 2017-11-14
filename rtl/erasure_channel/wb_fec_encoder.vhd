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
  --signal src_cyc_d        : std_logic;
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
  signal data_payload     : unsigned(15 downto 0);
  signal fec_stb          : std_logic;
  signal fec_hdr_stb      : std_logic;
  signal data_fifo_i      : t_fifo_out;  
  alias  fec_pkt_i        : t_wrf_bus is data_fifo_i(15 downto 0);
  alias  wrf_adr_i        : t_wrf_adr is data_fifo_i(17 downto 16);
  signal data_fifo_o      : t_fifo_out;
  alias  fec_pkt_o        : t_wrf_bus is data_fifo_o(15 downto 0);
  alias  wrf_adr_o        : t_wrf_adr is data_fifo_o(17 downto 16);
  signal fec_payload_stb  : std_logic;
  signal wr_fifo_o        : std_logic;
  signal rd_fifo_o        : std_logic;
  signal fifo_empty       : std_logic;
  signal fifo_full        : std_logic;
  signal fifo_cnt         : te_fifo_cnt_width; --FIXME
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
  
  fec_payload_stb <=  '1' when s_fec_strm  = SEND_FEC_PAYLOAD else
                      '0';

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
  fec_hdr_stb <= '1' when s_fec_strm  = SEND_FEC_HDR else
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
        ctrl_reg  <= ctrl_reg_i; --FIXME
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
        fec_hdr_payload_len := c_fec_hdr_len + (2 * to_integer(fec_block_len));
        case s_fec_strm is
          when IDLE =>
            if (eth_cnt >= fec_block_len - 2) then
              s_fec_strm  <= SEND_OOB;
              fec_stb     <= '1';
            else
              s_fec_strm  <= IDLE;            
              fec_stb         <= '0';
              fec_word_cnt    <= 0;
              fec_pkt_cnt     <= 0;
            end if;
          when SEND_OOB => 
              s_fec_strm  <= SEND_FEC_HDR;
          when SEND_FEC_HDR =>
            if (fec_word_cnt < c_fec_hdr_len - 1) then
              s_fec_strm  <= SEND_FEC_HDR;
            else
              s_fec_strm  <= SEND_FEC_PAYLOAD;
            end if;
            fec_word_cnt <= fec_word_cnt + 1;          
          when SEND_FEC_PAYLOAD =>
            if (fec_word_cnt <= fec_hdr_payload_len - 1) then
              s_fec_strm      <= SEND_FEC_PAYLOAD;
            elsif(fec_pkt_cnt <= g_num_block - 1) then
              s_fec_strm      <= IDLE_FEC;
              fec_pkt_cnt <= fec_pkt_cnt + 1;
            else
              fec_stb         <= '0';
              s_fec_strm      <= IDLE_FEC;
            end if;
            fec_word_cnt <= fec_word_cnt + 1;

          when IDLE_FEC =>
            if (fifo_empty = '1') then
              if (fec_pkt_cnt <= g_num_block - 1) then
                s_fec_strm  <= SEND_OOB;
                fec_word_cnt  <= 0;
              else
                s_fec_strm  <= IDLE;
                fec_word_cnt  <= 0;
              end if;
            else
              s_fec_strm  <= IDLE_FEC;
            end if;
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
          if snk_i.cyc = '1' and snk_i.stb = '1' and snk_stall = '0' then
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
          --snk_o         <= src_i;
        end if;
      end if;
    end if;
  end process;

  snk_stall   <=  src_i.stall when  ctrl_reg_i.fec_enc_en = c_DISABLE else
                  '1'         when snk_i.cyc = '0' and fec_stb = '1'  else
                  '0';

  snk_o.stall <= snk_stall;

  --Tx to WR Fabric
  --tx_fabric : process(clk_i) is
  --begin
  --  if rising_edge(clk_i) then
  --    if rst_n_i = '0' then
  --      src_cyc <= '0';
  --    else
  --      if (s_fec_strm = SEND_OOB or  
  --          s_fec_strm = SEND_FEC_HDR or
  --          s_fec_strm = SEND_FEC_PAYLOAD or  
  --          (fifo_empty = '0' and  s_fec_strm = IDLE_FEC)) then
  --        src_cyc <= '1';
  --      else
  --        src_cyc <= '0';
  --      end if;
  --      --src_cyc_d <= src_cyc;
  --    end if;
  --  end if;
  --end process;
  
  data_fabric : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        data_payload  <= x"0001";
      else
        if (src_cyc = '1') then
          data_payload <= data_payload + 1;
        else
          data_payload <= x"0001";
        end if;
      end if;
    end if;
  end process;

  enc_payload <= std_logic_vector(data_payload);

  --src_cyc <= '1' when (s_fec_strm = SEND_OOB or  
            --s_fec_strm = SEND_FEC_HDR or
  src_cyc <= '1' when (s_fec_strm = SEND_FEC_HDR or
                        s_fec_strm = SEND_FEC_PAYLOAD or  
                        (fifo_empty = '0' and  s_fec_strm = IDLE_FEC)) and
                        fifo_empty = '0' else
            '0';

  -- FIXME the problem is with the de-cyc it takes two cycles
  src_o.cyc <=  snk_i.cyc when ctrl_reg_i.fec_enc_en = c_DISABLE else
                src_cyc  when ctrl_reg_i.fec_enc_en = c_ENABLE else --FIXME something more elegant..
                --src_cyc  when ctrl_reg_i.fec_enc_en = c_ENABLE and fifo_empty = '0' else --FIXME something more elegant..
                '0';
  
  src_o.stb <=  snk_i.stb when ctrl_reg_i.fec_enc_en = c_DISABLE else
                src_cyc  when ctrl_reg_i.fec_enc_en = c_ENABLE else -- FIXME something more elegant
                --src_cyc  when ctrl_reg_i.fec_enc_en = c_ENABLE and fifo_empty = '0' else -- FIXME something more elegant
                '0';

  src_o.sel <=  snk_i.sel when  ctrl_reg_i.fec_enc_en = c_DISABLE else
                "11";

  src_o.we  <=  snk_i.we when  ctrl_reg_i.fec_enc_en = c_DISABLE else
                '1';
  
  wrf_adr_i <= c_WRF_OOB        when s_fec_strm = SEND_OOB              else
               c_WRF_DATA       when s_fec_strm = SEND_FEC_HDR or s_fec_strm = SEND_FEC_PAYLOAD else
               (others => '0');

  src_o.adr <=  snk_i.adr   when ctrl_reg_i.fec_enc_en = c_DISABLE else
                wrf_adr_o   when ctrl_reg_i.fec_enc_en = c_ENABLE;

  fec_pkt_i <= c_WRF_OOB_TYPE_TX & x"aaa" when s_fec_strm = SEND_OOB          else
               fec_hdr                    when s_fec_strm = SEND_FEC_HDR      else
               enc_payload                when s_fec_strm = SEND_FEC_PAYLOAD  else
               (others => '0');
  
  src_o.dat <= snk_i.dat        when ctrl_reg_i.fec_enc_en = c_DISABLE  else
               fec_pkt_o        when ctrl_reg_i.fec_enc_en = c_ENABLE   else
               (others => '0');

  wr_fifo_o <=  '1'  when s_fec_strm = SEND_OOB or
                          s_fec_strm = SEND_FEC_HDR or 
                          s_fec_strm = SEND_FEC_PAYLOAD else
                '0';

  --rd_fifo_out <= (not src_i.stall) and src_cyc;  
  
  rd_fifo_o <=  '1'  when  (s_fec_strm = SEND_OOB or 
                            s_fec_strm = SEND_FEC_PAYLOAD  or
                            s_fec_strm = SEND_FEC_HDR or
                            s_fec_strm = IDLE_FEC) and
                            src_i.stall = '0' and 
                            fifo_empty = '0'else
                  '0';

  ENC_HDR_PKT_FIFO : generic_sync_fifo
    generic map (
      g_data_width  => c_wrf_width + 2,
      g_size        => 256,
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

    -- TODO
    -- IF HALT TOO LONG AND FIFO FULL, ERROR and RESET EVERYTHING
    -- ACK THE CHANGE IN THE CTRL REGISTER
    -- WHEN ENC DISABLE REVIEW

end rtl;
