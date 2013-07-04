#!/usr/bin/lua

-- wbgen2, (c) 2010 Tomasz Wlostowski/CERN BE-Co-HT
-- LICENSED UNDER GPL v2

-- File: cgen_c_headers.lua
--
-- Texinfo documentation generator.
--

--function has_any_ports(reg)
--   local has = false;
--   if(reg.ports ~= nil) then return true; end
--   foreach_subfield(reg, function(field) if (field.ports ~= nil) then has = true; end end);
--   return has;
--end

function format_tex_string(s)
   s=string.gsub(s, " +", " ");
   s=string.gsub(s, "^%-", "@bullet{} ");
   s=string.gsub(s, "\n%-", "@*@bullet{} ");
   s=string.gsub(s, "\n", "@*");
   s=string.gsub(s, "<b>", "@b{");
   s=string.gsub(s, "</b>", "}");
   s=string.gsub(s, "<i>", "@b{");
   s=string.gsub(s, "</i>", "}");
   s=string.gsub(s, "<code>", "@code{");
   s=string.gsub(s, "</code>", "}");
   return s
end

function cgen_tex_memmap()
	local evenodd=0;
	local n = 2;
	emit("@regsection Memory map summary");

	emit("@multitable  @columnfractions .10 .15 .15 .55")
	emit("@headitem Address @tab Type @tab Prefix @tab Name")

	foreach_reg({TYPE_REG}, function(reg)
		if(reg.full_hdl_prefix ~= nil) then
			
			emit(string.format("@item @code{0x%x} @tab", reg.base * 4));

			if(reg.doc_is_fiforeg == nil) then
			   emit("REG @tab");
			else
			   emit("FIFOREG @tab");
			end

			emit("@code{"..reg.c_prefix.."} @tab");
			emit(reg.name);

		end
	end);

	foreach_reg({TYPE_RAM}, function(reg)
		if(reg.full_hdl_prefix ~= nil) then
                   emit(string.format("@item @code{0x%x - 0x%x}",reg.base, reg.base+math.pow(2, reg.wrap_bits)*reg.size-1));
                   emit("@tab MEM @tab @code{"..reg.c_prefix.."} @tab "..reg.name);
		end
	end);

	emit("@end multitable ")
     end

function cgen_tex_access(acc)
	if(acc == READ_ONLY) then
		return "R/O";
	elseif(acc == READ_WRITE) then
		return "R/W";
	elseif(acc == WRITE_ONLY) then
		return "W/O";
	else
		return "FIXME!";
	end
end


function cgen_texinfo_reg(reg)

	emit("@regsection @code{"..reg.c_prefix.."} - "..reg.name);

	cur_reg_no = cur_reg_no + 1;

	local tbl = htable_new(4, 2);

-- fixme: FIFO regs 
--        emit("Address: @code{"..string.format("0x%x", reg.base * (DATA_BUS_WIDTH/8)).."}");
	
	if(reg.description ~= nil) then
           emit(format_tex_string(reg.description));
 	end

	emit("@multitable @columnfractions .10 .10 .15 .10 .55")
	emit("@headitem Bits @tab Access @tab Prefix @tab Default @tab Name")

	foreach_subfield(reg, function(field)
        --  emit("@columnfractions .10 .10 .15 .10 .55")

          if(field.size == 1) then
              emit(string.format("@item @code{%d}", field.offset));
           else              emit(string.format("@item @code{%d...%d}", field.offset + field.size-1, field.offset));
           end
          emit("@tab "..cgen_tex_access(field.access_bus).." @tab");
	
	if(field.c_prefix == nil) then -- anonymous field?
           emit("@code{"..string.upper(reg.c_prefix).."}");
        else
           emit("@code{"..string.upper(field.c_prefix).."}");
        end
	
				val = 'X';
				if(field.reset_value ~= nil) then
					val = field.reset_value;
				elseif ((field.access_bus == READ_WRITE and field.access_dev == READ_ONLY) or field.type == MONOSTABLE or field.access_bus == WRITE_ONLY) then
					val = '0'
				end
				
        emit("@tab @code{"..val.."} @tab ");
        emit(field.name);

       -- emit("@columnfractions 1")
       -- emit("@item dupa")
        --if(field.description ~= nil) then
        --   emit("<br>"..string.gsub(field.description, "\n", "<br>"));
        --end

	end);
	emit("@end multitable");		

	local	got_any_descriptions = false
	foreach_subfield(reg, function(field)
                                 if(field.description ~= nil) then
                                 		got_any_descriptions = true
                                 end 
                              end);


	if(got_any_descriptions) then
	  emit("@multitable @columnfractions 0.15 0.85")
  	emit("@headitem Field @tab Description")
		foreach_subfield(reg, function(field)
                                 if(field.description ~= nil) then
                                    pfx = csel(field.c_prefix == nil, reg.c_prefix, field.c_prefix)
                                    emit("@item @code{"..pfx.."} @tab "..format_tex_string(field.description));
                                 end 
                              end);
    emit("@end multitable");		
  end


end

function cgen_generate_texinfo_documentation()
	cgen_new_snippet();
	cgen_tex_memmap(); 

	foreach_reg({TYPE_REG}, function(reg) if(reg.no_docu == nil or reg.no_docu == false)then cgen_texinfo_reg(reg);end end);

	cgen_write_current_snippet();
end