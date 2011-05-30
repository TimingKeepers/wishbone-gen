#!/usr/bin/lua

-- Copyright, 2010 Tomasz Włostowski, CERN BE-Co-HT
-- 
-- This file is part of wbgen2.
-- wbgen2 is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, version 2 (and only version 2, not any later version)
--
-- wbgen2 is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
-- General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with wbgen2; see the file COPYING. If not, write to the
-- Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
-- MA 02111-1307, USA.
--

wbgen2_version="0.6.1-alpha"

options = {};
options.reset_type = "asynchronous";
options.target_interconnect = "wb-classic";
options.register_data_output = false;
options.lang = "vhdl";
options.c_reg_style = "struct";
options.hdl_reg_style = "signals";

require "alt_getopt"

local usage_string = [[slave Wishbone generator
  wbgen2 [options] input_file.wb]]

local commands_string = [[options:
  -C, --co=FILE           Write the slave's generated C header file to FILE
  -D, --doco=FILE         Write the slave's generated HTML documentation to FILE
  -h, --help              Show this help text
  -l, --lang=LANG         Set the output Hardware Description Language (HDL) to LANG
                          Valid values for LANG: {vhdl,verilog}
  -s, --cstyle=STYLE      Set the style of register bank in generated C headers
                          Valid values for STYLE: {struct, defines}
  -H, --hstyle=STYLE      Set the style of register signals in generated VHDL/Verilog file
                          Valid values for STYLE: {signals, record}
  -K, --constco=FILE      Populate FILE with Verilog output (mainly constants)
  -v, --version           Show version information
  -V, --vo=FILE           Write the slave's generated HDL code to FILE
  -p, --vpo=FILE          Generate a VHDL package for slave's generated VHDL
                          (necessary with --hstyle=record)

wbgen2 (c) Tomasz Wlostowski/CERN BE-CO-HT 2010]]

function usage()
	 print(usage_string)
	 print("Try `wbgen2 -h' for more information")
end

function usage_complete()
	 print(usage_string)
	 print(commands_string)
end

function parse_args(arg)
	local long_opts = {
	   help		= "h",
	   version	= "v",
	   co		= "C",
	   doco		= "D",
	   constco	= "K",
	   lang		= "l",
	   vo		= "V",
           vpo          = "p",
	   cstyle       = "s",
           hstyle       = "H"
	}

	local optarg
	local optind

	optarg,optind = alt_getopt.get_opts (arg, "hvC:D:K:l:V:s:H:p:", long_opts)
	for key,value in pairs (optarg) do
		if key == "h" then
			usage_complete()
			os.exit(0)

		elseif key == "v" then
			print("wbgen2 version "..wbgen2_version)
			os.exit(0)

		elseif key == "C" then
			options.output_c_header_file = value

		elseif key == "D" then
			options.output_doc_file = value

		elseif key == "K" then
			options.output_vlog_constants_file = value

		elseif key == "l" then
			options.lang = value
			if (options.lang ~= "vhdl" and options.lang ~= "verilog") then
				die("Unknown HDL: "..options.lang);
			end

		elseif key == "s" then
		   options.c_reg_style = value;
		   if (options.c_reg_style ~= "struct" and options.c_reg_style ~= "defines") then
		      die("Unknown C RegBank style: "..options.c_reg_style);
		   end

		elseif key == "V" then
			options.output_hdl_file = value
		elseif key == "p" then
                   options.output_package_file = value
                elseif key == "H" then
			if (value ~= "signals" and value ~= "record") then
				die("Unknown register style: "..value);
			end
                        options.hdl_reg_style = value
                     end

	end

	if(arg[optind] == nil) then
		usage()
		os.exit(0)
	end

	input_wb_file = arg[optind];
end

parse_args(arg);

dofile(input_wb_file);

if(periph == nil) then die ("missing peripheral declaration"); end

    

foreach_field( fix_prefix );
foreach_field( fix_access );

foreach_reg(ALL_REG_TYPES, fix_prefix );

periph = fix_prefix(periph);

wbgen_count_subblocks();
wbgen_generate_eic();										

foreach_reg(ALL_REG_TYPES, fix_prefix );


foreach_reg(ALL_REG_TYPES, function(reg) 
	reg.total_size=0; 
	reg.current_offset = 0;
	reg.current_offset_unaligned = 0;
end);


foreach_field(calc_size);
foreach_reg({TYPE_REG, TYPE_RAM, TYPE_FIFO}, check_max_size);
foreach_field(calc_field_offset);

foreach_reg({TYPE_FIFO}, gen_code_fifo);

foreach_field(calc_num_fields);



foreach_reg({TYPE_REG, TYPE_RAM, TYPE_FIFO}, calc_address_sizes);

assign_addresses();

tree=gen_bus_logic_wishbone();

cgen_build_signals_ports();

if(options.output_hdl_file ~= nil) then
   if (options.lang == "vhdl") then
      cgen_generate_vhdl_code(tree);
   elseif (options.lang == "verilog") then
      --		cgen_generate_verilog_code(tree);
   end
end

if(options.output_c_header_file ~= nil) then
	cgen_generate_init(options.output_c_header_file)
	cgen_generate_c_header_code();
	cgen_generate_done();
end

if(options.output_vlog_constants_file ~= nil) then
	cgen_gen_vlog_constants(options.output_vlog_constants_file);
end

if(options.output_doc_file ~= nil) then
	cgen_generate_init(options.output_doc_file);
	cgen_generate_documentation();
	cgen_generate_done();
end

