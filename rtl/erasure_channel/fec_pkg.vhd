--! @file fec_pkg.vhd
--! @brief package for the fec code
--! @author C.Prados <cprados@mailfence.com>
--!
--! package for the fec project
--! 
--! See the file "LICENSE" for the full license governing this code.
--!-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.genram_pkg.all;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;

package fec_pkg is

  constant c_eth_hdr_len      : integer := 7;   -- 16 bit word
  constant c_eth_hdr_vlan_len : integer := 9;   -- 16 bit word
  constant c_fec_hdr_len      : integer := 8;
  constant c_fec_hdr_vlan_len : integer := 10;
  constant c_eth_payload      : integer := 750; -- 16 bit word
  constant c_eth_pkt          : integer := c_eth_hdr_len + c_eth_payload;
  constant c_eth_pl_width     : integer := f_ceil_log2(c_eth_payload);
  constant c_block_max_len    : integer := 188; -- 16 bit word
  constant c_FROM_PKT         : std_logic := '0';
  constant c_FROM_FIFO        : std_logic := '1';
  constant c_FIFO_ON          : std_logic := '1';
  constant c_FIFO_OFF         : std_logic := '1';
  constant c_ENABLE           : std_logic := '1';
  constant c_DISABLE          : std_logic := '0';

  -- Fabric
  constant c_wrf_width : integer := 16;
  subtype t_wrf_bus  is std_logic_vector(c_wrf_width - 1 downto 0);
  type t_wrf_bus_array is array (natural range <>) of t_wrf_bus;

  -- Enc FIFOs
  constant c_fifo_cnt_width   : integer := f_ceil_log2(c_block_max_len);
  subtype t_fifo_cnt_width  is std_logic_vector(c_fifo_cnt_width - 1 downto 0);
  subtype te_fifo_cnt_width  is std_logic_vector(8 downto 0);
  type t_fifo_cnt_array is array (natural range <>) of t_fifo_cnt_width;

  -- Ethernet Header
  subtype t_eth_vlan is std_logic_vector(15 downto 0);
  subtype t_mac_addr is std_logic_vector(47 downto 0);
  subtype t_eth_type is std_logic_vector(15 downto 0);
  subtype t_eth_hdr  is std_logic_vector(111 downto 0);

  -- FEC Header
  subtype t_pkt_erasure_code is std_logic_vector(1 downto 0);
  subtype t_bit_erasure_code is std_logic_vector(1 downto 0);
  subtype t_enc_frame_id     is std_logic_vector(5 downto 0);
  subtype t_enc_frame_sub_id is std_logic_vector(2 downto 0);
  subtype t_reserved         is std_logic_vector(2 downto 0);
  subtype t_block_len        is unsigned (c_eth_pl_width - 1 downto 0);

  -- FEC Counters
  constant c_id_width       : integer := 6;
  constant c_subid_width    : integer := 3;
  constant c_fec_cnt_width  : integer := 32;

  constant c_fec_sdb : t_sdb_device := (
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
    device_id       => x"73f9bb13",
    version         => x"00000001",
    date            => x"20170303",
    name            => "GSI:FEC            ")));

  type t_time_code is record
    time_valid  : std_logic;
    tai         : std_logic_vector(39 downto 0);
    cycles      : std_logic_vector(27 downto 0);
  end record;

  constant c_time_code : t_time_code := (
    time_valid  => '0',
    tai         => (others => '0'),
    cycles      => (others => '0'));

  type t_fec_ctrl_reg is record
    fec_ctrl_refresh  : std_logic;
    fec_pkt_er_code   : std_logic_vector(1 downto 0);
    fec_bit_er_code   : std_logic_vector(1 downto 0);
    --time_code         : t_time_code;
    fec_enc_en_golay  : std_logic;
    fec_enc_en        : std_logic;
  end record;

  constant c_fec_ctrl_reg : t_fec_ctrl_reg := (
    fec_ctrl_refresh  => '0',
    fec_pkt_er_code   => "01", -- Simple Code
    fec_bit_er_code   => "00", -- No Code
    --time_code         => c_time_code
    fec_enc_en_golay  => c_DISABLE,
    fec_enc_en        => c_ENABLE);

  type t_fec_stat_reg is record
    fec_enc_err :  std_logic_vector(1 downto 0);
    fec_enc_cnt :  std_logic_vector(c_fec_cnt_width - 1 downto 0);
  end record;

  constant c_fec_stat_reg : t_fec_stat_reg := (
    fec_enc_err => (others => '0'),
    fec_enc_cnt => (others => '0'));
    
  type t_frame_fsm  is (  
      INIT_HDR,
      ETH_HDR,
      PAY_LOAD,
      OOB,
      IDLE);

  type t_frame_enc_fsm is (
      INIT_HDR,
      ETH_HDR,
      FEC_HDR,
      PAY_LOAD,
      OOB,
      IDLE);

  type t_eth_frame_header is
      record
      eth_src_addr    : t_mac_addr;
      eth_des_addr    : t_mac_addr;
      eth_etherType   : t_eth_type;
  end record;
   
  type t_eth_vlan_frame_header is
      record
      eth_src_addr    : t_mac_addr;
      eth_des_addr    : t_mac_addr;
      eth_vlan        : t_eth_vlan;
      eth_etherType   : t_eth_type;
  end record;
  
  constant c_eth_frame_header_default : t_eth_frame_header := (
      eth_src_addr   => x"000000000000",
      eth_des_addr   => x"000000000000",
      eth_etherType  => x"0000");
 
  type t_fec_header is
      record    
      pkt_er_code     : t_pkt_erasure_code;
      bit_er_code     : t_bit_erasure_code;
      enc_frame_id    : t_enc_frame_id;
      enc_frame_subid : t_enc_frame_sub_id;
      reserved        : t_reserved;
  end record;

  constant c_fec_header : t_fec_header := (
      pkt_er_code     => "01",
      bit_er_code     => "00",
      enc_frame_id    => (others => '0'),
      enc_frame_subid => (others => '0'),
      reserved        => (others => '0'));

  component wb_slave_fec is
    port (
      clk_i          : in  std_logic;
      rst_n_i        : in  std_logic;
      wb_slave_i     : in  t_wishbone_slave_in;
      wb_slave_o     : out t_wishbone_slave_out;
      fec_stat_reg_i : in  t_fec_stat_reg;
      fec_ctrl_reg_o : out t_fec_ctrl_reg;
      time_code_i    : in  t_time_code);
  end component;

  component fec_hdr_gen is
    generic (
      g_id_width    : integer;
      g_subid_width : integer);
    port (
      clk_i             : in  std_logic;
      rst_n_i           : in  std_logic;
      hdr_i             : in  t_wrf_bus;
      hdr_stb_i         : in  std_logic;
      block_len_i       : in  t_block_len; 
      fec_stb_i         : in  std_logic;
      fec_hdr_stb_i     : in  std_logic;
      fec_hdr_o         : out t_wrf_bus;      
      enc_cnt_o         : out std_logic_vector(c_fec_cnt_width - 1 downto 0);
      ctrl_reg_i        : in  t_fec_ctrl_reg);
  end component;

  component wb_fec is
    generic (
      g_num_block   : integer := 4;
      g_en_fec_enc    : boolean;
      g_en_fec_dec    : boolean;
      g_en_golay      : boolean;
      g_en_dec_time   : boolean);
    port ( 
      clk_i           : in  std_logic;
      rst_n_i         : in  std_logic;    
      fec_timestamps_i: in  t_txtsu_timestamp;
      fec_tm_tai_i    : in  std_logic_vector(39 downto 0);
      fec_tm_cycle_i  : in  std_logic_vector(27 downto 0);        
      fec_dec_sink_i  : in  t_wrf_sink_in;
      fec_dec_sink_o  : out t_wrf_sink_out;
      fec_dec_src_i   : in  t_wrf_source_in;
      fec_dec_src_o   : out t_wrf_source_out;
      fec_enc_sink_i  : in  t_wrf_sink_in;
      fec_enc_sink_o  : out t_wrf_sink_out;
      fec_enc_src_i   : in  t_wrf_source_in;
      fec_enc_src_o   : out t_wrf_source_out;
      wb_slave_o      : out t_wishbone_slave_out;
      wb_slave_i      : in  t_wishbone_slave_in);
  end component;

  component wb_fec_encoder is
    generic (
      g_num_block   : integer := 4;
      g_en_golay    : boolean);    
    port (
      clk_i         : in  std_logic;
      rst_n_i       : in  std_logic;     
      snk_i         : in  t_wrf_sink_in;
      snk_o         : out t_wrf_sink_out;
      src_i         : in  t_wrf_source_in;
      src_o         : out t_wrf_source_out;
      ctrl_reg_i    : in  t_fec_ctrl_reg;
      stat_reg_o    : out t_fec_stat_reg);
  end component;

  component fec_encoder is
    generic (g_num_block : integer := 4);
    port (
      clk_i         : in  std_logic;
      rst_n_i       : in  std_logic;
      payload_i     : in  t_wrf_bus;
      block_len_i   : in  t_block_len;
      stb_i         : in  std_logic;
      enc_err_o     : out std_logic;
      stb_o         : out std_logic;
      enc_payload_o : out t_wrf_bus);
  end component;

  function f_calc_len_block (pl_len : t_eth_type; div_num_block, num_block : integer) return unsigned;
  function f_parse_eth (x : std_logic_vector) return t_eth_frame_header;
  function f_extract_eth (idx : integer; x : std_logic_vector) return t_wrf_bus;

end package fec_pkg;

package body fec_pkg is

  function f_calc_len_block (pl_len  : t_eth_type; div_num_block, num_block : integer) return unsigned is
    variable mod_block : unsigned(t_eth_type'left downto 0) := (others => '0');
    variable len_block : unsigned(t_eth_type'left downto 0) := (others => '0');
    variable upl_len   : unsigned(t_eth_type'left downto 0) := (others => '0');
  begin
    upl_len := unsigned(pl_len);
    len_block := upl_len srl div_num_block;

    mod_block := upl_len and to_unsigned(num_block - 1,t_eth_type'length);

    if (mod_block /= (mod_block'range => '0')) then
      len_block := len_block + 1;
    end if;

    return len_block(c_eth_pl_width - 1 downto 0);
  end function;

  function f_parse_eth (x : std_logic_vector) return t_eth_frame_header is
    variable y : t_eth_frame_header;
    begin
      y.eth_src_addr  := x(111 downto 64);
      y.eth_des_addr  := x( 63 downto 16);
      y.eth_etherType := x( 15 downto  0);    
     return y;
   end function;  
   
   function f_extract_eth (idx : integer; x : std_logic_vector) return t_wrf_bus is
    variable y : t_wrf_bus;
    begin
      y := x((x'left - (idx * y'length)) downto (x'left - ((idx + 1) * y'length) + 1));
     return y;
   end function;

end fec_pkg;
