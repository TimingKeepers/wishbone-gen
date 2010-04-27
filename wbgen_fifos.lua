-- -*- Mode: LUA; tab-width: 2 -*-

function fifo_wire_core_ports(fifo)
	local prefix = fifo.full_prefix;
  local total_size = 0;

  fifo.usedw_size = log2up(fifo.size);


	local ports = {
		 port(BIT, 0, "in", prefix.."_"..fifo.rdwr.."_req_i", 
					csel(fifo.direction == BUS_TO_CORE, "FIFO read request", "FIFO write request" ))
	};

-- add full/empty/usedw ports
	if inset(FIFO_FULL, fifo.flags_dev) then
		 table_join(ports, { port (BIT, 0, "out", prefix.."_"..fifo.rdwr.."_full_o", "FIFO full flag") });
		 table_join(fifo.maps, { vpm (fifo.rdwr.."_full_o", prefix.."_"..fifo.rdwr.."_full_o")});
	end

	if inset(FIFO_EMPTY, fifo.flags_dev) then
		 table_join(ports, { port (BIT, 0, "out", prefix.."_"..fifo.rdwr.."_empty_o", "FIFO empty flag") });
		 table_join(fifo.maps, { vpm (fifo.rdwr.."_empty_o", prefix.."_"..fifo.rdwr.."_empty_o")});
	end

	if inset(FIFO_COUNT, fifo.flags_dev) then
		 table_join(ports, { port (SLV, fifo.usedw_size, "out", prefix.."_"..fifo.rdwr.."_count_o", 
															 "FIFO number of used words") });
		 table_join(fifo.maps, { vpm (fifo.rdwr.."_count_o", prefix.."_"..fifo.rdwr.."_count_o")});
	end

	foreach_subfield(fifo, 
									 function(field, f) 
											local field_pfx = string.lower(prefix.."_"..field.hdl_prefix);
											total_size = total_size + field.size;

											if(fifo.direction == BUS_TO_CORE) then -- bus -> core fifo
												 table_join(ports, {port (field.type, field.size, "out", field_pfx.."_o")});
-- assign the output to the FIFO output port
			--							 table_join(fifo.extra_code, { 
		--																	 va(field_pfx.."_o", 
	--																				vi(prefix.."_out_int", field.offset_unaligned + field.size -1,
---																					 field.current_unaligned)) });

											else -- core -> bus fifo
												 table_join(ports, {port (field.type, field.size, "in",  field_pfx.."_i")});

												 table_join(fifo.extra_code, { 
																			 va(
																					vi(prefix.."_in_int", field.offset_unaligned + field.size -1,
																						 field.offset_unaligned),
																			    field_pfx.."_i") });
											end

									 end);

	table_join(fifo.ports, ports);
	fifo.total_size = total_size;
																	
end

function fifo_wire_bus_ports(fifo)
	 local fifo_reg_nbits = fifo.current_offset;
-- total number of FIFO input/output registers
	 local n_regs = math.ceil(fifo_reg_nbits / DATA_BUS_WIDTH);
	 
	 local fifo_dregs = {};
	 local i;

	 for i=0, n_regs -1 do
			local minofs = i * DATA_BUS_WIDTH;
			local maxofs = (i + 1 ) *DATA_BUS_WIDTH - 1;

			fifo_dregs[i] = {};
			fifo_dregs[i].ports = {};
			fifo_dregs[i].signals = {};
			fifo_dregs[i].write_code = {};
			fifo_dregs[i].read_code = {};
			fifo_dregs[i].reset_code_main = {};
			fifo_dregs[i].extra_code = {};
			fifo_dregs[i].ackgen_code= {};

			print("DREG ", i);

			foreach_subfield(fifo, 
											 function(field)
													if(field.offset >= minofs and field.offset + field.size - 1 <= maxofs) then
														 table.insert(fifo_dregs[i], field);
														 field.offset = field.offset - minofs;
														 print("FIELD: ", field.name, " OFS: ", field.offset, "SIZE: ",field.size);
													end
											 end);

			r = fifo_dregs[i];

			r.__type = TYPE_REG;

			r.no_std_regbank = true;
			r.hdl_prefix = string.format(fifo.hdl_prefix.."_R%d", i);
			r.c_prefix = string.format(fifo.c_prefix.."_R%d", i);
			r.ack_len = 2;
			r.ports = {};
			r.signals = {};

			if(fifo.direction == BUS_TO_CORE) then
				 r.name = "FIFO '"..fifo.name.."' data input register "..i;
			else -- core -> bus fifo
				 r.name = "FIFO '"..fifo.name.."' data output register "..i;
				 r.access_bus = READ_ONLY;
				 r.access_dev = WRITE_ONLY;
			end

		

			foreach_subfield(r,
											 function (field, r)

													if(fifo.direction == BUS_TO_CORE) then
														 field.write_code = {va(
																										vi(fifo.full_prefix.."_in_int",  -- dst
																											 field.offset_unaligned + field.size - 1,
																											 field.offset_unaligned),
																										vi("wrdata_reg",  -- src
																											 field.offset + field.size - 1, 
																											 field.offset))};

														 field.access_bus = WRITE_ONLY;
														 field.access_dev = READ_ONLY;

													else
													end

											 end);

			print(r.hdl_prefix, r.c_prefix, prefix);
			

			table.insert(periph, r);
	 end

	 print("lastreg: " ,r.name);
	 
	 -- last register:
	 if(fifo.direction == BUS_TO_CORE) then -- Last FIFO I/O register
			table_join(r.write_code, { va(fifo.full_prefix.."_wrreq_int", 1) });
			table_join(r.ackgen_code, { va(fifo.full_prefix.."_wrreq_int", 0) });
			table_join(r.reset_code_main, { va(fifo.full_prefix.."_wrreq_int", 0) });
	 end



-- add full/empty/usedw control register
	 local csr = {
			["__type"]         = TYPE_REG;
			["name"]           = "FIFO '"..fifo.name.."' control/status register";
			["c_prefix"]       = fifo.c_prefix.."_CSR";
			["hdl_prefix"]     = fifo.hdl_prefix.."_CSR";
			["no_std_regbank"] = true;
	 };

	 function gen_fifo_csr_field(flag, field_prefix, field_name, field_desc, size, type, offset)
			if inset(flag, fifo.flags_bus) then
				 local f = { 
						["__type"]      = TYPE_FIELD;
						["name"]        = field_name;
						["description"] = field_desc;
						["access_bus"]  = READ_ONLY;
						["access_dev"]  = WRITE_ONLY;
						["type"]        = type;
						["size"]        = size;
						["offset"]      = offset;
						["c_prefix"]    = field_prefix;
						["hdl_prefix"]  = field_prefix;
						["signals"] = {};
						["read_code"] = {};
						["ack_len"] = 2;
				 };
			
				 local sig =  fifo.full_prefix.."_"..field_prefix.."_int";

-- wire the FULL signal to appropriate FIFO output
				 table_join(fifo.maps, { vpm (fifo.rdwr.."_"..field_prefix.."_o", sig)});
				 table_join(f.signals, { signal (type, size, sig) });
				 if(type == BIT) then
						table_join(f.read_code, { va(vi("rddata_reg", f.offset), sig) });
				 else
						table_join(f.read_code, { va(vi("rddata_reg", f.offset + f.size - 1, f.offset), sig) });
				 end
				 table.insert(csr, f);		
			else
				 table_join(fifo.maps, { vpm (fifo.rdwr.."_full_o", vopenpin())});
			end
	 end

	 gen_fifo_csr_field(FIFO_FULL, 
											"full", 
											"FIFO full flag",
											"1: FIFO '"..fifo.name.."' is full\n0: FIFO is not full",
											1,
											BIT,
											16);

	 gen_fifo_csr_field(FIFO_EMPTY, 
											"empty", 
											"FIFO empty flag",
											"1: FIFO '"..fifo.name.."' is empty\n0: FIFO is not empty",
											1,
											BIT,
											17);

	 gen_fifo_csr_field(FIFO_COUNT, 
											"count", 
											"FIFO counter",
											"Number of data records currently being stored in FIFO '"..fifo.name.."'",
											fifo.usedw_size,
											SLV,
											0);


											


	 if(type(fifo.flags_bus) == "table") then
			table.insert(periph, csr);
	 end
	 

end

function gen_code_fifo(fifo)
  local prefix = string.lower(periph.hdl_prefix.."_"..fifo.hdl_prefix);

	print("GenCodeFIFO");

	fifo.full_prefix = prefix;
	fifo.ports= {};
	fifo.signals={};
	fifo.maps = {};
	fifo.extra_code = {};

	if(fifo.direction == BUS_TO_CORE) then
		 fifo.rdwr = "rd";
	else
		 fifo.rdwr = "wr";
	end


	fifo_wire_core_ports(fifo);
	fifo_wire_bus_ports(fifo);

	table_join(fifo.signals, {
								signal (SLV, fifo.total_size, fifo.full_prefix.."_in_int"),
								signal (SLV, fifo.total_size, fifo.full_prefix.."_out_int") });

	if(fifo.direction == BUS_TO_CORE) then
		 table_join(fifo.signals, { signal (BIT, 0, fifo.full_prefix.."_wrreq_int") });
	else

	end




end
