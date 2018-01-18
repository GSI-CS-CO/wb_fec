onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /hamming_weight_tb/H/clk_i
add wave -noupdate /hamming_weight_tb/H/rst_n_i
add wave -noupdate /hamming_weight_tb/H/hmm_stb_i
add wave -noupdate -radix hexadecimal -childformat {{/hamming_weight_tb/H/vector_i(11) -radix hexadecimal} {/hamming_weight_tb/H/vector_i(10) -radix hexadecimal} {/hamming_weight_tb/H/vector_i(9) -radix hexadecimal} {/hamming_weight_tb/H/vector_i(8) -radix hexadecimal} {/hamming_weight_tb/H/vector_i(7) -radix hexadecimal} {/hamming_weight_tb/H/vector_i(6) -radix hexadecimal} {/hamming_weight_tb/H/vector_i(5) -radix hexadecimal} {/hamming_weight_tb/H/vector_i(4) -radix hexadecimal} {/hamming_weight_tb/H/vector_i(3) -radix hexadecimal} {/hamming_weight_tb/H/vector_i(2) -radix hexadecimal} {/hamming_weight_tb/H/vector_i(1) -radix hexadecimal} {/hamming_weight_tb/H/vector_i(0) -radix hexadecimal}} -expand -subitemconfig {/hamming_weight_tb/H/vector_i(11) {-radix hexadecimal} /hamming_weight_tb/H/vector_i(10) {-radix hexadecimal} /hamming_weight_tb/H/vector_i(9) {-radix hexadecimal} /hamming_weight_tb/H/vector_i(8) {-radix hexadecimal} /hamming_weight_tb/H/vector_i(7) {-radix hexadecimal} /hamming_weight_tb/H/vector_i(6) {-radix hexadecimal} /hamming_weight_tb/H/vector_i(5) {-radix hexadecimal} /hamming_weight_tb/H/vector_i(4) {-radix hexadecimal} /hamming_weight_tb/H/vector_i(3) {-radix hexadecimal} /hamming_weight_tb/H/vector_i(2) {-radix hexadecimal} /hamming_weight_tb/H/vector_i(1) {-radix hexadecimal} /hamming_weight_tb/H/vector_i(0) {-radix hexadecimal}} /hamming_weight_tb/H/vector_i
add wave -noupdate -radix hexadecimal -childformat {{/hamming_weight_tb/H/hmm_dist_o(3) -radix hexadecimal} {/hamming_weight_tb/H/hmm_dist_o(2) -radix hexadecimal} {/hamming_weight_tb/H/hmm_dist_o(1) -radix hexadecimal} {/hamming_weight_tb/H/hmm_dist_o(0) -radix hexadecimal}} -expand -subitemconfig {/hamming_weight_tb/H/hmm_dist_o(3) {-radix hexadecimal} /hamming_weight_tb/H/hmm_dist_o(2) {-radix hexadecimal} /hamming_weight_tb/H/hmm_dist_o(1) {-radix hexadecimal} /hamming_weight_tb/H/hmm_dist_o(0) {-radix hexadecimal}} /hamming_weight_tb/H/hmm_dist_o
add wave -noupdate -expand -group TWO_0 /hamming_weight_tb/H/SECOND_STEP(0)/TWOBITADDER/a
add wave -noupdate -expand -group TWO_0 /hamming_weight_tb/H/SECOND_STEP(0)/TWOBITADDER/b
add wave -noupdate -expand -group TWO_0 /hamming_weight_tb/H/SECOND_STEP(0)/TWOBITADDER/add
add wave -noupdate -expand -group TWO_1 /hamming_weight_tb/H/SECOND_STEP(1)/TWOBITADDER/a
add wave -noupdate -expand -group TWO_1 /hamming_weight_tb/H/SECOND_STEP(1)/TWOBITADDER/b
add wave -noupdate -expand -group TWO_1 /hamming_weight_tb/H/SECOND_STEP(1)/TWOBITADDER/add
add wave -noupdate -expand -group THREE /hamming_weight_tb/H/THREEBITADDER/a
add wave -noupdate -expand -group THREE /hamming_weight_tb/H/THREEBITADDER/b
add wave -noupdate -expand -group THREE /hamming_weight_tb/H/THREEBITADDER/add
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3820909588 ps} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {3820828097 ps} {3820950101 ps}
