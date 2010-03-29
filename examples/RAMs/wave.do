onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /main/dut/rams_mem1k_raminst/clk_a_i
add wave -noupdate -format Logic /main/dut/rams_mem1k_raminst/clk_b_i
add wave -noupdate -format Literal /main/dut/rams_mem1k_raminst/addr_a_i
add wave -noupdate -format Literal /main/dut/rams_mem1k_raminst/addr_b_i
add wave -noupdate -format Literal /main/dut/rams_mem1k_raminst/data_a_i
add wave -noupdate -format Literal /main/dut/rams_mem1k_raminst/data_b_i
add wave -noupdate -format Literal /main/dut/rams_mem1k_raminst/data_a_o
add wave -noupdate -format Literal /main/dut/rams_mem1k_raminst/data_b_o
add wave -noupdate -format Literal /main/dut/rams_mem1k_raminst/bwsel_a_i
add wave -noupdate -format Literal /main/dut/rams_mem1k_raminst/bwsel_b_i
add wave -noupdate -format Logic /main/dut/rams_mem1k_raminst/rd_a_i
add wave -noupdate -format Logic /main/dut/rams_mem1k_raminst/rd_b_i
add wave -noupdate -format Logic /main/dut/rams_mem1k_raminst/wr_a_i
add wave -noupdate -format Logic /main/dut/rams_mem1k_raminst/wr_b_i
add wave -noupdate -format Literal /main/dut/rams_mem1k_raminst/clksel
add wave -noupdate -format Literal /main/dut/rams_mem1k_raminst/bwsel_int_a
add wave -noupdate -format Literal /main/dut/rams_mem1k_raminst/bwsel_int_b
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {20259630 ps} 0}
configure wave -namecolwidth 524
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
update
WaveRestoreZoom {99610350 ps} {100020508 ps}
