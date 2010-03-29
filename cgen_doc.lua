#!/usr/bin/lua

-- wbgen2, (c) 2010 Tomasz Wlostowski/CERN BE-Co-HT
-- LICENSED UNDER GPL v2

-- File: cgen_c_headers.lua
--
-- HTML documentation generator.
--

html_stylesheet = '\
	<!--\
  BODY  { background: white; color: black;\
  			  font-family: Arial,Helvetica; font-size:12; }\
	h1 { font-family: Trebuchet MS,Arial,Helvetica; font-size:30; color:#404040; }\
	h2 { font-family: Trebuchet MS,Arial,Helvetica; font-size:22; color:#404040; }\
	h3 { font-family: Trebuchet MS,Arial,Helvetica; font-size:16; color:#404040; }\
	.td_arrow_left { padding:0px; background: #ffffff; text-align: right; font-size:12;}\
	.td_arrow_right { padding:0px; background: #ffffff; text-align: left; font-size:12;}\
	.td_code { font-family:Courier New,Courier; padding: 3px; }\
	.td_desc { padding: 3px; }\
	.td_sym_center { background: #e0e0f0; padding: 3px; }\
	.td_port_name { font-family:Courier New,Courier; background: #e0e0f0; text-align: right; font-weight:bold;padding: 3px; width:200px; }\
	.td_pblock_left { font-family:Courier New,Courier; background: #e0e0f0; padding: 0px; text-align: left; }\
	.td_pblock_right { font-family:Courier New,Courier; background: #e0e0f0; padding: 0px; text-align: right; }\
	.td_bit { background: #ffffff; color:#404040; font-size:10; width: 70px; font-family:Courier New,Courier; padding: 3px; text-align:center; }\
	.td_field { background: #e0e0f0; padding: 3px; text-align:center; }\
	.td_unused { background: #a0a0a0; padding: 3px; text-align:center;  }\
	th { font-weight:bold; color:#ffffff; background: #202080; padding:3px; }\
	.tr_even { background: #f0eff0; }\
	.tr_odd { background: #e0e0f0; }\
	-->';

function htable_new(rows, cols)
	local tbl = {};

	tbl.rows = rows;
	tbl.cols = cols;

	tbl.data={};
	
	for i=1,rows do 
		tbl.data[i]={}; 
		for j=1,cols do 
			tbl.data[i][j] = {};
			tbl.data[i][j].text = "";
		end
	end

	return tbl;	
end

function htable_tdstyle(r, c, style)
	tbl.data[r][c].style = style;
end

function htable_trstyle(r, c, style)
	tbl.data[r].style = style;
end

function htable_frame(tbl, r,c1,c2)
	if(c2 == nil) then
		tbl.data[r][c1].extra = 'style="border: solid 1px black;"';
	else
		tbl.data[r][c1].extra = 'style="border-left: solid 1px black; border-top: solid 1px black; border-bottom: solid 1px black;';
		tbl.data[r][c2].extra = 'style="border-right: solid 1px black; border-top: solid 1px black; border-bottom: solid 1px black;';

		if(c2 > c1 + 1) then
			for i=c1+1,c2-1 do
				tbl.data[r][i].extra = 'border-top: solid 1px black; border-bottom: solid 1px black;';
			end
		end
	end
end

function htable_emit(tbl)
	emit("<table cellpadding=0 cellspacing=0 border=0>");
	for i = 1, tbl.rows do

	
		
		if(tbl.data[i].is_header ~= nil) then
			tag = "th";
		else
			tag = "td";
		end
	
	if(tbl.data[i].style ~= nil) then emit('<tr class="'..tbl.data[i].style..'">'); else emit('<tr>'); end
		for j=1,tbl.cols do
			local extra = "";
			
			
			if(tbl.data[i][j].extra ~= nil) then extra = tbl.data[i][j].extra; end 
			if(tbl.data[i][j].colspan ~= nil) then extra = extra..' colspan='..tbl.data[i][j].colspan..' '; end 
		
			if(tbl.data[i][j].style ~= nil) then emit('<'..tag..' '..extra..' class="'..tbl.data[i][j].style..'">'); else emit('<'..tag..'>'); end
			emit(tbl.data[i][j].text);
			emit('</'..tag..'>');
		end		
		emit("</tr>");
	end
	emit("</table>");
end

function has_any_ports(reg)
	local has = false;
	if(reg.ports ~= nil) then return true; end
	foreach_subfield(reg, function(field) if (field.ports ~= nil) then has = true; end end);
	return has;
end

function htable_add_row(tbl, r)
	if(r>tbl.rows) then
		for i=tbl.rows+1,r do
			tbl.data[i]={}; 
			for j=1,tbl.cols do 
				tbl.data[i][j] = {};
				tbl.data[i][j].text = "";
			end
		end
		tbl.rows=r;
	end
end


function hlink(where, name)
	return '<A href="'..where..'">'..name..'</a>';
end	

function hitem(name)
	return '<li>'..name..'</li>';
end	

function hanchor(sname, text)
	return '<a name="'..sname..'">'..text..'</a>';
end	

doc_toc = {};

function hsection(id0, id1, name)
	local sect = {};
	local n_dots = 0;
		
	sect.id_mangled = "sect_"..id0.."_"..id1;
	sect.key = id0 * 1000 + id1;

	if(id1 ~= 0) then
		sect.level = 2;
		sect.id = id0.."."..id1..".";
	else
		sect.level = 1;
		sect.id = id0..".";
	end

	sect.name = name;
	table.insert(doc_toc, sect);
	
	return "<h3>"..hanchor(sect.id_mangled, sect.id.." "..name).."</h3>";
end

function cgen_doc_port(row, v, leftright)
	local arrow;

	if(v.range > 1) then arrow = "Arr;"; else arrow="arr;"; end

	local portname = csel (v.range > 1,  string.format("%s[%d:0]", v.name, v.range-1), v.name);
	
	if(leftright) then
		arrow=csel(v.dir=="in", "&r", csel(v.dir=="out", "&l", "&h"))..arrow; 
 		row[1].text = arrow;
 		row[2].text = portname;
	else
		 arrow=csel(v.dir=="in", "&l", csel(v.dir=="out", "&r", "&h"))..arrow; 
 		row[5].text = arrow;
 		row[4].text = portname;
	end
end

function cgen_doc_hdl_symbol()
	local ports = {};

	emit(hsection(2, 0, "HDL symbol"));	
		
	for i,v in pairs(g_portlist) do
		if(v.is_wb) then
			table.insert(ports, v);
		end
	end

	foreach_reg(ALL_REG_TYPES, function(reg)
		if(has_any_ports(reg)) then
			table.insert(ports, reg.name);

			if(reg.ports ~= nil) then
				for i,v in pairs(reg.ports) do
					table.insert(ports, v);
				end
			end

			foreach_subfield(reg, function(field, reg) 
				for i,v in pairs(field.ports) do
					table.insert(ports ,v);
				end
			end);
		
		end
	end);
	cgen_doc_symbol(ports);
end


function cgen_doc_mem_symbol(ram)
	local ports = {};
	
 for i,v in pairs(ram.ports) do
		local p = v;
		if(string.find(v.name, "_i") ~= nil) then
			p.is_wb = true;
		else
			p.is_wb = false;
		end
		table.insert(ports, p);
	end
	
	if(ram.clock ~= nil) then
		local p = port(BIT, 0, "in", ram.clock);
		p.is_wb = true;
		table.insert(ports, p);
	end
	
	cgen_doc_symbol(ports);
end

function cgen_doc_symbol(ports)

	local tbl = htable_new(3, 5);
	local nrowl = 1;
	local nrowr = 1;
	local first_one = true;
	
	for i,v in pairs(ports) do
		if(v.is_wb) then
				htable_add_row(tbl, nrowl); 
				cgen_doc_port(tbl.data[nrowl], v, true);
				nrowl = nrowl+1;
		end
	end
	
	for i,v in ipairs(ports) do
	 	if(type(v) == "string") then
	 		if(first_one == false) then
				htable_add_row(tbl, nrowr);
				row = tbl.data[nrowr]; row[3].text="&nbsp;";
				nrowr=nrowr+1;
			else
				first_one = false;		
			end
			htable_add_row(tbl, nrowr);
			local row = tbl.data[nrowr];
			row[4].style = "td_port_name";
			row[4].text = "<b>"..v..":</b>";
			nrowr=nrowr+1;
		elseif(not v.is_wb) then
			htable_add_row(tbl, nrowr);
			local row = tbl.data[nrowr]; cgen_doc_port(row, v, false); nrowr = nrowr+1;
		end
	end
		
	
	for i=1,tbl.rows do
		local row = tbl.data[i];
		row[1].style = "td_arrow_left";
		row[2].style = "td_pblock_left";
		if(row[3].style == nil) then row[3].style = "td_sym_center"; end
		row[4].style = "td_pblock_right";
		row[5].style = "td_arrow_right";
	end


	htable_emit(tbl);
end



function cgen_doc_header_and_toc()
	emit('<HTML>');
	emit('<HEAD>');
	emit('<TITLE>'..periph.hdl_entity..'</TITLE>');
	emit('<STYLE TYPE="text/css" MEDIA="all">');
	emit(html_stylesheet);
	emit('</STYLE>');
	emit('</HEAD>');
	emit('<BODY>');

	emit('<h1 class="heading">'..periph.hdl_entity..'</h1>');
	emit('<h3>'..periph.name..'</h3>');
	local t = periph.description;
	emit('<p>'..string.gsub(t, "\n", "<br>")..'</p>');
	emit('<h3>Contents:</h3>');

	table.sort(doc_toc, function(a,b) return a.key < b.key; end);
	
	for i,v in ipairs(doc_toc) do
		emit('<span style="margin-left: '..((v.level-1) * 20)..'px; ">'..v.id.." "..hlink('#'..v.id_mangled, v.name)..'</span><br/>');
	end
													
									
	
end


function cgen_doc_memmap()
	local evenodd=0;
	local n = 2;
	emit(hsection(1, 0, "Memory map summary"));

	local tbl = htable_new(1,5);

	local row = tbl.data[1];

	row.is_header = true;
	row[1].text = "H/W Address"
	row[2].text = "Type";
	row[3].text = "Name";
	row[4].text = "VHDL/Verilog prefix";
	row[5].text = "C prefix";

	foreach_reg({TYPE_REG, TYPE_FIFO}, function(reg)
		if(reg.full_hdl_prefix ~= nil) then
			htable_add_row(tbl, n);
			local row = tbl.data[n]; n=n+1;
			
			row.style = csel(evenodd, "tr_odd", "tr_even");
		
			row[1].style = "td_code";
			row[1].text = string.format("0x%x", reg.base);
			row[2].text = "REG";

			row[3].text = hlink("#"..string.upper(reg.c_prefix), reg.name);
			row[4].style = "td_code";
			row[4].text = reg.full_hdl_prefix;

			row[5].style = "td_code";
			row[5].text = string.upper(reg.c_prefix);

			evenodd = not evenodd;
		end
	end);
	

	foreach_reg({TYPE_RAM}, function(reg)
		if(reg.full_hdl_prefix ~= nil) then
			htable_add_row(tbl, n);
			local row = tbl.data[n]; n=n+1;
			
			row.style = csel(evenodd, "tr_odd", "tr_even");
		
			row[1].style = "td_code";
			row[1].text = string.format("0x%x - 0x%x",reg.base, reg.base+math.pow(2, reg.wrap_bits)*reg.size-1);
			row[2].text = "MEM";

			row[3].text = hlink("#"..string.upper(reg.c_prefix), reg.name);
			row[4].style = "td_code";
			row[4].text = reg.full_hdl_prefix;

			row[5].style = "td_code";
			row[5].text = string.upper(reg.c_prefix);

			evenodd = not evenodd;
		end
	end);

	htable_emit(tbl);		

end

function find_field_by_offset (reg, offset)
	local found = nil;
	foreach_subfield(reg, function(field) if(offset >= field.offset and offset <= (field.offset+field.size-1)) then found = field; end end);
	return found;
end

function cgen_doc_fieldtable(reg, bitoffs)
	local td_width = 70;	
	local tbl;
	local n= 1;
	local cellidx = 1;
	
	tbl= htable_new(2,8);
	
	
	for i=1,8 do
		tbl.data[1][i].style = "td_bit";
		tbl.data[1][i].text = string.format("%d", bitoffs+8-i);
	end

	local bit = bitoffs + 7;
	while (bit >= bitoffs) do
		local f = find_field_by_offset(reg, bit);
		
		if(f == nil) then
			tbl.data[2][n].style = "td_unused";
			tbl.data[2][n].text = "-";
			n=n+1;
			bit=bit-1;
		else
			local fend;
			if(f.offset < bitoffs) then
				fend = bitoffs;
			else
				fend = f.offset;	  
			end
			local ncells = (bit - fend) + 1;
			
			if(ncells > 1) then tbl.data[2][n].colspan = ncells; end
		
			local prefix;
			
			prefix = f.c_prefix;
			if(prefix == nil)  then prefix = reg.c_prefix; end

			tbl.data[2][n].style = "td_field";
			tbl.data[2][n].text = csel(f.size>1, string.format("%s[%d:%d]", string.upper(prefix), bit-f.offset, fend-f.offset), string.upper(prefix));

			htable_frame(tbl, 2, cellidx);
			
		
			
			bit = bit - ncells;
			n=n+ncells;
		end
		
				cellidx = cellidx + 1;

	end

	htable_emit(tbl);
end

function cgen_doc_access(acc)
	if(acc == READ_ONLY) then
		return "read-only";
	elseif(acc == READ_WRITE) then
		return "read/write";
	elseif(acc == WRITE_ONLY) then
		return "write-only";
	else
		return "FIXME!";
	end
end

cur_reg_no = 1;

function cgen_doc_reg(reg)

	emit(hanchor(string.upper(reg.c_prefix),""));
	emit(hsection(3, cur_reg_no, reg.name));

	cur_reg_no = cur_reg_no + 1;

	local tbl = htable_new(4, 2);
	
	tbl.data[1][1].text = "<b>HW prefix: </b>";
	tbl.data[2][1].text = "<b>HW address: </b>";
	tbl.data[3][1].text = "<b>C prefix: </b>";
	tbl.data[4][1].text = "<b>C offset: </b>";

	tbl.data[1][2].text = reg.full_hdl_prefix; 
	tbl.data[2][2].text = string.format("0x%x", reg.base);
	tbl.data[3][2].text = string.upper(reg.c_prefix);
	tbl.data[4][2].text = string.format("0x%x", reg.base * (DATA_BUS_WIDTH/8));

	for i=1,4 do tbl.data[i][2].style = "td_code"; end

	htable_emit(tbl);
	
	
	if(reg.description ~= nil) then
		emit('<p>');
		emit(string.gsub(reg.description, "\n", "<br>"));
		emit('</p>');
	end
	
	for i=0,DATA_BUS_WIDTH/8-1 do
		cgen_doc_fieldtable(reg, (DATA_BUS_WIDTH/8-1-i)*8);
	end

	emit("<ul>");	
	foreach_subfield(reg, function(field)
		emit("<li><b>");
		if(field.c_prefix == nil) then -- anonymous field?
			emit(string.upper(reg.c_prefix));
		else
			emit(string.upper(field.c_prefix));
		end
	
		emit("</b>[<i>"..cgen_doc_access(field.access_bus).."</i>]: "..field.name);
		
		if(field.description ~= nil) then
			emit("<br>"..string.gsub(field.description, "\n", "<br>"));
		end

	end);
	emit("</ul>");		
end

cur_mem_no = 1;

function cgen_doc_ram(ram)
	emit(hanchor(string.upper(ram.c_prefix),""));
	emit(hsection(4, cur_mem_no, ram.name));
	cur_mem_no = cur_mem_no + 1;
	
	local tbl = htable_new(11, 2);

	tbl.data[1][1].text = "<b>HW prefix: </b>";
	tbl.data[2][1].text = "<b>HW address: </b>";
	tbl.data[3][1].text = "<b>C prefix: </b>";
	tbl.data[4][1].text = "<b>C offset: </b>";

	tbl.data[5][1].text = "<b>Size: </b>";
	tbl.data[6][1].text = "<b>Data width: </b>";
	tbl.data[7][1].text = "<b>Access (bus): </b>";
	tbl.data[8][1].text = "<b>Access (device): </b>";
	tbl.data[9][1].text = "<b>Mirrored: </b>";
	tbl.data[10][1].text = "<b>Byte-addressable: </b>";
	tbl.data[11][1].text = "<b>Peripheral port: </b>";

--	for i=1,6 do tbl.data[i][2].style="td_code"; end
	
	tbl.data[1][2].text = string.lower(periph.hdl_prefix.."_"..ram.hdl_prefix); 
	tbl.data[2][2].text = string.format("0x%x", ram.base);
	tbl.data[3][2].text = string.upper(ram.c_prefix);
	tbl.data[4][2].text = string.format("0x%x", ram.base * (DATA_BUS_WIDTH/8));

	tbl.data[5][2].text = ram.size.." "..ram.width.."-bit words";
	tbl.data[6][2].text = ram.width;
	tbl.data[7][2].text = cgen_doc_access(ram.access_bus);
	tbl.data[8][2].text = cgen_doc_access(ram.access_dev);
	
	if(ram.byte_select ~= nil and ram.byte_select == true) then
		tbl.data[10][2].text = "yes";
	else
		tbl.data[10][2].text = "no";
	end
	
	if(ram.wrap_bits ~= nil and 0 ~= ram.wrap_bits) then
		tbl.data[9][2].text = math.pow(2, ram.wrap_bits).." times";
	else
		tbl.data[9][2].text = "no";
	end	

	if(ram.clock ~= nil) then
		tbl.data[11][2].text = "asynchronous ("..ram.clock..")";
	else
		tbl.data[11][2].text = "bus-synchronous";
	end	


	htable_emit(tbl);

	emit("<br>");
	cgen_doc_mem_symbol(ram);
	
	if(ram.description ~= nil) then
		emit("<p>"..string.gsub(ram.description,"\n", "<br>").."</p>");
	end
end

cur_irq_no = 1;

function cgen_doc_irq(irq)
	emit(hanchor(string.upper(irq.c_prefix),""));
	emit(hsection(5, cur_irq_no, irq.name));
	cur_irq_no = cur_irq_no + 1;
	
	local tbl = htable_new(3, 2);

	tbl.data[1][1].text = "<b>HW prefix: </b>";
	tbl.data[2][1].text = "<b>C prefix: </b>";
	tbl.data[3][1].text = "<b>Trigger: </b>";

	tbl.data[1][2].text = string.lower(periph.hdl_prefix.."_"..irq.hdl_prefix); 
	tbl.data[2][2].text = string.upper(irq.c_prefix);

	local trigtab = {
	[EDGE_RISING] = "rising edge";
	[EDGE_FALLING] = "falling edge";
	[LEVEL_0] = "low level";
	[LEVEL_1] = "high level";
	};
	
	
	tbl.data[3][2].text = trigtab[irq.trigger];

	htable_emit(tbl);
	if(irq.description ~= nil) then
		emit("<p>"..string.gsub(irq.description,"\n", "<br>").."</p>");
	end
end


function cgen_generate_documentation()
	cgen_new_snippet(); cgen_doc_hdl_symbol(); local h_sym = cgen_get_snippet();

	cgen_new_snippet();
	emit(hsection(3,0, "Register description"));
	foreach_reg({TYPE_REG, TYPE_FIFO}, function(reg) if(reg.no_docu == nil or reg.no_docu == false)then cgen_doc_reg(reg);end end);
	local h_regs = cgen_get_snippet();

	
	local h_rams = "";
	if(periph.ramcount > 0) then
		emit(hsection(4,0, "Memory blocks"));
		cgen_new_snippet();
		foreach_reg({TYPE_RAM}, function(reg) if(reg.no_docu == nil or reg.no_docu == false)then cgen_doc_ram(reg);end end);
		h_rams = cgen_get_snippet();
	end


	local h_irqs = "";
	if(periph.irqcount > 0) then
		cgen_new_snippet();
		emit(hsection(5,0, "Interrupts"));
		foreach_reg({TYPE_IRQ}, function(reg) if(reg.no_docu == nil or reg.no_docu == false) then cgen_doc_irq(reg); end end);
		h_irqs = cgen_get_snippet();
	end


	cgen_new_snippet();
	cgen_doc_memmap(); 
	local h_memmap = cgen_get_snippet();


	cgen_new_snippet();
	cgen_doc_header_and_toc();

	emit(h_memmap);
	emit(h_sym);
	emit(h_regs);
	emit(h_rams);
	emit(h_irqs);
	
	emit('</BODY>');
	emit('</HTML>');
	cgen_write_current_snippet();
end
