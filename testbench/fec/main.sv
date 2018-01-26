// @file main.sv
// @brief Testbench for the WB_FEC
// @author C.Prados <c.prados@gsi.de> <bradomyn@gmail.com>
//
// This test-bench is inspired by the test-benches of the WR Core.
//
// See the file "LICENSE" for the full license governing this code.
//---------------------------------------------------------------------------
// This testbench produces pkts with random payload at regular intervals.
// The WB_FEC encodes 1 packet into 4 packets and sends it to the WR Fabric
// Loop Back. Before the packets reaches this module there is a module
// which simulates the losses of packets in a fiber optic. This module it
// is configurable and to drop specific packets out of the 4 encoded packets.
// Finally the WR Fabric Loop Back sends back the encoded frames to the WB_FEC
// decoder, which decodes the encoded packets.
//
// The payload of the original packets are stored and compared with the payload
// of the decoded packet. If the length or payload of the decoded packet is not
// the same the payload and length of the decoded packet is printed.
//
// See WR_TEST_BENCH.pdf for a visual representation of the testbench

`timescale 1ns/1ps

`include "tbi_utils.sv"

`include "simdrv_defs.svh"
`include "if_wb_master.svh"
`include "if_wb_slave.svh"
`include "wb_packet_source.svh"
`include "wb_packet_sink.svh"
`include "if_wb_link.svh"
`include "functions.svh"
`include "fec_regs.v"
`include "lbk_regs.v"

`define true 1
`define false 0

module main;

  wire clk_ref;
  wire clk_sys;
  wire rst_n;

  int seed;
  uint32_t data;
  int length = 0;
  int i = 0;
  int j = 0;
  int cnt = 0;
  int err = 0;
  int send_bogus_etype = 0;
  int dropper_en = 1;

  EthPacket tx_pk[$];
  EthPacket rx_pk;

  integer f;
  integer sig_low, toggletime;

  // set of wires between ENC and DEC
  wire enc_src_cyc;
  wire enc_src_stb;
  wire [1:0] enc_src_sel;
  wire [1:0] enc_src_adr;
  wire [15:0]enc_src_dat;
  wire enc_src_ack;
  wire enc_src_stall;
  wire enc_src_err;

  wire enc_snk_cyc;
  wire enc_snk_stb;
  wire [1:0] enc_snk_sel;
  wire [1:0] enc_snk_adr;
  wire [15:0]enc_snk_dat;
  wire enc_snk_ack;
  wire enc_snk_stall;
  wire enc_snk_err;


  wire dec_snk_cyc;
  wire dec_snk_stb;
  wire [1:0] dec_snk_sel;
  wire [1:0] dec_snk_adr;
  wire [15:0]dec_snk_dat;
  wire dec_snk_ack;
  wire dec_snk_stall;
  wire dec_snk_err;

	/* WB masters */
  IWishboneMaster WB_fec (clk_ref, rst_n);
  IWishboneMaster WB_lbk (clk_ref, rst_n);
  IWishboneMaster WB_drop (clk_ref, rst_n);

	/* WB accessors */
  CWishboneAccessor acc_fec, acc_lbk, acc_drop;

	/* Fabrics */
  IWishboneSlave  #(2,16) dec_snk (clk_ref, rst_n);
  IWishboneMaster #(2,16) enc_src (clk_ref, rst_n);

	/* Fabrics accessors */
  WBPacketSource fec_src;
  WBPacketSink   fec_snk;

  tbi_clock_rst_gen
  #(
    .g_rbclk_period(8000))
  clkgen(
    .clk_ref_o(clk_ref),
    .clk_sys_o(clk_sys),
    .phy_rbclk_o(phy_rbclk),
    .rst_n_o(rst_n)
  );

  xwb_fec #(
    .g_en_fec_enc(`true),
    .g_en_fec_dec(`true),
    .g_en_golay(`false),
    .g_en_dec_time(`false))
  XWB_FEC_ENC (
    .clk_i(clk_ref),
    .rst_n_i(rst_n),

    .fec_dec_sink_cyc(dec_snk_cyc),
		.fec_dec_sink_stb(dec_snk_stb),
		.fec_dec_sink_we(dec_snk_we),
		.fec_dec_sink_sel(dec_snk_sel),
		.fec_dec_sink_adr(dec_snk_adr),
		.fec_dec_sink_dat(dec_snk_dat),
		.fec_dec_sink_stall(dec_snk_stall),
		.fec_dec_sink_ack(dec_snk_ack),

		.fec_dec_src_cyc(dec_snk.slave.cyc),
		.fec_dec_src_stb(dec_snk.slave.stb),
		.fec_dec_src_we(dec_snk.slave.we),
		.fec_dec_src_sel(dec_snk.slave.sel),
		.fec_dec_src_adr(dec_snk.slave.adr),
		.fec_dec_src_dat(dec_snk.slave.dat_i),
		.fec_dec_src_stall(dec_snk.slave.stall),
		.fec_dec_src_ack(dec_snk.slave.ack),

    .fec_enc_sink_cyc(enc_src.master.cyc),
    .fec_enc_sink_stb(enc_src.master.stb),
    .fec_enc_sink_we(enc_src.master.we),
    .fec_enc_sink_sel(enc_src.master.sel),
    .fec_enc_sink_adr(enc_src.master.adr),
    .fec_enc_sink_dat(enc_src.master.dat_o),
    .fec_enc_sink_stall(enc_src.master.stall),
    .fec_enc_sink_ack(enc_src.master.ack),

		.fec_enc_src_cyc(enc_snk_cyc),
		.fec_enc_src_stb(enc_snk_stb),
		.fec_enc_src_we(enc_snk_we),
		.fec_enc_src_sel(enc_snk_sel),
		.fec_enc_src_adr(enc_snk_adr),
		.fec_enc_src_dat(enc_snk_dat),
		.fec_enc_src_stall(enc_snk_stall),
		.fec_enc_src_ack(enc_snk_ack),

    .wb_slave_cyc(WB_fec.master.cyc),
		.wb_slave_stb(WB_fec.master.stb),
		.wb_slave_we(WB_fec.master.we),
		.wb_slave_sel(WB_fec.master.sel),
		.wb_slave_adr(WB_fec.master.adr),
		.wb_slave_dat_i(WB_fec.master.dat_o),
		.wb_slave_dat_o(WB_fec.master.dat_i),
		.wb_slave_ack(WB_fec.master.ack),
		.wb_slave_stall(WB_fec.master.stall));

  xwrf_pkt_dropper #()
  XWRF_PKT(
    .clk_i                    (clk_ref),
    .rst_n_i                  (rst_n),

    .snk_ack                  (enc_snk_ack),
    .snk_stall                (enc_snk_stall),
    .snk_adr                  (enc_snk_adr),
    .snk_dat                  (enc_snk_dat),
    .snk_cyc                  (enc_snk_cyc),
    .snk_stb                  (enc_snk_stb),
    .snk_we                   (enc_snk_we),
    .snk_sel                  (enc_snk_sel),

    .src_ack                  (enc_src_ack),
    .src_stall                (enc_src_stall),
    .src_adr                  (enc_src_adr),
    .src_dat                  (enc_src_dat),
    .src_cyc                  (enc_src_cyc),
    .src_stb                  (enc_src_stb),
    .src_we                   (enc_src_we),
    .src_sel                  (enc_src_sel),

    .wb_ack                   (WB_drop.master.ack),
    .wb_stall                 (WB_drop.master.stall),
    .wb_cyc                   (WB_drop.master.cyc),
    .wb_stb                   (WB_drop.master.stb),
    .wb_adr                   (WB_drop.master.adr),
    .wb_sel                   (WB_drop.master.sel),
    .wb_we                    (WB_drop.master.we),
    .wb_dat_o                 (WB_drop.master.dat_i),
    .wb_dat_i                 (WB_drop.master.dat_o));

  wrf_loopback #(
    .g_interface_mode           (PIPELINED),
    .g_address_granularity      (BYTE))
  WRF_LBK (
    .clk_sys_i                  (clk_ref),
    .rst_n_i                    (rst_n),
    .snk_cyc_i                  (enc_src_cyc),
    .snk_stb_i                  (enc_src_stb),
    .snk_we_i                   (enc_src_we),
    .snk_sel_i                  (enc_src_sel),
    .snk_adr_i                  (enc_src_adr),
    .snk_dat_i                  (enc_src_dat),
    .snk_ack_o                  (enc_src_ack),
    .snk_stall_o                (enc_src_stall),

    .src_cyc_o                  (dec_snk_cyc),
    .src_stb_o                  (dec_snk_stb),
    .src_we_o                   (dec_snk_we),
    .src_sel_o                  (dec_snk_sel),
    .src_adr_o                  (dec_snk_adr),
    .src_dat_o                  (dec_snk_dat),
    .src_ack_i                  (dec_snk_ack),
    .src_stall_i                (dec_snk_stall),

    .wb_cyc_i                   (WB_lbk.master.cyc),
    .wb_stb_i                   (WB_lbk.master.stb),
    .wb_we_i                    (WB_lbk.master.we),
    .wb_sel_i                   (4'b1111),
    .wb_adr_i                   (WB_lbk.master.adr),
    .wb_dat_i                   (WB_lbk.master.dat_o),
    .wb_dat_o                   (WB_lbk.master.dat_i),
    .wb_ack_o                   (WB_lbk.master.ack),
    .wb_stall_o                 (WB_lbk.master.stall));

  initial begin
		uint64_t drop;
    int err_array[7];
    EthPacket pkt;
    pkt = new;

    @(posedge rst_n);
    repeat(3) @(posedge clk_ref);

    #1us;

    acc_lbk = WB_lbk.get_accessor();
    acc_lbk.set_mode(PIPELINED);
    WB_lbk.settings.cyc_on_stall = 1;

		acc_lbk.write(`ADDR_LBK_MCR, `LBK_MCR_ENA);

    acc_drop = WB_drop.get_accessor();
    acc_drop.set_mode(PIPELINED);
    WB_drop.settings.cyc_on_stall = 1;


    acc_fec = WB_fec.get_accessor();
    acc_fec.set_mode(PIPELINED);
    WB_fec.settings.cyc_on_stall = 1;

		fec_src = new(enc_src.get_accessor());
		//enc_src.settings.cyc_on_stall = 1;

    // configures the Module Dropper to drop packets
    // check the file fec_regs.v for more
    // info about errors that you can trigger
    // e.g acc_drop.write(`ADD_DROPP, `X01);
    // array of drop errors
    err_array = '{4'h0, 4'h2, 4'h6, 4'h1, 4'h5, 4'h3, 4'h7};

    // If you want to test the FEC bypass uncomment
    // and comment the lines 293, 294, 295
    //acc_drop.write(`ADD_DROPP, `X01);
    //acc_fec.write(`ADD_FEC_EN, 4'h0);

    #1us

    while(1) begin
      seed = (seed + 6) & 'hffff;
      // rnd length of the frames
      length = $dist_uniform(seed, 500, 1400);
      if (length < 64)
        begin
        $stop;
      end
      length = length & 'hffff;
      length = (length + 8) & ~'h07; // Multiple of 8

      /* dummy addresses */
      pkt.dst        = '{'hff, 'hff, 'hff, 'hff, 'hff, 'hff};
      pkt.src        = '{1,2,3,4,5,6};
      pkt.ethertype  = length;

      /* set the payload size to the minimum acceptable value:
         (46 bytes payload + 14 bytes header + 4 bytes CRC) */
      pkt.set_size(length);

      cnt = 0;
      for(j=0; j < 4; j++)
        begin
          pkt.payload[cnt] = $dist_uniform(seed, 100, 1500) & 'hff;
        for (i=1; i <= length/4; i++)
          begin
          pkt.payload[cnt] = $dist_uniform(seed, 64, 1500) & 'hff;
          cnt = cnt + 1;
        end
      end

      $write("\n----->TX LENGTH %d \n", length);

      // send frame with non-FEC ethertype
      if (send_bogus_etype == 8)
        begin
          pkt.ethertype  = 'hdead;
          send_bogus_etype = 0;
          //disable DROPPER
          acc_drop.write(`ADD_DROPP_EN, 4'h0);
          acc_fec.write(`ADD_FEC_EN, 4'h2);
          dropper_en = 0;        
          $write("\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
          $write("\nSending bogus ethertype this frame will be skipped by the decoder \n");
          $write("\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
          #1us;
      end
      else
        begin
        send_bogus_etype++;
        dropper_en = 1;
      end;
      
      if (dropper_en == 1)
        begin
        // rnd pkt drop generator
        err = err_array[$dist_uniform(seed, 0, 6)];
        acc_drop.write(`ADD_DROPP_EN, 4'h1);
        acc_drop.write(`ADD_DROPP, err);
        $write("\nDROPPING PKT WITH ERRO CODE %h \n", err);

        // if drops more than 3 packets no possible to decode
        if (err != 4'h7) begin
          tx_pk.push_front(pkt);
        end
        else begin
          $write("\n Error Decoding >2 Lost\n");
          $write("\n--------------------------------------------\n");
        end
      end

      fec_src.send(pkt);
      acc_fec.write(`ADD_FEC_EN, 4'h3);
      // Test at high max throughput:
      //#8ns;      
      //// if you want to test it comment out the $stop command from
      // line 400 on 
      // The problem is that the tx/rx packet verilog functions are not
      // blocking and the queue tx_pk and the fec_snk.recv(pkt) can't be
      // synchronized and the check of the decoded payload and encoded payload
      // will fail.
      #30us;
    end
  end

// Log file

  initial begin
    f = $fopen("output.txt","w");
  end

  always begin
  @(posedge enc_src.master.cyc) // wait for sig to goto 0
  sig_low = $realtime ;
  //@(enable)      // wait for enable to change its value
  @(negedge dec_snk.slave.cyc)
  toggletime= $realtime - sig_low ;
  $fwrite(f, "Delay\t%d\tPayload\t%d\n", toggletime, length);
  end

  initial begin
		uint64_t fec_info=0;
    EthPacket pkt;
    int total_cnt=0;
		int prev_size=0;
		uint64_t val64;
    int len;
    int lenx;
    int len_block;

    dec_snk.settings.gen_random_stalls = 1;
    fec_snk = new(dec_snk.get_accessor());

	  $write("--> starting");
		#5us;
    while(1) begin
			//#1us;
			fec_snk.recv(pkt);
			begin
				$write("%02X:", pkt.dst[0]);
				$write("%02X:", pkt.dst[1]);
				$write("%02X:", pkt.dst[2]);
				$write("%02X:", pkt.dst[3]);
				$write("%02X:", pkt.dst[4]);
				$write("%02X:", pkt.dst[5]);
				$write("%02X:", pkt.src[0]);
				$write("%02X:", pkt.src[1]);
				$write("%02X:", pkt.src[2]);
				$write("%02X:", pkt.src[3]);
				$write("%02X:", pkt.src[4]);
				$write("%02X",  pkt.src[5]);
			end;
			prev_size = pkt.size;

      //$write("Tx Queue Size %d \n", tx_pk.size());
      $write("\n");
			$write("--> RECV LENTH: size=%4d \n", pkt.size - 14);

      rx_pk = tx_pk.pop_back();

      if((pkt.size - 14) != rx_pk.size)
        begin
        lenx = 0;
        $write("Original Pkt: \n");
        while (lenx < rx_pk.size) begin
          $write("%02X", rx_pk.payload[lenx]);
          lenx++;
        end

        $write("\nDecoded Pkt: \n");
        lenx = 0;
        while (lenx < pkt.size - 14) begin
          $write("%02X", pkt.payload[lenx]);
          lenx++;
        end

        $write("\nERROR Tx Size %4d Rx Size %4d -- %4d \n", rx_pk.size, pkt.size - 14, pkt.size);
        $stop;
      end

      len = 0;
      while (len < rx_pk.size) begin
        if (rx_pk.payload[len] != pkt.payload[len])
          begin

          $write("Original Pkt: \n");
          lenx = 0;
          len_block = 0;
          while (lenx < rx_pk.size) begin
            $write("%02X", rx_pk.payload[lenx]);
            lenx++;
            if (len_block < (rx_pk.size)/4)
              begin
              len_block = len_block + 1;
            end
            else
              begin
              len_block = 0;
              $write("\n");
            end
          end

          $write("\n");

          $write("\nDecoded Pkt: \n");
          lenx = 0;
          len_block = 0;
          while (lenx < pkt.size - 14) begin
            $write("%02X", pkt.payload[lenx]);
            lenx++;
            if (len_block <= ((rx_pk.size - 14)/4))
              begin
              len_block = len_block + 1;
            end
            else
              begin
              len_block = 0;
              $write("\n");
            end
          end

          $write("\nError enc/dec");
          $stop;
        end
        len++;
      end
      $write("\n--------------------------------------------\n");
      if(total_cnt % 4 == 0) begin
        acc_fec.read(`ADD_FEC_NUM_ENC_PKT, fec_info);
        $write("Encoded Frames %04D -- ", fec_info);
        acc_fec.read(`ADD_FEC_NUM_ENC_ERR, fec_info);
        $write("Encoded Errors %04D -- ", fec_info);
        acc_fec.read(`ADD_FEC_NUM_DEC_PKT, fec_info);
        $write("Decoded Frames %04D -- ", fec_info);
        acc_fec.read(`ADD_FEC_NUM_DEC_ERR, fec_info);
        $write("Decoded Errors %04D -- ", fec_info);
        acc_fec.read(`ADD_FEC_NUM_JUMBO, fec_info);
        $write("Jumbo Frames: %04D\n", fec_info);
      end
      total_cnt++;
      $write("\n--------------------------------------------\n");
    end

  end
endmodule // main
