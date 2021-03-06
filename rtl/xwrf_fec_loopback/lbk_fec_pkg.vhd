---------------------------------------------------------------------------------------
-- Title          : Wishbone slave core for WRF Loopback
---------------------------------------------------------------------------------------
-- File           : lbk_pkg.vhd
-- Author         : auto-generated by wbgen2 from lbk_wishbone.wb
-- Created        : Wed Oct 28 15:10:33 2015
-- Standard       : VHDL'87
---------------------------------------------------------------------------------------
-- THIS FILE WAS GENERATED BY wbgen2 FROM SOURCE FILE lbk_wishbone.wb
-- DO NOT HAND-EDIT UNLESS IT'S ABSOLUTELY NECESSARY!
---------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package lbk_fec_wbgen2_pkg is
  
  
  -- Input registers (user design -> WB slave)
  
  type t_lbk_in_registers is record
    dmac_l_i                                 : std_logic_vector(31 downto 0);
    dmac_h_i                                 : std_logic_vector(15 downto 0);
    rcv_cnt_i                                : std_logic_vector(31 downto 0);
    drp_cnt_i                                : std_logic_vector(31 downto 0);
    fwd_cnt_i                                : std_logic_vector(31 downto 0);
    end record;
  
  constant c_lbk_in_registers_init_value: t_lbk_in_registers := (
    dmac_l_i => (others => '0'),
    dmac_h_i => (others => '0'),
    rcv_cnt_i => (others => '0'),
    drp_cnt_i => (others => '0'),
    fwd_cnt_i => (others => '0')
    );
    
    -- Output registers (WB slave -> user design)
    
    type t_lbk_out_registers is record
      mcr_ena_o                                : std_logic;
      mcr_clr_o                                : std_logic;
      mcr_fdmac_o                              : std_logic;
      dmac_l_o                                 : std_logic_vector(31 downto 0);
      dmac_l_load_o                            : std_logic;
      dmac_h_o                                 : std_logic_vector(15 downto 0);
      dmac_h_load_o                            : std_logic;
      rcv_cnt_o                                : std_logic_vector(31 downto 0);
      rcv_cnt_load_o                           : std_logic;
      drp_cnt_o                                : std_logic_vector(31 downto 0);
      drp_cnt_load_o                           : std_logic;
      fwd_cnt_o                                : std_logic_vector(31 downto 0);
      fwd_cnt_load_o                           : std_logic;
      end record;
    
    constant c_lbk_out_registers_init_value: t_lbk_out_registers := (
      mcr_ena_o => '0',
      mcr_clr_o => '0',
      mcr_fdmac_o => '0',
      dmac_l_o => (others => '0'),
      dmac_l_load_o => '0',
      dmac_h_o => (others => '0'),
      dmac_h_load_o => '0',
      rcv_cnt_o => (others => '0'),
      rcv_cnt_load_o => '0',
      drp_cnt_o => (others => '0'),
      drp_cnt_load_o => '0',
      fwd_cnt_o => (others => '0'),
      fwd_cnt_load_o => '0'
      );
    function "or" (left, right: t_lbk_in_registers) return t_lbk_in_registers;
    function f_x_to_zero (x:std_logic) return std_logic;
    function f_x_to_zero (x:std_logic_vector) return std_logic_vector;
end package;

package body lbk_fec_wbgen2_pkg is
function f_x_to_zero (x:std_logic) return std_logic is
begin
if x = '1' then
return '1';
else
return '0';
end if;
end function;
function f_x_to_zero (x:std_logic_vector) return std_logic_vector is
variable tmp: std_logic_vector(x'length-1 downto 0);
begin
for i in 0 to x'length-1 loop
if x(i) = '1' then
tmp(i):= '1';
else
tmp(i):= '0';
end if; 
end loop; 
return tmp;
end function;
function "or" (left, right: t_lbk_in_registers) return t_lbk_in_registers is
variable tmp: t_lbk_in_registers;
begin
tmp.dmac_l_i := f_x_to_zero(left.dmac_l_i) or f_x_to_zero(right.dmac_l_i);
tmp.dmac_h_i := f_x_to_zero(left.dmac_h_i) or f_x_to_zero(right.dmac_h_i);
tmp.rcv_cnt_i := f_x_to_zero(left.rcv_cnt_i) or f_x_to_zero(right.rcv_cnt_i);
tmp.drp_cnt_i := f_x_to_zero(left.drp_cnt_i) or f_x_to_zero(right.drp_cnt_i);
tmp.fwd_cnt_i := f_x_to_zero(left.fwd_cnt_i) or f_x_to_zero(right.fwd_cnt_i);
return tmp;
end function;
end package body;
