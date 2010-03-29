-- -*- Mode: LUA; tab-width: 2 -*-

-- wbgen2 - a simple Wishbone slave generator
-- (c) 2010 Tomasz Wlostowski
-- CERN BE-Co-HT
-- LICENSED UNDER GPL v2

function gen_hdl_field_prefix(field, reg)
	local field_count;

	if(reg.hdl_prefix == nil) then
		die("no prefix specified for reg: "..reg.name);
	end

	field_count = 0;
	foreach_subfield(reg, function(field, reg) field_count = field_count+1; end );

	if(field.count == 0) then
		die("empty reg: "..reg.name);
	end
		
	if(field.hdl_prefix == nil) then
		if(field_count >1 ) then die("multiple anonymous-prefix fields declared for reg: "..reg.name); end
		return  string.lower(periph.hdl_prefix.."_"..reg.hdl_prefix);
	end


  
	return  string.lower(periph.hdl_prefix.."_"..reg.hdl_prefix.."_"..field.hdl_prefix);

end

-- generates VHDL for monostable-type field (both same-clock and other-clock)
function gen_hdl_code_monostable(field, reg)
	local prefix = gen_hdl_field_prefix(field, reg); 

--	field.prefix = prefix;

-- monostable type field using WB bus clock
  if(field.clock == nil) then
-- WB-synchronous monostable port (bus write-only)
		field.signals = 	{	signal(BIT, 0, prefix.."_dly0"),
												signal(BIT, 0, prefix.."_int") };
					
		field.ports =		{	port(BIT, 0, "out", prefix.."_o", "Port for MONOSTABLE field: '"..field.name.."' in reg: '"..reg.name.."'" ) };
		field.acklen = 3;

		field.extra_code = vsyncprocess("bus_clock_int", "rst_n_i", {
												 vreset (0, {
													va(prefix.."_dly0", 0);
													va(prefix.."_o", 0);
												 });
												 vposedge {
													va(prefix.."_dly0", prefix.."_int");
													va(prefix.."_o", vand(prefix.."_int", vnot(prefix.."_dly0")));
												 };
												});
		
  	field.reset_code_main =  	{ va(prefix.."_int", 0) };
	  field.write_code = 				{ va(prefix.."_int", vi("wrdata_reg", field.offset)) };
	  field.read_code = 				{  };
	  field.ackgen_code = 			{ va(prefix.."_int", 0) };

  else
-- WB-asynchronous monostable port (bus write-only)	
 		field.signals = 					{	signal(BIT, 0, prefix.."_int"), 
 																signal(BIT, 0, prefix.."_int_delay"), 
																signal(BIT, 0, prefix.."_sync0"), 
																signal(BIT, 0, prefix.."_sync1"),
																signal(BIT, 0, prefix.."_sync2") };
					
	  field.ports = 						{	port(BIT, 0, "out", prefix.."_o", "Port for asynchronous (clock: "..field.clock..") MONOSTABLE field: '"..field.name.."' in reg: '"..reg.name.."'") };

	  field.acklen = 						5;
	   
	  field.extra_code =				{ vsyncprocess(field.clock, "rst_n_i", {
	  														vreset (0, {
	  														 va(prefix.."_o", 0);
	  														 va(prefix.."_sync0", 0);
	  														 va(prefix.."_sync1", 0);
	  														 va(prefix.."_sync2", 0);
	  														}); 

																vposedge({
																 va(prefix.."_sync0", prefix.."_int");
																 va(prefix.."_sync1", prefix.."_sync0");
																 va(prefix.."_sync2", prefix.."_sync1");
																 va(prefix.."_o", vand(prefix.."_sync2", vnot(prefix.."_sync1")));
 																});
 																});  };
																

	  field.reset_code_main = 	{ va(prefix.."_int", 0);
	 															va(prefix.."_int_delay", 0); };
	 															

	  field.write_code =				{ va(prefix.."_int", vi("wrdata_reg", field.offset));
	  														va(prefix.."_int_delay", vi("wrdata_reg", field.offset)); };

	  field.read_code =					{ };

	  field.ackgen_code_pre =		{ va(prefix.."_int", prefix.."_int_delay");
	  														va(prefix.."_int_delay", 0); };
  end
end


-- generates code for BIT-type field
function gen_hdl_code_bit(field, reg)
	local prefix = gen_hdl_field_prefix(field, reg); 

  field.prefix = prefix;

-- BIT-type field using WB bus clock
  if(field.clock == nil) then
    if(field.access == ACC_RW_RO) then
-- bus(read-write), dev(read-only) bitfield
			field.ports =						{ port(BIT, 0, "out", prefix.."_o", "Port for BIT field: '"..field.name.."' in reg: '"..reg.name.."'" ) };
			field.signals = 				{ signal(BIT, 0, prefix.."_int") };
			field.acklen = 					1;
			
			field.write_code =			{ va(prefix.."_int",  vi("wrdata_reg", field.offset)) };
			field.read_code = 			{ va(vi("rddata_reg", field.offset), prefix.."_int") };
	    field.reset_code_main =	{ va(prefix.."_int", 0) };
			field.extra_code =			{ va(prefix.."_o", prefix.."_int") };

	  elseif (field.access == ACC_RO_WO) then
-- bus(read-only), dev(read-only) bitfield
	   	field.ports =						{ port(BIT, 0, "in", prefix.."_i", "Port for BIT field: '"..field.name.."' in reg: '"..reg.name.."'") };
			field.signals = 				{  };
			field.acklen = 					1;
			field.write_code =			{  };
			field.read_code = 			{ va(vi("rddata_reg", field.offset), prefix.."_i") };
      field.reset_code_main =	{  };
			field.extra_code =	{  };

	  elseif (field.access == ACC_WO_RO) then
-- bus(write-only), dev(read-only) bitfield - unsupported yet (use RW/RO type instead)
			die("WO-RO type unsupported yet ("..field.name..")");

	  elseif (field.access == ACC_RW_RW) then
-- dual-write bitfield (both from the bus and the device)
			if(field.load == LOAD_EXT) then

-- external load type (e.g. the register itself is placed outside the WB slave, which only outputs new value and asserts the "load" signal for single clock cycle upon bus write.
		    field.ports =						{	port(BIT, 0, "out", prefix.."_o", "Ports for BIT field: '"..field.name.."' in reg: '"..reg.name.."'"),
							  									port(BIT, 0, "in", prefix.."_i"),	    
																	port(BIT, 0, "out", prefix.."_load_o") };	    
	
		    field.acklen =			 		1;
		    
		    field.read_code = 			{ va(vi("rddata_reg", field.offset), prefix.."_i") };
		    field.write_code = 			{ va(prefix.."_load_o", 1) };
		    field.extra_code =			{ va(prefix.."_o", vi("wrdata_reg", field.offset)) };
		    field.ackgen_code_pre = { va(prefix.."_load_o", 0) };
		    field.ackgen_code  = 		{ va(prefix.."_load_o", 0) };
		    field.reset_code_main = { va(prefix.."_load_o", 0) };
	
			else
		    die("internal RW/RW register storage unsupported yet ("..field.name..")");
			end
    end
	else
-- asynchronous bit-type register

    if(field.access == ACC_RW_RO) then
-- bus(read-write), dev(read-only) bitfield, asynchronous
			field.ports =						{ port(BIT, 0, "out", prefix.."_o", "Port for asynchronous (clock: "..field.clock..") BIT field: '"..field.name.."' in reg: '"..reg.name.."'") };
			field.signals = 				{ signal(BIT, 0, prefix.."_int"),
												  			signal(BIT, 0, prefix.."_sync0"),
												  			signal(BIT, 0, prefix.."_sync1") };
					
			field.acklen = 					4;
			field.write_code =			{ va(prefix.."_int", vi("wrdata_reg", field.offset)) };
			field.read_code = 			{ va(vi("rddata_reg", field.offset), prefix.."_int") };

	    field.reset_code_main =	{ va(prefix.."_int", 0) };

			field.extra_code =			{	vcomment("synchronizer chain for field : "..field.name.." (type RW/RO, bus_clock_int <-> "..field.clock..")");
																vsyncprocess(field.clock, "rst_n_i", {
																vreset(0, {
 								    							va(prefix.."_o", 0);
 							    								va(prefix.."_sync0", 0);
																	va(prefix.."_sync1", 0);
																});
																vposedge({
																	va(prefix.."_sync0", prefix.."_int");
																	va(prefix.."_sync1", prefix.."_sync0");
																	va(prefix.."_o", prefix.."_sync1");
																});
																});
															 };

		elseif (field.access == ACC_RO_WO) then
-- bus(read-only), dev(write-only) bitfield, asynchronous

		field.ports =							{ port(BIT, 0, "in", prefix.."_i", "Port for asynchronous (clock: "..field.clock..") BIT field: '"..field.name.."' in reg: '"..reg.name.."'") };
		field.signals = 					{ signal(BIT, 0, prefix.."_sync0"),
															  signal(BIT, 0, prefix.."_sync1") };
					
		field.acklen = 						1;
		field.write_code =				{  };
		field.read_code = 				{ va(vi("rddata_reg", field.offset), prefix.."_sync1") };

    field.reset_code_main =		{ };

		field.extra_code =				{	vcomment("synchronizer chain for field : "..field.name.." (type RO/WO, "..field.clock.." -> bus_clock_int)");
																vsyncprocess(field.clock, "rst_n_i", {
																vreset(0, {
																va(prefix.."_sync0", 0); 
																va(prefix.."_sync1", 0);
																});
																
																vposedge({
																va(prefix.."_sync0", prefix.."_i");
																va(prefix.."_sync1", prefix.."_sync0");
																});
																});
															};

    elseif (field.access == ACC_RW_RW) then
-- asynchronous dual-write bitfield. Tough shit :/

		if(field.load ~= LOAD_EXT) then
		    die("Only external load is supported for RW/RW bit fields");
			end

			local comment = "Ports for asynchronous (clock: "..field.clock..") RW/RW BIT field: '"..field.name.."' in reg: '"..reg.name.."'";

   		field.ports =									{	port(BIT, 0, "out", prefix.."_o", comment),
																			port(BIT, 0, "in", 	prefix.."_i"),
																			port(BIT, 0, "out", prefix.."_load_o") };  


			field.signals = 							{ signal(BIT, 0, prefix.."_int_read"),
																			signal(BIT, 0, prefix.."_int_write"),
																			signal(BIT, 0, prefix.."_lw"),
																			signal(BIT, 0, prefix.."_lw_delay"),
																			signal(BIT, 0, prefix.."_lw_read_in_progress"),
																			signal(BIT, 0, prefix.."_lw_s0"),
																			signal(BIT, 0, prefix.."_lw_s1"),
																			signal(BIT, 0, prefix.."_lw_s2"),
																			signal(BIT, 0, prefix.."_rwsel") };
																			
			field.acklen = 									6;
		
			field.write_code =						{ va(prefix.."_int_write", vi("wrdata_reg", field.offset));
																			va(prefix.."_lw", 1);
																			va(prefix.."_lw_delay", 1);
																			va(prefix.."_lw_read_in_progress", 0);
																			va(prefix.."_rwsel", 1); }; 

			field.read_code =						{ 	va(prefix.."_lw", 1);
																			va(prefix.."_lw_delay", 1);
																			va(prefix.."_lw_read_in_progress", 1);
																			va(prefix.."_rwsel", 0); }; 
																			

			field.reset_code_main =				{ va(prefix.."_lw", 0);
																			va(prefix.."_lw_delay", 0);
																			va(prefix.."_lw_read_in_progress", 0);
																			va(prefix.."_rwsel", 0);
																			va(prefix.."_int_write", 0);
																		};
							

			field.ackgen_code_pre =				{ va(prefix.."_lw", prefix.."_lw_delay");
																			va(prefix.."_lw_delay", 0);
																			vif(vand(vequal(vi("ack_sreg", 1), 1), vequal(prefix.."_lw_read_in_progress", 1)), {
																				va(vi("rddata_reg", field.offset), prefix.."_int_read");
																				va(prefix.."_lw_read_in_progress", 0);
																			});
																		};


			field.extra_code =						{ vcomment("asynchronous BIT register : "..field.name.." (type RW/WO, "..field.clock.." <-> bus_clock_int)");
											    					  vsyncprocess(field.clock, "rst_n_i", {
																				vreset(0, {
															 					  va(prefix.."_lw_s0", 0); 
																					va(prefix.."_lw_s1", 0); 
																					va(prefix.."_lw_s2", 0); 
																					va(prefix.."_int_read", 0); 
																					va(prefix.."_load_o", 0); 
																					va(prefix.."_o", 0);
																				});
																	      vposedge({
																					va(prefix.."_lw_s0", prefix.."_lw");
																					va(prefix.."_lw_s1", prefix.."_lw_s0");
																					va(prefix.."_lw_s2", prefix.."_lw_s1");
																					vif(vand(vequal(prefix.."_lw_s2", 0), vequal(prefix.."_lw_s1", 1)), {
																						vif(vequal(prefix.."_rwsel", 1), {
																							va(prefix.."_o", prefix.."_int_write");
																							va(prefix.."_load_o", 1);
																						}, {
																							va(prefix.."_load_o", 0);
																							va(prefix.."_int_read", prefix.."_i");
																						});
																					}, {
																						va(prefix.."_load_o", 0);
																					});
																					});
																					});
																				};

		elseif (field.access == ACC_WO_RO) then
			die("WO-RO type unsupported yet ("..field.name..")");
    end
	end
end

-- generates the bit-range for accessing a certain register field from WB-bus
function vir(name, field)
	local syn = {};
	syn.t="index";
	syn.name=name;
	syn.h=field.offset+field.size-1;
	syn.l=field.offset;
	return syn;
end

-- generates code for slv, signed or unsigned fields
function gen_hdl_code_slv(field, reg)
	local prefix = gen_hdl_field_prefix(field, reg); 


  field.prefix = prefix;

-- synchronous signed/unsigned/slv field
  if(field.clock == nil) then
  
	  if(field.access == ACC_RW_RO) then
-- bus(read-write), dev(read-only) slv
			field.ports =						{ port(field.type, field.size, "out", prefix.."_o", "Port for "..fieldtype_2_vhdl[field.type].." field: '"..field.name.."' in reg: '"..reg.name.."'") };
			field.signals = 				{ signal(SLV, field.size, prefix.."_int") };
			field.acklen = 					1;
			field.write_code =			{ va(prefix.."_int", vir("wrdata_reg", field)); };
			field.read_code = 			{ va(vir("rddata_reg", field), prefix.."_int"); };
	    field.reset_code_main =	{ va(prefix.."_int",  0); };
			field.extra_code =			{ va(prefix.."_o", prefix.."_int"); };
		
    elseif (field.access == ACC_RO_WO) then
-- bus(read-only), dev(write-only) slv
			field.ports =						{ port(field.type, field.size, "in", prefix.."_i",  "Port for "..fieldtype_2_vhdl[field.type].." field: '"..field.name.."' in reg: '"..reg.name.."'") };
			field.signals = 				{  };
			field.acklen = 					1;
			field.write_code =			{  };
			field.read_code = 			{ va(vir("rddata_reg", field), prefix.."_i"); };
   		field.reset_code_main =	{  };
			field.extra_code =			{  };

	  elseif (field.access == ACC_RW_RW) then
-- bus(read-write), dev(read-write) slv
   		if(field.load ~= LOAD_EXT) then
		    die("Only external load is supported for RW/RW slv/signed/unsigned fields");
			end

		    field.ports =						{	port(field.type, field.size, "out", prefix.."_o",  "Port for "..fieldtype_2_vhdl[field.type].." field: '"..field.name.."' in reg: '"..reg.name.."'"),
										    					port(field.type, field.size, "in", prefix.."_i"),	    
																	port(BIT, 0, "out", prefix.."_load_o") };	    
	
		    field.acklen = 					1;
		    
		    field.read_code = 			{ va(vir("rddata_reg", field), prefix.."_i"); };
		    field.write_code = 			{ va(prefix.."_load_o", 0); };
		    field.extra_code =			{ va(prefix.."_o", vir("wrdata_reg", field)); };
		    field.ackgen_code_pre = { va(prefix.."_load_o", 0);};
		    field.ackgen_code = 		{ va(prefix.."_load_o", 0); };
		    field.reset_code_main = { va(prefix.."_load_o", 0); };
		end
	else
-- asynchronous register. Even tougher shit :(

		if(field.access == ACC_RW_RO) then
-- bus(read-write), dev(read-only) slv/signed/unsigned
			local comment = "Port for asynchronous (clock: "..field.clock..") "..fieldtype_2_vhdl[field.type].." field: '"..field.name.."' in reg: '"..reg.name.."'";

			field.ports =									{ port(field.type, field.size, "out", prefix.."_o", comment) };

			field.signals = 							{ signal(SLV, field.size, prefix.."_int"),
																			signal(BIT, 0, prefix.."_swb"),
																			signal(BIT, 0, prefix.."_swb_delay"),
																			signal(BIT, 0, prefix.."_swb_s0"),
																			signal(BIT, 0, prefix.."_swb_s1"),
																			signal(BIT, 0, prefix.."_swb_s2") };
							
			field.acklen = 								4;
		
			field.write_code =						{ va(prefix.."_int", vir("wrdata_reg", field));
																			va(prefix.."_swb", 1);
																			va(prefix.."_swb_delay", 1); };
							
			field.read_code = 						{ va(vir("rddata_reg", field), prefix.."_int"); };
		
			field.reset_code_main =				{ va(prefix.."_int", 0); 
																			va(prefix.."_swb", 0);
																			va(prefix.."_swb_delay", 0); };
										
			field.ackgen_code_pre =				{ va(prefix.."_swb", prefix.."_swb_delay");
																			va(prefix.."_swb_delay", 0); };
			

			field.extra_code =						{ vcomment("asynchronous "..fieldtype_2_vhdl[field.type].." register : "..field.name.." (type RW/RO, "..field.clock.." <-> bus_clock_int)");
																			vsyncprocess(field.clock, "rst_n_i", {
																				vreset(0, {
																					va(prefix.."_swb_s0", 0);
																					va(prefix.."_swb_s1", 0); 
																					va(prefix.."_swb_s2", 0); 
																					va(prefix.."_o", 0);
																				});
																				vposedge({
																					va(prefix.."_swb_s0", prefix.."_swb");
																					va(prefix.."_swb_s1", prefix.."_swb_s0");
																					va(prefix.."_swb_s2", prefix.."_swb_s1");
																					vif(vand(vequal(prefix.."_swb_s2", 0), vequal(prefix.."_swb_s1", 1)), {
																						va(prefix.."_o", prefix.."_int");
																					});
																				});
																			});
																			};
																		
		elseif(field.access == ACC_RO_WO) then
-- bus(read-write), dev(read-only) slv
			local comment = "Port for asynchronous (clock: "..field.clock..") "..fieldtype_2_vhdl[field.type].." field: '"..field.name.."' in reg: '"..reg.name.."'";
	
			field.ports =									{ port(field.type, field.size, "in", prefix.."_i", comment) };

			field.signals = 							{ signal(SLV, field.size, prefix.."_int"),
																			signal(BIT, 0, prefix.."_lwb"),
																			signal(BIT, 0, prefix.."_lwb_delay"),
																			signal(BIT, 0, prefix.."_lwb_in_progress"),
																			signal(BIT, 0, prefix.."_lwb_s0"),
																			signal(BIT, 0, prefix.."_lwb_s1"),
																			signal(BIT, 0, prefix.."_lwb_s2") };
					  
			field.acklen = 								6;
			field.write_code =						{  }; 

			field.read_code = 						{ va(prefix.."_lwb", 1);
																			va(prefix.."_lwb_delay", 1);
																			va(prefix.."_lwb_in_progress", 1); };

			field.reset_code_main =				{ va(prefix.."_lwb", 0);
																			va(prefix.."_lwb_delay", 0);
																			va(prefix.."_lwb_in_progress", 0); };


			field.ackgen_code_pre =				{ va(prefix.."_lwb", prefix.."_lwb_delay");
																			va(prefix.."_lwb_delay", 0);
																			vif(vand(vequal(vi("ack_sreg", 1), 1), vequal(prefix.."_lwb_in_progress", 1)), {
																				va(vir("rddata_reg", field), prefix.."_int");
																				va(prefix.."_lwb_in_progress", 0);
																			});
																		};

			field.extra_code =						{ vcomment("asynchronous "..fieldtype_2_vhdl[field.type].." register : "..field.name.." (type RO/WO, "..field.clock.." <-> bus_clock_int)"),
																			vsyncprocess(field.clock, "rst_n_i", {
																			vreset(0, { 
																				va(prefix.."_lwb_s0", 0);
																				va(prefix.."_lwb_s1", 0);
																				va(prefix.."_lwb_s2", 0); 
																				va(prefix.."_int", 0);
																			});
																			vposedge({
																				va(prefix.."_lwb_s0", prefix.."_lwb");
																				va(prefix.."_lwb_s1", prefix.."_lwb_s0");
																				va(prefix.."_lwb_s2", prefix.."_lwb_s1");
																				vif(vand(vequal(prefix.."_lwb_s1", 1), vequal(prefix.."_lwb_s2", 0)), {
																					va(prefix.."_int", prefix.."_i");
																				});
																			});
																		});																			
																		};
	
		elseif(field.access == ACC_RW_RW) then
-- async bus(read-write), dev(read-write) slv. gooosh...

   		if(field.load ~= LOAD_EXT) then
		    die("Only external load is supported for RW/RW slv/signed/unsigned fields");
			end

			local comment = "Ports for asynchronous (clock: "..field.clock..") "..fieldtype_2_vhdl[field.type].." field: '"..field.name.."' in reg: '"..reg.name.."'";

   		field.ports =									{	port(field.type, field.size, "out", prefix.."_o", comment),
																			port(field.type, field.size, "in", prefix.."_i"),
																			port(BIT, 0, "out", prefix.."_load_o") };  


			field.signals = 							{ signal(SLV, field.size, prefix.."_int_read"),
																			signal(SLV, field.size, prefix.."_int_write"),
																			signal(BIT, 0, prefix.."_lw"),
																			signal(BIT, 0, prefix.."_lw_delay"),
																			signal(BIT, 0, prefix.."_lw_read_in_progress"),
																			signal(BIT, 0, prefix.."_lw_s0"),
																			signal(BIT, 0, prefix.."_lw_s1"),
																			signal(BIT, 0, prefix.."_lw_s2"),
																			signal(BIT, 0, prefix.."_rwsel") };
																			
							
			field.acklen = 									6;
		
			field.write_code =						{ va(prefix.."_int_write", vir("wrdata_reg", field));
																			va(prefix.."_lw", 1);
																			va(prefix.."_lw_delay", 1);
																			va(prefix.."_lw_read_in_progress", 0);
																			va(prefix.."_rwsel", 1); }; 

			field.read_code =						{ 	va(prefix.."_lw", 1);
																			va(prefix.."_lw_delay", 1);
																			va(prefix.."_lw_read_in_progress", 1);
																			va(prefix.."_rwsel", 0); }; 
																			

			field.reset_code_main =				{ va(prefix.."_lw", 0);
																			va(prefix.."_lw_delay", 0);
																			va(prefix.."_lw_read_in_progress", 0);
																			va(prefix.."_rwsel", 0);
																			va(prefix.."_int_write", 0);
																		};
							

			field.ackgen_code_pre =				{ va(prefix.."_lw", prefix.."_lw_delay");
																			va(prefix.."_lw_delay", 0);
																			vif (vand(vequal(vi("ack_sreg", 1), 1), vequal(prefix.."_lw_read_in_progress", 1)), {
																				va(vir("rddata_reg", field), prefix.."_int_read");
																			});
																			va(prefix.."_lw_read_in_progress", 0);
																			};

			field.extra_code =						{ vcomment("asynchronous "..fieldtype_2_vhdl[field.type].." register : "..field.name.." (type RW/WO, "..field.clock.." <-> bus_clock_int)");
											    					  vsyncprocess(field.clock, "rst_n_i", {
													 					  vreset(0, {
																				va(prefix.."_lw_s0", 0);
																				va(prefix.."_lw_s1", 0);
																				va(prefix.."_lw_s2", 0);
																				va(prefix.."_o", 0); 
																				va(prefix.."_load_o", 0); 
	 																			va(prefix.."_int_read", 0);
																			});
																			vposedge({	
																				va(prefix.."_lw_s0", prefix.."_lw");
																				va(prefix.."_lw_s1", prefix.."_lw_s0");
																				va(prefix.."_lw_s2", prefix.."_lw_s1");
																				vif(vand(vequal(prefix.."_lw_s2", 0), vequal(prefix.."_lw_s1", 1)), {
																					vif(vequal(prefix.."_rwsel", 1), {
																						va(prefix.."_o", prefix.."_int_write");
																						va(prefix.."_load_o", 1);
																					}, {
																						va(prefix.."_load_o", 0);
																						va(prefix.."_int_read", prefix.."_i");
																					});
																				}, {
																					va(prefix.."_load_o", 0);
																				});
																			});
																			});
																			};
		end 
	end
end

function gen_hdl_code_passthrough(field, reg)
	local prefix = gen_hdl_field_prefix(field, reg); 

	if(field.clock == nil) then
-- sync pass-through

			local comment = "Ports for PASS_THROUGH field: '"..field.name.."' in reg: '"..reg.name.."'";

   		field.ports =									{	port(SLV, field.size, "out", prefix.."_o", comment),
   																		port(BIT, 0, "out", prefix.."_wr_o") };

			field.acklen = 1;
			
			field.reset_code_main	= 			{ va(prefix.."_wr_o", 0); };
			field.read_code = 						{};
			field.write_code = 						{ va(prefix.."_wr_o", 1); };
			field.ackgen_code_pre =				{ va(prefix.."_wr_o", 0); };
			field.ackgen_code	 =					{ va(prefix.."_wr_o", 0); };
			field.extra_code =						{ vcomment("pass-through field: "..field.name.." in register: "..reg.name);
																			va(prefix.."_o", vir("wrdata_reg", field)); }
	else

			local comment = "Ports for asynchronous (clock: "..field.clock..") PASS_THROUGH field: '"..field.name.."' in reg: '"..reg.name.."'";

   		field.ports =									{	port(SLV, field.size, "out", prefix.."_o", comment),
   																		port(BIT, 0, "out", prefix.."_wr_o") };

			field.signals =								{ signal(BIT, 0, prefix.."_wr_int"), 
																			signal(BIT, 0, prefix.."_wr_int_delay"), 
																			signal(BIT, 0, prefix.."_wr_sync0"), 
																			signal(BIT, 0, prefix.."_wr_sync1"),
																			signal(BIT, 0, prefix.."_wr_sync2") };

			field.acklen = 4;
			
			field.reset_code_main	= 			{ va(prefix.."_wr_int", 0);
																			va(prefix.."_wr_int_delay", 0); };
			field.read_code = 						{};

			field.write_code = 						{ va(prefix.."_wr_int", 1); 
																			va(prefix.."_wr_int_delay", 1);  };
			field.ackgen_code_pre =				{ va(prefix.."_wr_int", prefix.."_wr_int_delay");
																			va(prefix.."_wr_int_delay", 0); };

			field.extra_code =						{ vcomment("pass-through field: "..field.name.." in register: "..reg.name);
																			va(prefix.."_o", vir("wrdata_reg", field));
																			vsyncprocess(field.clock, "rst_n_i", {
																				vreset(0, {
																					va(prefix.."_wr_sync0", 0);
																					va(prefix.."_wr_sync1", 0);
																					va(prefix.."_wr_sync2", 0);
																				});
																				vposedge({
																					va(prefix.."_wr_sync0", prefix.."_wr_int");
																					va(prefix.."_wr_sync1", prefix.."_wr_sync0");
																					va(prefix.."_wr_sync2", prefix.."_wr_sync1");
																					va(prefix.."_wr_o", vand(prefix.."_wr_sync1", vnot(prefix.."_wr_sync2")));
																				});
																			});
																			}
			end

end

-- generates code which loads data unused bits of data output register with Xs 
function fill_unused_bits(target, reg)
	local t={};
	local code={};

	foreach_subfield(reg, function(field, reg)
													if(field.type == SLV or field.type == SIGNED or field.type == UNSIGNED) then
														for i=field.offset, (field.offset+field.size-1) do t[i] = 1; end
													elseif(field.type == BIT or field.type == MONOSTABLE)  then
														t[field.offset] = 1;
													end
												end);

	for i = 0, DATA_BUS_WIDTH-1 do
		if(t[i] == nil) then
			table_join(code, { va(vi(target, i), vundefined()); });
		end
	end
	
	return code;
end


-- generates VHDL code for single register field
function gen_hdl_code_reg_field(field, reg)
  
	if(field.type == MONOSTABLE) then
    gen_hdl_code_monostable(field, reg);
	elseif(field.type == BIT) then 
    gen_hdl_code_bit(field, reg);
	elseif(field.type == SIGNED or field.type == UNSIGNED or field.type == SLV) then	    
    gen_hdl_code_slv(field, reg);
	elseif(field.type == PASS_THROUGH) then
		gen_hdl_code_passthrough(field, reg);
	end
end

-- generates VHDL for single register
function gen_abstract_code(reg)

 	reg.full_hdl_prefix = string.lower(periph.hdl_prefix.."_"..reg.hdl_prefix);

	if(reg.no_std_regbank == true) then
		return;
	end


	if(reg.__type == TYPE_RAM) then
		gen_code_ram(reg);
  else
  	foreach_subfield(reg, function(field, reg) gen_hdl_code_reg_field(field, reg); end );
  end
end

function gen_hdl_block_select_bits()
  return vi("rwaddr_reg", address_bus_width-1, (address_bus_width - address_bus_select_bits));
end

