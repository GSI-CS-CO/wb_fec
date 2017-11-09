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

library work;
use 

package fec_pkg is

    constant c_eth_hdr_len      : integer := 7;   -- 16 bit word
    constant c_eth_hdr_vlan_len : integer := 9;   -- 16 bit word
    constant c_eth_payload      : integer := 750; -- 16 bit word
    constant c_block_max_len    : integer := 188; -- 16 bit word
    constant c_FROM_PKT         : std_logic := '0';
    constant c_FROM_FIFO        : std_logic := '1';
    constant c_FIFO_ON          : std_logic := '1';
    constant c_FIFO_OFF         : std_logic := '1';
 
    -- Fabric
    constant c_wrf_width : integer := 16;
    subtype t_wrf_bus  is std_logic_vector(c_wrf_width - 1 downto 0);
    type t_wrf_bus_array is array (natural range <>) of t_wrf_source_in;

    -- Ethernet Header
    type t_eth_vlan is std_logic_vector(15 downto 0);
    type t_mac_addr is std_logic_vector(47 downto 0);
    type t_eth_type is std_logic_vector(15 downto 0);
    type t_eth_hdr  is std_logic_vector(111 downto 0);

    -- FEC Header
    type t_pkt_erasure_code is std_logic_vector(1 downto 0);
    type t_bit_erasure_code is std_logic_vector(1 downto 0);
    type t_enc_frame_id     is std_logic_vector(5 downto 0);
    type t_enc_frame_sub_id is std_logic_vector(2 downto 0);
    type t_reserved         is std_logic_vector(2 downto 0);

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
        name            => "GSI:FEC  ")));

  type t_enc_ctrl_reg is
    record
      signal fec_enc_en_golay : std_logic;
  end record;

  type t_enc_stat_reg is
    record
      signal fec_enc_err :  std_logic_vector(1 downto 0);
  end record;
    

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
     
    type t_eth_frame_header is
        record
        eth_src_addr    : t_mac_addr;
        eth_des_addr    : t_mac_addr;
        eth_vlan        : t_eth_vlan;
        eth_etherType   : t_eth_type;
    end record;
    
    constant c_eth_frame_header_default : t_eth_frame_header := (
        eth_src_addr   => x"abababababab",
        eth_des_addr   => x"ffffffffffff",
        eth_etherType  => x"0800");
   
    type t_fec_header is
        record    
        pkt_er_code     : t_pkt_erasure_code;
        bit_er_code     : t_bit_erasure_code;
        enc_frame_id    : t_enc_frame_id;
        enc_frame_subid : t_enc_frame_sub_id;
        reserved        : t_reserved;
    end record;

    constant c_fec_header : t_fec_header := (
        pkt_er_code     => x"1",
        bit_er_code     => x"1",
        enc_frame_id    => (others => '0'),
        enc_frame_subid => (others => '0'),
        reserved        => (others => '0'));
    end record;

  component wb_fec is
    generic (
        g_en_fec_enc    : boolean;
        g_en_fec_dec    : boolean;
        g_en_golay      : boolean;
        g_en_dec_time   : boolean);
    port ( 
        clk_i           : in  std_logic;
        rst_n_i         : in  std_logic;    
        ctrl_reg_i      : in  t_fec_ctrl_reg;
        stat_reg_o      : out t_fec_stat_reg;
        fec_timestamps_i: in  t_txtsu_timestamp;
        fec_tm_tai_i    : in  std_logic_vector(39 downto 0);
        fec_tm_cycle_i  : in  std_logic_vector(27 downto 0);        
        fec_dec_sink_i  : in  t_wrd_sink_in;
        fec_dec_sink_o  : in  t_wrd_sink_out;
        fec_dec_src_i   : in  t_wrf_source_in;
        fec_dec_src_o   : out t_wrf_source_out
        fec_enc_sink_i  : in  t_wrd_sink_in;
        fec_enc_sink_o  : in  t_wrd_sink_out;
        fec_enc_src_i   : in  t_wrf_source_in;
        fec_enc_src_o   : out t_wrf_source_out;
        wb_slave_o      : out t_wishbone_slave_out;
        wb_slave_i      : in  t_wishbone_slave_in);
  end component;

  component wb_fec_encoder is
    generic ( g_en_golay    : boolean);    
      port (
        clk_i         : in  std_logic;
        rst_n_i       : in  std_logic;     
        snk_i         : in  t_wrf_sink_in;
        snk_o         : out t_wrf_sink_out;
        src_i         : in  t_wrf_source_in;
        src_o         : out t_wrf_source_out;
        ctrl_reg      : out t_enc_ctrl_reg;
        stat_reg      : out t_enc_stat_reg);
  end component;

  component fec_encoder is
    generic (g_num_block : integer := 4);
    port (
      clk_i         : in  std_logic;
      rst_n_i       : in  std_logic;
      payload_i     : in  t_wrf_bus;
      stb_i         : in  std_logic;
      pl_len_i      : in  t_eth_type;
      enc_err_o     : out std_logic;
      stb_o         : out std_logic;
      enc_payload_o : out t_wrf_bus);
  end component;

  function f_calc_len_block (pl_len  : t_eth_type, integer  : c_div_num_block) return std_logic_vector;

end package fec_pkg;

package body fec_pkg is

  function f_calc_len_block (pl_len  : t_eth_type, integer  : c_div_num_block)
  return std_logic_vector is
    variable mod_block : t_eth_type;
    variable len_block : t_eth_type;
  begin
    mod_block <= pl_len and std_logic_vector(to_unsigned(c_div_num_block - 1,t_eth_type'length);
    len_block <= pl_len_i slr c_div_num_block when mond_block /= (others => '0') else
                (pl_len_i slr g_num_block) + 1;

    return  len_block;
  end function;
end fec_pkg;
