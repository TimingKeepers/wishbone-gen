SOURCES = cgen_c_headers.lua  cgen_common.lua  cgen_verilog.lua  cgen_vhdl.lua  target_wishbone.lua  wbgen_common.lua  wbgen_main.lua  wbgen_rams.lua  wbgen_regbank.lua  wbgen_eic.lua
OUTPUT = wbgen2

VHDL_LIBRARY = lib/wbgen2_dpssram.vhd lib/wbgen2_eic.vhd
VERILOG_LIBRARY = $(VHDL_LIBRARY:.vhd=.v)

all:	$(SOURCES) 
#		make -C utils/vhd2vl/src
		./utils/process_dofiles.lua wbgen_main.lua wbgen2
		chmod +x wbgen2

%.v:	%.vhd
		./utils/vhd2vl/src/vhd2vl $^ > $@