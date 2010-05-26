set input_wb_file "interrupts.wb"
set test_module "wb_test_interrupts"
set target "classic"
set lang "vhdl"

set library_files {
   "../../lib/wbgen2_pkg.vhd"
   "../../lib/wbgen2_eic.vhd"
};

vlib work
vlib wbgen2

foreach file $library_files { vcom -work wbgen2 $file }

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



../../wbgen2 -V $target_filename -K ./output/vlog_constants.v -C ./output/regdefs.h -l $lang $input_wb_file

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

