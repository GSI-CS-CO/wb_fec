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
  --signal eth_hrd_cnt      : unsigned(5 downto 0);
  signal eth_hrd_cnt      : integer range 0 to c_eth_hdr_len;
  signal eth_payload_cnt  : integer range 0 to c_eth_hdr_vlan_len;
  signal eth_hdr_reg      : t_eth_hdr;
  singal eth_hdr_shift    : t_eth_hdr;
begin 


  PKT_ERASURE_ENC : fec_encoder
    generic map (
  );
    port map (
      clk_i     => clk_i,
      rst_n_i   => rst_n_i,
      snk_i     => snk_i,
      snk_o     => snk_o
  );
  

  GOLAY_ENC_GEN : if g_en_golay generate
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
  eth_hdr_reg <= eth_hdr_shift(eth_hdr_shift'left downto 0) & snk_i.dat;
  eth_hdr     <= f_parse_eth(eth_hdr_reg);

  rx_fabric : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rstn_i = '0' then
        eth_hdr_cnt     <= (others => '0');
        eth_payload_cnt <= (others => '0');
        eth_hdr_shift   <= (others => '0');
      else
        snk_ack   <= snk_i.cyc and snk_i.stb
        --snk_stall <=;

        if snk_i.cyc = '0' then
          eth_hdr_cnt     <= (others => '0');
          eth_payload_cnt <= (others => '0');
        elsif snk_i.cyc = '1' and snk_i.stb = '1' and snk_stall = '0' then
          if snk_i.adr = c_WRF_DATA then
            if (eth_hdr_cnt < c_eth_hdr_len) then
              eth_hdr_shift <= eth_hdr_reg;
              pkt_erasure_stb <= '0';
              eth_hdr_cnt <= eth_hdr_cnt + 1;
            elsif (eth_payload_cnt < c_eth_payload_max_len)
              pkt_erasure_stb <= '1';
              --snk_i.dat;
              eth_payload_cnt <= eth_payload_cnt + 1;
            elsif (eth_payload_cnt >= c_eth_payload_max_len)
              -- jumbo frames error              
              pkt_erasure_stb <= '1';
              --snk_i.dat;
            end if;
          elsif snk_i.adr = c_WRF_OOB then
          elsif snk_i.adr = c_WRF_STATUS then 
          end if;
        else
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
