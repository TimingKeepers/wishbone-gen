#!/usr/bin/lua

-- wbgen2, (c) 2010 Tomasz Wlostowski
--                  CERN BE-Co-HT
-- LICENSED UNDER GPL v2


------------------------------
-- HDL syntax tree constructors
------------------------------

-- assignment: dst <= src;
function va (dst, src)
  local s={};
  s.t="assign";
  s.dst=dst;
  s.src=src;
  return s;
end

-- index: name(h downto l)

function vi(name, h, l)
 local s={};
 s.t="index";
 s.name=name;
 s.h=h;
 s.l=l;
 return s;
end

-- instance of a component
function vinstance(name, component, maps)
 local s={};
 s.t="instance";
 s.name=name;
 s.component = component;
 s.maps = maps;
 return s;
end

-- port map
function vpm(to, from)
 local s={};
 s.t="portmap";
 s.to = to;
 s.from = from;
 return s;

end

-- generic map
function vgm(to, from)
 local s={};
 s.t="genmap";
 s.to = to;
 s.from = from;
 return s;

end

-- combinatorial process: process(sensitivity_list) begin {code} end process;
function vcombprocess(slist, code)
 local s={};
 s.t="combprocess";
 s.slist = slist;
 s.code=code;
 return s;
end



-- synchronous process: process(clk, rst) begin {code} end process; 
function vsyncprocess(clk, rst, code)
 local s={};
 s.t="syncprocess";
 s.clk=clk;
 s.rst=rst;
 s.code=code;
 return s;
end



-- reset in process
function vreset(level, code)
 local s={};
 s.t="reset";
 s.level=level;
 s.code=code;
 return s;
end

function vposedge(code)
 local s={};
 s.t="posedge";
 s.code=code;
 return s;
end

function vif(cond, code, code_else)
 local s={};
 s.t="if";
 s.cond={ cond };
 s.code=code;
 s.code_else=code_else;
 return s;
end

function vequal(a,b)
 local s={};
 s.t="eq";
 s.a=a;
 s.b=b;
 return s;
end

function vand(a,b)
 local s={};
 s.t="and";
 s.a=a;
 s.b=b;
 return s;
end

function vnot(a)
 local s={};
 s.t="not";
 s.a=a;
 return s;
end

function vswitch(a, code)
 local s={};
 s.t="switch";
 s.a=a;
 s.code=code;
 return s;
end

function vcase(a, code)
 local s={};
 s.t="case";
 s.a=a;
 s.code=code;
 return s;
end

function vcasedefault(code)
 local s={};
 s.t="casedefault";
 s.code=code;
 return s;
end

function vcomment(str)
 local s={};
 s.t="comment";
 s.str=str;
 return s;
end

function vsub(a,b)
 local s={};
 s.t="sub";
 s.a=a;
 s.b=b;
 return s;
end

function vothers(value)
 local s={}
 s.t="others";
 s.val=value;
 return s;
end

function vopenpin()
 local s={}
 s.t="openpin";
 return s;
end

function vundefined()
 local s={}
 s.t="undefined";
 return s;
end


-- constructor for a HDL signal
function signal(type, nbits, name, comment)
    local t = {}
    t.comment = comment;
    t.type = type;
    t.range= nbits;
    t.name = name;
    return t;
end

-- constructor for a HDL port
function port(type, nbits, dir, name, comment, is_wb)
    local t = {}
		t.comment = comment;
    t.type = type;
    t.range= nbits;
    t.name = name;
    t.dir = dir;


    if(is_wb ~= nil and is_wb) then
    	t.is_wb = true;
    else
    	t.is_wb = false;
    end
    return t;
end

global_ports = {};
global_signals = {};

function add_global_signals(s)
	table_join(global_signals, s);
end

function add_global_ports(p)
	table_join(global_ports, p);
end


function cgen_build_clock_list()
    local allclocks = tree_2_table("clock");
    local i,v;
    local clockports = {};
    
    remove_duplicates(allclocks);
    
    for i,v in pairs(allclocks) do
    	table.insert(clockports, port(BIT, 0, "in", v, "", true));
    end

    return clockports;
end

function cgen_build_siglist()
	local siglist = {};
	local i,v;
	local s;
	
	siglist = tree_2_table("signals");
	
	table_join(siglist, global_signals);
	
	return siglist;
end



function cgen_build_portlist()
		local portlist = {};
    table_join(portlist, global_ports);
    table_join(portlist, cgen_build_clock_list());
    table_join(portlist, tree_2_table("ports"));
		return portlist;
end

function cgen_find_sigport(name)
	for i,v in pairs(g_portlist) do if(name == v.name) then return v; end end
	for i,v in pairs(g_siglist) do if(name == v.name) then return v; end end
	
	die("cgen internal error: undefined signal '"..name.."'");
	
	return nil;
end

function cgen_build_signals_ports()
	g_portlist = cgen_build_portlist();
	g_siglist = cgen_build_siglist();
end

cur_indent = 0;

function indent_zero()
	cur_indent=0;
end

function indent_left()
	cur_indent = cur_indent - 1;
end

function indent_right()
	cur_indent = cur_indent + 1;
end


function cgen_new_snippet()
	emit_code = "";
end

function emiti()
	local i;
	for i = 1,cur_indent do emit_code=emit_code.."  "; end
end

function emit(s)
	local i;
	
	for i = 1,cur_indent do emit_code=emit_code.."  "; end
	emit_code=emit_code..s.."\n";
end

function emitx(s)
	emit_code=emit_code..s;
end

function cgen_get_snippet()
  return emit_code;
end

function cgen_write_current_snippet()
	output_code_file.write(output_code_file, emit_code);
end

function cgen_write_snippet(s)
	output_code_file.write(output_code_file, s);
end


function cgen_generate_init(filename)
	output_code_file = io.open(filename, "w");
	if(output_code_file == nil) then
		die("Can't open code output file: "..filename);
	end
end

function cgen_generate_done()
	output_code_file.close(output_code_file);
end

function cgen_gen_vlog_constants(filename)
	local file = io.open(filename, "w");
 
 	if(file == nil) then
 		die("can't open "..filename.." for writing.");
 	end
	 
	  foreach_reg({TYPE_REG}, function(reg) 
				file.write(file, string.format("`define %-30s %d'h%x\n", "ADDR_"..string.upper(periph.hdl_prefix.."_"..reg.hdl_prefix), address_bus_width+2, (DATA_BUS_WIDTH/8) * reg.base));
			end);
		
		
		foreach_reg({TYPE_RAM}, function(reg) 
				local base = reg.select_bits * 
										 math.pow (2, address_bus_width - address_bus_select_bits);				
				file.write(file, string.format("`define %-30s %d'h%x\n", "BASE_"..string.upper(periph.hdl_prefix.."_"..reg.hdl_prefix), address_bus_width+2, (DATA_BUS_WIDTH/8) *base));
				file.write(file, string.format("`define %-30s 32'h%x\n", "SIZE_"..string.upper(periph.hdl_prefix.."_"..reg.hdl_prefix), reg.size));
		end);

	io.close(file);
end
