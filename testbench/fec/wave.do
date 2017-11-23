onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main/XWB_FEC_ENC/FEC_ENC/clk_i
add wave -noupdate /main/XWB_FEC_ENC/FEC_ENC/rst_n_i
add wave -noupdate -expand -group WRF_ENC -expand /main/XWB_FEC_ENC/FEC_ENC/snk_i
add wave -noupdate -expand -group WRF_ENC /main/XWB_FEC_ENC/FEC_ENC/snk_o
add wave -noupdate -expand -group WRF_ENC -expand /main/XWB_FEC_ENC/FEC_ENC/src_i
add wave -noupdate -expand -group WRF_ENC -expand /main/XWB_FEC_ENC/FEC_ENC/src_o
add wave -noupdate -expand -group WRF_DEC /main/XWB_FEC_ENC/FEC_DEC/snk_i
add wave -noupdate -expand -group WRF_DEC /main/XWB_FEC_ENC/FEC_DEC/snk_o
add wave -noupdate -expand -group WRF_DEC /main/XWB_FEC_ENC/FEC_DEC/src_i
add wave -noupdate -expand -group WRF_DEC /main/XWB_FEC_ENC/FEC_DEC/src_o
add wave -noupdate -expand -group LOOP_BACK /main/WRF_LBK/X_LOOPBACK/wrf_snk_i
add wave -noupdate -expand -group LOOP_BACK /main/WRF_LBK/X_LOOPBACK/wrf_snk_o
add wave -noupdate -expand -group LOOP_BACK /main/WRF_LBK/X_LOOPBACK/wrf_src_o
add wave -noupdate -expand -group LOOP_BACK /main/WRF_LBK/X_LOOPBACK/wrf_src_i
add wave -noupdate -expand -group LOOP_BACK_SIGNALS -height 16 /main/WRF_LBK/X_LOOPBACK/lbk_rxfsm
add wave -noupdate -expand -group LOOP_BACK_SIGNALS -height 16 /main/WRF_LBK/X_LOOPBACK/lbk_txfsm
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/rcv_cnt_inc
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/drp_cnt_inc
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/fwd_cnt_inc
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/wb_i
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/wb_o
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/frame_in
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/frame_out
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/frame_wr
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/frame_rd
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/ffifo_full
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/sfifo_empty
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/sfifo_full
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/fsize_in
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/fsize_out
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/fsize_wr
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/fsize_rd
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/fword_valid
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/forced_dmac
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/src_fab
add wave -noupdate -expand -group LOOP_BACK_SIGNALS /main/WRF_LBK/X_LOOPBACK/src_dreq
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2408850000 fs} 0}
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
WaveRestoreZoom {0 fs} {23785681920 fs}
