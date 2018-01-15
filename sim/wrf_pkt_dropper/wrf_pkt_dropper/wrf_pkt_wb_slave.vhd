library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.wrf_pkt_dropper_pkg.all;
use work.wishbone_pkg.all;

entity wrf_pkt_wb_slave is
  port(
    clk_i     : in  std_logic;
    rst_n_i   : in  std_logic;
    config_o  : out t_config;
    wb_o      : out t_wishbone_slave_out;
    wb_i      : in  t_wishbone_slave_in);
end wrf_pkt_wb_slave;

architecture rtl of wrf_pkt_wb_slave is
  signal config t_conf;
begin

  -- this wb slave doesn't supoort them
  wb_o.int <= '0';
  wb_o.rty <= '0';
  wb_o.err <= '0';

  wb_process : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_o.ack    <= '0';
        wb_o.dat    <= (others => '0');
        config      <= c_config;
      else
        wb_o.stall  <= '0';
        wb_o.ack    <= wb_i.cyc and wb_i.stb;

        if wb_i.cyc = '1' and wb_i.stb = '1' then
          case wb_i.adr(5 downto 2) is
            when "0000"    =>
              if wb_i.we = '1' then
                config.drop <= wb_slave_i.dat(3 downto 0);
              end if;
              wb_o.dat(3 downto 0)  <= config.drop;
              wb_o.dat(31 downto 4) <= (others => '0');
            when "0001"    =>
              if wb_i.we = '1' then
                config.rnd <= wb_i.dat(0);
              end if;
              wb_o.dat(0)           <= config.rnd;
              wb_o.dat(31 downto 1) <= (others => '0');
          end case;

          -- progates the changes in the reg
          if (wb_i.we = '1') then
            config.refresh <= '1';
          end if;
        else
            config.refresh <= '0';
        end if;
      end if;
    end if;
  end process;
  config_o <= config;
end rtl;
