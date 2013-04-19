-- -*- Mode: LUA; tab-width: 2 -*-

-- wbgen2 - a simple Wishbone slave generator
-- (c) 2010 Tomasz Wlostowski
-- CERN BE-Co-HT
-- LICENSED UNDER GPL v2

function ram_wire_core_ports(ram)
	local prefix = ram.full_prefix;



  if(match(ram.access_dev, {READ_ONLY, READ_WRITE})) then -- RAM is readable from the core - wire the data output and read strobe signals
		
		table_join(ram.ports, 	{	port(SLV, ram.width, "out", prefix.."_data_o", "Read data output"),
															port(BIT, 0, "in", prefix.."_rd_i", "Read strobe input (active high)") });

		table_join(ram.maps,		{ vpm ("data_b_o", prefix.."_data_o");
															vpm ("rd_b_i", prefix.."_rd_i"); } );
  else -- ram is not readable - the read strobe low and leave the data output open
		table_join(ram.maps,		{ vpm ("data_b_o", vopenpin());
															vpm ("rd_b_i", vi("allzeros", 0)) });
  end

  if(match(ram.access_dev, {WRITE_ONLY, READ_WRITE})) then

		table_join(ram.ports,	 	{ port(SLV, ram.width, "in", prefix.."_data_i", "Write data input"), 
															port(BIT, 0, "in", prefix.."_wr_i", "Write strobe (active high)") });

		table_join(ram.maps, 		{ vpm ("data_b_i", prefix.."_data_i");
															vpm ("wr_b_i", prefix.."_wr_i"); });

		if(ram.byte_select == true and ram.width >= 16) then
			table_join(ram.ports, { port (SLV, ram.width/8, "in", prefix.."_bwsel_i", "Byte select input (active high)") } );
			table_join(ram.maps, 			{ vpm ("bwsel_b_i", prefix.."_bwsel_i"); } );
		else
			table_join(ram.maps,			{ vpm ("bwsel_b_i", vi("allones", math.floor(ram.width/8)-1, 0)); } );
		end
  else
  	table_join(ram.maps,		{ vpm ("bwsel_b_i", vi("allones", math.floor(ram.width/8)-1, 0)); 
  														vpm ("data_b_i", vi("allzeros", ram.width-1 ,0));
  														vpm ("wr_b_i", vi("allzeros", 0)) });
  end
end

function ram_wire_bus_ports(ram)
	local prefix = ram.full_prefix;
	
-- RAM is readable from the bus?
  if(match(ram.access_bus, {READ_ONLY, READ_WRITE})) then -- yes: wire rd strobe and data output
		
		table_join(ram.signals, { signal(SLV, ram.width,  prefix.."_rddata_int"),
															signal(BIT, 0, prefix.."_rd_int") } );


		table_join(ram.maps,		{ vpm ("data_a_o", vi(prefix.."_rddata_int", ram.width-1, 0));
															vpm ("rd_a_i", prefix.."_rd_int"); } );
																		
  else -- not readable? - set read strobe to zero and leave the data output open
   	table_join(ram.maps,		{	vpm ("rd_a_i", vi("allzeros", 0)),
 															vpm ("data_a_o", vopenpin()) });
  end

-- RAM is writable from the bus?
  if(match(ram.access_bus, {WRITE_ONLY, READ_WRITE})) then
		table_join(ram.signals, { signal(BIT, 0, prefix.."_wr_int") } );

		table_join(ram.maps,	{ vpm ("data_a_i", vi("wrdata_reg", ram.width-1, 0));
														vpm ("wr_a_i", prefix.."_wr_int"); });


		if(ram.byte_select == true and ram.width >= 16) then
			table_join(ram.maps, { vpm ("bwsel_a_i", vi("bwsel_reg", math.floor(ram.width/8)-1, 0)); } );
		else
			table_join(ram.maps,	{ vpm ("bwsel_a_i", vi("allones", math.floor(ram.width/8)-1, 0)); } );
		end
		
  else
  	table_join(ram.maps, 	{ vpm ("bwsel_a_i", vi("allones", math.floor(ram.width/8)-1, 0)); 
  													vpm ("data_a_i", vi("allzeros", ram.width-1 ,0));
  													vpm ("wr_a_i", vi("allzeros", 0)) });
  end
end

function gen_code_ram(ram)
  local prefix = string.lower(periph.hdl_prefix.."_"..ram.hdl_prefix);
	
-- generate the RAM-related ports
	ram.full_prefix = prefix;
	ram.signals = {};
	ram.maps = {};
	
  ram.ports = { port (SLV, ram.addr_bits - ram.wrap_bits, "in", prefix.."_addr_i", "Ports for RAM: "..ram.name ) };
	ram.reset_code_main = {};

-- wire the obligartory signals - address busses and clocks
	table_join(ram.maps,	{ vpm ("clk_a_i", "clk_sys_i");
													vpm ("clk_b_i", csel(ram.clock ~= nil, ram.clock, "clk_sys_i"));
													vpm ("addr_b_i", prefix.."_addr_i");
													vpm ("addr_a_i", vi("rwaddr_reg", log2up(ram.size)-1, 0));
											  });


-- evaluate the access flags (from the core) and wire the core signals to appropriate ports
	ram_wire_core_ports(ram);
-- do the same for the bus signals
	ram_wire_bus_ports(ram);

-- fill in all the generic mappings
	table_join(ram.maps,			{ vgm ("g_data_width", ram.width);
															vgm ("g_size", ram.size);
															vgm ("g_addr_width", log2up(ram.size));
															vgm ("g_dual_clock", csel(ram.clock ~= nil, "true", "false"));
															vgm ("g_use_bwsel", csel(ram.byte_select == true, "true", "false"));
															});

-- instantiate the RAM.
	ram.extra_code = { 			vcomment ("RAM block instantiation for memory: "..ram.name);
                          vinstance (prefix.."_raminst", "wbgen2_dpssram", ram.maps );
									 };

	ram.base = ram.select_bits * math.pow (2, address_bus_width - address_bus_select_bits);				

end
