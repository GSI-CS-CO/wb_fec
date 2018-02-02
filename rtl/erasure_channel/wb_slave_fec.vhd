--! @file wb_fec.vhd
--! @brief  FEC
--! @author C.Prados <cprados@mailfence.com>
--!
--! See the file "LICENSE" for the full license governing this code.
--!-------------------------------------------------------------------------------
--! Register Map
--! 0x0  Enable/disable encoder/decoder
--! 0x4  FEC type
--! 0x8  FEC Ethertype
--! 0xC  Etherbone Ethertype
--! 0x10 Num of Encoded Frames
--! 0x14 Num of Decoded Frames
--! 0x18 Num of Jumbo Frames Errors in Rx
--! 0x1C Num of Decoding Errors > 2 FEC pkts lost
--! 0x20 Num of Encoding Errors & Jumbo Frames Errors

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

  signal s_fec_ctrl   : t_fec_ctrl_reg;
  signal dec_err_d    : std_logic;
  signal enc_err_d    : std_logic_vector(1 downto 0);
  signal dec_err_cnt  : unsigned (c_fec_cnt_width - 1 downto 0);
  signal enc_err_cnt  : unsigned (c_fec_cnt_width - 1 downto 0);
  signal jumbo_pkt_cnt: unsigned (c_fec_cnt_width - 1 downto 0);
  signal jumbo_pkt_d  : std_logic;

begin

  -- this wb slave doesn't supoort them
  wb_slave_o.int <= '0';
  wb_slave_o.rty <= '0';
  wb_slave_o.err <= '0';

  fec_ctrl_reg_o  <= s_fec_ctrl;

  wb_process : process(clk_i)

  begin

    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        s_fec_ctrl  <= c_fec_ctrl_reg;
        jumbo_pkt_d <= '0';
        dec_err_d   <= '0';
        dec_err_cnt <= (others => '0');
        enc_err_cnt <= (others => '0');
        jumbo_pkt_cnt   <= (others => '0');
        wb_slave_o.dat  <= (others => '0');
        wb_slave_o.ack  <= '0';
        s_fec_ctrl.fec_ctrl_refresh <= '1';
      else
        wb_slave_o.stall <= '0';
        wb_slave_o.ack <= wb_slave_i.cyc and wb_slave_i.stb;

        if wb_slave_i.cyc = '1' and wb_slave_i.stb = '1' then
          case wb_slave_i.adr(5 downto 2) is
            when "0000" =>  -- enable/disable encoder/decoder
              if wb_slave_i.we = '1' then
                s_fec_ctrl.fec_enc_en <= wb_slave_i.dat(0);
                s_fec_ctrl.fec_dec_en <= wb_slave_i.dat(1);
              else
                wb_slave_o.dat(0) <= s_fec_ctrl.fec_enc_en; 
                wb_slave_o.dat(1) <= s_fec_ctrl.fec_dec_en;
                wb_slave_o.dat(31 downto 2) <= (others => '0');
              end if;
            when "0001" =>  -- Pkt Erasure Code / Bit Erasure Code
              if wb_slave_i.we = '1' then
                s_fec_ctrl.fec_code <= wb_slave_i.dat(2 downto 0);
              end if;
              wb_slave_o.dat(2  downto 0) <= s_fec_ctrl.fec_code;
              wb_slave_o.dat(31 downto 3) <= (others => '0');
            when "0010" => -- FEC Ethertype
              if wb_slave_i.we = '1' then
                s_fec_ctrl.fec_ethtype <= wb_slave_i.dat(15 downto 0);
              end if;
              wb_slave_o.dat(15 downto 0)   <= s_fec_ctrl.fec_ethtype;
              wb_slave_o.dat(31 downto 16)  <= (others => '0');
            when "0011" => -- Etherbone Ethertype
              if wb_slave_i.we = '1' then
                s_fec_ctrl.eb_ethtype <= wb_slave_i.dat(15 downto 0);
              end if;
              wb_slave_o.dat(15 downto 0)   <= s_fec_ctrl.eb_ethtype;
              wb_slave_o.dat(31 downto 16)  <= (others => '0');
            when "0100" => -- number of encoded frames
              wb_slave_o.dat  <= fec_stat_reg_i.enc_err.fec_enc_cnt;
            when "0101" => --number of decoded frames
              wb_slave_o.dat  <= fec_stat_reg_i.dec_err.fec_dec_cnt;
            when "0110" => -- number of errors jumbo frames
              wb_slave_o.dat  <= std_logic_vector(jumbo_pkt_cnt);
            when "0111" => -- number of dec errors
              wb_slave_o.dat  <= std_logic_vector(dec_err_cnt);
            when "1000" => -- number of enc errors
              wb_slave_o.dat  <= std_logic_vector(enc_err_cnt);
            when "1001" =>
              s_fec_ctrl.rst_cnt <= '1';
            when others =>
          end case;

          -- propagates the changes in the reg
          if (wb_slave_i.we = '1') then
            s_fec_ctrl.fec_ctrl_refresh <= '1';
          end if;

        else
            s_fec_ctrl.rst_cnt <= '0';
            s_fec_ctrl.fec_ctrl_refresh <= '0';
        end if;

        -- Encoding Error Counter
        enc_err_d <= fec_stat_reg_i.enc_err.fec_enc_err;
        if (s_fec_ctrl.rst_cnt <= '1') then
          enc_err_cnt <= (others => '0');
        elsif ((enc_err_d(0) = '0' and fec_stat_reg_i.enc_err.fec_enc_err(0) = '1') or
               (enc_err_d(1) = '0' and fec_stat_reg_i.enc_err.fec_enc_err(1) = '1')) then
          enc_err_cnt <= enc_err_cnt + 1;
        end if;

        -- Decoding Error Counter
        dec_err_d <= fec_stat_reg_i.dec_err.dec_err;
        if (s_fec_ctrl.rst_cnt <= '1') then
          dec_err_cnt <= (others => '0');
        elsif (dec_err_d = '0' and fec_stat_reg_i.dec_err.dec_err = '1') then
          dec_err_cnt <= dec_err_cnt + 1;
        end if;
        -- Jumbo Frame Error
        jumbo_pkt_d <= fec_stat_reg_i.dec_err.jumbo_frame;
        if (s_fec_ctrl.rst_cnt <= '1') then
          jumbo_pkt_cnt <= (others => '0');
        elsif (jumbo_pkt_d = '0' and fec_stat_reg_i.dec_err.jumbo_frame = '1') then
          jumbo_pkt_cnt <= jumbo_pkt_cnt + 1;
        end if;
      end if;
    end if;
  end process;
end rtl;
