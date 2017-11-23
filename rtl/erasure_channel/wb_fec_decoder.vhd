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
  signal fec_nex_id       : std_logic;
  signal fec_skip_pkt     : std_logic;
  signal eth_cnt          : unsigned (c_eth_pkt_width - 1 downto 0);
  type t_fec_rx_strm  is (IDLE, RX_FEC_PKT, RX_OOB);
  signal s_fec_rx_strm    : t_fec_rx_strm;
  signal pkt_stb          : std_logic;
  signal pkt_err          : std_logic;
  signal hdr_stb          : std_logic;
  signal fec_stb          : std_logic;
  signal fec_stb_d        : std_logic;
  signal eth_payload_stb  : std_logic;
  signal src_halt         : std_logic;
  signal dec_err          : t_dec_err;
  signal eth_payload      : t_wrf_bus;
  signal eth_hdr          : t_wrf_bus;
  signal eth_hdr_stb      : std_logic;
  signal ctrl_reg         : t_fec_ctrl_reg;
  signal snk_stall        : std_logic;
  signal snk_ack          : std_logic;
  type t_enc_refresh is (IDLE, WAIT_TO_APPLY);
  signal s_enc_refresh    : t_enc_refresh;

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
    fec_stb_o         => fec_stb,
    pkt_payload_o     => eth_payload,
    pkt_payload_stb_o => eth_payload_stb,
    halt_streaming_i  => src_halt,
    pkt_dec_err_o     => dec_err);

  FEC_HDR_PROC : fec_hdr_gen
    generic map(
      g_id_width    => c_id_width,
      g_subid_width => c_subid_width,
      g_fec_type    => "decoder")
    port map(
      clk_i         => clk_i,
      rst_n_i       => rst_n_i,
      hdr_i         => snk_i.dat,
      hdr_stb_i     => hdr_stb,
      block_len_i   => (others => '0'),
      fec_stb_i     => fec_stb,
      fec_hdr_stb_i => eth_hdr_stb,
      fec_hdr_o     => eth_hdr,
      enc_cnt_o     => open,
      ctrl_reg_i    => ctrl_reg);
  
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
  --TODO 
  --stat_reg_o.fec_enc_err  <= enc_err & pkt_err;
  --stat_reg_o.fec_enc_cnt  <= pkt_id;

  -- Rx from WR Fabric
  rx_fabric : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        oob_toggle    <= '0';                
        fec_skip_pkt  <= '0';
        eth_cnt       <= (others => '0');
        s_fec_rx_strm <= IDLE;
        pkt_stb       <= '0';
        pkt_err       <= '0';
      else
        if (ctrl_reg_i.fec_enc_en =  c_ENABLE) then
          snk_ack <= snk_i.cyc and snk_i.stb;
          case s_fec_rx_strm is
            when IDLE =>
              if snk_i.cyc = '1' and snk_i.stb = '1' and snk_stall = '0' and 
                 fec_skip_pkt = '0' then
                if (snk_i.adr = c_WRF_STATUS) then
                  if (snk_i.dat(1) = '1') then
                    --TODO The Frame has a bit error should go to Golay
                    fec_skip_pkt  <= '1';
                    s_fec_rx_strm <= IDLE;
                  else
                    s_fec_rx_strm <= RX_FEC_PKT;
                  end if;
                elsif (snk_i.adr = c_WRF_DATA) then
                    -- it shouldn't happen but just in case
                    s_fec_rx_strm   <= RX_FEC_PKT;
                    eth_cnt <= eth_cnt + 1;
                else
                  --TODO Error no correct info in the WR Fabric
                end if;
              elsif snk_i.cyc = '0' and snk_i.stb = '0' then
                fec_skip_pkt  <= '0';
                eth_cnt       <= (others => '0');
                s_fec_rx_strm <= IDLE;
                pkt_stb       <= '0';
                pkt_err       <= '0';
              end if;
            when RX_FEC_PKT =>
              if snk_i.cyc = '1' and snk_i.stb = '1' and snk_stall = '0' then
                if (snk_i.adr = c_WRF_DATA) then
                  if (eth_cnt < c_fec_hdr_len - 2) then
                  -- getting the pkt header
                    pkt_stb <= '0';
                  elsif (eth_cnt = c_fec_hdr_len - 2) then
                  -- check FEC ethertype
                    if (ctrl_reg.fec_ethtype /= snk_i.dat) then
                      --TODO No FEC pkt and FEC enable -> error
                      fec_skip_pkt  <= '1'; 
                      s_fec_rx_strm <= IDLE;
                    end if;                    
                    -- start getting FEC payload
                    pkt_stb       <= '1';
                  elsif (eth_cnt < c_eth_pkt - 1) then
                    pkt_stb <= '0';
                  --TODO jumbo pkt error
                    --pkt_err   <= '1';
                  end if;
                  eth_cnt <= eth_cnt + 1;
                elsif (snk_i.adr = c_WRF_OOB) then
                  pkt_stb <= '0';
                  oob_info.oob_type <= snk_i.dat(15 downto 12);
                  oob_info.valid    <= snk_i.dat(11);
                  oob_info.port_id  <= snk_i.dat(5 downto 0);
                  s_fec_rx_strm <= RX_OOB;
                end if;
              end if;                
            when RX_OOB =>
              if snk_i.cyc = '1' and snk_i.stb = '1' and snk_stall = '0' and
                snk_i.adr = c_WRF_OOB then
              else
                if (oob_toggle = '0') then
                  oob_info.ts_f <= snk_i.dat(15 downto 12);
                  oob_info.ts_r(27 downto 16) <= snk_i.dat(11 downto 0);
                  oob_toggle    <= '1';
                else
                  oob_info.ts_r(15 downto 0) <= snk_i.dat;
                  s_fec_rx_strm <= IDLE;
                end if;
              end if;
            when others =>
            end case;
        else -- c_DISABLE
          pkt_stb       <= '0';
          pkt_err       <= '0';
        end if;
      end if;
    end if;
  end process;

end rtl;
