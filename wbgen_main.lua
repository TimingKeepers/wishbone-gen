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

wbgen2_version="0.6.0"

options = {};
options.reset_type = "asynchronous";
options.target_interconnect = "wb-classic";
options.register_data_output = false;
options.lang = "vhdl";

function my_dofile(name)
	dofile("~/wbgen2_svn/wbgen2/"..name);
end

my_dofile("wbgen_common.lua");
my_dofile("cgen_common.lua");
my_dofile("cgen_vhdl.lua");
my_dofile("cgen_verilog.lua");
my_dofile("cgen_c_headers.lua");
my_dofile("cgen_doc.lua");
my_dofile("wbgen_regbank.lua");
my_dofile("wbgen_rams.lua");
my_dofile("wbgen_eic.lua");
my_dofile("target_wishbone.lua");


function parse_args(arg)
	local n=1;

	if(arg[1] == nil) then
		print("wbgen2 version "..wbgen2_version);
		print("(c) Tomasz Wlostowski/CERN BE-Co-HT 2010");
		print("");
		print("usage: "..arg[0].." input_file.wb [options]");
		print("");
		print("Options: ");
		print("-target [classic / pipelined]   - chooses between classic Wishbone bus and HT pipelined Wishbone.");
		print("-lang   [vhdl / verilog]        - chooses the HDL language to be generated");
		print("-vo     [file.vhdl / file.v]    - generates VHDL/Verilog code for the slave Wishbone core.");
		print("-co     [file.h]                - generates C header file containing register definitions and access macros");
		print("-consto [constants.v]           - generates Verilog file containing addresses of all registers/rams and writes them to specified file. Useful for writing testbenches.");
		print("-doco   [documentation.html]    - generates nice HTML documentation and writes it to specified file.");

		print("");
		os.exit(0);
	end
	
	input_wb_file = arg[1];

	vhdl_gen_reg_constants = false;
	vlog_gen_reg_constants = false;

	n=2;
	while(arg[n] ~= nil) do
		local sw = arg[n];
		
		if (sw == "-vo") then
			options.output_hdl_file = chk_nil(arg[n+1], "HDL output filename expected");
			n=n+2;
		elseif (sw == "-co") then
			options.output_c_header_file = chk_nil(arg[n+1], "C header output filename expected");
			n=n+2;
		elseif (sw == "-consto") then
			options.output_vlog_constants_file = chk_nil(arg[n+1],"Verilog constants filename expected");
			n=n+2;
		elseif (sw == "-doco") then
			options.output_doc_file = chk_nil(arg[n+1],"Documentation filename expected");
			n=n+2;
		elseif (sw == "-lang") then
			options.lang = chk_nil(arg[n+1],"Target HDL language name expected");
			if (options.lang ~= "vhdl" and options.lang ~= "verilog") then
				die("Unknown HDL: "..options.lang);
			end
			n=n+2;
		else
			n=n+1;
		end
	
	end

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
	reg.current_offset=0;
end);


foreach_field(calc_size);
foreach_reg({TYPE_REG, TYPE_RAM, TYPE_FIFO}, check_max_size);
foreach_field(calc_field_offset);

foreach_reg({TYPE_REG, TYPE_RAM, TYPE_FIFO}, calc_address_sizes);

assign_addresses();

tree=gen_bus_logic_wishbone();

cgen_build_signals_ports();

if(options.output_hdl_file ~= nil) then
	cgen_generate_init(options.output_hdl_file)
	if (options.lang == "vhdl") then
		cgen_generate_vhdl_code(tree);
	elseif (options.lang == "verilog") then
		cgen_generate_verilog_code(tree);
	end
	
	cgen_generate_done();
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

