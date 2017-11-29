--! @file wb_fec.vhd
--! @brief  FEC
--! @author C.Prados <cprados@mailfence.com>
--!
--! See the file "LICENSE" for the full license governing this code.
--!-------------------------------------------------------------------------------
--! Register Map
--! Ctrl Enc/Dec
--! 0x00, wr, enable/disable encoder 1bit
--! 0x04, wr, Pkt Erasure Code 2bit - Bit Erasure Code 2bit
--! 0x08  wr, Ethertype 16bit
-- Stat Enc/Dec
--! 0x0, r, Number of encoded frames --TBD
--! 0x0, wr, Encoded Frames Counter 32bit
-- Decoder Latency Statitcis
--! 0x, wr, decoder last latency
--! 0x, wr, decoder max latency
--! 0x, wr, decoder min latency
--! 0x, wr, decoder latency accumulated
--! 0x, wr, decoder number of latency measured
-- Ctrl Reset Stat Registers

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fec_pkg.all;
use work.wr_fabric_pkg.all;
use work.wishbone_pkg.all;

entity wb_slave_fec is
  port (
    clk_i             : in  std_logic;
    rst_n_i           : in  std_logic;
    wb_slave_i        : in  t_wishbone_slave_in;
    wb_slave_o        : out t_wishbone_slave_out;
    fec_stat_reg_i    : in  t_fec_stat_reg;
    fec_ctrl_reg_o    : out t_fec_ctrl_reg;
    fec_ctrl_refres_o : out std_logic;
    time_code_i       : in  t_time_code);
end wb_slave_fec;

architecture rtl of wb_slave_fec is

  signal s_fec_stat : t_fec_stat_reg;
  signal s_fec_ctrl : t_fec_ctrl_reg;

begin

  -- this wb slave doesn't supoort them
  wb_slave_o.int <= '0';
  wb_slave_o.rty <= '0';
  wb_slave_o.err <= '0';


  wb_process : process(clk_i)

  begin

    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        s_fec_stat  <= c_fec_stat_reg;
        s_fec_ctrl  <= c_fec_ctrl_reg;
        wb_slave_o.ack    <= '0';
        wb_slave_o.dat    <= (others => '0');
        s_fec_ctrl.fec_ctrl_refresh <= '1';
      else
        wb_slave_o.stall <= '0';
        wb_slave_o.ack <= wb_slave_i.cyc and wb_slave_i.stb;

        if wb_slave_i.cyc = '1' and wb_slave_i.stb = '1' then
          case wb_slave_i.adr(5 downto 2) is
            when "0000"    =>  -- enable/disable encoder 0x0
              if wb_slave_i.we = '1' then
                s_fec_ctrl.fec_enc_en <= wb_slave_i.dat(0);
              end if;
              wb_slave_o.dat(0) <= s_fec_ctrl.fec_enc_en;
              wb_slave_o.dat(31 downto 1) <= (others => '0');
            when "0001"    => --  Pkt Erasure Code / Bit Erasure Code 0x4
              if wb_slave_i.we = '1' then
                s_fec_ctrl.fec_code <= wb_slave_i.dat(2 downto 0);
              end if;
              wb_slave_o.dat(2  downto 0) <= s_fec_ctrl.fec_code;
              wb_slave_o.dat(31 downto 3) <= (others => '0');
            when "0010"    => -- Ethertype 0x8
              if wb_slave_i.we = '1' then
                s_fec_ctrl.fec_ethtype <= wb_slave_i.dat(15 downto 0);
              end if;
              wb_slave_o.dat(15 downto 0)   <= s_fec_ctrl.fec_ethtype;
              wb_slave_o.dat(31 downto 16)  <= (others => '0');
            when "0011"    => -- decoded frames 0xC
              if wb_slave_i.we = '1' then
                --s_fec_stat.stat_dec.err_dec <= wb_slave_i.dat; -- it'd be set to 0
              end if;
              --wb_slave_o.dat <= s_fec_stat.stat_dec.err_dec;
            when others =>
          end case;

          -- progates the changes in the reg
          if (wb_slave_i.we = '1') then
            s_fec_ctrl.fec_ctrl_refresh <= '1';
          end if;
        else
            s_fec_ctrl.fec_ctrl_refresh <= '0';
        end if;

      --s_fec_ctrl.time_code <= time_code_i;
      fec_ctrl_reg_o <= s_fec_ctrl;
      s_fec_stat     <= fec_stat_reg_i;
      end if;
    end if;
  end process;

end rtl;
