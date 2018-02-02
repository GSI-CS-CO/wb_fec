--! @file wb_cnt_checker.vhd
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
use work.wb_cnt_checker_pkg.all;
use work.fec_pkg.all;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;

entity wb_cnt_checker is
    port (
      clk_i     : in  std_logic;
      rst_n_i   : in  std_logic;
      wb_o      : out t_wishbone_slave_out;
      wb_i      : in  t_wishbone_slave_in);
end wb_cnt_checker;

architecture rtl of wb_cnt_checker is
  signal eb_dat           : std_logic_vector(31 downto 0);
  signal eb_cnt           : unsigned(31 downto 0);
  signal eb_missing_cnt   : unsigned(31 downto 0);
begin

  -- this wb slave doesn't supoort them
  wb_o.int <= '0';
  wb_o.rty <= '0';
  wb_o.err <= '0';

  wb_process : process(clk_i)
    variable cnt_diff   : unsigned(31 downto 0);
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_o.ack        <= '0';
        wb_o.dat        <= (others => '0');
        eb_cnt          <= (0 => '1', others => '0');
        eb_dat          <= (others => '0');
        eb_missing_cnt  <= (others => '0');
      else
        wb_o.stall  <= '0';
        wb_o.ack    <= wb_i.cyc and wb_i.stb;

        if wb_i.cyc = '1' and wb_i.stb = '1' then
          case wb_i.adr(5 downto 2) is
            when "0000"    =>
              if wb_i.we = '1' then
                if(eb_dat /= wb_i.dat) then
                  eb_missing_cnt <= eb_missing_cnt + unsigned(wb_i.dat) - unsigned(eb_dat) - 1;
                end if;
                eb_dat  <= wb_i.dat;
                eb_cnt  <= eb_cnt + 1;
              end if;
              wb_o.dat(31 downto 0) <= eb_dat;
            when "0001"     =>
              if wb_i.we = '1' then
                eb_cnt <= (others => '0');
              end if;
              wb_o.dat(31 downto 0) <= std_logic_vector(eb_cnt);
            when "0010"     =>
              if wb_i.we = '1' then
                eb_missing_cnt <= (others => '0');
              end if;
              wb_o.dat(31 downto 0) <= std_logic_vector(eb_missing_cnt);
            when "0011"     =>
              if wb_i.we = '1' then
                eb_cnt <= (others => '0');
                eb_missing_cnt <= (others => '0');
                eb_dat <= (others => '0');
              end if;
              wb_o.dat <= (others => '0');
            when others =>
          end case;
        end if;
      end if;
    end if;
  end process;
end rtl;
