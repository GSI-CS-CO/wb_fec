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
  constant c_eth_hdr_len_width: integer := f_ceil_log2(c_eth_hdr_len);
  constant c_fec_hdr_len      : integer := 9;   -- 16 bit word
  constant c_fec_hdr_vlan_len : integer := 11;  -- 16 bit word
  constant c_eth_payload      : integer := 752; -- 16 bit word
  constant c_eth_pl_width     : integer := f_ceil_log2(c_eth_payload);
  constant c_eth_pkt          : integer := c_eth_hdr_len + c_eth_payload;
  constant c_eth_pkt_width    : integer := f_ceil_log2(c_eth_pkt);
  constant c_block_max_len    : integer := 188; -- 16 bit word
  --constant c_block_len_width  : integer := f_ceil_log2(c_block_max_len);
  constant c_block_len_width  : integer := 8;
  constant c_eth_pkt_len_widht: integer := 12;
  --constant c_FROM_STR         : std_logic := '0';
  --constant c_FROM_XOR         : std_logic := '1';
  constant c_FIFO_ON          : std_logic := '1';
  constant c_FIFO_OFF         : std_logic := '0';
  constant c_ENABLE           : std_logic := '1';
  constant c_DISABLE          : std_logic := '0';
  subtype t_fec_pkt_cnt is unsigned (3 downto 0);
  constant c_IDLE             : t_fec_pkt_cnt  := "0000";
  constant c_PKT_0_1          : t_fec_pkt_cnt  := "0001";
  constant c_PKT_0_2          : t_fec_pkt_cnt  := "0010";
  constant c_PKT_1_1          : t_fec_pkt_cnt  := "0011";
  constant c_PKT_1_2          : t_fec_pkt_cnt  := "0100";
  constant c_PKT_2_1          : t_fec_pkt_cnt  := "0101";
  constant c_PKT_2_2          : t_fec_pkt_cnt  := "0110";
  constant c_PKT_3_1          : t_fec_pkt_cnt  := "0111";
  constant c_PKT_3_2          : t_fec_pkt_cnt  := "1000";

  -- Decoder
  type t_next_op  is (IDLE, STORE, XOR_0_1, XOR_0_2, XOR_0_3, XOR_1_2, XOR_1_3, XOR_2_3);

  -- Fabric
  constant c_wrf_width      : integer := 16;
  constant c_wrf_adr_width  : integer := 2;
  subtype t_wrf_adr  is std_logic_vector(c_wrf_adr_width - 1 downto 0);
  subtype t_wrf_bus  is std_logic_vector(c_wrf_width - 1 downto 0);
  type t_wrf_bus_array is array (natural range <>) of t_wrf_bus;
  constant c_WRF_STATUS_FEC   : t_wrf_bus := x"0005"; -- vCRC = 0, vSMAC = 1, err = 1, isHP = 1
  constant c_WRF_OOB_FEC      : t_wrf_bus := c_WRF_OOB_TYPE_TX & x"aaa";

  -- FIFOs
  subtype t_read_block is std_logic_vector(3 downto 0);
  constant c_FIFO_0_1         : t_read_block := "0001";
  constant c_FIFO_Z           : t_read_block := "0000";
  constant c_FIFO_1_2         : t_read_block := "0110";
  constant c_FIFO_ALL         : t_read_block := "1111";

  -- Enc FIFOs
  constant c_out_fifo_size      : integer := 1024;
  constant c_fec_fifo_size      : integer := 256;
  constant c_wrf_fifo_size      : integer := 64;
  constant c_out_fifo_cnt_width : integer := f_log2_size(c_out_fifo_size);
  constant c_fec_fifo_cnt_width : integer := f_log2_size(c_fec_fifo_size);
  constant c_wrf_fifo_cnt_width : integer := f_log2_size(c_wrf_fifo_size);
  subtype t_fec_fifo_cnt_width  is std_logic_vector(c_fec_fifo_cnt_width - 1 downto 0);
  subtype t_out_fifo_cnt_width  is std_logic_vector(c_out_fifo_cnt_width - 1 downto 0);
  subtype t_wrf_fifo_cnt_width  is std_logic_vector(c_wrf_fifo_cnt_width - 1 downto 0);
  constant c_wrf_fifo_width     : integer := c_wrf_width + c_wrf_adr_width;
  subtype t_wrf_fifo_out        is std_logic_vector(c_wrf_fifo_width - 1 downto 0);
  type t_fifo_cnt_array     is array (natural range <>) of t_fec_fifo_cnt_width;
  subtype t_wrd_adr_width   is std_logic_vector(1 downto 0);

  -- Dec FIFOs
  subtype t_we_src     is unsigned(1 downto 0);
  type t_we_src_sel is array (natural range <>) of t_we_src;
  constant c_DEC_IDLE : t_we_src := "00";
  constant c_PAYLOAD  : t_we_src := "01";
  constant c_XOR_OP   : t_we_src := "10";
  constant c_LOOPBACK : t_we_src := "11";

  -- Ethernet Header
  subtype t_eth_vlan is std_logic_vector(15 downto 0);
  subtype t_mac_addr is std_logic_vector(47 downto 0);
  subtype t_eth_type is std_logic_vector(15 downto 0);
  subtype t_eth_hdr  is std_logic_vector(111 downto 0);

  -- FEC constant
  constant c_id_width       : integer := 6;
  constant c_subid_width    : integer := 3;
  constant c_fec_cnt_width  : integer := 32;
  constant c_erasure_code   : integer := 3;
  constant c_fec_reserved   : integer := 4;
  constant c_fec_padding    : integer := 6;
  constant c_fec_hdr_pkt_len: integer := 10;
  constant c_pad_cnt        : integer := 16;

  -- FEC Header
  subtype t_fec_hdr_reserved is std_logic_vector(c_fec_reserved - 1 downto 0);
  subtype t_fec_padding      is std_logic_vector(c_fec_padding - 1 downto 0);
  subtype t_fec_hdr_pkt_len  is std_logic_vector(c_fec_hdr_pkt_len - 1 downto 0);
  subtype t_erasure_code     is std_logic_vector(c_erasure_code - 1 downto 0);
  subtype t_enc_frame_id     is std_logic_vector(c_id_width - 1 downto 0);
  subtype t_enc_frame_sub_id is std_logic_vector(c_subid_width - 1 downto 0);
  subtype t_blk_len          is std_logic_vector(c_block_len_width - 1 downto 0);
  subtype t_block_len        is unsigned(c_block_len_width - 1 downto 0);
  subtype t_fec_pkt_len      is unsigned((2 * c_eth_pl_width) downto 0);
  subtype t_eth_pkt_len      is unsigned (c_eth_pkt_len_widht - 1 downto 0);
  subtype fec_code_range     is natural range 15 downto 13;
  subtype fec_id_range       is natural range 12 downto  7;
  subtype fec_subid_range    is natural range  6 downto  4;
  subtype reserved           is natural range  3 downto  0;

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

  type t_padding is record
    --pad_block   : std_logic_vector(c_fec_padding - 1 downto 0);
    --pad_pkt     : std_logic_vector(c_fec_padding - 1 downto 0);
    pad_block   : unsigned(c_fec_padding - 1 downto 0);
    pad_pkt     : unsigned(c_fec_padding - 1 downto 0);

  end record;

  constant c_padding : t_padding := (
    pad_block   => (others => '0'),
    pad_pkt     => (others => '0'));

  type t_time_code is record
    time_valid  : std_logic;
    tai         : std_logic_vector(39 downto 0);
    cycles      : std_logic_vector(27 downto 0);
  end record;

  constant c_time_code : t_time_code := (
    time_valid  => '0',
    tai         => (others => '0'),
    cycles      => (others => '0'));

  type t_dec_err  is
    record
    jumbo_frame : std_logic;
    dec_err     : std_logic;
  end record;

  constant c_dec_err : t_dec_err := (
    jumbo_frame => '0',
    dec_err     => '0');

  type t_fec_ctrl_reg is record
    fec_ctrl_refresh  : std_logic;
    fec_code          : t_erasure_code;
    --time_code         : t_time_code;
    fec_ethtype       : t_eth_type;
    fec_enc_en        : std_logic;
    fec_dec_en        : std_logic;
  end record;

  constant c_fec_ctrl_reg : t_fec_ctrl_reg := (
    fec_ctrl_refresh  => '0',
    fec_code          => "000", -- Simple Code
    --time_code         => c_time_code
    fec_ethtype       => x"cafe",
    fec_enc_en        => c_ENABLE,
    fec_dec_en        => c_ENABLE);

  type t_fec_stat_reg is record
    fec_enc_err : std_logic_vector(1 downto 0);
    fec_enc_cnt : std_logic_vector(c_fec_cnt_width - 1 downto 0);
    fec_dec_err : t_dec_err;
  end record;

  constant c_fec_stat_reg : t_fec_stat_reg := (
    fec_enc_err => (others => '0'),
    fec_enc_cnt => (others => '0'),
    fec_dec_err => c_dec_err);

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
    fec_code        : t_erasure_code;
    enc_frame_id    : t_enc_frame_id;
    enc_frame_subid : t_enc_frame_sub_id;
    reserved        : t_fec_hdr_reserved;
    eth_pkt_len     : t_fec_hdr_pkt_len;
    fec_padding_crc : t_fec_padding;
  end record;

  constant c_fec_header : t_fec_header := (
    fec_code        => (others => '0'),
    enc_frame_id    => (others => '0'),
    enc_frame_subid => (others => '0'),
    reserved        => (others => '0'),
    eth_pkt_len     => (others => '0'),
    fec_padding_crc => (others => '0'));

  type t_fec_id is
    record
    enc_frame_id    : t_enc_frame_id;
    enc_frame_subid : t_enc_frame_sub_id;
  end record;

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

  component fec_len_tx_pad is
    generic (
      g_num_block : integer := 4);
    port (
      clk_i           : in  std_logic;
      rst_n_i         : in  std_logic;
      pkt_len_i       : in  t_eth_type;
      fec_block_len_o : out t_block_len;
      padding_o       : out t_padding);
  end component;

  component fec_hdr_gen is
    generic (
      g_id_width    : integer;
      g_subid_width : integer;
      g_fec_type    : string);
    port (
      clk_i             : in  std_logic;
      rst_n_i           : in  std_logic;
      hdr_i             : in  t_wrf_bus;
      hdr_stb_i         : in  std_logic;
      fec_stb_i         : in  std_logic;
      fec_hdr_stb_i     : in  std_logic;
      fec_hdr_stall_i   : in  std_logic;
      fec_hdr_done_o    : out std_logic; 
      fec_hdr_o         : out t_wrf_bus;
      pkt_len_i         : in  t_eth_type;
      padding_i         : in  t_padding;
      enc_cnt_o         : out std_logic_vector(c_fec_cnt_width - 1 downto 0);
      ctrl_reg_i        : in  t_fec_ctrl_reg);
  end component;

  component wb_fec is
    generic (
      g_num_block   : integer := 4;
      g_en_fec_enc  : boolean;
      g_en_fec_dec  : boolean;
      g_en_golay    : boolean;
      g_en_dec_time : boolean);
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

  component wb_fec_decoder is
    generic (
      g_num_block   : integer := 4;
      g_en_golay    : boolean := FALSE);
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

  component fec_decoder is
    generic (
      g_num_block : integer := 4);
    port (
      clk_i             : in  std_logic;
      rst_n_i           : in  std_logic;
      fec_payload_i     : in  t_wrf_bus;
      fec_payload_stb_i : in  std_logic;
      fec_pad_stb_i     : in  std_logic;
      fec_stb_o         : out std_logic;
      pkt_payload_o     : out t_wrf_bus;
      pkt_payload_stb_o : out std_logic;
      eth_stream_o      : out std_logic;
      dat_stream_i      : in  std_logic;
      halt_streaming_i  : in  std_logic;
      pkt_dec_err_o     : out t_dec_err);
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
      payload_stb_i : in  std_logic;
      fec_stb_i     : in  std_logic;
      fec_enc_rd_i  : in  std_logic;
      block_len_i   : in  t_block_len;
      streaming_o   : out std_logic;
      enc_err_o     : out std_logic;
      enc_payload_o : out t_wrf_bus);
  end component;

  component fec_len_rx_pad is
    generic (
      g_num_block : integer := 4);
    port (
      clk_i           : in  std_logic;
      rst_n_i         : in  std_logic;
      fec_pad_stb_i   : in  std_logic;
      padding_crc_i   : in  t_fec_padding;
      pkt_len_i       : in  t_fec_hdr_pkt_len;
      fec_block_len_o : out t_block_len;
      padding_o       : out t_padding;
      pad_crc_err_o   : out std_logic);
  end component;

  -- encoder
  function f_calc_len_block (pl_len : t_eth_type; div_num_block, num_block : integer) return unsigned;
  function f_parse_eth (x : std_logic_vector) return t_eth_frame_header;
  function f_extract_eth (idx : unsigned; x : t_eth_hdr) return t_wrf_bus;
  -- decoder
  function f_pkt_len_conv (len_16bit_word : t_fec_hdr_pkt_len) return t_eth_pkt_len;
  function f_next_op(fec_pkt_rx : std_logic_vector; subid : t_enc_frame_sub_id) return t_next_op;
  function f_is_decoded(fec_pkt_rx : std_logic_vector; subid : t_enc_frame_sub_id) return std_logic;
  function f_update_pkt_rx( fec_pkt_rx : std_logic_vector;
                            subid : t_enc_frame_sub_id;
                            status_fec_id : std_logic) return std_logic_vector;
  function f_fifo_id (subid : t_enc_frame_sub_id)
    return t_we_src_sel;

  --function f_we_src_sel (next_op : t_next_op; subid : t_enc_frame_sub_id ; op_step : integer) return t_we_src_sel;
  function f_we_src_sel (next_op : t_next_op; subid : t_enc_frame_sub_id; len : unsigned; block_len : t_block_len)
            return t_we_src_sel;

  --function f_read_block (next_op : t_next_op; op_step : integer) return std_logic_vector;
  function f_read_block (next_op : t_next_op; len : unsigned; block_len : t_block_len) return std_logic_vector;
  function f_parse_fec_hdr (fec_hdr_bus : t_wrf_bus) return t_fec_header;
  function f_hotbit(num : integer) return std_logic_vector;
end package fec_pkg;

package body fec_pkg is

  -- encoder
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

    return len_block(c_block_len_width - 1 downto 0);
  end function;

  function f_parse_eth (x : std_logic_vector) return t_eth_frame_header is
   variable y : t_eth_frame_header;
   begin
     y.eth_src_addr  := x(111 downto 64);
     y.eth_des_addr  := x( 63 downto 16);
     y.eth_etherType := x( 15 downto  0);
    return y;
  end function;

  function f_extract_eth (idx : unsigned; x : t_eth_hdr)  return t_wrf_bus is
   variable y : t_wrf_bus;
   variable idx_i : integer range 0 to c_eth_hdr_len;
   begin
     idx_i := to_integer(idx);
     y := x((x'left - (idx_i * y'length)) downto (x'left - ((idx_i + 1) * y'length) + 1));
    return y;
  end function;

   -- decoder
  function f_pkt_len_conv (len_16bit_word : t_fec_hdr_pkt_len) return t_eth_pkt_len is
    variable pkt_len  : t_eth_pkt_len;
    variable tmp      : t_fec_hdr_pkt_len;
    begin
      pkt_len := "00" & unsigned(len_16bit_word);
      pkt_len := pkt_len sll 1;
    return pkt_len;
  end function;

  function f_fifo_id (subid : t_enc_frame_sub_id) 
    return t_we_src_sel is
  --TODO make it generic to g_num_pkt
    variable fifo_sel : t_we_src_sel (4 downto 0);
    begin
      fifo_sel  := (others => (others => '0'));
      case subid is
        when "000" => fifo_sel(2) := c_PAYLOAD;
        when "001" => fifo_sel(3) := c_PAYLOAD;
        when "010" => fifo_sel(0) := c_PAYLOAD;
        when "011" => fifo_sel(1) := c_PAYLOAD;
        when others => fifo_sel   := (others => (others => '0'));
      end case;
    return fifo_sel;
  end function;

  function f_we_src_sel (next_op : t_next_op; subid : t_enc_frame_sub_id;
                         len : unsigned; block_len : t_block_len) return t_we_src_sel is
    variable we_src_sel : t_we_src_sel (4 downto 0);
    begin
      we_src_sel := (others => (others => '0'));
      case next_op is
        when XOR_0_1  =>
          if (len <= block_len - 1) then
            we_src_sel(1) := c_XOR_OP;
            we_src_sel(4) := c_XOR_OP;
          elsif (len <= (2 * block_len) - 1) then
            we_src_sel    := f_fifo_id(subid);
            we_src_sel(0) := c_XOR_OP;
         end if;
        when XOR_0_2 =>
          if (len <= block_len - 1) then
            we_src_sel(3) := c_XOR_OP;
          elsif (len <= (2 * block_len) - 1) then
            we_src_sel    := f_fifo_id(subid);
            we_src_sel(1) := c_XOR_OP;
          end if;
        when XOR_0_3 =>
          if (len <= block_len - 1) then
            we_src_sel(4) := c_XOR_OP;
          elsif (len <= (2 * block_len) - 1) then
            we_src_sel    := f_fifo_id(subid);
            we_src_sel(3) := c_XOR_OP;
            we_src_sel(0) := c_XOR_OP;
          end if;
        when XOR_1_2 =>
          if (len <= block_len - 1) then
            we_src_sel(2) := c_XOR_OP;
            we_src_sel(4) := c_XOR_OP;
          elsif (len <= (2 * block_len) - 1) then
            we_src_sel    := f_fifo_id(subid);
            we_src_sel(1) := c_XOR_OP;
          end if;
        when XOR_1_3 =>
          if (len <= block_len - 1) then
            we_src_sel(0) := c_XOR_OP;
            we_src_sel(4) := c_XOR_OP;
          elsif (len <= (2 * block_len) - 1) then
            we_src_sel    := f_fifo_id(subid);
            we_src_sel(2) := c_XOR_OP;
          end if;
        when XOR_2_3 =>
          if (len <= block_len - 1) then
            we_src_sel(3) := c_XOR_OP;
            we_src_sel(4) := c_XOR_OP;
          elsif (len <= (2 * block_len) - 1) then
            we_src_sel    := f_fifo_id(subid);
            we_src_sel(2) := c_XOR_OP;
          end if;
        when others   => we_src_sel := (others => (others => '0'));
      end case;
    return we_src_sel;
  end function;

  function f_read_block (next_op : t_next_op; len : unsigned; block_len : t_block_len) return std_logic_vector is
    variable read_block : std_logic_vector (4 downto 0);
    begin
      read_block  := (others => '0');
      case next_op is
        when XOR_0_1  =>
          if (len <= block_len - 1) then
            read_block(2) := c_FIFO_ON;
          elsif (len <= (2 * block_len) - 1) then
            read_block(4) := c_FIFO_ON;
          end if;
        when XOR_0_2 =>
          if (len <= block_len - 1) then
            read_block(2) := c_FIFO_ON;
          elsif (len <= (2 * block_len) - 1) then
          end if;
        when XOR_0_3 =>
          if (len <= block_len - 1) then
          elsif (len <= (2 * block_len) - 1) then
            read_block(4) := c_FIFO_ON;
          end if;

        when XOR_1_2 =>
          if (len <= block_len - 1) then
            read_block(3) := c_FIFO_ON;
          elsif (len <= (2 * block_len) - 1) then
            read_block(4) := c_FIFO_ON;
          end if;
        when XOR_1_3 =>
          if (len <= block_len - 1) then
            read_block(3) := c_FIFO_ON;
          elsif (len <= (2 * block_len) - 1) then
          end if;
        when XOR_2_3 =>
          if (len <= block_len - 1) then
            read_block(0) := c_FIFO_ON;
          elsif (len <= (2 * block_len) - 1) then
            read_block(4) := c_FIFO_ON;
          end if;
        when others   => read_block := (others => '0');
      end case;
    return read_block;
  end function;

--  function f_we_src_sel (next_op : t_next_op; subid : t_enc_frame_sub_id; op_step : integer) return t_we_src_sel is
--
--    variable we_src_sel : t_we_src_sel (3 downto 0);
--    begin
--      we_src_sel := (others => (others => '0'));
--      case next_op is
--        when IDLE     =>
--        when STORE    =>
--          if (op_step = 0) then
--          elsif (op_step = 1) then
--            we_src_sel := f_fifo_id(subid);
--          end if;
--        when XOR_0_1  =>
--          if (op_step = 0) then
--          elsif (op_step = 1) then
--            we_src_sel(1) := c_XOR_OP;
--            we_src_sel(2) := c_LOOPBACK;
--          elsif (op_step = 2) then
--            we_src_sel    := f_fifo_id(subid);
--            we_src_sel(0) := c_XOR_OP;
--            we_src_sel(1) := c_LOOPBACK;
--         end if;
--        when others   => we_src_sel := (others => (others => '0'));
--      end case;
--    return we_src_sel;
--  end function;
--
--  function f_read_block (next_op : t_next_op; op_step : integer) return std_logic_vector is
--
--    variable read_block : std_logic_vector (3 downto 0);
--    begin
--      read_block  := (others => '0');
--      case next_op is
--        when IDLE     =>
--        when STORE    =>
--        when XOR_0_1  =>
--          if (op_step = 0) then
--          elsif (op_step = 1) then
--            read_block(2) := c_FIFO_ON;
--          elsif (op_step = 2) then
--            read_block(1) := c_FIFO_ON;
--          end if;
--        when others   => read_block := (others => '0');
--      end case;
--    return read_block;
--  end function;

  function f_next_op (fec_pkt_rx : std_logic_vector; subid : t_enc_frame_sub_id) return t_next_op is
  --TODO make it generic to g_num_pkt
    variable fec_pkt_update : std_logic_vector (3 downto 0) := (others => '0');
    variable int_subid      : integer range 0 to 3 := 0;
    variable is_decoded     : std_logic;
    variable next_op        : t_next_op;
    begin
    --TODO check if nested functions f_update_pkt_rx
      fec_pkt_update  := fec_pkt_rx;
      int_subid       := to_integer(unsigned(subid));
      fec_pkt_update(int_subid) := '1';

      case fec_pkt_update is
        when "0000" => next_op := IDLE;
        when "0011" => next_op := XOR_0_1;
        when "0101" => next_op := XOR_0_2;
        when "1001" => next_op := XOR_0_3;
        when "0110" => next_op := XOR_1_2;
        when "1010" => next_op := XOR_1_3;
        when "1100" => next_op := XOR_2_3;
        when others => next_op := STORE;
      end case;
    return next_op;
  end function;

  function f_is_decoded (fec_pkt_rx : std_logic_vector; subid : t_enc_frame_sub_id) return std_logic is
  --TODO make it generic to g_num_pkt
    variable fec_pkt_update : std_logic_vector (3 downto 0) := (others => '0');
    variable int_subid      : integer range 0 to 3 := 0;
    variable is_decoded     : std_logic;
    begin
    --TODO check if nested functions f_update_pkt_rx
      fec_pkt_update  := fec_pkt_rx;
      int_subid       := to_integer(unsigned(subid));
      fec_pkt_update(int_subid) := '1';

      case fec_pkt_update is
        when  "0000"  => is_decoded := '0';
        when  "0001"  => is_decoded := '0';
        when  "0010"  => is_decoded := '0';
        when  "0100"  => is_decoded := '0';
        when  "1000"  => is_decoded := '0';
        when others   => is_decoded := '1'; -- rx more than 1 packet
      end case;
    return is_decoded;
  end function;

  function f_update_pkt_rx (fec_pkt_rx : std_logic_vector;
                            subid : t_enc_frame_sub_id;
                            status_fec_id : std_logic) return std_logic_vector is

    variable fec_pkt_update : std_logic_vector (3 downto 0) := (others => '0');
    variable int_subid      : integer range 0 to 3 := 0;
    begin
      int_subid := to_integer(unsigned(subid));

      if (status_fec_id = '0') then --same FEC ID, get the current value
        fec_pkt_update  := fec_pkt_rx;
      end if;

      fec_pkt_update(int_subid) := '1';

    return fec_pkt_update;
  end function;

  function f_parse_fec_hdr (fec_hdr_bus : t_wrf_bus) return t_fec_header is
      variable fec_hdr : t_fec_header;
    begin
      fec_hdr.fec_code        := fec_hdr_bus (fec_code_range);
      fec_hdr.enc_frame_id    := fec_hdr_bus (fec_id_range);
      fec_hdr.enc_frame_subid := fec_hdr_bus (fec_subid_range);
      fec_hdr.reserved        := fec_hdr_bus (reserved);
      fec_hdr.eth_pkt_len     := (others => '0');
      fec_hdr.fec_padding_crc := (others => '0');
    return fec_hdr;
  end function;

  function f_hotbit(num : integer) return std_logic_vector is
      variable hotbit  : std_logic_vector(4 downto 0) := (others => '0');
    begin
      for i in 0 to 4 loop
        if (i = num) then
          hotbit(i) := '1';
        end if;
      end loop;
      return hotbit;
  end function;
end fec_pkg;
