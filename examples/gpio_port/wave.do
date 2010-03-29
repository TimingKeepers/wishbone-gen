onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /main/dut/rst_n_i
add wave -noupdate -format Logic /main/dut/wb_clk_i
add wave -noupdate -format Literal /main/dut/wb_addr_i
add wave -noupdate -format Literal /main/dut/wb_data_i
add wave -noupdate -format Literal /main/dut/wb_data_o
add wave -noupdate -format Logic /main/dut/wb_cyc_i
add wave -noupdate -format Logic /main/dut/wb_sel_i
add wave -noupdate -format Logic /main/dut/wb_stb_i
add wave -noupdate -format Logic /main/dut/wb_we_i
add wave -noupdate -format Logic /main/dut/wb_ack_o
add wave -noupdate -format Literal /main/dut/gpio_pins_b
add wave -noupdate -format Literal /main/dut/gpio_ddr
add wave -noupdate -format Literal /main/dut/gpio_psr
add wave -noupdate -format Literal /main/dut/gpio_pdr
add wave -noupdate -format Logic /main/dut/gpio_pdr_wr
add wave -noupdate -format Literal /main/dut/gpio_sopr
add wave -noupdate -format Logic /main/dut/gpio_sopr_wr
add wave -noupdate -format Literal /main/dut/gpio_copr
add wave -noupdate -format Logic /main/dut/gpio_copr_wr
add wave -noupdate -format Literal /main/dut/gpio_reg
add wave -noupdate -format Literal /main/dut/gpio_pins_sync1
add wave -noupdate -format Literal /main/dut/gpio_pins_sync0
add wave -noupdate -format Logic /main/dut/wb_slave/rst_n_i
add wave -noupdate -format Logic /main/dut/wb_slave/wb_clk_i
add wave -noupdate -format Literal /main/dut/wb_slave/wb_addr_i
add wave -noupdate -format Literal /main/dut/wb_slave/wb_data_i
add wave -noupdate -format Literal /main/dut/wb_slave/wb_data_o
add wave -noupdate -format Logic /main/dut/wb_slave/wb_cyc_i
add wave -noupdate -format Logic /main/dut/wb_slave/wb_sel_i
add wave -noupdate -format Logic /main/dut/wb_slave/wb_stb_i
add wave -noupdate -format Logic /main/dut/wb_slave/wb_we_i
add wave -noupdate -format Logic /main/dut/wb_slave/wb_ack_o
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_async_clk_i
add wave -noupdate -format Literal /main/dut/wb_slave/gpio_ddr_o
add wave -noupdate -format Literal /main/dut/wb_slave/gpio_psr_i
add wave -noupdate -format Literal /main/dut/wb_slave/gpio_pdr_o
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_pdr_wr_o
add wave -noupdate -format Literal /main/dut/wb_slave/gpio_sopr_o
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_sopr_wr_o
add wave -noupdate -format Literal /main/dut/wb_slave/gpio_copr_o
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_copr_wr_o
add wave -noupdate -format Literal /main/dut/wb_slave/gpio_ddr_int
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_ddr_swb
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_ddr_swb_delay
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_ddr_swb_s0
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_ddr_swb_s1
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_ddr_swb_s2
add wave -noupdate -format Literal /main/dut/wb_slave/gpio_psr_int
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_psr_lwb
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_psr_lwb_delay
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_psr_lwb_in_progress
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_psr_lwb_s0
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_psr_lwb_s1
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_psr_lwb_s2
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_pdr_wr_int
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_pdr_wr_int_delay
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_pdr_wr_sync0
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_pdr_wr_sync1
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_pdr_wr_sync2
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_sopr_wr_int
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_sopr_wr_int_delay
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_sopr_wr_sync0
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_sopr_wr_sync1
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_sopr_wr_sync2
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_copr_wr_int
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_copr_wr_int_delay
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_copr_wr_sync0
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_copr_wr_sync1
add wave -noupdate -format Logic /main/dut/wb_slave/gpio_copr_wr_sync2
add wave -noupdate -format Logic /main/dut/wb_slave/wb_ack_regbank
add wave -noupdate -format Literal /main/dut/wb_slave/ack_cntr
add wave -noupdate -format Logic /main/dut/wb_slave/ack_in_progress
add wave -noupdate -format Logic /main/dut/wb_slave/tmpbit
add wave -noupdate -format Literal /main/dut/wb_slave/wb_data_out_int
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 333
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
WaveRestoreZoom {0 ps} {15750 ns}
