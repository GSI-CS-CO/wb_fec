library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;

package wrf_pkt_dropper_pkg is

  subtype t_drop_conf is std_logic_vector(3 downto 0);
  constant  c_XOR_0_1 : t_drop_conf := "0000";
  constant  c_XOR_0_2 : t_drop_conf := "0010";
  constant  c_XOR_0_3 : t_drop_conf := "0110";
  constant  c_XOR_1_2 : t_drop_conf := "0001";
  constant  c_XOR_1_3 : t_drop_conf := "0101";
  constant  c_XOR_2_3 : t_drop_conf := "0011";

  constant c_dropper_sdb : t_sdb_device := (
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
    device_id       => x"73c0b112",
    version         => x"00000001",
    date            => x"20180103",
    name            => "GSI:PKT_DROPPER    ")));

  type t_conf is record
    drop    : t_drop_conf;
    rnd     : std_logic;
    refresh : std_logic;
  end record;

  constant c_config : t_conf := (
    drop    =>  c_XOR_0_1,
    rnd     => '0',
    refresh => '1');

  component wrf_pkt_wb_slave is
    port (
      clk_i     : in  std_logic;
      rst_n_i   : in  std_logic;
      config_o  : out t_conf;
      wb_o      : out t_wishbone_slave_out;
      wb_i      : in  t_wishbone_slave_in);
  end component;

  component  wrf_pkt_dropper is
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
  end component;

  function f_pkt_drop (config : t_conf) return t_drop_conf ;

end package wrf_pkt_dropper_pkg;

package body wrf_pkt_dropper_pkg is

  function f_pkt_drop (config : t_conf) return t_drop_conf is
  begin
    return config.drop;
  end function;

end wrf_pkt_dropper_pkg;
