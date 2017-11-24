onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main/XWB_FEC/FEC_ENC/clk_i
add wave -noupdate /main/XWB_FEC/FEC_ENC/rst_n_i
add wave -noupdate -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_ack
add wave -noupdate -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_err
add wave -noupdate -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_rty
add wave -noupdate -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_stall
add wave -noupdate -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_int
add wave -noupdate -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_dat_o
add wave -noupdate -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_dat_i
add wave -noupdate -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_cyc
add wave -noupdate -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_stb
add wave -noupdate -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_adr
add wave -noupdate -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_sel
add wave -noupdate -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_we
add wave -noupdate -group XWB_FEC /main/XWB_FEC/fec_ctrl_reg
add wave -noupdate -group XWB_FEC /main/XWB_FEC/fec_stat_reg
add wave -noupdate -group FAB_DEC /main/XWB_FEC/fec_dec_sink_i
add wave -noupdate -group FAB_DEC /main/XWB_FEC/fec_dec_sink_o
add wave -noupdate -group FAB_DEC /main/XWB_FEC/fec_dec_src_i
add wave -noupdate -group FAB_DEC /main/XWB_FEC/fec_dec_src_o
add wave -noupdate -group FAB_ENC /main/XWB_FEC/fec_enc_sink_i
add wave -noupdate -group FAB_ENC /main/XWB_FEC/fec_enc_sink_o
add wave -noupdate -group FAB_ENC -expand /main/XWB_FEC/fec_enc_src_i
add wave -noupdate -group FAB_ENC -expand /main/XWB_FEC/fec_enc_src_o
add wave -noupdate -group ERASURE /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/payload_i
add wave -noupdate -group ERASURE /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/enc_err_o
add wave -noupdate -group ERASURE /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/enc_payload_o
add wave -noupdate -group ERASURE /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/rst_n
add wave -noupdate -group ERASURE /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/empty
add wave -noupdate -group ERASURE /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/full
add wave -noupdate -group ERASURE /main/XWB_FEC/FEC_ENC/fec_block_len
add wave -noupdate -group ERASURE /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/code_src_sel
add wave -noupdate -group ERASURE /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/fifo_cnt
add wave -noupdate -group ERASURE /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/pl_block
add wave -noupdate -group ERASURE /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/xor_code
add wave -noupdate -group ERASURE /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/block2enc
add wave -noupdate -group ERASURE /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/read_block
add wave -noupdate -group ERASURE /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/block_cnt
add wave -noupdate -group ERASURE /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/enc_cnt
add wave -noupdate -group ERASURE /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/we_src_sel
add wave -noupdate -group ERASURE /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/we_mask
add wave -noupdate -group ERASURE /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/we_loop_back
add wave -noupdate -expand -group FIFO_0 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(0)/PKT_BLOCK_FIFO/d_i
add wave -noupdate -expand -group FIFO_0 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(0)/PKT_BLOCK_FIFO/we_i
add wave -noupdate -expand -group FIFO_0 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(0)/PKT_BLOCK_FIFO/rd_i
add wave -noupdate -expand -group FIFO_0 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(0)/PKT_BLOCK_FIFO/q_o
add wave -noupdate -expand -group FIFO_0 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(0)/PKT_BLOCK_FIFO/empty_o
add wave -noupdate -expand -group FIFO_0 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(0)/PKT_BLOCK_FIFO/full_o
add wave -noupdate -expand -group FIFO_0 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(0)/PKT_BLOCK_FIFO/almost_empty_o
add wave -noupdate -expand -group FIFO_0 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(0)/PKT_BLOCK_FIFO/almost_full_o
add wave -noupdate -expand -group FIFO_0 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(0)/PKT_BLOCK_FIFO/count_o
add wave -noupdate -expand -group FIFO_1 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(1)/PKT_BLOCK_FIFO/d_i
add wave -noupdate -expand -group FIFO_1 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(1)/PKT_BLOCK_FIFO/we_i
add wave -noupdate -expand -group FIFO_1 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(1)/PKT_BLOCK_FIFO/q_o
add wave -noupdate -expand -group FIFO_1 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(1)/PKT_BLOCK_FIFO/rd_i
add wave -noupdate -expand -group FIFO_1 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(1)/PKT_BLOCK_FIFO/empty_o
add wave -noupdate -expand -group FIFO_1 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(1)/PKT_BLOCK_FIFO/full_o
add wave -noupdate -expand -group FIFO_1 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(1)/PKT_BLOCK_FIFO/almost_empty_o
add wave -noupdate -expand -group FIFO_1 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(1)/PKT_BLOCK_FIFO/almost_full_o
add wave -noupdate -expand -group FIFO_1 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(1)/PKT_BLOCK_FIFO/count_o
add wave -noupdate -group FIFO_2 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(2)/PKT_BLOCK_FIFO/d_i
add wave -noupdate -group FIFO_2 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(2)/PKT_BLOCK_FIFO/we_i
add wave -noupdate -group FIFO_2 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(2)/PKT_BLOCK_FIFO/q_o
add wave -noupdate -group FIFO_2 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(2)/PKT_BLOCK_FIFO/rd_i
add wave -noupdate -group FIFO_2 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(2)/PKT_BLOCK_FIFO/empty_o
add wave -noupdate -group FIFO_2 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(2)/PKT_BLOCK_FIFO/full_o
add wave -noupdate -group FIFO_2 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(2)/PKT_BLOCK_FIFO/almost_empty_o
add wave -noupdate -group FIFO_2 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(2)/PKT_BLOCK_FIFO/almost_full_o
add wave -noupdate -group FIFO_2 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(2)/PKT_BLOCK_FIFO/count_o
add wave -noupdate -group FIFO_3 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(3)/PKT_BLOCK_FIFO/d_i
add wave -noupdate -group FIFO_3 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(3)/PKT_BLOCK_FIFO/we_i
add wave -noupdate -group FIFO_3 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(3)/PKT_BLOCK_FIFO/q_o
add wave -noupdate -group FIFO_3 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(3)/PKT_BLOCK_FIFO/rd_i
add wave -noupdate -group FIFO_3 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(3)/PKT_BLOCK_FIFO/empty_o
add wave -noupdate -group FIFO_3 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(3)/PKT_BLOCK_FIFO/full_o
add wave -noupdate -group FIFO_3 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(3)/PKT_BLOCK_FIFO/almost_empty_o
add wave -noupdate -group FIFO_3 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(3)/PKT_BLOCK_FIFO/almost_full_o
add wave -noupdate -group FIFO_3 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/g_PKT_BLOCK_FIFO(3)/PKT_BLOCK_FIFO/count_o
add wave -noupdate -expand -group WB_FEC_ENC -expand /main/XWB_FEC/FEC_ENC/snk_i
add wave -noupdate -expand -group WB_FEC_ENC /main/XWB_FEC/FEC_ENC/snk_o
add wave -noupdate -expand -group WB_FEC_ENC /main/XWB_FEC/FEC_ENC/src_i
add wave -noupdate -expand -group WB_FEC_ENC /main/XWB_FEC/FEC_ENC/src_i.stall
add wave -noupdate -expand -group WB_FEC_ENC -expand /main/XWB_FEC/FEC_ENC/src_o
add wave -noupdate -expand -group WB_FEC_ENC /main/XWB_FEC/FEC_ENC/ctrl_reg_i
add wave -noupdate -expand -group WB_FEC_ENC /main/XWB_FEC/FEC_ENC/stat_reg_o
add wave -noupdate -expand -group WB_FEC_ENC /main/XWB_FEC/FEC_ENC/src_cyc
add wave -noupdate -expand -group WB_FEC_ENC -group err /main/XWB_FEC/FEC_ENC/enc_err
add wave -noupdate -expand -group WB_FEC_ENC -group err /main/XWB_FEC/FEC_ENC/pkt_err
add wave -noupdate -expand -group WB_FEC_ENC -radix decimal /main/XWB_FEC/FEC_ENC/fec_bytes
add wave -noupdate -expand -group WB_FEC_ENC -expand -group STB /main/XWB_FEC/FEC_ENC/fec_stb_d
add wave -noupdate -expand -group WB_FEC_ENC -expand -group STB /main/XWB_FEC/FEC_ENC/hdr_stb
add wave -noupdate -expand -group WB_FEC_ENC -expand -group STB /main/XWB_FEC/FEC_ENC/pkt_stb
add wave -noupdate -expand -group WB_FEC_ENC -expand -group STB /main/XWB_FEC/FEC_ENC/fec_stb
add wave -noupdate -expand -group WB_FEC_ENC -expand -group STB /main/XWB_FEC/FEC_ENC/fec_hdr_stb
add wave -noupdate -expand -group WB_FEC_ENC /main/XWB_FEC/FEC_ENC/hdr_ethertype
add wave -noupdate -expand -group WB_FEC_ENC /main/XWB_FEC/FEC_ENC/pkt_len
add wave -noupdate -expand -group WB_FEC_ENC /main/XWB_FEC/FEC_ENC/ctrl_reg
add wave -noupdate -expand -group WB_FEC_ENC /main/XWB_FEC/FEC_ENC/snk_stall
add wave -noupdate -expand -group WB_FEC_ENC /main/XWB_FEC/FEC_ENC/enc_payload
add wave -noupdate -expand -group WB_FEC_ENC -group fifo /main/XWB_FEC/FEC_ENC/wrf_adr_o
add wave -noupdate -expand -group WB_FEC_ENC -group fifo /main/XWB_FEC/FEC_ENC/data_fifo_i
add wave -noupdate -expand -group WB_FEC_ENC -group fifo /main/XWB_FEC/FEC_ENC/wrf_adr_i
add wave -noupdate -expand -group WB_FEC_ENC -group fifo /main/XWB_FEC/FEC_ENC/fec_pkt_o
add wave -noupdate -expand -group WB_FEC_ENC -group fifo /main/XWB_FEC/FEC_ENC/fec_pkt_i
add wave -noupdate -expand -group WB_FEC_ENC -group fifo /main/XWB_FEC/FEC_ENC/rd_fifo_o
add wave -noupdate -expand -group WB_FEC_ENC -group fifo /main/XWB_FEC/FEC_ENC/wr_fifo_o
add wave -noupdate -expand -group WB_FEC_ENC -group fifo /main/XWB_FEC/FEC_ENC/fifo_empty
add wave -noupdate -expand -group WB_FEC_ENC -group fifo /main/XWB_FEC/FEC_ENC/fifo_full
add wave -noupdate -expand -group WB_FEC_ENC -group fifo /main/XWB_FEC/FEC_ENC/fifo_cnt
add wave -noupdate -expand -group WB_FEC_ENC /main/XWB_FEC/FEC_ENC/start_streaming
add wave -noupdate -expand -group WB_FEC_ENC /main/XWB_FEC/FEC_ENC/fec_hdr
add wave -noupdate -expand -group WB_FEC_ENC /main/XWB_FEC/FEC_ENC/fec_block_len
add wave -noupdate -expand -group WB_FEC_ENC -height 16 /main/XWB_FEC/FEC_ENC/s_enc_refresh
add wave -noupdate -expand -group WB_FEC_ENC -height 16 /main/XWB_FEC/FEC_ENC/s_fec_strm
add wave -noupdate -expand -group WB_FEC_ENC /main/XWB_FEC/FEC_ENC/eth_cnt
add wave -noupdate -expand -group WB_FEC_ENC /main/XWB_FEC/FEC_ENC/fec_pkt_cnt
add wave -noupdate -expand -group WB_FEC_ENC /main/XWB_FEC/FEC_ENC/fec_word_cnt
add wave -noupdate -group HDR_GEN /main/XWB_FEC/FEC_ENC/FEC_HDR_PROC/hdr_i
add wave -noupdate -group HDR_GEN /main/XWB_FEC/FEC_ENC/FEC_HDR_PROC/hdr_stb_i
add wave -noupdate -group HDR_GEN /main/XWB_FEC/FEC_ENC/FEC_HDR_PROC/block_len_i
add wave -noupdate -group HDR_GEN /main/XWB_FEC/FEC_ENC/FEC_HDR_PROC/fec_stb_i
add wave -noupdate -group HDR_GEN /main/XWB_FEC/FEC_ENC/FEC_HDR_PROC/fec_hdr_stb_i
add wave -noupdate -group HDR_GEN /main/XWB_FEC/FEC_ENC/FEC_HDR_PROC/fec_hdr_o
add wave -noupdate -group HDR_GEN /main/XWB_FEC/FEC_ENC/FEC_HDR_PROC/enc_cnt_o
add wave -noupdate -group HDR_GEN /main/XWB_FEC/FEC_ENC/FEC_HDR_PROC/ctrl_reg_i
add wave -noupdate -group HDR_GEN /main/XWB_FEC/FEC_ENC/FEC_HDR_PROC/id_cnt
add wave -noupdate -group HDR_GEN /main/XWB_FEC/FEC_ENC/FEC_HDR_PROC/subid_cnt
add wave -noupdate -group HDR_GEN /main/XWB_FEC/FEC_ENC/FEC_HDR_PROC/fec_hdr_stb_d
add wave -noupdate -group HDR_GEN /main/XWB_FEC/FEC_ENC/FEC_HDR_PROC/fec_stb_d
add wave -noupdate -group HDR_GEN /main/XWB_FEC/FEC_ENC/FEC_HDR_PROC/fec_hdr
add wave -noupdate -group HDR_GEN /main/XWB_FEC/FEC_ENC/FEC_HDR_PROC/fec_hdr_len
add wave -noupdate -group HDR_GEN /main/XWB_FEC/FEC_ENC/FEC_HDR_PROC/eth_hdr_reg
add wave -noupdate -group HDR_GEN /main/XWB_FEC/FEC_ENC/FEC_HDR_PROC/eth_hdr_shift
add wave -noupdate -group HDR_GEN -expand /main/XWB_FEC/FEC_ENC/FEC_HDR_PROC/eth_hdr
add wave -noupdate -group HDR_GEN /main/XWB_FEC/FEC_ENC/FEC_HDR_PROC/hdr_reserved
add wave -noupdate -expand -group ENCODER -expand -group STB /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/payload_stb_i
add wave -noupdate -expand -group ENCODER -expand -group STB /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/fec_stb_i
add wave -noupdate -expand -group ENCODER -expand -group STB /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/fec_enc_rd_i
add wave -noupdate -expand -group ENCODER /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/enc_payload_o
add wave -noupdate -expand -group ENCODER /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/enc_payload
add wave -noupdate -expand -group ENCODER -expand /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/block2enc
add wave -noupdate -expand -group ENCODER -expand /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/pl_block
add wave -noupdate -expand -group ENCODER /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/payload_i
add wave -noupdate -expand -group ENCODER /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/block2enc(0)
add wave -noupdate -expand -group ENCODER /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/xor_code
add wave -noupdate -expand -group ENCODER -expand -group FIFO /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/ENC_PKT_FIFO/d_i
add wave -noupdate -expand -group ENCODER -expand -group FIFO /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/ENC_PKT_FIFO/we_i
add wave -noupdate -expand -group ENCODER -expand -group FIFO /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/ENC_PKT_FIFO/q_o
add wave -noupdate -expand -group ENCODER -expand -group FIFO /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/ENC_PKT_FIFO/rd_i
add wave -noupdate -expand -group ENCODER -expand -group FIFO /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/ENC_PKT_FIFO/empty_o
add wave -noupdate -expand -group ENCODER -expand -group FIFO /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/ENC_PKT_FIFO/full_o
add wave -noupdate -expand -group ENCODER -expand -group FIFO /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/ENC_PKT_FIFO/almost_empty_o
add wave -noupdate -expand -group ENCODER -expand -group FIFO /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/ENC_PKT_FIFO/almost_full_o
add wave -noupdate -expand -group ENCODER -expand -group FIFO /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/ENC_PKT_FIFO/count_o
add wave -noupdate -expand -group ENCODER /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/block_len_i
add wave -noupdate -expand -group ENCODER /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/block_cnt
add wave -noupdate -expand -group ENCODER /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/fec_pl_len
add wave -noupdate -expand -group ENCODER /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/enc_cnt
add wave -noupdate -expand -group ENCODER -height 16 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/s_ENC
add wave -noupdate -expand -group ENCODER -height 16 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/S_ENC_CNT
add wave -noupdate -expand -group ENCODER /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/enc_err_o
add wave -noupdate -expand -group ENCODER /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/rst_n
add wave -noupdate -expand -group ENCODER /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/empty
add wave -noupdate -expand -group ENCODER /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/full
add wave -noupdate -expand -group ENCODER -expand /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/cnt
add wave -noupdate -expand -group ENCODER /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/code_src_sel
add wave -noupdate -expand -group ENCODER /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/read_block
add wave -noupdate -expand -group ENCODER /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/we_src_sel
add wave -noupdate -expand -group ENCODER /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/we_mask
add wave -noupdate -expand -group ENCODER /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/we_loop_back
add wave -noupdate -expand -group ENCODER -height 16 /main/XWB_FEC/FEC_ENC/PKT_ERASURE_ENC/s_ENC
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2779073570 fs} 0} {{Cursor 2} {1764000000 fs} 0}
configure wave -namecolwidth 194
configure wave -valuecolwidth 150
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
WaveRestoreZoom {2270214740 fs} {2865761620 fs}
