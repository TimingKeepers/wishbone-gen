#!/usr/bin/lua

-- wbgen2, (c) 2013 Grzegorz Daniluk/CERN BE-CO-HT
-- LICENSED UNDER GPL v2

-- File: cgen_doc_latex.lua
--
-- LATEX documentation generator.
--

function lx_htable_emit(tbl)
   local temp ="";
   local cell_align = "";

   if( tbl.data[1][1].style == nil ) then
     cell_align = "l ";
   elseif( tbl.data[1][1].style == "td_bit" ) then
     cell_align = ">{\\centering\\arraybackslash}p{1.5cm} ";
   end

   temp = "\\begin{tabular}{";
   for j=1, tbl.cols do
     temp = temp..cell_align;
   end
   temp = temp.."}";
   emit(temp);

   for i = 1, tbl.rows do
     local row = "";
      
     j=1;
     while j<=tbl.cols do
       row = row..tbl.data[i][j].text;
       if( tbl.data[i][j].style ~= nil ) then
         if( tbl.data[i][j].style == "td_field" ) then
           j = j + tbl.data[i][j].flen;
         end
       end
       if(j ~= tbl.cols) then
         row = row..' & ';
       else
         row = row..'\\\\';
       end
	 	 
       j = j + 1;
     end		
     emit(row);
   end
   emit("\\end{tabular}");
   emit("");
end

function cgen_doc_lx_header_and_toc()
  emit('\\subsection{'..periph.name..'}');
  emit('\\label{subsec:wbgen:'..periph.prefix..'}');

	local t = periph.description;
	if(t == nil) then t = ""; end
	emit(string.gsub(t, "\n", "\\\\"));
end


function cgen_doc_lx_memmap()
	local n = 2;
  local reg_text = " ";

  emit('\\subsubsection{Memory map summary}');
  emit('\\rowcolors{2}{gray!25}{white}');
  emit('\\resizebox{\\textwidth}{!}{');
  emit('\\begin{tabular}{|l|l|l|l|l|}');
  emit('\\rowcolor{RoyalPurple}');
  emit('\\color{white} SW Offset & \\color{white} Type & \\color{white} Name &');
  emit('\\color{white} HW prefix & \\color{white} C prefix\\\\');

	foreach_reg({TYPE_REG}, function(reg)
		if(reg.full_hdl_prefix ~= nil) then
      reg_text = string.format("0x%x", reg.base * (DATA_BUS_WIDTH/8))..'& ';

			if(reg.doc_is_fiforeg == nil) then
			   reg_text = reg_text.."REG & ";
			else
			   reg_text = reg_text.."FIFOREG & ";
			end

      reg_text = reg_text..reg.name.." & "..reg.full_hdl_prefix.." & "..string.upper(reg.c_prefix).."\\\\";
      reg_text = string.gsub(reg_text, "_", "\\_");
      emit(reg_text);
		end
	end);
	

	foreach_reg({TYPE_RAM}, function(reg)
		if(reg.full_hdl_prefix ~= nil) then
      reg_text = string.format("0x%x - 0x%x", reg.base*(DATA_BUS_WIDTH/8), reg.base*(DATA_BUS_WIDTH/8)+(math.pow(2, reg.wrap_bits)*reg.size-1)*DATA_BUS_WIDTH/8)..'& ';

      reg_text = reg_text.."MEM & "..reg.name.." & "..reg.full_hdl_prefix.." & "..string.upper(reg.c_prefix).."\\\\";
      reg_text = string.gsub(reg_text, "_", "\\_");
      emit(reg_text);
		end
	end);

	emit('\\hline');
  emit('\\end{tabular}');
  emit('}');  --end of resizebox

end

function cgen_doc_lx_fieldtable(reg, bitoffs)
	local td_width = 70;	
	local tbl;
	local n= 1;

	tbl= htable_new(2,8);
	
	for i=1,8 do
		tbl.data[1][i].style = "td_bit";
    tbl.data[1][n].flen = 0;
		tbl.data[1][i].text = string.format("%d", bitoffs+8-i);
	end

	local bit = bitoffs + 7;
	while (bit >= bitoffs) do
		local f = find_field_by_offset(reg, bit);
		

		if(f == nil) then
			tbl.data[2][n].style = "td_unused";
      tbl.data[2][n].flen = 0;
      if(n==1) then
			  tbl.data[2][n].text = "\\multicolumn{1}{|c}{-}";
      elseif(n==8) then
			  tbl.data[2][n].text = "\\multicolumn{1}{c|}{-}";
      else
			  tbl.data[2][n].text = "-";
      end
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
			
			dbg("ncells: ",ncells,"bit: ", bit, "name: ",f.prefix);

			tbl.data[2][n].colspan = ncells;
		
		
			local prefix;
			
			prefix = f.c_prefix;
			if(prefix == nil)  then prefix = reg.c_prefix; end

			prefix = string.gsub(prefix, "_", "\\_");

			tbl.data[2][n].style = "td_field";
      tbl.data[2][n].flen = bit-fend;
			tbl.data[2][n].text = csel(f.size>1, string.format("\\multicolumn{%d}{|c|}{\\cellcolor{RoyalPurple!25}%s[%d:%d]}", bit-fend+1, string.upper(prefix), bit-f.offset, fend-f.offset), string.format("\\multicolumn{1}{|c|}{\\cellcolor{RoyalPurple!25}%s}", string.upper(prefix)));

			bit = bit - ncells;
			n=n+1;
		end
		
	
	end

  --part of htable_emit()
  for i = 1, tbl.rows do
    local row = "";
     
    j=1; 
    k=0;
    while k<tbl.cols do
      row = row..tbl.data[i][j].text;
      if( tbl.data[i][j].style ~= nil ) then
        if( tbl.data[i][j].style == "td_field" ) then
          k = k + tbl.data[i][j].flen;
        end
      end
      k = k + 1;
      if(k ~= tbl.cols) then
        row = row..' & ';
      else
        row = row..'\\\\';
      end
      j = j + 1;
    end		
    emit(row);
    emit("\\hline");
  end
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

function cgen_doc_lx_reg(reg)
  local temp = "";
  local description = "";

	cur_reg_no = cur_reg_no + 1;

  emit("\\paragraph*{"..reg.name.."}\\vspace{12pt}");
  emit("");

	local tbl = htable_new(4, 2);
	
	tbl.data[1][1].text = "{\\bf HW prefix:} ";
	tbl.data[2][1].text = "{\\bf HW address:} ";
	tbl.data[3][1].text = "{\\bf SW prefix:} ";
	tbl.data[4][1].text = "{\\bf SW offset:} ";

	tbl.data[1][2].text = string.gsub(reg.full_hdl_prefix, "_", "\\_"); 
	tbl.data[2][2].text = string.format("0x%x", reg.base);
	tbl.data[3][2].text = string.gsub(string.upper(reg.c_prefix), "_", "\\_");
	tbl.data[4][2].text = string.format("0x%x", reg.base * (DATA_BUS_WIDTH/8));

  emit("\\rowcolors{1}{white}{white}");
	lx_htable_emit(tbl);
	
	
	if(reg.description ~= nil) then
    emit("\\vspace{12pt}");
    description = string.gsub(reg.description, "\n", "\\\\");
    description = string.gsub(description, "_", "\\_");
    description = string.gsub(description, "<code>", "\\texttt{");
    description = string.gsub(description, "</code>", "}");
    emit(description);
	end

  --generate header for tabular
	temp = "\\begin{tabular}{";
  for j=1, 8 do
    temp = temp..">{\\centering\\arraybackslash}p{1.5cm} ";
  end
  temp = temp.."}";
  emit("");
  emit("\\vspace{12pt}");
  emit("\\noindent");
  emit('\\resizebox{\\textwidth}{!}{');
  emit(temp);

	for i=0,DATA_BUS_WIDTH/8-1 do
		cgen_doc_lx_fieldtable(reg, (DATA_BUS_WIDTH/8-1-i)*8);
	end
  emit("\\end{tabular}");
  emit("}");
  emit("");

	emit("\\begin{itemize}");	
	foreach_subfield(reg, function(field)
    emit("\\item \\begin{small}");
		emit("{\\bf ");
		if(field.c_prefix == nil) then -- anonymous field?
			emit(string.gsub(string.upper(reg.c_prefix), "_", "\\_"));
		else
			emit(string.gsub(string.upper(field.c_prefix), "_", "\\_"));
		end
	
		emit("} [\\emph{"..cgen_doc_access(field.access_bus).."}]: "..field.name);
		
		if(field.description ~= nil) then
      emit("\\\\");
      description = string.gsub(field.description, "\n", "\\\\");
      description = string.gsub(description, "_", "\\_");
      description = string.gsub(description, "<code>", "\\texttt{");
      description = string.gsub(description, "</code>", "}");
      emit(description);
		end

    emit("\\end{small}");

	end);
	emit("\\end{itemize}");		
end

cur_mem_no = 1;

function cgen_doc_lx_ram(ram)
  local description = "";

  emit("\\paragraph*{"..ram.name.."}\\vspace{12pt}");
  emit("");
	cur_mem_no = cur_mem_no + 1;
	
	local tbl = htable_new(11, 2);

	tbl.data[1][1].text  = "{\\bf HW prefix:} ";
	tbl.data[2][1].text  = "{\\bf HW address:} ";
	tbl.data[3][1].text  = "{\\bf C prefix:} ";
	tbl.data[4][1].text  = "{\\bf C offset:} ";

	tbl.data[5][1].text  = "{\\bf Size:} ";
	tbl.data[6][1].text  = "{\\bf Data width:} ";
	tbl.data[7][1].text  = "{\\bf Access (bus):} ";
	tbl.data[8][1].text  = "{\\bf Access (device):} ";
	tbl.data[9][1].text  = "{\\bf Mirrored:} ";
	tbl.data[10][1].text = "{\\bf Byte-addressable:} ";
	tbl.data[11][1].text = "{\\bf Peripheral port:} ";

	tbl.data[1][2].text = string.lower(string.gsub(periph.hdl_prefix, "_", "\\_").."\\_"..string.gsub(ram.hdl_prefix,"_","\\_")); 
	tbl.data[2][2].text = string.format("0x%x", ram.base);
	tbl.data[3][2].text = string.upper(string.gsub(ram.c_prefix,"_","\\_"));
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


  emit("\\begin{small}");
	lx_htable_emit(tbl);
  emit("\\end{small}");

	if(ram.description ~= nil) then
    description = string.gsub(ram.description, "\n", "\\\\");
    description = string.gsub(description, "_", "\\_");
    description = string.gsub(description, "<code>", "\\texttt{");
    description = string.gsub(description, "</code>", "}");
    emit(description);
	end
end

cur_irq_no = 1;

function cgen_doc_lx_irq(irq)
  local description = "";

  emit("\\paragraph*{"..irq.name.."}\\vspace{12pt}");
	cur_irq_no = cur_irq_no + 1;
	
	local tbl = htable_new(3, 2);

	tbl.data[1][1].text = "{\\bf HW prefix:} ";
	tbl.data[2][1].text = "{\\bf C prefix:} ";
	tbl.data[3][1].text = "{\\bf Trigger:} ";

	tbl.data[1][2].text = string.gsub(string.lower(periph.hdl_prefix.."_"..irq.hdl_prefix), "_", "\\_"); 
	tbl.data[2][2].text = string.upper(string.gsub(irq.c_prefix,"_","\\_"));

	local trigtab = {
	[EDGE_RISING] = "rising edge";
	[EDGE_FALLING] = "falling edge";
	[LEVEL_0] = "low level";
	[LEVEL_1] = "high level";
	};
	
	
	tbl.data[3][2].text = trigtab[irq.trigger];

  emit("\\begin{small}");
	lx_htable_emit(tbl);
  emit("\\end{small}");

	if(irq.description ~= nil) then
    emit("\\vspace{12pt}");
    description = string.gsub(irq.description, "\n", "\\\\");
    description = string.gsub(description, "_", "\\_");
    description = string.gsub(description, "<code>", "\\texttt{");
    description = string.gsub(description, "</code>", "}");
    emit(description);
	end
end


function cgen_generate_latex_documentation()

	cgen_new_snippet();
  emit("\\subsubsection{Register description}");
	foreach_reg({TYPE_REG}, function(reg) if(reg.no_docu == nil or reg.no_docu == false)then cgen_doc_lx_reg(reg);end end);
	local h_regs = cgen_get_snippet();

	
	local h_rams = "";
	if(periph.ramcount > 0) then
		emit("\\subsubsection{Memory blocks}");
		cgen_new_snippet();
		foreach_reg({TYPE_RAM}, function(reg) if(reg.no_docu == nil or reg.no_docu == false)then cgen_doc_lx_ram(reg);end end);
		h_rams = cgen_get_snippet();
	end


	local h_irqs = "";
	if(periph.irqcount > 0) then
		cgen_new_snippet();
    emit("\\subsubsection{Interrupts}");
		foreach_reg({TYPE_IRQ}, function(reg) if(reg.no_docu == nil or reg.no_docu == false) then cgen_doc_lx_irq(reg); end end);
		h_irqs = cgen_get_snippet();
	end


	cgen_new_snippet();
	cgen_doc_lx_memmap(); 
	local h_memmap = cgen_get_snippet();


	cgen_new_snippet();
	cgen_doc_lx_header_and_toc();

	emit(h_memmap);
	emit(h_regs);
	emit(h_rams);
	emit(h_irqs);
	
	cgen_write_current_snippet();
end
