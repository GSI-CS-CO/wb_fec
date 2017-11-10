onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main/XWB_FEC/FEC_ENC/clk_i
add wave -noupdate /main/XWB_FEC/FEC_ENC/rst_n_i
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/snk_i
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/snk_o
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/src_i
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/src_o
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/ctrl_reg_i
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/stat_reg_o
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/eth_hdr_cnt
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/eth_payload_cnt
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/eth_hdr_reg
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/eth_hdr_shift
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/eth_hdr
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/enc_err
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/pkt_err
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/pkt_stb
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/pkt_enc_stb
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/snk_ack
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/snk_stall
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/enc_payload
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/enc_en
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/enc_src_out
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/enc_src_in
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/enc_sink_out
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/enc_sink_in
add wave -noupdate -group FEC_ENC /main/XWB_FEC/FEC_ENC/s_enc_switch
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_dec_sink_ack
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_dec_sink_stall
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_dec_sink_adr
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_dec_sink_dat
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_dec_sink_cyc
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_dec_sink_stb
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_dec_sink_we
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_dec_sink_sel
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_dec_src_ack
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_dec_src_stall
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_dec_src_adr
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_dec_src_dat
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_dec_src_cyc
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_dec_src_stb
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_dec_src_we
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_dec_src_sel
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_enc_sink_ack
add wave -noupdate -expand -group XWB_FEC -group enc_fab /main/XWB_FEC/fec_enc_sink_stall
add wave -noupdate -expand -group XWB_FEC -group enc_fab /main/XWB_FEC/fec_enc_sink_adr
add wave -noupdate -expand -group XWB_FEC -group enc_fab /main/XWB_FEC/fec_enc_sink_dat
add wave -noupdate -expand -group XWB_FEC -group enc_fab /main/XWB_FEC/fec_enc_sink_cyc
add wave -noupdate -expand -group XWB_FEC -group enc_fab /main/XWB_FEC/fec_enc_sink_stb
add wave -noupdate -expand -group XWB_FEC -group enc_fab /main/XWB_FEC/fec_enc_sink_we
add wave -noupdate -expand -group XWB_FEC -group enc_fab /main/XWB_FEC/fec_enc_sink_sel
add wave -noupdate -expand -group XWB_FEC -group enc_fab /main/XWB_FEC/fec_enc_src_ack
add wave -noupdate -expand -group XWB_FEC -group enc_fab /main/XWB_FEC/fec_enc_src_stall
add wave -noupdate -expand -group XWB_FEC -group enc_fab /main/XWB_FEC/fec_enc_src_adr
add wave -noupdate -expand -group XWB_FEC -group enc_fab /main/XWB_FEC/fec_enc_src_dat
add wave -noupdate -expand -group XWB_FEC -group enc_fab /main/XWB_FEC/fec_enc_src_cyc
add wave -noupdate -expand -group XWB_FEC -group enc_fab /main/XWB_FEC/fec_enc_src_stb
add wave -noupdate -expand -group XWB_FEC -group enc_fab /main/XWB_FEC/fec_enc_src_we
add wave -noupdate -expand -group XWB_FEC -group enc_fab /main/XWB_FEC/fec_enc_src_sel
add wave -noupdate -expand -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_ack
add wave -noupdate -expand -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_err
add wave -noupdate -expand -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_rty
add wave -noupdate -expand -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_stall
add wave -noupdate -expand -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_int
add wave -noupdate -expand -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_dat_o
add wave -noupdate -expand -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_dat_i
add wave -noupdate -expand -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_cyc
add wave -noupdate -expand -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_stb
add wave -noupdate -expand -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_adr
add wave -noupdate -expand -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_sel
add wave -noupdate -expand -group XWB_FEC -group wb /main/XWB_FEC/wb_slave_we
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_ctrl_reg
add wave -noupdate -expand -group XWB_FEC /main/XWB_FEC/fec_stat_reg
add wave -noupdate -expand /main/XWB_FEC/fec_dec_sink_i
add wave -noupdate /main/XWB_FEC/fec_dec_sink_o
add wave -noupdate /main/XWB_FEC/fec_dec_src_i
add wave -noupdate -expand /main/XWB_FEC/fec_dec_src_o
add wave -noupdate /main/XWB_FEC/fec_enc_sink_i
add wave -noupdate /main/XWB_FEC/fec_enc_sink_o
add wave -noupdate /main/XWB_FEC/fec_enc_src_i
add wave -noupdate /main/XWB_FEC/fec_enc_src_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2321837380 fs} 0}
configure wave -namecolwidth 259
configure wave -valuecolwidth 226
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
WaveRestoreZoom {2095957270 fs} {2736826430 fs}
