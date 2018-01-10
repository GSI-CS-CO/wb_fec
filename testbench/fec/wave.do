onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main/XWB_FEC_ENC/clk_i
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/wrf_snk_i
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/wrf_snk_o
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/wrf_src_o
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/wrf_src_i
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/wb_i
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/wb_o
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/regs_fromwb
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/regs_towb
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/wb_out
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/wb_in
add wave -noupdate -group LOOPBACK -height 16 /main/WRF_LBK/X_LOOPBACK/lbk_rxfsm
add wave -noupdate -group LOOPBACK -height 16 /main/WRF_LBK/X_LOOPBACK/lbk_txfsm
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/rcv_cnt
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/drp_cnt
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/fwd_cnt
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/fsize
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/txsize
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/tx_cnt
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/rcv_cnt_inc
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/drp_cnt_inc
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/fwd_cnt_inc
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/frame_in
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/frame_out
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/frame_wr
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/frame_rd
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/ffifo_full
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/ffifo_empty
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/sfifo_empty
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/sfifo_full
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/fsize_in
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/fsize_out
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/fsize_wr
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/fsize_rd
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/fword_valid
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/forced_dmac
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/src_fab
add wave -noupdate -group LOOPBACK /main/WRF_LBK/X_LOOPBACK/src_dreq
add wave -noupdate -group LOOP_BACK /main/WRF_LBK/X_LOOPBACK/wrf_snk_i
add wave -noupdate -group LOOP_BACK /main/WRF_LBK/X_LOOPBACK/wrf_snk_o
add wave -noupdate -group LOOP_BACK /main/WRF_LBK/X_LOOPBACK/wrf_src_o
add wave -noupdate -group LOOP_BACK /main/WRF_LBK/X_LOOPBACK/wrf_src_i
add wave -noupdate -group FEC_ENC -expand /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/snk_i
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/snk_o
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/src_i
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/src_o
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/ctrl_reg_i
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/stat_reg_o
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/src_cyc
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/src_stb
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/snk_ack
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/fec_stb_d
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/enc_err
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/pkt_err
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/pkt_stb
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/hdr_ethertype
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/pkt_len
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/ctrl_reg
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/snk_stall
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/enc_payload
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/fec_hdr
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/fec_stb
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/fec_hdr_stb
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/pkt_id
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/OOB_frame_id
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/data_fifo_i
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/data_fifo_o
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/fec_enc_rd
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/wr_fifo_o
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/rd_fifo_o
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/fifo_empty
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/fifo_full
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/fifo_cnt
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/fec_block_len
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/hdr_stb
add wave -noupdate -group FEC_ENC -height 16 /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/s_enc_refresh
add wave -noupdate -group FEC_ENC -height 16 /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/s_fec_strm
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/eth_cnt
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/pad_cnt
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/fec_pkt_cnt
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/fec_word_cnt
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/pad_word_cnt
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/fec_bytes
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/start_streaming
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/padding
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/data_stb
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/pad_stb
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/padded
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/pkt_data
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/wrf_adr_o
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/fec_pkt_o
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/wrf_adr_i
add wave -noupdate -group FEC_ENC /main/XWB_FEC_ENC/y_WB_FEC_ENC/FEC_ENC/fec_pkt_i
add wave -noupdate -group WB_DEC -expand /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/snk_i
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/snk_o
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/src_i
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/src_o
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/ctrl_reg_i
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/stat_reg_o
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/oob_info
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/oob_toggle
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/fec_skip_pkt
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/eth_cnt
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/wrf_oob_cnt
add wave -noupdate -group WB_DEC -expand -group STB /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/hdr_stb
add wave -noupdate -group WB_DEC -expand -group STB /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/eth_hdr_stb
add wave -noupdate -group WB_DEC -expand -group STB /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/pkt_stb
add wave -noupdate -group WB_DEC -expand -group STB /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/eth_payload_stb
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/fec_pad_stb
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/pkt_err
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/fec_stb
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/fec_stb_d
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/src_halt
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/dec_err
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/eth_payload
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/eth_hdr
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/ctrl_reg
add wave -noupdate -group WB_DEC /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/snk_stall
add wave -noupdate -group WB_DEC -height 16 /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/s_enc_refresh
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/hdr_i
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/hdr_stb_i
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/fec_stb_i
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/fec_hdr_stb_i
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/fec_hdr_o
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/pkt_len_i
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/padding_i
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/enc_cnt_o
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/ctrl_reg_i
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/id_cnt
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/subid_cnt
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/fec_hdr_stb_d
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/fec_stb_d
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/fec_hdr
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/fec_hdr_len
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/eth_hdr_len
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/eth_hdr_reg
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/eth_hdr_shift
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/eth_hdr
add wave -noupdate -group DEC_FEC_HDR /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/FEC_HDR_PROC/pkt_len
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/fec_payload_stb_i
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/rst_n_fifo
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/rst_n_dec
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/rst_n_i
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/fec_pad_stb_i
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/fec_stb_o
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/stream_out
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/payload_cnt
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/pkt_payload_o
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/pkt_payload_stb_o
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/halt_streaming_i
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/pkt_dec_err_o
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/decoding_id
add wave -noupdate -expand -group DECODER -height 16 /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/s_DEC
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/s_NEXT_OP
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/fec_payload_cnt
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/CTRL_DEC/op_step
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/CTRL_deFEC/new_pkt
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/CTRL_deFEC/new_fec_id
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/xor_we
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/fec_payload
add wave -noupdate -expand -group DECODER -expand /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/we_mask
add wave -noupdate -expand -group DECODER -expand -subitemconfig {/main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/we_src_sel(2) -expand} /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/we_src_sel
add wave -noupdate -expand -group DECODER -expand /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/read_block
add wave -noupdate -expand -group DECODER -expand /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/read_payload
add wave -noupdate -expand -group DECODER -expand -group XOR_BLOCK_FIFO /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/fec_payload_i
add wave -noupdate -expand -group DECODER -expand -group XOR_BLOCK_FIFO /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/fec_payload
add wave -noupdate -expand -group DECODER -expand -group XOR_BLOCK_FIFO /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/xor_we
add wave -noupdate -expand -group DECODER -expand -group XOR_BLOCK_FIFO /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/xor_empty
add wave -noupdate -expand -group DECODER -expand -group XOR_BLOCK_FIFO /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/xor_full
add wave -noupdate -expand -group DECODER -expand -group XOR_BLOCK_FIFO /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/xor_rd
add wave -noupdate -expand -group DECODER -expand -group XOR_BLOCK_FIFO /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/xor_payload
add wave -noupdate -expand -group DECODER -expand -group XOR_BLOCK_FIFO /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/xor_cnt
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/block_stream
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/fec_pkt_rx
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/pkt_dec_err
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/pkt_block_xor
add wave -noupdate -expand -group DECODER -expand -group BLOCK_FIFO -expand /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/pkt_block_fifo
add wave -noupdate -expand -group DECODER -expand -group BLOCK_FIFO /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/read_fec_block
add wave -noupdate -expand -group DECODER -expand -group BLOCK_FIFO /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/we_mask
add wave -noupdate -expand -group DECODER -expand -group BLOCK_FIFO -expand /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/payload_block
add wave -noupdate -expand -group DECODER -expand -group BLOCK_FIFO /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/empty
add wave -noupdate -expand -group DECODER -expand -group BLOCK_FIFO /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/cnt
add wave -noupdate -expand -group DECODER -expand -group BLOCK_FIFO /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/full
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/block_len
add wave -noupdate -expand -group DECODER -expand /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/s_fec_hdr
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/fec_payload_stb_d
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/fec_pad_err
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/padding_crc
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/pkt_len
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/padding
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/fec_payload
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/CTRL_DEC/subid
add wave -noupdate -expand -group DECODER /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/fec_stb
add wave -noupdate -group PADDING /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/fec_pad_stb_i
add wave -noupdate -group PADDING /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/fec_pad_stb_d
add wave -noupdate -group PADDING /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/calc_padding/pkt_len_mult
add wave -noupdate -group PADDING /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/calc_padding/pad_pkt
add wave -noupdate -group PADDING /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/calc_padding/pad_block
add wave -noupdate -group PADDING /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/calc_padding/pkt_len
add wave -noupdate -group PADDING /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/calc_padding/padding_crc
add wave -noupdate -group PADDING /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/padding_crc_i
add wave -noupdate -group PADDING /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/pkt_len_i
add wave -noupdate -group PADDING /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/calc_padding/block_len
add wave -noupdate -group PADDING /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/fec_block_len
add wave -noupdate -group PADDING /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/fec_block_len_o
add wave -noupdate -group PADDING -expand /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/padding_o
add wave -noupdate -group PADDING /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/pad_crc_err_o
add wave -noupdate -group PADDING /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/padding
add wave -noupdate -group PADDING /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/c_mult
add wave -noupdate -group PADDING /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/c_not_mult
add wave -noupdate -group PADDING /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/c_min_pkt_len
add wave -noupdate -group PADDING /main/XWB_FEC_ENC/y_WB_FEC_DEC/FEC_DEC/PKT_ERASURE_DEC/PADDING_MOD/c_fec_min_block
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 4} {2468000000 fs} 0} {{Cursor 3} {2404000000 fs} 0} {{Cursor 4} {2340000000 fs} 0} {{Cursor 4} {2532000000 fs} 0} {{Cursor 5} {2217725130 fs} 0} {{Cursor 6} {2525418530 fs} 0}
configure wave -namecolwidth 192
configure wave -valuecolwidth 144
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 400000
configure wave -gridperiod 800000
configure wave -griddelta 10
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 fs} {11548425040 fs}
