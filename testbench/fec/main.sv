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

	/* WB accessors */
  CWishboneAccessor acc_fec, acc_lbk;

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

		.fec_enc_src_cyc(enc_src_cyc),
		.fec_enc_src_stb(enc_src_stb),
		.fec_enc_src_we(enc_src_we),
		.fec_enc_src_sel(enc_src_sel),
		.fec_enc_src_adr(enc_src_adr),
		.fec_enc_src_dat(enc_src_dat),
		.fec_enc_src_stall(enc_src_stall),
		.fec_enc_src_ack(enc_src_ack),

    .wb_slave_cyc(WB_fec.master.cyc),
		.wb_slave_stb(WB_fec.master.stb),
		.wb_slave_we(WB_fec.master.we),
		.wb_slave_sel(4'b1111),
		.wb_slave_adr(WB_fec.master.adr),
		.wb_slave_dat_i(WB_fec.master.dat_o),
		.wb_slave_dat_o(WB_fec.master.dat_i),
		.wb_slave_ack(WB_fec.master.ack),
		.wb_slave_stall(WB_fec.master.stall));


  wrf_loopback #(
    .g_interface_mode           (PIPELINED),
    .g_address_granularity      (BYTE))
  WRF_LBK (
    .clk_sys_i                  (clk_ref),
    .rst_n_i                    (rst_n),
    .snk_cyc_i                  (enc_src_cyc),
    .snk_stb_i                  (enc_src_stb),
    //.snk_we_i                   (1'b1),
    .snk_we_i                   (enc_src_we),
    .snk_sel_i                  (enc_src_sel),
    .snk_adr_i                  (enc_src_adr),
    .snk_dat_i                  (enc_src_dat),
    .snk_ack_o                  (enc_src_ack),
    .snk_stall_o                (enc_src_stall),

    //.clk_sys_i                  (clk_ref),
    //.rst_n_i                    (rst_n),

    //.snk_cyc_i                  (enc_src.master.cyc),
    //.snk_stb_i                  (enc_src.master.stb),
    //.snk_we_i                   (enc_src.master.we),
    //.snk_sel_i                  (enc_src.master.sel),
    //.snk_adr_i                  (enc_src.master.adr),
    //.snk_dat_i                  (enc_src.master.dat_o),
    //.snk_ack_o                  (enc_src.master.stall),
    //.snk_stall_o                (enc_src.master.ack),

    //.src_cyc_o                  (dec_snk.slave.cyc),
    //.src_stb_o                  (dec_snk.slave.stb),
    //.src_we_o                   (dec_snk.slave.we),
    //.src_sel_o                  (dec_snk.slave.sel),
    //.src_adr_o                  (dec_snk.slave.adr),
    //.src_dat_o                  (dec_snk.slave.dat_i),
    //.src_ack_i                  (dec_snk.slave.stall),
    //.src_stall_i                (dec_snk.slave.ack),

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

  //initial begin

  //  @(posedge rst_n);
  //  repeat(3) @(posedge clk_sys);

  //  #1us;

  //  acc_fec = WB_fec.get_accessor();
  //  acc_fec.set_mode(PIPELINED);
  //  WB_fec.settings.cyc_on_stall = 1;

	//	//fec_src = new(dec_src.get_accessor());
	//	//dec_src.settings.cyc_on_stall = 1;

	//	fec_src = new(enc_src.get_accessor());
	//	dec_src.settings.cyc_on_stall = 1;

  //  #1us;
	//	acc_fec.write(`FEC_ENC_EN, 1'h0);
	//	//#1us;
	//	//acc_fec.write(`ADDR_LBK_DMAC_L, 32'h33445566);
	//	//#1us;
	//	//acc_fec.write(`ADDR_LBK_MCR, `LBK_MCR_ENA | `LBK_MCR_FDMAC);
	//	//acc_fec.write(`ADDR_LBK_MCR, `LBK_MCR_ENA);

  //  //#1500ns;
  //  tx_sizes = {};
  //  //NOW LET'S SEND SOME FRAMES
  //  send_frames(fec_src, 1500);
  //end

  initial begin
    EthPacket pkt;
    pkt = new; 


    @(posedge rst_n);
    repeat(3) @(posedge clk_ref);

    #1us;

    //acc_fec = WB_fec.get_accessor();
    //acc_fec.set_mode(PIPELINED);
    //WB_fec.settings.cyc_on_stall = 1;

    acc_lbk = WB_lbk.get_accessor();
    acc_lbk.set_mode(PIPELINED);
    WB_lbk.settings.cyc_on_stall = 1;		
    
    fec_src = new(enc_src.get_accessor());
    enc_src.settings.cyc_on_stall = 1;


    #1us;
    acc_lbk.write(`ADDR_LBK_DMAC_H, 32'hFFFFFFFF);
    #1us;
    acc_lbk.write(`ADDR_LBK_DMAC_L, 32'hFFFFFFFF);
    #1us;
    acc_lbk.write(`ADDR_LBK_MCR, `LBK_MCR_ENA | `LBK_MCR_FDMAC);
    //acc_lbk.write(`ADDR_LBK_MCR, `LBK_MCR_ENA);

    //#1us;
    //acc_lbk.write(`ADDR_LBK_MCR, `LBK_MCR_ENA);

    //#10us;
		//acc_fec.write(`FEC_ENC_EN, 1'h1);

    #1500ns;
    while(1) begin
      seed = (seed + 1) & 'hffff;
      //length = $dist_uniform(seed, 128, 1500);
      length = $dist_uniform(seed, 500, 1500);
      length = length & 'hffff;
      length = (length + 7) & ~'h07;
      
      $write("----->LENGTH %x \n", length);

      /* some dummy addresses */
      pkt.dst        = '{'hff, 'hff, 'hff, 'hff, 'hff, 'hff};
      pkt.src        = '{1,2,3,4,5,6};
      pkt.ethertype  = length;

      /* set the payload size to the minimum acceptable value:
         (46 bytes payload + 14 bytes header + 4 bytes CRC) */
      pkt.set_size(length);

      cnt = 0;
      for(j=0; j < 4; j++)
        begin
        for (i=1; i <= length/4; i++)
          begin
          pkt.payload[cnt] = i & 'hff;
          //pkt.payload[cnt] = j & 'hff;
          cnt = cnt + 1;
        end
      end

      //for(i=0; i < lenght; i++)
      //  begin
      //  data = $dist_uniform(seed, 0, (1<<31)-1);
      //  pkt.payload[i] = data & 'hff;
      //end
      
      //while(1) begin
        /* send the packet */
        fec_src.send(pkt);
        #5000ns;
    end
  end

  //initial begin
  //  f = $fopen("output.txt","w");
  //end

  //always begin
  //@(posedge enc_src.master.cyc) // wait for sig to goto 0
  //sig_low = $realtime ;
  ////@(enable)      // wait for enable to change its value
  ////HAS TO BE CHANGED @(negedge enc_snk.slave.cyc)
  //toggletime= $realtime - sig_low ;
  //$fwrite(f, "Delay %d Payload %d \n", toggletime, length);
  //end

  initial begin
    EthPacket pkt;
		int prev_size=0;
		uint64_t val64;
    int total_cnt=0;

    dec_snk.settings.gen_random_stalls = 1;    
    fec_snk = new(dec_snk.get_accessor());
    
	  $warning("--> starting");
		#5us;
    while(1) begin
			#1us;
			fec_snk.recv(pkt);
			//if(pkt.size-prev_size!=1)
			//	$warning("--> recv: size=%4d, %4d", pkt.size, pkt.size-prev_size);
			//if(pkt.dst[0]!=8'h11 || pkt.dst[1]!=8'h22 || pkt.dst[2]!=8'h33 || 
			//	 pkt.dst[3]!=8'h44 || pkt.dst[4]!=8'h55 || pkt.dst[5]!=8'h66)
			//if(pkt.dst[0]!=8'h16 || pkt.dst[1]!=8'h21 || pkt.dst[2]!=8'h2c || 
			//	 pkt.dst[3]!=8'h2c || pkt.dst[4]!=8'h37 || pkt.dst[5]!=8'h42)
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
				$info("--> recv: size=%4d, %4d", pkt.size, pkt.size-prev_size);
			end;
			prev_size = pkt.size;
			//acc_fec.read(`ADDR_LBK_RCV_CNT, val64);
			//$display("rcv_cnt: %d", val64);
			//acc_fec.read(`ADDR_LBK_DRP_CNT, val64);
			//$display("drp_cnt: %d", val64);
			//acc_fec.read(`ADDR_LBK_FWD_CNT, val64);
			//$display("fwd_cnt: %d", val64);
			//acc_fec.write(`ADDR_LBK_MCR, `LBK_MCR_CLR);
			//acc_fec.write(`ADDR_LBK_MCR, 0);
      if(total_cnt % 50 == 0) begin
        acc_lbk.read(`ADDR_LBK_RCV_CNT, val64);
        $display("rcv_cnt: %d", val64);
        acc_lbk.read(`ADDR_LBK_DRP_CNT, val64);
        $display("drp_cnt: %d", val64);
        acc_lbk.read(`ADDR_LBK_FWD_CNT, val64);
        $display("fwd_cnt: %d", val64);
      end
      total_cnt++;


    end
  end

endmodule // main
