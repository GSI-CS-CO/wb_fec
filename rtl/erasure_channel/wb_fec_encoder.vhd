--! @file wb_fec_encoder.vhd
--! @brief  A FEC Encoder
--! @author C.Prados <cprados@mailfence.com>
--!
--! See the file "LICENSE" for the full license governing this code.
--! TODO bypass if the encoder is not enable
--!-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

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
  signal eth_cnt          : integer range 0 to c_eth_hdr_len + c_eth_payload;
  signal src_cyc_d        : std_logic;
  signal src_cyc          : std_logic;
  signal enc_err          : std_logic;
  signal pkt_err          : std_logic;
  signal pkt_stb          : std_logic;
  signal pkt_enc_stb      : std_logic;
  signal hdr_etherType    : t_eth_type;
  signal ctrl_reg         : t_fec_ctrl_reg;
  signal snk_ack          : std_logic;
  signal snk_stall        : std_logic;
  signal enc_payload      : std_logic_vector(c_wrf_width - 1 downto 0);
  signal enc_en           : std_logic;
  signal fec_block_len    : t_block_len;
  signal hdr_stb          : std_logic;
  type t_enc_refresh is (REFRESH, WAIT_REFRESH);
  signal s_enc_refresh : t_enc_refresh;
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
      enc_payload_o => enc_payload);

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

  FEC_HDR : fec_hdr_gen
    generic map(
      g_id_width    => c_id_width,
      g_subid_width => c_subid_width)
    port map(
      clk_i       => clk_i,
      rst_n_i     => rst_n_i,
      hdr_i       => snk_i.dat,
      hdr_stb_i   => hdr_stb,
      block_len_i => fec_block_len,
      stb_i       => '0',
      fec_stb_i   => '0',
      fec_hdr_o   => open,
      enc_cnt_o   => stat_reg_o.fec_enc_cnt,
      ctrl_reg_i  => ctrl_reg);
  
  hdr_stb <= '1' when (snk_i.cyc = '1' and snk_i.stb = '1' and pkt_stb = '0' and
                       snk_stall = '0' and snk_i.adr = c_WRF_DATA) else 
             '0';

  -- Encoded frames payload lenght
  fec_block_len <= f_calc_len_block(hdr_etherType, c_div_num_block, g_num_block);

  -- Refresh the ctrl setting after pkt encoded
  ctrl_refresh : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
          s_enc_refresh <= REFRESH;
          enc_en        <= c_ENABLE;
          src_cyc_d     <= '0';
      else
        src_cyc_d <= snk_i.cyc;
        case s_enc_refresh is
          when REFRESH =>
            if (ctrl_reg_i.fec_ctrl_refresh = '1' and src_cyc = '0') then
              ctrl_reg  <= ctrl_reg_i;
              s_enc_refresh <= REFRESH;
            elsif (ctrl_reg_i.fec_ctrl_refresh = '1' and src_cyc = '1') then
              s_enc_refresh <= WAIT_REFRESH;
            end if;
          when WAIT_REFRESH => -- wait till the last enc pkt has been sent
            if ((src_cyc = '0') and (src_cyc_d = '1')) then
              ctrl_reg  <= ctrl_reg_i;
            end if;
            s_enc_refresh <= REFRESH;
        end case;
      end if;
    end if;
  end process;

  -- Rx from WR Fabric
  -- parsing ethernet header
  rx_fabric : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        hdr_etherType   <= (others => '0');
        eth_cnt         <= 0;
        pkt_stb         <= '0';
        pkt_err         <= '0';
      else
        if (enc_en =  c_ENABLE) then
          snk_ack   <= snk_i.cyc and snk_i.stb;
          snk_stall <= '0';

          if snk_i.cyc = '1' and snk_i.stb = '1' and snk_stall = '0' then
            if snk_i.adr = c_WRF_DATA then
              -- getting the frame header
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
                -- jumbo frames error
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
          src_o         <= snk_i;
        end if;
      end if;
    end if;
  end process;

  --Tx to WR Fabric
  tx_fabric : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
      else
        if (enc_en =  c_ENABLE) then
        else -- c_DISABLE
          snk_o <= src_i;
        end if;
      end if;
    end if;
  end process;
end rtl;
