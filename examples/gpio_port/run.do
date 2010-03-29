set input_wb_file "gpio_port.wb"
set test_module "gpio_port"
set target "classic"
set lang "vhdl"

set library_files {}
set extra_files { "gpio_port.vhd" };

mkdir -p ./output
vlib work
vlib wbgen2

foreach file $library_files { vcom -work wbgen2 $file }
foreach file $extra_files { vcom -work work $file }

if { $lang == "vhdl" } {
   set target_filename  [format "./output/%s.vhd" $test_module ]
   set target_wb "+define+WB_USE_CLASSIC"
   set wbgen_opt "-target classic"
} else {
   set target_filename  [format "./output/%s.v" $test_module ]
   set target_wb "+define+WB_USE_PIPELINED"
   set wbgen_opt "-target pipelined"
}
puts $target_filename



../../wbgen2 $input_wb_file -vo $target_filename -consto ./output/vlog_constants.v -co ./output/regdefs.h -lang $lang $wbgen_opt

if { $lang == "verilog" } {
   vlog -work work -work wbgen2 $target_filename
} else {
   vcom -work work $target_filename
}

vlog ./testbench.v

vsim work.main
radix -hexadecimal

do wave.do

run 100us
wave zoomfull

