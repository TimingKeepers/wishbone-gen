vlib work

../../wbgen2.lua gpio_port_async.wb -vo ./output/wb_slave_gpio_port_async.vhdl -consto ./output/vlog_constants.v

vcom ./output/wb_slave_gpio_port_async.vhdl
vcom ./gpio_port_async.vhdl

vlog ./testbench.v


vsim work.main
radix -hexadecimal
do wave.do

run 15us
wave zoomfull

