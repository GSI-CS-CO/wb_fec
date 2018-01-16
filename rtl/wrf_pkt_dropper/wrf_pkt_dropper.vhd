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
use work.wrf_pkt_dropper_pkg.all;
use work.fec_pkg.all;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;

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

architecture rtl of wrf_pkt_dropper is
  type t_refresh is (IDLE, WAIT_TO_APPLY);
  signal s_refresh        : t_refresh;
  type t_drop is (IDLE, DROP);
  signal s_NEXT_PKT       : t_drop;
  signal src_ack          : std_logic;
  signal snk_ack          : std_logic;
  signal next_pkt_drop    : std_logic;
  signal src_stall        : std_logic;
  signal snk_cyc          : std_logic;
  signal snk_stb          : std_logic;
  signal snk_we           : std_logic;
  signal snk_sel          : std_logic_vector(1 downto 0);
  signal snk_adr          : t_wrf_adr;
  signal snk_dat          : t_wrf_bus;
  signal src_adr          : t_wrf_adr;
  signal src_dat          : t_wrf_bus;
  signal config           : t_conf;
  signal drop_config      : t_conf;
  signal pkt_drop         : t_drop_conf;
  signal pkt_cnt          : integer range 0 to 4;
begin

  WB_SLAVE : wrf_pkt_wb_slave
      port map (
        clk_i     => clk_i,
        rst_n_i   => rst_n_i,
        config_o  => config,
        wb_o      => wb_o,
        wb_i      => wb_i);

  -- Refresh the ctrl setting after pkt encoded
  ctrl_config_refresh : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
          s_refresh <= IDLE;
          drop_config   <= c_config;
      else
        case s_refresh is
          when IDLE =>
            if (config.refresh = '1' and (pkt_cnt = 0)) then
              drop_config  <= config;
              s_refresh <= IDLE;
            elsif (config.refresh = '1' and (pkt_cnt /= 0)) then
              s_refresh <= WAIT_TO_APPLY;
            end if;
          when WAIT_TO_APPLY => -- wait till the last enc pkt has been sent
            if (pkt_cnt = 0) then
              drop_config  <= config;
              s_refresh <= IDLE;
            else
              s_refresh <= WAIT_TO_APPLY;
            end if;
          when others =>
        end case;
      end if;
    end if;
  end process;

  -- Rx from WR Fabric
  rx_fabric : process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        next_pkt_drop   <= '0';
        snk_cyc         <= '0';
        src_stall       <= '0';
        src_ack         <= '0';
        snk_ack         <= '0';
        snk_stb         <= '0';
        snk_we          <= '0';
        pkt_cnt         <= 0;
        s_NEXT_PKT      <= IDLE;
        snk_adr         <= (others => '0');
        snk_dat         <= (others => '0');
        pkt_drop        <= (others => '0');
        snk_sel         <= (others => '0');
      else
        -- Rx
        snk_cyc   <= snk_i.cyc;
        snk_stb   <= snk_i.stb;
        snk_we    <= snk_i.we;
        snk_sel   <= snk_i.sel;
        snk_adr   <= snk_i.adr;
        snk_dat   <= snk_i.dat;

        -- Tx
        src_stall <= src_i.stall;
        src_ack   <= src_i.ack;
        snk_ack   <= snk_i.cyc and snk_i.stb;


        pkt_drop <= f_pkt_drop(drop_config);

        case s_NEXT_PKT is
          when IDLE =>
            if (snk_i.cyc = '1' and snk_cyc = '0') then
              if (pkt_drop(pkt_cnt) = '1') then
                s_NEXT_PKT <= DROP;
                next_pkt_drop <= '1';
              else
                next_pkt_drop <= '0';
              end if;

              if (pkt_cnt < g_num_block - 1) then
                pkt_cnt <= pkt_cnt + 1;
              else
                pkt_cnt <= 0;
              end if;
            else
              next_pkt_drop <= '0';
            end if;
          when DROP =>
            if (snk_i.stb = '0' and snk_stb = '1') then
              s_NEXT_PKT    <= IDLE;
            else
              next_pkt_drop <= '1';
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

  snk_o.ack     <= src_ack   when next_pkt_drop = '0' else
                   snk_ack   when next_pkt_drop = '1';

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
