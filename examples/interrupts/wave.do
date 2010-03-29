onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /main/dut/rst_n_i
add wave -noupdate -format Logic /main/dut/wb_clk_i
add wave -noupdate -format Literal /main/dut/wb_addr_i
add wave -noupdate -format Literal /main/dut/wb_data_i
add wave -noupdate -format Literal /main/dut/wb_data_o
add wave -noupdate -format Logic /main/dut/wb_cyc_i
add wave -noupdate -format Literal /main/dut/wb_sel_i
add wave -noupdate -format Logic /main/dut/wb_stb_i
add wave -noupdate -format Logic /main/dut/wb_we_i
add wave -noupdate -format Logic /main/dut/wb_ack_o
add wave -noupdate -format Logic /main/dut/wb_irq_o
add wave -noupdate -format Logic /main/dut/irq_ipe_i
add wave -noupdate -format Logic /main/dut/irq_ine_i
add wave -noupdate -format Logic /main/dut/irq_il0_i
add wave -noupdate -format Logic /main/dut/irq_il1_i
add wave -noupdate -format Literal /main/dut/eic_idr_int
add wave -noupdate -format Logic /main/dut/eic_idr_write_int
add wave -noupdate -format Literal /main/dut/eic_ier_int
add wave -noupdate -format Logic /main/dut/eic_ier_write_int
add wave -noupdate -format Literal /main/dut/eic_imr_int
add wave -noupdate -format Literal /main/dut/eic_isr_clear_int
add wave -noupdate -format Literal /main/dut/eic_isr_status_int
add wave -noupdate -format Logic /main/dut/eic_isr_write_int
add wave -noupdate -format Literal /main/dut/irq_inputs_vector_int
add wave -noupdate -format Literal /main/dut/ack_sreg
add wave -noupdate -format Literal /main/dut/rddata_reg
add wave -noupdate -format Literal /main/dut/wrdata_reg
add wave -noupdate -format Literal /main/dut/bwsel_reg
add wave -noupdate -format Literal /main/dut/rwaddr_reg
add wave -noupdate -format Logic /main/dut/ack_in_progress
add wave -noupdate -format Logic /main/dut/wr_int
add wave -noupdate -format Logic /main/dut/rd_int
add wave -noupdate -format Logic /main/dut/bus_clock_int
add wave -noupdate -format Literal /main/dut/allones
add wave -noupdate -format Literal /main/dut/allzeros
add wave -noupdate -format Logic /main/dut/eic_irq_controller_inst/rst_n_i
add wave -noupdate -format Logic /main/dut/eic_irq_controller_inst/clk_i
add wave -noupdate -format Literal /main/dut/eic_irq_controller_inst/irq_i
add wave -noupdate -format Literal /main/dut/eic_irq_controller_inst/reg_imr_o
add wave -noupdate -format Literal /main/dut/eic_irq_controller_inst/reg_ier_i
add wave -noupdate -format Logic /main/dut/eic_irq_controller_inst/reg_ier_wr_stb_i
add wave -noupdate -format Literal /main/dut/eic_irq_controller_inst/reg_idr_i
add wave -noupdate -format Logic /main/dut/eic_irq_controller_inst/reg_idr_wr_stb_i
add wave -noupdate -format Literal /main/dut/eic_irq_controller_inst/reg_isr_o
add wave -noupdate -format Literal /main/dut/eic_irq_controller_inst/reg_isr_i
add wave -noupdate -format Logic /main/dut/eic_irq_controller_inst/reg_isr_wr_stb_i
add wave -noupdate -format Logic /main/dut/eic_irq_controller_inst/wb_irq_o
add wave -noupdate -format Literal /main/dut/eic_irq_controller_inst/irq_mode
add wave -noupdate -format Literal /main/dut/eic_irq_controller_inst/irq_mask
add wave -noupdate -format Literal /main/dut/eic_irq_controller_inst/irq_pending
add wave -noupdate -format Literal /main/dut/eic_irq_controller_inst/irq_i_d0
add wave -noupdate -format Literal /main/dut/eic_irq_controller_inst/irq_i_d1
add wave -noupdate -format Literal /main/dut/eic_irq_controller_inst/irq_i_d2
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10200000 ps} 0}
configure wave -namecolwidth 271
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
WaveRestoreZoom {7440472 ps} {12959528 ps}
