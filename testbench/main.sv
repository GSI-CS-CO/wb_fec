`include "if_wb_master.svh"
`include "if_wb_slave.svh"
`include "wb_packet_source.svh"
`include "wb_packet_sink.svh"

`timescale 1ps/1ps

module main;

  /* clock & reset generator */   
   reg clk_sys  = 1'b0;
   reg rst_n    = 1'b0;

  /* WB accessors */
  CWishboneAccessor acc_wrc, acc_ep, acc_lbk;

  /* Fabrics */
  IWishboneMaster #(2,16) WB_wrc_src (clk_sys, rst_n);
  IWishboneSlave  #(2,16) WB_wrc_snk (clk_sys, rst_n);
  IWishboneMaster #(2,16) WB_ep_src  (clk_sys, rst_n);
  IWishboneSlave  #(2,16) WB_ep_snk  (clk_sys, rst_n);

  /* Fabrics accessors */
  WBPacketSource wrc_src, ep_src;
  WBPacketSink   wrc_snk, ep_snk;

  always #4ns clk_sys <= ~clk_sys;
   initial begin
      repeat(3) @(posedge clk_sys);
      rst_n <= 1'b1;
   end





