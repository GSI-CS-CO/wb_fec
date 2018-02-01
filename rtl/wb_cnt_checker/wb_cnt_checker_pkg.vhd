library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.wishbone_pkg.all;

package wb_cnt_checker_pkg is

  constant c_checker_sdb : t_sdb_device := (
    abi_class       => x"0000", -- undocumented device
    abi_ver_major   => x"01",
    abi_ver_minor   => x"01",
    wbd_endian      => c_sdb_endian_big,
    wbd_width       => x"4", -- 32-bit port granularity
    sdb_component   => (
    addr_first      => x"0000000000000000",
    addr_last       => x"000000000000ffff",
    product         => (
    vendor_id       => x"0000000000000651", -- GSI
    device_id       => x"73aaa112",
    version         => x"00000001",
    date            => x"20180103",
    name            => "GSI:CNT_CHECKER    ")));

  component wb_cnt_checker is
    port (
      clk_i     : in  std_logic;
      rst_n_i   : in  std_logic;
      wb_o      : out t_wishbone_slave_out;
      wb_i      : in  t_wishbone_slave_in);
  end component;
end package wb_cnt_checker_pkg;
