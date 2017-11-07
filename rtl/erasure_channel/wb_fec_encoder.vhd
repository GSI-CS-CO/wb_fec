--! @file wb_fec_encoder.vhd
--! @brief  A FEC Encoder
--! @author C.Prados <cprados@mailfence.com>
--!
--! See the file "LICENSE" for the full license governing this code.
--!-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.fec_pkg.all;
use work.golay_pk.all;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;

entity wb_fec_encoder is
  generic ( g_en_golay    : boolean);    
    port (
      clk_i       : in  std_logic;
      rst_n_i     : in  std_logic;     
      snk_i       : in  t_wrf_sink_in;
      snk_o       : out t_wrf_sink_out;
      src_i       : in  t_wrf_source_in;
      src_o       : out t_wrf_source_out;
      slave_o     : out t_wishbone_slave_out;
      slave_i     : in  t_wishbone_slave_in);
end wb_fec_encoder;

architecture rtl of wb_fec_encoder is
  --signal eth_hrd_cnt      : unsigned(5 downto 0);
  --signal eth_payload_cnt  : unsigned(5 downto 0);
  signal eth_hdr_cnt      : integer range 0 to c_eth_hdr_len - 1;
  signal eth_payload_cnt  : integer range 0 to c_eth_hdr_vlan_len; -- covers jumbo frames
  signal eth_hdr_reg      : t_eth_hdr;
  signal eth_hdr_shift    : t_eth_hdr;
  signal eth_hdr          : t_eth_frame_header;
  signal enc_err          : std_logic;
  signal pkt_stb          : std_logic;
  signal pkt_enc_stb      : std_logic;
  signal fec_enc_err      : std_logic(1 downto 0);
  signal enc_err          : std_logic;
  signal pkt_err          : std_logic;

begin 


  PKT_ERASURE_ENC : fec_encoder
    generic map (
  );
    port (
      clk_i         => clk_i,
      rst_n_i       => rst_n_i,
      payload_i     => snk_i.dat,
      stb_i         => pkt_stb,
      pl_len_i      => eth_hdr.eth_etherType, -- payload in 16 bit words
      enc_err_o     => enc_err,
      stb_o         => pkt_enc_stb,
      enc_payload_o => );
 
    port map (
      clk_i     => clk_i,
      rst_n_i   => rst_n_i,
      snk_i     => snk_i,
      snk_o     => snk_o
  );
  
  fec_enc_err <= enc_err & pkt_err;

  g_GOLAY_ENC : if g_en_golay generate
    GOLAY_ENC : golay_encoder
      port map (
        clk_i       => clk_i,
        rst_n_i     => rst_n_i,
        stb_i       => 
        payload_i   =>
        code_word_o => );
  end generate;

  ----- Fabric Interface
  -- Rx

  -- parsing ethernet header
  eth_hdr_reg <= eth_hdr_shift(eth_hdr_shift'left downto 0) & snk_i.dat;
  eth_hdr     <= f_parse_eth(eth_hdr_reg);

  rx_fabric : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rstn_i = '0' then
        eth_hdr_cnt     <= (others => '0');
        eth_payload_cnt <= (others => '0');
        eth_hdr_shift   <= (others => '0');
        pkt_stb         <= '0';
        pkt_err         <= '0';
      else
        snk_ack   <= snk_i.cyc and snk_i.stb
        --snk_stall <=;

        if snk_i.cyc = '0' then
          eth_hdr_cnt     <= (others => '0');
          eth_payload_cnt <= (others => '0');
          eth_hdr_shift   <= (others => '0');
          pkt_stb         <= '0';
          pkt_err         <= '0';
        elsif snk_i.cyc = '1' and snk_i.stb = '1' and snk_stall = '0' then
          if snk_i.adr = c_WRF_DATA then
            if (eth_hdr_cnt < c_eth_hdr_len) then
              eth_hdr_shift <= eth_hdr_reg;
              pkt_stb     <= '0';
              eth_hdr_cnt <= eth_hdr_cnt + 1;
            elsif (eth_payload_cnt < c_eth_payload_max_len)
              pkt_stb         <= '1';
              eth_payload_cnt <= eth_payload_cnt + 1;
            elsif (eth_payload_cnt >= c_eth_payload_max_len)
              -- jumbo frames error
              pkt_err <= '1';
              pkt_stb <= '0';
            end if;          
          else -- snk_i.adr = c_WRF_OOB or snk_i.adr = c_WRF_STATUS          
            eth_hdr_cnt     <= (others => '0');
            eth_payload_cnt <= (others => '0');
            eth_hdr_shift   <= (others => '0');
            pkt_stb         <= '0';
            pkt_err         <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

 -- Tx
 rx_fabric : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rstn_i = '0' then
      else
      end if;
    end if;
  end process;

end rtl;
