onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main/ENC/clk_i
add wave -noupdate /main/ENC/rst_n_i
add wave -noupdate /main/ENC/stb_i
add wave -noupdate /main/ENC/payload_i
add wave -noupdate /main/ENC/code_word_o
add wave -noupdate /main/DEC/paycode_i
add wave -noupdate /main/DEC/paycode
add wave -noupdate /main/DEC/stb_i
add wave -noupdate /main/DEC/decoded_o
add wave -noupdate /main/DEC/payload_o
add wave -noupdate /main/DEC/parity
add wave -noupdate /main/DEC/failed_o
add wave -noupdate -height 16 /main/DEC/s_dec
add wave -noupdate /main/DEC/synd
add wave -noupdate /main/DEC/codeword_m
add wave -noupdate -expand /main/DEC/hmm_wgt_m
add wave -noupdate /main/DEC/wgt_dec
add wave -noupdate /main/DEC/hmm_wgt
add wave -noupdate /main/DEC/synd_d
add wave -noupdate /main/DEC/synd_err
add wave -noupdate /main/DEC/codeword
add wave -noupdate /main/DEC/parity_gen
add wave -noupdate -group HAMMING_WGT_DEC /main/DEC/HAMMWGT_DEC/hmm_wgt_i
add wave -noupdate -group HAMMING_WGT_DEC /main/DEC/HAMMWGT_DEC/wgt_dec_o
add wave -noupdate -group HAMMING_WGT_DEC /main/DEC/HAMMWGT_DEC/hmm_wgt_m
add wave -noupdate -group HAMMING_WGT_DEC /main/DEC/HAMMWGT_DEC/hmm_wgt_i
add wave -noupdate -group HAMMING_WGT_DEC /main/DEC/HAMMWGT_DEC/wgt_dec_o
add wave -noupdate -group HAMMING_WGT_DEC /main/DEC/HAMMWGT_DEC/hmm_wgt_m
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {65435880 fs} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
WaveRestoreZoom {0 fs} {525 ns}
