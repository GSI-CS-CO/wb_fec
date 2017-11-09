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
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;

entity wb_fec_encoder is
  generic ( g_en_golay    : boolean := FALSE);
    port (
      clk_i         : in  std_logic;
      rst_n_i       : in  std_logic;     
      snk_i         : in  t_wrf_sink_in;
      snk_o         : out t_wrf_sink_out;
      src_i         : in  t_wrf_source_in;
      src_o         : out t_wrf_source_out;
      ctrl_reg_i    : in  t_enc_ctrl_reg;
      stat_reg_o    : out t_enc_stat_reg);
end wb_fec_encoder;

architecture rtl of wb_fec_encoder is
  signal eth_hdr_cnt      : integer range 0 to c_eth_hdr_len - 1;
  signal eth_payload_cnt  : integer range 0 to c_eth_hdr_vlan_len; -- covers jumbo frames
  signal eth_hdr_reg      : t_eth_hdr;
  signal eth_hdr_shift    : t_eth_hdr;
  signal eth_hdr          : t_eth_frame_header;
  signal enc_err          : std_logic;
  signal pkt_err          : std_logic;
  signal pkt_stb          : std_logic;
  signal pkt_enc_stb      : std_logic;
  --signal ctrl_reg         : t_enc_ctrl_reg;
  --signal stat_reg         : t_enc_stat_reg;
  signal snk_ack          : std_logic;
  signal snk_stall        : std_logic;
  signal enc_payload      : std_logic_vector(c_wrf_width - 1 downto 0);
  signal enc_en           : std_logic;
  signal enc_src_out      : t_wrf_source_out;
  signal enc_src_in       : t_wrf_source_in;
  signal enc_sink_out     : t_wrf_sink_out;
  signal enc_sink_in      : t_wrf_sink_in;
  type t_enc_switch is (ENC_ENABLE, ENC_DISABLE);
  signal s_enc_switch : t_enc_switch;


begin 

  PKT_ERASURE_ENC : fec_encoder
    port  map(
      clk_i         => clk_i,
      rst_n_i       => rst_n_i,
      payload_i     => snk_i.dat,
      stb_i         => pkt_stb,
      pl_len_i      => eth_hdr.eth_etherType, -- payload in 16 bit words
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

  ----- Fabric Interface
  -- Bypass Encoder Disable
  bypass_fabric : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
          s_enc_switch  <= ENC_ENABLE;
          enc_en        <= c_DISABLE;
      else
        case s_enc_switch is
          when ENC_ENABLE =>
            if (ctrl_reg_i.fec_enc_en = '0') then
            --TODO wait till the encoder finish
              enc_en  <= c_DISABLE;  
            end if;
          when ENC_DISABLE =>
            if (ctrl_reg_i.fec_enc_en = '1') then
            --TODO wait till the encoder finish
              enc_en  <= c_ENABLE;  
            end if;
        end case;
      end if;
    end if;
  end process;

  -- Rx from WR Fabric
  -- parsing ethernet header
  eth_hdr_reg <= eth_hdr_shift(t_eth_hdr'left - snk_i.dat'length downto 0) & snk_i.dat;
  eth_hdr     <= f_parse_eth(eth_hdr_reg);

  rx_fabric : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        eth_hdr_cnt     <= 0;
        eth_payload_cnt <= 0;
        eth_hdr_shift   <= (others => '0');
        pkt_stb         <= '0';
        pkt_err         <= '0';
      else
        if (enc_en =  c_ENABLE) then
          snk_ack   <= snk_i.cyc and snk_i.stb;
          --snk_stall <=;

          if snk_i.cyc = '0' then
            eth_hdr_cnt     <= 0;
            eth_payload_cnt <= 0;
            eth_hdr_shift   <= (others => '0');
            pkt_stb         <= '0';
            pkt_err         <= '0';
          elsif snk_i.cyc = '1' and snk_i.stb = '1' and snk_stall = '0' then
            if snk_i.adr = c_WRF_DATA then
              if (eth_hdr_cnt < c_eth_hdr_len) then
                eth_hdr_shift <= eth_hdr_reg;
                pkt_stb     <= '0';
                eth_hdr_cnt <= eth_hdr_cnt + 1;
              elsif (eth_payload_cnt < c_eth_payload) then
                pkt_stb         <= '1';
                eth_payload_cnt <= eth_payload_cnt + 1;
              elsif (eth_payload_cnt >= c_eth_payload) then
                -- jumbo frames error
                pkt_err <= '1';
                pkt_stb <= '0';
              end if;          
            else -- snk_i.adr = c_WRF_OOB or snk_i.adr = c_WRF_STATUS          
              eth_hdr_cnt     <= 0;
              eth_payload_cnt <= 0;
              eth_hdr_shift   <= (others => '0');
              pkt_stb         <= '0';
              pkt_err         <= '0';
            end if;
          end if;
        else -- c_DISABLE
          src_o <= snk_i;
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
