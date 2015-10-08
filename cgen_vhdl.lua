-- -*- Mode: LUA; tab-width: 2 -*-

-- wbgen2, (c) 2010 Tomasz Wlostowski/CERN BE-Co-HT
-- LICENSED UNDER GPL v2

-- File: cgen_vhdl.lua
--
-- The VHDL code generator.
--

-- conversion table between VHDL data types and wbgen2 internal data types
fieldtype_2_vhdl={};
fieldtype_2_vhdl[BIT]="std_logic";
fieldtype_2_vhdl[MONOSTABLE]="std_logic";
fieldtype_2_vhdl[SIGNED] = "signed";
fieldtype_2_vhdl[UNSIGNED] = "unsigned";
fieldtype_2_vhdl[ENUM] = "std_logic_vector";
fieldtype_2_vhdl[SLV] = "std_logic_vector";


-- generates a string containing VHDL-compatible numeric constant of value [value] and size [numbits]
function gen_vhdl_bin_literal(value, numbits)
 if(numbits == 1) then
	 return string.format("'%d'", csel(value==0,0,1));
 end

    local str ='\"';
    local i,n,d,r;
    
    n=value;
    r=math.pow(2, numbits-1);

		if(value == nil) then
	    for i=1,numbits do
				str=str.."X";
			end    
    else
    for i=1,numbits do
			d=math.floor(n/r);
			str=str..csel(d>0,"1","0");
			n=n%r;
			r=r/2;
    end
    
    end
    return str..'\"';
 end

function strip_periph_prefix(s)
   return string.gsub(s, "^"..periph.hdl_prefix.."\_", "")
end

-- fixme: do this neatly
function port2record(s)
   if(options.hdl_reg_style ~= "record") then
      return s
   end

   for i,port in ipairs(g_portlist) do
      if(port.name == s and port.is_reg_port) then
		      return csel(port.dir=="in", "regs_i.", "regs_o.")..strip_periph_prefix(s)
      end
   end
   return s
end


function cgen_vhdl_package()
	local pkg_name = periph.hdl_prefix.."_wbgen2_pkg";
   emit("package "..pkg_name.." is")
   indent_right();
   emit("");


   emit("");
   emit("-- Input registers (user design -> WB slave)");
   emit("");
	
	 cgen_vhdl_port_struct("in");

   emit("");
   emit("-- Output registers (WB slave -> user design)");
   emit("");

	 cgen_vhdl_port_struct("out");
	   

   
   indent_left();

 	 local typename = "t_"..periph.hdl_prefix.."_in_registers";

   emit("function \"or\" (left, right: "..typename..") return "..typename..";");
   emit("function f_x_to_zero (x:std_logic) return std_logic;");
   emit("function f_x_to_zero (x:std_logic_vector) return std_logic_vector;");

   indent_left();
   indent_left();
   emit("end package;");
   
   emit("");
   emit("package body "..pkg_name.." is");

   emit("function f_x_to_zero (x:std_logic) return std_logic is");
   emit("begin")
--	 emit("if x = '1' then")
--   emit("return '1';")
--   emit("else")
--	 emit("return '0';")
--	 emit("end if;")
	 emit("return x;")
   emit("end function;");

   emit("function f_x_to_zero (x:std_logic_vector) return std_logic_vector is");
	 emit("variable tmp: std_logic_vector(x'length-1 downto 0);");
   emit("begin");
   emit("for i in 0 to x'length-1 loop");
--   emit("if(x(i) = 'X' or x(i) = 'U') then");
--   emit("tmp(i):= '0';");
--   emit("else");
   emit("tmp(i):=x(i);");
--   emit("end if; ");
   emit("end loop; ");
   emit("return tmp;");
   emit("end function;");
   
   

   emit("function \"or\" (left, right: "..typename..") return "..typename.." is");
   emit("variable tmp: "..typename..";");
   emit("begin");

   for i=1,table.getn(g_portlist) do
      local port = g_portlist[i];
      if(port.is_reg_port == true and port.dir == "in") then
      	local n = strip_periph_prefix(port.name);
					emit("tmp."..n.." := f_x_to_zero(left."..n..") or f_x_to_zero(right."..n..");");
      end
   end
	 emit("return tmp;");   
   emit("end function;");
   
   emit("end package body;");
end

function cgen_vhdl_port_struct(direction)

   emit("type t_"..periph.hdl_prefix.."_"..direction.."_registers is record");
   indent_right();

   local p_list= {};
   
   for i=1,table.getn(g_portlist) do
      local port = g_portlist[i];
      if(port.is_reg_port == true and port.dir == direction) then
         table.insert(p_list, port);
      end
   end

   for i,port in ipairs(p_list) do
   		local ptype = csel(port.type == SLV and port.range == 1, "std_logic", fieldtype_2_vhdl[port.type]);
      local line = string.format("%-40s : %s", strip_periph_prefix(port.name), ptype);

      if(port.range > 1) then
         line = line.."("..(port.range-1).." downto 0)";
      end    

      line = line..";";
      emit(line);
   end

   emit("end record;");
   indent_left();
   emit("");
   emit("constant c_"..periph.hdl_prefix.."_"..direction.."_registers_init_value: t_"..periph.hdl_prefix.."_"..direction.."_registers := (");
   indent_right();
      
   for i=1,table.getn(p_list) do
      local port = p_list[i];
      line = strip_periph_prefix(port.name).." => ";
      if(port.range > 1) then
        line = line.."(others => '0')"
          else
        line = line.."'0'"
        end
                if(i ~= table.getn(p_list)) then
              line = line..",";
            end
      
            emit(line);
         end
      emit(");");

end

-- function generates a VHDL file header (some comments and library/package include definitions).
function cgen_vhdl_header(file_name)
    emit("---------------------------------------------------------------------------------------");
    emit("-- Title          : Wishbone slave core for "..periph.name);
    emit("---------------------------------------------------------------------------------------");
    emit("-- File           : "..file_name);
    emit("-- Author         : auto-generated by wbgen2 from "..input_wb_file);
    emit("-- Created        : "..os.date());
    emit("-- Standard       : VHDL'87");
    emit("---------------------------------------------------------------------------------------");
    emit("-- THIS FILE WAS GENERATED BY wbgen2 FROM SOURCE FILE "..input_wb_file);
    emit("-- DO NOT HAND-EDIT UNLESS IT'S ABSOLUTELY NECESSARY!");
    emit("---------------------------------------------------------------------------------------");
		emit("");
		emit("library ieee;");
		emit("use ieee.std_logic_1164.all;");
		emit("use ieee.numeric_std.all;");

-- do we have RAMs or FIFOs? - if yes, include the wbgen2 components library.
		if(periph.ramcount > 0 or periph.fifocount > 0 or periph.irqcount > 0) then
--			emit("library wbgen2;");
			emit("use work.wbgen2_pkg.all;");
		end

		emit("");
end


-- function generates VHDL entity header (ports and generics) and beginning of ARCHITECTURE block (signal and constant definitions).
function cgen_vhdl_entity()
	local last;

   if(options.hdl_reg_style == "record") then
      emit("use work."..periph.hdl_prefix.."_wbgen2_pkg.all;");
      emit("\n");
   end

	emit ("entity "..periph.hdl_entity.." is");
  indent_right();

  if(table.getn(g_optlist) ~= 0) then
     emit ("generic (");
     indent_right();
     emiti()

     for i,v in pairs(g_optlist) do
        emiti();
        emitx(v.." : integer := 1");
        if(i ~= table.getn(g_optlist)) then
           emit(";")
        else
           emit(");")
        end
     end
     indent_left();
  end

  indent_left();

	indent_right();
  emit ("port (");
	indent_right();

-- emit the ports.
  for i=1,table.getn(g_portlist) do
		local port = g_portlist[i];

    if(options.hdl_reg_style == "signals" or not port.is_reg_port) then

       -- if we have a comment associated with current port, let's emit it before the port definition.
       if(port.comment ~= nil and port.comment ~= "") then
          emitx("-- "..port.comment.."\n");
       end
       
--       print(port.name.." "..port.type)
       -- generate code for the port
       local line = string.format("%-40s : %-6s %s", port.name, port.dir, fieldtype_2_vhdl[port.type]);

       if(port.range > 1 or port.type == SLV) then
          line = line.."("..(port.range-1).." downto 0)";
       end    

       -- eventually append a semicolon
       line=line..csel((i == table.getn(g_portlist)) and not (options.hdl_reg_style == "record"), "", ";");

       -- and spit out the line
       emit(line);
    end
  end

  if(options.hdl_reg_style == "record") then
     emit(string.format("%-40s : %-6s %s", "regs_i", "in", "t_"..periph.hdl_prefix.."_in_registers;"));
     emit(string.format("%-40s : %-6s %s", "regs_o", "out", "t_"..periph.hdl_prefix.."_out_registers"));
  end
    
	indent_left();
 	emit(");");
	indent_left();
	emit("end "..periph.hdl_entity..";");
	emit("");

-- generate the ARCHITECTURE block with signal definitions

	emit("architecture syn of "..periph.hdl_entity.." is");
	emit("");

-- we do it the same way as for the ports. 
	for i,v in pairs (g_siglist) do
		s=string.format("signal %-40s : %-15s", v.name, fieldtype_2_vhdl[v.type]);
		if(v.range > 0 and v.type ~= BIT) then
			s=s..string.format("(%d downto 0)", v.range-1);
		end
		s=s..";";
		emit(s);
	end

	emit("");

	emit("begin");
	indent_right();

--   if(options.hdl_reg_style == "record") then
--      emit("regs_b <= c_"..periph.hdl_prefix.."_registers_init_value;");
--   end
end

-- function generates the ending of VHDL file - in our case an END statement, closing the single ARCHITECTURE block.
function cgen_vhdl_ending()
	indent_left();
	emit("end syn;");
end

-- This is the main code generator function. It takes a syntax tree [tree], and traverses it recursively, producing VHDL code.
-- Note that it supports only a small subset of VHDL language which is used by slave cores. All the following functions are private.
function cgen_generate_vhdl_code(tree)

	-- function searches for a subnode of type [t] in node [node].
	function find_code(node, t)
		for i,v in ipairs(node) do if ((v.t ~= nil) and (v.t == t)) then return v; end end
		return nil;
	end

	-- function generates a synchronous process, e.g. a process which looks like:
	-- process (clk, rst)
	-- if(rst)
	-- [put code from vreset subnode here]
	-- elsif rising_edge(clk)
	-- [put code from vposedge subnode here]
	-- end 

	function cgen_vhdl_syncprocess(node)
		emit("process ("..node.clk..", "..node.rst..")");
		emit("begin");
		indent_right();

	-- search for reset and posedge subnodes. 			
		local vrst = find_code(node.code, "reset");
		local vpe = find_code(node.code, "posedge");

	-- no posedge block - then what our process is supposed to be doing? :D			
		if(vpe == nil) then die("vhdl code generation error: no vposedge defined for vsyncprocess"); end
			
	-- generate the process body depending on the type of reset (sync/async)
		if(options.reset_type == "asynchronous") then
			if(vrst ~= nil) then
				emit("if ("..node.rst.." = '"..vrst.level.."') then ");
				indent_right();

	-- recursively emit the vreset subnode
				recurse(vrst.code);
				indent_left();
	
				emit("elsif rising_edge("..node.clk..") then");
				indent_right();
		
			else
				emit("if rising_edge("..node.clk..") then");			
				indent_right();
			end

	-- -- recursively emit the vposedge
			recurse(vpe.code);		
			indent_left();
	 	  emit("end if;");
			
		else -- the same as above, but with synchronous reset
			emit("if rising_edge("..node.clk..") then");
			indent_right();
			
			if(vrst ~= nil) then
				 emit("if ("..node.rst.." = '"..vrst.level.."') then ");
				 indent_right();
				 recurse(vrst.code);
				 indent_left();
				 emit("else ");
			end
	 		  
			indent_right();
			recurse(vpe.code); 		  
			indent_left();
			emit("end if;");
			indent_left();
			emit("end if;");
		end
		indent_left();

		emit("end process;");	
		emit("");
		emit("");
	end

-- emits a VHDL combinatorial process
	function cgen_vhdl_combprocess(node)
		local first_one = true;
		emiti();
		emitx("process (");

		for i,v in pairs(node.slist) do
			if(first_one) then
				first_one = false;
			else
				emitx(", ");
			end
			emitx(v);
		end
		
		emit(")");
		emit("begin");

		indent_right();
		recurse(node.code);
		indent_left();

		emit("end process;");	
		emit("");
		emit("");
	end


	-- function takes a node and determines it's type, value and range 
	function node_typesize(node)
		local ts = {};
		local sig;

--		print("tsize",node);

		ts.node = node;

	-- if it's a direct signal or a numeric constant, it simply returns it.

	-- our node is a LUA table, which most likely means that it's a non-terminal leaf of syntax tree.
		if(type(node) == "table") then

	-- if the subnode is of type vi (indexed signal)
			if(node.t ~= nil and node.t == "index") then

	-- find the definition of the signal to determine its VHDL type.
				sig = cgen_find_sigport(node.name);

	-- and extract indexing bondaries (h downto l)
				ts.h=node.h;
				ts.l=node.l;
				ts.name=sig.name;
				ts.type=sig.type;
				
					if(ts.l == nil) then
						ts.size = 1;
						ts.type = BIT;
					else
						ts.size = ts.h-ts.l+1;
					end
			
				return ts;
			elseif(node.t ~= nil and node.t == "undefined") then
				ts.type = UNDEFINED;
				return ts;

	-- if the subnode is not of "vi" type, treat is as an expression (arithmetic, logic, etc.)
		 	else
					ts.type = EXPRESSION;
					ts.code = node;
					return ts;
			end

	-- node is a LUA string - it's a signal or port. Determine its type, range and return it to the caller.
		 elseif(type(node) == "string") then
			sig = cgen_find_sigport(node);
			ts.size = sig.range;
			ts.type = sig.type;
			ts.name = node;
			return ts;

	-- node is a LUA number - just return it, the caller should take care of range/type determination depending on the assignment target.
		 elseif(type(node) == "number") then
			ts.type = INTEGER;
			ts.name = node;
			ts.size = 0;
			return ts;
		else 
			die("vhdl cgen internal error: node_typesize got an unknown node.");
		end
	end

	-- generates the signal name with subrange (if applies): signame, signame(h downto l) or signame(h). 
	function gen_subrange(t)
     local n = port2record(t.name);
		-- node is a VHDL "open" pin declaration?

     if(type(t.node) == "table" and t.node.t == "openpin") then
        return "open";
     end

		--print("gensub: ", t.name);

		if (t.h ~= nil and ( t.l == nil or (t.l == t.h))) then
			return n.."("..t.h..")";
		elseif(t.h ~= nil and t.l ~= nil) then
			return n.."("..t.h.." downto "..t.l..")";
		else
			return n;
		end
	end

	-- calculates bit-size of a signal
	function calc_size(t)
		if(t.h ~= nil and t.l == nil) then
			return 1;
		elseif(t.h ~= nil and t.l ~= nil) then
			return t.h-t.l+1; 
		else
			local sig= cgen_find_sigport(t.name);
			return sig.range;
		end
	end

	-- WARNING! UGLY CODE!
	-- generates a VHDL type-conversion code for assignment between tsd (destination node) and tss (source node).
	function gen_vhdl_typecvt(tsd, tss)

	-- print("Gen_typecvt:",  tsd.name);
	-- print("Gen_typecvt:",  tss.name, tss.type);

	-- types match? Coool, we have nothing to do
		if(tsd.type == tss.type) then 
			return(gen_subrange(tss));

		elseif (tss.type == UNDEFINED) then
			return "'X'"
	-- dest: bit/slv/signed/unsigned <= src: numeric_constant;
		elseif (tss.type == INTEGER) then

			if(tsd.type == BIT) then 
				return("'"..tss.name.."'");
			elseif(tsd.type == SLV) then
--				return("std_logic_vector(to_unsigned("..tss.name..", "..calc_size(tsd).."))");
					return gen_vhdl_bin_literal(tss.name, calc_size(tsd));
			elseif(tsd.type == SIGNED) then
				return("to_signed("..tss.name..", "..calc_size(tsd)..")");
			elseif(tsd.type == UNSIGNED) then
				return("to_unsigned("..tss.name..", "..calc_size(tsd)..")");
			else die ("unsupported assignment: "..tsd.name.." "..tss.name); end	

	-- dest: bit <= src: SLV
		elseif (tss.type == BIT) then

			if(tsd.type == SLV) then
				return(gen_subrange(tss));
			else die ("unsupported assignment: "..tsd.name.." "..tss.name); end	

		elseif (tss.type == SIGNED or tss.type == UNSIGNED) then

	-- dest: slv <= src: signed/unsigned
			if(tsd.type == SLV) then
				return("std_logic_vector("..gen_subrange(tss)..")");
		 else die ("unsupported assignment: "..tsd.name.." "..tss.name); end	

		elseif (tss.type == SLV) then

	-- dest: signed/unsigned <= src: slv
			if(tsd.type == SIGNED) then
				return("signed("..gen_subrange(tss)..")");
			elseif (tsd.type == UNSIGNED) then
--					print(tss);
				return("unsigned("..gen_subrange(tss)..")");
		 elseif (tsd.type == BIT) then
				return gen_subrange(tss);
		 else 
				die ("unsupported assignment: "..tsd.name.." "..tss.name); end	
		 
		else die ("unsupported assignment: "..tsd.name.." "..tss.name); end	
	end

	-- function generates VHDL code for assignment-type node (node.src <= node.dst).
	function cgen_vhdl_assign(node)
	-- determine types and ranges of source and destination node.
		local tsd = node_typesize(node.dst);
		local tss = node_typesize(node.src);

	--	print(tsd.name);

	-- source node is an expression? - recurse it
		if(tss.type == EXPRESSION) then
			emiti();
		--	print(gen_subrange(tsd));
			emitx(gen_subrange(tsd).." <= ");
			recurse({tss.code});
			emitx(";\n");
		else
	-- not an expression? - assign the destination with proper type casting.
			emit(gen_subrange(tsd).." <= "..gen_vhdl_typecvt(tsd, tss)..";");
		end
	end

	-- function generates an if..else..end if control block.
	function cgen_vhdl_if(node)

		emiti(); emitx("if (");
	-- recurse the condition block
		recurse(node.cond);
		emitx(") then\n");

	-- "if..else" construct
		if(node.code_else ~= nil) then
			indent_right();		recurse(node.code);		indent_left();
			emit("else");
			indent_right();		recurse(node.code_else);		indent_left();
			emit("end if;");
	-- just "if" construct
		else
			indent_right();	recurse(node.code);	indent_left();
			emit("end if;");
		end
	end

	-- function generates an if..else..end if control block.
	function cgen_vhdl_generate_if(node)
     if(g_gen_block_count == nil) then
        g_gen_block_count = 0
     else
        g_gen_block_count = g_gen_block_count + 1
     end
     
     gname = string.format("genblock_%d", g_gen_block_count)
		emiti(); emitx(gname..": if (");
	-- recurse the condition block
		recurse(node.cond);
		emitx(") generate\n");

    indent_right();	recurse(node.code);	indent_left();
    emit("end generate "..gname..";");
 end


	-- function generates a NOT unary expression.
	function cgen_vhdl_not(node)
	-- check type of node to be NOTed
		local tsa = node_typesize(node.a);

		emitx("not ");

	-- recurse
		if(tsa.type == EXPRESSION) then
			emitx("("); recurse({node.a}); emitx(")");
		else
	-- or emit the value/signal
			emitx(gen_subrange(tsa));
	 end
	end


	-- function generates code for a VHDL binary expression.
	function cgen_vhdl_binary_op(node)


		local tsa = node_typesize(node.a);
		local tsb = node_typesize(node.b);
		local op=node.t;


	-- emit the left-side operand
		if(tsa.type == EXPRESSION) then
			emitx("("); recurse({node.a}); emitx(")");
		else
			emitx(gen_subrange(tsa));
		end

	-- emit the operator
		if(op=="eq") then emitx(" = "); end
		if(op=="and") then emitx(" and "); end
		if(op=="or") then emitx(" or "); end
		if(op=="sub") then emitx(" - "); end
		if(op=="add") then emitx(" + "); end

	-- ..and the right-side operand
		if(tsb.type == EXPRESSION) then
			emitx("("); recurse({node.b}); emitx(")");
		else
			emitx(gen_vhdl_typecvt(tsa, tsb));
		end
	end


	-- 
	function cgen_vhdl_comment(node)
--	print("COMMENT: "..node.str);
		emitx("-- "..node.str.."\n");
	end


	-- function generates VHDL switch/case statement
	function cgen_vhdl_switch(node)

		local tsa = node_typesize(node.a);

		emiti(); emitx("case ");

	-- recurse the case header: case (expression) is
		if(tsa.type == EXPRESSION) then
			emitx("("); recurse({node.a}); emitx(")");
		else
			local tsb = {};
			tsb.type = SLV;
			emitx(gen_vhdl_typecvt(tsb, tsa));
		end	

		emitx(" is\n");

	-- iterate all the subnodes
		for i,v in pairs(node.code)  do

	-- it's a case match:
			if(v.t == "case") then			
				emit("when "..gen_vhdl_bin_literal(v.a, tsa.size).." => ");
				indent_right();
				recurse({v.code});
				indent_left();

	-- it's a default match: (when others =>)
			elseif(v.t == "casedefault") then			
				emit("when others =>");
				indent_right();
				recurse({v.code});
				indent_left();
			end	
		end

		emit("end case;");
	end


	-- function instantiates and wires a VHDL component.
	function cgen_vhdl_instance(node)
		local num_pmaps=0;
		local num_gmaps=0;
		local n;

	-- emit the instatiation code
		emit(node.name.." : "..node.component);

	-- count the number of PORT MAPs and GENERIC MAPs
		for i,v in pairs(node.maps) do
			if(v.t=="genmap") then
				num_gmaps=num_gmaps+1;
			elseif(v.t == "portmap") then
				num_pmaps=num_pmaps+1;
			end 
		end
	
	-- do we gave GENERIC MAPs?	
		if(num_gmaps > 0) then
			indent_right();
			emit("generic map (");
			indent_right();
			n=1;

	-- then emit all of them
			for i,v in pairs(node.maps) do
				if(v.t=="genmap") then
				emit(string.format("%-20s => %s", v.to, v.from)..csel(n==num_gmaps,"",","));
				n=n+1;
				end
			end	
			indent_left();
			emit(")");
			indent_left();		
		end	

	-- do we have PORT MAPs?
		if(num_pmaps > 0) then
			indent_right();
			emit("port map (");
			indent_right();
			n=1;
			for i,v in pairs(node.maps) do
				if(v.t=="portmap") then
				local tsd = node_typesize(v.from);
				emit(string.format("%-20s => %s", v.to, gen_subrange(tsd))..csel(n==num_pmaps,"",","));
				n=n+1;
				end
			end	
			indent_left();
			emit(");");
			indent_left();		
		end	

		emit("");
	end

	-- generates VHDL "others => value" construct
	function cgen_vhdl_others(node)
		emitx("(others => '"..node.val.."')");
	end
	
	-- generates VHDL "pin => open" mapping
	function cgen_vhdl_openpin(node)
		emitx("open");
	end
	
	-- the main recursive traversal function.
	function recurse(node)

		local generators = {
			["comment"] 			= cgen_vhdl_comment;
			["syncprocess"] 	= cgen_vhdl_syncprocess;
			["combprocess"] 	= cgen_vhdl_combprocess;
			["assign"]			 	= cgen_vhdl_assign;
			["if"]			 			= cgen_vhdl_if;
			["generate_if"]		= cgen_vhdl_generate_if;
			["eq"]					 	= cgen_vhdl_binary_op;
			["add"]					 	= cgen_vhdl_binary_op;		
			["sub"]					 	= cgen_vhdl_binary_op;
			["or"]					 	= cgen_vhdl_binary_op;
			["and"]					 	= cgen_vhdl_binary_op;
			["not"]						= cgen_vhdl_not;
			["switch"] 				= cgen_vhdl_switch;
			["instance"]			= cgen_vhdl_instance;
			["others"]				= cgen_vhdl_others;
 			["openpin"]				= cgen_vhdl_openpin;
		};

	--	print(node);

		for i,v in pairs(node) do
			-- no type? probably just a block of code. recurse it deeper.

			if(v.t == nil) then
				recurse(v);
			else
				local func = generators[v.t];
	--		print(v.t);
				if(func == nil) then
					die("Unimplemented generator: "..v.t);
				end
				func(v);
			end
		end
 end

  if(options.hdl_reg_style == "record" and options.output_package_file ~= nil) then
     cgen_generate_init(options.output_package_file);
     cgen_new_snippet();
     cgen_vhdl_header(options.output_package_file);
     cgen_vhdl_package();
     cgen_write_current_snippet();
     cgen_generate_done();
  end


	cgen_generate_init(options.output_hdl_file)
-- here we go. Let's create a new snippet of code. VHDL generator is single-pass, so we'll need only one snippet.
	cgen_new_snippet();
-- output the header,
  
	cgen_vhdl_header(options.output_hdl_file);
-- .. the entity declaration
	cgen_vhdl_entity();
-- the main code
	recurse(tree);
-- the ending
	cgen_vhdl_ending();

-- and flush the snippet to the output file :)
	cgen_write_current_snippet();

	cgen_generate_done();
-- voila, we're done!
end

