-- -*- Mode: LUA; tab-width: 2 -*-

function fifo_wire_core_ports(fifo)
	local prefix = fifo.full_prefix;
  local total_size = 0;

  fifo.usedw_size = log2up(fifo.size);


	local ports = {
		 port(BIT, 0, "in", prefix.."_"..fifo.rdwr.."_req_i", 
					csel(fifo.direction == BUS_TO_CORE, "FIFO read request", "FIFO write request" ), VPORT_REG)
	};

  -- wire the read/write request port
	table_join(fifo.maps, { vpm (fifo.rdwr.."_req_i",  prefix.."_"..fifo.rdwr.."_req_i") });

  -- add full/empty/usedw ports
	if inset(FIFO_FULL, fifo.flags_dev) then
		 table_join(ports, { port (BIT, 0, "out", prefix.."_"..fifo.rdwr.."_full_o", "FIFO full flag", VPORT_REG) });
		 table_join(fifo.maps, { vpm (fifo.rdwr.."_full_o", prefix.."_"..fifo.rdwr.."_full_o")});
	end

	if inset(FIFO_EMPTY, fifo.flags_dev) then
		 table_join(ports, { port (BIT, 0, "out", prefix.."_"..fifo.rdwr.."_empty_o", "FIFO empty flag", VPORT_REG) });
		 table_join(fifo.maps, { vpm (fifo.rdwr.."_empty_o", prefix.."_"..fifo.rdwr.."_empty_o")});
	end

	if inset(FIFO_COUNT, fifo.flags_dev) then
		 table_join(ports, { port (SLV, fifo.usedw_size, "out", prefix.."_"..fifo.rdwr.."_usedw_o", 
															 "FIFO number of used words", VPORT_REG) });
		 table_join(fifo.maps, { vpm (fifo.rdwr.."_usedw_o", prefix.."_"..fifo.rdwr.."_usedw_o")});
	end

	foreach_subfield(fifo, 
									 function(field, f) 
											local field_pfx = string.lower(prefix.."_"..field.hdl_prefix);
											total_size = total_size + field.size;

											if(fifo.direction == BUS_TO_CORE) then -- bus -> core fifo
                         -- generate an output port for the field
												 table_join(ports, {port (field.type, field.size, "out", field_pfx.."_o", "", VPORT_REG)});
                         -- assign the output to the FIFO output port
												 table_join(fifo.extra_code, { 
																			 va(field_pfx.."_o", 
																					vi(prefix.."_out_int", field.offset_unaligned + field.size -1,
																						 field.offset_unaligned)) });
												 
											else 
-- generate an input port for the field
												 table_join(ports, {port (field.type, field.size, "in",  field_pfx.."_i", "", VPORT_REG)});
                         
-- core -> bus fifo: wire the inputs to FIFO data input
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
	 local r;

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

--			print("DREG ", i);

			-- allocate the registers.

			foreach_subfield(fifo, 
											 function(field)
						
													if(field.offset >= minofs and field.offset + field.size - 1 <= maxofs) then
														 table.insert(fifo_dregs[i], field);
														 field.offset = field.offset - minofs;
														 dbg("FIELD: ", field.name, " OFS: ", field.offset, "SIZE: ",field.size);

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
			r.doc_is_fiforeg = true;

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
														 
														 field.read_code = { 
																va(
																	 vi("rddata_reg",  -- src
																			field.offset + field.size - 1, 
																			field.offset),
																vi(fifo.full_prefix.."_out_int",  -- dst
																	 field.offset_unaligned + field.size - 1,
																	 field.offset_unaligned))
														 };

														 field.access_bus = READ_ONLY;
														 field.access_dev = WRITE_ONLY;
														 

													end

											 end);

			

			table.insert(periph, r);
	 end

	 dbg("lastreg: " ,r.name);
	 
	 -- last register:
	 if(fifo.direction == BUS_TO_CORE) then -- Last FIFO I/O register
			table_join(r.write_code, { va(fifo.full_prefix.."_wrreq_int", 1) });
			table_join(r.ackgen_code, { va(fifo.full_prefix.."_wrreq_int", 0) });
			table_join(r.reset_code_main, { va(fifo.full_prefix.."_wrreq_int", 0) });
	 else
			local r = fifo_dregs[0];

	--		local old_readcode = deepcopy(r.read_code);
			
-- generate a delay for read request signal
			table_join(r.extra_code, { vsyncprocess("clk_sys_i", "rst_n_i", {
																	 vreset(0, {
																		 va(fifo.full_prefix.."_rdreq_int_d0", 0)
																	 });
																	 vposedge ( {
																		va(fifo.full_prefix.."_rdreq_int_d0",fifo.full_prefix.."_rdreq_int")
																	 });
																}) });

			local fields_readcode = {};

			foreach_subfield(r, 
											 function(field)
													table_join(fields_readcode, field.read_code);
													field.read_code = nil;
											 end);
													

			table_join(r.reset_code_main, { va(fifo.full_prefix.."_rdreq_int", 0) });

			r.read_code = {
				 vif(vequal(fifo.full_prefix.."_rdreq_int_d0", 0), { 
											 va(fifo.full_prefix.."_rdreq_int", vnot(fifo.full_prefix.."_rdreq_int"));
										}, { -- else
											 fields_readcode;
											 va("ack_in_progress", 1);
											 va(vi("ack_sreg", 0), 1);
										})
			};

			r.dont_emit_ack_code = true;


	 end


	 


-- add full/empty/usedw control register
	 local csr = {
			["__type"]         = TYPE_REG;
			["name"]           = "FIFO '"..fifo.name.."' control/status register";
			["c_prefix"]       = fifo.c_prefix.."_CSR";
			["hdl_prefix"]     = fifo.hdl_prefix.."_CSR";
			["no_std_regbank"] = true;
	 };

	 function gen_fifo_csr_field(flag, field_prefix, field_name, field_desc, size, type, offset, do_map)
			
      print("GenCSR Field "..field_name);

      if(fifo.flags_bus == nil) then
         return;
			end

			
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

         if(do_map==nil) then
            do_map=true
         else
            do_map=false
         end

         -- wire the FULL/EMPTY/USEDW signals to appropriate FIFO outputs
				 if(do_map) then
            table_join(fifo.maps, { vpm (fifo.nrdwr.."_"..field_prefix.."_o", sig)});
         end
				 table_join(f.signals, { signal (csel(type == MONOSTABLE, BIT, type), size, sig) });

         if (type == BIT) then
            table_join(f.read_code, { va(vi("rddata_reg", f.offset), sig) });
         elseif (type == SLV) then
            table_join(f.read_code, { va(vi("rddata_reg", f.offset + f.size - 1, f.offset), sig) });
         elseif (type == MONOSTABLE) then
            f.access_bus = WRITE_ONLY;
            f.access_dev = READ_ONLY;
            f.reset_code_main = { va(sig, 0) };
            f.write_code = { vif(vequal(vi("rddata_reg", f.offset), 1), { va(sig, 1) })};
            f.ackgen_code = { va(sig, 0 )}
         end
				 table.insert(csr, f);		
      elseif (do_map) then
				 table_join(fifo.maps, { vpm (fifo.nrdwr.."_"..field_prefix.."_o", vopenpin())});
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

	 gen_fifo_csr_field(FIFO_CLEAR, 
											"clear_bus", 
											"FIFO clear",
											"write 1: clears FIFO '"..fifo.name.."\nwrite 0: no effect",
											1,
											MONOSTABLE,
											18,
                      false);

	 gen_fifo_csr_field(FIFO_COUNT, 
											"usedw", 
											"FIFO counter",
											"Number of data records currently being stored in FIFO '"..fifo.name.."'",
											fifo.usedw_size,
											SLV,
											0);


										
-- add the FIFO CSR register to the peripheral
	 if(type(fifo.flags_bus) == "table") then
			table.insert(periph, csr);
	 end

-- wire the bus-side read/write request port
	 table_join(fifo.maps, { vpm (fifo.nrdwr.."_req_i",  fifo.full_prefix.."_"..fifo.nrdwr.."req_int") });
	 
end


function fifo_wire_clear_ports(fifo)
   
   c_dev = inset(FIFO_CLEAR, fifo.flags_dev);
   c_bus = inset(FIFO_CLEAR, fifo.flags_bus); 

	table_join(fifo.signals, {
								signal (BIT, 0, fifo.full_prefix.."_rst_n")
             });

  table_join(fifo.maps, { vpm ("rst_n_i", fifo.full_prefix.."_rst_n")});

  if(c_dev) then
		 table_join(fifo.ports, { port (BIT, 0, "in", fifo.full_prefix.."_clear_i", "FIFO clear") });
  end

  if (c_dev and c_bus) then 
     table_join(fifo.extra_code, {
                   va(fifo.full_prefix.."_rst_n", vand("rst_n_i", vnot(vor(fifo.full_prefix.."_clear_i", fifo.full_prefix.."_clear_bus_int"))));
                });

  elseif (c_dev) then
     
     table_join(fifo.extra_code, {
                   va(fifo.full_prefix.."_rst_n", vand("rst_n_i", vnot(fifo.full_prefix.."_clear_i")));
                });
  elseif (c_bus) then
     table_join(fifo.extra_code, {
                   va(fifo.full_prefix.."_rst_n", vand("rst_n_i", vnot(fifo.full_prefix.."_clear_bus_int")));
                });
  else
     table_join(fifo.extra_code, {
                   va(fifo.full_prefix.."_rst_n", "rst_n_i");
                });
  end

end

function gen_code_fifo(fifo)
  local prefix = string.lower(periph.hdl_prefix.."_"..fifo.hdl_prefix);

	dbg("GenCodeFIFO");

	fifo.full_prefix = prefix;
	fifo.ports= {};
	fifo.signals={};
	fifo.maps = {};
	fifo.extra_code = {};

	if(fifo.direction == BUS_TO_CORE) then
		 fifo.rdwr = "rd";
		 fifo.nrdwr = "wr";
	else
		 fifo.rdwr = "wr";
		 fifo.nrdwr = "rd";
	end


	fifo_wire_core_ports(fifo);
	fifo_wire_bus_ports(fifo);
  fifo_wire_clear_ports(fifo);


	table_join(fifo.signals, {
								signal (SLV, fifo.total_size, fifo.full_prefix.."_in_int"),
								signal (SLV, fifo.total_size, fifo.full_prefix.."_out_int")
 });

	if(fifo.direction == BUS_TO_CORE) then
		 table_join(fifo.signals, { signal (BIT, 0, fifo.full_prefix.."_wrreq_int") });
	else
		 table_join(fifo.signals, { signal (BIT, 0, fifo.full_prefix.."_rdreq_int") });
		 table_join(fifo.signals, { signal (BIT, 0, fifo.full_prefix.."_rdreq_int_d0") });
	end



	if(fifo.clock == nil) then -- sync FIFO, single clock
		 table_join(fifo.maps, { vpm ("clk_i", "clk_sys_i"); });
	else -- async FIFO, dual clocks
	  if (fifo.direction == BUS_TO_CORE) then
		 table_join(fifo.maps, { vpm ("rd_clk_i", fifo.clock);
									 vpm ("wr_clk_i", "clk_sys_i") });
														 
	  elseif (fifo.direction == CORE_TO_BUS) then
		 table_join(fifo.maps, { vpm ("wr_clk_i", fifo.clock);
									 vpm ("rd_clk_i", "clk_sys_i") });
    end
		 
	end

-- wire the data I/O
		 table_join(fifo.maps, { 
									 vpm ("wr_data_i",  fifo.full_prefix.."_in_int");
									 vpm ("rd_data_o",  fifo.full_prefix.."_out_int") ;

-- and the generics
									 vgm ("g_size", fifo.size);
									 vgm ("g_width",  fifo.total_size);
									 vgm ("g_usedw_size", log2up(fifo.size))

						});

		 


	table_join(fifo.extra_code, {
								vinstance(fifo.full_prefix.."_INST", csel(fifo.clock == nil, "wbgen2_fifo_sync", "wbgen2_fifo_async"), fifo.maps);
						 });


end
