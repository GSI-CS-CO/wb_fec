--! @file wrf_pkt_dropper.vhd
--! @brief  A FEC Encoder
--! @author C.Prados <cprados@mailfence.com>
--!
--! See the file "LICENSE" for the full license governing this code.
--! Drops fec packets.
--!-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fec_pkg.all;
use work.wrf_pkt_dropper_pkg.all;
use work.wishbone_pkg.all;
use work.genram_pkg.all;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;

entity wrf_pkt_dropper is
  generic (
    g_num_block   : integer := 4);
    port (
      clk_i     : in  std_logic;
      rst_n_i   : in  std_logic;
      snk_i     : in  t_wrf_sink_in;
      snk_o     : out t_wrf_sink_out;
      src_i     : in  t_wrf_source_in;
      src_o     : out t_wrf_source_out;
      wb_o      : out t_wishbone_slave_out;
      wb_i      : in  t_wishbone_slave_in);
end wrf_pkt_dropper;

architecture rtl of wb_fec_encoder is
  type t_refresh is (IDLE, WAIT_TO_APPLY);
  signal s_refresh        : t_refresh;
  signal snk_ack          : std_logic;
  signal next_pkt_drop    : std_logic;
  signal snk_cyc          : std_logic;
  signal src_stall        : std_logic;
  signal snk_cyc          : std_logic;
  signal src_stall        : std_logic;
  signal snk_stb          : std_logic;
  signal src_sel          : std_logic;
  signal src_we           : std_logic;
  signal src_adr          : t_wrf_adr;
  signal src_dat          : t_wrf_bus;
  signal config           : t_conf;
  signal drop_config      : t_conf;
  signal pkt_drop         : t_drop_conf;
begin

  WB_SLAVE : wrf_pkt_wb_slave
      port (
        clk_i   <= clk_i,
        rst_n_i <= rst_n_i,
        config  <= config,
        wb_o    <= wb_o,
        wb_i    <= wb_i);
  end component;

  -- Refresh the ctrl setting after pkt encoded
  ctrl_config_refresh : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
          s_enc_refresh <= IDLE;
          drop_config   <= c_config;
      else
        case s_enc_refresh is
          when IDLE =>
            if (config.refresh = '1' and pkt_cnt = 0) then
              drop_config  <= config;
              s_refresh <= IDLE;
            elsif (config.refresh = '1' and pkt_cnt != 0) then
              s_refresh <= WAIT_TO_APPLY;
            end if;
          when WAIT_TO_APPLY => -- wait till the last enc pkt has been sent
            if (pkt_cnt = 0) then
              drop_config  <= config;
              s_refresh <= IDLE;
            else
              s_refresh <= WAIT_TO_APPLY;
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
        snk_ack         <= '0';
        next_pkt_drop   <= '0';
        snk_cyc         <= '0';
        src_stall       <= '0';
        snk_cyc         <= '0';
        src_stall       <= '0';
        snk_stb         <= '0';
        src_sel         <= '0';
        src_we          <= '0';
        pkt_cnt         <= 0;
        src_adr         <= (others => '0');
        src_dat         <= (others => '0');
        pkt_drop        <= (others => '0');
      else
        snk_o.ack <= snk_cyc and snk_stb;

        src_stall <= src_i.stall;
        snk_cyc   <= snk_i.cyc;
        src_stall <= src_i.stall;
        snk_stb   <= snk_i.stb;
        src_sel   <= snk_i.sel;
        src_we    <= snk_i.we;
        src_adr   <= snk_i.adr;
        src_dat   <= snk_i.dat;

        pkt_drop = f_pkt_drop(drop_config);

        case s_NEXT_PKT is
          when IDLE =>
            if (snk_i.cyc and (not snk_cyc)) then
              if (pkt_drop[pkt_cnt] = '1') then
                s_NEXT_PKT <= DROP;
                next_pkt_drop = '1';
              else
                next_pkt_drop <= '0';
              end if;

              if (pkt_cnt <= g_num_block - 1) then
                pkt_cnt = pkt_cnt + 1;
              else
                pkt_cnt = 0;
              end if;
            else
              next_pkt_drop <= '0';
            end if;
          when DROP =>
            if ((not nk_i.cyc) and snk_cyc) then
              s_NEXT_PKT    <= IDLE;
              next_pkt_drop <= '0';
            else
              next_pkt_drop = '1';
            end if;
          when others =>
        end case;
      end if;
    end if;
  end process;

  -- Rx from WR Frabric
  snk_o.stall <=  src_stall   when next_pkt_drop = '0' else
                  '0'         when next_pkt_drop = '1';

  snk_o.err    <=  '0';
  snk_o.rty    <=  '0';

  -- Tx to WR Farbric
  src_o.stb <=  snk_stb   when next_pkt_drop = '0' else
                '0'       when next_pkt_drop = '1';

  src_o.cyc <=  snk_cyc  when next_pkt_drop = '0' else
                '0'      when next_pkt_drop = '1';

  src_o.sel <=  snk_sel when  next_pkt_drop = '0' else
                "11";

  src_o.we  <=  snk_we  when next_pkt_drop = '0' else
                '0';

  src_o.adr <=  snk_adr         when next_pkt_drop = '0' else
                (others => '0') when next_pkt_drop = '1';

  src_o.dat <= snk_dat          when next_pkt_drop = '0' else
               (others => '0')  when next_pkt_drop = '1';
end rtl;
