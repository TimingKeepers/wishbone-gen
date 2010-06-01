onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /main/tsf_wr_req
add wave -noupdate -format Logic /main/tsf_wr_full
add wave -noupdate -format Logic /main/tsf_wr_empty
add wave -noupdate -format Literal /main/tsf_wr_usedw
add wave -noupdate -format Literal /main/tsf_val_r
add wave -noupdate -format Literal /main/tsf_val_f
add wave -noupdate -format Literal /main/tsf_pid
add wave -noupdate -format Literal /main/tsf_fid
add wave -noupdate -format Literal /main/dut/ft_tsf_in_int
add wave -noupdate -format Literal /main/dut/ft_tsf_out_int
add wave -noupdate -format Logic /main/dut/ft_tsf_rdreq_int
add wave -noupdate -format Logic /main/dut/ft_tsf_rdreq_int_d0
add wave -noupdate -format Logic /main/memacc_rd_req
add wave -noupdate -format Logic /main/memacc_rd_full
add wave -noupdate -format Logic /main/memacc_rd_empty
add wave -noupdate -format Literal /main/memacc_rd_usedw
add wave -noupdate -format Logic /main/memacc_ad_sel
add wave -noupdate -format Literal /main/memacc_ad
add wave -noupdate -format Logic /main/clk
add wave -noupdate -format Logic /main/rst
add wave -noupdate -format Logic /main/dut/ft_memacc_inst/wr_req_i
add wave -noupdate -format Literal /main/dut/ft_tsf_inst/rd_data_o
add wave -noupdate -format Logic /main/dut/ft_tsf_inst/rd_req_i
add wave -noupdate -format Logic /main/dut/ft_tsf_inst/rd_empty_o
add wave -noupdate -format Logic /main/dut/ft_tsf_inst/rd_full_o
add wave -noupdate -format Literal /main/dut/ft_tsf_inst/rd_usedw_o
add wave -noupdate -format Logic /main/dut/ft_tsf_rdreq_int
add wave -noupdate -format Logic /main/dut/ft_tsf_rdreq_int_d0
add wave -noupdate -format Literal /main/WB/wb_addr
add wave -noupdate -format Literal /main/WB/wb_data_o
add wave -noupdate -format Literal /main/WB/wb_bwsel
add wave -noupdate -format Literal /main/WB/wb_data_i
add wave -noupdate -format Logic /main/WB/wb_ack
add wave -noupdate -format Logic /main/WB/wb_cyc
add wave -noupdate -format Logic /main/WB/wb_stb
add wave -noupdate -format Logic /main/WB/wb_we
add wave -noupdate -format Logic /main/WB/wb_rst
add wave -noupdate -format Logic /main/WB/wb_clk
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {637405 ps} 0}
configure wave -namecolwidth 288
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
WaveRestoreZoom {124709 ps} {1150101 ps}
